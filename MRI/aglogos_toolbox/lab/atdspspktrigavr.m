function atdspspktrigavr(SIG)
%
%
%

if nargin == 0,  help atspktrigavr; return;  end


SpkChan = SIG.spkchan;
SigChan = SIG.sigchan;

LAGS = SIG.lags;
DAT = SIG.dat - SIG.shuffled.dat;

FREQ = SIG.f;
SPC = SIG.spc - SIG.shuffled.spc;


if length(SIG.ExpNo) == 1,
  tmptxt = sprintf('%s ExpNo=%d(%s): %s',SIG.session,SIG.ExpNo,SIG.grpname,SIG.dir.dname);
else
  tmptxt = sprintf('%s %s: %s',SIG.session,SIG.grpname,SIG.dir.dname);
end


% PLOT WAVEFORM
figure;
set(gcf,'Name',sprintf('%s  WAVEFORM',tmptxt));

for N = 1:length(SpkChan),
  subplot(4,2,N);
  plot(LAGS,squeeze(DAT(:,N,:)));
  grid on;
  set(gca,'ylim',[-0.2 0.2],'xlim',[-1.5 1.5]);
  text(0.1,0.85,sprintf('%7dspikes(%.2fHz)',round(SIG.nspk(N)),SIG.spkHz(N)),...
       'units','normalized');
  
  xlabel('Lags in seconds');
  ylabel('Amplitude in SDU');
end

% PLOT SPECTROGRAM
figure;
set(gcf,'Name',sprintf('%s  SPECTRUM',tmptxt));

for N = 1:length(SpkChan),
  subplot(4,2,N);
  plot(FREQ,squeeze(SPC(:,N,:)));
  grid on;
  set(gca,'ylim',[-10 80],'xlim',[0 50]);
  text(0.1,0.85,sprintf('%7dspikes(%.2fHz)',round(SIG.nspk(N)),SIG.spkHz(N)),...
       'units','normalized');
  
  xlabel('Freq in Hz');
  ylabel('Amplitude');
end
