function tcimgmovie(varargin)
%TCIMGMOVIE - makes a movie from tcImg data.
%  TCIMGMOVIE(SES,EXPNO,...)
%  TCIMGMOVIE(TCIMG,...) makes a movie from tcImg data.
%  TCIMGMOVIE(2DSEQFILE,...) makes a movie from 2dseq
%
%  Supported options are :
%   'minmax'  : [min max] for scaling data
%   'cmap'    : name of the colormap.
%   'drawroi' : 0|1, draw ROIs
%
%  VERSION :
%    0.90 25.10.07 YM  pre-release
%    0.91 29.10.07 YM  supports also 2dseq.
%    0.92 18.09.08 YM  less memory usage when 2dseq, use pvread_2dseq.
%    0.93 24.09.08 YM  supports saving avi.
%    0.94 20.01.12 YM  bug fix for nt=1, adds "centroid".
%    0.95 03.09.25 YM  bug fix when called like tcimgmovie(2dseq).
%    0.96 04.09.25 YM  supports the widget for MinMaxV, 'cmap' option.
%
%  See also sigload pvread_2dseq

if nargin == 0,  eval(sprintf('help %s',mfilename)); return;  end



% execute callback function then return; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(varargin{1}) && ~isempty(findstr(varargin{1},'Callback')),
  %fprintf('%s %s\n',datestr(now),varargin{1});
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return;
end


if isstruct(varargin{1}) && isfield(varargin{1},'dat'),
  % called like tcimgmovie(tcImg)
  tcImg = varargin{1};
  optidx = 2;
else
  if ~isempty(findstr(varargin{1},'2dseq')),
    % called like tcimgmovie(2dseq_file)
    tcImg = subGetTCIMG(varargin{1},varargin{2:end});
    optidx = 2;
  else
    % called like tcimgmovie(Ses,ExpNo,...)
    if exist('mcsession','class'),
      tmpimg = ctcimg(varargin{:});
      tcImg = tmpimg.oldformat();
      clear tmpimg;
    else
      % called like tcimgmovie(Ses,ExpNo,...)
      tcImg = sigload(varargin{1},varargin{2},'tcImg');
    end
    optidx = 3;
  end
end


DRAW_ROI = 0;
MINMAXV  = [];
COLOR_MAP = 'gray';
for N = optidx:2:length(varargin)
  switch lower(varargin{N}),
   case {'minmax','minmaxv'}
    MINMAXV = varargin{N+1};
   case {'drawroi' 'drawrois' 'roi' 'rois'}
     DRAW_ROI = varargin{N+1};
   case {'colormap' 'cmap'}
     COLOR_MAP = varargin{N+1};
  end
end


% if has 'trials', then make them as a single
if size(tcImg.dat,5) > 1,
  tmpsz = size(tcImg.dat);
  tcImg.dat = reshape(tcImg.dat,[tmpsz(1:3) prod(tmpsz(4:end))]);
end


if any(DRAW_ROI),
  ROI = sub_loadroi(tcImg);
else
  ROI = [];
end


figW = 120;
figH = 30;

if tcImg.ExpNo(1) > 0
  tmptxt = sprintf('%s: %s ExpNo=%d',mfilename,tcImg.session,tcImg.ExpNo(1));
else
  tmptxt = sprintf('%s: %s [%d %d]',mfilename,tcImg.session,tcImg.scanreco(1),tcImg.scanreco(2));
end

hMain = figure(...
    'Name',tmptxt,...
    'NumberTitle','off', 'toolbar','figure',...
    'Tag','main','units','char',...
    'HandleVisibility','on', 'Resize','on',...
    'DoubleBuffer','on', 'BackingStore','on', 'Visible','on',...
    'DefaultAxesFontSize',10,...
    'DefaultAxesfontweight','bold',...
    'PaperPositionMode','auto', 'PaperType','A4', 'PaperOrientation', 'landscape');


tmppos = get(hMain,'pos');
tmpy = tmppos(2)+tmppos(4);
tmppos(3) = figW;  tmppos(4) = figH;
tmppos(2) = tmpy - tmppos(4);
set(hMain, 'pos',tmppos);
clear tmppos tmpy;

% AXES TO PLOT IMAGES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hAxs = axes(...
    'Parent',hMain,'Tag','ImageAxs',...
    'Units','char','Position',[ 8 3 90 26],...
    'fontsize',8,'Box','off','color','black','Visible','on');


% SLIDER - Time bar
if size(tcImg.dat,4) == 1,
  minv = 0.999;  maxv = 1.001;
  sstep = [1 1];
else
  minv = 1;     maxv = size(tcImg.dat,4);
  sstep = [1/max([1 maxv-1]) 0.05];
end
TimeSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[ 8 0.8 90 0.8],'Tag','TimeSldr',...
    'Callback','tcimgmovie(''Main_Callback'',gcbo,''t-slider'',[])',...
    'value',1,'min',minv,'max',maxv,'SliderStep',sstep,...
    'TooltipString','Time Points');


XDSP = figW-18;
% Button: Make movie %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MakeMovieBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[XDSP figH-3 15 1.5],...
    'String','Make','Tag','MakeMovieBtn',...
    'Callback','tcimgmovie(''Main_Callback'',gcbo,''make-movie'',guidata(gcbo))',...
    'TooltipString','Make a movie',...
    'FontWeight','bold');

% Button: Play movie %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PlayMovieBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[XDSP figH-5 15 1.5],...
    'String','Play','Tag','PlayMovieBtn',...
    'Callback','tcimgmovie(''Main_Callback'',gcbo,''play-movie'',guidata(gcbo))',...
    'TooltipString','Play a movie',...
    'FontWeight','bold');

% Button: Play movie %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SaveMovieBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[XDSP figH-7 15 1.5],...
    'String','Save AVI','Tag','SaveMovieBtn',...
    'Callback','tcimgmovie(''Main_Callback'',gcbo,''save-movie'',guidata(gcbo))',...
    'TooltipString','Save a movie',...
    'FontWeight','bold');

FpsTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP figH-9.2 12 1.5],...
    'String','fps:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','FpsTxt',...
    'BackgroundColor',get(hMain,'Color'));
FpsEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+7 figH-9 8 1.5],...
    'String','24','Tag','FpsEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','frames/sec',...
    'FontWeight','Bold');

tmpi = find(strcmpi({'gray','jet','hot','cool','bone','copper','pink'},COLOR_MAP));
ColormapCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP figH-11 15 1.5],...
    'String',{'gray','jet','hot','cool','bone','copper','pink'},...
    'Value',tmpi,'Tag','ColormapCmb',...
    'Callback','tcimgmovie(''Main_Callback'',gcbo,''t-slider'',[])',...
    'HorizontalAlignment','left',...
    'TooltipString','colormap',...
    'FontWeight','Bold');

CentroidCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP figH-13 15 1.5],...
    'Tag','CentroidCheck','Value',0,...
    'String','centroid','FontWeight','bold',...
    'Callback','tcimgmovie(''Main_Callback'',gcbo,''t-slider'',[])',...
    'TooltipString','prints centroid','BackgroundColor',get(hMain,'Color'));

UseImagescCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP figH-15 15 1.5],...
    'Tag','UseImagescCheck','Value',0,...
    'String','imagesc','FontWeight','bold',...
    'Callback','tcimgmovie(''Main_Callback'',gcbo,''t-slider'',[])',...
    'TooltipString','use imagesc()','BackgroundColor',get(hMain,'Color'));

MinMaxTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP figH-17 12 1.5],...
    'String','MinMax:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','MinMaxTxt',...
    'BackgroundColor',get(hMain,'Color'));
MinMaxEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP figH-18.5 15 1.5],...
    'String','','Tag','MinMaxEdt',...
    'HorizontalAlignment','center',...
    'Callback','tcimgmovie(''Main_Callback'',gcbo,''t-slider'',[])',...
    'TooltipString','MinMax to normalize',...
    'FontWeight','Bold');



setappdata(hMain,'tcImg',tcImg);
minv = min(tcImg.dat(:));  maxv = max(tcImg.dat(:));
if isempty(MINMAXV),
  MINMAXV = [min(0,minv) maxv];
  fprintf(' MINMAXV = [%g %g]\n',MINMAXV(1),MINMAXV(2));
end
set(MinMaxEdt,'String',sprintf('%g  %g',MINMAXV(1),MINMAXV(2)));
set(MinMaxTxt,'String',sprintf('MinMax [%g %g]:',minv,maxv));
%setappdata(hMain,'MINMAXV',MINMAXV);
clear minv maxv;
setappdata(hMain,'ROI',    ROI);

if isfield(tcImg,'centroid'),
  CENT = tcImg.centroid;
else
  CENT = mcentroid(tcImg.dat,tcImg.ds);
end
CENT = CENT';  % (xyz,t) --> (t,xyz)
for N = 1:3,
  CENT(:,N) = CENT(:,N) - nanmean(CENT(:,N));
end
CENTTHR = nanstd(CENT,[],1);
setappdata(hMain,'CENT',   CENT);
setappdata(hMain,'CENTTHR',CENTTHR);

% get widgets handles at this moment
HANDLES = findobj(hMain);
% NOW SET "UNITS" OF ALL WIDGETS AS "NORMALIZED".
HANDLES = HANDLES(HANDLES ~= hMain);
set(HANDLES,'units','normalized');

% make the window x1.5 larger.


Main_Callback(hMain,'t-slider');
tmppos = get(hMain,'pos');  tmpy = tmppos(2)+tmppos(4); tmppos(3:4) = round(tmppos(3:4)*1.5); tmppos(2) = tmpy - tmppos(4); set(hMain,'pos',tmppos);
clear tmpy tmppos;


return;


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tcImg = subGetTCIMG(IMGFILE,varargin)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

IMGCROP = [];
SLICROP = [];
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'imgcrop','imagecrop'}
    IMGCROP = varargin{N+1};
   case {'slicrop','slicecrop'}
    SLICROP = varargin{N+1};
  end
end

[tmpdir,reconum] = fileparts(fileparts(IMGFILE));
[tmpdir,scannum] = fileparts(fileparts(tmpdir));
[tmpdir,sesdir,tmpext] = fileparts(tmpdir);
%sesname = strcat(tmpdir,tmpext);
sesname = sesdir;
scannum = str2num(scannum);
reconum = str2num(reconum);


acqp   = pvread_acqp(IMGFILE,'verbose',0);
reco   = pvread_reco(IMGFILE,'verbose',0);

IMGP   = pv_imgpar(IMGFILE,'acqp',acqp,'reco',reco);
imgdat = pvread_2dseq(IMGFILE,'imgp',IMGP,...
                      'imgcrop',IMGCROP,'slicrop',SLICROP);


tcImg.session = sesname;
tcImg.grpname = 'unknown';
tcImg.ExpNo   = -1;
%tcImg.dat     = double(imgdat);
tcImg.dat     = imgdat;
tcImg.dx      = IMGP.imgtr;
tcImg.ds      = IMGP.voxsize;
tcImg.usr.pvpar.acqp = acqp;
tcImg.usr.pvpar.reco = reco;
tcImg.scanreco = [scannum, reconum];
tcImg.imgfile = IMGFILE;


return



% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Main_Callback(hObject,eventdata,handles)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(hObject);


ROI = getappdata(wgts.main,'ROI');


switch lower(eventdata),
 case {'make-movie'}
  tcImg   = getappdata(wgts.main,'tcImg');
  %MINMAXV = getappdata(wgts.main,'MINMAXV');
  MINMAXV = str2num(get(wgts.MinMaxEdt,'String'));
  CENT    = getappdata(wgts.main,'CENT');
  CENTTHR = getappdata(wgts.main,'CENTTHR');
  
  cmapname = get(wgts.ColormapCmb,'String');
  cmapname = cmapname{get(wgts.ColormapCmb,'Value')};
  switch lower(cmapname)
   case {'jet'}
    txtcolor = 'y';
   case {'cool'}
    txtcolor = 'k';
   otherwise
    txtcolor = 'y';
  end
  
  cmap = eval(sprintf('%s(256)',cmapname));
  colormap(cmap);
  drawnow;
  UseImagesc = get(wgts.UseImagescCheck,'Value');
  
  minv = MINMAXV(1);
  maxv = MINMAXV(2);
  [NRow NCol] = subGetNRowNCol(size(tcImg.dat),[]);

  axes(wgts.ImageAxs);
  for N = 1:size(tcImg.dat,4),
    subDrawVolume(wgts,tcImg,N,NRow,NCol,minv,maxv,UseImagesc,txtcolor,ROI);
    %set(wgts.TimeSldr,'Value',N);
    M(N) = getframe;
  end
  set(wgts.ImageAxs,'tag','ImageAxs');
  setappdata(wgts.main,'M',M);
  
 case {'play-movie'}
  M = getappdata(wgts.main,'M');
  if isempty(M),
    Main_Callback(hObject,'make-movie',[]);
    M = getappdata(wgts.main,'M');
  end
  fps = str2num(get(wgts.FpsEdt,'String'));
  if isempty(fps),  fps = 1;  end
  movie(M,1,fps);
  
 case {'save-movie'}
  M = getappdata(wgts.main,'M');
  if isempty(M),
    Main_Callback(hObject,'make-movie',[]);
    M = getappdata(wgts.main,'M');
  end
  fps = str2num(get(wgts.FpsEdt,'String'));
  if isempty(fps),  fps = 1;  end
  fname = sprintf('tcimgmovie_%s.avi',datestr(now,'YYYYmmdd_HHMM'));
  fprintf('%s: saving %s...fps=%g',mfilename,fname,fps);
  mov = avifile(fname,'fps',fps,'compression','none','quality',100);
  for N = 1:length(M),
    mov = addframe(mov,M(N));
  end
  mov = close(mov);
  fprintf(' done.\n');
  
 case {'t-slider'}
  tcImg   = getappdata(wgts.main,'tcImg');
  %MINMAXV = getappdata(wgts.main,'MINMAXV');
  MINMAXV = str2num(get(wgts.MinMaxEdt,'String'));
  CENT    = getappdata(wgts.main,'CENT');
  CENTTHR = getappdata(wgts.main,'CENTTHR');
  N = round(get(wgts.TimeSldr,'Value'));
  if N < 1, N = 1;  end
  if N > size(tcImg.dat,4), N = size(tcImg.dat,4);  end
  cmapname = get(wgts.ColormapCmb,'String');
  cmapname = cmapname{get(wgts.ColormapCmb,'Value')};
  switch lower(cmapname)
   case {'jet'}
    txtcolor = 'y';
   case {'cool'}
    txtcolor = 'k';
   otherwise
    txtcolor = 'y';
  end
  cmap = eval(sprintf('%s(256)',cmapname));
  colormap(cmap);
  UseImagesc = get(wgts.UseImagescCheck,'Value');
  
  minv = MINMAXV(1);
  maxv = MINMAXV(2);
  [NRow NCol] = subGetNRowNCol(size(tcImg.dat),[]);
  
  axes(wgts.ImageAxs);
  subDrawVolume(wgts,tcImg,N,NRow,NCol,minv,maxv,UseImagesc,txtcolor,ROI);
  drawnow;

 otherwise
  fprintf('WARNING %s: Main_Callback() ''%s'' not supported yet.\n',...
          mfilename,eventdata);
end

return;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION to draw a volume
function M = subDrawVolume(wgts,tcImg,N,NRow,NCol,minv,maxv,UseImagesc,txtcolor,ROI)

tmpimg = subCollageVolume(tcImg.dat(:,:,:,N),NRow,NCol);
if UseImagesc > 0,
  imagesc(tmpimg);
else
  tmpimg = double(tmpimg);
  minv = double(minv);  maxv = double(maxv);
  tmpimg = (tmpimg - minv) / (maxv - minv);
  imagesc(tmpimg);
  set(gca,'clim',[0 1]);
end
subDrawImageBorder(tcImg,NRow,NCol);
set(wgts.ImageAxs,'FontSize',8);
sub_drawroi(ROI,NRow,NCol,size(tcImg.dat,1),size(tcImg.dat,2));
text(0.01,0.995,sprintf('%04d (%.2fsec)',N,(N-1)*tcImg.dx),...
     'color',txtcolor,'units','normalized','horizontalalignment','left','verticalalignment','top');
text(0.99,0.005,sprintf('vox = [%g %g %g]mm',tcImg.ds(1),tcImg.ds(2),tcImg.ds(3)),...
     'color',txtcolor,'units','normalized','horizontalalignment','right','verticalalignment','bottom');
if get(wgts.CentroidCheck,'Value') > 0,
  tmpx = 0.75;
  text(0.75,0.05,'(',...
       'color',[0.7 0.7 0.7],'units','normalized','horizontalalignment','left');
  for C = 1:3,
    if abs(CENT(N,C)) < CENTTHR(C),
      text(tmpx+0.01,0.05,sprintf('%.2f',CENT(N,C)),...
           'color',[0.7 0.7 0.7],'units','normalized','horizontalalignment','left');
    else
      text(tmpx+0.01,0.05,sprintf('%.2f',CENT(N,C)),...
           'color',[0.9 0.2 0.2],'units','normalized','horizontalalignment','left');
    end
    tmpx = tmpx + 0.08;
  end
  text(0.985,0.05,')',...
       'color',[0.7 0.7 0.7],'units','normalized','horizontalalignment','left');
end
daspect([1 tcImg.ds(2)/tcImg.ds(1) 1]);
set(wgts.ImageAxs,'tag','ImageAxs');

return


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION to get NRow/NCol for Lightbox mode
function [NRow NCol] = subGetNRowNCol(IMGDIM,PIXDIM)

if isempty(PIXDIM),  PIXDIM = [1 1 1];  end

nslices = IMGDIM(3);

if 1,
  xfov = IMGDIM(1)*PIXDIM(1);
  yfov = IMGDIM(2)*PIXDIM(2);
  
  NRow = ceil(sqrt(nslices*xfov/yfov));
  NCol = round(nslices/NRow);

  if NCol*NRow < nslices,
    if xfov > yfov,
      NRow = NRow + 1;
    else
      NCol = NCol + 1;
    end
  end
  
  %fprintf('nsli=%d,xfov=%g,yfov=%g,NRow=%d,NCol=%d\n',nslices,xfov,yfov,NRow,NCol);
else
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
end


return



% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function img = subCollageVolume(imgvol,NRow,NCol)

% note that image()/imacesc() requires (y,x) not (x,y)
  
nx = size(imgvol,1);
ny = size(imgvol,2);

img = zeros(ny*NRow,nx*NCol);
%size(img), NRow, NCol, size(imgvol)

K = 1;
for Y = 1:NRow,
  tmpy = (1:ny) + (Y-1)*ny;
  for X=1:NCol,
    tmpx = (1:nx) + (X-1)*nx;
    img(tmpy,tmpx) = imgvol(:,:,K)';
    K = K + 1;
    if K > size(imgvol,3),  break;  end
  end
  if K > size(imgvol,3),  break;  end
end

return





% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ROI = sub_loadroi(tcImg)
ROI = [];
if ~exist(tcImg.session,'file'),  return;  end

Ses = goto(tcImg.session);
grp = getgrp(Ses,tcImg.ExpNo(1));

if ~exist('./Roi.mat','file');  return;  end
if ~any(strcmp(who('-file','./Roi.mat'),grp.grproi)),  return;  end

ROI = load('./Roi.mat',grp.grproi);
ROI = ROI.(grp.grproi);


return



% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sub_drawroi(ROI,NRow,NCol,NX,NY)

if isempty(ROI); return;  end


for N = 1:length(ROI.roi),
  tmproi = ROI.roi{N};
  if isempty(tmproi.px) || isempty(tmproi.py),  continue;  end
  offsX = mod((tmproi.slice-1),NCol)*NX;
  offsY = floor((tmproi.slice-1)/NCol)*NY;
  tmpx  = tmproi.px + offsX;
  tmpy  = tmproi.py + offsY;
  hold on;
  plot(tmpx,tmpy,'color','m');
end



return


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subDrawImageBorder(tcImg,NRow,NCol);
nx = size(tcImg.dat,1);  ny = size(tcImg.dat,2);
tmpy = get(gca,'ylim');
for K = 1:NCol-1
  tmpx = [nx nx]*K + 0.5;
  line(tmpx,tmpy,'Color',[0.3 0.3 0.3]);
end
tmpx = get(gca,'xlim');
for K = 1:NRow-1
  tmpy = [ny ny]*K + 0.5;
  line(tmpx,tmpy,'Color',[0.3 0.3 0.3]);
end
set(gca,'XTick',[nx:nx:nx*(NCol-1)], 'YTick',[ny:ny:ny*(NRow-1)]);

return

