function varargout = imgviewer(varargin)
%IMGVIEWER - Browse 2dseq or tcImg Image-Data
% varargout = IMGVIEWER (varargin) is a GUI to browse image data
% and test analysis steps.
% PURPOSE : GUI for viewing MRI scans
% USAGE :   imgviewer
% INFO :    
%
% *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
% IMMEDIATE TODOs or CURRENTLY WORKING ON:
% *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
% ** IMGVIEWER - This function must now be optimized to show
%       different types of imaging data; At this point, the
%       following requirements are obvious (there will be more as
%       we write-debug the session):
%       (a) Image anatomy files in lightbox/orthogonal views
%       (b) Image controls scans; probably we'll need to
%       incorporate the showepi13-type of function in the viewer;
%       (c) Show vitals; the vital are included here (we may want
%       to put them also into other modules) because the imaging
%       data are the ones that suffer most from the respritation
%       and cardiac pulses;
%       (d) showimginfo should also come into this module
%       (e) qview type of display (already exists in primitive
%       form), showing all time points (like in movie) for all
%       slices;
%       (f) dspimg functionality to observer time courses
%       (g) statistics module showing all image statistics
%       (h) Histology and animal information
%       (j) Tripilot scans
%       (i) if possible, a good mdeft should be defined for each
%       animal; preferably also the skull-scan and implant-related
%       figures;
%       --- In addition, we have to think of how to incorporate
%       displays related to the dependence analysis etc.
% INCLUDE:
% DSPEPI13 - Display multislice "EPI13" test functional data
% DSPIMG - time series and images
% SHOWCSCAN - Show control scans (eg "epi13", tcimg, etc)
% SHOWASCAN - Show control scans (eg "epi13", tcimg, etc)
% SHOWPULSE - Shows Neural responses to very short pulse-stimuli
% SHOWBPULSE - Shows "BOLD" responses to very short pulse-stimuli
% SHOWRVWAVE - Demonstrates how to use the resorting of the data
%
% *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
% COMPLETED TASKS
% *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
%
%  VERSION :
%    0.90 11.12.03 YM  first release
%    0.91 20.04.04 YM  bug fix
%    0.93 19.09.08 YM  adapted for new csession class.
%
%  See also dgzviewer adfviewer

persistent H_IMGVIEWER;    % keep the figure handle

if nargin == 0,  help imgviewer;  return;  end

% execute callback function
if isstr(varargin{1}) & ~isempty(findstr(varargin{1},'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return
end

SESSION = '';  IMGFILE = '';
% invoked from 'mgui' or console.
if isempty(which(varargin{1})),
  % never supported.
  % varargin{1} as a 'IMGFILE'
  % imgviewer('//wks8/.../2dseq')
  IMGFILE = varargin{1};
else
  % imgviewer('b01mn3',2)
  SESSION = varargin{1};
  if nargin >= 2,
    EXPNO = varargin{2};
  else
    EXPNO = [];
  end
end


%% prevent double execution
if ishandle(H_IMGVIEWER),
  close(H_IMGVIEWER);
  %fprintf('\n ''imgviewer'' already opened.\n');
  %return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CREATE THE MAIN WINDOW
% Reminder: get(0,'DefaultUicontrolBackgroundColor')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[scrW scrH] = getScreenSize('char');
figW = 216.0;  figH =  61.0;
figX = 31.0;   figY = scrH-figH-3;  % 3 for menu and title bars.
hMain = figure(...
    'Name','GUI for MRI Analysis','NumberTitle','off', ...
    'Tag','main', 'MenuBar', 'none', ...
    'HandleVisibility','callback','Resize','off',...
    'DoubleBuffer','on', 'Visible','off',...
    'Units','char','Position',[figX figY figW figH],...
    'Color',[0.8 0.83 0.83]);
H_IMGVIEWER = hMain;
if ~isempty(SESSION), setappdata(hMain,'session',SESSION);  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PULL-DOWN MENU [File Edit View Help]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- FILE
hMenuFile = uimenu(hMain,'Label','File');
uimenu(hMenuFile,'Label','Exit','Separator','on',...
       'Callback','imgviewer(''Main_Callback'',gcbo,''exit'',[])');

% --- EDIT
hMenuEdit = uimenu(hMain,'Label','Edit');
uimenu(hMenuEdit,'Label','imgviewer : main GUI',...
       'UserData','imgviewer','Callback',...
       'imgviewer(''Main_Callback'',gcbo,''edit-gui'',[])');
uimenu(hMenuEdit,'Label','getpvpars : Paravision Parameters',...
       'UserData','getpvpars','Callback',...
       'imgviewer(''Main_Callback'',gcbo,''edit-gui'',[])');
uimenu(hMenuEdit,'Label','gettripilot : Read/Show Tripilot Scan',...
       'UserData','gettripilot','Callback',...
       'imgviewer(''Main_Callback'',gcbo,''edit-gui'',[])');
uimenu(hMenuEdit,'Label','imgload : Make tcImg Structure',...
       'UserData','imgload','Callback',...
       'imgviewer(''Main_Callback'',gcbo,''edit-gui'',[])');
uimenu(hMenuEdit,'Label','read2dseq : Read 2dseq File',...
       'UserData','read2dseq','Callback',...
       'imgviewer(''Main_Callback'',gcbo,''edit-gui'',[])');

% --- VIEW
hMenuView = uimenu(hMain,'Label','View');
uimenu(hMenuView,'Label','Redraw',...
       'Callback','imgviewer(''Plot_Callback'',gcbo,[],[])');
uimenu(hMenuView,'Label','2x2','UserData',[2 2],...
       'Tag','LB2x2','Callback','imgviewer(''View_Callback'',gcbo,[],[])');
uimenu(hMenuView,'Label','4x4','UserData',[4 4],...
       'Tag','LB4x4','Callback','imgviewer(''View_Callback'',gcbo,[],[])');
uimenu(hMenuView,'Label','8x8','UserData',[8 8],...
       'Tag','LB8x8','Callback','imgviewer(''View_Callback'',gcbo,[],[])');

% --- FIGURES
hMenuView = uimenu(hMain,'Label','Figures');
hNature = uimenu(hMenuView,'Label','Nature 2001');
uimenu(hNature,'Label','Figure 1a: Site & Spectrograms',...
       'UserData','n1fig1b00',...
       'Callback','imgviewer(''Figure_Callback'',gcbo,[],[])');
uimenu(hNature,'Label','Figure 1b: Site & Spectrograms',...
       'UserData','n1fig1a00',...
       'Callback','imgviewer(''Figure_Callback'',gcbo,[],[])');
uimenu(hNature,'Label','Figure 2: SNR & Avg Spectrogram',...
       'UserData','n1fig2',...
       'Callback','imgviewer(''Figure_Callback'',gcbo,[],[])');

% --- HELP
hMenuHelp = uimenu(hMain,'Label','Help');
uimenu(hMenuHelp,'Label','Analysis Package','Callback','helpwin');
uimenu(hMenuHelp,'Label','imgviewer','Separator','on',...
       'Callback','helpwin imgviewer');
uimenu(hMenuHelp,'Label','SesHelp','Callback','seshelp');
uimenu(hMenuHelp,'Label','ToDo''s','Callback','sestodo');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UI SESSION-CONTROL   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = figH - 2.2;
% LABEL - Session:
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[0.5 H-0.2 12 1.5],...
    'String','Session :','FontWeight','bold',...
    'HorizontalAlignment','right',...
    'BackgroundColor',get(hMain,'Color'));
% ENTRY - Enter here the session name
SessionEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[14 H 23 1.5],...
    'Callback','imgviewer(''Session_Callback'',gcbo,''set'',guidata(gcbo))',...
    'String','session','Tag','SessionEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','set the session',...
    'FontWeight','bold','BackgroundColor','white');
% BROWSE BUTTON - Invokes the path/file finder (Select File to Open)
SessionBrowseBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[37 H 4 1.5],...
    'Callback','imgviewer(''Session_Callback'',gcbo,''browse'',guidata(gcbo))',...
    'Tag','SessionBrowseBtn',...
    'TooltipString','Browse a session',...
    'ForegroundColor','white','BackgroundColor','white');
mguiSetIcon(SessionBrowseBtn,'stock_open16x16.png');        % THE ICON
% EDIT DESCRIPTION-FILE BUTTON - Invokes Emacs session.m
SessionEditBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[41 H 4 1.5],...
    'Callback','imgviewer(''Session_Callback'',gcbo,''edit'',guidata(gcbo))',...
    'Tag','SessionEditBtn',...
    'TooltipString','Edit the session',...
    'ForegroundColor','white','BackgroundColor','white');
mguiSetIcon(SessionEditBtn,'stock_edit16x16.png');
%---------------------------------------------------
% PRESS TO LOAD OUR DEFAULT DEBUG-SESSION
%---------------------------------------------------
SessionDefaultBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[48 H-1 24 2.2],...
    'Callback','imgviewer(''Session_Callback'',gcbo,''default'',[])',...
    'Tag','SessionDefaultBtn','String','Debug-Session',...
    'TooltipString','set to default','FontWeight','bold',...
    'ForegroundColor',[1 1 0],'BackgroundColor',[0.3 0 0.1]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UI GROUP-CONTROL     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = H - 1.8;
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[0.5 H-0.2 12 1.5],...
    'String','Group :','FontWeight','bold',...
    'HorizontalAlignment','right',...
    'BackgroundColor',get(hMain,'Color'));
GroupCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[14 H 23 1.5],...
    'String',{'group'},...
    'Callback','imgviewer(''Group_Callback'',gcbo,''select'',[])',...
    'TooltipString','group selection',...
    'Tag','GroupCmb','FontWeight','Bold');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UI EXPNO-CONTROL     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = H - 1.8;
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[0.5 H-0.2 12 1.5],...
    'String','Exps :','FontWeight','bold',...
    'HorizontalAlignment','right',...
    'BackgroundColor',get(hMain,'Color'));
ExpNoEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[14 H 62 1.5],...
    'Callback','imgviewer(''ExpNoEdt_Callback'',gcbo,[],[])',...
    'String','exp. numbers','Tag','ExpNoEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','set exp. number(s)',...
    'FontWeight','Bold');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UI 2dseq FILE-ENTRIES      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = H - 3;  FILEX = 10;
uicontrol(...                                   % LABEL
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[0.5 H-0.2 9 1.5],...
    'String','2dseq :','FontWeight','bold',...
    'HorizontalAlignment','right',...
    'BackgroundColor',get(hMain,'Color'));
DataFileEdt = uicontrol(...                     % ENTRY
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[FILEX H 56 1.5],...
    'String','unnamed','Tag','DataFileEdt',...
    'HorizontalAlignment','left','FontWeight','normal',...
    'TooltipString','2dseq file');
DataBrowseBtn = uicontrol(...                   % BROWSE BUTTON
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[67 H 4 1.5],...
    'Callback','imgviewer(''Data_Callback'',gcbo,''browse'',guidata(gcbo))',...
    'Tag','DataBrowseBtn',...
    'TooltipString','Browse a session',...
    'ForegroundColor','white','BackgroundColor','white');
mguiSetIcon(DataBrowseBtn,'stock_open16x16.png');
DataLoadBtn = uicontrol(...                     % LOAD-FILE BUTTON
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[71 H 4 1.5],...
    'Callback','imgviewer(''Data_Callback'',gcbo,''load'',guidata(gcbo))',...
    'Tag','DataLoadBtn',...
    'TooltipString','Load data',...
    'ForegroundColor','white','BackgroundColor','white');
mguiSetIcon(DataLoadBtn,'stock_insert-slide16x16.png');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UI MAT (tcImg) FILE-ENTRIES    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = H - 2;
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[0.5 H-0.2 9 1.5],...
    'String','tcImg :','FontWeight','bold',...
    'HorizontalAlignment','right',...
    'BackgroundColor',get(hMain,'Color'));
MatDataFileEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[FILEX H 56 1.5],...
    'String','unnamed','Tag','MatDataFileEdt',...
    'HorizontalAlignment','left','FontWeight','normal',...
    'TooltipString','2dseq file');
MatDataBrowseBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[67 H 4 1.5],...
    'Callback','imgviewer(''Data_Callback'',gcbo,''matbrowse'',guidata(gcbo))',...
    'Tag','MatDataBrowseBtn',...
    'TooltipString','Browse a session',...
    'ForegroundColor','white','BackgroundColor','white');
mguiSetIcon(MatDataBrowseBtn,'stock_open16x16.png');
MatDataLoadBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[71 H 4 1.5],...
    'Callback','imgviewer(''Data_Callback'',gcbo,''matload'',guidata(gcbo))',...
    'Tag','MatDataLoadBtn',...
    'TooltipString','Load data',...
    'ForegroundColor','white','BackgroundColor','white');
mguiSetIcon(MatDataLoadBtn,'stock_insert-slide16x16.png');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IMAGE PARAMETERS DEFINED BY CHECK-BOXES  %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = H - 4;
ProcsBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[2 H 40 2],...
    'Callback','mgui_script(''Script_Callback'',gcbo,''batch'',[])',...
    'String','Image Processing Parameters','Tag','ProcsBtn',...
    'FontWeight','bold',...
    'TooltipString','Run ''sesbatch'' for the current session',...
    'BackgroundColor',[0 0.2 0.1],'ForegroundColor',[1 1 1]);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SELECTION OF TEXT/SCRIPT TO DISPLAY (SESSION, GROUP, PV-PARS)  %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = H - 3.5;
uicontrol(...
    'Parent',hMain,'Style','frame',...
    'Units','char','Position',[1.5 0.5 74.5 H+2.5],...
    'ForegroundColor','black','BackgroundColor',[.7 .7 .8]);
InfoCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[50 H+1.1 25 1.5],...
    'String',{'Session','Group','Pvpars'},...
    'Callback','imgviewer(''Main_Callback'',gcbo,''selectinf'',[])',...
    'HorizontalAlignment','left',...
    'TooltipString','info selection',...
    'Tag','InfoCmb','FontWeight','Bold');
InfoTxt = uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','char','Position',[2 3.5 73 H-2.7],...
    'String',{'session','group'},...
    'Callback','imgviewer(''Main_Callback'',gcbo,''edit-info'',[])',...
    'HorizontalAlignment','left','FontName','Courier New',...
    'FontSize',9,'Tag','InfoTxt','Background','white');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[2 1 9 1.5],...
    'String','Status :','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'BackgroundColor','black','ForegroundColor','red');
ErrorTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[12 1 63 1.5],...
    'String','normal',...
    'Callback','imgviewer(''Main_Callback'',gcbo,''edit-info'',[])',...
    'HorizontalAlignment','left','FontWeight','bold',...
    'Tag','ErrorTxt','Background','white','ForegroundColor','b');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONTROLS ON TOP OF THE ACTUAL IMAGE-DISPLAY WINDOW   %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
BUTX = 80;              BUTW = 6;
BUTY = figH-3.5;        BUTH = 2;
DataViewCmb = uicontrol(...                         % ACTUAL VIEW-COMBO
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[BUTX BUTY-0.25 23 BUTH],...
    'String',{'LightBox','Orthogonal'},...
    'Callback','imgviewer(''Plot_Callback'',gcbo,[],[])',...
    'TooltipString','view selection',...
    'Tag','DataViewCmb','FontWeight','Bold');
DataRedrawBtn = uicontrol(...                       % REDRAW/REFRESH IMAGES
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[BUTX+24 BUTY BUTW BUTH],...
    'Callback','imgviewer(''Plot_Callback'',gcbo,[],guidata(gcbo))',...
    'Tag','DataRedrawBtn',...
    'TooltipString','Redraw images',...
    'ForegroundColor','white','BackgroundColor','white');
mguiSetIcon(DataRedrawBtn,'stock_refresh16x16.png');
DataCropBtn = uicontrol(...                         % CROPPING
    'Parent',hMain,'Units','char','Position',[BUTX+30 BUTY BUTW BUTH],...
    'Callback','imgviewer(''Data_Callback'',gcbo,''crop'',guidata(gcbo))',...
    'Tag','DataCropBtn',...
    'TooltipString','Crop data',...
    'ForegroundColor','white','BackgroundColor','white');
mguiSetIcon(DataCropBtn,'stock_crop16x16.png');
DataRoiBtn = uicontrol(...                          % ROI DEFINITION
    'Parent',hMain,'Units','char','Position',[BUTX+36 BUTY BUTW BUTH],...
    'Callback','imgviewer(''Data_Callback'',gcbo,''roi'',guidata(gcbo))',...
    'Tag','DataRoiBtn',...
    'TooltipString','Roi selection',...
    'ForegroundColor','white','BackgroundColor','white');
mguiSetIcon(DataRoiBtn,'stock_draw-polygon16x16.png');

% TRIPILOT
BUTX = 168.5;       BUTW = 8;
BUTY = figH-3.8;    BUTH = 3;
TripilotBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[BUTX BUTY BUTW BUTH],...
    'Callback','imgviewer(''TopBtn_Callback'',gcbo,''TriPilot'',guidata(gcbo))',...
    'Tag','TripilotBtn',...
    'TooltipString','Load Tripilot Scan',...
    'ForegroundColor','white','BackgroundColor','white');
mguiSetIcon(TripilotBtn,'tripilot.bmp');

BUTX = BUTX + 9;
MdeftBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[BUTX BUTY BUTW BUTH],...
    'Callback','imgviewer(''TopBtn_Callback'',gcbo,''init'',guidata(gcbo))',...
    'Tag','MdeftBtn',...
    'TooltipString','Load MDEFT Scan',...
    'ForegroundColor','white','BackgroundColor','white');
mguiSetIcon(MdeftBtn,'mrianat40x40.bmp');

BUTX = BUTX + 9;
FuncBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[BUTX BUTY BUTW BUTH],...
    'Callback','imgviewer(''TopBtn_Callback'',gcbo,''init'',guidata(gcbo))',...
    'Tag','FuncBtn',...
    'TooltipString','Load Funclogy Slices',...
    'ForegroundColor','white','BackgroundColor','white');
mguiSetIcon(FuncBtn,'FuncScan.bmp');

BUTX = BUTX + 9;
HistoBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[BUTX BUTY BUTW BUTH],...
    'Callback','imgviewer(''TopBtn_Callback'',gcbo,''init'',guidata(gcbo))',...
    'Tag','HistoBtn',...
    'TooltipString','Load Histology Slices',...
    'ForegroundColor','white','BackgroundColor','white');
mguiSetIcon(HistoBtn,'histology.bmp');

BUTX = BUTX + 9;
MonkPhotooBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[BUTX BUTY BUTW BUTH],...
    'Callback','imgviewer(''TopBtn_Callback'',gcbo,''init'',guidata(gcbo))',...
    'Tag','MonkPhotooBtn',...
    'TooltipString','Load MonkPhotoology Slices',...
    'ForegroundColor','white','BackgroundColor','white');
mguiSetIcon(MonkPhotooBtn,'MonkPhoto.bmp');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AXIS FOR LIGHTBOX/ORTHO VIEWS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XDSP = 80;
XDSPLEN = 132;
LBOX_Y = 2.5;
AxsFrame = axes(...
    'Parent',hMain,'Units','char','color',get(hMain,'color'),'xtick',[],...
    'ytick',[],'Position',[XDSP 2.3 XDSPLEN+1 figH-6.3],...
    'Box','on','linewidth',1.5,'xcolor','r','ycolor','r');
LightBoxAxs = axes(...
    'Parent',hMain,'Tag','LightBoxAxs',...
    'Units','char','Position',[XDSP+0.5 LBOX_Y XDSPLEN-0.1 figH-6.7],...
    'xticklabel','','yticklabel','','xtick',[],'ytick',[],...
    'Color','black','layer','top');
TimeBarTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP 0.3 20 1.5],...
    'String','Volume: 1','FontWeight','bold',...
    'HorizontalAlignment','left','Tag','TimeBarTxt',...
    'BackgroundColor',get(hMain,'Color'));
TimeBarSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[XDSP+20 0.4 113 1.5],...
    'Callback','imgviewer(''Plot_Callback'',gcbo,[],[])',...
    'Tag','TimeBarSldr','SliderStep',[0.1 0.2],...
    'TooltipString','Time Points (Volumes)');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AXES for Orhtogonal display
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 28; XSZ = 55; YSZ = 20;
XDSP=XDSP+10;
SagitalTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H+YSZ 15 1.5],...
    'String','Sagital','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','SagitalTxt',...
    'BackgroundColor',get(hMain,'Color'));
SagitalEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+15 H+YSZ+0.2 8 1.5],...
    'Callback','imgviewer(''Plot_Callback'',gcbo,[],[])',...
    'String','','Tag','SagitalEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set sagital slice',...
    'FontWeight','Bold');
SagitalSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[XDSP+XSZ*0.6 H+YSZ+0.2 XSZ*0.4 1.2],...
    'Callback','imgviewer(''SagitalSldr_Callback'',gcbo,[],guidata(gcbo))',...
    'Tag','SagitalSldr','SliderStep',[1 4],...
    'TooltipString','sagital slice');
SagitalAxs = axes(...
    'Parent',hMain,'Tag','SagitalAxs',...
    'Units','char','Position',[XDSP H XSZ YSZ],...
    'Box','off','Color','black');

H = 3;
CoronalTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H+YSZ 15 1.5],...
    'String','Coronal','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','CoronalTxt',...
    'BackgroundColor',get(hMain,'Color'));
CoronalEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+15 H+YSZ+0.2 8 1.5],...
    'Callback','imgviewer(''Plot_Callback'',gcbo,[],[])',...
    'String','','Tag','CoronalEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set coronal slice',...
    'FontWeight','Bold');
CoronalSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[XDSP+XSZ*0.6 H+YSZ+0.2 XSZ*0.4 1.2],...
    'Callback','imgviewer(''CoronalSldr_Callback'',gcbo,[],guidata(gcbo))',...
    'Tag','CoronalSldr','SliderStep',[1 4],...
    'TooltipString','coronal slice');
CoronalAxs = axes(...
    'Parent',hMain,'Tag','CoronalAxs',...
    'Units','char','Position',[XDSP H XSZ YSZ],...
    'Box','off','Color','black');
TransverseTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+10+XSZ H+YSZ 15 1.5],...
    'String','Transverse','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','TransverseTxt',...
    'BackgroundColor',get(hMain,'Color'));
TransverseEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+10+XSZ+15 H+YSZ+0.2 8 1.5],...
    'Callback','imgviewer(''Plot_Callback'',gcbo,[],[])',...
    'String','','Tag','TransverseEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set transverse slice',...
    'FontWeight','Bold');
TransverseSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[XDSP+10+XSZ*1.6 H+YSZ+0.2 XSZ*0.4 1.2],...
    'Callback','imgviewer(''TransverseSldr_Callback'',gcbo,[],guidata(gcbo))',...
    'Tag','TransverseSldr','SliderStep',[1 4],...
    'TooltipString','transverse slice');
TransverseAxs = axes(...
    'Parent',hMain,'Tag','TransverseAxs',...
    'Units','char','Position',[XDSP+10+XSZ H XSZ YSZ],...
    'Box','off','Color','black');

% orthogonal flags
H = 40;
CrosshairChk = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+10+XSZ+5 H 35 1.5],...
    'String','Show Crosshairs','FontWeight','bold',...
    'Tag','CrosshairChk','Value',1,...
    'HorizontalAlignment','left',...
    'BackgroundColor',get(hMain,'Color'));

% set widgets for 'orthogonal' invisible
set([SagitalTxt,CoronalTxt,TransverseTxt],'visible','off');
set([SagitalSldr,CoronalSldr,TransverseSldr],'visible','off');
set([SagitalEdt,CoronalEdt,TransverseEdt],'visible','off');
set([SagitalAxs,CoronalAxs,TransverseAxs],'visible','off');
set(CrosshairChk,'visible','off');

% initialize the application.
%imgviewer('Main_Callback',hMain,'init');
Main_Callback(hMain,'init');

if ~isempty(SESSION),
  [fpath,froot,fext] = fileparts(which(SESSION));
  set(SessionEdt,'String',froot);
  Session_Callback(SessionEdt,'set',guidata(SessionEdt));
  if ~isempty(EXPNO),
    set(ExpNoEdt,'String',deblank(sprintf('%d ',EXPNO)));
    Data_Callback(DataFileEdt,'init',[]);
    Main_Callback(hMain,'selectinf',[]);
  end
else
end

set(hMain,'Visible','on');

% for debug
%wgts = guihandles(hMain)

% returns the window handle if needed.
if nargout,
  varargout{1} = hMain;
end

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ============================================================================
%                           CALLBACK FUNCTIONS
% ============================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Main_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% hObject    handle to togglebutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wgts = guihandles(hObject);
switch lower(eventdata),
 case {'init'}
  
 case {'exit'}
  close(wgts.main);
 case {'viewinfo'}
  pos = get(wgts.main,'position');
  if strcmpi(get(wgts.MenuViewShowInfo,'checked'),'off'),
    pos(3) = 140;
    set(wgts.MenuViewShowInfo,'checked','on');
    set(wgts.ViewInfoBtn,'String','<<');
  else
    pos(3) = 64;
    set(wgts.MenuViewShowInfo,'checked','off');
    set(wgts.ViewInfoBtn,'String','>>');
  end
  set(wgts.main,'position',pos);
 case {'selectinf'}
  info = get(wgts.InfoCmb,'String');
  info = info{get(wgts.InfoCmb,'Value')};
  switch lower(info)
   case {'session'}
    tmptxt = getappdata(wgts.main,'sesinfo');
   case {'group'}
    tmptxt = getappdata(wgts.main,'grpinfo');
   case {'pvpars','pvpar'}
    tmptxt = getappdata(wgts.main,'pvparinfo');
   otherwise
    tmptxt = '';
  end
  % update session info
  set(wgts.InfoTxt,'String',tmptxt,'Value',1);
  
 case {'set'}
 
 case {'edit-gui'}
  edit(get(hObject,'UserData'));
 
 case {'edit-info'}
  % check double-click or not
  if ~strcmp(get(wgts.main,'SelectionType'),'open'), return;  end
  info = get(wgts.InfoCmb,'String');
  info = info{get(wgts.InfoCmb,'Value')};
  token = get(wgts.InfoTxt,'String');
  switch lower(info),
    case {'pvpars','pvpar'}
     return;
   otherwise
    editfile = which(get(wgts.SessionEdt,'String'));
    token = strtok(token{get(wgts.InfoTxt,'Value')});
  end

  if isempty(editfile) | ~exist(editfile,'file'),
    fprintf(' imgviewer.Main_Callback: ''%s'' not found.\n');
    return;
  end
  mguiEdit(editfile,token);
  
 otherwise
  
end
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Session_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% hObject    handle to togglebutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wgts = guihandles(get(hObject,'Parent'));
sesfile = which(get(wgts.SessionEdt,'String'));
switch lower(eventdata),
 case { 'init'}
 case {'default'}
  set(wgts.SessionEdt,'String','m02lx1');
  Session_Callback(wgts.SessionEdt,'set',[]);
 case { 'browse','open' }
  if exist(sesfile) ~= 2,
    dirs = getdirs;
    sesfile = fullfile(dirs.sesdir,'*.m');
  end
  [sesfile,pathname] = uigetfile(sesfile);
  if isequal(sesfile,0) | isequal(pathname,0)
    % canceled
  else
    [fpath,froot,fext] = fileparts(sesfile);
    set(wgts.SessionEdt,'String',froot);
    Session_Callback(wgts.SessionEdt,'set',guidata(wgts.SessionEdt));
  end
 case { 'edit' }
  if exist(sesfile) == 2,
    eval(sprintf('edit %s;',sesfile));
  else
    edit;
  end
 case { 'set','editbox','select','cmbbox' }
  % update group/exp.no
  set(wgts.GroupCmb,'String',{'group'});
  set(wgts.ExpNoEdt,'String','');
  if exist(sesfile) ~= 2,
    fprintf(' imgviewer.Session_Callback : ''%s.m'' not found.\n',sesfile);
  end
  [fpath,froot,fext] = fileparts(sesfile);
  eval(sprintf('clear %s;',froot));  % To keep updated.
  Ses = goto(froot,1);      % The second argument suppresses Ver-Message

  % get help discription
  helplines = {};  k = 1;
  tmptxt = eval(sprintf('help(''%s'');',froot));
  idx = findstr(tmptxt,sprintf('\n'));
  s = 0;
  for n = 1:length(idx),
    tmpline = cat(2,'%',tmptxt(s+2:idx(n)-1));
    if length(findstr(tmpline,'%')) ~= length(tmpline),
      helplines{k} = tmpline;
      k = k + 1;
    end
    s = idx(n);
  end

  % load text lines
  %tmplines = txt_read(which(froot));
  tmplines = {}; k = 1;
  fid = fopen(which(froot));
  while 1
    if feof(fid), break; end
    tmpline = deblank(fgetl(fid));
    if isempty(tmpline), continue;  end
    if tmpline(1) == '%', continue;  end
    if strncmpi(tmpline,'return',6), break; end
    tmplines{k} = tmpline; k = k + 1;
  end
  fclose(fid);
  % extract only ses.xxx
  tmplines = tmplines(find(strncmpi(tmplines,'ses.',4)));
  for n = 1:length(tmplines),
    % remove blank before '=';
    [tok1,tok2] = strtok(tmplines{n});
    idx = findstr(tok2,'=');
    if isempty(idx),
      tmplines{n} = strcat(tok1,tok2);
    else
      tmplines{n} = cat(2,tok1,' ',tok2(idx(1):end));
    end
  end
  % extract session info
  idx = strncmpi(tmplines,'ses.grp',7);
  sestxt = cat(2,helplines,tmplines(find(idx == 0)));
  grptxt = tmplines(find(idx == 1));
  % keep data
  setappdata(wgts.main,'sesinfo',sestxt);
  setappdata(wgts.main,'grptext',grptxt);
  setappdata(wgts.main,'session',Ses);
  setappdata(wgts.main,'nrows',2);
  setappdata(wgts.main,'ncols',2);
  % update group
  imgviewer('Group_Callback',wgts.GroupCmb,'init',[]);
  
 otherwise
  fprintf(' imgviewer.Session_Calllback : ''%s'' not supported yet.\n',eventdata);
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Group_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% hObject    handle to togglebutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wgts = guihandles(get(hObject,'Parent'));
ses = getappdata(wgts.main,'session');

switch lower(eventdata),
 case {'init'}
  % update group
  grps = {'ALL';};
  grps = cat(1,grps,fieldnames(ses.grp));
  grps{end+1} = 'UNKNOWN';
  set(wgts.GroupCmb,'String',grps,'Value',2);
  Group_Callback(wgts.GroupCmb,'select',guidata(wgts.GroupCmb));
 case {'select'}
  grp = get(wgts.GroupCmb,'String');
  sel = get(wgts.GroupCmb,'Value');
  if sel == 1,
    % all exps
    exps = [];
    for k = 2:length(grp)-1,
      eval(sprintf('exps = [exps,ses.grp.%s.exps];',grp{k}));
    end
    exps = sort(exps(:));
    grpinfo = '';
  elseif sel == length(grp),
    % unknown
    exps = [];
    grpinfo = '';
  else
    if ~isfield(ses.grp,grp{sel}),
      return;
    end
    eval(sprintf('exps = ses.grp.%s.exps;',grp{sel}));
    grptext = getappdata(wgts.main,'grptext');
    % update group info
    grpinfo = {};  k = 1;
    token = sprintf('ses.grp.%s.',grp{sel});
    grpinfo = grptext(find(strncmpi(grptext,token,length(token))));
  end
  setappdata(wgts.main,'grpinfo',grpinfo);
  set(wgts.ExpNoEdt,'String',deblank(sprintf('%d ',exps)));
  Data_Callback(wgts.DataFileEdt,'init',[]);
  Main_Callback(wgts.main,'selectinf',[]);
 case {'edit'}
  grp = get(wgts.GroupCmb,'String');
  sel = get(wgts.GroupCmb,'Value');
  if ~isfield(ses.grp,grp{sel}),
    mguiEdit(which(ses.name),'ses.grp.');
  else
    mguiEdit(which(ses.name),sprintf('ses.grp.%s.',grp{sel}));
  end
 otherwise
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ExpNoEdt_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(get(hObject,'Parent'));
% update the group/raw data
ses = getappdata(wgts.main,'session');
expno = str2num(get(wgts.ExpNoEdt,'String'));
if length(expno) ~= 1,  return;  end
grp = get(wgts.GroupCmb,'String');
try
  tmpgrp = getgrp(ses,expno);
catch
  set(wgts.GroupCmb,'Value',length(grp));
  return;
end
idx = find(strcmpi(grp,tmpgrp.name));
set(wgts.GroupCmb,'Value',idx(1));
Data_Callback(wgts.DataImgEdt,'init',[]);
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Data_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(get(hObject,'Parent'));
ses  = getappdata(wgts.main,'session');
switch lower(eventdata)
 case {'init'}
  expno = str2num(get(wgts.ExpNoEdt,'String'));
  if isempty(expno),  return;  end
  expno = expno(1);
  if exist('csession','class'),
    ses = csession(ses);
    imgfile = ses.filename(expno,'2dseq');
  else
    imgfile = catfilename(ses,expno,'img');
  end
  set(wgts.DataFileEdt,'String',imgfile);
  set(wgts.DataFileEdt,'UserData',expno);
  set(wgts.MatDataFileEdt,'String',catfilename(ses,expno,'tcimg'));
  
  if isempty(dir(imgfile)),
    fprintf(' imgviewer.Data_Callback: not found ''%s''.\n',imgfile);
    return;
  end
  pvpars = getpvpars(ses,expno);
  setappdata(wgts.main,'pvpars',pvpars);
  % prepare pvpar info
  pvinfo = {}; k = 1;
  pvinfo{k} = sprintf('      nx = %d',pvpars.nx); k = k + 1;
  pvinfo{k} = sprintf('      ny = %d',pvpars.ny); k = k + 1;
  pvinfo{k} = sprintf('      nt = %d',pvpars.nx); k = k + 1;
  pvinfo{k} = sprintf('    nsli = %d',pvpars.nsli); k = k + 1;
  pvinfo{k} = sprintf('    nseg = %d',pvpars.nseg); k = k + 1;
  pvinfo{k} = sprintf('   imgtr = %.4f',pvpars.imgtr); k = k + 1;
  pvinfo{k} = sprintf('   slitr = %.4f',pvpars.slitr); k = k + 1;
  pvinfo{k} = sprintf('   segtr = %.4f',pvpars.segtr); k = k + 1;
  pvinfo{k} = sprintf('   effte = %.4f',pvpars.effte); k = k + 1;
  pvinfo{k} = sprintf(' recovtr = %.4f',pvpars.recovtr); k = k + 1;
  pvinfo{k} = sprintf('gradtype = %s',...
                      num2str(pvpars.gradtype(:)'));
  pvinfo{k} = strrep(pvinfo{k},'  ',' ');  k = k + 1;
  pvinfo{k} = sprintf(' graddur = %.4f',pvpars.graddur); k = k + 1;
  pvinfo{k} = sprintf('     fov = %s',...
                      num2str(pvpars.fov(:)')); k = k + 1;
  pvinfo{k} = sprintf('     res = %.4f %.4f',...
                      pvpars.res(1),pvpars.res(2)); k = k + 1;
  pvinfo{k} = sprintf('  actres = %.4f %.4f',...
                      pvpars.actres(1),pvpars.actres(2)); k = k + 1;
  pvinfo{k} = sprintf('  slithk = %d',pvpars.slithk); k = k + 1;
  pvinfo{k} = sprintf(' isodist = %d',pvpars.isodist); k = k + 1;
  pvinfo{k} = sprintf('  sligap = %d',pvpars.sligap); k = k + 1;
  pvinfo{k} = sprintf('  dstime = %d',pvpars.dstime); k = k + 1;
  pvinfo{k} = sprintf('      ds = %d',pvpars.ds); k = k + 1;
  % prepare reco info
  reco = pvpars.reco;
  pvinfo{k} = '------------------------------------';  k = k + 1;
  pvinfo{k} = sprintf('RECO_inp_size = [%s]',...
                     num2str(reco.RECO_inp_size(:)'));
  pvinfo{k} = strrep(pvinfo{k},'  ',' ');  k = k + 1;
  pvinfo{k} = sprintf('RECO_ft_size = [%s]',...
                     num2str(reco.RECO_ft_size(:)'));
  pvinfo{k} = strrep(pvinfo{k},'  ',' ');  k = k + 1;
  pvinfo{k} = sprintf('RECO_fov = [%s]',...
                     num2str(reco.RECO_fov(:)'));
  pvinfo{k} = strrep(pvinfo{k},'        ',' ');  k = k + 1;
  pvinfo{k} = sprintf('RECO_size = [%s]',...
                     num2str(reco.RECO_size(:)'));
  pvinfo{k} = strrep(pvinfo{k},'  ',' ');  k = k + 1;
  %pvinfo{k} = sprintf('RECO_maxima = %s',...
  %                   num2str(reco.RECO_maxima(:)'));
  %pvinfo{k} = strrep(pvinfo{k},'   ',' ');  k = k + 1;
  pvinfo{k} = sprintf('RECO_wordtype = %s',reco.RECO_wordtype); k = k + 1;
  pvinfo{k} = sprintf('RECO_byte_order = %s',reco.RECO_byte_order); k = k + 1;
  pvinfo{k} = sprintf('RECO_image_threshold = %.4f',...
                     reco.RECO_image_threshold); k = k + 1;
  pvinfo{k} = sprintf('RECO_ir_scale = %d',reco.RECO_ir_scale); k = k + 1;
  pvinfo{k} = sprintf('RECO_map_mode = %s',reco.RECO_map_mode); k = k + 1;
  pvinfo{k} = sprintf('RECO_map_range = [%s]',...
                     num2str(reco.RECO_map_range(:)'));
  pvinfo{k} = strrep(pvinfo{k},'     ',' ');  k = k + 1;
  pvinfo{k} = sprintf('RECO_map_percentile = [%s]',...
                     num2str(reco.RECO_map_percentile(:)'));
  pvinfo{k} = strrep(pvinfo{k},'       ',' ');  k = k + 1;

  % keep it
  setappdata(wgts.main,'pvparinfo',pvinfo);
 case {'browse'}
  imgfile = get(wgts.DataFileEdt,'String');
  if isempty(dir(imgfile)),
    imgfile = '2dseq*';
  end
  [imgfile pathname] = uigetfile(...
      {'2dseq*', '2dseq Files (2dseq*)'; ...
       '*.*',    'All Files (*.*)'}, ...
      'Pick a 2dseq file',imgfile);
  
  if isequal(imgfile,0) | isequal(pathname,0)
    % canceled
  else
    imgfile = fullfile(pathname,imgfile);
    set(wgts.DataFileEdt,'String',imgfile);
    %Data_Callback(wgts.DataFileEdt,'set',[]);
  end
 
 case {'matbrowse'}
  imgfile = get(wgts.MatDataFileEdt,'String');
  if isempty(dir(imgfile)),
    imgfile = '*.mat';
  end
  [imgfile pathname] = uigetfile(imgfile);
  if isequal(imgfile,0) | isequal(pathname,0)
    % canceled
  else
    imgfile = fullfile(pathname,imgfile);
    set(wgts.MatDataFileEdt,'String',imgfile);
    %Data_Callback(wgts.MatDataFileEdt,'set',[]);
  end
 
 case {'set'}
  imgfile = get(wgts.DataFileEdt,'String');
  
 case {'load'}
  imgfile = get(wgts.DataFileEdt,'String');
  if ~exist(imgfile,'file'),
    fprintf('File %s does not exist\n',imgfile);
    return;
  end;
  FileType = 0;
  setappdata(wgts.main,'FileType',FileType);
  bDenoise = get(wgts.DataDenoiseChk,'Value');
  % load 2dsea and process it here....
  % Do it in the workspace to avoid memory problems,
  % like evalin('base','....');
  Plot_Callback(wgts.DataViewCmb,[],[]);
 
 case {'matload'}
  imgfile = get(wgts.MatDataFileEdt,'String');
  if ~exist(imgfile,'file'),
    fprintf('File %s does not exist\n',imgfile);
    return;
  end;
  tcImg = matsigload(imgfile,'tcImg');
  sstep = 1/size(tcImg.dat,4); lstep = 10 * sstep;
  set(wgts.TimeBarTxt,'string',sprintf('Volume: %4d',1));
  set(wgts.TimeBarSldr,'SliderStep',[sstep lstep],'Max',size(tcImg.dat,4),...
                    'Min',1,'Value',1);
  setappdata(wgts.main,'tcImg',tcImg);
  FileType = 1;
  setappdata(wgts.main,'FileType',FileType);
  % draw data
  Plot_Callback(wgts.DataViewCmb,[],[]);
 
 case {'crop'}
  fprintf(' imgviewer.Data_Callback : ''%s''\n',eventdata);
 case {'roi'}
  fprintf(' imgviewer.Data_Callback : ''%s''\n',eventdata);

 otherwise
  fprintf(' imgviewer.Data_Callback : ''%s'' not supported yet.\n',eventdata);
  return;
end

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function View_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DIMS = get(hObject,'UserData');
wgts = guihandles(get(hObject,'Parent'));
setappdata(wgts.main,'nrows',DIMS(1));
setappdata(wgts.main,'ncols',DIMS(2));
Plot_Callback(wgts.DataViewCmb,[],[]);
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Plot_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(get(hObject,'Parent'));
if ~isfield(wgts,'LightBoxAxs'),
  keyboard
end
% import data from the workspace
try
  imgdata = evalin('base','imgdata');
catch
  %fprintf(' imgviewer.Plot_Callback: data not loaded yet.\n');
  %return;
end
viewtype = get(wgts.DataViewCmb,'String');
viewtype = viewtype{get(wgts.DataViewCmb,'Value')};
orthoWgts = [wgts.SagitalTxt,wgts.CoronalTxt,wgts.TransverseTxt,...
             wgts.SagitalSldr,wgts.CoronalSldr,wgts.TransverseSldr,...
             wgts.SagitalEdt,wgts.CoronalEdt,wgts.TransverseEdt,...
             wgts.SagitalAxs,wgts.CoronalAxs,wgts.TransverseAxs,...
             wgts.CrosshairChk];

switch viewtype
 case {'LightBox'}
  set(wgts.LightBoxAxs,'visible','on');
  delete(get(wgts.SagitalAxs,'Children'));
  delete(get(wgts.CoronalAxs,'Children'));
  delete(get(wgts.TransverseAxs,'Children'));
  set(orthoWgts,'visible','off');
  FileType = getappdata(wgts.main,'FileType');
  if isempty(FileType), return; end;

  if FileType,
    tcImg = getappdata(wgts.main,'tcImg');
    Img = tcImg.dat;
  else
    Img = getappdata(wgts.main,'2dseqImg');
  end;
  set(wgts.main,'HandleVisibility','on');
  axes(wgts.LightBoxAxs);
  TimePnt = round(get(wgts.TimeBarSldr,'value'));
  set(wgts.TimeBarTxt,'string',sprintf('Volume: %4d',TimePnt));
  
  NCols = getappdata(wgts.main,'ncols');
  NRows = getappdata(wgts.main,'nrows');
  for N=1:size(Img,3),
    dspimage(Img(:,:,N,TimePnt),wgts.LightBoxAxs,N,NRows,NCols);
    hold on;
  end;
  hold off;
  set(wgts.LightBoxAxs,'Tag','LightBoxAxs');
  set(wgts.main,'HandleVisibility','off');
  
 case {'Orthogonal'}
  delete(get(wgts.LightBoxAxs,'Children'));
  set(wgts.LightBoxAxs,'visible','off');
  set(orthoWgts,'visible','on');
  FileType = getappdata(wgts.main,'FileType');
  if isempty(FileType), return; end;
 
 otherwise
  fprintf(' imgviewer.Plot_Callback : ''%s'' not supported yet.\n',eventdata);
  return;
end
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SagitalSldr_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(get(hObject,'Parent'));
if strcmpi(get(wgts.SagitalAxs,'visible'),'off'), return;  end
fprintf(' imgviewer.SagitalSldr_Callback: \n');
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function CoronalSldr_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(get(hObject,'Parent'));
if strcmpi(get(wgts.CoronalAxs,'visible'),'off'), return;  end
fprintf(' imgviewer.CoronalSldr_Callback: \n');
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TransverseSldr_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(get(hObject,'Parent'));
if strcmpi(get(wgts.TransverseAxs,'visible'),'off'), return;  end
fprintf(' imgviewer.TransverseSldr_Callback: \n');
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TopBtn_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(get(hObject,'Parent'));
ses  = getappdata(wgts.main,'session');
if isempty(ses),  return;  end;
switch lower(eventdata)
 case {'tripilot'}
  feval('gettripilot',ses.name);
 case {'load'}
 otherwise,
end
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Figure_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
func_name = get(hObject,'UserData');
feval(lower(func_name));
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ImgOptions_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(get(hObject,'Parent'));
switch lower(eventdata)

 otherwise
  fprintf(' mgui.Script_Callback : ''%s'' not supported yet.\n',eventdata);
end
return

