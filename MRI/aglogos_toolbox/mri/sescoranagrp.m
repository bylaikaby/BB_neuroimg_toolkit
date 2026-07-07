function sescoranagrp(SesName, GRPS)
%SESCORANAGRP - Correlation analysis for grouped data
% SESCORANAGRP(SesName, GRPS) invokes MCORANA, which runs the actual correlation analysis
% between a stimulus model and the time courses of voxels. 
%
% VERSION :
%   0.90 03.01.06 YM  mofified from sescorana.m
%  
% See also MCORANA MATSCOR MCOR SESCORANA


if nargin < 1,
  help sescoranagrp;
  return;
end;

Ses = goto(SesName);

if ~exist('GRPS','var') | isempty(GRPS),
  GRPS = getgrpnames(Ses);
end;

if ischar(GRPS), GRPS = { GRPS };  end



% Checks grp.refgrp and split EXPS into refgrp and not
[runGRPS elsGRPS] = subCheckRefGrp(Ses,GRPS);

% DOING grp.refgrp.grpexp first.
for iGrp = 1:length(runGRPS),
  GrpName = runGRPS{iGrp};
  fprintf('sescoranagrp: [%3d/%d] processing %s Grp=%s\n', iGrp,length(GRPS),Ses.name,GrpName);
  Sig = mcorana(Ses, GrpName);
  anap = getanap(Ses,GrpName);
  if isfield(anap,'gettrial') & anap.gettrial.status > 0,
    sigsave(Ses,GrpName,'troiTs',Sig);
  else
    sigsave(Ses,GrpName,'roiTs',Sig);
  end
  clear Sig;
end

for iGrp = 1:length(elsGRPS),
  GrpName = elsGRPS{iGrp};
  fprintf('sescoranagrp: [%3d/%d] processing %s Grp=%s\n', iGrp+length(runGRPS),length(GRPS),Ses.name,GrpName);
  Sig = mcorana(Ses, GrpName);
  anap = getanap(Ses,GrpName);
  if isfield(anap,'gettrial') & anap.gettrial.status > 0,
    sigsave(Ses,GrpName,'troiTs',Sig);
  else
    sigsave(Ses,GrpName,'roiTs',Sig);
  end
  clear Sig;
end;

  
  
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to split GRPS into refgrp and not
function [runGRPS elsGRPS] = subCheckRefGrp(Ses,GRPS)

IDX = zeros(size(GRPS));
for iGrp = 1:length(GRPS),
  grp = getgrp(Ses,GRPS{iGrp});
  if isfield(grp,'refgrp') & ~isempty(grp.refgrp),
    grpexp = grp.refgrp.grpexp;
    if ischar(grpexp),
      if strcmpi(grpexp,grp.name),
        IDX(iGrp) = 1;
      end
    else
      if ExpNo == grp.exp,
        IDX(iGrp) = 1;
      end
    end
  end
end

runGRPS = GRPS(find(IDX == 1));
elsGRPS = GRPS(find(IDX == 0));

return;

