function irf = lfpmuairf(Sig1, Sig2, LagsInSec, FLTORD)
%LFPMUAIRF - Compute the Impuse Response of the LFP-MUA system
%
% irf = LFPMUAIRF(Sig1, Sig2, LagsInSec) - get IRF of an entire group To deconvolve the effects of
% the response function, r, in the absenc of any noise, we simply divide C(f) by R(f) to get
% the neural signal. This can derived immediately from the fundanmental equation: s(t) =
% int(r(t-tau)*u(tau)*dr) <=> S(f) = R(f)*U(f)
%
%	u - uncorrupted signal (neural activity, e.g. Lfp2080, Mua, Sdf)
%	c - corrupted signal (BOLD, e.g. Pts, Nts)
%	r - hemodynamic response function
%	U, C, & R are the Fourier transforms of s,r,u, respectively.
% 
% Under real conditions c(r) is not just smeared out by a kernel determined by the system's
% impulse response, but it is also corrupted by measurement error, in our case by the
% instability of the B0, physiological noise, etc. etc.  Thus an optimal (Wiener) filter,
% phi(t) or PHI(f), must be found, which when applied to the measured signal c(t) or C(f), and
% then deconvolved by r(t) or R(f), produced a signal hut(u(t)) or hut(U(f)) that is the best
% estimate of the true signal u(t) or U(f).  In other words: hut(U(f)) = [C(f) * PHI(f)] / R(f)
% To asses how close the estimate is to the actual signal we shall ask how "close" the signals
% are in the least-square sense.  That is: int(|hut(u(t))-u(t)|^2 dt) must be minimized
%
% The output-input data are given as z = [y u], with y as the output column vector and u as the
% input column vector.  Function 'cra' prewhitens the input sequence, i.e., filters u through a
% filter chosen so that the result is as uncorrelated (white) as possible. The output y is
% subjected to the same filter, and then the covariance functions of the filtered y and u are
% computed and graphed. The cross correlation function between (prewhitened) input and output
% is also computed and graphed. Positive values of the lag variable then corresponds to an
% influence from u to later values of y. In other words, significant correlation for negative
% lags is an indication of feedback from y to u in the data.
%
% irf -- A properly scaled version of this correlation function is also an estimate of the
% system's impulse response irf. This is also graphed along with 99% confidence levels. The
% output argument irf is this impulse response estimate, so that its first entry corresponds to
% lag zero. (Negative lags are excluded in irf.)  covR -- The output argument R contains the
% covariance/correlation information as follows: The first column of R contains the lag
% indices. The second column contains the covariance function of the (possibly filtered)
% output. The third column contains the covariance function of the (possibly prewhitened)
% input, and the fourth column contains the correlation function. The plots can be redisplayed
% by cra(R).
%
%	NKL, 14.02.01
%	NKL, 28.07.04

%
% irf = lfpmuairf(Sig1, Sig2, LagsInSec, FLTORD)
if nargin < 3,
	LagsInSec = 1.5;
end;

if nargin < 4,
  FLTORD	= 10;           % For prewhittening
end;

if nargin < 2,
  fprintf('\nlfpmuairf: Syntax parse ERROR\n\n');
  help lfpmuairf;
  return;
end;

if size(Sig1.dat,2)>1,
  fprintf('lfpmuairf: expects vectors not matrices\n');
  keyboard;
end;

if size(Sig2.dat,2)>1,
  fprintf('lfpmuairf: expects vectors not matrices\n');
  keyboard;
end;

% NOW ALL SIGNALS ARE RESAMPLED AT 40Hz
% Nothing magic about 40Hz; it's good enough temporal resolution for an accurate measurement
% of IRF. The neural signal will need decimation and the BOLD signal resampling with higher
% rate. We use the resample() function for both signals with the same Fs = 40;
Fs = 40;

% To do the conversion we use the RAT function to find integers p and q that yield the correct
% resampling factor: [p,q] = rat(NewFs/Fs,0.0001) with tolerance of 0.0001.
[p,q] = rat(Fs/(1/Sig1.dx),0.0001);

% We then resample(Sig.dat,p,q); Note that the RESAMPLE function applies a lowpass filter to
% the input sequence to prevent aliasing during resampling. It designs this filter using the
% firls function with a Kaiser window. The syntax resample(x,p,q,l,beta) controls the filter's
% length and the beta parameter of the Kaiser window. Alternatively, use ...  the function
% intfilt to design an interpolation filter b and use it with resample(x,p,q,b)
Sig1.dat = resample(Sig1.dat,p,q);
Sig1.dx = 1/Fs;

% And now for the MRI signal
[p,q] = rat(Fs/(1/Sig2.dx),0.0001);
Sig2.dat = resample(Sig2.dat,p,q);
Sig2.dx = 1/Fs;

% MAKE SURE BOTH SIGNALS ARE OF THE SAME LENGTH
if length(Sig2.dat)>length(Sig1.dat),
  Sig2.dat = Sig2.dat(1:length(Sig1.dat));
else
  Sig1.dat = Sig1.dat(1:length(Sig2.dat));
end;

NLAGS = round(LagsInSec / Sig1.dx);
if NLAGS >= size(Sig2.dat,1),
  NLAGS = size(Sig2.dat,1);
  fprintf('lfpmuairf[WARNING]: too many NLAGS, using %d\n',NLAGS);
end;

%   [IR,R,CL] = CRA(Z,M,NA,PLOT) gives access to
%   Z: The data, entered as an IDDATA object or a matrix 
%      with two columns Z = [y u].
%   IR: The estimated impulse response (IR(1) corresponds to g(0))
%   M: The number of lags for which the functions are computed (def 20)
%   NA: The order of the whitening filter.(Def 10). With NA=0, no prewhite-
%       ning is performed. Then the covariance functions of the original
%       data are obtained.
%   PLOT: PLOT=0 gives no plots. PLOT=1 (Default) gives a plot of IR along
%       with a 99 % confidence region. PLOT=2 gives a plot of all R's.
%   Note that in the plot, the response to a normalized pulse input,
%      u(t) = 1/T for 0<t<T, is shown, where T is the sampling interval
%      of the data.
%   R: The covariance/correlation information
%      R(:,1) contains the lag indices
%      R(:,2) contains the covariance function of y (poss. prewhitened)
%      R(:,3) contains the covariance function of u (poss. prewhitened)
%      R(:,4) contains the correlation function between (poss prewhitened)
%        u and y (positive lags corresponds to an influence from u to y)
%      CL is the 99 % significance level for the impulse response
%
u = Sig1.dat;
c = Sig2.dat;

if size(u,1) <= 2*NLAGS,
  u = cat(1,u,u);
  c = cat(1,c,c);
end;

z = [c u];
[ir,R] = cra(z,NLAGS,FLTORD,0);

irf = Sig1;
len = round(LagsInSec/irf.dx);
irf.dat = ir(1:len);














