function Sig = getkhindex(Spkt,varargin)
%GETKHINDEX - Compute Sync/Desync index by using Kenneth D. Harris method.
%  Sig = getkhindex(Spkt,...) computes sync/desync index by using Kenneth D. Harris method.
%
%  Supported options are :
%    'bin_width'      :  MUA bin width in msec
%    'kh_smooth'      :  0|1, apply smoothing as in KH's paper (boost towards "sync" state...)
%    'ga_smooth'      :  0|1, apply gaussian smoothing (may boost towards "sync" state...)
%    'ele_site'       :  electrode sites of all channels as a cell array of strings
%    'pack_sites'     :  0|1, to pack the same ele-sites or not
%    'twin_sec'       :  time window for spectrum in sec
%    'nfft'           :  NFFT
%    'tstep_sec'      :  time step/shift in sec
%    'numerator_hz'   :  numerator-frequency as [min max] in hz
%    'denominator_hz' :  denominator-frequency as [min max] in hz
%    'include_dc'     :  0|1, include 0 Hz or not
%    'verbose'        :  0|1
%
%  EXAMPLE :
%    Spkt = sigload('rathm1',4,'Spkt')
%    grp  = getgrp('rathm1',4);
%    Sig = getkhindex(Spkt,'bin_width',0.5,'ele_site',grp.ele.site);
%
%  REFERENCE :
%    - Curto, Sakata, Marguet, Itskov, and Harris  2009
%      The Journal of Neuroscience, 29(34):10600 –10612
%
%  VERSION :
%    0.90 23.10.13 YM  pre-release
%
%  See also spectrogram fconv sesgetkhindex

if nargin == 0,  eval(['help ' mfilename]); return;  end

if iscell(Spkt)
  for N=1:length(Spkt)
    Sig{N} = getkhindex(Spkt{N},varargin{:});
  end
  return
end


% ==========================================================
% OPTIONS :
% ==========================================================
BIN_WIDTH_MS = Spkt.dx(1)*1000;    % MUA bin witdth in msec
DO_KH_SMOOTH = 0;         % apply smoothing as in KH's paper
DO_GA_SMOOTH = 0;         % apply gaussian smoothing
ELE_SITE     = {};        % electrode sites
PACK_SITES   = 1;

TWIN_SEC     = 0.5;       % time window in sec
NFFT         = [];        % NFFT
TSTEP_SEC    = 0.1;       % time step in sec
NUMER_HZ     = [0  5];    % freq. range of numerator
DENOM_HZ     = [0 50];    % freq. range of denominator
INCLUDE_DC   = 0;         % include DC (0Hz)

VERBOSE      = 1;

for N=1:2:length(varargin)
  switch lower(varargin{N}),
   case {'binw' 'binwidth' 'bin_width' 'bin_width_ms'}
    BIN_WIDTH_MS = varargin{N+1};
   case {'khsmooth' 'kh_smooth'}
    DO_KH_SMOOTH = varargin{N+1};
   case {'gasmooth' 'ga_smooth' 'gaussiansmooth' 'gaussian_smooth'}
    DO_GA_SMOOTH = varargin{N+1};
   case {'elesite' 'elesites' 'ele_site' 'ele_sites'}
    ELE_SITE = varargin{N+1};
   case {'packsite' 'packsites' 'pack_site' 'pack_sites'}
    PACK_SITES = varargin{N+1};
   case {'twin' 'twin_sec'}
    TWIN_SEC = varargin{N+1};
   case {'nfft'}
    NFFT = varargin{N+1};
   case {'tstep' 'tstep_sec'}
    TSTEP_SEC = varargin{N+1};
   case {'numerator' 'numerhz' 'numeratorhz' 'numerator_hz'}
    NUMER_HZ = varargin{N+1};
   case {'denominator' 'denomhz' 'denominatorhz' 'denominator_hz'}
    DENOM_HZ = varargin{N+1};
   case {'includedc' 'include_dc'}
    INCLUDE_DC = varargin{N+1};
   case {'verbose'}
    VERBOSE = varargin{N+1};
  end
end

if isempty(ELE_SITE),  PACK_SITES = 0;  end


if VERBOSE, fprintf(' %s:',mfilename);  end


if VERBOSE, fprintf(' bin(%gms).',BIN_WIDTH_MS);  end
if BIN_WIDTH_MS == Spkt.dx(1)*1000,
  Sig = Spkt;
else
  if isfield(Spkt,'times')
    Sig = sub_makehist(Spkt,BIN_WIDTH_MS/1000);
  else
    Sig = siginterp1(Spkt,BIN_WIDTH_MS/1000,'linear');
  end
end
tmpf = {'dsp' 'duration' 'times' 'dt' 'dtorg' 'times_spkcdt' 'usr' 'chan' 'err' 'spkcdt' 'siggetspk'};
for N = 1:length(tmpf)
  if isfield(Sig,tmpf{N}),  Sig = rmfield(Sig,tmpf{N});  end
end

% NOTE : APPLY SMOOTHING AS IN KH'S PAPER,  THIS BOOSTS THE INDEX TOWARDS "1" (ie. SYNC state)....
if any(DO_KH_SMOOTH),
  if VERBOSE, fprintf(' kh_smooth.');  end
  % smoothing by half-hanning window (pre-causality)
  n = round(0.02/Sig.dx(1));  % 20msec
  kdat = hanning(2*n+1);
  kdat = kdat(1:n+1);
  kdat = kdat(:);
  for N = 1:size(Sig.dat,2)
    tmpdat = fconv(Sig.dat(:,N),kdat);
    % should shift forward to match the time, this is pre-causality.
    %newdat(:,N) = tmpdat(end-size(Sig.dat,1)+1:end);
    Sig.dat(:,N) = tmpdat(end-size(Sig.dat,1)+1:end);
  end
  % smoothing by exponential (post-causality)
  ttau = 0.1;  % 100ms tau
  tmpt = 0:Sig.dx(1):0.4;  % 400ms kernel size
  kdat = exp(-tmpt/ttau);
  kdat = kdat(:);
  %kdat = kdat / sum(kdat(:));
  for N = 1:size(Sig.dat,2)
    tmpdat = fconv(Sig.dat(:,N),kdat);
    % should be no shift, this is post-causality.
    %newdat(:,N) = tmpdat(1:size(Sig.dat,1));
    Sig.dat(:,N) = tmpdat(1:size(Sig.dat,1));
  end
end


% NOTE : APPLY GAUSSIAN SMOOTHING,  DEPENDING ON KERNEL-SD, THIS MAY BOOST THE INDEX TOWARDS "1" (ie. SYNC state)....
if any(DO_GA_SMOOTH)
  ksd = 0.015;  % 15ms kernel sd.
  if VERBOSE, fprintf(' ga_smooth(%gms).',ksd*1000);  end
  tmpw = 3*round(ksd/Sig.dx(1));
  tmpt = (-tmpw:tmpw)*Sig.dx(1);
  kdat = exp(-tmpt.^2/(2*ksd*ksd));
  kdat = kdat(:);
  for N = 1:size(Sig.dat,2)
    tmpdat = fconv(Sig.dat(:,N),kdat);
    % should half-shift forward to match the time, the kernel is symmetric.
    %newdat(:,N) = tmpdat(tmpw+1:end-tmpw);
    Sig.dat(:,N) = tmpdat(tmpw+1:end-tmpw);
  end
end


if any(PACK_SITES)
  if VERBOSE, fprintf(' pack_sites.');  end
  Sig = sub_pack_site(Sig,ELE_SITE);
else
  Sig.ele_site = ELE_SITE;
end

WINDOW = round(TWIN_SEC/Sig.dx(1));
if isempty(NFFT),
  NFFT   = WINDOW;
end
NOVERLAP = WINDOW - round(TSTEP_SEC/Sig.dx(1));


if VERBOSE, fprintf(' spect[%g %g]/[%g %g].',NUMER_HZ(1),NUMER_HZ(2),DENOM_HZ(1),DENOM_HZ(2));  end
TKIND = [];
for N = 1:size(Sig.dat,2)
  [tmpspc,F,T] = spectrogram(Sig.dat(:,N),WINDOW,NOVERLAP,NFFT,1/Sig.dx(1));
  
  tmpspc = tmpspc.*conj(tmpspc);  % power
  % tmpspc = abs(tmpspc);         % amplitude 
  
  if INCLUDE_DC
    idx_numer = (F >= NUMER_HZ(1) & F <= NUMER_HZ(2));
    idx_denom = (F >= DENOM_HZ(1) & F <= DENOM_HZ(2));
  else
    idx_numer = (F >= NUMER_HZ(1) & F <= NUMER_HZ(2) & F ~= 0);
    idx_denom = (F >= DENOM_HZ(1) & F <= DENOM_HZ(2) & F ~= 0);
  end
  
  if isempty(TKIND)
    TKIND = zeros(length(tmpspc),size(Sig.dat,2));
  end

  % tmpspc as (f,t)
  tmpdenom = sum(tmpspc(idx_denom,:),1);
  tmpnumer = sum(tmpspc(idx_numer,:),1);

  % avoid divided-by-zero
  tmpidx = (tmpdenom == 0);
  tmpdenom(tmpidx) = 1;
  tmpnumer(tmpidx) = 0;
  
  TKIND(:,N) = (tmpnumer./tmpdenom)';  % TKIND as (t,chan)
end

Sig.dat = TKIND;
Sig.dx  = T(2)-T(1);
Sig.t   = T;
if isfield(Sig,'dxorg')
  Sig.dxorg = Sig.dx / Spkt.dx * Spkt.dxorg;
end
if isfield(Sig,'dir')
  Sig.dir.dname = 'tkind';
end


Sig.(mfilename).bin_width_ms   = BIN_WIDTH_MS;
Sig.(mfilename).kh_smooth      = DO_KH_SMOOTH;
Sig.(mfilename).ga_smooth      = DO_GA_SMOOTH;
Sig.(mfilename).pack_sites     = PACK_SITES;
Sig.(mfilename).twin_sec       = TWIN_SEC;
Sig.(mfilename).nfft           = NFFT;
Sig.(mfilename).numerator_hz   = NUMER_HZ;
Sig.(mfilename).denominator_hz = DENOM_HZ;
Sig.(mfilename).include_dc     = INCLUDE_DC;


if VERBOSE, fprintf('  done.\n');  end

return


% ===================================================
% make spike histgram, copied from siggetspk()
function Spkt = sub_makehist(Spkt,BINW_SEC)
% ===================================================
if isfield(Spkt,'duration') && isfield(Spkt,'dt')
  % Spkt as 'Spkt'
  tlen_sec = Spkt.duration * Spkt.dt;
else
  tlen_sec = size(Spkt.dat,1)*Spkt.dx(1);
end

EDGES = 0:BINW_SEC:(tlen_sec + BINW_SEC/2);
EDGES = EDGES/Spkt.dt;  % in points

Spkt.dat = zeros(length(EDGES),size(Spkt.times,1),size(Spkt.times,2));
for iChan = 1:size(Spkt.times,1),
  for iObsp = 1:size(Spkt.times,2),
    % 22.12.04 YM: simple use of hist with NBINS will not give correct histgram.
	%[n,x] = hist(Spkt.times{iChan,iObsp},NBINS);
    if isempty(Spkt.times{iChan,iObsp}),  continue;  end
	n = histc(Spkt.times{iChan,iObsp},EDGES);
	Spkt.dat(:,iChan,iObsp) = n;
  end
end

NEWDX = (EDGES(2)-EDGES(1))*Spkt.dt;
if isfield(Spkt,'dxorg'),
  Spkt.dxorg = NEWDX / Spkt.dx * Spkt.dxorg;
end
Spkt.dx = NEWDX;

return



% ===================================================
% pack the same sites
function Sig = sub_pack_site(Sig,ELE_SITE)
% ===================================================

usite = sort(unique(ELE_SITE));

NEWDAT = zeros(size(Sig.dat,1),length(usite));

for N = 1:length(usite)
  tmpidx = find(strcmpi(ELE_SITE, usite{N}) == 1);
  NEWDAT(:,N) = sum(Sig.dat(:,tmpidx),2);
end

Sig.dat = NEWDAT;
Sig.ele_site = usite;

return
