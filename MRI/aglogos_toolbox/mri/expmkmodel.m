function varargout = expmkmodel(Ses,GrpExp,ModelStr,varargin)
%EXPMKMODEL - Creates a model for corr/glm analysis
%  MODEL = EXPMKMODEL(SES,EXPNO,MODELSTR,...) creates a model for 
%  corr/glm analysis.
%
%  MODELSTR can be a string of
%    boxcar, hemo, fhemo, irhemo
%    Delta, Theta, ThetaR, Alpha, Beta, Gamma, LFP, LFPR, LFPN, MUA
%    blpSpc-alpha,blpSpc-mua, as blpSpc-(bandname)
%    Sdf, pLfpL, pLfpM, pLfpH, pMua, vital
%    trial[X], trialhemo[X], trialfhemo[X]
%    stim[X], stimhemo[X], stimfhemo[X]
%
%  MODELSTR can be also  
%    anyone of roi-name,
%    function handle like '@myfunc'
%    a matlab file with 'MODEL' variable, like 'model.mat[1:2]' or 'model_%03d.mat[1]'.
%
%  If MODELSTR is a name of neural signal then it will be convolved with
%  'gampdf' as a kernel.
%
%  If MODELSTR has a prefix of 'inv' then model will be inversed (*-1).
%
%  Channel selection for neural signals can be specified as postfix of the signal name.
%  For examples, channel 1 of 'gamma' as 'gamma[1]' or 
%  average of [1,3:4] 'mua' channels as 'mua[1,3:4]'.
%  If no channel information, then all channels will be averaged to create the model.
%
%
%  If MODELSTR is a functional handle, the program will call it.
%  For example, MODELSTR = @mymodel, then the program will call mymodel(Ses,GrpExp).
%  If MODELSTR is a string for a function handle, the program will call it.
%  For exapple, MODELSTR = '@mymodel(1)', then the program will call mymodel(1,Ses,GrpExp).
%
%  If user-defined model is simple enough (ie. just changing .val/.t),
%  then one can set GRP.xxx.model{x} as following and set use model{x}.name for 
%  .corana{x}.mdlsct and .glmana{x}.mdlsct .
%    GRP.corana{1}.mdlsct   = 'boxcar';  % normal boxcar
%    GRP.corana{2}.mdlsct   = 'step';    % will refer to model{1}
%    GRP.corana{3}.mdlsct   = 'pulse';   % will refer to model{2}
%    GRP....
%    GRP.xxx.model{1}.name  = 'step';      % model-name, must be unique
%    GRP.xxx.model{1}.type  = 'boxcar';    % kernel type, can be boxcar,hemo etc.
%    GRP.xxx.model{1}.val   = {[0 0 0 0 0 0 1 1 1 1 1 1]};
%    GRP.xxx.model{2}.name  = 'pulse';
%    GRP.xxx.model{2}.type  = 'boxcar';
%    GRP.xxx.model{2}.val   = {[0 0 0 0 0 0 1 0.4 0.3 0.2 0.1 0]};
%    % GRP.xxx.model{2}.HemoDelay = 0;  % optional for type==boxcar
%    % GRP.xxx.model{2}.HemoTail  = 0;  % optional for type==boxcar
%    GRP.xxx.model{3}.name  = 'gamma(+hemo)';
%    GRP.xxx.model{3}.type  = 'blp-gamma';
%    GRP.xxx.model{3}.HemoModel = 'gampdf';  % optional for 'blp-xxx'
%    GRP.xxx.model{4}.name  = 'gamma(-hemo)';
%    GRP.xxx.model{4}.type  = 'blp-gamma';
%    GRP.xxx.model{4}.HemoModel = 'none';
%
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
%     MODELSTR == 'trial[X]' is a boxcar for trial X.  X must be >= 0.
%                 'trialhemo[X]'    convolved with gampdf
%                 'trialfhemo[X]'   convolved with fast-gampdf
%                 'trialdthemo[X]'  derivative of 'trialhemo'
%                 'trialdtfhemo[X]' derivative of 'trialfhemo'
%
%     MODELSTR == 'stim[X]' is a boxcar for trial X.  X must be >= 0.
%                 'stimhemo[X]'    convolved with gampdf
%                 'stimfhemo[X]'   convolved with fast-gampdf
%                 'stimdthemo[X]'  derivative of 'stimhemo'
%                 'stimdtfhemo[X]' derivative of 'stimfhemo'
%
%     MODELSTR == 'blpSpc-xxx' means 'xxx' band of blpSpc, like blpSpc-alpha.
%
%     MODELSTR == 'ClnSpc-xxx' means 'xxx' band of ClnSpc, like ClnSpc-1:2500.
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
%    0.99 27.03.06 YM  supports channel selection with the postfix of 'ModelStr'.
%    1.00 30.03.06 YM  checks unique coordinates for ROI-model.
%    1.01 02.04.06 YM  supports ModelStr as GRP.xxx.model{x}.name, filename(.mat).
%    1.02 06.04.06 YM  supports roiTsPca and troiTsPca, see sigpca.m also.
%    1.03 20.04.06 YM  supports "trial[xxx]".
%    1.04 13.03.07 YM  supports 'awake' stuff.
%    1.05 27.06.07 YM  supports "stim[xxx]".
%    1.06 17.10.07 YM  supports "vfgampdf".
%    1.07 28.01.08 YM  supports "cSpc", ClnSpc convolved with HRF, and cBlp
%    1.08 13.06.08 YM  supports "blpSpc" with band selection.
%    1.09 16.06.08 YM  supports GRP.xxx.model{X}.HemoModel, ClnSpc-xxxx as model.
%    1.10 25.08.10 YM  supports "trialdt..."
%    1.11 20.09.10 YM  bug fix for gettrial.trial2obsp/Average.
%    1.12 27.01.12 YM  supports 'MriSig' and .mat like "model_%03d.mat[X]".
%    1.13 15.12.14 YM  replaced 'findstr' with 'strfind'.
%
%  See also EXPGETPAR EXPGETSTM MHEMOKERNEL

if nargin < 2,  help expmkmodel;  return;  end
if nargin < 3,  ModelStr = 'boxcar';   end;

if isa(ModelStr,'function_handle'),
  % ModelStr as a function handle.
  MODEL = feval(ModelStr,Ses,GrpExp);
elseif ischar(ModelStr) && strncmp(ModelStr,'@',1),
  % ModelStr as a string for a function handle, with a prefix of '@'
  cmdstr = strrep(ModelStr(2:end),'()','');
  idx = strfind(cmdstr,')');
  if ~isempty(idx),
    cmdstr = sprintf('%s,Ses,GrpExp)',cmdstr(1:idx(1)-1));
  else
    cmdstr = sprintf('%s(Ses,GrpExp)',cmdstr);
  end
  MODEL = eval(cmdstr);
elseif ischar(ModelStr) && ~isempty(strfind(ModelStr,'.mat')),
  MODEL = subLoadFile(Ses,GrpExp,ModelStr);
else
  MODEL = subMakeModel(Ses,GrpExp,ModelStr,varargin{:});
end


% make NaN as zero
%MODEL = sub_nan2zero(MODEL);


% return MODEL or plot it
if nargout > 0,
  varargout{1} = MODEL;
else
  if iscell(MODEL) && iscell(MODEL{1}),
    for N = 1:length(MODEL),
      subPlotModel(Ses,ModelStr,MODEL{N});
    end
  else
    subPlotModel(Ses,ModelStr,MODEL);
  end
end


return;


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function MODEL = sub_nan2zero(MODEL)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if iscell(MODEL),
  for N = 1:length(MODEL),
    MODEL{N} = sub_nan2zero(MODEL{N});
  end
  return;
end

MODEL.dat(isnan(MODEL.dat(:))) = 0;

return



% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to load a model
function MODEL = subLoadFile(Ses,GrpExp,MatFile,varargin)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
if isfield(anap,'mareats') && isfield(anap.mareats,'IRESAMPLE') && anap.mareats.IRESAMPLE,
  ExpPar.stm.voldt = anap.mareats.IRESAMPLE;
end;

if any(strfind(MatFile,'%')),
  MatFile = sprintf(MatFile,GrpExp);
end

% GET CHANNEL INFO FROM MatFile
% MatFile can be like 'mymodel.mat[1:2]'
tmpc = strfind(MatFile,'[');

if ~isempty(tmpc),
  Channel = str2num(MatFile(tmpc(1)+1:end-1));
  MatFile = MatFile(1:tmpc(1)-1);
end
if ~exist(MatFile,'file'),
  error('\n ERROR %s: file ''%s'' not found.\n',mfilename,MatFile);
  return;
end

varname = who('-file',MatFile);
idx = find(strcmpi(varname,'model'));
if isempty(idx),
  error('\n ERROR %s: ''MODEL'' structure not found in ''%s''.\n',mfilename,MatFile);
end
varname = varname{idx(1)};

% load data here...
MODEL = load(MatFile,varname);
MODEL = MODEL.(varname);

% select channel
if ~isempty(Channel),
  if iscell(MODEL),
    for N = 1:length(MODEL),
      if iscell(MODEL{N}),
        for T = 1:length(MODEL{N}),
          MODEL{N}{T}.dat = MODEL{N}{T}.dat(:,Channel);
        end
      else
        MODEL{N}.dat = MODEL{N}.dat(:,Channel);
      end
    end
  else
    MODEL.dat = MODEL.dat(:,Channel);
  end
end

% must be a vector
if iscell(MODEL),
  for N = 1:length(MODEL),
    if iscell(MODEL{N}),
      for T = 1:length(MODEL{N}),
        MODEL{N}{T}.dat = subAverageVector(MODEL{N}{T}.dat);
      end
    else
      MODEL{N}.dat = subAverageVector(MODEL{N}.dat);
    end
  end
else
  MODEL.dat = subAverageVector(MODEL.dat);
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
if isfield(anap,'mareats') && isfield(anap.mareats,'IRESAMPLE') && anap.mareats.IRESAMPLE,
  ExpPar.stm.voldt = anap.mareats.IRESAMPLE;
end;

% SET OPTIONAL PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subAssignVarargin(varargin);
if ~exist('IRDX','var') || isempty(IRDX),
  % This is sampling time to create models, not for the final model.
  IRDX = 0.01;  % 10msec, should be engough for BOLD
end
if isfield(anap,'mareats') && isfield(anap.mareats,'IRESAMPLE') && anap.mareats.IRESAMPLE,
  ExpPar.stm.voldt = anap.mareats.IRESAMPLE;
end;
if ~exist('DX','var') || isempty(DX),
  % This is the final sampling time of the model.
  DX = ExpPar.stm.voldt;
end

% IRDX should be smaller than DX
if IRDX > DX,  IRDX = DX/10;  end


if ~exist('HemoDelay','var') || isempty(HemoDelay),
  if isfield(anap,'HemoDelay') && ~isempty(anap.HemoDelay),
    HemoDelay = anap.HemoDelay;
  else
    HemoDelay = 2;
  end
end
if ~exist('HemoTail','var') || isempty(HemoTail),
  if isfield(anap,'HemoTail') && ~isempty(anap.HemoTail),
    HemoTail = anap.HemoTail;
  else
    HemoTail  = 6;
  end
end
if DX > 100,  HemoDelay = 0; HemoTail = 0;  end  % for rat.xxx

if ~exist('HemoModel','var'),
  %HemoModel = 'gampdf';
  HemoModel = '';
end
if ~exist('Channel','var'),
  Channel = [];
end
if ~exist('BandName','var'),
  BandName = '';
end
if ~exist('Sort','var'),
  Sort = '';
  if isfield(anap,'gettrial') && anap.gettrial.status > 0,
    if isfield(anap.gettrial,'sort') && ~isempty(anap.gettrial.sort),
      Sort = anap.gettrial.sort;
    else
      Sort = 'trial';
    end
    if ~exist('PreT','var') && isfield(anap.gettrial,'PreT'),
      PreT = anap.gettrial.PreT;
    end
    if ~exist('PostT','var') && isfield(anap.gettrial,'PostT'),
      PostT = anap.gettrial.PostT;
    end
  end
end
if ~exist('PreT','var')  || isempty(PreT),   PreT  = [];  end
if ~exist('PostT','var') || isempty(PostT),  PostT = [];  end
if exist('stm','var') && ~isempty(stm),
  ExpPar.stm = sctmerge(ExpPar.stm,stm);
end

% for compatibilities...
if strncmpi(ModelStr,'inv',3),
  DO_INVERSE = 1;
  ModelStr = ModelStr(4:end);
else
  DO_INVERSE = 0;
end

% Check ModelStr with GRP.xxx.model{x}.name
if isfield(grp,'model') && ~isempty(grp.model),
  for N = 1:length(grp.model),
    if strcmpi(ModelStr,grp.model{N}.name),
      if isfield(grp.model{N},'type') && ~isempty(grp.model{N}.type),
        ModelStr = grp.model{N}.type;
      end
      if isfield(grp.model{N},'v') && ~isempty(grp.model{N}.v),
        ExpPar.stm.v    = grp.model{N}.v;
      end
      if isfield(grp.model{N},'t') && ~isempty(grp.model{N}.t),
        tmpdt = {};  tmpt = {};
        for K = 1:length(grp.model{N}.t),
          tmpdt{K} = grp.model{N}.t{K}(:)' * ExpPar.stm.voldt;
          tmpt{K}  = [0 cumsum(tmpdt{K}(:)')];
        end
        ExpPar.stm.t    = tmpt;
        ExpPar.stm.dt   = tmpdt;
        ExpPar.stm.time = tmpt;
      end
      if isfield(grp.model{N},'val') && ~isempty(grp.model{N}.val),
        ExpPar.stm.val = grp.model{N}.val;
      end
      if isfield(grp.model{N},'HemoDelay') && ~isempty(grp.model{N}.HemoDelay),
        HemoDelay = grp.model{N}.HemoDelay;
      end 
      if isfield(grp.model{N},'HemoTail') && ~isempty(grp.model{N}.HemoTail),
        HemoTail = grp.model{N}.HemoTail;
      end
      if isfield(grp.model{N},'HemoModel') && ~isempty(grp.model{N}.HemoModel),
        HemoModel = grp.model{N}.HemoModel;
      end
      break;
    end
  end
end


% GET CHANNEL INFO FROM ModelStr
% ModelStr can be like gamma[1:2]
tmpc = strfind(ModelStr,'[');
if ~isempty(tmpc),
  Channel = eval(ModelStr(tmpc(1):end));
  ModelStr = ModelStr(1:tmpc(1)-1);
end
% this may cause problem when ModelStr is 'v1'...
%ChannelStr = regexprep(ModelStr,'[A-Za-z ]','');
%if ~isempty(ChannelStr),  Channel = eval(ChannelStr);  end
%ModelStr = regexprep(ModelStr,'[1-9\[\]:,]','');
%ModelStr = deblank(ModelStr);

tmpc = strfind(ModelStr,'-');
if ~isempty(tmpc),
  BandName = ModelStr(tmpc(1)+1:end);
  ModelStr = ModelStr(1:tmpc(1)-1);
end



% check for blp-band
blpbands = {...
    'evp', 'delta', 'theta', 'dethe','alpha','nm1','nm2','gamma','hgamma','mua',...
    'dethe','alpha','nm1','nm2','gamma','hgamma','mua',...
    'Delta','Theta','ThetaR','Alpha','Beta','Gamma','LFP','LFPR','LFPN','MUA',...
    'ep','stmnm','nm','stm','lfp','mua','nMod' };
if any(strcmpi(blpbands,ModelStr)),
  % ModelStr is given by band name for blp
  BandName = ModelStr;
  ModelStr = 'blp';
end
% ANAP.siggetblp.band{ 1}  = {[   1     8] 'dethe'    'LFP',  0.5};
% ANAP.siggetblp.band{ 2}  = {[   8    12] 'alpha'  'LFP',  4};
% ANAP.siggetblp.band{ 3}  = {[  12    24] 'nm1'    'LFP',  6};
% ANAP.siggetblp.band{ 4}  = {[  24    40] 'nm2'    'LFP',  8};
% ANAP.siggetblp.band{ 5}  = {[  60   100] 'gamma'  'LFP', 20};
% ANAP.siggetblp.band{ 6}  = {[ 120   250] 'hgamma' 'LFP', 60};
% ANAP.siggetblp.band{ 7}  = {[1000  3000] 'mua'    'MUA', 60};
% OR
% EEG detla(0-4), theta(4-8), alpha(8-12), beta(12-24), gamma(24-130);
% ANAP.siggetblp.band{ 1}  = {[   0     2] 'evp'    'LFP',  0};   % No Envelope-filter
% ANAP.siggetblp.band{ 2}  = {[   1     4] 'delta'  'LFP',  2};
% ANAP.siggetblp.band{ 3}  = {[   4.1   8] 'theta'  'LFP',  4};
% ANAP.siggetblp.band{ 4}  = {[   8.1  12] 'alpha'  'LFP',  4};
% ANAP.siggetblp.band{ 5}  = {[  12.1  24] 'nm1'    'LFP', 10};
% ANAP.siggetblp.band{ 6}  = {[  24.1  40] 'nm2'    'LFP', 10};
% ANAP.siggetblp.band{ 7}  = {[  60   100] 'gamma'  'LFP', 20};
% ANAP.siggetblp.band{ 8}  = {[ 120   250] 'hgamma' 'LFP', 20};
% ANAP.siggetblp.band{ 9}  = {[1000  3000] 'mua'    'MUA', 20};
% OR
% info.band{ 1}  = {[   0     4] 'ep'    'LFP',  0};    % Evoked potential
% info.band{ 2}  = {[   4    12] 'stmnm' 'LFP',  2};    % Stim-related & Neuromodulatory?
% info.band{ 3}  = {[  15    60] 'nm'    'LFP',  4};    % Stim-unrelated; Neuromodulatory
% info.band{ 4}  = {[  70   110] 'stm'   'LFP',  4};    % Stim-related; independent of MUA (50%)
% info.band{ 5}  = {[  10   110] 'lfp'   'LFP',  4};    % Traditional LFPs
% info.band{ 6}  = {[ 400  3000] 'mua'   'MUA', 45};    % Traditional Analog MUA

if isempty(Sort) || strcmpi(Sort,'none'),
  DO_SORTING = 0;
else
  DO_SORTING = 1;
end
%DO_SORTING = ~isempty(Sort) 

ROI_LOAD = 0;  % flag for roiTs/troiTs, if 1, then no need to correct length of .dat.
% NOW MAKE THE MODEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch lower(ModelStr),
 case { 'boxcar' }
  IRDX = DX;
  HemoModel = 'none';
  DAT = subGetBoxCar(ExpPar,DX,HemoDelay,HemoTail,grp);
 case { 'boxcar0' }
  IRDX = DX;
  HemoModel = 'none';
  DAT = subGetBoxCar(ExpPar,DX,0,0,grp);
 case { 'spmhrf' }
  HemoModel = 'spmhrf';
  DAT = subGetBoxCar(ExpPar,IRDX,0,0,grp);
  IR.name     = 'spmhrf';
  IR.dx       = IRDX;
  IR.info     = [5 12 1 1 6 0 25];
  IR.dat      = spm_hrf(IR.dx,IR.info);
  DAT = subConvolveData(DAT,IR.dat(:),0);
 case { 'hemo', 'dthemo' }
  HemoModel = 'gampdf';
  DAT = subGetBoxCar(ExpPar,IRDX,0,0,grp);
  IR = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);
  if strcmpi(ModelStr,'dthemo')
    DAT1 = DAT;
    DAT(:) = 0;
    %DAT = zeros(length(DAT1),1);
    DT = diff(DAT1);
    DAT(1:length(DT)) = DT;
  end
 case { 'fhemo','fasthemo', 'dtfhemo' }
  HemoModel = 'fgampdf';
  DAT = subGetBoxCar(ExpPar,IRDX,0,0,grp);
  IR = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);
  if strcmpi(ModelStr,'dtfhemo')
    DAT1 = DAT;
    DAT(:) = 0;
    %DAT = zeros(length(DAT1),1);
    DT = diff(DAT1);
    DAT(1:length(DT)) = DT;
  end
 case { 'hipp', 'mnkhipp', 'pl', 'sr', 'cx', 'th'};
  HemoModel = 'hipp';
  DAT = subGetBoxCar(ExpPar,IRDX,0,0,grp);
  IR = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);
 
 case { 'trialhipp','trialdthipp', 'dttrialhipp' }
  trials = Channel;  Channel = [];
  HemoModel = 'hipp';
  ExpPar.stm = subUpdateStimVal(ExpPar,trials,[]);
  DAT = subGetBoxCar(ExpPar,IRDX,0,0,grp);
  IR  = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);
  if any(strcmpi(ModelStr,{'trialdthipp', 'dttrialhipp'})),
    DT = diff(DAT);
    DAT(1:length(DT)) = DT;
  end
 case {'stimhipp','stimdthipp','dtstimhipp'}
  stimid = Channel;  Channel = [];
  HemoModel = 'hipp';
  ExpPar.stm = subUpdateStimVal(ExpPar,[],stimid);
  DAT = subGetBoxCar(ExpPar,IRDX,0,0,grp);
  IR  = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);
  if any(strcmpi(ModelStr,{'stimdthipp','dtstimhipp'})),
    DT = diff(DAT);
    DAT(1:length(DT)) = DT;
  end
 
 case { 'vfhemo','veryfasthemo' }
  HemoModel = 'vfgampdf';
  DAT = subGetBoxCar(ExpPar,IRDX,0,0,grp);
  IR = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);
 case { 'irhemo','ir' }
  HemoModel = 'ir';
  DAT = subGetBoxCar(ExpPar,IRDX,0,0,grp);
  IR = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);
 case { 'hemodiff' }
  HemoModel = 'gampdf';
  DAT = subGetBoxCar(ExpPar,IRDX,0,0,grp);
  DAT = diff([DAT(1);DAT(:)]);		% DAT(1) to keep the length of DAT.
  DAT = abs(DAT);					% rectify it
  IR = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);
 case { 'cohen', 'dtcohen' }
  HemoModel = 'Cohen';
  DAT = subGetBoxCar(ExpPar,IRDX,0,0,grp);
  IR = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);
  if strcmpi(ModelStr,'dtcohen')
    DAT1 = DAT;
    DAT(:) = 0;
    %DAT = zeros(length(DAT1),1);
    DT = diff(DAT1);
    DAT(1:length(DT)) = DT;
  end

 case {'opt', 'dtopt'}
  HemoModel = 'opt';
  DAT = subGetBoxCar(ExpPar,IRDX,0,0,grp);
  IR = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);
  if strcmpi(ModelStr,'dtopt')
    DAT1 = DAT;
    DAT(:) = 0;
    %DAT = zeros(length(DAT1),1);
    DT = diff(DAT1);
    DAT(1:length(DT)) = DT;
  end
  
 case { 'trial' ,'trialboxcar' , 'boxcartrial' }
  IRDX = DX;
  HemoModel = 'none';
  trials = Channel;  Channel = [];
  ExpPar.stm = subUpdateStimVal(ExpPar,trials,[]);
  DAT = subGetBoxCar(ExpPar,DX,HemoDelay,HemoTail,grp);
 case { 'trialhemo','trialdthemo', 'dttrialhemo' }
  trials = Channel;  Channel = [];
  HemoModel = 'gampdf';
  ExpPar.stm = subUpdateStimVal(ExpPar,trials,[]);
  DAT = subGetBoxCar(ExpPar,IRDX,0,0,grp);
  IR = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);
  if any(strcmpi(ModelStr,{'trialdthemo','dttrialhemo'})),
    DT = diff(DAT);
    DAT(1:length(DT)) = DT;
  end
 case { 'trialfhemo','trialdtfhemo', 'dttrialfhemo' }
  trials = Channel;  Channel = [];
  HemoModel = 'fgampdf';
  ExpPar.stm = subUpdateStimVal(ExpPar,trials,[]);
  DAT = subGetBoxCar(ExpPar,IRDX,0,0,grp);
  IR  = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);
  if any(strcmpi(ModelStr,{'trialdtfhemo', 'dttrialfhemo'})),
    DT = diff(DAT);
    DAT(1:length(DT)) = DT;
  end
 case { 'trialvfhemo','trialdtvfhemo', 'dttrialvfhemo' }
  trials = Channel;  Channel = [];
  HemoModel = 'vfgampdf';
  ExpPar.stm = subUpdateStimVal(ExpPar,trials,[]);
  DAT = subGetBoxCar(ExpPar,IRDX,0,0,grp);
  IR  = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);
  if any(strcmpi(ModelStr,{'trialdtvfhemo', 'dttrialvfhemo'})),
    DT = diff(DAT);
    DAT(1:length(DT)) = DT;
  end
 case { 'trialcohen','trialdtcohen', 'dttrialcohen' }
  trials = Channel;  Channel = [];
  HemoModel = 'Cohen';
  ExpPar.stm = subUpdateStimVal(ExpPar,trials,[]);
  DAT = subGetBoxCar(ExpPar,IRDX,0,0,grp);
  IR  = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);
  if any(strcmpi(ModelStr,{'trialdtcohen', 'dttrialcohen'})),
    DT = diff(DAT);
    DAT(1:length(DT)) = DT;
  end
  
 case {'stim','stimboxcar'}
  IRDX = DX;
  HemoModel = 'none';
  stimid = Channel;  Channel = [];
  ExpPar.stm = subUpdateStimVal(ExpPar,[],stimid);
  DAT = subGetBoxCar(ExpPar,DX,HemoDelay,HemoTail,grp);
 case {'stimhemo','stimdthemo','dtstimhemo'}
  stimid = Channel;  Channel = [];
  HemoModel = 'gampdf';
  ExpPar.stm = subUpdateStimVal(ExpPar,[],stimid);
  DAT = subGetBoxCar(ExpPar,IRDX,0,0,grp);
  IR  = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);
  if any(strcmpi(ModelStr,{'stimdthemo','dtstimhemo'})),
    DT = diff(DAT);
    DAT(1:length(DT)) = DT;
  end
 case {'stimfhemo','stimdtfhemo','dtstimfhemo'}
  stimid = Channel;  Channel = [];
  HemoModel = 'fgampdf';
  ExpPar.stm = subUpdateStimVal(ExpPar,[],stimid);
  DAT = subGetBoxCar(ExpPar,IRDX,0,0,grp);
  IR  = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);
  if any(strcmpi(ModelStr,{'stimdtfhemo','dtstimfhemo'})),
    DT = diff(DAT);
    DAT(1:length(DT)) = DT;
  end
 case {'stimcohen','stimdtcohen','dtstimcohen'}
  stimid = Channel;  Channel = [];
  HemoModel = 'Cohen';
  ExpPar.stm = subUpdateStimVal(ExpPar,[],stimid);
  DAT = subGetBoxCar(ExpPar,IRDX,0,0,grp);
  IR  = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);
  if any(strcmpi(ModelStr,{'stimdtcohen','dtstimcohen'})),
    DT = diff(DAT);
    DAT(1:length(DT)) = DT;
  end
  
 case { 'trialopt','trialdtopt', 'dttrialopt' }
  trials = Channel;  Channel = [];
  HemoModel = 'opt';
  ExpPar.stm = subUpdateStimVal(ExpPar,trials,[]);
  DAT = subGetBoxCar(ExpPar,IRDX,0,0,grp);
  IR  = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);
  if any(strcmpi(ModelStr,{'trialdtopt', 'dttrialopt'})),
    DT = diff(DAT);
    DAT(1:length(DT)) = DT;
  end
 case {'stimopt', 'stimdtopt','dtstimopt'}
  stimid = Channel;  Channel = [];
  HemoModel = 'opt';
  ExpPar.stm = subUpdateStimVal(ExpPar,[],stimid);
  DAT = subGetBoxCar(ExpPar,IRDX,0,0,grp);
  IR  = mhemokernel(HemoModel,IRDX,25);
  DAT = subConvolveData(DAT,IR.dat(:),0);
  if any(strcmpi(ModelStr,{'stimdtopt','dtstimopt'})),
    DT = diff(DAT);
    DAT(1:length(DT)) = DT;
  end
 
 case lower({ 'pLfpL', 'pLfpM', 'pLfpH' ,'pMua', 'Sdf' }),
  if isempty(HemoModel),  HemoModel = 'gampdf';  end
  DAT = subGetNeuSig(Ses,GrpExp,ModelStr,IRDX, HemoModel, Channel);
  
 case lower({ 'rmsTs', 'rmsCln', 'rmsBlp' }),
  if isempty(HemoModel),  HemoModel = 'gampdf';  end
  DAT = subGetNeuSig(Ses,GrpExp,ModelStr,IRDX, HemoModel, Channel);
  
 case lower({ 'cSpc','ocSpc','cBlp' }),
  if isempty(HemoModel),  HemoModel = 'none';  end
  %HemoModel = 'none';
  IRDX = DX;
  DAT = subGetNeuSig(Ses,GrpExp,ModelStr,IRDX, HemoModel, Channel);

 case lower({ 'blp' }),
  if isempty(HemoModel),  HemoModel = 'gampdf';  end
  USE_TBLP = 0;
  % use tblp only when tblp is converted into a obsp !!!!
  if isfield(anap,'gettrial') && anap.gettrial.status > 0,
    if isfield(anap.gettrial,'trial2obsp') && anap.gettrial.trial2obsp > 0,
      USE_TBLP = 1;
      DO_SORTING = 0;
    end
    if ~isnumeric(GrpExp),
      USE_TBLP = 1;
      DO_SORTING = 0;
    end
  end
  [DAT stm] = subGetBlp(Ses,GrpExp,IRDX, BandName, HemoModel, Channel, USE_TBLP);
 
 case lower({ 'blpSpc' }),
  if isempty(HemoModel),  HemoModel = 'none';  end
  %HemoModel = 'none';
  IRDX = DX;
  LIM_FREQ = [0.04 0.11];  % 0.05  0.1, sometimes blpSpc's 0.1 is a bit bigger than 0.1
  DAT = subGet_blpSpc(Ses,GrpExp,BandName,IRDX, HemoModel,Channel,LIM_FREQ);

 case lower({ 'ClnSpc' }),
  if isempty(HemoModel),  HemoModel = 'gampdf';  end
  IRDX = DX;
  LIM_FREQ = [0.5 2500];
  DAT = subGet_ClnSpc(Ses,GrpExp,BandName,IRDX, HemoModel,Channel,LIM_FREQ);
  
 %case { lower(Ses.roi.names) 'all' 'roiall' 'allroi' },
 case lower({Ses.roi.names{:} 'all' 'roiall' 'allroi'}),
  if isempty(HemoModel),  HemoModel = 'none';  end
  IRDX = DX;
  ROI_LOAD = 1;
  if exist('MriSig','var'),
    DO_SORTING = 0;
    [DAT stm] = subGetRoiSig(Ses,GrpExp,ModelStr,MriSig);
  else
    MriSig = 'roiTs';
    % use troiTs only when troiTs is converted into a obsp !!!!
    if isfield(anap,'gettrial') && anap.gettrial.status > 0,
      if isfield(anap.gettrial,'trial2obsp') && anap.gettrial.trial2obsp > 0,
        MriSig = 'troiTs';
        DO_SORTING = 0;
      end
      if ~isnumeric(GrpExp),
        USE_TROITS = 'troiTs';
        DO_SORTING = 0;
      end
    end
    [DAT stm] = subGetRoiSig(Ses,GrpExp,ModelStr,MriSig);
  end
  
 case { 'vital','pleth' }
  if isempty(HemoModel),  HemoModel = 'none';  end
  %HemoModel = 'none';
  DAT = subGetVital(Ses,ExpNo(1),IRDX, HemoModel);
  
 case lower({ 'roiTsPca', 'troiTsPca' }),
  if isempty(HemoModel),  HemoModel = 'none';  end
  IRDX = DX;
  ROI_LOAD = 0;
  USE_TROITS = 0;
  % use troiTsPca only when troiTs is converted into a obsp !!!!
  if isfield(anap,'gettrial') && anap.gettrial.status > 0,
    if isfield(anap.gettrial,'trial2obsp') && anap.gettrial.trial2obsp > 0,
      USE_TROITS = 1;
      DO_SORTING = 0;
    end
    if ~isnumeric(GrpExp),
      USE_TROITS = 1;
      DO_SORTING = 0;
    end
  end
  [DAT stm] = subGetRoiPcaSig(Ses,GrpExp,ModelStr,USE_TROITS,Channel);
 
 otherwise
  error('%s ERROR: ''%s'' not supported yet or not in ROI.names in the session file.\n',mfilename,ModelStr);
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
if ~isempty(Sort) && ~strcmpi(Sort,'none'),
  if DO_SORTING > 0,
    spar = getsortpars(Ses,ExpNo(1));
    if any(strcmpi({'stim','stimulus'},Sort)),
      spar = spar.stim;
    else
      spar = spar.(Sort);
    end
    MODEL.dat = DAT;
    MODEL = sigsort(MODEL,spar,PreT,PostT,0);
    if ~iscell(MODEL),  MODEL = { MODEL };  end
    if isfield(anap.gettrial,'Average') && anap.gettrial.Average > 0,
      if isfield(anap.gettrial,'trial2obsp') && anap.gettrial.trial2obsp == 0,
        for N = 1:length(MODEL),
          MODEL{N}.dat = subAverageVector(MODEL{N}.dat);
        end
      end
    end
    if isfield(anap.gettrial,'trial2obsp') && anap.gettrial.trial2obsp > 0,
      if isfield(anap.gettrial,'Average') && anap.gettrial.Average > 0
        MODEL = trial2obsp(MODEL,'mean');
      else
        MODEL = trial2obsp(MODEL,'none');
      end
    end
  else
    if iscell(DAT),
      % need to update .stm with that of sorted one.
      if iscell(DAT{1}),
        for N = 1:length(DAT),
          tmpmodel{N} = repmat({MODEL},size(DAT{N}));
        end
        MODEL = tmpmodel;  clear tmpmodel;
      else
        MODEL = repmat({MODEL},size(DAT));
      end
      for N = 1:length(MODEL),
        if iscell(DAT{N}),
          for K = 1:length(DAT{N}),
            MODEL{N}{K}.dat = DAT{N}{K};
            MODEL{N}{K}.stm = stm{N}{K};
          end
        else
          MODEL{N}.dat = DAT{N};
          MODEL{N}.stm = stm{N};
        end
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
if ROI_LOAD == 0 && ~isempty(Sort) && ~strcmpi(Sort,'none'),
  if strcmpi(Sort,'trial') && ~isawake(grp) && ~any(PreT) && ~any(PostT),
    if iscell(MODEL),
      for N = 1:length(MODEL),
        if iscell(MODEL{N}),
          for K = 1:length(MODEL{N}),
            LEN = round(sum(MODEL{N}{K}.stm.dt{1})/MODEL{N}{K}.dx);
            MODEL{N}{K}.dat = subFixDatLength(MODEL{N}{K}.dat,LEN);
          end
        else
          LEN = round(sum(MODEL{N}.stm.dt{1})/MODEL{N}.dx);
          MODEL{N}.dat = subFixDatLength(MODEL{N}.dat,LEN);
        end
      end
    else
      LEN = round(sum(MODEL.stm.dt{1})/MODEL.dx);
      MODEL.dat = subFixDatLength(MODEL.dat,LEN);
    end
  end
elseif ROI_LOAD == 0,
  LEN = round(sum(MODEL.stm.dt{1})/MODEL.dx);
  if MODEL.dx == ExpPar.stm.voldt && isstruct(ExpPar.pvpar),
    if round(sum(MODEL.stm.dt{1})/ExpPar.pvpar.imgtr) ~= ExpPar.pvpar.nt,
      LEN = round(ExpPar.pvpar.nt*ExpPar.pvpar.imgtr/MODEL.dx);
    end
  end
  MODEL.dat = subFixDatLength(MODEL.dat,LEN);
end

% LAST CHECK FOR LENGTH
% ExpNo = MODEL.ExpNo;
% if length(ExpNo)>1,
%   ExpNo = ExpNo(1);
% end;
% tmp = sigload(MODEL.session,ExpNo,'roiTs');
% if iscell(tmp), tmp=tmp{1}; end;
% if size(MODEL.dat,1) > size(tmp.dat,1),
%   MODEL.dat = MODEL.dat(1:size(tmp.dat,1));
% elseif size(MODEL.dat,1) < size(tmp.dat,1),
%   L = size(tmp.dat,1) - size(MODEL.dat,1);
%   MODEL.dat = cat(1,MODEL.dat,zeros(L,1));
%   fprintf('Model was zero padded (N=%d)\n', L);
% end;

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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function STM = subUpdateStimVal(EXPPAR,TRIALS,STIMID)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

EVT = EXPPAR.evt;
STM = EXPPAR.stm;

% In the converted Alexander Rauch files the EVT.obs{1} does not have the endE and other
% fields
% For example:
%   adflen: 3.0014e+005
%   beginE: 0
%     endE: 3.0011e+005
%    mri1E: 33.2122
%   trialE: [10x1 double]
%     fixE: [0x1 double]
%        t: [30x1 double]
% QUICK-FIX!!!               
if ~isfield(EVT.obs{1},'endE'),
  EVT.obs{1}.endE = EVT.obs{1}.times.end;
end;


if ~isempty(TRIALS) && isfield(EVT.obs{1}.times,'ttype') && isfield(EVT.obs{1},'trialID'),
  ttimes = EVT.obs{1}.times.ttype/1000;  % trial time in sec
  ttype  = EVT.obs{1}.trialID;           % trial ID
  ttimes(end+1) = EVT.obs{1}.endE/1000;  % obs-end in sec
  for N = 1:length(ttype),
    if any(TRIALS == ttype(N)),  continue;  end
    ts = ttimes(N);
    te = ttimes(N+1);
    idx = find(STM.time{1} >= ts & STM.time{1} < te);
    STM.val{1}(idx) = 0;
  end
end

if ~isempty(STIMID),
  for N = 1:length(STM.v{1}),
    if any(STIMID == STM.v{1}(N)),  continue;  end
    STM.val{1}(N) = 0;
  end
end

  
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function returns 'boxcar'
function Wv = subGetBoxCar(ExpPar,DX,HemoDelay,HemoTail,grp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% use epoch.time (timing by event file) for precise modeling.
VAL = ExpPar.stm.val{1};
T   = ExpPar.stm.time{1};
DT  = ExpPar.stm.dt{1};
LEN = round(sum(ExpPar.stm.dt{1})/DX);
% make sure to cover a whole time series, even if stimulus durations
% are randomized.
if isstruct(ExpPar.pvpar),
  if round(sum(ExpPar.stm.dt{1})/ExpPar.pvpar.imgtr) ~= ExpPar.pvpar.nt,
    LEN = round(ExpPar.pvpar.nt*ExpPar.pvpar.imgtr/DX);
  end
end

if 0,
  HemoDelay = floor(HemoDelay/DX);
  HemoTail  = floor(HemoTail/DX);
  % +1 for matlab indexing
  TS = floor(T/DX) + 1 + HemoDelay;
  TE = floor(T/DX) + 1 + HemoTail - 1;
else
  % +1 for matlab indexing
  TS = floor((T+HemoDelay)/DX) + 1;
  if HemoTail > 0,
    TE = floor((T+HemoTail)/DX) + 1;
  else
    TE = floor((T+HemoTail)/DX);
  end
end
if isawake(grp),
  TE(1) = 1;
  for N = 1:length(TS),
    if HemoTail > 0,
      TE(N+1) = floor((T(N)+DT(N)+HemoTail)/DX) + 1;
    else
      TE(N+1) = floor((T(N)+DT(N)+HemoTail)/DX);
    end
  end
end
if isoptimaging(grp),
  TE(1) = 1;
  for N = 1:length(TS),
    if HemoTail > 0,
      TE(N+1) = floor((T(N)+DT(N)+HemoTail)/DX) + 1;
    else
      TE(N+1) = floor((T(N)+DT(N)+HemoTail)/DX);
    end
  end
end

TE(end+1) = LEN;


Wv = zeros(LEN,1);

for N = 1:length(VAL),
  if VAL(N) == 0,  continue;  end
  ts = TS(N);
  te = TE(N+1);
  if ts > LEN,  ts = LEN;  end
  if te > LEN,  te = LEN;  end
  if te < 1,       te = 1;      end
  Wv(ts:te) = VAL(N);
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
      DAT{N} = nanmean(nanmean(tblp{N}.dat,5),4);
      stm{N} = tblp{N}.stm;
      DAT{N}(isnan(DAT{N}(:))) = 0;
    end
  else
    band = tblp.info.band;
    DX   = tblp.dx;
    DAT  = nanmean(nanmean(tblp.dat,5),4);
    DAT(isnan(DAT(:))) = 0;
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

if isnumeric(Chan) && ~isempty(Chan),
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

if ~isempty(HemoModel) && ~strcmpi(HemoModel,'none'),
  %HemoModel
  IR = mhemokernel(HemoModel,IRDX,25);
  % convolve Wv.dat with the hemodynamic kernel
  DAT = subConvolveData(DAT,IR.dat,0);
  %hold on; grid on;
  %plot([0:size(DAT,1)-1]*IRDX,DAT,'y');
end



return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTOIN to return neural signals
function DAT = subGetNeuSig(Ses,ExpNo,SigName,IRDX,HemoModel,Chan)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Sig = sigload(Ses,ExpNo,SigName);
if isnumeric(Chan) && ~isempty(Chan),
  DAT = Sig.dat(:,Chan);
else
  DAT = Sig.dat;
end
DAT = subAverageVector(DAT);

DX = Sig.dx;  clear Sig;
DAT = subResampleData(DAT,DX,IRDX,0,1);

if ~isempty(HemoModel) && ~strcmpi(HemoModel,'none'),
  IR = mhemokernel(HemoModel,IRDX,25);
  % convolve Wv.dat with the hemodynamic kernel
  DAT = subConvolveData(DAT,IR.dat,0);
end
  
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTOIN to return blpSpc
function DAT = subGet_blpSpc(Ses,ExpNo,BandName,IRDX,HemoModel,Chan,LIM_FREQ)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Sig = sigload(Ses,ExpNo,'blpSpc');

iband = 0;
for N = 1:length(Sig.info.band),
  if strcmpi(BandName,Sig.info.band{N}{2}),
    iband = N;  break;
  end
end
if iband == 0,
  error(' ERROR %s: ''%s'' not found in blpSpc.',mfilename,BandName);
end

%blpSpc.dat as (t,f,chan,band,..)
if size(Sig.dat,5) > 1,
  Sig = nanmean(Sig.dat,4);
end
% band selection
Sig.dat = Sig.dat(:,:,:,iband);
% channel selection
if isnumeric(Chan) && ~isempty(Chan),
  DAT = Sig.dat(:,:,Chan);
else
  DAT = nanmean(Sig.dat,3);
end
idx = find(Sig.freq >= LIM_FREQ(1) & Sig.freq <= LIM_FREQ(2));
DAT = squeeze(nanmean(DAT(:,idx),2));


DX = Sig.dx(1);  clear Sig;
DAT = subResampleData(DAT,DX,IRDX,0,1);

if ~isempty(HemoModel) && ~strcmpi(HemoModel,'none'),
  IR = mhemokernel(HemoModel,IRDX,25);
  % convolve Wv.dat with the hemodynamic kernel
  DAT = subConvolveData(DAT,IR.dat,0);
end
  
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTOIN to return ClnSpc
function DAT = subGet_ClnSpc(Ses,ExpNo,BandName,IRDX,HemoModel,Chan,LIM_FREQ)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Sig = sigload(Ses,ExpNo,'ClnSpc');

if isempty(BandName),
  LIM_FREQ = [0.5 2500];
elseif strcmpi(BandName,'amir'),
  LIM_FREQ = [0.5 2500];
  Sig = xform(Sig,'percent','prestim');
else
  LIM_FREQ = eval(BandName);
  LIM_FREQ = [min(LIM_FREQ) max(LIM_FREQ)];
end

tmpf = (0:size(Sig.dat,2)-1)*Sig.dx(2);
fidx = find(tmpf >= LIM_FREQ(1) & tmpf <= LIM_FREQ(2));


%ClnSpc.dat as (t,f,chan,..)
if size(Sig.dat,4) > 1,
  Sig = nanmean(Sig.dat,4);
end
% channel selection
if isnumeric(Chan) && ~isempty(Chan),
  DAT = Sig.dat(:,:,Chan);
else
  DAT = nanmean(Sig.dat,3);
end
% band selection
DAT = squeeze(nanmean(DAT(:,fidx),2));

DX = Sig.dx(1);  clear Sig;
%DAT = subDo_filter(DAT,DX,[0 1/DX/2*0.8]);
DAT = subResampleData(DAT,DX,IRDX,0,1);

if ~isempty(HemoModel) && ~strcmpi(HemoModel,'none'),
  IR = mhemokernel(HemoModel,IRDX,25);
  % convolve Wv.dat with the hemodynamic kernel
  DAT = subConvolveData(DAT,IR.dat,0);
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

if exist('HemoModel','var') && ~isempty(HemoModel) && ~strcmpi(HemoModel,'none'),
  IR = mhemokernel(HemoModel,IRDX,25);
  % convolve Wv.dat with the hemodynamic kernel
  DAT = subConvolveData(DAT,IR.dat,0);
end
  
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTOIN to return roiTs data
function [DAT stm] = subGetRoiSig(Ses,GrpExp,ModelStr,MriSig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(MriSig),
  roiTs = sigload(Ses,GrpExp,MriSig);
  if ~isnumeric(GrpExp) && isempty(roiTs),
    error('\n ERROR %s: no %s in the grouped file.\n Run sesgrpmake without setting ROI models to save time-series data.\n',mfilename,MriSig);
  end
else
  roiTs = MriSig;
end
if ~iscell(roiTs),  roiTs = { roiTs };  end

if iscell(roiTs{1}),
  troiTs = roiTs;
  EPISZ = size(troiTs{1}{1}.ana);
  for T = 1:length(troiTs{1}),
    tmpTs{T}.session = roiTs{1}{T}.session;
    tmpTs{T}.grpname = roiTs{1}{T}.grpname;
    tmpTs{T}.ExpNo   = roiTs{1}{T}.ExpNo;
    tmpTs{T}.coords  = [];
    tmpTs{T}.dat     = [];
    tmpTs{T}.dx      = troiTs{1}{T}.dx;
    tmpTs{T}.stm     = troiTs{1}{T}.stm;
    for R = 1:length(troiTs),
      if any(strcmp(troiTs{R}{T}.name,ModelStr)) || any(strcmpi(ModelStr,{'all' 'roiall' 'allroi'}))
        tmpTs{T}.coords = cat(1,tmpTs{T}.coords,troiTs{R}{T}.coords);
        tmpTs{T}.dat    = cat(2,tmpTs{T}.dat,troiTs{R}{T}.dat);
      end
    end
    if isempty(tmpTs{T}.coords),
      error('\n ERROR %s: specified ROI not found.\n',mfilename);
    end
    if size(tmpTs{T}.dat,3) > 1,
      tmpTs{T}.dat = nanmean(tmpTs{T}.dat,3);
    end
    xyz = double(tmpTs{T}.coords);
    idx = sub2ind(EPISZ,xyz(:,1),xyz(:,2),xyz(:,3));
    [uidx usel] = unique(idx);
    %length(usel)
    tmpTs{T} = xform(tmpTs{T},'tosdu','prestim');
    DAT{T} = squeeze(nanmean(tmpTs{T}.dat,2));
    stm{T} = tmpTs{T}.stm;
  end
else
  EPISZ = size(roiTs{1}.ana);
  tmpTs.session = roiTs{1}.session;
  tmpTs.grpname = roiTs{1}.grpname;
  tmpTs.ExpNo   = roiTs{1}.ExpNo;
  tmpTs.coords = [];
  tmpTs.dat    = [];
  tmpTs.stm    = roiTs{1}.stm;
  tmpTs.dx     = roiTs{1}.dx;
  for R = 1:length(roiTs),
    if any(strcmp(roiTs{R}.name,ModelStr)) || any(strcmpi(ModelStr,{'all' 'roiall' 'allroi'}))
      tmpTs.coords = cat(1,tmpTs.coords,roiTs{R}.coords);
      tmpTs.dat    = cat(2,tmpTs.dat,roiTs{R}.dat);
    end
  end
  if isempty(tmpTs.coords),
    error('\n ERROR %s: specified ROI not found.\n',mfilename);
  end
  if size(tmpTs.dat,3) > 1,
    tmpTs.dat = nanmean(tmpTs.dat,3);
  end
  xyz = double(tmpTs.coords);
  idx = sub2ind(EPISZ,xyz(:,1),xyz(:,2),xyz(:,3));
  [uidx usel] = unique(idx);
  tmpTs.dat = tmpTs.dat(:,usel);
  tmpTs = xform(tmpTs,'tosdu','blank');
  %length(usel)
  DAT = squeeze(nanmean(tmpTs.dat,2));
  stm = {};
end


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTOIN to return roiTsPca data
function [DAT stm] = subGetRoiPcaSig(Ses,GrpExp,ModelStr,USE_TROITS,Channel)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if USE_TROITS,
  % use troiTs only when troiTs is converted into a obsp !!!!
  tmpTs = sigload(Ses,GrpExp,'troiTsPca');
  if ~isnumeric(GrpExp) && isempty(tmpTs),
    error('\n ERROR %s: no troiTsPca in the grouped file.\n',mfilename);
  end
  if ~iscell(tmpTs{1}),  tmpTs = { tmpTs };  end
  for R = 1:length(tmpTs),
    for T = 1:length(tmpTs{R}),
      if ~isempty(Channel),
        DAT{R}{T} = tmpTs{R}{T}.dat(:,Channel);
      else
        DAT{R}{T} = tmpTs{R}{T}.dat;
      end
      stm{R}{T} = tmpTs{R}{T}.stm;
    end
  end
else
  tmpTs = sigload(Ses,GrpExp,'roiTsPca');
  if ~isnumeric(GrpExp) && isempty(tmpTs),
    error('\n ERROR %s: no roiTsPca in the grouped file.\n',mfilename);
  end
  if ~iscell(tmpTs),  tmpTs = { tmpTs };  end
  if ~isempty(Channel),
    DAT = tmpTs.dat(:,Channel);
  else
    DAT = tmpTs.dat;
  end
  stm = {};
end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to do filtering, cutoffs as [highpass lowpass]
function DAT = subDo_filter(DAT,DX,cutoffs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if length(cutoffs) ~= 2,  return;  end
if all(cutoffs <= 0),  return;  end

nyq = 1.0/DX(1)/2;
if cutoffs(1) == 0,
  % low-pass
  [b,a] = butter(4,cutoffs(2)/nyq,'low');
elseif cutoffs(2) == 0,
  % high-pass
  [b,a] = butter(4,cutoffs(1)/nyq,'high');
else
  % band-pass
  [b,a] = butter(4,cutoffs/nyq,'bandpass');
end

if isvector(DAT),  DAT = DAT(:);  end

dlen   = size(DAT,1);
flen   = max([length(b),length(a)]);
idxfil = [flen+1:-1:2 1:dlen dlen-1:-1:dlen-flen-1];
idxsel = (1:dlen) + flen;

tmpdat  = filtfilt(b,a,DAT(idxfil,:));
DAT     = tmpdat(idxsel,:);

return


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
if p == q,  return;  end

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
      idxsel = (1:siglen) + round(mirror*p/q);
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
      if min(idxmir) > 0 && max(idxmir) <= orglen,
        idxsel = (1:siglen) + round(mirror*p/q);
        datmir = resample(DAT(idxmir,:),p,q);
        DAT = datmir(idxsel,:);
      else
        DAT = resample(DAT,p,q);
      end
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
    DAT = squeeze(nanmean(DAT,2));
  end
end

DAT(isnan(DAT(:))) = 0;

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
DAT(isnan(DAT(:))) = 0;

klen = length(KDAT);
if klen >= size(DAT,1),
  DO_MIRROR = 0;
end

if DO_MIRROR,
  idxmir = [klen+1:-1:2 1:size(DAT,1) size(DAT,1)-1:-1:size(DAT,1)-klen-1];
  idxsel = (1:size(DAT,1)) + klen;
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



% ================================================================================
% SUBFUNCTION to fix the length
function DAT = subFixDatLength(DAT,LEN)
% ================================================================================
if isvector(DAT),  DAT = DAT(:);  end
if size(DAT,1) == LEN,  return;  end

datsz = size(DAT);
DAT = reshape(DAT,[datsz(1) prod(datsz(2:end))]);

if size(DAT,1) > LEN,
  DAT = DAT(1:LEN,:);
else
  L = LEN-size(DAT,1);
  DAT(end+1:LEN,:) = DAT(end-1:-1:end-L,:);
  %DAT(end+1:LEN,:) = 0;
end

DAT = reshape(DAT, [LEN, datsz(2:end)]);

return



% ================================================================================
% SUBFUNCTION to plot the model
function subPlotModel(Ses,ModelStr,MODEL)
% ================================================================================
if isstruct(MODEL),  MODEL = {MODEL};   end

try
  grp = getgrp(Ses,MODEL{1}.grpname);
catch
  grp = [];
end

figure('Name',sprintf('%s: %s',datestr(now),mfilename));

COL = lines(256); legtxt = {};
for N = 1:length(MODEL),
  if isfield(MODEL{N},'t') && ~isemtpy(MODEL{N}.t),
    t = MODEL{N}.t;
  else
    t = (0:length(MODEL{N}.dat)-1)*MODEL{N}.dx;
  end
  plot(t, MODEL{N}.dat,'color',COL(N,:));
  hold on;
  legtxt{N} = sprintf('%d',N);
  stm = MODEL{N}.stm;
end
if length(MODEL) == 1,
  legend(strrep(ModelStr,'_','\_'));
else
  legend(legtxt);
end
grid on;
set(gca,'xlim',[0 max(t)]);
ylm = get(gca,'ylim');
if ylm(2) == 1,
  set(gca,'ylim',[ylm(1) 1.1]);
end

xlabel('Time in sec');  ylabel('Amplitude');
title(strrep(sprintf('%s: MODEL=%s DX=%.3fs',mfilename,ModelStr,MODEL{1}.dx),'_','\_'));

ylm = get(gca,'ylim');  tmph = ylm(2)-ylm(1);
h = [];
for N = 1:length(MODEL),
  if ~isfield(MODEL{N},'stm') || isempty(MODEL{N}.stm), continue;  end
  if length(MODEL{N}.stm.time{1}) == 1,
    MODEL{N}.stm.time{1}(2) = MODEL{N}.stm.time{1}(1) + MODEL{N}.stm.dt{1}(1);
  else
    MODEL{N}.stm.time{1}(end+1) = size(MODEL{N}.dat,1)*MODEL{N}.dx;
  end
  for S = 1:length(stm.v{1}),
    if any(strcmpi(MODEL{N}.stm.stmtypes{stm.v{1}(S)+1},{'blank','none'})),  continue;  end
    ts = MODEL{N}.stm.time{1}(S);
    if ~isempty(grp) && isawake(grp),
      te = ts + MODEL{N}.stm.dt{1}(S);
    elseif ts + MODEL{N}.stm.dt{1}(S) < MODEL{N}.stm.time{1}(S+1),
      te = ts + MODEL{N}.stm.dt{1}(S);
    else
      te = MODEL{N}.stm.time{1}(S+1);
      if te <= 0,  te = ts + MODEL{N}.stm.dt{1}(S);  end
    end
    tmpw = te-ts;
    if tmpw > 0,
      h(end+1) = rectangle('pos',[ts ylm(1) tmpw  tmph],...
                           'facecolor',[0.85 0.85 0.85],'linestyle','none',...
                           'tag','stim-rect');
    end
    line([ts ts],ylm,'color',[0 0 0],'tag','stim-line');
    if tmpw > 0,
      line([te te],ylm,'color',[0 0 0],'tag','stim-line');
    end
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
