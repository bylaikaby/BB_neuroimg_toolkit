

SAMP_F  = 10000;  % Hz
LEN_SEC =  20;   % sec

SAMP_T = 1/SAMP_F;
LEN_N  = round(LEN_SEC/SAMP_T);

% create 2kHz sine wave
t = [1:round(0.01/SAMP_T)]*SAMP_T;
SDAT = sin(2*pi*2000*t);


% create simulated data
DAT = rand(1,LEN_N)*0.01;

for N = 1:4,
  idx = [1:length(SDAT)] + round(0.2*N/SAMP_T);
  DAT(idx) = DAT(idx) + SDAT;
end


% apply low-pass filter
[b,a] = butter(4,0.5,'low');
DAT = filtfilt(b,a,DAT);



T = [1:length(DAT)]*SAMP_T;
nfft = 2^nextpow2(2/SAMP_T);

[B,Fb,Tb] = specgram(DAT,nfft,SAMP_F,nfft,nfft/2);

% remove DC and neary-DC components
Fb = Fb(3:end);
B = B(3:end,:);

figure;
subplot(2,1,1);
plot(T,DAT);
subplot(2,1,2);
%imagesc(Tb,Fb,abs(B));
surf(Tb,Fb,abs(B),'linestyle','none');

