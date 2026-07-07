function dsppleth(Sig)
%DSPPLETH - Display the plethysmogram signal
% DSPPLETH(Sig) Display the plethysmogram signal in a single plot
% with no "figure" call.
% NKL 12.03.04

subplot(2,1,1);
t = [0:size(Sig.dat,1)-1] * Sig.dx;
plot(t,Sig.dat,'r');
set(gca,'xlim',[t(1) t(end)]);
xlabel('Time in seconds');
ylabel('Pleth Amplitude');

subplot(2,1,2);
[fftamp,fftfr] = sigfft(Sig);
plot(fftfr,fftamp,'k');
xlabel('Frequency in Hz');
ylabel('FFT-Amp');
set(gca,'xlim',[0 4]);

if 0,  
  fr = Sig{1}.pleth.fftfr;
  fr = fr(find(fr<4));

  for N=1:length(Sig),
    ms(N) = length(Sig{N}.pleth.dat);
  end;
  ms = min(ms);
  for N=1:length(Sig),
    s(:,N) = Sig{N}.pleth.dat(1:ms);
    f(:,N) = Sig{N}.pleth.fftamp(1:length(fr));
  end;
 
  expno = [1:length(Sig)];
  [x,y] = meshgrid(expno,fr);
  plot3(x,y,f);
  set(gca,'ydir','reverse');
end;  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [fabs,fr] = sigfft(Sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MAXFREQ = 4;
data = detrend(Sig.dat);
srate = 1/Sig.dx;
len = size(data,1);
len = 65536;
fdat = fft(data,len,1);
LEN = size(fdat,1)/2;
fabs = abs(fdat(1:LEN,:));
lfr = (srate/2) * [0:LEN-1]/(LEN-1);
fr = lfr(:);
idx = find(fr<MAXFREQ);
fr = fr(idx);
fabs = fabs(idx);
return;




