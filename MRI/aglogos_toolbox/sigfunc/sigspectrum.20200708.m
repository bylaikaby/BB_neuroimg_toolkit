function varargout = sigspectrum(SIG,varargin)
%SIGSPECTRUM - Compute spectrum.
%  SPC = SIGSPECTRUM(SIG,...) computes spectrum of the given signal.
%  Units is in magnitude, NOT POWER.
%
%  Supported options are :
%    'method'     : fft|welch|spectrogram
%    'windowsec'  : time window in sec
%    'windowtype' : window type, none|hanning|hamming|blackman|kaiser|blackmanharris
%    'nfftsec'    : FFT size in sec
%    'plot'       : 0|1 to plot the result
%    'legend'     : a cell array of strings for legend()
%
%  EXAMPLE :
%    sig = mvoxselect('h05ti1','polar2','V2','fhemo+',[],0.01)
%    spc = sigspectrum(sig,'WindowSec',10)
%
%  VERSION :
%    0.90 15.06.09 YM  pre-release
%    0.91 05.11.10 YM  supports "windowtype".
%    0.92 08.11.13 YM  bug fix of freq in sub_fft().
%    0.93 08.06.18 YM  supports 'legend' text.
%
%  See also spectrogram pwelch fft

if nargin == 0,  help sigspectrum; return;  end

% ANALYSIS OPTIONS 
METHOD     = 'welch';
WindowType = 'hamming';
WindowSec  = 0.25;
NfftSec    = [];
DO_AVERAGE = 0;
DO_PLOT    = 0;
LEG_TXT    = {};

for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'method'}
    METHOD = varargin{N+1};
   case {'window'}
    WindowType = varargin{N+1};
   case {'windowsec'}
    WindowSec = varargin{N+1};
   case {'nfftsec'}
    NfftSec = varargin{N+1};
   case {'average','do_average','doaverage'}
    DO_AVERAGE = varargin{N+1};
   case {'plot'}
    DO_PLOT = varargin{N+1};
   case {'legend'}
    LEG_TXT = varargin{N+1};
  end
end

if isempty(NfftSec),  NfftSec = WindowSec;  end


if strcmpi(SIG,'test'),
  sampt = 1.0/5000;
  npts  = round(30/sampt);
  tmpt  = (0:npts-1)*sampt;
  tmpdat1 = sin(tmpt*150*2*pi);
  tmpdat2 = sin(tmpt*800*2*pi);
  clear SIG;
  SIG.dat = tmpdat1(:) + tmpdat2(:);
  SIG.dx  = sampt;
  clear tmpt sampt npts tmpdat1 tmpdat2;
else
end

if any(DO_AVERAGE),
  SIG.dat = nanmean(SIG.dat,2);
end


NWINDOW = round(WindowSec/SIG.dx);
NFFT    = round(NfftSec/SIG.dx);


% WINDOW
if isempty(WindowType),  WindowType = 'hamming';  end
if ischar(WindowType),
  switch lower(WindowType),
   case {'ones','none'}
    WINDOW = ones(NWINDOW,1);
   case {'hanning','hann'}
    WINDOW = hann(NWINDOW);  % Hanning window
   case {'hamming'}
    WINDOW = hamming(NWINDOW);  % Hamming window
   case {'blackman'}
    WINDOW = blackman(NWINDOW);  %  Blackman window
   case {'kaiser'}
    WINDOW = kaiser(NWINDOW);
   case {'blackmanharris'}
    WINDOW = blackmanharris(NWINDOW);
  end
else
  WINDOW     = WindowType;
  WindowType = 'user';
end



switch lower(METHOD),
 case {'spectrogram'}
  SPC = sub_spectrogram(SIG,WindowType,WINDOW,NFFT);
 case {'fft'}
  SPC = sub_fft(SIG,WindowType,WINDOW,NFFT);
 case {'welch','pwelch'}
  SPC = sub_pwelch(SIG,WindowType,WINDOW,NFFT);
 otherwise
  error(' ERROR %s: METHOD=''%s'' not supported.\n',mfilename);
end


if any(DO_PLOT),
  sub_plot(SPC,SIG,LEG_TXT);
end
  
if nargout > 0,
  varargout{1} = SPC;
  if nargout > 1,
    varargout{2} = SIG;
  end
end

return





function SPC = sub_spectrogram(SIG,WindowType,WINDOW,NFFT)

NWINDOW = length(WINDOW);
OVERLAP = round(NWINDOW*0.5);
Fs      = 1/SIG.dx;

spcdat = [];
for N = size(SIG.dat,2):-1:1,
  tmpdat = double(SIG.dat(:,N));
  % note tmpspc as (f,t)
  %[tmpspc F T] = spectrogram(tmpdat,WINDOW,OVERLAP,NFFT,Fs);
  [tmpspc F] = spectrogram(tmpdat,WINDOW,OVERLAP,NFFT,Fs);
  tmpspc = abs(tmpspc)/NFFT*2;
  spcdat(:,N) = nanmean(tmpspc,2);
end

SPC.dat = spcdat;
SPC.freq = F;
SPC.method  = 'mean-spectrogram';
SPC.window  = WindowType;
SPC.nwindow = NWINDOW;
SPC.overlap = OVERLAP;
SPC.nfft    = NFFT;
SPC.Fs      = Fs;

return


function SPC = sub_fft(SIG,WindowType,WINDOW,NFFT)

NWINDOW = length(WINDOW);
OVERLAP = round(NWINDOW*0.5);
Fs      = 1/SIG.dx;

%F = Fs/2*linspace(0,1,round(NFFT/2));
%tmpsel = 1:round(NFFT/2);

% calculate unshifted frequency vector
dF = Fs/NFFT;
F = (0:(NFFT-1))*dF;
tmpsel = find(F <= Fs/2);

% dF = Fs/NFFT;
% F  = (0:dF:(Fs-dF)) - (Fs-mod(NFFT,2)*dF)/2;
% tmpsel = find(F >= 0);

spcdat = [];
for N = size(SIG.dat,2):-1:1,
  tmpidx = 1:NWINDOW;
  tmpspc = [];
  while tmpidx(end) < size(SIG.dat,1),
    tmpdat = double(SIG.dat(tmpidx,N)).*WINDOW(:);
    tmpfft = fft(tmpdat,NFFT)/NWINDOW;
    %tmpfft = 2*abs(tmpfft(1:round(NFFT/2))); % single sided
    tmpfft = 2*abs(tmpfft(tmpsel)); % single sided
    tmpspc = cat(2,tmpspc,tmpfft);
    tmpidx = tmpidx + (NWINDOW - OVERLAP);
  end
  tmpspc = abs(tmpspc);
  spcdat(:,N) = nanmean(tmpspc,2);
end

F = F(tmpsel);
% take care of DC, Fs/2
tmpi = find(F == 0 | F == Fs/2);
if any(tmpi),  spcdat(tmpi,:) = spcdat(tmpi,:)/2;  end


SPC.dat = spcdat;
SPC.freq = F;
SPC.method = 'mean-fft';
SPC.window  = WindowType;
SPC.nwindow = NWINDOW;
SPC.overlap = OVERLAP;
SPC.nfft    = NFFT;
SPC.Fs      = Fs;

return


function SPC = sub_pwelch(SIG,WindowType,WINDOW,NFFT)

NWINDOW = length(WINDOW);
OVERLAP = round(NWINDOW*0.5);
Fs      = 1/SIG.dx;

spcdat = [];
for N = size(SIG.dat,2):-1:1,
  tmpdat = double(SIG.dat(:,N));
  % note tmpspc as (f,t)
  [Pxx F] = pwelch(tmpdat,WINDOW,OVERLAP,NFFT,Fs);
  tmpspc = sqrt(Pxx);
  spcdat(:,N) = tmpspc(:);
end

SPC.dat = spcdat;
SPC.freq = F;
SPC.method  = 'pwelch';
SPC.window  = WindowType;
SPC.nwindow = NWINDOW;
SPC.overlap = OVERLAP;
SPC.nfft    = NFFT;
SPC.Fs      = Fs;

return



function sub_plot(SPC,SIG,LEG_TXT)

if ~isempty(LEG_TXT),
  legtxt = LEG_TXT;
else
  legtxt = cell(1,size(SPC.dat,2));
  for N = 1:size(SPC.dat,2),
    legtxt{N} = sprintf('Ch%02d',N);
  end
end

figure('Name',sprintf('%s %s',mfilename,datestr(now,'HH:MM:SS')));
pos = get(gcf,'pos');
pos(2) = pos(2)-pos(4);  pos(4) = pos(4)*2;
set(gcf,'pos',pos);

subplot(2,1,1);
idx = find(SPC.freq > 0);
tmpf = SPC.freq(idx);
plot(tmpf,SPC.dat(idx,:));
grid on;  legend(legtxt,'fontsize',8);
set(gca,'xlim',[tmpf(1) tmpf(end)],'layer','top','yscale','log');
xlabel('Frequency in Hz');
ylabel('Amplitude');
title(strrep(sprintf('%s: %s',mfilename,SPC.method),'_','\_'));
tmptxt = sprintf('Fs=%.2fkHz(%gmsec) window=%d(%.2fs,%s) nfft=%d(%.2fs)',...
                 SPC.Fs/1000,1000/SPC.Fs,SPC.nwindow,SPC.nwindow/SPC.Fs,SPC.window,SPC.nfft,SPC.nfft/SPC.Fs);
text(0.02,0.05,tmptxt,'units','normalized');

subplot(2,1,2);
tmpt = (0:size(SIG.dat,1)-1)*SIG.dx;
plot(tmpt,SIG.dat);
grid on;  legend(legtxt,'fontsize',8);
set(gca,'xlim',[0 tmpt(end)],'layer','top');
xlabel('Time in seconds');
ylabel('Amplitude');
%title(strrep(sprintf('Time Course: %s',SPC.filename),'_','\_'));
title('Time Course');
text(0.02,0.05,sprintf('Fs=%.2fkHz(%gmsec)',1.0/SIG.dx/1000,1000*SIG.dx),'units','normalized');

return

