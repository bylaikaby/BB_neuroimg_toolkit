%SMR_GETSAMPLEINTERVAL - Get the sample interval (usec) of the given channel in the smrfile.
%  SampIntervalUsec = SMR_GETSAMPLEINTERVAL(SMRFILE,CHAN) gets the sample interval (usec) of 
%  the given channel in the smrfile.
%  "CHAN" can be a numeric (1~MaxChan) or a string of channel name/title.
%
%  EXAMPLE :
%    >> sampt_us = smr_GetSampleInterval('R139.2_111214_01.smr','D1');
%
%  VERSION :
%    0.90 16.11.15 YM  pre-release
%
%  See also smr_ReadHeader smr_ReadChannelInfo smr_FindChannel smr_ReadWaveS
