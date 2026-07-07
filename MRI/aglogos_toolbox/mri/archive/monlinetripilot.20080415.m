function varargout = monlinetripilot(varargin)
%MONLINETRIPILOT - viewer for tripilot scan
%  MONLINETRIPILOT  called by MONLINE.
%
%  EXAMPLE :
%    >> monline
%    >> monlinetripilot(SIG)
%
%  NOTES :
%    This function will be called by monline.m after processing data.
%
%  VERSION :
%    0.90 14.04.08 YM  pre-release
%
%  See also MONLINE MONLINEPROC MONLINEVIEW MONLINEPVPAR

% display help if no arguments %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 0,  help monlinetripilot; return;  end


% execute callback function then return; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(varargin{1}) & ~isempty(findstr(varargin{1},'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return;
end


% PREPARE DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(varargin{1}),
  % called like monlinetripilot(TRIPILOT_FILE,IMAGE_FILE)
  ONLINE = subLoadData(varargin{1},varargin{2});
  ivar = 3;
else
  % called like monlinetripilot(SIG)
  ONLINE = varargin{1};
  % no need to keep a big data for this tripilot
  if isfield(ONLINE,'dat'),  ONLINE.dat = [];  end
  ivar = 2;
end

hMain = [];
for N=ivar:2:length(varargin),
  switch lower(varargin{N}),
   case {'hfig','figure','hmain'}
    hMain = varargin{N+1};
  end
end


anaminv = 0;
anamaxv = round(mean(ONLINE.tripilot.dat(:))*7.0);
anagamma = 1.8;
ONLINE.tripilot.anargb = subScaleAnatomy(ONLINE.tripilot.dat,anaminv,anamaxv,anagamma);
ONLINE.tripilot.anascale = [anaminv anamaxv anagamma];




% GET SCREEN SIZE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[scrW scrH] = subGetScreenSize('char');
% keep the figure size smaller than XGA (1024x768) for notebook PC.
% figWH: [185 57]chars = [925 741]pixels
figW = 162; figH = 57;
figX = max(min(63,scrW-figW),10);
figY = scrH-figH-9.7;


% SET WINDOW TITLE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmptitle = sprintf('%s:  %s  %d/%d  %s',...
                   mfilename,ONLINE.session,ONLINE.scanreco(1),ONLINE.scanreco(2),...
                   datestr(now));


if ishandle(hMain),
  % update 'ONLINE' data
  setappdata(hMain,'ONLINE',ONLINE);
  Main_Callback(hMain,'init');
  return
elseif ~isempty(hMain),
  figure(hMain);  clf;
  set(hMain,...
      'Name',tmptitle,...
      'NumberTitle','off', 'toolbar','figure',...
      'Tag','main', 'units','char', 'pos',[figX figY figW figH],...
      'HandleVisibility','on', 'Resize','on',...
      'DoubleBuffer','on', 'BackingStore','on', 'Visible','on',...
      'DefaultAxesFontSize',8,...
      'DefaultAxesfontweight','bold',...
      'PaperPositionMode','auto', 'PaperType','A4', 'PaperOrientation', 'landscape');
  
else
  % CREATE A MAIN FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  hMain = figure(...
      'Name',tmptitle,...
      'NumberTitle','off', 'toolbar','figure',...
      'Tag','main', 'units','char', 'pos',[figX figY figW figH],...
      'HandleVisibility','on', 'Resize','on',...
      'DoubleBuffer','on', 'BackingStore','on', 'Visible','on',...
      'DefaultAxesFontSize',8,...
      'DefaultAxesfontweight','bold',...
      'PaperPositionMode','auto', 'PaperType','A4', 'PaperOrientation', 'landscape');
end




% CREATE AXES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 3; XSZ = 68; YSZ = 24.5;
XDSP=8;
TraAxs = axes(...
    'Parent',hMain,'Tag','TraAxs',...
    'Units','char','Position',[XDSP H+YSZ+H XSZ YSZ],...
    'Box','off','color','black','Visible','on');
SagAxs = axes(...
    'Parent',hMain,'Tag','SagAxs',...
    'Units','char','Position',[XDSP+XSZ+10 H+YSZ+H XSZ YSZ],...
    'Box','off','color','black','Visible','on');
CorAxs = axes(...
    'Parent',hMain,'Tag','CorAxs',...
    'Units','char','Position',[XDSP H XSZ YSZ],...
    'Box','off','color','black','Visible','on');

% INFORMATION LIST %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
InfoTxt = uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','char','Position',[XDSP+XSZ+10 H XSZ 14],...
    'String',{'session','group','datsize','resolution'},...
    'HorizontalAlignment','left',...
    'FontName','Comic Sans MS','FontSize',9,...
    'TooltipString','Double-click invokes ACQP/METHOD/RECO window',...
    'Callback','monlinetripilot(''Main_Callback'',gcbo,''show-pvpar'',guidata(gcbo))',...
    'Tag','InfoTxt','Background','white');


% Superimpose or not %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 3 + YSZ - 1.5;
OverlayCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+XSZ+10 H 20 1.5],...
    'Tag','OverlayCheck','Value',1,...
    'Callback','monlinetripilot(''Main_Callback'',gcbo,''redraw'',guidata(gcbo))',...
    'String','Overlay','FontWeight','bold',...
    'TooltipString','slice on/off','BackgroundColor',get(hMain,'Color'));
CrosshairCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+XSZ+10+20 H 20 1.5],...
    'Tag','CrosshairCheck','Value',1,...
    'Callback','monlinetripilot(''Main_Callback'',gcbo,''redraw'',guidata(gcbo))',...
    'String','Crosshair','FontWeight','bold',...
    'TooltipString','crosshair on/off','BackgroundColor',get(hMain,'Color'));


% ANATOMY SCALE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 3 + YSZ - 3.5;
AnatScaleTxt =  uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+XSZ+10 H-0.3 30 1.5],...
    'String','Anat. Scale:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','AnatScaleTxt',...
    'BackgroundColor',get(hMain,'Color'));
AnatScaleEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+XSZ+10+20, H 30 1.5],...
    'String',sprintf('%g  %g  %g',anaminv,anamaxv,anagamma),...
    'Tag','AnatScaleEdt',...
    'Callback','monlinetripilot(''Main_Callback'',gcbo,''update-anatomy'',guidata(gcbo))',...
    'HorizontalAlignment','center',...
    'TooltipString','Scale anatomy [min max gamma]',...
    'FontWeight','Bold');


% get widgets handles at this moment
HANDLES = findobj(hMain);


% INITIALIZE THE APPLICATION
setappdata(hMain,'ONLINE',ONLINE);
Main_Callback(hMain,'init');
set(hMain,'visible','on');


% NOW SET "UNITS" OF ALL WIDGETS AS "NORMALIZED".
HANDLES = HANDLES(find(HANDLES ~= hMain));
set(HANDLES,'units','normalized');



% RETURNS THE WINDOW HANDLE IF REQUIRED.
if nargout,
  varargout{1} = hMain;
end


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pvpar = subGetPvPar(ACQP,RECO,IMND,METHOD)
pvpar.acqp = ACQP;
pvpar.reco = RECO;
if ~isempty(METHOD),
  pvpar.method = METHOD;
end
if ~isempty(IMND),
  pvpar.imnd   = IMND;
end

% basic info
pvpar.nx   = RECO.RECO_size(1);
pvpar.ny   = RECO.RECO_size(2);
pvpar.nsli = ACQP.NSLICES;
pvpar.nt   = ACQP.NR;
if ~isempty(METHOD),
  pvpar.nseg = METHOD.PVM_EpiNShots;
else
  pvpar.nseg = IMND.IMND_numsegments;
  if strcmpi(IMND.EPI_segmentation_mode,'No_Segments')    % glitch for EPI
    pvpar.nseg   = 1;			
  end
end
pvpar.ds(1) = RECO.RECO_fov(1) / RECO.RECO_size(1) * 10;
pvpar.ds(2) = RECO.RECO_fov(2) / RECO.RECO_size(2) * 10;
if length(ACQP.ACQ_slice_offset) > 1,
  pvpar.ds(3) = mean(diff(ACQP.ACQ_slice_offset));
else
  %pvpar.ds(3) = ACQP.ACQ_slice_sepn;
  pvpar.ds(3) = ACQP.ACQ_slice_thick;
end
% timings in seconds
if ~isempty(METHOD),
  pvpar.slitr = ACQP.ACQ_repetition_time/1000/ACQP.NSLICES;
  pvpar.segtr = ACQP.ACQ_repetition_time/1000;
  pvpar.imgtr = ACQP.ACQ_repetition_time/1000*METHOD.PVM_EpiNShots;
  pvpar.effte = METHOD.EchoTime/1000;
  pvpar.recovtr = ACQP.ACQ_recov_time(:)'/1000;
else
  if strncmp(ACQP.PULPROG, '<BLIP_epi',9)
    pvpar.slitr	= IMND.EPI_slice_rep_time/1000;
    pvpar.segtr	= IMND.IMND_rep_time;       
    pvpar.imgtr	= pvpar.segtr * pvpar.nseg;
    if strcmpi(IMND.EPI_scan_mode,'FID')
      pvpar.effte = IMND.EPI_TE_eff/1000;
    else
      pvpar.effte = IMND.IMND_echo_time/1000;
    end
  else
    pvpar.slitr	= IMND.IMND_rep_time;
    pvpar.segtr	= IMND.IMND_acq_time/1000;
    pvpar.imgtr	= pvpar.slitr;
    pvpar.effte	= IMND.IMND_echo_time/1000;
  end
  pvpar.recovtr	= IMND.IMND_recov_time(:)'/1000;
end
  
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SIG = subLoadData(TRIPILOT_FILE,IMAGE_FILE)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get tripilot data
[TRIDAT TACQP TRECO] = pvread_2dseq(TRIPILOT_FILE);
ds = TRECO.RECO_fov ./ TRECO.RECO_size * 10;  % in mm
ds(3) = ds(1);

TRIPILOT.dat = TRIDAT;
TRIPILOT.ds  = ds;
TRIPILOT.pvpar.acqp = TACQP;
TRIPILOT.pvpar.reco = TRECO;

% Get info for imaging
ACQP   = pvread_acqp(IMAGE_FILE,'verbose',0);
IMND   = pvread_imnd(IMAGE_FILE,'verbose',0);
METHOD = pvread_method(IMAGE_FILE,'verbose',0);
RECO   = pvread_reco(IMAGE_FILE,'verbose',0);

p = IMAGE_FILE;
for N = 1:5,
  [p,f,e] = fileparts(p);
  if N == 2,
    recov = str2num(f);
  elseif N == 4,
    scanv = str2num(f);
  elseif N == 5,
    sespath = p;
    sesname = strcat(f,e);
  end
end

% prepare return structure
SIG.imgfile  = IMAGE_FILE;
SIG.path     = sespath;
SIG.session  = sesname;
SIG.scanreco = [scanv recov];
SIG.tripilot = TRIPILOT;
SIG.pvpar    = subGetPvPar(ACQP,RECO,IMND,METHOD);
  
return


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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Main_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%fprintf('Main_Callback.%s\n',eventdata);
wgts = guihandles(hObject);
switch lower(eventdata),
 case {'init'}
  ONLINE = getappdata(wgts.main,'ONLINE');
  
  % set information text
  pvpar = ONLINE.pvpar;
  INFTXT = {};
  INFTXT{end+1} = sprintf('%s  %d/%d',ONLINE.session,ONLINE.scanreco(1),ONLINE.scanreco(2));
  INFTXT{end+1} = sprintf('%s',pvpar.acqp.ACQ_time(2:end-1));
  INFTXT{end+1} = sprintf('%s',pvpar.acqp.PULPROG);
  INFTXT{end+1} = sprintf('[%dx%dx%d/%d]',pvpar.nx,pvpar.ny,pvpar.nsli,pvpar.nt);
  INFTXT{end+1} = sprintf('[%gx%gx%g]',pvpar.ds(1),pvpar.ds(2),pvpar.ds(3));
  INFTXT{end+1} = sprintf('nseg=%d, imgtr=%gs',pvpar.nseg,pvpar.imgtr);
  
  set(wgts.InfoTxt,'String',INFTXT);
  Main_Callback(hObject,'redraw',[]);
  
 case {'update-anatomy'}
  anascale = str2num(get(wgts.AnatScaleEdt,'String'));
  if length(anascale) == 3,
    ONLINE = getappdata(wgts.main,'ONLINE');
    ONLINE.tripilot.anargb = subScaleAnatomy(ONLINE.tripilot.dat,anascale(1),anascale(2),anascale(3));
    ONLINE.tripilot.anascale = anascale;
    setappdata(wgts.main,'ONLINE',ONLINE);
    Main_Callback(hObject,'redraw',[]);
  end
 
 case {'redraw'}
  ONLINE = getappdata(wgts.main,'ONLINE');
  IMGDAT = ONLINE.tripilot.anargb;
  imgsz  = size(ONLINE.tripilot.dat);
  imgres = ONLINE.tripilot.ds;
  IMGDAT = permute(IMGDAT,[2 1 3 4]);  % (x,y,z,color) --> (y,x,z,color)
  
  tmpX = [0:imgsz(1)-1]*imgres(1) - imgsz(1)*imgres(1)/2;
  tmpY = [0:imgsz(2)-1]*imgres(2) - imgsz(2)*imgres(2)/2;
  
  axes(wgts.TraAxs);
  image(tmpX,tmpY,squeeze(IMGDAT(:,:,1,:)));
  daspect([2 2 1]);
  set(gca,'Tag','TraAxs');
  
  axes(wgts.SagAxs);
  image(tmpX,tmpY,squeeze(IMGDAT(:,:,2,:)));
  daspect([2 2 1]);
  set(gca,'Tag','SagAxs');

  axes(wgts.CorAxs);
  image(tmpX,tmpY,squeeze(IMGDAT(:,:,3,:)));
  daspect([2 2 1]);
  set(gca,'Tag','CorAxs');
  
  if get(wgts.OverlayCheck,'value') > 0,
    subDrawSlices(wgts,ONLINE.pvpar);
  end
  if get(wgts.CrosshairCheck,'value') > 0,
    tmph = [wgts.TraAxs, wgts.SagAxs, wgts.CorAxs];
    for N = 1:3,
      axes(tmph(N));
      line([tmpX(1) tmpX(end)],[0,0],'color',[0.9 0.9 0]);
      line([0 0],[tmpY(1) tmpY(end)],'color',[0.9 0.9 0]);
    end
  end
  
  
 case {'show-pvpar'}
  if ~strcmp(get(wgts.main,'SelectionType'),'open'), return;  end
  
  ONLINE = getappdata(wgts.main,'ONLINE');
  clear monilnepvpar;
  monlinepvpar(ONLINE,'hfig',gcf+100);
  return

 otherwise
  fprintf('WARNING %s: Main_Callback() ''%s'' not supported yet.\n',mfilename,eventdata);
end
  
return;
  
  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION to get screen size
function [scrW, scrH] = subGetScreenSize(Units)
oldUnits = get(0,'Units');
set(0,'Units',Units);
sz = get(0,'ScreenSize');
set(0,'Units',oldUnits);

scrW = sz(3);  scrH = sz(4);

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to draw slices
function subDrawSlices(wgts,PVPAR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

axes(wgts.TraAxs);


axes(wgts.SagAxs);


axes(wgts.CorAxs);


  
return
