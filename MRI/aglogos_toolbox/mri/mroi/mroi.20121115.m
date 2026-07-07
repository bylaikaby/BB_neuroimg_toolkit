function varargout = mroi(varargin)
%MROI - Utility to define Regions of Interests (ROIs)
% MROI(SESSION,GRPANME) permits the definition of multiple ROIs in arbitrarily
% selected slices. Full documentation of the program and description
% of the procedures to generate and use ROIs can be obtained by
% typing HROI.
%  
% TODO's
% ===============
% ** GETELEDIST get interelectrode distance from "ROI" file
%
%
% NOTES :
%   - Settings can be set by ANAP in the description file like
%     ANAP.colors = 'crgbkmy';
%     ANAP.gamma  = 1.8;
%   - Electrodes' position can be given in the description file.
%     GRPP.ele.mcoords(1,:) = [x y z];   % in EPI coodinates
%     GRPP.ele.mcoords(2,:) = [x y z];
%
% NOTES :
%  ROI structure will be like .... (updated 05.08.2005 YM)
%  RoiDef = 
%      session: 'm02lx1'
%      grpname: 'movie1'
%         exps: [1 16]
%      anainfo: {4x1 cell}
%     roinames: {7x1 cell}
%          dir: [1x1 struct]
%          dsp: [1x1 struct]
%          grp: [1x1 struct]
%          ana: [136x88x2 double]
%          img: [34x22x2 double]
%           ds: [0.7500 0.7500 2]
%           dx: 0.2500
%          roi: {1x14 cell}
%          ele: {[1x1 struct]  [1x1 struct]}
%
%  RoiDef.roi{1} = 
%         name: 'V1'
%        slice: 1
%           px: [7x1 double]
%           py: [7x1 double]
%         mask: [34x22 logical]
%
%  RoiDef.ele{1} = 
%          ele: 1
%        slice: 1
%         anax: 87.5456
%         anay: 73.5622
%            x: 22
%            y: 18
%
%  
%  VERSION
%    0.90 05.03.04 YM  pre-release, modified from Nikos's mroi.m.
%    1.00 09.03.04 NKL ROI & DEBUG
%    1.01 11.04.04 NKL
%    1.02 16.04.04 NKL Display Ana and tcImg
%    1.03 06.09.04 YM  bug fix on 'grproi-select' and Roi saving.
%    1.04 12.10.04 YM  supports zoom-in, bug fix on 'grp-select'.
%    1.05 23.11.04 YM  supports gamma setting, bug fix.
%    1.10 30.11.04 YM  supports corr.map if available.
%    1.11 29.05.05 YM  bug fix of 'sticky' mode.
%    1.12 30.05.05 YM  supports 'cursor' shape for roipoly.
%    1.13 06.06.05 YM  set .mask/.anamask as logical.
%    1.14 09.06.05 YM  supports 'AnaScale', bug fix on saving roi.anamask.
%    1.15 20.07.05 YM  supports 'DrawROI', bug fix.
%    1.20 05.08.05 YM  changed "Roi.roi" format, px/py is for funtional, not anatomy.
%    1.21 07.10.06 YM  does a simple motion correction if 'ImgDistort'.
%    1.22 15.11.06 YM  suppoprts the sama gamma value for all slices.
%    1.23 19.02.07 YM  suppoprts 'midline' and 'ant.commisure'
%    1.24 01.03.07 YM  now 'stat.map' as old 'corr.map'.
%    1.25 20.03.07 YM  fix upper/lower case between ses.roi.names and Roi.roi{X}.name.
%    1.26 02.04.07 YM  fix problem on group selection, colored stat.map.
%    1.27 10.12.07 YM  bug fix for MatLab 7.5, crash of roipoly().
%    1.28 07.03.08 YM  use roipoly of Matlab 7.1
%    1.29 30.05.08 YM  avoid crash on huge tcImg like i008c1
%    1.30 05.02.10 YM  supports 'LRline'
%    1.31 01.09.10 YM  control for drawing ROIs
%    1.32 28.10.10 BS  added atlas 
%    1.33 17.11.10 BS  improved atlas
%    1.34 30.11.10 BS  supports atlas_tform file
%    1.35 09.03.11 YM  redraw when RoiSelCmb, supports 'coordinate' in RoiActCmb.
%    1.36 27.12.11 YM  use strcmp() instead of strcmpi for roi-names.
%    1.37 21.01.12 YM  makes backup like Roi.yyyymmdd_HHMM.mat.
%    1.38 22.01.12 YM  supports "sulcus" as marker.
%    1.39 23.01.12 YM  supports "clear" for atlas-roi while keeping polygon-roi.
%    1.40 03.02.12 YM  use mroi_file()save() functions.
%    1.41 03.03.12 YM  use mroiatlas_tform.mat instead of atlas_tform.mat.
%    1.42 06.03.12 YM  supports 'erase' action and marker-size, epi-ana.
%    1.43 24.10.12 YM  supports 'undo' action.
%
%  See also HROI, MROISCT, MROIDSP, MROI_CURSOR, HIMGPRO, HHELP

persistent H_MROI;	% keep the figure handle.

if ~nargin,
  help mroi;
  return;
else
  if isfield(varargin{1},'name'),
    SESSION = varargin{1}.name;
  else
    SESSION = varargin{1};
  end
  if nargin > 1,  GrpExp = varargin{2};  end
end

% execute callback function then return;
if ischar(SESSION) && ~isempty(findstr(SESSION,'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return;
end

% prevent double execution
if ishandle(H_MROI),
  close(H_MROI);
end

% ====================================================================
% DISPLAY PARAMETERS FOR THE PLACEMENT OF AXIS ETC.
% ====================================================================
[scrW scrH] = getScreenSize('char');
figW        = 180.0;
figH        =  50.0;
figX        =   1.0;
figY        = scrH-figH-4;   % MUST BE "-4" for menu/title, need to avoid y-offset of roipoly()
IMGXOFS     = 3;
IMGYOFS     = figH * 0.11;
IMGYLEN     = figH * 0.68;
IMGXLEN     = figW * 0.47;
IMG2XOFS	= 2 * IMGXOFS + IMGXLEN;
TCPY        = 18;
TCPOFS      = 29;
FRPOFS      = 6;
XPLOT       = 97;
XPLOTLEN    = 75;

% ====================================================================
% CREATE THE MAIN WINDOW
% Reminder: get(0,'DefaultUicontrolBackgroundColor')
%    'Color', get(0,'DefaultUicontrolBackgroundColor'),...
% ====================================================================
hMain = figure(...
'Name',sprintf('MROI:'), ...
	'NumberTitle','off', ...
    'Tag','main', 'MenuBar', 'none', ...
    'HandleVisibility','on','Resize','on',...
    'DoubleBuffer','on', 'BackingStore','on','Visible','off',...
    'Units','char','Position',[figX figY figW figH],...
    'UserData',[figW figH],...
    'Color',[.85 .98 1],'DefaultAxesfontsize',10,...
    'DefaultAxesFontName', 'Comic Sans MS',...
    'DefaultAxesfontweight','bold');
H_MROI = hMain;
%[figX figY figW figH]
%set(hMain,'visible','on');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PULL-DOWN MENU [File Edit View Help]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- FILE
hMenuFile = uimenu(hMain,'Label','File');
uimenu(hMenuFile,'Label','Export as TIFF','Separator','off',...
       'Callback','mroi(''Print_Callback'',gcbo,''tiff'',[])');
uimenu(hMenuFile,'Label','Export as JPEG','Separator','off',...
       'Callback','mroi(''Print_Callback'',gcbo,''jpeg'',[])');
uimenu(hMenuFile,'Label','Export as Windows Metafile','Separator','off',...
       'Callback','mroi(''Print_Callback'',gcbo,''meta'',[])');
uimenu(hMenuFile,'Label','Page Setup...','Separator','on',...
       'Callback','mroi(''Print_Callback'',gcbo,''pagesetupdlg'',[])');
uimenu(hMenuFile,'Label','Print Setup...','Separator','off',...
       'Callback','mroi(''Print_Callback'',gcbo,''printdlg'',[])');
uimenu(hMenuFile,'Label','Print','Separator','off',...
       'Callback','mroi(''Print_Callback'',gcbo,''print'',[])');
uimenu(hMenuFile,'Label','Exit','Separator','on',...
       'Callback','mroi(''Main_Callback'',gcbo,''exit'',[])');
% --- EDIT
hMenuEdit = uimenu(hMain,'Label','Edit');
uimenu(hMenuEdit,'Label','mroi',...
       'Callback','edit ''mroi'';');
hCB = uimenu(hMenuEdit,'Label','mroi : Callbacks');
uimenu(hCB,'Label','Main_Callback',...
       'Callback','mroi(''Main_Callback'',gcbo,''edit-cb'',[])');
uimenu(hCB,'Label','Roi_Callback',...
       'Callback','mroi(''Main_Callback'',gcbo,''edit-cb'',[])');
uimenu(hCB,'Label','Print_Callback',...
       'Callback','mroi(''Main_Callback'',gcbo,''edit-cb'',[])');
uimenu(hMenuEdit,'Label','sescheck  : session checker',...
       'Callback','edit ''sescheck'';');
uimenu(hMenuEdit,'Label','Copy Figure','Separator','on',...
       'Callback','mroi(''Print_Callback'',gcbo,''copy-figure'',[])');
% --- FILE
hMenuView = uimenu(hMain,'Label','View');
uimenu(hMenuView,'Label','Figure Toolbar','Separator','off','Tag','MenuFigToolbar',...
       'Callback','mroi(''Main_Callback'',gcbo,''fig-toolbar'',[])');
% --- HELP
hMenuHelp = uimenu(hMain,'Label','Help');
uimenu(hMenuHelp,'Label','ROI','Separator','off',...
       'Callback','hroi');
uimenu(hMenuHelp,'Label','ROI Structure','Separator','off',...
       'Callback','hroistructure');
uimenu(hMenuHelp,'Label','roiTS Structure','Separator','off',...
       'Callback','hroitsstructure');

% ====================================================================
% DISPLAY NAMES OF SESSION/GROUP
% ====================================================================
H = figH - 2;
BKGCOL = get(hMain,'Color');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS H 20 1.5],...
    'String','Session: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
uicontrol(...
    'Parent',hMain,'Style','pushbutton',...
    'Units','char','Position',[IMGXOFS+12 H 25 1.5],...
    'String',SESSION,'FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left',...
    'Callback','mroi(''Main_Callback'',gcbo,''edit-group'',[])',...
    'ForegroundColor',[1 1 0.1],'BackgroundColor',[0 0.8 0]);
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+40 H 20 1.5],...
    'String','Group: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
GrpSelCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMGXOFS+50 H 36 1.5],...
    'String',{'Grp 1','Grp 2'},...
    'Callback','mroi(''Main_Callback'',gcbo,''grp-select'',[])',...
    'TooltipString','Group Selection',...
    'Tag','GrpSelCmb','FontWeight','Bold');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS H-2 12 1.5],...
    'String','ROI Set: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
GrpRoiSelCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMGXOFS+12 H-1.75 25 1.25],...
    'String',{'Roi 1','Roi 2'},...
    'Callback','mroi(''Main_Callback'',gcbo,''grproi-select'',[])',...
    'TooltipString','GrpRoi Selection',...
    'Tag','GrpRoiSelCmb','FontWeight','Bold');

% LOAD BUTTON - LOADS ROIs
RoiLoadBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[IMGXOFS+50 H-2 17 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''load-redraw'',guidata(gcbo))',...
    'Tag','RoiLoadBtn','String','LOAD',...
    'TooltipString','Load ROIs','FontWeight','bold');
%'ForegroundColor',[0 0 0],'BackgroundColor',[0 0 0.5]);

% SAVE BUTTON - Saves ROIs
RoiSaveBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[IMGXOFS+69 H-2 17 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''save'',guidata(gcbo))',...
    'Tag','RoiSaveBtn','String','SAVE',...
    'TooltipString','Save ROIs','FontWeight','bold');%,...
    %'ForegroundColor',[0.9 0.9 0],'BackgroundColor',[0 0 0.5]);



% ====================================================================
% Anatomy/Display settings, gamma etc.
% ====================================================================
XDSP = IMG2XOFS;  HY = figH - 6;
% Gamma setting to displaying anatomy
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP HY 30 1.25],...
    'String','AnaGamma: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
GammaEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+15 HY 7 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''set-gamma'',guidata(gcbo))',...
    'String','Gamma','Tag','GammaEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','set a gamma value for image',...
    'FontWeight','bold','BackgroundColor','white');
GammaHoldCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+22 HY 25 1.5],...
    'Tag','GammaHoldCheck','Value',1,...
    'Callback','mroi(''Main_Callback'',gcbo,''imgdraw'',[])',...
    'String','Hold','FontWeight','bold',...
    'TooltipString','hold gamma for all slices','BackgroundColor',get(hMain,'Color'));

% CLim setting for display
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+33 HY 30 1.25],...
    'String','AnaScale: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
AnaScaleEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+46 HY 15 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''imgdraw'',[])',...
    'String','firsttime','Tag','AnaScaleEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','set scaling for anatomy',...
    'FontWeight','bold','BackgroundColor','white');
% AutoScale button - If checked "clim" became "auto"
AutoAnaScaleCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+61.5 HY 25 1.5],...
    'Tag','AutoAnaScale','Value',0,...
    'Callback','mroi(''Main_Callback'',gcbo,''imgdraw'',[])',...
    'String','Auto','FontWeight','bold',...
    'TooltipString','Automatic scaling','BackgroundColor',get(hMain,'Color'));

% EPI ana
EpiAnaCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+74 HY 25 1.5],...
    'Tag','EpiAnaCheck','Value',0,...
    'Callback','mroi(''Main_Callback'',gcbo,''epi-ana'',[])',...
    'String','EpiAna','FontWeight','bold',...
    'TooltipString','use EPI as anatomy','BackgroundColor',get(hMain,'Color'));



% ====================================================================
% ROI CONTROL
% ====================================================================
XDSP = IMGXOFS;
H = figH-8;%IMGYOFS + IMGYLEN + 0.6;
% COMBO : ROI selecton
RoiSelCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[XDSP H 19 1.5],...
    'String',{'Roi1','Roi2'},...
    'Callback','mroi(''Main_Callback'',gcbo,''roi-select-redraw'',[])',...
    'TooltipString','ROI selection',...
    'Tag','RoiSelCmb','FontWeight','Bold');
% COMBO : ROI action
ActCmd = {'No Action','Find','UNDO','Coordinate','Append','Replace',...
          'Add bitmap','Erase bitmap','Electrodes',...
          'Reset CURSOR',...
          'Clear','Clear All Slices',...
          'Clear All in the Slice','Clear Others in the slice',...
          'Clear electrodes',...
          'Clear Bitmap', 'Clear All Slices (Bitmap)',...
          'Clear midline','Clear ant.commisure','Clear LR-Separate','COMPLETE CLEAR'};
RoiActCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[XDSP+21 H 25 1.5],...
    'String',ActCmd,...
    'Callback','mroi(''Roi_Callback'',gcbo,''roi-action'',[])',...
    'TooltipString','ROI action',...
    'Tag','RoiActCmb','FontWeight','Bold');

MarkerCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+57 H+2 12 1.5],...
    'Tag','MarkerCheck','Value',1,...
    'String','','FontWeight','bold',...
    'Callback','mroi(''Marker_Callback'',gcbo,''marker-show'',[])',...
    'TooltipString','show markers','BackgroundColor',get(hMain,'Color'));
MarkerCmd = {'Sulcus',...
             'lus','ios','sts','ls','ips','cs','as','ps',...
             'cas','pos','apos','cgs',...
             'ots','pmts','amts','rs',...
             'clear' 'COMPLETE CLEAR'};
MarkerActCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[XDSP+61 H+2 25 1.5],...
    'String',MarkerCmd,...
    'Callback','mroi(''Marker_Callback'',gcbo,''marker-action'',[])',...
    'TooltipString','Marker action',...
    'Tag','MarkerActCmb','FontWeight','Bold');


% STICKY BUTTON - IF SET APPEND IS STICKY AND SLICE ADVANCES
StickyCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+40 H+2 12 1.5],...
    'Tag','Sticky','Value',0,...
    'String','Sticky','FontWeight','bold',...
    'TooltipString','Append-Advance-Slice','BackgroundColor',get(hMain,'Color'));
% COMBO : ROI draw
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+49 H 12 1.25],...
    'String','DrawROI: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
RoiDrawCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[XDSP+61 H 25 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''roidraw-ana'',[])',...
    'Tag','RoiDrawCmb','Value',1,...
    'String',{'all' 'all ROIs' 'all polygons' 'current' 'markers' 'none'},'FontWeight','bold',...
    'TooltipString','Draw ROI-polygon');
RoiDrawEpiCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMG2XOFS H 25 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''roidraw-epi'',[])',...
    'Tag','RoiDrawEpiCmb','Value',1,...
    'String',{'all' 'all ROIs' 'all polygons' 'current' 'markers' 'none'},'FontWeight','bold',...
    'TooltipString','Draw ROI-polygon');
% Marker size for ROI(bitmap)
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMG2XOFS+36 H 20 1.25],...
    'String','MarkerSize: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
MarkerSizeEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMG2XOFS+51 H 10 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''redraw'',[])',...
    'String','1.5','Tag','MarkerSizeEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','set marker-size',...
    'FontWeight','bold');


% ====================================================================
% Cursor setting for ROIPOLY
% ====================================================================
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H+2 12 1.25],...
    'String','Pointer: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
RoiCursorCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[XDSP+12 H+2 25 1.5],...
    'String',{'crosshair','black dot','white dot','circle','cross','fluer','fullcross','ibeam','arrow'},...
    'TooltipString','ROIPOLY pointer',...
    'Tag','RoiCursorCmb','Value',3,'FontWeight','Bold');

% ====================================================================
% AXES for plots, image and ROIs
% ====================================================================
% ANATOMY-IMAGE-ROI AXIS
AxsFrame = axes(...
    'Parent',hMain,'Units','char','color',get(hMain,'color'),'xtick',[],...
    'ytick',[],'Position',[IMGXOFS IMGYOFS IMGXLEN+1 IMGYLEN],...
    'Box','on','linewidth',3,'xcolor','r','ycolor','r',...
	'ButtonDownFcn','mroi(''Main_Callback'',gcbo,''zoomin-ana'',[])',...
    'color',[0 0 .2]);
ImageAxs = axes(...
    'Parent',hMain,'Tag','ImageAxs',...
    'Units','char','Color','k','layer','top',...
    'Position',[IMGXOFS+2 IMGYOFS+1.7 IMGXLEN*.95 IMGYLEN*.85],...
    'xticklabel','','yticklabel','','xtick',[],'ytick',[]);
% EPI-IMAGE-ROI AXIS
Axs2Frame = axes(...
    'Parent',hMain,'Units','char','color',get(hMain,'color'),'xtick',[],...
    'ytick',[],'Position',[IMG2XOFS IMGYOFS IMGXLEN+1 IMGYLEN],...
    'Box','on','linewidth',3,'xcolor','r','ycolor','r',...
	'ButtonDownFcn','mroi(''Main_Callback'',gcbo,''zoomin-func'',[])',...
    'color',[0 0 .2]);
% W/out BAR 'Position',[IMG2XOFS+2 IMGYOFS+1 IMGXLEN*.95 IMGYLEN*.85],...
Image2Axs = axes(...
    'Parent',hMain,'Tag','Image2Axs',...
    'Units','char','Color','k','layer','top',...
    'Position',[IMG2XOFS+2 IMGYOFS+1.7 IMGXLEN*.9 IMGYLEN*.85],...
    'xticklabel','','yticklabel','','xtick',[],'ytick',[]);


AnaTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+4 figH-12.5 18 1.25],...
    'tag','AnaTxt','String','ANA :','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'foregroundcolor',[0.8 0.8 0],'BackgroundColor',[0 0 .2]);



% ====================================================================
% Statistical.Map (Optional)
% ====================================================================
XDSP = IMG2XOFS + 3;  HY = figH - 2;
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP HY 12 1.25],...
    'String','Stat Map: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
StatMapCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[XDSP+14 HY 25 1.5],...
    'String',{'none'},...
    'Callback','mroi(''Main_Callback'',gcbo,''imgdraw'',[])',...
    'TooltipString','Stat Map Selection',...
    'Tag','StatMapCmb','FontWeight','Bold');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+42 HY 12 1.25],...
    'String','V-Thr: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
StatVThrEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+50 HY 10 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''imgdraw'',guidata(gcbo))',...
    'String','10','Tag','StatVThrEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','set threshold for stat.map',...
    'FontWeight','bold','BackgroundColor','white');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+62 HY 12 1.25],...
    'String','P-Thr: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
StatPThrEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+70 HY 12 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''imgdraw'',guidata(gcbo))',...
    'String','0.1','Tag','StatPThrEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','set threshold for stat.map',...
    'FontWeight','bold','BackgroundColor','white');
BonferroniCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+67 HY-2 30 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''imgdraw'',guidata(gcbo))',...
    'Tag','BonferroniCheck','Value',0,...
    'String','Bonferroni','FontWeight','bold',...
    'TooltipString','Bonferroni correction','BackgroundColor',get(hMain,'Color'));





% ====================================================================
% FUNCTION BUTTONS FOR IMAGE AND TIME-SERIES PROCESSING
% ====================================================================
% XDSP = IMG2XOFS + 41;
% HY = figH-8;%IMGYOFS + IMGYLEN + 0.6;
imgpro = {'mean','median','max','min','std','Std(Stim)','cv','T0','Tend'};
% uicontrol(...
%     'Parent',hMain,'Style','Text',...
%     'Units','char','Position',[XDSP HY 18 1.25],...
%     'String','Image Process: ','FontWeight','bold',...
%     'HorizontalAlignment','left','fontsize',9,...
%     'BackgroundColor',BKGCOL);
% ImgProcCmb = uicontrol(...
%     'Parent',hMain,'Style','popupmenu',...
%     'Units','char','Position',[XDSP+20 HY 25 1.5],...
%     'String',imgpro,...
%     'Callback','mroi(''Main_Callback'',gcbo,''imgproc-select'',[])',...
%     'TooltipString','GrpRoi Selection',...
%     'Tag','ImgProcCmb','FontWeight','Bold');

uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMG2XOFS+60 figH-12.5 18 1.25],...
    'String','EPI :','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'foregroundcolor',[0.8 0.8 0],'BackgroundColor',[0 0 .2]);
ImgProcCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMG2XOFS+67 figH-12.5 17 1.5],...
    'String',imgpro,...
    'Callback','mroi(''Main_Callback'',gcbo,''imgproc-select'',[])',...
    'TooltipString','GrpRoi Selection',...
    'Tag','ImgProcCmb','FontWeight','Bold');



% ====================================================================
% SLICE SELECTION SLIDER
% ====================================================================
% LABEL : Slice X
SliceBarTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS 2.5 15 1.5],...
    'String','Slice : 1','FontWeight','bold','FontSize',10,...
    'HorizontalAlignment','left','Tag','SliceBarTxt',...
    'BackgroundColor',get(hMain,'Color'));
SliceBarSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[IMGXOFS+16 2.6 158 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''slice-slider'',[])',...
    'Tag','SliceBarSldr','SliderStep',[1 4],...
    'TooltipString','Set current slice');

% ====================================================================
% STATUS LINE: 
% ====================================================================
StatusCol = [.92 .96 .94];
StatusFrame = axes(...
    'Parent',hMain,'Units','char','color',get(hMain,'color'),'xtick',[],...
    'ytick',[],'Position',[IMGXOFS 0.35 174 1.8],...
    'Box','on','linewidth',1,'xcolor','k','ycolor','k',...
    'color',StatusCol);
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+2 0.45 11 1.5],...
    'String','Status :','FontWeight','bold','fontsize',10,...
    'HorizontalAlignment','left','ForegroundColor','r',...
    'BackgroundColor',StatusCol);
StatusField = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+16 0.55 145 1.2],...
    'String','Normal','FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left','Tag','StatusField',...
    'ForegroundColor','k','BackgroundColor',StatusCol);

% ====================================================================
% ATLAS: 
% ====================================================================
XDSP = IMGXOFS;
H = figH-10;

uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H 8 1.25],...
    'String','Atlas:','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
AtlasCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[XDSP+9 H 25 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''edit-atlas'',[])',...
    'String',{'Hor DV','Hor VD','Cor AP','Cor PA'},...
    'TooltipString','Atlas Orientation',...
    'Tag','AtlasCmb','Value',1,'FontWeight','Bold');

uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+37 H 6 1.25],...
    'String','slice: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
AtlasSliceBarSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[XDSP+44 H 15 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''atlslice-slider'',[])',...
    'Tag','AtlasSliceBarSldr','SliderStep',[1 4],...
    'Max',100,'Min',-100,'Value',1,...
    'TooltipString','Set current atlas slice');
AtlasSlice = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+60 H 7 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''edit-atlslice'',[])',...
    'String','inactive','Tag','AtlasSlice',...
    'HorizontalAlignment','left',...
    'TooltipString','Atlas slice',...
    'FontWeight','bold','BackgroundColor','white');

uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+70 H 30 1.25],...
    'String','crop (mm): ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
AtlasCropEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+84, H 25 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''edit-atlcrop'',[])',...
    'String','inactive','Tag','AtlasCropEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','set crop for Atlas',...
    'FontWeight','bold','BackgroundColor','white');
crophelp=uicontrol(...
    'Parent',hMain,'Style','pushbutton',...
    'Units','char','Position',[XDSP+110, H 12 1.5],...
    'String','CropGUI','FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left',...
    'Tag','crophelp',...
    'Callback','mroi(''Main_Callback'',gcbo,''edit-atlcrop2'',[])');

uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+IMG2XOFS+39 H 15 1.25],...
    'String','rotate:','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
AtlasRotEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+IMG2XOFS+48, H 10 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''imgdraw'',[])',...
    'String','inactive','Tag','AtlasRotate',...
    'HorizontalAlignment','left',...
    'TooltipString','rotate atlas',...
    'FontWeight','bold','BackgroundColor','white');

OverlayCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[figW-22 H 20 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''imgdraw'',[])',...
    'Tag','OverlayCheck','Value',0,...
    'String','AtlasOverlay','FontWeight','bold',...
    'TooltipString','Activate Atlas overlay','BackgroundColor',get(hMain,'Color'));



% ====================================================================
% INITIALIZE THE APPLICATION.
% ====================================================================
MAPCOLORS = 'cywgmrbkcywgmrbk';
COLORS = 'crgbkmy';
GAMMA = 1.8;

% Code change Bernd Schaffeld 13.08.10
% old: ses = goto(SESSION);
% new:
  if isfield(varargin{1},'name'),
    ses=goto(varargin{1});
  else
    ses=goto(SESSION);
  end

grps = getgroups(ses);


% SELECT GROUPS HAVING DIFFERENT ROI-DEFINITION-REQUIREMENTS
DoneGroups = {};
ToDoGroups = {};
K=0;
for GrpNo = 1:length(grps),
  if ~isimaging(ses,grps{GrpNo}.name),  continue;  end
  if ~isfield(grps{GrpNo},'grproi') || isempty(grps{GrpNo}.grproi),
	grps{GrpNo}.grproi = 'RoiDef';
  end;
  ToDoGroups{end+1} = grps{GrpNo}.name;
%   if isempty(DoneGroups) | ...
%  		~any(strcmp(DoneGroups,grps{GrpNo}.grproi)),
%  	K=K+1;
%  	DoneGroups{K} = grps{GrpNo}.grproi;
%  	ToDoGroups{K} = grps{GrpNo}.name;
%   end;
end;
GrpNames = getgrpnames(ses);
GrpNames = ToDoGroups;

% NOW WE HAVE THE GROUPS REQURING DIFFERENT ROI-DEFINITIONS
% THIS MAY HAPPEN WHEN THE ANIMAL'S POSITION IS CHANGED DURING THE
% EXPERIMENT.
% WE SAVE THE NAMES OF THE ROIS OF EACH SUCH GROUP IN GRPROINAMES
for N=1:length(GrpNames),
  grp = getgrpbyname(ses,GrpNames{N});
  GrpRoiNames{N} = grp.grproi;
end;

% GET DEFAULT GROUP NAME IF NONE IS DEFINED
if ~exist('GrpExp'),
  GrpExp = GrpNames{1};
end;

% AND ALSO THE ROI NAME FOR THIS GROUP
grp = getgrpbyname(ses,GrpExp);
if isnumeric(GrpExp),
  ExpNo = GrpExp(1);
else
  ExpNo = grp.exps(1);
end
anap = getanap(ses,ExpNo);
wgts = guihandles(hMain);
idx = find(strcmp(GrpNames,grp.name));
if isempty(idx),  idx = 1;  end
set(wgts.GrpSelCmb,'String',GrpNames,'Value',idx);
set(wgts.GrpRoiSelCmb,'String',GrpRoiNames,'Value',1);
clear idx;


if isfield(anap,'mroi')
  if isfield(anap.mroi,'colors'),
    COLORS = anap.mroi.colors;
  end
  if isfield(anap.mroi,'mapcolors'), 
    MAPCOLORS = anap.mroi.mapcolors;
  end
  if isfield(anap.mroi,'gamma'),
    GAMMA = anap.mroi.gamma;
  end

  %check if anap.mori.atlas is present and set the values, values not set
  %will get defaults
  if isfield(anap.mroi,'atlas') && ~isempty(anap.mroi.atlas),
    if isfield(anap.mroi.atlas,'set')
      switch lower(anap.mroi.atlas.set)
       case 'hor dv'
        set(wgts.AtlasCmb,'Value',1);
       case 'hor vd'
        set(wgts.AtlasCmb,'Value',2);
       case 'cor ap'
        set(wgts.AtlasCmb,'Value',3);
       case 'cor pa'
        set(wgts.AtlasCmb,'Value',4);
       case { 'mroiatlas_tform.mat'  'atlas_tform.mat' 'mat' 'tform' }
        set(wgts.AtlasCmb,'String',{'Hor DV','Hor VD','Cor AP','Cor PA','Atlas_tform.mat'});
        set(wgts.AtlasCmb,'Value',5);
       otherwise
        set(wgts.AtlasCmb,'Value',1);
      end
    else
      set(wgts.AtlasCmb,'Value',1); 
    end
    if isfield(anap.mroi.atlas,'slice')
      if length(anap.mroi.atlas.slice)>1 %if slices are given as a vector
        set(wgts.AtlasSlice,'String',num2str(anap.mroi.atlas.slice(1)))
        setappdata(hMain,'atlslice',anap.mroi.atlas.slice)
      else
        set(wgts.AtlasSlice,'String',num2str(anap.mroi.atlas.slice))
        setappdata(hMain,'atlslice',anap.mroi.atlas.slice)
      end
    else
      set(wgts.AtlasSlice,'String',num2str(7))
      setappdata(hMain,'atlslice',7)
    end

    if isfield(anap.mroi.atlas,'imgcrop')
      if iscell(anap.mroi.atlas.imgcrop)
        imgcropmat=reshape([anap.mroi.atlas.imgcrop{:}],[4 length(anap.mroi.atlas.imgcrop)])';
        set(wgts.AtlasCropEdt,'String',num2str(imgcropmat(1,:),'%g   '))
        setappdata(hMain,'atlimgcrop',imgcropmat)
      else
        set(wgts.AtlasCropEdt,'String',num2str(anap.mroi.atlas.imgcrop,'%g   '))
        setappdata(hMain,'atlimgcrop',num2str(anap.mroi.atlas.imgcrop,'%g   '))
      end
    else
      set(wgts.AtlasCropEdt,'String',num2str([1 1 1 1],'%g   '))
      setappdata(hMain,'atlimgcrop',num2str([1 1 1 1],'%g   '))
    end

    %if isfield(anap.mroi.atlas,'imgscale')
    %  set(wgts.AtlasScaleEdt,'String',num2str(anap.mroi.atlas.imgscale))
    %else
    %  set(wgts.AtlasScaleEdt,'String','auto')
    %end
          
    if isfield(anap.mroi.atlas,'overlay')
      set(wgts.OverlayCheck,'Value',anap.mroi.atlas.overlay)
    else
      set(wgts.OverlayCheck,'Value',0)
    end

    if isfield(anap.mroi.atlas,'rotate')
      if length(anap.mroi.atlas.rotate)>1 %if rotate is given as a vector
        set(wgts.AtlasRotate,'String',num2str(anap.mroi.atlas.rotate(1)))
        setappdata(hMain,'atlrotate',anap.mroi.atlas.rotate)
      else
        set(wgts.AtlasRotate,'String',num2str(anap.mroi.atlas.rotate))
        setappdata(hMain,'atlrotate',anap.mroi.atlas.rotate)
      end
    else
      set(wgts.AtlasRotate,'String','0')
      setappdata(hMain,'atlrotate','0')
    end
    fpath = fileparts(fileparts(mfilename('fullpath')));
    atlasfile=fullfile(fpath,'mroiatlas/atlas_data/atlas_saleem.mat'); %locate atlas
    Atlas=load(atlasfile); %load atlas
    clear fpath;
    
    
    % backward compatibility...
    if exist('./atlas_tform.mat','file'),
      srcfile = fullfile(pwd,'atlas_tform.mat');
      dstfile = fullfile(pwd,'mroiatlas_tform.mat');
      movefile(srcfile,dstfile,'f');
      clear srcfile dstfile;
    end
    
    %try to load transformed atlas
    if exist(fullfile(pwd,'mroiatlas_tform.mat'),'file'),
      vname = sprintf('%s_atlasimg',strrep(grp.grproi,'_atlas',''));
      Atlastform = load(fullfile(pwd,'mroiatlas_tform.mat'),vname);
      if isfield(Atlastform,vname),
        set(wgts.AtlasCmb,'String',{'Hor DV','Hor VD','Cor AP','Cor PA','Atlas_tform.mat'});
        set(wgts.AtlasCmb,'Value',5);
        Atlas.Roidef_atlas = Atlastform.(vname);
      end
      clear Atlastform vname;
    end
    setappdata(hMain,'Atlas',Atlas);
  else
    set(wgts.OverlayCheck,'Enable','off');
    set(wgts.AtlasCropEdt,'Enable','off');
    set(wgts.AtlasSlice,'Enable','off');
    set(wgts.AtlasCmb,'Enable','off');
    set(wgts.crophelp,'Enable','off');
    set(wgts.AtlasSliceBarSldr,'Enable','off');
    set(wgts.OverlayCheck,'Value',0);
    set(wgts.AtlasRotate,'Enable','off');
  end
else
    %need that because the slider throws warning otherwise
    set(wgts.OverlayCheck,'Enable','off');
    set(wgts.AtlasCropEdt,'Enable','off');
    set(wgts.AtlasSlice,'Enable','off');
    set(wgts.AtlasCmb,'Enable','off');
    set(wgts.crophelp,'Enable','off');
    set(wgts.AtlasSliceBarSldr,'Enable','off');
    set(wgts.OverlayCheck,'Value',0);
    set(wgts.AtlasRotate,'Enable','off');
end


setappdata(hMain,'Ses',ses);
setappdata(hMain,'ExpNo',ExpNo);
setappdata(hMain,'Grp',grp);
setappdata(hMain,'COLOR',COLORS);
setappdata(hMain,'MAPCOLOR',MAPCOLORS);
setappdata(hMain,'GAMMA',GAMMA);
setappdata(hMain,'StatMap',[]);
setappdata(hMain,'CurOp', 'mean');

mroi('Main_Callback',hMain,'init');
set(hMain,'Visible','on');

if nargout, varargout{1} = hMain;  end
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN CALLBACK
function Main_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
funcname = mfilename('fullpath');
[ST, I] = dbstack;
n = findstr(ST(I).name,'(');
if any(n),
cbname = ST(I).name(n+1:end-1);
else
cbname = ST(I).name;
end

wgts = guihandles(hObject);
ses = getappdata(wgts.main,'Ses');
grp = getappdata(wgts.main,'Grp');
curImg = getappdata(wgts.main,'curImg');
curanaImg = getappdata(wgts.main,'curanaImg');
COLORS = getappdata(wgts.main,'COLOR');
MAPCOLORS = getappdata(wgts.main,'MAPCOLOR');
GAMMA = getappdata(wgts.main,'GAMMA');


%fprintf('%s: eventdata=''%s''\n',gettimestring,eventdata);

switch lower(eventdata),
 case {'init'}
  % CHANGE 'UNITS' OF ALL WIDGETS FOR SUCCESSFUL PRINT
  % the following is as dirty as it can be... but it allows
  % rescaling and also correct printing... leave it so, until you
  % find a better solution!
  handles = findobj(wgts.main);
  for N=1:length(handles),
    try
      set(handles(N),'units','normalized');
    catch
    end
  end
  % DUE TO BUG OF MATLAB 7.5, 'units' for figure must be 'pixels'
  % otherwise roipoly() will crash.
  set(wgts.main,'units','pixels');
  
  % re-evaluate session/group info.

  % Code change Bernd Schaffeld 16.08.10
  %ses = getses(ses.name);

  grp = getgrp(ses,grp.name);
  anap = getanap(ses,grp);
  setappdata(wgts.main,'Ses',ses);
  setappdata(wgts.main,'Grp',grp);
  
  % INITIALIZE WIDGETS
  set(wgts.RoiSelCmb,'String',ses.roi.names,'Value',1);
  
  % ---------------------------------------------------------------------
  % LOAD FUNCTIONAL SCAN (average or single-experiment)
  % ---------------------------------------------------------------------
  %if ismanganese(grp) && exist('tcImg.mat','file') && ~isempty(who('-file','tcImg.mat',grp.name)),
  %  fname = 'tcImg.mat';
  %  tcImg = load(fname,grp.name);
  %  tcImg = tcImg.(grp.name);
  %  StatusPrint(hObject,cbname,'tcImg is group %s of "tcImg.mat"',grp.name);
  %else
    ExpNo = getappdata(wgts.main,'ExpNo');
    if ~any(grp.exps == ExpNo),
      ExpNo = grp.exps(1);
      setappdata(wgts.main,'ExpNo',ExpNo);
    end
    if isfield(anap,'mareats') && isfield(anap.mareats,'USE_REALIGNED') && ~any(anap.mareats.USE_REALIGNED),
      fname = sigfilename(ses,ExpNo,'tcImg.bak');
      if exist(fname,'file'),
        tcImg = sigload(ses,ExpNo,'tcImg.bak');
      else
        fname = sigfilename(ses,ExpNo,'tcImg');
        tcImg = sigload(ses,ExpNo,'tcImg');
      end
    else
      fname = sigfilename(ses,ExpNo,'tcImg');
      tcImg = sigload(ses,ExpNo,'tcImg');
    end
    if isstruct(tcImg) && ~isfield(tcImg,'stm'),
      fprintf('MROI: No stm-field was found! Check dgz/session files\n');
      keyboard;
    end;
    if iscell(tcImg) && ~isfield(tcImg{1},'stm'),
      fprintf('MROI: No stm-field was found! Check dgz/session files\n');
      keyboard;
    end;
    
    StatusPrint(hObject,cbname,'tcImg loaded from "%s"',fname);
  %end
  % adds Z resolution, if needed.
  if length(tcImg.ds) < 3,
    tmppar = expgetpar(ses,grp.name);
    tcImg.ds(3) = tmppar.pvpar.slithk;
    clear tmppar;
  end
  
  curImg = tcImg;
  if size(curImg.dat,4) > 1,
    % checks centroid and average only stable images
    curImg = subDoCentroidAverage(curImg);
  end
  tcImg.ana = curImg.dat;  % keep the averaged one as epi-anatomy
  setappdata(wgts.main,'tcImg',tcImg);
  setappdata(wgts.main,'curImg',curImg);

  % ---------------------------------------------------------------------
  % LOAD ANATOMY
  % ---------------------------------------------------------------------
  if isfield(anap,'ImgDistort') && anap.ImgDistort,
    anaImg = tcImg;
    anaImg.method = 'epi';
    if size(anaImg.dat,4) > 1,
      % checks centroid and average only stable images
      anaImg = subDoCentroidAverage(anaImg);
    end
  elseif ~isfield(grp,'ana') || isempty(grp.ana),
    anaImg = tcImg;
    anaImg.method = 'epi';
    if size(anaImg.dat,4) > 1,
      % checks centroid and average only stable images
      anaImg = subDoCentroidAverage(anaImg);
    end
  else
    if sesversion(ses) >= 2,
      AnaFile = sigfilename(ses,grp.ana{2},grp.ana{1});
      if exist(AnaFile,'file'),
        anaImg = load(AnaFile,grp.ana{1});
        anaImg = anaImg.(grp.ana{1});
      else
      AnaFile = strrep(AnaFile,pwd,'');
      StatusPrint(hObject,cbname,'"%s" not found, run "sesascan"',AnaFile);
      return;
      end
    else
      AnaFile = sprintf('%s.mat',grp.ana{1});
      if exist(AnaFile,'file') && ~isempty(who('-file',AnaFile,grp.ana{1})),
        anaImg = load(AnaFile,grp.ana{1});
        anaImg = anaImg.(grp.ana{1}){grp.ana{2}};
      else
        StatusPrint(hObject,cbname,'"%s" not found, run "sesascan"',AnaFile);
        return;
      end
    end
    
    % We use to keep all slices and select the appropriate ones in
    % the 'imgdraw' case, but the line:
    % mroidsp(curanaImg.dat(:,:,grp.ana{3}(SLICE)));
    % Now this step is eliminated. We choose the appropriate
    % slices right here.
    if ~isempty(grp.ana{3}),
      anaImg.dat = anaImg.dat(:,:,grp.ana{3});
    end
    anaImg.method = sprintf('%s {%d}',grp.ana{1},grp.ana{2});
  end
  
  curanaImg = anaImg;
  setappdata(wgts.main,'anaImg',anaImg);
  setappdata(wgts.main,'curanaImg',curanaImg);
  set(wgts.AnaTxt,'String',upper(curanaImg.method));
  
  % set color scaling for anatomy
  %%% AnaScale = [min(curanaImg.dat(:)) max(curanaImg.dat(:))*0.8]; -- NKL 27.09.06
  AnaScale = [min(curanaImg.dat(:)) max(curanaImg.dat(:))];
  set(wgts.AnaScaleEdt,'String',sprintf('%g  %g',AnaScale(1),AnaScale(2)));
  setappdata(wgts.main,'AnaScale',AnaScale);

  % set dimensional info.
  IMGDIMS.ana     = [size(curanaImg.dat,1), size(curanaImg.dat,2)];
  if ~isfield(anap,'ImgDistort'),
    anap.ImgDistort = 0;
  end
  if anap.ImgDistort == 0 && isfield(grp,'ana') && ~isempty(grp.ana),
    if length(ses.ascan.(grp.ana{1})) >= grp.ana{2},
      IMGDIMS.anaorig = ses.ascan.(grp.ana{1}){grp.ana{2}}.imgcrop(3:4);
    else
      IMGDIMS.anaorig = IMGDIMS.ana;
    end
  else
    IMGDIMS.anaorig = ones(size(IMGDIMS.ana));
  end
  IMGDIMS.epi     = [size(tcImg.dat,1), size(tcImg.dat,2)];
  IMGDIMS.pxscale = size(tcImg.dat,1)/size(curanaImg.dat,1);
  IMGDIMS.pyscale = size(tcImg.dat,2)/size(curanaImg.dat,2);
  setappdata(wgts.main,'IMGDIMS',IMGDIMS);


  % ---------------------------------------------------------------------
  % LOAD STAT.MAP if available.
  % ---------------------------------------------------------------------
  roiTs = {};  StatMap = [];
  if exist('mroistat.mat','file') && ~isempty(who('-file','mroistat.mat',grp.name)),
    roiTs = load('mroistat.mat',grp.name);
    roiTs = roiTs.(grp.name);
  elseif exist('allcorr.mat','file') && ~isempty(who('-file','allcorr.mat',grp.name)),
    % for compatibility for manganese stuff
    roiTs = load('allcorr.mat',grp.name);
    roiTs = roiTs.(grp.name);
    for N = 1:length(roiTs),
    end
    for N = 1:length(roiTs),
      for K = 1:length(roiTs{N}.modelname),
        roiTs{N}.modelname{K} = sprintf('corr %s',roiTs{N}.modelname{K});
      end
      if ~isfield(roiTs{N},'statv'),
        roiTs{N}.statv = roiTs{N}.r;
        roiTs{N} = rmfield(roiTs{N},'r');
      end
    end
  end
  if ~isempty(roiTs),
    modelname = {'none','all'};
    modelname(3:length(roiTs{1}.modelname)+2) = roiTs{1}.modelname;
    set(wgts.StatMapCmb,'String',modelname);
    set(wgts.StatMapCmb,'Value',1);
    set(wgts.StatMapCmb,'Tag','StatMapCmb');

    % prepare stat. maps.
    StatMap.modelname = roiTs{1}.modelname;
    xyz = double(roiTs{1}.coords);  % make sure to be double, to avoid troubles on sub2ind().
    %sz = [size(curImg.dat,1),size(curImg.dat,2),size(curImg.dat,3)];
    sz  = [size(roiTs{1}.ana,1),size(roiTs{1}.ana,2),size(roiTs{1}.ana,3)];
    StatMap.vmap = zeros([sz length(roiTs{1}.p)]);
    StatMap.pmap = ones([sz length(roiTs{1}.p)]);
    StatMap.vmax = zeros(1,length(roiTs{1}.p));
    ind = sub2ind(sz,xyz(:,1),xyz(:,2),xyz(:,3));
    for iModel = 1:length(roiTs{1}.p),
      tmpvmap = zeros(sz);
      tmppmap = ones(sz);
      tmpvmap(ind) = roiTs{1}.statv{iModel}(:);
      tmppmap(ind) = roiTs{1}.p{iModel}(:);
      StatMap.vmap(:,:,:,iModel) = tmpvmap;
      StatMap.pmap(:,:,:,iModel) = tmppmap;
      if ~isempty(strfind(roiTs{1}.modelname{iModel},'corr')),
        Statmap.vmax(iModel) = 1;
      else
        Statmap.vmax(iModel) = max(roiTs{1}.statv{iModel}(:));
      end
    end
  else
    modelname = {'none'};
    set(wgts.StatMapCmb,'String',modelname);
    set(wgts.StatMapCmb,'Value',1);
    set(wgts.StatMapCmb,'Tag','StatMapCmb');
  end
  setappdata(wgts.main,'roiTs',roiTs);
  setappdata(wgts.main,'StatMap',StatMap);

  % SET SLIDER PROPERTIES: +0.01 TO PREVENT ERROR
  nslices = size(curImg.dat,3);
  
  set(wgts.SliceBarSldr,'Min',1,'Max',nslices+0.01,'Value',1);
  % NOTE THAT SLIDER STEP IS NORMALIZED FROM 0 to 1, NOT MIN/MAX
  if nslices > 1,
    sstep = [1/(nslices-1), 2/(nslices-1)];
  else
    sstep = [1 2];
  end
  set(wgts.SliceBarSldr,'SliderStep',sstep);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Atlas-init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
% set the atlas slider
%   % SET SLIDER PROPERTIES: +0.01 TO PREVENT ERROR
if strcmpi(get(wgts.AtlasSliceBarSldr,'Enable'),'on')
   atlas.atlas=get(wgts.AtlasCmb,'Value'); %gives the folder
   atlas.slice=str2num(get(wgts.AtlasSlice,'String'));
    switch atlas.atlas
        case {1,2}%hor
           minatlsl=-5;
           maxatlsl=41;
           sstep=[1/46 3/46];
        case {3,4}%cor
           minatlsl=-25;
           maxatlsl=50;
           sstep=[1/75 3/75];
        case {5}%roidef_atlas
           minatlsl=-25;
           maxatlsl=50;
           sstep=[1/75 3/75];
           set(wgts.AtlasSliceBarSldr,'Enable','off');
           set(wgts.AtlasCropEdt,'Enable','off');
           set(wgts.AtlasSlice,'Enable','off');
           set(wgts.crophelp,'Enable','off');
           set(wgts.AtlasRotate,'Enable','off');
    end
   set(wgts.AtlasSliceBarSldr,'Min',minatlsl,'Max',maxatlsl+0.01,'Value',1,'SliderStep',sstep,'Value',atlas.slice);
    
    setappdata(wgts.main,'atlordermarker',0); %just to remember in case we change the atlas 
    sldrmax=round(get(wgts.SliceBarSldr,'Max'));
    atlslice=getappdata(wgts.main,'atlslice');
    %if we have a singular value
    if size(atlslice,2)==1
        switch atlas.atlas
            case {2,4}   
                atlslice=atlslice:atlslice+sldrmax-1;
            case {1,3}
                atlslice=atlslice:-1:atlslice-sldrmax+1;
        end
        setappdata(wgts.main,'atlordermarker',1)
    end
    %if the atlslices don't match the number of slices
    sldiff=length(atlslice)-sldrmax;
    if sldiff >0
        atlslice=atlslice(1):atlslice(sldrmax);
    end
    if sldiff <0
       switch atlas.atlas
           case {1,3}%add slices in negative order
            newatl=atlslice(end)-1:-1:atlslice(end)+sldiff;
            atlslice=[atlslice newatl];
           case {2,4,5}
            newatl=atlslice(end)+1:atlslice(end)-sldiff;
            atlslice=[atlslice newatl];
       end
    end
    setappdata(wgts.main,'atlslice',atlslice)

   
end


  
  % ---------------------------------------------------------------------
  % SET GRPROI/ROI
  % ---------------------------------------------------------------------
  selgrproi = find(strcmp(get(wgts.GrpRoiSelCmb,'String'),grp.grproi));
  if isempty(selgrproi),  selgrproi = 1;  end
  set(wgts.GrpRoiSelCmb,'Value',selgrproi(1));
  Main_Callback(wgts.GrpRoiSelCmb,'load',[]);
  Main_Callback(wgts.RoiSelCmb,'roi-select',[]);

  % INVOKE THIS TO DRAW IMAGES
  Main_Callback(wgts.SliceBarSldr,'slice-slider',[]);
 
 
 case {'edit-session'}
  mguiEdit(which(ses.name));
  
 case {'edit-group'}
  grpname = get(wgts.GrpNameBut,'String');
  mguiEdit(which(ses.name),strcat('GRP.',grpname));
 
  
 case {'edit-atlcrop'}

  atlas.crop=get(wgts.AtlasCropEdt,'String');
  atlimgcrop=getappdata(wgts.main,'atlimgcrop');
  SLICE = round(get(wgts.SliceBarSldr,'Value'));

  if size(atlimgcrop,1)>2
      atlimgcrop(SLICE,:)=str2num(atlas.crop);
  else
    atlimgcrop=str2num(atlas.crop);
  end
  setappdata(wgts.main,'atlimgcrop',atlimgcrop)
  mroi('Main_Callback',wgts.main,'imgdraw');
  
  
  
 case {'edit-atlcrop2'}
  atlas=getappdata(wgts.main,'Atlas');
  atlas.atlas=get(wgts.AtlasCmb,'Value'); %gives the folder
  sldrval=round(get(wgts.SliceBarSldr,'Value'));
  atlslice=getappdata(wgts.main,'atlslice'); 
  atlas.slice=num2str(checklimits(atlslice(sldrval),...
                get(wgts.AtlasSliceBarSldr,'Min'),...
                round(get(wgts.AtlasSliceBarSldr,'Max')),0));    
  
  atlas.crop=get(wgts.AtlasCropEdt,'String');% gives the region of the image in [x y w h]
  %atlas.scale=get(wgts.AtlasScaleEdt,'String');% gives the scale for the image [sx sy]
  atlas.rotate=get(wgts.AtlasRotate,'String');
  atlas.ds=getappdata(wgts.main,'atlds');
  tmpana=getappdata(wgts.main,'curanaImg');
  atlas.imgsz=size(tmpana.dat);
  clear tmpana

  atlas=crophelp2(atlas);
  set(wgts.AtlasCropEdt,'String',atlas.crop);
  atlimgcrop=getappdata(wgts.main,'atlimgcrop');
  SLICE = round(get(wgts.SliceBarSldr,'Value'));

  if size(atlimgcrop,1)>2
      atlimgcrop(SLICE,:)=str2num(atlas.crop);
  else
    atlimgcrop=str2num(atlas.crop);
  end
  setappdata(wgts.main,'atlimgcrop',atlimgcrop)
  atlslice(sldrval)=str2num(atlas.slice);
  setappdata(wgts.main,'atlslice',atlslice);
  set(wgts.AtlasSlice,'String',num2str(atlslice(sldrval)));  
  set(wgts.AtlasSliceBarSldr,'Value',atlslice(sldrval));
  mroi('Main_Callback',wgts.main,'imgdraw');
  
 case {'edit-atlslice'}
    sldrval=round(get(wgts.SliceBarSldr,'Value'));
    atlslice=getappdata(wgts.main,'atlslice');
    atlslice(sldrval)=round(str2num(get(wgts.AtlasSlice,'String')));
    atlslice(sldrval)=checklimits(atlslice(sldrval),...
                get(wgts.AtlasSliceBarSldr,'Min'),...
                round(get(wgts.AtlasSliceBarSldr,'Max')),0);
    setappdata(wgts.main,'atlslice',atlslice);
    set(wgts.AtlasSliceBarSldr,'Value',atlslice(sldrval));
  mroi('Main_Callback',wgts.main,'imgdraw');
  
 case {'edit-atlas'}
  atlas.atlas=get(wgts.AtlasCmb,'Value');
  atlas.slice=str2num(get(wgts.AtlasSlice,'String'));
    %check for limits of the atlas and correct if needed
    switch atlas.atlas
     case {1,2} %hor VD
        atlas.slice=checklimits(atlas.slice,-5,41,0,-5);
        set(wgts.AtlasSlice,'String',num2str(atlas.slice));
        minatlsl=-5;
        maxatlsl=41;
        sstep=[1/46 3/46];
        set(wgts.AtlasSliceBarSldr,'Enable','on');
        set(wgts.AtlasCropEdt,'Enable','on');
        set(wgts.AtlasSlice,'Enable','on');
        set(wgts.crophelp,'Enable','on');
        set(wgts.AtlasRotate,'Enable','on');
     case {3,4} %cor AP
        atlas.slice=checklimits(atlas.slice,-25,50,0,50);
        set(wgts.AtlasSlice,'String',num2str(atlas.slice));
        minatlsl=-25;
        maxatlsl=50;
        sstep=[1/75 3/75];
        set(wgts.AtlasSliceBarSldr,'Enable','on');
        set(wgts.AtlasCropEdt,'Enable','on');
        set(wgts.AtlasSlice,'Enable','on');
        set(wgts.crophelp,'Enable','on');
        set(wgts.AtlasRotate,'Enable','on');
     case {5}%roidef_atlas
        minatlsl=-25;
        maxatlsl=50;
        sstep=[1/75 3/75];
        set(wgts.AtlasSliceBarSldr,'Enable','off');
        set(wgts.AtlasCropEdt,'Enable','off');
        set(wgts.AtlasSlice,'Enable','off');
        set(wgts.crophelp,'Enable','off');
        set(wgts.AtlasRotate,'Enable','off');
    end
    if getappdata(wgts.main,'atlordermarker')==1
        sldrmax=round(get(wgts.SliceBarSldr,'Max'));
        atlslice=getappdata(wgts.main,'atlslice');
        %if we have a singular value
        switch atlas.atlas
            case {2,4}   
                atlslice=atlslice(1):atlslice+sldrmax-1;
            case {1,3}
                atlslice=atlslice(1):-1:atlslice-sldrmax+1;
        end
        setappdata(wgts.main,'atlslice',atlslice); %atlslice changed, update atlslice and atlslice-slider
        sldrval=round(get(wgts.SliceBarSldr,'Value'));
        curatlslice=checklimits(atlslice(sldrval),...
                get(wgts.AtlasSliceBarSldr,'Min'),...
                round(get(wgts.AtlasSliceBarSldr,'Max')),0);
        set(wgts.AtlasSlice,'String',num2str(curatlslice));  
        set(wgts.AtlasSliceBarSldr,'Value',curatlslice);
    end
    
    
  set(wgts.AtlasSliceBarSldr,'Min',minatlsl,'Max',maxatlsl+0.01,'Value',1,'SliderStep',sstep,'Value',atlas.slice);
  mroi('Main_Callback',wgts.main,'imgdraw');
 
 case {'atlslice-slider'}
  if strcmpi(get(wgts.AtlasSliceBarSldr,'Enable'),'on')   %get rid of the error message
      sldrval=round(get(wgts.SliceBarSldr,'Value'));
    atlslice=getappdata(wgts.main,'atlslice');
    atlslice(sldrval)=round(get(wgts.AtlasSliceBarSldr,'Value'));
    atlslice(sldrval)=checklimits(atlslice(sldrval),...
                get(wgts.AtlasSliceBarSldr,'Min'),...
                round(get(wgts.AtlasSliceBarSldr,'Max')),0);
    setappdata(wgts.main,'atlslice',atlslice);
    set(wgts.AtlasSlice,'String',num2str(atlslice(sldrval)))
     mroi('Main_Callback',wgts.main,'imgdraw')
  end
  
 case {'slice-slider'}		% HERE WE DISPLAY THE IMAGES
  if ~isfield(wgts,'ImageAxs') || ~isfield(wgts,'main'),  return;  end    % why this happens?
  SLICE = round(get(wgts.SliceBarSldr,'Value'));
  set(wgts.SliceBarTxt,'String',sprintf('Slice: %d',SLICE));
  GAMMA = getappdata(wgts.main,'GAMMA');
  if get(wgts.GammaHoldCheck,'Value') == 0,
    set(wgts.GammaEdt,'String',num2str(GAMMA(SLICE)));
  end
  
  %slicer code for atlas
  %if get(wgts.OverlayCheck,'Value')
  if 1,
    atlas.atlas=get(wgts.AtlasCmb,'Value'); %gives the folder
    atlrotate=getappdata(wgts.main,'atlrotate');
    if length(atlrotate)>1
      atlrotate=atlrotate(SLICE);
      set(wgts.AtlasRotate,'String',num2str(atlrotate))
    end

    atlimgcrop=getappdata(wgts.main,'atlimgcrop');
    if size(atlimgcrop,1)>2
      atlimgcrop=atlimgcrop(SLICE,:);
      set(wgts.AtlasCropEdt,'String',deblank(sprintf('%g   ',atlimgcrop)));
    end
    
    atlslice=getappdata(wgts.main,'atlslice');
    sldrval=round(get(wgts.SliceBarSldr,'Value'));
    if ~isempty(atlslice)
      curatlslice=checklimits(atlslice(sldrval),...
                              get(wgts.AtlasSliceBarSldr,'Min'),...
                              round(get(wgts.AtlasSliceBarSldr,'Max')),0);
      set(wgts.AtlasSlice,'String',num2str(curatlslice));  
      set(wgts.AtlasSliceBarSldr,'Value',curatlslice);
    end
    %mroi('Main_Callback',wgts.main,'imgdraw');
  end

  mroi('Main_Callback',wgts.main,'imgdraw');
  if isfield(curanaImg,'dat') && ~isempty(curanaImg.dat),
    set(wgts.ImageAxs,'xlim',[0.5,size(curanaImg.dat,1)+0.5],'ylim',[0.5,size(curanaImg.dat,2)+0.5]);
  end
  curImg = getappdata(wgts.main,'curImg');
  if isfield(curImg,'dat') && ~isempty(curImg.dat),
    set(wgts.Image2Axs,'xlim',[0.5,size(curImg.dat,1)+0.5],'ylim',[0.5,size(curImg.dat,2)+0.5]);
  end

 case {'epi-ana' 'epiana'}
  tcImg   = getappdata(wgts.main,'tcImg');
  anaImg  = getappdata(wgts.main,'anaImg');
  IMGDIMS = getappdata(wgts.main,'IMGDIMS');
  if get(wgts.EpiAnaCheck,'value') > 0,
    curanaImg = tcImg;
    curanaImg.dat = tcImg.ana;
    curanaImg.method = 'epi';
  else
    curanaImg = anaImg;
  end
  IMGDIMS.ana     = [size(curanaImg.dat,1), size(curanaImg.dat,2)];
  IMGDIMS.pxscale = size(tcImg.dat,1)/size(curanaImg.dat,1);
  IMGDIMS.pyscale = size(tcImg.dat,2)/size(curanaImg.dat,2);
  setappdata(wgts.main,'curanaImg',curanaImg);
  setappdata(wgts.main,'IMGDIMS',IMGDIMS);
  set(wgts.AnaTxt,'String',upper(curanaImg.method));

  mroi('Main_Callback',wgts.main,'imgdraw');
  
  
 case {'imgdraw'}
  if ~isfield(wgts,'ImageAxs') || ~isfield(wgts,'main'),  return;  end    % why this happens?
  % ************* DRAWING OF THE ANATOMY IMAGE
  SLICE = round(get(wgts.SliceBarSldr,'Value'));
  figure(wgts.main);
  
  % ************* DRAWING OF THE ANATOMY IMAGE ****************************************
  GAMMA = str2double(get(wgts.GammaEdt,'String'));
  tmpanaimg = subScaleAnaImage(hObject,wgts,curanaImg.dat(:,:,SLICE));
  set(wgts.main,'CurrentAxes',wgts.ImageAxs); cla;

  if strcmpi(get(wgts.OverlayCheck,'Enable'),'on'),
    Atlas=getappdata(wgts.main,'Atlas');
    Atlas.atlas=get(wgts.AtlasCmb,'Value'); %gives the folder
    sldrval=round(get(wgts.SliceBarSldr,'Value'));              % gives the image
    atlslice=getappdata(wgts.main,'atlslice');%
    if ~isempty(atlslice)
      Atlas.slice=num2str(checklimits(atlslice(sldrval),...                          %
                                      get(wgts.AtlasSliceBarSldr,'Min'),...         %
                                      round(get(wgts.AtlasSliceBarSldr,'Max')),0));  %
    else
      Atlas.slice='7';
    end
    Atlas.crop=get(wgts.AtlasCropEdt,'String');% gives the region of the image in [x y w h]
    Atlas.ds=curanaImg.ds;
    Atlas.slicetrans = round(get(wgts.SliceBarSldr,'Value')); %needed for transformed atlas
    setappdata(wgts.main,'atlds',Atlas.ds)
    % Atlas.scale=get(wgts.AtlasScaleEdt,'String');% gives the scale for the image [sx sy]
    Atlas.rotate=get(wgts.AtlasRotate,'String');
    if isequal(str2num(Atlas.crop),[1 1 1 1]),
      Atlas.crop=num2str([1 1 size(tmpanaimg,1)*Atlas.ds(1) size(tmpanaimg,2)*Atlas.ds(2)],'%g   ');
      set(wgts.AtlasCropEdt,'String',Atlas.crop);
    end
    if get(wgts.OverlayCheck,'Value') > 0
      mroidspatlas(tmpanaimg,Atlas,0,GAMMA);
    else
      mroidsp(tmpanaimg,0,GAMMA);
    end
  else
    mroidsp(tmpanaimg,0,GAMMA);
  end
  daspect(wgts.ImageAxs,[2 2*curanaImg.ds(1)/curanaImg.ds(2) 1]);

  mdl = get(wgts.StatMapCmb,'String');
  mdl = mdl{get(wgts.StatMapCmb,'Value')};
  
  if ~strcmpi(mdl,'none'),
    StatMap  = getappdata(wgts.main,'StatMap');
    vthr     = str2num(get(wgts.StatVThrEdt,'String'));
    pthr     = str2num(get(wgts.StatPThrEdt,'String'));
    roinames = get(wgts.RoiSelCmb,'String');
    midx = find(strcmpi(StatMap.modelname,mdl));
    
    tmpscaleX = size(curanaImg.dat,1) / size(StatMap.vmap,1);
    tmpscaleY = size(curanaImg.dat,2) / size(StatMap.vmap,2);
    
    L=length(StatMap.modelname);
    for N = 1:length(StatMap.modelname),
      ofs = -L/2 + N;
      if ~strcmpi(mdl,'all') && N ~= midx,  continue;  end
      vmap = squeeze(StatMap.vmap(:,:,SLICE,N));
      pmap = squeeze(StatMap.pmap(:,:,SLICE,N));
      if pthr < 1,
        % Bonferroni
        if get(wgts.BonferroniCheck,'value') > 0,
          pthr = pthr / prod(size(vmap));
        end
        idx = find(pmap(:) > pthr);
        if ~isempty(idx),  vmap(idx) = 0;  end
      end
      
      cidx = find(strcmp(roinames,StatMap.modelname{N}));
      if ~isempty(cidx),
        cidx = mod(cidx(1),length(MAPCOLORS)) + 1;
      else
        cidx = mod(N,length(MAPCOLORS)) + 1;
      end
      tmpcol = MAPCOLORS(cidx);
      [tmpx tmpy] = find(pmap < pthr);
      hold on;
      tmpx = tmpx * tmpscaleX;
      tmpy = tmpy * tmpscaleY;

      MODEL_MARKER_SIZE = 5;
      plot(tmpx+ofs,tmpy+ofs,'marker','.','markersize',MODEL_MARKER_SIZE,...
           'markerfacecolor',tmpcol,'markeredgecolor',tmpcol,...
           'linestyle','none');
    end
  end

  tmptxt = sprintf('Vox=[%g %g %g]mm',curanaImg.ds);
  text(0.01,-0.01,tmptxt,'units','normalized','color','y','VerticalAlignment','top');
  
  % DRAW ROIS
  RoiRoi = getappdata(wgts.main,'RoiRoi');
  RoiEle = getappdata(wgts.main,'RoiEle');
  set(wgts.main,'CurrentAxes',wgts.Image2Axs);
  subDrawAnaROIs(wgts,RoiRoi,RoiEle,ses,SLICE,COLORS);
  % some plotting function clears 'tag' of the axes !!!!!
  set(wgts.ImageAxs,'Tag','ImageAxs');  

  % ************* DRAWING OF THE EPI IMAGE *******************************************
  curImg = getappdata(wgts.main,'curImg');
  IMGDIMS = getappdata(wgts.main,'IMGDIMS');
  %figure(wgts.main);
  set(wgts.main,'CurrentAxes',wgts.Image2Axs); cla;
  %mroidsp(curImg.dat(:,:,SLICE,:),1,0,getappdata(wgts.main,'CurOp'));
  mroidsp(curImg.dat(:,:,SLICE,:),1,0,'');
  daspect(wgts.Image2Axs,[2 2*curImg.ds(1)/curImg.ds(2) 1]);
  % DRAW ROIs
  subDrawEpiROIs(wgts,RoiRoi,RoiEle,ses,SLICE,COLORS,IMGDIMS);
  set(wgts.Image2Axs,'Tag','Image2Axs');
  tmptxt = sprintf('Vox=[%g %g %g]mm',curImg.ds);
  text(0.01,-0.01,tmptxt,'units','normalized','color','y','VerticalAlignment','top');

  set(wgts.main,'CurrentAxes',wgts.ImageAxs);
  
 case {'roidraw-ana'}
  SLICE = round(get(wgts.SliceBarSldr,'Value'));
  RoiRoi = getappdata(wgts.main,'RoiRoi');
  RoiEle = getappdata(wgts.main,'RoiEle');
  delete(findobj(wgts.ImageAxs,'tag','roi'))
  delete(findobj(wgts.ImageAxs,'tag','roi-marker'))
  subDrawAnaROIs(wgts,RoiRoi,RoiEle,ses,SLICE,COLORS);
 case {'roidraw-epi'}
  SLICE = round(get(wgts.SliceBarSldr,'Value'));
  RoiRoi = getappdata(wgts.main,'RoiRoi');
  RoiEle = getappdata(wgts.main,'RoiEle');
  IMGDIMS = getappdata(wgts.main,'IMGDIMS');
  delete(findobj(wgts.Image2Axs,'tag','roi'))
  delete(findobj(wgts.Image2Axs,'tag','roi-marker'))
  subDrawEpiROIs(wgts,RoiRoi,RoiEle,ses,SLICE,COLORS,IMGDIMS);


 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 case {'load'}
  % ---------------------------------------------------------------------
  % LOAD ROI IF EXISTS.
  % ---------------------------------------------------------------------
  GAMMA = 1.8;
  
  
  RoiVar = get(wgts.GrpRoiSelCmb,'String');
  RoiVar = RoiVar{get(wgts.GrpRoiSelCmb,'Value')};
  RoiFile = mroi_file(ses,RoiVar);
  if exist(RoiFile,'file') && ~isempty(who('-file',RoiFile,RoiVar)),
    StatusPrint(hObject,cbname,'Loading "%s" from %s, please wait...',RoiVar,RoiFile);
    goto(ses); % MAKE SURE WE ARE IN THE SESSION DIRECTORY
    Roi = load(RoiFile,RoiVar);
    Roi = Roi.(RoiVar);
    Roi = subValidateRoi(wgts,Roi,ses);
    Roi = subValidateBrain(wgts,Roi,ses);
    tmpele = subUpdateEle(wgts,ses,RoiVar);
    if ~isempty(tmpele), Roi.ele = tmpele; clear tmpele; end
	if isfield(Roi,'roi'), RoiRoi = Roi.roi; else RoiRoi = {}; end;
	if isfield(Roi,'ele'), RoiEle = Roi.ele; else RoiEle = {}; end;
	if isfield(Roi,'midline'),  RoiML = Roi.midline; else RoiML = {}; end;
	if isfield(Roi,'acommisure'),  RoiAC = Roi.acommisure; else RoiAC = {}; end;
    if isfield(Roi,'lr_separate'), RoiLR = Roi.lr_separate; else RoiLR = {};  end
    if isfield(Roi,'marker'), RoiMarker = Roi.marker; else RoiMarker = {};  end
    
	StatusPrint(hObject,cbname,'Loaded Roi "%s" from Roi.mat',RoiVar);
    if isfield(Roi,'gamma'),  GAMMA = Roi.gamma;  end
  else
    RoiRoi = {};
    RoiEle = subUpdateEle(wgts,ses,RoiVar);
    RoiML  = {};
    RoiAC  = {};
    RoiLR  = {};
    RoiMarker = {};
    StatusPrint(hObject,cbname,'"%s" not found in Roi.mat',RoiVar);
  end
  set(wgts.main,'Name',sprintf('MROI : %s %s/%s',ses.name,grp.name,RoiVar))
  
  % set gamma values for each slices
  nslices = size(curImg.dat,3);
  if length(GAMMA) ~= nslices,
    GAMMA = ones(1,nslices)*GAMMA(1);
  end
  SLICE = round(get(wgts.SliceBarSldr,'Value'));
  set(wgts.GammaEdt,'String',num2str(GAMMA(SLICE)));
  
  setappdata(wgts.main,'RoiRoi',RoiRoi);
  setappdata(wgts.main,'RoiEle',RoiEle);
  setappdata(wgts.main,'RoiML',RoiML);
  setappdata(wgts.main,'RoiAC',RoiAC);
  setappdata(wgts.main,'RoiLR',RoiLR);
  setappdata(wgts.main,'RoiMarker',RoiMarker);
  setappdata(wgts.main,'GAMMA',GAMMA);
  
  
  % for undo-command
  setappdata(wgts.main,'LastRoiAction','');
  setappdata(wgts.main,'RoiRoi_bak',RoiRoi);
  setappdata(wgts.main,'RoiEle_bak',RoiEle);
  setappdata(wgts.main,'RoiML_bak',RoiML);
  setappdata(wgts.main,'RoiAC_bak',RoiAC);
  setappdata(wgts.main,'RoiLR_bak',RoiLR);
  setappdata(wgts.main,'RoiMarker_bak',RoiMarker);
  
  % no 'redraw' to avoid Matlab warning, 
  % if redraw needed, use 'load-redraw' below.
  %Main_Callback(wgts.GrpRoiSelCmb,'redraw',[]);
  
  
 case {'load-redraw'}
  Main_Callback(wgts.GrpRoiSelCmb,'load',[]);
  Main_Callback(wgts.GrpRoiSelCmb,'redraw',[]);
  %mroi('Main_Callback',wgts.main,'redraw');
  

 case {'save'}
  tcImg  = getappdata(wgts.main,'tcImg');
  anaImg    = getappdata(wgts.main,'anaImg');
  GAMMA     = getappdata(wgts.main,'GAMMA');
  Roi = mroisct(ses,grp,tcImg,anaImg,GAMMA);
  Roi.roi = getappdata(wgts.main,'RoiRoi');
  Roi.ele = getappdata(wgts.main,'RoiEle');
  Roi.midline    = getappdata(wgts.main,'RoiML');
  Roi.acommisure = getappdata(wgts.main,'RoiAC');
  Roi.lr_separate = getappdata(wgts.main,'RoiLR');
  Roi.marker = getappdata(wgts.main,'RoiMarker');
  if isempty(Roi.roi),
    StatusPrint(hObject,cbname,'no ROI to save');
    return;
  end
  % mroisct(ses,grp,tcImg,anaImg) returns the following Roi-fields
  % ====================================================
  % Roi.session Roi.grpname Roi.exps Roi.anainfo  Roi.roi.names
  % Roi.dir  Roi.dsp  Roi.grp  Roi.usr
  % Roi.ana  Roi.img  Roi.ds   Roi.dx		
  % Roi.roi  Roi.ele	
  % Roi.roi.coords --- ARE ADDED BY THE FOLLOWING LINES
  % [x,y] = find(Roi.roi{RoiNo}.mask);
  % Roi.roi{RoiNo}.coords = [x y ones(length(x),1)*Roi.roi{RoiNo}.slice];
  % 26.04.04 -- The cooordinates will be added by the mareats
  % function which selects the time series of interest. In all
  % other positions, the .coords will be eliminated. It's
  % maintenance along the process is only nuisance, as the
  % information is used after mareats anyway...
  % ====================================================
  IMGDIMS = getappdata(wgts.main,'IMGDIMS');
  % Check whether tracer experiment or not, if it is, then use Roi.ana (int16)
  % as Roi.img, to save the size of Roi.mat:  120M-->12M for m02th1.
  if isfield(tcImg,'dir') && isfield(tcImg.dir,'scantype'),
    if strcmpi(tcImg.dir.scantype,'mdeft') && ndims(tcImg.dat) == 3,
      szana = size(Roi.ana);  szimg = size(Roi.img);
      if length(szana) == length(szana) && all(szana == szimg),
        % it is likely that this is a tracer experiment.
        Roi.img = Roi.ana;  % ana supposed to be int16.
      end
    end
  end
  

  RoiVar = get(wgts.GrpRoiSelCmb,'String');
  RoiVar = RoiVar{get(wgts.GrpRoiSelCmb,'Value')};
  RoiFile = mroi_file(ses,RoiVar);
  set(wgts.StatusField,'String',sprintf('Saving "%s" to "%s", please wait...',RoiVar,RoiFile));
  mroi_save(ses,RoiVar,Roi,'file',RoiFile,'verbose',0,'backup',1);
  % goto(ses); % MAKE SURE WE ARE IN THE SESSION DIRECTORY
  % eval(sprintf('%s = Roi;',RoiVar));
  % if exist(RoiFile,'file'),
  %   [fp fr fe] = fileparts(RoiFile);
  %   x = dir(RoiFile);
  %   bakfile = sprintf('%s.%s.%s%s',fr,datestr(datenum(x.date),'yyyymmdd_HHMM'),mfilename,fe);
  %   bakfile = fullfile(fp,bakfile);
  %   copyfile(RoiFile,bakfile,'f');
  %   %copyfile(RoiFile,sprintf('%s.bak',RoiFile),'f');
  %   if all(strcmp(who('-file',RoiFile),RoiVar)),
  %     % only "RoiVar" in RoiFile
  %     save(RoiFile,RoiVar);
  %   else
  %     % need to 'append' since RoiFile has other stuffs.
  %     save(RoiFile,RoiVar,'-append');
  %   end
  % else
  %   mmkdir(fileparts(RoiFile));
  %   save(RoiFile,RoiVar);
  % end
  set(wgts.StatusField,'String',sprintf('%s done.',get(wgts.StatusField,'String')));

 case {'roi-select'}
  roiname = get(wgts.RoiSelCmb,'String');
  roiname = roiname{get(wgts.RoiSelCmb,'Value')};
  % set 'RoiAction' to 'no action'
  actions = get(wgts.RoiActCmb,'String');
  idx = find(strcmpi(actions,'no action'));
  set(wgts.RoiActCmb,'Value',idx);
  
 case {'roi-select-redraw'}
  % redraw rois
  Main_Callback(wgts.SliceBarSldr,'roi-select',[]);
  RoiDraw = get(wgts.RoiDrawCmb,'String');
  RoiDraw = RoiDraw{get(wgts.RoiDrawCmb,'Value')};
  if strcmpi(RoiDraw,'current'),
    Main_Callback(wgts.SliceBarSldr,'roidraw-ana',[]);
  end
  RoiDraw = get(wgts.RoiDrawEpiCmb,'String');
  RoiDraw = RoiDraw{get(wgts.RoiDrawEpiCmb,'Value')};
  if strcmpi(RoiDraw,'current'),
    Main_Callback(wgts.SliceBarSldr,'roidraw-epi',[]);
  end

  % MENU HANDLING
 case {'edit-cb'}
  % edit callback functions
  token = get(hObject,'Label');
  if ~isempty(token),
    mguiEdit(which('mroi'),sprintf('function %s(hObject',token));
  end
 case {'exit'}
  if ishandle(wgts.main), close(wgts.main);  end
  return;

 case {'grp-select', 'group-select'}
  grpname = get(wgts.GrpSelCmb,'String');
  grpname = grpname{get(wgts.GrpSelCmb,'Value')};
  grp = getgrp(ses,grpname);
  setappdata(wgts.main,'Grp',grp);
  mroi('Main_Callback',wgts.main,'init');
  mroi('Main_Callback',wgts.main,'redraw');
 
 case {'grproi-select'}
  roiset  = get(wgts.GrpRoiSelCmb,'String');
  roiset  = roiset{get(wgts.GrpRoiSelCmb,'Value')};
  grpname = get(wgts.GrpSelCmb,'String');
  for N = 1:length(grpname),
    grp = getgrp(ses,grpname{N});
    if strcmpi(grp.grproi,roiset),
      set(wgts.GrpSelCmb,'value',N);
      mroi('Main_Callback',wgts.main,'grp-select');
      break;
    end
  end
  
 case {'set-gamma'}
  SLICE = round(get(wgts.SliceBarSldr,'Value'));
  value = str2double(get(wgts.GammaEdt,'String'));
  GAMMA = getappdata(wgts.main,'GAMMA');
  GAMMA(SLICE) = value;
  setappdata(wgts.main,'GAMMA',GAMMA);
  mroi('Main_Callback',wgts.main,'redraw');


 % =============================================================
 % EXECUTION OF CALLBACKS OF THE FUNCTION-BUTTONS (bNames)
 % PROCESSING AND DISPLAY OF IMAGES AND TIME SERIES
 % =============================================================
 case {'redraw'}
  Main_Callback(wgts.RoiSelCmb,'roi-select',[]);
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);

 case {'imgproc-select'}
  curImg = getappdata(wgts.main,'tcImg');
  anaImg = getappdata(wgts.main,'anaImg');
  curanaImg = anaImg;
  imgpro = get(wgts.ImgProcCmb,'String');
  imgpro = imgpro{get(wgts.ImgProcCmb,'Value')};
  if ~isa(curImg.dat,'double'), curImg.dat = double(curImg.dat);  end

  set(wgts.StatusField,'String',sprintf('imgproc(%s)...',imgpro));  drawnow;
  switch lower(imgpro)
   case {'mean'}
    curImg.dat = nanmean(curImg.dat,4);
   case {'median','median-img'}
    curImg.dat = median(curImg.dat,4);
   case {'max','max-img'}
    curImg.dat = max(curImg.dat,4);
   case {'std','std-img'}
    curImg.dat = nanstd(curImg.dat,1,4);
   case {'std(stim)' 'stmstd'}
    curImg = tosdu(curImg);
    tmp = getbaseline(curImg,'dat','notblank');
    curImg.dat = nanmean(curImg.dat(:,:,:,tmp.ix),4);
    mask = curImg.dat;
    mask(mask(:) <3)  = 1;
    mask(mask(:) >=3) = 1.5;
    for N=1:size(curImg.dat,3),
      curanaImg.dat(:,:,N) = anaImg.dat(:,:,N) .* ...
          imresize(mask(:,:,N),size(anaImg.dat(:,:,N)));
    end;
    setappdata(wgts.main,'curanaImg',curanaImg);
   case {'cv','cv-img'}
    m = nanmean(double(curImg.dat),4);
    s = nanstd(double(curImg.dat),[],4);
    tmpidx = m < eps;
    m(tmpidx) = 1;
    s(tmpidx) = 0;
    curImg.dat = s ./ m;
    clear m s tmpidx;
   case {'t0','t0-img'}
    curImg.dat = curImg.dat(:,:,:,1);
   case {'tend','tend-img'}
    curImg.dat = curImg.dat(:,:,:,end);
  end 
  set(wgts.StatusField,'String',sprintf('imgproc(%s)... done.',imgpro));
 
  setappdata(wgts.main,'curImg',curImg);
  setappdata(wgts.main,'curanaImg',curanaImg);
  setappdata(wgts.main, 'CurOp', imgpro);
  mroi('Main_Callback',wgts.main,'redraw');

 case {'zoomin-ana'}
  click = get(wgts.main,'SelectionType');
  if strcmp(click,'open'),
    %fprintf('zoomin-ana\n');
    hfig = wgts.main+1001;
    figure(hfig); clf;
    haxs = copyobj(wgts.ImageAxs,hfig);
    set(haxs,'Position',[ 0.1300 0.1100 0.7750 0.8150]);
    set(hfig,'Colormap',get(wgts.main,'Colormap'));
    title(haxs,sprintf('%s: GRP=%s ROI=%s (ana)',ses.name,grp.name,grp.grproi));
  end
  
 case {'zoomin-func'}
  click = get(wgts.main,'SelectionType');
  if strcmp(click,'open'),
    %fprintf('zoomin-func\n');
    hfig = wgts.main+1002;
    figure(hfig); clf;
    haxs = copyobj(wgts.Image2Axs,hfig);
    set(haxs,'Position',[ 0.1300 0.1100 0.7750 0.8150]);
    set(hfig,'Colormap',get(wgts.main,'Colormap'));
    title(haxs,sprintf('%s: GRP=%s ROI=%s (func)',ses.name,grp.name,grp.grproi));
  end
  
 case {'fig-toolbar'}
  %HandleVisibility = get(wgts.main,'HandleVisibility');
  %set(wgts.main,'HandleVisibility','on');
  if strcmpi(get(wgts.MenuFigToolbar,'checked'),'off'),
    set(wgts.main,'toolbar','figure');
    set(wgts.MenuFigToolbar,'checked','on');
  else
    set(wgts.main,'toolbar','none');
    set(wgts.MenuFigToolbar,'checked','off');
  end
  %set(wgts.main,'HandleVisibility',HandleVisibility);
 
 
 otherwise
  %fprintf('unknown\n');
  
end
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALLBACK for ROI-ACTION
function Roi_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~strcmpi(eventdata,'roi-action'), return;  end
  
funcname = mfilename('fullpath');
[ST, I] = dbstack;
n = findstr(ST(I).name,'(');
if any(n),
cbname = ST(I).name(n+1:end-1);
else
cbname = ST(I).name;
end


wgts = guihandles(hObject);
actions = get(wgts.RoiActCmb,'String');

ROI_COMMAND = actions{get(wgts.RoiActCmb,'Value')};

set(wgts.StatusField,'String',sprintf('ROI (''%s'')...',ROI_COMMAND));

% do the current action
% 30.05.05 YM:  I have to use "subRoiCommand" to support "replace" in "sticky" mode,
% otherwise, "replace" become "append" when move to the next slice in the old code.
switch lower(ROI_COMMAND),
 case {'coordinate'}
  set(wgts.RoiActCmb,'Enable','off');
  set(wgts.MarkerActCmb,'Enable','off');
  while 1,
    tmpxy = ginput(1);
    % check right-click
    click = get(wgts.main,'SelectionType');
    if strcmpi(click,'alt'),  break;  end
    % if empty, break
    if isempty(tmpxy),  break;  end
    % print-out the value
    if wgts.ImageAxs == gca,
      % if anatomy figure, then convert into EPI coordinates.
      IMGDIMS = getappdata(wgts.main,'IMGDIMS');
      tmpxy(1) = tmpxy(1) * IMGDIMS.pxscale;
      tmpxy(2) = tmpxy(2) * IMGDIMS.pyscale;
    end
    tmpz = round(get(wgts.SliceBarSldr,'Value'));
    fprintf('  XYZ=[%g %g %g]\n',tmpxy(1),tmpxy(2),tmpz);
  end
  set(wgts.RoiActCmb,'Enable','on');
  set(wgts.MarkerActCmb,'Enable','on');
 
 case {'find'}
  set(wgts.RoiActCmb,'Enable','off');
  set(wgts.MarkerActCmb,'Enable','off');
  RoiRoi = getappdata(wgts.main,'RoiRoi');
  
  roiname = get(wgts.RoiSelCmb,'String');
  roiname = roiname{get(wgts.RoiSelCmb,'Value')};
  set(wgts.StatusField,'String',sprintf('Finding(%s)...',roiname)); drawnow;
  slice = NaN(1,length(RoiRoi));
  for N = 1:length(RoiRoi)
    if strcmp(RoiRoi{N}.name,roiname)
      slice(N) = RoiRoi{N}.slice;
    end
  end
  slice = min(slice);
  set(wgts.RoiActCmb,'Enable','on');
  set(wgts.MarkerActCmb,'Enable','on');

  if any(slice),
    set(wgts.StatusField,'String',sprintf('Finding(%s)... slice=%d.',roiname,slice));
    set(wgts.SliceBarTxt,'String',sprintf('Slice: %d',slice));
    set(wgts.SliceBarSldr,'value',slice);
    Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
  else
    set(wgts.StatusField,'String',sprintf('Finding(%s)... not found.',roiname));
  end
  
  
 case {'append','replace'}
  % if command == 'replace', then clear the current ROIs.
  if strcmpi(ROI_COMMAND,'replace'),
    subRoiCommand('clear', wgts,1);
    subRoiCommand('append',wgts,0);
    setappdata(wgts.main,'LastRoiAction',ROI_COMMAND);
  else
    subRoiCommand('append',wgts,1);
  end
  % call recursively, if 'sticky' mode
  if get(wgts.Sticky,'Value'),
    curImg = getappdata(wgts.main,'curImg');
    nslices = size(curImg.dat,3);
    SLICE = round(get(wgts.SliceBarSldr,'Value')) + 1;
    if get(wgts.Sticky,'Value') && SLICE <= nslices,
      set(wgts.SliceBarTxt,'String',sprintf('Slice: %d',SLICE));
      set(wgts.SliceBarSldr,'Value',SLICE);
      mroi('Main_Callback',wgts.main,'redraw');
      idx = find(strcmpi(actions,ROI_COMMAND));
      set(wgts.RoiActCmb,'Value',idx);
      %mroi('Roi_Callback',wgts.RoiActCmb,'roi-action',[]);
      Roi_Callback(wgts.RoiActCmb,'roi-action',[]);
    end
  end

 case {'reset cursor'}
  set(wgts.main,'Pointer','arrow');
  
 case {'undo'}
  subUndoCommand(wgts);

 otherwise
  subRoiCommand(ROI_COMMAND,wgts,1);
end

set(wgts.StatusField,'String',sprintf('%s done.',get(wgts.StatusField,'String')));

% set to 'no action'
idx = find(strcmpi(actions,'no action'));
set(wgts.RoiActCmb,'Value',idx);
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sub function of CALLBACK for ROI-ACTION
function subRoiCommand(COMMANDSTR,wgts,DO_BACKUP)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 3,  DO_BACKUP = 1;  end

ses = getappdata(wgts.main,'Ses');
grp = getappdata(wgts.main,'Grp');
COLORS = getappdata(wgts.main,'COLOR');

RoiRoi  = getappdata(wgts.main,'RoiRoi');
RoiEle  = getappdata(wgts.main,'RoiEle');
RoiML   = getappdata(wgts.main,'RoiML');
RoiAC   = getappdata(wgts.main,'RoiAC');
RoiLR   = getappdata(wgts.main,'RoiLR');
SLICE   = round(get(wgts.SliceBarSldr,'Value'));
roiname = get(wgts.RoiSelCmb,'String');
roiname = roiname{get(wgts.RoiSelCmb,'Value')};

if DO_BACKUP
  setappdata(wgts.main,'LastRoiAction',COMMANDSTR);
  setappdata(wgts.main,'RoiRoi_bak',RoiRoi);
  setappdata(wgts.main,'RoiEle_bak',RoiEle);
  setappdata(wgts.main,'RoiML_bak',RoiML);
  setappdata(wgts.main,'RoiAC_bak',RoiAC);
  setappdata(wgts.main,'RoiLR_bak',RoiLR);
end


% reset the mouse event to avoid matlab returns
% a funny state of it...
set(wgts.main,'SelectionType','normal');

set(wgts.main,'CurrentAxes',wgts.ImageAxs);

switch lower(COMMANDSTR),
 case {'append'}
  % disable widgets
  set(wgts.RoiSelCmb,'Enable','off');
  set(wgts.RoiActCmb,'Enable','off');
  set(wgts.RoiLoadBtn,'Enable','off');
  set(wgts.RoiSaveBtn,'Enable','off');
  set(wgts.MarkerActCmb,'Enable','off');

  IMGDIMS = getappdata(wgts.main,'IMGDIMS');
  if all(IMGDIMS.ana == IMGDIMS.epi),
    SAME_DIMS = 1;
  else
    SAME_DIMS = 0;
  end

  cidx = find(strcmp(ses.roi.names,roiname));
  cidx = mod(cidx(1),length(COLORS)) + 1;
  while 1,
    % use 'timer' function to modify the cusor
    tmpcursor = get(wgts.RoiCursorCmb,'String');
    tmpcursor = tmpcursor{get(wgts.RoiCursorCmb,'Value')};
    tobj = timer('TimerFcn',sprintf('mroi_cursor(''%s'');',tmpcursor),...
                'StartDelay',0.2);
    start(tobj);
    % get roi
    try
      %[anamask,anapx,anapy] = roipoly;
      [anamask,anapx,anapy] = roipoly_71;
    catch
      % Note that Matlab 7.5 roipoly() will crash by right-click.
      % check user interaction
      click = get(wgts.main,'SelectionType');
      if strcmpi(click,'alt'),
        wait(tobj);  delete(tobj);
        break;
      else
        lasterr
      end
    end
    % delete the timer object and restore the cursor
    wait(tobj);  delete(tobj);
    
    % check user interaction
    click = get(wgts.main,'SelectionType');

    if strcmpi(click,'extend'),
      set(wgts.Sticky,'Value',0);
      %fprintf('click-extend');
      break;
    elseif strcmpi(click,'alt'),
      %fprintf('click-alt');
      break;
    else
      %fprintf('click-%s',click);
    end;

    % check size of poly, if very small ignore it.
    %length(anapx), length(anapy)
    if length(anapx)*length(anapy) < 1,  break;  end
    anamask = logical(anamask'); % transpose "mask"
    % now register the new roi
    N = length(RoiRoi) + 1;
    RoiRoi{N}.name  = roiname;
    RoiRoi{N}.slice = SLICE;
    %RoiRoi{N}.anamask  = anamask;
    %RoiRoi{N}.anapx    = anapx;
    %RoiRoi{N}.anapy    = anapy;
    RoiRoi{N}.px    = anapx * IMGDIMS.pxscale; 
    RoiRoi{N}.py    = anapy * IMGDIMS.pyscale; 
    if SAME_DIMS,
      RoiRoi{N}.mask     = anamask;
    else
      RoiRoi{N}.mask     = logical(round(imresize(double(anamask),IMGDIMS.epi)));
      %RoiRoi{N}.mask = poly2mask(RoiRoi{N}.px,RoiRoi{N}.py,IMGDIMS.epi(2),IMGDIMS.epi(1))';
    end

    % draw the polygon
    set(wgts.main,'CurrentAxes',wgts.ImageAxs);  hold on;
    plot(anapx,anapy,'color',COLORS(cidx));
    x = min(anapx) - 4;  y = min(anapy) - 2; if x<0, x=1; end;
    %x = px(1) - 2;  y = py(1) - 2;
    text(x,y,strrep(strrep(roiname,'_','\_'),'^','\^'),'color',COLORS(cidx),'fontsize',8);
  end
  setappdata(wgts.main,'RoiRoi',RoiRoi);

  % enable widgets
  set(wgts.RoiSelCmb,'Enable','on');
  set(wgts.RoiActCmb,'Enable','on');
  set(wgts.RoiLoadBtn,'Enable','on');
  set(wgts.RoiSaveBtn,'Enable','on');
  set(wgts.MarkerActCmb,'Enable','on');
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
  mroi_cursor('arrow');
  
 case {'add bitmap'}
  % disable widgets
  set(wgts.RoiSelCmb,'Enable','off');
  set(wgts.RoiActCmb,'Enable','off');
  set(wgts.RoiLoadBtn,'Enable','off');
  set(wgts.RoiSaveBtn,'Enable','off');
  set(wgts.MarkerActCmb,'Enable','off');

  IMGDIMS = getappdata(wgts.main,'IMGDIMS');
  if all(IMGDIMS.ana == IMGDIMS.epi),
    SAME_DIMS = 1;
  else
    SAME_DIMS = 0;
  end

  RoiAdd = {};
  while 1,
    % use 'timer' function to modify the cusor
    tmpcursor = get(wgts.RoiCursorCmb,'String');
    tmpcursor = tmpcursor{get(wgts.RoiCursorCmb,'Value')};
    tobj = timer('TimerFcn',sprintf('mroi_cursor(''%s'');',tmpcursor),...
                'StartDelay',0.2);
    start(tobj);
    % get roi
    try
      %[anamask,anapx,anapy] = roipoly;
      [anamask,anapx,anapy] = roipoly_71;
    catch
      % Note that Matlab 7.5 roipoly() will crash by right-click.
      % check user interaction
      click = get(wgts.main,'SelectionType');
      if strcmpi(click,'alt'),
        wait(tobj);  delete(tobj);
        break;
      else
        lasterr
      end
    end
    % delete the timer object and restore the cursor
    wait(tobj);  delete(tobj);
    
    % check user interaction
    click = get(wgts.main,'SelectionType');

    if strcmpi(click,'extend'),
      set(wgts.Sticky,'Value',0);
      %fprintf('click-extend');
      break;
    elseif strcmpi(click,'alt'),
      %fprintf('click-alt');
      break;
    else
      %fprintf('click-%s',click);
    end;

    % check size of poly, if very small ignore it.
    %length(anapx), length(anapy)
    if length(anapx)*length(anapy) < 1,  break;  end
    anamask = logical(anamask'); % transpose "mask"
    % now register the new roi
    N = length(RoiAdd) + 1;
    RoiAdd{N}.name  = roiname;
    RoiAdd{N}.slice = SLICE;
    %RoiAdd{N}.anamask  = anamask;
    %RoiAdd{N}.anapx    = anapx;
    %RoiAdd{N}.anapy    = anapy;
    RoiAdd{N}.px    = anapx * IMGDIMS.pxscale; 
    RoiAdd{N}.py    = anapy * IMGDIMS.pyscale; 
    if SAME_DIMS,
      RoiAdd{N}.mask     = anamask;
    else
      RoiAdd{N}.mask     = logical(round(imresize(double(anamask),IMGDIMS.epi)));
      %RoiAdd{N}.mask = poly2mask(RoiAdd{N}.px,RoiAdd{N}.py,IMGDIMS.epi(2),IMGDIMS.epi(1))';
    end

    % draw the polygon
    set(wgts.main,'CurrentAxes',wgts.ImageAxs);  hold on;
    plot(anapx,anapy,'color',[0.4 0.4 0.8]);
    x = min(anapx) - 4;  y = min(anapy) - 2; if x<0, x=1; end;
  end
  % now subtract the polygon from 'mask'
  for N = 1:length(RoiRoi)
    % must not be polygon
    if ~isempty(RoiRoi{N}.px),  continue;  end
    % the same name and the same slice
    if ~strcmp(RoiRoi{N}.name,roiname) || RoiRoi{N}.slice ~= SLICE,  continue;  end
    % ok modify it.
    for K = 1:length(RoiAdd)
      RoiRoi{N}.mask = RoiRoi{N}.mask | RoiAdd{K}.mask;
    end
  end

  setappdata(wgts.main,'RoiRoi',RoiRoi);

  % enable widgets
  set(wgts.RoiSelCmb,'Enable','on');
  set(wgts.RoiActCmb,'Enable','on');
  set(wgts.RoiLoadBtn,'Enable','on');
  set(wgts.RoiSaveBtn,'Enable','on');
  set(wgts.MarkerActCmb,'Enable','on');
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
  mroi_cursor('arrow');
  
  
 case {'erase bitmap'}
  % disable widgets
  set(wgts.RoiSelCmb,'Enable','off');
  set(wgts.RoiActCmb,'Enable','off');
  set(wgts.RoiLoadBtn,'Enable','off');
  set(wgts.RoiSaveBtn,'Enable','off');
  set(wgts.MarkerActCmb,'Enable','off');

  IMGDIMS = getappdata(wgts.main,'IMGDIMS');
  
  if all(IMGDIMS.ana == IMGDIMS.epi),
    SAME_DIMS = 1;
  else
    SAME_DIMS = 0;
  end

  RoiErase = {};
  while 1,
    % use 'timer' function to modify the cusor
    tmpcursor = get(wgts.RoiCursorCmb,'String');
    tmpcursor = tmpcursor{get(wgts.RoiCursorCmb,'Value')};
    tobj = timer('TimerFcn',sprintf('mroi_cursor(''%s'');',tmpcursor),...
                'StartDelay',0.2);
    start(tobj);
    % get roi
    try
      %[anamask,anapx,anapy] = roipoly;
      [anamask,anapx,anapy] = roipoly_71;
    catch
      % Note that Matlab 7.5 roipoly() will crash by right-click.
      % check user interaction
      click = get(wgts.main,'SelectionType');
      if strcmpi(click,'alt'),
        wait(tobj);  delete(tobj);
        break;
      else
        lasterr
      end
    end
    % delete the timer object and restore the cursor
    wait(tobj);  delete(tobj);
    
    % check user interaction
    click = get(wgts.main,'SelectionType');

    if strcmpi(click,'extend'),
      set(wgts.Sticky,'Value',0);
      %fprintf('click-extend');
      break;
    elseif strcmpi(click,'alt'),
      %fprintf('click-alt');
      break;
    else
      %fprintf('click-%s',click);
    end;

    % check size of poly, if very small ignore it.
    %length(anapx), length(anapy)
    if length(anapx)*length(anapy) < 1,  break;  end
    anamask = logical(anamask'); % transpose "mask"
    % now register the new roi
    N = length(RoiErase) + 1;
    RoiErase{N}.name  = roiname;
    RoiErase{N}.slice = SLICE;
    %RoiErase{N}.anamask  = anamask;
    %RoiErase{N}.anapx    = anapx;
    %RoiErase{N}.anapy    = anapy;
    RoiErase{N}.px    = anapx * IMGDIMS.pxscale; 
    RoiErase{N}.py    = anapy * IMGDIMS.pyscale; 
    if SAME_DIMS,
      RoiErase{N}.mask     = anamask;
    else
      RoiErase{N}.mask     = logical(round(imresize(double(anamask),IMGDIMS.epi)));
      %RoiErase{N}.mask = poly2mask(RoiErase{N}.px,RoiErase{N}.py,IMGDIMS.epi(2),IMGDIMS.epi(1))';
    end

    % draw the polygon
    set(wgts.main,'CurrentAxes',wgts.ImageAxs);  hold on;
    plot(anapx,anapy,'color',[0.4 0.4 0.8]);
    x = min(anapx) - 4;  y = min(anapy) - 2; if x<0, x=1; end;
  end
  % now subtract the polygon from 'mask'
  for N = 1:length(RoiRoi)
    % must not be polygon
    if ~isempty(RoiRoi{N}.px),  continue;  end
    % the same name and the same slice
    if ~strcmp(RoiRoi{N}.name,roiname) || RoiRoi{N}.slice ~= SLICE,  continue;  end
    % ok modify it.
    for K = 1:length(RoiErase)
      RoiRoi{N}.mask = RoiRoi{N}.mask & ~RoiErase{K}.mask;
    end
  end

  setappdata(wgts.main,'RoiRoi',RoiRoi);

  % enable widgets
  set(wgts.RoiSelCmb,'Enable','on');
  set(wgts.RoiActCmb,'Enable','on');
  set(wgts.RoiLoadBtn,'Enable','on');
  set(wgts.RoiSaveBtn,'Enable','on');
  set(wgts.MarkerActCmb,'Enable','on');
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
  mroi_cursor('arrow');
  
 case {'clear'}
  % clear the current ROI in this slice
  IDX = [];
  for N = 1:length(RoiRoi),
    if ~strcmp(RoiRoi{N}.name,roiname) || RoiRoi{N}.slice ~= SLICE,
      IDX(end+1) = N;
    end
  end
  setappdata(wgts.main,'RoiRoi',RoiRoi(IDX));
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
  
 case {'clear bitmap'}
  % clear the current ROI in this slice (only for bitmap ROIs)
  IDX = [];
  for N = 1:length(RoiRoi),
    if any(RoiRoi{N}.px) || ~strcmp(RoiRoi{N}.name,roiname) || RoiRoi{N}.slice ~= SLICE,
      IDX(end+1) = N;
    end
  end
  setappdata(wgts.main,'RoiRoi',RoiRoi(IDX));
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
 
 case {'clear all slices'}
  % clear the current ROI throughout slices
  IDX = [];
  for N = 1:length(RoiRoi),
    if ~strcmp(RoiRoi{N}.name,roiname),
      IDX(end+1) = N;
    end
  end
  if isempty(IDX),
    RoiRoi = {};
  else
    RoiRoi = RoiRoi(IDX);
  end
  setappdata(wgts.main,'RoiRoi',RoiRoi);
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);

 case {'clear all in the slice'}
  % clear all ROIs in the current slice
  IDX = [];
  for N = 1:length(RoiRoi),
    if RoiRoi{N}.slice ~= SLICE,
      IDX(end+1) = N;
    end
  end
  setappdata(wgts.main,'RoiRoi',RoiRoi(IDX));
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
  
 case {'clear others in the slice'}  
  % clear all ROIs in the current slice except the current ROI.
  IDX = [];
  for N = 1:length(RoiRoi),
    if RoiRoi{N}.slice ~= SLICE || strcmp(RoiRoi{N}.name,roiname),
      IDX(end+1) = N;
    end
  end
  setappdata(wgts.main,'RoiRoi',RoiRoi(IDX));
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
  
 case {'clear all slices (bitmap)'}
  % clear the current ROI throughout slices (only bitmap ROIs)
  IDX = [];
  for N = 1:length(RoiRoi),
    if any(RoiRoi{N}.px) || ~strcmp(RoiRoi{N}.name,roiname),
      IDX(end+1) = N;
    end
  end
  if isempty(IDX),
    RoiRoi = {};
  else
    RoiRoi = RoiRoi(IDX);
  end
  setappdata(wgts.main,'RoiRoi',RoiRoi);
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
  
 case {'clear ac','clear anterior commisure','clear ant.commisure'}
  % look for corresonding indices for electrodes in this slice
  IDX = [];
  for N = 1:length(RoiAC),
    if RoiAC{N}.slice ~= SLICE,
      IDX(end+1) = N;
    end
  end
  if isempty(IDX),
    RoiAC = {};
  else
    RoiAC = RoiAC(IDX);
  end
  setappdata(wgts.main,'RoiAC',RoiAC);
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);

 case {'clear midline'}
  RoiML = getappdata(wgts.main,'RoiML');
  % look for corresonding indices for electrodes in this slice
  IDX = [];
  for N = 1:length(RoiML),
    if RoiML{N}.slice ~= SLICE,
      IDX(end+1) = N;
    end
  end
  if isempty(IDX),
    RoiML = {};
  else
    RoiML = RoiML(IDX);
  end
  setappdata(wgts.main,'RoiML',RoiML);
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);

 case {'clear lr-separate','clear lr'}
  RoiLR = getappdata(wgts.main,'RoiLR');
  % look for corresonding indices for electrodes in this slice
  IDX = [];
  for N = 1:length(RoiLR),
    if RoiLR{N}.slice ~= SLICE,
      IDX(end+1) = N;
    end
  end
  if isempty(IDX),
    RoiLR = {};
  else
    RoiLR = RoiLR(IDX);
  end
  setappdata(wgts.main,'RoiLR',RoiLR);
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
  
 case {'clear electrodes'}
  % look for corresonding indices for electrodes in this slice
  IDX = [];
  for N = 1:length(RoiEle),
    if RoiEle{N}.slice ~= SLICE,
      IDX(end+1) = N;
    end
  end
  if isempty(IDX),
    RoiEle = {};
  else
    RoiEle = RoiEle(IDX);
  end
  setappdata(wgts.main,'RoiEle',RoiEle);
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
 
 case {'midline'}
  % disable widgets
  set(wgts.RoiSelCmb,'Enable','off');
  set(wgts.RoiActCmb,'Enable','off');
  set(wgts.RoiLoadBtn,'Enable','off');
  set(wgts.RoiSaveBtn,'Enable','off');
  set(wgts.MarkerActCmb,'Enable','off');
  % clear the points first
  % look for corresonding indices for electrodes in this slice
  IDX = [];
  for N = 1:length(RoiML),
    if RoiML{N}.slice ~= SLICE,
      IDX(end+1) = N;
    end
  end
  if isempty(IDX),
    RoiML = {};
  else
    RoiML = RoiML(IDX);
  end
  setappdata(wgts.main,'RoiML',RoiML);
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
  IMGDIMS = getappdata(wgts.main,'IMGDIMS');
  
  % This works too, but [y, x] = myginput(1,'fleur');
  % impixel is better for pixel coordinates
  for N = 1:1,
    % use 'timer' function to modify the cusor
    tmpcursor = get(wgts.RoiCursorCmb,'String');
    tmpcursor = tmpcursor{get(wgts.RoiCursorCmb,'Value')};
    tobj= timer('TimerFcn',sprintf('mroi_cursor(''%s'');',tmpcursor),...
                'StartDelay',0.1);
    start(tobj);
    % get the electrode position
    [x, y] = ginput(1);
    % delete the timer object and restore the cursor
    delete(tobj);  mroi_cursor('arrow');
    
    % check user interaction
    click = get(wgts.main,'SelectionType');
    if strcmp(click,'alt'),  continue;  end
    % check the size
    if isempty(x),  continue;  end
    K = length(RoiML) + 1;
    RoiML{K}.ele   = N;
    RoiML{K}.slice = SLICE;
    RoiML{K}.anax  = x;
    RoiML{K}.anay  = y;
    RoiML{K}.x  = round(RoiML{K}.anax * IMGDIMS.pxscale);
    RoiML{K}.y  = round(RoiML{K}.anay * IMGDIMS.pyscale);
    % plot the position
    set(wgts.main,'CurrentAxes',wgts.ImageAxs);  hold on;
    plot(x,y,'yx','markersize',12);
    text(x-5,y-5,'ML','color','y','fontsize',8);
  end
  set(wgts.ImageAxs,'tag','ImageAxs');
  setappdata(wgts.main,'RoiML',RoiML);
  % enable widgets
  set(wgts.RoiSelCmb,'Enable','on');
  set(wgts.RoiActCmb,'Enable','on');
  set(wgts.RoiLoadBtn,'Enable','on');
  set(wgts.RoiSaveBtn,'Enable','on');
  set(wgts.MarkerActCmb,'Enable','on');
 

 case {'ant.commisure'}
  % disable widgets
  set(wgts.RoiSelCmb,'Enable','off');
  set(wgts.RoiActCmb,'Enable','off');
  set(wgts.RoiLoadBtn,'Enable','off');
  set(wgts.RoiSaveBtn,'Enable','off');
  set(wgts.MarkerActCmb,'Enable','off');
  % clear the points first
  % look for corresonding indices for electrodes in this slice
  IDX = [];
  for N = 1:length(RoiAC),
    if RoiAC{N}.slice ~= SLICE,
      IDX(end+1) = N;
    end
  end
  if isempty(IDX),
    RoiAC = {};
  else
    RoiAC = RoiAC(IDX);
  end
  setappdata(wgts.main,'RoiAC',RoiAC);
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
  IMGDIMS = getappdata(wgts.main,'IMGDIMS');
  
  % This works too, but [y, x] = myginput(1,'fleur');
  % impixel is better for pixel coordinates
  for N = 1:1,
    % use 'timer' function to modify the cusor
    tmpcursor = get(wgts.RoiCursorCmb,'String');
    tmpcursor = tmpcursor{get(wgts.RoiCursorCmb,'Value')};
    tobj= timer('TimerFcn',sprintf('mroi_cursor(''%s'');',tmpcursor),...
                'StartDelay',0.1);
    start(tobj);
    % get the electrode position
    [x, y] = ginput(1);
    % delete the timer object and restore the cursor
    delete(tobj);  mroi_cursor('arrow');
    
    % check user interaction
    click = get(wgts.main,'SelectionType');
    if strcmp(click,'alt'),  continue;  end
    % check the size
    if isempty(x),  continue;  end
    K = length(RoiAC) + 1;
    RoiAC{K}.ele   = N;
    RoiAC{K}.slice = SLICE;
    RoiAC{K}.anax  = x;
    RoiAC{K}.anay  = y;
    RoiAC{K}.x  = round(RoiAC{K}.anax * IMGDIMS.pxscale);
    RoiAC{K}.y  = round(RoiAC{K}.anay * IMGDIMS.pyscale);
    % plot the position
    set(wgts.main,'CurrentAxes',wgts.ImageAxs);  hold on;
    plot(x,y,'yx','markersize',12);
    text(x-5,y-5,'AC','color','y','fontsize',8);
  end
  set(wgts.ImageAxs,'tag','ImageAxs');
  setappdata(wgts.main,'RoiAC',RoiAC);
  % enable widgets
  set(wgts.RoiSelCmb,'Enable','on');
  set(wgts.RoiActCmb,'Enable','on');
  set(wgts.RoiLoadBtn,'Enable','on');
  set(wgts.RoiSaveBtn,'Enable','on');
  set(wgts.MarkerActCmb,'Enable','on');

 case {'lr-separate'}
  % disable widgets
  set(wgts.RoiSelCmb,'Enable','off');
  set(wgts.RoiActCmb,'Enable','off');
  set(wgts.RoiLoadBtn,'Enable','off');
  set(wgts.RoiSaveBtn,'Enable','off');
  set(wgts.MarkerActCmb,'Enable','off');
  % clear the points first
  % look for corresonding indices for electrodes in this slice
  IDX = [];
  for N = 1:length(RoiLR),
    if RoiLR{N}.slice ~= SLICE,
      IDX(end+1) = N;
    end
  end
  if isempty(IDX),
    RoiLR = {};
  else
    RoiLR = RoiLR(IDX);
  end
  setappdata(wgts.main,'RoiLR',RoiLR);
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
  IMGDIMS = getappdata(wgts.main,'IMGDIMS');
  
  % This works too, but [y, x] = myginput(1,'fleur');
  % impixel is better for pixel coordinates
  for N = 1:1,
    % use 'timer' function to modify the cusor
    tmpcursor = get(wgts.RoiCursorCmb,'String');
    tmpcursor = tmpcursor{get(wgts.RoiCursorCmb,'Value')};
    tobj= timer('TimerFcn',sprintf('mroi_cursor(''%s'');',tmpcursor),...
                'StartDelay',0.2);
    start(tobj);
    % get a line 
    try
      %[anamask,anapx,anapy] = roipoly;
      [anamask,anapx,anapy] = roipoly_71;
    catch
      % Note that Matlab 7.5 roipoly() will crash by right-click.
      % check user interaction
      click = get(wgts.main,'SelectionType');
      if strcmpi(click,'alt'),
        wait(tobj);  delete(tobj);
        break;
      else
        lasterr
      end
    end
    % delete the timer object and restore the cursor
    wait(tobj);  delete(tobj);
    
    % check user interaction
    click = get(wgts.main,'SelectionType');
    if strcmpi(click,'extend'),
      set(wgts.Sticky,'Value',0);
      %fprintf('click-extend');
      break;
    elseif strcmpi(click,'alt'),
      %fprintf('click-alt');
      break;
    else
      %fprintf('click-%s',click);
    end;
    % check the size
    if length(anapx) < 2, break;  end
    anapx = anapx(1:2);
    anapy = anapy(1:2);
    K = length(RoiLR) + 1;
    RoiLR{K}.ele   = N;
    RoiLR{K}.slice = SLICE;
    RoiLR{K}.anax  = anapx;
    RoiLR{K}.anay  = anapy;
    RoiLR{K}.x  = round(anapx * IMGDIMS.pxscale);
    RoiLR{K}.y  = round(anapy * IMGDIMS.pyscale);
    % plot the position
    set(wgts.main,'CurrentAxes',wgts.ImageAxs);  hold on;
    plot(anapx,anapy,'color','r');
    text(anapx(1),anapy(1),'LR','color','y','fontsize',8);
  end
  set(wgts.ImageAxs,'tag','ImageAxs');
  setappdata(wgts.main,'RoiLR',RoiLR);

  % enable widgets
  set(wgts.RoiSelCmb,'Enable','on');
  set(wgts.RoiActCmb,'Enable','on');
  set(wgts.RoiLoadBtn,'Enable','on');
  set(wgts.RoiSaveBtn,'Enable','on');
  set(wgts.MarkerActCmb,'Enable','on');
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
  mroi_cursor('arrow');
  
 case {'electrodes'}
  if ~isfield(grp,'hardch') || isempty(grp.hardch),
    return;
  end
  
  % disable widgets
  set(wgts.RoiSelCmb,'Enable','off');
  set(wgts.RoiActCmb,'Enable','off');
  set(wgts.RoiLoadBtn,'Enable','off');
  set(wgts.RoiSaveBtn,'Enable','off');
  set(wgts.MarkerActCmb,'Enable','off');
  % clear the points first
  % look for corresonding indices for electrodes in this slice
  IDX = [];
  for N = 1:length(RoiEle),
    if RoiEle{N}.slice ~= SLICE,
      IDX(end+1) = N;
    end
  end  
  if isempty(IDX),
    RoiEle = {};
  else
    RoiEle = RoiEle(IDX);
  end
  setappdata(wgts.main,'RoiEle',RoiEle);
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
  IMGDIMS = getappdata(wgts.main,'IMGDIMS');
  
  % This works too, but [y, x] = myginput(1,'fleur');
  % impixel is better for pixel coordinates
  for N = 1:length(grp.hardch),
    % use 'timer' function to modify the cusor
    tmpcursor = get(wgts.RoiCursorCmb,'String');
    tmpcursor = tmpcursor{get(wgts.RoiCursorCmb,'Value')};
    tobj= timer('TimerFcn',sprintf('mroi_cursor(''%s'');',tmpcursor),...
                'StartDelay',0.1);
    start(tobj);
    % get the electrode position
    [x, y] = ginput(1);
    % delete the timer object and restore the cursor
    delete(tobj);  mroi_cursor('arrow');
    
    % check user interaction
    click = get(wgts.main,'SelectionType');
    if strcmp(click,'alt'),  continue;  end
    % check the size
    if isempty(x),  continue;  end
    K = length(RoiEle) + 1;
    RoiEle{K}.ele   = N;
    RoiEle{K}.slice = SLICE;
    RoiEle{K}.anax  = x;
    RoiEle{K}.anay  = y;
    RoiEle{K}.x  = round(RoiEle{K}.anax * IMGDIMS.pxscale);
    RoiEle{K}.y  = round(RoiEle{K}.anay * IMGDIMS.pyscale);
    % plot the position
    set(wgts.main,'CurrentAxes',wgts.ImageAxs);  hold on;
    plot(x,y,'y+','markersize',12);
    VALS = sprintf('e%d[%4.1f,%4.1f]', N, x, y);
    text(x-5,y-5,VALS,'color','y','fontsize',8);
  end
  set(wgts.ImageAxs,'tag','ImageAxs');
  setappdata(wgts.main,'RoiEle',RoiEle);
  % enable widgets
  set(wgts.RoiSelCmb,'Enable','on');
  set(wgts.RoiActCmb,'Enable','on');
  set(wgts.RoiLoadBtn,'Enable','on');
  set(wgts.RoiSaveBtn,'Enable','on');
  set(wgts.MarkerActCmb,'Enable','on');
 
 case {'complete clear'}
  % clear ROIs completely
  setappdata(wgts.main,'RoiRoi',{});
  setappdata(wgts.main,'RoiEle',{});
  setappdata(wgts.main,'RoiML',{});
  setappdata(wgts.main,'RoiAC',{});
  setappdata(wgts.main,'RoiLR',{});
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
  
end  
  
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sub function of CALLBACK for UNDO-ACTION
function subUndoCommand(wgts,DO_BACKUP)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

LastRoiAction = getappdata(wgts.main,'LastRoiAction');
switch lower(LastRoiAction),
 case {'append','replace','add bitmap','erase bitmap',...
       'clear','clear all slices',...
       'clear all in the slice','clear others in the slice',...
       'clear bitmap', 'clear all slices (bitmap)'}
  setappdata(wgts.main,'RoiRoi',getappdata(wgts.main,'RoiRoi_bak'));
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
 case {'electrodes','clear electrodes'}
  setappdata(wgts.main,'RoiEle',getappdata(wgts.main,'RoiEle_bak'));
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
  
 case {'ant.commisure' 'clear ant.commisure'}
  setappdata(wgts.main,'RoiAC',getappdata(wgts.main,'RoiAC_bak'));
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
 case {'midline','clear midline'}
  setappdata(wgts.main,'RoiML',getappdata(wgts.main,'RoiML_bak'));
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
 case {'lr-separate' 'clear lr-separate'}
  setappdata(wgts.main,'RoiLR',getappdata(wgts.main,'RoiLR_bak'));
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
  
 case {'complete clear'}
  setappdata(wgts.main,'RoiRoi',getappdata(wgts.main,'RoiRoi_bak'));
  setappdata(wgts.main,'RoiEle',getappdata(wgts.main,'RoiEle_bak'));
  setappdata(wgts.main,'RoiAC',getappdata(wgts.main,'RoiAC_bak'));
  setappdata(wgts.main,'RoiML',getappdata(wgts.main,'RoiML_bak'));
  setappdata(wgts.main,'RoiLR',getappdata(wgts.main,'RoiLR_bak'));
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
 otherwise
  LastRoiAction = '';
  
end

set(wgts.StatusField,'String',sprintf('%s LastRoiAction=''%s''',get(wgts.StatusField,'String'),LastRoiAction));

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sub function of CALLBACK for Markers
function Marker_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
funcname = mfilename('fullpath');
[ST, I] = dbstack;
n = findstr(ST(I).name,'(');
if any(n),
cbname = ST(I).name(n+1:end-1);
else
cbname = ST(I).name;
end

wgts = guihandles(hObject);
switch lower(eventdata),
 case {'marker-show'}
  h  = findobj(wgts.ImageAxs,'tag','roi-marker');
  h2 = findobj(wgts.Image2Axs,'tag','roi-marker');
  if get(wgts.MarkerCheck,'value') > 0,
    set(h, 'visible','on');
    set(h2,'visible','on');
  else
    set(h, 'visible','off');
    set(h2,'visible','off');
  end
 case {'marker-action'}
  COMMANDSTR = get(wgts.MarkerActCmb,'String');
  COMMANDSTR = COMMANDSTR{get(wgts.MarkerActCmb,'Value')};
  subMarkerCommand(COMMANDSTR,wgts);
end

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sub function of CALLBACK for Marker-Action
function subMarkerCommand(COMMANDSTR,wgts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ses = getappdata(wgts.main,'Ses');
grp = getappdata(wgts.main,'Grp');

RoiMarker = getappdata(wgts.main,'RoiMarker');
SLICE   = round(get(wgts.SliceBarSldr,'Value'));
actions = get(wgts.MarkerActCmb,'String');

% reset the mouse event to avoid matlab returns
% a funny state of it...
set(wgts.main,'SelectionType','normal');

set(wgts.main,'CurrentAxes',wgts.ImageAxs);

switch lower(COMMANDSTR),
 case {'clear'}
  RoiMarker = getappdata(wgts.main,'RoiMarker');
  % look for corresonding indices for markers in this slice
  IDX = [];
  for N = 1:length(RoiMarker),
    if RoiMarker{N}.slice ~= SLICE,
      IDX(end+1) = N;
    end
  end
  if isempty(IDX),
    RoiMarker = {};
  else
    RoiMarker = RoiMarker(IDX);
  end
  setappdata(wgts.main,'RoiMarker',RoiMarker);
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);

 case {'lus','ios','sts','ls','ips','cs','as','ps',...
       'cas','pos','apos','cgs',...
       'ots','pmts','amts','rs' }
  % disable widgets
  set(wgts.RoiSelCmb,'Enable','off');
  set(wgts.RoiActCmb,'Enable','off');
  set(wgts.RoiLoadBtn,'Enable','off');
  set(wgts.RoiSaveBtn,'Enable','off');
  set(wgts.MarkerActCmb,'Enable','off');
  % clear the points first
  % look for corresonding indices for electrodes in this slice
  IDX = [];
  for N = 1:length(RoiMarker),
    if RoiMarker{N}.slice == SLICE && strcmpi(RoiMarker{N}.name,COMMANDSTR)
      IDX(end+1) = N;
    end
  end
  if any(IDX),
    RoiMarker(IDX) = [];
    setappdata(wgts.main,'RoiMarker',RoiMarker);
  end
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
  IMGDIMS = getappdata(wgts.main,'IMGDIMS');
  
  % This works too, but [y, x] = myginput(1,'fleur');
  % impixel is better for pixel coordinates
  for N = 1:1,
    % use 'timer' function to modify the cusor
    tmpcursor = get(wgts.RoiCursorCmb,'String');
    tmpcursor = tmpcursor{get(wgts.RoiCursorCmb,'Value')};
    tobj= timer('TimerFcn',sprintf('mroi_cursor(''%s'');',tmpcursor),...
                'StartDelay',0.1);
    start(tobj);
    % get the electrode position
    [x, y] = ginput(1);
    % delete the timer object and restore the cursor
    delete(tobj);  mroi_cursor('arrow');
    
    % check user interaction
    click = get(wgts.main,'SelectionType');
    if strcmp(click,'alt'),  continue;  end
    % check the size
    if isempty(x),  continue;  end
    K = length(RoiMarker) + 1;
    RoiMarker{K}.name  = COMMANDSTR;
    RoiMarker{K}.slice = SLICE;
    RoiMarker{K}.anax  = x;
    RoiMarker{K}.anay  = y;
    RoiMarker{K}.x  = round(RoiMarker{K}.anax * IMGDIMS.pxscale);
    RoiMarker{K}.y  = round(RoiMarker{K}.anay * IMGDIMS.pyscale);
    % plot the position
    set(wgts.main,'CurrentAxes',wgts.ImageAxs);  hold on;
    text(x,y,COMMANDSTR,'color','y','fontsize',8,'tag','roi-marker');
    set(wgts.main,'CurrentAxes',wgts.Image2Axs);  hold on;
    text(RoiMarker{K}.x,RoiMarker{K}.y,COMMANDSTR,'color','y','fontsize',8,'tag','roi-marker');
  end
  set(wgts.ImageAxs,'tag','ImageAxs');
  set(wgts.Image2Axs,'tag','Image2Axs');
  setappdata(wgts.main,'RoiMarker',RoiMarker);
  % enable widgets
  set(wgts.RoiSelCmb,'Enable','on');
  set(wgts.RoiActCmb,'Enable','on');
  set(wgts.RoiLoadBtn,'Enable','on');
  set(wgts.RoiSaveBtn,'Enable','on');
  set(wgts.MarkerActCmb,'Enable','on');
  %Main_Callback(wgts.SliceBarSldr,'roidraw-epi',[]);
 
 case {'complete clear'}
  % clear ROIs completely
  setappdata(wgts.main,'RoiMarker',{});
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);

 case {'reset cursor'}
  set(wgts.main,'Pointer','arrow');
  
end  

% set to 'no action'
set(wgts.MarkerActCmb,'Value',1);


return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function StatusPrint(hObject,fname,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmp = sprintf(varargin{:});
if any(fname),
  tmp = sprintf('%s.%s : %s',mfilename,fname,tmp);
end
wgts = guihandles(hObject);
set(wgts.StatusField,'String',tmp);
drawnow;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Print_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
funcname = mfilename('fullpath');
[ST, I] = dbstack;
n = findstr(ST(I).name,'(');
if any(n),
cbname = ST(I).name(n+1:end-1);
else
cbname = ST(I).name;
end

wgts = guihandles(hObject);

ses = getappdata(wgts.main,'Ses');
grp = getappdata(wgts.main,'Grp');
goto(ses);
tmp = gettimestring;
tmp(findstr(tmp,':')) = '_';
OutFile = sprintf('%s_%s_%s',ses.name,grp.name,tmp);
StatusPrint(hObject,cbname,OutFile);

orient landscape;
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');
set(gcf,'InvertHardCopy',		'off');

if 0,
papersize = get(gcf, 'PaperSize');
width = papersize(1) * 0.8;
height = papersize(2) * 0.8;
left = (papersize(1)- width)/2;
bottom = (papersize(2)- height)/2;
myfiguresize = [left, bottom, width, height]
set(gcf, 'PaperPosition', myfiguresize);
end;

switch lower(eventdata),
 case {'print'},
  % print the figure
  print;
 case {'printdlg'},
  % show a printer-setup dialog
  printdlg;
 case {'pagesetupdlg'},
  % show a page-setup dialog
  pagesetupdlg;
 case {'meta'}
  % export as meta
  print('-dmeta',OutFile);
 case {'tiff'}
  % export as tiff
  print('-dtiff',OutFile);
 case {'jpeg'}
  % export as jpeg
  print('-djpeg',OutFile);
 case {'copy-figure'}
  % copy the figure to the clipboard
  print('-dmeta');
  
 otherwise
  StatusPrint(hObject,cbname,'Wrong Printer Parameters');
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SetFunBtn(hMain,HX,HY,TagName,Label)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cb = sprintf('mroi(''Main_Callback'',gcbo,''%s'',guidata(gcbo))',...
            Label);
POS = [HX HY 16 1.55];
COL = [1 .9 .6];
H = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',POS,'Callback',cb,...
    'Tag',TagName,'String',Label,...
    'TooltipString','Process Data (Filter Operations)','FontWeight','bold',...
    'ForegroundColor',[0 0 .1],'BackgroundColor',COL);
evalin('caller',sprintf('%s=H;',TagName));

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SetRadioBtn(hMain,HX,HY,TagName,Label)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cb = sprintf('mroi(''RadioButton_Callback'',gcbo,''%s'',guidata(gcbo))',...
            TagName);
POS = [HX HY 18 1.52];
FCOL = [1 0 0];
BCOL = [1 1 .8];
H = uicontrol(...
'Parent',hMain,...
'Style','radiobutton',...
'Units','characters',...
'String',Label,...
'Position',POS,...
'BackgroundColor',BCOL,...
'ForegroundColor',FCOL,...
'Callback',cb,...
'ListboxTop',0,...
'TooltipString','',...
'Tag',TagName);
evalin('caller',sprintf('%s=H;',TagName));


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to validate ROI structure to most updated format.
function Roi = subValidateRoi(wgts,Roi,ses)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(Roi.roi),  return;  end

IMGDIMS = getappdata(wgts.main,'IMGDIMS');
% remove non-sense ROIs
selidx = 1:length(Roi.roi);
for N = 1:length(Roi.roi),
  if ~isfield(Roi.roi{N},'mask') || isempty(find(Roi.roi{N}.mask(:) > 0)),
    selidx(N) = NaN;
  end
end
selidx = find(~isnan(selidx));
if length(selidx) ~= length(Roi.roi),
  Roi.roi = Roi.roi(selidx);
end

% 1. fix upper/lower case of ROI names
% 2. scale px/py if needed, now .px/py is for functional image, no longer for anatomy.
for N = 1:length(Roi.roi),
  % FIX ROINAME'S UPPER/LOWER CASE, sometime lgn renamed as LGN and so on...
  % idx = find(strcmpi(ses.roi.names,Roi.roi{N}.name));
  % if ~isempty(idx),
  %   Roi.roi{N}.name = ses.roi.names{idx(1)};
  % end
  % SCALE PX/PY
  [px,py] = find(Roi.roi{N}.mask);
  % +1 may need due to imresize() operated mask.
  if floor(max(Roi.roi{N}.px)) > max(px)+1 & floor(max(Roi.roi{N}.py)) > max(py)+1,
    % likely px/py is for anatomy and not for functional image.
    % first convert for the current anatomy
    Roi.roi{N}.px      = Roi.roi{N}.px * IMGDIMS.ana(1) / IMGDIMS.anaorig(1);
    Roi.roi{N}.py      = Roi.roi{N}.py * IMGDIMS.ana(2) / IMGDIMS.anaorig(2);
    % not convert anatomy to functional
    Roi.roi{N}.px      = Roi.roi{N}.px * IMGDIMS.pxscale;
    Roi.roi{N}.py      = Roi.roi{N}.py * IMGDIMS.pyscale;
  end
  if isfield(Roi.roi{N},'anamask'),
    Roi.roi{N} = rmfield(Roi.roi{N},'anamask');
  end
  if size(Roi.roi{N}.mask,1) ~= IMGDIMS.epi(1) || size(Roi.roi{N}.mask,2) ~= IMGDIMS.epi(2),
    % imgcrop may changed after mroi()...
    if any(Roi.roi{N}.px)
      tmpbw = poly2mask(Roi.roi{N}.px,Roi.roi{N}.py,IMGDIMS.epi(2),IMGDIMS.epi(1));
      Roi.roi{N}.mask = tmpbw';  % (y,x) --> (x,y)
    end
  end
  
  Roi.roi{N}.mask = logical(Roi.roi{N}.mask);
end

% scale anax/anay, if needed
if isfield(Roi,'ele'),
  for N = 1:length(Roi.ele),
    tmpx = round(Roi.ele{N}.anax * IMGDIMS.pxscale);
    if tmpx ~= Roi.ele{N}.anax,
      Roi.ele{N}.anax = Roi.ele{N}.x / IMGDIMS.pxscale;
      Roi.ele{N}.anay = Roi.ele{N}.y / IMGDIMS.pyscale;
    end
  end
end
  
  
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to handle annoying 'Brain','brain'
function Roi = subValidateBrain(wgts,Roi,ses)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
idx = find(strcmpi(ses.roi.names,'brain'));
if isempty(idx),  return;  end
idx = idx(1);
for R = 1:length(Roi.roi),
  if strcmpi(Roi.roi{R}.name,'brain'),
    Roi.roi{R}.name = ses.roi.names{idx};
  end
end  

return




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to validate ROI structure to most updated format.
function RoiEle = subUpdateEle(wgts,ses,RoiVar)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RoiEle   = {};
IMGDIMS = getappdata(wgts.main,'IMGDIMS');

grpnames = fieldnames(ses.grp);
for N = 1:length(grpnames),
  tmpgrp = ses.grp.(grpnames{N});
  if ~isfield(tmpgrp,'grproi') || ~strcmpi(tmpgrp.grproi,RoiVar),  continue;  end
  if isfield(tmpgrp,'ele') && isfield(tmpgrp.ele,'mcoords') && ~isempty(tmpgrp.ele.mcoords),
    fprintf(' %s : ROI.ele was updated by "ele.mcoords".\n',mfilename);
    RoiEle = {};
    for N = 1:size(tmpgrp.ele.mcoords,1),
      RoiEle{N}.ele = N;
      RoiEle{N}.slice = tmpgrp.ele.mcoords(N,3);
      RoiEle{N}.anax  = tmpgrp.ele.mcoords(N,1) / IMGDIMS.pxscale;
      RoiEle{N}.anay  = tmpgrp.ele.mcoords(N,2) / IMGDIMS.pyscale;;
      RoiEle{N}.x     = tmpgrp.ele.mcoords(N,1);
      RoiEle{N}.y     = tmpgrp.ele.mcoords(N,2);
    end
    break;
  end
end



return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to draw anatomical image
function anaimg = subScaleAnaImage(hObject,wgts,anaimg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
anasclstr = get(wgts.AnaScaleEdt,'String');
anaimg = double(anaimg);
if get(wgts.AutoAnaScale,'Value'),
  AnaScale = [min(anaimg(:)) max(anaimg(:))*0.8];
  set(wgts.AnaScaleEdt,'String',sprintf('%g  %g',AnaScale(1),AnaScale(2)));
  setappdata(wgts.main,'AnaScale',AnaScale);
else
  anasclstr = strrep(anasclstr,'[','');
  anasclstr = strrep(anasclstr,'[','');
  if length(str2num(anasclstr)) == 2,
    AnaScale = str2num(anasclstr);
    setappdata(wgts.main,'AnaScale',AnaScale);
  else
    [ST, I] = dbstack;
    n = findstr(ST(I).name,'(');
    if any(n),
      cbname = ST(I).name(n+1:end-1);
    else
      cbname = ST(I).name;
    end
    StatusPrint(hObject,cbname,'WARNING: Invalid AnaScale');
    AnaScale = getappdata(wgts.main,'AnaScale');
  end
end
 
if isempty(AnaScale),
  minv = min(anaimg(:));  maxv = max(anaimg(:));
else
  minv = AnaScale(1);     maxv = AnaScale(2);
end

% scale image 0 to 1
anaimg = double(anaimg);
anaimg = (anaimg - minv) ./ (maxv - minv);
anaimg(anaimg(:) < 0) = 0;
anaimg(anaimg(:) > 1) = 1;

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to draw ROIs for anatomy
function subDrawAnaROIs(wgts,RoiRoi,RoiEle,ses,SLICE,COLORS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~ishandle(wgts.ImageAxs),  return;  end
RoiDraw = get(wgts.RoiDrawCmb,'String');
RoiDraw = RoiDraw{get(wgts.RoiDrawCmb,'Value')};

RoiML  = getappdata(wgts.main,'RoiML');
RoiAC  = getappdata(wgts.main,'RoiAC');
RoiLR  = getappdata(wgts.main,'RoiLR');
RoiMarker = getappdata(wgts.main,'RoiMarker');

MarkerSize = str2double(get(wgts.MarkerSizeEdt,'String'));

IMGDIMS = getappdata(wgts.main,'IMGDIMS');

DO_DRAW = zeros(1,length(RoiRoi));
switch lower(RoiDraw)
 case {'all'}
  for N = 1:length(RoiRoi)
    if RoiRoi{N}.slice ~= SLICE, continue;  end
    DO_DRAW(N) = 1;
  end
  
 case {'all rois'}
  CurRoiName = get(wgts.RoiSelCmb, 'String');
  for N = 1:length(RoiRoi)
    if RoiRoi{N}.slice ~= SLICE, continue;  end
    if ~any(strcmp(RoiRoi{N}.name,CurRoiName)),  continue;  end
    DO_DRAW(N) = 1;
  end
  
 case {'all polygons'}
  CurRoiName = get(wgts.RoiSelCmb,'String');
  CurRoiName = CurRoiName{get(wgts.RoiSelCmb,'Value')};
  for N = 1:length(RoiRoi)
    if RoiRoi{N}.slice ~= SLICE, continue;  end
    if any(strcmp(RoiRoi{N}.name,CurRoiName)),
      DO_DRAW(N) = 1;
      continue;
    end
    if isempty(RoiRoi{N}.px) || isempty(RoiRoi{N}.py),  continue;  end
    DO_DRAW(N) = 1;
  end
 
 case {'current'}
  CurRoiName = get(wgts.RoiSelCmb,'String');
  CurRoiName = CurRoiName{get(wgts.RoiSelCmb,'Value')};
  for N = 1:length(RoiRoi)
    if RoiRoi{N}.slice ~= SLICE, continue;  end
    if ~any(strcmp(RoiRoi{N}.name,CurRoiName)),  continue;  end
    DO_DRAW(N) = 1;
  end
end


for N = 1:length(RoiRoi),
  if DO_DRAW(N) == 0,  continue;  end
    
  roiname = RoiRoi{N}.name;
  px      = RoiRoi{N}.px / IMGDIMS.pxscale;
  py      = RoiRoi{N}.py / IMGDIMS.pyscale;
  % draw the polygon
  %axes(wgts.ImageAxs); hold on;
  set(wgts.main,'CurrentAxes',wgts.ImageAxs);  hold on;
  cidx = find(strcmp(ses.roi.names,roiname));
  if isempty(cidx),  cidx = 1;  end
  cidx = mod(cidx(1),length(COLORS)) + 1;
  if isempty(px) || isempty(py),
    tmpimg = imresize(double(RoiRoi{N}.mask),IMGDIMS.ana,'nearest');
    [px,py] = find(tmpimg);
    plot(px,py,'color',COLORS(cidx),'linestyle','none',...
         'marker','s','markersize',MarkerSize,'tag','roi',...
         'markeredgecolor','none','markerfacecolor',COLORS(cidx));
  else
    ROI_LINE_WIDTH = 3;
    %plot(px,py,'color','w','tag','roi','linewidth',ROI_LINE_WIDTH); hold on;
    %plot(px,py,'color',COLORS(cidx),'tag','roi','linewidth',1.5);
    plot(px,py,'color',COLORS(cidx),'tag','roi');
    hold off;
  end;
  x = min(px) - 4;  y = min(py) - 2; if x<0, x=1; end;
  % x = px(1) - 2;  y = py(1) - 2;
  text(x,y,strrep(strrep(roiname,'_','\_'),'^','\^'),'color',COLORS(cidx),'fontsize',10,'tag','roi','fontweight','bold');
end

if ~any(strcmpi(RoiDraw,{'none'}))
  % draw electrodes
  for N = 1:length(RoiEle)
    if RoiEle{N}.slice ~= SLICE, continue;  end
    ele = RoiEle{N}.ele;
    if get(wgts.EpiAnaCheck,'value') > 0,
      x   = RoiEle{N}.x;
      y   = RoiEle{N}.y;
    else
      x   = RoiEle{N}.anax;
      y   = RoiEle{N}.anay;
    end      
    % plot the position
    %axes(wgts.ImageAxs); hold on;
    set(wgts.main,'CurrentAxes',wgts.ImageAxs);  hold on;
    plot(x,y,'y+','markersize',12,'tag','roi');
    VALS = sprintf('e%d[%4.1f,%4.1f]', ele, x, y);
    text(x-5,y-5,VALS,'color','y','fontsize',8,'tag','roi');
  end
  % draw midline
  for N = 1:length(RoiML)
    if RoiML{N}.slice ~= SLICE, continue;  end
    ele = RoiML{N}.ele;
    if get(wgts.EpiAnaCheck,'value') > 0,
      x   = RoiML{N}.x;
      y   = RoiML{N}.y;
    else
      x   = RoiML{N}.anax;
      y   = RoiML{N}.anay;
    end
    % plot the position
    %axes(wgts.ImageAxs); hold on;
    set(wgts.main,'CurrentAxes',wgts.ImageAxs);  hold on;
    plot(x,y,'yx','markersize',12,'tag','roi');
    text(x-5,y-5,'ML','color','y','fontsize',8,'tag','roi');
  end
  % draw ant.commisure
  for N = 1:length(RoiAC)
    if RoiAC{N}.slice ~= SLICE, continue;  end
    ele = RoiAC{N}.ele;
    if get(wgts.EpiAnaCheck,'value') > 0,
      x   = RoiAC{N}.x;
      y   = RoiAC{N}.y;
    else
      x   = RoiAC{N}.anax;
      y   = RoiAC{N}.anay;
    end
    % plot the position
    %axes(wgts.ImageAxs); hold on;
    set(wgts.main,'CurrentAxes',wgts.ImageAxs);  hold on;
    plot(x,y,'yx','markersize',12,'tag','roi');
    text(x-5,y-5,'AC','color','y','fontsize',8,'tag','roi');
  end
  % draw LR-separation
  for N = 1:length(RoiLR),
    if RoiLR{N}.slice ~= SLICE, continue;  end
    ele = RoiLR{N}.ele;
    if get(wgts.EpiAnaCheck,'value') > 0,
      x   = RoiLR{N}.x;
      y   = RoiLR{N}.y;
    else
      x   = RoiLR{N}.anax;
      y   = RoiLR{N}.anay;
    end
    % plot the position
    %axes(wgts.ImageAxs); hold on;
    set(wgts.main,'CurrentAxes',wgts.ImageAxs);  hold on;
    plot(x,y,'color','r','tag','roi');
    text(x(1),y(1),'LR','color','y','fontsize',8,'tag','roi');
  end
  
  % draw markers
  tmpvis = get(wgts.MarkerCheck,'value');
  for N = 1:length(RoiMarker),
    if RoiMarker{N}.slice ~= SLICE, continue;  end
    tmptxt = RoiMarker{N}.name;
    if get(wgts.EpiAnaCheck,'value') > 0,
      x   = RoiMarker{N}.x;
      y   = RoiMarker{N}.y;
    else
      x   = RoiMarker{N}.anax;
      y   = RoiMarker{N}.anay;
    end
    % plot the position
    set(wgts.main,'CurrentAxes',wgts.ImageAxs);  hold on;
    tmph = text(x(1),y(1),tmptxt,'color','y','fontsize',8,'tag','roi-marker');
    if ~tmpvis, set(tmph,'visible','off');  end
  end
end

curanaImg = getappdata(wgts.main,'curanaImg');

set(wgts.ImageAxs,'YDir','reverse');
set(wgts.ImageAxs,...
    'xlim',[0.5 size(curanaImg.dat,1)+0.5],...
    'ylim',[0.5 size(curanaImg.dat,2)+0.5]);
                  

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to draw ROIs for functional image
function subDrawEpiROIs(wgts,RoiRoi,RoiEle,ses,SLICE,COLORS,IMGDIMS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~ishandle(wgts.Image2Axs),  return;  end
RoiDraw = get(wgts.RoiDrawEpiCmb,'String');
RoiDraw = RoiDraw{get(wgts.RoiDrawEpiCmb,'Value')};
if strcmpi(RoiDraw,'none'),  return;  end

RoiML  = getappdata(wgts.main,'RoiML');
RoiAC  = getappdata(wgts.main,'RoiAC');
RoiLR  = getappdata(wgts.main,'RoiLR');
RoiMarker = getappdata(wgts.main,'RoiMarker');

MarkerSize = str2double(get(wgts.MarkerSizeEdt,'String'));


DO_DRAW = zeros(1,length(RoiRoi));
switch lower(RoiDraw)
 case {'all'}
  for N = 1:length(RoiRoi)
    if RoiRoi{N}.slice ~= SLICE, continue;  end
    DO_DRAW(N) = 1;
  end
  
 case {'all rois'}
  CurRoiName = get(wgts.RoiSelCmb, 'String');
  for N = 1:length(RoiRoi)
    if RoiRoi{N}.slice ~= SLICE, continue;  end
    if ~any(strcmp(RoiRoi{N}.name,CurRoiName)),  continue;  end
    DO_DRAW(N) = 1;
  end
  
 case {'all polygons'}
  CurRoiName = get(wgts.RoiSelCmb,'String');
  CurRoiName = CurRoiName{get(wgts.RoiSelCmb,'Value')};
  for N = 1:length(RoiRoi)
    if RoiRoi{N}.slice ~= SLICE, continue;  end
    if any(strcmp(RoiRoi{N}.name,CurRoiName)),
      DO_DRAW(N) = 1;
      continue;
    end
    if isempty(RoiRoi{N}.px) || isempty(RoiRoi{N}.py),  continue;  end
    DO_DRAW(N) = 1;
  end
 
 case {'current'}
  CurRoiName = get(wgts.RoiSelCmb,'String');
  CurRoiName = CurRoiName{get(wgts.RoiSelCmb,'Value')};
  for N = 1:length(RoiRoi)
    if RoiRoi{N}.slice ~= SLICE, continue;  end
    if ~any(strcmp(RoiRoi{N}.name,CurRoiName)),  continue;  end
    DO_DRAW(N) = 1;
  end
end


for N = 1:length(RoiRoi),
  if DO_DRAW(N) == 0,  continue;  end

  roiname = RoiRoi{N}.name;

  % 01.06.04 TO SEE THE RoiDef_Act !!!
  SEE_USERROI_AND_XCOR_RESULT = 0;    %Debugging
  if SEE_USERROI_AND_XCOR_RESULT,
    DIMS = [size(tcImg.dat,1) size(tcImg.dat,2)];
    [maskx,masky] = find(RoiRoi{N}.mask);
    if all(size(Roi.roi{N}.mask)==DIMS),
      if ~isfield(anaImg,'EpiAnatomy') || ~anaImg.EpiAnatomy,
        % 06.06.05 YM: WHY SAVING ANATOMY IMAGES NOT MASK HERE?????
        if 0,          
          Roi.roi{N}.anamask = curanaImg.dat(:,:,SLICE);
        end
        continue;
      end;
    end;
    %axes(wgts.Image2Axs); hold on;
    set(wgts.main,'CurrentAxes',wgts.Image2Axs);  hold on;
    cidx = find(strcmp(ses.roi.names,roiname));
    cidx = mod(cidx(1),length(COLORS)) + 1;
    plot(maskx,masky,'linestyle','none','marker','s',...
         'markersize',2,'tag','roi','markerfacecolor',COLORS(cidx),...
         'markeredgecolor',COLORS(cidx));
  end;

  if isempty(RoiRoi{N}.px) || isempty(RoiRoi{N}.py),
    [px,py] = find(RoiRoi{N}.mask);
  else
    px = RoiRoi{N}.px;
    py = RoiRoi{N}.py;
  end;
  % draw the polygon
  %axes(wgts.Image2Axs); hold on;
  set(wgts.main,'CurrentAxes',wgts.Image2Axs);  hold on;
  cidx = find(strcmp(ses.roi.names,roiname));
  if isempty(cidx),  cidx = 1;  end
  cidx = mod(cidx(1),length(COLORS)) + 1;
  if isempty(RoiRoi{N}.px) || isempty(RoiRoi{N}.py),
    plot(px,py,'color',COLORS(cidx),'linestyle','none',...
         'marker','s','markersize',MarkerSize,'tag','roi','markerfacecolor',COLORS(cidx));
  else
    plot(px,py,'color',COLORS(cidx),'tag','roi');
  end;
  x = min(px) - 4;  y = min(py) - 2; if x<0, x=1; end;
  %x = px(1) - 2;  y = py(1) - 2;
  % text(x,y,strrep(strrep(roiname,'_','\_'),'^','\^'),'color',COLORS(cidx),'fontsize',8);
end

if ~any(strcmpi(RoiDraw,{'none'}))
  % draw electrodes
  for N = 1:length(RoiEle)
    if RoiEle{N}.slice ~= SLICE, continue;  end
    ele = RoiEle{N}.ele;
    x   = RoiEle{N}.x;
    y   = RoiEle{N}.y;
    %axes(wgts.Image2Axs); hold on;
    set(wgts.main,'CurrentAxes',wgts.Image2Axs);
    hold(wgts.Image2Axs,'on');
    plot(x,y,'y+','markersize',12,'tag','roi');
    VALS = sprintf('e%d[%4.1f,%4.1f]', ele, x, y);
    text(x-5,y-5,VALS,'color','y','fontsize',8,'tag','roi');
  end
  % draw midline
  for N = 1:length(RoiML)
    if RoiML{N}.slice ~= SLICE, continue;  end
    ele = RoiML{N}.ele;
    x   = RoiML{N}.x;
    y   = RoiML{N}.y;
    %axes(wgts.Image2Axs); hold on;
    set(wgts.main,'CurrentAxes',wgts.Image2Axs);  hold on;
    plot(x,y,'yx','markersize',12,'tag','roi');
    text(x-5,y-5,'ML','color','y','fontsize',8,'tag','roi');
  end
  % draw ant.commisure
  for N = 1:length(RoiAC)
    if RoiAC{N}.slice ~= SLICE, continue;  end
    ele = RoiAC{N}.ele;
    x   = RoiAC{N}.x;
    y   = RoiAC{N}.y;
    %axes(wgts.Image2Axs); hold on;
    set(wgts.main,'CurrentAxes',wgts.Image2Axs);  hold on;
    plot(x,y,'yx','markersize',12,'tag','roi');
    text(x-5,y-5,'AC','color','y','fontsize',8,'tag','roi');
  end
  % draw LR-separation
  for N = 1:length(RoiLR)
    if RoiLR{N}.slice ~= SLICE, continue;  end
    ele = RoiLR{N}.ele;
    x   = RoiLR{N}.x;
    y   = RoiLR{N}.y;
    %axes(wgts.Image2Axs); hold on;
    set(wgts.main,'CurrentAxes',wgts.Image2Axs);  hold on;
    plot(x,y,'color','r','tag','roi');
    text(x(1),y(1),'LR','color','y','fontsize',8,'tag','roi');
  end

  % draw markers
  tmpvis = get(wgts.MarkerCheck,'value');
  for N = 1:length(RoiMarker),
    if RoiMarker{N}.slice ~= SLICE, continue;  end
    tmptxt = RoiMarker{N}.name;
    x   = RoiMarker{N}.x;
    y   = RoiMarker{N}.y;
    % plot the position
    set(wgts.main,'CurrentAxes',wgts.Image2Axs);  hold on;
    tmph = text(x(1),y(1),tmptxt,'color','y','fontsize',8,'tag','roi-marker');
    if ~tmpvis, set(tmph,'visible','off');  end
  end
end

curImg = getappdata(wgts.main,'curImg');

set(wgts.Image2Axs,'YDir','reverse');
set(wgts.Image2Axs,...
    'xlim',[0.5 size(curImg.dat,1)+0.5],...
    'ylim',[0.5 size(curImg.dat,2)+0.5]);


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to average only stable images
function tcImg = subDoCentroidAverage(tcImg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TCENT = mcentroid(tcImg.dat);
TCENT = TCENT';  % (xyz,t) --> (t,xyz)
  
m = mean(TCENT);
s = std(TCENT);

% to avoid "divide by zero"
idx = find(s == 0);
TCENT(idx,:) = 0;
s(idx) = 1;

for N = 1:3,
  TCENT(:,N) = (TCENT(:,N) - m(N)) / s(N);
end
TCENT = abs(TCENT);

if numel(tcImg.dat)*8 > 400e+6,
  idx = find(TCENT(:,1) < 2.0 & TCENT(:,2) < 2.0 & TCENT(:,3) < 2.0);
  imgsz = size(tcImg.dat);
  mdat = zeros(imgsz(1:3));
  Nlen = length(idx);
  for N = 1:length(idx),
    mdat = mdat + tcImg.dat(:,:,:,idx(N))/Nlen;
  end
  tcImg.dat = mdat;
else
  idx = find(TCENT(:,1) > 2.0 | TCENT(:,2) > 2.0 | TCENT(:,3) > 2.0);
  %fprintf('(%d/%d)',length(idx),size(tcImg.dat,4));
  if ~isempty(idx),
    tcImg.dat(:,:,:,idx) = [];
  end
  tcImg.dat = mean(tcImg.dat,4);
end
  
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% checks if the given number is within limits and gives back a valid number
function erg=checklimits(test,xmin,xmax,odd,default)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if odd
    if ~mod(test,2) %if test is an odd number
        test=test+1;
    end
end
if test<xmin
    erg=xmin;
elseif test>xmax
    erg=xmax;
else
    erg=test;
end
if exist('default','var') && test~=erg % if a default value is entered take this instead of limits
    erg=default;
end
return;
