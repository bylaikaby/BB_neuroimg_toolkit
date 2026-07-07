function oSig = sigrmfield(Sig,field,varargin)
%SIGRMFIELD - remove given field(s) from the signal structure.
%  oSig = sigrmfield(Sig,field) removes given field(s) from the signal structure.
%
%  NOTE :
%    - case insensitive.
%    - no error-break if "Sig" doesn't have the given "field".
%
%  EXAMPLE :
%    >> oSig = sigrmfield(Sig,{'ExpNo','stm','info'})
%
%  VERSION :
%    0.90 07.06.19 YM  pre-release
%
%  See also rmfield

if nargin < 2,  eval(['help ' mfilename]); return;  end

if numel(Sig) > 1
  if iscell(Sig),
    for N = 1:numel(Sig),
      oSig{N} = sigrmfield(Sig{N},field,varargin{:});
    end
  else
    for N = 1:numel(Sig)
      oSig(N) = sigrmfield(Sig(N),field,varargin{:});
    end
  end
  return
end

if ischar(field) && ~isrow(field)
  % converts char matrix to cell-str but leave char vector alone
  field = cellstr(field);
end

ifield = fieldnames(Sig);
[C,ia] = intersect(lower(ifield),lower(field));

if isempty(ia)
  % nothing to remove...
  oSig = Sig;
else
  oSig = rmfield(Sig,ifield(ia));
end

return
