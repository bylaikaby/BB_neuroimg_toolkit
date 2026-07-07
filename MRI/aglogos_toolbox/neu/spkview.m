function varargout = spkview(varargin)
%SPKVIEW - Displays neural signals of spikes (Spkt)
%  SPKVIEW(SESSION,GRPNAME/EXPNO,SigName)
%  SPKVIEW(Sig)  displays "Sig".
%
%  EXAMPLE :
%    spkview('d04nm1',1);
%    spkview(Spkt);
%
%  NOTES :
% 
%
%  VERSION :
%    0.90 04.07.06 YM   pre-release.
%
%  See also SIGLOAD SETBACK SETFRONT GETSTIMINDICES NVIEW

if nargin == 0,  help spkview; return;  end

% execute callback function then return; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(varargin{1}) & ~isempty(findstr(varargin{1},'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return;
end


% DEFAULT CONTROL SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ANAP.spkview.viewmode  = 'channel';
%ANAP.spkview.viewpage  = 1;
ANAP.spkview.trial     = 1;
ANAP.spkview.band      = 1;



% PREPARE DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NEUSIG = {};


% called like spkview(blp),
if isstruct(varargin{1}) & isfield(varargin{1},'session') & isfield(varargin{1},'dat'),
  varargin{1} = { varargin{1} };
end
if isempty(NEUSIG) & iscell(varargin{1}),
  NEUSIG = varargin{1};
  if iscell(NEUSIG),
    Ses = goto(NEUSIG{1}.session);
    grp = getgrp(Ses,NEUSIG{1}.ExpNo(1));
  else
    Ses = goto(NEUSIG.session);
    grp = getgrp(Ses,NEUSIG.ExpNo(1));
  end
  anap = getanap(Ses,grp);
end

% called like spkview('demo')
if isempty(NEUSIG) & ischar(varargin{1}) & strcmpi(varargin{1},'demo'),
  varargout = spkview('d04nm1',1);
  return;
end

% called like spkview(Ses,grp/expno,[SigName])
if isempty(NEUSIG),
  Ses = goto(varargin{1});
  grp = getgrp(Ses,varargin{2});
  anap = getanap(Ses,grp);
  if nargin >= 3,
    SIGNAME = varargin{3};
  else
    if isfield(anap,'gettrial') & anap.gettrial.status > 0,
      SIGNAME = 'tSpkt';
    else
      SIGNAME = 'Spkt';
    end
  end
  NEUSIG = sigload(Ses,varargin{2},SIGNAME);
end


% To make compatible with tblp, make blp as a cell array of cell array.
if ~iscell(NEUSIG),  NEUSIG = { NEUSIG };  end


if isempty(NEUSIG),
  fprintf('\n%s ERROR: no way to get ''%s''.\n',mfilename,SIGNAME);
  return;
end

if isfield(NEUSIG{1}.dir,'dname') & ~isempty(NEUSIG{1}.dir.dname),
  SIGNAME = NEUSIG{1}.dir.dname;
else
  SIGNAME = 'unknown';
end


% OVERWRITE DEFAULT SETTING BY ANAP
if isfield(anap,'spkview'),   ANAP.spkview = sctmerge(ANAP.spkview,anap.spkview);  end



% GET SCREEN SIZE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[scrW scrH] = subGetScreenSize('char');

%figW = 175; figH = 55;
figW = 185; figH = 57;
figX = 31;  figY = scrH-figH-5;

%[figX figY figW figH]

tmptitle = sprintf('%s: SES=''%s'' GRP=''%s''',mfilename,NEUSIG{1}.session,NEUSIG{1}.grpname);
if length(NEUSIG{1}.ExpNo) == 1,
  tmptitle = sprintf('%s ExpNo=%d',tmptitle,NEUSIG{1}.ExpNo);
else
  tmptitle = sprintf('%s NumExps=%d',tmptitle,length(NEUSIG{1}.ExpNo));
end


% CREATE A MAIN FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hMain = figure(...
    'Name',tmptitle,...
    'NumberTitle','off', 'toolbar','figure',...
    'Tag','main', 'units','char', 'pos',[figX figY figW figH],...
    'HandleVisibility','on', 'Resize','on',...
    'DoubleBuffer','on', 'BackingStore','on', 'Visible','on',...
    'DefaultAxesFontSize',10,...
    'DefaultAxesFontName', 'Comic Sans MS',...
    'DefaultAxesfontweight','bold',...
    'PaperPositionMode','auto', 'PaperType','A4', 'PaperOrientation', 'landscape');



% WIDGETS TO SELECT SIG %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XDSP = 10; H = figH - 2.5;
SigTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H-0.3 30 1.5],...
    'String','SIG:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','RoiTxt',...
    'BackgroundColor',get(hMain,'Color'));
signames = { SIGNAME };
SigCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+10 H 25 1.5],...
    'Callback','spkview(''Main_Callback'',gcbo,''select-sig'',guidata(gcbo))',...
    'String',signames,'Value',1,'Tag','SigCmb',...
    'HorizontalAlignment','left',...
    'TooltipString','Select SIG to plot',...
    'FontWeight','Bold');
clear signames;

% BAND SELECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bands = {};
if isfield(NEUSIG{1},'info') & isfield(NEUSIG{1}.info,'band'),
  for N = 1:length(NEUSIG{1}.info.band),
    bands{N} = sprintf('%s: %d-%d',NEUSIG{1}.info.band{N}{2},NEUSIG{1}.info.band{N}{1});
  end
  bands{end+1} = 'ALL';
elseif isfield(NEUSIG{1},'range'),
  bands{1} = sprintf('%d-%d',NEUSIG{1}.range);
else
  bands{1} = 'unknown';
end
tmpband = ANAP.spkview.band;
if tmpband < 1 | tmpband > length(bands),
  fprintf('WARNING %s: band is out of range ''%d''.\n',mfilename,tmpband);
  tmpband = 1;
end
BandTxt =  uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+70 H-0.3 30 1.5],...
    'String','Band:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','BandTxt',...
    'BackgroundColor',get(hMain,'Color'));
BandCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+80 H 34 1.5],...
    'Callback','spkview(''Main_Callback'',gcbo,''redraw'',guidata(gcbo))',...
    'String',bands,'Value',tmpband,'Tag','BandCmb',...
    'HorizontalAlignment','left',...
    'TooltipString','Select Trial to plot',...
    'FontWeight','Bold');
clear bands tmpband;

% INFORMATION TEXT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = figH - 7;
InfoTxt = uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','char','Position',[XDSP+125 H 35 6],...
    'String',{'session','group','datsize','dx'},...
    'HorizontalAlignment','left',...
    'FontName','Comic Sans MS','FontSize',9,...
    'Tag','InfoTxt','Background','white');

% VIEW MODE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XDSP = 10; H = figH - 4.5;
ViewModeTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H-0.3 30 1.5],...
    'String','View:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','ViewModeTxt',...
    'BackgroundColor',get(hMain,'Color'));
ViewModeCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+10 H 25 1.5],...
    'Callback','spkview(''Main_Callback'',gcbo,''view-mode'',guidata(gcbo))',...
    'String',{'channel','repeat'},...
    'Tag','ViewModeCmb','Value',1,...
    'TooltipString','Select the view mode',...
    'FontWeight','bold','Background','white');
% ViewModeCmb = uicontrol(...
%     'Parent',hMain,'Style','Popupmenu',...
%     'Units','char','Position',[XDSP+10 H 25 1.5],...
%     'Callback','spkview(''Main_Callback'',gcbo,''view-mode'',guidata(gcbo))',...
%     'String',{'channel','tile'},...
%     'Tag','ViewModeCmb','Value',1,...
%     'TooltipString','Select the view mode',...
%     'FontWeight','bold','Background','white');
ViewPageCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+40 H 25 1.5],...
    'String',{'page1','page2','page3','page4'},...
    'Callback','spkview(''Main_Callback'',gcbo,''view-page'',guidata(gcbo))',...
    'HorizontalAlignment','left',...
    'Tag','ViewPageCmb','Value',1,...
    'TooltipString','Select a page to plot',...
    'FontWeight','bold','Background','white');


% TRIAL SELECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
trials = {};
for N = 1:length(NEUSIG),
  if isfield(NEUSIG{N}.stm,'labels') & ~isempty(NEUSIG{N}.stm.labels),
    trials{end+1} = sprintf('%d: %s',N,NEUSIG{N}.stm.labels{1});
  else
    trials{end+1} = sprintf('%d',N);
  end
end
if length(NEUSIG) > 1,  trials{end+1} = 'ALL';  end
tmptrial = ANAP.spkview.trial;
if tmptrial < 1 | tmptrial > length(trials),
  fprintf('WARNING %s: trial is out of range ''%d''.\n',mfilename,tmptrial);
  tmptrial = 1;
end
TrialTxt =  uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+70 H-0.3 30 1.5],...
    'String','Trial:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','TrialTxt',...
    'BackgroundColor',get(hMain,'Color'));
TrialCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+80 H 34 1.5],...
    'Callback','spkview(''Main_Callback'',gcbo,''redraw'',guidata(gcbo))',...
    'String',trials,'Value',tmptrial,'Tag','TrialCmb',...
    'HorizontalAlignment','left',...
    'TooltipString','Select Trial to plot',...
    'FontWeight','Bold');
clear trials tmptrial;


% ENTRY TWIN - Enter the time window.
XDSP = 10; H = figH - 6.5;
XDSP = 10; H = figH - 6.5;
PlotTwinTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H-0.3 30 1.5],...
    'String','Twin:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','PlotTwinTxt');
PlotTwinEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+10 H 12 1.5],...
    'String','2.000','FontWeight','bold',...
    'Callback','spkview(''Main_Callback'',gcbo,''t-window'',[])',...
    'Tag','PlotTwinEdt');


% Hold-on check %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XDSP = 10; H = figH - 6.5;
TCHoldCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+80 H 20 1.5],...
    'Tag','TCHoldCheck','Value',0,...
    'String','Hold On','FontWeight','bold',...
    'TooltipString','map on/off','BackgroundColor',get(hMain,'Color'));
set(TCHoldCheck,'visible','off');




% AXES for plots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% AXES FOR WHOLE/ZOOMED-VIEW %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XDSP=15;  XSZ = 155;
H = 39; YSZ = 10;
OverViewAxs = axes(...
    'Parent',hMain,'Tag','OverViewAxs',...
    'Units','char','Position',[XDSP H XSZ YSZ],...
    'Box','off','color','black','Visible','on','FontWeight','bold');
% SLIDER - Time bar for magnified view.
TimeBarSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[XDSP-3 H-4 XSZ+6 1.5],...
    'Callback','spkview(''Main_Callback'',gcbo,''t-slider'',[])',...
    'Tag','TimeBarSldr','SliderStep',[0.1 0.2],...
    'TooltipString','Time Points');
H = 4; YSZ = 30;
ZoomViewAxs = axes(...
    'Parent',hMain,'Tag','ZoomViewAxs',...
    'Units','char','Position',[XDSP H XSZ YSZ],...
    'Box','off','Visible','on','FontWeight','bold');






% get widgets handles at this moment
HANDLES = findobj(hMain);


% INITIALIZE THE APPLICATION
setappdata(hMain,'NEUSIG',NEUSIG);
setappdata(hMain,'ANAP',ANAP);
%setappdata(hMain,'COLORS','rgbcmyk');
setappdata(hMain,'COLORS',lines(7));
Main_Callback(OverViewAxs,'init');
set(hMain,'visible','on');



% NOW SET "UNITS" OF ALL WIDGETS AS "NORMALIZED".
HANDLES = HANDLES(find(HANDLES ~= hMain));
set(HANDLES,'units','normalized');



Main_Callback(OverViewAxs,'redraw',[]);


% RETURNS THE WINDOW HANDLE IF REQUIRED.
if nargout,
  varargout{1} = hMain;
end

return;





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Main_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(hObject);
NEUSIG = getappdata(wgts.main,'NEUSIG');

switch lower(eventdata),
 case {'init'}
  inftxt = {};
  inftxt{end+1} = sprintf('%s, %s',NEUSIG{1}.session,NEUSIG{1}.grpname);
  inftxt{end+1} = sprintf('ExpNo= %s',deblank(sprintf('%d ',NEUSIG{1}.ExpNo)));
  inftxt{end+1} = sprintf('dt= %fms',NEUSIG{1}.dt(1)*1000);
  %inftxt{end+1} = sprintf('dat= [%s]',deblank(sprintf('%d ',size(NEUSIG{1}.dat))));
  %inftxt{end+1} = sprintf('dx= %f',NEUSIG{1}.dx(1));
  set(wgts.InfoTxt,'String',inftxt);

  
  twin = str2num(get(wgts.PlotTwinEdt,'String'));
  if size(NEUSIG{1}.dat,1)*NEUSIG{1}.dx < twin,
    twin = round(size(NEUSIG{1}.dat,1)*NEUSIG{1}.dx/0.1)*0.1;
    set(wgts.PlotTwinEdt,'String',sprintf('%.3f',twin));
  end
  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  if strcmpi(ViewMode,'channel'),
    ExpView_Callback(hObject,'init',[]);
  else
    RepeatView_Callback(hObject,'init',[]);
  end
 
 case {'view-mode'}
  set(wgts.TCHoldCheck,'Value',0);
  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  if strcmpi(ViewMode,'channel'),
    ExpView_Callback(hObject,'init',[]);
  else
    RepeatView_Callback(hObject,'init',[]);
  end
  Main_Callback(hObject,'redraw',[]);
 
 case {'select-sig'}

 case {'view-page','redraw'}
  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  if strcmpi(ViewMode,'channel'),
    ExpView_Callback(hObject,'redraw',[]);
  else
    RepeatView_Callback(hObject,'redraw',[]);
  end

 case {'t-window'}
  TWIN = str2num(get(wgts.PlotTwinEdt,'String'));
  if isempty(TWIN),
    set(wgts.PlotTwinEdt,'String','2.000');
  end
  Main_Callback(hObject,'t-slider',[]);  
  
 case {'t-slider'}
  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  if strcmpi(ViewMode,'channel'),
    ExpView_Callback(hObject,'t-slider',[]);
  else
    RepeatView_Callback(hObject,'t-slider',[]);
  end
  
 case {'zoom-in'}
%   ViewMode = get(wgts.ViewModeCmb,'String');
%   ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
%   if strcmpi(ViewMode,'channel'),
%     ExpView_Callback(hObject,'zoom-in',[]);
%   else
%     RepeatView_Callback(hObject,'zoom-in',[]);
%   end
  subNewWindow(hObject,NEUSIG);
  
 otherwise
  fprintf('WARNING %s: Main_Callback() ''%s'' not supported yet.\n',mfilename,eventdata);
end
  
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ExpView_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(hObject);
NEUSIG = getappdata(wgts.main,'NEUSIG');
switch lower(eventdata)
 case {'init'}
  pagestr = {};
  for N = 1:size(NEUSIG{1}.times,2),
    if size(NEUSIG{1}.times,2) == length(NEUSIG{1}.ExpNo) & length(NEUSIG{1}.ExpNo) > 1,
      pagestr{N} = sprintf('exp %d',NEUSIG{1}.ExpNo(N));
    else
      pagestr{N} = sprintf('rep %d',N);
    end
  end
  set(wgts.ViewPageCmb,'String',pagestr,'Value',1);
  
 case {'view-mode'}
  ExpView_Callback(hObject,'init',[]);
  ExpView_Callback(hObject,'redraw',[]);
 
 case {'view-page','redraw'}
  COLORS  = getappdata(wgts.main,'COLORS');
  pagestr = get(wgts.ViewPageCmb,'String');
  pageval = get(wgts.ViewPageCmb,'Value');
  iExp    = pageval;
  TrialNo  = get(wgts.TrialCmb,'String');  TrialNo  = TrialNo{get(wgts.TrialCmb,'Value')};
  if strcmpi(TrialNo,'all'),
    TrialNo = 1:length(NEUSIG);
  else
    TrialNo = sscanf(TrialNo,'%d:');
    TrialNo = TrialNo(1);
  end
  haxs = wgts.OverViewAxs;
  subPlotOverView(wgts,haxs,COLORS,NEUSIG,iExp,-1,TrialNo);
  haxs = wgts.ZoomViewAxs;
  subPlotZoomView(wgts,haxs,COLORS,NEUSIG,iExp,-1,TrialNo);
  
 case {'t-slider'}
  COLORS  = getappdata(wgts.main,'COLORS');
  pagestr = get(wgts.ViewPageCmb,'String');
  pageval = get(wgts.ViewPageCmb,'Value');
  iExp    = pageval;
  TrialNo  = get(wgts.TrialCmb,'String');  TrialNo  = TrialNo{get(wgts.TrialCmb,'Value')};
  if strcmpi(TrialNo,'all'),
    TrialNo = 1:length(NEUSIG);
  else
    TrialNo = sscanf(TrialNo,'%d:');
    TrialNo = TrialNo(1);
  end
  haxs = wgts.ZoomViewAxs;
  subPlotZoomView(wgts,haxs,COLORS,NEUSIG,iExp,-1,TrialNo);

  
 case {'zoom-in'}
  fprintf('write codes here\n');
  
 otherwise
  fprintf('WARNING %s: ExpView_Callback() ''%s'' not supported yet.\n',mfilename,eventdata);
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function RepeatView_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(hObject);
NEUSIG = getappdata(wgts.main,'NEUSIG');
switch lower(eventdata)
 case {'init'}
  pagestr = {};
  for N = 1:length(NEUSIG{1}.chan),
    pagestr{N} = sprintf('ch%d (ele%d)',N,NEUSIG{1}.chan(N));
  end
  set(wgts.ViewPageCmb,'String',pagestr,'Value',1);
  
 case {'view-mode'}
  RepeatView_Callback(hObject,'init',[]);
  RepeatView_Callback(hObject,'redraw',[]);
 
 case {'view-page','redraw'}
  COLORS  = getappdata(wgts.main,'COLORS');
  pagestr = get(wgts.ViewPageCmb,'String');
  pageval = get(wgts.ViewPageCmb,'Value');
  iCh     = pageval;
  TrialNo  = get(wgts.TrialCmb,'String');  TrialNo  = TrialNo{get(wgts.TrialCmb,'Value')};
  if strcmpi(TrialNo,'all'),
    TrialNo = 1:length(NEUSIG);
  else
    TrialNo = sscanf(TrialNo,'%d:');
    TrialNo = TrialNo(1);
  end
  haxs = wgts.OverViewAxs;
  subPlotOverView(wgts,haxs,COLORS,NEUSIG,-1,iCh,TrialNo);
  haxs = wgts.ZoomViewAxs;
  subPlotZoomView(wgts,haxs,COLORS,NEUSIG,-1,iCh,TrialNo);
  
 case {'t-slider'}
  COLORS  = getappdata(wgts.main,'COLORS');
  pagestr = get(wgts.ViewPageCmb,'String');
  pageval = get(wgts.ViewPageCmb,'Value');
  iCh     = pageval;
  TrialNo  = get(wgts.TrialCmb,'String');  TrialNo  = TrialNo{get(wgts.TrialCmb,'Value')};
  if strcmpi(TrialNo,'all'),
    TrialNo = 1:length(NEUSIG);
  else
    TrialNo = sscanf(TrialNo,'%d:');
    TrialNo = TrialNo(1);
  end
  haxs = wgts.ZoomViewAxs;
  subPlotZoomView(wgts,haxs,COLORS,NEUSIG,-1,iCh,TrialNo);
  
 case {'zoom-in'}
  fprintf('write codes here\n');
  
 otherwise
  fprintf('WARNING %s: RepeatView_Callback() ''%s'' not supported yet.\n',mfilename,eventdata);
end

return;






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to draw channel-view data
function subPlotOverView(wgts,haxs,COLORS,NEUSIG,iExp,iChan,TrialNo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

POS = get(haxs,'pos');
TAG = get(haxs,'tag');
if get(wgts.TCHoldCheck,'Value') == 0,
  % cla;
  delete(allchild(haxs));
  set(haxs,'UserData',[]);
end
  
hDATA = get(haxs,'UserData');
spkimg = [];  spkusr = '';
if ~isempty(hDATA),
  spkimg = get(hDATA(1),'cdata');
  spkusr = get(hDATA(1),'UserData');
end

axes(haxs);
for iTrial = 1:length(TrialNo),
  T = TrialNo(iTrial);
  if iExp > 0,
    if size(NEUSIG{T}.dat,3) > 1,
      spkdat = NEUSIG{T}.dat(:,:,iExp);
    else
      spkdat = NEUSIG{T}.dat(:,:);
    end
  else
    spkdat = squeeze(NEUSIG{T}.dat(:,iChan,:));
  end
  if isempty(spkimg),
    spkimg = spkdat / length(TrialNo);
  else
    idx = 1:size(spkdat,1);
    if size(spkdat,1) > size(spkimg,1),
      spkimg(end+1:size(spkdat,1),:) = 0;
    end
    spkimg(idx,:) = spkimg(idx,:) + spkdat / length(TrialNo);
  end
  
  tmpt = [0:size(NEUSIG{T}.dat,1)-1]*NEUSIG{T}.dx(1);
  tmpcol = COLORS(mod(length(hDATA),size(COLORS,1))+1,:);
  tmptxt = sprintf('Trial=%s',NEUSIG{T}.stm.labels{1});
  spkusr = sprintf('%s %s',spkusr,tmptxt);
end

tmpt = [0:size(spkimg)-1]*NEUSIG{1}.dx(1);
if ~isempty(hDATA),
  set(hDATA,'cdata',spkimg','xdata',tmpt,'UserData',spkusr);
else
  hDATA = imagesc(tmpt,1:size(spkimg,2),spkimg');
  set(hDATA,'UserData',spkusr);
end
set(haxs,'ylim',[0.5 size(spkimg,2)+0.5]);
set(haxs,'UserData',hDATA);
grid on;

% update slieder's step
TWIN = str2num(get(wgts.PlotTwinEdt,'String'));
sstep = [TWIN/max(tmpt)/4, min([1.01 TWIN/max(tmpt)*5])];
set(wgts.TimeBarSldr,'min',0,'max',max(tmpt),'SliderStep',sstep);

% update slider-position
% current time point
T = get(wgts.TimeBarSldr,'Value');
% set slider position
set(wgts.TimeBarSldr,'Value',min([T max(tmpt)-0.1]));


if get(wgts.TCHoldCheck,'Value') == 0,
  set(haxs,'xlim',[min(tmpt),max(tmpt)],'Tag','OverViewAxs');
  xlabel('Time in seconds');
  if iExp > 0,
    ylabel('Channels');
  else
    ylabel('Experiments');
  end
  set(haxs,'layer','top');
  set(haxs,...
      'ButtonDownFcn','spkview(''Main_Callback'',gcbo,''zoom-in'',guidata(gcbo))');
  subDrawStimIndicators(haxs,NEUSIG,TrialNo,1,'w');
else
  delete(findobj(haxs,'type','text','tag','Nvox'));
  %delete(findobj(haxs,'type','text'));
  subDrawStimIndicators(haxs,NEUSIG,TrialNo,0);
  legtxt = {};
  for N = 1:length(hDATA),
    legtxt{N} = get(hDATA(N),'UserData');
  end
  h = legend(haxs,legtxt);
  setfront(h);
  if get(wgts.LegendCheck,'value') == 0,
    set(h,'visible','off');
  end
end
  
set(allchild(haxs),...
    'ButtonDownFcn','spkview(''Main_Callback'',gcbo,''zoom-in'',guidata(gcbo))');



set(haxs,'POS',POS,'tag',TAG);

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to draw zoomed data
function subPlotZoomView(wgts,haxs,COLORS,NEUSIG,iExp,iChan,TrialNo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TWIN = str2num(get(wgts.PlotTwinEdt,'String'));
T0 = get(wgts.TimeBarSldr,'Value');

POS = get(haxs,'pos');
TAG = get(haxs,'tag');

tmpt = [T0,T0 + TWIN];

delete(allchild(haxs));
set(haxs,'UserData',[]);
hDATA = [];
spkusr = '';
%spkimg = zeros(size(NEUSIG{1}.dat,2),round(TWIN*1000),3);

axes(haxs);
for iTrial = 1:length(TrialNo),
  T = TrialNo(iTrial);
  %tmpcol = COLORS(mod(length(hDATA),length(COLORS))+1,:);
  tmpcol = COLORS(mod(length(TrialNo),size(COLORS,1))+1,:);
  tmpcol = reshape(tmpcol,[1 1 3]);
  if iExp > 0,
    for N = 1:length(NEUSIG{T}.chan),
      spkt = NEUSIG{T}.times{N,iExp}*NEUSIG{T}.dt;
      spkt = spkt(find(spkt >= T0 & spkt < T0+TWIN));
      if isempty(spkt), continue;  end
      tmpx = [spkt(:)';spkt(:)'];
      tmpy = repmat([N-0.5 N+0.5]',[1,length(spkt)]);
      line(tmpx,tmpy,'color',tmpcol,'linewidth',1.5);
      hold on;
    end
  else
    szy = min(size(NEUSIG{T}.times,2),500);
    for N = 1:szy,
      spkt = NEUSIG{T}.times{iChan,N}*NEUSIG{T}.dt;
      spkt = spkt(find(spkt >= T0 & spkt < T0+TWIN));
      if isempty(spkt), continue;  end
      tmpx = [spkt(:)';spkt(:)'];
      tmpy = repmat([N-0.5 N+0.5]',[1,length(spkt)]);
      line(tmpx,tmpy,'color',tmpcol,'linewidth',1.5);
      hold on;
    end
  end
  tmptxt = sprintf('Trial=%s',NEUSIG{T}.stm.labels{1});
end

if iExp > 0,
  szy = length(NEUSIG{1}.chan);
else
  szy = min(size(NEUSIG{T}.times,2),500);
  if size(NEUSIG{T}.times,2) > 500,
    fprintf(' %s: nrepeats(%d) limited to %d. \n',mfilename,size(NEUSIG{T}.times,2),szy);
  end
end
set(haxs,'ylim',[0.5 szy+0.5],'ydir','reverse','layer','top');

set(haxs,'UserData',hDATA);
grid on;

% update slieder indicator
h = findobj(wgts.OverViewAxs,'tag','twin');
tmppos = [T0 0.5 TWIN szy];
if isempty(h),
  axes(wgts.OverViewAxs);
  h = rectangle('pos',tmppos,'tag','twin',...
                'facecolor','none','edgecolor',[1.0 0 0]);
  %setfront(h);
  axes(haxs);
else
  set(h(1),'pos',tmppos);
end


% if get(wgts.TCHoldCheck,'Value') == 0, niko
if (get(wgts.TCHoldCheck,'Value') == 0) % niko
  set(haxs,'xlim',[min(tmpt),max(tmpt)],'Tag','ZoomViewAxs'); % niko
  % set(haxs,'xlim',[200,600],'Tag','ZoomViewAxs'); niko
  xlabel('Time in seconds');
  if iExp > 0,
    ylabel('Channels');
  else
    ylabel('Repeats');
  end
  set(haxs,'layer','top');
  set(haxs,...
      'ButtonDownFcn','spkview(''Main_Callback'',gcbo,''zoom-in'',guidata(gcbo))');
  subDrawStimIndicators(haxs,NEUSIG,TrialNo,1);
else
  delete(findobj(haxs,'type','text','tag','Nvox'));
  %delete(findobj(haxs,'type','text'));
  subDrawStimIndicators(haxs,NEUSIG,TrialNo,0);
  legtxt = {};
  for N = 1:length(hDATA),
    legtxt{N} = get(hDATA(N),'UserData');
  end
  h = legend(haxs,legtxt);
  setfront(h);
  if get(wgts.LegendCheck,'value') == 0,
    set(h,'visible','off');
  end
end
  
set(allchild(haxs),...
    'ButtonDownFcn','spkview(''Main_Callback'',gcbo,''zoom-in'',guidata(gcbo))');



set(haxs,'POS',POS,'tag',TAG);

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to draw stimulus indicators
function subDrawStimIndicators(haxs,NEUSIG,TrialNo,DRAW_OBJ,LINECOLOR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('LINECOLOR','var'), LINECOLOR = 'k';  end

axes(haxs);
if DRAW_OBJ > 0,
  % draw stimulus indicators
  ylm   = get(haxs,'ylim');  tmph = ylm(2)-ylm(1);
  drawL = [];  drawR = [];
  for iTrial = 1:length(TrialNo),
    T = TrialNo(iTrial);
    if isfield(NEUSIG{T},'stm') & ~isempty(NEUSIG{T}.stm),
      stimv = NEUSIG{T}.stm.v{1};
      stimt = NEUSIG{T}.stm.time{1};  stimt(end+1) = sum(NEUSIG{T}.stm.dt{1});
      stimdt = NEUSIG{T}.stm.dt{1};
      for N = 1:length(stimv),
        if any(strcmpi(NEUSIG{T}.stm.stmpars.StimTypes{stimv(N)+1},{'blank','none','nostim'})),
          continue;
        end
        if stimt(N) == stimt(N+1),
          tmpw = stimdt(N);
        else
          tmpw = stimt(N+1) - stimt(N);
        end
        if ~any(drawL == stimt(N)),
          line([stimt(N), stimt(N)],ylm,'color',LINECOLOR,'tag','stim-line');
          drawL(end+1) = stimt(N);
        end
        if isempty(drawR) | ~any(drawR(:,1) == stimt(N) & drawR(:,2) == tmpw),
          rectangle('Position',[stimt(N) ylm(1) tmpw tmph],...
                    'facecolor',[0.88 0.88 0.88],'linestyle','none',...
                    'tag','stim-rect');
          drawR(end+1,1) = stimt(N);
          drawR(end  ,2) = tmpw;
        end
        if ~any(drawL == stimt(N)+tmpw),
          line([stimt(N),stimt(N)]+tmpw,ylm,'color',LINECOLOR,'tag','stim-line');
          drawL(end+1) = stimt(N)+tmpw;
        end
      end
    end
  end
else
  ylm   = get(haxs,'ylim');  tmph = ylm(2)-ylm(1);
  for iTrial = 1:length(TrialNo),
    T = TrialNo(iTrial);
    if isfield(NEUSIG{T},'stm') & ~isempty(NEUSIG{T}.stm),
      stimv = NEUSIG{T}.stm.v{1};
      stimt = NEUSIG{T}.stm.time{1};  stimt(end+1) = sum(NEUSIG{T}.stm.dt{1});
      stimdt = NEUSIG{T}.stm.dt{1};
      for N = 1:length(stimv),
        if any(strcmpi(NEUSIG{T}.stm.stmpars.StimTypes{stimv(N)+1},{'blank','none','nostim'})),
          continue;
        end
        if stimt(N) == stimt(N+1),
          tmpw = stimdt(N);
        else
          tmpw = stimt(N+1) - stimt(N);
        end
        % elongate rectangle
        hrect = findobj(gca,'tag','stim-rect');
        h = [];
        for K = 1:length(hrect),
          pos = get(hrect(K),'pos');
          if pos(1) == stimt(N) & pos(3) < tmpw,
            h = hrect(K);  break;
          end
        end
        if isempty(h),
          rectangle('Position',[stimt(N) ylm(1) tmpw tmph],...
                    'facecolor',[0.88 0.88 0.88],'linestyle','none',...
                    'tag','stim-rect');
        else
          pos = get(h,'pos');
          pos(3) = tmpw;
          set(h,'pos',pos);
        end
        % draw a line if needed.
        hline = findobj(gca,'tag','stim-line');
        h = [];
        for K = 1:length(hline),
          pos = get(hline(K),'pos');
          if pos(1) == stimt(N),
            h = hline(N);  break;
          end
        end
        if isempty(h),
          line([stimt(N),stimt(N)]+tmpw,ylm,'color','k','tag','stim-line');
        end
      end
    end
  end
end

% adjust stimulus indicator size
set(allchild(haxs),'HandleVisibility','on');
ylm = get(haxs,'ylim');  tmph = ylm(2)-ylm(1);
h = findobj(haxs,'tag','stim-line');
set(h,'ydata',ylm);
h = findobj(haxs,'tag','stim-rect');
for N = 1:length(h),
  tmppos = get(h(N),'pos');
  tmppos(2) = ylm(1);  tmppos(4) = tmph;
  set(h(N),'pos',tmppos);
end

setfront(findobj(haxs,'tag','stim-line'));
setback(findobj(haxs,'tag','stim-rect'));
% set indicators' handles invisible to use legend() funciton.
set(findobj(haxs,'tag','stim-line'),'handlevisibility','off');
set(findobj(haxs,'tag','stim-rect'),'handlevisibility','off');

  

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to zoom-in plot (TIME COURSE)
function subZoomInTC(wgts,hsrc,NEUSIG)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

EleNo   = get(wgts.ViewPageCmb,'String');  EleNo   = EleNo{get(wgts.ViewPageCmb,'Value')};
TrialNo = get(wgts.TrialCmb,'String');     TrialNo = TrialNo{get(wgts.TrialCmb,'Value')};
BandNo  = get(wgts.BandCmb,'String');      BandNo  = BandNo{get(wgts.BandCmb,'Value')};


hfig = wgts.main + 2004;

tmpstr = sprintf('Neural Signal Time Course\n%s %s',NEUSIG{1}.session,NEUSIG{1}.grpname);
if length(NEUSIG{1}.ExpNo) > 1,
  tmpstr = sprintf('%s NumExps=%d',tmpstr,length(NEUSIG{1}.ExpNo));
else
  tmpstr = sprintf('%s ExpNo=%d',tmpstr,NEUSIG{1}.ExpNo);
end

if length(get(hsrc,'UserData')) > 1,
  % multiple plot with "hold-on"
else
  tmpstr = sprintf('%s %s %s',tmpstr,EleNo,BandNo);
end
if length(get(wgts.TrialCmb,'String')) > 1 & get(wgts.TCHoldCheck,'value') == 0,
  tmpstr = sprintf('%s Trial=%s',tmpstr,TrialNo);
end

if any(strcmpi(EleNo,{'all','average'})),
  tmpstr = sprintf('%s AvrChn=[%s]',tmpstr,get(wgts.AvrChanEdt,'string'));
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
if 0,
  haxs = axes;
  subCompCopy(hsrc,haxs);
else
  haxs = copyobj(hsrc,hfig);
  set(haxs,'pos',[0.1300    0.1100    0.7750    0.8150]);
  title(tmpstr);
  % FU__ING MATLAB(R14), copyobj() makes lines in legend all black. ----------
  erb = findobj(haxs,'tag','tcdat');
  for N = 1:length(erb),
    tmph = findobj(erb(N),'type','line');
    set(erb(N),'color',get(tmph(1),'color'));
  end
  %---------------------------------------------------------------------------
end

% if "hold-on" then put the legend
hDATA = get(hsrc,'UserData');
legtxt = {};
if length(hDATA) > 1,
  for N = 1:length(hDATA),
    legtxt{N} = get(hDATA(N),'UserData');
  end
  h = legend(haxs,legtxt);
  setfront(h);
end

%clear callbacks
set(haxs,'ButtonDownFcn','');  % clear callback function
%set(get(haxs,'Children'),'ButtonDownFcn','');
set(allchild(haxs),'ButtonDownFcn','');

% make font size bigger
set(haxs,'FontSize',10);
set(get(haxs,'title'),'FontSize',10);
set(get(haxs,'xlabel'),'FontSize',10);
set(get(haxs,'ylabel'),'FontSize',10);

% make line(s) thicker
set(findobj(haxs,'tag','tcdat'),'linewidth',2);


return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTOIN to make convolution
function DAT = subConvolveData(DAT,KDAT,DO_MIRROR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if iscell(DAT),
  for N = 1:length(DAT),
    DAT{N} = subConvolveData(DAT{N},KDAT,DO_MIRROR);
  end
  return;
end

KDAT = KDAT(:);

idx = find(isnan(DAT(:)));
DAT(idx) = 0;

if DO_MIRROR,
  klen = length(KDAT);
  idxmir = [klen+1:-1:2 1:size(DAT,1) size(DAT,1)-1:-1:size(DAT,1)-klen-1];
  idxsel = [1:size(DAT,1)] + klen;
  for N = 1:size(DAT,2),
    %tmp = conv(DAT(idxmir,N),KDAT);
    tmp = fconv(DAT(idxmir,N),KDAT);
    DAT(:,N) = tmp(idxsel);
  end
else
  sel = 1:size(DAT,1);
  for N = 1:size(DAT,2),
    %tmp = conv(DAT(:,N),KDAT);
    tmp = fconv(DAT(:,N),KDAT);
    DAT(:,N) = tmp(sel);
  end
end

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION to get screen size
function [scrW scrH] = subGetScreenSize(Units)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
oldUnits = get(0,'Units');
set(0,'Units',Units);
sz = get(0,'ScreenSize');
set(0,'Units',oldUnits);

scrW = sz(3);  scrH = sz(4);

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION to find legend handle, taken from legend.m
function leg = find_legend(ha)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parent = get(ha,'Parent');
ax = findobj(get(parent,'Children'),'flat','Type','axes','Tag','legend');
leg=[];
k=1;
while k<=length(ax) && isempty(leg)
  if islegend(ax(k))
    hax = handle(ax(k));
    if isequal(double(hax.axes),ha)
      leg=ax(k);
    end
  end
  k=k+1;
end
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION to find legend handle, taken from legend.m
function tf=islegend(ax)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if length(ax) ~= 1 || ~ishandle(ax)
  tf=false;
else
  tf=isa(handle(ax),'scribe.legend');
end
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to show plots in new window
function subNewWindow(hObject,NEUSIG)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

wgts = guihandles(get(hObject,'Parent'));
hfig = wgts.main + 1005;

tmptitle = sprintf('%s: SES=''%s'' GRP=''%s''',mfilename,NEUSIG{1}.session,NEUSIG{1}.grpname);
if length(NEUSIG{1}.ExpNo) == 1,
  tmptitle = sprintf('%s ExpNo=%d',tmptitle,NEUSIG{1}.ExpNo);
else
  tmptitle = sprintf('%s NumExps=%d',tmptitle,length(NEUSIG{1}.ExpNo));
end

figure(hfig);  clf;
pos = get(hfig,'pos');
pos = [pos(1)-(840-pos(3)) pos(2)-(900-pos(4)) 900 720];
figtitle(tmptitle,'FontSize',11,'FontWeight','bold');

[scrW scrH] = subGetScreenSize('pixels');
if pos(1) < -pos(3) | pos(1) > scrW,  pos(1) = 1;  end
if pos(2)+pos(4) < 0 | pos(2)+pos(4)+70 > scrH,  pos(2) = scrH-pos(4)-70;  end
set(hfig,'Name',tmptitle,'pos',pos);

hova = copyobj(wgts.OverViewAxs,hfig);
set(hova,'Position',[0.08 0.74 0.88 0.2]);

haxs = copyobj(wgts.ZoomViewAxs,hfig);
set(haxs,'Position',[0.08  0.07  0.88  0.60]);    

%clear callbacks
set(haxs,'ButtonDownFcn','');
set(allchild(haxs),'ButtonDownFcn','');
set(hova,'ButtonDownFcn','');
set(allchild(hova),'ButtonDownFcn','');

return;
