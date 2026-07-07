function sescor(Ses,Exp)
%SESCOR - computes correlation and saves it into roiTs structure (Andrei)
% SESCOR(Ses,Exp) - stores r and p values into roiTs of an experiment  
% AB 07.09.04
  
  if nargin < 2,
	exps=getexps(Ses);
  elseif ischar(Exp),
	exps=getexps(Ses,Exp);
  else
	exps=Exp;
  end;
  grp = getgrp(Ses,exps(1));
  TrialID = -1;
  if isfield(grp,'actmap') & length(grp.actmap) > 1,
	TrialID = grp.actmap{2};
  end;
  
  for K=1:length(exps),
	sigload(Ses,exps(K),'roiTs');
	grp = getgrp(Ses,exps(K));
	if strncmp(grp.name,'spon',4) | strncmp(grp.name,'base',4),
	  for N=1:length(roiTs),
		roiTs{N}.r{1} = ones(1,size(roiTs{N}.dat,2));
		roiTs{N}.p{1} = zeros(1,size(roiTs{N}.dat,2));
	  end;
	else
	  mdlsct{1} = expgetstm(Ses,exps(K),'hemo');
	  if TrialID >= 0,
		pars = getsortpars(Ses,exps(K));
		TrialIndex = findtrialpar(pars,TrialID);
		for N=1:length(roiTs),
		  tmproiTs{N} = sigsort(roiTs{N},pars.trial);
		  tmproiTs{N} = tmproiTs{N}{TrialIndex};
		end;
		mdlsct{1} = sigsort(mdlsct{1},pars.trial);
		mdlsct{1} = mdlsct{1}{TrialIndex};
		tmproiTs = matscor(tmproiTs,mdlsct);
		for N=1:length(roiTs),
		  roiTs{N}.r = tmproiTs{N}.r;
		  roiTs{N}.p = tmproiTs{N}.p;
		end;
	  else
		roiTs = matscor(roiTs,mdlsct);
	  end;
	end;
	
	if ~nargout,
	  filename = catfilename(Ses, exps(K));
	  if exist(filename,'file'),
		save(filename,'-append','roiTs');
	  else
		save(filename,'roiTs');
	  end;
	  fprintf('sescor: roiTs saved in %s\n',filename);
	end;

  end;




