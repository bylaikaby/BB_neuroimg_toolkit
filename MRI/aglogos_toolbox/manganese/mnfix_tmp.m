
SESSION = 'm02th1';
GRPNAME = 'mdeftinj';

Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);


fprintf('%s: ',mfilename);
for N = 1:205,
  fprintf('.');
  %matfile = sprintf('TC_SLICE_RAW/%s_%s_sl%03d.mat',Ses.name,grp.name,N);
  matfile = sprintf('TC_SLICE_REALIGNED/%s_%s_sl%03d.mat',Ses.name,grp.name,N);
  load(matfile,'tcImg');
  sz = size(tcImg.dat);
  if length(sz) == 3,
    tcImg.dat = reshape(tcImg.dat,[sz(1),sz(2),1,sz(3)]);
    save(matfile,'tcImg');
  end
  if mod(N,25) == 0,
    fprintf('%d\n%s: ',N,mfilename);
  end
end
