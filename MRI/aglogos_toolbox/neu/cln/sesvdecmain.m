function sesvdecmain(SESSION,EXPS)
%SESVDECMAIN - Read ADF files and eliminate gradient interference
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

Ses = goto(SESSION);

if nargin < 2,
  EXPS = validexps(Ses);
end;

names = fieldnames(Ses.grp);
for N=1:length(names),
  fprintf('sesvdecmain: Processing group %s\n', names{N});
  if strncmp(names{N},'movie',5),
	eval(sprintf('grp = Ses.grp.%s;',names{N}));
	for ExpNo = grp.exps,
	  fprintf('sesvdecmain[vdecmain]: Experiment: %d ', ExpNo);
	  vdecmain(Ses,ExpNo);
	  fprintf('\n');
	end;
  end;
end;
