% mexsmr : batch file to make mex DLLs for CED Spike2 files (.smr)
%
% VERSION :
%   0.90 12.Nov.2015 YM

clear all;

switch lower(mexext)
 case {'mexa64'}
  mex CFLAGS='-std=c99 -fPIC' smr_ReadHeader.c        smrapi.c
  mex CFLAGS='-std=c99 -fPIC' smr_ReadChannelInfo.c   smrapi.c
  mex CFLAGS='-std=c99 -fPIC' smr_FindChannel.c       smrapi.c
  mex CFLAGS='-std=c99 -fPIC' smr_GetSampleInterval.c smrapi.c
  mex CFLAGS='-std=c99 -fPIC' smr_ReadWaveS.c         smrapi.c
 otherwise
  mex smr_ReadHeader.c        smrapi.c
  mex smr_ReadChannelInfo.c   smrapi.c
  mex smr_FindChannel.c       smrapi.c
  mex smr_GetSampleInterval.c smrapi.c
  mex smr_ReadWaveS.c         smrapi.c
end
