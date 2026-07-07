function sescorana(SesName, EXPS)
%SESCORANA - Correlation analysis
% SESCORANA(SesName, EXPS) invokes MCORANA, which runs the actual correlation analysis
% between a stimulus model and the time courses of voxels. 
% FIX BELOW.....
% Cross correlation analysis between convolved neural response and the fMRI signal
% SESCORANA loads the convolved form of the neural responses, that is the CBLP signals, and
% uses them as model (regressor) for correlation analysis between this model and the time
% courses of the fMRI signal.
%  
% See also MCORANA MATSCOR MCOR
%
% NKL 23.07.04

if nargin < 1,
  help sescorana;
  return;
end;

Ses = goto(SesName);

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;

% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  fprintf('sescorana: [%3d/%d] processing %s Exp=%d\n', iExp,length(EXPS),Ses.name,ExpNo);
  roiTs = mcorana(Ses, ExpNo);
  sigsave(Ses,ExpNo,'roiTs',roiTs);
end;

  
  
return;
% THIS IS THE OLD CODE CORRELATING NEURAL RESPONSES TO FMRI
for GrpNo = 1:length(grpnames),
  grp = getgrpbyname(Ses,grpnames{GrpNo});
  sigload(Ses,grp.name,'blp');
  cblp = sigconv(blp);
  Neu{1} = blp2sig(cblp,'gmua');
  roiTs = sigload(Ses,grp.exps(1),'roiTs');
  dx = roiTs{1}.dx; len = size(roiTs{1}.dat,1); clear roiTs;
  Neu{1} = sigresample(Neu{1},1/dx,len);
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
