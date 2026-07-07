function oSig = gettrial(varargin)
%GETTRIAL - Split observation period in trials and return average response per trial.
% tSig = GETTRIAL(SIG,ANAP) 
% tSig = GETTRIAL(SES,EXPNO,SIGNAME) splits observation periods including repetition of 
% a stimulus condition.  The function will average the trial responses and will return 
% the mean of the responses.
%
% NOTE: GLM analysis may run by examining responses only during one of the trials and
% subsequently selecting the time series of the other conditions by using the same voxel
% map.
%
% Sessions may have groups with trials and groups with continuous observation periods
% (e.g. spontaneous activity, hyperc experiments, etc.). SESGETTRIAL examines the field 
% GRP.normo.anap.gettrial.status; If it's 1, then gettrial is called.
%
%
%  Parameters can be controled by ANAP.gettrial, GRPP.anap.gettrial or GRP.xxx.anap.gettrial
%    ANAP.gettrial.status     = 1;         % sort or not, 0|1
%    ANAP.gettrial.Xmethod    = 'none';    % normalization, none|tosdu|zerobase
%    ANAP.gettrial.Xepoch     = 'blank';   % normalization, blank|prestim
%    ANAP.gettrial.sort       = 'trial';   % sort by what,  trial|trialstim|stimulus
%    ANAP.gettrial.Average    = 1;         % average or not, 0|1
%    ANAP.gettrial.trial2obsp = 1;         % concatinate or not after sorting, 0|1
%  If different Xmethod for different signal, then can be set like
%    ANAP.gettrial.(signame).Xmethod = 'percent';
%    ANAP.(signame).gettrial.Xmethod = 'percent';
%
%
%  EXAMPLE :
%    >> sesgettrial(SESSION,GRPNAME);       % does for all CTG.TrialSigs
%    >> sesgettrial(SESSION,GRPNAME,'blp')  % does only for ''blp''
%    or 
%    >> blp = sigload(SESSION,ExpNo,'blp');
%    >> tblp = gettrial(blp);
%
% TO DEBUG:
%   n03qv1/1        Mutliple same trials in obsp
%   n03qv1/81       Mutliple different trials in obsp
%   m02lx1/1        No trials
%
%  VERSION :
%    0.90 NKL 20.07.04
%    0.91 YM  23.03.06 supports HemoDelay/HemoTail for tcImg/roiTs/troiTs.
%    0.92 YM  21.04.06 supports "trial2obsp".
%    0.93 YM  22.05.07 accepts "ANAP" as argument
%    0.94 YM  23.11.07 accepts gettrial(Ses,ExpNo,SigName) to save memory.
%    0.95 YM  29.04.08 supports ANAP.gettrial.(signame).
%
% See also SESGETTRIAL XFORM


if nargin == 0,  eval(sprintf('help %s',mfilename)); return;  end

ANAP = [];
% ================================================================================
if nargin >= 3, % THIS IS THE WAY THE FUNCTION IS CALLED WITHIN SESGETTRIAL
% ================================================================================
  % tSig = gettrial(Ses,ExpNo,SigName), OR
  % tSig = gettrial(Ses,ExpNo,SigName,ANAP)
  Ses   = goto(varargin{1});
  ExpNo = varargin{2};
  grp   = getgrp(Ses,ExpNo);
  Sig   = sigload(Ses,ExpNo,varargin{3});
  if nargin > 3,  ANAP = varargin{4};  end
  CAN_SAVE_MEMORY = 1;
  
else
  % called like tSig = gettrial(Sig,ANAP)
  Sig = varargin{1};
  if isstruct(Sig),
    SesName = Sig.session;
    GrpName = Sig.grpname;
    ExpNo = Sig.ExpNo(1);     % NKL: Use ExpNo(1) in case we have a group file
  else
    SesName = Sig{1}.session;
    GrpName = Sig{1}.grpname;
    ExpNo = Sig{1}.ExpNo(1);
  end;
  if nargin > 1,  ANAP = varargin{2};  end
  Ses = goto(SesName);
  grp = getgrpbyname(Ses, GrpName);
  CAN_SAVE_MEMORY = 0;
end

if isempty(ANAP),
  ANAP = getanap(Ses,ExpNo);
else
  ANAP = sctmerge(getanap(Ses,ExpNo),ANAP);
end

% MEAN-REMOVAL FOR THE ENTIRE EXPERIMENT ==============================================
% ANAP.gettrial.IBRAINMEAN = 1 removes the mean of the ROI
% ANAP.gettrial.IBRAINMEAN = 2 removes the mean of the entire Brain
% ANAP.gettrial.IBRAINMEAN = 3 removes the mean by applying PCA
%
% MEAN-REMOVAL FOR TRIALS  ============================================================
% ANAP.gettrial.IBRAINMEAN = 4 for each channel, it removes the mean of "non-stim" epochs

if ANAP.gettrial.IBRAINMEAN == 4,
  mriSig = 0;
  if isstruct(Sig),
    idx = getStimIndices(Sig,'blank',0, 0);  
    SIGMEAN = nanmean(Sig.dat(idx,:,:),1);
    SIGSTD = nanstd(Sig.dat(idx,:,:),[],1);
  end;
end;

% Do not split in trials if status is zero!
if ~isfield(ANAP,'gettrial') || ~ANAP.gettrial.status,
  fprintf('Group %s has no trials; Skipping...\n', grp.name);
  oSig = {};
  return;
end;

% overwrite ANAP.gettrial by ANAP.gettrial.(signame)
try
  [V info] = issig(Sig);
catch
  disp(lasterr);
  info.signame = '';
end
% anap.(signame).gettrial
if isfield(ANAP,info.signame) && isfield(ANAP.(info.signame),'gettrial'),
  ANAP.gettrial = sctmerge(ANAP.gettrial,ANAP.(info.signame).gettrial);
end
% anap.gettrial.(signame)
if isfield(ANAP.gettrial,info.signame),
  ANAP.gettrial = sctmerge(ANAP.gettrial,ANAP.gettrial.(info.signame));
end
% Do not split in trials if status is zero!
if ~ANAP.gettrial.status,
  fprintf('Group %s has no trials; Skipping...\n', grp.name);
  oSig = {};
  return;
end;

if ~isfield(ANAP.gettrial,'trial2obsp'),
  ANAP.gettrial.trial2obsp = 0;
end

% GET SORT-PARAMETERS
pars = getsortpars(Ses,ExpNo);

if isstruct(Sig),
  % If it's a structure (e.g. blp) convert to 1D cell-array
  % In the end of the function 1D arrays will become a structure again
  Sig = {Sig};
  UNDO_CELL = 1;
else
  UNDO_CELL = 0;
end;

DIM=ndims(Sig{1}.dat)+1;

if isfield(Sig{1},'dir') && isfield(Sig{1}.dir,'dname'),
  switch Sig{1}.dir.dname,
   case {'ClnSpc'}
    DIM = 4;  % ClnSpc as (t,f,chan)
  end
end

PreT = [];  PostT = [];
if isfield(ANAP.gettrial,'PreT'),
  PreT = ANAP.gettrial.PreT;
end
if isfield(ANAP.gettrial,'PostT'),
  PostT = ANAP.gettrial.PostT;
end
Toffset = 0;
if isfield(ANAP.gettrial,'Toffset'),
  Toffset = ANAP.gettrial.Toffset;
end

CheckJawPo = 0;
if isfield(ANAP.gettrial,'CheckJawPo'),
  CheckJawPo = ANAP.gettrial.CheckJawPo;
end
CheckCentroid = 0;
if isfield(ANAP.gettrial,'CheckCentroid'),
  CheckCentroid = ANAP.gettrial.CheckCentroid;
end

DoDetrend = 0;
if isfield(ANAP.gettrial,'detrend'),
  DoDetrend = ANAP.gettrial.detrend;
end

for RoiNo=1:length(Sig),                % For all signals (e.g. roiTs with many ROIs)

  switch lower(ANAP.gettrial.sort)
   case {'trial'}
    tmp = sigsort(Sig{RoiNo},pars.trial,PreT,PostT,CheckJawPo,CheckCentroid,Toffset,DoDetrend);
   case {'trialstim'}
    tmp = sigsort(Sig{RoiNo},pars.trialstim,PreT,PostT,CheckJawPo,CheckCentroid,Toffset,DoDetrend);
   case {'stim','stimulus','randomstm'}
    tmp = sigsort(Sig{RoiNo},pars.stim, PreT,PostT,CheckJawPo,CheckCentroid,Toffset,DoDetrend);
   otherwise
    error('\nERROR %s: anap.gettrial.sort must be either ''trial'' or ''stimulus''.\n',mfilename);
  end
  
  %tmp.dat = tmp.dat(:,:,[4:8 10]);
  
  if CAN_SAVE_MEMORY,
    % it's possible to save memory
    Sig{RoiNo} = [];
  end
  
  
  % sigsort will return a structure if the obsp has always the same trial
  % In this case the .dat field is extended to DIM (ndims+1) to include the individual trials.
  if isstruct(tmp),
    tmp = {tmp};
  end;

  oSig{RoiNo} = tmp;  clear tmp;
  
  if ~strcmpi(ANAP.gettrial.Xmethod,'none'),
    HemoDelay = [];  HemoTail = [];
    if any(strcmpi({'tcImg','roiTs','troiTs'},oSig{RoiNo}{1}.dir.dname)),
      if isfield(ANAP.gettrial,'HemoDelay'), HemoDelay = ANAP.gettrial.HemoDelay;  end
      if isfield(ANAP.gettrial,'HemoTail'),  HemoTail  = ANAP.gettrial.HemoTail;   end
    end
    oSig{RoiNo} = xform(oSig{RoiNo},ANAP.gettrial.Xmethod,ANAP.gettrial.Xepoch,HemoDelay,HemoTail);
  end

  if ANAP.gettrial.Average && ANAP.gettrial.trial2obsp == 0,
    % We average multiple occurrences of the same trial
    % The dimension DIM is one-more than the unsorted signal's dimension!
    for iTrial = 1:length(oSig{RoiNo}),    % e.g. trial-no
      if ~isempty(oSig{RoiNo}{iTrial}.dat),
        oSig{RoiNo}{iTrial}.dat = hnanmean(oSig{RoiNo}{iTrial}.dat,DIM);
      end
    end;
  end
    
  % Update the info-structure, so the user knows when was the last modification and
  % what exactly it was
  if isfield(oSig{RoiNo}{1},'info'),
    oSig{RoiNo} = sigupdate(oSig{RoiNo});
  end;
end;

if ANAP.gettrial.IBRAINMEAN==4,
  if iscell(oSig),
    if exist('SIGMEAN','var'),
      if iscell(oSig{1}),
        for N=1:length(oSig),
          for K=1:length(oSig{N}),
            oSig{N}{K}.dat=oSig{N}{K}.dat-repmat(SIGMEAN,[size(oSig{N}{K}.dat,1) 1 1 size(oSig{N}{K}.dat,4)]);
            oSig{N}{K}.dat=oSig{N}{K}.dat./repmat(SIGSTD,[size(oSig{N}{K}.dat,1) 1 1 size(oSig{N}{K}.dat,4)]);
          end;
        end;
      else
        for N=1:length(oSig),
          oSig{N}.dat = oSig{N}.dat - repmat(SIGMEAN, [size(oSig{N}.dat,1) 1 1 size(oSig{N}.dat,4)]);
          oSig{N}.dat = oSig{N}.dat ./ repmat(SIGSTD, [size(oSig{N}.dat,1) 1 1 size(oSig{N}.dat,4)]);
        end;
      end;
    end;
  else
    oSig.dat = oSig.dat - repmat(SIGMEAN, [size(oSig.dat,1) 1 1 size(oSig.dat,4)]);
    oSig.dat = oSig.dat ./ repmat(SIGSTD, [size(oSig.dat,1) 1 1 size(oSig.dat,4)]);
  end;
end;

if ~isawake(grp) && ANAP.gettrial.trial2obsp > 0,
  if ANAP.gettrial.Average,  
    oSig = trial2obsp(oSig,'mean');
  else
    oSig = trial2obsp(oSig,'none');
  end
end
if ~ANAP.gettrial.trial2obsp,
  % DO NOT REDUCE CELL-DIMENSIONS...
  return;
end;

% If it's a neural-signal, then 1D cells should be converted into structures
% roiTs (where the first dimensions is model-number) should remain cell arrays for
% compatibility with all our functions, even if only one model exists...
if UNDO_CELL > 0 || length(oSig) == 1,
  oSig = oSig{1};
end;
return;

