function plot_tkcca(RES,varargin)
%PLOT_TKCCA - Plot tkCCA result
%  PLOT_TKCCA(RES,...) plots tkCCA results.
%
%  NOTE :
%    Lags by exptkcca/exptcor are flipped for easy comparison with HRF.
%
%  EXAMPLE :
%    res = exptkcca('b06sc1',1);
%    plot_cca(res)
% 
%  VERSION : 
%    0.90 20.04.09 YM  pre-release
% 
%  See also exptkcca

if nargin < 1,  eval(sprintf('help %s',mfilename)); return;  end

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

anap = getanap(RES.session);
RES.fmri.thr = anap.tkcca.thr;

for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'thr','threshold'}
    RES.fmri.thr = varargin{N+1};
  end
end;

ANA = anaload(RES.session,RES.grpname);
s = size(RES.fmri.ana);
for N=1:size(ANA.dat,3),
  dat(:,:,N) = imresize(ANA.dat(:,:,N),s(1:2));
end;
RES.fmri.ana = dat;

RES.fmri.weights = nanmean(RES.fmri.weights,2);
for N = 1:length(RES.ephys),
  RES.ephys(N).weights = nanmean(RES.ephys(N).weights,3);
  RES.ephys(N).xcorr   = nanmean(RES.ephys(N).xcorr,  2);
end


if strcmpi(RES.opts.algorithm,'corrcoef'),
  algorithm = 'COR';
else
  algorithm = 'CCA';
end

mfigure([10 400 700 500]);
if isfield(RES,'session') && ischar(RES.session) && ~isempty(RES.session),
  set(gcf,'Name',sprintf('%s-mri %s %s (nexp=%d)',algorithm,RES.session,RES.grpname,length(RES.exps)));
else
  set(gcf,'Name','%s-mri',algorithm);
end
axes;
subPlotMRI(RES.fmri,OPTS);

mfigure([730 400 700 500]);
if isfield(RES,'session') && ischar(RES.session) && ~isempty(RES.session),
  set(gcf,'Name',sprintf('%s-neu %s %s (nexp=%d)',algorithm,RES.session,RES.grpname,length(RES.exps)));
else
  set(gcf,'Name','%s-neu',algorithm);
end
subPlotNEU(RES.ephys,RES.opts.algorithm,OPTS);
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subPlotMRI(RES, OPTS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
GAMMA_VAL = 1;

ANARGB = subScaleAnatomy(RES.ana, 0, max(RES.ana(:))*0.8, GAMMA_VAL);
STATMAP = NaN(size(RES.ana));
tmpvox = sub2ind(size(RES.ana),RES.coords(:,1),RES.coords(:,2),RES.coords(:,3));
STATMAP(tmpvox) = RES.weights(:);

[NRow NCol] = subGetNRowNCol(size(RES.ana),RES.ds);

nX = size(RES.ana,1);  X = [0:size(RES.ana,1)-1];
nY = size(RES.ana,2);  Y = [0:size(RES.ana,2)-1];  Y = fliplr(Y);

if 1
% do zscore normalization
tmpstat = (STATMAP-nanmean(STATMAP(:)))/nanstd(STATMAP(:));
%idx = find(tmpstat<1);
%tmpstat(idx) = NaN;
STATMAP = tmpstat;
end

STATMAP = abs(STATMAP);

MAXV = max(STATMAP(:))*0.8;
% MAXV = 5;
% MINV = -MAXV;
MINV = 0;
THR_W = RES.thr;

% CMAP = jet(256);
CMAP = hot(256);
H_AXES = gca;
for N = 1:size(STATMAP,3),
  tmpana = squeeze(ANARGB(:,:,N,:));
  tmps   = squeeze(STATMAP(:,:,N));
  tmpp   = ones(size(tmps));
  if any(THR_W),
    tmpp(find(abs(tmps(:)) > THR_W)) = 0;
  else

    tmpxyz = RES.coords(RES.coords(:,3)==N,:);
    tmpvox = sub2ind(size(tmpp),tmpxyz(:,1),tmpxyz(:,2));
    tmpp(tmpvox) = 0;
  end
  tmpimg = subFuseImage(tmpana,tmps,MINV,MAXV,tmpp,0.1,CMAP);
  
  iCol = floor((N-1)/NCol)+1;
  iRow = mod((N-1),NCol)+1;
  offsX = nX*(iRow-1);
  offsY = nY*NRow - iCol*nY;

  tmpx = X + offsX;
  tmpy = Y + offsY;
  
  tmpimg = permute(tmpimg,[2 1 3]);
  image(tmpx,tmpy,tmpimg);  hold on;
  text(min(tmpx)+1,max(tmpy),sprintf('slice=%d',N),...
       'color',[0.9 0.9 0.5],'VerticalAlignment','top',...
       'FontSize',8,'Fontweight','bold');
  
end
set(gca,'color','black');
set(gca,'XTickLabel',{},'YTickLabel',{},'XTick',[],'YTick',[]);
set(gca,'Ydir','normal','xlim',[0 nX*NCol],'ylim',[0 nY*NRow]);
title('fMRI Weights');

subDrawColorBar(H_AXES,MINV,MAXV,CMAP,'weight','',THR_W);
axes(H_AXES);  % focus out the colorbar
return

function subPlotNEU(RES,method,OPTS)
maxv = zeros(1,length(RES));
for N = 1:length(RES),
  maxv = max(abs(RES(N).weights(:)));
end
maxv = max(maxv);

for N = 1:length(RES),
  subplot(length(RES),2,2*N-1);
  tlag = RES(N).lags*RES(N).dx;
  
  tlag = -tlag;  % match with HRF
  
  tmpy = 1:size(RES(N).weights,1);
  imagesc(tlag,tmpy,RES(N).weights);
  
  if any(strcmpi(method,{'cor','corrcoef','cov'})),
    set(gca,'clim',[-1 1]);
  else
    %set(gca,'clim',[-35 35]);
    set(gca,'clim',[-maxv maxv]*0.85);
  end
  
  if strcmpi(RES(1).dimname{2},'chan'),
    yticklabel = {};
    for K = 1:length(RES(N).band),
      yticklabel{K} = RES(N).band{K}{2};
    end
    set(gca,'color','black');
    set(gca,'YTickLabel',yticklabel,'YTick',tmpy);
    set(gca,'Ydir','normal','xlim',sort([tlag(1) tlag(end)]));
    title(sprintf('Ch%02d Weights',N));
    
    subplot(length(RES),2,2*N);
    mn = nanmean((RES(N).xcorr(:)));
    mx = max(abs(RES(N).xcorr(:))-mn)*1.5;
    plot(tlag,RES(N).xcorr);
    grid on;
    set(gca,'xlim',sort([tlag(1) tlag(end)]),'ylim',[-mx+mn mx+mn]);
    xlabel('Lags in seconds (neuro to BOLD)');
    ylabel('CC');
    title(sprintf('Ch%02d [%s]',N, OPTS.elename{N}));
    
  elseif strcmpi(RES(1).dimname{2},'band'),
    yticklabel = {};
    for K = 1:size(RES(N).weights,1),
      yticklabel{K} = sprintf('Ch%02d',K);
    end
    set(gca,'color','black');
    set(gca,'YTickLabel',yticklabel,'YTick',tmpy);
    set(gca,'Ydir','normal','xlim',sort([tlag(1) tlag(end)]));
    title(sprintf('Band-Weights: %s',RES(1).band{N}{2}));
    
    subplot(length(RES),2,2*N);
    mn = nanmean((RES(N).xcorr(:)));
    mx = max(abs(RES(N).xcorr(:))-mn)*1.2;
    plot(tlag,RES(N).xcorr);
    grid on;
    set(gca,'xlim',sort([tlag(1) tlag(end)]),'ylim',[-mx+mn mx+mn]);
    xlabel('Lags in seconds (neuro to BOLD)');
    ylabel('CC');
    title(sprintf('Band-XC: %s',RES(1).band{N}{2}));
  end
  
end
  
  
return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to get NRow/NCol
function [NRow NCol] = subGetNRowNCol(IMGDIM,PIXDIM)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xfov = IMGDIM(1)*PIXDIM(1);
yfov = IMGDIM(2)*PIXDIM(2);
nslices = IMGDIM(3);


NRow = ceil(sqrt(nslices*xfov/yfov));
NCol = round(nslices/NRow);

if NCol*NRow < nslices,
  if xfov > yfov,
    NRow = NRow + 1;
  else
    NCol = NCol + 1;
  end
end
return


if nslices <= 2,
  NRow = 2;  NCol = 1;  %  2 images in a page
elseif nslices <= 4,
  NRow = 2;  NCol = 2;  %  4 images in a page
elseif nslices <= 9
  NRow = 3;  NCol = 3;  %  9 images in a page
elseif nslices <= 12
  NRow = 4;  NCol = 3;  % 12 images in a page
elseif nslices <= 16
  NRow = 4;  NCol = 4;  % 16 images in a page
else
  NRow = 5;  NCol = 4;  % 20 images in a page
end

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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to fuse anatomy and functional images
function IMG = subFuseImage(ANARGB,STATV,MINV,MAXV,PVAL,ALPHA,CMAP)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ndims(ANARGB) == 2,
  % image is just a vector, squeezed, so make it 2D image with RGB
  ANARGB = permute(ANARGB,[1 3 2]);
end

IMG = ANARGB;
if isempty(STATV) | isempty(PVAL) | isempty(ALPHA),  return;  end

PVAL(find(isnan(PVAL(:)))) = 1;  % to avoid error;

imsz = [size(ANARGB,1) size(ANARGB,2)];
if any(imsz ~= size(STATV)),
  if datenum(version('-date')) >= datenum('January 29, 2007'),
    STATV = imresize_old(STATV,imsz,'nearest',0);
    PVAL  = imresize_old(PVAL, imsz,'nearest',0);
    %STATV = imresize_old(STATV,imsz,'bilinear',0);
    %PVAL  = imresize_old(PVAL, imsz,'bilinear',0);
  else
    STATV = imresize(STATV,imsz,'nearest',0);
    PVAL  = imresize(PVAL, imsz,'nearest',0);
    %STATV = imresize(STATV,imsz,'bilinear',0);
    %PVAL  = imresize(PVAL, imsz,'bilinear',0);
  end
end


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
  %fprintf('\nsize(IMG)=  '); fprintf('%d ',size(IMG));
  %fprintf('\nsize(STATV)='); fprintf('%d ',size(STATV));
  IMG(idx) = STATV(idx);
end


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to draw a color bar
function hnew = subDrawColorBar(PARENT_AXS,MINV,MAXV,CMAP,DATNAME,TITLESTR,THR_W)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TAGNAME = sprintf('%s-colorbar',mfilename);

h = findobj(gcf,'tag',TAGNAME);

pos = get(PARENT_AXS,'pos');
if isempty(h),
  pos(3) = pos(3) * 0.87;
  set(PARENT_AXS,'pos',pos);
end
posX = pos(1)+pos(3)+0.05;
posW = 0.05;
hnew = axes('pos',[posX pos(2) posW pos(4)]);

n = size(CMAP,1)-1;

if isempty(MAXV) | isempty(MINV),
  fprintf('subDrawColorBar: MAXV/MINV empty matrices\n');
  return;
end;

ydat = [0:n]/n * (MAXV - MINV) + MINV;
%imagesc(1,ydat,[0:n]');
%colormap(CMAP);
image(1,ydat,ind2rgb([1:size(CMAP,1)]',CMAP));
if MINV < MAXV & ~isnan(MINV) & ~isnan(MAXV),
set(hnew,'ylim',[MINV MAXV],'YAxisLocation','right' ,...
      'XTickLabel',{},'XTick',[],'Ydir','normal','tag',TAGNAME,'UserData',TITLESTR);
end;

if exist('THR_W','var') & ~isempty(THR_W),
  hold on;
  line(get(gca,'xlim'), [THR_W THR_W],'color','k');
  line(get(gca,'xlim'),-[THR_W THR_W],'color','k');
end

ylabel(DATNAME);
if ~isempty(TITLESTR),  title(TITLESTR);  end

% modify position/size of colorbars
h = findobj(gcf,'tag',TAGNAME);
if length(h) > 1,
  tmpw = posW*2/length(h);
  tmpy = pos(2);  tmph = pos(4);
  h = sort(h);
  oldylm = NaN;
  for N = 1:length(h),
    % update size/position
    tmpx = (posX+posW) - (N-1)*tmpw;
    set(h(N),'pos',[tmpx tmpy tmpw*0.5 tmph]);
    % update title/ylabel
    tmptxt = get(get(h(N),'ylabel'),'String');
    tmpleg = get(h(N),'UserData');
    if ~isempty(tmpleg),
      title(h(N),tmpleg);
      if N ~= 1,  ylabel(h(N),'');  end
      %if N ~= length(h),  ylabel(h(N),'');  end
      %set(h(N),'YAxisLocation','left');
    else
      if ~isempty(tmptxt),
        ylabel(h(N),'');  title(h(N),tmptxt);
      end
    end
    % hide/show YTick
    tmpylm = get(h(N),'ylim');
    if all(tmpylm == oldylm),
      set(h(N),'YTickLabel',{});
    else
      oldylm = tmpylm;
    end
  end
end
return
