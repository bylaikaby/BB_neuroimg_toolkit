%SMR_READCHANINFO - Read file header from a SPIKE2 SMR file.
%  [HEADER, CHLIST] = SMR_INFO(SMRFILE,...) reads file header from a SPIKE2 SMR file.
%
%  EXAMPLE :
%    >> header = smr_ReadChannelInfo('R139.2_111214_01.smr','D1');
%
%  VERSION :
%    0.90 13.11.15 YM  pre-release
%
%  See also smr_info smr_ReadChannelInfo smr_FindChannel smr_GetSampleInterval smr_ReadWaveS
