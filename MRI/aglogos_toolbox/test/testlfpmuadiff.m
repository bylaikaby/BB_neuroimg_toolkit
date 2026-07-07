
if ~exist('Cln','var'),
  Cln = sigload('c98nm1',1,'Cln');
end
%x = Cln.dat([1:round(30/Cln.dx)]+round(15/Cln.dx),3);
X = Cln.dat([1:round(50/Cln.dx)]+round(20/Cln.dx),3);

Fs   = 1/Cln.dx;
nyqf = Fs/2;

[b,a] = butter(4,500/nyqf,'high');  MUA = filtfilt(b,a,X);  MUA = decimate(abs(MUA),5);
[b,a] = butter(4,500/nyqf,'low');   LFP = filtfilt(b,a,X);  LFP = decimate(LFP,5);


Fs = 1/Cln.dx/5;
nyqf = Fs/2;


nfft = 2^nextpow2(1*Fs)
[B,f,t] = specgram(LFP,nfft,Fs,nfft,nfft-round(0.1*Fs));
[wv,ff,tt] = wvdc(LFP(:)',10,2048,Fs);

figure('Name','Power Specgram');
subplot(2,1,1);
fsel = find(f > 0 & f < 300);  imagesc(t,f(fsel),20*log10(abs(B(fsel,:))+eps));
subplot(2,1,2);
fsel = find(ff > 0 & ff < 300);  imagesc(tt,ff(fsel),20*log10(abs(wv(fsel,:))+eps));


figure('Name','Time Normalized Power Specgram');
Zb = zscore(abs(B)')';
Zwv = zscore(abs(wv)')';
subplot(2,1,1);
fsel = find(f > 0 & f < 300);imagesc(t,f(fsel),Zb(fsel,:))
subplot(2,1,2);
fsel = find(ff > 0 & ff < 300);imagesc(tt,ff(fsel),Zwv(fsel,:));



[b,a] = butter(4,100/nyqf,'low');
if 1,
  LFPn = filtfilt(b,a,LFP);
else
  LFPn = LFP;
end
LFPn = filtfilt(b,a,abs(LFPn));


[b,a] = butter(4,40/nyqf,'low');
LFPn = filtfilt(b,a,LFPn);
MUAn = filtfilt(b,a,MUA);




LFPn = abs(LFPn)/sum(abs(LFPn));
MUAn = abs(MUAn)/sum(abs(MUAn));


figure;
plot([0:length(MUAn)-1]/Fs,MUAn,'r'); grid on; hold on;
plot([0:length(MUAn)-1]/Fs,LFPn,'b');

