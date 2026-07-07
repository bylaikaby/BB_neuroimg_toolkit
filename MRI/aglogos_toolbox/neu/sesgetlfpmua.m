function sesgetlfpmua(SESSION,EXPS,LOG)
%SESGETLFPMUA - Get pLFP/pMUA etc by calling the function GETLFPMUA
%
%	VERSION : 1.00 NKL, 28.04.03
%
%	See also EXPGETBLP, BANDSEP, CLN2BAND, GETBANDMEAN, EXPGETBANDS

Ses = goto(SESSION);

if nargin < 3,
  LOG=0;
end;

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

if LOG,
  LogFile=strcat('SESGETLFPMUA_',Ses.name,'.log');	% Start log file
  diary off;										% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);									% Start the new one
end;

for ExpNo = EXPS,
  grp = getgrp(Ses,ExpNo);

  if isfield(grp,'done') & grp.done,
	continue;
  end;

  if ~isrecording(Ses,grp.name),
	continue;
  end;
  fprintf('Processing Group: %s, ExpNo = %d\n', grp.name,ExpNo);
  getlfpmua(Ses,ExpNo);
end;

if LOG,
  diary off;
end;

