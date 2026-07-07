function cblp = sesconvblp(SesName,EXPS,LOG)
%SESCONVBLP - Convolve BLP signals of a session (calls expconvblp)
%
% SESCONVBLP (SesName, GrpName, LOG) will load the blp signals of each experiment of each group
% GrpName and save the results in the coresponding mat file.
%
% See also EXPCONVBLP SIGCONV SESGETHRF
%
% NKL 01.08.04
  

Ses = goto(SesName);

if nargin < 3,
  LOG = 0;
end;

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;

% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

if LOG,
  LogFile=strcat('SESGETHRF_',Ses.name,'.log');	% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end;

for ExpNo = EXPS,
  expconvblp(Ses,ExpNo);
end;

if LOG,
  diary off;
end;


