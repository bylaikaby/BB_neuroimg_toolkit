function Sig = sigmean(Sig,DIM)
%SIGMEAN - Compute the mean of a signal along dimension DIM (default=1)
% NKL 01.08.04
  
if nargin < 2,
  DIM=1;
end;

Sig.err = std(Sig.dat,1,DIM)/sqrt(size(Sig.dat,DIM));
Sig.dat = mean(Sig.dat,DIM);


