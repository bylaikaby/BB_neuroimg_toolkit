function [spikes,thr,index] = wvc_amp_detect(x,handles,varargin)
% Detect spikes with amplitude thresholding. Uses median estimation.
% Detection is done with filters set by fmin_detect and fmax_detect. Spikes
% are stored for sorting using fmin_sort and fmax_sort. This trick can
% eliminate noise in the detection but keeps the spikes shapes for sorting.
%
%
%  VERSION :
%    1.00 24.03.14 YM  modified from wave_clus's amp_detect().
%    1.01 24.03.14 YM  testing findpeaks().
%    1.02 25.03.14 YM  allocate memory first, "index".
%
%  See also waveclus_GetSpikes waveclus_DoClustering wvc_int_spikes findpeaks


USE_FINDPEAKS = 1;

for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'usefindpeaks' 'use_findpeaks' 'findpeaks'}
    USE_FINDPEAKS = varargin{N+1};
  end
end



sr=handles.par.sr;
w_pre=handles.par.w_pre;
w_post=handles.par.w_post;
ref=handles.par.ref;
detect = handles.par.detection;
stdmin = handles.par.stdmin;
stdmax = handles.par.stdmax;
fmin_detect = handles.par.detect_fmin;
fmax_detect = handles.par.detect_fmax;
fmin_sort = handles.par.sort_fmin;
fmax_sort = handles.par.sort_fmax;

% HIGH-PASS FILTER OF THE DATA
if any(exist('ellip','file')),            %Checks for the signal processing toolbox
  [b,a]=ellip(2,0.1,40,[fmin_detect fmax_detect]*2/sr);
  xf_detect=filtfilt(b,a,x);
  if fmin_sort == fmin_detect && fmax_sort == fmax_detect,
    xf = xf_detect;
  else
    [b,a]=ellip(2,0.1,40,[fmin_sort fmax_sort]*2/sr);
    xf=filtfilt(b,a,x);
  end
else
  xf=wvc_fix_filter(x);                   %Does a bandpass filtering between [300 3000] without the toolbox.
  xf_detect = xf;
end

clear x;

noise_std_detect = median(abs(xf_detect))/0.6745;
noise_std_sorted = median(abs(xf))/0.6745;
thr = stdmin * noise_std_detect;        %thr for detection is based on detected settings.
thrmax = stdmax * noise_std_sorted;     %thrmax for artifact removal is based on sorted settings.

% LOCATE SPIKE TIMES
nspk = 0;
if any(USE_FINDPEAKS)
  switch detect
   case 'pos'
    % xf_detect =  xf_detect;    % do nothing...
   case 'neg'
    xf_detect = -xf_detect;      % reverse the polarity.
   case 'both'
    xf_detect = abs(xf_detect);  % rectify.
  end
  % [tmppks, xaux] = findpeaks(xf_detect,'MINPEAKHEIGHT',thr);
  % xaux = xaux(xaux > w_pre+2 & xaux < length(xf_detect)-w_post-2);
  % tmppks = xf_detect(xaux);
  [tmppks, xaux] = findpeaks(xf_detect(w_pre+2:end-w_post-2),'MINPEAKHEIGHT',thr);
  xaux = xaux +w_pre+1;
  index = sub_rm_neighbors(tmppks,xaux,ref);
  nspk  = length(index);
  clear tmppks;
else
  ref2 = floor(ref/2);
  switch detect
   case 'pos'
    xaux = find(xf_detect(w_pre+2:end-w_post-2) > thr) +w_pre+1;
    xaux0 = 0;
    index = zeros(1,length(xaux));
    for i=1:length(xaux)
      if xaux(i) >= xaux0 + ref
        [maxi iaux]=max((xf(xaux(i):xaux(i)+ref2-1)));    %introduces alignment
        nspk = nspk + 1;
        index(nspk) = iaux + xaux(i) -1;
        xaux0 = index(nspk);
      end
    end
    index = index(1:nspk);
   case 'neg'
    xaux = find(xf_detect(w_pre+2:end-w_post-2) < -thr) +w_pre+1;
    xaux0 = 0;
    index = zeros(1,length(xaux));
    for i=1:length(xaux)
      if xaux(i) >= xaux0 + ref
        [maxi iaux]=min((xf(xaux(i):xaux(i)+ref2-1)));    %introduces alignment
        nspk = nspk + 1;
        index(nspk) = iaux + xaux(i) -1;
        xaux0 = index(nspk);
      end
    end
    index = index(1:nspk);
   case 'both'
    xaux = find(abs(xf_detect(w_pre+2:end-w_post-2)) > thr) +w_pre+1;
    xaux0 = 0;
    index = zeros(1,length(xaux));
    for i=1:length(xaux)
      if xaux(i) >= xaux0 + ref
        [maxi iaux]=max(abs(xf(xaux(i):xaux(i)+ref2-1)));    %introduces alignment
        nspk = nspk + 1;
        index(nspk) = iaux + xaux(i) -1;
        xaux0 = index(nspk);
      end
    end
    index = index(1:nspk);
  end
end


% SPIKE STORING (with or without interpolation)
ls=w_pre+w_post;
spikes=zeros(nspk,ls+4);
xf=[xf zeros(1,w_post)];
for i=1:nspk                          %Eliminates artifacts
  if max(abs( xf(index(i)-w_pre:index(i)+w_post) )) < thrmax               
    spikes(i,:)=xf(index(i)-w_pre-1:index(i)+w_post+2);
  end
end
aux = find(spikes(:,w_pre)==0);       %erases indexes that were artifacts
spikes(aux,:)=[];
index(aux)=[];
        
switch handles.par.interpolation
 case 'n'
  spikes(:,end-1:end)=[];       %eliminates borders that were introduced for interpolation 
  spikes(:,1:2)=[];
 case 'y'
  %Does interpolation
  spikes = wvc_int_spikes(spikes,handles);   
end



return




% =====================================================
function locs = sub_rm_neighbors(pks,locs,ref)
% =====================================================

[pks, ix] = sort(pks,'descend');
locs = locs(ix);

[locs, isel] = rm_neighbors(locs,ref);
pks = pks(isel);

[locs, ix] = sort(locs,'ascend');
% pks = pks(ix);

locs = locs(:)';

return
