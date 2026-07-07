function blp = algetfratio(Arg1, Arg2, RoiName, pVal, bSign)
%ALGETFRATIO - Show the F-Ratio of reduced-to-full design matrix for each frequency band
% blp = algetfratio(SesName, GrpName, RoiName) computes the F Ratio for different
% regressors (ClnSpc or BLP).
%
% EXAMPLES
%       blp = algetfratio('n02gu1');  (Defaults Group='fix', Roi='ele')
%       blp = algetfratio('n02gu1', 'fix', 'ele');
%       blp = algetfratio('alert','all');
%       blp = algetfratio('alert','kftop');
%
% NKL 23.01.2008
%
%  See also dspfratio

CUR_GROUP = 'fix';

if nargin < 5,  bSign = 1;                  end;
if nargin < 4,  pVal = 0.01;                end;
if nargin < 3,  RoiName = 'fratio';         end;
if nargin < 1,  help algetfratio; return;   end;

if strcmp(Arg1,'alert'),
  PrepType = Arg1;
  Selection = Arg2;
  GrpName = CUR_GROUP;
  ses = seslist(PrepType,Selection);
else
  ses{1}{1} = Arg1;
  if ~exist('Arg2','var'),
    Arg2 = CUR_GROUP;
  end;
  GrpName = Arg2;
end;

for N=1:length(ses),
  fprintf('%s.', ses{N}{1});
  tmpblp = subAlgetfratio(ses{N}{1},GrpName,RoiName,pVal);

  if pVal,
    idx = find(tmpblp.pvalues>pVal);
    tmpblp.betas(idx) = NaN;
    tmpblp.serror(idx) = NaN;
  end;
  if bSign == 1,
    pidx = find(tmpblp.betas<=0);
    tmpblp.betas(pidx) = NaN;
    tmpblp.serror(pidx) = NaN;
  elseif bSign == -1,
    pidx = find(tmpblp.betas>0);
    tmpblp.betas(pidx) = NaN;
    tmpblp.serror(pidx) = NaN;
  else
    tmpblp.betas = abs(tmpblp.betas);
    tmpblp.serror = abs(tmpblp.serror);
  end;
  tmpblp.betas = hnanmean(tmpblp.betas,2);
  tmpblp.serror = hnanmean(tmpblp.serror,2);

  if N==1,
    blp = tmpblp;
  else
    blp.y = cat(2,blp.y,tmpblp.y);
    blp.p = cat(2,blp.p,tmpblp.p);
    blp.betas = cat(2,blp.betas,tmpblp.betas);
    blp.serror = cat(2,blp.serror,tmpblp.serror);
  end;
end;
fprintf(' Done!\n');
blp.arg1 = Arg1;
blp.arg2 = Arg2;

if ~nargout,
  fratio = blp;
  fname = catfilename(Arg1,Arg2);
  fprintf('Saving fratio to %s...',fname);
  save(fname,'-append', 'fratio');
  fprintf('Done.\n');
  
  mfigure([100 100 600 800]);
  dspfratio(blp);
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function blp = subAlgetfratio(SesName, GrpName, RoiName, PVAL)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      groupglm: 'before glm'
%       glmconts: {1x10 cell}
%         glmana: {1x8 cell}
%          bands: {[2 4]  [4 8]  [8 13]  [15 60]  [65 100]  [1000 2600]}
%      bandnames: {'delta'  'theta'  'alpha'  'nm'  'stm'  'mua'}
%          NoReg: 6
%     FullDesIdx: 2
%     FullConIdx: 4
%        bDesIdx: 3
%        bConIdx: 5


grp = getgrp(SesName, GrpName);

if any(strfind(grp.groupglm,'before')),
  % grp.groupglm = 'before glm'
  blp = subProc(SesName,GrpName,RoiName,PVAL);
else
  % grp.groupglm = 'after glm'
  for iExp = 1:length(grp.exps),
    fprintf('.');
    tmpblp = subProc(SesName,grp.exps(iExp),RoiName,PVAL);
    if iExp == 1,
      blp = tmpblp;
    else
      blp.y = cat(2,blp.y,tmpblp.y);
      blp.p = cat(2,blp.p,tmpblp.p);
      blp.betas = cat(2,blp.betas,tmpblp.betas);
      blp.serror = cat(2,blp.serror,tmpblp.serror);
      blp.pvalues = cat(2,blp.pvalues,tmpblp.pvalues);
    end
  end
end


return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function blp = subProc(SesName,GrpExp,RoiName,PVAL)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

grp = getgrp(SesName,GrpExp);
roiTs = sigload(SesName,GrpExp,'roiTs');
roiTs = mroitsget(roiTs,[],RoiName);
roiTs = roiTs{1};

GlmCONT   = roiTs.glmcont;
GlmOUTPUT = roiTs.glmoutput;

FFull = nanmean(GlmCONT(grp.FullConIdx).statv(:));

sIdxB = grp.bConIdx;
eIdxB = sIdxB + grp.NoReg - 1;

betas = []; serror = [];
for N=1:length(GlmOUTPUT(grp.FullDesIdx).STATS),   % number of voxels
  betas = cat(2,betas,GlmOUTPUT(grp.FullDesIdx).STATS{N}.beta(:));
  serror = cat(2,serror,GlmOUTPUT(grp.FullDesIdx).STATS{N}.serrors(:));
end;
betas = betas(1:end-1,:);
serror = serror(1:end-1,:);

% MODELS ARE: fVal, PBR, NBR, Full, Incompl1, Incompl2,....
% To ensure we pick the reqion of normal BPR within the ELE roi
% We use the pvalues of PBR to select voxels
pvalues = GlmCONT(2).pvalues;

K=1;
for N=sIdxB:eIdxB,
  bF = nanmean(GlmCONT(N).statv(:));
  NoReg = grp.NoReg - 1;
  [F_ratB(K), p_ratB(K)] = F_ratio(FFull, bF, grp.NoReg, NoReg, size(roiTs.dat,1));
  K = K + 1;
end;

if nargout,
  blp.sesname   = SesName;
  blp.grpname   = grp.name;
  blp.roiname   = RoiName;
  blp.x         = [1:length(F_ratB)]';
  blp.y         = double(F_ratB(:));
  blp.p         = double(p_ratB(:));
  blp.betas     = betas;
  blp.serror    = serror;
  blp.pvalues   = pvalues;
  blp.xlim      = [0 length(F_ratB)+1];
  blp.xticklabel= grp.bandnames;
  blp.xlabel    = 'Center Frequency in Hz';
  blp.ylabel    = 'F-Ratio';
  blp.date      = date;
  blp.time      = gettimestring;
end;

