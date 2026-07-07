function clnpsd(ses,ExpNo)


Cln = sigload(ses,ExpNo,'Cln');


Cln.dat = Cln.dat/32768*10;  % scale to +/-10


tmpt = [0:size(Cln.dat,1)-1]*Cln.dx;


Cln.dat(:,4) = sin(pi*2*1000*tmpt) * 10;




NFFT = round(0.25/Cln.dx);
NOVERLAP = round(NFFT*0.2);
Fs = 1.0/Cln.dx;

legtxt = {};
for N=size(Cln.dat,2):-1:1,
  %[Pxx f] = pwelch(Cln.dat(:,N),NFFT,NOVERLAP,NFFT,Fs);
  %CLNPSD(:,N) = Pxx(:);
  [S,f,T] = spectrogram(Cln.dat(:,N),NFFT,NOVERLAP,NFFT,Fs);
  S = mean(abs(S),2);
  CLNSPC(:,N) = S(:);
  legtxt{N} = sprintf('Ch%d',N);
end

figure;

plot(f,CLNSPC);
legend(legtxt);
set(gca,'xlim',[0 3500]);
set(gca,'yscale','log','ylim',[0.1 10000]);
xlabel('Frequency in Hz');
grid on;
title(sprintf('%s ExpNo=%d',Cln.session,Cln.ExpNo(1)));
