function atsesconvert(SESSION,arg2,LOG)
%ATSESCONVERT - Converts Andreas' data
% ATSESCONVERT - Converts alert monkey tetrode data to our structures
%	
%	See also
%	ATCONVERT ATGETSPIKES ATGETCLN ATGETLFP

if nargin == 0,
  error('usage: atsesconvert(SESSION, ExpNo/GrpName, [LOG]');
end

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

if nargin < 3,
  LOG = 0;
end;

if LOG,
  LogFile=strcat('ATCONVERT_',Ses.name,'.log');		% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end;

fprintf('atsesconvert: Computing coherence for session %s\n',Ses.name);

for ExpNo = EXPS,
  atconvert(Ses,ExpNo);
end;

if LOG,
  diary off;
end;

