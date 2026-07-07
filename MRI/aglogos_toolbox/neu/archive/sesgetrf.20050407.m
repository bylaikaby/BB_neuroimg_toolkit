function sesgetrf(SESSION,EXPS,LOG)
%SESGETRF - Compute RF of the cells by means of reverse correlation.
% SESGETRF - The function read the bandpass signal (e.g. Lfp, Mua)
% and determines the times at which the signal passes through a
% particular value determined by the user. It then uses this time
% information to determine the vide frames that were presented at
% those times. 
%	
% See also GETRF, VGETFRAMEDATA, VDECMAIN, VCLNMAIN, VGETFRAMEDATA

if nargin == 0,
  SESSION = 'c98nm1';
  EXPS = [1];
end

Ses = goto(SESSION);
if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end


if isfield(Ses.anap,'revcor'),
  ARGS = Ses.anap.revcor;
end;  

if nargin < 3,
  LOG = 0;
end;

if LOG,
  LogFile=strcat('GETRF_',Ses.name,'.log');		% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end;

if isfield(Ses,'revcor'),
end;

fprintf('sesgetrf: Extracting site-RF for session %s\n',Ses.name);

for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  grp = getgrp(Ses,ExpNo);
  if strncmp(grp.name,'movie',5),
    fprintf('%s: sesgetrf [%d/%d] %s, %s, ExpNo=%d\n',...
            gettimestring,N,length(EXPS),Ses.name,grp.name,ExpNo);
	getrf(Ses,ExpNo,ARGS);
  end;
end;


if LOG,
  diary off;
end;
