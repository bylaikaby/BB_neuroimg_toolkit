function MDATA = smr_readmkr(SMRFILE,CHAN,varargin)
%SMR_READMKR - Read Digital Marker data from a SPIKE2 SMR file.
%  MDATA = SMR_READMKR(SMRFILE,CHAN,...) reads Digital Marker data form a SPIKE2 SMR file.
%  'CHAN' can be a number (>=1) or a channel name/title.
%
%  Supported options are :
%    'window_sec' : time window to read as [start_sec, length_sec]
%
%  EXAMPLE :
%    >> [h,chlist] = smr_info('R139.2_111214_01.smr')
%    >> {chlist(:).title}       % shows a list of channel names
%    >>
%    >> mdata = smr_readmkr('R139.2_111214_01.smr',15,'window_sec',[0 10])
%    >> mdata = smr_readmkr('R139.2_111214_01.smr','PFC')
%
%  VERSION :
%    0.90 12.11.15 RMN  pre-release
%
%  See also smr_info smr_findchan smr_read smrmat2cln
%           SONGetChannel SONGetSampleInterval SONGetBlockHeaders

if nargin < 2,  eval(['help ' mfilename]); return;  end

% options
VERBOSE       = 1;
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
    end
end

if ~exist(SMRFILE,'file'),
    error(' ERROR %s: SMRFile not found, %s.',mfilename,SMRFILE);
end


if ischar(CHAN),
    CHANSTR = CHAN;
    CHAN = smr_findchan(SMRFILE,CHANSTR,'chanlist',SMRCHLIST,'verbose',0);
    if ~any(CHAN)
        error(' ERROR %s: chan(''%s'') not found in %s.',mfilename,CHANSTR,SMRFILE);
    end
end

fid = fopen(SMRFILE,'r','ieee-le');
[data, chheader] = SONGetChannel(fid, CHAN, 'seconds','scale');
fclose(fid);

if isempty(chheader)
    chheader.title   = [];
    chheader.comment = [];
    MDATA.length     = 0;
    MDATA.times      = 0;
    MDATA.marker     = [];
else
    if isempty(WINDOW_SEC) || ~any(WINDOW_SEC),
        
        MDATA.length = chheader.npoints;
        MDATA.times  = data.timings;
        indx         = 1:MDATA.length;
    else
        indx = data.timings > WINDOW_SEC(1) & data.timings < sum(WINDOW_SEC);
        MDATA.times  = data.timings(indx);
        MDATA.times  = MDATA.times - WINDOW_SEC(1);
        MDATA.length = length(MDATA.times);
    end
    MDATA.codes = data.markers(indx,:);    
end

MDATA.title    = chheader.title;
MDATA.comment  = chheader.comment;

MDATA.smr_read.chheader = chheader;
MDATA.smr_read.window_sec = WINDOW_SEC;

return
