% fix the wrong voxel resolution in tcImg of m02th1.
% 06.06.05 YM

SESSION = 'm02th1';
GRPNAME = 'mdeftinj';

Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);
EXPS = grp.exps;

try,
fprintf('%s: ',mfilename);
for iExp = 1:length(EXPS),
  fprintf('.');
  ExpNo = EXPS(iExp);
  matfile = sigfilename(Ses,ExpNo,'tcImg');
  tcImg = load(matfile,'tcImg');
  tcImg = tcImg.tcImg;
  %keyboard
  tcImg.ds = [0.4 0.4 0.4];
  save(matfile,'tcImg');
  if mod(iExp,25) == 0,
    fprintf('%d\n%s: ',iExp,mfilename);
  end
end
fprintf(' done.\n');


catch,
  fprintf('%s',lasterr);
  keyboard
end

  