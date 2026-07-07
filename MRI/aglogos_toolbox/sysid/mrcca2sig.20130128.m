function Sig = mrcca2sig(RES,SigName,varargin)
%MRCCA2SIG - Generate 'Sig' based on mrcca.
%  SIG = mrcca2sig(RES,SigName,...) generates 'Sig' based on mrcca.
%  Supported options are :
%    'thr'    : threshould for mrcca(fmri).
%    'grpexp' : group or exp numbers for the signal to read.
%
%  EXAMPLE :
%    >> goto('e10ha1')
%    >> load('mritkcca_test.mat')
%    >> sig = mrcca2sig(res,'rproiTs','thr',1);
%
%  VERSION :
%    0.90 28.01.13 YM  pre-release
%
%  See also plot_mrcca sesmrcca expmrcca expmrcca_cv


if ischar(RES),
  RES = load(RES,'res');
  RES = RES.res;
end


% RES = 
%      opts: [1x1 struct]
%     lambda: [1.0000e-003 1.0000e-003 1.0000e-003 1.0000e-003 1.0000e-003]
%       fmri: [1x1 struct]
%      ephys: [1x4 struct]

if iscell(RES.session),
  RES.session = RES.session{1};
  RES.grpname = RES.grpname{1};
  RES.exps = RES.exps{1};
end;
OPTS = RES.opts;

anap = getanap(RES.session,RES.grpname);
if isfield(anap,'mrcca') && isfield(anap.mrcca,'thr')
  FMRI_thr = anap.mrcca.thr;
else
  FMRI_thr = 1;
end


GrpExp = RES.exps;
for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'thr','threshold'}
     FMRI_thr = varargin{N+1};
   case {'grpexp' 'exp' 'exps' 'grp' 'group' 'grpname' 'groupname'}
    GrpExp = varargin{N+1};
  end
end;


Ses = goto(RES.session);

if isnumeric(GrpExp),
  EXPS = GrpExp;
elseif ischar(GrpExp),
  grp = getgrp(Ses,RES.grpname);
  EXPS = grp.exps;
elseif isstruct(GrpExp) && isfield(GrpExp,'exps')
  EXPS = GrpExp.exps;
else
  % 'GrpExp' must be a numeric vector our group-name...
  keyboard
end


CcaSig = sub_ccasig(RES, FMRI_thr);

%EXPS = EXPS(1:5);

fprintf(' %s: %s (nexps=%d,%s): ',mfilename, Ses.name, length(EXPS), SigName);
Sig = [];
for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  if mod(iExp,10) == 0,
    fprintf('%d',iExp);
  else
    fprintf('.');
  end
  tmpsig = sigload(Ses,ExpNo,SigName);
  
  tmpsig = mvoxselect(tmpsig,'all','none',[],1.0);
  tmpsig = mvoxlogical(tmpsig,'and',CcaSig);
  
  % Sig.dat as (time,vox,exps)
  if isempty(Sig),
    Sig = tmpsig;
  else
    Sig.dat = cat(3,Sig.dat,tmpsig.dat);
  end
end
Sig.ExpNo = EXPS;
Sig.mrcca.weights = CcaSig.weights;
Sig.mrcca.thr     = FMRI_thr;

fprintf(' done.\n');


return





function CcaSig = sub_ccasig(RES, FMRI_thr)

STATMAP = RES.fmri.weights;
if size(STATMAP,2) > 1
  STATMAP = nanmean(STATMAP,2);
end

if 1
% do zscore normalization
tmpstat = (STATMAP-nanmean(STATMAP(:)))/nanstd(STATMAP(:));
%idx = find(tmpstat<1);
%tmpstat(idx) = NaN;
STATMAP = tmpstat;
end

tmpidx = find(abs(STATMAP(:)) > FMRI_thr);

CcaSig.dat = [];
CcaSig.coords = RES.fmri.coords(tmpidx,:);
CcaSig.weights = STATMAP(tmpidx);
CcaSig.weights = CcaSig.weights(:);


return
