function SIG = mvoxmask(SIG1,SIG2)
%MVOXMASK - masks (logical AND) SIG1 with SIG2.
%  SIG = MVOXMASK(SIG1,SIG2) masks (logical AND) SIG1 with SIG2.
%    Time courses of returned SIG is compatible with SIG1, NOT with SIG2.
%
%  EXAMPLE :
%    >> sig1 = mvoxselect('e04ds1','visesmix','all','glm[2]',[],0.01);
%    >> sig2 = mvoxselect('e04ds1','visescomb','all','glm[1]',[],0.01);
%    >> sig12 = mvoxmask(sig1,sig2)
%    >> figure;  plot([mean(sig1.dat,2), mean(sig12.dat,2)]);
%
%  VERSION :
%    0.90 13.11.08 YM  pre-release
%
%  See also MVOXSELECT MVOXLOGICAL INTERSECT

if nargin < 2,  eval(sprintf('help %s;',mfilename)); return;  end


SIG = mvoxlogical(SIG1,'and',SIG2);


return
