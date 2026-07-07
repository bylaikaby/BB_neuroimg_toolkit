function showcln(SesName, ExpNo)
%SHOWCLN - Show the cleaned signal, Cln, and its spectral power
% SHOWCLN(SesName, GrpExp)
%
% NKL 11.01.06
  
if nargin < 2,
  help showcln;
  return;
end;

Cln = sigload(SesName, ExpNo, 'Cln');

fCln = sigfft(Cln);

mfigure([100 100 1000 900]);
subplot(2,1,1);
dspsig(Cln);

subplot(2,1,2);
dspfft(fCln);

suptitle(sprintf('Session: %s, Exp: %d', SesName, ExpNo));

  