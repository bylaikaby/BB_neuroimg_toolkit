function sesfsana(SESSION,DOPRINT)
%SESFSANA - Analyze flash suppression data
% SESFSANA(SESSION) - deals specifically with the FS data. The
% function assumes that:
% 1. You have run the basic analysis steps (CLNBASIC or DECBASIC)
% 2. You have run sesfsanaspec(SESSION), which generates the Psd
% signals and groups them into the appropriate group file.
%
% In short: To analyze the Flash Suppression Data:
% 1. Edit xp and set session switch and DECBASIC/CLNBASIC
%	 sesgetcln(Ses,EXPS);			% Decimate from 22.3K to 7K
%	 sesgetcond(Ses,EXPS);			% Extract single observation periods
%	 sesclnspc(Ses,EXPS);			% Compute Spectrograms
%	 sesgetlfpmua(Ses,EXPS);		% LfpPow, MuaPow (avg Spc)
%	 sesgetspk(Ses,EXPS);			% Extract spikes/SDFs
%	 sesgrpmake(Ses);				% Make groups
% 2. sesflashspec(SESSION)			% Make Psd/zPsd Signals
% 3. Run this file
%  
% NKL, 04.06.03
%
% NOTES 15.06.03
% ** Inspect the data and defined channel indices with modulating sites
% ** Must develop cor analysis... and coherence measurements
% ** Compute lfp-mua cor, average corrrelated/uncorrelated?
  
  
global DispPars DISPMODE PPTSTATE
DISPMODE=0;
setdispmode(DISPMODE);

PPTSTATE = getpptstate;
if isempty(PPTSTATE),
  PPTSTATE = 0;				% DEFAULT NO PPT OUTPUT
  setpptstate(PPTSTATE);
end;

initDispPars(DISPMODE,PPTSTATE);
DispPars.mfigure = 1;
DispPars.pptout = 'meta';

if nargin < 2,  DOPRINT = 0; end;
if DOPRINT,
  DispPars.printer = 1;
end;

if ~nargin,
  SESSION = 'b01nm3';		% The very first session!
  GrpName = 'flash';		% One group only (flash)
end;

Ses = goto(SESSION);
names = fieldnames(Ses.grp);

if 0,
% PLOT SPECTRA POWER DISTRIBUTIONS FOR DICHOPTIC EPOCH
for N=1:length(names),
  if strncmp(names{N},'flash',5),
	DOPlotSpecs(Ses,names{N});
  end;
end;
end;

% PLOT n2p and p2n TIME COURSES FOR CONGRUENT CONDITIONS
if exist('GrpName','var') & ~isempty(GrpName),
  DOsesfsana(Ses,GrpName,'dioptic');
else
  for N=1:length(names),
	if strncmp(names{N},'flash',5),
	  DOsesfsana(Ses,names{N},'dioptic');
	end;
  end;
end;

% PLOT n2p and p2n TIME COURSES FOR CONGRUENT CONDITIONS
if exist('GrpName','var') & ~isempty(GrpName),
  DOsesfsana(Ses,GrpName,'dichoptic');
else
  for N=1:length(names),
	if strncmp(names{N},'flash',5),
	  DOsesfsana(Ses,names{N},'dichoptic');
	end;
  end;
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DOsesfsana(Ses,GrpName,CONDITION)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global DispPars
MEAN_RESPONSE = 0;			% IF SET AVERAGE ALL CHANNELS
grp = getgrpbyname(Ses,GrpName);
cmd = sprintf('sesfsana(%s,%s,%s): ',Ses.name,GrpName,CONDITION);

% IF IT'S A RECORDINGS ESSION LOAD MAIN SIGNALS
if isrecording(grp),
  load(strcat(GrpName,'.mat'),'LfpM','Mua');
end;

% IF IMAGING TOO, LOAD HEMODYNAMICE RESPONSES
if isimaging(grp),
  load(strcat(GrpName,'.mat'),'shtc');
end;

if isfield(grp,'avg'),
  for N=1:length(LfpM),
	LfpM{N}.avg = grp.avg;
	Mua{N}.avg = grp.avg;
  end;
end;

if MEAN_RESPONSE,
  mfigure([100 200 800 320]);
  suptitle(strcat(cmd,'Signals: LfpM/MUA'),'r',8);
  subplot(1,2,1);
  dspflash(LfpM,0,CONDITION);
  subplot(1,2,2);
  dspflash(Mua,0,CONDITION);
  if DispPars.printer,	print; close all; end;

  if 0 & isimaging(grp),
	mfigure([100 200 600 500]);
	suptitle(strcat(cmd,'Signal - ',shtc{1}{1}.dir.dname));
	for S=1:length(shtc),
	  subplot(length(shtc),1,S);
	  dspflash(shtc{S},0,CONDITION);
	end;
	if DispPars.printer,	print; close all; end;
  end;
  
else
  if 0,
	Mix = sigmult(LfpM,Mua);
	PlotMultiChannel(Mix,cmd,CONDITION);
	if DispPars.printer,	print; close all; end;
  end;

  PlotMultiChannel(LfpM,cmd,CONDITION);
  if DispPars.printer,	print; close all; end;
  PlotMultiChannel(Mua,cmd,CONDITION);
  if DispPars.printer,	print; close all; end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function PlotMultiChannel(Sig,cmd,CONDITION)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if size(Sig{1}.dat,2) <= 2,	% Combined MRI and PHysiology
  ROW=2; COL=1;
  mfigure([100 100 500 500]);
else
  ROW=4; COL=4;
  mfigure([100 100 900 700]);
end;

suptitle(strcat(cmd,'Signal - ',Sig{1}.dir.dname));
for ChanNo = 1:16,
  if ~any(Sig{1}.chan == ChanNo),
	subplot(ROW,COL,ChanNo);
	set(gca,'color',[.3 .3 .3]);
	text(0.25,0.5,'No Response','color','y');
	set(gca,'box','on');
	title(sprintf('Site: %d, Ch: NaN', ChanNo));
	set(gca,'yticklabel',[]);
	set(gca,'xticklabel',[]);
  end;
end;

for ChanNo = 1:size(Sig{1}.dat,2),
  subplot(ROW,COL,Sig{1}.chan(ChanNo));
  set(gca,'color','w');
  dspflash(Sig,ChanNo,CONDITION);
  title(sprintf('Site: %d, Ch: %d', Sig{1}.chan(ChanNo), ChanNo));
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DOPlotSpecs(Ses,GrpName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
grp = getgrpbyname(Ses,GrpName);
cmd = sprintf('sesflah(%s,%s): ',Ses.name,GrpName);
load(strcat(GrpName,'.mat'),'zPsdC','zPsdIC');
mfigure([100 100 1000 850]);
subplot(2,2,1);
show(zPsdC{1});
title('Congruent Conditions (First 500ms)');

subplot(2,2,2);
show(zPsdC{2});
title('Congruent Conditions (Late (>500ms) Response)');

subplot(2,2,3);
show(zPsdIC{1});
title('Incongruent Conditions (First 500ms)');

subplot(2,2,4);
show(zPsdIC{1});
title('Incongruent Conditions (Late (>500ms) Response)');
return;



