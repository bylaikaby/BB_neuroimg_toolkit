function MDATA = smr_readwav(SMRFILE,CHAN,varargin)
%SMR_READWAV - Read waveform data from a SPIKE2 SMR file.
%  MDATA = SMR_READWAV(SMRFILE,CHAN,...) reads waveform data form a SPIKE2 SMR file.
%  'CHAN' can be a number (>=1) or a channel name/title.
%
%  Supported options are :
%    'window_sec' : time window to read as [start_sec, length_sec]
%
%  EXAMPLE :
%    >> [h,chlist] = smr_info('R139.2_111214_01.smr')
%    >> {chlist(:).title}       % shows a list of channel names
%    >>
%    >> mdata = smr_readwav('R139.2_111214_01.smr',15,'window_sec',[0 10])
%    >> mdata = smr_readwav('R139.2_111214_01.smr','PFC')
%
%  VERSION :
%    0.90 10.11.15 YM  pre-release
%    0.91 13.11.15 YM  supports MEXs (int16 data) for better performance (x20).
%
%  See also smr_info smr_findchan smr_read smrmat2cln
%           smr_GetSampleInterval smr_ReadChannelInfo smr_ReadWaveS
%           SONGetChannel SONGetSampleInterval SONGetBlockHeaders

if nargin < 2,  eval(['help ' mfilename]); return;  end


% options
VERBOSE       = 1;
SIGTOOL_LIB   = 0;   % use SON2 Lib of sigTOOL
WINDOW_SEC    = [];  % time window to read as [start_sec, length_sec]
BLOCK_READING = 1;   % block-reading of 10s is ~30% faster than whole-reading.
SMRHEADER     = [];  % SMR header
SMRCHLIST     = [];  % SMR channel list
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'verbose'}
    VERBOSE = any(varargin{N+1});
   case {'win','twin','window' 'windowsec' 'window_sec'}
    WINDOW_SEC = varargin{N+1};
   case {'block' 'blockread' 'blockreading'}
    BLOCK_READING = varargin{N+1};
   case {'smrheader' 'header'}
    SMRHEADER = varargin{N+1};
   case {'chanlist' 'smrchanlist' 'channellist' 'smrchannellist' 'smrchlist'}
    SMRCHLIST = varargin{N+1};
   case {'sigtool' 'sigtoollib' 'son2'}
    SIGTOOL_LIB = any(varargin{N+1});
  end
end

if ~exist(SMRFILE,'file'),
  error(' ERROR %s: SMRFile not found, %s.',mfilename,SMRFILE);
end


if ischar(CHAN),
  CHANSTR = CHAN;
  CHAN = smr_findchan(SMRFILE,CHANSTR,'chanlist',SMRCHLIST,'verbose',0,'son2',SIGTOOL_LIB);
  if ~any(CHAN)
    error(' ERROR %s: chan(''%s'') not found in %s.',mfilename,CHANSTR,SMRFILE);
  end
end


if any(SIGTOOL_LIB)
  fid = fopen(SMRFILE,'r','ieee-le');
  sampinterval_usec = SONGetSampleInterval(fid,CHAN);
else
  sampinterval_usec = smr_GetSampleInterval(SMRFILE,CHAN);
end
if ~any(sampinterval_usec),
  MDATA = [];
  if any(SIGTOOL_LIB), fclose(fid);  end
  if any(VERBOSE),
    warning(' ERROR %s: invalid data channel (%d).\n',mfilename,CHAN);
  end
  return
end

DX = sampinterval_usec * 1.0e-6;
if isempty(WINDOW_SEC) || ~any(WINDOW_SEC),
  BLOCK_READING = 0;
  ts = NaN;
  len = NaN;
else
  ts = floor(WINDOW_SEC(1)/DX) + 1;
  len = round(WINDOW_SEC(2)/DX);
end
  

if any(BLOCK_READING),
  % block reading
  if any(SIGTOOL_LIB)
    bheader = SONGetBlockHeaders(fid,CHAN);
    % bheader(:,x) =
    %    5120 % disk pointer to start of block
    %     100 % start time (clock ticks)
    % 2549100 % end time (clock ticks)
    %       1 % channel number
    %    2550 % number of data points
  else
    [chinfo, chblocks] = smr_ReadChannelInfo(SMRFILE,CHAN);
    chheader.title   = chinfo.title;
    chheader.comment = chinfo.comment;
    chheader.scale   = chinfo.adc.scale;
    chheader.offset  = chinfo.adc.offset;
    chheader.units   = chinfo.adc.units;
    bheader = chblocks.bheader;
    % bheader(:,x) =
    %  293376 % disk pointer to start of block
    %      30 % start time (clock ticks)
    %   73362 % end time (clock ticks)
    %    2038 % number of data points
  end
  bstarts = cumsum([0 bheader(end,:)]);
  b1 = max(find(bstarts <= ts));
  b2 = min(find(bstarts >= ts+len-1));
  if ~any(b1) || ~any(b2),
    error(' ERROR %s: window=[%g %g]sec is out of range (maxlen=%gsec).',mfilename,WINDOW_SEC(1),WINDOW_SEC(2),sum(bheader(end,:))*DX);
  end
  
  if any(SIGTOOL_LIB),
    [data, chheader] = SONGetChannel(fid, CHAN, b1, b2, 'seconds','scale');
    fclose(fid);
  else
    data = smr_ReadWaveS(SMRFILE, CHAN, b1, b2, 1);
    %data = data * chheader.scale / 6553.6 + chheader.offset;
  end
  data = data((0:len-1) + ts - bstarts(b1));
else
  % whole reading
  if any(SIGTOOL_LIB)
    [data, chheader] = SONGetChannel(fid, CHAN, 'seconds','scale');
    fclose(fid);
  else
    data = smr_ReadWaveS(SMRFILE, CHAN, 1, -1, 1);
    %data = data * chheader.scale / 6553.6 + chheader.offset;
  end
  if ~isnan(ts),
    data = data((0:len-1) + ts);
  else
    ts = 1;
  end
end



MDATA.title    = chheader.title;
MDATA.comment  = chheader.comment;
MDATA.interval = sampinterval_usec*1.0e-6;
MDATA.scale    = chheader.scale;
MDATA.offset   = chheader.offset;
MDATA.units    = chheader.units;
MDATA.start    = NaN;  % ????
MDATA.length   = length(data);
MDATA.values   = data(:);  % should be a column vector


MDATA.smr_read.chheader = chheader;
MDATA.smr_read.window_sec = WINDOW_SEC;
MDATA.smr_read.sampinterval_usec = sampinterval_usec;
MDATA.smr_read.start_pts = ts;

return
