function varargout = clnadjevt(Ses,ExpNo,INTERACTIVE)
%CLNADJEVT - Adjust the MRI events correcting the QNX/Paravision clockDiff
% CLNADJEVT(SESSION,ExpNo) is the first function to call before the
% actual denoising of the physiology data acquired simultaneously with
% the MR images. The following things must be taken into consideration if the code is
% modified or change by any of the people involved in the projects:
%
% ***1*** For the same slice-thickness the slice selection pulse should be identical for all
% acquisitions (the pulse duration and amplitude is defining the slice thickness by means of
% the slope of the gradient). Variation in either one of them is either a serious problem at
% the Bruker side, or noise in our acquisition. There is nothing to "fix" with software
% here. If you notice differences between successive image-acquisitions let one of the
% MR-people or NKL know of the problem.
% Nevertheless, the time between two excitations for the same slice  
%
% ***2*** For the same segment the only difference in interference is that due to the RF-pulse
% frequency content. Also this point is just FYI. We do not compensate completely for this
% small differences.
%
% ***3*** For different segments we expect different timing between the slice-selection pulse
% and the actual readout period. Also possible are differences in the initial readout shift
% that points to different location of the K-Space. To achieve perfect alignment between
% interference patterns we separate the gradient-interference in groups and analyze each group
% separately (see below). For example, when we have multi-shot multi-slice scans than the
% gradient will be in the following order:
%   Slice-1 Seg-1 Slice-2 Seg-1 ... Slice-N Seg-1
%   Slice-1 Seg-2 Slice-2 Seg-2 ... Slice-N Seg-2
%	That is, for 4 slices and 2 segments we have:
%	1111222211112222
% The software will group all interference patterns due to 1 & 2 gradients in groups (1) and
% (2) respectively. The pattern 112211... is saved in pv.gradtype.
%
% CORRECTIONS:
% ===========================================================
% A Clock-Error is expected in both the initial registration of the MRI events (mri(1)) and the
% subsequent events, which typically show an additive error. This must be corrected by
% software. We proceed as follows:
%
% ***C1*** To correct the additive error we first calculate the time-correction factor,
% TFACTOR. The correction is performed by the expgetpar.m function during the estimation/saving
% of parameters in SesPar.mat. The new times are saved under evt.obs{ObsNo}.times.ANYFIELD,
% including evt.obs{ObsNo}.times.mri
%
% ***C2*** To achieve optimal time adjustment: 
%	 1 Get mean and SD of the initial portion of the signal (before the first MRI event).
%	 2 Search for the first occurrence of 5 consequtive values lying above 5 SDs (MRI1)
%	 3 Peform mri = mri - mri(1);
%	 4 And add the correct mri(1), that is mri(1) = MRI1
%
%
% NOTE:
% In general, the denoising procedure works well and in most cases it actually does almost a
% perfect job. Yet, there are some data sets that cause trouble. I (nkl) do not understand the
% source of the variability, as paravision is supposed to be (and must be if the images look
% like "images") extremely accurate in the timing of pulse sequences. Intenstive debugging and
% statstical analysis of the signals may be required before we decide to rely "blindly" on an
% automatic clean-up procedure.... in short: check you data visually if you don't want to have
% some funny "results"
%
% VERSION : 1.00 09.02.03 NKL  original clnadjevt
%           1.10 03.03.04 YM   modified to include old data
%           1.11 01.04.04 YM   supports cases with shorter baseline period.
%           1.20 15.05.05 NKL  modified to include all new updates of MIR/Phys software
%
% See also CLNHELP, GETCLOCKERROR, SESCLNADJEVT, CLNMAIN, CLNADF


CLNADJEVT_VERSION = 1.20;	% version info, will be checked in clnamin/clnadf

DEBUG = 0;

if nargin == 0,
  Ses = 'c01jw1';  ExpNo = 31;
  Ses = 'm02lx1';  ExpNo = 1;
elseif nargin == 1,
  fprintf('usage: adjevt = clnadjevt(SESSION,ExpNo);\n');
  return;
end

if ~exist('INTERACTIVE','var'),  INTERACTIVE = 1;  end


% ======================================================================
% THIS HERE SHOULD BE ADJUSTED FOR YOUR COMPUTER'S MEMORY CAPACITY!!
% ======================================================================
MAXMEM = 1024e+06;


% ======================================================================
% READ INITIAL SEGMENT TO DEFINE THE SLICE-SELECTION PATTERN
% COMPUTE STATISTICS OF INITIAL SEGMENT, FIND FIRST SLICE-SELECTION
% GRADIENT, AND PLOT PRE, MRI(1), AND POST TIME POINTS
% ======================================================================
NoSTD			= 10;	% Ten SDs above mean is the thershold
SustainedPnts	= 5;	% The signal must remain high for at least 5 points 
PreMsec			= 5;	% Before slice selection pulse


% ======================================================================
% BASIC INFORMATION
% ======================================================================
Ses = goto(Ses);				% session
grp = getgrp(Ses,ExpNo);		% group

if 0,
  evt = expgetevt(Ses,ExpNo);		% event
  pv  = getpvpars(Ses,ExpNo);		% imaging
else
  fprintf('CLNADJEVT: Events/PvPars Read from SesPar.mat\n');
  % ======================================================================================
  % REMINDER
  % EXPGETPAR WILL CALL: evt = expgetevt(Ses,ExpNo);
  % The latter does...
  %
  % etime{N}.begin  = selectevt(DG, N, ec.BeginObsp,  ec.sub.all);
  % etime{N}.end	  = selectevt(DG, N, ec.EndObsp,    ec.sub.all);
  % ...
  % etime{N}.mri    = selectevt(DG, N, ec.Mri,	    ec.sub.MriTrigger);
  % It will get all times from DGZ file
  %
  % THIS INITIAL TIMES will be preserved in origtimes field of evt.obs structure. They can
  % be used for debugging. The original .times field will include all time corrections,
  % subtraction of offsets etc.
  % ======================================================================================
  par = expgetpar(Ses,ExpNo);
  pv = par.pvpar;
end;

evt = par.evt;

% NOTE:
% ***************************************************
% There is a strange variability between the start of the
% slice-selection gradient and a subsequent pulse (CHECK w/
% JOSEF). In the first type of gradient both the slice selection
% pulse and this other pulse are aligned. In the grad(2) they are
% not. So, instead of getting the slice selection pulse as
% pattern for the correllation I use here the time period from
% onset of the SS gradient to about TE value of the sequence.
%
% Description of the plot in the INTERACTIVE mode
% ***************************************************
% The first line (blue) is slice-selection - PreMsec
% The second line (red) is slice-selection
% The third line at around the k-space center is the TE value.
% The last line is the end of interference

PROBLEM_IS_SOLVED = 0;			% !!!!!!!!!!!
if PROBLEM_IS_SOLVED,
  dur = (pv.times.prepulse + pv.times.postpulse) * 1.2;
else
  dur = (pv.times.readoutstart + pv.times.te);
end;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALCULATE DEFAULT PERI-MRIEVENT WINDOW
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is what I did initially; Josef managed to get the gradient-related
% numbers out of the IMND/ACQP files; so we can now define as PCA
% pattern the signal between the slice selection and the end of the
% readout gradient.
% ======================================================================
% dt1 = pv.slitr;				% Slice TR is the shortest intergrad
% if pv.nsli == 1,				% If only one slice, then segment TR
%	dt1 = pv.segtr;
% end;
% dt1 = dt1 * 1000;				% Convert in "milliseconds"
% ======================================================================
dt1 = pv.graddur * 1050;
PCApat = [-dt1*0.1 dt1*1.05];	% Calculate window around MRI event

% ======================================================================
% ADF INFORMATION
% ======================================================================
adffile = catfilename(Ses,ExpNo,'phys');
[NoChanAdf,NoObsp,dx,obslen] = adf_info(adffile);
% 27.09.03 WE OVERWRITE THE NoChan OBTAINED FROM adf_infor BECAUSE
% of the additional two channels we use for the
% movie-experiments. The gradient channels is now -- not the last
% channel, but rather one after the last channel as defined in the
% grp.hardch
NoChan = length(grp.hardch)+1;

% check amount of memory for the MRI event signal.
% 8 as double precision, 1/2 of MAXMEM as a limit.  16.02.04 YM
if max(obslen)*8 >= MAXMEM/2,
  % very long data requiring partial reading.
  ENOUGH_RAM = 0;
else
  % reasonable to read a whole obsp.
  ENOUGH_RAM = 1;
end

if length(obslen) ~= length(evt.obs),
  fprintf(' clnadjevt ERROR: NoObsp differs between dgz and adf/adfw.\n');
  keyboard
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% evt.obs{ObsNo}.origtimes
% It includes the event times as read from the dgz file, without any corrections.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for iObsp = 1:length(obslen),
  tmpd = evt.obs{iObsp}.origtimes.end - obslen(iObsp)*dx;
  tmpd = tmpd / evt.obs{iObsp}.origtimes.end * 100;
  if abs(tmpd) > 0.1,
    fprintf(' clnadjevt ERROR: obsp=%d is collapsed,',iObsp);
    fprintf(' adflen=%.3fs, dgzlen=%.3fs.\n',...
            obslen(iObsp)*dx/1000.,evt.obs{iObsp}.origtimes.end/1000.);
    keyboard;
  end
  % check mri-events too, some OLD DATA has empty mri-events.
  if isempty(evt.obs{iObsp}.origtimes.mri),
    NoObsp = iObsp-1;  break;
  end
end

% ======================================================================
% SAVE RECORDING INFO HERE (TO BE USED BY CLNADF)
% ======================================================================
SCT.version	 = CLNADJEVT_VERSION;	% version of clnadjevt
SCT.ExpNo	 = ExpNo;				% Experiment number
SCT.Seg		 = {};					% Beg/End of chunks in MRI-EVT
SCT.SegPnts	 = {};					% Beg/End of chunks in ADC Points
SCT.NoObsp	 = NoObsp;				% Observation number (usually=1)
SCT.NoChan	 = NoChan;				% Number of channels (data=1 or 2)
SCT.NoVol    = pv.nt;				% Number of volumes/time-points

SCT.NoGrad   = length(pv.gradtype);				% e.g 12
SCT.NoUniq	 = length(unique(pv.gradtype));		% 2 unique types
SCT.gradtype = pv.gradtype;						% e.g 121212121212...
SCT.uniqlen	 = [];
SCT.uniqdur  = [];

% gradtype: [1 2]
% nt = 440
% SCT.grd = [1 2 1 2 1 2 ......], size=880
SCT.grd		 = repmat(pv.gradtype(:),pv.nt,1)';	% Full gradient pattern
SCT.grange   = PCApat/1000;			% STORE!! in seconds (see remark above)
SCT.dstime   = pv.dstime;			% Dummy scan time
SCT.dx		 = dx/1000;				% STORE!! in seconds (see remark above)
SCT.obslen   = obslen;				% Obs Period Length
SCT.obsdur   = obslen*SCT.dx;		% Same as obslen but in seconds
SCT.mri		 = [];
SCT.dmri	 = [];


% ================================================================================
% Compare the number of expected gradient patterns with the recorded mri events.
% ================================================================================
nmri = 0;
if length(evt.obs)>1,
  fprintf('ClnAdjEvt[WARNING]: Multiple Observation periods\n');
  fprintf('Check SCT.grd in ClnAdjEvt code\n');
end;

for N = 1:length(evt.obs),
  nmri = nmri + length(evt.obs{N}.times.mri);
end

if nmri < length(SCT.grd),
  % ==============================================
  % This may not be an error in cases where stimulus program
  % changes stimulus duration on fly.  01.03.04 YM
  totdgzlen = 0;
  for N = 1:length(evt.obs),
    totdgzlen = totdgzlen + evt.obs{N}.times.end/1000.;
  end
  fprintf('\n clnadjevt WARNING:');
  fprintf(' length(recorded mri-event) is less than expected.\n');
  fprintf('   NumMriEvents = %d/%d',nmri,length(SCT.grd));
  fprintf('   totlen = %.2fs/%.2fs\n',totdgzlen,pv.nt*pv.imgtr);
  fprintf(' This warning may not apply when the stimulus/qnx programs change\n');
  fprintf(' the stimulus duration during the experiment.\n');
  fprintf(' This is so, because paravision pre-estimates max duration.');
  keyboard
end

if DEBUG,
  fprintf('Data Structure "sct"\n');
  SCT
  fprintf('NoChan,NoObsp,dx,obslen: %d,%d,%d,%d\n',NoChan,NoObsp,dx,obslen);
end;

if isfield(grp,'gradch'),
  GradCh = grp.gradch;
else
  GradCh = NoChan;
end
if GradCh > NoChanAdf, GradCh = NoChanAdf; end


% ======================================================================
% DETECT PRECISE TIMING OF INTERFERENCE NOISE
% ======================================================================
for iObsp = 1:NoObsp,
  % GET ORIGINAL MRI EVENT TIMES
  % REMINDER: evt.obs{}.times are with subtracted MRI OFFSET 
  mriTime = evt.obs{iObsp}.origtimes.mri;	% Saved MRI Events in mseconds
  mriIndx = round(mriTime/dx);				% Saved MRI Events in ADC points

  if DEBUG,
    fprintf('MRI EVT (first 10), Obsp=%d\n',iObsp);
    for N = 1:10,
      fprintf('  MRITIME/MRIINDX(%2d) = %d/%d\n',N,mriTime(N),mriIndx(N));
    end;
  end

  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % DEFINE THE SLICE-SELECTION PATTERN THAT SIGNIFIES THE BEGINNING
  % OF THE ACQUISITION. THE MRI EVENTS ARE INAQUARATE 
  % READ FROM "ZERO" TO THE SECOND MRI-EVENT "MRI(2)"
  % THIS MEANS: WE ARE LOOKING FOR THE FIRST FLANK OF THE SLICE SELECTION GRADIENT!!
  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % ATTENTION:!!!
  % ADC/QNX-Clock START when you press the go-button.
  % You then wait for the first MRI event, which can come any time from 1 to 250 ms. plus
  % the time you need to start the image acquisition on the paravision side.
  % If you have dummies, the trigger will come at the end of the dummy scans. That is, the
  % time of the first MRI event will be the dummy-scan duration (ca 6 second that correspond
  % to the tissue mangetization time) plus the actual MRI event. So, you expect the first
  % MRI event (in msec) to be at the order of 6000+ ms.
  if ENOUGH_RAM,
    GradADFData = adf_read(adffile,iObsp-1,GradCh-1);
    dat0 = GradADFData(1:mriIndx(2));
  else
    dat0 = adf_read(adffile,iObsp-1,GradCh-1,0,mriIndx(2));
  end

  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % COMPUTE BASELINE STATISTICS
  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if iObsp == 1,
    if isfield(grp,'pvavr') && grp.pvavr > 0,
      % ONLY VALID FOR THE OLD NATURE-DATA
      % imaging data was averaged by paravision,usually 8 obsp -> 1 obsp
      GradStartT = mriTime(1);
      if INTERACTIVE,
        fprintf('CLNADJEVT: Old data (Nature 2001)\n');
      end;
    elseif isfield(pv,'dstime') & pv.dstime > 0,
      % The dummy scans have the following effect: With each QNX "go" the time clock of
      % QNX starts (current time - Obsp-starttime). No images are acquired but the
      % interference patterns are collected as the ADC is running. When the acquisition of
      % images starts, then we get the first "real" MRI event. The time of that event
      % is usually (~ 1 Segment-TR) + the duration of the dummy scans.
      %
      % The variable GradStartT shows the start of the very first interference pattern
      % generated by the first dummy scan. This pattern is expected ca 6 seconds (our
      % default dummy scan duration) before the first MRI event!
      % For example for "clnadjevt('b05wc1',2)" the mriTime(1) = 6357, and the GradStartT
      % variable is 357.
      GradStartT = mriTime(1) - pv.dstime * 1000;
      if INTERACTIVE,
        fprintf('CLNADJEVT: Dummy scans exist\n');
        fprintf('CLNADJEVT: mri(1) is mri(1)+dstime, dstime=duration of dummy scans\n');
      end;
    else
      GradStartT = mriTime(1);      % ORIGINAL EVENT TIMES!!!
      if INTERACTIVE,
        fprintf('CLNADJEVT: No dummy scans; first MRI event is ~250ms\n');
      end;
    end;

    if GradStartT <= 1,
      % 07.Oct.03 YM
      % The state system has probably started after start of ParaVision.
      % This is a problem-case and should not be processed without corrections; so we go to
      % a keyboard statement after printing out warnings!
      fprintf('\n clnadjevt ERROR: ExpNo=%d ObspNo=%d',ExpNo,iObsp);
      fprintf(' GradStartT[%d] >= mriTime(1)[%d]\n',GradStartT,mriTime(1));
      fprintf(' State system likely started after the first MRI event.\n');
      keyboard
    end

    % WE now want to determine the variability of the signal in periods of no
    % interference. The initial segment from 0 to GradStartT can be used but sometimes it is
    % slightly longer than it should, intruding the interference region of the first
    % segment. To avoid problems well consider half of GradStartT as the baseline signal.
    PREIDX = [1:round((GradStartT/2)/dx)]';         % baseline region in points
    mBase = nanmean(dat0(PREIDX));                  % Mean signal
    sBase = nanstd(dat0(PREIDX));                   % And its STD

    % Now check if interference starts even earlier than GradStartT/2
    % Default NoSTD = 10;
    % We take the first 40 ms as the minimum possible time before the first interference
    % pattern of the fist gradient scan. This should be for all practical purposes really
    % fine...
    RUHE = 40;
    if sBase > NoSTD * nanstd(dat0(1:round(RUHE/dx))),
      PREIDX = 1:round(RUHE/dx);
      mBase = nanmean(dat0(PREIDX));
      sBase = nanstd(dat0(PREIDX));
    end
    THR = abs(NoSTD * sBase);
    clear PREIDX;
  end

  if iObsp >= 2,
    % ONLY VALID FOR THE OLD NATURE-DATA
    % 02.08.04 YM, base line changes during grad.signals...
    % need to update mean base???
    mBase = mean(dat0);
  end

  if DEBUG,
    figure(iObsp);
    cla; plot(abs(dat0)); hold on;  grid on;
    line(get(gca,'xlim'),[THR+mBase THR+mBase],'color','r');
    line(get(gca,'xlim'),[mBase mBase],'color','g');
  end
  %
  % From now on we work with the meaningful signal that starts after the first MRI event,
  % namely the mriTime(1). Two problems:
  %     (a) where to start?
  %     (b) how to search for the onset of the slice-selection gradient?
  % (a) Empirically the first MRI event is accurately determined with a precision of +/- a
  % couple of milliseconds. The difference between paravision and qnx clocks increases as
  % the observation period continues.
  % The time between the end of one pattern and the start of the other is ca 10ms.
  % We take as start the mriTime(1)-10ms.
  % (b) To find the first continuous set of points above criterion
  % we take the difference of indices and search for the first n indices
  % that have a value of 1.
  % SustainedPnts (Default = 5) Defined above
  %
  PatDT = 10;                           % 4ms before mriTime(1) start the search!
  mri1 = round((mriTime(1)-PatDT)/dx);
  tmpdat = dat0(mri1:end);
  IDX = find(abs(tmpdat - mBase) > THR);
  didx = diff(IDX);                     % If consequtive points their diff will be 1
  GRD1 = 0;  N = 1;
  while N <= length(didx)-SustainedPnts,
    if all(didx(N:N+SustainedPnts) == 1),
      if IDX(N) <= round(PreMsec/dx),
        % skip to the next grad. signal
        N2 = find(didx > max(didx)*0.2);
        N2 = N2(find(N2 > N));
        N  = N2(1) - 1;
        clear N2;
        continue;
      end
      GRD1 = IDX(N);
      break;
    end;
    N = N + 1;
  end
  GRD1 = mri1 + GRD1 - 1;

  if GRD1 <= 0,
    fprintf('\n clnadjevt ERROR: failed to detect GRD1.\n');
    keyboard
  end

  PREGRD1   = GRD1 - round(PreMsec/dx);
  POSTGRD1  = round(GRD1 + (dur*1000)/dx);
  ENDGRD    = round(GRD1 + (pv.graddur*1000/dx));

  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % PLOT-1: SHOW RESULTS TO USER AND CHECK IF MANUAL CORRECTIONS ARE NEEDED
  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if INTERACTIVE,
    mfigure([2 200 1300 800]);
    set(gcf,'Name',sprintf('Ses:%s  ExpNo:%d  %s',Ses.name,ExpNo,adffile));
    set(gcf,'NumberTitle','off');
    t = [0:length(dat0)-1]*dx;
    plot(t,dat0,'k');
    % NOTE:
    % pv.graddur*1050 is 0.5% more duration than that obtained by
    % pvpars...
    % set(gca,'xlim',round([PREGRD1*dx*0.999-GRD1*dx pv.graddur*1050]));
    LIM = 15;   % View LIM points before and after (only for viewing purposes)
    set(gca,'xlim',[PREGRD1-LIM ENDGRD+LIM]*dx);
    xlabel('time / ms');
    ylm = get(gca,'ylim');
    ylmL = [ylm(1) ylm(2)];     % For line height
    ylmT = ylm(2)*0.8;          % For text

    % ZERO BASELINE
    line(get(gca,'xlim'),[0 0],'linestyle',':','linewidth',2,'color','k');

    % PRE SLICE SELECTION
    t = PREGRD1*dx;
    line([t t],ylmL,'color','b','linewidth',3);

    % ONSET OF SLICE SELECTION
    t1 = GRD1*dx;
    line([t1 t1],ylmL,'color','r','linewidth',1,'linestyle',':');

    % POST SLICE SELECTION
    t2 = POSTGRD1*dx;
    line([t2 t2],ylmL,'color','k','linewidth',3);

    % END OF INTERFERENCE
    t3 = ENDGRD*dx;
    line([t3 t3],ylmL,'color','c','linewidth',3);
    vals = sprintf('PRE/GRD/POST/END: %d/%d/%d/%d', PREGRD1, GRD1, POSTGRD1, ENDGRD);
    title(sprintf('Event Indices: %s (PRE to POST is COR Pattern)',vals));

    text(t,ylmT,'PreSlice (Beg of Inteference)','FontWeight','bold',...
         'backgroundcolor','w','color','b');
    text(t1,ylmT*0.8,'SliSel (Determines PreSlice)','FontWeight','bold',...
         'backgroundcolor','w','color','r','HorizontalAlignment','left');
    text(t2,ylmT,'PostSli (TE)','FontWeight','bold','backgroundcolor','w',...
         'HorizontalAlignment','center');
    text(t3,ylmT,'End (graddur)','FontWeight','bold',...
         'backgroundcolor','w','HorizontalAlignment','right');
    try,
      if ~yesorno('Is the result acceptable? [if not define first 3 points again]');
        tmp = ginput(3);
        lim = round(tmp(:,1)/dx);
        lim = lim + GRD1;
      else
        lim = [PREGRD1; GRD1; POSTGRD1];
      end;
      clear ylm tmp t;
    catch,
      close all;
      return;
    end;
  else
    lim = [PREGRD1; GRD1; POSTGRD1];
  end;


  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % APPLY XCOR ANALYSIS AND MAKE FINE ADJUSTMENT OF MRI EVENTS
  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  IPRE   = abs(lim(1)-lim(2));
  IPOST  = abs(lim(2)-lim(3));
  ILEN   = abs(lim(3)-lim(1));
  pat    = dat0([1:ILEN] + lim(1));

  % THIS IS OBSOLETE, BUT KEEP IT FOR COMPARISON...
  % THE FIRST CORRECTION ACCOUNTS FOR THE LINEARLY INCREASING
  % DIFFERENCE BETWEEN THE MRI EVENTS AND THE ACUTAL TIME OF
  % PARAVISION TRIGGER. THE DIFFERENCE IS BECAUSE OF SLIGHTLY
  % DIFFERENT CLOCK SPEEDS AT THE QNX/PARAVISION ENVIRONMENTS.
  % CORFAC = 0.99998203793307;			% Multiply mri() with this number
  % tmri = mriTime - mriTime(1);			% Subtract before scaling
  % tmri = tmri * CORFAC + mriTime(1);	% Add the offset back
  % imri = round(tmri/dx);

  % Instead we use the "tfactor" computed by expgetpar. Because for some sessions that abobe
  % "CORFAC" is not correct. 19.08.04 YM
  % REMINDER: mriTime = evt.obs{iObsp}.origtimes.mri;
  
  % ??????????????????????????????????????????????????????????????????????????????????????
  % TO YUSUKE: It seems that we are re-doing the work here. WHY???? The .times should be
  % fine. And the time corrections are mostly used in this location anyway?!
  % ??????????????????????????????????????????????????????????????????????????????????????
  tmri = mriTime * par.evt.tfactor;
  imri = round(tmri/dx/par.adf.tfactor);
  
  inewmri = zeros(length(tmri),1);
  inewmri(end) = imri(end);

  nlags = round(ILEN/2);
  
  % 06.08.04 YM
  % ENHANCE CONTRASTS TO DETECT CORRECT TIMING.
  tmpmax = max(pat);
  %GradADFData(find(GradADFData >  tmpmax*0.8)) =  tmpmax;

  GradADFData(find(GradADFData < -tmpmax*0.8)) = -tmpmax;
  pat(find(pat < -tmpmax*0.7)) = -tmpmax;

  % use only negative values
  %GradADFData(find(GradADFData > 0)) = 0;
  %pat = pat(find(pat > 0)) = 0;

  for N = 1:length(tmri)-1,
    if ENOUGH_RAM,
      dat = GradADFData((1:ILEN)+imri(N)-IPRE);
    else
      dat = adf_read(adffile,iObsp-1,GradCh-1,imri(N)-IPRE,ILEN);
    end
    [C,lags] = xcorr(pat,dat,nlags,'unbiased');
    [mx,mxi] = max(C);							% optimal lag
    inewmri(N) = imri(N)-(mxi-nlags);			% difference
    if grp.daqver < 2 && N == 2,
      % In old data, 1st grad. signal looks different from others.
      pat = GradADFData([1:ILEN]+inewmri(N)-IPRE);
    end
  end;

  if DEBUG,
    mfigure([50 50 900 700]); cla;  color = 'rgbcmykrgbcmyk';
    PLOTDAT = [];
    for N = length(tmri)-1:-1:1,
      PLOTDAT(N,:) = GradADFData([1:ILEN]+inewmri(N)-IPRE);
    end
    PLOTDAT = PLOTDAT';
    plot(pat,'color','black','linewidth',3);
    hold on;
    plot(PLOTDAT);
    hold on;  grid on;
    keyboard
  end;

  newmri = inewmri * dx;
  SCT.mri{iObsp} = newmri/1000;
  SCT.mri1orig{iObsp} = evt.obs{iObsp}.origtimes.mri(1)/1000;
  SCT.dmri{iObsp} = (mriTime - newmri)/1000;
  clear tmri imri;

  if iObsp == 1,
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % EVEN IF MULTIPLE OBSERVATION PERIODS ARE PRESENT THE LENGTH OF EACH
    % ONE OF THEM WILL BE THE SAME. SO, WE USE THE FIRST OBSERVATION PERIOD'S
    % EVETNS TO CALCULATE PARTIAL READ-LENGTHS FOR LONG FILES.
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    mrilen = inewmri(end) - inewmri(1);
    if ENOUGH_RAM,
      SCT.Seg{1}.beg = 1;
      SCT.Seg{1}.end = length(inewmri);
    else
      sl = ones(round(mrilen/MAXLEN),1) * MAXLEN;
      vollen = inewmri(SCT.NoGrad+1) - inewmri(1);	% Volume length in points
      nevt = round(sl/vollen)*SCT.NoGrad;
      for N=1:length(sl),
        SCT.Seg{N}.beg = (N-1)*round(sl(N)/vollen)*SCT.NoGrad+1;
        SCT.Seg{N}.end = N*round(sl(N)/vollen)*SCT.NoGrad;
      end;
      if SCT.Seg{N}.end < length(inewmri),
        SCT.Seg{N+1}.beg = SCT.Seg{N}.end + 1;
        SCT.Seg{N+1}.end = length(inewmri);
      end;
    end;

    % sometimes length(inewmri) is not times of length(SCT.gradtype).
    % why this happens ?  anyway it's safe to ignore last portion
    % to get proper gradient lengths.          03.03.04 YM
    if mod(length(inewmri),length(SCT.gradtype)) == 0,
      graddt = diff(inewmri);
    else
      N = length(SCT.gradtype);
      graddt = diff(inewmri(1:floor(length(inewmri)/N)*N));
    end

    % ===============================================================
    % SCT.grd = repmat(pv.gradtype(:),pv.nt,1)' is the number of "packages", which should be equal
    % to the number of volumes and number of MRI events. This is not always the case. YM
    % noticed that some data have different number of volumes and MRI events. This is due to
    % the fact that our latest data collection (and of course all the alert monkey data of
    % presence and future) will have randomized presentation times. In such cases the
    % duration of the observation period as computed at the QNX/Stim side will be different
    % from the duration Paravision calculate in terms of "number of volumes". I see only one
    % solution to this problem, which only applies for future-data. Randomization should be
    % done in advance and the total time should be passed to Paravision. To make things
    % easy, we can define the max(ObspDuration) as the paravision time that calculates the
    % number of volumes to be acquired.
    % ===============================================================
    SCT.uniqtype = SCT.gradtype;

    for N = 1:length(SCT.gradtype),
      idx = N:length(SCT.gradtype):length(graddt);

      % USE min(); it's than max(). The latter sometimes includes the next pattern of
      % interference, as the duration of each slice+segment is slightly (by 1-2 ms)
      % different from volume to volume!!
      SCT.uniqlen(N) = min(graddt(idx));
      SCT.uniqdur(N) = SCT.uniqlen(N)*SCT.dx;
    end
    SCT.NoUniq = length(SCT.uniqlen);
    clear graddt idx;
  end

  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % PLOT-2: SHOW 
  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if INTERACTIVE,
    [px,py] = getScreenSize;
    pxlen = px; pylen = py;
    px = 1; py=5;
    
    % THIS HERE IS VERY TIME CONSUMING; IT'S ONLY FOR DEBUGGING
	DUR = round((min(SCT.uniqdur)/3)/SCT.dx);
    if DEBUG,
      X = 20;
      if ENOUGH_RAM,
        sig.dat = GradADFData;
      else
        sig.dat = adf_read(adffile,iObsp-1,GradCh-1);
      end
      sig.dx = dx;
      K = 1;
      NPLOTS = 60;
      figure('Position',[px py pxlen*0.9 pylen*0.9]);
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

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % PCApat = [-dt1*0.1 dt1*1.05];	is the window around MRI event
    % ilen is the window length in points
    % THE NEXT LINES AVERAGE ALL OCCURRENCES OF A TYPE TO SEE WHETHER WE HAVE A GOOD
    % ALIGNEMENT. IF NO SMOOTHING IS VISIBLE, WE ARE IN GOOD SHAPE!
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ilen = round((PCApat(2) - PCApat(1) + 1)/dx);
    for K = 1:length(SCT.uniqtype),
      % FIND REPETITION OF EACH UNIQUE TYPE!
      idx = find(SCT.grd == SCT.uniqtype(K));

      % DISCARD GRADIENTS AFTER LAST MRI EVENT
      idx = idx(find(idx <= length(newmri)));

      pmri = newmri(idx);
      for N = 1:length(pmri)-1,
        ibeg = round((pmri(N) + PCApat(1))/dx);

        if ENOUGH_RAM,
          % It means we loaded already the entire OBSP!
          tmp = GradADFData((1:ilen) + ibeg);
        else
          tmp = adf_read(adffile,iObsp-1,GradCh-1,ibeg,ilen);
        end
        if N == 1,
          dat = tmp;
        else
          dat = dat + tmp;
        end;
      end;
      gra{K} = dat/N;
    end;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % THIS IS THE PLOT SHOWN IN THE INTERACTIVE MODE
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    mfigure([px py+20 pxlen*0.7 pylen-20],'Mean of Each GradType');
    for K = 1:length(SCT.uniqtype),
      subplot(length(SCT.uniqtype),1,K);
      plot([0:length(gra{K})-1]*dx+PCApat(1),gra{K});
      
      % MORE PLOTTING UTILITIES HERE..........
      % Gradient Onset
      % line([PCApat????????????????????????????
      %   ibeg = round((pmri(N) + PCApat(1))/dx);
      set(gca,'xlim',PCApat);
      title(sprintf('Grad Type: %d',SCT.uniqtype(K)));
    end;
    
    xlabel(sprintf('Time in msec; G-Range = [%5.2f %5.2f]', PCApat(1),PCApat(2)));
    suptitle(sprintf('Unique Grad-Pattenrs for Session: %s, ExpNo: %d', Ses.name, ExpNo));

    fh = figure('position',[pxlen*0.7+px py+20 pxlen*0.3 pylen-20]);
    suptitle('PV Parameters');
    set(fh,'DefaultAxesfontsize',8,'color',[.95 .95 1]);
    COL = get(fh,'color');
    TxtAx = axes(...
        'Parent',fh,'Units','char','color',COL,'xtick',[],'xcolor',COL,'ycolor',COL,...
        'ytick',[],'Box','off','ydir','reverse','xtick',[],'ytick',[]);
    fn = fieldnames(pv);
    fn = fn(1:end-3);
    % The previous statement excludes the substructures below
    % times: [1x1 struct]
    % acqp: [1x1 struct]
    % reco: [1x1 struct]

    pos = get(TxtAx,'position');
    pos = round(pos); pos(3)=pos(3)-1; pos(4)=pos(4)-1;
    set(TxtAx,'xlim',[0 pos(3)],'ylim',[0 pos(4)]);
    axes(TxtAx);
    text(2,pos(2)+4,fn,'fontsize',7);
    for FN=1:length(fn),
      fnv{FN} = sprintf('%10.5f',getfield(pv,fn{FN}));
    end;
    text(pos(3)/4,pos(2)+4,fnv,'fontsize',7);
    set(TxtAx,'xticklabel',[],'yticklabel',[]);
    clear fn, fnv;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    try,
      if ~yesorno('Pattern Range. Is it acceptable?');
        fprintf('Current Range = [%5.2f %5.2f]\n',PCApat(1), PCApat(2));
        fprintf('Select Range Manually\n');
        keyboard;
      end;
    catch,
      keyboard
      close all;
    end;
    clear gra tmp dat;
  end
end

% ======================================================================
% Save/Output the result
% ======================================================================
if nargout,
  varargout{1} = SCT;
else
  VAR = sprintf('exp%03d', ExpNo);
  eval(sprintf('%s = SCT;', VAR));
  if ~exist('ClnAdjEvt.mat','file'),
	save('ClnAdjEvt.mat',VAR);
  else
	save('ClnAdjEvt.mat','-append',VAR);
  end;
end


return;

