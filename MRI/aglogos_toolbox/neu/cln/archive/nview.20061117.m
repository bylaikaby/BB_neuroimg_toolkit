function varargout = nview(varargin)
%NVIEW - Displays neural signals
%  NVIEW(SESSION,GRPNAME/EXPNO,SigName)
%  NVIEW(Sig)  displays "Sig".
%
%  EXAMPLE :
%    nview('j04yz1','normo');
%    nview(blp);
%
%  NOTES :
%   Settings can be set by ANAP.nview like following.
%     ANAP.nview.viewmode  = 'single';
%     ANAP.nview.viewpage  = 1;
%     ANAP.nview.trial     = 1;
%     ANAP.nview.band      = 1;
%     ANAP.nview.averagech = [];
%     ANAP.nview.xlabel    = 'Time in seconds';
%     ANAP.nview.ylabel    = 'Amplitude SD Units';
%
%  VERSION :
%    0.90 04.03.06 YM   pre-release.
%    0.92 07.03.06 YM   supports "trials", "zoom-in".
%    0.93 20.03.06 YM   supports "MatrixView" mode.
%    0.94 23.03.06 YM   supports selected average, error-bar on/off.
%    0.95 15.11.06 YM   supports "ANAP.nvew" in the description file.
%
%  See also SIGLOAD SETBACK SETFRONT GETSTIMINDICES

if nargin == 0,  help nview; return;  end

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
ANAP.nview.viewmode  = 'single';
ANAP.nview.viewpage  = 1;
ANAP.nview.trial     = 1;
ANAP.nview.band      = 1;
ANAP.nview.averagech = [];
ANAP.nview.xlabel    = 'Time in seconds';
ANAP.nview.ylabel    = 'Amplitude SD Units';


% PREPARE DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NEUSIG = {};


% called like nview(blp),
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

% called like nview('demo')
if isempty(NEUSIG) & ischar(varargin{1}) & strcmpi(varargin{1},'demo'),
  varargout = nview('f01m91','polar1');
  return;
end

% called like nview(Ses,grp/expno,[SigName])
if isempty(NEUSIG),
  Ses = goto(varargin{1});
  grp = getgrp(Ses,varargin{2});
  anap = getanap(Ses,grp);
  if nargin >= 3,
    SIGNAME = varargin{3};
  else
    if isfield(anap,'gettrial') & anap.gettrial.status > 0,
      SIGNAME = 'tblp';
    else
      SIGNAME = 'blp';
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

% if blp/tblp, then set default band as MUA
if any(strcmpi(SIGNAME,{'blp','tblp'})),
  if isfield(NEUSIG{1},'info') & isfield(NEUSIG{1}.info,'band'),
    for N = 1:length(NEUSIG{1}.info.band),
      if strcmpi(NEUSIG{1}.info.band{N}{2},'MUA'),
        ANAP.nview.band = N;  break;
      end
    end
  end
end


% OVERWRITE DEFAULT SETTING BY ANAP
if isfield(anap,'nview'),   ANAP.nview = sctmerge(ANAP.nview,anap.nview);  end


% AVERAGE DATA IF IT IS GROUPED DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if length(NEUSIG{1}.ExpNo) > 1,
  if any(strcmpi(SIGNAME,{'blp','tblp','esblp'})),
    % blp.dat as (t,chan,band,exps)
    for N = 1:length(NEUSIG),
      tmpsz = size(NEUSIG{N}.dat);
      NEUSIG{N}.dat = reshape(mean(NEUSIG{N}.dat,4),tmpsz(1:3));
    end
  else
    % assuming .dat as (t,chan,exps)
    for N = 1:length(NEUSIG),
      tmpsz = size(NEUSIG{N}.dat);
      NEUSIG{N}.dat = reshape(mean(NEUSIG{N}.dat,3),tmpsz(1:2));
    end
  end
end



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
    'Callback','nview(''Main_Callback'',gcbo,''select-sig'',guidata(gcbo))',...
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
tmpband = ANAP.nview.band;
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
    'Callback','nview(''Main_Callback'',gcbo,''redraw'',guidata(gcbo))',...
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
    'Callback','nview(''Main_Callback'',gcbo,''view-mode'',guidata(gcbo))',...
    'String',{'single','matrix'},...
    'Tag','ViewModeCmb','Value',1,...
    'TooltipString','Select the view mode',...
    'FontWeight','bold','Background','white');
% ViewModeCmb = uicontrol(...
%     'Parent',hMain,'Style','Popupmenu',...
%     'Units','char','Position',[XDSP+10 H 25 1.5],...
%     'Callback','nview(''Main_Callback'',gcbo,''view-mode'',guidata(gcbo))',...
%     'String',{'single','tile'},...
%     'Tag','ViewModeCmb','Value',1,...
%     'TooltipString','Select the view mode',...
%     'FontWeight','bold','Background','white');
ViewPageCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+40 H 25 1.5],...
    'String',{'page1','page2','page3','page4'},...
    'Callback','nview(''Main_Callback'',gcbo,''view-page'',guidata(gcbo))',...
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
tmptrial = ANAP.nview.trial;
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
    'Callback','nview(''Main_Callback'',gcbo,''redraw'',guidata(gcbo))',...
    'String',trials,'Value',tmptrial,'Tag','TrialCmb',...
    'HorizontalAlignment','left',...
    'TooltipString','Select Trial to plot',...
    'FontWeight','Bold');
clear trials tmptrial;


% SELECTION FOR AVERAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(ANAP.nview.averagech),
  ANAP.nview.averagech = 1:size(NEUSIG{1}.dat,2);
end
XDSP = 10; H = figH - 6.5;
AvrChanTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H-0.3 30 1.5],...
    'String','AvrCh:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','AvrChanTxt',...
    'BackgroundColor',get(hMain,'Color'));
AvrChanEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+10 H 25 1.5],...
    'String',deblank(sprintf('%d ',ANAP.nview.averagech)),...
    'Callback','nview(''Main_Callback'',gcbo,''redraw'',guidata(gcbo))',...
    'HorizontalAlignment','left',...
    'Tag','AvrChanEdt','Value',1,...
    'TooltipString','Select channels for averaging');
ErrBarCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+40 H 20 1.5],...
    'Tag','ErrBarCheck','Value',1,...
    'String','ErrorBar','FontWeight','bold',...
    'Callback','nview(''Main_Callback'',gcbo,''redraw'',guidata(gcbo))',...
    'TooltipString','error-bar on/off','BackgroundColor',get(hMain,'Color'));
LegendCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+60 H 20 1.5],...
    'Tag','LegendCheck','Value',1,...
    'String','Legend','FontWeight','bold',...
    'Callback','nview(''Main_Callback'',gcbo,''legend'',guidata(gcbo))',...
    'TooltipString','legend on/off','BackgroundColor',get(hMain,'Color'));




% Hold-on check %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XDSP = 10; H = figH - 6.5;
TCHoldCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+80 H 20 1.5],...
    'Tag','TCHoldCheck','Value',0,...
    'String','Hold On','FontWeight','bold',...
    'TooltipString','map on/off','BackgroundColor',get(hMain,'Color'));



% AXES for plots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% AXES FOR SINGLE VIEW %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 4; XSZ = 155; YSZ = 45;
XDSP=15;
SingleViewAxs = axes(...
    'Parent',hMain,'Tag','SingleViewAxs',...
    'Units','char','Position',[XDSP H XSZ YSZ],...
    'Box','off','color','black','Visible','on','FontWeight','bold');
if size(NEUSIG{1}.dat,2) == 1,
  NCOL = 1;  NROW = 1;
elseif size(NEUSIG{1}.dat,2) == 2,
  NCOL = 1;  NROW = 2;
elseif size(NEUSIG{1}.dat,2) <= 4,
  NCOL = 2;  NROW = 2;
elseif size(NEUSIG{1}.dat,2) <= 6,
  NCOL = 2;  NROW = 3;
elseif size(NEUSIG{1}.dat,2) <= 9,
  NCOL = 3;  NROW = 3;
elseif size(NEUSIG{1}.dat,2) <= 12,
  NCOL = 4;  NROW = 3;
else
  NCOL = 4;  NROW = 4;
end
MatrixViewAxs = subCreateMatrixView(hMain,NCOL,NROW,[XDSP,4,XSZ,YSZ]);



% get widgets handles at this moment
HANDLES = findobj(hMain);


% INITIALIZE THE APPLICATION
setappdata(hMain,'NEUSIG',NEUSIG);
setappdata(hMain,'ANAP',ANAP);
setappdata(hMain,'COLORS','rgbcmy');
setappdata(hMain,'MatrixView',[NCOL NROW]);
setappdata(hMain,'MatrixViewAxs',MatrixViewAxs);
Main_Callback(SingleViewAxs,'init');
set(hMain,'visible','on');



% NOW SET "UNITS" OF ALL WIDGETS AS "NORMALIZED".
HANDLES = HANDLES(find(HANDLES ~= hMain));
set(HANDLES,'units','normalized');

% CHANGE THE VIEW MODE IF NEEDED
if ~strcmpi(ANAP.nview.viewmode,'single'),
  ViewMode = get(ViewModeCmb,'String');
  idx = find(strcmpi(ViewMode,ANAP.nview.viewmode));
  if isempty(idx),
    fprintf('WARNING %s: unknown view-mode, ''%s''.\n',mfilename,ANAP.nview.viewmode);
  else
    set(ViewModeCmb,'Value',idx);
    %Main_Callback(ViewModeCmb,'view-mode',[]);
    Main_Callback(ViewModeCmb,'init',[]);
    if ~isempty(ANAP.nview.viewpage),
      ViewPages = get(ViewPageCmb,'String');
      if ANAP.nview.viewpage < 1 | ANAP.nview.viewpage > length(ViewPages),
        fprintf('WARNING %s: view-page out of range, ''%d''.\n',mfilename,ANAP.nview.viewpage);
      else
        set(ViewPageCmb,'Value',ANAP.nview.viewpage);
      end
    end
  end
end

Main_Callback(SingleViewAxs,'redraw',[]);


% RETURNS THE WINDOW HANDLE IF REQUIRED.
if nargout,
  varargout{1} = hMain;
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to create matrix view axes
function MatrixViewAxs = subCreateMatrixView(hMain,NCOL,NROW,POS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xmergin = 2;
ymergin = 1;

x0  = POS(1);
y0  = POS(2);
xsz = (POS(3)-xmergin*(NCOL-1)) / NCOL;
ysz = (POS(4)-ymergin*(NROW-1)) / NROW;

MatrixViewAxs = [];
for iY = NROW:-1:1,
  tmpy = (ysz+ymergin)*(iY-1) + y0;
  for iX = 1:NCOL,
    tmpx = (xsz+xmergin)*(iX-1) + x0;
    MatrixViewAxs(end+1) = axes(...
        'Parent',hMain,'Tag','MatrixViewAxs',...
        'Units','char','Position',[tmpx tmpy xsz ysz],...
        'Box','off','color','black','Visible','on','FontWeight','bold');
  end
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
  inftxt{end+1} = sprintf('dat= [%s]',deblank(sprintf('%d ',size(NEUSIG{1}.dat))));
  inftxt{end+1} = sprintf('dx= %f',NEUSIG{1}.dx(1));
  set(wgts.InfoTxt,'String',inftxt);


  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  if strcmpi(ViewMode,'single'),
    SingleView_Callback(hObject,'init',[]);
  else
    MatrixView_Callback(hObject,'init',[]);
  end
 
 case {'select-sig'}
  
 case {'view-mode'}
  set(wgts.TCHoldCheck,'Value',0);
  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  if strcmpi(ViewMode,'single'),
    SingleView_Callback(hObject,'init',[]);
  else
    MatrixView_Callback(hObject,'init',[]);
  end
  Main_Callback(hObject,'redraw',[]);
 
 case {'view-page','redraw'}
  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  if strcmpi(ViewMode,'single'),
    SingleView_Callback(hObject,'redraw',[]);
  else
    MatrixView_Callback(hObject,'redraw',[]);
  end
  
 case {'legend'}
  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  if strcmpi(ViewMode,'single'),
    SingleView_Callback(hObject,'legend',[]);
  else
    MatrixView_Callback(hObject,'legend',[]);
  end
  
 case {'zoom-in','zoomin'}
  click = get(wgts.main,'SelectionType');
  if strcmpi(click,'open'),
    % double click
    ViewMode = get(wgts.ViewModeCmb,'String');
    ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
    if strcmpi(ViewMode,'single'),
      subZoomInTC(wgts,wgts.SingleViewAxs,NEUSIG);
    else
      subZoomInMatrix(wgts,NEUSIG);
    end
  end
  
 otherwise
  fprintf('WARNING %s: Main_Callback() ''%s'' not supported yet.\n',mfilename,eventdata);
end
  
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SingleView_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(hObject);
NEUSIG = getappdata(wgts.main,'NEUSIG');
switch lower(eventdata)
 case {'init'}
  % make SingleView visile, MatrixView invisible
  subChangeViewMode(wgts,'on','off');

  pagestr = {};
  if isfield(NEUSIG{1},'chan') & ~isempty(NEUSIG{1}.chan),
    for N = 1:length(NEUSIG{1}.chan),
      pagestr{N} = sprintf('ch %d: ele %d',N,NEUSIG{1}.chan(N));
    end
  else
    for N = 1:size(NEUSIG{1}.dat,2),
      pagestr{N} = sprintf('ch %d',N);
    end
  end
  pagestr{end+1} = 'AVERAGE';
  set(wgts.ViewPageCmb,'String',pagestr,'Value',1);

 case {'view-mode'}
  SingleView_Callback(hObject,'init',[]);
  SingleView_Callback(hObject,'redraw',[]);
  
 case {'view-page','redraw'}
  COLORS  = getappdata(wgts.main,'COLORS');
  pagestr = get(wgts.ViewPageCmb,'String');
  pageval = get(wgts.ViewPageCmb,'Value');
  if length(pagestr) == pageval,
    ChanNo = str2num(get(wgts.AvrChanEdt,'String'));
    if isempty(ChanNo),
      ChanNo = 1:pageval-1;    % plot averaged data
      set(wgts.AvrChanEdt,'String',sprintf('1:%d',max(ChanNo)));
    end
  else
    ChanNo = pageval;    % plot a channel
  end
  BandInfo = get(wgts.BandCmb,'String');  BandNo = get(wgts.BandCmb,'Value');
  if strcmpi(BandInfo(BandNo),'all'),
    BandNo = 1:BandNo-1;
  end
  TrialNo  = get(wgts.TrialCmb,'String');  TrialNo  = TrialNo{get(wgts.TrialCmb,'Value')};
  if strcmpi(TrialNo,'all'),
    TrialNo = 1:length(NEUSIG);
  else
    TrialNo = sscanf(TrialNo,'%d:');
    TrialNo = TrialNo(1);
  end
  
  haxs = wgts.SingleViewAxs;
  subPlotSingleTimeCourse(wgts,haxs,COLORS,NEUSIG,ChanNo,BandNo,TrialNo,BandInfo);

 case {'legend'}
  haxs = wgts.SingleViewAxs;
  if get(wgts.LegendCheck,'value') > 0,
    if length(get(haxs,'UserData')) > 1,
      set(find_legend(haxs),'visible','on');
    end
  else
    set(find_legend(haxs),'visible','off');
  end
  
 otherwise
  fprintf('WARNING %s: SingleView_Callback() ''%s'' not supported yet.\n',mfilename,eventdata);
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function MatrixView_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

wgts = guihandles(hObject);
NEUSIG = getappdata(wgts.main,'NEUSIG');
MatrixView    = getappdata(wgts.main,'MatrixView');
MatrixViewAxs = getappdata(wgts.main,'MatrixViewAxs');
NCOL = MatrixView(1);  NROW = MatrixView(2);

switch lower(eventdata)
 case {'init'}
  % make MatrixView visible, SingleView invisile
  subChangeViewMode(wgts,'off','on');

  pagestr = {};
  max_chan = size(NEUSIG{1}.dat,2);
  dsp_chan = length(MatrixViewAxs);
  max_page = floor((size(NEUSIG{1}.dat,2)-1)/dsp_chan) + 1;
  for N = 1:max_page,
    pagestr{N} = sprintf('Page%d: ch%d-%d',N,(N-1)*dsp_chan+1,min([N*dsp_chan,max_chan]));
  end
  set(wgts.ViewPageCmb,'String',pagestr,'Value',1);

  
 case {'view-mode'}
  MatrixView_Callback(hObject,'init',[]);
  MatrixView_Callback(hObject,'redraw',[]);
  
 case {'view-page','redraw'}
  COLORS  = getappdata(wgts.main,'COLORS');
  ANAP    = getappdata(wgts.main,'ANAP');
  pagestr = get(wgts.ViewPageCmb,'String');
  pagestr = pagestr{get(wgts.ViewPageCmb,'Value')};
  ipage = sscanf(pagestr,'Page%d:');  ipage = ipage(1);
  max_chan = size(NEUSIG{1}.dat,2);
  dsp_chan = length(MatrixViewAxs);
  CHANS = (ipage-1)*dsp_chan+1:min([ipage*dsp_chan,max_chan]);
  BandInfo = get(wgts.BandCmb,'String');  BandNo = get(wgts.BandCmb,'Value');
  if strcmpi(BandInfo(BandNo),'all'),
    BandNo = 1:BandNo-1;
  end
  TrialNo  = get(wgts.TrialCmb,'String');  TrialNo  = TrialNo{get(wgts.TrialCmb,'Value')};
  if strcmpi(TrialNo,'all'),
    TrialNo = 1:length(NEUSIG);
  else
    TrialNo = sscanf(TrialNo,'%d:');
    TrialNo = TrialNo(1);
  end
  
  for iCh = 1:length(CHANS),
    ChanNo = CHANS(iCh);
    haxs = MatrixViewAxs(iCh);
    set(haxs,'visible','on');
    subPlotMatrixTimeCourse(wgts,haxs,COLORS,NEUSIG,ChanNo,BandNo,TrialNo,BandInfo);
    if get(wgts.TCHoldCheck,'Value') == 0,
      if iCh == (NROW-1)*NCOL +1,
        xlabel(ANAP.nview.xlabel);  ylabel(ANAP.nview.ylabel);
      end
    end
  end
  for iCh = length(CHANS)+1:length(MatrixViewAxs),
    haxs = MatrixViewAxs(iCh);
    POS = get(haxs,'pos');
    TAG = get(haxs,'tag');
    delete(allchild(haxs));
    set(haxs,'UserData',[]);
    set(haxs,'pos',POS,'tag',TAG,'visible','off');
  end

 case { 'legend' }
  if get(wgts.LegendCheck,'value') > 0,
    for N = 1:length(MatrixViewAxs),
      haxs = MatrixViewAxs(N);
      if strcmpi(get(haxs,'visible'),'on') & length(get(haxs,'UserData')) > 1,
        set(find_legend(haxs),'visible','on');
      end
    end
  else
    for N = 1:length(MatrixViewAxs),
      haxs = MatrixViewAxs(N);
      set(find_legend(haxs),'visible','off');
    end
  end
  
  
 otherwise
  fprintf('WARNING %s: MatrixView_Callback() ''%s'' not supported yet.\n',mfilename,eventdata);
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to change view mode
function subChangeViewMode(wgts,SingleViewOnOff,MatrixViewOnOff)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% SingleViewAxs
h = findobj(wgts.main,'tag','SingleViewAxs');
for N = 1:length(h),
  haxs = h(N);
  
  POS = get(haxs,'pos');
  TAG = get(haxs,'tag');
  delete(allchild(haxs));
  set(haxs,'UserData',[]);
  
  set(haxs,'visible',SingleViewOnOff,'pos',POS,'tag',TAG);

end
% MatrixViewAxs
h = findobj(wgts.main,'tag','MatrixViewAxs');
for N = 1:length(h),
  haxs = h(N);

  POS = get(haxs,'pos');
  TAG = get(haxs,'tag');
  delete(allchild(haxs));
  set(haxs,'UserData',[]);
  
  set(haxs,'visible',MatrixViewOnOff,'pos',POS,'tag',TAG);
end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to draw single-view data
function subPlotSingleTimeCourse(wgts,haxs,COLORS,NEUSIG,ChanNo,BandNo,TrialNo,BandInfo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ANAP = getappdata(wgts.main,'ANAP');
POS = get(haxs,'pos');
TAG = get(haxs,'tag');
if get(wgts.TCHoldCheck,'Value') == 0,
  % cla;
  delete(allchild(haxs));
  set(haxs,'UserData',[]);
end
  
hDATA = get(haxs,'UserData');

axes(haxs);
for iTrial = 1:length(TrialNo),
  T = TrialNo(iTrial);
  tmpt = [0:size(NEUSIG{T}.dat,1)-1]*NEUSIG{T}.dx(1);
  tmpdat = NEUSIG{T}.dat(:,ChanNo,BandNo);
  tmpcol = COLORS(mod(length(hDATA),length(COLORS))+1);
  if length(ChanNo) > 1,
    % do average
    tmpm = squeeze(mean(tmpdat,2));
    tmps = squeeze(std(tmpdat,[],2)) / sqrt(size(tmpdat,2));
    for iBand = 1:size(tmpm,2),
      tmptxt = sprintf('Trial=%s NCh=%d %s',...
                       NEUSIG{T}.stm.labels{1},length(ChanNo),BandInfo{BandNo(iBand)});
                       
      if get(wgts.ErrBarCheck,'value') > 0,
        hDATA(end+1) = errorbar(tmpt,tmpm(:,iBand),tmps(:,iBand),...
                                'color',tmpcol,'tag','tcdat', 'UserData',tmptxt);
      else
        hDATA(end+1) = plot(tmpt,tmpm(:,iBand),...
                                'color',tmpcol,'tag','tcdat', 'UserData',tmptxt);
      end
      hold on;
    end
  else
    for iBand = 1:size(tmpdat,3),
      tmptxt = sprintf('Trial=%s Ele=%d %s',...
                       NEUSIG{T}.stm.labels{1},NEUSIG{1}.chan(ChanNo),BandInfo{BandNo(iBand)});
      hDATA(end+1) = plot(tmpt,tmpdat(:,1,iBand),...
                          'color',tmpcol,'tag','tcdat','UserData',tmptxt);
      hold on;
    end
  end
end

set(haxs,'UserData',hDATA);
grid on;

if get(wgts.TCHoldCheck,'Value') == 0,
  set(haxs,'xlim',[min(tmpt),max(tmpt)],'Tag','SingleViewAxs');
  xlabel(ANAP.nview.xlabel);  ylabel(ANAP.nview.ylabel);
%   tmpstr = sprintf('Nvox=%d P<%s ROI=%s Model=%s/%s',...
%                    size(tcdat,2),get(wgts.AlphaEdt,'String'),...
%                    RoiName,StatName,ModelNo);
%   text(0.01,0.99,tmpstr,'units','normalized',...
%        'FontName','Comic Sans MS','tag','Nvox',...
%        'HorizontalAlignment','left','VerticalAlignment','top');
  text(0.99,0.01,'mean+-sem','units','normalized',...
       'FontName','Comic Sans MS','tag','Info',...
       'HorizontalAlignment','right','VerticalAlignment','bottom');
  set(haxs,'layer','top');
  set(haxs,...
      'ButtonDownFcn','nview(''Main_Callback'',gcbo,''zoom-in'',guidata(gcbo))');
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
    'ButtonDownFcn','nview(''Main_Callback'',gcbo,''zoom-in'',guidata(gcbo))');



set(haxs,'POS',POS,'tag',TAG);

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to draw matrix-view data
function subPlotMatrixTimeCourse(wgts,haxs,COLORS,NEUSIG,ChanNo,BandNo,TrialNo,BandInfo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ANAP = getappdata(wgts.main,'ANAP');

POS = get(haxs,'pos');
TAG = get(haxs,'tag');
if get(wgts.TCHoldCheck,'Value') == 0,
  % cla;
  delete(allchild(haxs));
  set(haxs,'UserData',[]);
end
  
hDATA = get(haxs,'UserData');

axes(haxs);
for iTrial = 1:length(TrialNo),
  T = TrialNo(iTrial);
  tmpt = [0:size(NEUSIG{T}.dat,1)-1]*NEUSIG{T}.dx(1);
  tmpdat = NEUSIG{T}.dat(:,ChanNo,BandNo);
  tmpcol = COLORS(mod(length(hDATA),length(COLORS))+1);
  if length(ChanNo) > 1,
    % do average
    tmpm = squeeze(mean(tmpdat,2));
    tmps = squeeze(std(tmpdat,[],2)) / sqrt(size(tmpdat,2));
    for iBand = 1:size(tmpm,2),
      tmptxt = sprintf('Trial=%s NCh=%d %s',...
                       NEUSIG{T}.stm.labels{1},length(ChanNo),BandInfo{BandNo(iBand)});
                       
      hDATA(end+1) = errorbar(tmpt,tmpm(:,iBand),tmps(:,iBand),...
                              'color',tmpcol,'tag','tcdat', 'UserData',tmptxt);
      hold on;
    end
  else
    for iBand = 1:size(tmpdat,3),
      tmptxt = sprintf('Trial=%s Ele=%d %s',...
                       NEUSIG{T}.stm.labels{1},NEUSIG{1}.chan(ChanNo),BandInfo{BandNo(iBand)});
      hDATA(end+1) = plot(tmpt,tmpdat(:,1,iBand),...
                          'color',tmpcol,'tag','tcdat','UserData',tmptxt);
      hold on;
    end
  end
end

set(haxs,'UserData',hDATA);
grid on;

if get(wgts.TCHoldCheck,'Value') == 0,
  set(haxs,'xlim',[min(tmpt),max(tmpt)],'Tag','MatrixViewAxs');
%  xlabel(MYXLABEL);  ylabel(MYYLABEL);
%   tmpstr = sprintf('Nvox=%d P<%s ROI=%s Model=%s/%s',...
%                    size(tcdat,2),get(wgts.AlphaEdt,'String'),...
%                    RoiName,StatName,ModelNo);
%   text(0.01,0.99,tmpstr,'units','normalized',...
%        'FontName','Comic Sans MS','tag','Nvox',...
%        'HorizontalAlignment','left','VerticalAlignment','top');

  text(0.01,0.99,sprintf('ch%d-ele%d',ChanNo,NEUSIG{1}.chan(ChanNo)),'units','normalized',...
       'FontName','Comic Sans MS','FontWeight','bold','tag','Info',...
       'HorizontalAlignment','left','VerticalAlignment','top');
  text(0.99,0.01,'mean+-sem','units','normalized',...
       'FontName','Comic Sans MS','tag','Info',...
       'HorizontalAlignment','right','VerticalAlignment','bottom');
  set(haxs,'layer','top');
  set(haxs,...
      'ButtonDownFcn','nview(''Main_Callback'',gcbo,''zoom-in'',guidata(gcbo))');
  subDrawStimIndicators(haxs,NEUSIG,TrialNo,1);
else
  delete(findobj(haxs,'type','text','tag','Nvox'));
  %delete(findobj(haxs,'type','text'));
  subDrawStimIndicators(haxs,NEUSIG,TrialNo,0);
  legtxt = {};
  for N = 1:length(hDATA),
    legtxt{N} = get(hDATA(N),'UserData');
  end
  h = legend(haxs,legtxt,'fontsize',6,'location','NorthEast');
  setfront(h);
  if get(wgts.LegendCheck,'value') == 0,
    set(h,'visible','off');
  end
end
  
set(allchild(haxs),...
    'ButtonDownFcn','nview(''Main_Callback'',gcbo,''zoom-in'',guidata(gcbo))');



set(haxs,'POS',POS,'tag',TAG);

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to draw stimulus indicators
function subDrawStimIndicators(haxs,NEUSIG,TrialNo,DRAW_OBJ)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
          line([stimt(N), stimt(N)],ylm,'color','k','tag','stim-line');
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
          line([stimt(N),stimt(N)]+tmpw,ylm,'color','k','tag','stim-line');
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
          %pos = get(hline(K),'pos');
          pos = get(hline(K),'xdata');
          if pos(1) == stimt(N),
            h = hline(K);  break;
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to zoom-in plot (TIME COURSE)
function subZoomInMatrix(wgts,NEUSIG)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ChanNo  = get(wgts.ViewPageCmb,'String');  ChanNo  = ChanNo{get(wgts.ViewPageCmb,'Value')};
TrialNo = get(wgts.TrialCmb,'String');     TrialNo = TrialNo{get(wgts.TrialCmb,'Value')};
BandNo  = get(wgts.BandCmb,'String');      BandNo  = BandNo{get(wgts.BandCmb,'Value')};
MatrixViewAxs = getappdata(wgts.main,'MatrixViewAxs');



hfig = wgts.main + 2005;

tmptitle = sprintf('Neural Signal Time Course\n%s %s',NEUSIG{1}.session,NEUSIG{1}.grpname);
if length(NEUSIG{1}.ExpNo) > 1,
  tmptitle = sprintf('%s NumExps=%d',tmptitle,length(NEUSIG{1}.ExpNo));
else
  tmptitle = sprintf('%s ExpNo=%d',tmptitle,NEUSIG{1}.ExpNo);
end

if length(get(MatrixViewAxs(1),'UserData')) > 1,
  % multiple plot with "hold-on"
else
  tmptitle = sprintf('%s %s %s',tmptitle,ChanNo,BandNo);
end
if length(get(wgts.TrialCmb,'String')) > 1 & get(wgts.TCHoldCheck,'value') == 0,
  tmptitle = sprintf('%s Trial=%s',tmptitle,TrialNo);
end


figure(hfig);  clf;
pos = get(hfig,'pos');
pos = [pos(1)-(680-pos(3)) pos(2)-(500-pos(4)) 680 500];
% sometime, wiondow is outside the screen....why this happens??
[scrW scrH] = subGetScreenSize('pixels');
if pos(1) < -pos(3) | pos(1) > scrW,  pos(1) = 1;  end
if pos(2)+pos(4) < 0 | pos(2)+pos(4)+70 > scrH,  pos(2) = scrH-pos(4)-70;  end
set(hfig,'Name',tmptitle,'pos',pos);
figtitle(tmptitle);

haxs = [];
for iAxs = 1:length(MatrixViewAxs),
  hsrc = MatrixViewAxs(iAxs);
  if strcmpi(get(hsrc,'visible'),'off'),  continue;  end

  haxs(iAxs) = copyobj(hsrc,hfig);
  % FU__ING MATLAB(R14), copyobj() makes lines in legend all black. ----------
  erb = findobj(haxs(iAxs),'tag','tcdat');
  for N = 1:length(erb),
    tmph = findobj(erb(N),'type','line');
    set(erb(N),'color',get(tmph(1),'color'));
  end
  %---------------------------------------------------------------------------

  % xlim,ylim is funny....
  set(haxs(iAxs),'xlim',get(hsrc,'xlim'),'ylim',get(hsrc,'ylim'));
  
  %clear callbacks
  set(haxs(iAxs),'ButtonDownFcn','');  % clear callback function
  set(allchild(haxs(iAxs)),'ButtonDownFcn','');

end

% if "hold-on" then put the legend
hsrc = MatrixViewAxs(1);
hDATA = get(hsrc,'UserData');
legtxt = {};
if length(hDATA) > 1,
  for N = 1:length(hDATA),
    legtxt{N} = get(hDATA(N),'UserData');
  end
  h = legend(haxs(1),legtxt,'location','northoutside');
  set(h,'fontweight','bold','fontsize',8,'fontname','Comic Sans MS');
  pos = get(h,'pos');
  set(h,'pos',[0.08 0.88 pos(3:end)],'units','normalized');
  %drawnow;
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
