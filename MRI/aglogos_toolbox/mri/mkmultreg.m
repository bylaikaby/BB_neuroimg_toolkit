function mdl = mkmultreg(Ses,ExpNo,Mode)
%MKMULTREG - Generate multiple regressors for Multiple Regression Analysis
% Ret = MKMULTREG (Ses,ExpNo) returns the time and the value of the
%       stimulus function.
%  
% VERSION : 0.01 08.08.05 NKL
%
% See also EXPGETPAR, MKMODEL, GETSTIMINDICES

if nargin < 2,  help mkmultreg;  return;  end
if nargin < 3,  Mode = 'pulses';   end;

Ses = goto(Ses);
if ischar(ExpNo),
  grp = getgrpbyname(Ses,ExpNo);
  ExpNo = grp.exps(1);
else
  grp = getgrp(Ses,ExpNo);
end

% Read experiment parameters
ExpPar = expgetpar(Ses,ExpNo);

% Get the stimulus structure
% stmtypes: {'blank'  'Conc-w0'  'Radi-w0'  'blank'}
%     v: {[0 1 2 0]}
%   val: {[0 1 1 0]}
%     t: {[0 20 40 60 80]}
%  time: {[0 20 40 60]}
stmconf = subGetEpoch(Ses,grp,ExpNo,ExpPar);
DX = ExpPar.stm.voldt;

NMODELS = length(stmconf.v);
for NM=1:NMODELS,
  epoch.v{1} = stmconf.v{NM};
  epoch.val{1} = stmconf.val{NM};
  epoch.t{1} = stmconf.t{NM};
  epoch.time{1} = stmconf.time{NM};

  if isfield(stmconf,'model'),
    Mode = stmconf.model{NM};
  end;
  
  switch lower(Mode)
   case { 'boxcar' }
    HemoDelay     = 1;
    HemoTail      = 1;
    Ret.session   = Ses.name;
    Ret.grpname   = grp.name;
    Ret.ExpNo     = ExpNo;
    Ret.dir.dname = 'model';
    Ret.dsp.func	= 'dspmodel';
    Ret.dsp.label	= {'Time in Sec'; 'SD Units'};
    Ret.dsp.args	= {};
    Ret.stm       = ExpPar.stm;
    Ret.stm.time  = epoch.time;
    Ret.dx        = DX;
    Ret.dat       = subGetBoxCar(ExpPar,epoch,DX,HemoDelay,HemoTail);
   case { 'pulses' }
    Ret.session   = Ses.name;
    Ret.grpname   = grp.name;
    Ret.ExpNo     = ExpNo;
    Ret.dir.dname = 'model';
    Ret.dsp.func	= 'dspmodel';
    Ret.dsp.label	= {'Time in Sec'; 'SD Units'};
    Ret.dsp.args	= {};
    Ret.stm       = ExpPar.stm;
    Ret.stm.time  = epoch.time;
    Ret.dx        = DX;
    Ret.dat       = subGetHemo(ExpPar,epoch,DX,'gampdf',0,'adapt');
   case { 'hemo' }
    Ret.session   = Ses.name;
    Ret.grpname   = grp.name;
    Ret.ExpNo     = ExpNo;
    Ret.dir.dname = 'model';
    Ret.dsp.func	= 'dspmodel';
    Ret.dsp.label	= {'Time in Sec'; 'SD Units'};
    Ret.dsp.args	= {};
    Ret.stm       = ExpPar.stm;
    Ret.stm.time  = epoch.time;
    Ret.dx        = DX;
    Ret.dat       = subGetHemo(ExpPar,epoch,DX,'gampdf',0,'boxcar');
   otherwise
    fprintf(' mkmultreg ERROR: ''%s'' not supported yet.\n',Mode);
    keyboard
  end
  mdl{NM} = Ret;
end;

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function returns 'pulses'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Wv = subGetAdapt(ExpPar,epoch,DX,HemoDelay,HemoTail)
% use epoch.time (timing by event file) for precise modeling.
VAL         = epoch.val{1};
T           = epoch.time{1};
LEN         = round(sum(ExpPar.stm.dt{1})/DX);

% make sure to cover a whole time series, even if stimulus durations
% are randomized.
if isstruct(ExpPar.pvpar),
  if round(sum(ExpPar.stm.dt{1})/ExpPar.pvpar.imgtr) ~= ExpPar.pvpar.nt,
    LEN = round(ExpPar.pvpar.nt*ExpPar.pvpar.imgtr/DX);
  end
end

HemoDelay = floor(HemoDelay/DX);
HemoTail  = floor(HemoTail/DX);

TS          = floor(T/DX) + HemoDelay + 1;
TE          = floor(T/DX) + HemoTail;
TE(end+1)   = LEN;

Wv = zeros(LEN,1);
for N = 1:length(VAL),
  if VAL(N) ~= 0,
    ts = TS(N);
    te = TE(N+1);
    if ts > LEN,  ts = LEN;  end
    if te > LEN,  te = LEN;  end
    tmp = VAL(N)*exp(-[0:LEN]/length(ts:te));
    Wv(ts:te) = tmp(1:length(ts:te));
  end
end
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function returns 'boxcar'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Wv = subGetBoxCar(ExpPar,epoch,DX,HemoDelay,HemoTail)
% use epoch.time (timing by event file) for precise modeling.
VAL         = epoch.val{1};
T           = epoch.time{1};
LEN         = round(sum(ExpPar.stm.dt{1})/DX);

% make sure to cover a whole time series, even if stimulus durations
% are randomized.
if isstruct(ExpPar.pvpar),
  if round(sum(ExpPar.stm.dt{1})/ExpPar.pvpar.imgtr) ~= ExpPar.pvpar.nt,
    LEN = round(ExpPar.pvpar.nt*ExpPar.pvpar.imgtr/DX);
  end
end

HemoDelay = floor(HemoDelay/DX);
HemoTail  = floor(HemoTail/DX);

TS          = floor(T/DX) + HemoDelay + 1;
TE          = floor(T/DX) + HemoTail;
TE(end+1)   = LEN;

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
function Wv = subGetHemo(ExpPar,epoch,DX,Model,DoDiff,InputFunction)
IRTDX = 0.01;      % time resolution for dat/kernel, decimated later.

% HemoDely/HemoTail should be represented by "IR", not boxcar.
if strcmp(InputFunction,'boxcar'),
  Wv = subGetBoxCar(ExpPar,epoch,IRTDX,0,1);
else
  Wv = subGetAdapt(ExpPar,epoch,IRTDX,0,1);
end;

if exist('DoDiff','var') && DoDiff == 1,
  Wv = diff([Wv(1);Wv(:)]);		% Wv(1) to keep the length of Wv.
  Wv = abs(Wv);					% rectify it
end

switch lower(Model),
 case { 'gamma','gampdf','gammapdf'}
  IRTLEN = round(25/IRTDX);     % 25 sec duration
  IRT = [0:IRTLEN-1] * IRTDX;	% see impresp.mat/supir.t
  Lamda = 10;
  Theta = 0.4089;
  IR = gampdf(IRT,Lamda,Theta);
 otherwise
  fprintf(' ERROR mkmultreg.subGetHemo :');
  fpritnf(' ''%s'' not supported yet.\n',Model);
  keyboard
end

sel = 1:length(Wv);
Wv = conv(Wv(:),IR(:));
Wv = Wv(sel);

% now decimate to DX
Wv = decimate(Wv,DX/IRTDX);

LEN = round(sum(ExpPar.stm.dt{1})/DX);
% make sure to cover a whole time series, even if stimulus durations
% are randomized.
if isstruct(ExpPar.pvpar),
  if round(sum(ExpPar.stm.dt{1})/ExpPar.pvpar.imgtr) ~= ExpPar.pvpar.nt,
    LEN = round(ExpPar.pvpar.nt*ExpPar.pvpar.imgtr/DX);
  end
end

if length(Wv) > LEN,  Wv = Wv(1:LEN);  end
Wv = Wv/max(abs(Wv));
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
if isfield(grp,'model'),
  Epoch.model = grp.model;
end;
return;

