function Sig = sigdetrend(Sig,varargin)
%SIGDETREND - Detrend data fields of signal Sig (e.g. Cln, Lfp)
% SIGDETREND(Sig) uses Matlab's detrend function to get rid of linear trends in the data.
%
%  VERSION :
%    1.00 19.05.03 NKL
%    1.01 06.02.12 YM   clean-up, supports all args for detend().
%
%  See also detrend reshape

if nargin < 1,  help sigdetrend; return;  end

if iscell(Sig)
  for N = 1:length(Sig),
    Sig{N} = sigdetrend(Sig{N},varargin{:});
  end
  return
end

s = size(Sig.dat);
Sig.dat = reshape(Sig.dat,[s(1) prod(s(2:end))]);
Sig.dat = detrend(Sig.dat,varargin{:});
Sig.dat = reshape(Sig.dat,s);

if isfield(Sig, 'base'),
  s = size(Sig.base);
  Sig.base = reshape(Sig.base,[s(1) prod(s(2:end))]);
  Sig.base = detrend(Sig.base,varargin{:});
  Sig.base = reshape(Sig.base,s);
end;
return



