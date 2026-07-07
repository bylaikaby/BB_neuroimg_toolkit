function varargout = mgetmask(Ses,GrpExp,SAVE2MAT)
%MGETMASK - Creates a mask for roiTs/troiTs on the basis of the r/p values obtained by SESCORANA
%  MGETMASK(SES,GRPEXP,1) creates mask data from corr analysis (.r/.p) and save it.
%  MASK = MGETMASK(SES,GRPEXP) load mask data and return it.
%
%  MASK data will be a cell array that is compatible to roiTs structure
%   MASK{1} =
%     session: 'j04yz1'
%     grpname: 'normo'
%       ExpNo: [11 15 19 24 28]
%        name: 'brain'
%       slice: -1
%      coords: [881x3 double]
%      corana: {[1x1 struct]  [1x1 struct]  [1x1 struct]  [1x1 struct]} <-- each models
%   %%% Add the GLMana structure into this
%   MASK{1}.corana{1} =
%       mdlsct: 'hemo'
%          mdl: [88x1 double]
%            r: [881x1 double]
%            p: [881x1 double]
%          dat: [1x881 int8]
%         rval: 0.1200
%         aval: 0.0600
%     aval_rep: 0.8000
%
%
%  VERSION :
%    0.90 04.01.06 YM   pre-release
%    0.91 06.01.06 YM   moved .r/.p into .corana{M}
%    0.92 09.01.06 YM   supports where troiTs is converted to obsp.
%    0.93 10.01.06 YM   do OR operation if grp.refgrp.reftrial > 0.
%    0.94 24.03.06 YM   supports "grouping before cor".
%    0.95 28.01.08 YM   avoid error even for non-sense grp.refgrp.reftrial.
%
%  See also SESGETMASK CREATEGLMMASK MROITSMASK

if nargin < 2, eval(sprintf('help %s;',mfilename)); return;  end


if ~exist('SAVE2MAT','var'), SAVE2MAT = 0;  end

Ses = goto(Ses);

matfile = catfilename(Ses,GrpExp,'mat');
if SAVE2MAT > 0,
  % make mask data and save it, usually called from sesgetmask().
  mask = subCreateMask(Ses,GrpExp);
  fprintf(' saving ''mask'' to %s...',matfile);
  if exist(matfile,'file'),
    save(matfile,'mask','-append');
  else
    save(matfile,'mask');
  end
  fprintf('done.\n');
else
  % just load mask data
  mask = load(matfile,'mask');
  if isempty(fieldnames(mask)),
    mgetmask(Ses,GrpExp,1);
    %error('%s: no ''mask'' data found, run sesgetmask() first.\n',mfilename);
  else
    mask = mask.mask;
  end
end


if nargout,
  varargout{1} = mask;
end
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mask = subCreateMask(Ses,GrpExp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
  mask = subCreateCorrMask(Ses,GrpExp);
catch
  mask = [];
end
if isempty(mask)
  mask = CreateGlmMask(Ses,GrpExp);
else
  mask = CreateGlmMask(mask);
end

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to make mask data for seletion by .r/.p fields
function MASK = subCreateCorrMask(Ses,GrpExp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Ses = goto(Ses);
grp = getgrp(Ses,GrpExp);
anap = getanap(Ses,GrpExp);
if isnumeric(GrpExp),
  EXPS = GrpExp;
else
  EXPS = grp.exps;
end
% no need to process further, just return MASK structure.
if ~isfield(grp,'corana') || isempty(grp.corana),
  MASK = [];
  return;
end


% check which data should be used for masking, troiTs or roiTs
if isfield(anap,'gettrial') && ~isempty(anap.gettrial) && anap.gettrial.status > 0,
  SigName = 'troiTs';
else
  SigName = 'roiTs';
end

if isfield(grp,'refgrp') && isfield(grp.refgrp,'reftrial') && ~isempty(grp.refgrp.reftrial) && grp.refgrp.reftrial > 0,
  TrialIndex = grp.refgrp.reftrial;
else
  TrialIndex = [];
end


GROUP_BEFORE_COR = 0;
if isfield(grp,'groupcor') && ~isempty(grp.groupcor),
  switch lower(grp.groupcor),
   case {'average before cor','averagebeforecor',...
         'group before cor','groupbeforecor', 'before cor', 'beforecor'}
    GROUP_BEFORE_COR = 1;
  end
end


fprintf(' %s.subCreateCorrMask %s',mfilename,Ses.name);
if GROUP_BEFORE_COR > 0,
  fprintf('Grp=%s ',grp.name);
  iSig = sigload(Ses,grp.name,SigName);
else
  ExpNo = EXPS(1);
  fprintf('ExpNo=%d.',ExpNo);
  iSig = sigload(Ses,ExpNo,SigName);
end

if strcmpi(SigName,'troiTs'),
  if isempty(TrialIndex) || TrialIndex == 0,
    TrialIndex = 1:length(iSig{1});
  end
  fprintf(' reftrial=');  fprintf('%d ',TrialIndex);
end


HOW_OFTEN = 0.8;   % 0:same as OR, 1:same as AND
Rthr = anap.rval * 0.8;
Pthr = anap.aval * 1.2;

for R = 1:length(iSig),
  MASK{R}.session = Ses.name;
  MASK{R}.grpname = grp.name;
  MASK{R}.ExpNo = EXPS;
  if strcmpi(SigName,'troiTs') && iscell(iSig{R}),
    % case of troiTs
    MASK{R}.name   = iSig{R}{1}.name;
    MASK{R}.slice  = iSig{R}{1}.slice;
    MASK{R}.coords = iSig{R}{1}.coords;
    if isfield(grp,'corana'),
      MASK{R}.corana = grp.corana;
      for M = length(iSig{R}{1}.r):-1:1,
        for T = length(iSig{R}):-1:1,
          MASK{R}.corana{M}.mdl{T} = iSig{R}{T}.mdl{M};
          MASK{R}.corana{M}.r{T}   = iSig{R}{T}.r{M};
          MASK{R}.corana{M}.p{T}   = iSig{R}{T}.p{M};
          tmpidx = (iSig{R}{T}.r{M} > Rthr & iSig{R}{T}.p{M} < Pthr);
          MASK{R}.corana{M}.dat{T} = single(tmpidx);
          MASK{R}.corana{M}.rval = Rthr;
          MASK{R}.corana{M}.aval = Pthr;
          MASK{R}.corana{M}.aval_rep = HOW_OFTEN;
        end
      end
    else
      MASK{R}.corana = {};
    end
  else
    % case of roiTs
    MASK{R}.name   = iSig{R}.name;
    MASK{R}.slice  = iSig{R}.slice;
    MASK{R}.coords = iSig{R}.coords;
    if isfield(grp,'corana'),
      MASK{R}.corana = grp.corana;
      for M = 1:length(iSig{R}.r)
        if isfield(iSig{R},'mdl')
          MASK{R}.corana{M}.mdl = iSig{R}.mdl{M};
          MASK{R}.corana{M}.r   = iSig{R}.r{M};
          MASK{R}.corana{M}.p   = iSig{R}.p{M};
          tmpidx = (iSig{R}.r{M} > Rthr & iSig{R}.p{M} < Pthr);
          MASK{R}.corana{M}.dat = single(tmpidx);
          MASK{R}.corana{M}.rval = Rthr;
          MASK{R}.corana{M}.aval = Pthr;
          MASK{R}.corana{M}.aval_rep = HOW_OFTEN;
        else
          MASK{R}.corana = {};
        end
      end
    else
      MASK{R}.corana = {};
    end
  end
end

% no need to process further, just return MASK structure.
%if ~isfield(grp,'corana') | isempty(grp.corana),  return;  end

% if grouping before cor, then do following and return
if GROUP_BEFORE_COR > 0,
  MASK = subFinalizeMask(MASK,1,TrialIndex,HOW_OFTEN);
  return;
end


for iExp = 2:length(EXPS),
  ExpNo = EXPS(iExp);
  fprintf('%d.',ExpNo);
  iSig = sigload(Ses,ExpNo,SigName);
  for R = 1:length(iSig),
    if strcmpi(SigName,'troiTs') && iscell(iSig{R}),
      % case of troiTs
      for M = 1:length(iSig{R}{1}.r)
        for T = 1:length(iSig{R}),
          MASK{R}.corana{M}.r{T}   = MASK{R}.corana{M}.r{T} + iSig{R}{T}.r{M};
          MASK{R}.corana{M}.p{T}   = MASK{R}.corana{M}.p{T} + iSig{R}{T}.p{M};
          tmpidx = (iSig{R}{T}.r{M} > Rthr & iSig{R}{T}.p{M} < Pthr);
          MASK{R}.corana{M}.dat{T} = MASK{R}.corana{M}.dat{T} + single(tmpidx);
        end
      end
    else
      % case of roiTs
      for M = 1:length(iSig{R}.r)
        MASK{R}.corana{M}.r   = MASK{R}.corana{M}.r + iSig{R}.r{M};
        MASK{R}.corana{M}.p   = MASK{R}.corana{M}.p + iSig{R}.p{M};
        tmpidx = (iSig{R}.r{M} > Rthr & iSig{R}.p{M} < Pthr);
        MASK{R}.corana{M}.dat = MASK{R}.corana{M}.dat + single(tmpidx);
      end
    end
  end
end


MASK = subFinalizeMask(MASK,length(EXPS),TrialIndex,HOW_OFTEN);

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to finalize MASK structure
function MASK = subFinalizeMask(MASK,NEXPS,TrialIndex,HOW_OFTEN)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if length(TrialIndex) == 1 && TrialIndex > 0,
  % select only the relevant trial.
  for R = 1:length(MASK),
    for M = 1:length(MASK{R}.corana),
      if iscell(MASK{R}.corana{M}.dat),
        MASK{R}.corana{M}.dat = MASK{R}.corana{M}.dat{TrialIndex};
        MASK{R}.corana{M}.r   = MASK{R}.corana{M}.r{TrialIndex};
        MASK{R}.corana{M}.p   = MASK{R}.corana{M}.p{TrialIndex};
        MASK{R}.corana{M}.mdl = MASK{R}.corana{M}.mdl{TrialIndex};
      end
    end
  end
end


% no need to save it as double
for R = 1:length(MASK),
  for M = 1:length(MASK{R}.corana),
    if iscell(MASK{R}.corana{M}.r),
      for T = 1:length(MASK{R}.corana{M}.r),
        MASK{R}.corana{M}.dat{T}  = single(MASK{R}.corana{M}.dat{T}/NEXPS);
        MASK{R}.corana{M}.r{T}    = MASK{R}.corana{M}.r{T}/NEXPS;
        MASK{R}.corana{M}.p{T}    = MASK{R}.corana{M}.p{T}/NEXPS;
        if HOW_OFTEN == 1,
          notsig = find(MASK{R}.corana{M}.dat{T} < 1);   % same as AND operation
        elseif HOW_OFTEN == 0,
          notsig = find(MASK{R}.corana{M}.dat{T} == 0);  % same as OR operation
        else
          notsig = find(MASK{R}.corana{M}.dat{T} < HOW_OFTEN);
        end
        MASK{R}.corana{M}.dat{T}(:)      = 1;
        MASK{R}.corana{M}.dat{T}(notsig) = 0;
        MASK{R}.corana{M}.r{T}(notsig)   = 0;
        MASK{R}.corana{M}.p{T}(notsig)   = 1;
        MASK{R}.corana{M}.dat{T} = int8(MASK{R}.corana{M}.dat{T});
      end
      % do OR operation
      tmpdat = MASK{R}.corana{M}.dat{1};
      tmpr   = MASK{R}.corana{M}.r{1};
      tmpp   = MASK{R}.corana{M}.p{1};
      tmpm   = MASK{R}.corana{M}.mdl{1};
      Ntrials = length(MASK{R}.corana{M}.r);
      for T = 2:Ntrials,
        tmpdat = int8(tmpdat | MASK{R}.corana{M}.dat{T});
        idx = find(MASK{R}.corana{M}.r{T} > tmpr);
        tmpr(idx) = MASK{R}.corana{M}.r{T}(idx);
        idx = find(MASK{R}.corana{M}.p{T} < tmpp);
        tmpp(idx) = MASK{R}.corana{M}.p{T}(idx);
        tmpm = tmpm + MASK{R}.corana{M}.mdl{T};
      end
      MASK{R}.corana{M}.dat = tmpdat;
      MASK{R}.corana{M}.r   = tmpr;
      MASK{R}.corana{M}.p   = tmpp;
      MASK{R}.corana{M}.mdl = tmpm / Ntrials;
    else
      MASK{R}.corana{M}.dat  = single(MASK{R}.corana{M}.dat/NEXPS);
      MASK{R}.corana{M}.r   = MASK{R}.corana{M}.r/NEXPS;
      MASK{R}.corana{M}.p   = MASK{R}.corana{M}.p/NEXPS;
      if HOW_OFTEN == 1,
        notsig = find(MASK{R}.corana{M}.dat < 1);   % same as AND operation
      elseif HOW_OFTEN == 0,
        notsig = find(MASK{R}.corana{M}.dat == 0);  % same as OR operation
      else
        notsig = find(MASK{R}.corana{M}.dat < HOW_OFTEN);
      end
      MASK{R}.corana{M}.dat(:)      = 1;
      MASK{R}.corana{M}.dat(notsig) = 0;
      MASK{R}.corana{M}.r(notsig)   = 0;
      MASK{R}.corana{M}.p(notsig)   = 1;
      MASK{R}.corana{M}.dat = int8(MASK{R}.corana{M}.dat);
    end
  end
end


return;
