function varargout = monlinetripilot(varargin)
%MONLINETRIPILOT - viewer for tripilot scan
%  MONLINETRIPILOT  called by MONLINE.
%
%  EXAMPLE :
%    >> monline
%    >> monlinetripilot(SIG)
%
%  NOTES :
%    This function will be called by monline.m after processing data.
%
%  VERSION :
%    0.90 14.04.08 YM  pre-release
%    0.91 24.04.08 MK  limited support of slice-drawing
%    0.92 10.12.13 YM  ignore errors on slice orientation, just make a warning.
%
%  See also MONLINE MONLINEPROC MONLINEVIEW MONLINEPVPAR

% display help if no arguments %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 0,  help monlinetripilot; return;  end


% execute callback function then return; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(varargin{1}) & ~isempty(findstr(varargin{1},'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return;
end


% PREPARE DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(varargin{1}),
  % called like monlinetripilot(TRIPILOT_FILE,IMAGE_FILE)
  ONLINE = subLoadData(varargin{1},varargin{2});
  ivar = 3;
else
  % called like monlinetripilot(SIG)
  ONLINE = varargin{1};
  % no need to keep a big data for this tripilot
  if isfield(ONLINE,'dat'),  ONLINE.dat = [];  end
  ivar = 2;
end

hMain = [];
for N=ivar:2:length(varargin),
  switch lower(varargin{N}),
   case {'hfig','figure','hmain'}
    hMain = varargin{N+1};
  end
end


anaminv = 0;
anamaxv = round(mean(ONLINE.tripilot.dat(:))*7.0) ;
anagamma = 1.8;
ONLINE.tripilot.anargb = subScaleAnatomy(ONLINE.tripilot.dat,anaminv,anamaxv,anagamma);
ONLINE.tripilot.anascale = [anaminv anamaxv anagamma];



% GET SCREEN SIZE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[scrW scrH] = subGetScreenSize('char');
% keep the figure size smaller than XGA (1024x768) for notebook PC.
% figWH: [185 57]chars = [925 741]pixels
figW = 162; figH = 57;
figX = max(min(63,scrW-figW),10);
figY = scrH-figH-9.7;


% SET WINDOW TITLE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmptitle = sprintf('%s:  %s  %d/%d  %s',...
                   mfilename,ONLINE.session,ONLINE.scanreco(1),ONLINE.scanreco(2),...
                   datestr(now));


if ishandle(hMain),
  % update 'ONLINE' data
  setappdata(hMain,'ONLINE',ONLINE);
  Main_Callback(hMain,'init');
  return
elseif ~isempty(hMain),
  figure(hMain);  clf;
  set(hMain,...
      'Name',tmptitle,...
      'NumberTitle','off', 'toolbar','figure',...
      'Tag','main', 'units','char', 'pos',[figX figY figW figH],...
      'HandleVisibility','on', 'Resize','on',...
      'DoubleBuffer','on', 'BackingStore','on', 'Visible','on',...
      'DefaultAxesFontSize',8,...
      'DefaultAxesfontweight','bold',...
      'PaperPositionMode','auto', 'PaperType','A4', 'PaperOrientation', 'landscape');
  
else
  % CREATE A MAIN FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  hMain = figure(...
      'Name',tmptitle,...
      'NumberTitle','off', 'toolbar','figure',...
      'Tag','main', 'units','char', 'pos',[figX figY figW figH],...
      'HandleVisibility','on', 'Resize','on',...
      'DoubleBuffer','on', 'BackingStore','on', 'Visible','on',...
      'DefaultAxesFontSize',8,...
      'DefaultAxesfontweight','bold',...
      'PaperPositionMode','auto', 'PaperType','A4', 'PaperOrientation', 'landscape');
end



% CREATE AXES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 3; XSZ = 68; YSZ = 24.5;
XDSP=8;
TraAxs = axes(...
    'Parent',hMain,'Tag','TraAxs',...
    'Units','char','Position',[XDSP H XSZ YSZ],...
    'Box','off','color','black','Visible','on');
SagAxs = axes(...
    'Parent',hMain,'Tag','SagAxs',...
    'Units','char','Position',[XDSP+XSZ+10 H+YSZ+H XSZ YSZ],...
    'Box','off','color','black','Visible','on');
CorAxs = axes(...
    'Parent',hMain,'Tag','CorAxs',...
    'Units','char','Position',[XDSP H+YSZ+H XSZ YSZ],...
    'Box','off','color','black','Visible','on');

% INFORMATION LIST %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
InfoTxt = uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','char','Position',[XDSP+XSZ+10 H XSZ 14],...
    'String',{'session','group','datsize','resolution'},...
    'HorizontalAlignment','left',...
    'FontName','Comic Sans MS','FontSize',9,...
    'TooltipString','Double-click invokes ACQP/METHOD/RECO window',...
    'Callback','monlinetripilot(''Main_Callback'',gcbo,''show-pvpar'',guidata(gcbo))',...
    'Tag','InfoTxt','Background','white');


% Superimpose or not %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 3 + YSZ - 1.5;
OverlayCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+XSZ+10 H 20 1.5],...
    'Tag','OverlayCheck','Value',1,...
    'Callback','monlinetripilot(''Main_Callback'',gcbo,''redraw'',guidata(gcbo))',...
    'String','Overlay','FontWeight','bold',...
    'TooltipString','slice on/off','BackgroundColor',get(hMain,'Color'));
CrosshairCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+XSZ+10+20 H 20 1.5],...
    'Tag','CrosshairCheck','Value',1,...
    'Callback','monlinetripilot(''Main_Callback'',gcbo,''redraw'',guidata(gcbo))',...
    'String','Crosshair','FontWeight','bold',...
    'TooltipString','crosshair on/off','BackgroundColor',get(hMain,'Color'));


% ANATOMY SCALE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 3 + YSZ - 3.5;
AnatScaleTxt =  uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+XSZ+10 H-0.3 30 1.5],...
    'String','Anat. Scale:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','AnatScaleTxt',...
    'BackgroundColor',get(hMain,'Color'));
AnatScaleEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+XSZ+10+20, H 30 1.5],...
    'String',sprintf('%g  %g  %g',anaminv,anamaxv,anagamma),...
    'Tag','AnatScaleEdt',...
    'Callback','monlinetripilot(''Main_Callback'',gcbo,''update-anatomy'',guidata(gcbo))',...
    'HorizontalAlignment','center',...
    'TooltipString','Scale anatomy [min max gamma]',...
    'FontWeight','Bold');


% get widgets handles at this moment
HANDLES = findobj(hMain);


% INITIALIZE THE APPLICATION
setappdata(hMain,'ONLINE',ONLINE);
Main_Callback(hMain,'init');
set(hMain,'visible','on');


% NOW SET "UNITS" OF ALL WIDGETS AS "NORMALIZED".
HANDLES = HANDLES(find(HANDLES ~= hMain));
set(HANDLES,'units','normalized');



% RETURNS THE WINDOW HANDLE IF REQUIRED.
if nargout,
  varargout{1} = hMain;
end


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pvpar = subGetPvPar(ACQP,RECO,IMND,METHOD)
pvpar.acqp = ACQP;
pvpar.reco = RECO;
if ~isempty(METHOD),
  pvpar.method = METHOD;
end
if ~isempty(IMND),
  pvpar.imnd   = IMND;
end

% basic info
pvpar.nx   = RECO.RECO_size(1);
pvpar.ny   = RECO.RECO_size(2);
pvpar.nsli = ACQP.NSLICES;
pvpar.nt   = ACQP.NR;
if ~isempty(METHOD),
  pvpar.nseg = METHOD.PVM_EpiNShots;
else
  pvpar.nseg = IMND.IMND_numsegments;
  if strcmpi(IMND.EPI_segmentation_mode,'No_Segments')    % glitch for EPI
    pvpar.nseg   = 1;			
  end
end
pvpar.ds(1) = RECO.RECO_fov(1) / RECO.RECO_size(1) * 10;
pvpar.ds(2) = RECO.RECO_fov(2) / RECO.RECO_size(2) * 10;
if length(ACQP.ACQ_slice_offset) > 1,
  pvpar.ds(3) = mean(diff(ACQP.ACQ_slice_offset));
else
  %pvpar.ds(3) = ACQP.ACQ_slice_sepn;
  pvpar.ds(3) = ACQP.ACQ_slice_thick;
end
% timings in seconds
if ~isempty(METHOD),
  pvpar.slitr = ACQP.ACQ_repetition_time/1000/ACQP.NSLICES;
  pvpar.segtr = ACQP.ACQ_repetition_time/1000;
  pvpar.imgtr = ACQP.ACQ_repetition_time/1000*METHOD.PVM_EpiNShots;
  pvpar.effte = METHOD.EchoTime/1000;
  pvpar.recovtr = ACQP.ACQ_recov_time(:)'/1000;
else
  if strncmp(ACQP.PULPROG, '<BLIP_epi',9)
    pvpar.slitr	= IMND.EPI_slice_rep_time/1000;
    pvpar.segtr	= IMND.IMND_rep_time;       
    pvpar.imgtr	= pvpar.segtr * pvpar.nseg;
    if strcmpi(IMND.EPI_scan_mode,'FID')
      pvpar.effte = IMND.EPI_TE_eff/1000;
    else
      pvpar.effte = IMND.IMND_echo_time/1000;
    end
  else
    pvpar.slitr	= IMND.IMND_rep_time;
    pvpar.segtr	= IMND.IMND_acq_time/1000;
    pvpar.imgtr	= pvpar.slitr;
    pvpar.effte	= IMND.IMND_echo_time/1000;
  end
  pvpar.recovtr	= IMND.IMND_recov_time(:)'/1000;
end
  
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SIG = subLoadData(TRIPILOT_FILE,IMAGE_FILE)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get tripilot data
TACQP = pvread_acqp(TRIPILOT_FILE);
TRECO = pvread_reco(TRIPILOT_FILE);
TRIDAT = pvread_2dseq(TRIPILOT_FILE,'acqp',TACQP,'reco',TRECO);
ds = TRECO.RECO_fov ./ TRECO.RECO_size * 10;  % in mm
ds(3) = ds(1);

TRIPILOT.dat = TRIDAT;
TRIPILOT.ds  = ds;
TRIPILOT.pvpar.acqp = TACQP;
TRIPILOT.pvpar.reco = TRECO;

% Get info for imaging
ACQP   = pvread_acqp(IMAGE_FILE,'verbose',0);
IMND   = pvread_imnd(IMAGE_FILE,'verbose',0);
METHOD = pvread_method(IMAGE_FILE,'verbose',0);
RECO   = pvread_reco(IMAGE_FILE,'verbose',0);

p = IMAGE_FILE;
for N = 1:5,
  [p,f,e] = fileparts(p);
  if N == 2,
    recov = str2num(f);
  elseif N == 4,
    scanv = str2num(f);
  elseif N == 5,
    sespath = p;
    sesname = strcat(f,e);
  end
end

% prepare return structure
SIG.imgfile  = IMAGE_FILE;
SIG.path     = sespath;
SIG.session  = sesname;
SIG.scanreco = [scanv recov];
SIG.tripilot = TRIPILOT;
SIG.pvpar    = subGetPvPar(ACQP,RECO,IMND,METHOD);
SIG.ds       = SIG.pvpar.ds;
  
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
% CORRECTION:
tmpana(find(tmpana(:) <=   0)) =   1;
tmpana(find(tmpana(:) > 256)) = 256;
anacmap = gray(256).^(1/GAMMA);
for N = size(tmpana,3):-1:1,
  ANARGB(:,:,:,N) = ind2rgb(tmpana(:,:,N),anacmap);
end

ANARGB = permute(ANARGB,[1 2 4 3]);  % [x,y,rgb,z] --> [x,y,z,rgb]


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Main_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%fprintf('Main_Callback.%s\n',eventdata);
wgts = guihandles(hObject);
switch lower(eventdata),
 case {'init'}
  ONLINE = getappdata(wgts.main,'ONLINE');
  
  % set information text
  pvpar = ONLINE.pvpar;
  INFTXT = {};
  INFTXT{end+1} = sprintf('%s  %d/%d',ONLINE.session,ONLINE.scanreco(1),ONLINE.scanreco(2));
  INFTXT{end+1} = sprintf('%s',pvpar.acqp.ACQ_time(2:end-1));
  INFTXT{end+1} = sprintf('%s',pvpar.acqp.PULPROG);
  INFTXT{end+1} = sprintf('[%dx%dx%d/%d]',pvpar.nx,pvpar.ny,pvpar.nsli,pvpar.nt);
  INFTXT{end+1} = sprintf('[%gx%gx%g]',ONLINE.ds(1),ONLINE.ds(2),ONLINE.ds(3));
  INFTXT{end+1} = sprintf('nseg=%d, imgtr=%gs',pvpar.nseg,pvpar.imgtr);
  
  set(wgts.InfoTxt,'String',INFTXT);
  Main_Callback(hObject,'redraw',[]);
  
 case {'update-anatomy'}
  anascale = str2num(get(wgts.AnatScaleEdt,'String'));
  if length(anascale) == 3,
    ONLINE = getappdata(wgts.main,'ONLINE');
    ONLINE.tripilot.anargb = subScaleAnatomy(ONLINE.tripilot.dat,anascale(1),anascale(2),anascale(3));
    ONLINE.tripilot.anascale = anascale;
    setappdata(wgts.main,'ONLINE',ONLINE);
    Main_Callback(hObject,'redraw',[]);
  end
 
 case {'redraw'}
  ONLINE = getappdata(wgts.main,'ONLINE');
  IMGDAT = ONLINE.tripilot.anargb;
  imgsz  = size(ONLINE.tripilot.dat);
  imgres = ONLINE.tripilot.ds;
  IMGDAT = permute(IMGDAT,[2 1 3 4]);  % (x,y,z,color) --> (y,x,z,color)
  
  tmpX = [0:imgsz(1)-1]*imgres(1) - imgsz(1)*imgres(1)/2;
  tmpY = [0:imgsz(2)-1]*imgres(2) - imgsz(2)*imgres(2)/2;
  
  AXISCOLOR = [0.8 0.2 0.8];   XLIM = [-60 60];  YLIM = [-60 60];

  
  axes(wgts.TraAxs); cla;
  image(tmpX,tmpY,squeeze(IMGDAT(:,:,1,:)));
  set(gca,'color',[0 0 0],'xlim',XLIM,'ylim',YLIM);
  daspect([2 2 1]);
  set(gca,'Tag','TraAxs');
  xlabel('X (mm)');  ylabel('Y (mm)');
  text(0.01,0.99,'Axial','color',[0.9 0.9 0],...
       'units','normalized','verticalalignment','top');
  
  axes(wgts.SagAxs); cla;
  image(tmpX,tmpY,squeeze(IMGDAT(:,:,2,:)));
  set(gca,'color',[0 0 0],'xlim',XLIM,'ylim',YLIM);
  daspect([2 2 1]);
  set(gca,'Tag','SagAxs');
  xlabel('Y (mm)');  ylabel('Z (mm)');
  text(0.01,0.99,'Sagital','color',[0.9 0.9 0],...
       'units','normalized','verticalalignment','top');

  axes(wgts.CorAxs); cla;
  image(tmpX,tmpY,squeeze(IMGDAT(:,:,3,:)));
  set(gca,'color',[0 0 0],'xlim',XLIM,'ylim',YLIM);
  daspect([2 2 1]);
  set(gca,'Tag','CorAxs');
  xlabel('X (mm)');  ylabel('Z (mm)');
  text(0.01,0.99,'Coronal','color',[0.9 0.9 0],...
       'units','normalized','verticalalignment','top');
 
  haxs = [wgts.TraAxs, wgts.SagAxs, wgts.CorAxs];
  set(haxs,'xcolor',AXISCOLOR,'ycolor',AXISCOLOR);
  
  if get(wgts.OverlayCheck,'value') > 0,
    subDrawSlices(wgts,ONLINE.pvpar);
  end
  if get(wgts.CrosshairCheck,'value') > 0,
    tmph = [wgts.TraAxs, wgts.SagAxs, wgts.CorAxs];
    for N = 1:3,
      axes(tmph(N));
      line([tmpX(1) tmpX(end)],[0,0],'color',[0.9 0.9 0]);
      line([0 0],[tmpY(1) tmpY(end)],'color',[0.9 0.9 0]);
    end
  end
  
  set(allchild(wgts.CorAxs),...
      'ButtonDownFcn','monlinetripilot(''Main_Callback'',gcbo,''button-coronal'',guidata(gcbo))');
  set(allchild(wgts.SagAxs),...
      'ButtonDownFcn','monlinetripilot(''Main_Callback'',gcbo,''button-sagital'',guidata(gcbo))');
  set(allchild(wgts.TraAxs),...
      'ButtonDownFcn','monlinetripilot(''Main_Callback'',gcbo,''button-transverse'',guidata(gcbo))');
  
  
 
 case {'show-pvpar'}
  if ~strcmp(get(wgts.main,'SelectionType'),'open'), return;  end
  
  ONLINE = getappdata(wgts.main,'ONLINE');
  clear monilnepvpar;
  monlinepvpar(ONLINE,'hfig',gcf+100);
  return
  
 case {'button-sagital','button-coronal','button-axial','button-transverse'}
  click = get(wgts.main,'SelectionType');
  if strcmpi(click,'open'),
    % double click
    ONLINE = getappdata(wgts.main,'ONLINE');
    planestr = eventdata(8:end);  % ignoring 'button-'
    subZoomIn(planestr,wgts,ONLINE);
  end

 otherwise
  fprintf('WARNING %s: Main_Callback() ''%s'' not supported yet.\n',mfilename,eventdata);
end
  
return;
  
  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION to get screen size
function [scrW, scrH] = subGetScreenSize(Units)
oldUnits = get(0,'Units');
set(0,'Units',Units);
sz = get(0,'ScreenSize');
set(0,'Units',oldUnits);

scrW = sz(3);  scrH = sz(4);

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to zoom-in plot
function subZoomIn(planestr,wgts,SIG)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch lower(planestr)
 case {'coronal'}
  hfig = wgts.main + 1001;
  hsrc = wgts.CorAxs;
  DX = SIG.ds(1);  DY = SIG.ds(3);
  tmpstr = sprintf('CORONAL %s %d/%d',SIG.session,SIG.scanreco);
  tmpxlabel = 'X (mm)';  tmpylabel = 'Z (mm)';
 case {'sagital'}
  hfig = wgts.main + 1002;
  hsrc = wgts.SagAxs;
  DX = SIG.ds(2);  DY = SIG.ds(3);
  tmpstr = sprintf('SAGITAL %s %d/%d',SIG.session,SIG.scanreco);
  tmpxlabel = 'Y (mm)';  tmpylabel = 'Z (mm)';
 case {'transverse','axial'}
  hfig = wgts.main + 1003;
  hsrc = wgts.TraAxs;
  DX = SIG.ds(1);  DY = SIG.ds(2);
  tmpstr = sprintf('TRANSVERSE %s %d/%d',SIG.session,SIG.scanreco);
  tmpxlabel = 'X (mm)';  tmpylabel = 'Y (mm)';
end


figure(hfig);  clf;
set(hfig,'PaperPositionMode',	'auto');
set(hfig,'PaperOrientation', 'landscape');
set(hfig,'PaperType',			'A4');
pos = get(hfig,'pos');
pos = [pos(1)-(680-pos(3)) pos(2)-(500-pos(4)) 680 500];
% sometime, wiondow is outside the screen....why this happens??
[scrW scrH] = subGetScreenSize('pixels');
if pos(1) < -pos(3) | pos(1) > scrW,  pos(1) = 1;  end
if pos(2)+pos(4) < 0 | pos(2)+pos(4)+70 > scrH,  pos(2) = scrH-pos(4)-70;  end
set(hfig,'Name',tmpstr,'pos',pos);
haxs = copyobj(hsrc,hfig);
set(haxs,'ButtonDownFcn','');  % clear callback function
h = findobj(haxs,'type','image');
set(h,'ButtonDownFcn','');  % clear callback function

set(haxs,'Position',[0.13  0.11  0.775  0.815],'units','normalized');

xlabel(tmpxlabel);  ylabel(tmpylabel);
title(haxs,strrep(tmpstr,'_','\_'));
daspect(haxs,[1 1 1]);
pos = get(haxs,'pos');

%clear callbacks
set(haxs,'ButtonDownFcn','');
set(allchild(haxs),'ButtonDownFcn','');

% make font size bigger
set(haxs,'FontSize',10);
set(get(haxs,'title'),'FontSize',10);
set(get(haxs,'xlabel'),'FontSize',10);
set(get(haxs,'ylabel'),'FontSize',10);

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to draw slices
function subDrawSlices(wgts,PVPAR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% draw 'purple' slices

SlicesEdges = subGetSlicesEdges(PVPAR) ;
if isempty(SlicesEdges),  return;  end

axes(wgts.TraAxs);
if  0 == ishold() ;
    holdtemp = 0;
    hold on;
else
    holdtemp = 1 ;
end
subDrawIntersection(PVPAR, SlicesEdges ,3) ;
if holdtemp == 0
    hold off ;
end

axes(wgts.SagAxs);
if ishold == 0
    holdtemp = 0;
    hold on;
else
    holdtemp = 1 ;
end

subDrawIntersection(PVPAR, SlicesEdges ,1) ;
if holdtemp == 0
    hold off ;
end

axes(wgts.CorAxs);
if  0 == ishold() ;
    holdtemp = 0;
    hold on;
else
    holdtemp = 1 ;
end
subDrawIntersection(PVPAR, SlicesEdges ,2) ;
if holdtemp == 0
    hold off ;
end
  
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to draw the intersection of a slice with the dim-th dimension 
function RET = subGetSlicesEdges(PVPAR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% LIMITATIONS:
% At the moment, there is only axial slice orientation and rotation around
% the x-axis supported. TODO:
% 1. To which coordinates is the GradOrient-Matrix assigned to? Should be
% ok now for rotation around x-axis but not around y-axis.

%PVPAR.method.PVM_SPackArrSliceOrient = 'hihi'
if ~isequal(PVPAR.method.PVM_SPackArrSliceOrient,'axial')
    fprintf('WARNING %s: sorry, non-axial slice orientation is not supported yet.\n',mfilename)
    RET = [];
    return;
end

%Prepare the parameters to calculate the edges of the slice
if strcmp(PVPAR.method.PVM_SPackArrReadOrient,'L_R')
    r_1 = PVPAR.method.PVM_Fov(1)/2 ;
    r_2 = PVPAR.method.PVM_Fov(2)/2 ;
else
    r_1 = PVPAR.method.PVM_Fov(2)/2 ;
    r_2 = PVPAR.method.PVM_Fov(1)/2 ;
end
no_slices = PVPAR.method.PVM_SPackArrNSlices ;
thickness = PVPAR.method.PVM_SliceThick ;
distance  = PVPAR.method.PVM_SPackArrSliceDistance ;
%  alpha = 60*pi/180 ; % um y-Achse % for testing purposes only
%  betha = 30*pi/180 ; % um x-Achse % for testing purposes only
R = [ PVPAR.method.PVM_SPackArrGradOrient(1) PVPAR.method.PVM_SPackArrGradOrient(2) PVPAR.method.PVM_SPackArrGradOrient(3) ; ...
      PVPAR.method.PVM_SPackArrGradOrient(4) PVPAR.method.PVM_SPackArrGradOrient(5) PVPAR.method.PVM_SPackArrGradOrient(6) ; ...
      PVPAR.method.PVM_SPackArrGradOrient(7) PVPAR.method.PVM_SPackArrGradOrient(8) PVPAR.method.PVM_SPackArrGradOrient(9) ] ;
  
if R(2,3) >= 0 
    angle_x = acos( R(2,2) ) ;
else
    angle_x = 2*pi - acos( R(2,2) ) ;
end
% Check, if R is the expected kind of rotation around x-axis
U     = [1          0              0       ;
         0   cos(angle_x)  -sin(angle_x)   ;
         0   sin(angle_x)   cos(angle_x) ] ;
if ~isequal(U, R)
    error('Sorry, rotation around y-Axes is not supported yet.')
end
%    R = [ cos(alpha)     0      -sin(alpha)   % for testing purposes only
%          0              1       0
%          sin(alpha)     0       cos(alpha) ] %TEST-Parameter
%    T =[  1              0       0
%          0         cos(betha) -sin(betha)
%          0         sin(betha)  cos(betha) ] %TEST-Parameter
%      R = R *T ;
m_1 = -PVPAR.method.PVM_SPackArrPhase2Offset ;% Center of the Slice, first coordinate A_P, goes to Post, so positive
m_2 = -PVPAR.method.PVM_SPackArrPhase1Offset ;% Center of the Slice, first coordinate A_P, goes to Post, so positive
m_3 = -PVPAR.method.PVM_SPackArrSliceOffset ;% "Isodist H" in Paravision, Center of the Slice, second coordinate H_F, goes to Head, so negative

%Calculate the Center of the first slice
m = R * [ m_1 ; m_2 ; m_3 ] + (no_slices - 1)/2 * distance * R * [ 0 ; 0 ; 1 ] ;

%Calculate the vertices of first slice
K(:,1) = m  ...
    - r_1 * R * [ 1 ; 0 ; 0 ] ...
    - r_2 * R * [ 0 ; 1 ; 0 ] ...
    - thickness/2 * R * [ 0 ; 0 ; 1 ] ;
K(:,2) = m  ...
    - r_1 * R * [ 1 ; 0 ; 0 ] ...
    + r_2 * R * [ 0 ; 1 ; 0 ] ...
    - thickness/2 * R * [ 0 ; 0 ; 1 ] ;
K(:,3) = m  ...
    + r_1 * R * [ 1 ; 0 ; 0 ] ...
    + r_2 * R * [ 0 ; 1 ; 0 ] ...
    - thickness/2 * R * [ 0 ; 0 ; 1 ] ;
K(:,4) = m  ...
    + r_1 * R * [ 1 ; 0 ; 0 ] ...
    - r_2 * R * [ 0 ; 1 ; 0 ] ...
    - thickness/2 * R * [ 0 ; 0 ; 1 ] ;
K(:,5) = m  ...
    - r_1 * R * [ 1 ; 0 ; 0 ] ...
    - r_2 * R * [ 0 ; 1 ; 0 ] ...
    + thickness/2 * R * [ 0 ; 0 ; 1 ] ;
K(:,6) = m  ...
    - r_1 * R * [ 1 ; 0 ; 0 ] ...
    + r_2 * R * [ 0 ; 1 ; 0 ] ...
    + thickness/2 * R * [ 0 ; 0 ; 1 ] ;
K(:,7) = m  ...
    + r_1 * R * [ 1 ; 0 ; 0 ] ...
    + r_2 * R * [ 0 ; 1 ; 0 ] ...
    + thickness/2 * R * [ 0 ; 0 ; 1 ] ;
K(:,8) = m  ...
    + r_1 * R * [ 1 ; 0 ; 0 ] ...
    - r_2 * R * [ 0 ; 1 ; 0 ] ...
    + thickness/2 * R * [ 0 ; 0 ; 1 ] ;
% Put the vertices of first slice to Output-Parameter.
RET = zeros(no_slices,3,8) ;
RET(1,:,:) = [ K(:,1) K(:,2) K(:,3) K(:,4) K(:,5) K(:,6) K(:,7) K(:,8) ] ;

%Calculate the vertices of the other slices.
switch PVPAR.method.PVM_SPackArrSliceOrient
    case 'axial'
        move = R * [ 0 ; 0 ; -1 ] ;
    case 'sagital'
    case 'coronal'
end
for k = 2:no_slices   
    for l = 1:8
        K(:,l) = K(:,l) + distance * move ;
    end
    RET(k,:,:) = [ K(:,1) K(:,2) K(:,3) K(:,4) K(:,5) K(:,6) K(:,7) K(:,8) ] ; 
end
return ;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to draw the intersection of a slice with the dim-th dimension
% zero plane
function subDrawIntersection(PVPAR, K , dim)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Define the edges of a abstract slice by the vertices.
edge = [ [1 2] ;[2 3] ;[3 4] ;[4 1] ;[5 6] ;[6 7] ;[7 8] ;[8 5] ;[1 5] ;[2 6] ;[3 7] ;[4 8] ] ;

% Calculate the Points of intersection between the edges and the view.
for s_n = 1:PVPAR.method.PVM_SPackArrNSlices ;
    %S() = zeros(2,length(edge)) ;
    S = [] ;
    t = 1 ;
    for k = 1:length(edge) ;
        if K(s_n,dim,edge(k,1)) * K(s_n,dim,edge(k,2)) <= 0.0 &&  (K(s_n,dim,edge(k,1)) - K(s_n,dim,edge(k,2))) ~= 0 ;
            b = -K(s_n,dim,edge(k,1)) / (K(s_n,dim,edge(k,1)) - K(s_n,dim,edge(k,2))) ;
            S(:,t) = K(s_n,:,edge(k,1)) + b * (K(s_n,:,edge(k,1)) - K(s_n,:,edge(k,2))) ;
            t = t + 1 ;
        elseif K(s_n,dim,edge(k,2)) == 0 && K(s_n,dim,edge(k,1)) == 0
            S(:,t) = K(s_n,:,edge(k,1)) ;
            t = t + 1 ;
            S(:,t) = K(s_n,:,edge(k,2)) ;
            t = t + 1 ;
        end
    end
    if isempty(S)
        continue ;
    end

    % Sort out identical points of intersection.
    S = unique(S','rows')' ;
    
    % Throw away the needless dimension.
    switch dim ;
        case 1 ;
            size1 = 0 ;
            size2 = 2 ;
        case 2
            size1 = 1 ;
            size2 = 1 ;
        case 3
            size1 = 2 ;
            size2 = 0 ;
    end
    if size1 > 0
        Sn( 1:size1 , : ) = S( 1:dim-1 , : ) ;
    end
    if size2 > 0
        Sn(size1+1:size1+size2,:) = S(dim+1:end,:) ;
    end
    S = Sn ;
    Sn = [] ;

    % Sort the order of points of intersection.

    % Get the most left most low point of intersection to the first place.
    S = sortrows(S',1)' ;
    S = sortrows(S',-2)' ;
    
    Sn(:,1) = S(:,1) ;
    if size(S,1) > 1
        S = S(:,2:end) ;
        % Calculate for every other Point the radian between the second
        % coordinate and the straight line between this point and the first
        % point.
        for k = 1:length(S)
            a = S(2,k) - Sn(2,1) ;
            b = S(1,k) - Sn(1,1) ;
            c = sqrt(a*a + b*b)  ;
            if a > 0 && b >= 0 
                S(3,k) = acos(a/c) ;
            end
            if a <= 0 && b > 0 
                S(3,k) = acos(a/c) ;
            end
            if a < 0 && b <= 0 
                S(3,k) = 2*pi - acos(a/c) ;
            end
            if a >= 0 && b < 0 
                S(3,k) = 2*pi - acos(a/c) ;
            end
        end
        % Sort remaining points based on their radiant.
        S = sortrows(S',3)' ;
        % Get the remaining points in this order.
        for k = 1:length(S)
            Sn(:,k+1) = S(1:2,k) ;
        end
    end
    S = Sn ;
    Sn = [] ;
    
    %Plot the points of intersection.
    plot ( [S(1,:) S(1,1)], [S(2,:) S(2,1)] ) ;
    
end
return ;