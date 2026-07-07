function varargout = monlinepvpar(varargin)
%MONLINEPVPAR - viewer of paravision parameters for online analysis
%  MONLINEPVPAR called by MONLINEVIEW.
%
%  EXAMPLE :
%    >> monline
%    >> monlinepvpar(SIG)
%
%  NOTES :
%    This function will be called by monlineview.m.
%
%  VERSION :
%    0.90 03.04.08 YM  pre-release
%    0.91 08.04.08 YM  bug fix for old matlab (7.0.4)
%
%  See also MONLINE MONLINEPROC MONLINEVIEW


% display help if no arguments %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 0,  help monlinepvpar; return;  end


% execute callback function then return; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(varargin{1}) & ~isempty(findstr(varargin{1},'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return;
end


hMain = [];


% PREPARE DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% called like monlinepvpar(SIG) by monline
ONLINE = varargin{1};
for N = 2:2:length(varargin),
  switch lower(varargin{N}),
   case {'hfig','figure','hmain'}
    hMain = varargin{N+1};
  end
end


if ishandle(hMain),  figure(hMain);  return;  end


% GET SCREEN SIZE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[scrW scrH] = subGetScreenSize('char');
% keep the figure size smaller than XGA (1024x768) for notebook PC.
% figWH: [185 57]chars = [925 741]pixels
figW = 162; figH = 35;
figX = max(min(63,scrW-figW),10);
figY = scrH-figH-9.7;


% SET WINDOW TITLE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmptitle = sprintf('%s:  %s  %d/%d  %s',...
                   mfilename,ONLINE.session,ONLINE.scanreco(1),ONLINE.scanreco(2),...
                   datestr(now));

FontSize = 9;

% CREATE A MAIN FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(hMain),
  figure(hMain);
else
  hMain = figure;
end
set(hMain,...
    'Name',tmptitle,...
    'NumberTitle','off', 'toolbar','figure',...
    'Tag','main', 'units','char', 'pos',[figX figY figW figH],...
    'HandleVisibility','on', 'Resize','on',...
    'DoubleBuffer','on', 'BackingStore','on', 'Visible','on',...
    'DefaultAxesFontSize',FontSize,...
    'DefaultAxesfontweight','bold',...
    'PaperPositionMode','auto', 'PaperType','A4', 'PaperOrientation', 'landscape');

tmptxt = sprintf('%s  %d/%d  ''%s''',...
                 ONLINE.session,ONLINE.scanreco(1),ONLINE.scanreco(2),ONLINE.imgfile);
InfoTxt =  uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[3 figH-2 150 1.5],...
    'String',tmptxt,'FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','InfoTxt',...
    'BackgroundColor',get(hMain,'Color'));


AcqpTxt =  uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[3 figH-3.5 30 1.5],...
    'String','ACQP:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','AcqpTxt',...
    'BackgroundColor',get(hMain,'Color'));
AcqpList = uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','char','Position',[3 1 50 figH-4.2],...
    'String',subGetPvString(ONLINE.pvpar.acqp),...
    'HorizontalAlignment','left',...
    'FontSize',FontSize,...
    'Tag','AcqpList','Background','white');

if isfield(ONLINE.pvpar,'method') & ~isempty(ONLINE.pvpar.method),
  MethodTxt =  uicontrol(...
      'Parent',hMain,'Style','Text',...
      'Units','char','Position',[56 figH-3.5 30 1.5],...
      'String','METHOD:','FontWeight','bold',...
      'HorizontalAlignment','left',...
      'Tag','MethodTxt',...
      'BackgroundColor',get(hMain,'Color'));
  MethodList = uicontrol(...
      'Parent',hMain,'Style','Listbox',...
      'Units','char','Position',[56 1 50 figH-4.2],...
      'String',subGetPvString(ONLINE.pvpar.method),...
      'HorizontalAlignment','left',...
      'FontSize',FontSize,...
      'Tag','MethodList','Background','white');
else
  ImndTxt =  uicontrol(...
      'Parent',hMain,'Style','Text',...
      'Units','char','Position',[56 figH-3.5 30 1.5],...
      'String','IMND:','FontWeight','bold',...
      'HorizontalAlignment','left',...
      'Tag','ImndTxt',...
      'BackgroundColor',get(hMain,'Color'));
  ImndList = uicontrol(...
      'Parent',hMain,'Style','Listbox',...
      'Units','char','Position',[56 1 50 figH-4.2],...
      'String',subGetPvString(ONLINE.pvpar.imnd),...
      'HorizontalAlignment','left',...
      'FontSize',FontSize,...
      'Tag','ImndList','Background','white');
end



RecoTxt =  uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[109 figH-3.5 30 1.5],...
    'String','RECO:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','RecoTxt',...
    'BackgroundColor',get(hMain,'Color'));
RecoList = uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','char','Position',[109 1 50 figH-4.2],...
    'String',subGetPvString(ONLINE.pvpar.reco),...
    'HorizontalAlignment','left',...
    'FontSize',FontSize,...
    'Tag','RecoList','Background','white');



% get widgets handles at this moment
HANDLES = findobj(hMain);
% NOW SET "UNITS" OF ALL WIDGETS AS "NORMALIZED".
HANDLES = HANDLES(find(HANDLES ~= hMain));
set(HANDLES,'units','normalized');


% RETURNS THE WINDOW HANDLE IF REQUIRED.
if nargout,
  varargout{1} = hMain;
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Main_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(hObject);

switch lower(eventdata),
end

return

  
  


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION to get screen size
function [scrW, scrH] = subGetScreenSize(Units)
oldUnits = get(0,'Units');
set(0,'Units',Units);
sz = get(0,'ScreenSize');
set(0,'Units',oldUnits);

scrW = sz(3);  scrH = sz(4);

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION to convert numbers to strings
function STR = subGetPvString(par)

STR = {};
fnames = fieldnames(par);
for N = 1:length(fnames),
  STR{end+1} = sprintf('%s: %s',fnames{N},sub2string(par.(fnames{N})));
end

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION to convert data into a string
function STR = sub2string(val)

STR = '';
if isempty(val),  return;  end
if ischar(val),
  STR = val;
elseif isnumeric(val),
  if isvector(val) & length(val) > 1,
    STR = sprintf('[%s]',deblank(sprintf('%g ',val)));
  else
    try,
      STR = num2str(val);
    catch
      STR = 'ERROR: old matlab';
    end
  end
elseif iscell(val),
  STR = sprintf('{%s}',sub2string(val{1}));
  for N = 1:length(val),
    STR = strcat(STR,sprintf(' {%s}',sub2string(val{N})));
  end
end

STR = deblank(STR);

return
