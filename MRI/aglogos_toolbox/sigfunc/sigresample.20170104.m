function oSig = sigresample(Sig,NEWDX,varargin)
%SIGRESAMPLE - resamples the signal.
%  oSig = sigresample(Sig,NEWDX,...) resamples the signal with NEWDX.
%  The program assumes the 1st dimension as time series.
%
%  EXAMPLE :
%    >> oSig = sigresample(Sig,Sig.dx/2,'USE_FIR',0,'SAVE_MEMORY',1);
%
%  NOTE :
%    Sig.dat must be (t,...)
%
%  OPTIONAL SETTINGS
%    SAVE_MEMORY    : do resamping one by one to save memory (default=0)
%    MIRROR_EDGES   : minimize unstable periods in both time edges (default=1)
%    USE_FIR        : flag to use FIR filter for resampling (default=0)
%    FIR_passripple : FIR filter: passripple  (default=0.1)
%    FIR_dB         : FIR filter: dB (default=60)
%    FIR_transband  : FIR filter: transband in Hz (default=(1/NEWDX)*0.008)
%    RAT_TOLERANCE  : torelance for rat()  (default=0.0001);
%    LENGTH_PTS     : trancate/zero-pad data to the given length (in points)
%
%  VERSION :
%    0.90 29.11.07 YM  pre-release
%    0.91 21.04.08 YM  bug fix on oSig.dx
%    0.92 05.06.08 YM  support RAT_TOL
%    0.93 22.12.10 YM  support LENGTH_PTS
%
%  See also resample siginterp1 siggetblp

if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end

if iscell(Sig),
  for N = 1:length(Sig),
    oSig{N} = sigresample(Sig{N},NEWDX,varargin{:});
  end
  return
end

% if NEWDX == Sig.dx,  no need to do resampling.
if NEWDX == Sig.dx,  oSig = Sig;  return;  end


% DEFAULT CONTROL SETTINGS
SAVE_MEMORY    = 0;     % do resamping one by one to save memory
MIRROR_EDGES   = 1;     % minimize unstable periods in both time edges
USE_FIR        = 0;     % flag to use FIR filter for resampling
FIR_passripple = 0.1;   % FIR filter: passripple
FIR_dB         = 60;    % FIR filter: dB
FIR_transband  = [];    % FIR filter: transband in Hz
RAT_TOL        = 0.0001;
LENGTH_PTS     = [];
DATA_FIELD     = 'dat';

% UPDATE OPTIONAL SETTINGS
for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'dat'}
    DATA_FIELD = varargin{N+1};
   case {'save_memory','savememory'}
    SAVE_MEMORY = varargin{N+1};
   case {'mirror_edges','mirroredges','mirror'}
    MIRROR_EDGES = varargin{N+1};
   case {'use_fir','usefir','fir'}
    USE_FIR = varargin{N+1};
   case {'fir_passripple','firpassripple','passripple'};
    FIR_passripple = varargin{N+1};
   case {'fir_db','firdb','db'}
    FIR_dB = varargin{N+1};
   case {'fir_transband','firtransband','transband'}
    FIR_transband = varargin{N+1};
   case {'rat_tol','rattol','rat_tolerance'}
    RAT_TOL = varargin{N+1};
   case {'length_pts','len','length'}
    LENGTH_PTS = varargin{N+1};
  end
end


[p,q] = rat(Sig.dx/NEWDX,RAT_TOL);
oSig = Sig;
oSig.(DATA_FIELD) = [];
if isfield(Sig,'dxorg'),
  oSig.dxorg = Sig.dxorg/Sig.dx*NEWDX;
end
oSig.dx  = NEWDX;
oSig.dx = Sig.dx*q/p; % corrected by 'p' and 'q'

if USE_FIR > 0,
  %NewFs = 1/NEWDX;
  NewFs = 1/oSig.dx;
  if isempty(FIR_transband),
    FIR_transband = NewFs * 0.008; % 60dB decay width for above resampling
  end
  fsamp = p/Sig.dx;  %note: freq of RESAMPLED signal!
  fcuts = [NewFs/2-FIR_transband NewFs/2]; %we want cutoff to start transband before nyquist
  mags = [1 0];
  devs = [abs(1-10^(FIR_passripple/20)) 10^(-FIR_dB/20)];
  [n,Wn,beta,ftype] = kaiserord(fcuts,mags,devs,fsamp);
  n = n + rem(n,2);
  b = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');
  
  % for compatibility of siggetblp()
  %offset due to filtering in sec
  if isfield(oSig,'fltcutoff'),
    oSig.fltcutoff = oSig.fltcutoff+length(b)/fsamp; 
  else
    oSig.fltcutoff = length(b)/fsamp; 
  end;
  clear mags devs fsamp n Wn beta ftype;
end

% reshape Sig.(DATA_FIELD) from (t,a,b,c...) to 2D (t,abc...)
szdat = size(Sig.(DATA_FIELD));
Sig.(DATA_FIELD)  = reshape(Sig.(DATA_FIELD),[szdat(1) prod(szdat(2:end))]);
SINGLE_FLAG=0;
if isa(Sig.(DATA_FIELD),'single'),
  SINGLE_FLAG=1;
  Sig.(DATA_FIELD) = double(Sig.(DATA_FIELD));
end;

if USE_FIR > 0,
  if MIRROR_EDGES > 0,
    pqmax = max(p,q);
    %Ly = ceil(Lx*p/q);  % output length, from resample.m
    siglen = ceil(size(Sig.(DATA_FIELD),1)*p/q);
    %siglen = length(resample(double(Sig.(DATA_FIELD)(:,1)),p,q,b));

    mirror = ceil(length(b)/pqmax)*pqmax;
    idxmir = [mirror+1:-1:2 1:size(Sig.(DATA_FIELD),1) size(Sig.(DATA_FIELD),1)-1:-1:size(Sig.(DATA_FIELD),1)-mirror-1];
    idxsel = (1:siglen) + round(mirror*p/q);
    if SAVE_MEMORY > 0,
      for N = size(Sig.(DATA_FIELD),2):-1:1,
        datmir = resample(Sig.(DATA_FIELD)(idxmir,N),p,q,b);
        oSig.(DATA_FIELD)(:,N) = datmir(idxsel);
      end
    else
      datmir = resample(Sig.(DATA_FIELD)(idxmir,:),p,q,b);
      oSig.(DATA_FIELD) = datmir(idxsel,:);
    end
  else
    if SAVE_MEMORY > 0,
      for N = size(Sig.(DATA_FIELD),2):-1:1,
        oSig.(DATA_FIELD)(:,N) = resample(Sig.(DATA_FIELD)(:,N),p,q,b);
      end
    else
      oSig.(DATA_FIELD) = resample(Sig.(DATA_FIELD),p,q,b);
    end
  end
else
  if MIRROR_EDGES > 0,
    % NOTE :
    % resample() will use firls with a Kaise window as default.
    % followig code was taken from Matlab's resample() function.
    bta = 5;    N = 10;     pqmax = max(p,q);
    if( N>0 )
      fc = 1/2/pqmax;
      L = 2*N*pqmax + 1;
      h = p*firls( L-1, [0 2*fc 2*fc 1], [1 1 0 0]).*kaiser(L,bta)' ;
      % h = p*fir1( L-1, 2*fc, kaiser(L,bta)) ;
    else
      L = p;
      h = ones(1,p);
    end
    %Ly = ceil(Lx*p/q);  % output length, from resample.m
    siglen = ceil(size(Sig.(DATA_FIELD),1)*p/q);
    %siglen = length(resample(double(Sig.(DATA_FIELD)(:,1)),p,q));
    mirror = ceil(length(h)/pqmax)*pqmax;
    if size(Sig.(DATA_FIELD),1) <= mirror,
      mirror = round(size(Sig.(DATA_FIELD),1)/2);
    end
    idxmir = [mirror+1:-1:2 1:size(Sig.(DATA_FIELD),1) size(Sig.(DATA_FIELD),1)-1:-1:size(Sig.(DATA_FIELD),1)-mirror-1];
    idxsel = (1:siglen) + round(mirror*p/q);
    if SAVE_MEMORY > 0,
      for N = size(Sig.(DATA_FIELD),2):-1:1,
        datmir = resample(Sig.(DATA_FIELD)(idxmir,N),p,q);
        oSig.(DATA_FIELD)(:,N) = datmir(idxsel);
      end
    else
      datmir = resample(Sig.(DATA_FIELD)(idxmir,:),p,q);
      oSig.(DATA_FIELD) = datmir(idxsel,:);
    end
  else
    if SAVE_MEMORY,
      for N = size(Sig.(DATA_FIELD),2):-1:1,
        oSig.(DATA_FIELD)(:,N) = resample(Sig.(DATA_FIELD)(:,N),p,q);
      end
    else
      oSig.(DATA_FIELD) = resample(Sig.(DATA_FIELD),p,q);
    end
  end
end


if any(LENGTH_PTS),
  if size(oSig.(DATA_FIELD),1) > LENGTH_PTS,
    oSig.(DATA_FIELD) = oSig.(DATA_FIELD)(1:LENGTH_PTS,:);
  elseif size(oSig.(DATA_FIELD),1) < LENGTH_PTS,
    oSig.(DATA_FIELD)(end+1:LENGTH_PTS,:) = 0;
  end
end

% recover the original dimension for oSig.(DATA_FIELD)
szdat(1) = size(oSig.(DATA_FIELD),1);
oSig.(DATA_FIELD) = reshape(oSig.(DATA_FIELD),szdat);
if SINGLE_FLAG,
  oSig.(DATA_FIELD) = single(oSig.(DATA_FIELD));
end;

% store some information
oSig.(mfilename).date           = date;
oSig.(mfilename).time           = datestr(now,'HH:MM:SS');
oSig.(mfilename).save_memory    = SAVE_MEMORY;
oSig.(mfilename).mirroe_edges   = MIRROR_EDGES;
oSig.(mfilename).use_fir        = USE_FIR;
oSig.(mfilename).fir_passripple = FIR_passripple;
oSig.(mfilename).fir_db         = FIR_dB;
oSig.(mfilename).fir_transband  = FIR_transband;

if isfield(oSig,'t'),
  oSig.t = gettimebase(oSig);
  if isfield(oSig,'win'),  oSig.t = oSig.t + oSig.win(1); end;
  if isfield(oSig,'WIN'),  oSig.t = oSig.t + oSig.WIN(1); end;
end;

return
