function spc = sigwelch(Sig,ANAP)
%SIGWELCH - Compute PSD of the signal using the Welch method
% SIGWELCH(Sig) uses Matlab's pwelch function to computer power spectral
% density of the neural signals.
% NKL, 31 May 2008

DEBUG = 0;

if nargin < 2,
  ANAP.initdrop   = 1;        % Drop the first 10 seconds
  ANAP.epoch      = [];       % Analyze all data (real spont activity)
  ANAP.lastdrop   = 1;        % Drop last x seconds
  ANAP.cutoff     = 2;        % High pass filter with this cutoff
  ANAP.timewindow = 10;        % Time window for pwelch function
  ANAP.overlap    = 0.2;      % 20% window shifts
end;

Ses = Sig.session;

if strcmp(Sig.session,'b07nb1'),
  Sig.dx = Sig.dxorg;
end;

% IT SEEMS THAT MOST SESSIONS SUFFER FROM THIS SMALL TIME-DIFFERENCE??
if isfield(Sig,'dxorg'),
  Sig.dx = Sig.dxorg;
end;

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

if DEBUG,
  fprintf('%s,%s(%d) TWIN = %4.2f\n', spc.session,spc.grpname,spc.ExpNo,spc.twin);
  return;
end;

% do ANAP.cutoff high-pass to match with our sessions
if ANAP.cutoff,
  [b a] = butter(2,ANAP.cutoff/(1.0/Sig.dx/2),'high');
end;

DAT = []; SPC = []; F = [];
for O=1:size(Sig.dat,3),
  for iCh = 1:size(Sig.dat,2),
    if ANAP.cutoff,
      Sig.dat(:,iCh,O) = filtfilt(b,a,Sig.dat(:,iCh,O));
    end;
    [Pxx F] = pwelch(Sig.dat(:,iCh,O),NFFT,ANAP.overlap,NFFT,1.0/Sig.dx);
    DAT = cat(2,DAT,Pxx(:));
  end
end;

spc.freq    = F;
spc.dat     = DAT;
spc.raw     = DAT;
spc.blp     = subGetBands(spc);

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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  bamp = subGetBands(spc)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
range = getbandinfo(spc.session);

for N=1:length(range),
  tmpband = range{N};
  freq = find(spc.freq>=tmpband(1) & spc.freq<tmpband(2));
  for K=1:size(spc.dat,2),
    bamp(N,K) = nanmean(spc.dat(freq,K));
  end;
end;
return;
