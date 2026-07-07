function clnadjevt(SESSION, ExpNo, INTERACTIVE)
%CLNADJEVT - Adjust the MRI events correcting the QNX/Paravision clockDiff
% CLNADJEVT(SESSION,ExpNo) is the first function to call before the
% actual denoising of the physiology data acquired simultaneously with
% the MR images. The procedure relies on the following assumptions:
%
% 1.For the same slice-thickness the slice selection pulse should
%	be identical in all acquisitions; That is same duration and
%	amplitude. Variation in either one of them is either serious problem
%	at the Bruker side, or noise in our acquisition.
%
% 2.For the same segment the only difference in interference is
%	that due to the RF-pulse frequency content.
%
% 3.For different segments we expect different timing between the
%	slice-selection pulse and the actual readout period. Also possible
%	are differences in the initial readout shift that points to different
%	location of the K-Space.
%
% 4.A Clock-Error is expected in both the initial registration of
%	the MRI events (mri(1)) and the subsequent events, which will show an
%	additive error. 
%
% 5.To solve the latter problem in a way that all data can be analyzed by
%	the same routine, we are proceeding as follows:
%	a. Get mean and SD of the initial portion of the signal
%		(before the first MRI event).
%	b. Search for the first occurrence of 5 consequtive values
%		lying above 5 SDs; they define MRI1
%	c. Peform mri = mri - mri(1);
%	d. Correct for additive error: mri = mri * CORFAC
%			CORFAC is calculated by GETCLOCKERROR(SESSION,ExpNo)
%	e. And add the correct mri(1), that is mri(1) = MRI1
%
% 6.When we have multi-shot multi-slice scans than the gradient
%	will be in the followin order:
%   Slice-1 Seg-1 Slice-2 Seg-1 ... Slice-N Seg-1
%   Slice-1 Seg-2 Slice-2 Seg-2 ... Slice-N Seg-2
%	That is, for 4 slices and 2 segments we have:
%	1111222211112222
% 7.The program was debugged with j00fo1/22 which seems to be
%	totally screwed up as far as mri(1) and the rest of the events goes.
%	Other Examples to debug things:
%	J00.fa1/10(12); J00.fo1/22(22); N00.eb1/16(16)
%
%**************************
% IMPORTANT NOTE:
%**************************
%*	IN GENERAL, THE DENOISING PROCEDURE WORKS WELL AND IN MOST CASES
%*	IT ACTUALLY DOES ALMOST A PERFECT JOB. YET, THERE ARE SOME DATA
%*	SETS THAT CAUSE TROUBLE. I (NKL) DO NOT UNDERSTAND THE SOURCE OF
%*	THE VARIABILITY, AS PARAVISION IS SUPPOSED TO BE (AND MUST BE IF
%*	THE IMAGES LOOK LIKE "IMAGES") EXTREMELY ACCURATE IN THE TIMING
%*	OF PULSE SEQUENCES. MORE INTENSTIVE DEBUGGING AND STATSTICAL
%*	ANALYSIS OF THE SIGNALS MAY BE REQUIRED BEFORE WE DECIDE TO RELY
%*	"BLINDLY" ON AN AUTOMATIC CLEAN-UP PROCEDURE....
%*	IN SHORT: CHECK YOU DATA VISUALLY IF YOU DON'T WANT TO HAVE SOME
%*	FUNNY "RESULTS"
%
% NKL, 09.02.03
%
%	See also CLNHELP GETCLOCKERROR

DEBUG	= 0;

if nargin < 3,
	INTERACTIVE = 1;
end;

% THIS HERE SHOULD BE ADJUSTED FOR YOUR COMPUTER'S MEMORY
% CAPACITY!!

MAXMEM	= 150000000;		% We take 1/5 of the max mem to be tha maxDataSize
MAXLEN	= round(MAXMEM/8);	% 8 Bytes per double

if ~nargin,
	SESSION = 'c01jw1';
	ExpNo = 31;
end;

if nargin & nargin < 2,
	fprintf('usage: clnadjevt(SESSION,ExpNo);\n');
end;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GET FILENAMES AND ADF_FILE INFORMATION
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);
evt = expgetevt(Ses, ExpNo);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GET IMAGING PARAMETERS (to be used for checking validity algorithm)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pv = getpvpars(Ses,ExpNo);

if DEBUG,
  LogFile=strcat('DEBUG_',Ses.name,'.log');		% Start log file
  diary off;						% Close previous ones...
  hbackup(LogFile);					% Make a backup for history
  diary(LogFile);					% Start the new one
  evt
  pv
end;

%		========================================================
%		PARAMETERS OF SESSION C01JW1 EXPNO=1
%		========================================================
%          nx: 128
%          ny: 128
%          nt: 440
%        nsli: 1
%        nseg: 2
%       imgtr: 0.2500
%       slitr: 0.0438
%       segtr: 0.1250
%       effte: 0.0280
%     recovtr: 0.1250
%        vdtr: [0 0]
%    gradtype: [1 2]
%     graddur: 0.0959
%     actsize: [128 128]
%         fov: [96 96]
%         res: [0.7500 0.7500]
%      actres: [0.7500 0.7500]
%      slithk: 2
%     isodist: -2.5000
%      sligap: 0
%      dstime: 6
%          ds: 48
%       times: [1x1 struct]
% =====================================
%        prepulse: 0.0015
%       postpulse: 0.0033
%           pulse: 0.0030
%              te: 0.0280
%            acqt: 0.0811
%       zerophase: 0.0162
%        pulsedur: 0.0078
%    readoutstart: 0.0110%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALCULATE DEFAULT PERI-MRIEVENT WINDOW
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is what I did initially; Josef managed to get the stupid
% numbers out of the IMND/ACQP files; so we can now define as PCA
% pattern the signal between the slice selection and the end of the
% readout gradient.
% ======================================================================
% dt1 = pv.slitr;					% Slice TR is the shortest intergrad
% if pv.nsli == 1,				% If only one slice, then segment TR
%	dt1 = pv.segtr;
% end;
% dt1 = dt1 * 1000;				% Convert in "milliseconds"
% ======================================================================
dt1 = pv.graddur * 1050;
PCApat = [-dt1*0.1 dt1*1.05];	% Calculate window around MRI event

% gradtype: [1 2]
% nt = 440
% sctgrd = [1 2 1 2 1 2 ......], size=880
sctgrd = [];
for N=1:pv.nt,
	sctgrd = cat(1,sctgrd,pv.gradtype(:));
end;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GET ADF FILE INFORMATION
% ======================================================================
% ****** NOTE ****** To facilitate the visual testing of the accuracy
% of the process of readjusting the MRI events the sampt (dx) is left in
% MILLISECONDS!!!!! The sct structure, however, still stores its value
% in seconds to make it compatible with the rest of the software.
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
name = catfilename(Ses,ExpNo,'phys');
[NoChan,NoObsp,dx,obslen] = adf_info(name);

% 27.09.03 WE OVERWRITE THE NoChan OBTAINED FROM adf_infor BECAUSE
% OF THE ADDITIONAL TWO CHANNELS WE USE FOR THE
% MOVIE-EXPERIMENTS. THE GRADIENT CHANNELS IS NOW -- NOT THE LAST
% CHANNEL, BUT RATHER ONE AFTER THE LAST CHANNEL AS DEFINED IN THE
% GRP.HARDCH
NoChan = length(grp.hardch)+1;

if NoObsp > 1,
  fprintf('Multiple observation periods detected!\n');
  fprintf('Ignoring all but the first...\n');
  NoObsp = 1;
  obslen = obslen(1);
end;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FOR COMPARISON: COMPUTE MRI EVENTS BASED ON PARAVISION TIMING
% NOTE USED HERE -- BUT DO NOT DELETE !!!! IS GOOD FOR DEBUGGING
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if 0,
  for SegNo = 1:pv.nseg,
	IDX = SegNo*pv.nsli;
	vol(IDX) = (pv.segtr + pv.vdtr(SegNo)) - (pv.nsli-1)*pv.slitr;
	for SliNo = 1:pv.nsli-1,
	  vol((SegNo-1)*pv.nsli+SliNo) = pv.slitr;
	end;
  end;
  vol = vol(:);
  trig = [];
  for N=1:pv.nt,
	trig = cat(1,trig,vol);
  end;
  trig = [0; cumsum(trig)] * 1000;
end;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% READ INITIAL SEGMENT TO DEFINE THE SLICE-SELECTION PATTERN
% COMPUTE STATISTICS OF INITIAL SEGMENT, FIND FIRST SLICE-SELECTION
% GRADIENT, AND PLOT PRE, MRI(1), AND POST TIME POINTS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NoSTD			= 5;		% Six SDs above mean is the thershold
SustainedPnts	= 5;		% The signal must remain high for at least 5 points 
PreMsec			= 5;		% Before slice selection pulse

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE RECORDING INFO HERE (TO BE USED BY CLNADF)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sct.ExpNo	 = ExpNo;						% Experiment number
sct.Seg		 = {};							% Beg/End of chunks in MRI-EVT
sct.SegPnts	 = {};							% Beg/End of chunks in ADC Points
sct.NoObsp	 = NoObsp;						% Observation number (usually=1)
sct.NoChan	 = NoChan;						% Number of channels (data=1 or 2)
sct.NoVol    = pv.nt;						% Number of volumes/time-points

sct.NoGrad   = length(pv.gradtype);			% e.g 12
sct.NoUniq	 = length(unique(pv.gradtype));	% 2 unique types
sct.gradtype = pv.gradtype;					% e.g 121212121212...
sct.uniqtype = unique(pv.gradtype);			% 12 (like gradtype)
sct.uniqlen	 = [];
sct.uniqdur  = [];

sct.grd		 = sctgrd;						% Full gradient pattern
sct.grange   = PCApat/1000;					% STORE!! in seconds (see remark above)
sct.dstime   = pv.dstime;					% Dummy scan time
sct.dx		 = dx/1000;						% STORE!! in seconds (see remark above)
sct.obslen   = obslen;						% Obs Period Length
sct.obsdur   = obslen*sct.dx;				% Same as obslen but in seconds
sct.mri		 = [];
sct.dmri	 = [];

if DEBUG,
  fprintf('Data Structure "sct"\n');
  sct
end;

% GET ORGINAL MRI EVENT TIMES
% REMINDER -- EXPGETEVT: SUBTRACTS THE OFFSET 
orgmri = evt.obs{1}.origtimes.mri;		% Saved MRI Events in mseconds
iorgmri = round(orgmri/dx);				% Saved MRI Events in ADC points

if DEBUG,
  fprintf('NoChan,NoObsp,dx,obslen: %d,%d,%d,%d\n',NoChan,NoObsp,dx,obslen);
  fprintf('MRI EVT\n');
  for N=1:10,
	fprintf('ORGMRI/IORGMRI(%d) = %d/%d\n',N,orgmri(N),iorgmri(N));
  end;
end;

for ObspNo = 1:NoObsp,
  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % DEFINE THE SLICE-SELECTION PATTERN THAT SIGNIFIES THE BEGINNING
  % OF THE ACQUISITION. THE MRI EVENTS ARE INAQUARATE 
  % READ FROM "ZERO" TO THE SECOND MRI-EVENT "MRI(2)"
  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  dat0=adf_read(name,ObspNo-1,NoChan-1,0,iorgmri(2));
  dat0 = dat0(:);

  % IF DUMMIES EXIST THAN START EARLIER THAN MRI(1)
  if isfield(pv,'dstime') & pv.dstime > 0,
	DummyTime = pv.dstime * 1000;		% Dummy Time in msec
  else
	DummyTime = 0;
  end;
  Dummy1 = orgmri(1) - DummyTime;		% Here starts the gradient
  
  PREIDX = [1:round((Dummy1-1)/dx)]';	% Dummy region in points

  m = nanmean(dat0(PREIDX));		%
  s = nanstd(dat0(PREIDX));			%
  tmp = dat0 - m;
  THR = abs(NoSTD * s);				%
  IDX = find(abs(tmp)>THR);		%

  % WE HAVE NOW ALL POINTS ABOVE CRITERION
  % WE WANT TO FIND THE FIRST "SustainedPnts" above CRITERION
  % WE TAKE THE DIFFERENCE OF INDICES AND SEARCH FOR THE FIRST N
  % WHICH (THE INDICES) HAVE VALUE OF 1
  didx = diff(IDX);		% If consequtive points their diff will be 1
  for N=1:length(didx)-SustainedPnts,
	if all(didx(N:N+SustainedPnts)==1),
	  break;
	end;
  end;
  GRD1 = IDX(N);

  if DEBUG,
	mfigure([10 500 1200 400]);
	plot(dat0,'k');
	hold on;
	line([GRD1 GRD1],get(gca,'ylim'),'linewidth',2,'color','r');
	set(gca,'xlim',[GRD1-1000 GRD1+1000]);
	title(sprintf('GRD1 = %d pnts, %5.3f sec',GRD1,GRD1*dx));
  end;

  PREGRD1 = GRD1 - round(PreMsec/dx);
  % ********* NOTE:
  % There is a strange variability between the start of the
  % slice-selection gradient and a subsequent pulse (CHECK w/
  % JOSEF). In the first type of gradient both the slice selection
  % pulse and this other pulse are aligned. In the grad(2) they are
  % not. So, instead of getting the slice selection pulse as
  % pattern for the correllation I use here the time period from
  % onset of the SS gradient to about TE value of the sequence.
  PROBLEM_IS_SOLVED = 0;			% !!!!!!!!!!!
  if PROBLEM_IS_SOLVED,
	dur = (pv.times.prepulse + pv.times.postpulse) * 1.2;
  else
	dur = (pv.times.readoutstart + pv.times.te);
  end;
  POSTGRD1 = round(GRD1 + (dur*1000)/dx);
  
  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % SHOW RESULTS TO USER AND CHECK IF MANUAL CORRECTIONS ARE NEEDED
  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if INTERACTIVE,
	mfigure([2 400 1000 500]);
	plot([0:length(dat0)-1]*dx-GRD1*dx,dat0,'k');
	% NOTE:
	% pv.graddur*1050 is 0.5% more duration than that obtained by
	% pvpars...
	set(gca,'xlim',round([PREGRD1*dx*0.999-GRD1*dx pv.graddur*1050]));
	xlabel('time / ms');
	% PRE SLICE SELECTION
	line([PREGRD1*dx-GRD1*dx PREGRD1*dx-GRD1*dx],get(gca,'ylim'),'color','b');
	% ONSET OF SLICE SELECTION
	line([GRD1*dx-GRD1*dx GRD1*dx-GRD1*dx],get(gca,'ylim'),'color','r');
	% POST SLICE SELECTION
	line([POSTGRD1*dx-GRD1*dx POSTGRD1*dx-GRD1*dx],get(gca,'ylim'),'color','b');
	% END OF INTERFERENCE
	line([GRD1*dx-GRD1*dx+pv.graddur*1000 GRD1*dx-GRD1*dx+pv.graddur*1000],...
		 get(gca,'ylim'),'color','y','linewidth',2);
	
	ans = yesorno('Is the result acceptable?');
	if ~ans,
	  tmp = ginput(3);
	  lim = round(tmp(:,1)/dx);
	  lim = lim + GRD1;
	else
	  lim = [PREGRD1; GRD1; POSTGRD1];
	end;
	close all;
  else
	lim = [PREGRD1; GRD1; POSTGRD1];
  end;

  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % APPLY XCOR ANALYSIS AND MAKE FINE ADJUSTMENT OF MRI EVENTS
  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  CORFAC = 0.99998203793307;			% Multiply mri() with this number
  pat = dat0(lim(1):lim(end));
  IPRE = abs(lim(1)-lim(2));
  IPOST = abs(lim(2)-lim(3));
  ILEN = abs(lim(3)-lim(1));

  % THE FIRST CORRECTION ACCOUNTS FOR THE LINEARLY INCREASING
  % DIFFERENCE BETWEEN THE MRI EVENTS AND THE ACUTAL TIME OF
  % PARAVISION TRIGGER. THE DIFFERENCE IS BECAUSE OF SLIGHTLY
  % DIFFERENT CLOCK SPEEDS AT THE QNX/PARAVISION ENVIRONMENTS.
  mri = orgmri - orgmri(1);				% Subtract before scaling
  mri = mri * CORFAC + orgmri(1);		% Add the offset back
  imri = round(mri/dx);

  nlags = round(ILEN/2);
  for N=1:length(mri)-1,
	dat = adf_read(name,ObspNo-1,NoChan-1,imri(N)-IPRE,ILEN);
	[C,lags] = xcorr(pat,dat,nlags);
	[mx,mxi] = max(C);							% optimal lag
	inewmri(N) = imri(N)-(mxi-nlags);			% difference 
  end;
  
  inewmri(length(imri)) = imri(end);
  inewmri = inewmri(:);
  newmri = inewmri * dx;
  sct.mri{ObspNo} = newmri/1000;
  sct.mri1orig{ObspNo} = evt.obs{ObspNo}.origtimes.mri(1)/1000;
  sct.dmri{ObspNo} = (orgmri - newmri)/1000;
  clear mri imri;

  if ObspNo==1,
	% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% EVEN IF MULTIPLE OBSERVATION PERIODS ARE PRESENT THE LENGTH OF EACH
	% ON OF THEM WILL BE THE SAME. SO, WE USE THE LAST OBSERVATION PERIOD'S
	% EVETNS TO CALCULATE PARTIAL READ-LENGTHS FOR LONG FILES.
	% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	mrilen = inewmri(end) - inewmri(1);
	if mrilen > MAXLEN,
	  sl = ones(round(mrilen/MAXLEN),1) * MAXLEN;
	  vollen = inewmri(sct.NoGrad+1) - inewmri(1);	% Volume length in points
	  nevt = round(sl/vollen)*sct.NoGrad;
	  for X=1:length(sl),
		sct.Seg{X}.beg = (X-1)*round(sl(X)/vollen)*sct.NoGrad+1;
		sct.Seg{X}.end = X*round(sl(X)/vollen)*sct.NoGrad;
	  end;
	  if (sct.Seg{X}.end < length(inewmri)),
		sct.Seg{X+1}.beg = sct.Seg{X}.end + 1;
		sct.Seg{X+1}.end = length(inewmri);
	  end;
	else
	  sct.Seg{1}.beg = 1;
	  sct.Seg{1}.end = [length(inewmri)];
	end;
	
	graddt = diff(inewmri);
	graddt(length(inewmri)) = graddt(end);
	for N=1:sct.NoUniq,
	  idx = find(sct.grd==sct.uniqtype(N));
	  idx = idx(find(idx <= length(inewmri)));
	  sct.uniqlen(N) = min(graddt(idx));
	  sct.uniqdur(N) = sct.uniqlen(N)*sct.dx;
	end;
	DUR = round((min(sct.uniqdur)/3)/sct.dx);
  end;
  
  if INTERACTIVE,
	% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% SHOW RESULTS NOW (PATTERN AFTER PATTERN...)
	% IF THEY ARE ACCEPTABLE SAVE DATA INTO ClnAdjEvt.mat
	% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	DISPLAY_TRIAL = 0;
	if DISPLAY_TRIAL,
	  X = 20;
	  sig.dat=adf_read(name,ObspNo-1,NoChan-1);
	  sig.dx = dx;
	  K=1;
	  NPLOTS = 60;
	  figure('Position',[2 50 1230 820]);
	  set(gcf,'color','w');
	  NFIGS = floor(pv.nt/NPLOTS);
	  for FigNo=1:NFIGS,
		FIGOFS = (FigNo-1)*NPLOTS;
		for PlotNo=1:NPLOTS,
		  subplot(round(NPLOTS/4),4,PlotNo);
		  ibeg = inewmri(FIGOFS+PlotNo);
		  iend = ibeg+DUR;
		  plot(sig.dat(ibeg-X:iend),'k');
		  text(2*X,0,sprintf('%4d',K));
		  K=K+1;
		  axis off
		  hold on;
		  line([X X],get(gca,'ylim'),'linestyle',':','color','r');
		  hold off;
		end;
		pause;
	  end;
	end;
  
	ilen = round((PCApat(2) - PCApat(1) + 1)/dx);
	for K=1:length(sct.uniqtype),
	  idx = find(sct.grd==sct.uniqtype(K));
	  idx = idx(find(idx <= length(newmri)));
	  pmri = newmri(idx);
	  for N=1:length(pmri)-1,
		ibeg = round((pmri(N) + PCApat(1))/dx);
		tmp=adf_read(name,ObspNo-1,NoChan-1,ibeg,ilen);
		if N==1,
		  dat = tmp;
		else
		  dat = dat + tmp;
		end;
	  end;
	  gra{K} = dat/N;
	end;
  
	mfigure([1 50 600 900]);
	for K=1:length(sct.uniqtype),
	  subplot(length(sct.uniqtype),1,K);
	  plot([0:length(gra{K})-1]*dx+PCApat(1),gra{K});
	  set(gca,'xlim',PCApat);
	end;
	xlabel(sprintf('Time in msec; G-Range = [%5.2f %5.2f]',PCApat(1),PCApat(2)));
	suptitle(sprintf('Session: %s, ExpNo: %d', Ses.name, ExpNo));
	
	ans = yesorno('Pattern Range. Is it acceptable?');
	if ~ans,
	  fprintf('Current Range = [%5.2f %5.2f]\n',PCApat(1), PCApat(2));
	  fprintf('Select Range Manually\n');
	  keyboard;
	end;
	close all;
  end;
end;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert to seconds before dumping into ClnAdjEvt.mat file
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
VAR = sprintf('exp%03d', ExpNo);
eval(sprintf('%s = sct;', VAR));

if ~exist('ClnAdjEvt.mat','file'),
	save('ClnAdjEvt.mat',VAR);
else
	save('ClnAdjEvt.mat','-append',VAR);
end;

if DEBUG,
  diary off;						% CLOSE LOG FILE
end;  
return;














