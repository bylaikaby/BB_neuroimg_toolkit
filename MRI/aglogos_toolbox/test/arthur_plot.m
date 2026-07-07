function arthur_plot(roiTs,ALPHA)

if nargin < 2,  ALPHA = 0.1;  end

if isstruct(roiTs),  roiTs = { roiTs };  end


% scaling
MINMAX = [ -1  1 ];
  

EPIDIM = [roiTs{1}.grp.imgcrop(3:4) size(roiTs{1}.ana,3)];
  
ANAIMG = roiTs{1}.ana;
RMAP   = zeros(EPIDIM);
PMAP   = ones(EPIDIM);

% get R and P maps
for N = 1:length(roiTs),
  xyz  = roiTs{N}.coords;
  tmpR = roiTs{N}.r;
  tmpP = roiTs{N}.p;
  for M = 1:length(tmpR),
    idx = sub2ind(EPIDIM,xyz(:,1),xyz(:,2),xyz(:,3));
    RMAP(idx) = tmpR{M}(:);
    PMAP(idx) = tmpP{M}(:);
  end
end


% resize R and P map, if needed
if any(size(ANAIMG) ~= EPIDIM),
  RMAP = imresize(RMAP,size(ANAIMG));
  PMAP = imresize(PMAP,size(ANAIMG));
end


% make multiple slices as a single image
ANAIMG = mgetcollage(ANAIMG);
RMAP   = mgetcollage(RMAP);
PMAP   = mgetcollage(PMAP);


% make anatomy as RGB
cmapA = gray(256);
ANAIMG = ANAIMG / max(ANAIMG(:));
ANAIMG = round(ANAIMG*255) + 1;	  % +1 for matlab indexing
ANAIMG(find(ANAIMG(:) <   0)) =   1;
ANAIMG(find(ANAIMG(:) > 230)) = 230;
FUSED_RGB = ind2rgb(ANAIMG,cmapA);


% make functional as RGB
posmap = hot(128);
negmap = zeros(128,3);
negmap(:,3) = [1:128]'/128;
%negmap(:,2) = flipud(brighten(negmap(:,3),-0.5));
negmap(:,3) = brighten(negmap(:,3),0.5);
negmap = flipud(negmap);
cmapF = [negmap; posmap];


minv = min(MINMAX);
maxv = max(MINMAX);
RMAP = (RMAP - minv) / (maxv - minv);  % scaling min-max as 0-1
RMAP = round(RMAP*255) + 1;            % +1 for matlab indexing
RMAP(find(RMAP(:) <   0)) =   1;
RMAP(find(RMAP(:) > 256)) = 256;
FUNCRGB = ind2rgb(RMAP,cmapF);


% fuse anatomy and functional
tmppmap = repmat(PMAP,[1 1 3]);  % for rgb indexing
idx = find(tmppmap(:) < ALPHA);
if ~isempty(idx),
  FUSED_RGB(idx) = FUNCRGB(idx);
end




if length(roiTs{1}.ExpNo) > 1,
  tmptxt = sprintf('%s grp=%s P<%f',roiTs{1}.session,roiTs{1}.grpname,ALPHA);
else
  tmptxt = sprintf('%s exp=%d P<%f',roiTs{1}.session,roiTs{1}.ExpNo,ALPHA);
end
if isfield(roiTs{1},'naverages'),
  tmptxt = sprintf('%s naverages=%d',tmptxt,roiTs{1}.naverages);
end

tmptxt = strrep(tmptxt,'_','\_');


figure;
set(gcf,'Name', tmptxt);
% plot image
axes('pos',[0.1300    0.1100    0.6879    0.8150]);
set(gca,'FontName','Comic Sans MS');

tmpx = [1:size(FUSED_RGB,1)] * roiTs{1}.ds(1);
tmpy = [1:size(FUSED_RGB,2)] * roiTs{1}.ds(2);
image(tmpx,tmpy,permute(FUSED_RGB,[2 1 3]));
xlabel('X in mm');  ylabel('Y in mm');
title(tmptxt,'FontName','Comic Sans MS','FontWeight','bold');
set(gca,'ylim',[min(tmpy) 22]);

% plot a color bar
axes('pos',[0.8286    0.1100    0.0595    0.8150]);
set(gca,'FontName','Comic Sans MS','FontSize',8);
tmpimg = cmapF;
tmpx   = 0;
tmpy   = [0:255]/255 * (maxv - minv) + minv;
image(tmpx,tmpy,[1:256]');
colormap(cmapF);
title('R value');
set(gca,'xticklabel',[],'xtick',[],...
		'YaxisLocation','right','Ydir','normal');


return;


