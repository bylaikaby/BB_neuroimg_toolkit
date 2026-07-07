sigload('c98nm3',1,'blp')
dat = blp.dat;
mdat = squeeze(mean(dat,2));
dx = blp.dx;
T = [0:size(dat,1)-1]*blp.dx;
%plot(T,mdat(:,1))
%hmdat = hilbert(mdat);
%hold on;
%plot(T,abs(hmdat(:,1)),'r')
%grid on;
 
stmidx = getStimIndices(blp,'anystim');
mdat = mdat(stmidx,:);


Fs = 1/blp.dx;
WINDOW_SEC = 10;
WINDOW = 2^nextpow2(WINDOW_SEC*Fs);
NFFT = WINDOW;
NOVERLAP = round(WINDOW*0.2);

[cxy,chfreq]=mscohere(mdat(:,1),mdat(:,2),WINDOW,NOVERLAP,NFFT,Fs);

figure; cla;
plot(chfreq,cxy)
[cxy,chfreq]=mscohere(mdat(:,1),mdat(:,9),WINDOW,NOVERLAP,NFFT,Fs);
plot(chfreq,cxy); grid on; hold on; set(gca,'xlim',[0 30]);
[cxy,chfreq]=mscohere(mdat(:,2),mdat(:,9),WINDOW,NOVERLAP,NFFT,Fs);
plot(chfreq,cxy,'r');
[cxy,chfreq]=mscohere(mdat(:,3),mdat(:,9),WINDOW,NOVERLAP,NFFT,Fs);
plot(chfreq,cxy,'g');
[cxy,chfreq]=mscohere(mdat(:,4),mdat(:,9),WINDOW,NOVERLAP,NFFT,Fs);
plot(chfreq,cxy,'k');
[cxy,chfreq]=mscohere(mdat(:,5),mdat(:,9),WINDOW,NOVERLAP,NFFT,Fs);
plot(chfreq,cxy,'c');
[cxy,chfreq]=mscohere(mdat(:,6),mdat(:,9),WINDOW,NOVERLAP,NFFT,Fs);
plot(chfreq,cxy,'m');
[cxy,chfreq]=mscohere(mdat(:,7),mdat(:,9),WINDOW,NOVERLAP,NFFT,Fs);
plot(chfreq,cxy,'m');
[cxy,chfreq]=mscohere(mdat(:,8),mdat(:,9),WINDOW,NOVERLAP,NFFT,Fs);
plot(chfreq,cxy,'color',[0.7 0.7 0.2]);


figure;
[c,lags]= xcov(mdat(:,1),mdat(:,9),2500,'coef');
plot(lags*dx,c); grid on; set(gca,'ylim',[-0.4 0.8]);  hold on;
[c,lags]= xcov(mdat(:,2),mdat(:,9),2500,'coef');
plot(lags*dx,c,'color','r');
[c,lags]= xcov(mdat(:,3),mdat(:,9),2500,'coef');
plot(lags*dx,c,'color','g');
[c,lags]= xcov(mdat(:,4),mdat(:,9),2500,'coef');
plot(lags*dx,c,'color','k');
[c,lags]= xcov(mdat(:,5),mdat(:,9),2500,'coef');
plot(lags*dx,c,'color','c');
[c,lags]= xcov(mdat(:,6),mdat(:,9),2500,'coef');
plot(lags*dx,c,'color','m');
[c,lags]= xcov(mdat(:,7),mdat(:,9),2500,'coef');
plot(lags*dx,c,'color','m');
[c,lags]= xcov(mdat(:,8),mdat(:,9),2500,'coef');
plot(lags*dx,c,'color',[0.7 0.7 0.2]);
[c,lags]= xcov(mdat(:,9),mdat(:,9),2500,'coef');
plot(lags*dx,c);
