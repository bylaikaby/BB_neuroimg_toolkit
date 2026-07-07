function [EEG, DAP, RS3, CEO] = nscan_loaddat7(DATFILE,varargin)
%NSCAN_LOADDAT7 - Load Curry7(neuroscan) data.
%  EEG = NSCAN_LOADDAT7(DATFILE,...) loads Curry7(neuroscan) data.
%  [EEG, DAP, RS3, CEO] = NSCAN_LOADDAT7(DATFILE,...) returns additional
%  parameters of corresponding .dap/rs3/ceo files.
%
%  OPTIONS :
%    'samples'    : sample selection as [start end] in sample-points
%    'channels'   : channel selection as a numeric vector
%    'invertstim' : 0|1, invert stimulus bits
%    'invertresp' : 0|1, invert response bits
%
%  EXAMPLE :
%    [eeg dap rs3 ceo] = nscan_loaddat7('D:/Temp/Acquire 01.dat');
%
%  NOTE :
%   The programs are tested in our settings (Curry7.0.6, SynAmpsRT, MATLAB2011b).
%   In other environment, one may need to update/adapt the codes.
%    .dap : parameters in ascii
%    .dat : plain binary
%    .rs3 : electrode info? in ascii
%    .ceo : event info? in ascii
%
%  VERSION :
%    0.90 23.01.14 YM  pre-release, MPI Tuebingen
%    0.91 10.02.14 YM  clean-up
%
%  See also nscan_loadpar7

%  COPYRIGHT (C) 2014 Yusuke Murayama,  Max Planck Institute for Biological Cybernetics
%  Simplified BSD License, see readme.txt for detail.


if nargin < 1, eval(['help ' mfilename]); return;  end


% optional arguments
iPERIOD    = [];
iCHANS     = [];
InvertStim = 0;
InvertResp = 1;
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'period' 'srange' 'sample' 'samples'}
    iPERIOD = varargin{N+1};
   case {'chans' 'channels' 'chan' 'channel'}
    iCHANS  = varargin{N+1};
   case {'invertstim' 'invert_stim' 'invert stimulus' 'invertstimulus'}
    InvertStim = any(varargin{N+1});
   case {'invertresp' 'invert_resp' 'invert response' 'invertresponse'}
    InvertResp = any(varargin{N+1});
  end
end


if ~exist(DATFILE,'file'),
  error(' ERROR %s : ''%s'' not found.\n',mfilename,DATFILE);
end

[fp fr fe] = fileparts(DATFILE);
DAPFILE = fullfile(fp,[fr '.dap']);
RS3FILE = fullfile(fp,[fr '.rs3']);
CEOFILE = fullfile(fp,[fr '.ceo']);


DAP = [];  RS3 = [];  CEO = [];
%if exist(DAPFILE,'file'),
  DAP = nscan_loadpar7(DAPFILE);
%end
%if exist(RS3FILE,'file'),
  RS3 = nscan_loadpar7(RS3FILE);
%end
if exist(CEOFILE,'file'),
  CEO = nscan_loadpar7(CEOFILE);
end



% byte order
switch lower(DAP.DATA_PARAMETERS.DataByteOrder)
 case {'intel'}
  ByteOrder = 'ieee-le';  % little endian
 otherwise
  fprintf(' ERROR %s : unknown DataByteOrder ''%s''.\n',...
          mfilename,DAP.DATA_PARAMETERS.DataByteOrder);
  keyboard
end

% word-type
switch lower(DAP.DATA_PARAMETERS.DataFormat)
 case {'float'}
  WordType = 'single=>single';
 otherwise
  fprintf(' ERROR %s : unknown DataFormat ''%s''.\n',...
          mfilename,DAP.DATA_PARAMETERS.DataFormat);
  keyboard
end

nsamples  = DAP.DATA_PARAMETERS.NumSamples;
nchannels = DAP.DATA_PARAMETERS.NumChannels;

fid = fopen(DATFILE,'rb',ByteOrder);
data = fread(fid,inf,WordType);
fclose(fid);

if strcmpi(DAP.DATA_PARAMETERS.DataSampOrder,'SAMP')
  data = reshape(data,[nchannels,nsamples]);
else
  data = resahpe(data,[nsamples,nchannels]);
  data = data';  % to be compatible...
end


% OK, now let's deal with triggers, assuming as the last channel...
ChanLabels = RS3.LABELS.List(:)';
ChanLabels = cat(2,ChanLabels,RS3.LABELS_OTHERS.List(:)');
if strcmpi(ChanLabels{end},'Trigger'),
  switch lower(DAP.DATA_PARAMETERS.DataFormat)
   case {'float'}
    trig = typecast(data(end,:),'uint8');
    trig = reshape(trig,[4 nsamples]);
    stimbits = trig(2,:);
    respbits = trig(3,:);
    

    %tmpbits = typecast(data(end,:),'uint32');
    %sbits   = bitand(tmpbits,uint32(1)));
    %tmppat  = bitand(bitshift(tmpbits,-8),uint32(1));

    % fprintf('0x%X  \n',typecast(data(end,1),'uint32'));
    % fprintf('0x%X  \n',typecast(data(end,1),'uint16'));
    % fprintf('0x%X  \n',typecast(data(end,1),'uint8'));
 
    nchannels = nchannels - 1;
    data(end,:) = [];
    clear trig;
    
   otherwise
    fprintf(' ERROR %s : unknown DataFormat ''%s''.\n',...
            mfilename,DAP.DATA_PARAMETERS.DataFormat);
    keyboard
  end
end


chans = 1:nchannels;


% make a EEG structure like EEGLAB
try
  EEG = eeg_emptyset;
catch
end

EEG.filename = sprintf('%s%s',fr,fe);
EEG.filepath = fp;
EEG.comments = DAP.DATA_PARAMETERS.Comments;
EEG.srate = 1000000 / DAP.DATA_PARAMETERS.SampleTimeUsec;
EEG.nbchan = nchannels;
for chan = 1:length(chans)
  EEG.chanlocs(chan).labels = ChanLabels{chan};
  EEG.chanlocs(chan).ref    = 'GND';
  EEG.chanlocs(chan).scale  = 1;
  %EEG.chanlocs(chan).unit   = DAP.DEVICE_PARAMETERS.DataUnit;
  if isfield(RS3,'SENSORS') && isfield(RS3.SENSORS,'List') && size(RS3.SENSORS,1) >= chan
    % EEG.chanlocs(chan).sph_radius = ;
    % EEG.chanlocs(chan).sph_theta  = ;
    % EEG.chanlocs(chan).sph_phi    = ;
    EEG.chanlocs(chan).X = RS3.SENSORS.List(chan,1);
    EEG.chanlocs(chan).Y = RS3.SENSORS.List(chan,2);
    EEG.chanlocs(chan).Z = RS3.SENSORS.List(chan,3);
  end
end
EEG.pnts = nsamples;
EEG.data = data;
EEG.trials = 1;
EEG.ximn   = 0;
EEG.xmax   = (EEG.pnts - 1) / EEG.srate;
EEG.times  = (0:EEG.pnts-1) / EEG.srate;

EEG.ref = 'GND';


% Event Makers
EEG.event = [];
if isfield(CEO,'NUMBER_LIST') && isfield(CEO.NUMBER_LIST,'List')
  % elist = CEO.NUMBER_LIST.List;
  % for N = 1:size(elist,1)
  %   is = elist(N,5) + 1;  % +1 for matlab indexing
  %   ie = elist(N,6);      % no need for +1
    
  %   tmpevt.latency  = is;
  %   tmpevt.duration = ie - is + 1;
  %   tmpevt.channel  = elist(N,3);
  %   tmpevt.type     = '';
  %   tmpevt.code     = '';
  %   if tmpevt.duration <= 0,  tmpevt.duration = NaN;  end
  %   EEG.event = cat(2,EEG.event,tmpevt);
  % end
  
  % stimulus bits
  for iBit = 0:7
    bitevt = sub_bitevt(iBit,stimbits,'Stimulus',InvertStim);
    EEG.event = cat(2,EEG.event,bitevt);
  end
  % response bits
  for iBit = 0:7,
    bitevt = sub_bitevt(iBit,respbits,'Response',InvertResp);
    EEG.event = cat(2,EEG.event,bitevt);
  end
  % sort by the latency
  if length(EEG.event) > 1,
    tmplat = [EEG.event.latency];
    [tmplat ix] = sort(tmplat);
    EEG.event = EEG.event(ix);
  end
end


% channel selection
if any(iCHANS)
  EEG.data = EEG.data(iCHANS,:);
  EEG.chanlocs = EEG.chanlocs(iCHANS);
end

% period selection
if any(iPERIOD) && length(iPERIOD) == 2,
  if iPERIOD(1) < 1 || iPERIOD(2) > EEG.pnts
    error(' ERROR %s: period selection is out of range\n', mfilename);
  end
  
  EEG.pnts = iPERIOD(2) - iPERIOD(1) + 1;
  EEG.data = EEG.data(:, iPERIOD(1):iPERIOD(2));
  for N = 1:numel(EEG.event)
    EEG.event(N).latency = EEG.event(N).latency - iPERIOD(1);
  end
  % Remove unreferenced events
  if ~isempty(EEG.event)
    tmpv = [EEG.event.latency];
    EEG.event = EEG.event(tmpv >= 1 & tmpv <= EEG.pnts);
    clear tmpv;
  end
  
end


% Convert to EEG.data to double for MATLAB < R14
if str2double(version('-release')) < 14
  EEG.data = double(EEG.data);
end



return



% =========================================================
function bitevt = sub_bitevt(iBit,databits,codestr,DoInvert)
% =========================================================
bitevt = [];

tmppat = int32(bitand(bitshift(databits,-iBit),uint8(1)));
if any(DoInvert)
  tmppat = 1 - tmppat;
end
tmpdif = diff(tmppat);
l2h = find(tmpdif > 0) + 1;
h2l = find(tmpdif < 0) + 1;
if isempty(l2h) || isempty(h2l), return;  end
%l2h = l2h(l2h < h2l(end));
h2l = h2l(h2l > l2h(1));
if isempty(l2h) || isempty(h2l), return;  end
h2l(end+1) = NaN;  % just to prevent errors
  
tmpevt.latency  = NaN;
tmpevt.duration = NaN;
tmpevt.channel  = iBit;
tmpevt.type     = '';
tmpevt.code     = codestr;

% keep as similar as "BrainVision"
if ~isempty(codestr)
  tmpevt.type   = sprintf('%s %d',codestr(1),2^iBit);
end

for K = 1:length(l2h),
  tmpevt.latency  = l2h(K);
  tmpevt.duration = h2l(K) - l2h(K);
  bitevt = cat(2,bitevt,tmpevt);
end

return
