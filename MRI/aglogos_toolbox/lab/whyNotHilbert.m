%This file demonstrates both cases where the Hilbert transform is useful, 
%and cases where it is not.

%Arthur Gretton

%21/12/05

%22/12/05 added an AR demonstration for bandpass filtering a broad spectrum signal

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%First example: a classical AM signal. In this case, Hilbert transform
%is the correct answer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all
close all

NPTS = 5000;

tAxis = linspace(0,0.1,NPTS);
dt = tAxis(2)-tAxis(1);
nyq = 1/2/dt;
freqaxis = [-nyq:2*nyq/NPTS:nyq-nyq/NPTS];  %p. 77 Buck, Daniel, Singer

envFreq = 300;
carrFreq = 1000;

env = sin(2*pi*envFreq*tAxis) + 5;
carr = sin(2*pi*carrFreq*tAxis);

modSig = env.*carr; %amplitude modulated signal

freqPlotRange = [NPTS/2+1:NPTS/2+400];

subplot(2,2,1)
plot(tAxis(1:1000),modSig(1:1000),'r',tAxis(1:1000),env(1:1000))
title('Envelope signal and AM signal')
subplot(2,2,2)
a=abs(fftshift(fft(modSig)));
semilogy(freqaxis(freqPlotRange),a(freqPlotRange))
title('Spectrum of AM signal')
subplot(2,2,3)
reconstructedEnv = abs(hilbert(modSig));
plot(tAxis(1:1000),reconstructedEnv(1:1000),tAxis(1:1000),env(1:1000),'r')
title('Hilbert reconstruction vs original signal')
legend('Estimated envelope from Hilbert','Original signal')
subplot(2,2,4)
a=abs(fftshift(fft(reconstructedEnv)));
semilogy(freqaxis(freqPlotRange),a(freqPlotRange))
title('Spectrum of Hilbert reconstruction')


print('-depsc2','sineCorrectAM.eps');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%2nd example: an AM signal with an incorrect DC offset. In this case, Hilbert
%transform can be misleading.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

NPTS = 5000;

tAxis = linspace(0,0.1,NPTS);
dt = tAxis(2)-tAxis(1);
nyq = 1/2/dt;
freqaxis = [-nyq:2*nyq/NPTS:nyq-nyq/NPTS];  %p. 77 Buck, Daniel, Singer

envFreq = 300;
carrFreq = 1000;

env = sin(2*pi*envFreq*tAxis) + 0.5;
carr = sin(2*pi*carrFreq*tAxis);

modSig = env.*carr; %amplitude modulated signal

freqPlotRange = [NPTS/2+1:NPTS/2+400];

subplot(2,2,1)
plot(tAxis(1:1000),modSig(1:1000),'r',tAxis(1:1000),env(1:1000))
title('Envelope signal and AM signal')
subplot(2,2,2)
a=abs(fftshift(fft(modSig)));
semilogy(freqaxis(freqPlotRange),a(freqPlotRange))
title('Spectrum of AM signal')
subplot(2,2,3)
reconstructedEnv = abs(hilbert(modSig));
plot(tAxis(1:1000),reconstructedEnv(1:1000),tAxis(1:1000),env(1:1000),'r')
title('Hilbert reconstruction vs original signal')
legend('Estimated envelope from Hilbert','Original signal')
subplot(2,2,4)
a=abs(fftshift(fft(reconstructedEnv)));
semilogy(freqaxis(freqPlotRange),a(freqPlotRange))
title('Spectrum of Hilbert reconstruction')


print('-depsc2','sineClippingAM.eps');


figure

%Now do absolute value + lowpass

%hs=fdesign.lowpass(envFreq*1.4/nyq,envFreq*1.6/nyq,1,80);   %see help fdesign/lowpass
%h=cheby2(hs);
%[b,a] = sos2tf(h.sosMatrix);    %check the filter with fvtool(b,a)

hs=fdesign.lowpass(envFreq*1.1/nyq,envFreq*2.1/nyq,1,60);   %see help fdesign/lowpass
h=design(hs,'kaiserwin');   %equiripple is shortest, kaiserwin is faster to compute 
%see http://www.mathworks.com/products/filterdesign/demos.html?file=/products/demos/shipping/filterdesign/lpfirdemo.html
b=h.Numerator;
filtReconstructEnv = filtfilt(b,1,abs(modSig));
subplot(2,1,1)
plot(tAxis(1:1000),filtReconstructEnv(1:1000),tAxis(1:1000),env(1:1000),'r')
legend('reconstructed envelope','envelope')
a=abs(fftshift(fft(filtReconstructEnv)));
subplot(2,1,2)
semilogy(freqaxis(freqPlotRange),a(freqPlotRange))
title('Spectrum of Filter reconstruction')

print('-depsc2','sineClippingLpfAM.eps');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%3rd case: a broadband AR process, which is bandpass filtered. In this case, we
%are also mislead by Hilbert transform.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all
close all

NPTS = 10000;

tAxis = linspace(0,0.1,NPTS);
dt = tAxis(2)-tAxis(1);
nyq = 1/2/dt;
freqaxis = [-nyq:2*nyq/NPTS:nyq-nyq/NPTS];  %p. 77 Buck, Daniel, Singer

freqPlotRange = [NPTS/2+1:NPTS/2+400];


carrFreq = 2000;  %This is a "virtual" carrier frequency - it tells you where to bandpass filter
envFreq = 300;    %This is "virtual" envelope frequency for the passband width

%%%%%%%%%%%%%%%%%%%%%%%
%Generate the AR signal
%%%%%%%%%%%%%%%%%%%%%%%

numPolePairs=2;   %AR component has this many pole pairs
ARw0=[0.2 0.6 1.2];
ARpoleamp0=[0.8 0.7 0.6];
ARamp0 = ARcoeffGen(ARpoleamp0,ARw0);
P=length(ARamp0);
sigma2_e0 = 0.8;  %driving noise variance
ma=zeros(P,1);    %Mean : generative process for initial a_0
sigma2_a=1;       %Variance : generative process for initial a_0
a0=zeros(P+NPTS,1);                         
a0(1:P) = randn(P,1)*sqrt(sigma2_a) + ma;   %Generate initial amplitudes
for i=1:NPTS
  a0(i+P)= a0(i+P-1:-1:i)'*ARamp0 + sqrt(sigma2_e0)*randn;
end
y = a0(P+1:NPTS+P);

subplot(3,1,1)
plot(tAxis(1:1000),y(1:1000))
title('AR signal')
subplot(3,1,2)
a=abs(fftshift(fft(y)));
semilogy(freqaxis,a)
title('Spectrum of AR signal')

%Bandpass filter it
Fst1 = (carrFreq-envFreq)/nyq*0.8;
Fp1 = (carrFreq-envFreq)/nyq;
Fp2 = (carrFreq+envFreq)/nyq;
Fst2 = (carrFreq+envFreq)/nyq*1.2;
hs = fdesign.bandpass(Fst1,Fp1,Fp2,Fst2, 100, 1, 60);
h=design(hs,'kaiserwin');   
b=h.Numerator;
modSig = filtfilt(b,1,y);

subplot(3,1,3)
a=abs(fftshift(fft(modSig)));
semilogy(freqaxis,a)
title('Spectrum of bandpass signal')

print('-depsc2','ARandBandpass.eps');

%%%%%%%%%%%%%%%%%%%%%%%
%Hilbert transform it
%%%%%%%%%%%%%%%%%%%%%%%

figure



subplot(2,2,1)
reconstructedEnv = abs(hilbert(modSig));
plot(tAxis(2000:4700),reconstructedEnv(2000:4700),tAxis(2000:4700),modSig(2000:4700),'r')
title('Hilbert reconstruction vs original signal')
legend('Estimated envelope from Hilbert','Original signal')
subplot(2,2,2)
a=abs(fftshift(fft(reconstructedEnv)));
semilogy(freqaxis(freqPlotRange),a(freqPlotRange))
title('Spectrum of Hilbert reconstruction')




%%%%%%%%%%%%%%%%%%%%%%%
%Take abs/low pass filter approach
%%%%%%%%%%%%%%%%%%%%%%%



hs=fdesign.lowpass(envFreq*1.5/nyq,envFreq*2.1/nyq,1,60);   %see help fdesign/lowpass
h=design(hs,'kaiserwin');   %equiripple is shortest, kaiserwin is faster to compute 
%see http://www.mathworks.com/products/filterdesign/demos.html?file=/products/demos/shipping/filterdesign/lpfirdemo.html
b=h.Numerator;
filtReconstructEnv = filtfilt(b,1,abs(modSig));
subplot(2,2,3)
plot(tAxis(2000:4700),filtReconstructEnv(2000:4700),tAxis(2000:4700),modSig(2000:4700),'r')
title('Envelope obtained using abs and low pass filter')
a=abs(fftshift(fft(filtReconstructEnv)));
subplot(2,2,4)
semilogy(freqaxis(freqPlotRange),a(freqPlotRange))
title('Spectrum of abs and low pass filter reconstruction')






print('-depsc2','ARreconstructions.eps');
