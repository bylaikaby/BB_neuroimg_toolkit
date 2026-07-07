function Sig = mrcca2sig(RES, SigName, varargin)
%MRCCA2SIG - Assign ROIs and Time Series to thresholded Weight-Maps (tkCCA)
% Sig = mrcca2sig(RES,SigName,...) generates 'Sig' based on mrcca.
%
%    'thr'    : threshould for mrcca(fmri).
%    'grpexp' : group or exp numbers for the signal to read.
%
%  VERSION :
%   YM  28.01.13, NKL 26.03.2013
%
%  See also plot_mrcca sesmrcca expmrcca expmrcca_cv

if ischar(RES),
  RES = load(RES,'res');
  RES = RES.res;
end

if iscell(RES.session),
  RES.session = RES.session{1};
  RES.grpname = RES.grpname{1};
  RES.exps = RES.exps{1};
end;
OPTS = RES.opts;

anap = getanap(RES.session,RES.grpname);
RoiName = anap.SELROI;
if isfield(anap,'mrcca') && isfield(anap.mrcca,'thr')
  FMRI_thr = anap.mrcca.thr;
else
  FMRI_thr = 1;
end

GrpExp = RES.exps;
for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'mri','mrisig'},
    MriSig = varargin{N+1};
   case {'thr','threshold'}
    FMRI_thr = varargin{N+1};
   case {'grpexp' 'exp' 'exps' 'grp' 'group' 'grpname' 'groupname'}
    GrpExp = varargin{N+1};
   case {'roi' 'roiname'}
    RoiName = varargin{N+1};
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
  fprintf('GrpExp must be a numeric vector our group-name!\n');
  keyboard
end

% THRESHOLD tkCCA Maps
CcaSig = sub_ccasig(RES, FMRI_thr);

% READ roiTs of each experiment and used them as "mask" for the tkCCA brain-map
fprintf(' %s: %s (nexps=%d,%s): ',mfilename, Ses.name, length(EXPS), SigName);
Sig = [];

for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  if mod(iExp,10) == 0,
    fprintf('%d',iExp);
  else
    fprintf('.');
  end
  mrisig = sigload(Ses,ExpNo,SigName);
    
  expsig = [];
  for iRoi=1:length(RoiName),
    roits = [];
    for K = 1:length(mrisig),
      if ~strcmp(mrisig{K}.name,RoiName{iRoi}),  continue;  end
      if isempty(roits),
        roits = mrisig{K};
      else
        roits.dat = cat(2,roits.dat,mrisig{K}.dat);
        roits.coords = cat(1,roits.coords,mrisig{K}.coords);
      end
    end 
    if isempty(roits) || isempty(roits.dat), continue; end;
    % avoid duplicated voxels;
    tmpidx = sub2ind(size(roits.ana),roits.coords(:,1),roits.coords(:,2),roits.coords(:,3));
    [b m] = unique(tmpidx);
    roits.dat = roits.dat(:,m);
    roits.coords = roits.coords(m,:);
    roits.name = RoiName{iRoi};
    
    roits2 = mvoxlogical(roits,'and',CcaSig);
    
    if isempty(roits2) | isempty(roits2.dat), continue; end;
    
    roits2.frac = 100*size(roits2.dat,2)/size(roits.dat,2);
    roits2.dat = nanmean(roits2.dat,2);
    
    if isempty(expsig),
      expsig = roits2;
      expsig.name = {RoiName{iRoi}};
    else
      expsig.dat = cat(2, expsig.dat, roits2.dat);
      expsig.frac = cat(1, expsig.frac, roits2.frac);
      expsig.name{end+1} = RoiName{iRoi};
    end
  end
  
  if isempty(Sig)
    Sig = expsig;
  else
    Sig.dat  = cat(3, Sig.dat, expsig.dat);
    Sig.frac = cat(2, Sig.frac, expsig.frac(:));
  end
end

Sig.ExpNo           = EXPS;
Sig.mrcca.weights   = CcaSig.weights;
Sig.mrcca.thr       = FMRI_thr;

fprintf(' done.\n');
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function CcaSig = sub_ccasig(RES, FMRI_thr)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RES.fmri.weights is a "voxel X NoExp" matrix, e.g. [65464 15]
NORM_TYPE = 0;      % This seems more reliable, but we need stats here...
if NORM_TYPE,
  STATMAP = zscore(RES.fmri.weights,[],1);
  STATMAP = nanmean(STATMAP,2);
else
  STATMAP = RES.fmri.weights;
  if size(STATMAP,2) > 1
    STATMAP = nanmean(STATMAP,2);
  end
  
  tmpstat = (STATMAP-nanmean(STATMAP(:)))/nanstd(STATMAP(:));
  STATMAP = tmpstat;
end;
tmpidx = find(abs(STATMAP(:)) > FMRI_thr);

CcaSig.dat      = [];
CcaSig.coords   = RES.fmri.coords(tmpidx,:);
CcaSig.weights  = STATMAP(tmpidx);
CcaSig.weights  = CcaSig.weights(:);
return
