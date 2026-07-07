function Sig = sigtosdu(Sig)
%SIGTOSDU - Convert Signal to baseline-SD Units
% SIGTOSDU(Sig) computes mean and SD of the blank periods and
% converts the singal in SD units after removing the mean.
% NKL, 19.05.03

DoUndo = 0;
if isstruct(Sig),
  DoUndo = 1;
  Sig = {Sig};
end;

for N=1:length(Sig),
  Sig{N} = tosdu(Sig{N});
end;

if DoUndo,
  Sig = Sig{1};
end;



