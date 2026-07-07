function [IDX, PAR] = findtrialpar(SortPar,trialID)
%FINDTRIALPAR - Get index and parameters of trialID (SortPar is returned from getsortpar)
%
% USAGE : [IDX, PAR] = findtrialpar(SortPar,trialID)
% EXAMPLE :
%   gettrialinfo('c01ph1',17)
%   par = getsortpars('c01ph1',17)
%   [IDX,PAR] = findtrialpar(par,0);
% VERSION : 0.90 18.04.04 YM   first release
%
% See also FINDSTIMPAR GESORTPAR GETTRIALINFO

if nargin ~= 2,  help findtrialpar;  return;  end

IDX = [];  PAR = {};
  
if isfield(SortPar,'trial'),
  SortPar = SortPar.trial;
end

if ischar(trialID),
  IDX = find(strcmpi(SortPar.label,trialID));
else
  IDX = find(SortPar.id == trialID);
end

if nargout > 1,
  PAR = SortPar;
  % select IDX
  PAR.id = PAR.id(IDX);
  PAR.label = PAR.label{IDX};
  PAR.nrep = PAR.nrep(IDX);
  PAR.obs = PAR.obs{IDX};
  PAR.tonset = PAR.tonset{IDX};
  PAR.tlen = PAR.tlen{IDX};
  PAR.types = PAR.types{IDX};
  PAR.v = PAR.v{IDX};
  PAR.t = PAR.t{IDX};
  PAR.dt = PAR.dt{IDX};
  PAR.prmnames = PAR.prmnames{IDX};
  PAR.prmvals = PAR.prmvals{IDX};
end

return;

