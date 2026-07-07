function sesdecmain(SESSION,EXPS)
%SESDECMAIN - Read ADF files and eliminate gradient interference
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
  names = fieldnames(Ses.grp);
  for N=1:length(names),
	fprintf('sesdecmain: Processing group %s\n', names{N});
	if strncmp(names{N},'movie',5),
	  eval(sprintf('grp = Ses.grp.%s;',names{N}));
	  for ExpNo = grp.exps,
		fprintf('sesdecmain[vdecmain]: Experiment: %d ', ExpNo);
		vdecmain(Ses,ExpNo);
		fprintf('\n');
	  end;
	else
	  eval(sprintf('grp = Ses.grp.%s;',names{N}));
	  for ExpNo = grp.exps,
		fprintf('sesdecmain[decmain]: Experiment: %d ', ExpNo);
		decmain(Ses,ExpNo);
		fprintf('\n');
	  end;
	end;
  end;
else
  if isa(EXPS,'char'),
	GrpName = EXPS;
	grp = getgrpbyname(Ses,GrpName);
	for ExpNo = grp.exps,
	  fprintf('sesdecmain[vdecmain]: Group: %s, Experiment: %d ',...
			  grp.name, ExpNo);
	  if strncmp(GrpName,'movie',5),
		vdecmain(Ses,ExpNo);
	  else
		decmain(Ses,ExpNo);
	  end;
	  fprintf('\n');
	end;
  else
	for ExpNo = EXPS,
	  grp = getgrp(Ses,ExpNo);
	  fprintf('sesdecmain[vdecmain]: Group: %s, Experiment: %d ',...
			  grp.name, ExpNo);
	  if strncmp(grp.name,'movie',5),
		vdecmain(Ses,ExpNo);
	  else
		decmain(Ses,ExpNo);
	  end;
	end;
  end;
end;

  
	
	
	

