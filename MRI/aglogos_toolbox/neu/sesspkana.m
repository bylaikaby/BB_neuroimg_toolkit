function sesspkana(SESSION,EXPS,LOG)
%SESSPKANA - Spike-triggered analysis (spkana)
%	NKL, 10.10.02
%	See also SIGSPC, SHOWSPC0, SHOWSPC3

Ses = goto(SESSION);

if nargin < 3,
  LOG = 0;
end;

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

if LOG,
  LogFile=strcat('SESSPKANA_',Ses.name,'.log');	% Start log file
  diary off;										% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);									% Start the new one
end;

for ExpNo = EXPS,
  spkana(Ses,ExpNo);
end;

if LOG,
  diary off;
end;

