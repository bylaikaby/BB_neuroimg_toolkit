function sts = spcsts(Spc)
%SPCSTS - Get statistics of signal Spc.
% SPCSTS (Spc) returns a structure with the following statistics:
%
% See also SIGSTS SIGSPCSTS
%
% NKL V01 28.05.04

if ~nargin,
  help spcsts;
  return;
end;

sts.session     = Spc.session;
sts.grpname     = Spc.grpname;
sts.ExpNo       = Spc.ExpNo;
sts.dir         = Spc.dir;
sts.dir.dname   = 'spcsts';
sts.dsp         = Spc.dsp;
sts.dsp.func    = 'dspspcsts';
sts.dx          = Spc.dx;
sts.chan        = Spc.chan;


[sts.h,sts.t,sts.p] = sigttest(Spc);
keyboard

plot([0:size(Spc.dat,2)-1]*Spc.dx(2),hnanmean(squeeze(sts.p),2));



clear tmp;
nlags = floor(size(b.dat,1)/2);
sts.nlags       = nlags;
sts.nw          = NW;
NW = floor(size(s.dat,1)/nlags);
for N=1:size(b.dat,2),
  tmp = xcorr(b.dat(:,N),b.dat(:,N),nlags);
  sts.bacr(:,N) = tmp/max(tmp(:));
end;

sts.sacr = zeros(size(sts.bacr,1),size(s.dat,2));
for N=1:size(s.dat,2),
  clear tmp;
  for M=1:NW-1,
    ix1 = (M-1)*nlags + 1;
    ix2 = ix1 + nlags - 1;
    tmp(:,M) = xcorr(s.dat(ix1:ix2,N),s.dat(ix1:ix2,N),nlags);
  end;
  y = mean(tmp,2);
  sts.sacr(:,N) = y/max(y(:));
end;

alphaVal    = 0.01;
sts.tt      = DoTTest(b.dat,s.dat,alphaVal);

sts.bmedian  = median(b.dat,1);
sts.smedian  = median(s.dat,1);
for N=1:size(Spc.dat,2),
  sts.biqr(1,N) = iqr(b.dat(:,N));
  sts.siqr(1,N) = iqr(s.dat(:,N));
end;
return;

  




