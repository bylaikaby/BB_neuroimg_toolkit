function waveclus_GetSpikes(Ses,GrpName,varargin)
%WAVECLUS_GETSPIKES - Extract spike candidates with wave_clus.
%  WAVECLUS_GETSPIKES(Ses,GrpName,...) extracts spike candidates with wave_clus.
%
%  Analysis parameters (ANAP) can be in the session file.
%  For waveclus_GetSpikes()/extract.
%    ANAP.waveclus.getspikes.detection       = 'both';     % type of threshold, pos|neg|both
%    ANAP.waveclus.getspikes.stdmin          = 5.00;       % minimum threshold (def.  5)
%    ANAP.waveclus.getspikes.stdmax          = 50;         % maximum threshold (def. 50)
%  For waveclus_GetSpikes()/spike-alignment.
%    ANAP.waveclus.spkalign.detection        = 'both';      % type of threshold, pos|neg|both
%
%  EXAMPLE :
%    waveclus2spk('rat10043','spont')  % it takes ~53min (7files,8chans)
%
%  EXAMPLE :
%    waveclus_GetSpikes('rat10043','spont')
%    waveclus_DoClustering('rat10043','spont')
%    waveclus2spk('rat10043','spont','GetSpikes',0,'DoClustering',0);
%
%  NOTE :
%    Since I use findpeaks() in wvc_amp_detect() to extract spike candidates, 
%    it would be fine without aligning.
%
%  NOTE (detection/align):
%    When findpeaks() used, there should be no need to align spikes...
%
%  REQUIREMENTS :
%    wave_clus 2.0:  http://www.vis.caltech.edu/~rodri/Wave_clus/Wave_clus_home.htm
%
%  VERSION :
%    0.90 23.03.14 YM  pre-release
%
%  See also waveclus2spk waveclus_DoClustering
%           wvc_filename wvc_amp_detect wvc_int_spikes

if nargin < 2,  eval(['help ' mfilename]); return;  end

% PROGRAM Get_spikes.
% Gets spikes from all files in Files.txt.
% Saves spikes and spike times.

handles.par.w_pre = NaN;                    %number of pre-event data points stored (def. 20)
handles.par.w_post = NaN;                   %number of post-event data points stored (def. 44)
% handles.par.detection = 'pos';            %type of threshold
% handles.par.detection = 'neg';              %type of threshold
handles.par.detection = 'both';           %type of threshold
handles.par.stdmin = 5.00;                  %minimum threshold (def. 5)
handles.par.stdmax = 50;                    %maximum threshold
handles.par.interpolation = 'y';            %interpolation for alignment
handles.par.int_factor = 2;                 %interpolation factor (def. 2)
handles.par.detect_fmin = 300;              %high pass filter for detection (def. 300)
handles.par.detect_fmax = 3000;             %low pass filter for detection (def. 3000)
handles.par.sort_fmin = 300;                %high pass filter for sorting (def. 300)
handles.par.sort_fmax = 3000;               %low pass filter for sorting (def. 3000)
handles.par.segments = 1;                   %nr. of segments in which the data is cutted.
handles.par.sr = 24000;                     %sampling frequency, in Hz (default 24000).
min_ref_per = 1.5;                          %detector dead time (in ms)
handles.par.ref = floor(min_ref_per ...
    *handles.par.sr/1000);                  %number of counts corresponding to the dead time


% Get basic info --------------------------------
Ses = goto(Ses);
grp = getgrp(Ses,GrpName);
EXPS = sort(grp.exps);
anap = getanap(Ses,grp);
if isfield(anap,'waveclus') && isfield(anap.waveclus,'getspikes')
  handles.par = sctmerge(handles.par,anap.waveclus.getspikes);
end


% OPTIOS ----------------------------------------
CHANS = [];
USE_FINDPEAKS = 1;
DO_ALIGN = 1-USE_FINDPEAKS;  % may not need when findpeaks=1

for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'chans'}
    CHANS = varargin{N+1};
   case {'usefindpeaks' 'use_findpeaks' 'findpeaks'}
    USE_FINDPEAKS = varargin{N+1};
   case {'align' 'do_align' 'doalign'}
    DO_ALIGN = varargin{N+1};
  end
end



% % for debug...
% CHANS = 1:2;
% EXPS = EXPS(1:5);


if isempty(CHANS)
  CLN = siginfo(Ses,EXPS(1),'Cln');  % just read info (no .dat)
  CHANS = 1:CLN.datsize(2);
end

fprintf('%s %s: %s %s (nfiles=%d nchans=%d)\n',...
        datestr(now,'HH:MM:SS'),mfilename,Ses.name,grp.name,length(EXPS),length(CHANS));
fprintf(' getspikes: detect=%s thr=%g/%g ref=%gms findpeaks=%d align=%d\n',...
        handles.par.detection,handles.par.stdmin,handles.par.stdmax,min_ref_per,...
        USE_FINDPEAKS,DO_ALIGN);



toffs = 0;
for iExp = 1:length(EXPS)
  
  t0 = tic;
  fprintf(' %3d/%d Exp=%3d: loading Cln.',iExp,length(EXPS),EXPS(iExp));
  CLN = sigload(Ses,EXPS(iExp),'Cln');
  
  if isempty(CHANS),
    CHANS = 1:size(CLN.dat,2);
  end
  
  DX = CLN.dxorg;  % use the original clock
  
  
  %sampling frequency, in Hz
  handles.par.sr = 1/DX;  
  %number of counts corresponding to the dead time
  handles.par.ref = floor(min_ref_per*handles.par.sr/1000);  

  %number of pre-event data points stored (def. 20)
  if ~any(handles.par.w_pre)
    handles.par.w_pre = round(0.001/DX);
  end
  %number of post-event data points stored (def. 44)
  if ~any(handles.par.w_post)
    handles.par.w_post = round(0.002/DX);
  end
  
  %interpolation factor (def. 2)
  handles.par.int_factor = round(40000*DX);  % ~40kHz

  par.getspikes = handles.par;
  
  
  fprintf(' amp_detect');
  for iCh = 1:length(CHANS)
    if mod(iCh,10) == 0,
      fprintf('%d',iCh);
    else
      fprintf('.');
    end
    
    ChanNo = CHANS(iCh);

    spkfile = wvc_filename(Ses,grp,ChanNo,'spikes');
    
    if iExp == 1,
      index = [];
      spikes = [];
    else
      load(spkfile,'index','spikes');
    end
    
    x = CLN.dat(:,ChanNo)';
    [tmpspikes, tmpthr, tmpindex] = wvc_amp_detect(x,handles,'findpeaks',USE_FINDPEAKS);
    
    tmpindex = tmpindex*DX*1000 + toffs;  % in msec
    
    
    index  = [index   tmpindex];
    spikes = [spikes; tmpspikes];
    
    fp = fileparts(spkfile);
    if ~isempty(fp) && ~exist(fp,'dir')
      mkdir(fp);
    end
    
    save(spkfile,'index','spikes','par');      %saves Sc files
  end
  
  toffs = toffs + size(CLN.dat,1)*DX*1000;   % in msec
  
  fprintf(' done (%gs).\n',toc(t0));
  
end


if ~any(DO_ALIGN),  return;  end


clear handles;
handles.par.w_pre=20;                       %number of pre-event data points stored
handles.par.w_post=44;                      %number of post-event data points stored
handles.par.detection = 'neg';              %type of threshold
handles.par.interpolation = 'y';            %interpolation for alignment
handles.par.int_factor = 2;                 %interpolation factor 
handles.par.sr = 24000;                     %sampling frequency, in Hz.
handles.par.alignment_window = 10;          %number of sample points around the maximum 


% update to match with spike detection
handles.par.w_pre      = par.getspikes.w_pre;
handles.par.w_post     = par.getspikes.w_post;
handles.par.int_factor = par.getspikes.int_factor;
handles.par.sr         = par.getspikes.sr;
handles.par.alignment_window = round(0.0005*handles.par.sr); % 0.5ms

handles.par.detection  = par.getspikes.detection;
if isfield(anap,'waveclus') && isfield(anap.waveclus,'getspikes')
  if isfield(anap.waveclus.getspikes,'align_detection'),
    handles.par.detection = anap.waveclus.getspikes.align_detection;
  end
end


if strcmpi(handles.par.detection,'none'),  return;  end



% keep parameters to save
par.spkalign = handles.par;



w_pre = handles.par.w_pre;
w_post = handles.par.w_post;
align_window = handles.par.alignment_window;
ls = w_pre + w_post;


t0 = tic;
fprintf(' align (nch=%d,detect=%s,win=%gms) : ',length(CHANS),...
        handles.par.detection,handles.par.alignment_window/handles.par.sr*1000);
for iCh = 1:length(CHANS)
  if mod(iCh,10) == 0,
    fprintf('%d',iCh);
  else
    fprintf('.');
  end
  
  ChanNo = CHANS(iCh);
  
  spkfile = wvc_filename(Ses,grp,ChanNo,'spikes');
  load(spkfile,'index','spikes');
  

  % make "spikes" wider
  spikes1 = zeros(size(spikes,1),ls+(2*align_window)+4);
  if (size(spikes,2)< (ls + align_window)+2)
    diff_size = ls+align_window+2-size(spikes,2);
    spikes1(:,1:align_window+2) = -spikes(:,align_window+2:-1:1);
    spikes1(:,1+align_window:align_window+size(spikes,2)) = spikes;
    spikes1(:,1+align_window+size(spikes,2)+2:end) = -spikes(:,end:-1:end-diff_size+1);
  else
    spikes1(:,1:align_window+2) = -spikes(:,align_window:-1:1);
    spikes1(:,1+align_window:(2*align_window+ls)) = spikes(1:align_window+ls);
  end

  % Introduces first alignment
  correct_times = zeros(size(spikes,1),1);
  spikes2 = zeros(size(spikes,1),ls+4);

  % for iSpk=1:size(spikes1,1)
  %   if strcmp(handles.par.detection, 'pos')
  %     [maxi iaux] = max(spikes1(iSpk,w_pre+2:w_pre+2*align_window+1));    %introduces alignment
  %   else 
  %     [mini iaux] = min(spikes1(iSpk,w_pre+2:w_pre+2*align_window+1));    %introduces alignment
  %   end;
  %   if iaux > 1
  %     spikes2(iSpk,:) = spikes1(iSpk,iaux-1:iaux+ls+2);
  %   else
  %     spikes2(iSpk,:) = spikes1(iSpk,iaux:iaux+ls+3);
  %   end
  %   correct_times(iSpk) = (iaux+w_pre-align_window+1)*1/handles.par.sr;  %corrects spike-times.
  % end
  switch lower(handles.par.detection)
   case {'pos'}
    SPIKES_DET =  spikes1;
   case {'neg'}
    SPIKES_DET = -spikes1;
   case {'both'}
    SPIKES_DET = abs(spikes1);
   otherwise
    error(' ERROR %s: ''%s'' not supported.\n',mfilename,handles.par.detection);
  end
  for iSpk=1:size(spikes1,1)
    [maxi iaux] = max(SPIKES_DET(iSpk,w_pre+2:w_pre+2*align_window+1));    %introduces alignment
    if iaux > 1
      spikes2(iSpk,:) = spikes1(iSpk,iaux-1:iaux+ls+2);
    else
      spikes2(iSpk,:) = spikes1(iSpk,iaux:iaux+ls+3);
    end
    correct_times(iSpk) = (iaux+w_pre-align_window+1)*1/handles.par.sr;  %corrects spike-times.
  end
  clear SPIKES_DET;
  
  spikes = spikes2;
    
  switch handles.par.interpolation
   case 'n'
    spikes(:,end-1:end)=[];       %eliminates borders that were introduced for interpolation 
    spikes(:,1:2)=[];
   case 'y'
    %Does interpolation
    spikes = wvc_int_spikes(spikes,handles);   
  end;
  
  save(spkfile,'index','spikes','correct_times','par');      %saves Sc files
end


fprintf(' done (%gs).\n',toc(t0));
