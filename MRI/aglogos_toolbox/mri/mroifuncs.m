function varargout = mroifuncs(varargin)
%MROIFUNCS - GUI showing roi-functions
%  MROIFUNCS - GUI showing roi-functions.
%
%  EXAMPLE :
%    >> mroifuncs
%
%  VERSION :
%    0.90 20.01.14 YM  pre-release
%
%  See also 


persistent H_MROIFUNCS;  % keep the figure handle
  

% execute callback function then return; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin > 0 && ischar(varargin{1}) && ~isempty(findstr(varargin{1},'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return;
end


%% prevent double execution
if ishandle(H_MROIFUNCS),
  close(H_MROIFUNCS);
  %fprintf('\n ''mgui'' already opened.\n');
  %return;
end



% DEFAULT CONTROL SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear FuncInfo;
%             sub_finfo(funcname, from, to, ...)
FuncInfo = [];


% GET SCREEN SIZE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[scrW scrH] = subGetScreenSize('char');

figW = 40; figH = 20;
figX = 1;  figY = scrH-figH-6;

%[figX figY figW figH]
% CREATE A MAIN FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hMain = figure(...
    'Name',mfilename,...
    'NumberTitle','off', 'toolbar','none','MenuBar','none',...
    'Tag','main', 'units','char', 'pos',[figX figY figW figH],...
    'HandleVisibility','on', 'Resize','on',...
    'DoubleBuffer','on', 'BackingStore','on', 'Visible','on',...
    'DefaultAxesFontSize',10,...
    'DefaultAxesFontName', 'Comic Sans MS',...
    'DefaultAxesfontweight','bold',...
    'PaperPositionMode','auto', 'PaperType','A4', 'PaperOrientation', 'landscape');


% WIDGETS %%%%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XDSP = 1; H = figH - 2.5;
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H-0.2 30 1.5],...
    'String','From :','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','FromTxt',...
    'BackgroundColor',get(hMain,'Color'));
uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+9 H 28 1.5],...
    'Callback','mroifuncs(''Main_Callback'',gcbo,''set-funcs'',guidata(gcbo))',...
    'String',{'Any' 'Atlas' 'ROI (other session)' 'ANA' 'EPI'},'Value',1,'Tag','FromCmb',...
    'HorizontalAlignment','left',...
    'TooltipString','Data Source',...
    'FontWeight','Bold');
%    'FontWeight','Bold','FontName','FixedWidth');  % 'FixedWidth' shows no underscore, '_'...


XDSP = 1; H = figH - 4.5;
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H-0.2 30 1.5],...
    'String','To :','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','ToTxt',...
    'BackgroundColor',get(hMain,'Color'));
uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+9 H 28 1.5],...
    'Callback','mroifuncs(''Main_Callback'',gcbo,''set-funcs'',guidata(gcbo))',...
    'String',{'Any' 'ROI' 'EPI' 'Template-Brain'},'Value',1,'Tag','ToCmb',...
    'HorizontalAlignment','left',...
    'TooltipString','Data Destination',...
    'FontWeight','Bold');
%    'FontWeight','Bold','FontName','FixedWidth');  % 'FixedWidth' shows no underscore, '_'...


XDSP = 1; H = figH - 6.5;
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H-0.2 30 1.5],...
    'String','Func :','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','FunctionsTxt',...
    'BackgroundColor',get(hMain,'Color'));
uicontrol(...
    'Parent',hMain,'Style','ListBox',...
    'Units','char','Position',[XDSP+9 H-12+1 28 12],...
    'Callback','mroifuncs(''Main_Callback'',gcbo,''on-func'',guidata(gcbo))',...
    'String',{'none'},'min',1,'max',1,'value',1,...
    'Tag','FuncList',...
    'HorizontalAlignment','left',...
    'TooltipString','available functions',...
    'FontWeight','bold');
%    'FontWeight','bold','FontName','FixedWidth');  % 'FixedWidth' shows no underscore, '_'...




XDSP = 1;  H = 0.5;
% Print-Help button
uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[XDSP H 20 1.5],...
    'Callback','mroifuncs(''Main_Callback'',gcbo,''print-help'',guidata(gcbo))',...
    'Tag','PrintHelpBtn','String','Print Help',...
    'TooltipString','Print help','FontWeight','bold',...
    'BackgroundColor',[0.8 0.8 0],'ForegroundColor',[0 0 1.0]);
% Edit button
uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[XDSP+20.2 H 17 1.5],...
    'Callback','mroifuncs(''Main_Callback'',gcbo,''edit'',guidata(gcbo))',...
    'Tag','EditBtn','String','Edit',...
    'TooltipString','Edit the script','FontWeight','bold',...
    'BackgroundColor',[0.5 0.8 0.8],'ForegroundColor',[0 0 1.0]);




setappdata(hMain,'FuncInfo', FuncInfo);

% get widgets handles at this moment
HANDLES = findobj(hMain);
Main_Callback(hMain,'set-funcs',[]);


% NOW SET "UNITS" OF ALL WIDGETS AS "NORMALIZED".
HANDLES = HANDLES(HANDLES ~= hMain);
set(HANDLES,'units','normalized');

H_MROIFUNCS = hMain;

if nargout,
  varargout{1} = hMain;
end
  

return;

% ==================================================================
function FINFO = sub_finfo(funcname, str_src, str_dst)
% ==================================================================
FINFO.func = funcname;
FINFO.src  = str_src;
FINFO.dst  = str_dst;

return


% ==================================================================
function Main_Callback(hObject,eventdata,handles)
% ==================================================================
wgts = guihandles(hObject);

%eventdata

switch lower(eventdata),
 case {'init'}

 case {'set-funcs'}
  Sub_SetFuncs(wgts);
  
 case {'print-help'}
  FuncName = get(wgts.FuncList,'String');
  if ~isempty(FuncName)
    FuncName = FuncName{get(wgts.FuncList,'Value')};
    if ~strcmpi(FuncName,'none')
      fprintf('--------------------------------------------------\n\n');
      eval(['help ' FuncName '.m']);
    end
  end
  
 case {'edit'}
  FuncName = get(wgts.FuncList,'String');
  if ~isempty(FuncName)
    FuncName = FuncName{get(wgts.FuncList,'Value')};
    if ~strcmpi(FuncName,'none')
      eval(['edit ' FuncName '.m']);
    end
  end

 case {'on-func'}
  click = get(wgts.main,'SelectionType');
  if strcmpi(click,'normal')
    % single-click
    % pause() to check a call by "open".
    pause(0.3);
    if strcmpi(get(wgts.main,'SelectionType'),'normal')
      % ok, it seems 'normal' not 'open' of double-click...
      Main_Callback(wgts.FuncList,'print-help');
    end
  elseif strcmpi(click,'alt')
    % single-click with Ctrl
  elseif strcmpi(click,'open')
    % double-click
    Main_Callback(wgts.FuncList,'edit');
  end
  
 otherwise
  fprintf('WARNING %s: Main_Callback() ''%s'' not supported yet.\n',mfilename,eventdata);
end
  
return;


% ==================================================================
function Sub_SetFuncs(wgts)
% ==================================================================
FromStr = get(wgts.FromCmb,'String');
FromStr = FromStr{get(wgts.FromCmb,'Value')};
ToStr   = get(wgts.ToCmb,'String');
ToStr   = ToStr{get(wgts.ToCmb,'Value')};

FuncName = {};

switch lower(FromStr)
 case {'atlas'}
  switch lower(ToStr)
   case {'roi'}
    FuncName{end+1} = 'matlas2roi';
    FuncName{end+1} = 'mroiatlas';
    FuncName{end+1} = 'mroi';
   case {'epi'}
    FuncName = {'none'};
   case {'brain' 'avr-brain' 'average-brain' 'template-brain'}
    FuncName = {'none'};
   otherwise
    FuncName{end+1} = 'matlas2roi';
    FuncName{end+1} = 'mroiatlas';
    FuncName{end+1} = 'mroi';
  end
  
 case {'roi (other session)' 'session-roi' 'session'}
  switch lower(ToStr)
   case {'roi'}
    FuncName{end+1} = 'mroi2roi_shift';
    FuncName{end+1} = 'mroi2roi_coreg';
    FuncName{end+1} = 'mroi';
   case {'epi'}
    FuncName = {'none'};
   case {'brain' 'avr-brain' 'average-brain' 'template-brain'}
    FuncName = {'none'};
   otherwise
    FuncName{end+1} = 'mroi2roi_shift';
    FuncName{end+1} = 'mroi2roi_coreg';
    FuncName{end+1} = 'mroi';
  end
    
 case {'ana' 'session-ana' 'inplane-ana'}
  switch lower(ToStr)
   case {'roi'}
    FuncName{end+1} = 'mana2epi';
    FuncName{end+1} = 'mroi';
   case {'epi'}
    FuncName{end+1} = 'mana2epi';
   case {'brain' 'avr-brain' 'average-brain' 'template-brain'}
    FuncName{end+1} = 'mana2brain';
    FuncName{end+1} = 'mroits2brain';
   otherwise
    FuncName{end+1} = 'mana2epi';
    FuncName{end+1} = 'mroi';
    FuncName{end+1} = 'mana2brain';
    FuncName{end+1} = 'mroits2brain';
  end
 
 case {'epi' 'session-epi' 'inplane-epi'}
  switch lower(ToStr)
   case {'roi'}
    FuncName{end+1} = 'mroi';
   case {'epi'}
    FuncName = {'none'};
   case {'brain' 'avr-brain' 'average-brain' 'template-brain'}
    FuncName{end+1} = 'mana2brain';
    FuncName{end+1} = 'mroits2brain';
   otherwise
    FuncName{end+1} = 'mroi';
    FuncName{end+1} = 'mana2brain';
    FuncName{end+1} = 'mroits2brain';
  end
 
 otherwise
  switch lower(ToStr)
   case {'roi'}
    FuncName{end+1} = 'matlas2roi';
    FuncName{end+1} = 'mroiatlas';
    FuncName{end+1} = 'mroi2roi_shift';
    FuncName{end+1} = 'mroi2roi_coreg';
    FuncName{end+1} = 'mroi';
   case {'epi'}
    FuncName{end+1} = 'mana2epi';
   case {'brain' 'avr-brain' 'average-brain' 'template-brain'}
    FuncName{end+1} = 'mana2brain';
    FuncName{end+1} = 'mroits2brain';
   otherwise
    FuncName{end+1} = 'matlas2roi';
    FuncName{end+1} = 'mroiatlas';
    FuncName{end+1} = 'mroi2roi_shift';
    FuncName{end+1} = 'mroi2roi_coreg';
    FuncName{end+1} = 'mroi';
    FuncName{end+1} = 'mana2epi';
    FuncName{end+1} = 'mana2brain';
    FuncName{end+1} = 'mroits2brain';
    FuncName{end+1} = 'mcoreg_spm_coreg';
    FuncName{end+1} = 'spm_coreg';
  end
end

% for N=1:length(FuncName)
%   FuncName{N} = strrep(FuncName{N},'_','\_');
% end

set(wgts.FuncList,'String',FuncName,'Value',1);


return
  
  

% ==================================================================
% FUNCTION to get screen size
function [scrW, scrH] = subGetScreenSize(Units)
% ==================================================================
oldUnits = get(0,'Units');
set(0,'Units',Units);
sz = get(0,'ScreenSize');
set(0,'Units',oldUnits);

scrW = sz(3);  scrH = sz(4);

return;
