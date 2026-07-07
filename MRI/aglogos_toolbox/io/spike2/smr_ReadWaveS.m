%SMR_READWAVES - Read wave data (int16) from a SMRFILE.
%  [Vals iTickStart] = smr_ReadWaveS(SMRFILE,CHAN) reads wave data (int16) from
%  the give SMRFILE.
%  [Vals iTickStart] = smr_ReadWaveS(SMRFILE,CHAN,BlockFrom,BlockTo) reads the given blocks
%  of wave data.
%  [Vals iTickStart] = smr_ReadWaveS(SMRFILE,CHAN,BlockFrom,BlockTo,Scale=1) reads data, then
%  scales data.
%
%  * "CHAN" can be a numeric (1~MaxChan) or a string of channel name/title.
%  * If "BlockTo" < 0, then reads until the block-end."
%  * If "Scale" = 1 (default), then "Vals" as double, otherwise int16.
%
%  EXAMPLE :
%    >> vals = smr_ReadWaveS('R139.2_111214_01.smr','D1', 1,-1);    % all blocks with scaling
%    >> vals = smr_ReadWaveS('R139.2_111214_01.smr','D1', 1,-1, 0); % all blocks w/o scaling
%    >> vals = smr_ReadWaveS('R139.2_111214_01.smr','D1', 1,10);    % 1-10 blocks with scaling
%
%  VERSION :
%    0.90 16.11.15 YM  pre-release
%
%  See also smr_ReadHeader smr_ReadChannelInfo smr_FindChannel smr_GetSampleInterval
