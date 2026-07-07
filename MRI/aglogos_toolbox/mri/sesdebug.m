function oSig = sesdebug(SESSION,GrpName)
%SESDEBUG - Debug GLM analysis on all group files
%  oSig = sesdebug(Ses,GrpName)
%
%  VERSION :
%    0.90 12.01.06 YM  pre-release
%
%  See also CATSIG GRPMAKE

if nargin < 2,  eval(sprintf('help %s;',mfilename)); return;  end

Ses  = goto(SESSION);

fprintf('SESDEBUG: [seareats, sesgettrial, sesgrpmake, GLM/COR]\n');
infogrp(Ses,GrpName);

sesareats(Ses,GrpName);
sesgettrial(Ses,GrpName);
sesgrpmake(Ses,GrpName);

groupglm(Ses,GrpName);
if 0,
  groupcor(Ses,GrpName);
end;
  
mview(Ses,GrpName);


