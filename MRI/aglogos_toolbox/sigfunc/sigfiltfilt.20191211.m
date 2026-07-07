function oSig = sigfiltfilt(Sig,arg1,arg2,varargin)
%SIGFILTFILT - Zero-phase digital filtering.
%  SIGFILTFILT(Sig,BandHz,fType,...) does zero-phase digital filtering.
%  Type can be 'lowpass','bandpass','highpass','stop','notch'.
%  SIGFILTFILT(Sig,b,a,...) does zero-phase digital filtering with
%  given b and a.
%
%  Available options are
%    'save_memory'    : 0|1, if 1, process by for-loop
%    'mirror'         : 0|1, mirror edges to avoid transients at both edges
%    'mirror_sec'     : >=0, mirroring window in sec
%    'filter'         : 'butter' 'cheby1' 'cheby2' for low/band/high-pass filter
%                     : 'iirnotch' 'iirpeak' 'iircomb' for notch/peak filter
%    'order'          : filter order for butter/cheby1/cheby2/iircomb
%    'fir_passripple' : FIR filter: passripple
%    'fir_dB'         : FIR filter: dB
%    'fir_transband'  : FIR filter: transband in Hz
%    'iir_q'          : IIR filter (notch/peak) filter: Q factor, Q=w0/BW
%    'iir_bwhz'       : IIR filter (notch/peak) filter: band-width in Hz, Q=w0/BW
%    'iir_dB'         : IIR filter (notch/peak) filter: dB
%    'keep_DC'        : 0|1, keep DC component or not
%    'field'          : field(data) name to process (default as 'dat')
%
%  EXAMPLE :
%    sig = sigfiltfilt(sig, [5 20], 'bandpass');
%    sig = sigfiltfilt(sig, 50,     'notch', 'iir_q', 100);
%
%  VERSION :
%    0.90 03.12.09 YM  modified from cdata/filtfilt.m
%    0.91 22.10.10 YM  treat NaN as 0.
%    0.92 09.12.11 YM  bug fix of KEEP_DC when 'lowpass'.
%    0.93 12.09.13 YM  supports 'notch' as 'fType'.
%    0.94 27.11.13 YM  use bsxfun() for better performance.
%    0.95 14.04.16 YM  supports 'mirror_sec'.
%
%  See also filtfilt butter cheby1 cheby2 iirnotch iirpeak iircomb

if nargin < 2,  help sigfiltfilt; return;  end
if nargin < 3,  arg2 = '';  end

if iscell(Sig),
  for N = 1:numel(Sig),
    oSig{N} = sigfiltfilt(Sig{N},arg1,arg2,varargin{:});
  end
  return
end

% DEFAULT CONTROL SETTINGS
SAVE_MEMORY    = 0;         % do resamping one by one to save memory
MIRROR_EDGES   = 1;         % minimize unstable periods in both time edges
MIRROR_SEC     = 0;         % mirroring window in sec, if 0, max(length(b),length(a)).
FILTER_NAME    = 'butter';  % filter name
FILTER_ORDER   = 4;         % filter order
% for FIR filter:
FIR_passripple = 0.1;       % FIR filter: passripple
FIR_dB         = 60;        % FIR filter: dB
FIR_transband  = [];        % FIR filter: transband in Hz
% for IIR filter (notch/peak):
IIR_Q          = 35;        % IIR (notch/peak) filter: Q factor
IIR_BW_HZ      = [];        % IIR (notch/peak) filter: band-width in Hz
IIR_dB         = [];        % IIR (notch/peak) filter: dB

KEEP_DC        = 0;
DATAFIELD      = 'dat';

% UPDATE OPTIONAL SETTINGS
for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'field' 'datfield' 'datafield' 'dat' 'data'},
    DATAFIELD = varargin{N+1};
   case {'save_memory','savememory'}
    SAVE_MEMORY = varargin{N+1};
   case {'mirror_edges','mirroredges','mirror'}
    MIRROR_EDGES = varargin{N+1};
   case {'mirror_sec' 'mirrorsec'}
    MIRROR_SEC   = varargin{N+1};
   case {'filter','filtername','filter_name'}
    FILTER_NAME = varargin{N+1};
   case {'order','filterorder','filter_order','forder'}
    FILTER_ORDER = varargin{N+1};
   case {'use_fir','usefir','fir'}
    if varargin{N+1} > 0,
      FILTER_NAME = 'fir';
    end
   case {'fir_passripple','firpassripple','passripple'};
    FIR_passripple = varargin{N+1};
   case {'fir_db','firdb','db'}
    FIR_dB = varargin{N+1};
   case {'fir_transband','firtransband','transband'}
    FIR_transband = varargin{N+1};
   case {'iir_q' 'iirq'}
    IIR_Q = varargin{N+1};
   case {'iir_bw_hz' 'iir_bwhz' 'iirbwhz'}
    IIR_BW_HZ = varargin{N+1};
   case {'iir_db' 'iirdb'}
    IIR_dB = varargin{N+1};
   
   case {'keep_dc','keepdc','keep dc', 'dc'}
    KEEP_DC = varargin{N+1};
  end
end

if isempty(Sig.(DATAFIELD)),
  oSig = Sig;
  return
end

USE_FIR = 0;
if ischar(arg2),
  % called like sigfiltfilt(Sig,BandHz,fType)
  nyqf   = (1/Sig.dx(1))/2;
  bandHz = arg1;
  ftype  = arg2;
  switch lower(ftype),
   case {'low','lowpass','lp','l'}
    ftype = 'low';
   case {'high','highpass','hp','h'}
    ftype = 'high';
   case {'band','bandpass','bp','b'}
    ftype = 'bandpass';
   case {'stop','bandstop','stopband'}
    ftype = 'stop';
   case {'notch'}
    if ~strcmpi(FILTER_NAME,'iircomb'),
      FILTER_NAME = 'iirnotch';  FILTER_ORDER = 2;
    end
   case {'peak'}
    if ~strcmpi(FILTER_NAME,'iircomb'),
      FILTER_NAME = 'iirpeak';  FILTER_ORDER = 2;
    end
   case {'iirnotch'}
    FILTER_NAME = 'iirnotch';  FILTER_ORDER = 2;
   case {'iirpeak'}
    FILTER_NAME = 'iirpeak';  FILTER_ORDER = 2;
   case {'iircomb-notch' 'notch-iircomb' 'iircombnotch'}
    ftype = 'notch';  FILTER_NAME = 'iircomb';
   case {'iircomb-peak' 'peak-iircomb' 'iircombpeak'}
    ftype = 'peak';   FILTER_NAME = 'iircomb';

   otherwise
    if length(bandHz) == 2,
      if bandHz(1) == 0 && bandHz(2) > 0,
        ftype = 'low';
        bandHz = bandHz(2);
      elseif bandHz(1) > 0 && bandHz(2) == 0,
        ftype = 'high';
        bandHz = bandHz(1);
      elseif all(bandHz > 0),
        ftype = 'bandpass';
      else
      error(' ERROR %s: ftype=''%s'' not supported.\n',mfilename,ftype);
      end
    else
      error(' ERROR %s: ftype=''%s'' not supported.\n',mfilename,ftype);
    end
  end

  if all(bandHz > nyqf),
    fprintf('\n WARNING %s: frequency[%s] out of range, nyqf=%gHz, skipped.\n',...
            mfilename,deblank(sprintf('%g ',bandHz)),nyqf);
    return
  end
  
  % check bands with nyqf.
  if strcmpi(ftype,'bandpass') && length(bandHz) > 1,
    if bandHz(2) > nyqf,
      fprintf('\n WARNING %s: band[%s] out of range, nyqf=%gHz, applying highpass only.\n',...
              mfilename,deblank(sprintf('%g ',bandHz)),nyqf);
      ftype = 'high';
      bandHz = bandHz(1);
    end
  end
  
  % ok, make b/a values for filtfilt().
  switch lower(FILTER_NAME),
   case {'butter','butterworth'}
    [b,a] = butter(FILTER_ORDER, bandHz/nyqf, ftype);
   case {'cheby1','chebyshev1'}
    [b a] = cheby1(FILTER_ORDER, 0.01, bandHz/nyqf, ftype);
   case {'cheby2','chebyshev2'}
    [b a] = cheby2(FILTER_ORDER, 20, bandHz/nyqf, ftype);
   case {'fir'}
    [b,a] = designfir(nyqf*2, bandHz, ftype,...
                      'passripple',FIR_passripple,'dB',FIR_dB,'transband',FIR_transband);
    USE_FIR = 1;
   
   case {'iirnotch'}
    w0 = bandHz(1)/nyqf;
    bw = IIR_BW_HZ/nyqf;
    if isempty(bw),  bw = w0/IIR_Q;  end
    if any(IIR_dB)
      [b a] = iirnotch(w0,bw,IIR_dB);
    else
      [b a] = iirnotch(w0,bw);
    end
   case {'iirpeak'}
    w0 = bandHz(1)/nyqf;
    bw = IIR_BW_HZ/nyqf;
    if isempty(bw),  bw = w0/IIR_Q;  end
    if any(IIR_dB)
      [b a] = iirpeak(w0,bw,IIR_dB);
    else
      [b a] = iirpeak(w0,bw);
    end
   case {'iircomb'}
    w0 = bandHz(1)/nyqf;
    bw = IIR_BW_HZ/nyqf;
    if isempty(bw),  bw = w0/IIR_Q;  end
    if any(IIR_dB)
      [b a] = iircomb(FILTER_ORDER, bw, IIR_dB, ftype);
    else
      [b a] = iircomb(FILTER_ORDER, bw, ftype);
    end
    
   otherwise
    error(' ERROR %s: ''%s'' not supported.\n',mfilename,FILTER_NAME);
  end
  
  if strcmpi(ftype,'low'),  KEEP_DC = 0;  end
else
  % called like sigfiltfilt(Sig,b,a)
  b = arg1;
  a = arg2;
end

% make (t,a,b,c,...) as (t,abc)

orgdat = Sig.(DATAFIELD);
tmpsz = size(orgdat);
orgdat = reshape(orgdat,[tmpsz(1) prod(tmpsz(2:end))]);

if KEEP_DC > 0,
  dcval = nanmean(orgdat,1);
end

orgdat(isnan(orgdat(:))) = 0;


if USE_FIR > 0,
  if MIRROR_EDGES > 0,
    mirror = max([length(b),length(a)]);
    if any(MIRROR_SEC) && MIRROR_SEC > 0,
      mirror = max([mirror, round(MIRROR_SEC/Sig.dx(1))]);
    end
  
	idxmir = [mirror+1:-1:2 1:size(orgdat,1) size(orgdat,1)-1:-1:size(orgdat,1)-mirror-1];
	% JUST TESTING
	%idxsel = (1:size(orgdat,1)) + (mirror + round(mirror/2) - 1);
	idxsel = (1:size(orgdat,1)) + mirror;
	if SAVE_MEMORY > 0,
	  if strcmpi(class(orgdat),'single'),
		for N = size(orgdat,2):-1:1,
		  datmir = s_filter(double(orgdat(idxmir,N)),b);
		  datmir = datmir(size(datmir,1):-1:1,:);
		  datmir = s_filter(datmir,b);
		  datmir = datmir(size(datmir,1):-1:1,:);
		  orgdat(:,N) = single(datmir(idxsel));
		end
	  else
		for N = size(orgdat,2):-1:1,
		  datmir = s_filter(orgdat(idxmir,N),b);
		  datmir = datmir(size(datmir,1):-1:1,:);
		  datmir = s_filter(datmir,b);
		  datmir = datmir(size(datmir,1):-1:1,:);
		  orgdat(:,N) = datmir(idxsel);
		end
	  end
	else
	  %datmir = filter(b,a,orgdat(idxmir,:));
	  datmir = s_filter(orgdat(idxmir,:),b);
	  datmir = datmir(size(datmir,1):-1:1,:);
	  %datmir = filter(b,a,datmir);
	  datmir = s_filter(datmir,b);
	  datmir = datmir(size(datmir,1):-1:1,:);
	  %datmir=[zeros(length(b)-1,size(datmir,2)); datmir];
	  orgdat = datmir(idxsel,:);
	end
	clear datmir idxmir idxsel;
  else
	orgdat = filtfilt(b,a,orgdat);
  end
else
  if MIRROR_EDGES > 0,
	mirror = max([length(b),length(a)]);
    if any(MIRROR_SEC) && MIRROR_SEC > 0,
      mirror = max([mirror, round(MIRROR_SEC/Sig.dx(1))]);
    end
	idxmir = [mirror+1:-1:2 1:size(orgdat,1) size(orgdat,1)-1:-1:size(orgdat,1)-mirror-1];
	idxsel = (1:size(orgdat,1)) + mirror;
	if SAVE_MEMORY > 0,
	  if strcmpi(class(orgdat),'single'),
		for N = size(orgdat,2):-1:1,
		  datmir = filtfilt(b,a,double(orgdat(idxmir,N)));
		  orgdat(:,N) = single(datmir(idxsel));
		end
	  else
		for N = size(orgdat,2):-1:1,
		  datmir = filtfilt(b,a,orgdat(idxmir,N));
		  orgdat(:,N) = datmir(idxsel);
		end
	  end
	else
	  datmir = filtfilt(b,a,orgdat(idxmir,:));
	  orgdat = datmir(idxsel,:);
	end
	clear datmir idxmir idxsel;
  else
	orgdat = filtfilt(b,a,orgdat);
  end
end

if KEEP_DC > 0,
  orgdat = bsxfun(@plus, orgdat, dcval);
  % for N = 1:size(orgdat,2),
  %   orgdat(:,N) = orgdat(:,N) + dcval(N);
  % end
  clear dcval;
end


% make (t,abc) as (t,a,b,c,..)
tmpsz(1) = size(orgdat,1);
orgdat = reshape(orgdat,tmpsz);

oSig = Sig;
oSig.(DATAFIELD) = orgdat;


return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function outdat=s_filter(sigdat,fdat)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if 0,
  ns=size(sigdat,1);
  nchan=size(sigdat,2);
  nfft=2^nextpow2(ns);
  S_fft=fft(sigdat,nfft);
  clear sigdat;
  F_fft=fft(fdat,nfft);
  % Avoid memory overflow
  %SxF_fft=S_fft.*repmat(F_fft',1,size(sigdat,2));
  for chNo=1:nchan
	SxF_fft(:,chNo)=S_fft(:,chNo).*F_fft';
  end;
  outdat=ifft(SxF_fft,nfft);
  outdat=outdat(1:ns,:);
end;
outdat=fftfilt(fdat',sigdat);
