function sigwhitendemo(Sig,FLTORDER)
%SIGWHITENDEMO - Show effects of prewhitening on signal Sig.
% SIGWHITENDEMO (Sig) shows the signals and their spectra to compare different methods of
% prewhitening; the process we use to get an unbiased IR estimate.
% NKL, 30.01.05

if nargin < 1,
  help sigwhitendemo;
  return;
end;

if nargin < 2,
  FLTORDER = 10;
end;

Sig.dat = hnanmean(Sig.dat,2);
Sig.dx = Sig.dx(1);

[famp,fang,freq] = sigfft(Sig);

oSig = Sig;

if 1,
  [oSig.dat,b] = whiten(Sig.dat,FLTORDER);
else
  oSig.dat = whitenSignal(Sig.dat);
end;
oSig.dat(1:20,:) = 0;
oSig.dat(end-20:end,:) = 0;

[ofamp,ofang,ofreq] = sigfft(oSig);


mfigure([100 40 950 920]);

subplot(2,1,1);
t = [0:size(Sig.dat,1)-1]*Sig.dx;
ax = plotyy(t,Sig.dat,t,oSig.dat);
xlabel('Time in seconds');
ylabel('Arbitrary Units');
set(ax(1),'xlim',[t(1) t(end)]);
set(ax(2),'xlim',[t(1) t(end)]);
set(ax(1),'xlim',[12 14]);
set(ax(2),'xlim',[12 14]);
grid on;

subplot(2,1,2);
plot(freq,famp,'linewidth',1.5);
hold on;
plot(freq,ofamp,'color','r','linewidth',1.5);
xlabel('Frequency in Hz');
ylabel('Magnitude');
title('Spectrum of LFP Signal');
grid on;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [odat,a] = whiten(dat,n)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
a = th2poly(ar(dat,n,'ls'));
odat = dat;
odat=filter(a,1,dat);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sigdat = whitenSignal( sigdat)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[m n]= size(sigdat);
if m < n
    sigdat = sigdat';
end
c = cov(sigdat); 

% eigen value decomposition, nobalance avoids small values round off
[E, D] = eig(c, 'nobalance');

% diagonalize cov. matrix and make variance of one
sigdat = sigdat * E * inv(sqrtm(D)) * E';

if m < n
    sigdat = sigdat';
end
return;
