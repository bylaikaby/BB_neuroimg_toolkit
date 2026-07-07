function oSig = siggetrf(iSig,ithreshold,offsetT,NoAvg,method)
%SIGGETRF - Compute site-RF structure by means of reverse correlation.
% OSIG = SIGGETRF(iSig,ithreshold,offsetT,imgnorm,NoAvg,method) reads the
% bandpass signals (e.g. Lfp, Mua) created with getlfpmuaflt
% and determines the times at which the signal passes through a
% particular activity value determined by the user. It then uses this time
% information to determine the vide frames that were presented at
% those times.
%
% The process requires precise alignment of vide frames with the
% neural data acquisition. The alignment is done by digitizing the
% output of an LED that signifies the onset of a video frame.
% The RF structures are scaled to 0 - 255 (ie. UINT8) by channel basis.
% To reconstruct original values, use oSig.datmax, oSig.datmin etc.
%
% ISIG is the LFP/MUA/SUA Signals
% ITHRESHOLD is the activity threshold at which a frame is selected
% for averaging.
% OFFSETT is the time before and after the trigger frame
% NoAvg is the minimum number of frames to average
% method = "range" "baseline" etc.
%
% VSig Structure:
%    session: 'c98nm1'
%    grpname: 'movie1'
%      ExpNo: 1
%        dir: [1x1 struct]
%        dsp: [1x1 struct]
%        grp: [1x1 struct]
%        usr: {}
%        evt: [1x1 struct]
%        stm: [1x1 struct]
%       chan: [1...]
%         dx: 1
%      movie: [1x1 struct]
%      range: [10 120]
%        vid: [1x1 struct]
%        dat: [5-D uint8]
%        std: [5-D uint8]
%
% SEEALSO getdir.m, utils/mex_avi, sesgetrf.m
%
% VERSION//DATE/AUTHOR/NOTES
%  0.90 14.09.03  YM
%  0.91 15.09.03  YM,  computed data is stored as UINT8.
%
  
% DECREASE THRESHOLD BY THIS AMOUNT IF NUMBER OF AVERAGES IS NOT SUFFICIENT.
THR_STEP = 12;
BASE_STD = 0.33;

% A GOOD SESSION TO USE FOR DEBUGGING !!
if ~nargin,
  SESSION = 'c98nm1';
  ExpNo = 1;
  NoAvg = 2000;
  Ses = goto(SESSION);
  iSig = sesgetsig( Ses, ExpNo,'Lfp');
  ithreshold = 3;
  offsetT = 1; % <-- positive lag???, 08.05.05 YM
  method = 'range';
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Offset ultimately will be 10:0.25:10 to get a good movie showing
% the evolution of the site-RF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if length(offsetT) == 1,
  dx = 0;
else
  dx = mean(diff(offsetT));
  offsetT = reshape(offsetT,1,length(offsetT));
end

if nargin < 4,  NoAvg = 1500;  end;
if nargin < 5,  method = 'range'; end;

mvdata				= iSig.movie;

oSig				= rmfield(iSig,{'tosdu','dat'});
oSig.vid.nx			= mvdata.nx;
oSig.vid.ny			= mvdata.ny;
oSig.vid.ns			= 3;
oSig.vid.nt			= length(offsetT);
oSig.vid.t			= offsetT;
oSig.vid.ithreshold	= ithreshold;
oSig.vid.threshold	= [];
oSig.vid.rIndex		= [];
oSig.dx				= dx;
oSig.dsp.func		= 'dsprf';

dirs = getdirs;
moviefile = strcat(dirs.movdir,mvdata.name);
stimont = iSig.stm.t{1}(2);
stimofft = iSig.stm.t{1}(3);

thrStep = ithreshold/100;

DEBUG = 0;
% PROCESS EACH CHANNEL
for chan = size(iSig.dat,2):-1:1,
  nframes = []; uframes = [];
  imgmean = [];	imgstd  = [];
  threshold(chan) = ithreshold;
  
  tmpdat = squeeze(iSig.dat(:,chan));
  iSig.dat(:,chan)=[];		% By doing this we minimize memory problems
  pack;						% just to be sure... MATLAB free() sucks

  son = round(stimont/iSig.dx);
  sof = round(stimofft/iSig.dx);

  if DEBUG,
	savtmpdat = tmpdat;
  end;
  
  tmpdat = tmpdat(son:sof);
  switch lower(method),
   case { 'range' }
	rIndex = find(tmpdat>threshold(chan) & tmpdat<threshold(chan)+THR_STEP);

	if length(rIndex) > NoAvg,
	  tmpidx = randperm(length(rIndex));
	  rIndex = rIndex(tmpidx);
	  rIndex = sort(rIndex(1:NoAvg));
	elseif length(rIndex)<NoAvg,
	  while(length(rIndex)<NoAvg),
		threshold(chan) = threshold(chan) - thrStep;
		if threshold(chan) < 0.5, % LOWER LIMIT FOR SD
		  break;
		end;
		rIndex = find(tmpdat>threshold(chan) & tmpdat<threshold(chan)+THR_STEP);
	  end;
	  if length(rIndex)>NoAvg,
		rIndex = rIndex(1:NoAvg);
	  end;
	end;

   case { 'baseline' }
	rIndex = find(abs(tmpdat) < BASE_STD);
	if isempty(rIndex),
	  rIndex = find(abs(tmpdat) < 2*BASE_STD);
	end;
	if isempty(rIndex),
	  fprintf('siggetrf: cannot find any indices within 0.66SD\n');
	  keyboard;
	end;
	  
	if length(rIndex) > NoAvg,
	  tmpidx = randperm(length(rIndex));
	  rIndex = rIndex(tmpidx);
	  rIndex = sort(rIndex(1:NoAvg));
	end;

   case { 'above_all' }
    rIndex = find(tmpdat > threshold(chan));
   
   case { 'edge_only' }
	rIndex = find(tmpdat > threshold(chan) & [tmpdat(2:end); ...
					tmpdat(end)] <= threshold(chan));
	  
	while(length(rIndex)<NoAvg),
	  threshold(chan) = threshold(chan) - thrStep;
	  rIndex = find(tmpdat > threshold(chan) & [tmpdat(2:end); ...
					tmpdat(end)] <= threshold(chan));
	  
	end;
   
   case { 'positive_slope' }
    rIndex = find(tmpdat > threshold(chan) & [diff(tmpdat);0] > 0);
  end

  rIndex = rIndex + son - 1;
  
  if DEBUG,
	plot([0:length(savtmpdat)-1]*iSig.dx,savtmpdat,'k');
	hold on;
	plot(rIndex*iSig.dx,savtmpdat(rIndex),'r.','markersize',6);
	xlabel('Time in seconds');
	keyboard
  end;
  
  oSig.vid.rIndex{chan} = rIndex;
  rIndex = rIndex * iSig.dx;   % in seconds

  for k = 1:length(offsetT),

    % converts in points of 'frames'
    rIndex2 = ceil((rIndex + offsetT(k))/mvdata.dx);
    frames = mvdata.dat(rIndex2);
    if k==1,
      fprintf(' %s: <%s(%d) %s> ch%02d: ith=%.2f, th=%.2f, nfr=%d, ufr=%d: ',...
              gettimestring, iSig.grpname, iSig.ExpNo, ...
			  iSig.dir.dname,chan, ithreshold, threshold(chan),...
			  length(frames),length(unique(frames(:))));
    else
      fprintf('.');
    end
      
    nframes(k) = length(frames);
    uframes(k) = length(unique(frames(:)));
    [imgmean(k,:,:,:), imgstd(k,:,:,:)] = vavi_mean(moviefile,frames);

  end
  fprintf('. done.\n');

  % convert 'double' to 'uint8';
  % data must not be pre-allocated at all, even as empty arrays.
  [imgmean, minv, maxv]     = subDouble2UInt8(imgmean);
  oSig.dat(:,:,:,:,chan)    = imgmean;
  oSig.vid.datmin(chan)     = minv;
  oSig.vid.datmax(chan)     = maxv;

  [imgstd, minv, maxv]      = subDouble2UInt8(imgstd);
  oSig.std(:,:,:,:,chan)    = imgstd;
  oSig.vid.method           = method;
  oSig.vid.threshold        = threshold;
  oSig.vid.stdmin(chan)     = minv;
  oSig.vid.stdmax(chan)     = maxv;
  oSig.vid.respTime{chan}   = rIndex;
  oSig.vid.nframes{chan}    = nframes;
  oSig.vid.uframes{chan}    = uframes;
end

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [img, minv, maxv] = subDouble2UInt8(img)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% convert precision of data
minv = min(img(:));
maxv = max(img(:));
diffv = maxv - minv;
% scaled 0 to 255;
img = (img - minv)/diffv*255.;
img = uint8(img);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [img, minv, maxv] = subDouble2UInt16(img)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% convert precision of data
minv = min(img(:));
maxv = max(img(:));
diffv = maxv - minv;
% scaled 0 to 65535;
img = (img - minv)/diffv*65535.;
img = uint16(img);

