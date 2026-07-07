function varargout = issig(Sig)
%ISSIG - Returns 1 if the input is a signal structure.
%  V = ISSIG(SIG) returns 1 if SIG is a signal sturcture, otherwise 0.
%  [V info] = ISSIG(SIG) returns also information about the signal.
%
%  VERSION :
%    0.90 12.01.06 YM  pre-release
%    0.91 23.04.06 YM  supports the case where the groupname changed after Sig generation.
%    1.00 15.04.13 YM  uses siginfo().
%
%  See also signame siginfo

if nargin == 0;  eval(sprintf('help %s;',mfilename)); return;  end

value = 0;

if iscell(Sig),
  value = issig(Sig{1});
elseif isstruct(Sig),
  if isfield(Sig,'dat') && (isfield(Sig,'dx') || isfield(Sig,'ds')),
    value = 1;
  end
else
end


varargout{1} = value;
if nargout > 1,
  varargout{2} = siginfo(Sig);
end


return;
