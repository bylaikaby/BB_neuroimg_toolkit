function show(SesName, DataFile, SigName, varargin)
%SHOW - Display signals using the "Sig.dsp.func" Function
% function show(SesName, EXPS, SigName)
%
% NKL 10.06.10
  
if nargin < 3,
  help show;
  return;
end;

Sig = sigload(SesName, DataFile, SigName);
if isempty(Sig),
  fprintf('Signal %s does not exist\n', SigName);
  return;
end;
  
if isstruct(Sig),
  feval(Sig.dsp.func, Sig);
else
  for N=1:length(Sig),
    feval(Sig{N}.dsp.func, Sig{N});
  end;
end;


