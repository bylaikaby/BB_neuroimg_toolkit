function grprf(SESSION, GrpName)
%GRPRF - Group all coherence data of a group
%
% ses.GrpCHSigs		= {'chLfp';'cfGamma';'chMua';'chSdf'};
% NKL 09.10.03

Ses = goto(SESSION);

if nargin < 2,
  grps = getgroups(Ses);
  grp = grps{1};
  GrpName = grp.name;
else
  grp = getgrpbyname(Ses,GrpName);
end;

sigs = Ses.ctg.GrpRFSigs;

if ~strncmp(GrpName,'movie',5),
  return;
end;

for N=1:length(sigs),
  filename = catfilename(Ses,grp.exps(1),'mat');
  ExistSigs = feval('who','-file',filename);
  NOSIG=1;
  for K=1:length(ExistSigs),
	if strcmp(ExistSigs{K},sigs{N}),
	  NOSIG=0;
	end;
  end;
  if NOSIG,
	fprintf('grprf: Signal %s is not in group %s\n',sigs{N},GrpName);
	continue;
  end;
  Sig = catmovie(Ses,GrpName,sigs{N});
  eval(sprintf('%s = Sig;', sigs{N}));
end;

filename = strcat(GrpName,'.mat');
if exist(filename,'file'),
  save(filename,'-append',sigs{:});
else
  fprintf('About to overwrite %s; are you sure?\n');
  pause;
  save(filename,sigs{:});
end;
fprintf('Saved RFestimates into %s\n',filename);



