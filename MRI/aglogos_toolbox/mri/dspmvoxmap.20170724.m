function varargout = dspmvoxmap(ROITS,varargin)
%DSPMVOXMAP - displays image maps of ROITS structure by mvoxselect
%  DSPMVOXMAP(ROITS,...) displays image maps of ROITS structure of that voxsels are 
%  selected by mvoxselect based on the certain statistics/alpha.
%  HAXES = DSPMVOXMAP(ROITS,...) does the same things, returing the axes handle.
%
%  Supported options are :
%    axes      : the axes handle to plot.
%    DatName   : data name to plot, 'statv','resp', 'beta'
%    Colormap  : a color map for activated voxsels
%    Clip      : clipping range as [min max]
%    colorbar  : a flag to draw a colorbar, 0 or 1
%    DrawROI   : a flag to draw ROIs, 0 or 1, can be a cell array of RoiNames
%    DrawELE   : a flag to draw electrodes, 0 or 1.
%    ROIColor  : a cell array of colors for ROIs
%    Slice     : slice selection
%    NRowNCol  : [NRow NCol] for display
%    Gamma     : Gamma correction for color coding
%    AnaGamma  : Gamma correction for anatomy
%    AnaScale  : scale factors for anatomy, [min max gamma]
%    AnaOnly   : draws only anatomy data, no functional map
%    Legend    : text string(s) for legend
%    SliceText : prints slice numbers or not, 0 or 1.
%
%  EXAMPLE :
%    >> sig = mvoxselect('e04ds1','visesmix','all','glm[2]',[],0.01);
%    >> dspmvoxmap(sig,'clip',[0 20],'colormap',hot(256))
%  EXAMPLE 2:
%    >> sig1 = mvoxselect('e04ds1','visesmix','v1','glm[1]',[],0.01);
%    >> h = dspmvoxmap(sig1,'clip',[0 20],'colormap','red')
%    >> sig2 = mvoxselect('e04ds1','visesmix','v2','glm[1]',[],0.01);
%    >> h = dspmvoxmap(sig2,'clip',[0 20],'colormap','green','axes',h)
%  EXAMPLE 3:
%    >> dspmvoxmap({sig1 sig2},'color',{'r','g'},'legend',{'v1','v2'})
%
%  VERSION :
%    0.90 12.03.07 YM  pre-release
%    0.91 14.03.07 YM  supports new options 'NRowNCol', 'DrawROI'.
%    0.92 15.03.07 YM  supports 'hold on' capability, ROITS as a cell array.
%    0.93 19.03.07 YM  'DrawROI' can be a cell array of RoiNames
%    0.94 14.11.07 YM  supports 'DrawELE'
%    0.95 28.04.08 YM  use imgresize_old() instead of imresize() for Matlab 2007b.
%    0.96 26.08.09 YM  supports AnaScale, AnaOnly.
%    0.97 07.10.11 YM  supports ROITS{}.epiana.
%    0.98 18.07.12 YM  supports .stat.fdq_q.
%    0.99 28.01.14 YM  supports 'beta' as 'DatName'.
%    1.00 21.07.17 YM  supports anatomy data as a option, 'ana'.
%
%  See also mvoxselect mvoxselectmask dspmvox dspmvoxtc anaload mview

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end

% CONTROL FLAGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H_AXES    =  [];
DATNAME   = 'statv';
CLIP_V    =  [];
NRowNCol  =  [];
DRAW_ROI  =   0;
DRAW_ELE  =   0;
ROICOLORS = {'r','g','b','c','m','y','k'};
CMAP      =  [];
GAMMAV    =  [];
ANAGAMMAV =  [];
ANASCALE  =  [];
LEGTXT    =  '';
SELSLICE  =  [];
COLORBARF =   0;
SLICETEXT =   1;
ANA       =  [];
PLOT_FUNCMAP = 1;
TITLE = [];

% parse inputs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for N=1:2:length(varargin),
  switch lower(varargin{N}),
   case {'title'}
    TITLE = varargin{N+1};
   case {'colorbar'}
    COLORBARF = varargin{N+1};
   case {'slice' 'slices'}
    SELSLICE = varargin{N+1};
   case {'clip'}
    CLIP_V = varargin{N+1};
   case {'datname','data','dataname'}
    DATNAME = varargin{N+1};
   case {'cmap','colormap'}
    CMAP = varargin{N+1};
   case {'nrowncol','nrowsncols','nrowcol'}
    NRowNCol = varargin{N+1};
   case {'drawroi','drawrois','roinames','roidraw'}
    DRAW_ROI = varargin{N+1};
   case {'drawele','eledraw','draweles'}
    DRAW_ELE = varargin{N+1};
   case {'roicolor','roicolors','color','colors'}
    ROICOLORS = varargin{N+1};
   case {'axes'}
    H_AXES = varargin{N+1};
   case {'gamma'}
    GAMMAV = varargin{N+1};
   case {'anagamma','gammaana'}
    ANAGAMMAV = varargin{N+1};
   case {'anascale'}
    ANASCALE  = varargin{N+1};
   case {'legend'}
    LEGTXT = varargin{N+1};
   case {'slicetext','textslice'}
    SLICETEXT = varargin{N+1};
   case {'anatomy' 'ana'}
    ANA = varargin{N+1};
   case {'anaonly','anatomyonly','onlyana','onlyanatomy'}
    PLOT_FUNCMAP = ~any(varargin{N+1});
   case {'plotfunc','plotfuncmap','funcmap'}
    PLOT_FUNCMAP = varargin{N+1};
  end
end


% If ROITS is a cell array, do for-loop then return
if iscell(ROITS) && length(ROITS) > 1,
  if isempty(CMAP), CMAP = {'r','g','b','c','m','y'};  end
  for N = 1:length(ROITS),
    if isempty(CLIP_V),
      tmpclip = [];
    elseif iscell(CLIP_V),
      tmpclip = CLIP_V{N};
    else
      if isvector(CLIP_V),
        tmpclip = CLIP_V;
      elseif size(CLIP_V,1) >= 2,
        tmpclip = CLIP_V(N,:);
      else
        tmpclip = CLIP_V(:,N);
      end
    end
    if iscell(DATNAME),
      tmpdatname = DATNAME{N};
    else
      tmpdatname = DATNAME;
    end
    if size(CMAP,3) > 1,
      tmpcmap = squeeze(CMAP(:,:,mod(N-1,size(CMAP,3))+1));
    elseif iscell(CMAP),
      tmpcmap = CMAP{mod(N-1,length(CMAP))+1};
    else
      tmpcmap = CMAP;
    end
    if length(GAMMAV) > 1,
      tmpgamma = GAMMAV(N);
    else
      tmpgamma = GAMMAV;
    end
    if iscell(LEGTXT),
      tmplegtxt = LEGTXT{N};
    else
      tmplegtxt = {};
    end
    if N == 1, 
      tmproi = DRAW_ROI;
      tmpele = DRAW_ELE;
      tmproic = ROICOLORS;
    else
      tmproi = 0;
      tmpele = 0;
      tmproic = [];
    end

    H_AXES = dspmvoxmap(ROITS{N},'Clip',tmpclip,'DatName',tmpdatname,...
                        'ColorMap',tmpcmap,'ColorBar',COLORBARF,...
                        'Gamma',tmpgamma,'AnaGamma',ANAGAMMAV,'legend',tmplegtxt,...
                        'DrawROI',tmproi,'RoiColors',tmproic,'DrawEle',tmpele,...
                        'NRowNCol',NRowNCol,'axes',H_AXES,'slice',SELSLICE,'anatomy',ANA);
  end
  if nargout,
    varargout{1} = H_AXES;
  end
  return
elseif iscell(ROITS) && length(ROITS) == 1,
  ROITS = ROITS{1};
end

if strcmpi(DATNAME,'beta')
  if ~isfield(ROITS.stat,'beta')
    error(' ERROR %s: the given dataset has no .stat.beta.\n',mfilename);
  end
end

if isempty(CLIP_V),
  switch lower(DATNAME),
   case {'statv','stat'}
    tmpmax = max(ROITS.stat.dat(:));
    if tmpmax > 10,
      MAP_MAXV = round(max(ROITS.stat.dat(:))/10)*10;
    elseif tmpmax > 0,
      MAP_MAXV = tmpmax;
    else
      MAP_MAXV = 1;
    end
    MAP_MINV = 0;
   case {'beta' 'glmbeta' 'glm_beta'}
    MAP_MAXV = max(abs(ROITS.stat.beta(:)));
    MAP_MINV = -MAP_MAXV;
   case {'resp','mean','meanresp','response'}
    MAP_MAXV = abs(max(ROITS.resp.mean(:)));
    MAP_MINV = -MAP_MAXV;
   case {'min','minresp','minresponse'}
    MAP_MAXV = abs(max(ROITS.resp.min(:)));
    MAP_MINV = -MAP_MAXV;
   case {'max','maxresp','maxresponse'}
    MAP_MAXV = abs(max(ROITS.resp.max(:)));
    MAP_MINV = -MAP_MAXV;
   otherwise
    if isfield(ROITS,DATNAME),
      if isstruct(ROITS.(DATNAME)),
        MAP_MAXV = abs(max(ROITS.(DATNAME).dat(:)));
        MAP_MINV = -MAP_MAXV;
      elseif isvector(ROITS.(DATNAME)),
        MAP_MAXV = abs(max(ROITS.(DATNAME)(:)));
        MAP_MINV = -MAP_MAXV;
      end
    end
  end
else
  MAP_MINV = CLIP_V(1);
  MAP_MAXV = CLIP_V(2);
end
if isempty(CMAP),  CMAP = jet(256);  end
if ischar(CMAP),   CMAP = subGetColormap(CMAP);  end
if isempty(GAMMAV), GAMMAV = 1.0;  end
CMAP = CMAP.^(1/GAMMAV);

% ROICOLORS must be a cell array
if isnumeric(ROICOLORS),
  % ROICOLORS as (N,3)
  ROICOLORS = num2cell(ROICOLORS,2);
elseif ischar(ROICOLORS),
  tmpc = {};
  for N = 1:length(ROICOLORS),
    tmpc{N} = ROICOLORS(N);
  end
  ROICOLORS = tmpc;
  clear tmpc;
end


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(ROITS.session),
  Ses = goto(ROITS.session);
  grp = getgrp(Ses,ROITS.grpname);
  ANAP = getanap(Ses,grp);
else
  ANAP = [];
end
if isfield(ROITS,'epiana') && any(ROITS.epiana),
  ANA.dat = ROITS.ana;
  ANA.ds  = ROITS.ds;
else
  if isempty(ANA),
    ANA = anaload(Ses,grp);
  end
end
if isequal(DRAW_ROI,1),
  DRAW_ROI = { 'all' };
elseif isequal(DRAW_ROI,0) || isempty(DRAW_ROI),
  DRAW_ROI = {};
elseif ischar (DRAW_ROI),
  DRAW_ROI = { DRAW_ROI };
end
if ~isempty(DRAW_ROI) || DRAW_ELE > 0,
  ROI = load('Roi.mat',grp.grproi);  ROI = ROI.(grp.grproi);
  %ROI.pxscale = size(ANA.dat,1)size(ROITS.ana,1)
  %ROI.pyscale = size(ANA.dat,2)size(ROITS.ana,2)
  ROI.pxscale = size(ROITS.ana,1) / size(ANA.dat,1);
  ROI.pyscale = size(ROITS.ana,2) / size(ANA.dat,2);
end


% converts ANA.dat into RGB
tmpana   = double(ANA.dat);
anaminv  = 0;
anamaxv  = 0;
if ~isempty(ANASCALE),
  anaminv = ANASCALE(1);
  anamaxv = ANASCALE(2);
  if length(ANASCALE) > 2 && isempty(ANAGAMMAV),
    ANAGAMMAV = ANASCALE(3);
  end
elseif ~isempty(ANAP),
  if ~isempty(ANAP.mview.anascale),
    if length(ANAP.mview.anascale) == 1,
      anamaxv = ANAP.mview.anascale(1);
    else
      anaminv = ANAP.mview.anascale(1);
      anamaxv = ANAP.mview.anascale(2);
      if length(ANAP.mview.anascale) > 2,
        ANAGAMMAV = ANAP.mview.anascale(3);
      end
    end
  end
end
if isempty(ANAGAMMAV),  ANAGAMMAV = 1.8;  end
if anamaxv == 0,  anamaxv = round(mean(tmpana(:))*3.5);  end
ANA.rgb = subScaleAnatomy(ANA.dat,anaminv,anamaxv,ANAGAMMAV);
ANA.scale = [anaminv anamaxv ANAGAMMAV];
ANA.episcale = size(ANA.dat)./size(ROITS.ana);
if length(ANA.episcale) < 3,  ANA.episcale(3) = 1;  end
clear tmpana anaminv anamaxv anacmap;

if isempty(TITLE),
  if ischar(ROITS.session),
    tmptitle = sprintf('%s(%s) ROI:%s model:%s P<%g',Ses.name,grp.name,...
                       ROITS.name,ROITS.stat.model,ROITS.stat.alpha);
  else
    tmptitle = sprintf('NSes=%d ROI:%s model:%s P<%g',length(ROITS.session),...
                       ROITS.name,ROITS.stat.model,ROITS.stat.alpha);
  end
  if isfield(ROITS.stat,'fdr_q') && any(ROITS.stat.fdr_q),
    tmptitle = sprintf('%s (P0=%g/FDRq=%g)',tmptitle,ROITS.stat.uncorrected_alpha,ROITS.stat.fdr_q);
  end
else
  tmptitle = TITLE;
end;

if isempty(H_AXES) || ~ishandle(H_AXES),
  figure('Name',sprintf('%s: %s',mfilename,tmptitle));
  set(gcf,'DefaultAxesfontsize',	10);
  set(gcf,'DefaultAxesfontweight','bold');
  set(gcf,'DefaultAxesFontName', 'Comic Sans MS');
  % check the position of the figure, due to Matlab's bug,
  % sometimes the figure appears outside the monitor....
  pos = get(gcf,'pos');
  if abs(pos(1)) > 5000 || abs(pos(2)) > 5000,
    set(gcf,'pos',[100 100 pos(3) pos(4)]);
  end
  %axes('pos',[0.1300    0.30    0.7750    0.620]);
  H_AXES = axes;
else
  axes(H_AXES);
end


if ~isempty(SELSLICE),
  nslices = length(SELSLICE);
else
  nslices = size(ANA.dat,3);
  SELSLICE = 1:nslices;
end;


% determine how many rows/colums 
if isempty(NRowNCol),
  tmpsz = size(ANA.dat);
  tmpsz(3) = nslices;
  [NRow NCol] = subGetNRowNCol(tmpsz,ANA.ds);
else
  NRow = NRowNCol(1);  NCol = NRowNCol(2);
end


nX = size(ANA.dat,1);
nY = size(ANA.dat,2);
X  = 0:nX-1;
Y  = nY-1:-1:0;

% PLOT MAPS
fimgsize = size(ROITS.ana);
for N = 1:nslices,
  SliceNo = SELSLICE(N);
  
  [tmps tmpp] = subGetFImage(ROITS,SliceNo,DATNAME);
  
  imgtag = sprintf('slice=%d',SliceNo);
  h = findobj(H_AXES,'tag',imgtag);
  
  iCol = floor((N-1)/NCol)+1;
  iRow = mod((N-1),NCol)+1;
  offsX = nX*(iRow-1);
  offsY = nY*NRow - iCol*nY;
  if isempty(h),
    % NEW PLOT
    tmpimg = squeeze(ANA.rgb(:,:,SliceNo,:));
    if PLOT_FUNCMAP,
      [tmpimg tmpmap] = subFuseImage(tmpimg,tmps,MAP_MINV,MAP_MAXV,tmpp,1,CMAP,[]);
    else
      tmpmap = [];
    end
    tmpx = X + offsX;
    tmpy = Y + offsY;
    image(tmpx,tmpy,permute(tmpimg,[2 1 3]),'tag',imgtag,'UserData',tmpmap);
    hold on;
    if SLICETEXT > 0,
      text(min(tmpx)+1,max(tmpy),sprintf('slice=%d',SliceNo),...
           'color',[0.9 0.9 0.5],'VerticalAlignment','top',...
           'FontName','Comic Sans MS','FontSize',8,'Fontweight','bold');
    end
    hold on;
  else
    % ADD IMAGE
    tmpimg = permute(get(h,'cdata'),[2 1 3]);
    tmpmap = get(h,'UserData');
    if PLOT_FUNCMAP,
      tmpimg = subFuseImage(tmpimg,tmps,MAP_MINV,MAP_MAXV,tmpp,1,CMAP,tmpmap);
    end
    set(h,'cdata',permute(tmpimg,[2 1 3]));
  end
  if ~isempty(DRAW_ROI),
    % draw ROI/ele
    subDrawROIs(gca,ROI,N,DRAW_ROI,ROICOLORS,offsX,offsY+nY,1);
  elseif DRAW_ELE,
    % draw ele only
    subDrawELEs(gca,ROI,N,ROI,ROICOLORS,offsX,offsY+nY,1);
  end
  
end
set(gca,'xlim',[0 nX*NCol-0.5],'ylim',[0 nY*NRow-0.5],'Ydir','normal',...
        'YTickLabel',{},'YTick',[],'XTickLabel',{},'XTick',[],'Ydir','normal');
set(gca,'color',[0 0 0],'UserData',mfilename);
title(strrep(tmptitle,'_','\_'));
%daspect(gca,[ANA.ds(1)/ANA.ds(2) 1 2]);
daspect(gca,[ANA.ds(2)/ANA.ds(1) 1 2]);
if COLORBARF,
  subDrawColorBar(gca,MAP_MINV,MAP_MAXV,CMAP,DATNAME,LEGTXT);
  axes(H_AXES);  % focus out the colorbar
end
if nargout,
  varargout{1} = H_AXES;
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
tmpana(tmpana(:) <   0) =   1;
tmpana(tmpana(:) > 256) = 256;
anacmap = gray(256).^(1/GAMMA);
for N = size(tmpana,3):-1:1,
  ANARGB(:,:,:,N) = ind2rgb(tmpana(:,:,N),anacmap);
end

ANARGB = permute(ANARGB,[1 2 4 3]);  % [x,y,rgb,z] --> [x,y,z,rgb]
return;




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
% SUBFUNCTION to get a functional image
function [SIMG PIMG] = subGetFImage(ROITS,SLICE,STATNAME)
SIMG = zeros(size(ROITS.ana,1),size(ROITS.ana,2));
PIMG = ones(size(SIMG));

tmpsel = find(ROITS.coords(:,3) == SLICE);
if isempty(tmpsel),  return;  end

coords = ROITS.coords(tmpsel,:);
tmpidx = sub2ind(size(SIMG),coords(:,1),coords(:,2));
switch lower(STATNAME),
 case {'statv','stat'}
  SIMG(tmpidx) = ROITS.stat.dat(tmpsel);
 case {'beta' 'glmbeta' 'glm_beta'}
  SIMG(tmpidx) = ROITS.stat.beta(tmpsel);
 case {'resp','mean','meanresp','response'}
  SIMG(tmpidx) = ROITS.resp.mean(tmpsel);
 case {'min','minresp','minresponse'}
  SIMG(tmpidx) = ROITS.resp.min(tmpsel);
 case {'max','maxresp','maxresponse'}
  SIMG(tmpidx) = ROITS.resp.max(tmpsel);
 otherwise
  if isfield(ROITS,STATNAME),
    if isstruct(ROITS.(STATNAME)),
      SIMG(tmpidx) = ROITS.(STATNAME).dat(tmpsel);
    elseif isvector(ROITS.(STATNAME)),
      SIMG(tmpidx) = ROITS.(STATNAME)(tmpsel);
    end
  end
end

PIMG(tmpidx) = ROITS.stat.p(tmpsel);

PIMG(isnan(SIMG(:))) = 1;

return




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to fuse anatomy and functional images
function [IMG MAPIDX] = subFuseImage(ANARGB,STATV,MINV,MAXV,PVAL,ALPHA,CMAP,MAPIDX)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ndims(ANARGB) == 2,
  % image is just a vector, squeezed, so make it 2D image with RGB
  ANARGB = permute(ANARGB,[1 3 2]);
end

IMG = ANARGB;
if isempty(STATV) || isempty(PVAL) || isempty(ALPHA),  return;  end

STATV(isnan(STATV(:))) = 0;  % to avoid error;
PVAL(isnan(PVAL(:))) = 1;  % to avoid error;

imsz = [size(ANARGB,1) size(ANARGB,2)];
if any(imsz ~= size(STATV)),
  if datenum(version('-date')) >= datenum('January 29, 2007'),
    STATV = imresize_old(STATV,imsz,'nearest',0);
    PVAL  = imresize_old(PVAL, imsz,'nearest',0);
  else
    STATV = imresize(STATV,imsz,'nearest',0);
    PVAL  = imresize(PVAL, imsz,'nearest',0);
    %STATV = imresize(STATV,imsz,'bilinear',0);
    %PVAL  = imresize(PVAL, imsz,'bilinear',0);
  end
end

NLevels = size(CMAP,1);

tmpdat = repmat(PVAL,[1 1 3]);   % for rgb
idx = find(tmpdat(:) < ALPHA);
if ~isempty(idx),
  % scale STATV from MINV to MAXV as 0 to 1
  if MAXV~=MINV,
      STATV = (STATV - MINV)/(MAXV - MINV);
  end;
  STATV = round(STATV*(NLevels)) + 1;  % +1 for matlab indexing
  STATV(STATV(:) <   0)     =   1;
  STATV(STATV(:) > NLevels) = NLevels;
  % map 1-NLevels as RGB
  STATV = ind2rgb(STATV,CMAP);
  % replace pixels
  %fprintf('\nsize(IMG)=  '); fprintf('%d ',size(IMG));
  %fprintf('\nsize(STATV)='); fprintf('%d ',size(STATV));

  % for already mapped voxels, add the color
  cidx = intersect(idx,MAPIDX);
  IMG(cidx) = IMG(cidx) + STATV(cidx);
  % for not-yet mapped voxels, set the color
  didx = setdiff(idx,MAPIDX);
  IMG(didx) = STATV(didx);

  % store indices of mapped voxels
  MAPIDX = union(MAPIDX,idx);
  
  % clip to 1, otherwise image() complains...
  IMG(IMG(:) > 1) = 1;
end



return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to draw a color bar
function subDrawColorBar(PARENT_AXS,MINV,MAXV,CMAP,DATNAME,TITLESTR)
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

if isempty(MAXV) || isempty(MINV),
  fprintf('subDrawColorBar: MAXV/MINV empty matrices\n');
  return;
end;

ydat = (0:n)/n * (MAXV - MINV) + MINV;
%imagesc(1,ydat,[0:n]');
%colormap(CMAP);
image(1,ydat,ind2rgb((1:size(CMAP,1))',CMAP));
set(hnew,'YAxisLocation','right' ,...
      'XTickLabel',{},'XTick',[],'Ydir','normal','tag',TAGNAME,'UserData',TITLESTR);
if MINV < MAXV && ~isnan(MINV) && ~isnan(MAXV),
set(hnew,'ylim',[MINV MAXV]);
end;
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot ROIs
function subDrawROIs(haxs,ROI,Slice,RoiName,COLORS,OffsX,OffsY,DO_FLIP)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isempty(ROI),  return;  end

axes(haxs);

for N = 1:length(ROI.roi),
  roiroi = ROI.roi{N};
  if roiroi.slice ~= Slice,  continue;  end
  if strcmpi(RoiName,'all') || any(strcmpi(roiroi.name,RoiName)),
  %if strcmpi(RoiName,'all') | ~isempty(strfind(RoiName,roiroi.name)),
    hold on;
    %anax = roiroi.px / ROI.pxscale + OffsX;
    %anay = roiroi.py / ROI.pyscale + OffsY;
    if DO_FLIP > 0,
      anax =  roiroi.px/ROI.pxscale + OffsX;
      anay = -roiroi.py/ROI.pyscale + OffsY;
    else
      anax =  roiroi.px/ROI.pxscale + OffsX;
      anay =  roiroi.py/ROI.pyscale + OffsY;
    end
    cidx = find(strcmpi(ROI.roinames, roiroi.name));
    if isempty(cidx),  cidx = 1;  end
    cidx = mod(cidx(1),length(COLORS)) + 1;
    plot(anax,anay,'color',COLORS{cidx},'tag','ROI');
  end
end


subDrawELEs(haxs,ROI,Slice,RoiName,COLORS,OffsX,OffsY,DO_FLIP);


return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot ELEs
function subDrawELEs(haxs,ROI,Slice,RoiName,COLORS,OffsX,OffsY,DO_FLIP)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isempty(ROI),  return;  end  


axes(haxs);
if isfield(ROI,'ele'),
  for N = 1:length(ROI.ele),
    ele = ROI.ele{N};
    if ele.slice ~= Slice,  continue;  end
    hold on;
    if DO_FLIP > 0,
      anax =  ele.x/ROI.pxscale + OffsX;
      anay = -ele.y/ROI.pyscale + OffsY;
    else
      anax =  ele.x/ROI.pxscale + OffsX;
      anay =  ele.y/ROI.pyscale + OffsY;
    end
    plot(anax,anay,'y+','markersize',12,'linewidth',2,'tag','ELE');
  end
end



return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to get a color map
function CMAP = subGetColormap(CMAPSTR,NLEVELS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('NLEVELS','var'),  NLEVELS = 256;  end

if CMAPSTR(end) == '-',
  DO_REVERSE = 1;
  CMAPSTR = CMAPSTR(1:end-1);
elseif CMAPSTR(end) == '+',
  DO_REVERSE = 0;
  CMAPSTR = CMAPSTR(1:end-1);
else
  DO_REVERSE = 0;
end


switch lower(CMAPSTR),
 case {'r','red'}
  CMAP = zeros(NLEVELS,3);
  CMAP(:,1) = (0:NLEVELS-1)'/(NLEVELS-1);
 case {'g','green'}
  CMAP = zeros(NLEVELS,3);
  CMAP(:,2) = (0:NLEVELS-1)'/(NLEVELS-1);
 case {'b','blue'}
  CMAP = zeros(NLEVELS,3);
  CMAP(:,3) = (0:NLEVELS-1)'/(NLEVELS-1);
 case {'c','cyan'}
  CMAP = zeros(NLEVELS,3);
  CMAP(:,2) = (0:NLEVELS-1)'/(NLEVELS-1);
  CMAP(:,3) = (0:NLEVELS-1)'/(NLEVELS-1);
 case {'m','magenta'}
  CMAP = zeros(NLEVELS,3);
  CMAP(:,1) = (0:NLEVELS-1)'/(NLEVELS-1);
  CMAP(:,3) = (0:NLEVELS-1)'/(NLEVELS-1);
 case {'y','yellow'}
  CMAP = zeros(NLEVELS,3);
  CMAP(:,1) = (0:NLEVELS-1)'/(NLEVELS-1);
  CMAP(:,2) = (0:NLEVELS-1)'/(NLEVELS-1);
 case {'k','black'}
  CMAP = zeros(NLEVELS,3);
  CMAP(:,1) = (NLEVELS-1:-1:1)'/(NLEVELS-1);
 case {'w','white'}
  CMAP = zeros(NLEVELS,3);
  CMAP(:,1) = (0:NLEVELS-1)'/(NLEVELS-1);
 case {'mri'}
  h = round(NLEVELS/2);
  c = hot(h);
  c1 = zeros(h,3);
  c1(:,3) = (0:h-1)'./h;
  CMAP = cat(1,flipud(c1),c);
  
 case { 'autumn','bone','colorcube','cool','copper',...
	'flag','gray','hot','hsv','jet','lines','pink','prism',...
	'spring','summer','white','winer' }
  CMAP = eval(sprintf('%s(NLEVELS)',CMAPSTR));
  
 otherwise
  fprintf('%s WARNING: colormap ''%s'' not supported.\n',CMAPSTR);
  CMAP = jet(NLEVELS);
end

if any(DO_REVERSE),
  %CMAP(1,:)
  CMAP = flipdim(CMAP,1);
  %CMAP(1,:)
end

return

