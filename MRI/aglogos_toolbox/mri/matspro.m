function roiTs = matspro(SESSION,ExpNo,ARGS)
%MATSPRO - Process the TS of each area in roiTs of each experiment
% MATSPRO (SESSION, ExpNo, ARGS) reads the catfilename(ses,expno)
% matlab file and processes the time series.
%  
% See also MAREATS
%  
% NKL 12.03.04

IDEBUG = 0;
if IDEBUG,
  SESSION = 'n03ow1';
  SESSION = 'd04pa1';
  SESSION = 'e04pb1';
  ExpNo = 2;
  Area = 'V1';
end;

% GENERAL PROCESSING
DEF.IHIGHPASS               = 0;		% High pass filter w/ a small kernel
DEF.ILOWPASS                = 0;		% Low pass filter w/ a small kernel
DEF.IDETREND                = 0;		% Detrend (if no highpas...)
DEF.ITOSDU                  = 1;		% Convert to SD Units
DEF.ICOEFVARIATION          = 0;		% Convert to SD Units

% RESPIRATION ARTIFACT REMOVAL
DEF.IRESPFLT                = 0;		% Remove respiratory art. (not used)
DEF.IRESPAUTOREGRESS        = 0;		% Remove respiratory art. (not used)
DEF.IRESPICA                = 0;		% Remove respiratory art. (not used)
DEF.IRESPPCA                = 0;		% Remove respiratory art. (not used)
DEF.ISPIKEREMOVAL           = 0;		% Remove spike-like outliers

% INCLUDE/EXCLUDE BUSINESS...
DEF.IEXCLUDE                = {'brain';'ele'};
DEF.ISAVE                   = ~IDEBUG;
DEF.IPLOT                   = IDEBUG;

%%% IF ARGS EXIST APPEND DEFAULTS ON THEM AND EVALUATE ALL
if ~IDEBUG & nargin < 2,
  help matspro;
  return;
end;
  
if exist('ARGS','var'),
  ARGS = sctcat(ARGS,DEF);
else
  ARGS = DEF;
end;
pareval(ARGS);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% READ DATA AND PROCESS  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);                    % Read session info
filename = catfilename(Ses,ExpNo);
roiTs = matsigload(filename,'roiTs');

if IHIGHPASS,
  cutoff = 0.125;
  [b,a] = cheby1(6,0.1,cutoff,'high');
  for N=1:length(roiTs),
    for K=1:size(roiTs{N}.dat,2),
      roiTs{N}.dat(:,K) = filtfilt(b,a,roiTs{N}.dat(:,K));
    end;
  end;
  if 0,
  % Based on the modeling results (see mtimeseries) most of the
  % power of the brief pulses is around 0.1Hz. 
  for N=1:length(roiTs),
    roiTs{N} = sigfilt(roiTs{N},0.125,'high');
  end;
  end;
  
end;

%%%%% LOW/HIGH PASS FILTERING TO SMOOTH & REMOVE SLOW OSCILLATIONS
if ILOWPASS,
  % The highest stimulus frequency for each deconvolution could
  % recover the neural signal in our studies (see deconvolution in
  % our Roy Proc 2002) was 0.21Hz. Modeling the BOLD response for
  % very brief pulses (e.g. mbriefpulses.m and Josef's paper) shows
  % that the fastest pulse we can use (30ms) has all the power
  % below 0.8Hz. So, it's safe to lowpass filter with a cutoff of .8Hz.
  % All this makes sense only for fast scans. Typically our fast
  % Time-Course paradigm has a sampling rate of 4Hz. Lower rates
  % (min 2Hz) would be also fine; So we check:
  MAXFREQ = 0.8;
  srate = 1/roiTs{1}.dx;
  if IDEBUG,
    tmpTs = roiTs;
  end;
  if srate > (2 * MAXFREQ),
    for N=1:length(roiTs),
      roiTs{N} = sigfilt(roiTs{N},ILOWPASS,'low');
    end;
  end;
end;

if IDETREND,
  for N=1:length(roiTs),
    roiTs{N}.dat = detrend(roiTs{N}.dat);
  end;
end;

%%%%% REMOVING RESPIRATORY ARTIFACTS BY APPLYING ONE OF THE
%%%%% FUNCTIONS BELOW...
if IRESPFLT,
  for N=1:length(roiTs),
    roiTs{N} = Denoise('respflt',roiTs{N});
  end;
elseif IRESPPCA,
  Sig = plethload(Ses,ExpNo);
  DecFac = round(roiTs{1}.dx/Sig.dx);
  y = Sig.dat(1:DecFac:end);
  y = y(1:size(roiTs{1}.dat,1));
  clear Sig;
  [PC, eVar, Proj, SigMean] = doPCA(roiTs{1}.dat,10);
  FracVar = eVar / sum(eVar);
  % -------------------------------------------------------------------
  % SELECT RELEVANT PCs/ICs BY CHECKING THEIR COR W/ AVG INTERFERENCE
  % -------------------------------------------------------------------
  clear pcacoef;
  CRITICAL_COEF = 0.25;
  pcalags = 20;
  for NPC = 1:size(PC,2),
    tmp = xcov(y,PC(:,NPC),pcalags,'coeff');
    pcacoef(NPC) = max(abs(tmp));
  end;
  pcidx = find(pcacoef > CRITICAL_COEF);
  RECODAT = roiTs{1}.dat - repmat(SigMean,[1,size(roiTs{1}.dat,2)]);
  Interference = PC(:,pcidx) * squeeze(Proj(:,pcidx))';
  RECODAT = RECODAT - Interference;
  RECODAT = repmat(SigMean,[1,size(roiTs{1}.dat,2)])+RECODAT;

  mfigure([500 100 500 800]);
  subplot(3,1,1);
  myfft(detrend(mean(roiTs{1}.dat,2)),1/roiTs{1}.dx);
  title('roiTs');
  subplot(3,1,2);
  myfft(mean(Interference,2),1/roiTs{1}.dx);
  title('Interference');
  subplot(3,1,3);
  myfft(detrend(mean(RECODAT,2)),1/roiTs{1}.dx);
  title('RECO');
  
  % ******* THIS SEEMS TO WORK, I MUST
elseif IRESPAUTOREGRESS,
elseif IRESPICA,
elseif ISPIKEREMOVAL,
end;

if ITOSDU,
  for N=1:length(roiTs),
    roiTs{N} = tosdu(roiTs{N});
    if exist('tmpTs','var'),
      tmpTs{N} = tosdu(tmpTs{N});
    end;
  end;
end;

if ICOEFVARIATION,
  for N=1:length(roiTs),
    roiTs{N} = tosdu(roiTs{N});
    if exist('tmpTs','var'),
      tmpTs{N} = tosdu(tmpTs{N});
    end;
  end;
end;

for N=1:length(roiTs),
  roiTs{N}.avg = hnanmean(roiTs{N}.dat,2);
  roiTs{N}.err = hnanstd(roiTs{N}.dat,2);
  roiTs{N}.err = roiTs{N}.err / sqrt(size(roiTs{N}.dat,2));
end;

if ISAVE,
  filename = catfilename(Ses,ExpNo,'mat');
  if exist(filename,'file'),
    save(filename,'-append','roiTs');
  else
    save(filename,'roiTs');
  end;
end;

if IPLOT,
  mfigure([1 450 1240 500]);
  COL='krgbmyckrgbmyckrgbmyckrgbmyckrgbmyc';
  R=1;
  for RoiNo=1:length(roiTs),
    t = [0:length(roiTs{RoiNo}.avg)-1] * roiTs{RoiNo}.dx;
    s{RoiNo} = roiTs{RoiNo}.roiname;
    if exist('Area','var') & ~strcmp(Area,s{RoiNo}),
      continue;
    end;
    if exist('tmpTs','var'),
      c = [.8 .9 .8];
%     plot(t,mean(tmpTs{RoiNo}.dat,2),'color',c,'linewidth',2);
      area(t,mean(tmpTs{RoiNo}.dat,2),'facecolor',c,'edgecolor',c);
    end;
    hold on;
    h(R) = plot(t,roiTs{R}.avg,COL(R));
    R=R+1;
  end;
  xlabel('Time in seconds');
  ylabel('SD Units');
  set(gca,'xlim',[t(1) t(end)]);
  suptitle(sprintf('matspro(%s,%d)',Ses.name,ExpNo),'r');
  legend(h,s,1);

  roiTs = getbriefstmt(roiTs);

  drawstmlines(roiTs{1},'color','r','linewidth',1,'linestyle',':');
  hold off;
  txt = num2str(roiTs{1}.stm.t{1});
  title(txt);
  
  pars=getsortpars('n03ow1',1);
  
  ts = sigsort(roiTs{1},pars.trial);
  for N=1:length(ts),
    dat(:,N) = mean(ts{N}.dat,2);
  end;
  figure(1000);
  plot(mean(dat,2));
  
  keyboard
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = Denoise(proc,Sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RESPLIM1 = 0.38;
RESPLIM2 = 0.41;
oSig = Sig;
dx = Sig.dx;
m = Sig.dat;
oSig = rmfield(oSig,'dat');

nyq = (1/dx)/2;
switch lower(proc),
 case {'respflt'},
  fdat = fft(m,2048,1);
  LEN = size(fdat,1)/2;
  famp = abs(fdat(1:LEN,:));
  freq = ((1/dx)/2) * [0:LEN-1]/(LEN-1);
  freq = freq(:);
  famp = mean(famp,2);
  idx1 = find(freq>0.35 & freq < 0.46);
  idx2 = find(freq>0.70 & freq < 0.92);
  idx3 = find(freq>1.05 & freq < 1.38);
  idx4 = find(freq>1.40 & freq < 1.80);
  [mf, f1] = max(famp(idx1));
  [mf, f2] = max(famp(idx2));
  [mf, f3] = max(famp(idx3));
  [mf, f4] = max(famp(idx4));
  f1 = f1 + idx1(1) - 1;
  f2 = f2 + idx2(1) - 1;
  f3 = f3 + idx3(1) - 1;
  f4 = f4 + idx4(1) - 1;
  frange{1} = [freq(f1)-0.005 freq(f1)+0.005];
  frange{2} = [freq(f2)-0.005 freq(f2)+0.005];
  frange{3} = [freq(f3)-0.005 freq(f3)+0.005];
  frange{4} = [freq(f4)-0.005 freq(f4)+0.005];
  [b,a] = butter(1,frange{1}/nyq,'stop');
  [b1,a1] = butter(1,frange{2}/nyq,'stop');
  [b2,a2] = butter(1,frange{3}/nyq,'stop');
  [b3,a3] = butter(1,frange{4}/nyq,'stop');
  fm = m;
  for K=1:size(fm,2),
    fm(:,K) = filtfilt(b,a,m(:,K));
    fm(:,K) = filtfilt(b1,a1,fm(:,K));
    fm(:,K) = filtfilt(b2,a2,fm(:,K));
    fm(:,K) = filtfilt(b3,a3,fm(:,K));
  end;
 case {'icadenoise'},
  W = amuse(m');
  demixedSources = W * m';
  m = demixedSources';
  fdat = fft(m,2048,1);
  LEN = size(fdat,1)/2;
  famp = abs(fdat(1:LEN,:));
  freq = ((1/dx)/2) * [0:LEN-1]/(LEN-1);
  freq = freq(:);
  clear fdat;
  ix = find(freq>RESPLIM1 & freq < RESPLIM2);
  for N=1:size(famp,2),
    tmp(N) = max(famp(ix,N));
  end;
  [stmp,six]=sort(tmp);
  six = six(:);
  NoComp = 2;
  SIX = six(end-NoComp+1:end);
  RespSig = m(:,SIX);
  tmp = demixedSources';
  tmp(:,SIX) = zeros(size(tmp,1),NoComp);
  fm = (inv(W) * tmp')';
end
oSig.dat = fm;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [PC, eVar, Proj, SigMean] = doPCA(dat, nopcs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dat		= dat';							% transpose dat (T,N)->(N,T)
SigMean	= mean(dat,1);					% mean value along N
for N = 1:size(dat,2),
  dat(:,N) = dat(:,N) - SigMean(N);		% center the data
end
tmpcov	= cov(dat);						% compute covariance matrix

% [U,eVar,PC] = SVDS(dat,nopcs) computes the the nopcs first singular
% vectors of dat. If A is NT-by-N and K singular values are
% computed, then U is NT-by-K with orthonormal columns, eVar is K-by-K
% diagonal, and V is N-by-K with orthonormal columns.
[U, eVar, PC] = svds(tmpcov, nopcs);	% find singular values

eVar  = diag(eVar);						% turn diagonal mat into vector.
SigMean = SigMean(:);					% return mean
Proj = dat * PC;						% Proj centered dat onto PCs.
return;

