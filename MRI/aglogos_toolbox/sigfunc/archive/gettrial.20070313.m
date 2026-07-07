function oSig = gettrial(Sig)
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

Ses = goto(SesName);
grp = getgrpbyname(Ses, GrpName);
anap = getanap(Ses,ExpNo);

% Do not split in trials if status is zero!
if ~anap.gettrial.status,
  fprintf('Group %s has no trials; Skipping...\n', grp.name);
  oSig = {};
  return;
end;

if ~isfield(anap.gettrial,'trial2obsp'),
  anap.gettrial.trial2obsp = 0;
end


if isstruct(Sig),
  % If it's a structure (e.g. blp) convert to 1D cell-array
  % In the end of the function 1D arrays will become a structure again
  signame = Sig.dir.dname;
  if isfield(Sig,'info'),
    info = Sig.info;
  end;
  Sig = {Sig};
else
  signame = Sig{1}.dir.dname;
  if isfield(Sig{1},'info'),
    info = Sig{1}.info;
  end;
end;

% GET SORT-PARAMETERS
pars = getsortpars(Ses,ExpNo);

DIM=ndims(Sig{1}.dat)+1;

PreT = [];  PostT = [];
if isfield(anap.gettrial,'PreT'),
  PreT = anap.gettrial.PreT;
end
if isfield(anap.gettrial,'PostT'),
  PostT = anap.gettrial.PostT;
end
CheckJawPo = 0;
if isfield(anap.gettrial,'CheckJawPo'),
  CheckJawPo = anap.gettrial.CheckJawPo;
end


for RoiNo=1:length(Sig),                % For all signals (e.g. roiTs with many ROIs)

  if strcmpi(anap.gettrial.sort,'trial'),
    tmp = sigsort(Sig{RoiNo},pars.trial,PreT,PostT,CheckJawPo);
  elseif any(strcmpi({'stim','stimulus'},anap.gettrial.sort)),
    tmp = sigsort(Sig{RoiNo},pars.stim, PreT,PostT,CheckJawPo);
  else
    error('\nERROR %s: anap.gettrial.sort must be either ''trial'' or ''stimulus''.\n');
  end
  
  % sigsort will return a structure if the obsp has always the same trial
  % In this case the .dat field is extended to DIM (ndims+1) to include the individual trials.
  if isstruct(tmp),
    tmp = {tmp};
  end;

  oSig{RoiNo} = tmp;  clear tmp;
  
  if ~strcmpi(anap.gettrial.Xmethod,'none'),
    HemoDelay = [];  HemoTail = [];
    if any(strcmpi({'tcImg','roiTs','troiTs'},oSig{RoiNo}{1}.dir.dname)),
      if isfield(anap.gettrial,'HemoDelay'), HemoDelay = anap.gettrial.HemoDelay;  end
      if isfield(anap.gettrial,'HemoTail'),  HemoTail  = anap.gettrial.HemoTail;   end
    end
    oSig{RoiNo} = xform(oSig{RoiNo},anap.gettrial.Xmethod,anap.gettrial.Xepoch,HemoDelay,HemoTail);
  end

  if anap.gettrial.Average & anap.gettrial.trial2obsp == 0,
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

if ~isawake(grp) & anap.gettrial.trial2obsp > 0,
  if anap.gettrial.Average  
    oSig = trial2obsp(oSig,'mean');
  else
    oSig = trial2obsp(oSig,'none');
  end
end


% If it's a neural-signal, then 1D cells should be converted into structures
% roiTs (where the first dimensions is model-number) should remain cell arrays for
% compatibility with all our functions, even if only one model exists...
if strcmp(Sig{1}.dir.dname,'blp'),
  if length(oSig) == 1,
    oSig = oSig{1};
  end;
end;
return;

