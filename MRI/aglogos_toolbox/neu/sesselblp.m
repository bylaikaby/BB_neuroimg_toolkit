function sesselblp(SesName,EXPS,LOG)
%SESSELBLP - Selects stimulus/mri-correlated frequency bands based on r-value
% SESSELBLP (SesName,EXPS,LOG) calls EXPSELBLP and SIGSELBLP to select individual frequency
% bands that best modulate together with the stimulus or the fMRI signal.
%
% See also EXPSELBLP SIGSELBLP
% NKL, 04.08.04

Ses = goto(SesName);

if nargin < 3,
  LOG = 0;
end;

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;

% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

SAVEIT = 1;

names = {'model';'roiTs'};
for ExpNo = EXPS,
  cblp = expselblp(Ses,ExpNo,SAVEIT);
end;

if LOG,
  LogFile=strcat('SESSELBLP_',Ses.name,'.log');	% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end;

if LOG,
  diary off;
end;

