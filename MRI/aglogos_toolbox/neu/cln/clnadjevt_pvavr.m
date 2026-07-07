function varargout = clnadjevt_pvavr(Ses,ExpNo,INTERACTIVE,DEBUG)
%CLNADJEVT_PVAVR - Adjust the MRI events correcting the QNX/Paravision clockDiff
% CLNADJEVT_PVPVR(SESSION,ExpNo) is the first function to call before the
% actual denoising of the physiology data acquired simultaneously with
% the MR images. The procedure relies on the following assumptions:
%
% VERSION :
%   1.00 09.02.03 NKL  original clnadjevt
%   1.10 03.03.04 YM   rewrite
%   1.11 01.04.04 YM   supports cases with shorter baseline period.
%   1.12 14.12.07 YM   supports funny cases of d973f1
%                      (shape of the 1st noise is different from others...)
%   1.13 31.01.12 YM   use expfilename() instead of catfilename().
%   1.14 12.11.19 YM   use expget"dg"evt() instead of expgetevt().
%
% THIS PROGRAM IS ONLY FOR OLD DATA WITH MULTIPLE OBSP LIKE A003X1.!!!!  
%
% See also CLNHELP GETCLOCKERROR SESCLNADJEVT CLNMAIN CLNADF_PVAVR

if nargin < 2,  help clnadjevt_pvavr; return;  end


CLNADJEVT_VERSION = 1.20;	% version info, will be checked in clnamin/clnadf


if ~exist('INTERACTIVE','var'),  INTERACTIVE = [];  end
if ~exist('DEBUG',      'var'),  DEBUG       = [];  end


if isempty(INTERACTIVE),  INTERACTIVE = 0;  end
if isempty(DEBUG),        DEBUG       = 0;  end

if nargin == 0,
  Ses = 'c01jw1';  ExpNo = 31;
  Ses = 'm02lx1';  ExpNo = 1;
elseif nargin == 1,
  fprintf('usage: adjevt = clnadjevt_pvavr(SESSION,ExpNo);\n');
  return;
end



% ======================================================================
% THIS HERE SHOULD BE ADJUSTED FOR YOUR COMPUTER'S MEMORY CAPACITY!!
% ======================================================================
MAXMEM = 1024e+06;


% ======================================================================
% READ INITIAL SEGMENT TO DEFINE THE SLICE-SELECTION PATTERN
% COMPUTE STATISTICS OF INITIAL SEGMENT, FIND FIRST SLICE-SELECTION
% GRADIENT, AND PLOT PRE, MRI(1), AND POST TIME POINTS
% ======================================================================
NoSTD			= 5;	% Six SDs above mean is the thershold
SustainedPnts	= 5;	% The signal must remain high for at least 5 points 
PreMsec			= 15;	% Before slice selection pulse
%PreMsec			= 5;	% Before slice selection pulse


% ======================================================================
% BASIC INFORMATION
% ======================================================================
Ses = goto(Ses);				% session
grp = getgrp(Ses,ExpNo);		% group
evt = expgetdgevt(Ses,ExpNo);		% event
%pv  = getpvpars(Ses,ExpNo);		% imaging
par = expgetpar(Ses,ExpNo);
pv = par.pvpar;
USE_XCOR = 1;
switch lower(Ses.name),
 case {'b973k1'}
  USE_XCOR = 0;
end

switch lower(Ses.name),
 case {'d991i1'}
  pv.nt = pv.nt * 15;
  pv.gradtype = unique(pv.gradtype);
 otherwise
  pv.nt = pv.nt * pv.nseg;
end


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
switch lower(Ses.name),
 case {'d991i1'}
  dur = 0.0392;  % same as 'a003c1'
 otherwise
  %dur = pv.graddur;
end



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


% ======================================================================
% ADF INFORMATION
% ======================================================================
adffile = expfilename(Ses,ExpNo,'phys');
[NoChanAdf,NoObsp,dx,obslen] = adf_info(adffile);
% 27.09.03 WE OVERWRITE THE NoChan OBTAINED FROM adf_infor BECAUSE
% OF THE ADDITIONAL TWO CHANNELS WE USE FOR THE
% MOVIE-EXPERIMENTS. THE GRADIENT CHANNELS IS NOW -- NOT THE LAST
% CHANNEL, BUT RATHER ONE AFTER THE LAST CHANNEL AS DEFINED IN THE
% GRP.HARDCH
NoChan = length(grp.hardch)+1;



if length(obslen) ~= length(evt.obs),
  fprintf(' clnadjevt_pvavr ERROR: NoObsp differs between dgz and adf/adfw.\n');
  keyboard
end
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
SCT.NoObsp	 = 1;				% Observation number (usually=1)
SCT.NoChan	 = NoChan;				% Number of channels (data=1 or 2)
SCT.NoVol    = pv.nt;				% Number of volumes/time-points

SCT.NoGrad   = length(pv.gradtype);				% e.g 12
SCT.NoUniq	 = length(unique(pv.gradtype));		% 2 unique types
SCT.gradtype = pv.gradtype;						% e.g 121212121212...
SCT.uniqtype = unique(pv.gradtype);				% 12 (like gradtype)
SCT.uniqlen	 = [];
SCT.uniqdur  = [];

% pv.gradtype(:) = 1;
% SCT.NoUniq   = 1;
% SCT.gradtype = 1;
% SCT.uniqtype = 1;


% gradtype: [1 2]
% nt = 440
% SCT.grd = [1 2 1 2 1 2 ......], size=880
SCT.grd	 	 = repmat(pv.gradtype(:),pv.nt/pv.nseg,1)';	% Full gradient pattern
SCT.grange   = PCApat/1000;			% STORE!! in seconds (see remark above)
SCT.dstime   = pv.dstime;			% Dummy scan time
SCT.dx		 = dx/1000;				% STORE!! in seconds (see remark above)
SCT.obslen   = sum(obslen);				% Obs Period Length
SCT.obsdur   = sum(obslen)*SCT.dx;		% Same as obslen but in seconds
SCT.mri		 = [];
SCT.dmri	 = [];


% =======================================================================
% check length of expected gradient pattern and recorded mri events.
% =======================================================================
nmri = 0;
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
  fprintf('\n clnadjevt_pvavr WARNING:');
  fprintf(' length(recorded mri-event) is less than expected.\n');
  fprintf('   NumMriEvents = %d/%d',nmri,length(SCT.grd));
  fprintf('   totlen = %.2fs/%.2fs\n',totdgzlen,pv.nt*pv.imgtr);
  fprintf(' This warning may not apply to cases where stimulus/qnx program changes\n');
  fprintf(' stimulus duration on the fly, while paravision scanning pre-estimated max duration. ...');
  %keyboard
  %return;
end

if DEBUG,
  fprintf('Data Structure "sct"\n');
  SCT
  fprintf('NoChan,NoObsp,dx,obslen: %d,%d,%d,[%s]\n',...
          NoChan,NoObsp,dx,deblank(sprintf('%d ',obslen)));
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
for iObsp = 1:1,
  % GET ORGINAL MRI EVENT TIMES
  % REMINDER -- EXPGETDGEVT: SUBTRACTS THE OFFSET 
  %mriTime = evt.obs{iObsp}.origtimes.mri;	% Saved MRI Events in mseconds
  mriTime = [];   obsoffs = 0;
  for K = 1:NoObsp,
    mriTime = cat(1,mriTime,evt.obs{K}.origtimes.mri(:)+obsoffs);
    obsoffs = obsoffs + evt.obs{K}.origtimes.end(1);
  end

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
  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % CONCATINATE ALL OBSPS INTO A SINGLE OBSP
  MRIADF = [];
  for K = 1:NoObsp,
    MRIADF = cat(2,MRIADF,adf_read(adffile,K-1,GradCh-1));
  end
  switch lower(Ses.name),
   case {'b005j1'},
    % NO GRAD. SIGNALS, USE PHYSIOLOGY DATA.
    [b,a] = butter(3,5/(1000/dx/2),'high');
    MRIADF = filtfilt(b,a,MRIADF);
  end
  dat0 = MRIADF(1:mriIndx(2));

  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % COMPUTE BASELINE STATISTICS
  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if iObsp == 1,
    % IF DUMMIES EXIST THEN START EARLIER THAN MRI(1)
    if isfield(grp,'pvavr') && grp.pvavr > 0,
      % imaging data was averaged by paravision,usually 8 obsp -> 1 obsp
      GradStartT = mriTime(1);
    elseif isfield(pv,'dstime') & pv.dstime > 0,
      GradStartT = mriTime(1) - pv.dstime * 1000;
    else
      GradStartT = mriTime(1);
    end;
    if GradStartT <= 1,
      % 07.Oct.03 YM
      % likely that the state system was started after start of ParaVision.
      fprintf('\n clnadjevt_pvavr ERROR: ExpNo=%d ObspNo=%d',ExpNo,iObsp);
      fprintf(' GradStartT[%d] >= mriTime(1)[%d]\n',GradStartT,mriTime(1));
      fprintf(' State system likely started after the first MRI event.\n');
      return;
      keyboard
      GradStartT = 2; % ??? what should we do ????
    end
    PREIDX = [1:round((GradStartT-1)/dx)]';	% baseline region in points
    mBase = nanmean(dat0(PREIDX));
    sBase = nanstd(dat0(PREIDX));
    % 01.07.04 YM:
    % Sometimes this PREIDX involves grad.signals in most of its period,
    % resulting large "sBase" that may cause failure of detecting signals.
    % To avoid this, check "sBase" with that of the first 50ms.
    if sBase > NoSTD * nanstd(dat0(1:round(50/dx))),
      % take the first 50ms as a baseline region.
      PREIDX = 1:round(50/dx);
      mBase = nanmean(dat0(PREIDX));
      sBase = nanstd(dat0(PREIDX));
    end
    % check again, this happens when grad.sinal starts before first 50ms...
    if abs(NoSTD * sBase) >= max(dat0-mBase)*0.8,
      PREIDX = find(abs(dat0-mBase) < max(dat0-mBase)*0.05);
      mBase = nanmean(dat0(PREIDX));
      sBase = nanstd(dat0(PREIDX));
    end
    
    THR = abs(NoSTD * sBase);
    clear PREIDX;
  end

  if iObsp >= 2,
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


  % WE WANT TO FIND THE FIRST "SustainedPnts" above CRITERION
  % WE TAKE THE DIFFERENCE OF INDICES AND SEARCH FOR THE FIRST N
  % WHICH (THE INDICES) HAVE VALUE OF 1
  IDX = find(abs(dat0 - mBase) > THR);
  didx = diff(IDX);		% If consequtive points their diff will be 1
  switch lower(Ses.name),
   case {'b005j1'}
    didx(find(didx < 100)) = 1;
   case {'b00401'}
    didx(find(didx < 50)) = 1;
  end
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
%   for N = 1:length(didx)-SustainedPnts,
%     if all(didx(N:N+SustainedPnts) == 1),
%       if IDX(N) <= round(PreMsec/dx),
%         % skip to the next grad. signal
%         N2 = find(didx > max(didx)*0.2);
%         N2 = N2(find(N2 > N));
%         N  = N2(1) - 1;
%         continue;
%       end
%       GRD1 = IDX(N);
%       break;
%     end;
%   end;
  if GRD1 <= 0,
    fprintf('\n clnadjevt_pvavr ERROR: failed to detect GRD1.\n');
    keyboard
  end
  PREGRD1  = GRD1 - round(PreMsec/dx);
  POSTGRD1 = round(GRD1 + (dur*1000)/dx);

  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % SHOW RESULTS TO USER AND CHECK IF MANUAL CORRECTIONS ARE NEEDED
  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  lim = [PREGRD1; GRD1; POSTGRD1];
  if INTERACTIVE | DEBUG,
    mfigure([2 400 1000 500]);
    set(gcf,'Name',sprintf('Ses:%s  ExpNo:%d  %s',Ses.name,ExpNo,adffile));
    set(gcf,'NumberTitle','off');
    t = [0:length(dat0)-1]*dx - GRD1*dx;
    plot(t,dat0,'k');
    % NOTE:
    % pv.graddur*1050 is 0.5% more duration than that obtained by
    % pvpars...
    set(gca,'xlim',round([PREGRD1*dx*0.999-GRD1*dx pv.graddur*2000])*2);
    xlabel('time / ms');
    ylm = get(gca,'ylim');
    ylm = ylm(2);
    % PRE SLICE SELECTION
    t = PREGRD1*dx-GRD1*dx;
    line([t t],get(gca,'ylim'),'color','b');
    text(t,ylm*0.9,'Pre-slice Selection','FontWeight','bold');
    % ONSET OF SLICE SELECTION
    t = GRD1*dx-GRD1*dx;
    line([t t],get(gca,'ylim'),'color','r');
    text(t,ylm*0.7,'Slice Selection','FontWeight','bold');
    % POST SLICE SELECTION
    t = POSTGRD1*dx-GRD1*dx;
    line([t t],get(gca,'ylim'),'color','b');
    text(t,ylm*0.7,'Post-slice Selection','FontWeight','bold','color','b','horizontalalignment','right');
    % END OF INTERFERENCE
    t = GRD1*dx-GRD1*dx+pv.graddur*1000;
    %t = GRD1*dx-GRD1*dx+dur*1000;
    line([t t],get(gca,'ylim'),'color','y','linewidth',2);
    text(t,ylm*0.9,'End of Interference','FontWeight','bold','color',[0.6 0.6 0],'horizontalalignment','right');
    grid on;
    
    if INTERACTIVE,
      if ~yesorno('Is the result acceptable?');
        tmp = ginput(3);
        lim = round(tmp(:,1)/dx);
        lim = lim + GRD1;
      end
    end;
    clear ylm tmp t;
    if ~DEBUG, close all;  end
  end;


  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % APPLY XCOR ANALYSIS AND MAKE FINE ADJUSTMENT OF MRI EVENTS
  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  IPRE   = abs(lim(1)-lim(2));
  IPOST  = abs(lim(2)-lim(3));
  ILEN   = abs(lim(3)-lim(1));
  
  pat    = dat0([1:ILEN] + lim(1));

  % THE FIRST CORRECTION ACCOUNTS FOR THE LINEARLY INCREASING
  % DIFFERENCE BETWEEN THE MRI EVENTS AND THE ACUTAL TIME OF
  % PARAVISION TRIGGER. THE DIFFERENCE IS BECAUSE OF SLIGHTLY
  % DIFFERENT CLOCK SPEEDS AT THE QNX/PARAVISION ENVIRONMENTS.
  %CORFAC = 0.99998203793307;			% Multiply mri() with this number
  %tmri = mriTime - mriTime(1);			% Subtract before scaling
  %tmri = tmri * CORFAC + mriTime(1);	% Add the offset back
  %imri = round(tmri/dx);

  % 19.08.04 YM: use "tfactor" computed by expgetpar.
  % There are sessions that abobe "CORFAC" is not correct.
  tmri = mriTime * par.evt.tfactor;
  imri = round(tmri/dx/par.adf.tfactor);
  
  inewmri = zeros(length(tmri),1);
  inewmri(end) = imri(end);

  nlags = round(ILEN/2);
  %nlags = round(IPOST/2);

  % 06.08.04 YM
  % ENHANCE CONTRASTS TO DETECT CORRECT TIMING.
  tmpmax = max(pat);
  MRIADF(find(MRIADF >  tmpmax*0.9)) =  tmpmax;
  MRIADF(find(MRIADF < -tmpmax*0.8)) = -tmpmax;
  pat(find(pat >  tmpmax*0.9)) =  tmpmax;
  pat(find(pat < -tmpmax*0.8)) = -tmpmax;
  % use only negative values
  %MRIADF(find(MRIADF > 0)) = 0;
  %pat = pat(find(pat > 0)) = 0;
  if USE_XCOR,
    for N = 1:length(tmri)-1,
      dat = MRIADF((1:ILEN)+imri(N)-IPRE);
      [C,lags] = xcorr(pat,dat,nlags,'unbiased');
      [mx,mxi] = max(C);							% optimal lag
      inewmri(N) = imri(N)-(mxi-nlags);			% difference
      if N ==2,
        % In old data, 1st grad. signal looks different from others.
        pat = MRIADF([1:ILEN]+inewmri(N)-IPRE);
      end
    end;
  else
    % just do edge detection
    for N = 1:length(tmri)-1,
      dat = MRIADF((1:ILEN)+imri(N)-IPRE);
      tmpidx = find(dat(:) < -600);
      if ~isempty(tmpidx),
        inewmri(N) = imri(N)+tmpidx(1)-IPRE;
      else
        % nothing can do..
        % likely to have only slice-selection..., b973k1,ExpNo=38,N=512
        inewmri(N) = imri(N);
      end
    end
  end
  
  % then do edge detection
  for N = 1:length(tmri)-1,
    dat = MRIADF((1:ILEN)+inewmri(N));
    tmpidx = find(dat(:) < -600);
    if ~isempty(tmpidx),
      inewmri(N) = inewmri(N)+tmpidx(1)-1;
    end
  end
  
  % data of old session has something before slice selection
  %inewmri = inewmri - 300; % ~14ms for noise before slice-selection

  if DEBUG,
    figure(100+iObsp); color = 'rgbcmykrgbcmyk';
    subplot(2,1,1); cla;
    
    PLOTDAT = [];
    for N = length(tmri)-1:-1:1,
      PLOTDAT(N,:) = MRIADF([1:ILEN]+inewmri(N)-IPRE);
    end
    PLOTDAT = PLOTDAT';
    plot(pat,'color','black','linewidth',3);
    hold on;
    plot(PLOTDAT);
    hold on;  grid on;
    clear PLOTDAT;
    
    subplot(2,1,2); cla;
    tmpskip = 20;
    plot(1:tmpskip:length(MRIADF),MRIADF(1:tmpskip:end));
    grid on;  hold on;
    for N = 1:length(inewmri),
      line([inewmri(N) inewmri(N)], get(gca,'ylim'),'color','k');
    end
    xlabel('Time in points');
    
  end
  
  
  newmri = inewmri * dx;
  SCT.mri{iObsp} = newmri/1000;
  SCT.mri1orig{iObsp} = evt.obs{iObsp}.origtimes.mri(1)/1000;
  SCT.dmri{iObsp} = (mriTime - newmri)/1000;
  clear tmri imri;
  

  if iObsp == 1,
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % EVEN IF MULTIPLE OBSERVATION PERIODS ARE PRESENT THE LENGTH OF EACH
    % ON OF THEM WILL BE THE SAME. SO, WE USE THE FIRST OBSERVATION PERIOD'S
    % EVETNS TO CALCULATE PARTIAL READ-LENGTHS FOR LONG FILES.
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    mrilen = inewmri(end) - inewmri(1);
    SCT.Seg{1}.beg = 1;
    SCT.Seg{1}.end = length(inewmri);


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
    % we should use length of mri-events in dgz not SCT.grd.
    % because we have some cases where stimulus program
    % changes stimulus duration on fly while paravision
    % scans estimated maximum duration.  01.03.04 YM
    SCT.uniqtype = SCT.gradtype;
    for N = 1:length(SCT.gradtype),
      %idx = N:length(SCT.gradtype):length(SCT.grd);
      tmpgrad = graddt(N:length(SCT.gradtype):length(graddt));
      % remove exceptional cases
      tmpgrad = tmpgrad(find(tmpgrad < mean(tmpgrad)*3));
      % min() is a little better than max().
      % for m02lx1,ExpNo=1,
      % max(): WARNING OUTLIERS: 24507/2694556 Values (p=0.00909500)
      % min(): WARNING OUTLIERS: 24429/2694556 Values (p=0.
      %SCT.uniqlen(N) = max(tmpgrad);
      SCT.uniqlen(N) = min(tmpgrad);
      SCT.uniqdur(N) = SCT.uniqlen(N)*SCT.dx;
      %keyboard
    end
    % make sure NoUniq is the same length of uniqlen.
    SCT.NoUniq = length(SCT.uniqlen);
    clear graddt tmpgrad;
  end

  if INTERACTIVE | DEBUG,
	DUR = round((max(SCT.uniqdur)/3)/SCT.dx);
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SHOW RESULTS NOW (PATTERN AFTER PATTERN...)
    % IF THEY ARE ACCEPTABLE SAVE DATA INTO ClnAdjEvt.mat
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    DISPLAY_TRIAL = 0;
    if DISPLAY_TRIAL,
      X = 20;
      sig.dat = MRIADF;
      sig.dx = dx;
      K = 1;
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
    for K = 1:length(SCT.uniqtype),
      idx = find(SCT.grd == SCT.uniqtype(K));
      idx = idx(find(idx <= length(newmri)));
      pmri = newmri(idx);
      for N = 1:length(pmri)-1,
        ibeg = round((pmri(N) + PCApat(1))/dx);
        tmp = MRIADF((1:ilen) + ibeg);
        if N == 1,
          dat = tmp;
        else
          dat = dat + tmp;
        end;
      end;
      gra{K} = dat/N;
    end;

    mfigure([1 50 600 900]);
    for K = 1:length(SCT.uniqtype),
      subplot(length(SCT.uniqtype),1,K);
      plot([0:length(gra{K})-1]*dx+PCApat(1),gra{K});
      set(gca,'xlim',PCApat);
    end;
    xlabel(sprintf('Time in msec; G-Range = [%5.2f %5.2f]',...
                   PCApat(1),PCApat(2)));
    suptitle(sprintf('Session: %s, ExpNo: %d', Ses.name, ExpNo));

	if INTERACTIVE,
      if ~yesorno('Pattern Range. Is it acceptable?');
        fprintf('Current Range = [%5.2f %5.2f]\n',PCApat(1), PCApat(2));
        fprintf('Select Range Manually\n');
        keyboard;
      end;
    end
    clear gra tmp dat;
    if ~DEBUG, close all;  end
  end
  
end


if DEBUG,
  
  
end


% ======================================================================
% Save/Output the result
% ======================================================================
if nargout,
  varargout{1} = SCT;
else
  if sesversion(Ses) >= 2,
    sigsave(Ses,ExpNo,'clnadj',SCT,'verbose',0);
  else
    VAR = sprintf('exp%03d', ExpNo);
    eval(sprintf('%s = SCT;', VAR));
    if ~exist('ClnAdjEvt.mat','file'),
      save('ClnAdjEvt.mat',VAR);
    else
      save('ClnAdjEvt.mat','-append',VAR);
    end;
  end
end


return;

