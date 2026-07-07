function Sig = sigfftfilt(Sig,Flim,Ftype)
%SIGFFTFILT - Filtering by FFT provides no phase lag and sharpest
%             frequency response.
% PURPOSE : To filter the signal by FFT.
% USAGE   : Sig = sigfftfilt(Sig,Flim,Ftype)
% ARGS    : Flim  : frequency limit(s) in Hz.
%           Ftype : filter type either 'low','high' or 'band'.
% EXAMPLE : roiTs{1} = sigfftfilt(roiTs{1},0.125,'high')
%           roiTs{1} = sigfftfilt(roiTs{1},[0.125 1],'band');
% NOTE    : Sig.dat should be a matrix of (t,n), the first column as time.
% VERSION : 07.04.04 YM   first release
%
% See also FFT IFFT

  
if nargin ~= 3, help sigfftfilt;  return;  end


% do FFT.
X = fft(Sig.dat);

% select frequencies and fill FFT coef with zero.
% note F above Fs/2 represent symetric negative frequencies.
Fs = 1.0/Sig.dx;
F  = 0:Fs/(size(X,1)-1):Fs;
switch lower(Ftype),
 case {'low','lowpass','lp'}
  % low pass
  Fi = find(F > Flim(1) & F < Fs - Flim(1));
  X(Fi,:) = 0;
 case {'high','highpass','hp'}
  % high pass
  Fi = find(F < Flim(1) | F > Fs - Flim(1));
  X(Fi,:) = 0;
 case {'band','bandpass','bp'}
  % high pass
  Fi = find(F < Flim(1) | F > Fs - Flim(1));
  X(Fi,:) = 0;
  % low pass
  Fi = find(F > Flim(2) & F < Fs - Flim(2));
  X(Fi,:) = 0;
 otherwise
  fprintf(' sigfftfilt: filter type ''%s'' not supported yet.\n',Ftype);
  keyboard
end

% do inverse FFT
Sig.dat = real(ifft(X));

return;
