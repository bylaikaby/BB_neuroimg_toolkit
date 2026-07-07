%   c99sl1               - - Mn Injection 20-22.10.04 (left eye)
%   d03se1               - - Mn Injection 13-18.10.04 (right eye)
%   m02th1               - - Mn Injection 17-22.12.04 (right eye)
%   o02wu1               - - Mn Injection 04,07,11.07.2005 (left eye)


%SESSIONS = {'c99sl1','d03se1','m02th1','o02wu1'};
SESSIONS = {'c99sl1','d03se1','o02wu1','m02th1'};

for N = 4:length(SESSIONS),
  SESSION = SESSIONS{N};
  GRPNAME = 'mdeftinj';
  mk_spmmask(SESSION,GRPNAME);
  mnrealign(SESSION,GRPNAME);
  %close all;
  mndenoise_pca(SESSION,GRPNAME);
  mnnormalize(SESSION,GRPNAME);
  mnttest(SESSION,GRPNAME);
end
