function varargout = showrois(Ses,GrpExp,varargin)
%SHOWROIS - displays ROIs.
%  SHOWROIS(SESSION,EXPNO,...)
%  SHOWROIS(SESSION,GRPNAME,...) displays ROIs.
%
%  Supported options are :
%    axes      : the axes handle to plot.
%    RoiName   : ROI names to draw
%    ROIColor  : a cell array of colors for ROIs
%    DrawELE   : a flag to draw electrodes, 0 or 1.
%    Slice     : slice selection
%    NRowNCol  : [NRow NCol] for display
%    AnaGamma  : Gamma correction for anatomy
%    AnaScale  : scale factors for anatomy, [min max gamma]
%    EpiAna    : uses EPI as anatomy or not, 0 or 1
%    SliceText : prints slice numbers or not, 0 or 1.
%
%  EXAMPLE :
%    >> showrois('I09rG1','spont','RoiName','all')
%    >> showrois('I09rG1','spont','RoiName','all','EpiAna',1)
%
%  VERSION :
%    0.90 06.07.15 YM  pre-release, derived from dspmvoxmap
%
%  See also anaload mroi_load mroi

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end


% CONTROL FLAGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H_AXES    =  [];
NRowNCol  =  [];
ROI_NAME  = { 'all' };
ROICOLORS = {'r','g','b','c','m','y','k'};
DRAW_ELE  =   1;
ANAGAMMAV =  [];
ANASCALE  =  [];
SELSLICE  =  [];
COLORBARF =   0;
SLICETEXT =   1;
EPI_ANA   =  [];


% parse inputs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for N=1:2:length(varargin),
  switch lower(varargin{N}),
   case {'slice' 'slices'}
    SELSLICE = varargin{N+1};
   case {'nrowncol','nrowsncols','nrowcol'}
    NRowNCol = varargin{N+1};
   case {'roiname','roinames','roi','rois'}
    ROI_NAME = varargin{N+1};
   case {'roicolor','roicolors','color','colors'}
    ROICOLORS = varargin{N+1};
   case {'drawele','eledraw','draweles'}
    DRAW_ELE = varargin{N+1};
   case {'axes'}
    H_AXES = varargin{N+1};
   case {'anagamma','gammaana'}
    ANAGAMMAV = varargin{N+1};
   case {'anascale'}
    ANASCALE  = varargin{N+1};
   case {'slicetext','textslice'}
    SLICETEXT = varargin{N+1};
   case {'epiana','anaepi','epi'}
    EPI_ANA = varargin{N+1};
  end
end


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
Ses = goto(Ses);
grp = getgrp(Ses,GrpExp);
ANAP = getanap(Ses,grp);


if isempty(EPI_ANA),
  EPI_ANA = 0;
  if isfield(ANAP,'ImgDistort') && ~isempty(ANAP.ImgDistort),
    EPI_ANA = ANAP.ImgDistort;
  end
end

ANA = anaload(Ses,grp,EPI_ANA);

if ischar(ROI_NAME),
  ROI_NAME = { ROI_NAME };
end

ROI = mroi_load(Ses,grp);
ROI.pxscale = size(ROI.img,1) / size(ANA.dat,1);
ROI.pyscale = size(ROI.img,2) / size(ANA.dat,2);



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
clear tmpana anaminv anamaxv anacmap;


tmptitle = sprintf('%s(%s) ROI:%s',Ses.name,grp.name,subCellStr2Str(ROI_NAME));


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
for N = 1:nslices,
  SliceNo = SELSLICE(N);
  
  imgtag = sprintf('slice=%d',SliceNo);
  h = findobj(H_AXES,'tag',imgtag);
  
  iCol = floor((N-1)/NCol)+1;
  iRow = mod((N-1),NCol)+1;
  offsX = nX*(iRow-1);
  offsY = nY*NRow - iCol*nY;

  tmpimg = squeeze(ANA.rgb(:,:,SliceNo,:));
  tmpx = X + offsX;
  tmpy = Y + offsY;
  image(tmpx,tmpy,permute(tmpimg,[2 1 3]),'tag',imgtag);
  hold on;
  if SLICETEXT > 0,
    text(min(tmpx)+1,max(tmpy),sprintf('slice=%d',SliceNo),...
         'color',[0.9 0.9 0.5],'VerticalAlignment','top',...
         'FontName','Comic Sans MS','FontSize',8,'Fontweight','bold');
  end
  hold on;
  % draw ROI/ele
  subDrawROIs(gca,ROI,N,ROI_NAME,ROICOLORS,offsX,offsY+nY,1);
  if DRAW_ELE,
    % draw ele only
    subDrawELEs(gca,ROI,N,ROI_NAME,ROICOLORS,offsX,offsY+nY,1);
  end
  
end
set(gca,'xlim',[0 nX*NCol-0.5],'ylim',[0 nY*NRow-0.5],'Ydir','normal',...
        'YTickLabel',{},'YTick',[],'XTickLabel',{},'XTick',[],'Ydir','normal');
set(gca,'color',[0 0 0],'UserData',mfilename);
title(strrep(tmptitle,'_','\_'));
%daspect(gca,[ANA.ds(1)/ANA.ds(2) 1 2]);
daspect(gca,[ANA.ds(2)/ANA.ds(1) 1 2]);

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



% ==================================================================
function str = subCellStr2Str(cstr)
% ==================================================================

if ischar(cstr),
  str = cstr;
  return
end

str = '';
if isempty(cstr),  return;  end

str = cstr{1};
for K = 2:length(cstr),
  str = [str, '+', cstr{K}];
end


return