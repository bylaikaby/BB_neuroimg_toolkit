function Sig = bveeg2sig(VHDRFILE,varargin)
%BVEEG2SIG - Create a signal structure from the given BrainVision file.
%  Sig = BVEEG3SIG(VHDRFILE,...) creates a signal from the given
%  BrainVision file.
%
%  Supported options are :
%    eegch    : EEG channel selection.
%    obsch    : DI bits for OBS periods, as onoff_bit or [on_bit off_bit].
%    ecgch    : channel(s) for ECG/EKG.
%    datclass : data class, 'double'|single'.
%
%  EXAMPLE 
%    Sig = bveeg2sig(vhdrfile) 
%    Sig = bveeg2sig(vhdrfile,'eegch',[1:26 28],'obsch',[0 1])
%
%  NOTE :
%    - vhdr/eeg/vmrk as header/eeg-data/marker file.
%    - BrainVisionRecorder marks only either low2high or high2low edges of DIs, not both.
%      Therefore, we need two DIs (one for on-edges and inverted one for off-edges) to
%      record both on/off edges.
%
%  REQUIREMENT :
%    eeglab (readbvconf, pop_loadbv)
%
%  VERSION :
%    0.90 25.04.13 YM  pre-release
%    0.91 13.05.13 YM  support 'obsch' for obs-periods.
%    0.92 23.05.13 YM  support 'ecgsch' for ECG/EKG.
%    0.93 10.02.14 YM  work aournd for warning of 'EEGOPTION_PATH'.
%
%  See also expgeteeg readbvconf pop_loadbv

if nargin < 1,  eval(['help ' mfilename]); return;  end

% options
EEG_CHAN  = [];
OBS_BITS  = [0 1];
EKG_CHAN  = [];
DAT_CLASS = 'double';   % better to use 'double' since sum/mean returns wrong values for 'single'.
VERBOSE   = 1;

for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'eegch' 'eegchan' 'chan' 'chans'}
    EEG_CHAN = varargin{N+1};
   case {'obsch' 'obschan' 'obsbit' 'obsbits'}
    OBS_BITS = varargin{N+1};
   case {'ecgch' 'ekgch'}
    EKG_CHAN = varargin{N+1};
   case {'datclass' 'dataclass'}
    DAT_CLASS = varargin{N+1};
   case {'verbose'}
    VERBOSE = varargin{N+1};
  end
end

% this is just to avoid warning from EEGLAB, missing 'EEGOPTION_PATH' etc.
% if 'icadefs.m' is not in 'eeglab' then update the path setting.
%which('icadefs.m')
fp_eeglab = fileparts(which('eeglab.m'));
if ~any(strfind(fileparts(which('icadefs.m')),fp_eeglab)),
  CUR_PATH = path;
  path(fullfile(fp_eeglab,'functions/sigprocfunc'), CUR_PATH);
else
  CUR_PATH = '';
end
%which('icadefs.m')


[fp fr fe] = fileparts(VHDRFILE);
hdrfile = sprintf('%s%s',fr,fe);


hdr = readbvconf(fp,hdrfile);

if VERBOSE,
  fprintf(' %s: obs[%s] ',mfilename,deblank(sprintf('%d ',OBS_BITS)));
  if any(EEG_CHAN)
    fprintf('nch=%d/%d  %s...',length(EEG_CHAN),str2double(hdr.commoninfos.numberofchannels),VHDRFILE);
  else
    fprintf('nch=%d  %s...',str2double(hdr.commoninfos.numberofchannels),VHDRFILE);
  end
end


fprintf('\n');  % just for messages from  readbvconf/pop_loadbv().
eeg = pop_loadbv(fp,hdrfile);

% OK, recover the original path...
if ~isempty(CUR_PATH)
  path(CUR_PATH);
end


% cut-out the OBS period, if any
if ~isempty(OBS_BITS),
  is = NaN;  ie = NaN;
  if length(OBS_BITS) == 1,
    % on-off within the same bit
    oni = 2^OBS_BITS(1);
    for N = 1:length(eeg.event)
      if any(strncmpi(eeg.event(N).code,'Stimulus',8)),
        tmpi = sscanf(eeg.event(N).type,'%*s %d');
        if tmpi == oni,
          is = eeg.event(N).latency;
          ie = eeg.event(N).duration + is - 1;
          break;
        end
      end
    end
  else
    % on-off in separated bits
    oni  = 2^OBS_BITS(1);
    offi = 2^OBS_BITS(2);
    for N = 1:length(eeg.event)
      if any(strncmpi(eeg.event(N).code,'Stimulus',8)),
        tmpi = sscanf(eeg.event(N).type,'%*s %d');
        if tmpi == oni,
          is = eeg.event(N).latency;
        elseif tmpi == offi,
          ie = eeg.event(N).latency;
          break;
        end
      end
    end
  end
  if any(is) && any(ie),
    eeg.data = eeg.data(:,is:ie);  % as (ch,time)
  else
    error(' ERROR %s: obs-TTLs not found at bit%d/%d.\n',mfilename,OBS_BITS(1),OBS_BITS(2));
  end
end


% channel infos.
chaninfo = [];
for N = 1:length(hdr.channelinfos)
  tmpstr = strread(hdr.channelinfos{N},'%s','delimiter',',','emptyvalue',NaN);
  tmpinfo.name = tmpstr{1};
  tmpinfo.reference = tmpstr{2};
  tmpinfo.resolution = str2double(tmpstr{3});
  tmpinfo.unit = tmpstr{4};
  if isempty(chaninfo)
    chaninfo = tmpinfo;
  else
    chaninfo(end+1) = tmpinfo;
  end
end


% make 'signal' structure.
Sig.session  = '';
Sig.grpname  = '';
Sig.ExpNo    = [];
Sig.dir      = [];
Sig.chaninfo = chaninfo;
Sig.chan     = 1:size(eeg.data,1);  % eeg.data as (ch,time)
Sig.dat      = eeg.data';  % (ch,time) --> (time,ch)
%Sig.dx       = 1.0/eeg.srate;
Sig.dx       = str2double(hdr.commoninfos.samplinginterval)/1000000;  % in sec

if any(EKG_CHAN),
  Sig.ecg.chaninfo = Sig.chaninfo(EKG_CHAN);
  Sig.ecg.dat = Sig.dat(:,EKG_CHAN);
  Sig.ecg.dx  = Sig.dx;
end

if any(EEG_CHAN),
  Sig.chan     = Sig.chan(EEG_CHAN);
  Sig.chaninfo = Sig.chaninfo(EEG_CHAN);
  Sig.dat      = Sig.dat(:,EEG_CHAN);
end


switch lower(DAT_CLASS)
 case {'double'}
  Sig.dat = double(Sig.dat);
 case {'single' 'float'}
  Sig.dat = single(Sig.dat);
end



return

