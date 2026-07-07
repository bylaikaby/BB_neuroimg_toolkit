function sesclnadjevt(SESSION,EXPS,LOG)
%SESCLNADJEVT - Creates the ClnAdjEvt.mat file with corrected MRI events
%	NKL, 10.10.02
%
% For old data with multiple obsp:
%   if "grp.pvpar" is 1 in the session file, then CLNMAIN_PVAVR will be called.
%
%	See also
%
%	SESINFO - Display imaging/physiology information for session
%	CLNHELP - Explains the process
%	GETCLOCKERROR - Compute difference between qnx/Paravision clocks
%	CLNADJEVT - Fixup the random deviations of mri events
%	CLNMAIN - Main program to denoise the physiology signal
%	CLNADF - Actual cleaner

if nargin < 1,  help sesclnadjevt; return;  end

Ses = goto(SESSION);

if nargin < 3,
  LOG = 0;
end;

if ~exist('EXPS','var') || isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end


if LOG,
  LogFile=strcat('SESCLNADJEVT_',Ses.name,'.log');	% Start log file
  diary off;										% Close previous ones...
  hbackup(LogFile);									% Make a backup for history
  diary(LogFile);									% Start the new one
end;

fprintf('sesclnadjevt: ');
fprintf('**** CLNADJEVT -- Adjusting events...\n');
for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  grp   = getgrp(Ses,ExpNo);
  fprintf(' %s: %3d/%d[Exp%3d]',datestr(now,'HH:MM:SS'),N,length(EXPS),ExpNo);
  if isrecording(grp) && isimaging(grp),
    fprintf(' Processing %s...',expfilename(Ses,ExpNo,'phys'));
    if isfield(grp,'pvavr') && grp.pvavr > 0,
      % this is for old data acquisition like a003x1.
      clnadjevt_pvavr(Ses,ExpNo,0);
    else
      clnadjevt(Ses,ExpNo,0);
    end
    fprintf(' done.\n');
  else
    fprintf(' not Phys+MRI, ...skipped\n');
  end
end;

if LOG,
  diary off;										% Close log file
end;

