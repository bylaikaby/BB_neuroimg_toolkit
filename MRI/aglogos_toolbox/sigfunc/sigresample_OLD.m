function oSig = sigresample(Sig,NewFs,Len)
%SIGRESAMPLE - Resample signal Sig at sampling rate of NewFs
% oSig = SIGRESAMPLE(Sig,NewFs,Len)
% NKL 11.03.04
  
nyq = (1/Sig.dx)/2;
s = size(Sig.dat);
oSig = rmfield(Sig,'dat');
oSig.dx = 1/NewFs;
[p,q] = rat(Sig.dx/oSig.dx,0.0001);

Sig.dat = reshape(Sig.dat,[s(1) prod(s(2:end))]);
for N=1:size(Sig.dat,2),
  oSig.dat = resample(Sig.dat,p,q);
end;

if ~exist('Len'),
  Len = size(oSig.dat,1);
end;

if size(oSig.dat,1) > Len,
  oSig.dat = oSig.dat(1:Len,:);
elseif size(oSig.dat,1) < Len,
  l = Len - size(oSig.dat,1);
  s = size(oSig.dat);
  s(1) = l;
  apnd = zeros(s);
  oSig.dat = cat(1,oSig.dat,apnd);
end;

s(1)=size(oSig.dat,1);
oSig.dat = reshape(oSig.dat,s);

return;
