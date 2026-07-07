function roiTs = dispderiv(roiTs, radius)
%DISPDERIV - Select roiTs on the basis models and electrode-distance
% dispderiv(SesName,GrpName) - will first select roiTs on the basis of GLM. Default is
% fVal of the following design matrix:
% --------------------------------------
% GRPP.glmconts = [];       % INJ-ROI,          PARA-INJ-ROI,     V1-Unaffected
% GRPP.glmana{DNO}.mdlsct = {'AvgModel.mat[1]','AvgModel.mat[2]','AvgModel.mat[3]'};
% NoReg = length(GRPP.glmana{DNO}.mdlsct) + 1;
% GRPP.glmconts{end+1} = setglmconts('f','fVal',  NoReg,'pVal',0.1,'WhichDesign',DNO);
% GRPP.glmconts{end+1} = setglmconts('t','base',  [ 1  1  0  0],'pVal',1,'WhichDesign',DNO);
% GRPP.glmconts{end+1} = setglmconts('t','pbr',   [ 0  0  1  0],'pVal',1,'WhichDesign',DNO);
% P-value was set to p<1e-8.
% --------------------------------------
% Following the GLM-selection, the sub-function selSubROI further categorizes response on the
% basis of the distance of voxels to the electrode-tip. The categories reflect the spread of
% activity measured with LFP/MUA (see Current Biology 2008 paper with Jozien Goense), as well
% as all information included in the ACh_NKL_Ana.pptx file.
% --------------------------------------
% Finally, we compute the baseline-shift and the power-modulation per trial for each of the
% selected spatial (ele-tip related) regions
% Use dispderiv(SesName, GrpName) w/out output argument to plot the selected roiTs and
% also to see modulation/baseline as a function of time.
%  
% NKL 27.12.2010

if nargin < 2,
  radius = 8;
end;

if ~nargin,
  SesName   = 'rat6e1';       % Session/ExpNo used for debugging...
  ExpNo     = 7;
  SigName   = 'roiTs';
  ROINAME   = 'hipp';
  Ses       = goto(SesName);
  grp       = getgrp(Ses,ExpNo);
  anap      = getanap(Ses, grp.name);
  Sig       = sigload(Ses, ExpNo, SigName);
  roiTs     = mvoxselect(Sig,ROINAME,[],[]);
end;

if isstruct(roiTs),
  roiTs = subNorm2Neighborhood(roiTs, radius);    % 3mm radius
else
  for N=1:length(roiTs),
    roiTs{N} = subNorm2Neighborhood(roiTs{N}, radius);    % 3mm radius
  end;
end;

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Ts = subNorm2Neighborhood(roiTs, neiRadius)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if neiRadius < 0,
  m = nanmean(roiTs.dat,2);
  roiTs.dat = roiTs.dat - repmat(m, [1 size(roiTs.dat,2)]);
  Ts = roiTs;
  return;
end;
  
ds = roiTs.ds(1:2).*roiTs.ds(1:2);
neiRadius = round(neiRadius/sqrt(sum(ds)));
TScoord = roiTs.coords;

Ts = roiTs;
for N=1:size(roiTs.dat,2),
  cCoord = TScoord(N,:);
  scoord = TScoord - repmat(cCoord,[size(TScoord,1) 1]);
  scoord = scoord .* repmat(roiTs.ds,[size(scoord,1) 1]);

  tmpdist = sqrt(sum(scoord.^2,2));
  idx = find(tmpdist<=neiRadius);
  idx(find(idx==N)) = [];
  dat = Ts.dat(:,idx);
  Ts.dat(:,N) = roiTs.dat(:,N) - nanmean(dat,2);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Ts = selSubROI_EleDist(roiTs, MUA_DIST, LFP_DIST, FAR_DIST)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    ana: [110x60x7 double]
%   name: 'brain'
% coords: [9228x3 double]
%    dat: [592x9228 double]
%    stm: [1x1 struct]
%     ds: [0.2500 0.2500 0.8530]

scoord = roiTs.coords;
ecoord = [round(roiTs.ele{1}.x) round(roiTs.ele{1}.y) round(roiTs.ele{1}.slice)];
scoord = scoord - repmat(ecoord,[size(scoord,1) 1]);
scoord = scoord .* repmat(roiTs.ds,[size(scoord,1) 1]);

% ------------------------------------------------------------------------------------
% NOTES from CB2008 and Nature Review
% Delta-Theta radius = 3-4mm, nMod=2-3mm, Gamma=1-2mm, MUA=1-2mm, SUA below 1mm
% Here I can define as 4mm radius the LFP & 2mm MUA
% ------------------------------------------------------------------------------------
NBANDS = 3;
SLICES = unique(roiTs.coords(:,3));
DEBUG = 0;
if DEBUG,
  mfigure([100 500 1450 400]);
  for N=1:length(SLICES),
    subplot(1,length(SLICES),N);
    idx = find(roiTs.coords(:,3)==SLICES(N));
    xy = scoord(idx,:);
    ele_dist = sqrt(sum(xy.^2,2));
    muaidx = find(ele_dist<=2);
    lfpidx = find(ele_dist>2 & ele_dist<=4);
    faridx = find(ele_dist>4);
    plot(xy(muaidx,1), xy(muaidx,2),...
         'marker','s','markersize',3,'markerfacecolor','r','markeredgecolor','none','linestyle','none');
    hold on;
    plot(xy(lfpidx,1), xy(lfpidx,2),...
         'marker','s','markersize',3,'markerfacecolor','g','markeredgecolor','none','linestyle','none');
    plot(xy(faridx,1), xy(faridx,2),...
         'marker','s','markersize',3,'markerfacecolor','b','markeredgecolor','none','linestyle','none');
    grid on;
    set(gca,'ydir','reverse');
  end;
end;
ele_dist = sqrt(sum(scoord.^2,2));
muaidx = find(ele_dist<=MUA_DIST);
lfpidx = find(ele_dist>MUA_DIST & ele_dist<=LFP_DIST);
faridx = find(ele_dist>FAR_DIST);

Ts{1}           = roiTs;
Ts{1}.coords    = Ts{1}.coords(lfpidx,:);
Ts{1}.dat       = Ts{1}.dat(:, lfpidx);
Ts{1}.roilabel  = sprintf('LFP-Extent (Dist<=%gmm)',LFP_DIST);
Ts{2}           = roiTs;
Ts{2}.coords    = Ts{2}.coords(muaidx,:);
Ts{2}.dat       = Ts{2}.dat(:, muaidx);
Ts{2}.roilabel  = sprintf('MUA-Extent (Dist<=%gmm)',MUA_DIST);
Ts{3}           = roiTs;
Ts{3}.coords    = Ts{3}.coords(faridx,:);
Ts{3}.dat       = Ts{3}.dat(:, faridx);
Ts{3}.roilabel  = sprintf('Delta+ Region (Dist>%gmm)',FAR_DIST);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subDispMaps(roiTs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
COLORS={[0 1 0],[1 0 0],[0 0 1],[1 0 1],[0 .7 .7],[.7 0 .7],[0 0 .4],[.4 .4 0],[.3 .6 .3]};
SLICES = unique(roiTs{1}.coords(:,3));  % All roiTs have the same slices
ANA = double(roiTs{1}.ana(:,:,SLICES));
anaminv  = 0;
anamaxv  = 0;
if anamaxv == 0,  anamaxv = round(mean(ANA(:))*3.5);  end
ANARGB = subScaleAnatomy(ANA,anaminv,anamaxv,1.3);

NRow = 3;  NCol = 1;  %  4 images in a page
nX = size(ANA,1);
nY = size(ANA,2);
X  = 0:nX-1;
Y  = nY-1:-1:0;

% Construct real images ([x,y,z,n])
IMGSIZE = size(ANA);
map = NaN([IMGSIZE, length(roiTs)]);
for N = 1:length(roiTs),
  COORDS = roiTs{N}.coords;
  % This here is to turn slices (e.g.) 3, 4, 5 to 1, 2, 3....
  COORDS(:,3) = COORDS(:,3) - min(COORDS(:,3)) + 1;
  for K = 1:size(COORDS,1),
    map(COORDS(K,1),COORDS(K,2),COORDS(K,3),N) = N;
  end;
end;

for N = 1:size(ANARGB,3),
  tmpimg = squeeze(ANARGB(:,:,N,:));
    
  iCol = floor((N-1)/NCol)+1;
  iRow = mod((N-1),NCol)+1;
  offsX = nX*(iRow-1);
  offsY = nY*NRow - iCol*nY;
  tmpx = X + offsX;
  tmpy = Y + offsY;
  image(tmpx,tmpy,permute(tmpimg,[2 1 3]));  hold on;

  for K = 1:length(roiTs),
    tmpcol = COLORS{K};
    tmps   = squeeze(map(:,:,N,K));
    idx = find(~isnan(tmps(:)));
    if isempty(idx),  continue;  end
    [xc,yc] = ind2sub(IMGSIZE(1:2),idx);
    xc = xc-1;  % because 'X' starts from 0
    yc = yc-1;  % because 'Y' starts from 0
    xc = xc*nX/IMGSIZE(1) + offsX;
    yc = offsY + nY - yc*nY/IMGSIZE(2);
    hold on;
    selv = tmps(idx);
    % plot positive
    sel  = find(selv(:) > 0);
    edgecol = tmpcol;
    if ~isempty(sel),
      plot(xc(sel)-(K-1)/4,yc(sel)-(K-1)/4,'marker','s','markersize',3,...
           'markerfacecolor',tmpcol,'markeredgecolor',edgecol,'linestyle','none');
    end
    % plot negative
    sel  = find(selv(:) < 0);
    edgecol = 'k';
    if ~isempty(sel),
      plot(xc(sel)-(K-1)/4,yc(sel)-(K-1)/4,'marker','s','markersize',3,...
           'markerfacecolor',tmpcol,'markeredgecolor',edgecol,'linestyle','none');
    end
  end;
end
set(gca,'xlim',[0 nX*NCol-0.5],'ylim',[0 nY*NRow-0.5],'Ydir','normal',...
        'YTickLabel',{},'YTick',[],'XTickLabel',{},'XTick',[],'Ydir','normal');
axis off
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to scale anatomy image
function ANARGB = subScaleAnatomy(ANA,MINV,MAXV,GAMMA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmpana = double(ANA);
tmpana = (tmpana - MINV) / (MAXV - MINV);
tmpana = round(tmpana*255) + 1; % +1 for matlab indexing
tmpana(find(tmpana(:) <   0)) =   1;
tmpana(find(tmpana(:) > 256)) = 256;
anacmap = gray(256).^(1/GAMMA);
for N = size(tmpana,3):-1:1,
  ANARGB(:,:,:,N) = ind2rgb(tmpana(:,:,N),anacmap);
end
ANARGB = permute(ANARGB,[1 2 4 3]);  % [x,y,rgb,z] --> [x,y,z,rgb]
return;

