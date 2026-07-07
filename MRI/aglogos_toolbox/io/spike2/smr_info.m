function [HEADER, CHLIST] = smr_info(SMRFILE,varargin)
%SMR_INFO - Read header/chanlist from a SPIKE2 SMR file.
%  [HEADER, CHLIST] = SMR_INFO(SMRFILE,...) reads header/chanlist from a SPIKE2 SMR file.
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
%    0.91 13.11.15 YM  supports MEXs for better performance (x7).
%
%  See also smr_read smr_findchan smr_chaninfo 
%           smr_ReadHeader smr_ReadChannelInfo  SONFileHeader SONChanList

if nargin < 1,  eval(['help ' mfilename]); return;  end


% options
VERBOSE       = 1;
SIGTOOL_LIB   = 0;   % use SON2 Lib of sigTOOL
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'verbose'}
    VERBOSE = any(varargin{N+1});
   case {'sigtool' 'sigtoollib' 'son2'}
    SIGTOOL_LIB = any(varargin{N+1});
  end
end


if ~exist(SMRFILE,'file'),
  error(' ERROR %s: SMRFile not found, %s.',mfilename,SMRFILE);
end

if any(SIGTOOL_LIB),
  % use SON2 lib of sigTOOL
  fid = fopen(SMRFILE,'r','ieee-le');
  HEADER = SONFileHeader(fid);
  if nargout > 1
    CHLIST = SONChanList(fid);
  end
  fclose(fid);
else
  % use MEX functions
  HEADER = smr_ReadHeader(SMRFILE);
  if nargout > 1,
    CHLIST = [];
    for K = 1:HEADER.channels
      chinfo = smr_ReadChannelInfo(SMRFILE,K);
      if chinfo.kind <= 0,  continue;  end
      if isempty(CHLIST),
        CHLIST = chinfo;
      else
        CHLIST(end+1) = chinfo;
      end
    end
  end
end


return
