function fratio = sesfratio(SesName, GrpName, RoiName, GLM_ALPHA)
%SESFRATIO - Compute F-Ratio of each group and save in the group file (Anesth. EXPS)
% fratio = sesfratio(SesName, GrpName, RoiName) computes the F Ratio for different
% regressors (ClnSpc or BLP).
%
% EXAMPLES
%
% NKL 23.01.2008

if nargin < 4,  GLM_ALPHA = 1;          end;
if nargin < 3,  RoiName = 'fratio';     end;
if nargin < 1,  help sesfratio; return; end;

% GET BASIC INFO
Ses  = goto(SesName);
grpnames = getgrpnames(Ses);

for N=1:length(grpnames),
  fprintf('%s: %s(%s) P<%g Processing : ',upper(mfilename),Ses.name,grpnames{N},GLM_ALPHA);
  % blp = algetfratio(Arg1, Arg2, RoiName, pVal, bSign, mdl)
  algetfratio(Ses.name,grpnames{N},'brain',0.01,1);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OLD STUFF _ KEEP!!!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 2 | isempty(GrpName) | issupgrp(SesName,GrpName),
  [grpnames, supgrpname] = supgrpmembers(SesName);
  EXPS = [];
  for N=1:length(grpnames),
    exps = getexps(Ses,grpnames{N});
    EXPS = cat(2,EXPS,exps);
  end;
  GrpName = supgrpname;
else
  EXPS = getexps(SesName,GrpName);
end;

fprintf('%s: %s(%s) P<%g Processing : ',upper(mfilename),Ses.name,GrpName,GLM_ALPHA);

PrepType = getpreptype(SesName);

BEFORE_GLM = 1;
ALL_GROUPS = 1;

if ~isempty(PrepType),
  if strcmp(PrepType,'anest') & ~BEFORE_GLM,
    for N=1:length(EXPS),
      ExpNo = EXPS(N);
      fprintf('%d.',ExpNo);
      tmpfratio = subSesfratio(SesName,ExpNo,RoiName,GLM_ALPHA);
      if N==1,
        fratio = tmpfratio;
      else
        fratio.y = cat(2,fratio.y,tmpfratio.y);
        fratio.p = cat(2,fratio.p,tmpfratio.p);
      end;
    end;
    fprintf('\n');
  elseif strcmp(PrepType,'anest') & BEFORE_GLM,
    if ALL_GROUPS,
      grpnames = getgrpnames(SesName);
    else
      grpnames = supgrpmembers(SesName);
    end;
    for N=1:length(grpnames),
      fratio = subAlgetfratio(SesName,grpnames{N},RoiName,GLM_ALPHA);
    end;
  else
    fratio = subAlgetfratio(SesName,GrpName,RoiName,GLM_ALPHA);
  end;
else
  fratio = subAlgetfratio(SesName,GrpName,RoiName,GLM_ALPHA);
end;

if ~nargout,
  if sesversion(SesName) >= 2,
    sigsave(SesName,GrpName,'fratio',fratio);
  else
    fname = sigfilename(SesName,GrpName,'mat');
    fprintf('saving ''fratio'' to ''%s''...',fname);
    save(fname,'-append', 'fratio');
    fprintf('done.\n');
  end
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fratio = subSesfratio(SesName, ExpNo, RoiName, GLM_ALPHA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       groupglm: 'before glm'
%       glmconts: {1x56 cell}
%         glmana: {1x54 cell}
%          Freqs: [1x45 double]
%          NoReg: 45
%        RegName: {1x45 cell}
%     FullDesIdx: 2
%     FullConIdx: 4
%      ConDesIdx: 5
%        bDesIdx: 48
%     bConDesIdx: 50
%         bFreqs: [5.0862 15.2588 38.9947 74.5985 106.8116 135.6336 160]
%         bNoReg: 7
%       bRegName: {'bP005'  'bP015'  'bP039'  'bP075'  'bP107'  'bP136'  'bMUA'}
roiTs = sigload(SesName,ExpNo,'roiTs');
roiTs = mroitsget(roiTs,[],RoiName);
roiTs = roiTs{1};
grp = getgrp(SesName, ExpNo);

% selecton by Pvalue
if GLM_ALPHA < 1,
  tmpidx = find(roiTs.glmcont(grp.FullConIdx).pvalues < GLM_ALPHA);
  selvox = roiTs.glmcont(grp.FullConIdx).selvoxels(tmpidx);
  FFull = nanmean(roiTs.glmcont(grp.FullConIdx).statv(tmpidx));
else
  selvox = roiTs.glmcont(grp.FullConIdx).selvoxels;
  FFull = nanmean(roiTs.glmcont(grp.FullConIdx).statv(:));
end

sIdxB = grp.bConDesIdx;
eIdxB = sIdxB + grp.bNoReg - 1;

K=1;
for N=sIdxB:eIdxB,
  if GLM_ALPHA < 1,
    % pick up voxels that are common to FFull
    [c ia ib] = intersect(selvox,roiTs.glmcont(N).selvoxels);
    bF(K) = nanmean(roiTs.glmcont(N).statv(ib));
  else
    bF(K) = nanmean(roiTs.glmcont(N).statv(:));
  end  
  
  tmpNoReg = grp.NoReg - length(grp.blpidx{K});
  [F_ratB(K), p_ratB(K)] = F_ratio(FFull,bF(K),grp.NoReg,tmpNoReg,size(roiTs.dat,1));
  K = K + 1;
end;

if nargout,
  fratio.sesname = SesName;
  fratio.grpname = ExpNo;
  fratio.roiname = RoiName;
  fratio.xlabel = 'Center Frequency in Hz';
  fratio.ylabel = 'F-Ratio';
  fratio.x = [1:length(F_ratB)]';
  fratio.y = double(F_ratB(:));
  fratio.p = double(p_ratB(:));
  fratio.xlim = [0 length(F_ratB)+1];
  fratio.xticklabel = grp.bRegName;
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fratio = subAlgetfratio(SesName, GrpName, RoiName, GLM_ALPHA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
roiTs = sigload(SesName,GrpName,'roiTs');
roiTs = mroitsget(roiTs,[],RoiName);
roiTs = roiTs{1};

grp = getgrpbyname(SesName, GrpName);

% selecton by Pvalue
if GLM_ALPHA < 1,
  tmpidx = find(roiTs.glmcont(grp.FullConIdx).pvalues < GLM_ALPHA);
  selvox = roiTs.glmcont(grp.FullConIdx).selvoxels(tmpidx);
  FFull = nanmean(roiTs.glmcont(grp.FullConIdx).statv(tmpidx));
else
  selvox = roiTs.glmcont(grp.FullConIdx).selvoxels;
  FFull = nanmean(roiTs.glmcont(grp.FullConIdx).statv(:));
end

% FFull = nanmean(roiTs.glmcont(grp.FullConIdx).statv(:));

sIdxB = grp.bConDesIdx;
eIdxB = sIdxB + grp.bNoReg - 1;

K=1;
for N=sIdxB:eIdxB,
  
  if GLM_ALPHA < 1,
    % pick up voxels that are common to FFull
    [c ia ib] = intersect(selvox,roiTs.glmcont(N).selvoxels);
    bF(K) = nanmean(roiTs.glmcont(N).statv(ib));
  else
    bF(K) = nanmean(roiTs.glmcont(N).statv(:));
  end  
  
  tmpNoReg = grp.NoReg - length(grp.blpidx{K});
  [F_ratB(K), p_ratB(K)] = F_ratio(FFull,bF(K),grp.NoReg,tmpNoReg,size(roiTs.dat,1));
  K = K + 1;
end;

if nargout,
  fratio.sesname = SesName;
  fratio.grpname = GrpName;
  fratio.roiname = RoiName;
  fratio.xlabel = 'Center Frequency in Hz';
  fratio.ylabel = 'F-Ratio';
  fratio.x = [1:length(F_ratB)]';
  fratio.y = double(F_ratB(:));
  fratio.p = double(p_ratB(:));
  fratio.xlim = [0 length(F_ratB)+1];
  fratio.xticklabel = grp.bRegName;
end;
return;


