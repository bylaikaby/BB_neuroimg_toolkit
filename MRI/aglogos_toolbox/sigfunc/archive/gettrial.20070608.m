function oSig = gettrial(Sig,ANAP)
%GETTRIAL - Split observation period in trials and return average response per trial.
% GETTRIAL splits observation periods including repetition of a stimulus condition. The
% function will average the trial responses and will return the mean of the responses.
%
% NOTE: GLM analysis may run by examining responses only during one of the trials and
% subsequently selecting the time series of the other conditions by using the same voxel
% map.
%
% Sessions may have groups with trials and groups with continuous observation periods
% (e.g. spontaneous activity, hyperc experiments, etc.). SESGETTRIAL examines the field 
% GRP.normo.anap.gettrial.status; If it's 1, then gettrial is called.
%
% The sorting parameter (trial or stim) is defined by
% GRPP.glm(1).sort = 'trial';
% And the trial to be used for analysis by
% GRPP.glm(1).selsort = 5;
%
%
% TO DEBUG:
%   n03qv1/1        Mutliple same trials in obsp
%   n03qv1/81       Mutliple different trials in obsp
%   m02lx1/1        No trials
%  
% See also SESGETTRIAL XFORM
%  
% NKL 20.07.04
% YM  23.03.06 supports HemoDelay/HemoTail for tcImg/roiTs/troiTs.
% YM  21.04.06 supports "trial2obsp".
% YM  22.05.07 accepts "ANAP" as argument

if nargin < 1,
  help gettrial;
  return;
end;

if isstruct(Sig),
  SesName = Sig.session;
  GrpName = Sig.grpname;
  ExpNo = Sig.ExpNo(1);     % NKL: Use ExpNo(1) in case we have a group file
else
  SesName = Sig{1}.session;
  GrpName = Sig{1}.grpname;
  ExpNo = Sig{1}.ExpNo(1);
end;

if ~exist('ANAP','var'),  ANAP = [];  end

Ses = goto(SesName);
grp = getgrpbyname(Ses, GrpName);

if isempty(ANAP),
  ANAP = getanap(Ses,ExpNo);
else
  ANAP = sctmerge(getanap(Ses,ExpNo),ANAP);
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

PreT = [];  PostT = [];
if isfield(ANAP.gettrial,'PreT'),
  PreT = ANAP.gettrial.PreT;
end
if isfield(ANAP.gettrial,'PostT'),
  PostT = ANAP.gettrial.PostT;
end
CheckJawPo = 0;
if isfield(ANAP.gettrial,'CheckJawPo'),
  CheckJawPo = ANAP.gettrial.CheckJawPo;
end
CheckCentroid = 0;
if isfield(ANAP.gettrial,'CheckCentroid'),
  CheckCentroid = ANAP.gettrial.CheckCentroid;
end


for RoiNo=1:length(Sig),                % For all signals (e.g. roiTs with many ROIs)

  if strcmpi(ANAP.gettrial.sort,'trial'),
    tmp = sigsort(Sig{RoiNo},pars.trial,PreT,PostT,CheckJawPo,CheckCentroid);
  elseif any(strcmpi({'stim','stimulus'},ANAP.gettrial.sort)),
    tmp = sigsort(Sig{RoiNo},pars.stim, PreT,PostT,CheckJawPo,CheckCentroid);
  else
    error('\nERROR %s: anap.gettrial.sort must be either ''trial'' or ''stimulus''.\n');
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

  if ANAP.gettrial.Average & ANAP.gettrial.trial2obsp == 0,
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

if ~isawake(grp) & ANAP.gettrial.trial2obsp > 0,
  if ANAP.gettrial.Average  
    oSig = trial2obsp(oSig,'mean');
  else
    oSig = trial2obsp(oSig,'none');
  end
end


% If it's a neural-signal, then 1D cells should be converted into structures
% roiTs (where the first dimensions is model-number) should remain cell arrays for
% compatibility with all our functions, even if only one model exists...
if UNDO_CELL > 0 & length(oSig) == 1,
  oSig = oSig{1};
end;

return;

