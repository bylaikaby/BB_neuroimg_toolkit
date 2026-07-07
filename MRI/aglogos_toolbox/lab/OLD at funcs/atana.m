function atana(SESSION,GrpName)
%ATANA - Process the tetrode data
% EXAMPLE OF SESSION-SIGNALS
% cln(  1): Gamma Lfp LfpH LfpL LfpM Mua Sdf Spkt
% cln( 12): Gamma Lfp LfpH LfpL LfpM Mua Sdf Spkt
% atsdf( 13): atSdf atSpkt
% atsdf( 24): atSdf atSpkt
% atlfp( 25): atLfp
% atlfp( 36): atLfp
% muares( 37): muaSdf muaSpkt 
% muares( 48): muaSdf muaSpkt 


if ~nargin,
  SESSION = 'd98at1';
end;

SWCONVERT		= 0;
SWLFPMUASPK		= 0;
SWCOHERE		= 0;
SWCONFUNC		= 0;
SWGROUP			= 0;
SWSPRATE		= 1;

Ses = goto(SESSION);

if nargin < 2,
  grps = getgroups(Ses);
else
  grps{1} = getgrpbyname(Ses,GrpName);
end;

for GrpNo = 1:length(grps),
  grp = grps{GrpNo};
  GrpName = grp.name;
  EXPS = grp.exps;
  Ses.confunc = grp.cf;
  
  Ses.InpSigs	= grp.InpSigs;
  Ses.Sigs		= grp.Sigs;
  Ses.SigBands	= grp.SigBands;
  Ses.GrpSigs	= grp.GrpSigs;
  Ses.GrpCFSigs = grp.GrpCFSigs;
  Ses.GrpCHSigs = grp.GrpCHSigs;

  if isempty(grp.hardch),
	grp = DoRemap(Ses,grp);
  end;
  
  if SWCONVERT,
	fprintf('atana: CONVERTING Session: %s, Group: %s\n',Ses.name, grp.name);
	DoConvert(Ses,EXPS);
  end;

  if SWLFPMUASPK,
	fprintf('atana: SIGXTRACT Session: %s, Group: %s\n',Ses.name, grp.name);
	DoXSigs(Ses,grp);
  end;
  
  if SWCOHERE,
	fprintf('atana: COHERENCE Session: %s, Group: %s\n',Ses.name, grp.name);
	DoCohere(Ses,grp);
  end;
  
  if SWCONFUNC,
	fprintf('atana: CONTRAST FUNTIONS Session: %s, Group: %s\n',...
			Ses.name, grp.name);
	DoConFunc(Ses,grp);
  end;
  
  if SWSPRATE,
	fprintf('atana: Generate SpikeRate Functions Session: %s\n',Ses.name);
	DoSpikeRate(Ses,grp);
  end;
  
end;

if SWGROUP,
  atsesgrpmake(Ses);
  atsupergrp(Ses);
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoSpikeRate(Ses,grp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DecFacStep=2;
Niter = 8;

groups	= {'cln';'atsdf';'muasdf'};
if ~any(strcmp(groups,grp.name)),
  return;
end;

grp = getgrpbyname(Ses,grp.name);
if strcmp(grp.name,'cln'),
  SigName = 'Sdf';
elseif strcmp(grp.name,'atsdf'),
  SigName = 'atSdf';
else
  SigName = 'muaSdf';
end;

for E=1:length(grp.exps),
  ExpNo = grp.exps(E);
  filename = catfilename(Ses,ExpNo,'mat');
  Sdf = matsigload(filename,SigName);

  if E==1,
	for K=1:Niter,
	  spRate{K} = Sdf;
	  spRate{K}.dat = [];
	end;
  end;
  
  for K=1:Niter,
	DecFac = 2^K;
	tmp = DoDecimate(Sdf,DecFac);
	spRate{K}.dat = cat(3,spRate{K}.dat,tmp);
	spRate{K}.dx = Sdf.dx * DecFac;
  end;
end;

for K=1:Niter,
  spRate{K}.dat = squeeze(mean(spRate{K}.dat,3));
  spRate{K}.dir.dname = 'spRate';
end;

fname=strcat(grp.name,'.mat');
save(strcat(grp.name,'.mat'),'-append','spRate');
fprintf('atana(DoSpikeRate): spRate appended in %s\n', fname);
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tmp = DoDecimate(Sdf,DecFac)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for K=size(Sdf.dat,2):-1:1,
  tmp(:,K) = decimate(Sdf.dat(:,K),DecFac);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoConFunc(Ses,grp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ExpNo = grp.exps,
  confunc(Ses,ExpNo);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoCohere(Ses,grp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ExpNo = grp.exps,
  expcohere(Ses,ExpNo);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoXSigs(Ses,grp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if any(strcmp(grp.Sigs,'Cln')),
  sesgetlfpmuaflt(Ses,grp.name);
  sesgetspk(Ses,grp.name);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoConvert(Ses,EXPS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ExpNo = EXPS,
  neufilename = catfilename(Ses,ExpNo,'atphys');
  clnfilename = catfilename(Ses,ExpNo,'cln');
  filename = catfilename(Ses,ExpNo,'mat');
  sigs = Ses.InpSigs;

  % WIRE-DATA LIKE OUR Cln; SAVE IN SesDir/CLNDATA
  if any(strcmp(sigs,'tet'))
	fprintf('atana: converting-processing "tet" from %s\n',neufilename);
	atgetcln(Ses,ExpNo);
  end;
  
  % atSdf and muaSdf saved in SesDir
  if any(strcmp(sigs,'res')),
	fprintf('atana: converting-processing "res" from %s\n', neufilename);
	atgetspikes(Ses,ExpNo);
  end;
  
  if any(strcmp(sigs,'muares')),
	fprintf('atana: converting-processing "muares" in %s\n',neufilename);
	atgetmuares(Ses,ExpNo);
  end;
  
  % LFPs
  if any(strcmp(sigs,'lfp')),
	fprintf('atana: converting-processing "lfp" in %s\n', neufilename);
	atgetlfp(Ses,ExpNo);
  end;
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function grp = DoRemap(Ses,grp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CELLGRID	= reshape([1:16],4,4);
TETGRID		= reshape([1:12],4,3);
CELLS		= Ses.confunc.cells;
TETRODES	= Ses.confunc.tetrodes;
DOPLOT		= 1;
K=1;
for N=1:length(TETRODES),
  [tx,ty] = find(TETGRID==TETRODES(N));
  tx = (tx-1) * size(CELLGRID,1);
  ty = (ty-1) * size(CELLGRID,2);

  for M=1:CELLS(N),
	[x,y] = find(CELLGRID==M);
	x = x + tx;
	y = y + ty;
	grp.hardch(K) = (y-1)*size(Ses.confunc.eleconfig,1)+x;
	K=K+1;
  end;
end;

if DOPLOT,
  d = Ses.confunc.idist;
  mfigure([100 100 700 700]);
  for C=1:size(Ses.confunc.eleconfig,1),
	plot(d*repmat([C],[size(Ses.confunc.eleconfig,2) 1]),...
		 d*[1:size(Ses.confunc.eleconfig,2)],'sk',...
		 'linestyle','none','markersize',2,'markerfacecolor','k');
	hold on;
  end;
  tmp = (1+size(Ses.confunc.eleconfig)) * Ses.confunc.idist;
  limx = [0 tmp(1)]; limy = [0 tmp(2)];
  set(gca,'ydir','reverse');
  set(gca,'xlim',limx,'ylim',limy);
  for N=1:length(grp.hardch),
	[x,y] = find(Ses.confunc.eleconfig==grp.hardch(N));
	plot(d*x,d*y,'sr','linestyle','none','markersize',6);
  end;
  for N=0:size(TETGRID,2)+1,
	x = N * size(CELLGRID,1) * d + d/2;
	tmp = get(gca,'ylim');
	tmp(1)=tmp(1)+d/2;
	tmp(2)=tmp(2)-d/2;
	line([x x],tmp,'color','g');
  end;
  for N=0:size(TETGRID,1)+1,
	y = N * size(CELLGRID,1) * d + d/2;
	tmp = get(gca,'xlim');
	tmp(1)=tmp(1)+d/2;
	tmp(2)=tmp(2)-d/2;
	line(tmp,[y y],'color','g');
  end;
  TIT=sprintf('Session: %s, Group: %s, SigType: atSdf', Ses.name,grp.name);
  suptitle(TIT,'r',11);
end;






