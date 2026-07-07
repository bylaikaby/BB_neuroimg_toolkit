function sesgetrfdyn(SESSION,EXPS,LOG)
%SESGETRF - Compute RF of the cells by means of reverse correlation.
% SESGETRF - The function read the bandpass signal (e.g. Lfp, Mua)
% and determines the times at which the signal passes through a
% particular value determined by the user. It then uses this time
% information to determine the vide frames that were presented at
% those times. 
%	
%	See also
%	Utilities
%	=========================================================================
%	CLNHELP - This file
%	SESINFO - Display imaging/physiology information for session
%	GETCLOCKERROR - Compute difference between QNX/Paravision clocks
%
%	Functions to do the actual denoising
%	=========================================================================
%	CLNADJEVT - Fixup the random deviations of MRI events
%	CLNMAIN - Main program to denoise the physiology signal
%	CLNADF - Actual cleaner

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

Frame		= 1;		% For display purposes
RFSigs		= {'LfpH';'Mua'};
TOFFSET		= [0];
LFP_THR		= [3];
MUA_THR		= [3];
BadRFChan	= [15];		% For display purposes

if isfield(Ses,'revcor'),
  ARGS = Ses.revcor;
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

fprintf('sesgetrfdyn: Extracting site-RF for session %s\n',Ses.name);

% FORCE TO SET NonAvg as 1000 ?????????????????????????????/
ARGS.NO_AVG = 1000;

for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  grp = getgrp(Ses,ExpNo);
  if strncmp(grp.name,'movie',5),
    fprintf('%s: sesgetrfdyn [%d/%d] %s, %s, ExpNo=%d\n',...
            gettimestring,N,length(EXPS),Ses.name,grp.name,ExpNo);
	getrfdyn(Ses,ExpNo,ARGS);
  end;
end;


if LOG,
  diary off;
end;
