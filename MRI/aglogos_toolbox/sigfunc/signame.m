function varargout = signame(Sig,NewName)
%SIGNAME - Get/Set the signal name.
%  SIGNAME = SIGNAME(SIG) gets the signal name.
%  SIG = SIGNAME(SIG,SIGNAME) sets the signal name.
%
%  VERSION :
%    01.02.12 YM  pre-release
%    14.04.13 YM  bug fix.
%
%  See also issig sigload siginfo

if nargin < 1,  help signame; return;  end

if nargin == 1,
  signame = sub_getname(Sig);
  varargout{1} = signame;
else
  Sig = sub_fixname(Sig,NewName);
  varargout{1} = Sig;
end


return


% ==========================================================
function SigName = sub_getname(Sig)

if iscell(Sig),
  if isempty(Sig),
    SigName = '';
  else
    SigName = sub_getname(Sig{1});
  end
  return
end

if isfield(Sig,'dir') && isfield(Sig.dir,'dname'),
  SigName = Sig.dir.dname;
else
  SigName = '';
end

return



% ==========================================================
function Sig = sub_fixname(Sig,NewName)
    
if iscell(Sig),
  for N = 1:numel(Sig),
    Sig{N} = sub_fixname(Sig{N},NewName);
  end
  return;
end
Sig.dir.dname = NewName;


return


