function hrf = grpgethrf(SESSION,GrpName,SigName,RoiName)
%GRPGETHRF - Compute HRF by using the experiments in group GrpName
% GRPGETHRF (SESSION, GrpName, SigName, RoiName) invokes EXPSIGHRF to compute the HRF by means of
% correlation analysis. Defaults for RoiName = "ele" and SigName = "blp", whereby hlm stands
% for the abs(hilbert(Lfp and Mua)).
%
% NOTE: The estimation of HRF will absolutely depend on the selection of ROIs. No meaningful
% results can be obtained if the ROI includes "non-brain" or even "non-cortex" regions. For
% all experiments examining transfer functions etc, the "ele" ROI must be constraint to its
% portion found responsive under standard stimulation conditions.
%
% Example (Functions called before calling GRPGETHRF)
% ========================================================================
% SesName = 'n03qv1';
% GrpName = 'polarflash';
%
% NKL 28.10.03
% NKL 01.06.08

if nargin < 4,
  RoiName = 'ele';      % To estimate HRF we use the voxels around the electrode
                        % only. Currently we have sufficient evidence that this is the best
                        % choice. Prediction is a function of distance (Granger causality
                        % measurements).
end;

if nargin < 3,
  SigName = 'blp';      % Input are the 20 frequency bands extracted from Cln (see SIGGETBLP
                        % for further detail.
end;

if nargin < 2,
  help grpgethrf;
  return;
end;

Ses = goto(SESSION);
grp = getgrpbyname(Ses,GrpName);

for N = 1:length(grp.exps),
  ExpNo = grp.exps(N);

  tmp = expgethrf(Ses,ExpNo,SigName,RoiName,troiTs{1}{1}.origIdx);
  
  if N==1,
    hrf = tmp;
  else
    hrf.dat = cat(DIM,hrf.dat,tmp.dat);
    hrf.raw = cat(DIM,hrf.raw,tmp.raw);
  end;
  hrf.RoiName = RoiName;
  fprintf('.');
end;

if ~nargout,
  filename = strcat(GrpName,'.mat');
  if exist(filename,'file'),
    save(filename,'-append','hrf');
  else
    save(filename,'hrf');
  end;
end;
