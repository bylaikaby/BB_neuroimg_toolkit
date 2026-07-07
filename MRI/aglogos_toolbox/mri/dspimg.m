function varargout = dspimg(varargin)
%DSPIMG - GUI interface to view tcImg images
% DSPIMG(tcImg) display the images and permits visualization of the time
% course of selected ROIs.
%
% TODO's
% ===============
% ** We still have problem when no correlations are found!!
% ** Must add combo-box for Filter_Callback(hObject,eventdata,handles)
%
% VERSION : 1.00 09.04.04 NKL ROI & DEBUG
% See also MROIGUI, MROISCT, MROIDSP

persistent H_DSPIMG;	% keep the figure handle.

if nargin == 0, help dspimg; return;  end


myinput = varargin{1};

% CHECK IF PROGRAM IS ACTIVE AND INPUT IS NAME OF CALLBACK
% IF YES, EXECUTE CALLBACK FUNCTION THEN RETURN;
if isstr(myinput) & ~isempty(findstr(myinput,'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return;
end

% PREVENT DOUBLE EXECUTION
if ishandle(H_DSPIMG),
  close(H_DSPIMG);
end

% ====================================================================
% HERE WE COME ONLY ONCE IN THE BEGINNING OF THE PROGRAM
% WE SET DISPLAY PARAMETERS FOR THE PLACEMENT OF AXIS ETC.
% ====================================================================
[scrW scrH] = getScreenSize('char');
figW        = 180.0;
figH        =  50.0;
figX        =   1.0;
figY        = scrH-figH-2;         % 3 for menu and title bars.
IMGXOFS     = 3;
IMGYOFS     = figH * 0.10;
IMGYLEN     = figH * 0.63;
IMGXLEN     = figW * 0.45;
TCPY        = 18;
TCPOFS      = 29;
FRPOFS      = 6;
XPLOT       = 97;
XPLOTLEN    = 75;

% ====================================================================
% CREATE THE MAIN WINDOW
% Reminder: get(0,'DefaultUicontrolBackgroundColor')
%    'Color', get(0,'DefaultUicontrolBackgroundColor'),...
% ====================================================================
hMain = figure(...
    'Name','DSPIMG tcImg Viewer','NumberTitle','off', ...
    'Tag','main', 'MenuBar', 'none', ...
    'HandleVisibility','on','Resize','off',...
    'DoubleBuffer','on', 'BackingStore','on','Visible','off',...
    'Units','char','Position',[figX figY figW figH],...
    'UserData',[figW figH],...
    'Color',[.85 .98 1],'DefaultAxesfontsize',10,...
    'DefaultAxesFontName', 'Comic Sans MS',...
    'DefaultAxesfontweight','bold');
H_DSPIMG = hMain;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PULL-DOWN MENU [File Edit View Help]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- FILE
hMenuFile = uimenu(hMain,'Label','File');
uimenu(hMenuFile,'Label','Load Experiment File','Separator','off',...
       'Callback','dspimg(''Main_Callback'',gcbo,''expload'',[])');
uimenu(hMenuFile,'Label','Load Group File','Separator','off',...
       'Callback','dspimg(''Main_Callback'',gcbo,''grpload'',[])');
uimenu(hMenuFile,'Label','Print','Separator','on',...
       'Callback','dspimg(''Print_Callback'',gcbo,''print'',[])');
uimenu(hMenuFile,'Label','Print TIFF','Separator','off',...
       'Callback','dspimg(''Print_Callback'',gcbo,''tiff'',[])');
uimenu(hMenuFile,'Label','Print JPEG','Separator','off',...
       'Callback','dspimg(''Print_Callback'',gcbo,''jpeg'',[])');
uimenu(hMenuFile,'Label','Window Metafile','Separator','off',...
       'Callback','dspimg(''Print_Callback'',gcbo,''meta'',[])');
uimenu(hMenuFile,'Label','Print Dialog','Separator','off',...
       'Callback','dspimg(''Print_Callback'',gcbo,''printdlg'',[])');
uimenu(hMenuFile,'Label','Page Dialog','Separator','off',...
       'Callback','dspimg(''Print_Callback'',gcbo,''pagesetupdlg'',[])');
uimenu(hMenuFile,'Label','Exit','Separator','on',...
       'Callback','dspimg(''Main_Callback'',gcbo,''exit'',[])');
uimenu(hMenuFile,'Label','Exit All',...
       'Callback','dspimg(''Main_Callback'',gcbo,''exit-all'',[])');
% --- HELP
hMenuHelp = uimenu(hMain,'Label','Help');
uimenu(hMenuHelp,'Label','About ROIs','Separator','off',...
       'Callback','AboutRois');
uimenu(hMenuHelp,'Label','dspimg','Separator','off',...
       'Callback','helpwin dspimg');

% ====================================================================
% DISPLAY NAMES OF SESSION/GROUP
% ====================================================================
H = figH - 2;
BKGCOL = get(hMain,'Color');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS H-0.15 12 1.3],...
    'String','Session: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
SesNameBut = uicontrol(...
    'Parent',hMain,'Style','pushbutton',...
    'Units','char','Position',[IMGXOFS+14 H-0.05 22 1.3],...
    'String','none','FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left','Tag','SesNameBut',...
    'Callback','dspimg(''Main_Callback'',gcbo,''edit-session'',[])',...
    'ForegroundColor',[1 1 0.1],'BackgroundColor',[0 0.5 0]);
ImgInfoBut = uicontrol(...
    'Parent',hMain,'Style','pushbutton',...
    'Units','char','Position',[IMGXOFS+38 H-0.05 22 1.3],...
    'String','Image Info','FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left','Tag','ImgInfoBut',...
    'Callback','dspimg(''Main_Callback'',gcbo,''get-imginfo'',[])',...
    'ForegroundColor',[.6 .1 .1],'BackgroundColor',[.5 .9 .9]);
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS H-1.8 12 1.3],...
    'String','Group: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
GrpNameBut = uicontrol(...
    'Parent',hMain,'Style','pushbutton',...
    'Units','char','Position',[IMGXOFS+14 H-1.8 22 1.3],...
    'String','Group-1','FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left','Tag','GrpNameBut',...
    'Callback','dspimg(''Main_Callback'',gcbo,''edit-group'',[])',...
    'ForegroundColor',[1 1 0.1],'BackgroundColor',[0.6 0.2 0]);
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS H-3.7 12 1.25],...
    'String','ROI Set: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
GrpRoiSelCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMGXOFS+14 H-3.4 47 1.25],...
    'String',{'Roi 1','Roi 2'},...
    'Callback','dspimg(''Main_Callback'',gcbo,''grproi-select'',[])',...
    'TooltipString','GrpRoi Selection',...
    'Tag','GrpRoiSelCmb','FontWeight','Bold');

% ====================================================================
% ROI CONTROL
% ====================================================================
XDSP = IMGXOFS;
H = IMGYOFS + IMGYLEN + 0.6;
% DEFAULT ROIS
DefRoiNames = {'Brain','V1','V2','MT','V4','Cntrl','Noise','Muscle'};
RoiSelCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[XDSP H 19 1.5],...
    'String',DefRoiNames,...
    'Callback','dspimg(''Main_Callback'',gcbo,''roi-select'',[])',...
    'TooltipString','ROI selection',...
    'Tag','RoiSelCmb','FontWeight','Bold');
TrialCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[XDSP+21 H 25 1.5],...
    'String','No Trials',...
    'Callback','dspimg(''Main_Callback'',gcbo,''get-trials'',[])',...
    'TooltipString','Obsp-Trials',...
    'Tag','TrialCmb','FontWeight','Bold');
CallMroiBut = uicontrol(...
    'Parent',hMain,'Style','pushbutton',...
    'Units','char','Position',[IMGXOFS+52 H-0.05 12 1.3],...
    'String','MROI','FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left','Tag','CallMroiBut',...
    'Callback','dspimg(''Main_Callback'',gcbo,''call-mroi'',[])',...
    'ForegroundColor',[1 1 1],'BackgroundColor',[.4 .4 .2]);
UpdateMroiBut = uicontrol(...
    'Parent',hMain,'Style','pushbutton',...
    'Units','char','Position',[IMGXOFS+65 H-0.05 17 1.3],...
    'String','Update ROI','FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left','Tag','UpdateMroiBut',...
    'Callback','dspimg(''Main_Callback'',gcbo,''roi-update'',[])',...
    'ForegroundColor',[1 1 1],'BackgroundColor',[.7 .2 .2]);

% ====================================================================
% AXES for IMAGE, TIME and SPECTRAL POWER Plots
% ====================================================================
ClearBut = uicontrol(...
    'Parent',hMain,'Style','pushbutton',...
    'Units','char','Position',[figW-20 figH-2.5 15 1.3],...
    'String','Clear Plots','FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left','Tag','ClearBut',...
    'Callback','dspimg(''Main_Callback'',gcbo,''clrdsp'',[])',...
    'ForegroundColor',[1 1 1],'BackgroundColor',[1 0 0]);
AxsFrame = axes(...
    'Parent',hMain,'Units','char','color',get(hMain,'color'),'xtick',[],...
    'ytick',[],'Position',[IMGXOFS IMGYOFS IMGXLEN+1 IMGYLEN],...
    'Box','on','linewidth',3,'xcolor','r','ycolor','r',...
    'color',[.1 .1 .2]);
ImageAxs = axes(...
    'Parent',hMain,'Tag','ImageAxs',...
    'Units','char','Color','k','layer','top',...
    'Position',[IMGXOFS+2 IMGYOFS+2 IMGXLEN*.9 IMGYLEN*.85],...
    'xticklabel','','yticklabel','','xtick',[],'ytick',[]);
XDSP = XPLOT;
TcPlotAxs = axes(...
    'Parent',hMain,'Tag','TcPlotAxs',...
    'Units','char','Position',[XDSP+0.5 TCPOFS+0.25 XPLOTLEN-0.3 TCPY-0.4],...
	'ButtonDownFcn','dspimg(''Main_Callback'',gcbo,''zoomin'',[])',...
    'Color','white','layer','top','box','on');
xlabel('Time in Seconds');
title('Voxel Time Series (VTS)','fontweight','bold','fontsize',11);
FrPlotAxs = axes(...
    'Parent',hMain,'Tag','FrPlotAxs',...
    'Units','char','Position',[XDSP+0.5 FRPOFS+0.25 XPLOTLEN-0.3 TCPY-0.4],...
	'ButtonDownFcn','dspimg(''Main_Callback'',gcbo,''zoomin'',[])',...
    'Color','white','layer','top','box','on');
xlabel('Frequencies in Hz');
title('Spectral Power of VTS','fontweight','bold','fontsize',11);

% ====================================================================
% SLICE SELECTION SLIDER
% ====================================================================
% LABEL : Slice X
SliceBarTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS 2.5 15 1.5],...
    'String','Slice : 1','FontWeight','bold','FontSize',10,...
    'HorizontalAlignment','left','Tag','SliceBarTxt',...
    'BackgroundColor',get(hMain,'Color'));
SliceBarSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[IMGXOFS+12 2.6 IMGXLEN-11 1.5],...
    'Callback','dspimg(''Main_Callback'',gcbo,''slice-slider'',[])',...
    'Tag','SliceBarSldr','SliderStep',[1 4],...
    'TooltipString','Set current slice');

% ====================================================================
% STATUS LINE: 
% ====================================================================
StatusCol = [.92 .96 .94];
StatusFrame = axes(...
    'Parent',hMain,'Units','char','color',get(hMain,'color'),'xtick',[],...
    'ytick',[],'Position',[IMGXOFS 0.35 172 1.8],...
    'Box','on','linewidth',1,'xcolor','k','ycolor','k',...
    'color',StatusCol);
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+2 0.45 11 1.5],...
    'String','Status :','FontWeight','bold','fontsize',10,...
    'HorizontalAlignment','left','ForegroundColor','r',...
    'BackgroundColor',StatusCol);
StatusField = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+16 0.55 145 1.2],...
    'String','Normal','FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left','Tag','StatusField',...
    'ForegroundColor','k','BackgroundColor',StatusCol);

% ====================================================================
% FUNCTION BUTTONS FOR IMAGE AND TIME-SERIES PROCESSING
% Syntax: SetFunBtn(hMain,POS,TagName,Label,COL)
% ====================================================================
YOFS = 47.3; HX = 3; DHY = 1.7;
HY = YOFS - 5.5;
SetFunBtn(hMain,HX,HY,'ButMeanImg','Mean-Img');
HY = HY - DHY;
SetFunBtn(hMain,HX,HY,'ButMedianImg','Median-Img');
HX = HX + 17;
HY = YOFS - 5.5;
SetFunBtn(hMain,HX,HY,'ButMaxImg','Max-Img');
HY = HY - DHY;
SetFunBtn(hMain,HX,HY,'ButStdImg','Std-Img');
HX = HX + 17;
HY = YOFS - 5.5;
SetFunBtn(hMain,HX,HY,'ButCvImg','Cv-Img');
HY = HY - DHY;
SetFunBtn(hMain,HX,HY,'ButStmStdImg','StmStd-Img');

% ====================================================================
% RADIO-BUTTONS TO DETERMINE THE TYPE TIME SERIES DISPLAYED
% ====================================================================
YOFS = 48; HX = 70; HY = YOFS; DHY = 1.6;
rbTags = {'rbIntensity','rbDetrendedIntensity',...
          'rbPercentMod','rbSdUnits','rbSdUnitsStim'};
SetRadioBtn(hMain,HX,HY,rbTags{1},'Intensity');
HY = HY - DHY;
SetRadioBtn(hMain,HX,HY,rbTags{2},'Detrended-Intensity');
HY = HY - DHY;
SetRadioBtn(hMain,HX,HY,rbTags{3},'Percent-Mod');
HY = HY - DHY;
SetRadioBtn(hMain,HX,HY,rbTags{4},'SD-Units');
HY = HY - DHY;
SetRadioBtn(hMain,HX,HY,rbTags{5},'SD-Units-Stim');
HY = HY - DHY;

% ====================================================================
% HOLD ON CHECK-BUTTON
% ====================================================================
HY = HY - DHY/3;
HoldOn = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[HX HY 18 1.5],...
    'Tag','HoldOn','Value',0,...
    'String','Hold On','FontWeight','bold',...
    'TooltipString','Hold On/Off','BackgroundColor',get(hMain,'Color'));


% *********************************************************************
% INITIALIZE THE APPLICATION.
% *********************************************************************

COLORS = 'crgbkmycrgbkmycrgbkmy';   % Enough colors for different ROIs
CurOp = 'Mean-Img';
wgts = guihandles(hMain);
setappdata(hMain, 'COLOR', COLORS);
setappdata(hMain, 'CurOp', CurOp);
setappdata(hMain, 'rbTags', rbTags);

% GET INPUT
tcImg = myinput;

ses = goto(tcImg.session);
grp = getgrpbyname(ses,tcImg.grpname);
expno = grp.exps(1);
pars = expgetpar(ses,expno);
tcImg.stm = pars.stm;
setappdata(hMain, 'tcImg', tcImg);

% INITIALIZE VARIABLES
curImg = tcImg;
curImg.dat = mean(curImg.dat,4);
sortpars = getsortpars(ses,expno);
nobsp = length(pars.stm.ntrials);
ntrials = pars.stm.ntrials(1);
TrialNames = {'Entire ObsP'};
if ntrials > 1,
  for N=2:ntrials+1,
    TrialNames{N} = sprintf('Trial %2d',N-1);
  end;
end;
setappdata(hMain, 'curImg',curImg);
setappdata(hMain, 'ses',ses);
setappdata(hMain, 'grp',grp);
setappdata(hMain, 'expno',expno);
setappdata(hMain, 'nobsp',nobsp);
setappdata(hMain, 'ntrials',ntrials);
setappdata(hMain, 'sortpars',sortpars);
set(wgts.TrialCmb,'String',TrialNames);
set(wgts.SesNameBut,'String',curImg.session);
set(wgts.GrpNameBut,'String',curImg.grpname);

% DISPLAY CURRENT IMAGE
dspimg('Main_Callback',hMain,'init');
set(hMain,'Visible','on');

if nargout,
  varargout{1} = hMain;
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Main_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ---------------------------------------
% THE FOLLOWING 4 LINES FINDS OUT WHICH FUNCTION WE ARE IN...
funcname = mfilename('fullpath');
[ST, I] = dbstack;
n = findstr(ST(I).name,'(');
cbname = ST(I).name(n+1:end-1);
% ---------------------------------------

% NOW GET ALL WIDGETS, GLOBALS, AND ROINAMES
wgts = guihandles(hObject);
COLORS = getappdata(wgts.main,'COLOR');
DefRoiNames = get(wgts.RoiSelCmb,'String');

ses = getappdata(wgts.main,'ses');
grp = getappdata(wgts.main,'grp');
expno = getappdata(wgts.main,'expno');
tcImg  = getappdata(wgts.main,'tcImg');
curImg = getappdata(wgts.main,'curImg');

switch lower(eventdata),
 case {'init'}
  % SET SLIDER PROPERTIES: +0.01 to prevent error
  nslices = size(curImg.dat,3);
  set(wgts.SliceBarSldr,'Min',1,'Max',nslices+0.01,'Value',1);
  % NOTE THAT SLIDER STEP IS NORMALIZED FROM 0 to 1, NOT MIN/MAX
  if nslices > 1,
    sstep = [1/(nslices-1), 2/(nslices-1)];
  else
    sstep = [1 2];
  end
  set(wgts.SliceBarSldr,'SliderStep',sstep);
  
  set(wgts.RoiSelCmb,'Value',2);        % Select V1
  set(wgts.rbIntensity,'Value',1);
  s = load('Roi.mat');
  GrpRoiNames = fieldnames(s);
  setappdata(wgts.main,'GrpRoiNames',GrpRoiNames');
  eval(sprintf('Roi = s.%s;', GrpRoiNames{1}));
  set(wgts.GrpRoiSelCmb,'String',GrpRoiNames);
  set(wgts.GrpRoiSelCmb,'Value',1);
  DefRoiNames = ses.roi.names;
  set(wgts.RoiSelCmb,'String',DefRoiNames);
  setappdata(wgts.main,'DefRoiNames',DefRoiNames');
  RoiRoi = Roi.roi;
  setappdata(wgts.main,'RoiRoi',RoiRoi);
  StatusPrint(hObject,cbname,'Loaded Group "%s" from Roi.mat',GrpRoiNames{1});
  dspimg('Main_Callback',wgts.main,'redraw');

 case {'redraw'}
  Main_Callback(wgts.RoiSelCmb,'roi-select',[]);
  Main_Callback(wgts.SliceBarSldr,'slice-slider',[]);

 case {'call-mroi'}
  evalin('base',sprintf('mroi(''%s'',''%s'')',ses.name,grp.name));
  StatusPrint(hObject,cbname,'Updated Roi.mat');
  
 case {'roi-update'}
  dspimg('Main_Callback',wgts.main,'init');
  
 case {'expload'}
  [imgfile pathname] = uigetfile('SIGS/*TCIMG.mat');
  if isequal(imgfile,0) | isequal(pathname,0)
    return;
  else
    imgfile = fullfile(pathname,imgfile);
  end
  tcImg = matsigload(imgfile,'tcImg');
  expno = tcImg.ExpNo;
  pars = expgetpar(ses,expno);
  tcImg.stm = pars.stm;
  setappdata(wgts.main, 'tcImg', tcImg);
  dspimg('Main_Callback',wgts.main,'load');

 case {'grpload'}
  [imgfile pathname] = uigetfile('*.mat');
  if isequal(imgfile,0) | isequal(pathname,0)
    return;
  else
    imgfile = fullfile(pathname,imgfile);
  end
  [tmp1,name] = fileparts(imgfile);
  if strcmp(lower(name),'tcimg'),
    tcImg = matsigload(imgfile,grp.name);
  else
    tcImg = matsigload(imgfile,'tcImg');
  end;
  if isempty(tcImg),
    StatusPrint(hObject,cbname,'No tcImg in "%s"',imgfile);
    return;
  end;
  expno = tcImg.ExpNo;
  pars = expgetpar(ses,expno);
  tcImg.stm = pars.stm;
  setappdata(wgts.main, 'tcImg', tcImg); 
  dspimg('Main_Callback',wgts.main,'load');

 case {'load'}
  curImg = tcImg;
  curImg.dat = double(mean(curImg.dat,4));
  ses = goto(curImg.session);
  grp = getgrpbyname(ses,curImg.grpname);
  expno = grp.exps(1);
  pars = expgetpar(ses,expno);
  sortpars = getsortpars(ses,expno);
  nobsp = length(pars.stm.ntrials);
  ntrials = pars.stm.ntrials(1);
  TrialNames = {'Entire ObsP'};
  if ntrials > 1,
    for N=2:ntrials+1,
      TrialNames{N} = sprintf('Trial %2d',N-1);
    end;
  end;
  setappdata(wgts.main, 'curImg',curImg);
  setappdata(wgts.main, 'ses',ses);
  setappdata(wgts.main, 'grp',grp);
  setappdata(wgts.main, 'expno',expno);
  setappdata(wgts.main, 'nobsp',nobsp);
  setappdata(wgts.main, 'ntrials',ntrials);
  setappdata(wgts.main, 'sortpars',sortpars);
  set(wgts.TrialCmb,'String',TrialNames);
  set(wgts.TrialCmb,'Value',1);
  set(wgts.SesNameBut,'String',curImg.session);
  set(wgts.GrpNameBut,'String',curImg.grpname);
  dspimg('Main_Callback',wgts.main,'redraw');
  
 case {'grproi-select'}
  grproiname = get(wgts.GrpRoiSelCmb,'String');
  grproiname = grproiname{get(wgts.GrpRoiSelCmb,'Value')};
  Roi = matsigload('Roi.mat',grproiname);
  grp = getgrpbyname(ses,Roi.grpname);
  if isempty(grp),
	fprintf('IMGDSP: %s GrpRoi was not found\n',grproiname);
	keyboard;
  end;
  set(wgts.GrpNameBut,'String',grp.name);
  SLICE = round(get(wgts.SliceBarSldr,'Value'));
  RoiRoi = Roi.roi;
  setappdata(wgts.main,'RoiRoi',RoiRoi);
  dspimg('Main_Callback',wgts.main,'redraw');
  StatusPrint(hObject,cbname,'Loaded Group "%s" from Roi.mat',grproiname);
  
 case {'roi-select'}
  roiname = DefRoiNames{get(wgts.RoiSelCmb,'Value')};
  dspimg('Main_Callback',wgts.main,'time-series');

 case {'slice-slider'}
  SLICE = round(get(wgts.SliceBarSldr,'Value'));
  set(wgts.SliceBarTxt,'String',sprintf('Slice: %d',SLICE));
  curImg = getappdata(wgts.main,'curImg');
  figure(wgts.main);
  axes(wgts.ImageAxs); cla;
  mroidsp(curImg.dat(:,:,SLICE),1,0,getappdata(wgts.main,'CurOp'));
  RoiRoi = getappdata(wgts.main,'RoiRoi');

  if ~isempty(RoiRoi),
    for N = 1:length(RoiRoi),
      if RoiRoi{N}.slice ~= SLICE, continue;  end
      roiname = RoiRoi{N}.name;
      msize = 3;
      if strcmp(roiname,'brain'),
        msize = 1;
      end;
      if isempty(RoiRoi{N}.px) | isempty(RoiRoi{N}.py),
        [px,py] = find(RoiRoi{N}.mask);
      else
        if isfield(RoiRoi{N},'anamask'),
          % OLD RoiRoi FORMAT, px/py in anatomy units
          fx = size(RoiRoi{N}.mask,1)/size(RoiRoi{N}.anamask,1);
          fy = size(RoiRoi{N}.mask,2)/size(RoiRoi{N}.anamask,2);
          px = RoiRoi{N}.px * fx;
          py = RoiRoi{N}.py * fy;
        else
          % NEW RoiRoi FORMAT, px/py in functional image units (since 07.08.05)
          px = RoiRoi{N}.px;
          py = RoiRoi{N}.py;
        end
      end;
      % draw the polygon
      axes(wgts.ImageAxs); hold on;
      x = min(px) - 1;  y = min(py) - 2;
      cidx = find(strcmpi(DefRoiNames,roiname));
      if isempty(cidx), continue;  end
      cidx = mod(cidx-1,length(COLORS)) + 1;
      if isempty(RoiRoi{N}.px) | isempty(RoiRoi{N}.py),
        plot(px,py,'color',COLORS(cidx),'linestyle','none',...
             'marker','s','markersize',msize,'markerfacecolor',COLORS(cidx));
      else
        plot(px,py,'color',COLORS(cidx));
      end;
      text(x,y,roiname,'color',COLORS(cidx),'fontsize',10,'fontweight','bold');
    end
  end;
  set(wgts.ImageAxs,'Tag','ImageAxs');
  dspimg('Main_Callback',wgts.main,'time-series');

 case {'exit'}
  if ishandle(wgts.main), close(wgts.main);  end
  return;
 
 case {'exit-all'}
  h = findobj('HandleVisibility','callback');
  close(h);
  if ishandle(wgts.main), close(wgts.main);  end
  return;

 case {'zoomin'}
  tit = sprintf('Session: %s, Group: %s, ExpNo: %d',...
                ses.name, grp.name, expno);
  ZoominButtonDownFcn(wgts,tit);
  %title(tit,'Color','r','fontweight','bold','fontsize',12);
  %tmp = expgetpar(ses,expno);
  
 case {'edit-session'}
  mguiEdit(which(ses.name));
  
 case {'edit-group'}
  grpname = get(wgts.GrpNameBut,'String');
  mguiEdit(which(ses.name),strcat('GRP.',grpname));
  
 case {'clrdsp'}
  axes(wgts.TcPlotAxs); cla;
  axes(wgts.FrPlotAxs); cla;
  axes(wgts.ImageAxs); hold on;
  
 % =============================================================
 % EXECUTION OF CALLBACKS OF THE FUNCTION-BUTTONS (bNames)
 % PROCESSING AND DISPLAY OF IMAGES AND TIME SERIES
 % =============================================================
 case {'mean-img'}
  curImg = tcImg;
  curImg.dat = mean(curImg.dat,4);
  setappdata(wgts.main,'curImg',curImg);
  setappdata(wgts.main, 'CurOp', eventdata);
  dspimg('Main_Callback',wgts.main,'redraw');

 case {'median-img'}
  curImg = tcImg;
  curImg.dat = median(curImg.dat,4);
  setappdata(wgts.main, 'CurOp', eventdata);
  setappdata(wgts.main,'curImg',curImg);
  dspimg('Main_Callback',wgts.main,'redraw');

 case {'max-img'}
  curImg = tcImg;
  curImg.dat = max(curImg.dat,4);
  setappdata(wgts.main, 'CurOp', eventdata);
  setappdata(wgts.main,'curImg',curImg);
  dspimg('Main_Callback',wgts.main,'redraw');

 case {'std-img'}
  curImg = tcImg;
  if isa(curImg.dat,'int16'),
    curImg.dat = int16(std(double(curImg.dat),1,4));
  else
    curImg.dat = std(curImg.dat,1,4);
  end;
  setappdata(wgts.main, 'CurOp', eventdata);
  setappdata(wgts.main,'curImg',curImg);
  dspimg('Main_Callback',wgts.main,'redraw');
  
 case {'stmstd-img'}
  curImg = tcImg;
  curImg = tosdu(curImg);
  tmp = siggetbaseline(curImg,'dat','notblank');
  curImg.dat = mean(curImg.dat(:,:,:,tmp.ix),4);
  setappdata(wgts.main, 'CurOp', eventdata);
  setappdata(wgts.main,'curImg',curImg);
  dspimg('Main_Callback',wgts.main,'redraw');
  
 case {'cv-img'}
  curImg = tcImg;
  m = mean(curImg.dat,4);
  curImg.dat = std(curImg.dat,1,4)./m;
  setappdata(wgts.main, 'CurOp', eventdata);
  setappdata(wgts.main,'curImg',curImg);
  dspimg('Main_Callback',wgts.main,'redraw');
  
 case {'get-imginfo'}
  mfigure([500 350 600 400],curImg.session);
  set(gcf,'color',[0 0 .3]);
  dspimginfo(curImg);

 case {'get-trials'}
  dspimg('Main_Callback',wgts.main,'time-series');

 case {'time-series'}
  roiname = DefRoiNames{get(wgts.RoiSelCmb,'Value')};
  RoiRoi = getappdata(wgts.main,'RoiRoi');
  if isempty(RoiRoi),
    StatusPrint(hObject,cbname,'No ROI was defined');
    return;
  end;
  SLICE = round(get(wgts.SliceBarSldr,'Value'));
  % Now select the roi with the desired name on the desired slice
  IDX = [];
  for N = 1:length(RoiRoi),
    if strcmpi(RoiRoi{N}.name,roiname) & RoiRoi{N}.slice == SLICE,
      IDX(end+1) = N;
    end
  end
  RoiRoi = RoiRoi(IDX);
  TrialNames = get(wgts.TrialCmb,'String');
  TrialNo = get(wgts.TrialCmb,'Value');
  if TrialNo > 1,
    sortpars = getappdata(wgts.main,'sortpars');
    tcImg = sigsort(tcImg,sortpars.trial);
    tcImg = tcImg{TrialNo-1};
  end;
  tcImg.dat = double(squeeze(tcImg.dat(:,:,SLICE,:)));
  curImgRoi = msigroitc(tcImg,RoiRoi);
  if isempty(curImgRoi),
    StatusPrint(hObject,cbname,'No ROI with this name was defined');
    return;
  end;
  rbTags = getappdata(wgts.main,'rbTags');
  for N=1:length(rbTags),
    if get(eval(sprintf('wgts.%s',rbTags{N})),'Value'), break; end;
  end;
  curImgRoi = TimeSeriesUnits(curImgRoi,N);
  setappdata(wgts.main,'curImgRoi',curImgRoi);
  

  % PLOT TIME SERIES
  axes(wgts.TcPlotAxs);
  if ~get(wgts.HoldOn,'Value'), cla;  end;

  t = [0:size(curImgRoi{1}.dat,1)-1]*curImgRoi{1}.dx;
  for K=1:length(curImgRoi),
    axes(wgts.TcPlotAxs);
    hold on;
    if isempty(curImgRoi{K}.dat),
      StatusPrint(hObject,cbname,'curImgRoi(%d) is empty',K);
      continue;
    end;
    cidx = find(strcmpi(DefRoiNames,curImgRoi{K}.name));
    cidx = mod(cidx-1,length(COLORS)) + 1;
    m = mean(curImgRoi{K}.dat,2);
    s = std(curImgRoi{K}.dat,1,2)/sqrt(size(curImgRoi{K}.dat,2));
    eb0 = errorbar(t,m,s);
    eb = findall(eb0); eb(1)=[];
    set(eb(1),'LineWidth',1,'Color','k');
    set(eb(2),'LineWidth',2,'Color',COLORS(cidx));
  end;
  grid on;
  xlabel('Time in Seconds');
  drawstmlines(tcImg,'color','r','linestyle','--','linewidth',2);
  set(wgts.TcPlotAxs,'xlim',[t(1) t(end)]);
  set(wgts.TcPlotAxs,'tag','TcPlotAxs');
  set(wgts.TcPlotAxs,'ButtonDownFcn',...
                   'dspimg(''Main_Callback'',gcbo,''zoomin'',[])');

  % AND THEIR SPECTRAL POWER DISTRIBUTION
  axes(wgts.FrPlotAxs);
  if ~get(wgts.HoldOn,'Value'), cla;  end;
  if get(wgts.HoldOn,'Value'), hold on;  end;
  for K=1:length(curImgRoi),
    if isempty(curImgRoi{K}.dat),
      StatusPrint(hObject,cbname,'curImgRoi(%d) is empty',K);
      continue;
    end;
    fdat = fft(curImgRoi{K}.dat,2048,1);
    LEN = size(fdat,1)/2;
    famp = abs(fdat(1:LEN,:));
    freq = ((1/curImgRoi{K}.dx)/2) * [0:LEN-1]/(LEN-1);
    axes(wgts.FrPlotAxs);
    hold on;
    cidx = find(strcmpi(DefRoiNames,curImgRoi{K}.name));
    cidx = mod(cidx-1,length(COLORS)) + 1;
    plot(freq(:),mean(famp,2),COLORS(cidx));
  end;
  grid on;
  if exist('freq'),
    set(wgts.FrPlotAxs,'xlim',[freq(1) freq(end)]);
    df = (freq(end)-freq(1))/10;
    set(wgts.FrPlotAxs,'xtick',[freq(1):df:freq(end)]);
    set(wgts.FrPlotAxs,'tag','FrPlotAxs');
    set(wgts.FrPlotAxs,'ButtonDownFcn',...
                   'dspimg(''Main_Callback'',gcbo,''zoomin'',[])');
    xlabel('Frequencies in Hz');
  end;
 otherwise
  StatusPrint(hObject,cbname,'WARNING: UNRECOGNIZED case');
end
VERBOSE=0;
if VERBOSE,
  fprintf('Main_Callback: Case: %s\n', eventdata);
end;

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function RadioButton_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(hObject);
set(wgts.rbIntensity,'Value',0);
set(wgts.rbDetrendedIntensity,'Value',0);
set(wgts.rbPercentMod,'Value',0);
set(wgts.rbSdUnits,'Value',0);
set(wgts.rbSdUnitsStim,'Value',0);
eval(sprintf('set(wgts.%s,''Value'',1)',eventdata));
dspimg('Main_Callback',wgts.main,'time-series');
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Filter_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
funcname = mfilename('fullpath');
[ST, I] = dbstack;
n = findstr(ST(I).name,'(');
cbname = ST(I).name(n+1:end-1);

wgts = guihandles(hObject);
curImgRoi = getappdata(wgts.main,'curImgRoi');
if isempty(curImgRoi),
  StatusPrint(hObject,cbname,'No curImgRoi was defined, Run GetTC');
  return;
end;

wnames = fieldnames(wgts);
wnames = wnames(find(strncmpi(wnames,'FltFunc',7)));
for n = 1:length(wnames),
  h = eval(sprintf('wgts.%s',wnames{n}));
  swname = strtok(get(h,'String'));
  swval  = get(h,'Value');
  eval(sprintf('swproc.%s = %d;', swname, swval));
end

%???????????????????????????????????????
fnames = fieldnames(swproc);
for K=1:length(fnames),
  if getfield(swproc,fnames{K}),
    for N=1:length(curImgRoi),
      % curImgRoi{N} = ProcData(fnames{K},curImgRoi{N});
    end;
  end;
end;
setappdata(wgts.main,'curImgRoi',curImgRoi);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Print_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
funcname = mfilename('fullpath');
[ST, I] = dbstack;
n = findstr(ST(I).name,'(');
cbname = ST(I).name(n+1:end-1);

wgts = guihandles(hObject);

tmp = gettimestring;
tmp(findstr(tmp,':')) = '_';
OutFile = 'dspimgWS.mat';
StatusPrint(hObject,cbname,OutFile);

orient landscape;
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');
set(gcf,'InvertHardCopy',		'off');

switch lower(eventdata),
 case {'print'},
  print;
 case {'printdlg'},
  printdlg;
 case {'pagesetupdlg'},
  pagesetupdlg;
 case {'meta'}
  print('-dmeta',OutFile);
 case {'tiff'}
  print('-dtiff',OutFile);
 case {'jpeg'}
  print('-djpeg',OutFile);
 otherwise
  StatusPrint(hObject,cbname,'Wrong Printer Parameters');
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                     U T I L I T I E S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% -------------------------------------------------------------------
function oSig = TimeSeriesUnits(Sig,ButNo)
% -------------------------------------------------------------------
oSig = Sig;
if isempty(oSig{1}.stm.t),
  st = round(size(oSig{1}.dat,1)*0.05);
else
  st = round(oSig{1}.stm.time{1}(2)/oSig{1}.dx);
end;

switch ButNo,
 case 1,            % Raw Intensity;
 case 2,            % Detrended Signal
  for N=1:length(oSig),
    if ~isempty(oSig{N}.dat),
      oSig{N}.dat = detrend(oSig{N}.dat);
    end;
  end;
 case 3,            % Percent Modulation
  for N=1:length(oSig),
    if ~isempty(oSig{N}.dat),
      m = repmat(mean(oSig{N}.dat(1:st,:),1),[size(Sig{N}.dat,1) 1]);
      oSig{N}.dat = 100 * (oSig{N}.dat-m) ./ m;
    end;
  end;
 case 4,            % SD Units
  for N=1:length(oSig),
    if ~isempty(oSig{N}.dat),
      m = repmat(mean(oSig{N}.dat,1),[size(Sig{N}.dat,1) 1]);
      s = repmat(std(oSig{N}.dat,1,1),[size(Sig{N}.dat,1) 1]);
      oSig{N}.dat = (oSig{N}.dat-m) ./ s;
    end;
  end;
 case 5,            % Stim-SD Units

  for N=1:length(oSig),
    if ~isempty(oSig{N}.dat),
      m = repmat(mean(oSig{N}.dat(1:st,:),1),[size(Sig{N}.dat,1) 1]);
      s = repmat(std(oSig{N}.dat(1:st,:),1,1),[size(Sig{N}.dat,1) 1]);
      oSig{N}.dat = (oSig{N}.dat-m) ./ s;
    end;
  end;
 otherwise,
end;
return;

% -------------------------------------------------------------------
function StatusPrint(hObject,fname,varargin)
% -------------------------------------------------------------------
tmp = sprintf(varargin{:});
tmp = sprintf('(%s): %s',fname,tmp);
wgts = guihandles(hObject);
set(wgts.StatusField,'String',tmp);
return;

% -------------------------------------------------------------------
function ZoominButtonDownFcn(wgts,tit)
% -------------------------------------------------------------------
pos = get(gca,'position');
xlab = get(get(gca,'xlabel'),'string');
xlim = get(gca,'xlim');
tmp=allchild(gca);
mfigure([20 350 1150 550]);
set(gcf,'Name',tit);
copyobj(tmp,gca)
pos = get(gca,'position');
pos(1) = pos(1) * 0.75; pos(3) = pos(3) * 1.1;
pos(2) = pos(2) * 1.20; pos(4) = pos(4) * 0.92;
set(gca,'position',pos);
ch = get(gca,'children');
if length(ch) > 1,
  ch = ch(2);
end;
set(gca,'xlim',xlim);
grid on;
names = fieldnames(wgts);
for N=1:length(names),
  if strncmp('rb',names{N},2),
    eval(sprintf('tmp=wgts.%s;',names{N}));
    if get(tmp,'Value') == 1,
      lb = get(tmp,'String');
      break;
    end;
  end;
end;
ylabel(lb);
text(-0.05,1.05,tit,'units','normalized','fontname','Comic Sans MS');

return;

% -------------------------------------------------------------------
function SetFunBtn(hMain,HX,HY,TagName,Label)
% -------------------------------------------------------------------
cb = sprintf('dspimg(''Main_Callback'',gcbo,''%s'',guidata(gcbo))',...
            Label);
POS = [HX HY 16 1.55];
COL = [.9 .9 .9];
H = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',POS,'Callback',cb,...
    'Tag',TagName,'String',Label,...
    'TooltipString','Process Image Data','FontWeight','bold',...
    'ForegroundColor',[0 0 .1],'BackgroundColor',COL);
evalin('caller',sprintf('%s=H;',TagName));


% -------------------------------------------------------------------
function SetRadioBtn(hMain,HX,HY,TagName,Label)
% -------------------------------------------------------------------
cb = sprintf('dspimg(''RadioButton_Callback'',gcbo,''%s'',guidata(gcbo))',...
            TagName);
POS = [HX HY 18 1.52];
FCOL = [1 0 0];
BCOL = [1 1 .8];
H = uicontrol(...
'Parent',hMain,...
'Style','radiobutton',...
'Units','characters',...
'String',Label,...
'Position',POS,...
'BackgroundColor',BCOL,...
'ForegroundColor',FCOL,...
'Callback',cb,...
'ListboxTop',0,...
'TooltipString','',...
'Tag',TagName);
evalin('caller',sprintf('%s=H;',TagName));

