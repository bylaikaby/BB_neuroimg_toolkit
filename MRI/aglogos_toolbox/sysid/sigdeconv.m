function oSig = sigdeconv(Sig,hrf,OPTYPE)
%SIGDECONV - Deconvolve the MRI signal using the spont-computed HRF
% SIGDECONV (SIG, HRF) uses the optimal (Wiener) kernel computed with
% correlation analysis to deconvolve the MRI signal. Deconvolution
% is enorm sensitive to noise because is a polynomial dvision. So,
% filtering of HRF is a "must".
%
% NOISE-FREE CONDITIONS
% To deconvolve the effects of the response function, r, in the absenc
% of any noise, we simply divide C(f) by R(f) to get the neural signal.
% This can derived immediately from the fundanmental equation:
% s(t) = int(r(t-tau)*u(tau)*dr) <=> S(f) = R(f)*U(f)
%
% u - uncorrupted signal (neural activity, e.g. Lfp2080, Mua, Sdf)
% c - corrupted signal (BOLD, e.g. Pts, Nts)
% r - hemodynamic response function
% U, C, & R are the Fourier transforms of s,r,u, respectively.
% 
% REAL CONDITIONS
% Under real conditions c(r) is not just smeared out by a kernel determined
% by the system's impulse response, but it is also corrupted by
% measurement error, in our case by the instability of the B0,
% physiological noise, etc. etc.
% Thus an optimal (Wiener) filter, phi(t) or PHI(f), must be found,
% which when applied to the measured signal c(t) or C(f), and then
% deconvolved by r(t) or R(f), produced a signal hut(u(t)) or
% hut(U(f)) that is the best estimate of the true signal u(t) or U(f).
% In other words: hut(U(f)) = [C(f) * PHI(f)] / R(f)
% To asses how close the estimate is to the actual signal we
% shall ask how "close" the signals are in the least-square sense.
% That is: int(|hut(u(t))-u(t)|^2 dt) must be minimized
% CRA -- DOCUMENTATION
% The output-input data are given as
% z = [y u]
% with y as the output column vector and u as the input column vector. 
% Function 'cra' prewhitens the input sequence, i.e., filters u through
% a filter chosen so that the result is as uncorrelated (white) as
% possible. The output y is subjected to the same filter, and then 
% the covariance functions of the filtered y and u are computed and 
% graphed. The cross correlation function between (prewhitened) input 
% and output is also computed and graphed. Positive values of the lag 
% variable then corresponds to an influence from u to later values 
% of y. In other words, significant correlation for negative lags
% is an indication of feedback from y to u in the data.
%cra OUTPUT arguments
% ir -- A properly scaled version of this correlation function is also an
% estimate of the system's impulse response ir. This is also graphed
% along with 99% confidence levels. The output argument ir is this
% impulse response estimate, so that its first entry corresponds to lag
% zero. (Negative lags are excluded in ir.)
% covR -- The output argument R contains the covariance/correlation
% information as follows: The first column of R contains the lag
% indices. The second column contains the covariance function of 
% the (possibly filtered) output. The third column contains the 
% covariance function of the (possibly prewhitened) input, and 
% the fourth column contains the correlation function. The plots
% can be redisplayed by cra(R). 
% cl -- The output argument cl is the 99% confidence level for the
% impulse response estimate
% cra INPUT arguments
%
% I HAVE TO IMPLEMENT THIS IN THE FUTURE...
% IRBOUND=0;
% if IRBOUND,
%   tmp = (abs(1./R)>IRBOUND);
%   R(tmp) = (R(tmp)./abs(R(tmp)))/IRBOUND;
% end;
if nargin < 3,
  OPTYPE = 1;
end;

if nargin < 2,
  help msigdeconv;
  return;
end;

Sig.dat = hnanmean(Sig.dat,2);

% WE MAY USE FILTERING IN SOME CASES; NOW IT DOES NOTHING...
LEN         = size(Sig.dat,1);
NFFT        = 4096;
CUTOFF      = 0.25;       % Hz
Fs = 1/hrf.dx;
Nyq = Fs/2;
[b,a] = butter(3,CUTOFF/Nyq,'low');

hrf.dat = hnanmean(hrf.dat,2);
  
if OPTYPE,
  Sig.fft = fft(Sig.dat,NFFT);
  hrf.fft = fft(hrf.dat,NFFT);

  Us = Sig.fft ./ hrf.fft;
  us = ifft(Us,NFFT);
%  us = real(us);                  % image is neglegible!
  us = abs(us);                  % image is neglegible!
else
  us = deconv(Sig.dat,hrf.dat);
end;

us = us(1:LEN);
oSig = Sig;
oSig.dat = us;


