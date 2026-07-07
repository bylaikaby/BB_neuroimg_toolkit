function [RVAL, idx] = icaselect(SesName, GrpName, rVal, DISP_THRESHOLD)
%ICASELECT - Select ICs according to their similarity with models defined in MDL_GrpName.mat
% oSig = icaselect(oSig), sorts out ICs according to their r value and selects the top one
% on the basis of correlation analysis
%
% GRPP.anap.ica.ClnSpc.evar_keep  = 20;
% GRPP.anap.ica.ClnSpc.dim        = 'spatial';
% GRPP.anap.ica.ClnSpc.type       = 'bell';
% GRPP.anap.ica.ClnSpc.normalize  = 'none';
%
% GRPP.anap.ica.roinames          = {'SC','LGN','V1','V2','MT'};
% GRPP.anap.ica.evar_keep         = 25;           % Numbers of PCs to keep
% GRPP.anap.ica.dim               = 'spatial';    % Temporal does not really work...
% GRPP.anap.ica.type              = 'bell';       % The Tony Bell algorithm
% GRPP.anap.ica.normalize         = 'none';       % No normalization (e.g. to SD etc.)
% GRPP.anap.ica.period            = 'all';        % blank, stim, all...
% GRPP.anap.ica.icomp             = [1:10];       % Display these components
% GRPP.anap.ica.ic2mdl            = [];           % Use the following ICs as models for GLM
% GRPP.anap.ica.pVal              = 0.05;         % pVal for corr(mixica,IComponent)
% GRPP.anap.ica.rVal              = 0.6;          % rVal-thr for corr(mixica,IComponent)
%
% Currently called by
%   icagetroi.m:27:  Sig = icaselect(Sig);
%   mkicaroi.m:50:  oSig = icaselect(oSig);
%
% 'b06lv1' 'b06lp1' 'h05km1' 'h05l21' 'h05ni1' 'h05lr1' 'h05np1'
%
% NKL 17.06.09

GABA_INJECTION = 1;

if nargin < 4,  DISP_THRESHOLD = 1.5; end;
if nargin < 2,  GrpName = 'esinj';   end;
if nargin < 1,  help icaselect; return; end;

Ses = goto(SesName);
grp = getgrpbyname(SesName, GrpName);
anap = getanap(SesName,GrpName);

if ~GABA_INJECTION,
  fname = sprintf('Mdl_%s.mat', GrpName);
  if ~exist(fname,'file'),
    fprintf('Model-File %s does not exist!\n', fname);
    fprintf('Run esmodels(SesName, GrpName,''avgresp''\n');
    return;
  end;

  % NOW LOAD MODEL
  load(fname,'model');
  if isfield(anap.ica,'mdlidx') & ~isempty(anap.ica.mdlidx),
    model.dat = model.dat(:,anap.ica.mdlidx);
  end;
else
  % For the injection experiments we have a whole-session average of the 4 response types,
  % namely INJ, V1, V2, IPZ
  load('Mdl_inj.mat','model');
  model.dat = nanmean(model.dat,3);
  goto(SesName);
end;

% -------------------------------------------------------
% FOR PHARMACOLOGY DEFINED IN ESINJGETPARS()
% -------------------------------------------------------
pVal = anap.ica.pVal;
if nargin < 3,
  rVal = anap.ica.rVal;
end;

if isfield(anap,'gettrial') & anap.gettrial.status > 0,
  SIGNAME = 'troiTs';
else
  SIGNAME = 'roiTs';
end

ICA_DIM = 'spatial';
if isfield(anap.ica,'dim'),
  ICA_DIM = anap.ica.dim;
end
if isfield(anap.ica,SIGNAME) & isfield(anap.ica.(SIGNAME),'dim'),
  ICA_DIM = anap.ica.(SIGNAME).dim;
end

icafile = sprintf('ICA_%s_%s_%s.mat',grp.name,SIGNAME,ICA_DIM);
if ~exist(icafile,'file'),
  fprintf('ICA-File %s does not exist!\n', icafile);
  fprintf('Run getica(SesName, GrpName)\n');
  return;
end;

tcICA =  icaload(SesName, GrpName, DISP_THRESHOLD);

%%%%%%%%%%%%%%%%%%%%%%%%%%
CompType = 'raw';
%%%%%%%%%%%%%%%%%%%%%%%%%%
eval(sprintf('tmpTs = tcICA.%s;', CompType));

if rVal,
  for N=1:size(model.dat,2),
    [cc(N,:), p(N,:)] = mcor(model.dat(:,N),tmpTs.dat,2);
  end;
  r = max(cc);
  p = min(p);
  r(find(p>=pVal)) = 0;
  r(find(r<=rVal)) = 0;
  [RVAL, RIDX]=sort(r,2,'descend');
  RIDX(find(RVAL==0)) = 0;

  tmpidx = find(RIDX);
  RIDX = RIDX(tmpidx);
  
  tcICA.map = tcICA.map(RIDX,:);
  tmpTs.dat = tmpTs.dat(:,RIDX);
end;

if nargout,
  return;
end;

Normalize   = 'percent';
Distance    = 'sqEuclidean';    % 'correlation'; 'cityblock'; cosine does not work..
Replicates  = 100;
NumClusters = 4;
DoMDS       = 0;                % do multidimensional scaling

[IDX,C,sumd,D] = kmeans(tmpTs.dat',NumClusters,'Replicates',Replicates,'Distance',Distance);
tcICA.kmeans.normalize     = Normalize;
tcICA.kmeans.mds           = DoMDS;
tcICA.kmeans.idx           = IDX;
tcICA.kmeans.C             = C;
tcICA.kmeans.sumd          = sumd;
tcICA.kmeans.D             = D;
tcICA.kmeans.distance      = Distance;
tcICA.kmeans.replicates    = Replicates;

for N=1:NumClusters,
  idx = find(IDX == N);
  map = []; ts = [];
  for K=1:length(idx),
    map = cat(3,map,tcICA.map(idx(K),:));
    ts = cat(3,ts,tmpTs.dat(:,idx(K)));
  end;
  savmap(N,:) = max(map,[],3);
  savts(:,N) = hnanmean(ts,3);
end;
tcICA.map = savmap;
tmpTs.dat = savts;

for N=1:size(model.dat,2),
  [r, p] = mcor(model.dat(:,N),tmpTs.dat,0);
  [mx, ix(N)] = max(r);
end;
tmpTs.dat = tmpTs.dat(:,ix);
tcICA.map = tcICA.map(ix,:);
IComp = [1:size(tmpTs.dat,2)];

eval(sprintf('tcICA.%s = tmpTs;', CompType));

% PLOT Selected ICs
Ses     = goto(SesName);
grp     = getgrp(Ses,GrpName);
anap    = getanap(Ses,GrpName);
stminfo = grp.stminfo;

mfigure([1 500 900 600]);
POS1 = [0.0500    0.1100    0.40    0.8150];
POS2 = [0.5303    0.1100    0.43    0.8150];

% ANAP.showmap.COL_LINE     = 'rcbm';
set(gcf,'color','w');
subplot('position',POS1);
icaplotclusters(tcICA,IComp);

for N=1:length(IComp)
  msubplot(length(IComp),2,2*N);
  icaplotts(tcICA, IComp(N), CompType, 0, IComp(N));
end;
return;

