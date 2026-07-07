function varargout = expmkmodel(Ses,GrpExp,ModelStr,varargin)
%EXPMKMODEL - Creates a model for corr/glm analysis
%  MODEL = EXPMKMODEL(SES,EXPNO,MODELSTR,...) creates a model for 
%  corr/glm analysis.
%
%  MODELSTR can be 
%    'boxcar','hemo','fhemo','irhemo'
%    'Delta','Theta','ThetaR','Alpha','Beta','Gamma','LFP','LFPR','LFPN','MUA'
%    'Sdf', 'pLfpL', 'pLfpM', 'pLfpH', 'pMua', 'vital'
%    anyone of roi-name, function handle
%
%  If MODELSTR is a name of neural signal then it will be convolved with
%  'gampdf' as a kernel.
%
%  If MODELSTR has a prefix of 'inv' then model will be inversed (*-1).
%
%  If MODELSTR is a functional handle, the program will call it.
%  For example, MODELSTR = @mymodel, then the program will call mymodel(Ses,GrpExp).
%  If MODELSTR is a string for a function handle, the program will call it.
%  For exapple, MODELSTR = '@mymodel(1)', then the program will call mymodel(1,Ses,GrpExp).
%
%     MODELSTR == 'boxcar' is a function of zeros during the
%           non-stimulation and of Ret.val during stimulation periods.
%           In this mode, one may set HemoDelay and HemoTail like
%           Ret = EXPMKMODEL (Ses,ExpNo,'boxcar','HemoDelay',2,'HemoTail',6).
%           As default, HemoDelay = 2s and HemoTail = 6s or, one can control values
%           by ANAP.HemoDelay/HemoTail in the description file.
%           Values for stimuli can be defined as grp.val{[0 1 0...]}.
%
%     MODELSTR == 'hemo' is a boxcar convolved with a gamma function
%           representing the hemodynamic response of the neurovascular
%           system.
%
%     MODELSTR == 'fhemo' is a boxcar convolved with a fast gamma function
%           representing the negative? hemodynamic response of the neurovascular
%           system.
%
%     MODELSTR == 'fhemo' is a boxcar convolved with a fast gamma function
%           representing the negative? hemodynamic response of the neurovascular
%           system.
%
%     MODELSTR == 'Cohen' is a boxcar convolved with Cohen's hemo dynamic response.
%
%     MODELSTR == 'roi name' is a mean time course of corresponding roi.
%
%
%  NOTE :
%    If anap.gettrial.status > 0, then the program returns MODEL(s) for each trials as
%    a cell array.
%
%
%  VERSION :
%    0.90 05.01.06 YM  clean-up from expgetstm().
%    0.91 05.01.06 YM  supports trial-based models.
%    0.92 06.01.06 YM  bug fix on 'varargin', 'boxcar'.
%    0.93 09.01.06 YM  supports where anap.gettrial.trial2obsp = 1.
%    0.94 10.01.06 YM  use hnanmean() instead of mean() and replaces NaN with 0.
%    0.95 18.01.06 YM  supports ModelStr as a function handle.
%    0.96 20.01.06 YM  supports ModelStr as a roi name.
%    0.97 25.01.06 YM  use ANAP.HemoDelay/HemoTail if exists.
%    0.98 23.03.06 YM  supports "Cohen" hemo dynamic response.
%
% See also EXPGETPAR EXPGETSTM MHEMOKERNEL

if nargin < 2,  help expmkmodel;  return;  end
if nargin < 3,  ModelStr = 'boxcar';   end;


if isa(ModelStr,'function_handle'),
  % ModelStr as a function handle.
  MODEL = feval(ModelStr,Ses,GrpExp);
elseif ischar(ModelStr) & strncmp(ModelStr,'@',1),
  % ModelStr as a string for a function handle, with a prefix of '@'
  cmdstr = strrep(ModelStr(2:end),'()','');
  idx = findstr(cmdstr,')');
  if ~isempty(idx),
    cmdstr = sprintf('%s,Ses,GrpExp)',cmdstr(1:idx(1)-1));
  else
    cmdstr = sprintf('%s(Ses,GrpExp)',cmdstr);
  end
  MODEL = eval(cmdstr);
else
  MODEL = subMakeModel(Ses,GrpExp,ModelStr,varargin);
end


% return MODEL or plot it
if nargout > 0,
  varargout{1} = MODEL;
else
  subPlotModel(Ses,ModelStr,MODEL);
end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to make a model
function MODEL = subMakeModel(Ses,GrpExp,ModelStr,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  
% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(Ses);
if ~isfield(Ses,'roi'),  Ses.roi.names = {};  end  % just to avoid error

if isnumeric(GrpExp),
  % GrpExp as an experiment number
  grp = getgrp(Ses,GrpExp);
  ExpNo = GrpExp;
else
  % GrpExp as a group name
  grp = getgrp(Ses,GrpExp);
  ExpNo = grp.exps;
end
ExpPar = expgetpar(Ses,ExpNo(1));
anap   = getanap(Ses,ExpNo(1));
  

% SET OPTIONAL PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subAssignVarargin(varargin);
if ~exist('IRDX','var') | isempty(IRDX),
  % This is sampling time to create models, not for the final model.
  IRDX = 0.01;  % 10msec, should be engough for BOLD
end
if ~exist('DX','var') | isempty(DX),
  % This is the final sampling time of the model.
  DX = ExpPar.stm.voldt;
end
if ~exist('HemoDelay','var') | isempty(HemoDelay),
  if isfield(anap,'HemoDelay') & ~isempty(anap.HemoDelay),
    HemoDelay = anap.HemoDelay;
  else
    HemoDelay = 2;
  end
end
if ~exist('HemoTail','var') | isempty(HemoTail),
  if isfield(anap,'HemoTail') & ~isempty(anap.HemoTail),
    HemoTail = anap.HemoTail;
  else
    HemoTail  = 6;
  end
end
if ~exist('HemoModel','var') | isempty(HemoModel),
  HemoModel = 'gampdf';
end
if ~exist('Channel','var'),
  Channel = [];
end
if ~exist('Sort','var'),
  Sort = '';
  if isfield(anap,'gettrial') & anap.gettrial.status > 0,
    if isfield(anap.gettrial,'sort') & ~isempty(anap.gettrial.sort),
      Sort = anap.gettrial.sort;
    else
      Sort = 'trial';
    end
    if isfield(anap.gettrial,'PreT'),
      PreT = anap.gettrial.PreT;
    end
    if isfield(anap.gettrial,'PostT'),
      PostT = anap.gettrial.PostT;
    end
  end
end
if ~exist('PreT')  | isempty(PreT),   PreT  = [];  end
if ~exist('PostT') | isempty(PostT),  PostT = [];  end
if exist('stm','var') & ~isempty(stm),
  ExpPar.stm = sctmerge(ExpPar.stm,stm);
end

% for compatibilities...
if strncmpi(ModelStr,'inv',3),
  DO_INVERSE = 1;
  ModelStr = ModelStr(4:end);
else
  DO_INVERSE = 0;
end

DO_SORTING = ~isempty(Sort);

ROI_LOAD = 0;  % flag for roiTs/troiTs, if 1, then no need to correct length of .dat.
% NOW MAKE THE MODEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch lower(ModelStr),
 case { 'boxcar' }
  IRDX = DX;
  HemoModel = 'none';
  DAT = subGetBoxCar(ExpPar,DX,HemoDelay,HemoTail);
 case { 'hemo' }
  HemoModel = 'gampdf';
  DAT = subGetBoxCar(ExpPar,IRDX,0,0);
  IR = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);
 case { 'fhemo','fasthemo' }
  HemoModel = 'fgampdf';
  DAT = subGetBoxCar(ExpPar,IRDX,0,0);
  IR = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);
 case { 'irhemo','ir' }
  HemoModel = 'ir';
  DAT = subGetBoxCar(ExpPar,IRDX,0,0);
  IR = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);
 case { 'hemodiff' }
  HemoModel = 'gampdf';
  DAT = subGetBoxCar(ExpPar,IRDX,0,0);
  DAT = diff([DAT(1);DAT(:)]);		% DAT(1) to keep the length of DAT.
  DAT = abs(DAT);					% rectify it
  IR = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);
 case { 'cohen' }
  HemoModel = 'Cohen';
  DAT = subGetBoxCar(ExpPar,IRDX,0,0);
  IR = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);

 case lower({ 'Delta','Theta','ThetaR','Alpha','Beta','Gamma','LFP','LFPR','LFPN','MUA' }),
  USE_TBLP = 0;
  % use tblp only when tblp is converted into a obsp !!!!
  if isfield(anap,'gettrial') & anap.gettrial.status > 0,
    if isfield(anap.gettrial,'trial2obsp') & anap.gettrial.trial2obsp > 0,
      USE_TBLP = 1;
      DO_SORTING = 0;
    end
  end
  [DAT stm] = subGetBlp(Ses,GrpExp,IRDX, ModelStr, HemoModel, Channel, USE_TBLP);
 %case lower({ 'tDelta','tTheta','tThetaR','tAlpha','tBeta','tGamma','tLFP','tLFPR','tLFPN','tMUA' }),
 
 case lower({ 'pLfpL', 'pLfpM', 'pLfpH' ,'pMua', 'Sdf' }),
  DAT = subGetNeuSig(Ses,GrpExp,ModelStr,IRDX, HemoModel, Channel);
  
 case lower({ 'rmsTs', 'rmsCln', 'rmsBlp' }),
  DAT = subGetNeuSig(Ses,GrpExp,ModelStr,IRDX, HemoModel, Channel);

 case lower(Ses.roi.names),
  IRDX = DX;
  ROI_LOAD = 1;
  USE_TROITS = 0;
  if 1,
    DAT = subGetRoiSig(Ses,GrpExp,ModelStr,USE_TROITS);
  else
    % use troiTs only when tblp is converted into a obsp !!!!
    if isfield(anap,'gettrial') & anap.gettrial.status > 0,
      if isfield(anap.gettrial,'trial2obsp') & anap.gettrial.trial2obsp > 0,
        USE_TBLP = 1;
        DO_SORTING = 0;
      end
    end
    [DAT stm] = subGetRoiSig(Ses,GrpExp,ModelStr,USE_TROITS);
  end
  
 case { 'vital','pleth' }
  HemoModel = 'none';
  DAT = subGetVital(Ses,ExpNo(1),IRDX, HemoModel);
 otherwise
  error('%s ERROR: ''%s'' not supported yet.\n',mfilename,ModelStr);
end

% must be a vector
DAT = subAverageVector(DAT);


% downsample to IRDX (usually volume TR)
if IRDX ~= DX,
  if IRDX > DX * 10,
    DAT = decimate(DAT,4);
    IRDX = IRDX * 4;
  end
  DAT = subResampleData(DAT,IRDX,DX,0,1);
end


% inverse data, if needed
if DO_INVERSE > 0,
  if iscell(DAT),
    for N = 1:length(DAT), DAT{N} = DAT{N} * -1;  end
  else
    DAT = DAT * -1;
  end
end


% now make MODEL structure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MODEL.session   = Ses.name;
MODEL.grpname   = grp.name;
MODEL.ExpNo     = ExpNo;
MODEL.name      = ModelStr;
MODEL.dir.dname = 'model';
MODEL.dsp.func	= 'dspmodel';
MODEL.dsp.label	= {'Time in Sec'; 'Amplitude'};
MODEL.dsp.args	= {};
MODEL.dx        = DX;
MODEL.dat       = [];
MODEL.stm       = ExpPar.stm;
MODEL.info.HemoModel = HemoModel;
MODEL.info.HemoDelay = HemoDelay;
MODEL.info.HemoTail  = HemoTail;
MODEL.info.chan = Channel;



% Do sorting if required %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(Sort) & ~strcmpi(Sort,'none'),
  if DO_SORTING > 0,
    spar = getsortpars(Ses,ExpNo(1));
    if any(strcmpi({'stim','stimulus'},Sort)),
      spar = spar.stim;
    else
      spar = spar.(Sort);
    end
    MODEL.dat = DAT;
    MODEL = sigsort(MODEL,spar,PreT,PostT);
    if ~iscell(MODEL),  MODEL = { MODEL };  end
    for N = 1:length(MODEL),
      MODEL{N}.dat = subAverageVector(MODEL{N}.dat);
    end
    if isfield(anap.gettrial,'trial2obsp') & anap.gettrial.trial2obsp > 0,
      MODEL = trial2obsp(MODEL,'mean');
    end
  else
    if iscell(DAT),
      % need to update .stm with that of sorted one.
      MODEL = repmat({MODEL},size(DAT));
      for N = 1:length(MODEL),
        MODEL{N}.dat = DAT{N};
        MODEL{N}.stm = stm{N};
      end
    else
      MODEL.dat = DAT;
      MODEL.stm = stm;
    end
  end
else
  MODEL.dat = DAT;
end


% if length is different due to conv() etc, trancate data
if ~isempty(Sort) & ~strcmpi(Sort,'none'),
  if strcmpi(Sort,'trial'),
    if iscell(MODEL),
      for N = 1:length(MODEL),
        LEN = round(sum(MODEL{N}.stm.dt{1})/MODEL{N}.dx);
        if length(MODEL{N}.dat) ~= LEN,
          MODEL{N}.dat = MODEL{N}.dat(1:LEN);
        end
      end
    else
      LEN = round(sum(MODEL.stm.dt{1})/MODEL.dx);
      if length(MODEL.dat) ~= LEN,
        MODEL.dat = MODEL.dat(1:LEN);
      end
    end
  end
elseif ROI_LOAD == 0,
  LEN = round(sum(MODEL.stm.dt{1})/MODEL.dx);
  if MODEL.dx == ExpPar.stm.voldt & isstruct(ExpPar.pvpar),
    if round(sum(MODEL.stm.dt{1})/ExpPar.pvpar.imgtr) ~= ExpPar.pvpar.nt,
      LEN = round(ExpPar.pvpar.nt*ExpPar.pvpar.imgtr/MODEL.dx);
    end
  end
  if length(MODEL.dat) ~= LEN,
    MODEL.dat = MODEL.dat(1:LEN);
  end
end



return;





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to assing options
function subAssignVarargin(INPARGS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if length(INPARGS) < 2,  return;  end
N = 1;
while N < length(INPARGS),
  assignin('caller',INPARGS{N},INPARGS{N+1});
  N = N + 2;
end
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function returns 'boxcar'
function Wv = subGetBoxCar(ExpPar,DX,HemoDelay,HemoTail)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% use epoch.time (timing by event file) for precise modeling.
VAL = ExpPar.stm.val{1};
T   = ExpPar.stm.time{1};
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



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTOIN to return neural signals (blp)
function [DAT stm] = subGetBlp(Ses,ExpNo,IRDX,BandName,HemoModel,Chan, USE_TBLP)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

anap = getanap(Ses,ExpNo);
if USE_TBLP,
  % use tblp only when tblp is converted into a obsp !!!!
  tblp = sigload(Ses,ExpNo,'tblp');
  if iscell(tblp),
    band = tblp{1}.info.band;
    DX   = tblp{1}.dx;
    for N = 1:length(tblp),
      DAT{N} = hnanmean(hnanmean(tblp{N}.dat,5),4);
      stm{N} = tblp{N}.stm;
      DAT{N}(find(isnan(DAT{N}))) = 0;
    end
  else
    band = tblp.info.band;
    DX   = tblp.dx;
    DAT  = hnanmean(hnanmean(tblp.dat,5),4);
    DAT(find(isnan(DAT))) = 0;
    stm  = tblp.stm;
  end
  clear tblp;
else
  blp = sigload(Ses,ExpNo,'blp');
  band = blp.info.band;
  DX  = blp.dx;
  DAT = blp.dat;
  stm = [];
  clear blp;
end
BAND_IDX = 0;
for N = 1:length(band),
  if strcmpi(BandName,band{N}{2}),
    BAND_IDX = N;
    break;
  end
end

if BAND_IDX == 0,
  error('%s ERROR: no ''%s'' in blp/tblp.\n',mfilename,BandName);
end

if isnumeric(Chan) & ~isempty(Chan),
  if iscell(DAT),
    for N = 1:length(DAT),
      DAT{N} = squeeze(DAT{N}(:,Chan,BAND_IDX));
    end
  else
    DAT = squeeze(DAT(:,Chan,BAND_IDX));
  end
else
  if iscell(DAT),
    for N = 1:length(DAT),
      DAT{N} = squeeze(DAT{N}(:,:,BAND_IDX));
    end
  else
    DAT = squeeze(DAT(:,:,BAND_IDX));
  end
end

DAT = subAverageVector(DAT);
DAT = subResampleData(DAT,DX,IRDX,0,1);

%figure;
%plot([0:size(DAT,1)-1]*IRDX,DAT);

if ~isempty(HemoModel) & ~strcmpi(HemoModel,'none'),
  IR = mhemokernel(HemoModel,IRDX,25);
  % convolve Wv.dat with the hemodynamic kernel
  DAT = subConvolveData(DAT,IR.dat,1);
  %hold on; grid on;
  %plot([0:size(DAT,1)-1]*IRDX,DAT,'y');
end



return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTOIN to return neural signals
function DAT = subGetNeuSig(Ses,ExpNo,SigName,IRDX,HemoModel,Chan)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Sig = sigload(Ses,ExpNo,SigName);
if isnumeric(Chan) & ~isempty(Chan),
  DAT = Sig.dat(:,Chan);
else
  DAT = Sig.dat;
end
DAT = subAverageVector(DAT);

DX = Sig.dx;  clear Sig;
DAT = subResampleData(DAT,DX,IRDX,0,1);

if ~isempty(HemoModel) & ~strcmpi(HemoModel,'none'),
  IR = mhemokernel(HemoModel,IRDX,25);
  % convolve Wv.dat with the hemodynamic kernel
  DAT = subConvolveData(DAT,IR.dat,1);
end
  
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTOIN to return the vital signal
function DAT = subGetVital(Ses,ExpNo,IRDX,HemoModel)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pleth = plethload(Ses,ExpNo);
DAT = subAverageVector(DAT);


DX = pleth.dx;  clear pleth;
DAT = subResampleData(DAT,DX,IRDX,0,1);

if exist('HemoModel','var') & ~isempty(HemoModel) & ~strcmpi(HemoModel,'none'),
  IR = mhemokernel(HemoModel,IRDX,25);
  % convolve Wv.dat with the hemodynamic kernel
  DAT = subConvolveData(DAT,IR.dat,1);
end
  
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTOIN to return roiTs data
function [DAT stm] = subGetRoiSig(Ses,GrpExp,ModelStr,USE_TROITS);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if USE_TROITS,
  % use troiTs only when tblp is converted into a obsp !!!!
  troiTs = sigload(Ses,GrpExp,'troiTs');
  if iscell(troiTs{1}),
    for N = 1:length(troiTs),
      if strcmpi(troiTs{N}{1}.name,ModelStr),
        troiTs = troiTs{N};
        break;
      end
    end
  else
    troiTs = mroitscat(mroitsget(troiTs,[],ModelStr));
  end
  for N = 1:length(troiTs),
    DAT{N} = squeeze(hnanmean(troiTs{N}.dat,2));
    stm{N} = troiTs{N}.stm;
  end
else
  roiTs = sigload(Ses,GrpExp,'roiTs');
  roiTs = mroitscat(mroitsget(roiTs,[],ModelStr));
  DAT = squeeze(hnanmean(roiTs{1}.dat,2));
end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTOIN to resample data
function DAT = subResampleData(DAT,DX,NewDX,USE_FIR,DO_MIRROR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
if iscell(DAT),
  for N = 1:length(DAT),
    DAT{N} = subResampleData(DAT{N},DX,NewDX,USE_FIR,DO_MIRROR);
  end
  return;
end

[p,q] = rat(DX/NewDX,0.0001);
if NewDX > DX,
  % downsampling
  if USE_FIR > 0,
    NewFs = 1/NewDX;
    NewFsTr = NewFs * 0.08;
    info.dB         = 60;
    info.passripple = 0.1;

    transband = NewFsTr; %transition width from passband to stopband
    fsamp = p/DX;  %note: freq of UPSAMPLED signal!
    fcuts = [NewFs/2-transband NewFs/2]; %we want cutoff to start transband before nyquist
    mags = [1 0];
    devs = [abs(1-10^(info.passripple/20)) 10^(-info.dB/20)];
    [n,Wn,beta,ftype] = kaiserord(fcuts,mags,devs,fsamp);
    n = n + rem(n,2);
    b = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');
    if DO_MIRROR,
      pqmax = max(p,q);
      orglen = size(DAT,1);
      siglen = length(resample(DAT(:,1),p,q,b));
      mirror = ceil(length(b)/pqmax)*pqmax;
      idxmir = [mirror+1:-1:2 1:orglen orglen-1:-1:orglen-mirror-1];
      idxsel = [1:siglen] + round(mirror*p/q);
      datmir = resample(DAT(idxmir,:),p,q,b);
      DAT = datmir(idxsel,:);
    else
      DAT = resample(DAT,p,q,b);
    end
  else
    if DO_MIRROR,
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
      pqmax = max(p,q);
      orglen = size(DAT,1);
      siglen = length(resample(DAT(:,1),p,q));
      mirror = ceil(length(h)/pqmax)*pqmax;
      idxmir = [mirror+1:-1:2 1:orglen orglen-1:-1:orglen-mirror-1];
      idxsel = [1:siglen] + round(mirror*p/q);
      datmir = resample(DAT(idxmir,:),p,q);
      DAT = datmir(idxsel,:);
    else
      DAT = resample(DAT,p,q);
    end
  end
elseif NewDX < DX,
  % upsampling
  DAT = resample(DAT,p,q);
end
  
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to make DAT as a vector
function DAT = subAverageVector(DAT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if iscell(DAT),
  for N = 1:length(DAT),
    DAT{N} = subAverageVector(DAT{N});
  end
  return;
end

if ~isvector(DAT),
  s = size(DAT);
  DAT = reshape(DAT,[s(1) prod(s(2:end))]);
  if size(DAT,2) > 1,
    %DAT = squeeze(mean(DAT,2));
    DAT = squeeze(hnanmean(DAT,2));
  end
end

DAT(find(isnan(DAT))) = 0;

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTOIN to make convolution
function DAT = subConvolveData(DAT,KDAT,DO_MIRROR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if iscell(DAT),
  for N = 1:length(DAT),
    DAT{N} = subConvolveData(DAT{N},KDAT,DO_MIRROR);
  end
  return;
end

KDAT = KDAT(:);
DAT(find(isnan(DAT))) = 0;

if DO_MIRROR,
  klen = length(KDAT);
  idxmir = [klen+1:-1:2 1:size(DAT,1) size(DAT,1)-1:-1:size(DAT,1)-klen-1];
  idxsel = [1:size(DAT,1)] + klen;
  for N = 1:size(DAT,2),
    %tmp = conv(DAT(idxmir,N),KDAT);
    tmp = fconv(DAT(idxmir,N),KDAT);
    DAT(:,N) = tmp(idxsel);
  end
else
  sel = 1:size(DAT,1);
  for N = 1:size(DAT,2),
    %tmp = conv(DAT(:,N),KDAT);
    tmp = fconv(DAT(:,N),KDAT);
    DAT(:,N) = tmp(sel);
  end
end

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot the model
function subPlotModel(Ses,ModelStr,MODEL);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure('Name',sprintf('%s: %s',datestr(now),mfilename));
if isstruct(MODEL),  MODEL = {MODEL};   end
COL = lines(256); legtxt = {};
for N = 1:length(MODEL),
  if isfield(MODEL{N},'t') & ~isemtpy(MODEL{N}.t),
    t = MODEL{N}.t;
  else
    t = [0:length(MODEL{N}.dat)-1]*MODEL{N}.dx;
  end
  plot(t, MODEL{N}.dat,'color',COL(N,:));
  hold on;
  legtxt{N} = sprintf('%d',N);
  stm = MODEL{N}.stm;
end
if length(MODEL) == 1,
  legend(ModelStr);
else
  legend(legtxt);
end
grid on;
set(gca,'xlim',[0 max(t)]);
xlabel('Time in sec');  ylabel('Amplitude');
title(sprintf('%s: MODEL=%s DX=%.3fs',mfilename,ModelStr,MODEL{1}.dx));

ylm = get(gca,'ylim');  tmph = ylm(2)-ylm(1);
h = [];
for N = 1:length(MODEL),
  if ~isfield(MODEL{N},'stm') | isempty(MODEL{N}.stm), continue;  end
  if length(MODEL{N}.stm.time{1}) == 1,
    MODEL{N}.stm.time{1}(2) = MODEL{N}.stm.time{1}(1) + MODEL{N}.stm.dt{1}(1);
  else
    MODEL{N}.stm.time{1}(end+1) = size(MODEL{N}.dat,1)*MODEL{N}.dx;
  end
  for S = 1:length(stm.v{1}),
    if any(strcmpi(MODEL{N}.stm.stmtypes{stm.v{1}(S)+1},{'blank','none'})),  continue;  end
    ts = MODEL{N}.stm.time{1}(S);
    te = MODEL{N}.stm.time{1}(S+1);
    tmpw = te-ts;
    h(end+1) = rectangle('pos',[ts ylm(1) tmpw  tmph],...
                         'facecolor',[0.85 0.85 0.85],'linestyle','none');
    line([ts ts],ylm,'color',[0 0 0]);
    line([te te],ylm,'color',[0 0 0]);
  end
end
% how this happens?
ylm = get(gca,'ylim');  tmph = ylm(2)-ylm(1);
for N = 1:length(h),
  pos = get(h(N),'pos');
  pos(4) = tmph;
  set(h(N),'pos',pos);
end
  

setback(h);

set(gca,'layer','top');

return;
