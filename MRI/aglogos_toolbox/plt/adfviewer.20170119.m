function varargout = adfviewer(varargin)
%ADFVIEWER - GUI to view adf/adfw data.
%  ADFVIEWER(ADFFILE)
%  ADFVIEWER(SESSION,EXPNO) runs GUI to view adf/adfw data.
%
%  EXAMPLE :
%    adfviewer('E/DataNeuro/C98.NM1/c98nm1_001.adfw')
%    adfviewer('//wks21/data/rat.hm1/rathm1_004.adfw')
%    adfviewer(SESSION,EXPNO)
%
%  VERSION :
%    0.90 16.12.03 YM  first release
%    0.91 20.04.04 YM  bug fix
%    0.93 19.09.08 YM  supports new csession class.
%    0.94 16.04.12 YM  scalable window-size
%    0.95 18.04.14 YM  uses expfilename() instead of catfilename().
%    0.96 17.01.16 YM  supports .adfx in uigetfile().
%    0.97 18.01.16 YM  plots MRI events.
%
%  See also adf_info adf_read dgzviewer tcimgmovie imgviewer

%persistent H_ADFVIEWER;    % keep the figure handle


if nargin == 0,  help adfviewer;  return;  end

% execute callback function
if ischar(varargin{1}) && ~isempty(findstr(varargin{1},'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return
end

% invoked from 'mgui' or console.
SESSION = '';  ADFFILE = '';
if isempty(which(varargin{1})),
  % varargin{1} as a 'ADFFILE'
  ADFFILE = varargin{1};
else
  % varargin{1} as a 'SESSION'
  SESSION = varargin{1};
  if nargin >= 2,
    EXPNO = varargin{2};
  else
    EXPNO = [];
  end
end

%% prevent double execution
% if ishandle(H_ADFVIEWER),
%   close(H_ADFVIEWER);
%   %fprintf('\n ''adfviewer'' already opened.\n');
%   %return;
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CREATE THE MAIN WINDOW
% Reminder: get(0,'DefaultUicontrolBackgroundColor')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[scrW scrH] = getScreenSize('char');
figW = 216.0;  figH = 60.0;
figX =  31.0;  figY = scrH-figH-7;  % 7 for menu and title bars.
hMain = figure(...
    'Name','ADF Viewer','NumberTitle','off', 'toolbar','figure',...
    'Tag','main', 'MenuBar','none', ...
    'HandleVisibility','callback',...
    'DoubleBuffer','on', 'Visible','off',...
    'Units','char','Position',[figX figY figW figH],...
    'Color',[0.8 0.83 0.83]);
%    'Color',[0.878 0.875 0.89]);
%    'Color', get(0,'DefaultUicontrolBackgroundColor'),...
%H_ADFVIEWER = hMain;
if ~isempty(SESSION), setappdata(hMain,'session',SESSION);  end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PULL-DOWN MENU [File Edit View Help]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- FILE
hMenuFile = uimenu(hMain,'Label','File');
uimenu(hMenuFile,'Label','Exit','Separator','on',...
       'Callback','adfviewer(''Main_Callback'',gcbo,''exit'',[])');

% --- EDIT
hMenuEdit = uimenu(hMain,'Label','Edit');
uimenu(hMenuEdit,'Label','adfviewer',...
       'Callback','edit ''adfviewer'';');
hCB = uimenu(hMenuEdit,'Label','adfviewer : Callbacks');
uimenu(hCB,'Label','Main_Callback',...
       'Callback','adfviewer(''Main_Callback'',gcbo,''edit-cb'',[])');
uimenu(hCB,'Label','Session_Callback',...
       'Callback','adfviewer(''Main_Callback'',gcbo,''edit-cb'',[])');
uimenu(hCB,'Label','Group_Callback',...
       'Callback','adfviewer(''Main_Callback'',gcbo,''edit-cb'',[])');
uimenu(hCB,'Label','ExpNoEdt_Callback',...
       'Callback','adfviewer(''Main_Callback'',gcbo,''edit-cb'',[])');
uimenu(hCB,'Label','Data_Callback',...
       'Callback','adfviewer(''Main_Callback'',gcbo,''edit-cb'',[])');

% --- VIEW
hMenuView = uimenu(hMain,'Label','View');
uimenu(hMenuView,'Label','Redraw',...
       'Callback','adfviewer(''Plot_Callback'',gcbo,''all'',[])');

% --- HELP
hMenuHelp = uimenu(hMain,'Label','Help');
uimenu(hMenuHelp,'Label','Analysis Package','Callback','helpwin');
uimenu(hMenuHelp,'Label','adfviewer','Separator','on',...
       'Callback','helpwin adfviewer');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SESSION UI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = figH - 1.8;
% LABEL - Session:
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[0.5 H-0.2 12 1.5],...
    'String','Session :','FontWeight','bold',...
    'HorizontalAlignment','right',...
    'BackgroundColor',get(hMain,'Color'));
% ENTRY SESSION - Enter the session.
SessionEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[14 H 23 1.5],...
    'Callback','adfviewer(''Session_Callback'',gcbo,''set'',guidata(gcbo))',...
    'String','session','Tag','SessionEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','set the session',...
    'FontWeight','bold','BackgroundColor','white');
% BROWSE SESSION BUTTION - Invokes the path/file finder (Select the session)
SessionBrowseBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[37 H 4 1.5],...
    'Callback','adfviewer(''Session_Callback'',gcbo,''browse'',guidata(gcbo))',...
    'Tag','SessionBrowseBtn',...
    'TooltipString','Browse a session',...
    'ForegroundColor','white','BackgroundColor','white');
mguiSetIcon(SessionBrowseBtn,'stock_open16x16.png');
% EDIT SESSION BUTTON : Invokes Emacs session.m
SessionEditBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[41 H 4 1.5],...
    'Callback','adfviewer(''Session_Callback'',gcbo,''edit'',guidata(gcbo))',...
    'Tag','SessionEditBtn',...
    'TooltipString','Edit the session',...
    'ForegroundColor','white','BackgroundColor','white');
mguiSetIcon(SessionEditBtn,'stock_edit16x16.png');
%---------------------------------------------------
% PRESS TO LOAD OUR DEFAULT DEBUG-SESSION
%---------------------------------------------------
SessionDefaultBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[48 H 15 1.5],...
    'Callback','adfviewer(''Session_Callback'',gcbo,''default'',[])',...
    'Tag','SessionDefaultBtn','String','Debug',...
    'TooltipString','set to default','FontWeight','bold',...
    'ForegroundColor',[0.9 0.9 0],'BackgroundColor',[0.3 0 0.1]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GROUP UI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = H - 1.8;
% LABEL - Group:
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[0.5 H-0.2 12 1.5],...
    'String','Group :','FontWeight','bold',...
    'HorizontalAlignment','right',...
    'BackgroundColor',get(hMain,'Color'));
% COMBOBOX GROUP - Select the group in the current session.
GroupCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[14 H 23 1.5],...
    'String',{'group'},...
    'Callback','adfviewer(''Group_Callback'',gcbo,''select'',[])',...
    'TooltipString','group selection',...
    'Tag','GroupCmb','FontWeight','Bold');
% EDIT GROUP BUTTON - Invokes Emacs session.m putting the cursor to
%                     the selected group.
GroupEditBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[37 H 4 1.5],...
    'Callback','adfviewer(''Group_Callback'',gcbo,''edit'',)',...
    'Tag','GroupEditBtn',...
    'TooltipString','edit the group params',...
    'ForegroundColor','white','BackgroundColor','white');
mguiSetIcon(GroupEditBtn,'stock_edit16x16.png');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXPNO UI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = H - 1.8;
% LABEL - Exps:
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[0.5 H-0.2 12 1.5],...
    'String','Exps :','FontWeight','bold',...
    'HorizontalAlignment','right',...
    'BackgroundColor',get(hMain,'Color'));
% ENTRY for experiment numbers - Enter ExpNo.
ExpNoEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[14 H 49 1.5],...
    'Callback','adfviewer(''ExpNoEdt_Callback'',gcbo,[],[])',...
    'String','exp. numbers','Tag','ExpNoEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','set exp. number(s)',...
    'FontWeight','Bold');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DATA UI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = H - 2;
% LABEL - Adf:
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[0.5 H-0.2 7 1.5],...
    'String','Adf :','FontWeight','bold',...
    'HorizontalAlignment','right',...
    'BackgroundColor',get(hMain,'Color'));
% ENTRY DATAFILE - Enter an adf/adfw file. 
DataFileEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[8 H 51 1.5],...
    'String','adffile','Tag','DataFileEdt',...
    'HorizontalAlignment','left','FontWeight','normal',...
    'TooltipString','adf/adfw file');
% BROWSE DATA BUTTON - Invokes the path/file finder (Select File to Open)
DataBrowseBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[59 H 4 1.5],...
    'Callback','adfviewer(''Data_Callback'',gcbo,''browse'',guidata(gcbo))',...
    'Tag','DataBrowseBtn',...
    'TooltipString','Browse an adffile',...
    'ForegroundColor','white','BackgroundColor','white');
mguiSetIcon(DataBrowseBtn,'stock_open16x16.png');
H = H - 2;
% ENTRY DATAFILE - Enter an adf/adfw file. 
DataPairedFileEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[8 H 55 1.5],...
    'String','paired adffile','Tag','DataPairedFileEdt',...
    'HorizontalAlignment','left','FontWeight','normal',...
    'TooltipString','paired adf/adfw file');

H = H - 2;
% LOAD DATA BUTTON 
DataLoadBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[45 H 18 1.5],...
    'Callback','adfviewer(''Data_Callback'',gcbo,''load-plot'',[])',...
    'Tag','DataLoadBtn','String','Load/Plot',...
    'TooltipString','Load data','FontWeight','bold',...
    'ForegroundColor',[0.9 0.9 0],'BackgroundColor',[0 0 0.5]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OBSP UI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = H - 2.5;
bkgc = [0.8 0.8 0.85];
% FRAME
uicontrol(...
    'Parent',hMain,'Style','frame',...
    'Units','char','Position',[0 H-2.5 64 4.5],...
    'ForegroundColor','black','BackgroundColor',bkgc);
% LABEL - Obsp.No:
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[1 H-0.2 12 1.5],...
    'String','Obs.No:','FontWeight','bold',...
    'HorizontalAlignment','right',...
    'Background',bkgc);
% ENTRY OBSP - Enter the observation number.
DataObsEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[14 H 10 1.5],...
    'String','1','FontWeight','bold',...
    'Callback','adfviewer(''Data_Callback'',gcbo,''set-obs'',[])',...
    'Tag','DataObsEdt');
% CHECHKBOX - Show/Hide stimulus events
ShowStimChk = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[40 H 22 1.5],...
    'String','Show Stimulus','FontWeight','bold',...
    'Tag','ShowStimChk',...
    'Callback','adfviewer(''Plot_Callback'',gcbo,''zoomed-event'',[])',...
    'HorizontalAlignment','left',...
    'TooltipString','Show/Hide stimulus events','BackgroundColor',bkgc);
H = H - 1.8;
% SLIDER for observation periods.
DataObsSldr = uicontrol(...
    'Parent',hMain,'Style','Slider',...
    'Units','char','Position',[2 H 60 1],...
    'Callback','adfviewer(''Data_Callback'',gcbo,''obs-slider'',[])',...
    'Tag','DataObsSldr','Min',1,'Max',1.01,'Value',1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% INFO UI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = H - 3.5;
% FRAME
uicontrol(...
    'Parent',hMain,'Style','frame',...
    'Units','char','Position',[0 0 64 H+1.8],...
    'ForegroundColor','black','BackgroundColor','black');
% COMBOBOX INFO - Selects the info-type to display
InfoCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[38 H 25 1.5],...
    'String',{'Session','Group','Data (adf/dgz)'},...
    'Callback','adfviewer(''Main_Callback'',gcbo,''selectinf'',[])',...
    'HorizontalAlignment','left',...
    'TooltipString','info selection',...
    'Tag','InfoCmb','FontWeight','Bold');
% LISTBOX INFO - Displays the selected information.
InfoTxt = uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','char','Position',[0.2 0.2 63 H-0.4],...
    'String',{'session','group'},...
    'Callback','adfviewer(''Main_Callback'',gcbo,''edit-info'',[])',...
    'HorizontalAlignment','left','FontName','Courier New',...
    'Tag','InfoTxt','Background','white');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DATA PLOT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bkgc = [0.83 0.8 0.83];
XDSP = 68;
XDSPLEN = 145;
LBOX_Y = 2.5;
% FRAME - big frame
axes(...
    'Parent',hMain,...
    'Units','char','Position',[XDSP-2.5 0 figW-XDSP+2.5 figH],...
    'color',bkgc,'xtick',[],'ytick',[],...
    'Box','off','linewidth',1.5,'xcolor',bkgc,'ycolor',bkgc);

% EVENT AXES - axes for event display.
axes(...
    'Parent',hMain,'Units','char',...
    'Position',[XDSP figH-3.5 XDSPLEN*0.4-1.5 2.5],...
    'Tag','EventAxes','Box','on','FontSize',8,...
    'XTickLabel',[],'YTickLabel',[],...
    'color','black','xcolor',[0.9 0.9 0.9],'ycolor',[0.9 0.9 0.9]);
H = figH - 3.5;
% CHECK-BOX for dgz clock correction
DgzClkCorrChk = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[figW-50-2 H 40 1.5],...
    'Callback','',...
    'Tag','DgzClkCorrChk','Value',1,...
    'String','dgz clock correction','FontWeight','bold',...
    'TooltipString','match dgz clock to adf','BackgroundColor',get(hMain,'Color'));
% CHECK-BOX for MRI event drawing
ShowMriChk = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[figW-20-2 H+1.5 40 1.5],...
    'Callback','adfviewer(''Plot_Callback'',gcbo,''zoomed-event'',[])',...
    'Tag','ShowMriChk','Value',0,...
    'String','MRI events','FontWeight','bold',...
    'TooltipString','show MRI events','BackgroundColor',get(hMain,'Color'));
% BUTTON - Goes to the 1st MRI noise.
MriEventBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[figW-20-2 H 20 1.5],...
    'Callback','adfviewer(''Data_Callback'',gcbo,''mri-event'',[])',...
    'String','First MRI (dgz)','FontWeight','bold','Tag','MriEventBtn',...
    'TooltipString','Move the window to the 1st MRI event',...
    'ForegroundColor',[0.9 0.9 0],'BackgroundColor',[0.3 0 0.1]);

% FRAME - for area defining plot-area, used to create axes.
AxsFrame = axes(...
    'Parent',hMain,'color',[0.2 0.2 0.2],...
    'Units','char','Position',[XDSP 4.3 XDSPLEN+1 figH-8.3],...
    'Tag','AxsFrame','ytick',[],'xtick',[],...
    'Box','on','linewidth',1.5,'xcolor','r','ycolor','r');

% SLIDER - Time bar for magnified view.
TimeBarSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[XDSP-2 2.4 XDSPLEN*0.4+5 1.5],...
    'Callback','adfviewer(''Data_Callback'',gcbo,''t-slider'',[])',...
    'Tag','TimeBarSldr','SliderStep',[0.1 0.2],...
    'TooltipString','Time Points');
% LABEL - TimeWindow:
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+XDSPLEN*0.4+10 2.4-0.2 25 1.5],...
    'String','Time Window (sec) :','FontWeight','bold',...
    'HorizontalAlignment','right','Background',bkgc);
% ENTRY TWIN - Enter the time window.
PlotTwinEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+XDSPLEN*0.4+37 2.4 12 1.5],...
    'String','2','FontWeight','bold',...
    'Callback','adfviewer(''Data_Callback'',gcbo,''t-window'',[])',...
    'Tag','PlotTwinEdt');
% LABEL - Ymin
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+XDSPLEN*0.4+10 0.4-0.2 25 1.5],...
    'String','Ymin :','FontWeight','bold',...
    'HorizontalAlignment','right','Background',bkgc);
% ENTRY Ymin - Enter the Ymin.
PlotYminEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+XDSPLEN*0.4+37 0.4 12 1.5],...
    'String','-20000','FontWeight','bold',...
    'Callback','adfviewer(''Data_Callback'',gcbo,''yscale'',[])',...
    'Tag','PlotYminEdt');
% LABEL - Ymax
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+XDSPLEN*0.4+55 0.4-0.2 10 1.5],...
    'String','Ymax :','FontWeight','bold',...
    'HorizontalAlignment','right','Background',bkgc);
% ENTRY Ymax - Enter the Ymin.
PlotYminEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+XDSPLEN*0.4+67 0.4 12 1.5],...
    'String','20000','FontWeight','bold',...
    'Callback','adfviewer(''Data_Callback'',gcbo,''yscale'',[])',...
    'Tag','PlotYmaxEdt');



% get widgets handles at this moment
HANDLES = findobj(hMain);

HANDLES = HANDLES(find(HANDLES ~= hMain));
for K=1:length(HANDLES)
  try
    set(HANDLES(K),'units','normalized');
  catch
  end
end


% initialize the application.
Main_Callback(hMain,'init');
if ~isempty(SESSION),
  set(SessionEdt,'String',SESSION);
  Session_Callback(SessionEdt,'set',[]);
  if ~isempty(EXPNO),
    set(ExpNoEdt,'String',num2str(EXPNO));
    ExpNoEdt_Callback(ExpNoEdt,'set',[]);
    Data_Callback(DataFileEdt,'load',[]);
  end
else
  if ~isempty(ADFFILE),
    set(DataFileEdt,'String',ADFFILE);
    Data_Callback(DataFileEdt,'load',[]);
  end
end
set(hMain,'Visible','on');


% NOW SET "UNITS" OF ALL WIDGETS AS "NORMALIZED".
HANDLES = HANDLES(find(HANDLES ~= hMain));
for K = 1:length(HANDLES)
  try
    %set(HANDLES(K),'units','normalized');
  catch
  end
end


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
 case {'edit-cb'}
  % edit callback functions
  token = get(hObject,'Label');
  if ~isempty(token),
    mguiEdit(which('mgui'),sprintf('function %s(hObject',token));
  end
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
   case {'data (adf/dgz)'}
    tmptxt = getappdata(wgts.main,'datainfo');
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
   case {'session','group'}
    editfile = which(get(wgts.SessionEdt,'String'));
    token = token{get(wgts.InfoTxt,'Value')};
    if ~isempty(token) && token(1) ~= '%',
      token = strtok(token)
    end
   otherwise
    return;
  end

  if isempty(editfile) || ~exist(editfile,'file'),
    fprintf(' adfviewer.Main_Callback: ''%s'' not found.\n');
    return;
  end
  mguiEdit(editfile,token);
  
 otherwise
  fprintf(' adfviewer.Main_Callback: ''%s'' not supported yet.\n',eventdata);
  return;
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
 case {'init'}
 case {'default'}
  set(wgts.SessionEdt,'String','m02lx1');
  Session_Callback(wgts.SessionEdt,'set',[]);
 case { 'browse','open' }
  if exist(sesfile) ~= 2,
    dirs = getdirs;
    sesfile = fullfile(dirs.sesdir,'*.m');
  end
  [sesfile,pathname] = uigetfile(...
      {'*.m', 'Mat-files (*.m)'; ...
       '*.*', 'All Files (*.*)'}, ...
      'Pick a session',sesfile);
  if isequal(sesfile,0) || isequal(pathname,0)
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
    fprintf(' adfviewer.Session_Callback : ''%s.m'' not found.\n',sesfile);
  end
  [fpath,froot,fext] = fileparts(sesfile);
  eval(sprintf('clear %s;',froot));  % To keep updated.
  Ses = getses(froot);

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
  tmplines = tmplines(strncmpi(tmplines,'ses.',4));
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
  sestxt = cat(2,helplines,tmplines(idx == 0));
  grptxt = tmplines(idx == 1);
  % keep data
  setappdata(wgts.main,'sesinfo',sestxt);
  setappdata(wgts.main,'grptext',grptxt);
  setappdata(wgts.main,'session',Ses);
  % update group
  adfviewer('Group_Callback',wgts.GroupCmb,'init',[]);
  
 otherwise
  fprintf(' adfviewer.Session_Calllback : ''%s'' not supported yet.\n',eventdata);
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
      exps = [exps, ses.grp.(grp{k}).exps];
      % eval(sprintf('exps = [exps,ses.grp.%s.exps];',grp{k}));
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
    exps = ses.grp.(grp{sel}).exps;
    %eval(sprintf('exps = ses.grp.%s.exps;',grp{sel}));
    grptext = getappdata(wgts.main,'grptext');
    % update group info
    grpinfo = {};  k = 1;
    token = sprintf('ses.grp.%s.',grp{sel});
    grpinfo = grptext(strncmpi(grptext,token,length(token)));
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
if isempty(tmpgrp),
  error('\nERROR %s: no group found, invalid ExpNo(=%d).\n',mfilename,expno);
end
idx = find(strcmpi(grp,tmpgrp.name));
set(wgts.GroupCmb,'Value',idx(1));
Data_Callback(hObject,'init',[]);

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
    adffile = ses.filename(expno,'phys');
  else
    adffile = expfilename(ses,expno,'phys');
  end
  set(wgts.DataFileEdt,'String',adffile);
  set(wgts.DataFileEdt,'UserData',expno);
  if isempty(dir(adffile)),
    fprintf(' adfviewer.Data_Callback: not found ''%s''.\n',adffile);
    return;
  end
  grp = getgrp(ses,expno);
  hardch = grp.hardch;
  adffile2 = expfilename(ses,expno,'phys2');
  if ~isempty(adffile2) && exist(adffile2,'file'),
    set(wgts.DataPairedFileEdt,'String',adffile2);
    set(wgts.DataPairedFileEdt,'UserData',expno);
  else
    set(wgts.DataPairedFileEdt,'String','');
  end
  Data_Callback(wgts.DataFileEdt,'reset-vars',[]);
 
 case {'reset-vars'}
  % reset appdata
  setappdata(wgts.main,'dgz',{});
  rmappdata(wgts.main,'dgz');
  setappdata(wgts.main,'datainfo','');
  setappdata(wgts.main,'NOBS',0);
  setappdata(wgts.main,'NCHAN',0);
  setappdata(wgts.main,'SAMPT',0);
  setappdata(wgts.main,'OBSLEN',[]);
  setappdata(wgts.main,'NCHAN2',0);
  setappdata(wgts.main,'SAMPT2',0);
  setappdata(wgts.main,'OBSLEN2',[]);
 
 case {'browse'}
  adffile = get(wgts.DataFileEdt,'String');
  if isempty(dir(adffile)),
    adffile = '';
  end
  [adffile pathname] = uigetfile(...
      {'*.adf;*.adfw;*.adfx', 'ADF-files (*.adf|adfw|adfx)'; ...
       '*.*',          'All Files (*.*)'}, ...
      'Pick an adffile',adffile);
  if isequal(adffile,0) || isequal(pathname,0)
    % canceled
  else
    adffile = fullfile(pathname,adffile);
    set(wgts.DataFileEdt,'String',adffile);
    % set Exps to ''
    set(wgts.ExpNoEdt,'String','');
    % set group to 'UNKNOWN'
    set(wgts.GroupCmb,'Value',length(get(wgts.GroupCmb,'String')));
    % set paired adf/adfw if exist.
    [fp,fr,fe] = fileparts(adffile);
    adffile2 = fullfile(fp,fr,'_2',fe);
    if exist(adffile2,'file'),
      set(wgts.DataPairedFileEdt,'String',adffile2);
    else
      set(wgts.DataPairedFileEdt,'String','');
    end
    % reset appdata
    Data_Callback(wgts.DataFileEdt,'reset-vars',[]);
  end
  
 case {'load'}
  adffile = get(wgts.DataFileEdt,'String');
  if strcmpi(adffile,'adffile'), return;  end
  if ~exist(adffile,'file'),
    fprintf(' adfviewer.Data_Callback: not found ''%s''.\n',adffile);
    return;
  end
  adffile2 = get(wgts.DataPairedFileEdt,'String');
  if ~isempty(adffile2) && exist(adffile2,'file'),
    MULTI_ADF = 1;
  else
    MULTI_ADF = 0;
    set(wgts.DataPairedFileEdt,'String','');
  end
  % get data-info %%%%%%%%%%%%%%%%%%
  datainfo = {};
  % get adf info
  [NCHAN, NOBS, sampt, obslen] = adf_info(adffile);
  OBSLEN = obslen*sampt/1000;  % in sec
  setappdata(wgts.main,'NCHAN',NCHAN);
  setappdata(wgts.main,'NOBS',NOBS);
  setappdata(wgts.main,'SAMPT',sampt/1000);  % SAMPT in sec.
  setappdata(wgts.main,'OBSLEN',OBSLEN);
  datainfo{1} = 'ADF info';
  datainfo{2} = '===================================';
  datainfo{3} = sprintf('nchan  = %d',NCHAN);
  datainfo{4} = sprintf('nobs   = %d',NOBS);
  datainfo{5} = sprintf('sampt  = %.4fms (%.2fkHz)',sampt,1/sampt);
  datainfo{6} = sprintf('obslen(pts) = %s',num2str(obslen));
  datainfo{6} = sprintf('obslen(sec) = %s',num2str(OBSLEN));
  if MULTI_ADF,
    [NCHAN2,tmp,sampt2,obslen2] = adf_info(adffile2);
    OBSLEN2 = obslen2*sampt2/1000;
    setappdata(wgts.main,'NCHAN2',NCHAN2);
    setappdata(wgts.main,'SAMPT2',sampt2/1000);
    setappdata(wgts.main,'OBSLEN2',OBSLEN2);
    datainfo{3} = sprintf('nchan  = %d (%d+%d)',NCHAN+NCHAN2,NCHAN,NCHAN2);
  else
    setappdata(wgts.main,'NCHAN2',0);
  end
  
  % get dgz info
  [fp,fr] = fileparts(adffile);
  dgzfile = fullfile(fp,strcat(fr,'.dgz'));
  if exist(dgzfile,'file'),
    dgz = dg_read(fullfile(fp,strcat(fr,'.dgz')));
    tmpinfo = {};
    tmpinfo{1} = '';
    tmpinfo{2} = 'DGZ Info';
    tmpinfo{3} = '==================================';
    tmpinfo{4} = sprintf('nobs = %d',length(dgz.e_types));
    tmpinfo{5} = 'DGZ System Parameters: dgz.e_pre';
    tmpinfo{6} = '==================================';
    k = length(tmpinfo) + 1;
    for n = 1:2:length(dgz.e_pre)-1,
      tmpinfo{k} = sprintf('%s: %s',dgz.e_pre{n}{2},dgz.e_pre{n+1}{2});
      k = k + 1;
    end
    datainfo = cat(2,datainfo,tmpinfo);
    obspdgz = zeros(size(OBSLEN));
    for n = 1:length(obspdgz),
      obspdgz(n) = dgz.e_times{n}(dgz.e_types{n} == 20)/1000; % in sec
    end
    [tmpv, tmpi] = max(obspdgz);
    dgz.tfactor = OBSLEN(tmpi)/obspdgz(tmpi);  % match to ADF
    setappdata(wgts.main,'dgz',dgz);
    clear obspdgz
  end
  % update info-box
  setappdata(wgts.main,'datainfo',datainfo);
  Main_Callback(wgts.InfoCmb,'selectinf',[]);
  % reset widget value
  set(wgts.DataObsEdt,'String','1');
  % set slider properties: +0.01 to prevent error
  set(wgts.DataObsSldr,'Min',1,'Max',NOBS+0.01,'Value',1);
  % create axes
  Plot_Callback(hObject,'init',[]);
 
 case {'load-plot'}
  adffile = get(wgts.DataFileEdt,'String');
  if ~exist(adffile,'file'),  return;  end
  Data_Callback(hObject,'load',[]);
  Plot_Callback(hObject,'overview',[]);
 
 case {'set-obs'}
  OBSP = sscanf(get(wgts.DataObsEdt,'String'),'%d',1);
  if isempty(OBSP),
    fprintf(' adfviewer.Data_Callback: invalid ObsNo.\n');
    return;
  end
  NOBS = getappdata(wgts.main,'NOBS');
  if OBSP < 1,
    OBSP = 1;
    set(wgts.EDataObsEdt,'String',num2str(OBSP));
    set(wgts.DataObsSldr,'Value',OBSP);
  elseif OBSP > NOBS,
    OBSP = NOBS;
    set(wgts.DataObsEdt,'String',num2str(NOBS));
    set(wgts.DataObsSldr,'Value',NOBS);
  end
  set(wgts.DataObsSldr,'Value',OBSP);
  
  Plot_Callback(hObject,'overview',[]);
  Plot_Callback(hObject,'zoomed',[]);
 
 case {'obs-slider'}
  OBSP = round(get(wgts.DataObsSldr,'Value'));
  set(wgts.DataObsEdt,'String',num2str(OBSP));
  Plot_Callback(hObject,'overview',[]);
  Plot_Callback(hObject,'zoomed',[]);
 
 case {'t-slider'}
  Plot_Callback(hObject,'zoomed',[]);
 
 case {'yscale'}
  % validate Ymin,Ymax
  Ymin = str2num(get(wgts.PlotYminEdt,'String'));
  if isempty(Ymin),
    Ymin = -20000;
    set(wgts.PlotYminEdt,'String',num2str(Ymin));
  end
  Ymax = str2num(get(wgts.PlotYmaxEdt,'String'));
  if isempty(Ymax),
    Ymax = 2000;
    set(wgts.PlotYmaxEdt,'String',num2str(Ymax));
  end
  if Ymin > Ymax,
    tmp = Ymin;    Ymin = Ymax;    Ymax = tmp;
    set(wgts.PlotYminEdt,'String',num2str(Ymin));
    set(wgts.PlotYmaxEdt,'String',num2str(Ymax));
  end
  % change YLim
  fnames = fieldnames(wgts);
  axesnames = fnames(strncmpi(fnames,'DataAxes2',9));
  for n = 1:length(axesnames),
    %eval(sprintf('h = wgts.%s;',axesnames{n}));
    h = wgts.(axesnames{n});
    set(h,'Ylim',[Ymin, Ymax]);
  end

 case {'t-window'}
  if ~isappdata(wgts.main,'OBSLEN'), return; end
  OBSLEN = getappdata(wgts.main,'OBSLEN');
  OBSP = sscanf(get(wgts.DataObsEdt,'String'),'%d',1);
  OBSLEN = OBSLEN(OBSP);
  % update slieder's step
  TWIN = str2num(get(wgts.PlotTwinEdt,'String'));
  sstep = [TWIN/OBSLEN/4, min([1.01 TWIN/OBSLEN*5])];
  set(wgts.TimeBarSldr,'SliderStep',sstep);
  % redraw data
  Plot_Callback(hObject,'zoomed',[]);
 
 case {'mri-event'}
  if ~isappdata(wgts.main,'dgz'),
    fprintf('%s: no accompanied dgz found.\n',mfilename);
    return;
  end
  dgz = getappdata(wgts.main,'dgz');
  T_MRI = getappdata(wgts.main,T_MRI);
  if isempty(T_MRI),  return;  end
  t_mri = T_MRI(1)*dgz.tfactor;
  
  % SAMPT = getappdata(wgts.main,'SAMPT');
  % adffile = get(wgts.DataFileEdt,'String');
  % OBSP = sscanf(get(wgts.DataObsEdt,'String'),'%d',1);
  % % find E_MRI(=46)
  % t_mri = dgz.e_times{OBSP}(dgz.e_types{OBSP} == 46);
  % if isempty(t_mri),  return;  end
  % t_mri = t_mri(1)/1000;  % first E_MRI(=46), the trigger.
  % % clock correction
  % t_end = dgz.e_times{OBSP}(dgz.e_types{OBSP} == 20)/1000; % in sec
  % OBSLEN = getappdata(wgts.main,'OBSLEN');  % in sec
  % t_factor = OBSLEN(OBSP)/t_end;
  % t_mri = t_mri * t_factor
  % %line([t_mri,t_mri],[0 1],'LineWidth',1,'Color',[1 0.3 0.3]);
  
  % % read the interferance channel
  % expno = str2num(get(wgts.ExpNoEdt,'String'));
  % if isempty(expno),  return;  end
  % expno = expno(1);
  % % get the channel for INTERFERENCE SIGNALS 
  % grp = getgrp(ses,expno);
  % if isfield(grp,'gradch') && ~isempty(grp.gradch)
  %   GRADCH = grp.gradch;
  % else
  %   %GRADCH = eval(sprintf('length(ses.grp.%s.hardch)+1',grp.name));
  %   GRADCH = length(grp.hardch) + 1;
  % end
  % % detect the 1st mri event
  % wv = adf_read(adffile,OBSP-1,GRADCH-1,0,round(t_mri/SAMPT));
  % wv = diff(wv);
  % t = find(wv < -1000);  % -1000 as THRESHOLD to detect MRI event.
  % if ~isempty(t),
  %   t_mri = t(1)*SAMPT;
  % else
  %   fprintf(' adfviewer.Data_Callback : failed to detect 1st MRI event.\n');
  % end

  % set time-window
  set(wgts.PlotTwinEdt,'String',num2str(0.2));
  % set slider position
  set(wgts.TimeBarSldr,'Value',max([0,t_mri-0.1]));
  % validate and plot data
  Data_Callback(hObject,'t-window',[]);
  
 otherwise
  fprintf(' adfviewer.Data_Callback : ''%s'' not supported yet.\n',eventdata);
  return;
end

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Plot_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(get(hObject,'Parent'));
ses  = getappdata(wgts.main,'session');
%if isempty(ses), return;  end
OBSP = sscanf(get(wgts.DataObsEdt,'String'),'%d',1);
if isempty(OBSP), return;  end
NCHAN  = getappdata(wgts.main,'NCHAN');
NCHAN2 = getappdata(wgts.main,'NCHAN2');
if NCHAN < 1, return; end
SAMPT = getappdata(wgts.main,'SAMPT');
OBSLEN = getappdata(wgts.main,'OBSLEN');
if isempty(OBSLEN),  return;  end
OBSLEN = OBSLEN(OBSP);
adffile  = get(wgts.DataFileEdt,'String');
adffile2 = get(wgts.DataPairedFileEdt,'String');
% yscale
Ymin = str2num(get(wgts.PlotYminEdt,'String'));
Ymax = str2num(get(wgts.PlotYmaxEdt,'String'));
if isempty(Ymin) || isempty(Ymax), return;  end
YLim = [Ymin,Ymax];
% time-window
TWIN = str2num(get(wgts.PlotTwinEdt,'String'));
% current time point
T = get(wgts.TimeBarSldr,'Value');

% PLOT DATA
switch eventdata
 case {'init'}
  % delete plot axes
  fnames = fieldnames(wgts);
  axesnames = fnames(strncmpi(fnames,'DataAxes',8));
  for n = 1:length(axesnames),
    eval(sprintf('delete(wgts.%s);',axesnames{n}));
  end
  % create axes
  set(wgts.AxsFrame,'units','char');
  pos = get(wgts.AxsFrame,'Position');
  set(wgts.AxsFrame,'units','normalized');
  XDSP = pos(1)+1.5;
  XDSPLEN = pos(3);
  YDSPLEN = (pos(4)-2)/(NCHAN+NCHAN2);
  % event plotting
  set(wgts.EventAxes,'units','char');
  set(...
      wgts.EventAxes,'Units','char',...
      'Position',[XDSP pos(2)+pos(4)+0.5 XDSPLEN*0.4-1.5 2.5],...
      'Box','on','FontSize',8,...
      'XTickLabel',[],'YTickLabel',[],...
      'color','black','xcolor',[0.9 0.9 0.9],'ycolor',[0.9 0.9 0.9]);
  set(wgts.EventAxes,'units','normalized');
  % data plotting
  for n = 1:NCHAN+NCHAN2,
    YDSP = pos(2) + pos(4) - n*YDSPLEN - 0.3;
    % overview
    h = axes(...
        'Parent',wgts.main,'Units','char',...
        'Position',[XDSP YDSP XDSPLEN*0.4-1.5 YDSPLEN],...
        'Box','on','FontSize',8,...
        'XTickLabel',[],'YTickLabel',[],...
        'color','black','xcolor',[0.9 0.9 0.9],'ycolor',[0.9 0.9 0.9],...
        'Tag',sprintf('DataAxes1_%d',n));
    set(h,'units','normalized');
    % magnified view
    h = axes(...
        'Parent',wgts.main,'Units','char',...
        'Position',[XDSP+XDSPLEN*0.4 YDSP XDSPLEN*0.6-3 YDSPLEN],...
        'Box','on','FontSize',8,...
        'XTickLabel',[],'YTickLabel',[],...
        'color','black','xcolor',[0.9 0.9 0.9],'ycolor',[0.9 0.9 0.9],...
        'Tag',sprintf('DataAxes2_%d',n));
    set(h,'units','normalized');
  end
 case {'overview'}
  % get Events if possible
  if isappdata(wgts.main,'dgz'),
    dgz = getappdata(wgts.main,'dgz');
    e_types = dgz.e_types{OBSP};
    e_subs  = dgz.e_subtypes{OBSP};
    e_times = dgz.e_times{OBSP}/1000;
    idx = find(e_types == 22);  % E_TRIALTYPE = 22
    setappdata(wgts.main,'T_TRIAL',e_times(idx));
    idx = find(e_types == 27 & e_subs == 2); % E_STIMULUS = 27
    setappdata(wgts.main,'T_STIMON',e_times(idx));
    setappdata(wgts.main,'P_STIMON',dgz.e_params{OBSP}(idx));
    idx = find(e_types == 42);  % E_REWARD = 42
    setappdata(wgts.main,'T_REWARD',e_times(idx));
    idx = find(e_types == 46);  % E_MRI = 46
    setappdata(wgts.main,'T_MRI',e_times(idx));
  else
    setappdata(wgts.main,'T_TRIAL',[]);
    setappdata(wgts.main,'T_STIMON',[]);
    setappdata(wgts.main,'P_STIMON',[]);
    setappdata(wgts.main,'T_REWARD',[]);
    setappdata(wgts.main,'T_MRI',   []);
  end
  % get 'hardch' and 'gradch', if possible,
  expno = str2num(get(wgts.ExpNoEdt,'String'));
  hardch = [];  gradch = [];
  if ~isempty(expno) && ~isempty(ses),
    expno = expno(1);
    grp = getgrp(ses,expno);
    if isfield(grp,'hardch'),  hardch = grp.hardch;  end
    if isimaging(grp) && isfield(grp,'gradch')
      gradch = grp.gradch;
    end
  end
  % set time slider
  tmax = min([OBSLEN,OBSLEN-TWIN]);
  sstep = [TWIN/OBSLEN/4, min([1.01 TWIN/OBSLEN*5])];
  set(wgts.TimeBarSldr,'Min',0,'Max',tmax,'SliderStep',sstep,'Value',0);
  % plot overview
  adffile = get(wgts.DataFileEdt,'String');
  NCHAN = getappdata(wgts.main,'NCHAN');
  tsel = 1:20:round(OBSLEN/SAMPT);
  t = tsel*SAMPT;
  TLim = [0, max(t)];
  % NEED TO CHANGE HandleVisibilty to plot data
  set(wgts.main,'HandleVisibility','on');

  % PLOT EVENT
  if isappdata(wgts.main,'dgz'),
    dgz = getappdata(wgts.main,'dgz');
    set(wgts.main,'CurrentAxes',wgts.EventAxes);
    delete(get(wgts.EventAxes,'Children'));
    % draw the selected time-window
    rectangle('Position',[0,0,TWIN,1],'Tag','TWIN',...
              'FaceColor',[0.85 0.85 1],'EdgeColor',[0.85 0.85 1]);

    T_TRIAL = getappdata(wgts.main,'T_TRIAL');
    for n = 1:length(T_TRIAL),
      ts = T_TRIAL(n);
      line([ts,ts],[0 1],'LineWidth',1,'Color',[0.3 1 0.3]);
      text(ts,0.5,'T','FontSize',8,'color',[0.2 0.9 0.2]);
    end
    T_STIMON = getappdata(wgts.main,'T_STIMON');
    P_STIMON = getappdata(wgts.main,'P_STIMON');
    for n = 1:length(T_STIMON),
      ts = T_STIMON(n);
      line([ts,ts],[0 1],'LineWidth',1,'Color',[1 1 0.3]);
      if length(P_STIMON{n}) >= 3,
        tmpstr = sprintf('S%d',P_STIMON{n}(3));
        text(ts,0.5,tmpstr,'FontSize',8,'color',[0.9 0.9 0.2]);
      end
    end
    T_REWARD = getappdata(wgts.main,'T_REWARD');
    for n = 1:length(T_REWARD),
      ts = T_REWARD(n);
      line([ts,ts],[0 1],'LineWidth',1,'Color',[1 0.1 0.3]);
      text(ts,0.5,'R','FontSize',8,'color',[0.9 0.2 0.2]);
    end
    T_MRI = getappdata(wgts.main,'T_MRI');
    % plot the 1st MRI alone
    if ~isempty(T_MRI),
      ts = T_MRI(1);
      line([ts,ts],[0 1],'LineWidth',1,'Color',[1 0.7 0.7],'tag','LineMri');
      text(ts,0.5,'M','FontSize',8,'color',[0.9 0.6 0.6],'tag','TxtMri');
    end
    
    set(wgts.EventAxes,'Tag','EventAxes',...
          'color','black','xcolor',[0.9 0.9 0.9],'ycolor',[0.9 0.9 0.9],...
          'XTickLabel',[],'YTickLabel',[],...
          'XLim',TLim,'YLim',[0 1]);
    SHOW_EVENT = 1;
  else
    SHOW_EVENT = 0;
  end
  % PLOT DATA
  for chan = 1:NCHAN+NCHAN2,
    h = eval(sprintf('wgts.DataAxes1_%d',chan));
    if chan <= NCHAN,
      wv = adf_read(adffile,OBSP-1,chan-1);
    else
      wv = adf_read(adffile2,OBSP-1,chan-NCHAN-1);
    end
    set(wgts.main,'CurrentAxes',h);
    plot(t,wv(tsel),'Color',[0.8 0.7 0.7],'Tag','Data');
    hold on;
    % draw the selected time-window
    rectangle('Position',[0,-35000,TWIN,70000],'Tag','TWIN',...
              'FaceColor','none','EdgeColor',[0.85 0.85 1]);
     
    tmpstr = sprintf(' Ch%02d',chan);
    if ~isempty(gradch) && chan == gradch,
      tmpstr = sprintf('%s-GRAD',tmpstr);
    elseif ~isempty(hardch) && any(hardch == chan),
      tmpstr = sprintf('%s-ELE',tmpstr);
    end
    % if ~isempty(hardch) && chan <= length(hardch)
    %   tmpstr = sprintf(' Ch%02d-EL%02d',chan,hardch(chan));
    % else
    %   tmpstr = sprintf(' Ch%02d',chan);
    % end

    text(0,0.85,tmpstr,'Units','normalized',...
         'FontSize',8,'FontWeight','bold',...
         'Color',[1 1 0.9]);
    hold off;
    % NEED TO SET 'UserData' here since plot() will reset it.
    set(h,'UserData',int16(wv));  % keep as int16
    % NEED TO SET 'TAG' since plot() will reset it.
    set(h,'Tag',sprintf('DataAxes1_%d',chan),...
          'color','black','xcolor',[0.9 0.9 0.9],'ycolor',[0.9 0.9 0.9],...
          'XLim',TLim,'YLim',YLim);
    if chan == NCHAN+NCHAN2,
      set(h,'XTickMode','auto','YTickLabel',[]);
    else
      set(h,'XTickLabel',[],'YTickLabel',[]);
    end
    if SHOW_EVENT,
      for n = 1:length(T_STIMON),
        ts = T_STIMON(n);
        %tmpstr = sprintf('S%d',P_STIMON{n}(3));
        line([ts,ts],YLim,'LineWidth',1,'Color',[1 1 0.3],'tag','LineStim');
      end
      if ~isempty(T_MRI),
        ts = T_MRI(1);
        line([ts,ts],YLim,'LineWidth',1,'Color',[1 0.7 0.7],'tag','LineMri');
      end
    end
  end

  set(wgts.main,'HandleVisibility','off');
  % PLOT ZOOMED DATA
  Plot_Callback(wgts.DataObsEdt,'zoomed',[]);
 
 case {'zoomed'}
  % get index for partial reading.
  ts = round(T/SAMPT) + 1;  % +1 for matlab indexing
  tw = round(TWIN/SAMPT);
  tsel = ts:ts+tw;
  tselmax = max(tsel);
  t = tsel*SAMPT;
  TLim = [min(t), max(t)];
  % NEED TO CHANGE HandleVisibilty to plot data
  set(wgts.main,'HandleVisibility','on');
  % change rectangles in overview axes
  hr = [];
  for chan = 1:NCHAN+NCHAN2,
    h = eval(sprintf('wgts.DataAxes1_%d',chan));
    hr(chan) = findobj(h,'Tag','TWIN');
  end
  if isappdata(wgts.main,'dgz'),
    hr(end+1) = findobj(wgts.EventAxes,'Tag','TWIN');
  end
  set(hr,'Position',[T,-35000,TWIN,70000]);

  % Plot data in zoomed axes
  for chan = 1:NCHAN+NCHAN2,
    % retreive data
    h = eval(sprintf('wgts.DataAxes1_%d',chan));
    wv = get(h,'UserData');
    %wv = adf_read(adffile,OBSP-1,chan-1,ts-1,length(t));
    h = eval(sprintf('wgts.DataAxes2_%d',chan));
    set(wgts.main,'CurrentAxes',h);
    if max(tsel) > length(wv),
      % paired adf may differ in length a very little...
      wv = wv(tsel(1):end);
      tmpt = t(1:length(wv));
      plot(tmpt,wv,'Color',[0.85 0.85 1],'Tag','Data');
    else
      wv = wv(tsel);
      plot(t,wv,'Color',[0.85 0.85 1],'Tag','Data');
    end
    % NEED TO SET 'TAG' since plot() will reset it.
    set(h,'Tag',sprintf('DataAxes2_%d',chan),...
          'color','black','xcolor',[0.9 0.9 0.9],'ycolor',[0.9 0.9 0.9],...
          'XLim',TLim,'YLim',YLim);
    if chan == NCHAN+NCHAN2,
      set(h,'XTickMode','auto','YTickLabel',[]);
    else
      set(h,'XTickLabel',[],'YTickLabel',[]);
    end
  end
  set(wgts.main,'HandleVisibility','off');
  Plot_Callback(wgts.DataObsEdt,'zoomed-event',[]);
 
 case {'zoomed-event'}
  TLim = get(wgts.DataAxes2_1,'xlim');
  % check events
  if isappdata(wgts.main,'dgz'),
    T_STIMON = getappdata(wgts.main,'T_STIMON');
    T_STIMON = T_STIMON(T_STIMON >= TLim(1) & T_STIMON <= TLim(2));
    T_MRI    = getappdata(wgts.main,'T_MRI');
    T_MRI    = T_MRI(T_MRI >= TLim(1) & T_MRI <= TLim(2));
    if any(get(wgts.DgzClkCorrChk,'value')),
      dgz = getappdata(wgts.main,'dgz');
      T_STIMON = T_STIMON * dgz.tfactor;
      T_MRI    = T_MRI    * dgz.tfactor;
    end
  else
    T_STIMON = [];
    T_MRI    = [];
  end
  SHOW_STIM = get(wgts.ShowStimChk,'value');
  SHOW_MRI  = get(wgts.ShowMriChk,'value');
  set(wgts.main,'HandleVisibility','on');
  % Plot data in zoomed axes
  for chan = 1:NCHAN+NCHAN2,
    h = eval(sprintf('wgts.DataAxes2_%d',chan));
    set(wgts.main,'CurrentAxes',h);
    hobjs = findobj(h,'Tag','LineStim');
    if any(hobjs),
      if any(SHOW_STIM),
        set(hobjs,'visible','on');
      else
        set(hobjs,'visible','off');
      end
    elseif any(SHOW_STIM),
      % plot events
      for k = 1:length(T_STIMON),
        ts = T_STIMON(k);
        line([ts,ts],YLim,'LineWidth',1,'Color',[1 1 0.3],'tag','LineStim');
      end
    end
    hobjs = findobj(h,'Tag','LineMri');
    if any(hobjs),
      if any(SHOW_MRI),
        set(hobjs,'visible','on');
      else
        set(hobjs,'visible','off');
      end
    elseif any(SHOW_MRI),
      % plot events
      for k = 1:length(T_MRI),
        ts = T_MRI(k);
        line([ts,ts],YLim,'LineWidth',1,'Color',[1 0.7 0.7],'tag','LineMri');
      end
    end
  end
  set(wgts.main,'HandleVisibility','off');
  
 otherwise
  fprintf(' adfviewer.Plot_Callback : ''%s'' not supported yet.\n',eventdata);
  return;
end


return;
