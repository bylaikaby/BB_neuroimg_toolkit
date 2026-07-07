function Sig = sigxform(Sig,varargin)
%SIGXFORM - Transform signal according to the second input argument "xform"
%  
%  Sig = SIGXFORM (Sig, 'ABS') - Full rectify
%  Sig = SIGXFORM (Sig, 'HALFRECT') - Half rectify
%  Sig = SIGXFORM (Sig, 'LOW', cutoff) - Low pass temporal filtering
%  Sig = SIGXFORM (Sig, 'HIGH', cutoff) - High pass temporal filtering
%  Sig = SIGXFORM (Sig, 'BANDPASS', [high low]) - Band pass temporal filtering
%  Sig = SIGXFORM (Sig, 'DETREND') - Detrending
%  Sig = SIGXFORM (Sig, 'CUMSUM') - Cummulative sum
%  Sig = SIGXFORM (Sig, 'TOSDU', [prestim | baseline....]) - Convert to STD Units
%  Sig = SIGXFORM (Sig, 'SQUARE') - Element multiplication
%  Sig = SIGXFORM (Sig, 'POWER') - 20*Log(squared signal)
%  Sig = SIGXFORM (Sig, 'HLM') - Gamma/Mua Bands Hilbert Transformed, Chan-Averaged
%  Sig = SIGXFORM (Sig, 'HILBERT') - Amplitude of Hilbert Transform
%  Sig = SIGXFORM (Sig, 'RMS') - Root Mean Square
%
% NKL, 19.05.03

if nargin < 2,
  help sigxform;
  return;
end;

DoUndo = 0;
if isstruct(Sig),
  DoUndo = 1;
  Sig = {Sig};
end;

for N=1:length(Sig),
  if isstruct(Sig{N}),
    Sig{N} = DoTransform(Sig{N},varargin{:});
  else
    for K=1:length(Sig{N}),
      if isstruct(Sig{N}{K})
        Sig{N}{K} = DoTransform(Sig{N}{K},varargin{:});
      else
        fprintf('ERROR: sigxform: maximum cell-array depth is 2 (sig{}{})\n');
        return;
      end;
    end;
  end;
end;
if DoUndo,
  Sig = Sig{1};
end;
return;
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sig = DoTransform(Sig, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
FiltFlag = 0;
xform = upper(varargin{1});
switch xform,
 
 case 'ABS',
  Sig.dat = abs(Sig.dat);
 
 case 'HALFRECT',
  Sig.dat(find(Sig.dat<0))=0;
 
 case 'LOW',
  FiltFlag = 1;
  if nargin < 3,
    fprintf('ERROR: sigxform: no low-pass cutoff\n');
    help sigxform;
    return;
  end;
  nyq = (1/Sig.dx)/2;
  [b,a] = butter(4,varargin{2}/nyq,'low');
  Sig = DoFilter(b,a, Sig);
 
 case 'HIGH',
  if nargin < 3,
    fprintf('ERROR: sigxform: no high-pass cutoff\n');
    help sigxform;
    return;
  end;
  nyq = (1/Sig.dx)/2;
  [b,a] = butter(4,varargin{2}/nyq,'high');
  Sig = DoFilter(b,a, Sig);
 
 case 'BANDPASS',
  if nargin < 3 | length(varargin{2})<2,
    fprintf('ERROR: sigxform: no band-pass cutoff\n');
    help sigxform;
    return;
  end;
  nyq = (1/Sig.dx)/2;
  [b,a] = butter(4,varargin{2}/nyq,'bandpass');
  Sig = DoFilter(b,a, Sig);
 
 case 'HLM',        % Hilbert transform of gamma/mua
  % Prepare to extract LFP band
  % we do this in two steps to avoid problems with filters
  ses = getses(Sig.session);
  mrange = ses.anap.bands.Mua;
  grange = ses.anap.bands.Gamma;
  nyq = (1/Sig.dx)/2;
  FirstCutoff = 300;
  [b,a] = butter(4,FirstCutoff/nyq,'low');
  oSig = DoFilter(b,a, Sig);
  [b,a] = butter(4,grange/nyq,'bandpass');
  oSig = DoFilter(b,a, oSig);
  for C = 1:size(Sig.dat,2),
    oSig.dat(:,C) = abs(hilbert((oSig.dat(:,C))));
  end;
  oSig.dat = hnanmean(oSig.dat,2);
  [b,a] = butter(4,mrange/nyq,'bandpass');
  Sig = DoFilter(b,a, Sig);
  for C = 1:size(Sig.dat,2),
    Sig.dat(:,C) = abs(hilbert((Sig.dat(:,C))));
  end;
  Sig.dat = hnanmean(Sig.dat,2);
  oSig.dat = cat(2,oSig.dat,Sig.dat);
  Sig = tosdu(oSig);
  clear oSig;
 
 case 'DETREND'
  for O = 1:size(Sig.dat,3),
    Sig.dat(:,:,O) = detrend(Sig.dat(:,:,O));
  end;

 case 'CUMSUM'
  Sig.dat = cumsum(Sig.dat);

 case 'TOSDU'
  if nargin < 2,
    Sig = tosdu(Sig);
  else
    Sig = xform(Sig,'tosdu',varargin{2});
  end;
 
 case 'SQUARE'
    Sig.dat = Sig.dat.*Sig.dat;
 
 case 'POWER'
    Sig.dat = 20*log(Sig.dat.*Sig.dat);
 
 case 'HILBERT'
  for O = 1:size(Sig.dat,3),
    for C = 1:size(Sig.dat,2),
      Sig.dat(:,C,O) = abs(hilbert((Sig.dat(:,C,O))));
    end;
  end;

 case 'RMS'
  Sig = sigrms(Sig,'window',0.1);   % Computer RMS in successive 100ms windows

 otherwise,
  fprintf('ERROR: sigxform: Unrecognized function mode\n');
  help sigxform;
  return;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
function Sig = DoFilter(b,a, Sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
ilen = size(Sig.dat,1);
len = round(ilen/10);
for N=1:size(Sig.dat,2),
  pre = Sig.dat(1:len,N);
  pst = Sig.dat(end-len+1:end,N);
  tmp = cat(1,flipud(pre),Sig.dat(:,N),flipud(pst));
  tmp = filtfilt(b,a,tmp);
  Sig.dat(:,N) = tmp(len+1:len+ilen);
end;
return;
