function varargout = mroi2(varargin)
%MROI2 - Utility to define Regions of Interests (ROIs)
% MROI permits the definition of multiple ROIs in arbitrarily
% selected slices. Full documentation of the program and description
% of the procedures to generate and use ROIs can be obtained by
% typing HROI.
%  
% TODO's
% ===============
% ** GETELEDIST get interelectrode distance from "ROI" file
%  
% VERSION : 0.90 05.03.04 YM  pre-release, modified from Nikos's mroi.m.
%         : 1.00 09.03.04 NKL ROI & DEBUG
%         : 1.01 11.04.04 NKL
%         : 1.02 16.04.04 NKL Display Ana and tcImg
%         : 1.03 06.09.04 YM  bug fix on 'grproi-select' and Roi saving.
%         : 1.04 12.10.04 YM  supports zoom-in, bug fix on 'grp-select'.
%  
% See also HROI, MROISCT, MROIDSP, HIMGPRO, HHELP

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
  if nargin > 1,  GrpName = varargin{2};  end
end

% execute callback function then return;
if isstr(SESSION) & ~isempty(findstr(SESSION,'Callback')),
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
figH        =  46.0;
figX        =   1.0;
figY        = scrH-figH-2;         % 3 for menu and title bars.
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
'Name',...
'MROI: Graphics Interface for Region-of-Interest (ROI) selection (V2.0 2004)',...
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PULL-DOWN MENU [File Edit View Help]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- FILE
hMenuFile = uimenu(hMain,'Label','File');
uimenu(hMenuFile,'Label','Export as TIFF','Separator','off',...
       'Callback','mroi2(''Print_Callback'',gcbo,''tiff'',[])');
uimenu(hMenuFile,'Label','Export as JPEG','Separator','off',...
       'Callback','mroi2(''Print_Callback'',gcbo,''jpeg'',[])');
uimenu(hMenuFile,'Label','Export as Windows Metafile','Separator','off',...
       'Callback','mroi2(''Print_Callback'',gcbo,''meta'',[])');
uimenu(hMenuFile,'Label','Page Setup...','Separator','on',...
       'Callback','mroi2(''Print_Callback'',gcbo,''pagesetupdlg'',[])');
uimenu(hMenuFile,'Label','Print Setup...','Separator','off',...
       'Callback','mroi2(''Print_Callback'',gcbo,''printdlg'',[])');
uimenu(hMenuFile,'Label','Print','Separator','off',...
       'Callback','mroi2(''Print_Callback'',gcbo,''print'',[])');
uimenu(hMenuFile,'Label','Exit','Separator','on',...
       'Callback','mroi2(''Main_Callback'',gcbo,''exit'',[])');
% --- EDIT
hMenuEdit = uimenu(hMain,'Label','Edit');
uimenu(hMenuEdit,'Label','mroi',...
       'Callback','edit ''mroi'';');
hCB = uimenu(hMenuEdit,'Label','mroi : Callbacks');
uimenu(hCB,'Label','Main_Callback',...
       'Callback','mroi2(''Main_Callback'',gcbo,''edit-cb'',[])');
uimenu(hCB,'Label','Roi_Callback',...
       'Callback','mroi2(''Main_Callback'',gcbo,''edit-cb'',[])');
uimenu(hCB,'Label','Print_Callback',...
       'Callback','mroi2(''Main_Callback'',gcbo,''edit-cb'',[])');
uimenu(hMenuEdit,'Label','sescheck  : session checker',...
       'Callback','edit ''sescheck'';');
uimenu(hMenuEdit,'Label','Copy Figure','Separator','on',...
       'Callback','mroi2(''Print_Callback'',gcbo,''copy-figure'',[])');
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
    'Units','char','Position',[IMGXOFS H-0.15 12 1.5],...
    'String','Session: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
uicontrol(...
    'Parent',hMain,'Style','pushbutton',...
    'Units','char','Position',[IMGXOFS+14 H-0.05 22 1.5],...
    'String',SESSION,'FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left',...
    'Callback','mroi2(''Main_Callback'',gcbo,''edit-session'',[])',...
    'ForegroundColor',[1 1 0.1],'BackgroundColor',[0 0.5 0]);
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS H-2 12 1.5],...
    'String','Group: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
GrpNameBut = uicontrol(...
    'Parent',hMain,'Style','pushbutton',...
    'Units','char','Position',[IMGXOFS+14 H-2 22 1.5],...
    'String','Edit','FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left','Tag','GrpNameBut',...
    'Callback','mroi2(''Main_Callback'',gcbo,''edit-group'',[])',...
    'ForegroundColor',[1 1 0.1],'BackgroundColor',[0.6 0.2 0]);
GrpSelCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMGXOFS+38 H-2 31 1.5],...
    'String',{'Grp 1','Grp 2'},...
    'Callback','mroi2(''Main_Callback'',gcbo,''grp-select'',[])',...
    'TooltipString','Group Selection',...
    'Tag','GrpSelCmb','FontWeight','Bold');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS H-4 12 1.25],...
    'String','ROI Set: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
GrpRoiSelCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMGXOFS+14 H-3.8 55 1.25],...
    'String',{'Roi 1','Roi 2'},...
    'Callback','mroi2(''Main_Callback'',gcbo,''grproi-select'',[])',...
    'TooltipString','GrpRoi Selection',...
    'Tag','GrpRoiSelCmb','FontWeight','Bold');

% ====================================================================
% ROI CONTROL
% ====================================================================
XDSP = IMGXOFS;
H = IMGYOFS + IMGYLEN + 0.6;
% COMBO : ROI selecton
RoiSelCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[XDSP H 19 1.5],...
    'String',{'Roi1','Roi2'},...
    'Callback','mroi2(''Main_Callback'',gcbo,''roi-select'',[])',...
    'TooltipString','ROI selection',...
    'Tag','RoiSelCmb','FontWeight','Bold');
% COMBO : ROI action
ActCmd = {'No Action','Append','Replace','Electrodes',...
          'Clear','Clear All Slices','Clear electrodes','COMPLETE CLEAR'};
RoiActCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[XDSP+21 H 25 1.5],...
    'String',ActCmd,...
    'Callback','mroi2(''Roi_Callback'',gcbo,''roi-action'',[])',...
    'TooltipString','ROI action',...
    'Tag','RoiActCmb','FontWeight','Bold');
% STICKY BUTTON - IF SET APPEND IS STICKY AND SLICE ADVANCES
StickyCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+47.5 H 12 1.5],...
    'Tag','Sticky','Value',0,...
    'String','Sticky','FontWeight','bold',...
    'TooltipString','Append-Advance-Slice','BackgroundColor',get(hMain,'Color'));
% LOAD BUTTON - LOADS ROIs
RoiLoadBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[XDSP+60 H 12 1.5],...
    'Callback','mroi2(''Main_Callback'',gcbo,''load'',guidata(gcbo))',...
    'Tag','RoiLoadBtn','String','LOAD',...
    'TooltipString','Load ROIs','FontWeight','bold',...
    'ForegroundColor',[0.9 0.9 0],'BackgroundColor',[0 0 0.5]);
% SAVE BUTTON - Saves ROIs
RoiSaveBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[XDSP+73 H 12 1.5],...
    'Callback','mroi2(''Main_Callback'',gcbo,''save'',guidata(gcbo))',...
    'Tag','RoiSaveBtn','String','SAVE',...
    'TooltipString','Save ROIs','FontWeight','bold',...
    'ForegroundColor',[0.9 0.9 0],'BackgroundColor',[0 0 0.5]);

% ====================================================================
% AXES for plots, image and ROIs
% ====================================================================
% ANATOMY-IMAGE-ROI AXIS
AxsFrame = axes(...
    'Parent',hMain,'Units','char','color',get(hMain,'color'),'xtick',[],...
    'ytick',[],'Position',[IMGXOFS IMGYOFS IMGXLEN+1 IMGYLEN],...
    'Box','on','linewidth',3,'xcolor','r','ycolor','r',...
	'ButtonDownFcn','mroi2(''Main_Callback'',gcbo,''zoomin-ana'',[])',...
    'color',[0 0 .2]);
ImageAxs = axes(...
    'Parent',hMain,'Tag','ImageAxs',...
    'Units','char','Color','k','layer','top',...
    'Position',[IMGXOFS+2 IMGYOFS+1 IMGXLEN*.95 IMGYLEN*.85],...
    'xticklabel','','yticklabel','','xtick',[],'ytick',[]);
% EPI-IMAGE-ROI AXIS
Axs2Frame = axes(...
    'Parent',hMain,'Units','char','color',get(hMain,'color'),'xtick',[],...
    'ytick',[],'Position',[IMG2XOFS IMGYOFS IMGXLEN+1 IMGYLEN],...
    'Box','on','linewidth',3,'xcolor','r','ycolor','r',...
	'ButtonDownFcn','mroi2(''Main_Callback'',gcbo,''zoomin-func'',[])',...
    'color',[0 0 .2]);
% W/out BAR 'Position',[IMG2XOFS+2 IMGYOFS+1 IMGXLEN*.95 IMGYLEN*.85],...
Image2Axs = axes(...
    'Parent',hMain,'Tag','Image2Axs',...
    'Units','char','Color','k','layer','top',...
    'Position',[IMG2XOFS+2 IMGYOFS+1 IMGXLEN*.9 IMGYLEN*.85],...
    'xticklabel','','yticklabel','','xtick',[],'ytick',[]);

% ====================================================================
% FUNCTION BUTTONS FOR IMAGE AND TIME-SERIES PROCESSING
% Syntax: SetFunBtn(hMain,POS,TagName,Label,COL)
% ====================================================================
YOFS = 43.8; HX = IMG2XOFS; 5; HY = YOFS; DHY = 1.7;
SetFunBtn(hMain,HX,HY,'ButMeanImg','Mean-Img');
HY = HY - DHY;
SetFunBtn(hMain,HX,HY,'ButMedianImg','Median-Img');
HY = HY - DHY;
SetFunBtn(hMain,HX,HY,'ButMaxImg','Max-Img');
HY = HY - DHY;
SetFunBtn(hMain,HX,HY,'ButStdImg','Std-Img');
HY = HY - DHY;
SetFunBtn(hMain,HX,HY,'ButStmStdImg','StmStd-Img');
HX = HX + 17;
HY = YOFS;
SetFunBtn(hMain,HX,HY,'ButCvImg','Cv-Img');
HY = HY - DHY;

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
    'Callback','mroi2(''Main_Callback'',gcbo,''slice-slider'',[])',...
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
% INITIALIZE THE APPLICATION.
% ====================================================================
COLORS = 'crgbkmy';
LENCOL=7;
ses = goto(SESSION);
grps = getgroups(ses);

% SELECT GROUPS HAVING DIFFERENT ROI-DEFINITION-REQUIREMENTS
DoneGroups = {};
ToDoGroups = {};
K=0;
for GrpNo = 1:length(grps),
  if ~isfield(grps{GrpNo},'grproi') | isempty(grps{GrpNo}.grproi),
	grps{GrpNo}.grproi = 'RoiDef';
  end;
  if isempty(DoneGroups) | ...
		~any(strcmp(DoneGroups,grps{GrpNo}.grproi)),
	K=K+1;
	DoneGroups{K} = grps{GrpNo}.grproi;
	ToDoGroups{K} = grps{GrpNo}.name;
  end;
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
if ~exist('GrpName'),
  GrpName = GrpNames{1};
end;

% AND ALSO THE ROI NAME FOR THIS GROUP
grp = getgrpbyname(ses,GrpName);
wgts = guihandles(hMain);
set(wgts.GrpSelCmb,'String',GrpNames,'Value',find(strcmp(GrpNames,grp.name)));
set(wgts.GrpRoiSelCmb,'String',GrpRoiNames,'Value',1);

setappdata(hMain,'Ses',ses);
setappdata(hMain,'Grp',grp);
setappdata(hMain,'COLOR',COLORS);
CurOp = 'Mean-Img';
setappdata(hMain, 'CurOp', CurOp);
mroi2('Main_Callback',hMain,'init');
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
cbname = ST(I).name(n+1:end-1);

wgts = guihandles(hObject);
ses = getappdata(wgts.main,'Ses');
grp = getappdata(wgts.main,'Grp');
curImg = getappdata(wgts.main,'curImg');
COLORS = getappdata(wgts.main,'COLOR');

%fprintf('%s: eventdata=''%s''\n',gettimestring,eventdata);

switch lower(eventdata),
 case {'init'}
  % CHANGE 'UNITS' OF ALL WIDGETS FOR SUCCESSFUL PRINT
  % the following is as dirty as it can be... but it allows
  % rescaling and also correct printing... leave it so, until you
  % find a better solution!
  handles = findobj(wgts.main);
  for K = 1:length(handles),
    try,
      set(handles(K),'units','normalized');
    catch
    end
  end
  
  % re-evaluate session/group info.
  ses = getses(ses.name);
  grp = getgrp(ses,grp.name);
  setappdata(wgts.main,'Ses',ses);
  setappdata(wgts.main,'Grp',grp);
  
  % INITIALIZE WIDGETS
  set(wgts.GrpNameBut,'String',grp.name);
  set(wgts.RoiSelCmb,'String',ses.roi.names,'Value',1);
  
  % ---------------------------------------------------------------------
  % LOAD FUNCTIONAL SCAN (average or single-experiment)
  % ---------------------------------------------------------------------
  if exist('tcImg.mat','file') & ~isempty(who('-file','tcImg.mat',grp.name)),
    fname = 'tcImg.mat';
    %tcAvgImg = matsigload('tcImg.mat',grp.name);
    tcAvgImg = sigload(ses,grp.name,'tcImg');
    StatusPrint(hObject,cbname,'tcAvgImg loaded from "tcImg.mat"');
  else
    ExpNo = grp.exps(1);
    fname = catfilename(ses,ExpNo,'tcImg');
    tcAvgImg = sigload(ses,ExpNo,'tcImg');
    if isstruct(tcAvgImg) & ~isfield(tcAvgImg,'stm'),
      fprintf('MROI: No stm-field was found! Check dgz/session files\n');
      keyboard;
    end;
    if iscell(tcAvgImg) & ~isfield(tcAvgImg{1},'stm'),
      fprintf('MROI: No stm-field was found! Check dgz/session files\n');
      keyboard;
    end;
  end
  StatusPrint(hObject,cbname,'tcAvgImg loaded from "%s"',fname);
  curImg = tcAvgImg;
  setappdata(wgts.main,'tcAvgImg',tcAvgImg);
  setappdata(wgts.main,'curImg',curImg);

  % ---------------------------------------------------------------------
  % LOAD ANATOMY
  % ---------------------------------------------------------------------
  if isfield(ses.anap,'ImgDistort') & ses.anap.ImgDistort,
    anaImg = tcAvgImg;
    anaImg.EpiAnatomy = 1;
    if size(anaImg.dat,4) > 1,  anaImg.dat = mean(anaImg.dat,4);  end
  elseif isempty(grp.ana),
    anaImg = tcAvgImg;
    anaImg.EpiAnatomy = 1;
    if size(anaImg.dat,4) > 1,  anaImg.dat = mean(anaImg.dat,4);  end
  else
    AnaFile = sprintf('%s.mat',grp.ana{1});
    if exist(AnaFile,'file') & ~isempty(who('-file',AnaFile,grp.ana{1})),
      tmp = load(AnaFile,grp.ana{1});
      eval(sprintf('anaImg = tmp.%s;',grp.ana{1}));
      anaImg = anaImg{grp.ana{2}};
    else
      StatusPrint(hObject,cbname,'"%s" not found, run "sesascan"',AnaFile);
      return;
    end
    % We use to keep all slices and select the appropriate ones in
    % the 'imgdraw' case, but the line:
    % mroidsp(curanaImg.dat(:,:,grp.ana{3}(SLICE)));
    % Now this step is eliminated. We choose the appropriate
    % slices right here.
    anaImg.dat = anaImg.dat(:,:,grp.ana{3});
  end

  % resize the functional image and use it as anatomy
  tmpana = mean(tcAvgImg.dat,4);
  tmpana2 = [];
  for iSlice = 1:size(tmpana,3),
	tmpana2(:,:,iSlice) = imresize(tmpana(:,:,iSlice),[size(anaImg.dat,1),size(anaImg.dat,2)]);
  end
  anaImg.dat = tmpana2;
  
  curanaImg = anaImg;
  setappdata(wgts.main,'anaImg',anaImg);
  setappdata(wgts.main,'curanaImg',curanaImg);
  ImgScale.x = size(tcAvgImg.dat,1)/size(curanaImg.dat,1);
  ImgScale.y = size(tcAvgImg.dat,2)/size(curanaImg.dat,2);
  setappdata(wgts.main,'ImgScale',ImgScale);

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
  
  % ---------------------------------------------------------------------
  % SET GRPROI
  % ---------------------------------------------------------------------
  selgrproi = find(strcmp(get(wgts.GrpRoiSelCmb,'String'),grp.grproi));
  if isempty(selgrproi),  selgrproi = 1;  end
  set(wgts.GrpRoiSelCmb,'Value',selgrproi(1));

  Main_Callback(wgts.GrpRoiSelCmb,'grproi-select',[]);

  Main_Callback(wgts.RoiSelCmb,'roi-select',[]);
  % INVOKE THIS TO DRAW IMAGES
  Main_Callback(wgts.SliceBarSldr,'slice-slider',[]);
  
 case {'edit-session'}
  mguiEdit(which(ses.name));
  
 case {'edit-group'}
  grpname = get(wgts.GrpNameBut,'String');
  mguiEdit(which(ses.name),strcat('GRP.',grpname));
  
 case {'slice-slider'}		% HERE WE DISPLAY THE IMAGES
  SLICE = round(get(wgts.SliceBarSldr,'Value'));
  set(wgts.SliceBarTxt,'String',sprintf('Slice: %d',SLICE));
  mroi2('Main_Callback',wgts.main,'imgdraw');

 case {'imgdraw'}
  % ************* DRAWING OF THE ANATOMY IMAGE
  SLICE = round(get(wgts.SliceBarSldr,'Value'));
  curanaImg = getappdata(wgts.main,'curanaImg');
  figure(wgts.main);
  axes(wgts.ImageAxs); cla;
  mroidsp(curanaImg.dat(:,:,SLICE));
  set(wgts.ImageAxs,'xlim',[1,size(curanaImg.dat,1)],'ylim',[1,size(curanaImg.dat,2)]);

  % DRAW ROIS
  RoiRoi = getappdata(wgts.main,'RoiRoi');
  RoiEle = getappdata(wgts.main,'RoiEle');
  for N = 1:length(RoiRoi),
    if RoiRoi{N}.slice ~= SLICE, continue;  end
    roiname = RoiRoi{N}.name;
    px      = RoiRoi{N}.px;
    py      = RoiRoi{N}.py;
    % draw the polygon
    axes(wgts.ImageAxs); hold on;
    cidx = find(strcmpi(ses.roi.names,roiname));
    cidx = mod(cidx(1),length(COLORS)) + 1;
    if isempty(px) | isempty(py),
      [px,py] = find(RoiRoi{N}.anamask);
      plot(px,py,'color',COLORS(cidx),'linestyle','none',...
           'marker','s','markersize',1.5,...
           'markeredgecolor','none','markerfacecolor',COLORS(cidx));
    else
      plot(px,py,'color',COLORS(cidx));
    end;
    %x = min(px) - 1;  y = min(py) - 2;
    x = px(1) - 2;  y = py(1) - 2;
    text(x,y,roiname,'color',COLORS(cidx),'fontsize',10,'fontweight','bold');
  end
  % draw electrodes
  for N = 1:length(RoiEle)
    if RoiEle{N}.slice ~= SLICE, continue;  end
    ele = RoiEle{N}.ele;
    x   = RoiEle{N}.anax;
    y   = RoiEle{N}.anay;
    % plot the position
    axes(wgts.ImageAxs); hold on;
    plot(x,y,'y+','markersize',12);
    VALS = sprintf('e%d[%4.1f,%4.1f]', ele, x, y);
    text(x-5,y-5,VALS,'color','y','fontsize',10,'fontweight','bold');
  end  
  % some plotting function clears 'tag' of the axes !!!!!
  set(wgts.ImageAxs,'Tag','ImageAxs');


  % ************* DRAWING OF THE EPI IMAGE
  curImg = getappdata(wgts.main,'curImg');
  ImgScale = getappdata(wgts.main,'ImgScale');
  figure(wgts.main);
  axes(wgts.Image2Axs); cla;
  mroidsp(curImg.dat(:,:,SLICE,:),1,0,getappdata(wgts.main,'CurOp'));
  set(wgts.Image2Axs,'xlim',[1,size(curImg.dat,1)],'ylim',[1,size(curImg.dat,2)]);
  RoiRoi = getappdata(wgts.main,'RoiRoi');
  RoiEle = getappdata(wgts.main,'RoiEle');
  for N = 1:length(RoiRoi),
    if RoiRoi{N}.slice ~= SLICE, continue;  end
    roiname = RoiRoi{N}.name;
    
    % 01.06.04 TO SEE THE RoiDef_Act !!!
    axes(wgts.Image2Axs); hold on;
    
    SEE_USERROI_AND_XCOR_RESULT = 0;    %Debugging
    if SEE_USERROI_AND_XCOR_RESULT,
      DIMS = [size(tcAvgImg.dat,1) size(tcAvgImg.dat,2)];
      [maskx,masky] = find(RoiRoi{N}.mask);
      if all(size(Roi.roi{N}.mask)==DIMS),
        if ~isfield(anaImg,'EpiAnatomy') | ~anaImg.EpiAnatomy,
          continue;
        end;
      end;
      Roi.roi{RoiNo}.anamask = Roi.roi{RoiNo}.mask;
      Roi.roi{RoiNo}.mask=imresize(double(Roi.roi{RoiNo}.anamask),DIMS);
      
      cidx = find(strcmpi(ses.roi.names,roiname));
      cidx = mod(cidx(1),length(COLORS)) + 1;
      plot(maskx,masky,'linestyle','none','marker','s',...
           'markersize',2,'markerfacecolor',COLORS(cidx),...
           'markeredgecolor',COLORS(cidx));
    end;
    
    if isempty(RoiRoi{N}.px) | isempty(RoiRoi{N}.py),
      [px,py] = find(RoiRoi{N}.mask);
    else
      px = RoiRoi{N}.px * ImgScale.x;
      py = RoiRoi{N}.py * ImgScale.y;
    end;
    % draw the polygon
    %x = min(px) - 1;  y = min(py) - 2;
    x = px(1) - 2;  y = py(1) - 2;
    cidx = find(strcmpi(ses.roi.names,roiname));
    cidx = mod(cidx(1),length(COLORS)) + 1;
    if isempty(RoiRoi{N}.px) | isempty(RoiRoi{N}.py),
      plot(px,py,'color',COLORS(cidx),'linestyle','none',...
           'marker','s','markersize',3,'markerfacecolor',COLORS(cidx));
    else
      plot(px,py,'color',COLORS(cidx));
    end;
    text(x,y,roiname,'color',COLORS(cidx),'fontsize',10,'fontweight','bold');
  end
  % draw electrodes
  for N = 1:length(RoiEle)
    if RoiEle{N}.slice ~= SLICE, continue;  end
    ele = RoiEle{N}.ele;
    x   = RoiEle{N}.x;
    y   = RoiEle{N}.y;
    axes(wgts.Image2Axs); hold on;
    plot(x,y,'y+','markersize',12);
    VALS = sprintf('e%d[%4.1f,%4.1f]', ele, x, y);
    text(x-5,y-5,VALS,'color','y','fontsize',10,'fontweight','bold');
  end  
  % some plotting function clears 'tag' of the axes !!!!!
  set(wgts.Image2Axs,'Tag','Image2Axs');


 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 case {'load'}
  Main_Callback(wgts.main,'grproi-select',[]);

 case {'save'}
  tcAvgImg  = getappdata(wgts.main,'tcAvgImg');
  anaImg = getappdata(wgts.main,'anaImg');
  Roi = mroisct(ses,grp,tcAvgImg,anaImg);
  Roi.roi = getappdata(wgts.main,'RoiRoi');
  Roi.ele = getappdata(wgts.main,'RoiEle');
  if isempty(Roi.roi),
    StatusPrint(hObject,cbname,'no ROI to save');
    return;
  end
  % mroisct(ses,grp,tcAvgImg,anaImg) returns the following Roi-fields
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
  DIMS = [size(tcAvgImg.dat,1) size(tcAvgImg.dat,2)];
  % Here we have a problem if we read existing ROIs and we add new
  % ones or we replace them. In this case, in the old ROIs the mask
  % is already scaled! and the anamask will be scaled down.. !!
  for RoiNo = 1:length(Roi.roi),
    if all(size(Roi.roi{RoiNo}.mask)==DIMS),
      if ~isfield(anaImg,'EpiAnatomy') | ~anaImg.EpiAnatomy,
        % If mask has already the same dimensions and the scan is
        % without distortions (in this case the actual EPI is used
        % for anatomy, and of course then anatomy and functional
        % images have the same dimensions...), then the RoiNo
        % corresponds to a Roi that was read from the Roi.mat file,
        % and it is already appropriately scaled; So, do nothing.
        % fprintf('%d is old roi\n',RoiNo);
        continue;
      end;
    end;
    Roi.roi{RoiNo}.anamask = Roi.roi{RoiNo}.mask;
    Roi.roi{RoiNo}.mask=imresize(double(Roi.roi{RoiNo}.anamask),DIMS);
  end;
  
  goto(ses); % MAKE SURE WE ARE IN THE SESSION DIRECTORY
  RoiFile = 'Roi.mat';
  % grproiname = grp.grproi;
  grproiname = get(wgts.GrpRoiSelCmb,'String');
  grproiname = grproiname{get(wgts.GrpRoiSelCmb,'Value')};
  eval(sprintf('%s = Roi;',grproiname));
  if exist(RoiFile,'file'),
    copyfile(RoiFile,sprintf('%s.bak',RoiFile),'f'),
    save(RoiFile,grproiname,'-append');
  else
    save(RoiFile,grproiname);
  end
  StatusPrint(hObject,cbname,'"%s" saved to "%s"',grproiname,RoiFile);

 case {'roi-select'}
  roiname = get(wgts.RoiSelCmb,'String');
  roiname = roiname{get(wgts.RoiSelCmb,'Value')};
  % set 'RoiAction' to 'no action'
  actions = get(wgts.RoiActCmb,'String');
  idx = find(strcmpi(actions,'no action'));
  set(wgts.RoiActCmb,'Value',idx);

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
  mroi2('Main_Callback',wgts.main,'init');
 
 case {'grproi-select'}
  % ---------------------------------------------------------------------
  % LOAD ROI IF EXISTS.
  % ---------------------------------------------------------------------
  RoiFile = './Roi.mat';
  grproiname = get(wgts.GrpRoiSelCmb,'String');
  RoiVar = grproiname{get(wgts.GrpRoiSelCmb,'Value')};
  if exist(RoiFile,'file') & ~isempty(who('-file',RoiFile,RoiVar)),
    Roi = matsigload('Roi.mat',RoiVar);
	if isfield(Roi,'roi'), RoiRoi = Roi.roi; else RoiRoi = {}; end;
	if isfield(Roi,'ele'), RoiEle = Roi.ele; else RoiEle = {}; end;
	StatusPrint(hObject,cbname,'Loaded Roi "%s" from Roi.mat',RoiVar);
  else
    RoiRoi = {};
    RoiEle = {};
    StatusPrint(hObject,cbname,'"%s" not found in Roi.mat',RoiVar);
  end
  setappdata(wgts.main,'RoiRoi',RoiRoi);
  setappdata(wgts.main,'RoiEle',RoiEle);
  mroi2('Main_Callback',wgts.main,'redraw');
  
 % =============================================================
 % EXECUTION OF CALLBACKS OF THE FUNCTION-BUTTONS (bNames)
 % PROCESSING AND DISPLAY OF IMAGES AND TIME SERIES
 % =============================================================
 case {'redraw'}
  Main_Callback(wgts.RoiSelCmb,'roi-select',[]);
  Main_Callback(wgts.SliceBarSldr,'slice-slider',[]);

 case {'mean-img'}
  curImg = getappdata(wgts.main,'tcAvgImg');
  curImg.dat = mean(curImg.dat,4);
  setappdata(wgts.main,'curImg',curImg);
  setappdata(wgts.main, 'CurOp', eventdata);
  anaImg = getappdata(wgts.main,'anaImg');
  setappdata(wgts.main,'curanaImg',anaImg);
  mroi2('Main_Callback',wgts.main,'redraw');

 case {'median-img'}
  curImg = getappdata(wgts.main,'tcAvgImg');
  curImg.dat = median(curImg.dat,4);
  setappdata(wgts.main, 'CurOp', eventdata);
  setappdata(wgts.main,'curImg',curImg);
  anaImg = getappdata(wgts.main,'anaImg');
  setappdata(wgts.main,'curanaImg',anaImg);
  mroi2('Main_Callback',wgts.main,'redraw');

 case {'max-img'}
  curImg = getappdata(wgts.main,'tcAvgImg');
  curImg.dat = max(curImg.dat,4);
  setappdata(wgts.main, 'CurOp', eventdata);
  setappdata(wgts.main,'curImg',curImg);
  anaImg = getappdata(wgts.main,'anaImg');
  setappdata(wgts.main,'curanaImg',anaImg);
  mroi2('Main_Callback',wgts.main,'redraw');

 case {'std-img'}
  curImg = getappdata(wgts.main,'tcAvgImg');
  curImg.dat = std(curImg.dat,1,4);
  setappdata(wgts.main, 'CurOp', eventdata);
  setappdata(wgts.main,'curImg',curImg);
  anaImg = getappdata(wgts.main,'anaImg');
  setappdata(wgts.main,'curanaImg',anaImg);
  mroi2('Main_Callback',wgts.main,'redraw');
  
 case {'stmstd-img'}
  curImg = getappdata(wgts.main,'tcAvgImg');
  curImg = tosdu(curImg);
  tmp = getbaseline(curImg,'dat','notblank');
  curImg.dat = mean(curImg.dat(:,:,:,tmp.ix),4);
  setappdata(wgts.main, 'CurOp', eventdata);
  setappdata(wgts.main,'curImg',curImg);
  anaImg = getappdata(wgts.main,'anaImg');
  mask = curImg.dat;
  mask(find(mask<3)) = 1;
  mask(find(mask>=3)) = 1.5;
  for N=1:size(curImg.dat,3),
    curanaImg.dat(:,:,N) = anaImg.dat(:,:,N) .* ...
        imresize(mask(:,:,N),size(anaImg.dat(:,:,N)));
  end;
  setappdata(wgts.main,'curanaImg',curanaImg);
  mroi2('Main_Callback',wgts.main,'redraw');
  
 case {'cv-img'}
  curImg = getappdata(wgts.main,'tcAvgImg');
  m = mean(curImg.dat,4);
  curImg.dat = std(curImg.dat,1,4)./m;
  setappdata(wgts.main, 'CurOp', eventdata);
  setappdata(wgts.main,'curImg',curImg);
  anaImg = getappdata(wgts.main,'anaImg');
  setappdata(wgts.main,'curanaImg',anaImg);
  mroi2('Main_Callback',wgts.main,'redraw');
  
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
  
 otherwise
  %fprintf('unknown\n');
  
end
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALLBACK for ROI-ACTION
function Roi_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
funcname = mfilename('fullpath');
[ST, I] = dbstack;
n = findstr(ST(I).name,'(');
cbname = ST(I).name(n+1:end-1);

wgts = guihandles(hObject);
ses = getappdata(wgts.main,'Ses');
grp = getappdata(wgts.main,'Grp');
if ~strcmpi(eventdata,'roi-action'), return;  end
COLORS = getappdata(wgts.main,'COLOR');

RoiRoi  = getappdata(wgts.main,'RoiRoi');
RoiEle  = getappdata(wgts.main,'RoiEle');
SLICE   = round(get(wgts.SliceBarSldr,'Value'));
roiname = get(wgts.RoiSelCmb,'String');
roiname = roiname{get(wgts.RoiSelCmb,'Value')};
actions = get(wgts.RoiActCmb,'String');
axes(wgts.ImageAxs);

% do the current action
switch lower(actions{get(wgts.RoiActCmb,'Value')}),
 case {'append'}
  % disable widgets
  set(wgts.RoiSelCmb,'Enable','off');
  set(wgts.RoiActCmb,'Enable','off');
  set(wgts.RoiSaveBtn,'Enable','off');
  cidx = find(strcmpi(ses.roi.names,roiname));
  cidx = mod(cidx(1),length(COLORS)) + 1;
  while 1,
    % get roi
    [mask,px,py] = roipoly;
    % check user interaction
    click = get(wgts.main,'SelectionType');
    if strcmp(click,'alt'),  break;  end
    % check size of poly, if very small ignore it.
    %length(px), length(py)
    if length(px)*length(py) < 1,  break;  end
    % now register the new roi
    N = length(RoiRoi) + 1;
    RoiRoi{N}.name  = roiname;
    RoiRoi{N}.slice = SLICE;
    RoiRoi{N}.mask  = mask';  % transpose "mask"
    RoiRoi{N}.px    = px;
    RoiRoi{N}.py    = py;
    % draw the polygon
    axes(wgts.ImageAxs); hold on;
    %x = min(px) - 1;  y = min(py) - 2;
    x = px(1) - 2;  y = py(1) - 2;
    plot(px,py,'color',COLORS(cidx));
    text(x,y,roiname,'color',COLORS(cidx),'fontsize',10,'fontweight','bold');
  end
  setappdata(wgts.main,'RoiRoi',RoiRoi);

  % HERE CHECK IF THE STICKY BUTTON IS CHECKED
  % IF IT IS, CONTINUE APPENDING AFTER SLICE-ADVANCING
  curImg = getappdata(wgts.main,'curImg');
  nslices = size(curImg.dat,3);
  SLICE = round(get(wgts.SliceBarSldr,'Value')) + 1;
  if get(wgts.Sticky,'Value') & SLICE <= nslices,
    set(wgts.SliceBarTxt,'String',sprintf('Slice: %d',SLICE));
    set(wgts.SliceBarSldr,'Value',SLICE);
    mroi2('Main_Callback',wgts.main,'redraw');
    actions = get(wgts.RoiActCmb,'String');
    idx = find(strcmpi(actions,'append'));
    set(wgts.RoiActCmb,'Value',idx);
    Roi_Callback(wgts.RoiActCmb,'roi-action',[]);
  else
    % enable widgets
    set(wgts.RoiSelCmb,'Enable','on');
    set(wgts.RoiActCmb,'Enable','on');
    set(wgts.RoiSaveBtn,'Enable','on');
    Main_Callback(wgts.SliceBarSldr,'slice-slider',[]);
  end;
  
 case {'replace'}
  % set to 'clear' and take the action
  idx = find(strcmpi(actions,'clear'));
  set(wgts.RoiActCmb,'Value',idx);
  Roi_Callback(wgts.RoiActCmb,'roi-action',[]);
  % set to 'append' and take the action
  idx = find(strcmpi(actions,'append'));
  set(wgts.RoiActCmb,'Value',idx);
  Roi_Callback(wgts.RoiActCmb,'roi-action',[]);
  
 case {'clear'}
  % clear the current ROI in this slice
  IDX = [];
  for N = 1:length(RoiRoi),
    if ~strcmpi(RoiRoi{N}.name,roiname) | RoiRoi{N}.slice ~= SLICE,
      IDX(end+1) = N;
    end
  end
  setappdata(wgts.main,'RoiRoi',RoiRoi(IDX));
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'slice-slider',[]);
  
 case {'clear all slices'}
  % clear the current ROI throughout slices
  IDX = [];
  for N = 1:length(RoiRoi),
    if ~strcmpi(RoiRoi{N}.name,roiname),
      IDX(end+1) = N;
    end
  end
  if isempty(IDX),
    setappdata(wgts.main,'RoiRoi',{});
  else
    setappdata(wgts.main,'RoiRoi',RoiRoi(IDX));
  end
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'slice-slider',[]);

 case {'clear electrodes'}
  % look for corresonding indices for electrodes in this slice
  IDX = [];
  for N = 1:length(RoiEle),
    if RoiEle{N}.slice ~= SLICE,
      IDX(end+1) = N;
    end
  end
  if isempty(IDX),
    setappdata(wgts.main,'RoiEle',{});
  else
    setappdata(wgts.main,'RoiEle',RoiEle(IDX));
  end
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'slice-slider',[]);
  
 case {'electrodes'}
  if ~isfield(grp,'hardch') || isempty(grp.hardch),
    % set to 'no action'
    idx = find(strcmpi(actions,'no action'));
    set(wgts.RoiActCmb,'Value',idx);
    return;
  end
  
  % disable widgets
  set(wgts.RoiSelCmb,'Enable','off');
  set(wgts.RoiActCmb,'Enable','off');
  set(wgts.RoiSaveBtn,'Enable','off');
  % clear the points first
  % look for corresonding indices for electrodes in this slice
  IDX = [];
  for N = 1:length(RoiEle),
    if RoiEle{N}.slice ~= SLICE,
      IDX(end+1) = N;
    end
  end
  if isempty(IDX),
    setappdata(wgts.main,'RoiEle',{});
  else
    setappdata(wgts.main,'RoiEle',RoiEle(IDX));
  end
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'slice-slider',[]);
  ImgScale = getappdata(wgts.main,'ImgScale');
  
  % This works too, but [y, x] = myginput(1,'fleur');
  % impixel is better for pixel coordinates
  for N = 1:length(grp.hardch),
    [x, y] = ginput(1);
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
    RoiEle{K}.x  = round(RoiEle{K}.anax * ImgScale.x);
    RoiEle{K}.y  = round(RoiEle{K}.anay * ImgScale.y);
    % plot the position
    axes(wgts.ImageAxs); hold on;
    plot(x,y,'y+','markersize',12);
    VALS = sprintf('e%d[%4.1f,%4.1f]', N, x, y);
    text(x-5,y-5,VALS,'color','y','fontsize',10,'fontweight','bold');
  end
  set(wgts.ImageAxs,'tag','ImageAxs');
  setappdata(wgts.main,'RoiEle',RoiEle);
  % enable widgets
  set(wgts.RoiSelCmb,'Enable','on');
  set(wgts.RoiActCmb,'Enable','on');
  set(wgts.RoiSaveBtn,'Enable','on');
 
 case {'complete clear'}
  % clear ROIs completely
  setappdata(wgts.main,'RoiRoi',{});
  setappdata(wgts.main,'RoiEle',{});
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'slice-slider',[]);

 otherwise
end

% set to 'no action'
idx = find(strcmpi(actions,'no action'));
set(wgts.RoiActCmb,'Value',idx);
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function StatusPrint(hObject,fname,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmp = sprintf(varargin{:});
tmp = sprintf('(%s): %s',fname,tmp);
wgts = guihandles(hObject);
set(wgts.StatusField,'String',tmp);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Print_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
funcname = mfilename('fullpath');
[ST, I] = dbstack;
n = findstr(ST(I).name,'(');
cbname = ST(I).name(n+1:end-1);

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
cb = sprintf('mroi2(''Main_Callback'',gcbo,''%s'',guidata(gcbo))',...
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SetRadioBtn(hMain,HX,HY,TagName,Label)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cb = sprintf('mroi2(''RadioButton_Callback'',gcbo,''%s'',guidata(gcbo))',...
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
