function Sig = sigmedian(Sig,DIM)
%SIGMEDIAN - Compute Median of a signal along dimension DIM (default=1)
% NKL 01.08.04
  
if nargin < 2,
  DIM=1;
end;

Sig.err = iqr(Sig.dat,DIM);
Sig.dat = median(Sig.dat,DIM);


