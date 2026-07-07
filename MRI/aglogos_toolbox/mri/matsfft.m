function fftTs = matsfft(roiTs, cutoff, ARGS)
%MATSFFT - Filters respiratory artifacts
% MVITFFT(roiTs) filters respiratory artifacts by examining the
% power spectrum of the signal and scaling all frequencies
% accordingly. In specific, the 1 - abs(spectrum) is used as
% scaling function for the spectrum of the MRI signal. The signal
% is then reconstructed.
% NKL, 10.02.01

DEF.DOFLT           = 1;
DEF.DOPLOT          = 0;
DEF.IDETREND        = 1;
DEF.IDETRENDONLY    = 0;

if nargin < 2,
  cutoff = 0;
end;

if ~nargin,
  help matsfft;
  fftTs = {};
  return;
end;

if exist('ARGS','var'),
  ARGS = sctcat(ARGS,DEF);
else
  ARGS = DEF;
end;
pareval(ARGS);

if isstruct(roiTs),
  tmp = roiTs;
  clear roiTs;
  roiTs{1} = tmp;
end;

if IDETREND,
  for N=1:length(roiTs),
    roiTs{N}.dat = detrend(roiTs{N}.dat);
  end;
end;

if IDETRENDONLY,
  for N=1:length(roiTs),
    m = repmat(mean(roiTs{N}.dat,1),[size(roiTs{N}.dat,1) 1]);
    roiTs{N}.dat = detrend(roiTs{N}.dat) + m;
  end;
end;

fftTs = roiTs;

Fs = 1/roiTs{1}.dx;
nyq = Fs/2;
LEN = size(fftTs{1}.dat,1);
PADLEN = max(LEN,4096);
PADLEN = LEN;

for N=1:length(fftTs),
  NCOL = size(fftTs{N}.dat,2);
  fdat = fftshift(fft(fftTs{N}.dat,PADLEN,1));
  
  if DOFLT,
    len = size(fdat,1)/2;
    fabs = abs(fdat);
    lfr  = [0:Fs/(PADLEN-1):Fs] - Fs/2;
    fabs = mean(fabs,2);
    me = median(fabs);
    iq = iqr(fabs);
    ix = find(lfr>-0.37 & lfr<0.37);
    fabs(ix) = me+iq;
    fabs = fabs - me;
    fabs = 1 - fabs/max(fabs);
    fabs = fabs - min(fabs);
    fabs = fabs/max(fabs);
    fdat = fdat .* repmat(fabs,[1 NCOL]);
  end;
  
  fftTs{N}.dat = real(ifft(fftshift(fdat)));
end;

if cutoff,
  [b,a] = butter(6,cutoff/nyq,'low');
  for N=1:length(fftTs),
    NCOL = size(fftTs{N}.dat,2);
    tmp = filtfilt(b,a,fftTs{N}.dat(:));
    fftTs{N}.dat = reshape(tmp,size(roiTs{N}.dat));
  end;
end;

if DOPLOT,
  Fs = 1/roiTs{1}.dx;
  mfigure([10 100 1000 750]);
  msubplot(2,2,1);
  collage(roiTs{1}.ana);
  subplot(2,2,2);

  % CHANGE
  t = [0:size(roiTs{1}.dat,1)-1]' * roiTs{1}.dx;
  plot(t, mean(roiTs{1}.dat,2),'color',[.8 .8 .75],'linewidth',4);
  hold on;
  plot(t, mean(fftTs{1}.dat(1:LEN,:),2),'r','linewidth',2);
  set(gca,'xlim',[t(1) t(end)]);
  grid on;
  xlabel('Time in seconds');
  subplot(2,2,4);
  ARGS.SRATE = Fs;
  ARGS.COLOR = 'k';
  Sig.dx = roiTs{1}.dx;
  Sig.dir = roiTs{1}.dir;
  Sig.dat = roiTs{1}.dat;
  msigfft(Sig,ARGS);
  hold on;
  ARGS.COLOR = 'r';
  ARGS.STYLE = ':';
  Sig.dx = fftTs{1}.dx;
  Sig.dir = fftTs{1}.dir;
  Sig.dat = fftTs{1}.dat;
  msigfft(Sig,ARGS);
  set(gca,'xlim',[0 1]);
  xlabel('Frequency in Hz');
  grid on;
  txt = sprintf('mtcimgfft(Session: %s, Group: %s',...
                roiTs{1}.session,roiTs{1}.grpname);
  suptitle(txt,'r',12);
end;

