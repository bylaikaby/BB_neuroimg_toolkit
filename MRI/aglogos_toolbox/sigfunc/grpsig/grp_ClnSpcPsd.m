function oSig = grp_ClnSpcPsd(Ses,GRPEXPS,SigName)
%GRP_ROITS - groups ClnSpcPsd compatible signals
%  SIG = GRP_CLN(SESSION,GRP/EXPS)
%  SIG = GRP_CLN(SESSION,GRP/EXPS,SIGNAME)
%
%  VERSION :
%    0.90 11.10.05 YM  pre-release
%
%  See also GRPMAKE

if nargin < 2, help grp_ClnSpcPsd; return;  end

if nargin < 3, SigName = 'ClnSpcPsd';  end
oSig = {};


oSig = grp_MuaPsd(Ses,GRPEXPS,SigName);


return;

  