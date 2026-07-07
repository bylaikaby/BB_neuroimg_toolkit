function Sig = siglfprestore(Sig,varargin)
%SIGLFPRESTORE - Restore LFP compnents by cumtrapz() or a shelving filter.
%  SIG = SIGLFPRESTORE(Sig,...) rstores LFP components by using cumtrapz() or a shelving filter.
%
%  Available options are
%    'method'         : 'cumtrapz'|'shelving'
%    'shelving_G'     : logrithmic gain (in dB), 7dB as default
%    'shelving_Fc'    : cutoff frequency in Hz, 7Hz as default
%    'shelving_Q'     : adjusts the slope be replacing the sqrt(2) term, 1/sqrt(2) as default
%    'detrend'        : 0|1, detrend or not
%    'keep_DC'        : 0|1, keep DC component or not
%    'mri_recover'    : 0|1, aggressive recovery for combined recording with MRI.
%                       if mri==1, then G=55,Fc=3.0Hz,Q=0.16.
%                       if mri==2, then G=60,Fc=1.8Hz,Q=0.15.
%                       if mri==3, then G=65,Fc=1.2Hz,Q=0.115.
%    'field'          : field(data) name to process (default as 'dat')
%
%  NOTE :
%   - 'cumtrapz' generates linear increase/decrease of baseline which can be removed by
%    detrending.  It also sometimes creates gaps which are difficult to remove.
%   - 'shelving' uses the lowpass shelving filter (see shelving.m) with calling
%   sigfiltfilt() which performs zero-phase digital filtering.
%
%  EXAMPLE :
%    >> cln = sigload(ses,expno,'Cln')
%    >> sigc = siglfprestore(cln,'method','cumtrapz');
%    >> sigs = siglfprestore(cln,'method','shelving', 'shelving_fc',10);
%    >> sigm = siglfprestore(cln,'mri',1);
%  EXAMPLE 2:
%    >> % this setting might inverse the filter response of our NMR-amplifier.
%    >> Fs = 7000;
%    >> [b,a] = shelving(50,5, Fs, 0.2, 'Base_Shelf');
%    >> [h,f] = freqz(b,a,8192,Fs);
%    >> plot(f,20*log10(abs(h))); set(gca,'xscale','log'); grid on;  ylabel('magnitude (dB)');
%    >> plot(f,angle(h)*180/pi); grid on; ylabel('phase (degrees)');
%
%  REQUIREMENT :
%   shelving.m
%
%  VERSION :
%   0.90 05.04.16 YM  pre-release
%   0.91 07.04.16 YM  supports 'shelving'.
%   0.92 14.04.16 YM  supports 'mri'=1,2,3.
%
%  See also cumtrapz shelving sigfiltfilt siggetblp fvtool freqz

if nargin < 1,  eval(['help ' mfilename]); return;  end


if iscell(Sig),
  for N = 1:numel(Sig)
    Sig{N} = siglfprestore(Sig,varargin{:});
  end
  return
end

% DEFAULT OPTIONAL SETTINGS
%METHOD         = 'cumtrapz';
METHOD         = 'shelving';
DO_DETREND     = 1;
KEEP_DC        = 1;
DATAFIELD      = 'dat';
SHRV_G         = 7;          % 7dB as default
SHRV_Fc        = 7;          % 7Hz as default
SHRV_Q         = 1/sqrt(2);  % 1/sqrt(2) as default


% UPDATE OPTIONAL SETTINGS
% first look for "nmr_recover' flag to set its default values.
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'nmr' 'mri' 'nmr_recover', 'mri_recover'}
    % This setting might inverse the filter response of our NMR-amplifier.
    % It could be too much, amplifying noise also.
    METHOD = 'shelving';
    if isequal(varargin{N+1},1),
      SHRV_G         = 55;         % 55dB as default
      SHRV_Fc        = 3;          %  3Hz as default
      SHRV_Q         = 0.16;       % 0.16 as default
    elseif isequal(varargin{N+1},2),
      SHRV_G         = 60;         % 60dB as default
      SHRV_Fc        = 1.8;        %  1.8Hz as default
      SHRV_Q         = 0.15;       % 0.15 as default
    elseif isequal(varargin{N+1},3),
      SHRV_G         = 65;         % 65dB as default
      SHRV_Fc        = 1.2;        %  1.2Hz as default
      SHRV_Q         = 0.115;      %  0.115 as default
    end
  end
end


for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'method'}
    METHOD = varargin{N+1};
   case {'detrend'}
    DO_DETREND = any(varargin{N+1});
   case {'keep_dc','keepdc','keep dc', 'dc'}
    KEEP_DC = varargin{N+1};
    
    % shelving parameters
   case {'g' 'shelving_g' 'shelvingg'}
    SHRV_G = varargin{N+1};
   case {'fc' 'shelving_fc' 'shelvingfc'}
    SHRV_Fc = varargin{N+1};
   case {'q' 'shelving_q' 'shelvingfc'}
    SHRV_Q = varargin{N+1};
   
   case {'field' 'datfield' 'datafield' 'dat' 'data' 'dat_field','data_field'},
    DATAFIELD = varargin{N+1};
  end
end


if isempty(Sig.(DATAFIELD)),
  oSig = Sig;
  return
end

tmpdat = Sig.(DATAFIELD);

% reshape data as a matrix
szdat = size(tmpdat);
tmpdat = reshape(tmpdat, [szdat(1) prod(szdat(2:end))]);

tmpm = nanmean(tmpdat,1);

if any(KEEP_DC),
  dcval = tmpm;  % keep this for later use
end

tmpdat = bsxfun(@minus, tmpdat, tmpm);


switch lower(METHOD)
 case {'cumtrapz'}
  METHOD = 'cumtrapz';
  tmpdat = cumtrapz(tmpdat);
 case {'shelving'}
  METHOD = 'shelving';
  % Make the gain half, due to 2x amplification of bi-directional filtering (filtfilt).
  [b,a] = shelving(SHRV_G/2, SHRV_Fc, 1/Sig.dx(1), SHRV_Q, 'Base_Shelf');
  tmpsig = Sig;
  tmpsig.dat = tmpdat;
  mirror_n = max([length(b)*4 length(a)*4 round(2/tmpsig.dx)]);
  if mirror_n > size(tmpsig.dat,1)/2,  mirror_n = 0;  end
  tmpsig = sigfiltfilt(tmpsig,b,a,'keep_dc',1,'mirror',1,'mirror_sec',mirror_n*tmpsig.dx);

  % fprintf('lowpass.');
  % nyqf = 1/tmpsig.dx/2;
  % tmpsig = sigfiltfilt(tmpsig,nyqf*0.1,'lowpass','keep_dc',0);

  tmpdat = tmpsig.dat;
  clear tmpsig;
 otherwise
  error(' ERROR %s: method(''%s'') not supported.\n',mfilename,METHOD);
end

if any(DO_DETREND)
  tmpdat = detrend(tmpdat);
end

if any(KEEP_DC),
  tmpm = dcval - nanmean(tmpdat,1);
  tmpdat = bsxfun(@plus, tmpdat, tmpm);
end

% restore the original dimension
tmpdat = reshape(tmpdat, szdat);

Sig.(DATAFIELD) = tmpdat; 

% keep the parameters
Sig.(mfilename).method    = METHOD;
Sig.(mfilename).detrend   = DO_DETREND;
Sig.(mfilename).keep_dc   = KEEP_DC;
Sig.(mfilename).datafield = DATAFIELD;
if strcmpi(METHOD,'shelving'),
  Sig.(mfilename).shelving_g  = SHRV_G;
  Sig.(mfilename).shelving_fc = SHRV_Fc;
  Sig.(mfilename).shelving_q  = SHRV_Q;
end


return
