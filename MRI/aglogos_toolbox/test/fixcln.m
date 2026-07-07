function fixcln(SESSION)
%FIXCLN - Separate Cln from all other signals
% FIXCLN Puts cln under CLNDATA and keeps the rest of the files
% small..
% s02: Cln LfpH LfpL LfpM Mua Sdf Spkt VLfpH3 VMua3 VSdf3 
Ses = goto(SESSION);

switch Ses.name,
 case {'c98nm1' 'c98nm2' 'a98nm1'},
  SIGS = {'Lfp'; 'Gamma'; 'LfpH'; 'LfpL'; 'LfpM'; 'Mua'; 'Sdf';'Spkt'};
  VSIGS = {'Lfp'; 'Gamma'; 'LfpH'; 'LfpL'; 'LfpM'; 'Mua'; 'Sdf';...
		   'Spkt'; 'VLfpH3'; 'VMua3'; 'VSdf3'};
  DoSplit1(Ses,SIGS,VSIGS);
 case {'r97nm1'},
  SIGS = {'LfpH'; 'LfpL'; 'LfpM'; 'Sdf';'Spkt'};
  VSIGS = {'Spkt'; 'Sdf'; 'LfpH'; 'LfpL'; 'LfpM'; 'VLfpH3'; 'VMua3'; 'VSdf3'};
  DoSplit2(Ses,SIGS,VSIGS);
 case {'s02nm1' 'g02nm1' 'g97nm1'},
  SIGS = {'LfpH'; 'LfpL'; 'LfpM'; 'Mua'; 'Sdf';'Spkt'};
  VSIGS = {'LfpH'; 'LfpL'; 'LfpM'; 'Mua'; 'Sdf';'Spkt';'VLfpH3'; 'VMua3'; 'VSdf3'};
  DoSplit1(Ses,SIGS,VSIGS);
 otherwise
  fprintf('fixcln: do not know what to do with %s\n', Ses.name);
  return;
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoSplit1(Ses,SIGS,VSIGS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('CLNDATA','dir'),	mkdir(pwd,'CLNDATA'); end;
EXPS = validexps(Ses);
for N=1:length(EXPS),
  ExpNo = EXPS(N);
  grp = getgrp(Ses,ExpNo);
  if strncmp(grp.name,'movie',5),
	tmpSIGS = VSIGS;
  else
	tmpSIGS = SIGS;
  end;
  
  filename=catfilename(Ses,ExpNo,'mat');
  clnfilename=catfilename(Ses,ExpNo,'cln');
  fprintf('%3d/%3d %s Fixing file %s\n', ...
		  N, length(EXPS), gettimestring, filename);
  load(filename,'Cln');
  save(clnfilename,'Cln');
  clear Cln;
  
  clear(tmpSIGS{:});
  load(filename,tmpSIGS{:});
  save(filename,tmpSIGS{:});
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoSplit2(Ses,SIGS,VSIGS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('CLNDATA','dir'),	mkdir(pwd,'CLNDATA'); end;
EXPS = validexps(Ses);
for N=1:length(EXPS),
  ExpNo = EXPS(N);
  grp = getgrp(Ses,ExpNo);
  if strncmp(grp.name,'movie',5),
	tmpSIGS = VSIGS;
  else
	tmpSIGS = SIGS;
  end;
  
  filename=catfilename(Ses,ExpNo,'mat');
  load(filename,tmpSIGS{:});
  save(filename,tmpSIGS{:});
  fprintf(' %s fixcln: processed file %s\n', gettimestring,filename);
end;


