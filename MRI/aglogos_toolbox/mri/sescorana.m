function sescorana(SesName, EXPS, SigName)
%SESCORANA - Correlation analysis w/ simple xcor or GLM analysis
% SESCORANA(SesName, EXPS) applies correlation analysis between user-defined regressors, or
% HRF convolved neural signals to select voxels related to a visual stimulus or behaviora
% task. Details on correlation analysis can be found in the header of MCORANA.
%  
%  NOTE :
%    Parameters can be given as follows.  They can be set as GRP.xxx.anap.xxxx
%      ANAP.shift              = 0;            % nlags for xcor in seconds
%
%      GRPP.groupcor = 'after cor';
%      GRPP.corana{1}.mdlsct = 'hemo';         % Model for correlation analysis
%      GRPP.corana{2}.mdlsct = 'invhemo';
%    To apply filter before xcorr, then
%      GRPP.corana{1}.mdlsct       = 'hemo'
%      GRPP.corana{1}.bold_tfilter = [0 0.1];  % 0.1Hz low-pass
%    To get corr.coeff at the given lag, then
%      GRPP.corana{1}.mdlsct       = 'hemo'
%      GRPP.corana{1}.bold_tfilter = [0 0.1];  % 0.1Hz low-pass
%      GRPP.corana{1}.lagfix       = 5;        % fixed lag in seconds
%
%
%  VERSION :
%    1.00 23.07.04 NKL
%    2.00 03.02.12 YM,  can separate corana results.
%
%  See also MCORANA STATSAVE EXPMKMODEL MATSCOR MCOR SHOWMODEL

if nargin < 1,
  help sescorana;
  return;
end;

if nargin < 3,  SigName = [];  end

Ses = goto(SesName);

if ~exist('EXPS','var') || isempty(EXPS),
  EXPS = validexps(Ses);
end;

% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end


for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  grp = getgrp(Ses,ExpNo);
  DO_MCORANA = 1;
  if isfield(grp,'refgrp') && ~isempty(grp.refgrp),
    if isnumeric(grp.refgrp.grpexp),
      if ExpNo ~= grp.refgrp.grpexp,
        DO_MCORANA = 0;
      end
    else
      if ~strcmpi(grp.refgrp.grpexp,grp.name),
        DO_MCORANA = 0;
      end
    end
  end
  if any(DO_MCORANA),
    if isempty(SigName),
      if trialstatus(Ses,ExpNo) > 0,
        tmpSigName = 'troiTs';
      else
        tmpSigName = 'roiTs';
      end
    else
      tmpSigName = SigName;
    end
    
    fprintf('sescorana: [%3d/%d] processing %s Exp=%d(%s)\n', ...
            iExp,length(EXPS),Ses.name,ExpNo,grp.name);
    if sesversion(Ses) >= 2,
      [Sig, corana] = mcorana(Ses, ExpNo, tmpSigName);
      statsave(Ses,ExpNo,tmpSigName,'corana',corana);
    else
      Sig = mcorana(Ses, ExpNo, SigName);
      sigsave(Ses,ExpNo,tmpSigName,Sig);
    end
    clear Sig;
  else
    fprintf('sescorana: [%3d/%d] %s Exp=%d(%s), skipped',...
            iExp,length(EXPS),Ses.name,ExpNo,grp.name);
    if ischar(grp.refgrp.grpexp),
      fprintf(' [refgrp=%s]\n',grp.refgrp.grpexp);
    else
      fprintf(' [refgrp=%d]\n',grp.refgrp.grpexp);
    end
  end
end


return




% THIS IS THE OLD CODE CORRELATING NEURAL RESPONSES TO FMRI
for GrpNo = 1:length(grpnames),
  grp = getgrp(Ses,grpnames{GrpNo});
  sigload(Ses,grp.name,'blp');
  cblp = sigconv(blp);
  Neu{1} = blp2sig(cblp,'gmua');
  roiTs = sigload(Ses,grp.exps(1),'roiTs');
  dx = roiTs{1}.dx; len = size(roiTs{1}.dat,1); clear roiTs;
  Neu{1} = sigresample(Neu{1},1/dx,'len',len);
  Neu{1}.dat = hnanmean(Neu{1}.dat,2);

  fprintf('SESCORANA: Session %s, Group %s\n', Ses.name,grpnames{GrpNo});
  for iExp = 1:length(grp.exps),
    ExpNo = grp.exps(iExp);
    Sig = sigload(Ses,ExpNo,'roiTs');
    Sig = matscor(Sig,Neu,0,0,0);
    sigsave(Ses,ExpNo,'roiTs',Sig);
  end;
end;
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to split EXPS into refgrp and not
function [runEXPS elsEXPS runGrp] = subCheckRefGrp(Ses,EXPS)

IDX = zeros(size(EXPS));
GRPS = cell(size(IDX));
for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  grp = getgrp(Ses,ExpNo);
  GRPS{iExp} = '';
  if isfield(grp,'refgrp') && ~isempty(grp.refgrp),
    grpexp = grp.refgrp.grpexp;
    if ischar(grpexp),
      if strcmpi(grpexp,grp.name),
        IDX(iExp) = 1;
        GRPS{iExp} = grp.name;
      end
    else
      if any(ExpNo == grp.exps),
        IDX(iExp) = 1;
      end
    end
  end
end

runEXPS = EXPS(find(IDX == 1));
elsEXPS = EXPS(find(IDX == 0));

GRPS  = unique(GRPS(find(IDX == 1)));
runGrp  = GRPS(find(~strcmpi(GRPS,'')));

return;

