function Sig = sigdiff(Sig,Order)
%SIGDIFF - Computes derivative of order "Order"
% SIGDIFF(Sig) uses Matlab's diff function to compute differences
% (or derivatives) of the Sig.dat field.
% NKL, 19.05.03

if nargin < 2,
  Order = 1;
end;

if length(Sig) == 1,
  tmp = Sig; clear Sig;
  Sig{1} = tmp; clear tmp;
end;

for N=1:length(Sig),
  Sig{N}.dat = diff(Sig{N}.dat,Order);
end;

if length(Sig) == 1,
  Sig = Sig{1};
end;

