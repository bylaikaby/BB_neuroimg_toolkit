function RET = test_smrfile()

SMRFILE = 'D:\DataNeuro\rat.1392\R139.2_111214_01.smr';

CH = {'PFC','LC','V1',...
    'E2','E12','E31','E22','E5','E20','E28','E13','E8','E15','E25','E19','E10',...
    'D1','D2','D3','D4','D5','D6','D7','D8','D9','D10','D11','D12','D13','D14','D15','D16'};

fprintf('mex:');
for N=1:10,
  fprintf('.');
  tic;
  for K = 1:length(CH),
    vals = smr_readwav(SMRFILE,CH{K},'win',[0 10],'son2',0);
  end
  elapsed(N) = toc;
end
fprintf('\n');


fprintf('son2: ');
for N=1:10,
  fprintf('.');
  tic;
  for K = 1:length(CH),
    vals2 = smr_readwav(SMRFILE,CH{K},'win',[0 10],'son2',1);
  end
  elapsed2(N) = toc;
end
fprintf('\n');




fprintf('mex:  %g+-%gs\n',mean(elapsed),std(elapsed));
fprintf('son2: %g+-%gs\n',mean(elapsed2),std(elapsed2));


% mex:  6.29056+-0.541545s
% son2: 124.654+-9.10841s

% mex:  5.79216+-0.903181s
% son2: 139.913+-8.69321s

% mex:  6.69521+-0.759499s
% son2: 134.324+-12.4873s


return


% tic
% % only for win32, virtually useless...
% chan=15-1;  % -1 for C-style indexing
% SONLoad();
% fh = SONOpenOldFile(SMRFILE,1);  % 1=ReadOnly
% sTime = 1;
% eTime = SONChanMaxTime(fh,chan);
% [npoints, bTime, data] = SONGetADCData(fh, chan, 0, sTime, eTime);
% SONCloseFile(fh);
% toc


% chan=15-1;  % -1 for C-style indexing
% CEDS64LoadLib(fileparts(which('CEDS64LoadLib')));  % fails in win64....
% fh = CEDS64OpenFile(SMRFILE,1);  % 1=ReadOnly

% CEDS64Close(fh);



tic
fid = fopen(SMRFILE,'r','ieee-le');
header = sub_readheader(fid);
chlist = sub_readchlist(fid,header);
for N=length(chlist):-1:1,
  chblck(N) = sub_blockheader(fid,header,chlist(N));
end
fclose(fid);
toc

RET.header = header;
RET.chlist = chlist;
RET.chblck = chblck;

tic
fid = fopen(SMRFILE,'r','ieee-le');
tmph = SONFileHeader(fid);
tmpc = SONChanList(fid);
for N=length(tmpc):-1:1,
  tmpb{N} = SONGetBlockHeaders(fid,tmpc(N).number);
end
fclose(fid);
toc



isequal(tmpb{end}(1,:),chblck(end).seek)

keyboard

return



% ----------------------------------------------------------
function HEADER = sub_readheader(fid)
% ----------------------------------------------------------

fseek(fid,0,'bof');

HEADER.systemID         = fread(fid, 1,'int16');
%HEADER.copyright        = fscanf(fid,'%c',10);
%HEADER.creator          = fscanf(fid,'%c',8);
HEADER.copyright        = fread(fid,10,'char=>char')';
HEADER.creator          = fread(fid, 8,'char=>char')';
HEADER.usPerTime        = fread(fid, 1,'uint16');
HEADER.timePerADC       = fread(fid, 1,'uint16');
HEADER.fileState        = fread(fid, 1,'int16');
HEADER.firstData        = fread(fid, 1,'int32');
HEADER.channels         = fread(fid, 1,'int16');
HEADER.chanSize         = fread(fid, 1,'uint16');
HEADER.extraData        = fread(fid, 1,'uint16');
HEADER.bufferSz         = fread(fid, 1,'uint16');
HEADER.osFormat         = fread(fid, 1,'uint16');
HEADER.maxFTime         = fread(fid, 1,'int32');
HEADER.dTimeBase        = fread(fid, 1,'float64');
HEADER.timeDate.Hun     = fread(fid, 1,'uint8');
HEADER.timeDate.Sec     = fread(fid, 1,'uint8');
HEADER.timeDate.Min     = fread(fid, 1,'uint8');
HEADER.timeDate.Hour    = fread(fid, 1,'uint8');
HEADER.timeDate.Day     = fread(fid, 1,'uint8');
HEADER.timeDate.Mon     = fread(fid, 1,'uint8');
HEADER.timeDate.Year    = fread(fid, 1,'uint16');
HEADER.cAlignFlag       = fread(fid, 1,'int8');
pad0 = fread(fid, 3,'int8');
HEADER.LUTable          = fread(fid, 1,'int32');
pad  = fread(fid,44,'int8');
HEADER.fileComment      = cell(1,5);    
for K = 1:5
  n = fread(fid, 1,'uint8');
  HEADER.fileComment{K} = fread(fid,n,'char=>char')';
  fseek(fid, 79-n, 'cof');
end

if HEADER.systemID < 6
  HEADER.dTimeBase      = 1.0e-6;
  HEADER.timeDate.Hun   = 0;
  HEADER.timeDate.Sec   = 0;
  HEADER.timeDate.Min   = 0;
  HEADER.timeDate.Hour  = 0;
  HEADER.timeDate.Day   = 0;
  HEADER.timeDate.Mon   = 0;
  HEADER.timeDate.Year  = 0;
end


return



% ----------------------------------------------------------
function CHLIST = sub_readchlist(fid,HEADER)
% ----------------------------------------------------------
CHLIST = [];

for chan = 1:HEADER.channels,
  chinfo = sub_readchinfo(fid,HEADER,chan);

  % only look at channels that are active
  if chinfo.kind <= 0,  continue;  end
  
  if isempty(CHLIST),
    CHLIST = chinfo;
  else
    CHLIST(end+1) = chinfo;
  end
end


return


% ----------------------------------------------------------
function CHINFO = sub_readchinfo(fid,HEADER,chan)
% ----------------------------------------------------------

base = 512+(140*(chan-1));            % Offset due to file header and preceding channel headers
fseek(fid, base, 'bof');

CHINFO.channel      = chan;
CHINFO.delSize      = fread(fid, 1,'uint16');
CHINFO.nextDelBlock = fread(fid, 1,'int32');
CHINFO.firstBlock   = fread(fid, 1,'int32');
CHINFO.lastBlock    = fread(fid, 1,'int32');
CHINFO.blocks       = fread(fid, 1,'uint16');
CHINFO.nExtra       = fread(fid, 1,'uint16');
CHINFO.preTrig      = fread(fid, 1,'int16');
CHINFO.blocksMSW    = fread(fid, 1,'int16');
CHINFO.phySz        = fread(fid, 1,'uint16');
CHINFO.maxData      = fread(fid, 1,'uint16');
n = fread(fid,1,'uint8');
CHINFO.comment      = fread(fid, n,'char=>char')';
fseek(fid, 71-n,'cof');
CHINFO.maxChanTime  = fread(fid, 1,'int32');
CHINFO.lChanDvd     = fread(fid, 1,'int32');
CHINFO.phyChan      = fread(fid, 1,'int16');
n = fread(fid, 1,'uint8');
CHINFO.title        = fread(fid, n,'char=>char')';
fseek(fid, 9-n,'cof');
CHINFO.idealRate    = fread(fid, 1,'float32');
CHINFO.kind         = fread(fid, 1,'uint8');
CHINFO.delSizeMSB   = fread(fid, 1,'uint8');

% ADC/ADCMark channels
CHINFO.adc.scale      = [];
CHINFO.adc.offset     = [];
CHINFO.adc.units      = '';
CHINFO.adc.divide     = [];
CHINFO.adc.interleave = 1;
% EventBoth channels
CHINFO.event.initLow  = [];
CHINFO.event.nextLow  = [];
% Real marker channels
CHINFO.real.min       = [];
CHINFO.real.max       = [];
CHINFO.real.units     = '';

% block header
%CHINFO.blockheader    = [];

% only read "active" one...
if CHINFO.kind <= 0,  return;  end

% read additional info
%if ~any([1 4 6 7] == CHINFO.kind),  return;  end

switch CHINFO.kind
 case 1
  % 16-bit integer waveform data (called 'Adc' throughout the SON library)
  CHINFO.adc.scale   = fread(fid, 1,'float32');
  CHINFO.adc.offset  = fread(fid, 1,'float32');
  n = fread(fid, 1,'uint8');
  CHINFO.adc.units   = fread(fid, n,'char=>char')';
  fseek(fid, 5-n,'cof');
  if HEADER.systemID < 6,
    CHINFO.adc.divide     = fread(fid, 1,'uint16');
  else
    CHINFO.adc.interleave = fread(fid, 1,'uint16');
  end
% case 2
  % Event data, times taken on the low going edge of a pulse (EventFall)
% case 3
  % Event data, times taken on a high going edge of a pulse (EventRise)
 case 4
  % Event data, times taken on both edges of a pulse (EventBoth)
  CHINFO.event.initLow = fread(fid, 1,'uint8');  % BOOLEAN
  CHINFO.event.nextLow = fread(fid, 1,'uint8');  % BOOLEAN
% case 5
  % Markers, an event time plus four identifying bytes (Marker)  
 case 6
  % 16-bit integer waveform transient shapes (we call this 'AdcMark' data), 
  % an array of waveform data attached to a marker. 
  % In version 6 the waveform data may be multiple, interleaved channels.
  CHINFO.adc.scale   = fread(fid, 1,'float32');
  CHINFO.adc.offset  = fread(fid, 1,'float32');
  n = fread(fid, 1,'uint8');
  CHINFO.adc.units   = fread(fid, n,'char=>char');
  fseek(fid, 5-n,'cof');
  if HEADER.systemID < 6,
    CHINFO.adc.divide     = fread(fid, 1,'int16');
  else
    CHINFO.adc.interleave = fread(fid, 1,'int16');
  end
 case 7
  % Real markers, an array of real numbers attached to a marker (RealMark)
  CHINFO.real.min    = fread(fid, 1,'float32');
  CHINFO.real.max    = fread(fid, 1,'float32');
  n = fread(fid, 1,'uint8');
  CHINFO.real.units  = fread(fid, n,'char=>char')';
  fseek(fid, 5-n,'cof');
% case 8
  % Text markers, a string of text attached to a marker (TextMark)
% case 9
  % 32-bit floating point waveforms (RealWave). These are new at version 6.
end


return



% ----------------------------------------------------------
function BHEAD = sub_blockheader(fid,HEADER,CHINFO)
% ----------------------------------------------------------

%BHEAD.chan = CHINFO.chan;
BHEAD.seek       = [];
BHEAD.startTime  = [];
BHEAD.endTime    = [];
BHEAD.items      = [];

if CHINFO.firstBlock <= 0,  return;  end
if CHINFO.blocks     <= 0,  return;  end


bhinfo1 = zeros(4,CHINFO.blocks,'int32');
bhinfo2 = zeros(2,CHINFO.blocks,'uint16');
% int32  predBlock
% int32  succBlock
% int32  startTime
% int32  endTime
% uint16 chanNumber
% uint16 items

fseek(fid, CHINFO.firstBlock,'bof');
bhinfo1(1:4,1) = fread(fid, 4,'int32=>int32');
bhinfo2(1:2,1) = fread(fid, 2,'uint16=>uint16');


if bhinfo1(2,1) == -1,
  N = 1;
else
  for N = 2:CHINFO.blocks
    fseek(fid,bhinfo1(2,N-1),'bof');
    bhinfo1(1:4,N) = fread(fid, 4,'int32=>int32');
    bhinfo2(1:2,N) = fread(fid, 2,'uint16=>uint16');
    %if bhinfo1(2,N) == -1,  break;  end
  end
end
bhinfo1 = bhinfo1(:,1:N);

BHEAD.seek      = [CHINFO.firstBlock, double(bhinfo1(2,1:end-1))];
BHEAD.startTime = double(bhinfo1(3,:));
BHEAD.endTime   = double(bhinfo1(4,:));
BHEAD.items     = double(bhinfo2(2,:));


return
