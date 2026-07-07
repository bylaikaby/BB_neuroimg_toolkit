function infoinfo(SesName,ExpNo)
%INFOINFO - Display the .info field of the roiTs structure
% INFOINFO (roiTs) displays all filtering and preprocessing parameters of roiTs
% NKL 17.12.07

Ses = goto(SesName);
EXPS = validexps(Ses);

if nargin < 2,
  ExpNo = EXPS(1);
end;

roiTs = sigload(Ses,ExpNo,'roiTs');

fprintf('Session: [%s], ExpNo = %d, roiTs.info\n', upper(SesName), ExpNo);
roiTs{1}.info
