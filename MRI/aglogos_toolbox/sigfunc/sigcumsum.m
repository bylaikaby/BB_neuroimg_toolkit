function Sig = sigcumsum(Sig)
%SIGCUMSUM - Returns the cummulative sum of the Sig.dat field
% SIGCUMSUM(Sig) uses Matlab's cumsum function to compute a running
% sum for the signal Sig.
% NKL, 19.05.03

if length(Sig) == 1,
  tmp = Sig; clear Sig;
  Sig{1} = tmp; clear tmp;
end;

for N=1:length(Sig),
  Sig{N}.dat = cumsum(Sig{N}.dat);
end;

if length(Sig) == 1,
  Sig = Sig{1};
end;

