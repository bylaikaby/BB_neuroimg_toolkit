function CHAN = smr_findchan(SMRFILE,CHANSTR,varargin)
%SMR_FINDCHAN - Find a channel number for the given channel title/name.
%  CHAN = SMR_FINDCHAN(SMRFILE,CHANSTR,...) finds a channel number 
%  for the given channel title/name.
%
%  EXAMPLE :
%    >> chan = smr_findchan('R139.2_111214_01.smr','D1');
%
%  VERSION :
%    0.90 11.11.15 YM  pre-release
%    0.91 13.11.15 YM  supports the MEX (smr_FindChannel), much faseter (x200-400).
%
%  See also smr_info smr_read smr_chaninfo smr_FindChannel SONChanList SONChannelInfo


if nargin < 2,  eval(['help ' mfilename]); return;  end


% options
VERBOSE       = 1;
SIGTOOL_LIB   = 0;   % use SON2 Lib of sigTOOL
SMRCHLIST     = [];  % SMR channel list
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'verbose'}
    VERBOSE = any(varargin{N+1});
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
  if isempty(SMRCHLIST),
    fid = fopen(SMRFILE,'r','ieee-le');
    SMRCHLIST = SONChanList(fid);
    fclose(fid);
  end
  CHAN = find(strcmp({SMRCHLIST(:).title},CHANSTR));
  if any(CHAN),
    CHAN = SMRCHLIST(CHAN).number;
  end
else
  % use the MEX function
  CHAN = smr_FindChannel(SMRFILE,CHANSTR);
end


if ~any(CHAN),
  if any(VERBOSE),
    error(' ERROR %s: chan(''%s'') not found in %s.',mfilename,CHANSTR,SMRFILE);
  end
end


return

