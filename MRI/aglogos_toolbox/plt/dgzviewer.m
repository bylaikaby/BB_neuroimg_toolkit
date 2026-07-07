function varargout = dgzviewer(varargin)
%DGZVIEWER - GUI to veiew dgz events.
%  DGZVIEWER(DGZFILE)
%  DGZVIEWER(SESSION,EXPNO) runs GUI to view dgz events.
%
%  EXAMPLE :
%    dgzviewer('E/DataNeuro/C98.NM1/c98nm1_001.dgz')
%    dgzviewer(SESSION,EXPNO)
%
%  VERSION :
%    0.90 14.12.03 YM  first release
%    0.91 20.04.04 YM  bug fix
%    0.92 04.06.04 YM  bug fix on E_STRINGS_X
%    0.93 26.06.04 YM  warning fix for Matlab R14
%    0.94 10.07.06 YM  bug fix on parameters out of edit-box.
%    0.95 19.09.08 YM  supports new csession class.
%
%  See also dg_read adfviewer tcimgmovie imgviewer

%persistent H_DGZVIEWER;    % keep the figure handle


if nargin == 0,  help dgzviewer;  return;  end

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
SESSION = '';  DGZFILE = '';
if any(strfind(varargin{1},'.dgz')),
  % varargin{1} as a 'DGZFILE'
  DGZFILE = varargin{1};
else
  % varargin{1} as a 'SESSION'
  SESSION = varargin{1};
  if nargin >= 2,
    EXPNO = varargin{2};
  else
    EXPNO = [];
  end
end

% %% prevent double execution
% if ishandle(H_DGZVIEWER),
%   close(H_DGZVIEWER);
%   %fprintf('\n ''dgzviewer'' already opened.\n');
%   %return;
% end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CREATE THE MAIN WINDOW
% Reminder: get(0,'DefaultUicontrolBackgroundColor')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[scrW scrH] = getScreenSize('char');
figW = 160.0;  figH = 45.0;
figX =  31.0;  figY = scrH-figH-3;  % 3 for menu and title bars.
hMain = figure(...
    'Name','DGZ Viewer','NumberTitle','off', ...
    'Tag','main', 'MenuBar', 'none', ...
    'HandleVisibility','callback','Resize','on',...
    'DoubleBuffer','on', 'Visible','off',...
    'Units','char','Position',[figX figY figW figH],...
    'Color',[0.8 0.83 0.83]);
H_DGZVIEWER = hMain;
if ~isempty(SESSION), setappdata(hMain,'session',SESSION);  end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PULL-DOWN MENU [File Edit View Help]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- FILE
hMenuFile = uimenu(hMain,'Label','File');
uimenu(hMenuFile,'Label','Exit','Separator','on',...
       'Callback','dgzviewer(''Main_Callback'',gcbo,''exit'',[])');

% --- EDIT
hMenuEdit = uimenu(hMain,'Label','Edit');
uimenu(hMenuEdit,'Label','dgzviewer',...
       'Callback','edit ''dgzviewer'';');
hCB = uimenu(hMenuEdit,'Label','dgzviewer : Callbacks');
uimenu(hCB,'Label','Main_Callback',...
       'Callback','dgzviewer(''Main_Callback'',gcbo,''edit-cb'',[])');
uimenu(hCB,'Label','Session_Callback',...
       'Callback','dgzviewer(''Main_Callback'',gcbo,''edit-cb'',[])');
uimenu(hCB,'Label','Group_Callback',...
       'Callback','dgzviewer(''Main_Callback'',gcbo,''edit-cb'',[])');
uimenu(hCB,'Label','ExpNoEdt_Callback',...
       'Callback','dgzviewer(''Main_Callback'',gcbo,''edit-cb'',[])');
uimenu(hCB,'Label','Data_Callback',...
       'Callback','dgzviewer(''Main_Callback'',gcbo,''edit-cb'',[])');

% --- VIEW
hMenuView = uimenu(hMain,'Label','View');
uimenu(hMenuView,'Label','Redraw',...
       'Callback','dgzviewer(''Plot_Callback'',gcbo,[],[])');

% --- HELP
hMenuHelp = uimenu(hMain,'Label','Help');
uimenu(hMenuHelp,'Label','Analysis Package','Callback','helpwin');
uimenu(hMenuHelp,'Label','dgzviewer','Separator','on',...
       'Callback','helpwin dgzviewer');


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
% ENTRY SESSION - Enter the session
SessionEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[14 H 23 1.5],...
    'Callback','dgzviewer(''Session_Callback'',gcbo,''set'',guidata(gcbo))',...
    'String','session','Tag','SessionEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','set the session',...
    'FontWeight','bold','BackgroundColor','white');
% BROWSE BUTTON -  - Invokes the path/file finder (Select File to Open)
SessionBrowseBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[37 H 4 1.5],...
    'Callback','dgzviewer(''Session_Callback'',gcbo,''browse'',guidata(gcbo))',...
    'Tag','SessionBrowseBtn',...
    'TooltipString','Browse a session',...
    'ForegroundColor','white','BackgroundColor','white');
mguiSetIcon(SessionBrowseBtn,'stock_open16x16.png');
% EDIT BUTTON - Invokes Emacs session.m
SessionEditBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[41 H 4 1.5],...
    'Callback','dgzviewer(''Session_Callback'',gcbo,''edit'',guidata(gcbo))',...
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
    'Callback','dgzviewer(''Session_Callback'',gcbo,''default'',[])',...
    'Tag','SessionDefaultBtn','String','Debug',...
    'TooltipString','set to default','FontWeight','bold',...
    'ForegroundColor',[0.9 0.9 0],'BackgroundColor',[0.3 0 0.1]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GROUP UI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = H - 1.8;
% LABEL - Group:
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[0.5 H-0.2 12 1.5],...
    'String','Group :','FontWeight','bold',...
    'HorizontalAlignment','right',...
    'BackgroundColor',get(hMain,'Color'));
% COMBOBOX - Group selection in the current session
GroupCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[14 H 23 1.5],...
    'String',{'group'},...
    'Callback','dgzviewer(''Group_Callback'',gcbo,''select'',[])',...
    'TooltipString','group selection',...
    'Tag','GroupCmb','FontWeight','Bold');
% EDIT BUTTON - Invokes Emacs session.m to edit the selected group.
GroupEditBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[37 H 4 1.5],...
    'Callback','dgzviewer(''Group_Callback'',gcbo,''edit'',)',...
    'Tag','GroupEditBtn',...
    'TooltipString','edit the group params',...
    'ForegroundColor','white','BackgroundColor','white');
mguiSetIcon(GroupEditBtn,'stock_edit16x16.png');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXPNO UI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = H - 1.8;
% LABEL - Exps:
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[0.5 H-0.2 12 1.5],...
    'String','Exps :','FontWeight','bold',...
    'HorizontalAlignment','right',...
    'BackgroundColor',get(hMain,'Color'));
% ENTRY - Enter the experiment number.
ExpNoEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[14 H 49 1.5],...
    'Callback','dgzviewer(''ExpNoEdt_Callback'',gcbo,[],[])',...
    'String','exp. numbers','Tag','ExpNoEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','set exp. number(s)',...
    'FontWeight','Bold');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DATA UI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = H - 2;
% LABEL - dgz:
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[0.5 H-0.2 7 1.5],...
    'String','dgz :','FontWeight','bold',...
    'HorizontalAlignment','right',...
    'BackgroundColor',get(hMain,'Color'));
% ENTRY - Enter a dgzfile
DataFileEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[8 H 51 1.5],...
    'String','dgzfile','Tag','DataFileEdt',...
    'HorizontalAlignment','left','FontWeight','normal',...
    'TooltipString','dgz file');
% BROWSE BUTTON - Invokes the path/file finder (Select File to Open)
DataBrowseBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[59 H 4 1.5],...
    'Callback','dgzviewer(''Data_Callback'',gcbo,''browse'',guidata(gcbo))',...
    'Tag','DataBrowseBtn',...
    'TooltipString','Browse a dgzfile',...
    'ForegroundColor','white','BackgroundColor','white');
mguiSetIcon(DataBrowseBtn,'stock_open16x16.png');

H = H - 2;
% LOAD DATA BUTTON - Load the selected dgzfile.
DataLoadBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[48 H 15 1.5],...
    'Callback','dgzviewer(''Data_Callback'',gcbo,''load'',[])',...
    'Tag','DataLoadBtn','String','Load DGZ',...
    'TooltipString','Load data','FontWeight','bold',...
    'ForegroundColor',[0.9 0.9 0],'BackgroundColor',[0 0 0.5]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
% INFO UI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
H = H - 4;
% FRAME
uicontrol(...
    'Parent',hMain,'Style','frame',...
    'Units','char','Position',[0 0 64 H+1.8],...
    'ForegroundColor','black','BackgroundColor','black');
% COMBOBOX - Select the info-type to display.
InfoCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[38 H 25 1.5],...
    'String',{'Session','Group','Events (e_names)','Params (e_pre)'},...
    'Callback','dgzviewer(''Main_Callback'',gcbo,''selectinf'',[])',...
    'HorizontalAlignment','left',...
    'TooltipString','info selection',...
    'Tag','InfoCmb','FontWeight','Bold');
% LISTBOX - Displays the selected information
InfoTxt = uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','char','Position',[0.2 0.2 63 H-0.4],...
    'String',{'session','group'},...
    'Callback','dgzviewer(''Main_Callback'',gcbo,''edit-info'',[])',...
    'HorizontalAlignment','left','FontName','Courier New',...
    'Tag','InfoTxt','Background','white');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EVENT INFO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bkgc = [0.85 0.8 0.85];
% FRAME
uicontrol(...
    'Parent',hMain,'Style','frame',...
    'Units','char','Position',[65 0 figW-65 figH],...
    'ForegroundColor',bkgc,'BackgroundColor',bkgc);

H = figH - 2.2;
% TEXT - DGZFILE info
DgzInfoTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[67+1 H-0.2 70 1.5],...
    'String','DGZ:','FontWeight','bold',...
    'Tag','DgzInfoTxt',...
    'HorizontalAlignment','left',...
    'Background',bkgc);
% CHECHKBOX - Show/Hide MRI events (E_MRI=46)
ShowMriEvtChk = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[figW-25 H 25 1.5],...
    'String','Show E_MRI','FontWeight','bold',...
    'Tag','ShowMriEvtChk',...
    'Callback','dgzviewer(''Data_Callback'',gcbo,''show-event'',[])',...
    'HorizontalAlignment','left',...
    'TooltipString','Show/Hide E_MRI(=46)','BackgroundColor',bkgc);

H = H - 2;
% LABEL - Obsp.No:
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[67+1 H-0.2 11 1.5],...
    'String','Obs.No:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Background',bkgc);
% ENTRY - Enter the observation number to display
DataObsEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[67+11+1 H 10 1.5],...
    'String','ObsNo','FontWeight','bold',...
    'Callback','dgzviewer(''Data_Callback'',gcbo,''set-obs'',[])',...
    'Tag','DataObsEdt');
% SLIDER for observation display
DataObsSldr = uicontrol(...
    'Parent',hMain,'Style','Slider',...
    'Units','char','Position',[67+25 H figW-68-25 1],...
    'Callback','dgzviewer(''Data_Callback'',gcbo,''slider'',[])',...
    'Tag','DataObsSldr');

H = H - 2;
% ENTRY (inactive) - Shows tag of event-information.
uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[67 H figW-68 1.5],...
    'String','EvtNo: Time(sec)  Type SubT NPrms    Notes',...
    'Callback','dgzviewer(''Main_Callback'',gcbo,''edit-info'',[])',...
    'HorizontalAlignment','left','FontName','Courier New',...
    'Enable','inactive','Background','white');

H = 3;
% LISTBOX - Displays event info in the current obsp.
EventTxt = uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','char','Position',[67 H figW-68 figH-9.4],...
    'String',{'event'},...
    'Callback','dgzviewer(''Data_Callback'',gcbo,''show-params'',[])',...
    'HorizontalAlignment','left','FontName','Courier New',...
    'Tag','EventTxt','Background','white');

H = H - 1.8;
% LABEL - Event Params:
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[67 H-0.2 20 1.5],...
    'String','Event Params:','FontWeight','bold',...
    'HorizontalAlignment','left','Background',bkgc);
% ENTRY (inactive) - Display parameter varlue of the selected event.
EventParamEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[67+18 H figW-67-18-1 1.5],...
    'String','event params','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','EventParamEdt','Enable','inactive',...
    'TooltipString','parameter values of the selected event');



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
  if ~isempty(DGZFILE),
    set(DataFileEdt,'String',DGZFILE);
    Data_Callback(DataFileEdt,'load',[]);
  end
end
set(hMain,'Visible','on');

% get widgets handles at this moment
HANDLES = findobj(hMain);
% NOW SET "UNITS" OF ALL WIDGETS AS "NORMALIZED".
HANDLES = HANDLES(HANDLES ~= hMain);
for N = 1:length(HANDLES),
  try
    set(HANDLES(N),'units','normalized');
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
    mguiEdit(which('dgzviewer'),sprintf('function %s(hObject',token));
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
   case {'events','events (e_names)'}
    tmptxt = getappdata(wgts.main,'evtinfo');
   case {'param','params','params (e_pre)'}
    tmptxt = getappdata(wgts.main,'prminfo');
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
    fprintf(' dgzviewer.Main_Callback: ''%s'' not found.\n');
    return;
  end
  mguiEdit(editfile,token);
  
 otherwise
  fprintf(' dgzviewer.Main_Callback: ''%s'' not supported yet.\n',eventdata);
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
  if exist(sesfile,'file') ~= 2,
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
  if exist(sesfile,'file') == 2,
    eval(sprintf('edit %s;',sesfile));
  else
    edit;
  end
 case { 'set','editbox','select','cmbbox' }
  % update group/exp.no
  set(wgts.GroupCmb,'String',{'group'});
  set(wgts.ExpNoEdt,'String','');
  if exist(sesfile,'file') ~= 2,
    fprintf(' dgzviewer.Session_Callback : ''%s.m'' not found.\n',sesfile);
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
  dgzviewer('Group_Callback',wgts.GroupCmb,'init',[]);
  
 otherwise
  fprintf(' dgzviewer.Session_Calllback : ''%s'' not supported yet.\n',eventdata);
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
idx = find(strcmpi(grp,tmpgrp.name));
set(wgts.GroupCmb,'Value',idx(1));
Data_Callback(wgts.DataFileEdt,'init',[]);

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
    dgzfile = ses.filename(expno,'dgz');
  else
    dgzfile = expfilename(ses,expno,'dgz');
  end
  set(wgts.DataFileEdt,'String',dgzfile);
  set(wgts.DataFileEdt,'UserData',expno);
  if isempty(dir(dgzfile)),
    fprintf(' dgzviewer.Data_Callback: not found ''%s''.\n',dgzfile);
    return;
  end
 case {'browse'}
  dgzfile = get(wgts.DataFileEdt,'String');
  if isempty(dir(dgzfile)),
    dgzfile = '*.dgz';
  end
  [dgzfile pathname] = uigetfile(...
      {'*.dgz', 'DGZ-files (*.dgz)'; ...
       '*.*',   'All Files (*.*)'}, ...
      'Pick a dgzfile',dgzfile);
  if isequal(dgzfile,0) || isequal(pathname,0)
    % canceled
  else
    dgzfile = fullfile(pathname,dgzfile);
    set(wgts.DataFileEdt,'String',dgzfile);
    % set Exps to ''
    set(wgts.ExpNoEdt,'String','');
    % set group to 'UNKNOWN'
    set(wgts.GroupCmb,'Value',length(get(wgts.GroupCmb,'String')));
    Data_Callback(wgts.DataFileEdt,'load',[]);
  end
 case {'load'}
  dgzfile = get(wgts.DataFileEdt,'String');
  if strcmpi(dgzfile,'dgzfile'), return;  end
  if ~exist(dgzfile,'file'),
    fprintf(' dgzviewer.Data_Callback: not found ''%s''.\n',dgzfile);
    return;
  end
  dgz = dg_read(dgzfile);
  % keep dgz
  setappdata(wgts.main,'dgz',dgz);
  nobs = length(dgz.e_types);
  % set DgzInfoTxt
  [fp,fr,fe] = fileparts(dgzfile);
  tmpstr = sprintf('DGZ:  %s by ''%s''  NObs=%d',...
                   strcat(fr,fe),dgz.e_pre{1}{2},nobs);
  set(wgts.DgzInfoTxt,'String',tmpstr);
  % update event-name info
  tmpinfo = {};
  tmpinfo{1} = 'Event Definition : dgz.e_names';
  tmpinfo{2} = '==================================';
  for n = 1:size(dgz.e_names,1),
    tmpinfo{n+2} = sprintf('%3d: %s',n-1,deblank(dgz.e_names(n,:)));
  end
  setappdata(wgts.main,'evtinfo',tmpinfo);
  % update param info
  tmpinfo = {};
  tmpinfo{1} = 'System Parameters: dgz.e_pre';
  tmpinfo{2} = '==================================';
  k = length(tmpinfo) + 1;
  for n = 1:2:length(dgz.e_pre)-1,
    if ischar(dgz.e_pre{n}{2}),
      tmpinfo{k} = sprintf('%s: %s',dgz.e_pre{n}{2},mat2str(dgz.e_pre{n+1}{2}));
      k = k + 1;
    end
  end
  setappdata(wgts.main,'prminfo',tmpinfo);

  % update info-box
  Main_Callback(wgts.InfoCmb,'selectinf',[]);
  % initialize DataObsEdr, DataObsSldr
  tmpstr = sprintf('max.obsp = %d',nobs);
  set(wgts.DataObsEdt,'String',num2str(1),'TooltipString',tmpstr);
  mstep = 1/nobs;  lstep = 10*mstep;
  set(wgts.DataObsSldr,'Min',1,'Max',nobs+mstep*0.01,'Value',1,...
                    'SliderStep',[mstep, lstep],...
                    'TooltipString',tmpstr);
  Data_Callback(wgts.DataObsEdt,'show-event',[]);
 case {'set-obs'}
  OBSP = sscanf(get(wgts.DataObsEdt,'String'),'%d',1);
  if isempty(OBSP),
    fprintf(' dgzviewer.Data_Callback: invalid ObsNo.\n');
    return;
  end
  dgz = getappdata(wgts.main,'dgz');
  if isempty(dgz), return;  end
  NOBS = length(dgz.e_times);
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
  Data_Callback(wgts.DataObsEdt,'show-event',[]);
 case {'show-event'}
  dgz = getappdata(wgts.main,'dgz');
  if isempty(dgz), return;  end
  SHOW_MRI = get(wgts.ShowMriEvtChk,'Value');
  OBSP = sscanf(get(wgts.DataObsEdt,'String'),'%d',1);
  if isempty(OBSP), return;  end
  % set event strings in the current obsp.
  tmpinfo = {};  k = 1;
  e_times = dgz.e_times{OBSP};
  e_types = dgz.e_types{OBSP};
  e_subs  = dgz.e_subtypes{OBSP};
  e_params = dgz.e_params{OBSP};
  for n = 1:length(e_types),
    % E_MRI = 46
    if ~SHOW_MRI && e_types(n) == 46, continue;  end
    if ischar(e_params{n}),
      nparams = size(e_params{n},1);
    else
      nparams = length(e_params{n});
    end
    tmpinfo{k} = sprintf(...
        '%5d: %9.3f   %3d %3d    %2d     %s',...
        n, e_times(n)/1000, e_types(n), e_subs(n), nparams,...
        deblank(dgz.e_names(e_types(n)+1,:)));
    k = k + 1;
  end
  set(wgts.EventTxt,'String',tmpinfo,'Value',1);
  Data_Callback(wgts.EventTxt,'show-params',[]);
 case {'show-params'}
  dgz = getappdata(wgts.main,'dgz');
  if isempty(dgz), return;  end
  OBSP = sscanf(get(wgts.DataObsEdt,'String'),'%d',1);
  if isempty(OBSP), return;  end
  tmpstr = get(wgts.EventTxt,'String');
  tmpstr = tmpstr{get(wgts.EventTxt,'Value')};
  N = sscanf(tmpstr,'%d',1);
  e_param = dgz.e_params{OBSP}{N};
  if isnumeric(e_param),
    remain = num2str(e_param(:)');
    [tmptxt remain] = strtok(remain);
    while 1,
      [token, remain] = strtok(remain);
      if isempty(token), break;  end
      tmptxt = sprintf('%s   %s',tmptxt,token);
    end
  elseif iscell(e_param),
    tmptxt = '';
    for n = 1:length(e_param),
      tmptxt = cat(2,tmptxt,' ',e_param{n});
    end
  elseif ischar(e_param),
    tmptxt = '';
    for n = 1:size(e_param,1),
      tmptxt = cat(2,tmptxt,deblank(e_param(n,:)),' ');
    end
    tmptxt = deblank(tmptxt);
  else
    tmptxt = '';
  end
  %set(wgts.EventParamEdt,'String',sprintf('%d:  %s',N,tmptxt));
  % Warning: Single line Edit Controls can not have multi-line text.
  set(wgts.EventParamEdt,'String',strrep(tmptxt,char(10),'\n'));

 case {'slider'}
  OBSP = round(get(wgts.DataObsSldr,'Value'));
  set(wgts.DataObsEdt,'String',num2str(OBSP));
  Data_Callback(wgts.DataObsSldr,'show-event',[]);
  
 otherwise
  fprintf(' dgzviewer.Data_Callback : ''%s'' not supported yet.\n',eventdata);
  return;
end

return;
