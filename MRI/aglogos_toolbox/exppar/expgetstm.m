function Ret = expgetstm(Ses,ExpNo,Mode,HemoDelay,HemoTail)
%EXPGETSTM - Provide stimulus-related information (stm, epoch, boxcar, hemo)
% Ret = EXPGETSTM (Ses,ExpNo) returns the time and the value of the
%       stimulus function. The stm structure contains the arrays .v
%       and .t that have the value and timing of on/off epochs of
%       stimulation respectively. These values are used to generate
%       the stimulus wave form, which is either a boxcar function or a
%       boxcar function convolved with a kernel representing the
%       hemodynamic response.
%  
% Ret = EXPGETSTM (Ses,ExpNo,Mode) has one of the following output
%       arguments:
%  
%       Mode == 'stm' is equivalent to EXPGETSTM(Ses,ExpNo)
%  
%       Mode == 'epoch' returns the timing and the value of the
%           stimulus-function in the following formats:
%  
%           ** Ret.t: The stimulus time in seconds as defined in the stm.t field
%           ** Ret.time: The stimulus time as read from the event file (but
%               in seconds)
%           ** Ret.val: If non grp.val is not defined, then the
%               value of the stimulus where "blank" is 0, and non-"blank" 1
%           ** Ret.val: If non grp.val is defined, then the value
%               of grp.val for each non-zero element, otherwise 0.
%
%       Mode == 'boxcar' is a function of zeros during the
%           non-stimulation and of Ret.val during stimulation periods.
%           In this mode, one may set HemoDelay and HemoTail like
%           Ret = EXPGETSTM (Ses,ExpNo,'boxcar',HemoDelay,HemoTail).
%           As default, HemoDelay = 2s and HemoTail = 6s.
%
%       Mode == 'hemo' is a boxcar convolved with a gamma function
%           representing the hemodynamic response of the neurovascular
%           system.
%
%       Mode == 'fhemo' is a boxcar convolved with a fast gamma function
%           representing the negative? hemodynamic response of the neurovascular
%           system.
%
%       Note that if 'Mode' has a prefix of 'inv' then waveform will be inverted.
%
% EXAMPLES:
% ==============================================
% epoch = expgetstm('m02lx1',1,'epoch');
%       v: {[0 1 2]}
%     val: {[0 1 0]}
%       t: {[0 60 360 390]}
%    time: {[0.0010 59.7010 358.1940]}
%
% epoch = expgetstm('n03ow1',1,'epoch');
%  epoch:
%       v: {[0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2]}
%     val: {[0 1 0 0 1 0 0 1 0 0 1 0 0 1 0 0 1 0 0 1 0 0 1 0 0 1 0]}
%       t: {[0 2 4 14 16 18 28 30 32 42 44 46 56 58 60 ...
%    time: {[0 1.9950 2.0617 13.9390 15.9190 16.0523 27.8680 29.8440 ...
%    
% VERSION : 0.90 13.04.04 YM   first release
%           0.91 05.09.04 YM   supports more functions.
%           0.92 08.09.04 YM   supports HemoDelay/HemoTail for 'boxcar'.
%           0.93 06.01.05 YM   bug fix on .v/.val.
%           0.94 05.01.06 YM   supports fgamma, prefix of "inv"
%
% See also EXPGETPAR, MKMODEL, GETSTIMINDICES, MHEMOKERNEL

if nargin < 2,  help expgetstm;  return;  end
if nargin < 3,  Mode = 'stm';   end;
if nargin < 4,  HemoDelay = 2;  end
if nargin < 5,  HemoTail  = 6;  end


Ses = goto(Ses);
if ischar(ExpNo),
  grp = getgrpbyname(Ses,ExpNo);
  ExpNo = grp.exps(1);
else
  grp = getgrp(Ses,ExpNo);
end

% read experiment parameters
ExpPar = expgetpar(Ses,ExpNo);

if nargin == 2,
  Ret = ExpPar.stm;
  return;
end;

epoch = subGetEpoch(Ses,grp,ExpNo,ExpPar);
switch lower(Mode)
 case {'totpts','invtotpts'}
  DX = ExpPar.stm.voldt;
  model = 'gampdf';   % 'ir' or 'gampdf'
  
  Ret.session = Ses.name;
  Ret.grpname = grp.name;
  Ret.ExpNo   = ExpNo;
  Ret.dir.dname = 'model';
  Ret.dsp.func	= 'dspmodel';
  Ret.dsp.label	= {'Time in Sec'; 'SD Units'};
  Ret.dsp.args	= {};
  Ret.stm       = ExpPar.stm;
  Ret.stm.time  = epoch.time;
  sig = sigload(Ses.name,ExpNo,'pLfpH');
  Ret.dx      = sig.dx;
  Ret.dat     = subGetHemo(ExpPar,mean(sig.dat,2),sig.dx,model);
  
 case { 'boxcar', 'invboxcar'}
  DX = ExpPar.stm.voldt;
  
  Ret.session   = Ses.name;
  Ret.grpname   = grp.name;
  Ret.ExpNo     = ExpNo;
  Ret.dir.dname = 'model';
  Ret.dsp.func	= 'dspmodel';
  Ret.dsp.label	= {'Time in Sec'; 'SD Units'};
  Ret.dsp.args	= {};
  Ret.stm       = ExpPar.stm;
  Ret.stm.time  = epoch.time;
  Ret.dx      = DX;
  Ret.dat     = subGetBoxCar(ExpPar,epoch,DX,HemoDelay,HemoTail);
  
 case { 'fhemo','fast hemo', 'fasthemo', 'invfhemo','invfasthemo' }
  DX = ExpPar.stm.voldt;
  model = 'fgampdf';   % 'ir' or 'gampdf'
  
  Ret.session = Ses.name;
  Ret.grpname = grp.name;
  Ret.ExpNo   = ExpNo;
  Ret.dir.dname = 'model';
  Ret.dsp.func	= 'dspmodel';
  Ret.dsp.label	= {'Time in Sec'; 'SD Units'};
  Ret.dsp.args	= {};
  Ret.stm       = ExpPar.stm;
  Ret.stm.time  = epoch.time;
  Ret.dx      = DX;
  Ret.dat     = subGetHemo(ExpPar,epoch,DX,model);
  
 case { 'hemo','invhemo' }
  DX = ExpPar.stm.voldt;
  model = 'gampdf';   % 'ir' or 'gampdf'
  
  Ret.session = Ses.name;
  Ret.grpname = grp.name;
  Ret.ExpNo   = ExpNo;
  Ret.dir.dname = 'model';
  Ret.dsp.func	= 'dspmodel';
  Ret.dsp.label	= {'Time in Sec'; 'SD Units'};
  Ret.dsp.args	= {};
  Ret.stm       = ExpPar.stm;
  Ret.stm.time  = epoch.time;
  Ret.dx      = DX;
  Ret.dat     = subGetHemo(ExpPar,epoch,DX,model);
 case { 'hemodiff' ,'invhemodiff'}
  DX = ExpPar.stm.voldt;
  model = 'gampdf';   % 'ir' or 'gampdf'
  
  Ret.session = Ses.name;
  Ret.grpname = grp.name;
  Ret.ExpNo   = ExpNo;
  Ret.dir.dname = 'model';
  Ret.dsp.func	= 'dspmodel';
  Ret.dsp.label	= {'Time in Sec'; 'SD Units'};
  Ret.dsp.args	= {};
  Ret.stm       = ExpPar.stm;
  Ret.stm.time  = epoch.time;
  Ret.dx      = DX;
  Ret.dat     = subGetHemo(ExpPar,epoch,DX,model,1);
  
 case { 'epoch', 'epochs' ,'invepoch','invepochs'}
  Ret = epoch;
 otherwise
  fprintf(' expgetstm ERROR: ''%s'' not supported yet.\n',Mode);
  keyboard
end


% INVERSE THE PORALITY, IF 'Model' has a prefix of 'inv'. %%%%%%%%%%%%%%%%%%%%%%%%
if strncmpi(Mode,'inv',3),
  Ret.dat = Ret.dat * -1;
end


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function returns 'boxcar'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Wv = subGetBoxCar(ExpPar,epoch,DX,HemoDelay,HemoTail)

% use epoch.time (timing by event file) for precise modeling.
VAL = epoch.val{1};
T   = epoch.time{1};
LEN = round(sum(ExpPar.stm.dt{1})/DX);
% make sure to cover a whole time series, even if stimulus durations
% are randomized.
if isstruct(ExpPar.pvpar),
  if round(sum(ExpPar.stm.dt{1})/ExpPar.pvpar.imgtr) ~= ExpPar.pvpar.nt,
    LEN = round(ExpPar.pvpar.nt*ExpPar.pvpar.imgtr/DX);
  end
end

HemoDelay = floor(HemoDelay/DX);
HemoTail  = floor(HemoTail/DX);

% +1 for matlab indexing
TS = floor(T/DX) + 1 + HemoDelay;
TE = floor(T/DX) + 1 + HemoTail;
TE(end+1) = LEN;

Wv = zeros(LEN,1);

for N = 1:length(VAL),
  if VAL(N) ~= 0,
    ts = TS(N);
    te = TE(N+1);
    if ts > LEN,  ts = LEN;  end
    if te > LEN,  te = LEN;  end
    Wv(ts:te) = VAL(N);
  end
end
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function returns 'hemo'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Wv = subGetHemo(ExpPar,epoch,DX,Model,DoDiff)
IRTDX = 0.01;      % time resolution for dat/kernel, decimated later.

if isa(epoch,'double'),
  IRTDX = DX/100;
  Wv = interp(epoch,100);
else
  % HemoDely/HemoTail should be represented by "IR", not boxcar.
  Wv = subGetBoxCar(ExpPar,epoch,IRTDX,0,0);
end;

if exist('DoDiff','var') && DoDiff == 1,
  Wv = diff([Wv(1);Wv(:)]);		% Wv(1) to keep the length of Wv.
  Wv = abs(Wv);					% rectify it
end


IR = mhemokernel(Model,IRTDX,25);

% convolve Wv.dat with the hemodynamic kernel
%sel = [1:length(Wv)] + floor(length(IR)/2);

sel = 1:length(Wv);
Wv = conv(Wv(:),IR.dat(:));
Wv = Wv(sel);

% now decimate to DX
Wv = decimate(Wv,DX/IRTDX);

if isa(epoch,'double'),
  nyq = (1/DX)/2;
  [b,a] = butter(3,[0.008 0.08]/nyq, 'bandpass');
  Wv = filtfilt(b,a,Wv);
end;

LEN = round(sum(ExpPar.stm.dt{1})/DX);
% make sure to cover a whole time series, even if stimulus durations
% are randomized.
if isstruct(ExpPar.pvpar),
  if round(sum(ExpPar.stm.dt{1})/ExpPar.pvpar.imgtr) ~= ExpPar.pvpar.nt,
    LEN = round(ExpPar.pvpar.nt*ExpPar.pvpar.imgtr/DX);
  end
end

if length(Wv) > LEN,  Wv = Wv(1:LEN);  end
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Epoch = subGetEpoch(Ses,grp,ExpNo,ExpPar)
% The function will return:
% (a) The stimulus time in seconds as defined in the .t field
% (b) The stimulus time as read from the event file
% (c) One of the outcomes below:
%  if non grp.val is defined, then
%        The value of the stimulus where "blank" is 0, and non-"blank" 1
% else
%        The value of grp.val for each non-zero element
%
% Meaning of structures:
% =====================================
%      evt: [1x1 struct]
%    pvpar: [1x1 struct]
%      stm: [1x1 struct]
%      rfp: [1x1 struct]  
%
% stm:
%      labels: {'config1'}
%    stmtypes: {'blank'  'movie'  'blank'}
%       voldt: 0.2500
%           v: {[0 1 2]}
%          dt: {[60 300 30]}
%           t: {[0 60 360 390]}
%     stmpars: [1x1 struct]
%     pdmpars: [1x1 struct]
%     hstpars: [1x1 struct]
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Epoch.stmtypes = ExpPar.stm.stmtypes;
Epoch.v = ExpPar.stm.v;

if isfield(grp,'val'),
  val = grp.val;
  for N=1:length(Epoch.v),
	v = ExpPar.stm.v{N};
	%if ~isempty(val{N}) & (length(find(unique(v))) ~= length(val{N})),
	if ~isempty(val{N}) & (length(find(unique(v))) > length(val{N})),
	  fprintf('Length(val) must be equal to nonzero elements of .v\n');
	  keyboard;
	end;
	
	ix = find(v);
	for NN=1:length(ix),
	  if isempty(val{N}),
		Epoch.val{N}(ix(NN)) = 1;
	  else
		Epoch.val{N}(ix(NN)) = val{N}(v(ix(NN)));
	  end;
	end;
  end;
else
  ix = find(strcmp(ExpPar.stm.stmtypes,'blank'));
  for N = 1:length(Epoch.v),
    val{N} = ones(1,length(Epoch.v{N}));
    for K = 1:length(ix),
      % +1 for matlab indexing
      val{N}(find(Epoch.v{N}+1 == ix(K))) = 0;
    end
  end

end;
Epoch.val = val;
Epoch.t = ExpPar.stm.t;
Epoch.time = ExpPar.stm.time;

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function returns 'hemo'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Wv = KEEPsubGetHemo(ExpPar,epoch,DX,Model)
DEBUG = 0;
IRTDX = 0.01;              % time resolution for dat/kernel, decimated later.
IRTLEN = round(25/IRTDX);  % 25 sec duration
IRT = [0:IRTLEN-1] * IRTDX;			% see impresp.mat/supir.t
Wv = subGetBoxCar(ExpPar,epoch,IRTDX);

if DEBUG,
  figure;  plot([0:length(Wv)-1]*IRTDX,Wv,'r');
  title(sprintf('Model: %s',Model));
end

switch lower(Model),
 case { 'ir','irmodel' }
  PAR = [0.4956 2.7456 3.3245 1.5615 31.8288 -0.0184];
  IR = irmodel(PAR,IRT);
 case { 'gamma','gampdf','gammapdf'}
  Lamda = 12;
  Theta = 0.4089;
  IR = gampdf(IRT,Lamda,Theta);
 otherwise
  fprintf(' ERROR expgetstm.subGetHemo :');
  fpritnf(' ''%s'' not supported yet.\n',Model);
  keyboard
end

% convolve Wv.dat with the hemodynamic kernel
%sel = [1:length(Wv)] + floor(length(IR)/2);
sel = 1:length(Wv);
Wv = conv(Wv,IR);
Wv = Wv(sel);

if DEBUG,
  hold on;
  plot([0:length(IR)-1]*IRTDX,IR,'black');
  plot([0:length(Wv)-1]*IRTDX,Wv,'b');
end

% now decimate to DX
Wv = decimate(Wv,DX/IRTDX);

LEN = round(sum(ExpPar.stm.dt{1})/DX);
if length(Wv) > LEN,  Wv = Wv(1:LEN);  end

if DEBUG,
  hold on;  plot([0:length(Wv)-1]*DX,Wv,'g');
end
return;


