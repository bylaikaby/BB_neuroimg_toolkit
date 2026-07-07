function cSig = atsigcohere(Sig,cfgType,ARGS)
%ATSIGCOHERE - time dependent coherence analysis
%	ATSIGCOHERE(X,Y,Fs,NFFT,WinLen) performs time dependent analsysi on
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
DOPLOT = 0;

if nargin < 2,
  cfgType = 'wire';
end;

if nargin < 1,
  error('atsigcohere: usage: atsigcohere(Sig);');
end;

% DEFAULT ARGUMENTS/PARAMETERS
WINDOWSEC	= 2;			% 2 seconds sliding window
OVERLAP		= 0.1;			% 10% overlap
EPOCH		= 0;			% If zero check Sig.stm for epochs

if exist('ARGS','var'),
  pareval(ARGS);
end;

Fs = 1/Sig.dx;

WINDOW = round(WINDOWSEC*Fs);			% Window in points
NOVERLAP = round(OVERLAP * WINDOW);		% Overlap in points
NFFT = WINDOW;

if (NFFT < WINDOW),
   NFFT = 2^nextpow2(WINDOW);
end;
	  
cSig = rmfield(Sig,{'dat'});
if isfield(cSig,'usr'),
  cSig = rmfield(cSig,'usr');
end;
if isfield(cSig,'evt'),
  cSig = rmfield(cSig,'evt');
end;
if isfield(cSig,'movie'),
  cSig = rmfield(cSig,'movie');
end;
if isfield(cSig,'tosdu'),
  cSig = rmfield(cSig,'tosdu');
end;

cSig.dir.dname = sprintf('ch%s',Sig.dir.dname);
cSig.dsp.func = 'dspch';

% IMPORTANT NOTE:
% THIS HERE ASSUMES BLANK-STIMULUS-BLANK; WE HAVE TO MAKE MORE
% GENERAL LATER ON!!!!!!!!!!!!!!!!!!!!!!!!
t = [0:size(Sig.dat,1)-1] * Sig.dx;
if ~EPOCH & any(Sig.stm.v{1}),
  STIMULUS=1;
  son = find(t>=Sig.stm.t{1}(2)&t<Sig.stm.t{1}(3));
  sof = find(t<Sig.stm.t{1}(2)|t>=Sig.stm.t{1}(3));
else
  STIMULUS=0;
  son = [1:size(Sig.dat,1)];
  sof = son;
end;

son = son(:);
sof = sof(:);
npairs = atgetelepos(Sig.session,Sig.grpname,cfgType);

try,
NoDist = length(npairs);
for DistNo = NoDist:-1:1,
  p = npairs{DistNo}.dat;
  for pNo = size(p,1):-1:1,
	N = p(pNo,1);
	M = p(pNo,2);
	[cxy,f]=cohere(Sig.dat(son,N),Sig.dat(son,M),NFFT,Fs,WINDOW,NOVERLAP);
	if STIMULUS,
	  [bxy,f]=cohere(Sig.dat(sof,N),Sig.dat(sof,M),NFFT,Fs,WINDOW,NOVERLAP);
	else
	  bxy = cxy;
	end;
	[sdat{DistNo}(:,pNo)] = cxy(:);
	[bdat{DistNo}(:,pNo)] = bxy(:);
  end;
end;
catch,
  disp(lasterr);
  keyboard;
end;

for DistNo = NoDist:-1:1,
  cSig.dat(:,DistNo) = mean(sdat{DistNo},2);
  cSig.std(:,DistNo) = std(sdat{DistNo},1,2);
  cSig.bdat(:,DistNo) = mean(bdat{DistNo},2);
  cSig.bstd(:,DistNo) = std(bdat{DistNo},1,2);
end;
cSig.f = f;
cSig.npairs = npairs;

if DOPLOT,
  for N=1:length(npairs),
	dist(N) = npairs{N}.dist;
  end;

  mfigure([100 100 500 750]);
  subplot(2,1,1);
  plot(cSig.f,cSig.dat(:,1),'linewidth',2,'color','r');
  hold on;
  plot(cSig.f,cSig.bdat(:,1),'linewidth',2,'color','k');
  set(gca,'xlim',cSig.range);
  xlabel('Frequency in Hz');
  ylabel('Power');
  grid on;

  subplot(2,1,2);
  lim1=35;
  lim2=80;
  fx = find(cSig.f>lim1&cSig.f<lim2);
  c = mean(cSig.dat(fx,:),1);
  bc = mean(cSig.bdat(fx,:),1);

  plot(dist, c, 'rs-','markerfacecolor','r');
  hold on;
  plot(dist, bc, 'ks-','markerfacecolor','k');
  xlabel('Distance in mm');
  ylabel('Coherence Value');
  grid on;
  keyboard
end;
clear sdat bdat f npairs;





