function oSig = sigfft(Sig,varargin)
%SIGFFT - Fast Fourier transform for our neural (BLP) and fMRI (roiTs) signals
% oSig = SIGFFT(Sig,varargin]) return amplitude, phase and frequency of Fourier
% transform. If no output arguments are defined, the spectrum is displayed.
%
% NKL, 27.02.00
% NKL, 08.01.06

if nargin < 1,                  % roiTs must be defined as input
  help sigfft;
  return;
end;

VALIDARGS = {'Xscale';'Padding';'Disp'};

% Default arguments for function DSPROITS
%
DEF.Xscale      = 'log';
DEF.Disp        = 0;

out = parseinput(VALIDARGS,varargin);
if ~isempty(out),
  out = sctcat(out,DEF);
else
  out = DEF;
end;
pareval(out);

if isfield(Sig,'usr'),      oSig = rmfield(Sig,{'usr'});    end;
if isfield(Sig,'dxorg'),    oSig = rmfield(Sig,{'dxorg'});  end;
if isfield(Sig,'err'),      oSig = rmfield(Sig,{'err'});    end;
if isfield(Sig,'stm'),      oSig = rmfield(Sig,{'stm'});    end;

if ~isstruct(Sig),
  for N=1:length(Sig),
    if isstruct(Sig{N}),
      [oSig{N}.dat, oSig{N}.dx] = subFFT(Sig{N});
      if (strcmpi(oSig{N}.dir.dname,'blp')),
        oSig{N}.dir.dname = 'fftblp';
        oSig{N}.dsp.func = 'dspfftblp';
        oSig{N}.sigdx = Sig.dx;
      else
        oSig{N}.dir.dname = 'fftroiTs';
        oSig{N}.dsp.func = 'dspfftroits';
      end;
    else
      for M=1:length(Sig{N}),
        [oSig{N}{M}.dat, oSig{N}.dx] = subFFT(Sig{N}{M});
        if (strcmpi(oSig{N}{M}.dir.dname,'blp')),
          oSig{N}{M}.dir.dname = 'fftblp';
          oSig{N}{M}.dsp.func = 'dspfftblp';
        else
          oSig{N}{M}.dir.dname = 'fftroiTs';
          oSig{N}{M}.dsp.func = 'dspfftroits';
        end;
        oSig{N}{M}.sigdx = Sig.dx;
      end;
    end
  end;
else
  [oSig.dat, oSig.dx] = subFFT(Sig);
  if (strcmpi(oSig.dir.dname,'blp')),
    oSig.dir.dname = 'fftblp';
    oSig.dsp.func = 'dspfftblp';
  elseif (strcmpi(lower(oSig.dir.dname),'cln')),
    oSig.dir.dname = 'fftcln';
    oSig.dsp.func = 'dspfft';
  else
    oSig.dir.dname = 'fftroiTs';
    oSig.dsp.func = 'dspfftroits';
  end;
  oSig.sigdx = Sig.dx;
end;

if (~nargout | DEF.Disp),
  y=oSig.dat;
  fr = [0:size(oSig.dat,1)-1]*oSig.dx;
  y = y./repmat(sum(y,1),[size(y,1) 1]);
  plot(fr, y,'linewidth',1);
  hold on;
  plot(fr, mean(y,2), 'linewidth',3,'color','c');
  set(gca,'xscale',DEF.Xscale);
  grid on
end
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [fdat, fdx]  = subFFT(Sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = size(Sig.dat);
if length(s) > 1,
  Sig.dat = reshape(Sig.dat,[s(1) prod(s(2:end))]);
end;
Fs = 1/Sig.dx;
Nyq = Fs/2;
fdx = Nyq/size(Sig.dat,1);
len = 2*size(Sig.dat,1);
fdat = fft(Sig.dat,len,1);
fdat = fdat(1:size(Sig.dat,1),:);
if length(s) > 1,
  fdat = reshape(fdat,s);
end;
fdat = abs(fdat);
return;
