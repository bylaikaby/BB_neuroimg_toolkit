function [wv, ff, tt] = wvdc(x, res, win, sps);
% wvdc		creates a Wigner-Ville spectrogram
%
% (wv,ff,tt)=wvd(x,res,win,sps)
%
% x=		real input time series
% res=		resolution, number of samples between windows
%		(for full resolution:  1)
% win=		window, becomes length of frequency axis
%		(a good default:  length(x)/2)
% sps=		samples per second of signal
%
% wv=		the W-V spectrum, each row represents a
%		frequency, each column a time instant
% ff=		frequency vector (optional)
% tt=		time vector (optional)
%
% 	Display using: 
%
%		imagesc(tt,ff,log10(abs(wv)));axis xy
% 	or:						
%		surf(tt,ff,log10(abs(wv)));shading interp
%
%	...of course modifying the abs or log10 as desired.
%
%						-Case Bradford, February 2005

%	
%		Adapted from Rene Laterveer, 1999, wvd.m package available from:
%		http://www.mathworks.com/matlabcentral/link_exchange/MATLAB/Signal_processing/
%

z=hilbert(x);

% make even number of points, at given resolution
npts = floor(floor(length(z)/res)/2)*2;

% make sure that we entered in an integer for the window
win=floor(win);

% round window length down to nearest odd integer
oddwin = (floor((win-1)/2)*2)+1;

% half point (for indexing reasons we need it later, we're
% filling two columns per loop, so we only index through half)
halfwin  = (oddwin+1)/2-1;

% create tt and ff
tt=[0:npts-1]*res/sps;
ff=[0:(win-1)]*(sps/2)/(win-1);

% pad with zeros
z = [zeros(1,oddwin-1), z, zeros(1,oddwin-1)];

% initialize (important when creating huge arrays)
wv = zeros(win,npts);

R = zeros(1, win);
idx = 1:halfwin;

for n=0:npts/2-1

  t = 2*n*res+oddwin;
  R(1) = z(t)*conj(z(t)) + i*z(t+res)*conj(z(t+res));
  v1 = z(t+idx).*conj(z(t-idx));
  v2 = z(t+res+idx).*conj(z(t+res-idx));
  R(idx+1) = v1+i*v2;
  R(win-idx+1) = conj(v1)+i*conj(v2);

  RF = fft(R, win);

  wv(:,2*n+1) = real(RF);
  wv(:,2*n+2) = imag(RF);

end

return;
