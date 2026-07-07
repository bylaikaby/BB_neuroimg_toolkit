function sesclnmain(SESSION,EXPS,LOG)
%SESCLNMAIN - Read ADF files and eliminate gradient interference
%	This function is used immediately after the creation of the session
%	parameter file PARSesName.mat, which includes all image and
%	neural data. The latter file is used by calling sespardump(SESSION),
%	and serves also as "check-out" routine to ensure integrity of files
%	etc.
%	NKL, 10.10.02
%
%	See also
%
%	SESINFO - Display imaging/physiology information for session
%	CLNHELP - Explains the process
%	GETCLOCKERROR - Compute difference between qnx/Paravision clocks
%	CLNADJEVT - Fixup the random deviations of mri events
%	CLNMAIN - Main program to denoise the physiology signal
%	CLNADF - Actual cleaner

Ses = goto(SESSION);

if nargin < 3,
  LOG=0;
end;

if nargin < 2,
  EXPS = validexps(Ses);
end;

if LOG,
  LogFile=strcat('SESCLNMAIN_',Ses.name,'.log');	% Start log file
  diary off;										% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);									% Start the new one
end;

for ExpNo = EXPS,
  grp = getgrp(Ses,ExpNo);
  if isfield(grp,'done') & grp.done,
	continue;
  end;
  
  if isrecording(Ses,grp.name) & isimaging(Ses,grp.name),
	clnmain(Ses,ExpNo);
  end;
end;

if LOG,
  diary off;										% Close log file
end;











