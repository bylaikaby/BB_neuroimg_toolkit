function tstwin(SESSION,GrpName,SigName)
%TSTWIN - Test the effects of window (PSTH bin width) on independence
% NKL 22.10.03

if ~nargin,
  SESSION = 'c98nm1';
  GrpName = 'movie1';
end;

if nargin < 3,
  SigName='all';
end;

Ses = goto(SESSION);
grp = getgrpbyname(Ses,GrpName);

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COHERENCE
%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(SigName,'ch') | strcmp(SigName,'all'),
  for N=1:length(grp.exps),
	ExpNo = grp.exps(N);
	chw{N} = DoTstCHWin(Ses,ExpNo);
  end;
  
  try,
	chw{1}.val = chw{1}.val(:);
	for N=2:length(grp.exps),
	  chw{1}.val = cat(2,chw{1}.val,chw{N}.val(:));
	end;
	chw = chw{1};
  catch,
	disp(lasterr);
	keyboard;
  end;
  
  fname = strcat(GrpName,'.mat');
  if exist(fname,'file'),
	save(fname,'-append','chw');
  else
	save(fname,'chw');
  end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% KERNEL COVARIANCE
%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(SigName,'cf') | strcmp(SigName,'all'),
  for N=1:length(grp.exps),
	ExpNo = grp.exps(N);
	cfw{N} = DoTstCFWin(Ses,ExpNo);
  end;
  
  try,
	cfw{1}.val = cfw{1}.val(:);
	for N=2:length(grp.exps),
	  cfw{1}.val = cat(2,cfw{1}.val,cfw{N}.val(:));
	end;
	cfw = cfw{1};
  catch,
	disp(lasterr);
	keyboard;
  end;
  
  fname = strcat(GrpName,'.mat');
  if exist(fname,'file'),
	save(fname,'-append','cfw');
  else
	save(fname,'cfw');
  end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cfw = DoTstCFWin(SESSION,ExpNo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);
cf = Ses.confunc;

filename = catfilename(Ses,ExpNo);
load(filename,'Sdf');

MYARGS.EPOCH	= 1;
MYARGS.SESINFO	= Sdf.session;

fprintf('Computing SDF coh-func for Session %s, ExpNo %d\n',Ses.name,ExpNo);
NoIter=16;

%%%%%%%%%%%%%%% ??????? If more time available we can start from 1 !!
for K=2:NoIter,
  spRate		= Sdf;
  spRate.dat	= [];
  
  DecFac = K^2;
  spRate.dat = DoDecimate(Sdf,DecFac);
  spRate.dx = Sdf.dx * DecFac;
  spRate.dir.dname = 'spRate';
  Sig = sigconfunc(spRate, 'kc',1,cf);
  top = max(Sig.kc.selfconts);
  cfavg = getSigConAvg( Sig, 'kc');
  tmp = cfavg.dmean/top;
  cfw.val(K) = nanmean(tmp);
  cfw.win(K) = spRate.dx;
end;

if ~nargout,
  save(GrpFileName,'-append','cfw');
  fprintf('tstwin: spRate appended in %s\n', filename);
else
  fprintf('DoTstWin: Computed cfw for ExpNo = %d\n', ExpNo);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function chw = DoTstCHWin(SESSION,ExpNo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);

filename = catfilename(Ses,ExpNo);
load(filename,'Sdf');

MYARGS.EPOCH	= 1;
MYARGS.SESINFO	= Sdf.session;

fprintf('Computing SDF coh-func for Session %s, ExpNo %d\n',Ses.name,ExpNo);
NoIter=13;
for K=1:NoIter,
  spRate		= Sdf;
  spRate.dat	= [];
  
  DecFac = K^2;
  spRate.dat = DoDecimate(Sdf,DecFac);
  spRate.dx = Sdf.dx * DecFac;
  spRate.dir.dname = 'spRate';
  Sig = sigcohere(spRate,MYARGS);
  chw.val(K) = nanmean(Sig.dat(:));
  chw.win(K) = spRate.dx;
end;

if ~nargout,
  save(GrpFileName,'-append','chw');
  fprintf('tstwin: spRate appended in %s\n', filename);
else
  fprintf('DoTstWin: Computed chw for ExpNo = %d\n', ExpNo);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tmp = DoDecimate(Sdf,DecFac)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for K=size(Sdf.dat,2):-1:1,
  tmp(:,K) = decimate(Sdf.dat(:,K),DecFac);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cfavg = getSigConAvg(Sig,cContrast)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
eval(sprintf('cf = Sig.%s;',cContrast));
for N=1:length(cf.dat),
  cfavg.dmean(N) = nanmean(cf.dat{N}(:));
  cfavg.dstd(N) = nanstd(cf.dat{N}(:))/sqrt(length(cf.dat{N}(:)));
end;
return;

