function checkfilt(SESSION,GrpName)
%CHECKFILT - Check the effect of filtering on roiTs
% CHECKFILT(SESSION, GrpName) the function checks the effect of filtering on roiTs
%
% NKL, 29.09.06a

if nargin < 2,
  help checkfilt;
  return;
end;

Ses = goto(SESSION);
sesareats(Ses,GrpName);
sesgettrial(Ses, GrpName);
sesgrpmake(Ses,GrpName);
groupglm(Ses,GrpName);
mview(Ses,GrpName);


