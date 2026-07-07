function [Sig1dat, Sig2dat] = sigwhiten(Sig1dat,Sig2dat)
%SIGWHITEN - Whiten signal (remove stimulus-related modulations)
% SIGWHITEN (Sig1dat,Sig2dat) whitens Sig1dat and if Sig2dat exists applies the same filter
% to Sig2dat. The process is necessary for computing the IR function between Sig1dat and
% Sig2dat.
% NKL, 30.01.05

if nargin < 1,
  help sigwhiten;
  return;
end;

FLTORDER = 1;
tmp = Sig2dat;
if size(tmp,2)>1,
  tmp = hnanmean(tmp,2);
end;

if ~nargout,
  savSig1dat = Sig1dat;
end;

[tmp,b] = whiten(tmp,FLTORDER);
a = 1;

for N=1:size(Sig1dat,2),
  Sig1dat(:,N)=filter(b,a,Sig1dat(:,N));
end;

if nargin > 1,
  for N=1:size(Sig2dat,2),
    Sig2dat(:,N)=filter(b,a,Sig2dat(:,N));
  end;
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [odat,a] = whiten(dat,n)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
a = th2poly(ar(dat,n,'ls'));
odat = dat;
odat=filter(a,1,dat);
return;






