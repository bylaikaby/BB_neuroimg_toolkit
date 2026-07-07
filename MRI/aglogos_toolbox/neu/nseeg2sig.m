function Sig = nseeg2sig(EEGFILE,varargin)
%NSEEG2SIG - Create a signal structure from the given NeuroScan file.
%  Sig = NSEEG3SIG(EEGFILE,...) creates a signal from the given
%  NeuroScan file.
%
%  Supported options are :
%    eegch    : EEG channel selection.
%    obsch    : DI bits for OBS periods, as onoff_bit or [on_bit off_bit].
%    ecgch    : channel(s) for ECG/EKG.
%    datclass : data class, 'double'|single'.
%
%  EXAMPLE 
%    Sig = nseeg2sig(eegfile) 
%    Sig = nseeg2sig(eegfile,'eegch',[1:26 28],'obsch',[0])
%
%  NOTE :
%
%  REQUIREMENT :
%    eeglab (pop_loadcnt, pop_loaddat)
%    nscan_xxxxx functions
%
%  VERSION :
%    0.90 10.02.14 YM  pre-release
%
%  See also expgeteeg pop_loadcnt nscan_loaddat7

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



[fp, fr, fe] = fileparts(EEGFILE);
switch lower(fe)
 case {'.dat'}
  % Curry7
  eeg = nscan_loaddat7(EEGFILE);
 case {'.cnt'}
  error('\n ERROR %s: unsupported neuroscan data (%s).\n',mfilename,fe);
  % old format
  if exist('vararg2str.m','file')
    eeg = pop_loadcnt(EEGFILE);
  else
    eeg = sub_loadcnt(EEGFILE);
  end
  fprintf('\n');  % just for messages from  readbvconf/pop_loadbv().
 otherwise
  error('\n ERROR %s: unsupported neuroscan data (%s).\n',mfilename,fe);
end


% OK, recover the original path...
if ~isempty(CUR_PATH)
  path(CUR_PATH);
end



if VERBOSE,
  fprintf(' %s: obs[%s] ',mfilename,deblank(sprintf('%d ',OBS_BITS)));
  if any(EEG_CHAN)
    fprintf('nch=%d/%d  %s...',length(EEG_CHAN),str2double(hdr.commoninfos.numberofchannels),EEGFILE);
  else
    fprintf('nch=%d  %s...',str2double(hdr.commoninfos.numberofchannels),EEGFILE);
  end
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
for N = 1:length(eeg.chanlocs)
  tmpeloc = eeg.chanlocs(N);
  tmpinfo.name       = tmpeloc.labels;
  tmpinfo.reference  = tmpeloc.ref;  % convet to a string?
  tmpinfo.resolution = [];
  tmpinfo.unit       = tmpeloc.unit;
  % neuroscan specific
  tmpinfo.scale      = tmpeloc.scale;
  tmpinfo.xyz        = [tmpinfo.X tmpinfo.Y tmpinfo.Z];
  tmpinfo.impedance  = [];
  
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




% =======================================================
% a modified version pop_loadcnt() of EEGLAB.
function EEG = sub_loadcnt(fullFileName)
% =======================================================

r = loadcnt( fullFileName);
% Check to see if data is in memory or in a file.
EEG.data            = r.data;
EEG.comments        = [ 'Original file: ' fullFileName ];
EEG.setname 		= 'CNT file';
EEG.nbchan          = r.header.nchannels;

% inport events
% -------------
I = 1:length(r.event);
if ~isempty(I)
    EEG.event(1:length(I),1) = [ r.event(I).stimtype ];
    EEG.event(1:length(I),2) = [ r.event(I).offset ]+1;
    EEG.event = eeg_eventformat (EEG.event, 'struct', { 'type' 'latency' });
end;

% modified by Andreas Widmann  2005/05/12  14:15:00
try, % this piece of code makes the function crash sometimes - Arnaud Delorme 2006/04/27
    temp = find([r.event.accept_ev1] == 14 | [r.event.accept_ev1] == 11); % 14: Discontinuity, 11: DC reset
    if ~isempty(temp)
        disp('pop_loadcnt note: event field ''type'' set to ''boundary'' for data discontinuities');
        for index = 1:length(temp)
            EEG.event(temp(index)).type = 'boundary';
        end;
    end
catch, end;
% end modification

% process keyboard entries
% ------------------------
if ~isempty(findstr('keystroke', lower(options)))
    tmpkbd  = [ r.event(I).keyboard ];
    tmpkbd2 = [ r.event(I).keypad_accept ];
    for index = 1:length(EEG.event)
        if EEG.event(index).type == 0
            if r.event(index).keypad_accept,
                EEG.event(index).type = [ 'keypad' num2str(r.event(index).keypad_accept) ];
            else
                EEG.event(index).type = [ 'keyboard' num2str(r.event(index).keyboard) ];
            end;
        end;
    end;
else
    % removeing keystroke events
    % --------------------------
    rmind = [];
    for index = 1:length(EEG.event)
        if EEG.event(index).type == 0
            rmind = [rmind index];
        end;
    end;
    if ~isempty(rmind)
        fprintf('Ignoring %d keystroke events\n', length(rmind));
        EEG.event(rmind) = [];
    end;
end;

% import channel locations (Neuroscan coordinates are not wrong)
% ------------------------
%x            = celltomat( { r.electloc.x_coord } );
%y            = celltomat( { r.electloc.y_coord } );
for index = 1:length(r.electloc)
    names{index} = deblank(char(r.electloc(index).lab'));
    if size(names{index},1) > size(names{index},2), names{index} = names{index}'; end;
end;
EEG.chanlocs  = struct('labels', names);
%EEG.chanlocs = readneurolocs( { names x y } );
%disp('WARNING: Electrode locations imported from CNT files may not reflect true locations');

% Check to see if data is in a file or in memory
% If in memory, leave alone
% If in a file, use values set in loadcnt.m for nbchan and pnts.
EEG.srate    = r.header.rate;
EEG.nbchan   = size(EEG.data,1) ;
EEG.nbchan   = r.header.nchannels ;
% EEG.nbchan       = size(EEG.data,1);
EEG.trials   = 1;
EEG.pnts     = r.ldnsamples ;
%size(EEG.data,2)

%EEG.pnts     = r.header.pnts 
%size(EEG.data,2);
EEG          = eeg_checkset(EEG, 'eventconsistency');
EEG          = eeg_checkset(EEG, 'makeur');

if exist('eeg_checkset.m','file'),
  if ((size(EEG.data,1) ~= EEG.nbchan) && (size(EEG.data,2) ~= EEG.pnts))
    % Assume a data file
    EEG      = eeg_checkset(EEG, 'loaddata');
  end
end

return
