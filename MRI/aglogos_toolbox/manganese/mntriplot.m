function mntriplot(SESSION,GRPNAME)
%MNTRIPLOT - plots coronal/sagital/transverse sections.
%
%  VERSION :
%    0.90 23.07.05 YM  pre-release
%
%  See also MNVIEW
  
% !!!!!!!!! PARAMETERS FOR D03se1 !!!!!!!!!!!!!!!!!!!!!!
PERMUTE_VEC = [1 3 2];
iX = 123;  iY = 80;  iZ = 63;
MINV = 0;  MAXV = 40;
GAMMA = 1.2;


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);





ANA = load(sprintf('%s.mat',grp.ana{1}),grp.ana{1});
ANA = ANA.(grp.ana{1}){grp.ana{2}};
% do permutation, if given
if ~isempty(PERMUTE_VEC),
  ANA.dat = permute(ANA.dat,PERMUTE_VEC);
  ANA.ds  = permute(ANA.ds,PERMUTE_VEC);
end
% converts ANA.dat into RGB
cmap = gray(256).^(1/1.8);	% 1.8 as gamma
tmpana = double(ANA.dat);
%tmpana = tmpana / (max(tmpana(:))*0.7);
tmpana = tmpana / (max(tmpana(:))*0.6);
tmpana = round(tmpana*255) + 1; % +1 for matlab indexing
tmpana(find(tmpana(:) <   0)) =   1;
tmpana(find(tmpana(:) > 256)) = 256;
for N = size(tmpana,3):-1:1,
  ANARGB(:,:,:,N) = ind2rgb(tmpana(:,:,N),cmap);
end
ANARGB = permute(ANARGB,[1 2 4 3]);  % [x,y,rgb,z] --> [x,y,z,rgb]
ANA.rgb = ANARGB;
clear tmpana;



nX = size(ANA.dat,1);  nY = size(ANA.dat,2);  nZ = size(ANA.dat,3);
x = [0:nX-1]*ANA.ds(1);  y = [0:nY-1]*ANA.ds(2);   z = [0:nZ-1]*ANA.ds(3);

MASKTHR = mean(ANA.dat(:))*0.5;

load('ttest20050718 regress=brain\ttest_pca(0)_normalize(global)_xyfilter(0)_cluster(1).mat');





STATS.dat = permute(STATS.dat, PERMUTE_VEC);
STATS.p   = permute(STATS.p,   PERMUTE_VEC);
if isfield(STATS,'mask') & ~isempty(STATS.mask),
  if isfield(STATS.mask,'dat') & ~isempty(STATS.mask.dat),
    STATS.mask.dat = permute(STATS.mask.dat, PERMUTE_VEC);
  end
end
ALPHA = STATS.mask.alpha;


CMAP = jet(256).^(1/GAMMA);

hFig = mfigure([1 50 1500 1150]);

% CORONAL
%subplot(2,2,1);
axes('pos', [0.12    0.64    0.3347    0.3412]);
tmpimg = squeeze(ANA.rgb(:,iY,:,:));
tmpana = squeeze(ANA.dat(:,iY,:));
tmps   = squeeze(STATS.dat(:,iY,:));
tmpp   = squeeze(STATS.p(:,iY,:));
tmpm   = squeeze(STATS.mask.dat(:,iY,:));
subPlot(tmpimg,tmpana,MASKTHR,x,z,tmps,tmpp,tmpm,MINV,MAXV,ALPHA,CMAP);
line([iX-1, iX-1]*ANA.ds(1),get(gca,'ylim'),'color','y');
line(get(gca,'xlim'),[iZ-1, iZ-1]*ANA.ds(3),'color','y');
x0 = 1;  y0 = 1;
line([0 10]+x0,[y0 y0],'color','white','linewidth',4);
text(x0+11,y0,'10mm','color','white','fontname','Comic Sans MS','fontweight','bold','fontsize',10);
axis off;
daspect([1 1 1]);



% SAGITAL
%subplot(2,2,2);
axes('pos', [0.50    0.595    0.4250    0.4333]);
tmpimg = squeeze(ANA.rgb(iX,:,:,:));
tmpana = squeeze(ANA.dat(iX,:,:));
tmps   = squeeze(STATS.dat(iX,:,:));
tmpp   = squeeze(STATS.p(iX,:,:));
tmpm   = squeeze(STATS.mask.dat(iX,:,:));
subPlot(tmpimg,tmpana,MASKTHR,y,z,tmps,tmpp,tmpm,MINV,MAXV,ALPHA,CMAP);
line([iY-1, iY-1]*ANA.ds(2),get(gca,'ylim'),'color','y');
line(get(gca,'xlim'),[iZ-1, iZ-1]*ANA.ds(3),'color','y');
x0 = 1;  y0 = 1;
line([0 10]+x0,[y0 y0],'color','white','linewidth',4);
text(x0+11,y0,'10mm','color','white','fontname','Comic Sans MS','fontweight','bold','fontsize',10);
axis off;
daspect([1 1 1]);
%pos = get(gca,'pos');
%pos([1 2]) = pos([1 2]) - 0.045;
%pos([3 4]) = pos([3 4])*1.27;
%set(gca,'pos',pos);


% TRANSVERSE
%subplot(2,2,3);
axes('pos',[0.042 0.1 0.49 0.546]);
tmpimg = squeeze(ANA.rgb(:,:,iZ,:));
tmpana = squeeze(ANA.dat(:,:,iZ));
tmps   = squeeze(STATS.dat(:,:,iZ));
tmpp   = squeeze(STATS.p(:,:,iZ));
tmpm   = squeeze(STATS.mask.dat(:,:,iZ));
subPlot(tmpimg,tmpana,MASKTHR,x,y,tmps,tmpp,tmpm,MINV,MAXV,ALPHA,CMAP);
line([iX-1, iX-1]*ANA.ds(1),get(gca,'ylim'),'color','y');
line(get(gca,'xlim'),[iY-1, iY-1]*ANA.ds(2),'color','y');
x0 = 1;  y0 = max(y)-2;
line([0 10]+x0,[y0 y0],'color','white','linewidth',4);
text(x0+11,y0,'10mm','color','white','fontname','Comic Sans MS','fontweight','bold','fontsize',10);
axis off;
daspect([1 1 1]);
%pos = get(gca,'pos');
%pos([2]) = pos([2])+0.1;
%pos([3 4]) = pos([3 4])*1.5;
%set(gca,'pos',pos);



% COLORBAR
subplot(2,2,4);
ydat = [0:255]/255 * (MAXV - MINV) + MINV;
hColorbar = imagesc(1,ydat,[0:255]'); colormap(CMAP);
set(gca,'ylim',[MINV MAXV],...
        'FontName','Comic Sans MS','fontweight','bold',...
        'YAxisLocation','right','XTickLabel',{},'XTick',[],'Ydir','normal');
pos = get(gca,'pos');  pos(3) = pos(3)*0.2;  set(gca,'pos',pos);

title(sprintf('T-stat, ALPHA=%g',ALPHA));


return;




function subPlot(tmpimg,tmpana,MASKTHR,x,y,tmps,tmpp,tmpm,MINV,MAXV,ALPHA,CMAP)
idx = find(tmpm(:) == 0);
tmps(idx) = 0;
tmpp(idx) = 1;

idx = find(tmpana(:) < MASKTHR);
tmps(idx) = 0;
tmpp(idx) = 1;

tmpimg = subFuseImage(tmpimg,tmps,MINV,MAXV,tmpp,ALPHA,CMAP);

image(x,y,permute(tmpimg,[2 1 3]));
set(gca,'ydir','reverse','xlim',[0 max(x)],'ylim',[0 max(y)]);

hold on;



return;





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to fuse anatomy and functional images
function IMG = subFuseImage(ANARGB,STATV,MINV,MAXV,PVAL,ALPHA,CMAP)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
IMG = ANARGB;
if isempty(STATV) | isempty(PVAL) | isempty(ALPHA),  return;  end

PVAL(find(isnan(PVAL(:)))) = 1;  % to avoid error;

tmpdat = repmat(PVAL,[1 1 3]);   % for rgb
idx = find(tmpdat(:) < ALPHA);
if ~isempty(idx),
  % scale STATV from MINV to MAXV as 0 to 1
  STATV = (STATV - MINV)/(MAXV - MINV);
  STATV = round(STATV*255) + 1;  % +1 for matlab indexing
  STATV(find(STATV(:) <   0)) =   1;
  STATV(find(STATV(:) > 256)) = 256;
  % map 0-256 as RGB
  STATV = ind2rgb(STATV,CMAP);
  % replace pixels
  IMG(idx) = STATV(idx);
end

 
return;
