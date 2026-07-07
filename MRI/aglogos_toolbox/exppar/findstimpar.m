function [IDX, PAR] = findstimpar(SortPar,stimID)
%FINDSTIMPAR - Get index and parameters of stimID (SortPar is returned from getsortpar)
%
% USAGE : [IDX, PAR] = findstimpar(SortPar,stimID)
% EXAMPLE :
%   getstiminfo('c01ph1',17)
%   par = getsortpars('c01ph1',17)
%   [IDX,PAR] = findstimpar(par,0);
% VERSION : 0.90 18.04.04 YM   first release
%
% See also FINDTRIALPAR GESORTPAR GETSTIMINFO

if nargin ~= 2,  help findstimpar;  return;  end

IDX = [];  PAR = {};

if isfield(SortPar,'stim'),
  SortPar = SortPar.stim;
end

if ischar(stimID),
  IDX = find(strcmpi(SortPar.id,stimID));
else
  IDX = find(SortPar.id == stimID);
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

