function varargout = anaview(varargin)
%ANAVIEW - displays anatomical images
%  ANAVIEW(SESSION,GRPNAME) displays anatomical images for SESSION/GRPNAME.
%  ANAVIEW(SESSION,ANANAME,INDEX) displays anatomical images for ANANAME/INDEX.
%  ANAVIEW(SIG) displays anatomical data "SIG".
%
%  ANAVIEW(SESSION,GRPNAME,PERMUTE_VEC)
%  ANAVIEW(SESSION,ANANAME,INDEX,PERMUTE_VEC)
%  ANAVIEW(SIG,PERMUTE_VEC) performs permutation of image data.
%
%
%  NOTES :
%    This function assumes .dat as (x,y,z) as default.
%    "Z-reverse" is enabled since usually 'y' starts from top.
%
%  EXAMPLE :
%    >> anaview('demo');
%    >> anaview('m02lx1','movie1');
%    >> anaview('m02lx1','gefi',1);
%
%  VERSION :
%    0.90 04.07.05 YM   pre-release
%    0.91 05.07.05 YM   supports permutation/gamma/crosshair.
%    0.92 05.07.05 YM   supports triplot.
%    0.93 08.07.05 YM   supports "lightbox" modes.
%    0.94 19.08.05 YM   supports "demo" mode, XYZrev for "Lightbox" modes.
%    0.95 14.08.05 YM   supports sesversion() >= 2
%    0.96 05.11.15 YM   supports zoom-in of "lightbox" modes.
%    0.97 09.11.16 YM   bug fix of "gamma" in lightbox modes.
%    0.98 06.07.17 YM   fixed problems of graphic handles (2014b).
%
%  See also ANALOAD

if nargin == 0,  help anaview; return;  end

% execute callback function then return;
if ischar(varargin{1}) & ~isempty(findstr(varargin{1},'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return;
end


ANA = {};  PERMUTE_VEC = [];
% called like anaview(mdeft{1}),
if isempty(ANA) & isstruct(varargin{1}) & isfield(varargin{1},'dat'),
  try
  Ses = getses(varargin{1}.session);
  catch
    Ses = [];
  end
  ANA = varargin{1};
  if iscell(ANA) & length(ANA) > 1,  ANA = ANA{1};  end
  if nargin > 1,  PERMUTE_VEC = varargin{2};  end
end

% called like anaview('demo')
if isempty(ANA) & ischar(varargin{1}) & strcmpi(varargin{1},'demo'),
  varargout = anaview('j02ta1','ir',1);
  return;
end

% called like anaview(Ses,grp/ana)
if isempty(ANA),
  Ses = goto(varargin{1});
  if ischar(varargin{2}) & isfield(Ses.ascan,varargin{2}),
    % anaview(Ses,ANANAME,[INDEX],[PERMUTE])
    if sesversion(Ses) < 2,
      ANA = load(sprintf('%s.mat',varargin{2}),varargin{2});
      ANA = ANA.(varargin{2});
      if nargin > 2,
        ANA = ANA{varargin{3}};
      else
        ANA = ANA{1};
      end
    else
      if nargin > 2
        anafile = sigfilename(Ses,varargin{3},varargin{2});
      else
        anafile = sigfilename(Ses,1,varargin{2});
      end
      ANA = load(anafile,varargin{2});
      ANA = ANA.(varargin{2});
    end
    if nargin > 3,  PERMUTE_VEC = varargin{4};  end
  else
    % anaview(Ses,grp/expno,[permute])
    ANA = anaload(Ses,varargin{2});
    if nargin > 2,  PERMUTE_VEC = varargin{3};  end
  end
end



if isempty(ANA),
  fprintf('\n%s ERROR: no way to get anatomy data.\n',mfilename);
  return;
end

% why this happend????
if ndims(ANA.dat) > 3,  ANA.dat = squeeze(ANA.dat);  end

% do permutation, if given
if ~isempty(PERMUTE_VEC),
  ANA.dat = permute(ANA.dat,PERMUTE_VEC);
end

ANA.dat = double(ANA.dat);

if ~isfield(ANA,'session') | isempty(ANA.session),
  ANA.session = 'unknown';
end
if ~isfield(ANA,'grpname') | isempty(ANA.grpname),
  ANA.grpname = 'unknown';
end

% GET SCREEN SIZE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
oldunits = get(0,'units');
set(0,'units','char');
SZscreen = get(0,'ScreenSize');
set(0,'units',oldunits);
scrW = SZscreen(3);  scrH = SZscreen(4);

figW = 175; figH = 51;
%figX = 31;  figY = scrH-figH-5;
figX = 31;  figY = floor(scrH-figH-8);

%[figX figY figW figH]


% CREATE A MAIN FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hMain = figure(...
    'Name',sprintf('%s: SES=''%s'' GRP=''%s''',mfilename,ANA.session,ANA.grpname),...
    'NumberTitle','off', 'toolbar','figure',...
    'Tag','main', 'units','char', 'pos',[figX figY figW figH],...
    'HandleVisibility','on', 'Resize','on',...
    'DoubleBuffer','on', 'BackingStore','on', 'Visible','on',...
    'DefaultAxesFontSize',10,...
    'DefaultAxesFontName', 'Comic Sans MS',...
    'DefaultAxesfontweight','bold');



% AXES for plots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% AXES FOR LIGHT BOX %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 3; XSZ = 55; YSZ = 20;
XDSP=10;
LightiboxAxs = axes(...
    'Parent',hMain,'Tag','LightboxAxs',...
    'Units','char','Position',[XDSP H XSZ*2+12 YSZ*2+6.5],...
    'Box','off','color','black','Visible','off');


% AXES FOR ORTHOGONL VIEW %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 28; XSZ = 55; YSZ = 20;
XDSP=10;
CoronalTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H+YSZ 20 1.5],...
    'String','Coronal (X-Z)','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','CoronalTxt',...
    'BackgroundColor',get(hMain,'Color'));
CoronalEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+22 H+YSZ+0.2 8 1.5],...
    'Callback','anaview(''OrthoView_Callback'',gcbo,''edit-coronal'',guidata(gcbo))',...
    'String','','Tag','CoronalEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set coronal slice',...
    'FontWeight','Bold');
CoronalSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[XDSP+XSZ*0.6 H+YSZ+0.2 XSZ*0.4 1.2],...
    'Callback','anaview(''OrthoView_Callback'',gcbo,''slider-coronal'',guidata(gcbo))',...
    'Tag','CoronalSldr','SliderStep',[1 4],...
    'TooltipString','coronal slice');
CoronalAxs = axes(...
    'Parent',hMain,'Tag','CoronalAxs',...
    'Units','char','Position',[XDSP H XSZ YSZ],...
    'Box','off','Color','black');
SagitalTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+10+XSZ H+YSZ 20 1.5],...
    'String','Sagital (Y-Z)','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','SagitalTxt',...
    'BackgroundColor',get(hMain,'Color'));
SagitalEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+10+XSZ+22 H+YSZ+0.2 8 1.5],...
    'Callback','anaview(''OrthoView_Callback'',gcbo,''edit-sagital'',guidata(gcbo))',...
    'String','','Tag','SagitalEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set sagital slice',...
    'FontWeight','Bold');
SagitalSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[XDSP+10+XSZ*1.6 H+YSZ+0.2 XSZ*0.4 1.2],...
    'Callback','anaview(''OrthoView_Callback'',gcbo,''slider-sagital'',guidata(gcbo))',...
    'Tag','SagitalSldr','SliderStep',[1 4],...
    'TooltipString','sagital slice');
SagitalAxs = axes(...
    'Parent',hMain,'Tag','SagitalAxs',...
    'Units','char','Position',[XDSP+10+XSZ H XSZ YSZ],...
    'Box','off','Color','black');


H = 3;
TransverseTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H+YSZ 20 1.5],...
    'String','Transverse (X-Y)','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','TransverseTxt',...
    'BackgroundColor',get(hMain,'Color'));
TransverseEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+22 H+YSZ+0.2 8 1.5],...
    'Callback','anaview(''OrthoView_Callback'',gcbo,''edit-transverse'',guidata(gcbo))',...
    'String','','Tag','TransverseEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set transverse slice',...
    'FontWeight','Bold');
TransverseSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[XDSP+XSZ*0.6 H+YSZ+0.2 XSZ*0.4 1.2],...
    'Callback','anaview(''OrthoView_Callback'',gcbo,''slider-transverse'',guidata(gcbo))',...
    'Tag','TransverseSldr','SliderStep',[1 4],...
    'TooltipString','transverse slice');
TransverseAxs = axes(...
    'Parent',hMain,'Tag','TransverseAxs',...
    'Units','char','Position',[XDSP H XSZ YSZ],...
    'Box','off','Color','black');

TriplotAxs = axes(...
    'Parent',hMain,'Tag','TriplotAxs',...
    'Units','char','Position',[XDSP+10+XSZ H XSZ YSZ],...
    'Box','off','color','white');



% VIEW MODE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 28;
XDSP=XDSP+XSZ+7;
ViewModeCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+10+XSZ H+YSZ 32 1.5],...
    'Callback','anaview(''Main_Callback'',gcbo,''view-mode'',guidata(gcbo))',...
    'String',{'orthogonal','lightbox-cor','lightbox-sag','lightbox-trans'},...
    'Tag','ViewModeCmb','Value',1,...
    'TooltipString','Select the view mode',...
    'FontWeight','bold');
ViewPageList = uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','char','Position',[XDSP+10+XSZ H+12 32 7],...
    'String',{'page1','page2','page3','page4'},...
    'Callback','anaview(''Main_Callback'',gcbo,''view-page'',guidata(gcbo))',...
    'HorizontalAlignment','left',...
    'FontName','Comic Sans MS','FontSize',9,...
    'Tag','ViewPageList','Background','white');


% INFORMATION TEXT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
InfoTxt = uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','char','Position',[XDSP+10+XSZ H 32 11],...
    'String',{'session','group','datsize','resolution'},...
    'HorizontalAlignment','left',...
    'FontName','Comic Sans MS','FontSize',9,...
    'Tag','InfoTxt','Background','white');



% AXES FOR COLORBAR %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 3;
ColorbarAxs = axes(...
    'Parent',hMain,'Tag','ColorbarAxs',...
    'units','char','Position',[XDSP+10+XSZ H XSZ*0.1 YSZ],...
    'FontSize',8,...
    'Box','off','YAxisLocation','right','XTickLabel',{},'XTick',[]);
ColorbarMinEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+10+XSZ+15 H 12 1.5],...
    'Callback','anaview(''Plot_Callback'',gcbo,[],[])',...
    'String','','Tag','ColorbarMinEdt',...
    'Callback','anaview(''Main_Callback'',gcbo,''update-clim'',guidata(gcbo))',...
    'HorizontalAlignment','center',...
    'TooltipString','set colorbar minimum',...
    'FontWeight','Bold');
ColorbarMaxEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+10+XSZ+15 H+YSZ-1.5 12 1.5],...
    'Callback','anaview(''Plot_Callback'',gcbo,[],[])',...
    'String','','Tag','ColorbarMaxEdt',...
    'Callback','anaview(''Main_Callback'',gcbo,''update-clim'',guidata(gcbo))',...
    'HorizontalAlignment','center',...
    'TooltipString','set colorbar maximum',...
    'FontWeight','Bold');


% GAMMA SETTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+10+XSZ+15, H+YSZ/2+5 30 1.25],...
    'String','Gamma: ','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'BackgroundColor',get(hMain,'color'));
GammaEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+10+XSZ+15, H+YSZ/2+3.5 10 1.5],...
    'Callback','anaview(''OrthoView_Callback'',gcbo,''set-gamma'',guidata(gcbo))',...
    'String','1.8','Tag','GammaEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set a gamma value for image',...
    'FontWeight','bold');



% CHECK BOX FOR X,Y,Z direction %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XReverseCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+10+XSZ+15 H+YSZ/2 20 1.5],...
    'Tag','XReverseCheck','Value',0,...
    'Callback','anaview(''Main_Callback'',gcbo,''dir-reverse'',guidata(gcbo))',...
    'String','X-Reverse','FontWeight','bold',...
    'TooltipString','Xdir reverse','BackgroundColor',get(hMain,'Color'));
YReverseCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+10+XSZ+15 H+YSZ/2-2.5 20 1.5],...
    'Tag','YReverseCheck','Value',0,...
    'Callback','anaview(''Main_Callback'',gcbo,''dir-reverse'',guidata(gcbo))',...
    'String','Y-Reverse','FontWeight','bold',...
    'TooltipString','Ydir reverse','BackgroundColor',get(hMain,'Color'));
ZReverseCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+10+XSZ+15 H+YSZ/2-2.5*2 20 1.5],...
    'Callback','anaview(''Main_Callback'',gcbo,''dir-reverse'',guidata(gcbo))',...
    'Tag','ZReverseCheck','Value',1,...
    'String','Z-Reverse','FontWeight','bold',...
    'TooltipString','Zdir reverse','BackgroundColor',get(hMain,'Color'));


% CHECK BOX FOR "cross-hair" %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CrosshairCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+10+XSZ+15 H+YSZ/2-7.5 20 1.5],...
    'Callback','anaview(''OrthoView_Callback'',gcbo,''crosshair'',guidata(gcbo))',...
    'Tag','CrosshairCheck','Value',1,...
    'String','Crosshair','FontWeight','bold',...
    'TooltipString','show a crosshair','BackgroundColor',get(hMain,'Color'));





% get widgets handles at this moment
HANDLES = findobj(hMain);


% INITIALIZE THE APPLICATION
setappdata(hMain,'ANA',ANA);
setappdata(hMain,'PERMUTE_VEC',PERMUTE_VEC);
Main_Callback(SagitalAxs,'init');
set(hMain,'visible','on');



% NOW SET "UNITS" OF ALL WIDGETS AS "NORMALIZED".
HANDLES = HANDLES(find(HANDLES ~= hMain));
set(HANDLES,'units','normalized');


% RETURNS THE WINDOW HANDLE IF REQUIRED.
if nargout,
  varargout{1} = hMain;
end





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Main_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(hObject);

switch lower(eventdata),
 case {'init'}
  ANA  = getappdata(wgts.main,'ANA');
  MINV = 0;  MAXV = round(double(max(ANA.dat(:))) * 0.8/1000)*1000;
  if MAXV == 0,  MAXV = 100;  end
  % set min/max value for scaling
  set(wgts.ColorbarMinEdt,'string',sprintf('%.1f',MINV));
  set(wgts.ColorbarMaxEdt,'string',sprintf('%.1f',MAXV));
  setappdata(wgts.main,'MINV',MINV);
  setappdata(wgts.main,'MAXV',MAXV);
  
  % set information text
  permute_vec = getappdata(wgts.main,'PERMUTE_VEC');
  INFTXT = {};
  INFTXT{end+1} = sprintf('%s',ANA.session);
  INFTXT{end+1} = sprintf('%s',ANA.grpname);
  if isfield(ANA,'ExpNo') & length(ANA.ExpNo) == 1,
    INFTXT{end+1} = sprintf('ExpNo=%d',ANA.ExpNo);
  end
  szdat = size(ANA.dat);
  INFTXT{end+1} = sprintf('[%d%s]',szdat(1),sprintf(' %d',szdat(2:end)));
  if isfield(ANA,'ds'),
    INFTXT{end+1} = sprintf('[%g%s]',ANA.ds(1),sprintf(' %g',ANA.ds(2:end)));
  end
  if ~isempty(permute_vec),
    INFTXT{end+1} = sprintf('permute=[%d%s]',permute_vec(1),sprintf(' %d',permute_vec(2:end)));
  end
  set(wgts.InfoTxt,'String',INFTXT);
  
  % initialize view
  if nargin < 3,
    OrthoView_Callback(hObject(1),'init');
    LightboxView_Callback(hObject(1),'init');
  else
    OrthoView_Callback(hObject(1),'init',handles);
    LightboxView_Callback(hObject(1),'init',handles);
  end

 case {'update-clim'}
  MINV = str2num(get(wgts.ColorbarMinEdt,'String'));
  if isempty(MINV),
    MINV = getappdata(wgts.main,'MINV');
    set(wgts.ColorbarMinEdt,'String',sprintf('%.1f',MINV));
  end
  MAXV = str2num(get(wgts.ColorbarMaxEdt,'String'));
  if isempty(MAXV),
    MAXV = getappdata(wgts.main,'MAXV');
    set(wgts.ColorbarMaxEdt,'String',sprintf('%.1f',MAXV));
  end
  % update tick for colorbar
  GRAHANDLE = getappdata(wgts.main,'GRAHANDLE');
  if ~isempty(GRAHANDLE),
    ydat = [0:255]/255 * (MAXV - MINV) + MINV;
    set(GRAHANDLE.colorbar,'ydata',ydat);
    set(wgts.ColorbarAxs,'ylim',[MINV MAXV]);
  end
  % update color for images
  haxs = [wgts.SagitalAxs, wgts.CoronalAxs, wgts.TransverseAxs, wgts.TriplotAxs, wgts.LightboxAxs];
  set(haxs,'clim',[MINV MAXV]);
  setappdata(wgts.main,'MINV',MINV);
  setappdata(wgts.main,'MAXV',MAXV);
  
 case {'view-mode'}
  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  hL = [wgts.LightboxAxs];
  hO = [wgts.CoronalTxt, wgts.CoronalEdt, wgts.CoronalSldr, wgts.CoronalAxs,...
        wgts.SagitalTxt, wgts.SagitalEdt, wgts.SagitalSldr, wgts.SagitalAxs,...
        wgts.TransverseTxt, wgts.TransverseEdt, wgts.TransverseSldr, wgts.TransverseAxs,...
        wgts.CrosshairCheck];
  
  if strcmpi(ViewMode,'orthogonal'),
    set(hL,'visible','off');
    set(findobj(hL),'visible','off');
    set(hO,'visible','on');
    h = findobj([wgts.CoronalAxs, wgts.SagitalAxs, wgts.TransverseAxs, wgts.TriplotAxs]);
    set(h,'visible','on');
  else
    set(hL,'visible','on');
    set(findobj(hL),'visible','on');
    set(hO,'visible','off');
    h = findobj([wgts.CoronalAxs, wgts.SagitalAxs, wgts.TransverseAxs, wgts.TriplotAxs]);
    set(h,'visible','off');
    LightboxView_Callback(hObject,'init',[]);
    LightboxView_Callback(hObject,'redraw',[]);
  end

 case {'view-page'}
  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  if ~isempty(strfind(ViewMode,'lightbox')),
    LightboxView_Callback(hObject,'redraw',[]);
  end
  
 case {'dir-reverse'}
  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  if ~isempty(strfind(ViewMode,'lightbox')),
    LightboxView_Callback(hObject,'redraw',[]);
  else
    OrthoView_Callback(hObject,'dir-reverse',[]);
  end
 
 otherwise
end
  
return;


       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to handle orthogonal view
function OrthoView_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(get(hObject,'Parent'));
ANA  = getappdata(wgts.main,'ANA');
MINV = getappdata(wgts.main,'MINV');
MAXV = getappdata(wgts.main,'MAXV');

switch lower(eventdata),
 case {'init'}
  iX = 1;  iY = 1;  iZ = 1;
  nX = size(ANA.dat,1);  nY = size(ANA.dat,2);  nZ = size(ANA.dat,3);
  % set slider edit value
  set(wgts.SagitalEdt,   'String', sprintf('%d',iX));
  set(wgts.CoronalEdt,   'String', sprintf('%d',iY));
  set(wgts.TransverseEdt,'String', sprintf('%d',iZ));
  % set slider, add +0.01 to prevent error.
  set(wgts.SagitalSldr,   'Min',1,'Max',nX+0.01,'Value',iX);
  set(wgts.CoronalSldr,   'Min',1,'Max',nY+0.01,'Value',iY);
  set(wgts.TransverseSldr,'Min',1,'Max',nZ+0.01,'Value',iZ);
  % set slider step, it is normalized from 0 to 1, not min/max
  set(wgts.SagitalSldr,   'SliderStep',[1, 2]/max(1,nX));
  set(wgts.CoronalSldr,   'SliderStep',[1, 2]/max(1,nY));
  set(wgts.TransverseSldr,'SliderStep',[1, 2]/max(1,nZ));
  
  cmap = gray(256);
  gammav = str2num(get(wgts.GammaEdt,'String'));
  if ~isempty(gammav),
    cmap = cmap.^(1/gammav);
  end
  
  AXISCOLOR = [0.8 0.2 0.8];
  % now draw images
  axes(wgts.SagitalAxs);     colormap(cmap);
  hSag = imagesc(1:nY,1:nZ,squeeze(ANA.dat(iX,:,:))');
  set(hSag,...
      'ButtonDownFcn','anaview(''OrthoView_Callback'',gcbo,''button-sagital'',guidata(gcbo))');
  set(wgts.SagitalAxs,'tag','SagitalAxs');	% set this again, some will reset.
  axes(wgts.CoronalAxs);     colormap(cmap);
  hCor = imagesc(1:nX,1:nZ,squeeze(ANA.dat(:,iY,:))');
  set(hCor,...
      'ButtonDownFcn','anaview(''OrthoView_Callback'',gcbo,''button-coronal'',guidata(gcbo))');
  set(wgts.CoronalAxs,'tag','CoronalAxs');  % set this again, some will reset.
  axes(wgts.TransverseAxs);  colormap(cmap);
  hTra = imagesc(1:nX,1:nY,squeeze(ANA.dat(:,:,iZ))');
  set(hTra,...
      'ButtonDownFcn','anaview(''OrthoView_Callback'',gcbo,''button-transverse'',guidata(gcbo))');
  set(wgts.TransverseAxs,'tag','TransverseAxs');	% set this again, some will reset.
  
  % now draw a color bar
  axes(wgts.ColorbarAxs);
  ydat = [0:255]/255 * (MAXV - MINV) + MINV;
  hColorbar = imagesc(1,ydat,[0:255]'); colormap(cmap);
  set(wgts.ColorbarAxs,'Tag','ColorbarAxs');  % set this again, some will reset.
  set(wgts.ColorbarAxs,'ylim',[MINV MAXV],'xcolor',AXISCOLOR,'ycolor',AXISCOLOR,...
                    'YAxisLocation','right','XTickLabel',{},'XTick',[],'Ydir','normal');
  
  haxs = [wgts.SagitalAxs, wgts.CoronalAxs, wgts.TransverseAxs];
  set(haxs,'clim',[MINV MAXV],'fontsize',8,'xcolor',AXISCOLOR,'ycolor',AXISCOLOR);
  GRAHANDLE.sagital    = hSag;
  GRAHANDLE.coronal    = hCor;
  GRAHANDLE.transverse = hTra;
  GRAHANDLE.colorbar   = hColorbar;
  
  % draw crosshair(s)
  axes(wgts.SagitalAxs);
  hSagV = line([iY iY],[ 1 nZ],'color','y');
  hSagH = line([ 1 nY],[iZ iZ],'color','y');
  set([hSagV hSagH],...
      'ButtonDownFcn','anaview(''OrthoView_Callback'',gcbo,''button-sagital'',guidata(gcbo))');
  axes(wgts.CoronalAxs);
  hCorV = line([iX iX],[ 1 nZ],'color','y');
  hCorH = line([ 1 nX],[iZ iZ],'color','y');
  set([hCorV hCorH],...
      'ButtonDownFcn','anaview(''OrthoView_Callback'',gcbo,''button-coronal'',guidata(gcbo))');
  axes(wgts.TransverseAxs);
  hTraV = line([iX iX],[ 1 nY],'color','y');
  hTraH = line([ 1 nX],[iY iY],'color','y');
  set([hTraV hTraH],...
      'ButtonDownFcn','anaview(''OrthoView_Callback'',gcbo,''button-transverse'',guidata(gcbo))');
  if get(wgts.CrosshairCheck,'Value') == 0,
    set([hSagV hSagH hCorV hCorH hTraV hTraH],'visible','off');
  end
  GRAHANDLE.sagitalV    = hSagV;
  GRAHANDLE.sagitalH    = hSagH;
  GRAHANDLE.coronalV    = hCorV;
  GRAHANDLE.coronalH    = hCorH;
  GRAHANDLE.transverseV = hTraV;
  GRAHANDLE.transverseH = hTraH;
  
  % tri-plot
  axes(wgts.TriplotAxs);
  tmpv = squeeze(ANA.dat(iX,:,:));
  [xi,yi,zi] = meshgrid(iX,1:nY,1:nZ);
  hSag = surface(...
      'xdata',reshape(xi,[nY,nZ]),'ydata',reshape(yi,[nY,nZ]),'zdata',reshape(zi,[nY,nZ]),...
      'cdata',tmpv,...
      'facecolor','texturemap','edgecolor','none',...
      'CDataMapping','scaled','linestyle','none');
  tmpv = squeeze(ANA.dat(:,iY,:));
  [xi,yi,zi] = meshgrid(1:nX,iY,1:nZ);
  hCor = surface(...
      'xdata',reshape(xi,[nX,nZ]),'ydata',reshape(yi,[nX,nZ]),'zdata',reshape(zi,[nX,nZ]),...
      'cdata',tmpv,...
    'facecolor','texturemap','edgecolor','none',...
      'CDataMapping','scaled','linestyle','none');
  tmpv = squeeze(ANA.dat(:,:,iZ));
  [xi,yi,zi] = meshgrid(1:nX,1:nY,iZ);
  hTra = surface(...
      'xdata',1:nX,'ydata',1:nY,'zdata',reshape(zi,[nY,nX]),...
      'cdata',tmpv',...
      'facecolor','texturemap','edgecolor','none',...
      'CDataMapping','scaled','linestyle','none');

  set(gca,'Tag','TriplotAxs');
  set(gca,'clim',[MINV MAXV],'fontsize',8,...
          'xlim',[1 nX],'ylim',[1 nY],'zlim',[1 nZ],'zdir','reverse');
  view(50,36);  grid on;
  xlabel('X'); ylabel('Y');  zlabel('Z');
  set([gca hSag hCor hTra],...
      'ButtonDownFcn','anaview(''OrthoView_Callback'',gcbo,''button-triplot'',guidata(gcbo))');
  
  
  GRAHANDLE.triSagital = hSag;
  GRAHANDLE.triCoronal = hCor;
  GRAHANDLE.triTransverse = hTra;
  
  setappdata(wgts.main,'GRAHANDLE',GRAHANDLE);

  OrthoView_Callback(hObject,'dir-reverse',[]);

 case {'slider-sagital'}
  GRAHANDLE = getappdata(wgts.main,'GRAHANDLE');
  if ~isempty(GRAHANDLE)
    iX = round(get(wgts.SagitalSldr,'Value'));
    set(GRAHANDLE.sagital,'cdata',squeeze(ANA.dat(iX,:,:))');
    set(GRAHANDLE.coronalV,   'xdata',[iX iX]);
    set(GRAHANDLE.transverseV,'xdata',[iX iX]);
    set(wgts.SagitalEdt,'String',sprintf('%d',iX));
    xdata = get(GRAHANDLE.triSagital,'xdata');
    xdata(:) = iX;
    set(GRAHANDLE.triSagital,'xdata',xdata,'cdata',squeeze(ANA.dat(iX,:,:)));
  end
  
  
 case {'slider-coronal'}
  GRAHANDLE = getappdata(wgts.main,'GRAHANDLE');
  if ~isempty(GRAHANDLE)
    iY = round(get(wgts.CoronalSldr,'Value'));
    set(GRAHANDLE.coronal,'cdata',squeeze(ANA.dat(:,iY,:))');
    set(GRAHANDLE.sagitalV,   'xdata',[iY iY]);
    set(GRAHANDLE.transverseH,'ydata',[iY iY]);
    set(wgts.CoronalEdt,'String',sprintf('%d',iY));
    ydata = get(GRAHANDLE.triCoronal,'ydata');
    ydata(:) = iY;
    set(GRAHANDLE.triCoronal,'ydata',ydata,'cdata',squeeze(ANA.dat(:,iY,:)));
  end
  
 case {'slider-transverse'}
  GRAHANDLE = getappdata(wgts.main,'GRAHANDLE');
  if ~isempty(GRAHANDLE)
    iZ = round(get(wgts.TransverseSldr,'Value'));
    set(GRAHANDLE.transverse,'cdata',squeeze(ANA.dat(:,:,iZ))');
    set(GRAHANDLE.sagitalH,   'ydata',[iZ iZ]);
    set(GRAHANDLE.coronalH,   'ydata',[iZ iZ]);
    set(wgts.TransverseEdt,'String',sprintf('%d',iZ));
    zdata = get(GRAHANDLE.triTransverse,'zdata');
    zdata(:) = iZ;
    set(GRAHANDLE.triTransverse,'zdata',zdata,'cdata',squeeze(ANA.dat(:,:,iZ))');
  end
  
 case {'edit-sagital'}
  iX = str2num(get(wgts.SagitalEdt,'String'));
  if isempty(iX),
    iX = round(get(wgts.SagitalSldr,'Value'));
    set(wgts.SagitalEdt,'String',sprintf('%d',iX));
  else
    if iX < 0,
      iX = 1; 
      set(wgts.SagitalEdt,'String',sprintf('%d',iX));
    elseif iX > size(ANA.dat,1),
      iX = size(ANA.dat,1);
      set(wgts.SagitalEdt,'String',sprintf('%d',iX));
    end
    set(wgts.SagitalSldr,'Value',iX);
    OrthoView_Callback(hObject,'slider-sagital',[]);
  end
  
 case {'edit-coronal'}
  iY = str2num(get(wgts.CoronalEdt,'String'));
  if isempty(iY),
    iY = round(get(wgts.CoronalSldr,'Value'));
    set(wgts.CoronalEdt,'String',sprintf('%d',iY));
  else
    if iY < 0,
      iY = 1; 
      set(wgts.CoronalEdt,'String',sprintf('%d',iY));
    elseif iY > size(ANA.dat,1),
      iY = size(ANA.dat,1);
      set(wgts.CoronalEdt,'String',sprintf('%d',iY));
    end
    set(wgts.CoronalSldr,'Value',iY);
    OrthoView_Callback(hObject,'slider-coronal',[]);
  end
 
 case {'edit-transverse'}
  iZ = str2num(get(wgts.TransverseEdt,'String'));
  if isempty(iZ),
    iZ = round(get(wgts.TransverseSldr,'Value'));
    set(wgts.TransverseEdt,'String',sprintf('%d',iZ));
  else
    if iZ < 0,
      iZ = 1; 
      set(wgts.TransverseEdt,'String',sprintf('%d',iZ));
    elseif iZ > size(ANA.dat,1),
      iZ = size(ANA.dat,1);
      set(wgts.TransverseEdt,'String',sprintf('%d',iZ));
    end
    set(wgts.TransverseSldr,'Value',iZ);
    OrthoView_Callback(hObject,'slider-transverse',[]);
  end

 case {'set-gamma'}
  gammav = str2num(get(wgts.GammaEdt,'String'));
  if ~isempty(gammav),
    cmap = gray(256).^(1/gammav);
    axes(wgts.SagitalAxs);     colormap(cmap);
    axes(wgts.CoronalAxs);     colormap(cmap);
    axes(wgts.TransverseAxs);  colormap(cmap);
    axes(wgts.ColorbarAxs);    colormap(cmap);
  end
  
 case {'dir-reverse'}
  % note that image(),imagesc() reverse Y axies
  Xrev = get(wgts.XReverseCheck,'Value');
  Yrev = get(wgts.YReverseCheck,'Value');
  Zrev = get(wgts.ZReverseCheck,'Value');
  if Xrev == 0,
    corX = 'normal';   traX = 'normal';
  else
    corX = 'reverse';  traX = 'reverse';
  end
  if Yrev == 0,
    sagX = 'normal';   traY = 'reverse';
  else
    sagX = 'reverse';  traY = 'normal';
  end
  if Zrev == 0,
    sagY = 'reverse';  corY = 'reverse';
  else
    sagY = 'normal';   corY = 'normal';
  end
  set(wgts.SagitalAxs,   'xdir',sagX,'ydir',sagY);
  set(wgts.CoronalAxs,   'xdir',corX,'ydir',corY);
  set(wgts.TransverseAxs,'xdir',traX,'ydir',traY);

 case {'crosshair'}
  GRAHANDLE = getappdata(wgts.main,'GRAHANDLE');
  if ~isempty(GRAHANDLE),
    if get(wgts.CrosshairCheck,'value') == 0,
      set(GRAHANDLE.sagitalV,   'visible','off');
      set(GRAHANDLE.sagitalH,   'visible','off');
      set(GRAHANDLE.coronalV,   'visible','off');
      set(GRAHANDLE.coronalH,   'visible','off');
      set(GRAHANDLE.transverseV,'visible','off');
      set(GRAHANDLE.transverseH,'visible','off');
    else
      set(GRAHANDLE.sagitalV,   'visible','on');
      set(GRAHANDLE.sagitalH,   'visible','on');
      set(GRAHANDLE.coronalV,   'visible','on');
      set(GRAHANDLE.coronalH,   'visible','on');
      set(GRAHANDLE.transverseV,'visible','on');
      set(GRAHANDLE.transverseH,'visible','on');
    end
  end
  
 case {'button-sagital'}
  click = get(wgts.main,'SelectionType');
  if strcmpi(click,'alt') & get(wgts.CrosshairCheck,'Value') == 1,
    pt = round(get(wgts.SagitalAxs,'CurrentPoint'));
    iY = pt(1,1);  iZ = pt(1,2);
    if iY > 0 & iY <= size(ANA.dat,2),
      set(wgts.CoronalEdt,'String',sprintf('%d',iY));
      set(wgts.CoronalSldr,'Value',iY);
      OrthoView_Callback(hObject,'slider-coronal',[]);
    end
    if iZ > 0 & iZ <= size(ANA.dat,3),
      set(wgts.TransverseEdt,'String',sprintf('%d',iZ));
      set(wgts.TransverseSldr,'Value',iZ);
      OrthoView_Callback(hObject,'slider-transverse',[]);
    end
  elseif strcmpi(click,'open')
    iX = round(get(wgts.SagitalSldr,'Value'));
    src = wgts.SagitalAxs;
    hfig = figure;
    ha = axes;
    copyobj(allchild(src),ha);
    set(ha,'xlim',get(src,'xlim'),'xdir',get(src,'xdir'),'xcolor',get(src,'xcolor'),...
           'ylim',get(src,'ylim'),'ydir',get(src,'ydir'),'ycolor',get(src,'ycolor'),...
           'clim',get(src,'clim'),'color',get(src,'color'),...
           'fontname',get(src,'fontname'),'fontsize',get(src,'fontsize'),...
           'fontweight',get(src,'fontweight'));
    title(sprintf('%s Sagital(Y-Z): %d',ANA.session,iX),'fontweight','bold','fontsize',10);
    set(hfig,'colormap',get(wgts.main,'colormap'));
    hc = colorbar;
    set(hc,'xcolor',get(src,'xcolor'),'ycolor',get(src,'ycolor'),...
           'fontname',get(src,'fontname'),'fontsize',get(src,'fontsize'),...
           'fontweight',get(src,'fontweight'));
    set(findobj(ha),'ButtonDownFcn','');
  end
  
 case {'button-coronal'}
  click = get(wgts.main,'SelectionType');
  if strcmpi(click,'alt') & get(wgts.CrosshairCheck,'Value') == 1,
    pt = round(get(wgts.CoronalAxs,'CurrentPoint'));
    iX = pt(1,1);  iZ = pt(1,2);
    if iX > 0 & iX <= size(ANA.dat,1),
      set(wgts.SagitalEdt,'String',sprintf('%d',iX));
      set(wgts.SagitalSldr,'Value',iX);
      OrthoView_Callback(hObject,'slider-sagital',[]);
    end
    if iZ > 0 & iZ <= size(ANA.dat,3),
      set(wgts.TransverseEdt,'String',sprintf('%d',iZ));
      set(wgts.TransverseSldr,'Value',iZ);
      OrthoView_Callback(hObject,'slider-transverse',[]);
    end
  elseif strcmpi(click,'open')
    iY = round(get(wgts.CoronalSldr,'Value'));
    src = wgts.CoronalAxs;
    hfig = figure;
    ha = axes;
    copyobj(allchild(src),ha);
    set(ha,'xlim',get(src,'xlim'),'xdir',get(src,'xdir'),'xcolor',get(src,'xcolor'),...
           'ylim',get(src,'ylim'),'ydir',get(src,'ydir'),'ycolor',get(src,'ycolor'),...
           'clim',get(src,'clim'),'color',get(src,'color'),...
           'fontname',get(src,'fontname'),'fontsize',get(src,'fontsize'),...
           'fontweight',get(src,'fontweight'));
    title(sprintf('%s Coronal(X-Z): %d',ANA.session,iY),'fontweight','bold','fontsize',10);
    set(hfig,'colormap',get(wgts.main,'colormap'));
    hc = colorbar;
    set(hc,'xcolor',get(src,'xcolor'),'ycolor',get(src,'ycolor'),...
           'fontname',get(src,'fontname'),'fontsize',get(src,'fontsize'),...
           'fontweight',get(src,'fontweight'));
    set(findobj(ha),'ButtonDownFcn','');
  end

 case {'button-transverse'}
  click = get(wgts.main,'SelectionType');
  if strcmpi(click,'alt') & get(wgts.CrosshairCheck,'Value') == 1,
    pt = round(get(wgts.TransverseAxs,'CurrentPoint'));
    iX = pt(1,1);  iY = pt(1,2);
    if iX > 0 & iX <= size(ANA.dat,1),
      set(wgts.SagitalEdt,'String',sprintf('%d',iX));
      set(wgts.SagitalSldr,'Value',iX);
      OrthoView_Callback(hObject,'slider-sagital',[]);
    end
    if iY > 0 & iY <= size(ANA.dat,2),
      set(wgts.CoronalEdt,'String',sprintf('%d',iY));
      set(wgts.CoronalSldr,'Value',iY);
      OrthoView_Callback(hObject,'slider-coronal',[]);
    end
  elseif strcmpi(click,'open')
    iZ = round(get(wgts.TransverseSldr,'Value'));
    src = wgts.TransverseAxs;
    hfig = figure;
    ha = axes;
    copyobj(allchild(src),ha);
    set(ha,'xlim',get(src,'xlim'),'xdir',get(src,'xdir'),'xcolor',get(src,'xcolor'),...
           'ylim',get(src,'ylim'),'ydir',get(src,'ydir'),'ycolor',get(src,'ycolor'),...
           'clim',get(src,'clim'),'color',get(src,'color'),...
           'fontname',get(src,'fontname'),'fontsize',get(src,'fontsize'),...
           'fontweight',get(src,'fontweight'));
    title(sprintf('%s Transverse(X-Y): %d',ANA.session,iZ),'fontweight','bold','fontsize',10);
    set(hfig,'colormap',get(wgts.main,'colormap'));
    hc = colorbar;
    set(hc,'xcolor',get(src,'xcolor'),'ycolor',get(src,'ycolor'),...
           'fontname',get(src,'fontname'),'fontsize',get(src,'fontsize'),...
           'fontweight',get(src,'fontweight'));
    set(findobj(ha),'ButtonDownFcn','');
  end
  
 case {'button-triplot'}
  click = get(wgts.main,'SelectionType');
  if strcmpi(click,'open'),
    iX = round(get(wgts.SagitalSldr,'Value'));
    iY = round(get(wgts.CoronalSldr,'Value'));
    iZ = round(get(wgts.TransverseSldr,'Value'));
    src = wgts.TriplotAxs;
    hfig = figure;
    ha = axes;
    copyobj(allchild(src),ha);
    set(ha,'xlim',get(src,'xlim'),'xdir',get(src,'xdir'),'xcolor',get(src,'xcolor'),...
           'ylim',get(src,'ylim'),'ydir',get(src,'ydir'),'ycolor',get(src,'ycolor'),...
           'clim',get(src,'clim'),'color',get(src,'color'),...
           'fontname',get(src,'fontname'),'fontsize',get(src,'fontsize'),...
           'fontweight',get(src,'fontweight'));
    xlabel(get(get(src,'xlabel'),'string'));
    ylabel(get(get(src,'ylabel'),'string'));
    zlabel(get(get(src,'zlabel'),'string'));
    title(sprintf('Triplot (X,Y,Z)=(%d,%d,%d)',iX,iY,iZ),'fontweight','bold','fontsize',10);
    set(hfig,'colormap',get(wgts.main,'colormap'));
    hc = colorbar;
    set(hc,'xcolor',get(src,'xcolor'),'ycolor',get(src,'ycolor'),...
           'fontname',get(src,'fontname'),'fontsize',get(src,'fontsize'),...
           'fontweight',get(src,'fontweight'));
    axes(src);
    tmpview = view;
    axes(ha);
    view(tmpview);  grid on;
    set(findobj(ha),'ButtonDownFcn','');
  end

  
 otherwise
end


return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to handle lightbox view
function LightboxView_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(get(hObject,'Parent'));
ANA  = getappdata(wgts.main,'ANA');
MINV    = getappdata(wgts.main,'MINV');
MAXV    = getappdata(wgts.main,'MAXV');
CMAP    = getappdata(wgts.main,'CMAP');
ViewMode = get(wgts.ViewModeCmb,'String');
ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
switch lower(ViewMode),
 case {'lightbox-cor'}
  iDimension = 2;
 case {'lightbox-sag'}
  iDimension = 1;
 case {'lightbox-trans'}
  iDimension = 3;
 otherwise
  iDimension = 3;
end
nmaximages = size(ANA.dat,iDimension);

NCol = 4;
NRow = 5;

switch lower(eventdata),
 case {'init'}
  NPages = floor((nmaximages-1)/NCol/NRow)+1;
  tmptxt = {};
  for iPage = 1:NPages,
    tmptxt{iPage} = sprintf('Page%d: %d-%d',iPage,...
                            (iPage-1)*NCol*NRow+1,min([nmaximages,iPage*NCol*NRow]));
  end
  set(wgts.ViewPageList,'String',tmptxt,'Value',1);
  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  if strcmpi(ViewMode,'lightbox'),
    LightboxView_Callback(hObject,'redraw',handles);
  end
  
 case {'redraw'}
  axes(wgts.LightboxAxs);  cla;
  pagestr = get(wgts.ViewPageList,'String');
  pagestr = pagestr{get(wgts.ViewPageList,'Value')};
  ipage = sscanf(pagestr,'Page%d:');
  SLICES = (ipage-1)*NCol*NRow+1:min([nmaximages,ipage*NCol*NRow]);
  if iDimension == 1,
    nX = size(ANA.dat,2);  nY = size(ANA.dat,3);
    INFSTR = 'Sag';
    Xrev = get(wgts.YReverseCheck,'Value');
    Yrev = get(wgts.ZReverseCheck,'Value');
  elseif iDimension == 2,
    nX = size(ANA.dat,1);  nY = size(ANA.dat,3);
    INFSTR = 'Cor';
    Xrev = get(wgts.XReverseCheck,'Value');
    Yrev = get(wgts.ZReverseCheck,'Value');
  else
    nX = size(ANA.dat,1);  nY = size(ANA.dat,2);
    INFSTR = 'Trans';
    Xrev = get(wgts.XReverseCheck,'Value');
    Yrev = get(wgts.YReverseCheck,'Value');
  end
  X = [0:nX-1];  Y = [nY-1:-1:0];
  if Xrev > 0,  X = fliplr(X);  end
  if Yrev > 0,  Y = fliplr(Y);  end
  for N = 1:length(SLICES),
    iSlice = SLICES(N);
    if iDimension == 1,
      tmpimg = squeeze(ANA.dat(iSlice,:,:));
    elseif iDimension == 2,
      tmpimg = squeeze(ANA.dat(:,iSlice,:));
    else
      tmpimg = squeeze(ANA.dat(:,:,iSlice));
    end
    iRow = floor((N-1)/NCol)+1;
    iCol = mod((N-1),NCol)+1;
    offsX = nX*(iCol-1);
    offsY = nY*(NRow-iRow);
    %fprintf('%3d: [%d %d] -- [%d %d]\n',N,iRow,iCol,offsX,offsY);
    tmpx = X + offsX;  tmpy = Y + offsY;
    tmph = imagesc(tmpx,tmpy,tmpimg');  hold on;
    text(min(tmpx)+1,min(tmpy)+1,sprintf('%s=%d',INFSTR,iSlice),...
         'color',[0.9 0.9 0.5],'VerticalAlignment','bottom',...
         'tag','LightboxText',...
         'FontName','Comic Sans MS','FontSize',8,'Fontweight','bold');
    set(tmph,...
      'ButtonDownFcn','anaview(''LightboxView_Callback'',gcbo,''button'',guidata(gcbo))');
  end

  cmap = gray(256);
  gammav = str2num(get(wgts.GammaEdt,'String'));
  if ~isempty(gammav),
    cmap = gray(256).^(1/gammav);
  end
  axes(wgts.LightboxAxs);  colormap(cmap);
  set(gca,'Tag','LightboxAxs','color','black');
  set(gca,'XTickLabel',{},'YTickLabel',{},'XTick',[],'YTick',[]);
  set(gca,'xlim',[0 nX*NCol],'ylim',[0 nY*NRow],'clim',[MINV MAXV]);
  set(gca,'YDir','normal');
  
 case {'button'}
  click = get(wgts.main,'SelectionType');
  if strcmpi(click,'open'),
    % double click
    pagestr = get(wgts.ViewPageList,'String');
    pagestr = pagestr{get(wgts.ViewPageList,'Value')};
    ipage = sscanf(pagestr,'Page%d:');
    SLICES = (ipage-1)*NCol*NRow+1:min([nmaximages,ipage*NCol*NRow]); 

    subZoomInLightbox(iDimension,[NRow NCol],SLICES,wgts,ANA);
  end

 otherwise
end

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to zoom-in plot
function subZoomInLightbox(iDimension,NRowNCol,SLICES,wgts,ANA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isobject(wgts.main),
  fmain = wgts.main.Number;
else
  fmain = wgts.main;
end
hsrc = wgts.LightboxAxs;

if iDimension == 1,
  % sagital
  hfig = fmain + 1002;
  DX = ANA.ds(2);  DY = ANA.ds(3);
  tmpstr = sprintf('%s: SAGITAL %03d-%03d %s',ANA.session,SLICES(1),SLICES(end));
  tmpxlabel = 'Y (mm)';  tmpylabel = 'Z (mm)';
  nx = size(ANA.dat,2);
  ny = size(ANA.dat,3);
elseif iDimension == 2
  % coronal
  hfig = fmain + 1001;
  DX = ANA.ds(1);  DY = ANA.ds(3);
  tmpstr = sprintf('%s: CORONAL %03d-%03d %s',ANA.session,SLICES(1),SLICES(end));
  tmpxlabel = 'X (mm)';  tmpylabel = 'Z (mm)';
  nx = size(ANA.dat,1);
  ny = size(ANA.dat,3);
else
  % transverse
  hfig = fmain + 1003;
  DX = ANA.ds(1);  DY = ANA.ds(2);
  tmpstr = sprintf('%s: TRANSVERSE %03d-%03d %s',ANA.session,SLICES(1),SLICES(end));
  tmpxlabel = 'X (mm)';  tmpylabel = 'Y (mm)';
  nx = size(ANA.dat,1);
  ny = size(ANA.dat,2);
end


tmpstr = strrep(tmpstr,'\','/');

PLOT_COLORBAR = 1;

figure(hfig);  clf;
pos = get(hfig,'pos');
set(hfig,'Name',tmpstr,'pos',[pos(1)-680+pos(3) pos(2)-500+pos(4) 680 500]);
haxs = copyobj(hsrc,hfig);
set(haxs,'ButtonDownFcn','');  % clear callback function
set(hfig,'Colormap',get(wgts.main,'Colormap'));
h = findobj(haxs,'type','image');
for N = 1:length(h)
  set(h(N),'ButtonDownFcn','');  % clear callback function
  set(h(N),'xdata',get(h(N),'xdata')*DX,'ydata',get(h(N),'ydata')*DY);
end


% to keep actual size correct, do like this...
anasz = [size(ANA.dat,1) size(ANA.dat,2) size(ANA.dat,3)] .* ANA.ds;
maxsz = max(anasz);
%set(haxs,'Position',[0.01 0.1 nx*DX/100 ny*DY/100],'units','normalized');
if PLOT_COLORBAR,
  set(haxs,'Position',[0.10 0.11 0.8 0.815],'units','normalized');
else
  set(haxs,'Position',[0.01 0.1 nx*DX/maxsz ny*DY/maxsz],'units','normalized');
end
h = findobj(haxs,'tag','LightboxText');
for N =1:length(h),
  tmppos = get(h(N),'pos');
  tmppos(1) = tmppos(1)*DX;  tmppos(2) = tmppos(2)*DY;
  set(h(N),'pos',tmppos);
end
set(haxs,'xtickmode','auto','ytickmode','auto');
set(haxs,'xlim',get(haxs,'xlim')*DX,'ylim',get(haxs,'ylim')*DY);
set(haxs,'xtick',0:10:max(get(haxs,'xlim')));  % every 10mm
set(haxs,'ytick',0:10:max(get(haxs,'ylim')));  % every 10mm
AXISCOLOR = [0.8 0.2 0.8];
set(haxs,'xcolor',AXISCOLOR,'ycolor',AXISCOLOR);


set(haxs,'fontsize',8);
tmpv = get(haxs,'xtick');
tmpstr = repmat({''},size(tmpv));
if numel(tmpstr) > 1
  tmpstr{2} = sprintf('%g',tmpv(2)-tmpv(1));
end
if numel(tmpstr) > 5
  tmpstr{6} = sprintf('%g',tmpv(6)-tmpv(1));
end
set(haxs,'xticklabel',tmpstr);

tmpv = get(haxs,'ytick');
tmpstr = repmat({''},size(tmpv));
if numel(tmpstr) > 1
  tmpstr{2} = sprintf('%g',tmpv(2)-tmpv(1));
end
if numel(tmpstr) > 5
  tmpstr{6} = sprintf('%g',tmpv(6)-tmpv(1));
end
set(haxs,'yticklabel',tmpstr);


xlabel(tmpxlabel);  ylabel(tmpylabel);
title(haxs,strrep(tmpstr,'_','\_'));
%title(haxs,tmpstr);
daspect(haxs,[1 1 1]);

if PLOT_COLORBAR,
  pos = get(haxs,'pos');
  hbar = copyobj(wgts.ColorbarAxs,hfig);
  set(hbar,'pos',[0.85 pos(2) 0.045 pos(4)]);
end

return

