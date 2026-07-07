function varargout = ClnBlpGui3(varargin)

% if Callback of GUI elements required
if ischar(varargin{1}) && ~isempty(strfind(varargin{1},'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return;
end


%%%%%%%%%%%%%%%%%%%%%
% Load session data %
%%%%%%%%%%%%%%%%%%%%%

if issig(varargin{1})
    % called like ClnBlpGui(Cln,blp,nevt,Spkt,...)
    cln=varargin{1};
    blp=varargin{2};
    nevt=varargin{3};
    spkt=varargin{4};
else
    % called like ClnBlpGui(Session,ExpNo,...)
    ses=varargin{1};
    ExpNum=varargin{2};
    ses = goto(ses);
    grp = getgrp(ses,ExpNum);
    if isnumeric(ExpNum)
      fprintf('%s : %s exp=%d(%s) : ',mfilename,ses.name,ExpNum,grp.name);
    else
      fprintf('%s : %s/%s : ',mfilename,ses.name,grp.name);
    end
    fprintf(' loading Cln.');
    Cln=sigload(ses, ExpNum, 'Cln');
    fprintf('blp.');
    blp=sigload(ses, ExpNum, 'blp');
    fprintf('nevt.');
    nevt=sigload(ses, ExpNum, 'nevt');
    fprintf('Spkt.');
    Spkt=sigload(ses, ExpNum, 'Spkt');
    fprintf(' done.\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%
% Make GUI %
%%%%%%%%%%%%

% ================== %
% Main figure window %
% ================== %
[scrW scrH] = subGetScreenSize('char');
if scrH > 70,
  figW = 315; figH = 83;
else
  figW = 220; figH = 53;
end
figX = 2;  figY = scrH-figH-6;

hMain = figure(...
    'Name','ClnBlpGui','NumberTitle','off', ...
    'Tag','main','MenuBar', 'figure', 'Toolbar','figure',...
    'HandleVisibility','on','Resize','on','DoubleBuffer','on', 'BackingStore','on','Visible','on',...
    'Units','char','Position',[figX figY figW figH],'UserData',[],...
    'DefaultAxesfontsize',13,'DefaultAxesFontName','Calibri','DefaultAxesfontweight','normal','color','w');

set(hMain,'color','w');
BKGCOL = get(hMain,'color');

setappdata(hMain,'CLN',Cln);
setappdata(hMain,'BLP',blp);
setappdata(hMain,'SPKT',Spkt);
setappdata(hMain,'NEVT',nevt);
setappdata(hMain,'SES',ses);
setappdata(hMain,'ExpNum',ExpNum);

% ================================= %
% Popupmenu: Waveform or TF profile %
% ================================= %
uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','normalized','Position',[0.032 0.948 0.055 0.019],...
    'String',{'Waveform','TF profile'},...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''redraw'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','left','Tag','popupmenu_WaveformTF',...
    'BackgroundColor',BKGCOL);

% ==================================== %
% Popupmenu: Time course or peri-event %
% ==================================== %
uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','normalized','Position',[0.126 0.948 0.055 0.019],...
    'String',{'Time course','Peri-event'},...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''popupmenu_time'',guidata(gcbo))',...    
    'ForegroundColor','k','HorizontalAlignment','left','Tag','popupmenu_Time',...
    'BackgroundColor',BKGCOL);

% =============================== %
% Text / Listbox: Choose channels %
% =============================== %
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','normalized','Position',[0.032 0.889 0.062 0.031],...
    'String','Choose channels',...
    'FontWeight','bold','FontSize',10,...
    'ForegroundColor','k','HorizontalAlignment','left','Tag','text7',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','normalized','Position',[0.032 0.67 0.08 0.216],...
    'String','Channels',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''listbox_channels'',guidata(gcbo))',...    
    'ForegroundColor','k','HorizontalAlignment','left','Tag','listbox_Channels',...
    'BackgroundColor',BKGCOL);

% ========================================== %
% Text / Listbox: Choose Cln or blp data set %
% ========================================== %
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','normalized','Position',[0.126 0.889 0.062 0.031],...
    'String','Choose Cln or blp data set',...
    'FontWeight','bold','FontSize',10,...
    'ForegroundColor','k','HorizontalAlignment','left','Tag','text8',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','normalized','Position',[0.126 0.67 0.08 0.216],...
    'String','Choose Cln or blp',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''redraw'',guidata(gcbo))',...    
    'ForegroundColor','k','HorizontalAlignment','left','Tag','listbox_Band',...
    'BackgroundColor',BKGCOL);

% ============================ %
% Listbox: Raw data or z-score %
% ============================ %
uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','normalized','Position',[0.031 0.598 0.08 0.043],...
    'String',{'Raw data','Z-score'},...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''redraw'',guidata(gcbo))',...        
    'ForegroundColor','k','HorizontalAlignment','left','Tag','listbox_RawdataZscore',...
    'BackgroundColor',BKGCOL);

% =========== %
% Panel: Time %
% =========== %
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','normalized','Position',[0.24 0.89 0.08 0.031],...
    'String','Choose time interval to depict',...
    'FontWeight','bold','FontSize',10,...
    'ForegroundColor','k','HorizontalAlignment','left','Tag','text9',...
    'BackgroundColor',BKGCOL);

panel_Time = uipanel('Parent',hMain,'Title','Time','FontSize',10,...
             'Units','normalized','Position',[0.217 0.79 0.156 0.1],...
             'BackgroundColor',BKGCOL);
         
uicontrol(...
    'Parent',panel_Time,'Style','Text',...
    'Units','normalized','Position',[0.049 0.767 0.211 0.163],...
    'String','t min [s]',...
    'ForegroundColor','k','HorizontalAlignment','left','Tag','text1',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Time,'Style','Text',...
    'Units','normalized','Position',[0.049 0.477 0.211 0.163],...
    'String','t win [s]',...
    'ForegroundColor','k','HorizontalAlignment','left','Tag','text2',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Time,'Style','Text',...
    'Units','normalized','Position',[0.049 0.186 0.211 0.163],...
    'String','t frame [s]',...
    'ForegroundColor','k','HorizontalAlignment','left','Tag','text3',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Time,'Style','Text',...
    'Units','normalized','Position',[0.53 0.163 0.445 0.174],...
    'String','(for peri-event mode)',...
    'ForegroundColor','k','HorizontalAlignment','left','Tag','text36',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Time,'Style','Edit',...
    'Units','normalized','Position',[0.316 0.709 0.206 0.256],...
    'String','0',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''edit_tmin'',guidata(gcbo))',... 
    'ForegroundColor','k','HorizontalAlignment','center','Tag','edit_Tmin',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Time,'Style','Edit',...
    'Units','normalized','Position',[0.316 0.419 0.206 0.256],...
    'String','2',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''edit_tmin'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','edit_Twin',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Time,'Style','Edit',...
    'Units','normalized','Position',[0.316 0.128 0.206 0.256],...
    'String','0.1',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''edit_tframe'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','edit_Tframe',...
    'BackgroundColor',BKGCOL);

% ============== %
% Panel: Filters %
% ============== %

panel_Filters = uipanel('Parent',hMain,'Title','Filters','FontSize',10,...
             'Units','normalized','Position',[0.217 0.667 0.156 0.105],...
             'BackgroundColor',BKGCOL);
         
uicontrol(...
    'Parent',panel_Filters,'Style','Checkbox',...
    'Units','normalized','Position',[0.036 0.67 0.304 0.253],...
    'String','Highpass',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''highpass'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','checkbox_Highpass',...
    'BackgroundColor',BKGCOL);
         
uicontrol(...
    'Parent',panel_Filters,'Style','Checkbox',...
    'Units','normalized','Position',[0.036 0.396 0.304 0.253],...
    'String','Lowpass',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''lowpass'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','checkbox_Lowpass',...
    'BackgroundColor',BKGCOL);
         
uicontrol(...
    'Parent',panel_Filters,'Style','Checkbox',...
    'Units','normalized','Position',[0.036 0.132 0.304 0.253],...
    'String','Bandpass',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''bandpass'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','checkbox_Bandpass',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Filters,'Style','Text',...
    'Units','normalized','Position',[0.571 0.165 0.065 0.209],...
    'String','-',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','text14',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Filters,'Style','Text',...
    'Units','normalized','Position',[0.862 0.747 0.097 0.154],...
    'String','[Hz]',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','text12',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Filters,'Style','Text',...
    'Units','normalized','Position',[0.862 0.473 0.097 0.154],...
    'String','[Hz]',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','text11',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Filters,'Style','Text',...
    'Units','normalized','Position',[0.862 0.198 0.097 0.154],...
    'String','[Hz]',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','text13',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Filters,'Style','Edit',...
    'Units','normalized','Position',[0.36 0.681 0.206 0.242],...
    'String','1',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''highpass'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','edit_Highpass',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Filters,'Style','Edit',...
    'Units','normalized','Position',[0.36 0.407 0.206 0.242],...
    'String','10',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''lowpass'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','edit_Lowpass',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Filters,'Style','Edit',...
    'Units','normalized','Position',[0.36 0.132 0.206 0.242],...
    'String','5',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''bandpass'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','edit_BandpassMin',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Filters,'Style','Edit',...
    'Units','normalized','Position',[0.644 0.132 0.206 0.242],...
    'String','20',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''bandpass'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','edit_BandpassMax',...
    'BackgroundColor',BKGCOL);

% =========================== %
% Panel: Show event positions %
% =========================== %
panel_Events = uipanel('Parent',hMain,'Title','Show event positions','FontSize',10,...
             'Units','normalized','Position',[0.124 0.454 0.25 0.194],...
             'BackgroundColor',BKGCOL);
         
uicontrol(...
    'Parent',panel_Events,'Style','Checkbox',...
    'Units','normalized','Position',[0.03 0.706 0.189 0.125],...
    'String','Event1','Value',1,...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''checkbox_event1'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','checkbox_Event1',...
    'BackgroundColor',BKGCOL,'ForegroundColor','r');

uicontrol(...
    'Parent',panel_Events,'Style','Checkbox',...
    'Units','normalized','Position',[0.03 0.584 0.189 0.125],...
    'String','Event2','Value',1,...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''checkbox_event2'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','checkbox_Event2',...
    'BackgroundColor',BKGCOL,'ForegroundColor','g','Visible','off');

uicontrol(...
    'Parent',panel_Events,'Style','Checkbox',...
    'Units','normalized','Position',[0.03 0.458 0.189 0.125],...
    'String','Event3','Value',1,...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''checkbox_event3'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','checkbox_Event3',...
    'BackgroundColor',BKGCOL,'ForegroundColor','c','Visible','off');

uicontrol(...
    'Parent',panel_Events,'Style','Checkbox',...
    'Units','normalized','Position',[0.03 0.332 0.189 0.125],...
    'String','Event4','Value',1,...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''checkbox_event4'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','checkbox_Event4',...
    'BackgroundColor',BKGCOL,'ForegroundColor','m','Visible','off');

uicontrol(...
    'Parent',panel_Events,'Style','Checkbox',...
    'Units','normalized','Position',[0.03 0.208 0.189 0.125],...
    'String','Event5','Value',1,...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''checkbox_event5'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','checkbox_Event5',...
    'BackgroundColor',BKGCOL,'ForegroundColor','y','Visible','off');

uicontrol(...
    'Parent',panel_Events,'Style','Checkbox',...
    'Units','normalized','Position',[0.03 0.081 0.189 0.125],...
    'String','Event6','Value',1,...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''checkbox_event6'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','checkbox_Event6',...
    'BackgroundColor',BKGCOL,'ForegroundColor','k','Visible','off');

uicontrol(...
    'Parent',panel_Events,'Style','Text',...
    'Units','normalized','Position',[0.29 0.869 0.174 0.077],...
    'String','Event no.',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','text32',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Events,'Style','Text',...
    'Units','normalized','Position',[0.463 0.869 0.242 0.077],...
    'String','Total event no.',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','text31',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Events,'Style','Text',...
    'Units','normalized','Position',[0.69 0.869 0.272 0.077],...
    'String','Overall event no.',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','text27',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Events,'Style','Text',...
    'Units','normalized','Position',[0.718 0.541 0.141 0.077],...
    'String','Brain area',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','text37',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Events,'Style','Text',...
    'Units','normalized','Position',[0.514 0.732 0.131 0.077],...
    'String','No.1',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','text_Event1',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Events,'Style','Text',...
    'Units','normalized','Position',[0.514 0.607 0.131 0.077],...
    'String','No.2',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','text_Event2',...
    'BackgroundColor',BKGCOL,'Visible','off');

uicontrol(...
    'Parent',panel_Events,'Style','Text',...
    'Units','normalized','Position',[0.514 0.481 0.131 0.077],...
    'String','No.3',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','text_Event3',...
    'BackgroundColor',BKGCOL,'Visible','off');

uicontrol(...
    'Parent',panel_Events,'Style','Text',...
    'Units','normalized','Position',[0.514 0.355 0.131 0.077],...
    'String','No.4',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','text_Event4',...
    'BackgroundColor',BKGCOL,'Visible','off');

uicontrol(...
    'Parent',panel_Events,'Style','Text',...
    'Units','normalized','Position',[0.514 0.224 0.131 0.077],...
    'String','No.5',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','text_Event5',...
    'BackgroundColor',BKGCOL,'Visible','off');

uicontrol(...
    'Parent',panel_Events,'Style','Text',...
    'Units','normalized','Position',[0.514 0.104 0.131 0.077],...
    'String','No.6',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','text_Event6',...
    'BackgroundColor',BKGCOL,'Visible','off');

uicontrol(...
    'Parent',panel_Events,'Style','Edit',...
    'Units','normalized','Position',[0.287 0.71 0.189 0.12],...
    'String','1',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''edit_event1'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','edit_Event1',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Events,'Style','Edit',...
    'Units','normalized','Position',[0.287 0.585 0.189 0.12],...
    'String','1',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''edit_event2'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','edit_Event2',...
    'BackgroundColor',BKGCOL,'Visible','off');

uicontrol(...
    'Parent',panel_Events,'Style','Edit',...
    'Units','normalized','Position',[0.287 0.459 0.189 0.12],...
    'String','1',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''edit_event3'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','edit_Event3',...
    'BackgroundColor',BKGCOL,'Visible','off');

uicontrol(...
    'Parent',panel_Events,'Style','Edit',...
    'Units','normalized','Position',[0.287 0.333 0.189 0.12],...
    'String','1',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''edit_event4'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','edit_Event4',...
    'BackgroundColor',BKGCOL,'Visible','off');

uicontrol(...
    'Parent',panel_Events,'Style','Edit',...
    'Units','normalized','Position',[0.287 0.208 0.189 0.12],...
    'String','1',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''edit_event5'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','edit_Event5',...
    'BackgroundColor',BKGCOL,'Visible','off');

uicontrol(...
    'Parent',panel_Events,'Style','Edit',...
    'Units','normalized','Position',[0.287 0.082 0.189 0.12],...
    'String','1',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''edit_event6'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','edit_Event6',...
    'BackgroundColor',BKGCOL,'Visible','off');

uicontrol(...
    'Parent',panel_Events,'Style','Edit',...
    'Units','normalized','Position',[0.725 0.71 0.189 0.12],...
    'String','1',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''edit_eventall'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','edit_EventAll',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Events,'Style','Listbox',...
    'Units','normalized','Position',[0.728 0.148 0.186 0.361],...
    'String','Brain area',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''redraw'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','left','Tag','listbox_BrainArea',...
    'BackgroundColor',BKGCOL);

% =================== %
% Panel: Average data %
% =================== %
panel_Average = uipanel('Parent',hMain,'Title','Average data','FontSize',10,...
             'Units','normalized','Position',[0.217 0.325 0.156 0.111],...
             'BackgroundColor',BKGCOL);
         
uicontrol(...
    'Parent',panel_Average,'Style','Pushbutton',...
    'Units','normalized','Position',[0.04 0.649 0.265 0.237],...
    'String','Events',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''average_events'',[])',...    
    'ForegroundColor','k','HorizontalAlignment','center','Tag','pushbutton_AverageEvents',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Average,'Style','Pushbutton',...
    'Units','normalized','Position',[0.04 0.381 0.265 0.237],...
    'String','Z-score',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''average_zscore'',[])',... 
    'ForegroundColor','k','HorizontalAlignment','center','Tag','pushbutton_Zscore',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Average,'Style','Pushbutton',...
    'Units','normalized','Position',[0.04 0.113 0.265 0.237],...
    'String','TF profile',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''average_tfprofile'',[])',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','pushbutton_TFprofile',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Average,'Style','Text',...
    'Units','normalized','Position',[0.506 0.68 0.211 0.144],...
    'String','t frame [s]',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','text34',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Average,'Style','Text',...
    'Units','normalized','Position',[0.486 0.423 0.231 0.144],...
    'String','t (data plot)',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','text28',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Average,'Style','Text',...
    'Units','normalized','Position',[0.506 0.165 0.211 0.144],...
    'String','t frame [s]',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','text35',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Average,'Style','Edit',...
    'Units','normalized','Position',[0.745 0.639 0.206 0.227],...
    'String','0.1',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','edit_AverageEvents',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Average,'Style','Edit',...
    'Units','normalized','Position',[0.745 0.124 0.206 0.227],...
    'String','1',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','edit_TFprofile',...
    'BackgroundColor',BKGCOL);

% ========================================= %
% Panel: PCA (principal component analysis) %
% ========================================= %
panel_PCA = uipanel('Parent',hMain,'Title','PCA','FontSize',10,...
             'Units','normalized','Position',[0.217 0.225 0.156 0.082],...
             'BackgroundColor',BKGCOL);
         
uicontrol(...
    'Parent',panel_PCA,'Style','Pushbutton',...
    'Units','normalized','Position',[0.04 0.537 0.385 0.328],...
    'String','Singular vectors',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''pca_vectors'',[])',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','pushbutton_SinVec',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_PCA,'Style','Pushbutton',...
    'Units','normalized','Position',[0.04 0.179 0.385 0.328],...
    'String','Singular values',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''pca_values'',[])',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','pushbutton_SinVal',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_PCA,'Style','Text',...
    'Units','normalized','Position',[0.506 0.627 0.211 0.209],...
    'String','t frame [s]',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','text29',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_PCA,'Style','Text',...
    'Units','normalized','Position',[0.482 0.239 0.231 0.209],...
    'String','No. of SV',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','text30',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_PCA,'Style','Edit',...
    'Units','normalized','Position',[0.745 0.537 0.206 0.328],...
    'String','1',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','edit_SVtframe',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_PCA,'Style','Edit',...
    'Units','normalized','Position',[0.745 0.179 0.206 0.328],...
    'String','5',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','edit_SVnum',...
    'BackgroundColor',BKGCOL);

% ============= %
% Panel: Spikes %
% ============= %
panel_Spikes = uipanel('Parent',hMain,'Title','Spikes','FontSize',10,...
             'Units','normalized','Position',[0.217 0.128 0.156 0.079],...
             'BackgroundColor',BKGCOL);
         
uicontrol(...
    'Parent',panel_Spikes,'Style','Checkbox',...
    'Units','normalized','Position',[0.045 0.547 0.377 0.359],...
    'String','Show spikes',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''show_spikes'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','checkbox_ShowSpikes',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',panel_Spikes,'Style','Pushbutton',...
    'Units','normalized','Position',[0.045 0.188 0.502 0.344],...
    'String','Show spike histogram',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''spike_hist'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','pushbutton_SpikeHist',...
    'BackgroundColor',BKGCOL);

% ============================ %
% Pushbutton: Reset everything %
% ============================ %
uicontrol(...
    'Parent',hMain,'Style','Pushbutton',...
    'Units','normalized','Position',[0.217 0.95 0.068 0.021],...
    'String','Reset everything!',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''init'',guidata(gcbo))',...
    'ForegroundColor','r','HorizontalAlignment','center','Tag','pushbutton_Reset',...
    'BackgroundColor',BKGCOL);

% ============================ %
% Pushbutton: Separate picture %
% ============================ %
uicontrol(...
    'Parent',hMain,'Style','Pushbutton',...
    'Units','normalized','Position',[0.313 0.088 0.06 0.021],...
    'String','Separate picture',...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''sep_pic'',[])',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','pushbutton_SepPic',...
    'BackgroundColor',BKGCOL);

% ============== %
% Slider: Events %
% ============== %
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','normalized','Position',[0.436 0.96 0.032 0.014],...
    'String','events',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','text20',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',hMain,'Style','Slider',...
    'Units','normalized','Position',[0.467 0.958 0.499 0.017],...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''event_slider'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','slider2',...
    'BackgroundColor',BKGCOL);

% ============ %
% Slider: Time %
% ============ %
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','normalized','Position',[0.434 0.013 0.032 0.014],...
    'String','time [s]',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','text10',...
    'BackgroundColor',BKGCOL);

uicontrol(...
    'Parent',hMain,'Style','Slider',...
    'Units','normalized','Position',[0.467 0.011 0.499 0.017],...
    'Callback','ClnBlpGui3(''Main_Callback'',gcbo,''time_slider'',guidata(gcbo))',...
    'ForegroundColor','k','HorizontalAlignment','center','Tag','slider1',...
    'BackgroundColor',BKGCOL);

% ======= %
% Picture %
% ======= %
axes(...
    'Parent',hMain,'Tag','axes1',...
    'Units','normalized','Position',[0.466 0.051 0.499 0.9],...
    'Box','on','color',BKGCOL,'Visible','on');   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%
% Initialization %
%%%%%%%%%%%%%%%%%%
% setappdata(hMain,'CLN',Cln);
% setappdata(hMain,'BLP',blp);
% setappdata(hMain,'SPKT',Spkt);
% setappdata(hMain,'NEVT',nevt);
% setappdata(hMain,'SES',ses);
% setappdata(hMain,'ExpNum',ExpNum);

Main_Callback(hMain,'init');
set(hMain,'visible','on');
if nargout,
  varargout{1} = hMain;
end;
return

% =========================================================================================================
function Main_Callback(hObject,eventdata,handles)
% =========================================================================================================

handles   = guihandles(hObject);
Cln    = getappdata(handles.main,'CLN');
blp    = getappdata(handles.main,'BLP');
nevt   = getappdata(handles.main,'NEVT');
ses    = getappdata(handles.main,'SES');
ExpNum = getappdata(handles.main,'ExpNum');

switch lower(eventdata),
    case {'init'}
        % Initialize channels
        %%%%%%%%%%%%%%%%%%%%%
        ChanNum=size(Cln.dat,2);    % determine number of channels

        ChanNumList(1:ChanNum)=(1:ChanNum); % assigns a Number to each channel

        % Assign channel names
        grp=getgrp(ses,ExpNum);                                     
        ChanNamesLength=length(grp.ele.site);

        for N=1:ChanNum
            if N<=ChanNamesLength
                ChanNumString{N}=sprintf('Ch%02d %s',N,grp.ele.site{N});
            else
                ChanNumString{N}=sprintf('Ch%02d %s',N,'unknown');
            end
        end

        set(handles.listbox_Channels,'String',ChanNumString,'Max',2,'Min',0)    % Give channel names to listbox
        
        setappdata(handles.main,'ChanNumList',ChanNumList);
        setappdata(handles.main,'ChanNumString',ChanNumString);

        % Initialize bands
        %%%%%%%%%%%%%%%%%%%%
        handles.BandNames{1}='Cln (raw)';
        for i=1:length(blp.info.band)
            handles.BandNames{i+1}=blp.info.band{1,i}{1,2};     % Find out all bands
        end

        set(handles.listbox_Band,'String',handles.BandNames)    % Give band names to listbox

        % Initialize event locations
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        list=[];
        f = fieldnames(nevt);
        i=0;
        for N=1:length(f) 
            if isstruct(nevt.(f{N})) && isfield(nevt.(f{N}),'onset');
                i=i+1;
                EventLoc{i}=sprintf('%s\n',f{N});
                x=cellstr(EventLoc{i});
                %initial_name=cellstr(get(handles.BrainArea,'String'));
                list = [list;x];
                set(handles.listbox_BrainArea,'String',list) 
                %set(handles.BrainArea,'String',EventLoc{i})
            end 
        end
        % set(handles.BrainArea,'String',EventLoc)

        % Initialize events
        %%%%%%%%%%%%%%%%%%%
        EL=get(handles.listbox_BrainArea,'String');
        EL_val=get(handles.listbox_BrainArea,'Value');
        curevt=EL{EL_val};

        if isfield(nevt.(curevt),'bpass')        % In older versions structire name can be .bpass
            nevt.(curevt).bname=nevt.(curevt).bpass;  % Rename ".bname"
        end

        % Load number and names of different events for checkboxes
        set(handles.checkbox_Event1,'String',nevt.(curevt).bname{1,1})
        NevtNamesLength=length(nevt.(curevt).bname);
        for i=2:NevtNamesLength
            set(eval(['handles.checkbox_Event' num2str(i)]) ,'String',nevt.(curevt).bname{1,i},'Visible','on')
            set(eval(['handles.edit_Event' num2str(i)]),'Visible','on') % Make checkbox & edit field visible if event exists
        end

        % Initialize time slider
        %%%%%%%%%%%%%%%%%%%%%%%%
        SliderStepMin=(str2num(get(handles.edit_Twin,'String')))/(length(Cln.dat(:,1))*Cln.dx);
        set(handles.slider1,'Min',0,'Max',length(Cln.dat(:,1))*Cln.dx,'SliderStep',[SliderStepMin SliderStepMin])


        % Initialize event slider
        %%%%%%%%%%%%%%%%%%%%%%%%%
        set(handles.slider2,'Min',0,'Max',length(nevt.(curevt).onset),'SliderStep',[1/length(nevt.(curevt).onset) 1/length(nevt.(curevt).onset)])

        % Initialize data set and plot
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        InitPlotData(hObject,eventdata,handles)
        RedrawAll(hObject,eventdata,handles)

    case {'redraw'}
        InitPlotData(hObject,handles)
        RedrawAll(hObject,handles) 
        
    case {'popupmenu_time'}
        % Set start time =0 if other time format is chosen
        xlimmin=0; 
        set(handles.edit_Tmin,'String',xlimmin)

        set(handles.slider1,'Value',xlimmin);
        set(handles.slider2,'Value',0)

        InitPlotData(hObject,handles)   % Recalculate/reload PlotData
        RedrawAll(hObject,handles)      % Plot data
        
    case {'listbox_channels'}
        ChanNumList = get(handles.listbox_Channels, 'Value');   % Get numbers of selected channels
        ChanNumString1 = get(handles.listbox_Channels, 'String');       % Load all channel names

        j=1;
        for i=ChanNumList
            ChanNumString{j} = ChanNumString1{i};   % Create list of channel names of selected channels
            j=j+1;
        end
        setappdata(handles.main,'ChanNumList',ChanNumList);
        setappdata(handles.main,'ChanNumString',ChanNumString);
                
        InitPlotData(hObject,handles)   % Recalculate/reload PlotData
        RedrawAll(hObject,handles)      % Plot data
        
    case {'edit_tmin'}
        PlotData = getappdata(handles.main,'PlotData');    % Load PlotData
        EventData = getappdata(handles.main,'EventData');  % Load EventData

        xlimmin=str2num(get(handles.edit_Tmin,'String'));   % Get new "t min" from input field
        xlimdiff=str2num(get(handles.edit_Twin,'String'));  % Get "t win" from input field

        % Avoid errors if tmin<0
        if xlimmin<0
            xlimmin=0;
        end

        % Update time slider
        SliderStepMin=xlimdiff/(size(PlotData.dat,1)*PlotData.dx);
        set(handles.slider1,'Min',0,'Max',size(PlotData.dat,1)*PlotData.dx,'SliderStep',[SliderStepMin SliderStepMin])
        set(handles.slider1,'Value',xlimmin);

        % Update event slider
        t_now=xlimmin+0.5*xlimdiff;                     % Current time is set to middle of plot area
        [i_evt,i_evt]=min(abs(EventData.times-t_now));  % Estimate nearest event
        set(handles.slider2,'Value',i_evt)              % Set event slider to nearest event number

        RedrawAll(hObject,handles)      % Plot data
        
    case {'edit_tframe'}
        % If peri-event mode: update plot, else: do nothing
        if get(handles.popupmenu_Time,'Value')==2
            InitPlotData(hObject,handles)   % Generate new data set using new tframe
            RedrawAll(hObject,handles)      % Plot data
        end
        
    case {'highpass'}
        if get(handles.checkbox_Highpass,'Value')==1    % If highpass filter activated...
            set(handles.checkbox_Lowpass,'Value',0)     % Deactivate other filters
            set(handles.checkbox_Bandpass,'Value',0)
            InitPlotData(hObject,handles)                       % Recalculate PlotData
            RedrawAll(hObject,handles)                          % Plot data
        else
            InitPlotData(hObject,handles)                       % If checkbox deactivated load unfiltered data
            RedrawAll(hObject,handles)                          % Plot data
        end
        
    case {'lowpass'}
        if get(handles.checkbox_Lowpass,'Value')==1    % If highpass filter activated...
            set(handles.checkbox_Highpass,'Value',0)     % Deactivate other filters
            set(handles.checkbox_Bandpass,'Value',0)
            InitPlotData(hObject,handles)                       % Recalculate PlotData
            RedrawAll(hObject,handles)                          % Plot data
        else
            InitPlotData(hObject,handles)                       % If checkbox deactivated load unfiltered data
            RedrawAll(hObject,handles)                          % Plot data
        end
        
    case {'bandpass'}
        if get(handles.checkbox_Bandpass,'Value')==1    % If highpass filter activated...
            set(handles.checkbox_Lowpass,'Value',0)     % Deactivate other filters
            set(handles.checkbox_Highpass,'Value',0)
            InitPlotData(hObject,handles)                       % Recalculate PlotData
            RedrawAll(hObject,handles)                          % Plot data
        else
            InitPlotData(hObject,handles)                       % If checkbox deactivated load unfiltered data
            RedrawAll(hObject,handles)                          % Plot data
        end
        
    case {'checkbox_event1'}
        if get(handles.popupmenu_Time,'Value')==1
            CallbackEvent1(handles) % Show/hide event lines
            InitPlotData(hObject,handles);  % Necessary to update event slider (list of active events)
        else
            InitPlotData(hObject,handles)   % Generate new data set with active events
            RedrawAll(hObject,handles)      % Plot data
        end
        
    case {'checkbox_event2'}
        if get(handles.popupmenu_Time,'Value')==1
            CallbackEvent2(handles) % Show/hide event lines
            InitPlotData(hObject,handles);  % Necessary to update event slider (list of active events)
        else
            InitPlotData(hObject,handles)   % Generate new data set with active events
            RedrawAll(hObject,handles)      % Plot data
        end
        
    case {'checkbox_event3'}
        if get(handles.popupmenu_Time,'Value')==1
            CallbackEvent3(handles) % Show/hide event lines
            InitPlotData(hObject,handles);  % Necessary to update event slider (list of active events)
        else
            InitPlotData(hObject,handles)   % Generate new data set with active events
            RedrawAll(hObject,handles)      % Plot data
        end
        
    case {'checkbox_event4'}
        if get(handles.popupmenu_Time,'Value')==1
            CallbackEvent4(handles) % Show/hide event lines
            InitPlotData(hObject,handles);  % Necessary to update event slider (list of active events)
        else
            InitPlotData(hObject,handles)   % Generate new data set with active events
            RedrawAll(hObject,handles)      % Plot data
        end
        
    case {'checkbox_event5'}
        if get(handles.popupmenu_Time,'Value')==1
            CallbackEvent5(handles) % Show/hide event lines
            InitPlotData(hObject,handles);  % Necessary to update event slider (list of active events)
        else
            InitPlotData(hObject,handles)   % Generate new data set with active events
            RedrawAll(hObject,handles)      % Plot data
        end
        
    case {'checkbox_event6'}
        if get(handles.popupmenu_Time,'Value')==1
            CallbackEvent6(handles) % Show/hide event lines
            InitPlotData(hObject,handles);  % Necessary to update event slider (list of active events)
        else
            InitPlotData(hObject,handles)   % Generate new data set with active events
            RedrawAll(hObject,handles)      % Plot data
        end
        
    case {'edit_event1'}
        EventData = getappdata(handles.main,'EventData');  % Load EventData
        i_evt=str2num(get(handles.edit_Event1,'String'));   % Get event number from input field

        NevtList=EventList(handles);    % Get list of active events

        % Count in active events until i_evt is reached
        j=0;
        k=0;
        for i=1:length(EventData.types);
            if EventData.types(i)==1
                j=j+1;
            end
            if j==i_evt
                break
            end
            if any(EventData.types(i) == NevtList)  % Determine overall event number
                k=k+1;
            end
        end
        i_evt=i;
        i_evt_selection=k+1;

        if get(handles.popupmenu_Time,'Value')==1
            % If time course mode: event is arranged in the middle of the plot area
            set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Twin,'String')))
        else
            % If peri-event mode: event is arranged at the beginning of the plot area (at tframe/2)
            set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Tframe,'String')))
        end

        set(handles.edit_EventAll,'String',i_evt_selection) % Set overall event number

        set(handles.slider1,'Value',str2num(get(handles.edit_Tmin,'String')));  % Update time slider
        set(handles.slider2,'Value',i_evt_selection)                            % Update event slider

        RedrawAll(hObject,handles)      % Plot data

    case {'edit_event2'}
        EventData = getappdata(handles.main,'EventData');  % Load EventData
        i_evt=str2num(get(handles.edit_Event2,'String'));   % Get event number from input field

        NevtList=EventList(handles);    % Get list of active events

        % Count in active events until i_evt is reached
        j=0;
        k=0;
        for i=1:length(EventData.types);
            if EventData.types(i)==2
                j=j+1;
            end
            if j==i_evt
                break
            end
            if any(EventData.types(i) == NevtList)  % Determine overall event number
                k=k+1;
            end
        end
        i_evt=i;
        i_evt_selection=k+1;

        if get(handles.popupmenu_Time,'Value')==1
            % If time course mode: event is arranged in the middle of the plot area
            set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Twin,'String')))
        else
            % If peri-event mode: event is arranged at the beginning of the plot area (at tframe/2)
            set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Tframe,'String')))
        end

        set(handles.edit_EventAll,'String',i_evt_selection) % Set overall event number

        set(handles.slider1,'Value',str2num(get(handles.edit_Tmin,'String')));  % Update time slider
        set(handles.slider2,'Value',i_evt_selection)                            % Update event slider

        RedrawAll(hObject,handles)      % Plot data
        
    case {'edit_event3'}
        EventData = getappdata(handles.main,'EventData');  % Load EventData
        i_evt=str2num(get(handles.edit_Event3,'String'));   % Get event number from input field

        NevtList=EventList(handles);    % Get list of active events

        % Count in active events until i_evt is reached
        j=0;
        k=0;
        for i=1:length(EventData.types);
            if EventData.types(i)==3
                j=j+1;
            end
            if j==i_evt
                break
            end
            if any(EventData.types(i) == NevtList)  % Determine overall event number
                k=k+1;
            end
        end
        i_evt=i;
        i_evt_selection=k+1;

        if get(handles.popupmenu_Time,'Value')==1
            % If time course mode: event is arranged in the middle of the plot area
            set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Twin,'String')))
        else
            % If peri-event mode: event is arranged at the beginning of the plot area (at tframe/2)
            set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Tframe,'String')))
        end

        set(handles.edit_EventAll,'String',i_evt_selection) % Set overall event number

        set(handles.slider1,'Value',str2num(get(handles.edit_Tmin,'String')));  % Update time slider
        set(handles.slider2,'Value',i_evt_selection)                            % Update event slider

        RedrawAll(hObject,handles)      % Plot data
        
    case {'edit_event4'}
        EventData = getappdata(handles.main,'EventData');  % Load EventData
        i_evt=str2num(get(handles.edit_Event4,'String'));   % Get event number from input field

        NevtList=EventList(handles);    % Get list of active events

        % Count in active events until i_evt is reached
        j=0;
        k=0;
        for i=1:length(EventData.types);
            if EventData.types(i)==4
                j=j+1;
            end
            if j==i_evt
                break
            end
            if any(EventData.types(i) == NevtList)  % Determine overall event number
                k=k+1;
            end
        end
        i_evt=i;
        i_evt_selection=k+1;

        if get(handles.popupmenu_Time,'Value')==1
            % If time course mode: event is arranged in the middle of the plot area
            set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Twin,'String')))
        else
            % If peri-event mode: event is arranged at the beginning of the plot area (at tframe/2)
            set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Tframe,'String')))
        end

        set(handles.edit_EventAll,'String',i_evt_selection) % Set overall event number

        set(handles.slider1,'Value',str2num(get(handles.edit_Tmin,'String')));  % Update time slider
        set(handles.slider2,'Value',i_evt_selection)                            % Update event slider

        RedrawAll(hObject,handles)      % Plot data
        
    case {'edit_event5'}
        EventData = getappdata(handles.main,'EventData');  % Load EventData
        i_evt=str2num(get(handles.edit_Event5,'String'));   % Get event number from input field

        NevtList=EventList(handles);    % Get list of active events

        % Count in active events until i_evt is reached
        j=0;
        k=0;
        for i=1:length(EventData.types);
            if EventData.types(i)==5
                j=j+1;
            end
            if j==i_evt
                break
            end
            if any(EventData.types(i) == NevtList)  % Determine overall event number
                k=k+1;
            end
        end
        i_evt=i;
        i_evt_selection=k+1;

        if get(handles.popupmenu_Time,'Value')==1
            % If time course mode: event is arranged in the middle of the plot area
            set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Twin,'String')))
        else
            % If peri-event mode: event is arranged at the beginning of the plot area (at tframe/2)
            set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Tframe,'String')))
        end

        set(handles.edit_EventAll,'String',i_evt_selection) % Set overall event number

        set(handles.slider1,'Value',str2num(get(handles.edit_Tmin,'String')));  % Update time slider
        set(handles.slider2,'Value',i_evt_selection)                            % Update event slider

        RedrawAll(hObject,handles)      % Plot data
        
    case {'edit_event6'}
        EventData = getappdata(handles.main,'EventData');  % Load EventData
        i_evt=str2num(get(handles.edit_Event6,'String'));   % Get event number from input field

        NevtList=EventList(handles);    % Get list of active events

        % Count in active events until i_evt is reached
        j=0;
        k=0;
        for i=1:length(EventData.types);
            if EventData.types(i)==6
                j=j+1;
            end
            if j==i_evt
                break
            end
            if any(EventData.types(i) == NevtList)  % Determine overall event number
                k=k+1;
            end
        end
        i_evt=i;
        i_evt_selection=k+1;

        if get(handles.popupmenu_Time,'Value')==1
            % If time course mode: event is arranged in the middle of the plot area
            set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Twin,'String')))
        else
            % If peri-event mode: event is arranged at the beginning of the plot area (at tframe/2)
            set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Tframe,'String')))
        end

        set(handles.edit_EventAll,'String',i_evt_selection) % Set overall event number

        set(handles.slider1,'Value',str2num(get(handles.edit_Tmin,'String')));  % Update time slider
        set(handles.slider2,'Value',i_evt_selection)                            % Update event slider

        RedrawAll(hObject,handles)      % Plot data
        
    case{'edit_eventall'}
        EventData = getappdata(handles.main,'EventData');  % Load EventData
        i_evt=str2num(get(handles.edit_EventAll,'String')); % Get event number from input field

        NevtList=EventList(handles);    % Get List of active events

        % Count in active events until i_evt is reached
        j=0;
        for i=1:length(EventData.types);
            if any(EventData.types(i) == NevtList)
                j=j+1;
            end
            if j==i_evt
                break
            end
        end
        i_evt=i; 

        if get(handles.popupmenu_Time,'Value')==1
            % If time course mode: event is arranged in the middle of the plot area
            set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Twin,'String')))
        else
            % If peri-event mode: event is arranged at the beginning of the plot area (at tframe/2)
            set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Tframe,'String')))
        end

        set(handles.slider1,'Value',str2num(get(handles.edit_Tmin,'String')));  % Update time slider
        set(handles.slider2,'Value',i_evt)                                      % Update event slider

        RedrawAll(hObject,handles)      % Plot data
        
    case {'average_events'}
        AverageEvents(handles)
        
    case {'average_zscore'}
        AverageZscore(handles)
        
    case {'average_tfprofile'}
        AverageTFprofile(handles)  
        
    case {'pca_values'}
        plotpcavalues(handles)
        
    case {'pca_vectors'}
        plotpcavectors(handles)
        
    case {'show_spikes'}
        CallbackSpikes(handles)
        
    case {'spike_hist'}
        SpikeHistogram(handles)
               
    case {'sep_pic'}
        SeparatePicture(handles)
        
    case {'time_slider'}
        TimeSlider(handles)
        RedrawAll(hObject,handles)      % Plot data
        
    case {'event_slider'}
        EventSlider(handles)
        RedrawAll(hObject,handles)      % Plot data
end

guidata(hObject,handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function InitPlotData(hObject,eventdata,handles)

%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize plot data %
%%%%%%%%%%%%%%%%%%%%%%%%

% This function is called each time when channel/ z-score etc. is changed

% Load experiment data
handles   = guihandles(hObject);
Cln = getappdata(handles.main,'CLN');
blp = getappdata(handles.main,'BLP');

PlotData=[];    % Reset PlotData

% Load selected Cln- or blp-data
val = get(handles.listbox_Band, 'Value');   
switch (val)
    case 1
    PlotData=Cln;
    otherwise
    PlotData=blp;
    PlotData.dat=PlotData.dat(:,:,val-1);
end

% Filters if needed
if get(handles.checkbox_Highpass,'Value')==1
    PlotData=sigfiltfilt(PlotData,[str2num(get(handles.edit_Highpass,'String'))],'highpass');
elseif get(handles.checkbox_Lowpass,'Value')==1
    PlotData=sigfiltfilt(PlotData,[str2num(get(handles.edit_Lowpass,'String'))],'lowpass');
elseif get(handles.checkbox_Bandpass,'Value')==1
    PlotData=sigfiltfilt(PlotData,[str2num(get(handles.edit_BandpassMin,'String')) str2num(get(handles.edit_BandpassMax,'String'))],'bandpass');
end
    

% Calculate z-score if needed
if get(handles.listbox_RawdataZscore,'Value')==2     % Z-score
    %PlotData = sigfiltfilt(PlotData,[80 150],'bandpass');
    PlotData.dat=zscore(PlotData.dat,[],1);
end

EventData = InitEventData(handles);     % Load/calculate event data
%SpikeData = InitSpikeData(handles);

if get(handles.popupmenu_Time,'Value')==2           % If peri-event,
    SpikeData=getappdata(handles.main,'SPKT');     % Load spike data
    [PlotData,EventData,SpikeData] = InitPeriEventData(handles,PlotData,EventData,SpikeData);   % Calculate peri-event data
    setappdata(handles.main,'SpikeData',SpikeData) % Set new spike data (new times, adapted to equidistant events)
end

% Store plot/event data
setappdata(handles.main,'PlotData',PlotData)
setappdata(handles.main,'EventData',EventData)
%setappdata(handles.main,'SpikeData',SpikeData)

guidata(hObject, handles);


function EventData = InitEventData(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize event data %
%%%%%%%%%%%%%%%%%%%%%%%%%

% Is called when event-checkboxes are used
% Sets vectors .names, .types, .times corresponting to selected events (checkboxes)

nevt = getappdata(handles.main,'NEVT');    % Load event data

EL=get(handles.listbox_BrainArea,'String');
EL_val=get(handles.listbox_BrainArea,'Value');
curevt=EL{EL_val};                          % Part of nevt structure

EventData=[];                               % Reset event data

NevtList=EventList(handles);                % List of activated events (checkboxes)

if isfield(nevt.(curevt),'bpass')           % In older version of preprocessing field is named .bpass
    EventData.names=nevt.(curevt).bpass;
else
   EventData.names=nevt.(curevt).bname;     % In newer version of preprocessing field is named .bname
end
EventData.types=nevt.(curevt).split;        % isplit ??
EventData.times=nevt.(curevt).onset;        % ionset ??

for i=1:6                                   % Maximum number of predefined event types
    if length(EventData.names) >= i         % If number of event types >= i ...
        EventNumber(i) = length(find(EventData.types == i));    % Determine number of events of the current type
        set(eval(['handles.text_Event' num2str(i)]),'String',EventNumber(i),'Visible','on') % Write this number to corresponding input field
    end
end

% If current event type does not belong to selected events: delete is from EventData
% => EventData is restricted to selected event types
for iEvt = 1:length(EventData.names),
    if any(NevtList == iEvt),  continue;  end
    EventData.names{iEvt} = [];
    tmpsel = (EventData.types == iEvt);
    EventData.types(tmpsel) = [];
    EventData.times(tmpsel) = [];
end

return

function NevtList=EventList(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% List of selected event types %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% List contains corresponding number from nevt.***.split / EventData.types
NevtList=[];                                % Reset list
if get(handles.checkbox_Event1,'Value')==1  % If checkbox for event 1 activated...
        NevtList=[NevtList,1];              % Add 1 to list
end
if get(handles.checkbox_Event2,'Value')==1  % If checkbox for event 2 activated...
        NevtList=[NevtList,2];              % Add 2 to list
end
if get(handles.checkbox_Event3,'Value')==1  % If checkbox for event 3 activated...
        NevtList=[NevtList,3];              % Add 3 to list
end
if get(handles.checkbox_Event4,'Value')==1  % If checkbox for event 4 activated...
        NevtList=[NevtList,4];              % Add 4 to list
end
if get(handles.checkbox_Event5,'Value')==1  % If checkbox for event 5 activated...
        NevtList=[NevtList,5];              % Add 5 to list
end
if get(handles.checkbox_Event6,'Value')==1  % If checkbox for event 6 activated...
        NevtList=[NevtList,6];              % Add 6 to list
end

return

function [PeriData,PeriEvent,SpikeData] = InitPeriEventData(handles, PlotData, EventData, Spkt)

%%%%%%%%%%%%%%%%%%%
% Peri-Event data %
%%%%%%%%%%%%%%%%%%%

ChanNumList=getappdata(handles.main,'ChanNumList');

% Calculate convenient tframe
tframe=str2num(get(handles.edit_Tframe,'String'));  % Get tframe from input field
iframe=ceil(tframe/PlotData.dx);                    % Calculate index of .dat correspondint to time tframe
if rem(iframe,2)                                    % If iframe odd...
    iframe=iframe+1;                                % Make it even, because event line is plotted at index iframe/2
end
tframe=iframe*PlotData.dx;                          % Calculate adjusted tframe
set(handles.edit_Tframe,'String',tframe);           % Write new tframe in input field

LengthEventData=length(EventData.types);            % Length of EventData.types / Eventdata.times vector

PeriEvent = EventData;                              % Update EventData for peri-event case

% Calculate spike data for peri-event mode
j=0;
for i=ChanNumList       % Numbers of selected channels
    j=j+1;
    tmpspk=Spkt.times{i,1};     % Spkt.times containes indices when spikes occur
    tmpspk=tmpspk*Spkt.dt;      % determine real times when spikes occur

    PeriSpikeData=[];           % Reset PeriSpikeData
    for k=1:LengthEventData
        y=transpose(tmpspk);    % To make vector orientations match
        % Extract time frame in spike data where event is laying in the middle
        x=y(y >= EventData.times(k)-0.5*tframe & y <= EventData.times(k)+0.5*tframe);
        % Add time frame to peri-event data
        PeriSpikeData=[PeriSpikeData x+((k-0.5)*tframe-EventData.times(k))];
        % To avoid errors; probably not necessary
        PeriSpikeData=PeriSpikeData(PeriSpikeData>0);
    end

tmpspk=transpose(PeriSpikeData);
eval(sprintf('SpikeData%d=tmpspk;',i)); % SpikeDatax=PeriSpikeData (time frames strung together)
SpikeDataLength(j)=length(tmpspk);      % Length of SpikeDatax vectors
end

MaxSpikeDataLength=max(SpikeDataLength);% Length of largest SpikeDatax vector
SpikeData=zeros(MaxSpikeDataLength,j);  % Initialize matrix to combine SpikeDatax vectors
                                        % Therefore MaxSpikeDataLength necessary, because all SpikeDatax
                                        % vectors have different lengths
j=0;
for i=ChanNumList
    j=j+1;
    % Fill rows of the matrix with SpikeDatax vectors; unfilled parts are 0
    SpikeData(1:SpikeDataLength(j),j)=eval(['SpikeData' num2str(i)]);
end

PeriEvent.times = (1:LengthEventData)*tframe - 0.5*tframe;  % Calculate new equidistant EventData.times

% Calculate PlotData.dat for peri-event case
% Determine index in PlotData.dat, when event takes place
ievt=ceil(EventData.times/PlotData.dx);


% EvtLine as (time,event,chan)
EvtLine=zeros(iframe,LengthEventData,length(ChanNumList)); % Initialize new event data set

tmpwin = -0.5*iframe+1:0.5*iframe;
for i=ChanNumList
    for j=1:LengthEventData-1
        % Time frame of events strung together in EvtLine
        EvtLine(:,j,i) = PlotData.dat(tmpwin + ievt(j),i);
    end
end
% EvtLine as (time*event,chan)
tmpsz = size(EvtLine);
EvtLine = reshape(EvtLine,[tmpsz(1)*tmpsz(2)  tmpsz(3)]);

PeriData = PlotData;
PeriData.dat=EvtLine;   % Copy calculated peri-event data
PeriData.NumSamplesPerEvent = length(tmpwin);

set(handles.slider1,'Max',size(PeriData.dat,1)*PeriData.dx) % Update time slider
set(handles.slider2,'Max',length(PeriEvent.types))          % Update event slider

return


function PlotWvData(handles)

%%%%%%%%%%%%%%%%%%%%%%
% Plot waveform data %
%%%%%%%%%%%%%%%%%%%%%%

PlotData=getappdata(handles.main,'PlotData');      % Load PlotData
if isempty(PlotData), return; end                   % If PlotData not available do nothing

ChanNumList=getappdata(handles.main,'ChanNumList');
ChanNumString=getappdata(handles.main,'ChanNumString');

delete(findobj(handles.axes1,'Tag','PlotData'));    % Delete existing plot

tmin=str2num(get(handles.edit_Tmin,'String'));      % Load tmin from input field 
tmax=tmin+str2num(get(handles.edit_Twin,'String')); % Tmax=tmin+twin (twin from input field)

TimeScale=(1:size(PlotData.dat,1))*PlotData.dx;     % Calculate time scale for picture
tpsel=(TimeScale >= tmin & TimeScale <=tmax);       % Define time scale in visible range

offset=(0:2:2*length(ChanNumList)-2);       % Define offset in y-direction for data sets of different channels

for i=ChanNumList
    if get(handles.listbox_Band, 'Value')<3         % If Cln data
        % Normalize amplitude of data
        PlotData.dat(:,i)=PlotData.dat(:,i)./max(PlotData.dat(:,i));
    else
        % Normalize amplitude of data 
        % Maximum amplitude can be 2x larger than of Cln data, because values are not negative
        PlotData.dat(:,i)=PlotData.dat(:,i)./max(PlotData.dat(:,i)).*2;
    end
end

% Plot data for selected channels
for iCH=1:length(ChanNumList)
    plot(TimeScale(tpsel),PlotData.dat(tpsel,ChanNumList(iCH))+offset(iCH),'Parent',handles.axes1,'Tag','PlotData')
    hold on
end

% Define visible range and labels
set(handles.axes1,'XLim',[tmin tmax],'xTick',tmin:(tmax-tmin)/10:tmax,'xTickLabel',tmin:(tmax-tmin)/10:tmax,'YLim',[-2 2*length(ChanNumList)],'YTick',[0:2:2*length(ChanNumList)-2],'YTickLabel',ChanNumString,'YGrid','on')
% Update time slider maximum
set(handles.slider1,'Max',size(PlotData.dat,1)*PlotData.dx)

% work around to fix resetting 'tag'
set(handles.axes1,'tag','axes1');

return


function PlotTfData(handles)

%%%%%%%%%%%%%%%%
% Plot TF data %
%%%%%%%%%%%%%%%%

% Displays time-frequency profiles

PlotData=getappdata(handles.main,'PlotData');      % Load PlotData
if isempty(PlotData), return; end                   % If PlotData not available do nothing

ChanNumList=getappdata(handles.main,'ChanNumList');

delete(findobj(handles.axes1,'Tag','PlotData'));    % Delete existing plot

tmin=str2num(get(handles.edit_Tmin,'String'));      % Load tmin from input field 
tmax=tmin+str2num(get(handles.edit_Twin,'String')); % Tmax=tmin+twin (twin from input field)

imin=ceil(tmin/PlotData.dx);                        % Calculate index of .dat referring to tmin
imax=floor(tmax/PlotData.dx);                       % Calculate index of .dat referring to tmax

if tmin==0
    imin=imin+1;                                    % Index must be positive integer
end

winsize = round(1/PlotData.dx);

% if isfield(PlotData,'NumSamplesPerEvent') && any(PlotData.NumSamplesPerEvent)
%   % peri-event data
%   nt     = PlotData.NumSamplesPerEvent;
%   tmpdat = reshape(PlotData.dat,[nt size(PlotData.dat,1)/nt  size(PlotData.dat,2)]);
  
%   minframe = floor(imin/nt) + 1;  % +1 for matlab indexing
%   maxframe = ceil(imax/nt);
%   tmpdat   = tmpdat(:,minframe:maxframe,:);
%   PlotData.dat = tmpdat;
%   imin2     = imin - nt*(minframe-1);
%   imax2     = imin2 + (imax-imin);

%   PlotData = sigtimefreq(PlotData);
%   tmpsz = size(PlotData.dat);
%   PlotData.dat = reshape(PlotData.dat,[tmpsz(1)*tmpsz(2) tmpsz(3:end)]);
  
%   PlotData.dat = PlotData.dat(imin2:imax2,:,:);
% else
  PlotData.dat=PlotData.dat(imin:imax,:);             % Reduce PlotData to visible range
  PlotData=sigtimefreq(PlotData,'winsize',winsize);                     % Calculate time-frequency profile
% end
  
  
PlotData.dat=abs(PlotData.dat);                     % Calculate absolute values of results

if get(handles.listbox_RawdataZscore,'Value')==2     % Z-score
  PlotData.dat=zscore(PlotData.dat,[],1);
end


TFPlotData = PlotData.dat(:,:,ChanNumList);
%TFPlotData(:,:,2) = 0;  % for debug..
TFPlotData = reshape(TFPlotData,[size(TFPlotData,1) size(TFPlotData,2)*size(TFPlotData,3)]);
TFPlotData = TFPlotData';

% Determine minimum and maximum frequency as limits for picture
% => colors of single TF profiles are normalized
minFreq=min(PlotData.freqs);                        
maxFreq=max(PlotData.freqs);                        
if get(handles.listbox_RawdataZscore,'Value')==2     % Z-score
  % make as symmetric 
  MaxAmp=max(abs(TFPlotData(:)));
  MinAmp=-MaxAmp;
else
  MinAmp=min(TFPlotData(:));
  MaxAmp=max(TFPlotData(:));
end

% TimeScale = (1:imax-imin+1)*PlotData.dx+imin*PlotData.dx;
% FreqScale(1:(j-1)*TFsizey)=(1:(j-1)*TFsizey);


% Plot TF profiles (including labeling)
imagesc(TFPlotData,'Parent',handles.axes1,'Tag','PlotData')         % Display image for TFPlotData
set(handles.axes1,'layer','top');
set(handles.axes1,'ydir','normal');
set(handles.axes1,'clim',[MinAmp MaxAmp])                           % Colors are in range [min(freq), max(freq)]
set(handles.axes1,'XLim',[1 imax-imin+1],'YLim',[0.5 size(TFPlotData,1)+0.5])
set(handles.axes1,'XTick',1:(imax-imin+1)/10:imax-imin+1)
set(handles.axes1,'xTickLabel',tmin:(tmax-tmin)/10:tmax)
ytick0 = (0:25:maxFreq-1);
yticklabel0 = {};
for N = 1:length(ytick0)
  yticklabel0{N} = sprintf('%g',ytick0(N));
end
ytick0 = ytick0/maxFreq*length(PlotData.freqs);
ytick  = [];
yticklabel = {};
for N = 1:length(ChanNumList)
  ytick = cat(2,ytick,ytick0+(N-1)*length(PlotData.freqs));
  yticklabel = cat(2,yticklabel,yticklabel0);
end
set(handles.axes1,'ytick',ytick,'yticklabel',yticklabel);

%set(handles.axes1,'YTick',0:TFsizey/4:TFsizey*(j-1))
%set(handles.axes1,'yTickLabel',{[num2str(minFreq) ' / ' num2str(maxFreq)],minFreq+(maxFreq-minFreq)/4,minFreq+(maxFreq-minFreq)/2,minFreq+(maxFreq-minFreq)*3/4})

setappdata(handles.main,'TFPlotData',TFPlotData);  % Store TFPlotData

return


function PlotEvents(handles)

%%%%%%%%%%%%%%%%%%%%
% Plot event lines %
%%%%%%%%%%%%%%%%%%%%

EventData=getappdata(handles.main,'EventData');                % Load EventData
if isempty(EventData), return; end                              % If EventData not available do nothing

ChanNumList=getappdata(handles.main,'ChanNumList');

% Delete existing event lines
delete(findobj(handles.axes1,'Tag','PlotEvent1'));
delete(findobj(handles.axes1,'Tag','PlotEvent2'));
delete(findobj(handles.axes1,'Tag','PlotEvent3'));
delete(findobj(handles.axes1,'Tag','PlotEvent4'));
delete(findobj(handles.axes1,'Tag','PlotEvent5'));
delete(findobj(handles.axes1,'Tag','PlotEvent6'));

evtcolors={'r' 'g' 'c' 'm' 'y' 'k'};    % Colors for different event types

tmin=str2num(get(handles.edit_Tmin,'String'));                  % Load tmin from input field
tmax=tmin+str2num(get(handles.edit_Twin,'String'));             % Tmax=tmin+twin (twin from input field)

% Define length of lines for waveform and TF case
if get(handles.popupmenu_WaveformTF,'Value')==1
    ymin=-2;
    ymax=2*length(ChanNumList);
else
    TFPlotData=getappdata(handles.main,'TFPlotData');          % Load TF data
    ymin=0.5;
    ymax=size(TFPlotData,1)+0.5;
end

for iEvt=1:length(EventData.names)                              % For selected event types
    cur_evt_sec=EventData.times(EventData.types==iEvt);         % Use only event times of current event type
    cur_evt_sec=cur_evt_sec(cur_evt_sec >= tmin & cur_evt_sec <= tmax); % Use only event times in visible range
    tmpcol=evtcolors{mod(iEvt-1,length(evtcolors))+1};          % Select referring event color
    
    % If event type is selected in checkbox, make lines visible, otherwise make lines invisible
    if get(eval(['handles.checkbox_Event' num2str(iEvt)]),'Value')>0
        IsVisible='on';
    else
        IsVisible='off';
    end
    
    tmptag=sprintf('PlotEvent%d',iEvt);                         % Define tag for lines "PlotEventx"
    
    if ~isempty(cur_evt_sec)                                    % If there are event lines in visible range...
        for i=1:length(cur_evt_sec)                             % For all events of current type in visible range...
            if get(handles.popupmenu_WaveformTF,'Value')==1     % If waveform format for PlotData...
                % Draw line at event position
                line([cur_evt_sec(i) cur_evt_sec(i)],[ymin ymax],'Color',tmpcol,'Tag',tmptag,'Visible',IsVisible);
            else                                                % If TF format for PlotData...
                PlotData=getappdata(handles.main,'PlotData');  % Load PlotData
                imin=ceil(tmin/PlotData.dx);                    % Calculate index for tmin
                ievt=round(cur_evt_sec(i)/PlotData.dx)-imin+1;  % Calculate index for event time
                % Draw line at event position (index)
                line([ievt ievt],[ymin ymax],'Color',tmpcol,'Tag',tmptag,'Visible',IsVisible);
            end
        end
    end
end

return


function CallbackEvent1(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Show/hide event lines (type 1) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tmptag='PlotEvent1';    % Tag of lines of current event

% If checkbox is activated show lines, otherwise hide them
if get(handles.checkbox_Event1,'Value')>0
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','on')
else
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','off')
end

drawnow;
return

function CallbackEvent2(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Show/hide event lines (type 2) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tmptag='PlotEvent2';    % Tag of lines of current event

% If checkbox is activated show lines, otherwise hide them
if get(handles.checkbox_Event2,'Value')>0
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','on')
else
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','off')
end

drawnow;
return

function CallbackEvent3(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Show/hide event lines (type 3) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tmptag='PlotEvent3';    % Tag of lines of current event

% If checkbox is activated show lines, otherwise hide them
if get(handles.checkbox_Event3,'Value')>0
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','on')
else
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','off')
end

drawnow;
return

function CallbackEvent4(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Show/hide event lines (type 4) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tmptag='PlotEvent4';    % Tag of lines of current event

% If checkbox is activated show lines, otherwise hide them
if get(handles.checkbox_Event4,'Value')>0
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','on')
else
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','off')
end

drawnow;
return

function CallbackEvent5(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Show/hide event lines (type 5) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tmptag='PlotEvent5';    % Tag of lines of current event

% If checkbox is activated show lines, otherwise hide them
if get(handles.checkbox_Event5,'Value')>0
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','on')
else
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','off')
end

drawnow;
return

function CallbackEvent6(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Show/hide event lines (type 6) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tmptag='PlotEvent6';    % Tag of lines of current event

% If checkbox is activated show lines, otherwise hide them
if get(handles.checkbox_Event6,'Value')>0
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','on')
else
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','off')
end

drawnow;
return


function PlotSpikes(handles)

%%%%%%%%%%%%%%%
% Plot Spikes %
%%%%%%%%%%%%%%%

Spkt=getappdata(handles.main,'SPKT');              % Load spike data
if isempty(Spkt), return; end                       % If spike data not available, do nothing

ChanNumList=getappdata(handles.main,'ChanNumList');

delete(findobj(handles.axes1,'Tag','PlotSpikes'));  % Delete existing spike lines

tmin=str2num(get(handles.edit_Tmin,'String'));      % Load tmin from input field
tmax=tmin+str2num(get(handles.edit_Twin,'String')); % Tmax=tmin+twin (twin from input field)

% If checkbox is activated show spikes, otherwise make them invisible
if get(handles.checkbox_ShowSpikes,'Value')>0
    IsVisible='on';
else
    IsVisible='off';
end

if get(handles.popupmenu_Time,'Value')==1           % If time course mode...
    j=0;
    for i=ChanNumList                       % For selected channels...
        j=j+1;
        SpikeData=Spkt.times{i,1};                  % Copy spike indices to SpikeData
        SpikeData=SpikeData*Spkt.dt;                % Calculate spike times from indices
        SpikeData=SpikeData(SpikeData >= tmin & SpikeData <= tmax); % Restrict data to visible range
        if ~isempty(SpikeData)                      % If spikes occur in visible range...
            for k=1:length(SpikeData)
                if get(handles.popupmenu_WaveformTF,'Value')==1         % If waveform mode...
                    % Draw short lines at spike positions
                    line([SpikeData(k) SpikeData(k)],[2*(j-1)-0.5 2*(j-1)+0.5],'Color','red','Tag','PlotSpikes','Visible',IsVisible);
                else                                                    % If TF mode...
                    PlotData=getappdata(handles.main,'PlotData');      % Load PlotData
                    TFPlotData=getappdata(handles.main,'TFPlotData');  % Load TFPlotData
                    imin=ceil(tmin/PlotData.dx);                        % Calculate index for tmin
                    tspkt=round(SpikeData(k)/PlotData.dx)-imin+1;       % Calculate index for spike time
                    % Calculate length of lines depending on y-size of TFPlotData and number of channels selected
                    yspkt=size(TFPlotData,1)/length(ChanNumList);
                    % Draw short lines at spike positions
                    line([tspkt tspkt],[(j-0.75)*yspkt (j-0.25)*yspkt],'Color','red','Tag','PlotSpikes','Visible',IsVisible);
                end
            end   
        end
    end
else                                                % If peri-event mode...
    SpikeData=getappdata(handles.main,'SpikeData');% Load spike data predefined for peri-event mode
    j=0;
    for i=ChanNumList                       % For selected channels...
        j=j+1;        
        tmpspk=SpikeData(SpikeData(:,j) ~= 0 & SpikeData(:,j) >= tmin & SpikeData(:,j) <= tmax,j);  % Restrict data to visible range
        if ~isempty(tmpspk)                         % If spikes occur in visible range...
            for k=1:length(tmpspk)
                if get(handles.popupmenu_WaveformTF,'Value')==1         % If waveform mode...
                    % Draw short lines at spike positions
                    line([tmpspk(k) tmpspk(k)],[2*(j-1)-0.5 2*(j-1)+0.5],'Color','red','Tag','PlotSpikes','Visible',IsVisible);
                else                                                    % If TF mode...
                    PlotData=getappdata(handles.main,'PlotData');      % Load PlotData
                    TFPlotData=getappdata(handles.main,'TFPlotData');  % Load TFPlotData
                    imin=ceil(tmin/PlotData.dx);                        % Calculate index for tmin
                    tspkt=round(tmpspk(k)/PlotData.dx)-imin+1;          % Calculate index for spike time
                    % Calculate length of lines depending on y-size of TFPlotData and number of channels selected
                    yspkt=size(TFPlotData,1)/length(ChanNumList);
                    % Draw short lines at spike positions
                    line([tspkt tspkt],[(j-0.75)*yspkt (j-0.25)*yspkt],'Color','red','Tag','PlotSpikes','Visible',IsVisible);
                end
            end   
        end
    end
end


function CallbackSpikes(handles)

%%%%%%%%%%%%%%%%%%%%
% Show/hide Spikes %
%%%%%%%%%%%%%%%%%%%%

% If checkbox is activated show lines, otherwise hide them
if get(handles.checkbox_ShowSpikes,'Value')>0
    set(findobj(handles.axes1,'Tag','PlotSpikes'),'Visible','on')
else
    set(findobj(handles.axes1,'Tag','PlotSpikes'),'Visible','off')
end

drawnow;
return

function AverageEvents(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot average event data %
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% If time course mode: do calculation
if get(handles.popupmenu_Time,'Value')==1
    
    % Activate all event types, necessary to get EventData including all types
    for i=1:6
       set(eval(['handles.checkbox_Event' num2str(i)]),'Value',1)
    end
    
    EventData = InitEventData(handles);                 % Load new EventData
    setappdata(handles.main,'EventData',EventData)     % Update EventData
    PlotData = getappdata(handles.main,'PlotData');    % Load PlotData
    ChanNumList=getappdata(handles.main,'ChanNumList');
    ChanNumString=getappdata(handles.main,'ChanNumString');
    
    tframe=str2num(get(handles.edit_AverageEvents,'String'));   % get time frame from input field

    iframe=ceil(tframe/PlotData.dx);    % Calculate referring PlotData.dat index

    % If iframe is odd number: make it even 
    % Because iframe/2 should be integer, because event line is plotted at this index
    if rem(iframe,2)
        iframe=iframe+1;
    end
   
    TimeScale = (1:iframe)*PlotData.dx - 0.5*tframe;    % Calculate time scale for picture

    LengthChanNum=length(ChanNumList);          % Number of activated channels, necessary to realize convenient division of the figure
    EvtNum=length(EventData.names);                     % Number of event types, necessary to decide if average values can be calculated

    f=figure;   % Open new figure window

    % Initialization of number of events of different types
    e1=1;
    e2=1;
    e3=1;
    e4=1;
    e5=1;
    e6=1;

    j_ind=1;                    % Channel index
    for j=ChanNumList   % Selected channels

    for i=1:length(EventData.types);    % Vector of event types (e.g. [1,2,1,1,3,2,2,3,1,...])
        if EventData.types(i)==1
            % Generate row in matrix E1 (length iframe): event of type 1 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E1(1:iframe,e1,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row            
            e1=e1+1;
        elseif EventData.types(i)==2
            % Generate row in matrix E2 (length iframe): event of type 2 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E2(1:iframe,e2,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row
            e2=e2+1; 
        elseif EventData.types(i)==3
            % Generate row in matrix E3 (length iframe): event of type 3 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E3(1:iframe,e3,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row
            e3=e3+1;        
        elseif EventData.types(i)==4
            % Generate row in matrix E4 (length iframe): event of type 4 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E4(1:iframe,e4,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row
            e4=e4+1;   
        elseif EventData.types(i)==5
            % Generate row in matrix E5 (length iframe): event of type 5 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E5(1:iframe,e5,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row
            e5=e5+1;  
        elseif EventData.types(i)==6
            % Generate row in matrix E6 (length iframe): event of type 6 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E6(1:iframe,e6,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row
            e6=e6+1;  

        end
    end
    
    % Calculate mean values of matrix columns and plot result
    axes('position',[0.1 0.05+(j_ind-0.85)/(LengthChanNum+1) 0.8 1/(LengthChanNum+1)],'units','normalized') % Change position of picture depending on channel no.

    E1mean(1:iframe,j)=mean(E1(1:iframe,:,j),2);    % Mean values of matrix columns is average event waveform
    plot(TimeScale,E1mean(:,j),'Color','red')       % plot result
    hold on

    if EvtNum>1                                     % Check if mean value needs to be calculated
    E2mean(1:iframe,j)=mean(E2(1:iframe,:,j),2);    % Mean values of matrix columns is average event waveform
    plot(TimeScale,E2mean(:,j),'Color','green')     % plot result
    hold on
    end

    if EvtNum>2                                     % Check if mean value needs to be calculated
    E3mean(1:iframe,j)=mean(E3(1:iframe,:,j),2);    % Mean values of matrix columns is average event waveform
    plot(TimeScale,E3mean(:,j),'Color','cyan')      % plot result
    hold on
    end

    if EvtNum>3                                     % Check if mean value needs to be calculated
    E4mean(1:iframe,j)=mean(E4(1:iframe,:,j),2);    % Mean values of matrix columns is average event waveform
    plot(TimeScale,E4mean(:,j),'Color','magenta')   % plot result
    hold on
    end

    if EvtNum>4                                     % Check if mean value needs to be calculated
    E5mean(1:iframe,j)=mean(E5(1:iframe,:,j),2);    % Mean values of matrix columns is average event waveform
    plot(TimeScale,E5mean(:,j),'Color','magenta')   % plot result
    hold on
    end

    if EvtNum>5                                     % Check if mean value needs to be calculated
    E6mean(1:iframe,j)=mean(E6(1:iframe,:,j),2);    % Mean values of matrix columns is average event waveform
    plot(TimeScale,E6mean(:,j),'Color','magenta')   % plot result
    hold on
    end

    if j_ind>1
        set(gca,'XTickLabel',[])    % Delete x-axis labels, which are not at outside margin
    end
    if j_ind==1
        xlabel('t_{frame} [s]')     % X-axis label
    end

    ylabel(ChanNumString(j_ind))% Y-axis label: channel names

    j_ind=j_ind+1;
    end

    title('Average events')
    legend(EventData.names)         % Legend: event types

% If peri-event mode: avoid wrong results, because time frames in PlotData may be smaller than tframe in Average Events
else warndlg('Please use time course mode!')
end

function AverageZscore(handles)

%%%%%%%%%%%%%%%%%%%
% Average z-score %
%%%%%%%%%%%%%%%%%%%

f=figure;                                                  % Open new figure window

PlotData=getappdata(handles.main,'PlotData');              % Load PlotData

if get(handles.listbox_RawdataZscore,'Value')==1            % If z-score is selected in listbox...
    %PlotData = sigfiltfilt(PlotData,[80 150],'bandpass');   % Previous filtering; why??
    PlotData.dat=zscore(PlotData.dat,[],1);                 % Calculate z-scores
end

PlotData.dat = nanmean(PlotData.dat,2);                     % Calculate mean value concerning the channels

TimeScale = (1:size(PlotData.dat,1))*PlotData.dx;           % Initialize time scale

tmin=str2num(get(handles.edit_Tmin,'String'));              % Get tmin from input field
tmax=tmin+str2num(get(handles.edit_Twin,'String'));         % Tmax=tmin+tdiff

plot(TimeScale,PlotData.dat)                                % Plot data
set(gca,'XLim',[tmin tmax])

function AverageTFprofile(handles)

%%%%%%%%%%%%%%%%%%%%%%
% Average TF profile %
%%%%%%%%%%%%%%%%%%%%%%

% If time course mode: do calculation
if get(handles.popupmenu_Time,'Value')==1
    
   % Activate all event types, necessary to get EventData including all types 
   for i=1:6
       set(eval(['handles.checkbox_Event' num2str(i)]),'Value',1)
   end

   EventData = InitEventData(handles);                 % Load new EventData
   setappdata(handles.main,'EventData',EventData)     % Update EventData
   PlotData = getappdata(handles.main,'PlotData');    % Load PlotData
   ChanNumList=getappdata(handles.main,'ChanNumList');
   ChanNumString=getappdata(handles.main,'ChanNumString');

   tframe=str2num(get(handles.edit_TFprofile,'String'));    % Load time frame from input field

   iframe=ceil(tframe/PlotData.dx);      % Calculate referring PlotData.dat index

   % If iframe is odd number: make it even 
   % Because iframe/2 should be integer, because event line is plotted at this index
   if rem(iframe,2)
       iframe=iframe+1;
   end
   
   TimeScale = (1:iframe)*PlotData.dx - 0.5*tframe; % Calculate time scale for pictures

    LengthChanNum=length(ChanNumList);      % Number of selected channels
    EvtNum=length(EventData.names);                 % Number of event types

    f=figure;                                       % Open new figure

    j_ind=1;                                        % Channel number index
    for j=ChanNumList                       % Selected channels
    % Initialization of number of events of different types
    e1=1;
    e2=1;
    e3=1;
    e4=1;
    e5=1;
    e6=1;

    for i=1:length(EventData.types);    % Vector of event types (e.g. [1,2,1,1,3,2,2,3,1,...])
        if EventData.types(i)==1
            % Generate row in matrix E1 (length iframe): event of type 1 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E1(1:iframe,e1,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row
            e1=e1+1;
        elseif EventData.types(i)==2
            % Generate row in matrix E2 (length iframe): event of type 2 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E2(1:iframe,e2,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row
            e2=e2+1; 
        elseif EventData.types(i)==3
            % Generate row in matrix E3 (length iframe): event of type 3 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E3(1:iframe,e3,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row
            e3=e3+1;        
        elseif EventData.types(i)==4
            % Generate row in matrix E4 (length iframe): event of type 4 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E4(1:iframe,e4,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row
            e4=e4+1;      
        elseif EventData.types(i)==5
            % Generate row in matrix E5 (length iframe): event of type 5 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E5(1:iframe,e5,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row
            e5=e5+1;    
        elseif EventData.types(i)==6
            % Generate row in matrix E6 (length iframe): event of type 6 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E6(1:iframe,e6,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row
            e6=e6+1;            

        end
    end

    for i=1:EvtNum
        % Change position of the picture depending on the channel index and event type
        axes('position',[0.1+(i-1)*0.2 0.05+(j_ind-0.85)/(LengthChanNum+1) 0.2 1/(LengthChanNum+1)],'units','normalized')

        % Calculate and plot TF profile of event matrix Ex
        TFdata=PlotData;                    % Load general data
        TFdata.dat=eval(['E' num2str(i)]);  % Load event matrix
        TFdata=sigtimefreq(TFdata);         % Calculate TF profiles
        TFdata.dat=abs(TFdata.dat);         % Calculate absolute values
        x=mean(TFdata.dat(:,:,:,j),3);      % Calculate mean TF profile 
        x=transpose(x);                     % Transpose result for correct display
        imagesc(TimeScale,TFdata.freqs,x)   % Plot data


        set(gca,'ydir','normal');           % Correct y-axis direction
        if j_ind>1
            set(gca,'XTickLabel',[])        % Delete center laying labels
        end
        if i>1 
            set(gca,'YTickLabel',[])        % Delete center laying labels
        end
        if i==1
            ylabel(ChanNumString(j_ind));   % Y-axis label: channel name
        end
        if j_ind==1
            xlabel('t_{frame} [s]');        % X-axis label
        end

        title(EventData.names{1,i});        % Titles: event names
    end

    j_ind=j_ind+1;
    end

    % If peri-event mode: avoid wrong results, because time frames in PlotData may be smaller than tframe in Average Events
    else warndlg('Please use time course mode!')
end

function plotpcavectors(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot PCA singular vectors %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% If time course mode: do calculation
if get(handles.popupmenu_Time,'Value')==1
    
    % Activate all event types, necessary to get EventData including all types
    for i=1:6
       set(eval(['handles.checkbox_Event' num2str(i)]),'Value',1)
    end
    
    EventData = InitEventData(handles);                 % Load new EventData
    setappdata(handles.main,'EventData',EventData)     % Update EventData
    PlotData = getappdata(handles.main,'PlotData');    % Load PlotData
    ChanNumList=getappdata(handles.main,'ChanNumList');
    ChanNumString=getappdata(handles.main,'ChanNumString');
    
    tframe=str2num(get(handles.edit_SVtframe,'String'));% get time frame from input field

    iframe=ceil(tframe/PlotData.dx);                % Calculate referring PlotData.dat index
    
    % If iframe is odd number: make it even 
    % Because iframe/2 should be integer, because event line is plotted at this index
    if rem(iframe,2)
        iframe=iframe+1;
    end
    
    TimeScale = (1:iframe)*PlotData.dx - 0.5*tframe;% Calculate time scale for picture

    LengthChanNum=length(ChanNumList);      % Number of activated channels, necessary to realize convenient division of the figure
    EvtNum=length(EventData.names);                 % Number of event types, necessary to decide if average values can be calculated

    f1=figure;  % Open new figure window

    j_ind=1;                                        % Channel number index
    for j=ChanNumList                       % Selected channels
        
    % Initialization of number of events of different types
    e1=1;
    e2=1;
    e3=1;
    e4=1;
    e5=1;
    e6=1;
    
    for i=1:length(EventData.types);    % Vector of event types (e.g. [1,2,1,1,3,2,2,3,1,...])
        if EventData.types(i)==1
            % Generate row in matrix E1 (length iframe): event of type 1 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E1(e1,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row        
            e1=e1+1;
        elseif EventData.types(i)==2
            % Generate row in matrix E2 (length iframe): event of type 2 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E2(e2,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row 
            e2=e2+1; 
        elseif EventData.types(i)==3
            % Generate row in matrix E3 (length iframe): event of type 3 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E3(e3,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row 
            e3=e3+1;        
        elseif EventData.types(i)==4
            % Generate row in matrix E4 (length iframe): event of type 4 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E4(e4,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row 
            e4=e4+1;      
        elseif EventData.types(i)==5
            % Generate row in matrix E5 (length iframe): event of type 5 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E5(e5,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row 
            e5=e5+1;    
        elseif EventData.types(i)==6
            % Generate row in matrix E6 (length iframe): event of type 6 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E6(e6,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row 
            e6=e6+1;            

        end
    end
    
    NumSV=str2num(get(handles.edit_SVnum,'String'));    % Get number of singular values from input field
    
    for i=1:EvtNum
        x=eval(['E' num2str(i) '(:,:,j)']);
        PCAcov=cov(x);                                  % Calculate covariance matrix of event matrices Ex
        [y(:,:,i),z(:,:,i)]=svds(PCAcov,NumSV);         % Calculate singular vectors and values
        
        miny=min(min(min(y)));                          % Determine limits for the plot
        maxy=max(max(max(y)));
    end
    
    for i=1:EvtNum
        % Change position of the pictures depending on the channel number and event type 
        axes('position',[0.1+(i-1)*0.2 0.05+(j_ind-0.85)/(LengthChanNum+1) 0.2 1/(LengthChanNum+1)],'units','normalized')
        % Plot singular vectors
        for k=NumSV:-1:1
            plot(TimeScale,y(:,k,i),'Color',[1/k 1-1/k 1-1/k]);
            set(gca,'YLim',[miny maxy],'XLim',[-0.5*tframe 0.5*tframe])
            hold on
        end
 
    if j_ind>1
        set(gca,'XTickLabel',[])                        % Delete center laying labels
    end
    if i>1 
        set(gca,'YTickLabel',[])                        % Delete center laying labels
    end
    if i==1
        ylabel(ChanNumString(j_ind));           % Y-axis label: channel name
    end
    if j_ind==1
        xlabel('t_{frame} [s]');
    end

    title(EventData.names{1,i});                        % Titles: event types
      
    end
      
    j_ind=j_ind+1;
    end
% If peri-event mode: avoid wrong results, because time frames in PlotData may be smaller than tframe of PCA
else warndlg('Please use time course mode!')
end


function plotpcavalues(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot PCA singular values %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% If time course mode: do calculation
if get(handles.popupmenu_Time,'Value')==1
    
    % Activate all event types, necessary to get EventData including all types
    for i=1:6
       set(eval(['handles.checkbox_Event' num2str(i)]),'Value',1)
    end
    
    EventData = InitEventData(handles);                 % Load new EventData
    setappdata(handles.main,'EventData',EventData)     % Update EventData
    PlotData = getappdata(handles.main,'PlotData');    % Load PlotData
    ChanNumList=getappdata(handles.main,'ChanNumList');
    ChanNumString=getappdata(handles.main,'ChanNumString');    
    
    tframe=str2num(get(handles.edit_SVtframe,'String'));% get time frame from input field

    iframe=ceil(tframe/PlotData.dx);                % Calculate referring PlotData.dat index
    
    % If iframe is odd number: make it even 
    % Because iframe/2 should be integer, because event line is plotted at this index
    if rem(iframe,2)
        iframe=iframe+1;
    end
    
    TimeScale = (1:iframe)*PlotData.dx - 0.5*tframe;% Calculate time scale for picture

    LengthChanNum=length(ChanNumList);      % Number of activated channels, necessary to realize convenient division of the figure
    EvtNum=length(EventData.names);                 % Number of event types, necessary to decide if average values can be calculated

    f1=figure;  % Open new figure window

    j_ind=1;                                        % Channel number index
    for j=ChanNumList                       % Selected channels
        
    % Initialization of number of events of different types
    e1=1;
    e2=1;
    e3=1;
    e4=1;
    e5=1;
    e6=1;
    
    for i=1:length(EventData.types);    % Vector of event types (e.g. [1,2,1,1,3,2,2,3,1,...])
        if EventData.types(i)==1
            % Generate row in matrix E1 (length iframe): event of type 1 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E1(e1,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row        
            e1=e1+1;
        elseif EventData.types(i)==2
            % Generate row in matrix E2 (length iframe): event of type 2 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E2(e2,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row 
            e2=e2+1; 
        elseif EventData.types(i)==3
            % Generate row in matrix E3 (length iframe): event of type 3 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E3(e3,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row 
            e3=e3+1;        
        elseif EventData.types(i)==4
            % Generate row in matrix E4 (length iframe): event of type 4 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E4(e4,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row 
            e4=e4+1;      
        elseif EventData.types(i)==5
            % Generate row in matrix E5 (length iframe): event of type 5 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E5(e5,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row 
            e5=e5+1;    
        elseif EventData.types(i)==6
            % Generate row in matrix E6 (length iframe): event of type 6 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E6(e6,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row 
            e6=e6+1;            

        end
    end
    
    NumSV=str2num(get(handles.edit_SVnum,'String'));    % Get number of singular values from input field

    for i=1:EvtNum
        x=eval(['E' num2str(i) '(:,:,j)']);
        PCAcov=cov(x);                                  % Calculate covariance matrix of event matrices Ex
        [y(:,:,i),z(:,:,i)]=svds(PCAcov,NumSV);         % Calculate singular vectors and values
        z1(:,i)=diag(z(:,:,i));
    end
    
    minz1=min(min(z1));                                 % Determine limits for the plot
    maxz1=max(max(z1));
    
    for i=1:EvtNum
        % Change position of the pictures depending on the channel number and event type 
        axes('position',[0.1+(i-1)*0.2 0.05+(j_ind-0.85)/(LengthChanNum+1) 0.2 1/(LengthChanNum+1)],'units','normalized')
        % Plot singular values
        for k=NumSV:-1:1
            plot(k,z1(k,i),'*','Color',[1/k 1-1/k 1-1/k]);
            set(gca,'YLim',[minz1 maxz1])
            hold on
        end
        
    if j_ind>1
        set(gca,'XTickLabel',[])                        % Delete center laying labels
    end
    if i>1 
        set(gca,'YTickLabel',[])                        % Delete center laying labels 
    end
    if i==1
        ylabel(ChanNumString(j_ind));           % Y-axis label: channel name
    end
    if j_ind==1
        xlabel('No SV');
    end

    title(EventData.names{1,i});                        % Titles: event types
      
    end
        
    j_ind=j_ind+1;
    end
% If peri-event mode: avoid wrong results, because time frames in PlotData may be smaller than tframe of PCA
else warndlg('Please use time course mode!')
end

function SpikeHistogram(handles)

%%%%%%%%%%%%%%%%%%%%%%%%
% plot spike histogram %
%%%%%%%%%%%%%%%%%%%%%%%%

PlotData = getappdata(handles.main,'SPKT');        % Load spike data
ChanNumList=getappdata(handles.main,'ChanNumList');

delete(findobj(gca,'Tag','PlotData'))               % Delete current plot

TimeScale = (1:size(PlotData.dat,1))*PlotData.dx;   % Calculate time scale

xlimmin=str2num(get(handles.edit_Tmin,'String'));   % Get tmin from input field
xlimdiff=str2num(get(handles.edit_Twin,'String'));  % Get twin from input field

% Plot spike histogram data
j=1;
for i=ChanNumList
    plot(TimeScale,PlotData.dat(:,i)+(j-1)*5,'Parent',handles.axes1,'Tag','PlotData')
    hold on
    set(handles.axes1,'XLim',[xlimmin xlimmin+xlimdiff],'YLim',[-5 5*length(ChanNumList)],'YTick',[0:1:5*length(ChanNumList)],'YTickLabel',{0,1,2,3,4},'YGrid','on')
    j=j+1;
end

function SeparatePicture(handles)

%%%%%%%%%%%%%%%%%%%%
% Separate picture %
%%%%%%%%%%%%%%%%%%%%

% Opens the current picture from figure area also in a separate figure window
% Thus, pictures can be compared, edited ...

f=figure;                                                       % Open new figure window
sepfig=copyobj(handles.axes1,f);                                % Copy axes data to new figure
set(sepfig,'Units','normalized','Position',[0.15 0.05 0.8 0.9]) % Adapt position data of new plot

function TimeSlider(handles)
%%%%%%%%%%%%%%%
% Time slider %
%%%%%%%%%%%%%%%

EventData = getappdata(handles.main,'EventData');  % Load EventData

xlimmin=get(handles.slider1,'Value');       % Get tmin from time slider
xlimdiff=get(handles.edit_Twin,'Value');    % Get twin from input field
set(handles.edit_Tmin,'String',xlimmin)     % Set new tmin in input field

% Update event slider
t_now=xlimmin+0.5*xlimdiff;                     % Current time is set to middle of plot area
[i_evt,i_evt]=min(abs(EventData.times-t_now));  % Estimate nearest event
set(handles.slider2,'Value',i_evt)              % Set event slider to nearest event number

return

function EventSlider(handles)
%%%%%%%%%%%%%%%%
% Event slider %
%%%%%%%%%%%%%%%%

EventData = getappdata(handles.main,'EventData');  % Load EventData

xlimdiff=str2num(get(handles.edit_Twin,'String'));  % Get twin from input field

i_evt=round(get(handles.slider2,'Value'));          % Get event index from slider
% Determine event time
if i_evt==0
    t_evt=0.5*xlimdiff;
else
    t_evt=EventData.times(i_evt);
end

if get(handles.popupmenu_Time,'Value')==1
    % If time course mode: event is arranged in the middle of the plot area
    xlimmin=t_evt-0.5*xlimdiff;
else
    % If peri-event mode: event is arranged at the beginning of the plot area (at tframe/2)
    xlimmin=t_evt-0.5*str2num(get(handles.edit_Tframe,'String'));
end

% Avoid errors if tmin<0
if xlimmin<0
    xlimmin=0;
end

set(handles.edit_Tmin,'String',xlimmin) % Update tmin input field
set(handles.slider1,'Value',xlimmin)    % Update time slider
return


function RedrawAll(hObject,eventdata,handles)

%%%%%%%%%%%%%%%
% Update plot %
%%%%%%%%%%%%%%%

% Is called when new drawing is required (changing slider, tmin, twin etc.)
handles   = guihandles(hObject);

if get(handles.popupmenu_WaveformTF,'Value')==1     % If waveform mode...
    PlotWvData(handles)                             % Plot waveform data
else                                                % If TF mode...
    PlotTfData(handles)                             % Plot TF data
end
PlotEvents(handles)                                 % Plot event lines if necessary
PlotSpikes(handles)                                 % Plot spike lines if necessary

% Update slider settings
EventData=getappdata(handles.main,'EventData');    % Load event data
SliderMax=get(handles.slider1,'Max');               % Get maximum of time slider
xlimdiff=str2num(get(handles.edit_Twin,'String'));  % Load twin from input field
LengthEventData=length(EventData.types);            % Determine total number of events (of selected types)
if LengthEventData==0                               % To avoid errors
    LengthEventData=1;
end

set(handles.slider1,'SliderStep',[xlimdiff/SliderMax xlimdiff/SliderMax])   % Update step size for time slider
set(handles.slider2,'Max',LengthEventData)                                  % Update maximum for event slider
set(handles.slider2,'SliderStep',[1/LengthEventData 1/LengthEventData])     % Update step size for event slider

guidata(hObject, handles);

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% =========================================================================================================
function [scrW scrH] = subGetScreenSize(Units)
% =========================================================================================================
% FUNCTION to get screen size
oldUnits = get(0,'Units');
set(0,'Units',Units);
sz = get(0,'ScreenSize');
set(0,'Units',oldUnits);
scrW = sz(3);  scrH = sz(4);
return;

function HelloCallback(hObject,eventdata,handles)
%msgbox('Hello world');
handles   = guihandles(hObject);
Cln    = getappdata(handles.main,'CLN');
        InitPlotData(hObject,handles)
        RedrawAll(hObject,handles)    

