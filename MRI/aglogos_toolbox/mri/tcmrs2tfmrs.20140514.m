function tfMrs = tcmrs2tfmrs(varargin)
%TCMRS2TFMRS - Convert "tcMrs" signal (complex) into time-freq MRS (tfMrs).
%  tfMrs = TCMRS2TFMRS(Ses,ExpNo,...)
%  tfMrs = TCMRS2TFMRS(tcMrs,...)  converts "tcMrs" signal (complex) into time-freq MRS (tfMrs).
%
%  Supported options are :
%    'method'   : a string of method, 'fft' | 'pwelch'
%    'window'   : window type, 'none'
%    'nfft'     : a number of FFT points
%    'nskip'    : skip leading data points
%    'pack2blp' : pack data like blp
%    'band'     : band information to pack, a cell array of { {[range] 'name'} ...}
%      
%  Parameters can be set in the session file as
%  ANAP.tcmrs2tfmrs or GRP.(xx).anap.tcmrs2tfmrs.
%    ANAP.tcmrs2tfmrs.method   = 'fft';   % a string of method, 'fft' | 'pwelch'
%    ANAP.tcmrs2tfmrs.window   = 'none';  % window type, 'none'
%    ANAP.tcmrs2tfmrs.nfft     = 256;     % a number of FFT points
%    ANAP.tcmrs2tfmrs.nskip    = 69;      % skip leading data points
%    ANAP.tcmrs2tfmrs.pack2blp = 0;       % pack data like blp
%    ANAP.tcmrs2tfmrs.band     = {};      % band information to pack, a cell array of { {[range] 'name'} ...}
%
%  EXAMPLE :
%    tfMrs = tcmrs2tfmrs('ratpe2',1)
%    tfMrs = 
%         session: 'ratpe2'
%         grpname: 'spont'
%           ExpNo: 1
%             dir: [1x1 struct]
%             dat: [8000x1x84 double]   <=== (time,vox,freq/band)
%              ds: [1.5000 1.5000 1.5000]
%              dx: 0.0828
%            freq: [1x84 double]
%     tcmrs2tfmrs: [1x1 struct]
%
%  EXAMPLE :
%    tcMrs = sigload('ratpe2',1,'tcMrs');
%    tfMrs = tcmrs2tfmrs(tcMrs);
%
%  VERSION :
%    0.90 13.05.14 YM  pre-release
%
%  See also sestfmrs imgload_spectroscopy sigspectrum

if nargin < 1,  eval(['help ' mfilename]); return;  end


if issig(varargin{1})
  % called like tcmrs2tfmrs(tcMrs,...)
  tcMrs = varargin{1};
  Ses = getses(tcMrs.session);
  grp  = getgrp(Ses,tcMrs.grpname);
  iopt = 2;
else
  % called like tcmrs2tfmrs(Ses,ExpNo,...)
  tcMrs = [];
  Ses = getses(varargin{1});
  ExpNo = varargin{2};
  grp = getgrp(Ses,ExpNo);
  iopt = 3;
end


% ANALYSIS OPTIONS 
METHOD     = 'pwelch';
WindowType = 'none';
NFFT       = [];
Nskip      = 0;
Pack2blp   = 0;
Bands      = {};
DoSave     = 0;
VERBOSE    = 1;

anap = getanap(Ses,grp);
if isfield(anap,'siggetblp')
  if isfield(anap.siggetblp,'band')
    Bands = cell(1,length(anap.siggetblp.band));
    for N = 1:length(anap.siggetblp.band),
      Bands{N} = anap.siggetblp.band{N}(1:2);  % as { [freq-range], name }
    end
  end
end
if isfield(anap,'tcmrs2tfmrs')
  if isfield(anap.tcmrs2tfmrs,'method')
    METHOD = anap.tcmrs2tfmrs.method;
  end
  if isfield(anap.tcmrs2tfmrs,'window')
    WindowType = anap.tcmrs2tfmrs.widow;
  end
  if isfield(anap.tcmrs2tfmrs,'nfft')
    NFFT = anap.tcmrs2tfmrs.nfft;
  end
  if isfield(anap.tcmrs2tfmrs,'nskip')
    Nskip = anap.tcmrs2tfmrs.nskip;
  end
  if isfield(anap.tcmrs2tfmrs,'pack2blp')
    Pack2blp = anap.tcmrs2tfmrs.pack2blp;
  end
  if isfield(anap.tcmrs2tfmrs,'band')
    Bands = anap.tcmrs2tfmrs.band;
  end
end

for N = iopt:2:length(varargin)
  switch lower(varargin{N})
   case {'method'}
    METHOD = varargin{N+1};
   case {'window'}
    WindowType = varargin{N+1};
   case {'nfft'}
    NFFT = varargin{N+1};
   case {'nskip'}
    Nskip = varargin{N+1};
   case {'pack2blp'}
    Pack2blp = varargin{N+1};
   case {'bands' 'band'}
    Bands = varargin{N+1};
   case {'save'}
    DoSave = varargin{N+1};
   case {'verbose'}
    VERBOSE = varargin{N+1};
  end
end


if VERBOSE,  fprintf(' %s:',mfilename);  end


if isempty(tcMrs)
  if VERBOSE,  fprintf(' loading tcMrs.');  end
  tcMrs = sigload(Ses,ExpNo,'tcMrs');
end

datsz = size(tcMrs.dat);
tcMrs.dat = reshape(tcMrs.dat,[datsz(1) prod(datsz(2:end))]);

if any(Nskip)
  tcMrs.dat = tcMrs.dat(Nskip+1:end,:);
  datsz(1) = size(tcMrs.dat,1);
end

if ~any(NFFT)
  NFFT = size(tcMrs.dat,1);
end


% WINDOW
if isempty(WindowType),  WindowType = 'hamming';  end
WindowSize = size(tcMrs.dat,1);
if ischar(WindowType),
  switch lower(WindowType),
   case {'ones','none'}
    WINDOW = ones(WindowSize,1);
    WindowType = 'none';
   case {'hanning','hann'}
    WINDOW = hann(WindowSize);  % Hanning window
   case {'hamming'}
    WINDOW = hamming(WindowSize);  % Hamming window
   case {'blackman'}
    WINDOW = blackman(WindowSize);  %  Blackman window
   case {'kaiser'}
    WINDOW = kaiser(WindowSize);
   case {'blackmanharris'}
    WINDOW = blackmanharris(WindowSize);
  end
else
  WINDOW     = WindowType;
  WindowType = 'user';
end

Fs = 1/tcMrs.tspect;
switch lower(METHOD),
 case {'fft'}
  if VERBOSE,  fprintf(' %s(nfft=%d,win=%s).',METHOD,NFFT,WindowType);  end

  if isempty(WINDOW) || all(WINDOW(:) == 1),
  else
    tmpwin = repmat(WINDOW(:),[1 size(tcMrs.dat,2)]);
    tcMrs.dat = tcMrs.dat .* tmpwin;
    clear tmpwin;
  end

  %F = Fs/2*linspace(0,1,round(NFFT/2));
  %tmpsel = 1:round(NFFT/2);

  % calculate unshifted frequency vector
  dF = Fs/NFFT;
  F = (0:(NFFT-1))*dF;
  tmpsel = find(F <= Fs/2);

  % dF = Fs/NFFT;
  % F  = (0:dF:(Fs-dF)) - (Fs-mod(NFFT,2)*dF)/2;
  % tmpsel = find(F >= 0);

  SPC = fft(tcMrs.dat,NFFT)/size(tcMrs.dat,1);
  
  % single-sided spectrum
  SPC = SPC(tmpsel,:);
  F = F(tmpsel);
  %PHASE = unwrap(angle(SPC),[],1); % unwrap along "freq"
  %PHASE = unwrap(angle(SPC),[],2); % unwrap along "time"
  PHASE = angle(SPC);
  SPC   = 2*abs(SPC);  % single-sided
  % take care of DC and Fs/2
  tmpi = find(F == 0 | F == Fs/2);
  if any(tmpi),
    SPC(tmpi,:) = SPC(tmpi,:)/2;
  end
  
  SPC = SPC.*SPC;  % power instead of amplitude
  
 case {'welch','pwelch'}
  METHOD = 'pwelch';        % Just in case that selection was done with "welch"
  WINDOW = [];
  WindowType = 'none';
 
  %NWINDOW  = round(size(tcMrs.dat,1)*0.75);
  %NOVERLAP = round(NWINDOW*0.25);
  
  if VERBOSE,  fprintf(' %s(nfft=%d,win=%s).',METHOD,NFFT,WindowType);  end
  SPC = [];
  for N = size(tcMrs.dat,2):-1:1,
    [Pxx, F] = pwelch(tcMrs.dat(:,N),WINDOW,[],NFFT,Fs);
    SPC(:,N) = Pxx(:);
  end
  % SPC = sqrt(SPC); % power-->amplitude
  % NKL, 14.05.14 (better power rather amplitude)
  tmpsel = find(F <= Fs/2);
  SPC = SPC(tmpsel,:);
  F = F(tmpsel);
  PHASE = [];
  
 otherwise
  error(' ERROR %s: METHOD=''%s'' not supported.\n',mfilename);
end

if VERBOSE,  fprintf(' F=[%g %g]/dF=%gHz.',F(1),F(end),F(2)-F(1));  end

tcMrs.dat = reshape(tcMrs.dat,datsz);

datsz(1) = size(SPC,1);
SPC = reshape(SPC,datsz);    % as (f,vox,time)
SPC = permute(SPC,[3 2 1]);  % as (time,vox,f)
if ~isempty(PHASE),
  PHASE = reshape(PHASE,datsz);    % as (f,vox,time)
  PHASE = permute(PHASE,[3 2 1]);  % as (time,vox,f)
end;

tfMrs.session = tcMrs.session;
tfMrs.grpname = tcMrs.grpname;
tfMrs.ExpNo   = tcMrs.ExpNo;
tfMrs.dir.dname = 'tfMrs';
tfMrs.dat     = SPC;
tfMrs.phase   = PHASE;
tfMrs.ds      = tcMrs.ds;
tfMrs.dx      = tcMrs.dx;
tfMrs.freq    = F;

tfMrs.(mfilename).method   = METHOD;
tfMrs.(mfilename).window   = WindowType;
tfMrs.(mfilename).nfft     = NFFT;
tfMrs.(mfilename).nskip    = Nskip;
tfMrs.(mfilename).pack2blp = Pack2blp;

clear tcMrs;

if any(Pack2blp)
  if VERBOSE,  fprintf(' pack2blp(%d).',length(Bands));  end
  tfMrs = sub_pack2blp(tfMrs,Bands);
end

if VERBOSE,  fprintf('  done.\n');  end

if any(DoSave) && exist('ExpNo','var'),
  sigsave(Ses,ExpNo,'tfMrs',tfMrs);
end

return


% --------------------------------------------------
function blp = sub_pack2blp(tfMrs,Bands)
% --------------------------------------------------

fmax = max(tfMrs.freq);
for N = 1:length(Bands),
  tmpf = Bands{N}{1};
  tmpf(tmpf > fmax) = fmax;
  Bands{N}{1} = tmpf;
end

blp = tfMrs;
blp.freq = Bands;

datsz = size(tfMrs.dat);
datsz(3) = length(Bands);
blp.dat = zeros(datsz,class(tfMrs.dat));

for N = 1:length(Bands),
  tmpf = Bands{N}{1};
  tmpi = find(tfMrs.freq >= tmpf(1) & tfMrs.freq <= tmpf(2));
  if any(tmpi),
    blp.dat(:,:,N) = nanmean(tfMrs.dat(:,:,tmpi),3);
  end
end

return

  
