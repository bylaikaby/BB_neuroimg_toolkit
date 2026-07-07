% basics of filtering
%sampling interval
Ts=.001;
%sampling frequency
Fs=1/Ts;
%define time vector
t=0:Ts:6;
tg=1;

sg=.1;


%define original signal
t1=2;
t2=3;
f1=50;
f2=10;
s1=.1;
s2=.7;
sfilt=.1;
filt1=exp(-(t-t1).^2/sfilt).*cos(2*pi*f1*t);
filt2=exp(-(t-t2).^2/sfilt).*sin(2*pi*f2*t);
filt1=filt1./(sum(abs(filt1).^2));
filt2=filt2./(sum(abs(filt2).^2));
twocompsig=exp(-(t-t1).^2/s1).*cos(2*pi*f1*t)+exp(-(t-t2).^2/s2).*sin(2*pi*f2*t);
%plot(t,twocompsig);

figure(1)
plot(t,twocompsig);
title('original signal (one 10Hz, one 50Hz)')

wsize = round(2/Ts);
wsize = wsize + mod(wsize+1,2);  % make as odd

figure(2)
subplot(1,3,1)
[tf, freqs, times]          = timefreqMB(twocompsig', Fs,'cycles',5,'freqs',[5 100],'ntimesout',400);
imagesc(times/1000,freqs,abs(tf))
set(gca,'Ydir','normal')
title('low nb of cycles (5: poor frequency res)')
subplot(1,3,2)
[tf, freqs, times]          = timefreqMB(twocompsig', Fs,'cycles',10,'freqs',[5 100]);
imagesc(times/1000,freqs,abs(tf))
set(gca,'Ydir','normal')
title('"optimal" nb of cycles (10)')
subplot(1,3,3)
[tf, freqs, times]          = timefreqMB(twocompsig', Fs,'cycles',15,'freqs',[5 100]);
imagesc(times/1000,freqs,abs(tf))
set(gca,'Ydir','normal')
title('high nb of cycles (15: poor temporal res)')

%uncomment to see also windowed fft analysis
% 
% figure(3)
% subplot(1,3,1)
% [tf, freqs, times]          = timefreq(twocompsig', Fs,'cycles',0,'winsize',.1*Fs,'freqs',[5 100]);
% imagesc(times/1000,freqs,abs(tf))
% set(gca,'Ydir','normal')
% subplot(1,3,2)
% [tf, freqs, times]          = timefreq(twocompsig', Fs,'cycles',0,'winsize',.5*Fs,'freqs',[5 100]);
% imagesc(times/1000,freqs,abs(tf))
% set(gca,'Ydir','normal')
% subplot(1,3,3)
% [tf, freqs, times]          = timefreq(twocompsig', Fs,'cycles',0,'winsize',Fs,'freqs',[5 100]);
% imagesc(times/1000,freqs,abs(tf))
% set(gca,'Ydir','normal')
