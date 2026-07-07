function oSig = expdeltagamma(Ses,ExpNo,varargin)
%EXPDELTAGAMMA -
%  SIG = EXPDELTAGAMMA(SESSION,ExpNo,...) computes relationship between 
%  delta-phase and gamma-amplitude (K.Whittingstall).
%
%
%  Supported options are :
%    'delta'     : delta range in Hz
%    'gamma'     : gamma range in Hz
%    'Resample'  : resampling in Hz
%    'twin'      : time window in seconds
%    'nphases'   : numbers of bins for phase
%    'threshold' : threshold for gamma amplitude in SDU
%    'plot'      : 0/1, do plot the result or not
%
%  VERSION :
%    0.90 03.12.09 YM  pre-release
%
%  See also sigresample sigfiltfilt

if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end


% options
DELTA_HZ    = [  2    4];
GAMMA_HZ    = [ 30  100];
%GAMMA_HZ    = [400 3000];
RESAMPLE_HZ = 500;
WINDOW_SEC  = 4;
SHIFT_SEC   = [];
PHASE_BINS  = 10;
GAMMA_THR   = 1.0;
DO_PLOT     = 1;
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'delta','delta_hz','deltahz'}
    DELTA_HZ = varargin{N+1};
   case {'gamma','gamma_hz','gammahz'}
    GAMMA_HZ = varargin{N+1};
   case {'resample','resamplehz','resamle_hz'}
    RESAMPLE_HZ = varargin{N+1};
   case {'twin','twin_sec','twindow','window_sec'}
    WINDOW_SEC = varargin{N+1};
   case {'shift','shift_sec','shiftsec','tshift','tshift_sec'}
    SHIFT_SEC = varargin{N+1};
   case {'nbin','nbins','nphase','nphases'}
    PHASE_BINS = varargin{N+1};
   case {'threshold','gammathr','gamma_thr','thr'}
    GAMMA_THR = varargin{N+1};
   case {'plot','do_plot','doplot'}
    DO_PLOT = varargin{N+1};
  end
end

if ~any(SHIFT_SEC),  SHIFT_SEC = WINDOW_SEC;  end


Ses = goto(Ses);
fprintf(' %s: %s exp% 3d',mfilename,Ses.name,ExpNo);

fprintf(' Delta/Gamma=%g-%g/%g-%gHz TWIN/dT=%g/%gs THR=%gsdu:',...
        DELTA_HZ(1),DELTA_HZ(2),GAMMA_HZ(1),GAMMA_HZ(2),...
        WINDOW_SEC,SHIFT_SEC,GAMMA_THR);


fprintf(' Cln.');
Cln = sigload(Ses,ExpNo,'Cln');



% downsample first
newdx = 1/RESAMPLE_HZ;
newdx = Cln.dx*round(newdx/Cln.dx);

if any(GAMMA_HZ > 1/newdx/2),
  DO_GAMMA_FIRST = 1;
  fprintf(' gamma.');
  GAMMA = sigfiltfilt(Cln,GAMMA_HZ,'bandpass');
else
  DO_GAMMA_FIRST = 0;
end


fprintf(' resample(%gHz).',1/newdx);
Cln = sigresample(Cln,newdx);


% band pass filtering
fprintf(' delta.');
DELTA = sigfiltfilt(Cln,DELTA_HZ,'bandpass');
if DO_GAMMA_FIRST,
  GAMMA = sigresample(GAMMA,Cln.dx);
else
  fprintf(' gamma.');
  GAMMA = sigfiltfilt(Cln,GAMMA_HZ,'bandpass');
end

NCh = size(Cln.dat,2);
% save memory, no need of Cln.dat
Cln.dat = [];

tsel  = 1:round(WINDOW_SEC/Cln.dx);
tshift = length(tsel);
tshift = round(SHIFT_SEC/Cln.dx);
ntwin = floor((size(DELTA.dat,1)-length(tsel)+tshift)/tshift);


EDGES = [0:360/PHASE_BINS:360]/360*2*pi;


DAT = zeros(ntwin,length(EDGES)-1,NCh);



fprintf(' processing(nch=%d)',NCh);
for iCh = 1:NCh,
  fprintf('.');
  % delta=phase, gamma=amplitude
  tmpdelta = angle(hilbert(DELTA.dat(:,iCh)));
  tmpgamma =   abs(hilbert(GAMMA.dat(:,iCh)));
  
  % -pi/+pi --> 0/2pi
  tmpidx = find(tmpdelta < 0);
  tmpdelta(tmpidx) = tmpdelta(tmpidx) + 2*pi;
  
  %tmpgamma = zscore(tmpgamma);
  
  toffs = 0;
  for N = 1:ntwin,
    tmpsel = tsel + toffs;
    tmpphs = tmpdelta(tmpsel);
    tmpamp = tmpgamma(tmpsel);
    
    tmpamp = zscore(tmpamp);
    for K = 1:length(EDGES)-1,
      tmpidx = find(tmpphs >= EDGES(K) & tmpphs < EDGES(K+1) & tmpamp > GAMMA_THR);
      %tmpidx = find(tmpphs >= EDGES(K) & tmpphs < EDGES(K+1));
      DAT(N,K,iCh) = nanmean(tmpamp(tmpidx));
    end
    toffs = toffs + tshift;
  end
end
DAT(find(isnan(DAT(:)))) = 0;

oSig.session = Cln.session;
oSig.grpname = Cln.grpname;
oSig.ExpNo   = Cln.ExpNo;
oSig.dat     = DAT;
oSig.dx      = tshift*Cln.dx;
oSig.edges   = EDGES;
oSig.phase   = (EDGES(1:end-1)+EDGES(2:end))/2;
oSig.(mfilename).delta_hz  = DELTA_HZ;
oSig.(mfilename).gamma_hz  = GAMMA_HZ;
oSig.(mfilename).resample  = RESAMPLE_HZ;
oSig.(mfilename).twin_sec  = WINDOW_SEC;
oSig.(mfilename).tshift    = SHIFT_SEC;
oSig.(mfilename).gamma_thr = GAMMA_THR;

fprintf(' done.\n');


if DO_PLOT,
  sub_plot(oSig);
end


return



function sub_plot(Sig)

DELTA_HZ = Sig.(mfilename).delta_hz;
GAMMA_HZ = Sig.(mfilename).gamma_hz;


figure('Name',sprintf('%s: %s ExpNo=%d',mfilename,Sig.session,Sig.ExpNo));
NCh = size(Sig.dat,3);
tmpt = [0:size(Sig.dat,1)-1]*Sig.dx;
tmpp = Sig.phase;
tmptxt = sprintf('%s ExpNo=%d Gamma=%g-%gHz',Sig.session,Sig.ExpNo,GAMMA_HZ(1),GAMMA_HZ(2));
for iCh = 1:NCh,
  subplot(NCh,1,iCh);
  tmpdat = squeeze(Sig.dat(:,:,iCh));
  imagesc(tmpt,tmpp,tmpdat');
  set(gca,'xlim',[tmpt(1) tmpt(end)],'ylim',[tmpp(1) tmpp(end)]);
  set(gca,'ydir','reverse');
  grid on;
  set(gca,'fontsize',8);
  title(sprintf('%s Ch=%d',tmptxt,iCh));
  set(gca,'clim',[0 3]);
  
  if iCh == NCh,
    xlabel('Time in seconds');
    ylabel(sprintf('Delta %g-%gHz Phase',DELTA_HZ(1),DELTA_HZ(2)));
  end
  
  
  pos = get(gca,'pos');
  pos(3) = pos(3)*0.75;
  set(gca,'pos',pos);
  
  % plot the average
  pos(1) = pos(1)+pos(3)+0.02;  pos(3) = 0.18;
  axes('pos',pos);

  tmpm = nanmean(tmpdat,1);
  tmps = nanstd(tmpdat,[],1)/sqrt(size(tmpdat,1));
  plot(tmpm,tmpp,'linewidth',2);
  hold on;
  plot(tmpm+tmps,tmpp,'linestyle',':');
  plot(tmpm-tmps,tmpp,'linestyle',':');
  grid on;
  set(gca,'ylim',[tmpp(1) tmpp(end)]);
  set(gca,'ydir','reverse');
  set(gca,'yticklabel',{});
  set(gca,'fontsize',8);

  if iCh == NCh,
    xlabel('Normalized Gamma Ampl.');
  end  
  
end

return
