function atsescohere(SESSION,arg2,cfgType)
%ATSESCOHERE - Compute interelectrode coherence
% ATSESCOHERE - Computes coherence for different distances
%	
%	See also
%	SIGCOHERE EXPCOHERE

if ~nargin,
  error('usage: atsescohere(SESSION, ExpNo/GrpName');
end

if nargin < 3,
  cfgType = 'wire';
end;

Ses = goto(SESSION);

if nargin & nargin < 2,
  arg2 = [];
end;

if exist('arg2','var') & isa(arg2,'char'),
  GrpName = arg2;
  grp = getgrpbyname(Ses,GrpName);
  EXPS = grp.exps;
else
  if isempty(arg2),
	EXPS = validexps(Ses);
  else
	EXPS = arg2;
  end;
end;

fprintf('atsescohere: Computing coherence for session %s\n',Ses.name);

for ExpNo = EXPS,
  grp = getgrp(Ses,ExpNo);
  atexpcohere(Ses,ExpNo,cfgType);
end;

