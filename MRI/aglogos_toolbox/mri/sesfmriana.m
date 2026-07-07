function sesfmriana(SesName)
%SESFMRIANA - Batch file to run all preprocessing and correlation/GLM analysis for fMRI data
% SESFMRIANA(SesName) runs all necessary steps to apply the correlation analysis on fMRI
% data. Models can be stimulus-based or neural-signal based.
%
% NKL 13.01.2006

DEF.SW_SESDUMPPAR           = 0;
DEF.SW_SESASCAN             = 0;
DEF.SW_SESCSCAN             = 0;
DEF.SW_SESVITAL             = 0;
DEF.SW_SESIMGLOAD           = 0;
DEF.SW_SESROI               = 0;
DEF.SW_SESAREATS            = 0;

DEF.SW_SESGETTRIAL          = 0;
DEF.SW_SESGETTRIAL_ROITS    = 0;
DEF.SW_SESCORANA            = 0;
DEF.SW_SESGLMANA            = 0;
DEF.SW_SESGRPMAKE           = 0;
DEF.SW_SESGRPMAKE_ROITS     = 0;
DEF.SW_SESGRPMAKE_TROITS    = 0;
DEF.SW_SESGETMASK           = 0;

DEF.SW_DSPCORANA            = 0;
DEF.SW_DSPGLMANA            = 0;

Ses = goto(SesName);
anap = getanap(SesName, 1); % ExpNo does not matter; it's the session ANAP

if isfield(anap,'TODO'),
    anap.TODO = sctcat(anap.TODO,DEF);
else
    anap.TODO = DEF;
end;
pareval(anap.TODO);

if nargin < 1,
  help sesfmriana;
  return;
end;

if SW_SESDUMPPAR,
  fprintf('SESFMRIANA: Creating SesPar.mat -- sesdumppar(%s)...\n',SesName);
  sesdumppar(Ses);
end;

if SW_SESASCAN,
  fprintf('SESFMRIANA: Loading Anatomy files -- sesascan(%s)...\n',SesName);
  sesascan(Ses);
end;

if SW_SESCSCAN,
  fprintf('SESFMRIANA: Loading EPI13 files -- sescscan(%s)...\n',SesName);
  sescscan(Ses);
end;

if SW_SESVITAL,
  fprintf('SESFMRIANA: Loading VITAL Signs -- sesvital(%s)...\n',SesName);
  sesvital(Ses);
end;

if SW_SESIMGLOAD,
  fprintf('SESFMRIANA: Loading tcImg data -- sesimgload(%s)...\n',SesName);
  sesimgload(Ses);
end;

if SW_SESROI,
  fprintf('SESFMRIANA: Extracting ROIs -- sesroi(%s)...\n',SesName);
  sesroi(Ses);
end;

if SW_SESAREATS,
  fprintf('SESFMRIANA: Extracting roiTs --  sesareats(%s)...\n',SesName);
  sesareats(SesName);
end;

if SW_SESGETTRIAL_ROITS,
  fprintf('SESFMRIANA: Splitting OBSP in trials --  sesgettrial(%s)...\n',SesName);
  sesgettrial(SesName,[],'roiTs');
end;

if SW_SESCORANA,
  fprintf('SESFMRIANA: Correlation Analysis -- sescorana(%s)...\n',SesName);
  sescorana(SesName);
end;

if SW_SESGLMANA,
  fprintf('SESFMRIANA: GLM Analysis -- sesglmana(%s)...\n',SesName);
  sesglmana(SesName);
end;

if SW_SESGRPMAKE_ROITS,
  fprintf('SESFMRIANA: Running sesgrpmake(%s)...\n',SesName);
  sesgrpmake(SesName,[],'roiTs');
end;

if SW_SESGRPMAKE_TROITS,
  fprintf('SESFMRIANA: Running sesgrpmake(%s)...\n',SesName);
  sesgrpmake(SesName,[],'troiTs');
end;

if SW_SESGETMASK,
  fprintf('SESFMRIANA: Creating voxel-selection MASKS -- sesgetmask(%s)...\n',SesName);
  sesgetmask(SesName);
end;

if SW_DSPCORANA,
  fprintf('SESFMRIANA: Plotting Correlation Results...\n');
  hypshow(SesName);
end;

if SW_DSPGLMANA,
  fprintf('SESFMRIANA: Plotting GLM Results...\n');
  glmshow(SesName);
end;


