function [CHINFO, BLKHEADER] = smr_chaninfo(SMRFILE,CHAN,varargin)
%SMR_CHANINFO - Read channel information from a SPIKE2 SMR file.
%  [CHHEADER, BLKHEADER] = SMR_CHANINFO(SMRFILE,CHAN,...) reads channel information
%  from a SPIKE2 SMR file.
%  'CHAN' can be a number (>=1) or a channel name/title.
%
%  EXAMPLE :
%    >> [chinfo, chblocks] = smr_chaninfo('R139.2_111214_01.smr',34)
%    >> [chinfo, chblocks] = smr_chaninfo('R139.2_111214_01.smr','D1')
%
%  VERSION :
%    0.90 11.11.15 YM  pre-release
%    0.91 13.11.15 YM  support MEX for better performance (x20-300).
%
%  See also smr_info smr_read smr_findchan smr_ReadChannelInfo SONChannelInfo SONGetBlockHeaders

if nargin < 2,  eval(['help ' mfilename]); return;  end


% options
VERBOSE       = 1;
SIGTOOL_LIB   = 0;   % use SON2 Lib of sigTOOL
SMRHEADER     = [];  % SMR header
SMRCHLIST     = [];  % SMR channel list
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'verbose'}
    VERBOSE = any(varargin{N+1});
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

if any(SIGTOOL_LIB),
  % use SON2 lib of sigTOOL
  if ischar(CHAN),
    CHANSTR = CHAN;
    CHAN = smr_findchan(SMRFILE,CHANSTR,'chanlist',SMRCHLIST,'verbose',0,'son2',1);
    if ~any(CHAN)
      error(' ERROR %s: chan(''%s'') not found in %s.',mfilename,CHANSTR,SMRFILE);
    end
  end
  fid = fopen(SMRFILE,'r','ieee-le');
  CHINFO = SONChannelInfo(fid,CHAN);
  if nargout > 1 
    BLKHEADER = SONGetBlockHeaders(fid,CHAN);
  end
  fclose(fid);
else
  % use the MEX function
  if nargout > 1,
    [CHINFO,BLKHEADER] = smr_ReadChannelInfo(SMRFILE,CHAN);
  else
    CHINFO = smr_ReadChannelInfo(SMRFILE,CHAN);
  end
end


return
