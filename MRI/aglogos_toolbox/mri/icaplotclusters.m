function icaplotclusters(ICA, icomp)
%ICAPLOTCLUSTERS - Plots all IC ROIs and Time Courses for checking for interesting components
% ICAPLOTCLUSTERS(SESSION,GRPNAME) run this function first to see the ICs and their ROIs
%
% ICA structure:
%         ana: [72x72x12 double]
%          ds: [0.7500 0.7500 2]
%      slices: [4 5 6 7 8 9]
%         map: [20x2575 double]
%      colors: {1x34 cell}
%     anapica: [1x1 struct]
%       mview: [1x1 struct]
%         raw: [1x1 struct]
%          ic: [1x1 struct]
% ICA.raw
%     session: 'h05tm1'
%     grpname: 'visesmix'
%       ExpNo: [1x40 double]
%      coords: [2575x3 double]
%       icomp: [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]
%         dat: [120x20 double]
%         err: [120x20 double]
%          dx: 2
%         stm: [1x1 struct]
% ICA.ic
%     session: 'h05tm1'
%     grpname: 'visesmix'
%       ExpNo: [1x40 double]
%         dat: [120x20 double]
%          dx: 2
%         stm: [1x1 struct]
%
% NKL 09.06.09
%
% See also GETICA ICALOAD ICAPLOTIC2D ICAPLOTTS SHOWICA

if nargin < 1,  help icaplotclusters;  return; end;

COLORS = ICA.colors;

ANA = anaload(ICA.ic.session, ICA.ic.grpname);
if isempty(ICA.slices),
  ICA.slices = [1:size(ANA.dat,3)];
end;

ANA.dat = ANA.dat(:,:,ICA.slices);
ICA.ana = ICA.ana(:,:,ICA.slices);

K=1;
for S=1:length(ICA.slices),
  for N=1:size(ICA.raw.coords,1),
    if ICA.raw.coords(N,3) == ICA.slices(S),
      tmp(K,:) = ICA.raw.coords(N,:);
      tmp(K,3) = S;
      IDX(K) = N;
      K=K+1;
    end;
  end;
end;
ICA.raw.coords = tmp;
ICA.map = ICA.map(:,IDX);

ANA.ds(3) = ICA.ds(3);
tmpana   = double(ANA.dat);
anaminv  = 0;
anamaxv  = 0;

if ~isempty(ICA.mview.anascale),
  if length(ICA.mview.anascale) == 1,
    anamaxv = ICA.mview.anascale(1);
  else
    anaminv = ICA.mview.anascale(1);
    anamaxv = ICA.mview.anascale(2);
    anagamma = ICA.mview.anascale(3);
  end
end

if anamaxv == 0,  anamaxv = round(mean(tmpana(:))*3.5);  end
ANA.rgb = subScaleAnatomy(ANA.dat,anaminv,anamaxv,anagamma);
ANA.scale = [anaminv anamaxv anagamma];
ANA.episcale = size(ANA.dat)./size(ICA.ana);
if length(ANA.episcale) < 3,  ANA.episcale(3) = 1;  end
clear tmpana anaminv anamaxv anagamma anacmap;

COORDS      = ICA.raw.coords;
IMGSIZE     = size(ICA.ana);
if length(IMGSIZE) == 2,
  IMGSIZE = [IMGSIZE 1];
end;


% construct real images ([x,y,z,n])
icamap = NaN([IMGSIZE, size(ICA.map,1)]);

for N = 1:size(ICA.map,2),
  for K = 1:size(ICA.map,1),
    icamap(COORDS(N,1),COORDS(N,2),COORDS(N,3),K) = ICA.map(K,N);  
  end;
end;
nslices = IMGSIZE(3);

if nslices <= 2,
  NRow = 2;  NCol = 1;  %  2 images in a page
elseif nslices <= 4,
  NRow = 2;  NCol = 2;  %  4 images in a page
elseif nslices <= 6,
  NRow = 3;  NCol = 2;  %  6 images in a page
elseif nslices <= 9
  NRow = 3;  NCol = 3;  %  9 images in a page
elseif nslices <= 12
  NRow = 4;  NCol = 3;  % 12 images in a page
elseif nslices <= 16
  NRow = 4;  NCol = 4;  % 16 images in a page
else
  NRow = 5;  NCol = 4;  % 20 images in a page
end

nX = size(ANA.dat,1);
nY = size(ANA.dat,2);
X  = 0:nX-1;
Y  = nY-1:-1:0;

rname = sprintf('%s ', ICA.anapica.roinames{:});
tmptitle = sprintf('%s(%s),Thr=%d, %s',upper(ICA.ic.session),ICA.ic.grpname,...
                   ICA.DISP_THRESHOLD,rname);
set(gcf,'Name',sprintf('%s: %s',mfilename,tmptitle));

% PLOT MAPS
if nargin < 2,
  icomp = [1:size(ICA.ic.dat,2)];
end;

for N = 1:size(ANA.rgb,3),
  tmpimg = squeeze(ANA.rgb(:,:,N,:));
    
  iCol = floor((N-1)/NCol)+1;
  iRow = mod((N-1),NCol)+1;
  offsX = nX*(iRow-1);
  offsY = nY*NRow - iCol*nY;
  tmpx = X + offsX;
  tmpy = Y + offsY;
  image(tmpx,tmpy,permute(tmpimg,[2 1 3]));  hold on;

  for IC = 1:length(icomp),
    C = icomp(IC);
    tmpcol = COLORS{C};
    tmps   = squeeze(icamap(:,:,N,C));
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
      plot(xc(sel)-(C-1)/4,yc(sel)-(C-1)/4,'marker','s','markersize',3,...
           'markerfacecolor',tmpcol,'markeredgecolor',edgecol,'linestyle','none');
    end
    
    % plot negative
    sel  = find(selv(:) < 0);
    edgecol = 'k';
    if ~isempty(sel),
      plot(xc(sel)-(C-1)/4,yc(sel)-(C-1)/4,'marker','s','markersize',3,...
           'markerfacecolor',tmpcol,'markeredgecolor',edgecol,'linestyle','none');
    end
  end;
    
  text(min(tmpx)+1,max(tmpy),sprintf('Slice=%d',ICA.slices(N)),...
       'color','c','VerticalAlignment','top',...
       'FontName','Calibri','FontSize',9,'Fontweight','normal');
end
set(gca,'xlim',[0 nX*NCol-0.5],'ylim',[0 nY*NRow-0.5],'Ydir','normal',...
        'YTickLabel',{},'YTick',[],'XTickLabel',{},'XTick',[],'Ydir','normal');


title(tmptitle,'fontweight','bold');
axis off
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to scale anatomy image
function ANARGB = subScaleAnatomy(ANA,MINV,MAXV,GAMMA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isstruct(ANA),
  tmpana = double(ANA.dat);
else
  tmpana = double(ANA);
end
clear ANA;
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
