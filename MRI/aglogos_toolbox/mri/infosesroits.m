function infosesroits(SESSION)
%INFOSESROITS - Display names and slice-number of roiTs structure
% INFOSESROITS (roiTs) displays the .name and .slice fields of the
% roiTs structure.
% NKL 16.05.04

Ses = goto(SESSION);
EXPS = validexps(Ses);

for N=1:length(EXPS),
  roiTs = sigload(Ses,EXPS(N),'roiTs');

  for K=1:length(roiTs),
    if iscell(roiTs{1}),
      fprintf('%3d %s/%s/%d: %s\n',...
              K, roiTs{K}{1}.session, roiTs{K}{1}.grpname, roiTs{K}{1}.ExpNo, roiTs{K}{1}.name);
    else
      fprintf('%3d %s/%s/%d: %s\n',...
              K, roiTs{K}.session, roiTs{K}.grpname, roiTs{K}.ExpNo, roiTs{K}.name);
    end;
  end;

end;

