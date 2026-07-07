function showcra
%SHOWCRA - Apply Wiener analysis to group data

%%% ESTIMATION PARAMS:
NFFT    = 2^8;      % length of FFT
RLEN    = 150;      % length of ir kernel (points)
dx      = 0.25;     % data sampling interval

%%% PROCESSING PARAMS:
OPTFLT 	= 0;		% Opt. filter options.
OPTLP	= 0.2;      % Optimal low pass. (Set OPTFLT = 3).
IRBOUND	= 5;        % ???
CSFLAG 	= 0;		% Deconvolve cs rather than c.
CRAEST 	= 1;		% Estimate IR using CRA.

% n BOLD noise signal
% c BOLD stimulus-induced signal
% u Neural stimulus-induced signal

%----------------------------------------------------
N = fft(n,NFFT);
U = fft(u,NFFT);
C = fft(c,NFFT);
   
% Scale such that the difference |C|^2-|N|^2 is always pos.
C2 = abs(C).^2;
N2 = abs(N).^2;
   
switch OPTFLT,
 case 1,                      % WORKS
  [P, Ps, Py, Pz, alpha, Fig] = hwienerflt(c, n, 2, NFFT,1,'adapt',0);
 case 2,                      % NEVER TESTED
  alpha = min(C2 ./ N2);
  S2 = C2 - alpha * N2;
  % Optimal Wiener filter:
  P = S2 ./ C2;
 case 3,                      % OPTIMAL LOW PASS.
  P = ones(round(OPTLP*NFFT/2),1);
  P(NFFT/2) = 0;
  P = [P;P(end:-1:1)];
 case 4,                      % OPTIMAL WIENER FILTER:
  alpha = C2' * N2;
  S2 = C2 - alpha * N2;
  P = S2 ./ C2;
 otherwise,	% No filtering.
  P = ones(NFFT,1);
end;
   

% u -- Neural
% c -- BOLD
% r -- hrf
% R -- fft(hrf)
%   
% WE MAY WANT TO FILTER BEFORE WE GET THE SPECTRUM
% C -- fft(c,NFFT)
% R -- fft(r,NFFT);
%
% This is supposed to work with (any) filtered kernel; BUT IT DOESN'T
% us = deconv(cs,r);

% WHAT IS THIS???
if IRBOUND,
   tmp = (abs(1./R)>IRBOUND);
   R(tmp) = (R(tmp)./abs(R(tmp)))/IRBOUND;
end;

Cs = fft(c,NFFT);

  
if OPTFLT, % FILTERED
           % Applying the P-filter in this case causes slight
           % imperfections in deconv.
  Us = P .* Cs ./ R;
else,
  % Perfect deconv. for this artificial case.
  Us = Cs ./ R;
end;

us = ifft(Us,NFFT);
us = real(us);		% imag is neglegible!
us = us(1:length(u));


%%% WORKING APPROACH 1
CRAEST      = 1;		% Estimate IR using CRA.
CSFLAG      = 0;		% Deconvolve cs rather than c.
OPTFLT      = 0;		% Use opt filter.
NFFT        = 2^8;
RLEN        = 100;

%%% WORKING APPROACH 2
CRAEST      = 1;		% Estimate IR using CRA.
CSFLAG      = 0;		% Deconvolve cs rather than c.
OPTFLT      = 1;		% Use opt filter.
NFFT        = 2^8;
RLEN        = 100;

%%% WORKING APPROACH 3
CRAEST      = 1;		% Estimate IR using CRA.
CSFLAG      = 0;		% Deconvolve cs rather than c.
OPTFLT      = 0;		% Use opt filter.
OPTLP		= 0.2;	% Optimal low pass. (Set OPTFLT = 3).
IRBOUND     = 5;
NFFT        = 2^8;
RLEN        = 150;
