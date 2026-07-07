function varargout = mspectrum(filename,varargin)
%MSPECTRUM - Compute spectrum.
%  SPC = MSPECTRUM(FILENAME,...) computes spectrum of the given datafile.
%
%  EXAMPLE :
%    spc = mspectrum('test.adfw')
%    spc = mspectrum('test_CLN.mat')
%
%  VERSION :
%    0.90 02.11.08 YM  pre-release
%
%  See also spectrogram pwelch fft

if nargin == 0,  help mspectrum; return;  end

% ANALYSIS OPTIONS 
METHOD = 'spectrogram';
%METHOD = 'welch';  % need scaling to get worked...
METHOD = 'fft';
WindowSec = 0.25;
NfftSec   = 0.25;
GAIN      = 10;
CHAN      = [];

for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'method'}
    METHOD = varargin{N+1};
   case {'windowsec'}
    WindowSec = varargin{N+1};
   case {'nfftsec'}
    NfftSec = varargin{N+1};
   case {'gain'}
    GAIN = varargin{N+1};
   case {'chan'}
    CHAN = varargin{N+1};
  end
end

filename = strrep(filename,'\','/');

if strcmpi(filename,'test'),
  sampt = 1.0/5000;
  npts  = round(30/sampt);
  tmpt  = [0:npts-1]*sampt;
  tmpdat1 = sin(tmpt*150*2*pi);
  tmpdat2 = sin(tmpt*800*2*pi);
  SIG.dat = tmpdat1(:) + tmpdat2(:);
  SIG.dx  = sampt;
  SIG.filename = 'test';
  SIG.chan = 1:size(SIG.dat,2);
  clear tmpt sampt npts tmpdat1 tmpdat2;
else
  [fp fr fe] = fileparts(filename);
  switch lower(fe),
   case {'.adfw','.adf'}
    [nchan nobs sampt obslens] = adf_info(filename);
    if isempty(CHAN),
      CHAN = 1:min(chan,4);
      nchan = min(nchan,4);
    else
      nchan = length(CHAN);
    end
    
    npts = round(30/sampt*1000);
    SIG.dat = zeros(npts,nchan);
    for N = 1:length(CHAN),
      SIG.dat(:,N) = adf_read(filename,0,CHAN(N)-1,0,npts);
    end
    SIG.dat = SIG.dat/32768*10/GAIN;   % ADC --> AD-Voltage --> x1 amp
    SIG.dx = sampt/1000;
    SIG.chan = CHAN;
    SIG.gain = GAIN;
   otherwise
    SIG = load(filename,'Cln');
    SIG = SIG.Cln;
    if isfield(SIG,'dxorg'),
      SIG.dx = SIG.dxorg;
    end
    
    npts = round(30/SIG.dx);
    SIG.dat = SIG.dat(1:npts,:);
    if ~isempty(CHAN),
      SIG.dat = SIG.dat(:,CHAN);
    end
    SIG.dat = SIG.dat/32768*10/GAIN;   % ADC --> AD-Voltage --> x1 amp
    if isempty(CHAN),
      SIG.chan = 1:size(SIG.dat,2);
    else
      SIG.chan = CHAN;
    end
    SIG.gain = GAIN;
  end
  SIG.filename = filename;
end


switch lower(METHOD),
 case {'spectrogram'}
  SPC = sub_spectrogram(SIG,WindowSec,NfftSec);
 case {'fft'}
  SPC = sub_fft(SIG,WindowSec,NfftSec);
 case {'welch','pwelch'}
  SPC = sub_pwelch(SIG,WindowSec,NfftSec);
 otherwise
  error(' ERROR %s: METHOD=''%s'' not supported.\n');
end


sub_plot(SPC,SIG);

if nargout > 0,
  varargout{1} = SPC;
  if nargout > 1,
    varargout{2} = SIG;
  end
end

return





function SPC = sub_spectrogram(SIG,WindowSec,NfftSec)

WINDOW  = round(WindowSec/SIG.dx);
OVERLAP = round(WINDOW*0.5);
NFFT    = round(NfftSec/SIG.dx);
Fs      = 1/SIG.dx;

spcdat = [];
for N = size(SIG.dat,2):-1:1,
  tmpdat = double(SIG.dat(:,N));
  % note tmpspc as (f,t)
  [tmpspc F T] = spectrogram(tmpdat,WINDOW,OVERLAP,NFFT,Fs);
  tmpspc = abs(tmpspc)/NFFT*2;
  spcdat(:,N) = nanmean(tmpspc,2);
end

SPC.filename = SIG.filename;
SPC.dat = spcdat;
SPC.freq = F;
SPC.method = 'mean-spectrogram';
SPC.window  = WINDOW;
SPC.overlap = OVERLAP;
SPC.nfft    = NFFT;
SPC.Fs      = Fs;

return


function SPC = sub_fft(SIG,WindowSec,NfftSec)

WINDOW  = round(WindowSec/SIG.dx);
OVERLAP = round(WINDOW*0.5);
NFFT    = round(NfftSec/SIG.dx);
Fs      = 1/SIG.dx;

winf    = ones(WINDOW,1);
%winf    = hann(WINDOW);  % Hanning window
%winf    = hamming(WINDOW);  % Hamming window
%winf    = blackman(WINDOW);  %  Blackman window
%winf    = kaiser(WINDOW);
%winf   = blackmanharris(WINDOW);

spcdat = [];
for N = size(SIG.dat,2):-1:1,
  tmpidx = [1:WINDOW];
  tmpspc = [];
  while tmpidx(end) < size(SIG.dat,1),
    tmpdat = double(SIG.dat(tmpidx,N)).*winf(:);
    tmpfft = fft(tmpdat,NFFT)/WINDOW;
    tmpfft = 2*abs(tmpfft(1:round(NFFT/2))); % single sided
    tmpspc = cat(2,tmpspc,tmpfft);
    tmpidx = tmpidx + (WINDOW - OVERLAP);
  end
  F = Fs/2*linspace(0,1,round(NFFT/2));
  tmpspc = abs(tmpspc);
  spcdat(:,N) = nanmean(tmpspc,2);
end

SPC.filename = SIG.filename;
SPC.dat = spcdat;
SPC.freq = F;
SPC.method = 'mean-fft';
SPC.window  = WINDOW;
SPC.overlap = OVERLAP;
SPC.nfft    = NFFT;
SPC.Fs      = Fs;

return


function SPC = sub_pwelch(SIG,WindowSec,NfftSec)

WINDOW  = round(WindowSec/SIG.dx);
OVERLAP = round(WINDOW*0.5);
NFFT    = round(NfftSec/SIG.dx);
Fs      = 1/SIG.dx;

spcdat = [];
for N = size(SIG.dat,2):-1:1,
  tmpdat = double(SIG.dat(:,N));
  % note tmpspc as (f,t)
  [Pxx F] = pwelch(tmpdat,WINDOW,OVERLAP,NFFT,Fs);
  tmpspc = sqrt(Pxx);
  spcdat(:,N) = tmpspc(:);
end

SPC.filename = SIG.filename;
SPC.dat = spcdat;
SPC.freq = F;
SPC.method = 'pwelch';
SPC.window  = WINDOW;
SPC.overlap = OVERLAP;
SPC.nfft    = NFFT;
SPC.Fs      = Fs;
SPC.chan    = SIG.chan;
SPC.gain    = SIG.gain;

return



function sub_plot(SPC,SIG)

for N = 1:size(SPC.dat,2),
  legtxt{N} = sprintf('Ch%02d',SIG.chan(N));
end
  
figure('Name',SPC.filename);
pos = get(gcf,'pos');
pos(2) = pos(2)-pos(4);  pos(4) = pos(4)*2;
set(gcf,'pos',pos);

subplot(2,1,1);
idx = find(SPC.freq > 0);
tmpf = SPC.freq(idx);
plot(tmpf,SPC.dat(idx,:)*1000);  % in mV
grid on;  legend(legtxt,'fontsize',8);
set(gca,'xlim',[tmpf(1) 3000],'layer','top','yscale','log');
xlabel('Frequency in Hz');
ylabel('Amplitude (mV)');
title(strrep(sprintf('%s: %s',SPC.method,SPC.filename),'_','\_'));
tmptxt = sprintf('Fs=%.2fkHz(%gmsec) window=%d(%.2fs) nfft=%d(%.2fs)',...
                 SPC.Fs/1000,1000/SPC.Fs,SPC.window,SPC.window/SPC.Fs,SPC.nfft,SPC.nfft/SPC.Fs);
text(0.02,0.05,tmptxt,'units','normalized');

subplot(2,1,2);
npts = round(1.0/SIG.dx);
tmpt = [0:npts-1]*SIG.dx*1000;  % in msec
plot(tmpt,SIG.dat(1:npts,:));
grid on;  legend(legtxt,'fontsize',8);
set(gca,'xlim',[0 20],'layer','top');
xlabel('Time in msec');
ylabel('Amplitude (V)');
title(strrep(sprintf('Time Course: %s',SPC.filename),'_','\_'));
text(0.02,0.05,sprintf('Fs=%.2fkHz(%gmsec)',1.0/SIG.dx/1000,1000*SIG.dx),'units','normalized');

return

