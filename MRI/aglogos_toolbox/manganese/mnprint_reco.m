function mnprint_reco(SESSION,GRPNAME)
%MNPRINT_RECO - Prints reco information.
%  MNPRINT_RECO(SESSION,GRPNAME) prints "reco" information.
%
%  VERSION :
%    0.90 21.06.05 YM   pre-release
%
%  See also EXPGETPAR

  
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);


EXPS = grp.exps;

fprintf('SESSION: %s  GROUP: %s\n',Ses.name,grp.name);
fprintf('ExpNo: RECO_maxima RECO_map_range  RECO_map_percentile\n');
for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  par = expgetpar(Ses,ExpNo);
  reco = par.pvpar.reco;
  fprintf(' %3d: %d  [%d %d]   [%.3f %.3f]\n',ExpNo,reco.RECO_maxima,...
          reco.RECO_map_range(1),reco.RECO_map_range(2),...
          reco.RECO_map_percentile(1),reco.RECO_map_percentile(2));
end
