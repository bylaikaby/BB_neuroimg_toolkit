function fftTs = mroitsfft(roiTs,roiname,varargin)
%MROITSFFT - Returns the average power spectrum of roiTs.
% fftTs = MVITFFT(roiTs,roiname) returns the average power spectrum of roiTs. If no output
% argument is found the function will plot the spectra in the current axis.
% NKL, 10.02.01
  
if nargin < 2,
  if iscell(roiTs),
    roiTs = roiTs{1};
  end;
  fprintf('MROITSFFT: No ROI Name was defined; Using %s\n',roiTs.name);
else
  roiTs = mroitsget(roiTs,[],roiname);
  roiTs = roiTs{1};
end;

if nargin<1,
  help mroitsfft;
  fftTs = {};
  return;
end;

for N=1:length(roiTs),
  roiTs.dat = detrend(roiTs.dat);
end;


fftTs = roiTs;
Fs = 1/roiTs.dx;
nyq = Fs/2;
LEN = size(fftTs.dat,1);
PADLEN = max(LEN,4096);
PADLEN = LEN;

fftTs = roiTs;
Fs = 1/roiTs.dx;
for N=1:length(roiTs),
  ARGS.SRATE = Fs;
  ARGS.COLOR = 'k';
  Sig.dx = roiTs.dx;
  Sig.dir = roiTs.dir;
  Sig.dat = roiTs.dat;
  [fftTs.dat, fftTs.pha, fre] = msigfft(Sig,ARGS);
  fftTs.dx = fre(2)-fre(1);
end;

if ~nargout,
  y=median(fftTs.dat,2);
  stem(fre, y,varargin{:});
  set(gca,'xlim',[0 nyq]);
  grid on
  xlabel('Frequency in Hz');
  ylabel('Power');
end;

