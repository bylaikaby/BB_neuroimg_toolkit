function [fabs,fang,fr] = msigfft(data, ARGS)
%MSIGFFT - Fast Fourier transform of matrices
%	[fabs,fang,fr] = MSIGFFT(data, ARGS)
%	data = NxM matrix, where columns are the data
%	fabs = NxM matrix, where columns are the power (abs)
%	fang = NxM matrix, where columns are the phase
%	fr  = frequencies
%	DFT or FFT for our MRI data
%	NKL, 27.02.00

SRATE   = 0;
DISP	= 0;
FLOOR   = 0;
PADDING = 1;
COLOR = 'k';
WIDTH = 0.8;
STYLE = '-';;
XSCALE='linear';
NORMALIZE=0;

if nargin > 1,
	if ~isempty(ARGS),
	   tmp = fieldnames(ARGS);
	   for i = 1:length(tmp),
		   eval(sprintf('%s = %s;',tmp{i},strcat('ARGS.',tmp{i})),'');
	   end;
	end;
end;

if nargin < 1, 
	error('usage: [fabs,fr] = msigfft(data,  ARGS)');
end

if isstruct(data),
  Sig=data;
  if strcmp(Sig.dir.dname,'tcImg'),
    fprintf('msigfft: data are from tcImg\n');
    fprintf('msigfft: examining the first slice only\n');
	data = detrend(mreshape(squeeze(Sig.dat(:,:,1,:))));
  else
	data = Sig.dat;

  end;
  srate = 1 / Sig.dx;
else
  srate = SRATE;
  if ~srate,
    fprintf('ARGS.SRATE is not defined\n');
    keyboard;
  end;
end;
Fs = srate;
Nyq = srate/2;

len = size(data,1);
if len > 128,       % Don't bother padding for small vectors
  if (FLOOR),
	len = getpow2(len,'floor');
  else
	len = getpow2(len,'ceiling');
  end;
end;

paddedLen = PADDING * len;

% It will return neg/pos frequencis
% The length of fdat is the same with that of data
% Yet, the max freq is the nyquist (half of Fs!!)
% ------------------------------------------------------------
fdat = fft(data,paddedLen,1);
lfr = (Fs/paddedLen) * [0:paddedLen-1];
LEN = size(fdat,1)/2;

fabs = abs(fdat(1:LEN,:));
fang = angle(fdat(1:LEN,:));
fr = lfr(:);
fr = lfr(1:LEN);
if (~nargout | DISP),
  y=mean(fabs,2);
  if NORMALIZE,
    y = y/sum(y);
  end;
  stem(lfr, y,'color',COLOR,...
       'linewidth',WIDTH,'linestyle',STYLE);
  set(gca,'xlim',[0 Nyq]);
  set(gca,'xscale',XSCALE);
  grid on
end
return;
