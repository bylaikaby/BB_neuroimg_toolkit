function blp = blpfratio(SesName, GrpName, RoiName, pVal, bSign)
%BLPFRATIO - Show the F-Ratio of reduced-to-full design matrix for each frequency band
% blp = blpfratio(SesName, GrpName, RoiName) computes the F Ratio for different
% regressors (ClnSpc or BLP).
%
% EXAMPLES
%       blp = blpfratio('n02gu1');  (Defaults Group='fix', Roi='ele')
%       blp = blpfratio('n02gu1', 'fix', 'ele');
%       blp = blpfratio('alert','all');
%       blp = blpfratio('alert','kftop');
%
% NKL 23.01.2008
%
%  See also dspfratio

if nargin < 5,  bSign = 1;                end;
if nargin < 4,  pVal = 0.01;              end;
if nargin < 3,  RoiName = 'v1';           end;
if nargin < 2,  GrpName = 'grat';         end;
if nargin < 1,  help blpfratio; return;   end;

tmpblp = subBlpfratio(SesName,GrpName,RoiName);

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

blp = tmpblp;
blp.arg1 = SesName;
blp.arg2 = GrpName;

if ~nargout,
  if ~exist('Selection','var'),
    Selection = SesName;
  end;
  fname = strcat('alfratio_',Selection);
  fprintf(' Saving ''BLP'' to ''s''...',fname);
  supgroupsave(fname,{'blp'}, blp);
  fprintf('done.\n');
  
  dspfratio(blp);
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function blp = subBlpfratio(SesName, GrpName, RoiName)
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
  blp = subProc(SesName,GrpName,RoiName);
else
  % grp.groupglm = 'after glm'
  for iExp = 1:length(grp.exps),
    fprintf('.');
    tmpblp = subProc(SesName,grp.exps(iExp),RoiName);
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

  % required to avoid error in dspfratio()
  % don't know this is correct or not...
  blp.y = nanmean(blp.y,2);
  blp.p = nanmean(blp.p,2);
  
end


return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function blp = subProc(SesName,GrpExp,RoiName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

grp = getgrp(SesName,GrpExp);

roiTs = sigload(SesName,GrpExp,'troiTs');
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
  blp.bands     = grp.bands;
  blp.xticklabel= grp.bandnames;
  blp.xlabel    = 'Center Frequency in Hz';
  blp.ylabel    = 'F-Ratio';
  blp.date      = date;
  blp.time      = gettimestring;
end;

