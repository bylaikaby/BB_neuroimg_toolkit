function varargout = clnadjevt(Ses, ExpNo, INTERACTIVE, DEBUG)
%CLNADJEVT - detects MRI events for cleaning interference noises.
%  CLNADJEVT(SESSION,EXPNO,[INTERACTIVE=0],[DEBUG=0]) detects MRI events for 
%  cleaning interference noises.
%
%  NOTES :
%    The first MRI events for each segment/slices are used as template to get 
%  precise timing of noise by xcorr().  This function generates only exact timing of
%  events and should not include things that effect on later processing, 
%  for example how many preceding points for PCA data etc.
%
%  The function generates a structure telling timing of interferance noise, like
%    exp001 = 
%        version: 2
%           date: '24-May-2005 18:11:41'
%          ExpNo: 1
%        adffile: '//Win49/M/DataNeuro/I04.vp1/i04vp1_001.adfw'
%         NoObsp: 1
%             dx: 4.8000e-005
%         obslen: 1685087
%       GradChan: 2                       <--- gradient channel number
%          NoVol: 256
%         NoGrad: 4
%         dstime: 6
%       gradtype: [1 1 2 2]
%            grd: [1x1024 double]         <--- gradient sequence, NoVol*NoGrad
%        SS_PNTS: [1x1024 double]         <--- MRI event timings in adf points
%        SS_OBSP: [1x1024 double]         <--- obsp of MRI event timings
%        SS_OFFS:                         <--- The first MR trigger in points 
%
%  VERSION :
%    0.90 20.05.05 YM  pre-release  derived from CLNADJEVT.m of NKL.
%    0.91 02.08.05 YM  bug fix, clean up etc.
%    0.92 15.08.05 YM  supports old data like m02lx1, where the last grad. data is missing.
%    0.93 26.04.06 YM  minimizes errors if distored by microstimulation artifacts (f05bf1).
%    0.94 17.05.06 YM  suppports cases where grad.noise start from positive (spin-echo).
%    0.95 29.01.08 YM  trys to interpolate missing triggers if needed.
%    0.96 28.02.08 YM  bug fix on Matlab's std() for integer, supports Matlab2007b.
%    0.97 15.09.11 YM  warning when GradStartT <= 0.
%    0.98 08.11.11 YM  improved baseline detection for the rat7T scanner.
%    0.99 31.01.12 YM  use expfilename() instead of catfilename().
%
%  See also CLNHELP SESCLNADJEVT CLNMAIN CLNADF CLNADJEVT_PVAVR

if nargin < 2,  help clnadjevt; return;  end


CLNADJEVT_VERSION = 2.20;


if ~exist('INTERACTIVE','var'),  INTERACTIVE = [];  end
if ~exist('DEBUG',      'var'),  DEBUG       = [];  end


% CONTROL SETTINGS/FLAGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SUPPORT_OLDFORMAT = 0;
if isempty(INTERACTIVE),  INTERACTIVE = 0;  end
if isempty(DEBUG),        DEBUG       = 0;  end


% ======================================================================
% BASIC INFORMATION
% ======================================================================
Ses = goto(Ses);				% session
grp = getgrp(Ses,ExpNo);		% group
par = expgetpar(Ses,ExpNo);
pv  = par.pvpar;
evt = par.evt;

if isfield(grp,'pvavr') && grp.pvavr > 0,
  varargout = clnadjevt_pvavr(Ses,ExpNo,INTERACTIVE,DEBUG);
  return
end


% ======================================================================
% READ INITIAL SEGMENT TO DEFINE THE SLICE-SELECTION PATTERN
% COMPUTE STATISTICS OF INITIAL SEGMENT, FIND FIRST SLICE-SELECTION
% GRADIENT, AND PLOT PRE, MRI(1), AND POST TIME POINTS
% ======================================================================
NoSTD			= 10;	% Ten SDs above mean is the threshold
SustainedPnts	= 10;	% The signal must remain stable for at least 10 points 


% ======================================================================
% ADF INFORMATION
% ======================================================================
adffile = expfilename(Ses,ExpNo,'phys');
if ~exist(adffile,'file'),
  error('ERROR %s: ''%s'' not found.\n',mfilename,adffile);
end
[adfNoChan,adfNoObsp,adfDX, adfObslen] = adf_info(adffile);
if isfield(grp,'gradch') && ~isempty(grp.gradch),
  GRAD_CHAN = grp.gradch;
else
  GRAD_CHAN = length(grp.hardch) + 1;
end
if GRAD_CHAN > adfNoChan,
  fprintf('\n %s WARNING: No grad. noise recored.',mfilename);
  fprintf(' Use the last channel as a noise source.');
  GRAD_CHAN = adfNoChan;
end
%PHYS_CHAN = length(grp.hardch);

if length(adfObslen) ~= length(evt.obs),
  if isfield(grp,'validobsp') && ~isempty(grp.validobsp),
    fprintf('\nWARNING: ADF/DGZ-obsplen mismatch; using adfObslen = adfObslen(grp.validobsp)\n');
    adfObslen = adfObslen(grp.validobsp);
  else
    fprintf('\n %s ERROR: NoObsp differs between dgz and adf/adfw.\n',mfilename);
    keyboard
  end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% evt.obs{ObsNo}.origtimes
% It includes the event times as read from the dgz file, without any corrections.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if length(evt.obs) == 1,
  adfObslen = adfObslen(1);
end

IS_MICROSTIM = ismicrostimulation(Ses,ExpNo);

for iObsp = 1:length(adfObslen),
  tmpd = evt.obs{iObsp}.origtimes.end - adfObslen(iObsp)*adfDX;
  tmpd = tmpd / evt.obs{iObsp}.origtimes.end * 100;
  if abs(tmpd) > 0.1,
    fprintf('\n WARNING %s: obsp=%d is collapsed,',mfilename,iObsp);
    fprintf(' adflen=%.3fs, dgzlen=%.3fs.\n',...
            adfObslen(iObsp)*adfDX/1000.,evt.obs{iObsp}.origtimes.end/1000.);
    %keyboard;
  end
  % check mri-events too, some OLD DATA has empty mri-events.
  if isempty(evt.obs{iObsp}.origtimes.mri),
    NoObsp = iObsp-1;  break;
  end
  NoObsp = iObsp;
end

if NoObsp > 1,
  fprintf('\n %s WARNING: Multiple Observation periods.', mfilename);
end;


% if MRI triggers are not for each gradient signal, then interpolate it.
if pv.nseg*pv.nsli > 1,
  dt_trig_rec = mean(diff(evt.obs{1}.times.mri));
  dt_trig     = pv.imgtr/pv.nseg/pv.nsli * 1000;  % in msec
  ninterp     = round(dt_trig_rec/dt_trig);
  if ninterp > 1,
    fprintf('\n %s WARNING: interp missing triggers (ninterp=%d)...',mfilename,ninterp);
    tmpdt = dt_trig_rec/ninterp;
    for N = 1:length(evt.obs),
      tmpmri = [];
      for K = 1:length(evt.obs{N}.times.mri)
        tmpmri(end+1) = evt.obs{N}.times.mri(K);
        for L = 1:ninterp-1,
          tmpmri(end+1) = evt.obs{N}.times.mri(K) + L*tmpdt;
        end
      end
      evt.obs{N}.times.mri = tmpmri;
      tmpmri = [];
      for K = 1:length(evt.obs{N}.origtimes.mri)
        tmpmri(end+1) = evt.obs{N}.origtimes.mri(K);
        for L = 1:ninterp-1,
          tmpmri(end+1) = evt.obs{N}.origtimes.mri(K) + L*tmpdt;
        end
      end
      evt.obs{N}.origtimes.mri = tmpmri;
    end
    clear tmpdt tmpmri;
  end
end


% ================================================================================
% Compare the number of expected gradient patterns with the recorded mri events.
% ================================================================================
nmri_expected = length(pv.gradtype) * pv.nt;
nmri_recorded = 0;
for N = 1:length(evt.obs),
  nmri_recorded = nmri_recorded + length(evt.obs{N}.origtimes.mri);
end
if nmri_recorded < nmri_expected,
  % ==============================================
  % This may not be an error in cases where stimulus program
  % changes stimulus duration on fly.  01.03.04 YM
  totdgzlen = 0;
  for N = 1:length(evt.obs),
    totdgzlen = totdgzlen + evt.obs{N}.times.end/1000.;
  end
  fprintf('\n %s WARNING:',mfilename);
  fprintf(' length(recorded mri-event) is less than expected.\n');
  fprintf('   NumMriEvents = %d/%d',nmri_recorded,nmri_expected);
  fprintf('   totlen = %.2fs/%.2fs\n',totdgzlen, pv.nt*pv.imgtr);
  fprintf(' This warning may not apply when the stimulus/qnx programs change\n');
  fprintf(' the stimulus duration during the experiment.\n');
  fprintf(' This is so, because paravision pre-estimates max duration.\n');
  fprintf(' PRESS A KEY TO CONTINUE.');
  pause;
end



DX_CORRECTED = adfDX * par.adf.tfactor;
SS_PNTS = [];  SS_OBSP = [];
% ======================================================================
% DETECT PRECISE TIMING OF INTERFERENCE NOISE
% ======================================================================
for iObsp = 1:NoObsp,
  % GET ORIGINAL MRI EVENT TIMES
  % REMINDER: evt.obs{}.times are with subtracted MRI OFFSET 
  mriTime = evt.obs{iObsp}.origtimes.mri;	% Saved MRI Events in mseconds
  mriTime = mriTime * par.evt.tfactor;		% time correction
  
  mriIndx = round(mriTime / DX_CORRECTED);  % MRI Events in adf points.

  SS_OFFS(iObsp) = mriIndx(1);

  % If 'int', we should be able to load a whole period of GRAD_CHAN.
  % 1000ms/0.048ms*60sec*60min*2byte/1024/1024 = 143MBytes/60min/channel
  GradADFData = adf_read(adffile,iObsp-1,GRAD_CHAN-1,[],[],'int');

  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % COMPUTE BASELINE STATISTICS
  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if iObsp == 1,
    GradStartT = mriTime(1);

    if GradStartT <= 1 && nmri_recorded <= nmri_expected,
      % The state system has probably started after start of ParaVision.
      fprintf('\n %s WARNING: %s ExpNo=%d',mfilename,Ses.name,ExpNo);
      fprintf(' GradStartT = %d\n',GradStartT);
      fprintf(' State system may started after the first MRI event.\n');
      figure('Name',sprintf('%s: %s ExpNo=%d',mfilename,Ses.name,ExpNo));
      plot((0:1000-1)*DX_CORRECTED*1000, GradADFData(1:1000));
      grid on; xlabel('Time (msec)');  ylabel('ADC');
      set(gca,'xlim',[-5 1000*DX_CORRECTED*1000]);
      hold on;  line([GradStartT GradStartT]*1000, get(gca,'ylim'),'color','r');
      c = input(' Continue processing? Y/N/K[N]: ','s');
      if isempty(c), c = 'N';  end
      switch lower(c),
       case {'n'}
        return;
       case {'k'}
        keyboard
      end
      
      if nmri_recorded == nmri_expected,  GradStartT = DX_CORRECTED;  end
    end
    

    % In old data, there is a DC offset before the 1st gradient came.
    [mBase, sBase, THR] = subGetBaseline(GradADFData(round(GradStartT/DX_CORRECTED):end), NoSTD);


    IPRE  = round(5/DX_CORRECTED);	% 5ms as pre-period of slice-selection
    %min(diff(mriIndx))
    %max(diff(mriIndx))
    PATTERN_LEN = round(min(diff(mriIndx))*0.97) + IPRE;
    TWIN = [1:PATTERN_LEN] - IPRE;
    for N = 1:length(pv.gradtype),
      tmptitle = sprintf('%s: %s Exp=%d, grad=%d\n',mfilename,Ses.name,ExpNo,N);
      
      % 15.09.11 YM: if not enough pre-period, then use the next repeat of this gradient.
      tmpt0  = mriIndx(N);
      tmplen = mriIndx(N+1) - mriIndx(N);
      if tmpt0 - tmplen*0.2 < 1,
        tmpt0  = mriIndx(N+length(pv.gradtype));
        tmplen = mriIndx(N+length(pv.gradtype)+1) - mriIndx(N+length(pv.gradtype));
      end
      
      T_SS = subFindSliceSelection(GradADFData,tmpt0,tmplen,...
                                   adfDX, mBase, THR, SustainedPnts,...
                                   INTERACTIVE, tmptitle);
      if INTERACTIVE && T_SS <= 0,
        % aborted by the user
        return;
      end
      if T_SS <= 0,
        fprintf('\n %s WARNING: failed to detect slice-selection timing.',mfilename);
        T_SS = subFindSliceSelection(GradADFData,tmpt0,tmplen,...
                                     adfDX, mBase, THR, SustainedPnts,...
                                     1, tmptitle);
      end
      T_SS = round(T_SS);
      if T_SS + TWIN(1) <= 0,  T_SS = -TWIN(1) + 1;  end
      GradTemplate(:,N) = GradADFData(TWIN + T_SS);
    end
    GradTemplate = double(GradTemplate);  % convert to "double" for xcorr().
    
    clear tmplate;
    if DEBUG,
      tmptitle = sprintf('%s: %s Exp=%d, grad template\n',mfilename,Ses.name,ExpNo);
      figure('Name',tmptitle);
      plot(TWIN,GradTemplate);
      hold on; grid on;
      ylm = get(gca,'ylim');
      line([0,0],ylm,'color','r');
      text(0,max(ylm)/2,'SLICE-SELECTION',...
           'horizontalalignment','center','fontweight','bold');
      % baseline, threshold
      xlm = get(gca,'xlim');
      line(xlm,[mBase,mBase],'color','k');
      text(min(xlm),mBase,'mBase','fontweight','bold',...
           'verticalalignment','bottom');
      line(xlm,[mBase-THR mBase-THR],'color',[0.9 0.5 0.5]);
      text(min(xlm), mBase-THR,'mBase-THR','fontweight','bold',...
           'verticalalignment','top');
      line(xlm,[mBase+THR mBase+THR],'color',[0.9 0.5 0.5]);
      text(min(xlm), mBase+THR,'mBase+THR','fontweight','bold',...
           'verticalalignment','top');
      % text
      xlabel(sprintf('Time in points (%.3fms/points)',adfDX));
      ylabel('ADC Units');
      title(sprintf('GRAD.Template, NumDiffGrad=%d',size(GradTemplate,2)));
    end
  end

  % ENHANCE CONTRASTS TO DETECT CORRECT TIMING.
  tmpmax = max(GradTemplate(:));
  GradADFData(GradADFData < -tmpmax*0.8) = -tmpmax;
  GradTemplate(GradTemplate < -tmpmax*0.8) = -tmpmax;
  
  NLAGS = round(length(TWIN) / 2);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % IN OLD DATA SET, THE LAST GRADIENT EVENTS IS NOT RECORDED FULLY...
  % SO WE HAVE TO INGORE THE LAST ONE.
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if max(TWIN + mriIndx(end)) > length(GradADFData),
    fprintf(' the last event is ignored...');
    mriIndx = mriIndx(1:end-1);
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  T_SS = zeros(1,length(mriIndx));
  try
  for N = 1:length(mriIndx),
    grad = mod(N-1,length(pv.gradtype)) + 1;
    tmpsel = TWIN + mriIndx(N);
    if tmpsel(1) < 1,
      dat = zeros(length(TWIN),1);
      dat(tmpsel > 0) = double(GradADFData(tmpsel(tmpsel > 0)));
    else
      dat = double(GradADFData(tmpsel)); % convert to "double" for xcorr().
    end
    [C,lags] = xcorr(GradTemplate(:,grad),dat,NLAGS,'unbiased');
    [maxv, maxi] = max(C);
    T_SS(N) = mriIndx(N) - lags(maxi);
    if IS_MICROSTIM && abs(T_SS(N)-mriIndx(N)) > 30,
      fprintf('x');
      % likely distorted by artifact like microstimulation,
      % try to remove outliers
      tmppat = GradTemplate(:,grad);
      idx = find(dat > 1.5*max(tmppat));
      dat(idx) = tmppat(idx);
      [C,lags] = xcorr(tmppat,dat,NLAGS,'unbiased');
      [maxv, maxi] = max(C);
      T_SS(N) = mriIndx(N) - lags(maxi);
    end
  end
  catch
    lasterr
    keyboard
  end

  SS_PNTS = cat(2,SS_PNTS,T_SS(:)');
  SS_OBSP = cat(2,SS_OBSP,ones(1,length(T_SS))*iObsp);
  
  if DEBUG,
    figure('Name',sprintf('%s: %s ExpNo=%d, xcorr',mfilename,Ses.name,ExpNo));
    plot(T_SS(:) - mriIndx(:),'marker','.','linestyle','none');  grid on;
    xlabel('MRI events');
    ylabel(sprintf('max lag in points (%.3fms/point)',adfDX));
    set(gca,'xlim',[0 length(T_SS)]);
    
    subPlotAlignedData(Ses.name,ExpNo,GradADFData,T_SS,TWIN,adfDX,pv.gradtype);
  end

end



% ======================================================================
% SAVE RECORDING INFO HERE (TO BE USED BY CLNADF)
% ======================================================================
SCT.version	 = CLNADJEVT_VERSION;		% version of clnadjust
SCT.date     = datestr(now);			% date string like '24-May-2005 15:13:42'
SCT.ExpNo	 = ExpNo;					% Experiment number
SCT.adffile  = adffile;					% name of adffile
SCT.NoObsp	 = NoObsp;					% Observation number (usually=1)
SCT.dx		 = adfDX/1000;				% in seconds
SCT.obslen   = adfObslen;				% Obs Period Length, in points
SCT.GradChan = GRAD_CHAN;				% the channel used to detect timings

SCT.NoVol    = pv.nt;					% Number of volumes/time-points
SCT.NoGrad   = length(pv.gradtype);		% e.g 4 for "1-1-2-2"
SCT.dstime   = pv.dstime;				% Dummy scan time
SCT.gradtype = pv.gradtype;				% e.g 1-1-2-2
% gradtype: [1 1 2 2]
% nt = 440
% SCT.grd = [1 1 2 2 1 1 2 2 ......], size=4*440
SCT.grd		 = repmat(pv.gradtype(:),pv.nt,1)';	% Full gradient pattern



% NEW DATA FIELDS
SCT.SS_PNTS  = SS_PNTS;					% Timing of slice selection in points
SCT.SS_OBSP  = SS_OBSP;					% Obsp for T_SS.
SCT.SS_OFFS  = SS_OFFS;                 % The first MR trigger in points 


% ======================================================================
% for compatibility
% ======================================================================
if SUPPORT_OLDFORMAT > 0,
  SCT.uniqtype   = SCT.gradtype;
  SCT.uniqlen    = [];
  SCT.uniqdur    = [];
  for iObsp = 1:NoObsp,
    SCT.mri{iObsp} = SS_PNTS(SS_OBSP == iObsp) * SCT.dx;
  end
  graddt = diff(SS_PNTS);
  for N = 1:length(SCT.gradtype),
    idx = N:length(SCT.gradtype):length(graddt);
    
    % USE min(); it's than max(). The latter sometimes includes the next pattern of
    % interference, as the duration of each slice+segment is slightly (by 1-2 ms)
    % different from volume to volume!!
    SCT.uniqlen(N) = min(graddt(idx));
    %SCT.uniqlen(N) = max(graddt(idx));
    SCT.uniqdur(N) = SCT.uniqlen(N)*SCT.dx;
    if DEBUG,
      fprintf('\n N=%02d: %.5f %.5f,  %.5f+-%.5fms',N,...
              min(graddt(idx))*SCT.dx, max(graddt(idx))*SCT.dx,...
              mean(graddt(idx))*SCT.dx, subSTD(graddt(idx))*SCT.dx);
      figure; plot(graddt(idx));
    end
  end
  SCT.NoUniq = length(SCT.uniqlen);

  SCT.Seg{1}.beg = 1;
  SCT.Seg{1}.end = length(SS_PNTS);
end





if nargout == 0,
  if sesversion(Ses) >= 2,
    sigsave(Ses,ExpNo,'clnadj',SCT,'verbose',0);
  else
    VAR = sprintf('exp%03d',ExpNo);
    eval(sprintf('%s = SCT;', VAR));
    savefile = fullfile(pwd,'ClnAdjEvt.mat');
    if ~exist(savefile,'file'),
      save(savefile,VAR);
    else
      save(savefile,'-append',VAR);
    end;
  end
else
  varargout{1} = SCT;
end
  

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute statistics during baseline period
function [mBase, sBase, THR] = subGetBaseline(GradADF,NoSTD)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if 0,
  m = mean(GradADF);
  s = std(GradADF);    % for integer, Matlab's std() crashes or returns wrong value...
  edges = -8*s:s*2:8*s;
  n = histc(GradADF,edges);
  [v,imax] = max(n);
  baseIDX = find(GradADF > edges(imax) & GradADF < edges(imax+1) & diff([GradADF 0]) < s*0.5);
else
  tmpmax = min(abs([max(GradADF) min(GradADF)])) * 0.25;
  tmpstep = tmpmax/10;
  edges = -tmpmax:tmpstep:tmpmax;
  n = histc(GradADF,double(edges));
  [v,imax] = max(n);
  while imax == 1,
    tmpmax = tmpmax * 1.2;
    tmpstep = tmpmax/10;
    edges = -tmpmax:tmpstep:tmpmax;
    n = histc(GradADF,double(edges));
    [v,imax] = max(n);
  end
  %baseIDX = find(GradADF > edges(imax-1)+tmpstep/2 & GradADF < edges(imax+1)-tmpstep/2 & diff([GradADF 0]) < tmpstep);
  baseIDX = find(GradADF > edges(imax-1)+tmpstep/2 & GradADF < edges(imax+1)-tmpstep/2 & diff([GradADF 0]) < tmpstep);
end


mBase = mean(GradADF(baseIDX));
sBase = subSTD(GradADF(baseIDX));
THR   = NoSTD * sBase;

if 0,
  figure('Name','baseline statistics');
  set(gcf,'DefaultAxesfontweight','bold');
  set(gcf,'DefaultAxesFontName', 'Comic Sans MS');
  plot(GradADF,'color','b');
  tmpsel = GradADF;  tmpsel(:) = NaN;  tmpsel(baseIDX) = GradADF(baseIDX);
  hold on; grid on;
  plot(tmpsel,'color','r');
  line(get(gca,'xlim'),[mBase mBase],'color','r');
  line(get(gca,'xlim'),[mBase-sBase mBase-sBase],'color','y');
  line(get(gca,'xlim'),[mBase+sBase mBase+sBase],'color','y');
  line(get(gca,'xlim'),[mBase-THR mBase-THR],'color','k');
  line(get(gca,'xlim'),[mBase+THR mBase+THR],'color','k');
  set(gca,'xlim',[0 10000]);
  xlabel('Time in points from the 1st MRI event');
  ylabel('ADC Units');
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function T_SS = subFindSliceSelection(GradADF, T0, LEN, DX, mBase, THR, SustainedPnts, INTERACTIVE,FIG_TITLE)

MARGIN_PTS = round(LEN * 0.2);

if T0 - MARGIN_PTS < 0,
  %PRE_MARGIN = 0;
  PRE_MARGIN = T0 - 1;
else
  PRE_MARGIN = MARGIN_PTS;
end
POST_MARGIN = MARGIN_PTS;

T_PTS = (-PRE_MARGIN:LEN+POST_MARGIN) + T0;
dat = GradADF(T_PTS);

% find baseline period
IDX  = find(dat > mBase - THR & dat < mBase + THR);
didx = diff(IDX);
T_BL = 0;  N = 1;
while N <= length(didx) - SustainedPnts,
  if all(didx(N:N+SustainedPnts) == 1),
    T_BL = IDX(N);
    break;
  end
  N = N + 1;
end

% find slice-selection timing
% 16.05.06 YM: include positive start also for spin-echo.
IDX = find(dat - mBase < -THR | dat - mBase > THR);
%IDX = find(dat - mBase < -THR);
IDX = IDX(IDX >= T_BL);
didx = diff(IDX);
ssidx = 0;  N = 1;
while N <= length(didx) - SustainedPnts,
  if all(didx(N:N+SustainedPnts) == 1),
    try
      m = mean(dat((-SustainedPnts:-1)+IDX(N)));
    catch
      keyboard
    end
    if m > mBase - THR && m < mBase + THR,
      ssidx = IDX(N);
      break;
    end
  end
  N = N + 1;
end

T_SS = ssidx + min(T_PTS) - 1;


if INTERACTIVE == 0,  return;  end

figure('Name',FIG_TITLE);
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName', 'Comic Sans MS');
% plot a waveform
plot(T_PTS,dat,'color','b');
hold on;  grid on;
% slice-selection
ylm = get(gca,'ylim');
h_ss = line([T_SS T_SS],ylm, 'color','r');
text(T_SS,max(ylm)/2,'SLICE-SELECTION',...
     'horizontalalignment','center','fontweight','bold');
% baseline, threshold
xlm = get(gca,'xlim');
line(xlm,[mBase,mBase],'color','k');
text(min(xlm),mBase,'mBase','fontweight','bold',...
     'verticalalignment','bottom');
line(xlm,[mBase-THR mBase-THR],'color',[0.9 0.5 0.5]);
text(min(xlm), mBase-THR,'mBase-THR','fontweight','bold',...
     'verticalalignment','top');
line(xlm,[mBase+THR mBase+THR],'color',[0.9 0.5 0.5]);
text(min(xlm), mBase+THR,'mBase+THR','fontweight','bold',...
     'verticalalignment','top');
% text
xlabel(sprintf('Time in points (%.3fms/points)',DX));
ylabel('ADC Units');
title(strrep(FIG_TITLE,'_','\_'));

while 1,
  if ~yesorno('Is the result acceptable? [if not define "slice-selection" point again]'),
    user_ss = ginput(1);
    T_SS = round(user_ss(1));
    set(h_ss,'xdata',[T_SS T_SS]);
  else
    break;
  end
end
  

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function subPlotAlignedData(SesName,ExpNo,GradADFData,T_SS,TWIN,DX,gradtype)

NumFig = ceil(length(gradtype)/16);
if NumFig == 1,
  if length(gradtype) <= 4,
    ncol = 1;  nrow = length(gradtype);
  else
    ncol = ceil(length(gradtype)/4);  nrow = 4;
  end
else
  nrow = 4;  ncol = 4;
end

t_skip = 5;
TWIN = TWIN(1:t_skip:end);

GRAD = 1;

for iFig = 1:NumFig,
  tmptitle = sprintf('%s: %s Exp=%d\n',mfilename,SesName,ExpNo);
  figure('Name',tmptitle);
  set(gcf,'DefaultAxesfontweight','bold');
  set(gcf,'DefaultAxesFontName', 'Comic Sans MS');

  for N = 1:nrow*ncol,
    if GRAD > length(gradtype),  break;  end
    
    tmpidx = GRAD:length(gradtype):length(T_SS);
    tmpadf = zeros(length(TWIN),length(tmpidx));
    for K = 1:length(tmpidx),
      if TWIN(1)+T_SS(tmpidx(K)) < 1,
        tmpsel = TWIN + T_SS(tmpidx(K));
        tmpadf(tmpsel > 0, K) = GradADFData(tmpsel(tmpsel > 0));
      else
        tmpadf(:,K) = GradADFData(TWIN + T_SS(tmpidx(K)));
      end
    end
    
    subplot(nrow,ncol,N);
    plot(TWIN,tmpadf);
    hold on;  grid on;
    ylm = get(gca,'ylim');
    line([0,0],ylm,'color','r');
    text(0,max(ylm)/2,'SLICE-SELECTION',...
         'horizontalalignment','center','fontweight','bold');
    % text
    xlabel(sprintf('Time in points (%.3fms/points)',DX));
    ylabel('ADC Units');
    title(sprintf('GRAD[%d] SEG=%d, N=%d',GRAD,gradtype(GRAD),length(tmpidx)));

    set(gca,'xlim',[min(TWIN),max(TWIN)]);
    
    GRAD = GRAD + 1;
  end
end

  

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function y = subSTD(x)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isinteger(x),  y = std(x);  return;  end

if isinteger(x),   y = double(std(single(x))); return;  end


% following may cause overflow due to x.^2 of integer...

% sum((x-m)^2)/(n-1)
%   = sum((x-m)^2)/n * n/(n-1)
%   = (sum(x^2)/n - m^2) * n/(n-1)

n = length(x);
m = mean(x);
%if n*2 > 500e+6
%  % do one by one to avoid memory problem...
%  v = 0;
%  for K = 1:n,
%    v = v + x(K)*x(K);
%  end
%  v = (v/n - m*m) * n/(n-1);
%else
  v = (sum(x.^2)/n - m*m) * n/(n-1);
%end
y = sqrt(v);


return
