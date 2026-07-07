function sesgetstat(SesName, EXPS, LOG)
%SESGETSTAT - Invokes EXPGETSTAT for each experiment of session "SesName"
% SESGETSTAT runs EXPGETSTAT for each experiment in EXPS. The sts
% structures of each experiment are saved in the corresponding MAT
% file, for further grouping and analysis.
%    
% VERSION : 1.00 NKL, 28.04.03
%
% See also EXPGETSTAT DSPSTAT

EXCLUDES = {'spont','baseline'};

Ses = goto(SesName);

if nargin < 3,
  LOG=0;
end;

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;

% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

if LOG,
  LogFile=strcat('SESGETSTAT_',Ses.name,'.log');	% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end;

for ExpNo = EXPS,
  filename = catfilename(Ses,ExpNo);
  grp = getgrp(Ses,ExpNo);
  if any(strncmp(EXCLUDES,grp.name,5)),
    continue;
  end;

  if isfield(grp,'done') & grp.done,
	continue;
  end;

  fprintf('%s: Proc Ses: %s, Group: %s, ExpNo = %d\n', ...
          gettimestring, Ses.name, grp.name,ExpNo);
  expgetstat(Ses, ExpNo);
end;

if LOG,
  diary off;
end;

