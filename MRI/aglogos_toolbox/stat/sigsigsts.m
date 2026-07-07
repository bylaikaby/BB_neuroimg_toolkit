function sts = sigsigsts(Sig1, Sig2, COV)
%SIGSIGSTS - Computes cross-correlation and cross-covarinace
% SIGSIGSTS (Sig1, Sig2) - Computes cross-correlation and cross-covarinace
% between different signals.
% NKL V01 28.05.04

if nargin < 3,
  COV = 1;
end;

if ~nargin,
  help sigsigsts;
  return;
end;

if length(size(Sig1.dat)) > 2,
  fprintf('SIGSIGSTS: expects a two-dimensional matrix\n');
  keyboard;
end;

if length(size(Sig2.dat)) > 2,
  fprintf('SIGSIGSTS: expects a two-dimensional matrix\n');
  keyboard;
end;

if Sig1.dx ~= Sig2.dx,
  fprintf('SIGSIGSTS: expects the same sampling rate for Sig1/Sig2\n');
  keyboard;
end;

if ~strcmp(Sig1.session,Sig2.session) | ...
  ~strcmp(Sig1.grpname,Sig2.grpname) | ...
  Sig1.ExpNo ~= Sig2.ExpNo,
  fprintf('SIGSIGSTS: signals must be from the same experiment\n');
  keyboard;
end;

HemoDelay1 = 0;
if strcmp(lower(Sig1.dir.dname),'roits'),
  HemoDelay1 = 2;
end;

HemoDelay2 = 0;
if strcmp(lower(Sig2.dir.dname),'roits'),
  HemoDelay2 = 2;
end;

b1 = sigselepoch(Sig1,'blank',HemoDelay1);
s1 = sigselepoch(Sig1,'nonblank',HemoDelay1);
Sig1.dat = [];

b2 = sigselepoch(Sig2,'blank',HemoDelay2);
s2 = sigselepoch(Sig2,'nonblank',HemoDelay2);
Sig2.dat = [];

nlags = floor(size(b1.dat,1)/2);
NW = floor(size(s1.dat,1)/nlags);

sts.session     = Sig1.session;
sts.grpname     = Sig1.grpname;
sts.ExpNo       = Sig1.ExpNo;
sts.dir         = Sig1.dir;
sts.dir.dname   = 'sigsigsts';
sts.dsp         = Sig1.dsp;
sts.dsp.func    = 'dspsigsigsts';
sts.dx          = Sig1.dx;
sts.nlags       = nlags;
sts.nw          = NW;
sts.chan        = Sig1.chan;

clear tmp;
for NN=1:size(b1.dat,2),
  for N=1:size(b2.dat,2),
    if COV,
      tmp = xcov(b1.dat(:,NN),b2.dat(:,N),nlags);
    else
      tmp = xcorr(b1.dat(:,NN),b2.dat(:,N),nlags);
    end;
    sts.bacr(:,N,NN) = tmp/max(tmp(:));
  end;
end;

sts.sacr = zeros(size(sts.bacr,1),size(s1.dat,2),size(s2.dat,2));
for NN=1:size(s1.dat,2),
  for N=1:size(s2.dat,2),
    clear tmp;
    for M=1:NW-1,
      ix1 = (M-1)*nlags + 1;
      ix2 = ix1 + nlags - 1;
      if COV,
        tmp(:,M) = xcov(s1.dat(ix1:ix2,NN),s2.dat(ix1:ix2,N),nlags);
      else
        tmp(:,M) = xcorr(s1.dat(ix1:ix2,NN),s2.dat(ix1:ix2,N),nlags);
      end;
    end;
    y = mean(tmp,2);
    sts.sacr(:,N,NN) = y/max(y(:));
  end;
end;
return;

  




