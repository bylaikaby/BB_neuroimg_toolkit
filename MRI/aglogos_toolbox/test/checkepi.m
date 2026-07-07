%Script to check the stability of a given EPI/SE scan.
%
%
%  See also checkepi_stability checkepi_spm_realign

DATA_DIR   = '\\10.102.5.251\ids1_mridata\7040\RawData';
STUDY_NAME = '20250902_095533_GeneralTest_20250902a_2_8';
SCAN_RECO  = [20 1];  % GE, 8 segments, 6s
SCAN_RECO  = [31 1];  % GE, 2 segments, 2s
SCAN_RECO  = [41 1];  % SE, 2s


SAVE_ROOT  = 'E:\DataMatlab';


% check basic statistics.
[IDATA, IMGP] = checkepi_stability(DATA_DIR,STUDY_NAME,SCAN_RECO,'save_root',SAVE_ROOT);

% MOTION PARAMETERS BY SPM
checkepi_spm_realign(DATA_DIR,STUDY_NAME,SCAN_RECO,'save_root',SAVE_ROOT);

% Make a movie from 2dseq
imgfile = fullfile(DATA_DIR,STUDY_NAME,sprintf('%d/pdata/%d/2dseq',SCAN_RECO(1),SCAN_RECO(2)));
tcimgmovie(imgfile,'cmap','jet');

