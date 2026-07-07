function spc = blpsigwelch(SesName,ExpNo,ANAP)
%BLPSIGWELCH - Compute PSD of the MRI signal using the Welch method
% BLPSIGWELCH(Sig) uses Matlab's pwelch function to computer power spectral
% density of the neural signals.
% NKL, 31 May 2008

if nargin < 3,
  ANAP.roiname    = 'brain';      % ROI is the electrode-region
  ANAP.roiname    = 'ele';      % ROI is the electrode-region
  ANAP.initdrop   = 1;            % Drop the first 10 seconds
  ANAP.epoch      = [];           % Analyze all data (real spont activity)
  ANAP.lastdrop   = 1;            % Drop last x seconds
  ANAP.cutoff     = 2;            % High pass filter with this cutoff
  ANAP.timewindow = 50;           % Time window for pwelch function
  ANAP.overlap    = 0.25;         % Overlap of windows for PSD calculation
  ANAP.lags       = 30;           % Number lags for HRF calculation
  ANAP.fltord     = 4;            % Order of filter for autoregressive... (cra)
  ANAP.funtype    = 'xcov(coef)'; % Function to use for HRF computation
end;

if nargin < 2,
  help blpsigwelch;
  return;
end;

Ses = goto(SesName);
Sig = sigload(SesName,ExpNo,'blp');
Sig = sigresample(Sig,1);

ExpNo = Sig.ExpNo;
% Empty = entire obsp; other possibilities: prestim, stim, blank, etc.
if ~isempty(ANAP.epoch),
  fprintf('e.');
  idx = getStimIndices(Sig,ANAP.epoch);
  Sig.dat = Sig.dat(idx,:,:);
end;

% Check if we need to discard the first X seconds...
if ANAP.initdrop,
  fprintf('id.');
  ANAP.initdrop = round(ANAP.initdrop/Sig.dx);
  if size(Sig.dat,1) > ANAP.initdrop,
    Sig.dat = Sig.dat(ANAP.initdrop+1:end,:,:);
  end;
end;

if ANAP.lastdrop,
  fprintf('ld.');
  ANAP.lastdrop = round(ANAP.lastdrop/Sig.dx);
  if size(Sig.dat,1) > ANAP.lastdrop,
    Sig.dat = Sig.dat(1:end-ANAP.lastdrop,:,:);
  end;
end;

fprintf('L=%d',size(Sig.dat,1));

NFFT = 2^nextpow2(ANAP.timewindow/Sig.dx);
ANAP.overlap = round(NFFT*ANAP.overlap);

spc.session = Sig.session;
spc.grpname = Sig.grpname;
spc.ExpNo   = Sig.ExpNo;
spc.anap    = ANAP;
spc.twin    = size(Sig.dat,1)*Sig.dx;

DAT = []; SPC = []; F = [];
for O=1:size(Sig.dat,3),
  for iCh = 1:size(Sig.dat,2),
    [Pxx F] = pwelch(Sig.dat(:,iCh,O),NFFT,ANAP.overlap,NFFT,1.0/Sig.dx);
    DAT = cat(2,DAT,Pxx(:));
  end
end;

spc.freq    = F;
spc.dat     = DAT;
spc.raw     = DAT;

if ~nargout,
  subPlotSpc(spc);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subPlotSpc(spc)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CIVAL = [1 99];
BSTRP = 200;

subplot(2,1,1);
if size(spc.dat,2) > 2,
  Boot = bootstrp(BSTRP,@hnanmean,spc.dat');
  Cinter = prctile(Boot,CIVAL); % the 1 and 99% intervals
  h = ciplot(Cinter(1,:),Cinter(2,:),spc.freq,[.8 .8 .8]);
  setback(h);
  hold on;
end;

m = nanmean(spc.dat,2);
plot(spc.freq, m, 'color', 'k', 'linewidth', 2);
set(gca,'xlim',[0 140],'xtick',[0:10:140]);
xlabel('Frequency in Hz');
ylabel('Power');
grid on;

subplot(2,1,2);
y = spc.blp;
NB = length(y);
x = [1:NB];
bar(x, y, 'k');
hold on

[range,bnames] = getbandinfo(spc.session);
for N=1:length(bnames),
  text(N, 3, bnames{N},'fontsize',9,'rotation',90,'color','r','fontweight','bold');
end;
hold off;
set(gca,'xlim', [0 NB+1]);;
set(gca,'xtick',[0:NB+1]);
xlabel('BLP Band');
ylabel('Percent singal increase');
return;


