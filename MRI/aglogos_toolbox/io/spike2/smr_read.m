function MDATA = smr_read(SMRFILE,CHAN,varargin)
%SMR_READ - Read data of a channel from a SPIKE2 SMR file.
%  MDATA = SMR_READ(SMRFILE,CHAN,...) reads data of a given channel from a SPIKE2 SMR file.
%  'CHAN' can be a number (>=1) or a channel name/title.
%
%  Supported options are :
%    'window_sec' : time window to read as [start_sec, length_sec]
%
%  EXAMPLE :
%    >> [h,chlist] = smr_info('R139.2_111214_01.smr')
%    >> {chlist(:).title}       % shows a list of channel names
%    >>
%    >> mdata = smr_read('R139.2_111214_01.smr',15,'window_sec',[0 10])
%    >> mdata = smr_read('R139.2_111214_01.smr','PFC')
%
%  VERSION :
%    0.90 10.11.15 YM  pre-release
%    0.91 13.11.15 YM  support MEXs.
%
%  See also smr_info smr_findchan smr_readwav smr_ReadChannelInfo SONChannelInfo

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
  error(' ERROR %s: SMRFile not found, %s.\n',mfilename,SMRFILE);
end


if any(SIGTOOL_LIB),
  % use SON2 lib of sigTOOL
  if isempty(SMRCHLIST),
    fid = fopen(SMRFILE,'r','ieee-le');
    SMRCHLIST = SONChanList(fid);
    fclose(fid);
  end
  if ischar(CHAN),
    CHANSTR = CHAN;
    CHAN = smr_findchan(SMRFILE,CHANSTR,'chanlist',SMRCHLIST,'verbose',0,'son2',SIGTOOL_LIB);
    if ~any(CHAN)
      error(' ERROR %s: chan(''%s'') not found in %s.',mfilename,CHANSTR,SMRFILE);
    end
  end
  smrch = SMRCHLIST(find([SMRCHLIST(:).number] == CHAN));
  
else
  % use the MEX function
  smrch = smr_ReadChannelInfo(SMRFILE,CHAN);
end


MDATA = [];
switch smrch.kind
 case {1}
  % 16-bit integer waveform data (called 'Adc' throughout the SON library)
  MDATA = smr_readwav(SMRFILE,CHAN,varargin{:});
 case {2,3,4}
  % Event data, times taken on the low going edge of a pulse (EventFall)
  % Event data, times taken on a high going edge of a pulse (EventRise)
  % Event data, times taken on both edges of a pulse (EventBoth)
  MDATA = smr_readevt(SMRFILE,CHAN,varargin{:});
 case {5}
  % Markers, an event time plus four identifying bytes (Marker)  
  MDATA = smr_readmkr(SMRFILE,CHAN,varargin{:});
 case {6}
  % 16-bit integer waveform transient shapes (we call this 'AdcMark' data), 
  % an array of waveform data attached to a marker. 
  % In version 6 the waveform data may be multiple, interleaved channels.
  MDATA = smr_readadcmkr(SMRFILE,CHAN,varargin{:});
 case {7}
  % Real markers, an array of real numbers attached to a marker (RealMark)
  MDATA = smr_readrealmkr(SMRFILE,CHAN,varargin{:});
 case {8}
  % Text markers, a string of text attached to a marker (TextMark)
  MDATA = smr_readtextmkr(SMRFILE,CHAN,varargin{:});
 case {9}
  % 32-bit floating point waveforms (RealWave). These are new at version 6.
  MDATA = smr_readwav(SMRFILE,CHAN,varargin{:});  % ?! maybe compatible ?!
  %MDATA = smr_readrealwav(SMRFILE,CHAN,varargin{:});
end


return
