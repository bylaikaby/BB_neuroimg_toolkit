function TFAC = expgettfactor(Ses,ExpNo)
%EXPGETTFACTOR - returns timing factor for adf/evt/img.
%
%
% VERSION : 0.90 19.04.04 YM  first release
%
% See also EXPGETPAR GETSORTPARS

if nargin == 0,  help expgettfactor;  return;  end

if nargin == 1,
  if isfield(Ses,'evt') & isfield(Ses,'stm'),
    ExpPar = Ses;
  end
else
  ExpPar = expgetpar(Ses,ExpNo);
end

if isempty(ExpPar.adf),
  TFAC.adf = 1.0;
else
  TFAC.adf = ExpPar.adf.tfactor;
end

TFAC.evt = ExpPar.evt.tfactor;
TFAC.img = 1.0;


return;
