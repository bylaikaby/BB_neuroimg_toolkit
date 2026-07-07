function Sig = expgeteeg(Ses,ExpNo,varargin)
%EXPGETEEG - Convert/Create 'eeg' signal for the given Ses/Exp.
%  Sig = EXPGETEEG(Ses,ExpNo,...) converts/creates 'eeg' signal for
%  the given Ses/Exp.
%  Supported options are :
%    eegch    : channel selection, a numeric vector.
%    obsch    : DI line(s) for OBS periods.
%    ecgch    : ECG/EKG channel(s).
%    highpass : highpass filter in Hz
%    decimate : a factor for decimation.
%
%  NOTE :
%    - Chan/ObsCh can be set in the session file.
%        GRP.(grpname).geteeg.eegch = [1:26 28]; % EEG channel selection
%        GRP.(grpname).geteeg.obsch = [0 1];     % DI lines for obs-periods
%        GRP.(grpname).geteeg.ecgch = [29];      % ECG/EKG channel(s)
%        GRP.(grpname).geteeg.highpassHz = 0.1;  % high-pass filter in Hz
%        GRP.(grpname).geteeg.decimate = 2;      % a factor for decimation
%    - The session file should have "EXPP(ExpNo).eegfile".
%        EXPP(ExpNo).eegfile = 'abcdefg0000.vhdr';  % BrainVision
%
%  EXAMPLE :
%    Sig = expgeteeg(Ses,ExpNo,...)
%
%  REQUIREMENT :
%    EEGLAB (readbvconf/pop_loadbv: BrainVision support)
%    nscan_xxxx functions
%
%  VERSION :
%    0.90 25.04.13 YM  pre-release
%    0.92 23.05.13 YM  supports "eegecgch" as ECG/EKG channel(s).
%    0.93 23.05.13 YM  supports "decimate" by using sub_decimate().
%    0.94 24.05.13 YM  supports "highpassHz" by using sigfiltfilt().
%    0.95 25.05.13 YM  highpass after decimate to avoid "singular" problem.
%    0.96 10.02.14 YM  supports Curry7 (neuroscan) data format.
%
%  See also sesgeteeg bveeg2sig nseeg2sig expfilename sigfiltfilt

if nargin < 2,  eval(['help ' mfilename]); return;  end

Ses  = goto(Ses);
grp  = getgrp(Ses,ExpNo);
anap = getanap(Ses,ExpNo);

% options
EEG_CHAN = [];
OBS_CHAN = [];
EKG_CHAN = [];
HPFLT_HZ = 0.1;
DEC_FRAC = 1;
CLK_CORRECTION = 1;
VERBOSE  = 1;

if isfield(grp,'geteeg'),
  if isfield(grp.geteeg,'eegch'),  EEG_CHAN = grp.geteeg.eegch;  end
  if isfield(grp.geteeg,'obsch'),  OBS_CHAN = grp.geteeg.obsch;  end
  if isfield(grp.geteeg,'ecgch'),  EKG_CHAN = grp.geteeg.ecgch;  end
  if isfield(grp.geteeg,'highpassHz'), HPFLT_HZ = grp.geteeg.highpassHz;  end
  if isfield(grp.geteeg,'decimate'), DEC_FRAC = grp.geteeg.decimate;  end
end
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'eegch' 'eegchan' }
    EEG_CHAN = varargin{N+1};
   case {'obsch' 'obschan' 'obsbit' 'obsbits'}
    OBS_CHAN = varargin{N+1};
   case {'ecgch' 'ekgch'}
    EKG_CHAN = varargin{N+1};
   case {'highpass' 'hp' 'highpasshz' 'hphz'}
    HPFLT_HZ = varargin{N+1};
   case {'decimate' 'dec' 'decfrac'}
    DEC_FRAC = varargin{N+1};
   case {'clkcorr' 'clkcorrect' 'clkcorrection' 'clockcorr' 'clockcorrect' 'clockcorrection'}
    CLK_CORRECTION = varargin{N+1};
   case {'verbose'}
    VERBOSE = varargin{N+1};
  end
end


EEGFILE = expfilename(Ses,ExpNo,'eeg');


fprintf(' %s: %s exp=%d: %s\n',mfilename,Ses.name,ExpNo,EEGFILE);

[fp fr fe] = fileparts(EEGFILE);
switch lower(fe)
 case {'.vhdr'}
  % BrainVision Recorder (.vhdr)
  Sig = bveeg2sig(EEGFILE,'eegch',EEG_CHAN,'obsch',OBS_CHAN,'ecgch',EKG_CHAN,'verbose',VERBOSE);
 
 case {'.cnt' '.dat'}
  % Neuroscan CURRY (.cnt/.dat)
  Sig = nseeg2sig(EEGFILE,'eegch',EEG_CHAN,'obsch',OBS_CHAN,'ecgch',EKG_CHAN,'verbose',VERBOSE);
  
 otherwise
  error(' ERROR %s: filetype ''%s'' not supported yet\n',mfilename,fe);
end


if any(DEC_FRAC) && DEC_FRAC > 1,
  fprintf(' dec[%d:%gkHz].',DEC_FRAC,(1/(Sig.dx*DEC_FRAC))/1000.);
  Sig.dat = sub_vec_decimate(Sig.dat,DEC_FRAC);
  Sig.dx  = Sig.dx * DEC_FRAC;
  
  if isfield(Sig,'ecg') && ~isempty(Sig.ecg),
    Sig.ecg.dat = sub_vec_decimate(Sig.ecg.dat,DEC_FRAC);
    Sig.ecg.dx  = Sig.ecg.dx * DEC_FRAC;
  end
end


if any(HPFLT_HZ)
  fprintf(' hp[%gHz].',HPFLT_HZ);
  Sig = sigfiltfilt(Sig,HPFLT_HZ,'highpass');
end


% update session/exp info
Sig.session = Ses.name;
Sig.grpname = grp.name;
Sig.ExpNo   = ExpNo;
Sig.dir.dname = 'eeg';

% do clock correction to match with dgz
if any(CLK_CORRECTION),
  fprintf(' clkcorr');
  par = expgetpar(Ses,ExpNo);
  evtlen = par.evt.obs{1}.origtimes.end(1) * par.evt.tfactor / 1000;
  eeglen = size(Sig.dat,1) * Sig.dx(1);

  tfactor = evtlen / eeglen;

  Sig.dxorg = Sig.dx;
  Sig.dx    = Sig.dx * tfactor;
  
  if isfield(Sig,'ecg') && ~isempty(Sig.ecg),
    Sig.ecg.dxorg = Sig.ecg.dx;
    Sig.ecg.dx    = Sig.ecg.dx * tfactor;
  end

  fprintf('(%g).',tfactor);
end


% information
Sig.(mfilename).eegch = EEG_CHAN;
Sig.(mfilename).obsch = OBS_CHAN;
Sig.(mfilename).ecgch = EKG_CHAN;
Sig.(mfilename).highpassHz = HPFLT_HZ;
Sig.(mfilename).decimate   = DEC_FRAC;
Sig.(mfilename).clkcorr    = CLK_CORRECTION;


fprintf(' done.\n');

if nargout == 0,
  sigsave(Ses,ExpNo,Sig.dir.dname,Sig);
end



return




% -------------------------------------------------------------------
function ovdata = sub_vec_decimate(ivdata,r)
% -------------------------------------------------------------------
ivsize = size(ivdata);
ivdata = reshape(ivdata, [ivsize(1) prod(ivsize(2:end))]);

ovdata = [];
if isa(ivdata,'single'),
  for N = size(ivdata,2):-1:1,
    ovdata(:,N) = single(sub_decimate(double(ivdata(:,N)),r));
  end
else
  for N = size(ivdata,2):-1:1,
    ovdata(:,N) = sub_decimate(ivdata(:,N),r);
  end
end

ovdata = reshape(ovdata, [size(ovdata,1) ivsize(2:end)]);

return



% -------------------------------------------------------------------
function odata = sub_decimate(idata,r,nfilt,option)
% -------------------------------------------------------------------
% This subfunciton is modified from MATLAB's decimate().
% The MATALB's decimate() has low-pass filtering of .8xNyqF,
% while here I have .9xNuqF.

% Validate required inputs 
validateinput(idata,r);

if fix(r) == 1
  odata = idata;
  return
end

if nargin == 2
  nfilt = 8;
end

if nfilt > 13
  warning(message('signal:decimate:highorderIIRs'));
end

nd = length(idata);
m = size(idata,1);
nout = ceil(nd/r);
  

% IIR filter
rip = .05;	% passband ripple in dB
[b,a] = cheby1(nfilt, rip, .9/r);
while all(b==0) || (abs(filtmag_db(b,a,.9/r)+rip)>1e-6)
  nfilt = nfilt - 1;
  if nfilt == 0
    break
  end
  [b,a] = cheby1(nfilt, rip, .9/r);
end
if nfilt == 0
  error(message('signal:decimate:InvalidRange'))
end

% be sure to filter in both directions to make sure the filtered data has zero phase
% make a data vector properly pre- and ap- pended to filter forwards and back
% so end effects can be obliterated.
odata = filtfilt(b,a,idata);
nbeg = r - (r*nout - nd);
odata = odata(nbeg:r:nd);

return

%--------------------------------------------------------------------------
function H = filtmag_db(b,a,f)
%FILTMAG_DB Find filter's magnitude response in decibels at given frequency.

nb = length(b);
na = length(a);
top = exp(-1i*(0:nb-1)*pi*f)*b(:);
bot = exp(-1i*(0:na-1)*pi*f)*a(:);

H = 20*log10(abs(top/bot));

%--------------------------------------------------------------------------
function validateinput(x,r)
% Validate 1st two input args: signal and decimation factor

if isempty(x) || issparse(x) || ~isa(x,'double'),
    error(message('signal:decimate:invalidInput', 'X'));
end

if (abs(r-fix(r)) > eps) || (r <= 0)
    error(message('signal:decimate:invalidR', 'R'));
end

