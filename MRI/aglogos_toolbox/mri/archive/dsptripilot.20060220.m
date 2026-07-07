function varargout = dsptripilot(varargin)
%DSPTRIPILOT - displays tripilot scan
%  DSPTRIPILOT(SESSION,EXPNO) displays tripilot scan for SESSION/EXPNO.
%  DSPTRIPILOT(TRIPILOT{N}) displays TRIPILOT{N} saved in tripilot.mat.
%
%  NOTE :
%    SESASCAN(SESSION) will save tripilot scan(s).  See SESASCAN for detail.
%
%  VERSION :
%    0.90 17.02.06 YM  pre-release
%    0.91 19.02.06 YM  supports 'zoom-in'.
%
%  See also SESASCAN GETPVPARS EXPGETPAR

if nargin == 0,  feval(@help,mfilename); return;  end

% execute callback function then return;
if ischar(varargin{1}) & ~isempty(findstr(varargin{1},'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return;
end



if isstruct(varargin{1}) & isfield(varargin{1},'dat'),
  % dsptripilot(TRIPILOT{X})
  TRIPILOT = varargin{1};
  GRP    = {};
  EXPPAR = {};
else
  % dsptripilot(SESSION,ExpNo)
  Ses = goto(varargin{1});
  if nargin > 1,
    ExpNo = varargin{2};
  else
    ExpNo = getexps(Ses);  ExpNo = ExpNo(1);
  end
  GRP = getgrp(Ses,ExpNo);
  TRIPILOT = load('tripilot.mat','tripilot');
  TRIPILOT = TRIPILOT.tripilot;
  if isfield(GRP,'tripilot') & GRP.tripilot > 0,
    TRIPILOT = TRIPILOT{GRP.tripilot};
  else
    fprintf('WARNING %s: assuming ASCAN.tripilot{1} as tripilot.\n',mfilename);
    fprintf('        %s: If not, add GRPP.tripilot/GRP.xxx.tripilot = X;\n',mfilename);
    TRIPILOT = TRIPILOT{1};
  end
  EXPPAR = expgetpar(Ses,ExpNo);
end


% 
TRIPILOT.dat(:,:,1) = TRIPILOT.dat(:,end:-1:1,1);
TRIPILOT.dat(:,:,2) = TRIPILOT.dat(end:-1:1,:,2);  % flipping L-R



TRIPILOT.dat = double(TRIPILOT.dat);


% min, max, gamma
anamin   = 0;
anamax   = round(max(TRIPILOT.dat(:)) * 0.7);
anagamma = 1.8;
TRIPILOT.anascale = [anamin, anamax, anagamma];



% GET SCREEN SIZE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[scrW scrH] = subGetScreenSize('char');

figW = 170; figH = 55;
figX = 31;  figY = scrH-figH-5;


% CREATE A MAIN FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hMain = figure(...
    'Name',mfilename,...
    'NumberTitle','off', 'toolbar','figure',...
    'Tag','main', 'units','char', 'pos',[figX figY figW figH],...
    'HandleVisibility','on', 'Resize','on',...
    'DoubleBuffer','on', 'BackingStore','on', 'Visible','on',...
    'DefaultAxesFontSize',10,...
    'DefaultAxesFontName', 'Comic Sans MS',...
    'DefaultAxesfontweight','bold',...
    'PaperPositionMode','auto', 'PaperType','A4', 'PaperOrientation', 'landscape');


% AXES FOR IMAGES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 30; XSZ = 70; YSZ = 22;
XDSP=10;
CoronalTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H+YSZ 20 1.5],...
    'String','Coronal (X-Z)','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','CoronalTxt',...
    'BackgroundColor',get(hMain,'Color'));
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
TransverseAxs = axes(...
    'Parent',hMain,'Tag','TransverseAxs',...
    'Units','char','Position',[XDSP H XSZ YSZ],...
    'Box','off','Color','black');

% WIDGETS TO CONTORL SCALING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmpstr = sprintf('%d  %d',TRIPILOT.anascale(1),TRIPILOT.anascale(2));
AnaMinMaxTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+10+XSZ+15, H+YSZ-1.5 20 1.25],...
    'String','min-max: ','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'BackgroundColor',get(hMain,'color'));
AnaMinMaxEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+10+XSZ+27, H+YSZ-1.5 15 1.5],...
    'Callback','dsptripilot(''Plot_Callback'',gcbo,[],[])',...
    'String',tmpstr,'Tag','AnaMinMaxEdt',...
    'Callback','dsptripilot(''Main_Callback'',gcbo,''redraw'',guidata(gcbo))',...
    'HorizontalAlignment','center',...
    'TooltipString','set anatomy min max',...
    'FontWeight','Bold');
clear tmpstr;
% COLORBAR GAMAMA SETTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmpstr = sprintf('%.1f',TRIPILOT.anascale(3));
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+10+XSZ+45, H+YSZ-1.5 20 1.25],...
    'String','gamma: ','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'BackgroundColor',get(hMain,'color'));
AnaGammaEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+10+XSZ+55, H+YSZ-1.5 15 1.5],...
    'Callback','dsptripilot(''Main_Callback'',gcbo,''redraw'',guidata(gcbo))',...
    'String',tmpstr,'Tag','AnaGammaEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set anatomy gamma',...
    'FontWeight','bold');
clear tmpstr;
% CHECK BOX FOR "cross-hair" %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CrosshairCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+10+XSZ+15, H+YSZ-3.5 15 1.5],...
    'Callback','dsptripilot(''Main_Callback'',gcbo,''update-crosshair'',guidata(gcbo))',...
    'Tag','CrosshairCheck','Value',1,...
    'String','Crosshair','FontWeight','bold',...
    'TooltipString','show a crosshair','BackgroundColor',get(hMain,'Color'));
% CHECK BOX FOR "slices" %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SlicesCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+10+XSZ+15+20, H+YSZ-3.5 15 1.5],...
    'Callback','dsptripilot(''Main_Callback'',gcbo,''update-slices'',guidata(gcbo))',...
    'Tag','SlicesCheck','Value',~isempty(EXPPAR),...
    'String','Slices','FontWeight','bold',...
    'TooltipString','show slices','BackgroundColor',get(hMain,'Color'));
% INFORMATION TEXT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 3.0;
InfoTxt = uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','char','Position',[XDSP+10+XSZ+15 H 55 17],...
    'String',{'session','group','datsize','resolution'},...
    'HorizontalAlignment','left',...
    'FontName','Comic Sans MS','FontSize',8,...
    'Tag','InfoTxt','Background','white');





% get widgets handles at this moment
HANDLES = findobj(hMain);


% INITIALIZE THE APPLICATION
setappdata(hMain,'TRIPILOT',TRIPILOT);
setappdata(hMain,'GRP',     GRP);
setappdata(hMain,'EXPPAR',  EXPPAR);
Main_Callback(hMain,'init',[]);
set(hMain,'visible','on');


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
TRIPILOT = getappdata(wgts.main,'TRIPILOT');
GRP      = getappdata(wgts.main,'GRP');
EXPPAR   = getappdata(wgts.main,'EXPPAR');

switch lower(eventdata),
 case {'init'}
  infotxt = subGetInfoText(TRIPILOT,GRP,EXPPAR);
  set(wgts.InfoTxt,'String',infotxt);
  
  Main_Callback(hObject,'redraw',[]);
  
 case {'redraw'}
  anagamma = str2num(get(wgts.AnaGammaEdt,'String'));
  if isempty(anagamma),
    anagamma = TRIPILOT.anascale(3);
    set(wgts.AnaGammaEdt,'String',sprintf('%.1f',anagamma));
  end
  anaminmax = str2num(get(wgts.AnaMinMaxEdt,'String'));
  if length(anaminmax) == 2,
    anamin = anaminmax(1);
    anamax = anaminmax(2);
  else
    anamin = TRIPILOT.anascale(1);
    anamax = TRIPILOT.anascale(2);
    set(wgts.AnaMinMaxEdt,'String',sprintf('%d  %d',anamin,anamax));
  end
  
  TRIPILOT.rgb = subScaleAnatomy(TRIPILOT,anamin,anamax,anagamma);
  TRIPILOT.anascale = [anamin anamax anagamma];
  setappdata(wgts.main,'TRIPILOT',TRIPILOT);
  
  for N = 1:3,
    subDrawImage(wgts,TRIPILOT,N);
  end

  Main_Callback(hObject,'update-crosshair',[]);
  Main_Callback(hObject,'update-slices',[]);
  

 case {'update-crosshair'}
  h = [wgts.TransverseAxs, wgts.SagitalAxs, wgts.CoronalAxs];
  for N = 1:3,
    haxs = h(N);
    if get(wgts.CrosshairCheck,'Value') > 0,
      axes(h(N));
      line([0 0], get(haxs,'ylim'), 'color','y','tag','crosshair');
      line(get(haxs,'xlim'), [0 0], 'color','y','tag','crosshair');
    else
      delete(findobj(haxs,'tag','crosshair'));
    end
  end
  
 case {'update-slices'}
  if ~isempty(EXPPAR) & get(wgts.SlicesCheck,'Value') > 0,
    subDrawSlices(wgts,EXPPAR.pvpar.acqp,EXPPAR.pvpar.reco);
  else
    h = [wgts.TransverseAxs, wgts.SagitalAxs, wgts.CoronalAxs];
    for N = 1:3,
      haxs = h(N);
      delete(findobj(haxs,'tag','slices'));
    end
  end
  
 case {'button-transverse'}
  click = get(wgts.main,'SelectionType');
  if strcmpi(click,'open'),
    % double click
    subZoomIn('transverse',wgts,TRIPILOT,GRP);
  end
 case {'button-sagital'}
  click = get(wgts.main,'SelectionType');
  if strcmpi(click,'open'),
    % double click
    subZoomIn('sagital',wgts,TRIPILOT,GRP);
  end
 case {'button-coronal'}
  click = get(wgts.main,'SelectionType');
  if strcmpi(click,'open'),
    % double click
    subZoomIn('coronal',wgts,TRIPILOT,GRP);
  end
       
  
 otherwise
  
end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to scale anatomy image
function infotxt = subGetInfoText(TRIPILOT,GRP,EXPPAR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

infotxt{1} = TRIPILOT.session;
if ~isempty(GRP),
  acqp = EXPPAR.pvpar.acqp;  reco = EXPPAR.pvpar.reco;
  % ACQP parameters
  infotxt{1} = sprintf('%s  %s',infotxt{1},GRP.name);
  infotxt{2} = sprintf('NSLICES= %d',acqp.NSLICES);
  if isfield(acqp,'ACQ_fov'),
    tmptxt = deblank(sprintf('%.2f ',acqp.ACQ_fov));
    infotxt{end+1} = sprintf('ACQ_fov= [%s] cm',tmptxt);
  end
  if isfield(acqp,'ACQ_size'),
    tmptxt = deblank(sprintf('%d ',acqp.ACQ_size));
    infotxt{end+1} = sprintf('ACQ_size= [%s]',tmptxt);
  end
  if isfield(acqp,'ACQ_slice_orient'),
    infotxt{end+1} = sprintf('ACQ_slice_orient= ''%s''',acqp.ACQ_slice_orient);
  end
  if isfield(acqp,'ACQ_slice_angle'),
    tmptxt = deblank(sprintf('%.2f ',acqp.ACQ_slice_angle));
    infotxt{end+1} = sprintf('ACQ_slice_angle= %s',tmptxt);
  end
  if isfield(acqp,'ACQ_phase1_offset'),
    tmptxt = deblank(sprintf('%.2f ',acqp.ACQ_phase1_offset));
    infotxt{end+1} = sprintf('ACQ_phase1_offset= [%s]',tmptxt);
  end
  if isfield(acqp,'ACQ_phase2_offset'),
    tmptxt = deblank(sprintf('%.2f ',acqp.ACQ_phase2_offset));
    infotxt{end+1} = sprintf('ACQ_phase2_offset= [%s]',tmptxt);
  end
  if isfield(acqp,'ACQ_slice_thick'),
    infotxt{end+1} = sprintf('ACQ_slice_thick= %.2f mm',acqp.ACQ_slice_thick);
  end
  if isfield(acqp,'ACQ_slice_sepn'),
    tmptxt = deblank(sprintf('%.2f ',acqp.ACQ_slice_sepn));
    infotxt{end+1} = sprintf('ACQ_slice_sepn= [%s] mm',tmptxt);
  end
  % RECO parameters
  if isfield(reco,'RECO_fov'),
    tmptxt = deblank(sprintf('%.2f ',reco.RECO_fov));
    infotxt{end+1} = sprintf('RECO_fov= [%s] cm',tmptxt);
  end
  if isfield(reco,'RECO_size'),
    tmptxt = deblank(sprintf('%d ',reco.RECO_size));
    infotxt{end+1} = sprintf('RECO_size= [%s]',tmptxt);
  end
  if isfield(reco,'RECO_wordtype'),
    infotxt{end+1} = sprintf('RECO_wordtype= ''%s''',reco.RECO_wordtype);
  end
  if isfield(reco,'RECO_byte_order'),
    infotxt{end+1} = sprintf('RECOO_byte_order= ''%s''',reco.RECO_byte_order);
  end
end

return;


  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to scale anatomy image
function ANARGB = subScaleAnatomy(ANA,MINV,MAXV,GAMMA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isstruct(ANA),
  tmpana = double(ANA.dat);
else
  tmpana = double(ANA);
end
clear ANA;
tmpana = (tmpana - MINV) / (MAXV - MINV);
tmpana = round(tmpana*255) + 1; % +1 for matlab indexing
tmpana(find(tmpana(:) <   0)) =   1;
tmpana(find(tmpana(:) > 256)) = 256;
anacmap = gray(256).^(1/GAMMA);
for N = size(tmpana,3):-1:1,
  ANARGB(:,:,:,N) = ind2rgb(tmpana(:,:,N),anacmap);
end
ANARGB = permute(ANARGB,[1 2 4 3]);  % [x,y,rgb,z] --> [x,y,z,rgb]

  
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to draw images
function subDrawImage(wgts,TRIPILOT,IDX)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if IDX == 1,
  % transverse
  haxs = wgts.TransverseAxs;
  tag = 'TransverseAxs';
  ButtonDownFcn = 'dsptripilot(''Main_Callback'',gcbo,''button-transverse'',guidata(gcbo))';
elseif IDX == 2,
  % sagital
  haxs = wgts.SagitalAxs;
  tag = 'SagitalAxs';
  ButtonDownFcn = 'dsptripilot(''Main_Callback'',gcbo,''button-sagital'',guidata(gcbo))';
else
  % coronal
  haxs = wgts.CoronalAxs;
  tag = 'CoronalAxs';
  ButtonDownFcn = 'dsptripilot(''Main_Callback'',gcbo,''button-coronal'',guidata(gcbo))';
end
% should be the same voxel size...
dx = TRIPILOT.ds(1);
dy = TRIPILOT.ds(2);
tmpimg = squeeze(TRIPILOT.rgb(:,:,IDX,:));  % x,y,z,rgb
tmpx   = [0:size(tmpimg,1)-1] * dx - size(tmpimg,1)*dx/2;
tmpy   = [0:size(tmpimg,2)-1] * dy - size(tmpimg,2)*dy/2;




AXISCOLOR = [0.8 0.2 0.8];
axes(haxs);
h = image(tmpx,tmpy,permute(tmpimg,[2 1 3]));
set(h,'ButtonDownFcn',ButtonDownFcn);

set(haxs,'tag',tag);
set(haxs,'fontsize',8,'xcolor',AXISCOLOR,'ycolor',AXISCOLOR);
set(haxs,'xlim',[min(tmpx) max(tmpx)],'ylim',[min(tmpy) max(tmpy)]);


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to draw images
function subDrawSlices(wgts,acqp,reco)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(acqp),  return;  end

fov    = acqp.ACQ_fov;           % FOV in cm
fov    = fov * 10;               % in mm
sliori = acqp.ACQ_slice_orient;  % slice orientaion

slithk  = acqp.ACQ_slice_thick;  % slice thickness in mm
isodist = acqp.ACQ_slice_offset;  % offset to the ISO center for each image in mm



slsepn = acqp.ACQ_slice_sepn;    % slice separation in mm
slthic = acqp.ACQ_slice_thick;   % slice thickness in mm
sloffs = acqp.ACQ_slice_offset;  % offset to the ISO center for each image in mm

%slreadoffs = acqp.ACQ_read_offset;


RECTCOLOR = [0.8 0.2 0.8];
%RECTCOLOR = [0.9 0.9 0.2];

haxs = wgts.SagitalAxs;
axes(haxs);
tmpw = slithk;  tmph = fov(2);
for N = 1:length(isodist),
  tmpx = isodist(N) - tmpw/2;
  tmpy = - tmph/2;
  rectangle('Position',[tmpx tmpy tmpw tmph],...
            'EdgeColor',RECTCOLOR,'tag','slices');
  
end

haxs = wgts.TransverseAxs;
axes(haxs);
tmpw = fov(1);  tmph = slithk;
for N = 1:length(isodist),
  tmpx = - tmpw/2;
  tmpy = isodist(N) - tmph/2;
  rectangle('Position',[tmpx tmpy tmpw tmph],...
            'EdgeColor',RECTCOLOR,'tag','slices');
  
end

  
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to zoom-in plot
function subZoomIn(planestr,wgts,TRIPILOT,GRP)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch lower(planestr)
 case {'coronal'}
  hfig = wgts.main + 1001;
  hsrc = wgts.CoronalAxs;
  tmpstr = sprintf('Tripilot CORONAL: %s', TRIPILOT.session);
  tmpxlabel = 'X (mm)';  tmpylabel = 'Z (mm)';
 case {'sagital'}
  hfig = wgts.main + 1002;
  hsrc = wgts.SagitalAxs;
  tmpstr = sprintf('Tripilot SAGITAL: %s',TRIPILOT.session);
  tmpxlabel = 'Y (mm)';  tmpylabel = 'Z (mm)';
 case {'transverse'}
  hfig = wgts.main + 1003;
  hsrc = wgts.TransverseAxs;
  tmpstr = sprintf('Tripilot TRANSVERSE: %s',TRIPILOT.session);
  tmpxlabel = 'X (mm)';  tmpylabel = 'Y (mm)';
end
if ~isempty(GRP),
  tmpstr = sprintf('%s %s',tmpstr,GRP.name);
end


figure(hfig);  clf;
pos = get(hfig,'pos');
pos = [pos(1)-(680-pos(3)) pos(2)-(500-pos(4)) 680 500];
% sometime, wiondow is outside the screen....why this happens??
[scrW scrH] = subGetScreenSize('pixels');
if pos(1) < -pos(3) | pos(1) > scrW,  pos(1) = 1;  end
if pos(2)+pos(4) < 0 | pos(2)+pos(4)+70 > scrH,  pos(2) = scrH-pos(4)-70;  end
set(hfig,'Name',tmpstr,'pos',pos);
haxs = copyobj(hsrc,hfig);
set(haxs,'ButtonDownFcn','');  % clear callback function
set(hfig,'Colormap',get(wgts.main,'Colormap'));
h = findobj(haxs,'type','image');
set(h,'ButtonDownFcn','');  % clear callback function

set(haxs,'Position',[0.08 0.1 0.75 0.75],'units','normalized');
set(haxs,'xtick',[-200:10:200]);
set(haxs,'ytick',[-200:10:200]);


xlabel(tmpxlabel);  ylabel(tmpylabel);
title(haxs,tmpstr);
daspect(haxs,[1 1 1]);
pos = get(haxs,'pos');
%hbar = copyobj(wgts.ColorbarAxs,hfig);
%set(hbar,'pos',[0.85 pos(2) 0.045 pos(4)]);    
%ylabel(hbar,DatName);

%clear callbacks
set(haxs,'ButtonDownFcn','');
set(allchild(haxs),'ButtonDownFcn','');

% make font size bigger
set(haxs,'FontSize',10);
set(get(haxs,'title'),'FontSize',10);
set(get(haxs,'xlabel'),'FontSize',10);
set(get(haxs,'ylabel'),'FontSize',10);
%set(hbar,'FontSize',10);
%set(get(hbar,'ylabel'),'FontSize',10);

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to get screen size
function [scrW scrH] = subGetScreenSize(Units)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
oldUnits = get(0,'Units');
set(0,'Units',Units);
sz = get(0,'ScreenSize');
set(0,'Units',oldUnits);

scrW = sz(3);  scrH = sz(4);

return;
