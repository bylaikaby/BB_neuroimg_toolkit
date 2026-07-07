function [SigCoh,F,T] = cohgram(X,Y,Fs,NFFT,Window)
%COHGRAM - time dependent coherence analysis
%	COHGRAM(X,Y,Fs,NFFT,WinLen) performs time dependent analsysi on
%	the band-pass filtered data.
%
%   See also COHERE, PSD, CSD, TFE, SIGSPC
%
%   Cxy = COHERE(X,Y,NFFT,Fs,WINDOW) estimates the coherence of X and Y
%   using Welch's averaged periodogram method.  Coherence is a function
%   of frequency with values between 0 and 1 that indicate how well the
%   input X corresponds to the output Y at each frequency.  X and Y are 
%   divided into overlapping sections, each of which is detrended, then 
%   windowed by the WINDOW parameter, then zero-padded to length NFFT.  
%   The magnitude squared of the length NFFT DFTs of the sections of X and 
%   the sections of Y are averaged to form Pxx and Pyy, the Power Spectral
%   Densities of X and Y respectively. The products of the length NFFT DFTs
%   of the sections of X and Y are averaged to form Pxy, the Cross Spectral
%   Density of X and Y.
%
%	The coherence Cxy is given by  Cxy = (abs(Pxy).^2)./(Pxx.*Pyy)
%
%   Cxy has length NFFT/2+1 for NFFT even, (NFFT+1)/2 for NFFT odd, or NFFT
%   if X or Y is complex. If you specify a scalar for WINDOW, a Hanning 
%   window of that length is used.  Fs is the sampling frequency which does
%   not effect the cross spectrum estimate but is used for scaling of plots.
%
%   [Cxy,F] = COHERE(X,Y,NFFT,Fs,WINDOW,NOVERLAP) returns a vector of freq-
%   uencies the same size as Cxy at which the coherence is computed, and 
%   overlaps the sections of X and Y by NOVERLAP samples.
%
%   COHERE(X,Y,...,DFLAG), where DFLAG can be 'linear', 'mean' or 'none', 
%   specifies a detrending mode for the prewindowed sections of X and Y.
%   DFLAG can take the place of any parameter in the parameter list
%   (besides X and Y) as long as it is last, e.g. COHERE(X,Y,'mean');
%   
%   COHERE with no output arguments plots the coherence in the current 
%   figure window.
%
%   The default values for the parameters are NFFT = 256 (or LENGTH(X),
%   whichever is smaller), NOVERLAP = 0, WINDOW = HANNING(NFFT), Fs = 2, 
%   P = .95, and DFLAG = 'none'.  You can obtain a default parameter by 
%   leaving it off or inserting an empty matrix [], e.g. 
%   COHERE(X,Y,[],10000).
%
%	AUTH: NKL, 08.05.03
  
% THINGS TO DO:
% 1. Choose appropriate times for window etc...
  2. 

if nargin < 3,
  error('cohgram: usage: cohgram(X,Y,Fs,[NFFT,Window]);');
end;

if nargin < 4,
  NFFT = 256;
end;

WinLenSec = 0.125;					% Time window for averaging in cohere
if nargin < 5,
  Window = WinLenSec * 6;			% 1 second sliding window
end;

WinLenPnt = round(WinLenSec*Fs);	% In points
WindowPnt = round(Window*Fs);		% Window for which we compute coherence

if WindowPnt < WinLenPnt,
  fprintf('Sliding Time Window must be greater then averaging window\n');
  fprintf('Check documentation of cohere\n');
  keyboard;
end;

% [Cxy,F] = COHERE(X,Y,NFFT,Fs,WINDOW,NOVERLAP) returns a vector of freq-

NoWin = floor(length(X)/WindowPnt);
t = [0:NoWin-1]'.*WindowPnt+1;

for WinNo=NoWin:-1:1,
  T1 = t(WinNo);
  T2 = T1 + WindowPnt;
  [SigCoh(:,WinNo),f]=cohere(X(T1:T2),Y(T1:T2),NFFT,Fs,NFFT,round(NFFT/4));
end;
SigCoh = SigCoh';
t = t * Window;

if nargout >= 2,
  F = f;
end;

if nargin == 3,
  T = t;
end;

if ~nargout,
  surf(t,f,SigCoh');
  set(gca,'yscale','log');
  set(gca,'Xlim',[0 t(end)]);
  set(gca,'Ylim',[f(1) f(end)]);
  set(gca,'Xcolor','k','LineWidth',1);
  set(gca,'Ycolor','k','LineWidth',1);
  xlabel('Time in sec','fontweight','bold','fontsize',8,'color','k');
  ylabel('Log Frequency in Hz','fontweight','bold','fontsize',8,'color','k');
  shading interp;
  view(0,90);
end;







