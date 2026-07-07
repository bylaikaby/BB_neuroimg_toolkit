function varargout = test_gui(varargin)
%TEST_GUI - GUI Template.
%  TEST_GUI('') runs GUI.
%
%  NOTE :
%    - replace all 'test_gui' with your function name...
%
%  Callback :
%    Widgets' callback must be like
%    'test_gui(''Main_Callback'',gcbo,''set-value'',guidata(gcbo))'.
%
%  EXAMPLE :
%    test_gui('');
%
%  VERSION :
%    0.90 03.02.12 YM  pre-release
%
%  See also

if ~nargin,  help test_gui; return;  end

% execute callback function then return;
if ischar(varargin{1}) && ~isempty(findstr(varargin{1},'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return;
end

% ====================================================================
% DISPLAY PARAMETERS FOR THE PLACEMENT OF AXIS ETC.
% ====================================================================
[scrW scrH] = sub_screen_size('char');
figW        = 180.0;
figH        =  50.0;
figX        =   1.0;
figY        = scrH-figH-4;   % MUST BE "-4" for menu/title, need to avoid y-offset of roipoly()


% ====================================================================
% CREATE THE MAIN WINDOW
% Reminder: get(0,'DefaultUicontrolBackgroundColor')
%    'Color', get(0,'DefaultUicontrolBackgroundColor'),...
% ====================================================================
figW        = 180.0;
figH        =  50.0;
figX        =   1.0;
figY        = scrH-figH-4;   % MUST BE "-4" for menu/title, need to avoid y-offset of roipoly()

hMain = figure(...
'Name',...
'TEST_GUI: TEST_GUI',...
	'NumberTitle','off', ...
    'Tag','main', ...
    'HandleVisibility','on','Resize','on',...
    'DoubleBuffer','on', 'BackingStore','on','Visible','off',...
    'Units','char','Position',[figX figY figW figH]);


% ====================================================================
% DISPLAY NAMES OF SESSION/GROUP
% ====================================================================
BKGCOL = get(hMain,'Color');
XDSP = 15;  HY = figH-3;
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP, HY 30 1.25],...
    'String','Value: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
ValueTextEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+10, HY 10 1.5],...
    'Callback','test_gui(''Main_Callback'',gcbo,''set-value'',guidata(gcbo))',...
    'String','0.5','Tag','ValueTextEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set a value for something',...
    'FontWeight','bold');

ImageAxs = axes(...
    'Parent',hMain,'Tag','ImageAxs',...
    'Units','char','layer','top',...
    'Position',[15 5 figW*0.8 figH*0.8],...
    'xticklabel','','yticklabel','','xtick',[],'ytick',[]);




test_gui('Main_Callback',hMain,'init');
set(hMain,'Visible','on');

if nargout, varargout{1} = hMain;  end
return;




% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [scrW scrH] = sub_screen_size(Units)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
oldUnits = get(0,'Units');
set(0,'Units',Units);
sz = get(0,'ScreenSize');
set(0,'Units',oldUnits);

scrW = sz(3);  scrH = sz(4);

return



% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN CALLBACK
function Main_Callback(hObject,eventdata,handles)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
funcname = mfilename('fullpath');
[ST, I] = dbstack;
n = findstr(ST(I).name,'(');
cbname = ST(I).name(n+1:end-1);

wgts = guihandles(hObject);


%fprintf('%s: eventdata=''%s''\n',datestr(now,'HH:MM:SS'),eventdata);


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

  
  % DO YOUR INITIALIZATION ========================================
  fprintf(' %s: init\n',mfilename);
  % DATA = load(YOURFILE)
  % setappdata(wgts.main,'DATA',DATA);
  % ===============================================================
  Main_Callback(hObject,'redraw',handles);
  
 case {'redraw'}
  sub_redraw(wgts);
  % some plotting functions rest 'tag', so set it again....
  set(wgts.ImageAxs,'tag','ImageAxs');
  
  
 case {'set-value'}
  Main_Callback(hObject,'redraw',handles);
  
 otherwise
  fprintf('%s: unknown: %s\n',mfilename,eventdata);
  
end
return;





function sub_redraw(wgts)

fprintf('%s.sub_redraw()\n',mfilename);

set(wgts.main,'CurrentAxes',wgts.ImageAxs);

Value = str2double(get(wgts.ValueTextEdt,'String'))

% PLOT SOMETHING =================================================
% DATA = getappdata(wgts.main,'DATA');




return
