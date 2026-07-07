function s = getexpinfo(SESSION,arg2)
%GETEXPINFO - Get information about SesName, ExpNo and Group
% GETEXPINFO (SESSION, ExpNo/GrpName)

if nargin < 2,
  error('usage: getexpinfo(SESSION,ExpNo/GrpName);');
end;

Ses = goto(SESSION);
if isa(arg2,'char'),
  GrpName=arg2;
  grp=getgrpbyname(Ses,GrpName);
  ExpNo = grp.exps(1);
else
  ExpNo = arg2;
  grp = getgrp(Ses,ExpNo);
  GrpName = grp.name;
end;

s = sprintf('Session: %s, GrpName: %s, ExpNo: %d',...
			Ses.name, GrpName, ExpNo);

