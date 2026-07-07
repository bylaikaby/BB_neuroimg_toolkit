function varargout = monlineview(varargin)
%MONLINEVIEW - viewer for online analysis
%  MONLINEVIEW called by MONLINE.
%
%  EXAMPLE :
%    >> monline
%    >> monlineview(SIG)
%    >> monlinepvpar(SIG)
%
%  NOTES :
%    This function will be called by monline.m after processing data.
%
%  VERSION :
%    0.90 01.10.06 YM  modified from onlinemview.
%    0.91 14.03.08 YM  bug fix, supports time-course/roi etc.
%    0.92 14.03.08 YM  supports 'sdu','percent'.
%    0.93 25.03.08 YM  supports 'cluster' detection.
%    0.94 02.04.08 YM  supports pos/neg, bug fix in subZoomInTC().
%    0.95 08.04.08 YM  bug fix, improved speed.
%    0.96 19.05.10 YM  supports GLM.
%    0.97 23.06.10 YM  supports the case of averaged scan.
%    0.98 03.12.10 YM  supports tSNR
%    0.99 11.12.13 YM  bug fix on displaying tSNR by 'none'.
%    1.00 18.04.18 YM  fixed problems of graphic handles (2014b).
%    1.10 19.04.18 YM  supports multiple testing correction (p-values adjust).
%    1.11 17.07.18 YM  fixed problems of graphic handles (2014b).
%    1.12 20.02.19 YM  supports plotting the model.
%
%  See also MONLINE MONLINEPROC MONLINEPVPAR PVAL_ADJUST


% display help if no arguments %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 0,  help monlineview; return;  end


% execute callback function then return; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(varargin{1}) && ~isempty(findstr(varargin{1},'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return;
end


% DEFAULT CONTROL SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ANAP.monlineview.viewpage = 1;
ANAP.monlineview.roi      = 'all';
ANAP.monlineview.drawroi  = 0;
ANAP.monlineview.drawele  = 1;
ANAP.monlineview.negcorr  = 1;
% statistics
ANAP.monlineview.alpha      = 0.01;
ANAP.monlineview.statistics = 't-test';
ANAP.monlineview.cluster    = 0;
% color bar settings
ANAP.monlineview.corana.minmax   = [];
ANAP.monlineview.glmana.minmax   = [];
ANAP.monlineview.glmana.betaminmax = [];
ANAP.monlineview.response.minmax = [];
ANAP.monlineview.tsnr.minmax = [];
ANAP.monlineview.gamma    = 1.8;





% PREPARE DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% called like monlineview(SIG,alpha,stat-name) by monline
ONLINE = varargin{1};
% for old compatibility
if isfield(ONLINE,'anap') && isfield(ONLINE.anap,'apply_hrf')
  if isnumeric(ONLINE.anap.apply_hrf)
    if ONLINE.anap.apply_hrf > 0
      ONLINE.anap.apply_hrf = 'Cohen';
    else
      ONLINE.anap.apply_hrf = 'none';
    end
  end
end
if nargin > 1,
  ANAP.monlineview.alpha = varargin{2};
end
if nargin > 2,
  ANAP.monlineview.statistics = varargin{3};
end


anaminv = 0;
anamaxv = ceil(mean(ONLINE.ana(:))*7.0/100)*100;
anagamma = 1.8;
ONLINE.anargb = subScaleAnatomy(ONLINE.ana,anaminv,anamaxv,anagamma);
ONLINE.anascale = [anaminv anamaxv anagamma];


% GET SCREEN SIZE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[scrW scrH] = subGetScreenSize('char');
% keep the figure size smaller than XGA (1024x768) for notebook PC.
% figWH: [185 57]chars = [925 741]pixels
figW = 185; figH = 57;
figX = max(min(63,scrW-figW),10);
figY = scrH-figH-9.7;


% SET WINDOW TITLE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isvector(ONLINE.scanreco),
  tmptitle = sprintf('%s:  %s  %d/%d  %s',...
                     mfilename,ONLINE.session,ONLINE.scanreco(1),ONLINE.scanreco(2),...
                     datestr(now));
else
  tmptitle = sprintf('%s:  %s [%s]/%d  %s',...
                     mfilename,ONLINE.session,...
                     deblank(sprintf('%d ',ONLINE.scanreco(:,1))),ONLINE.scanreco(1,2),...
                     datestr(now));
end


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



% ROI ACTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XDSP = 8; H = figH - 2.5;
RoiActTxt =  uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H-0.3 30 1.5],...
    'String','ROI:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','RoiActTxt',...
    'BackgroundColor',get(hMain,'Color'));
RoiActCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+10 H 25 1.5],...
    'Callback','monlineview(''ROI_Callback'',gcbo,''roi-action'',guidata(gcbo))',...
    'String',{'none','Append','Replace','Delete','Coordinate' 'Export as ROISIG'},'Value',1,...
    'Tag','RoiActCmb',...
    'HorizontalAlignment','left',...
    'TooltipString','Select ROI action',...
    'FontWeight','Bold');

% Superimpose or not %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
OverlayCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+40 H 20 1.5],...
    'Tag','OverlayCheck','Value',1,...
    'Callback','monlineview(''Main_Callback'',gcbo,''redraw-image'',guidata(gcbo))',...
    'String','Overlay','FontWeight','bold',...
    'TooltipString','map on/off','BackgroundColor',get(hMain,'Color'));

% MASING OF BLACK REGIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MaskBlackCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+55 H 20 1.5],...
    'Tag','MaskBlackCheck','Value',0,...
    'Callback','monlineview(''Main_Callback'',gcbo,''edit-alpha'',guidata(gcbo))',...
    'String','Black-mask','FontWeight','bold',...
    'TooltipString','Mask black regrions','BackgroundColor',get(hMain,'Color'));

% MASING BY tSNR %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MaskBySnrCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+77 H 20 1.5],...
    'Callback','monlineview(''Main_Callback'',gcbo,''edit-alpha'',guidata(gcbo))',...
    'Tag','MaskBySnrCheck','Value',1,...
    'String','tSNR-mask','FontWeight','bold',...
    'TooltipString','mask by tSNR','BackgroundColor',get(hMain,'Color'));
MaskBySnrEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+95 H 12 1.5],...
    'Callback','monlineview(''Main_Callback'',gcbo,''edit-alpha'',guidata(gcbo))',...
    'String','15','Tag','MaskBySnrEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','tSNR for masking',...
    'FontWeight','Bold');


% Paravision parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PvparButton = uicontrol(...
    'Parent',hMain,'Style','pushbutton',...
    'Units','char','Position',[XDSP+141 H 30 1.5],...
    'String','ACQP METHOD RECO','FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','center',...
    'TooltipString','Show ACQP/METHOD/RECO',...
    'Callback','monlineview(''Main_Callback'',gcbo,''show-pvpar2'',[])');


% P-value %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XDSP = 8; H = figH - 4.5;
AlphaTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H-0.3 30 1.5],...
    'String','Alpha:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','PvalueTxt',...
    'BackgroundColor',get(hMain,'Color'));
AlphaEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+10 H 25 1.5],...
    'Callback','monlineview(''Main_Callback'',gcbo,''edit-alpha'',guidata(gcbo))',...
    'String',num2str(ANAP.monlineview.alpha),'Tag','AlphaEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','alpha for significance level',...
    'FontWeight','Bold');

% WIDGETS TO SELECT STATISTICS/MODEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
stats = {'none'};
if isfield(ONLINE,'corr'),  stats{end+1} = 'corr';  end
if isfield(ONLINE,'glm'),   stats{end+1} = 'glm';  end
if isfield(ONLINE,'ttest'), stats{end+1} = 't-test';  end
idx = find(strcmpi(stats,ANAP.monlineview.statistics));
if isempty(idx),
  if length(stats) == 1,
    fprintf('WARNING %s: statistics ''%s'' not found.\n',mfilename,ANAP.monlineview.statistics);
    idx = 1;
  else
    idx = 2;
    ANAP.monlineview.statistics = stats{idx};
  end
end
StatTxt =  uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+40 H-0.3 30 1.5],...
    'String','Statistics:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','StatTxt',...
    'BackgroundColor',get(hMain,'Color'));
StatCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+53 H 20 1.5],...
    'Callback','monlineview(''Main_Callback'',gcbo,''init-stat-widget'',guidata(gcbo))',...
    'String',stats,'Value',idx,'Tag','StatCmb',...
    'HorizontalAlignment','left',...
    'TooltipString','Select statistics to plot',...
    'FontWeight','Bold');
clear stats;
% Multiple testing corretion %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TestingCorrTxt =  uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+76 H-0.3 30 1.5],...
    'String','p-values adjust:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','TestingCorrTxt',...
    'BackgroundColor',get(hMain,'Color'));
TestingCorrCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+95 H 25 1.5],...
    'String',{'none','Bonferroni','Holm','Hochberg','BY','BH(fdr)','Sidak'},...
    'Callback','monlineview(''Main_Callback'',gcbo,''edit-alpha'',guidata(gcbo))',...
    'HorizontalAlignment','left',...
    'Tag','TestingCorrCmb','Value',1,...
    'TooltipString','Select a page for lightbox',...
    'FontWeight','bold','Background','white');
if exist('pval_adjust.m','file') ~= 2,
  fprintf(' WARNING %s: ''pval_adjust.m'' not found, disabled multiple testing correction.\n',mfilename);
  set(TestingCorrCmb,'Enable','off');
end


% Cluster detection %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ClusterCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+127 H 20 1.5],...
    'Tag','ClusterCheck','Value',ANAP.monlineview.cluster,...
    'Callback','monlineview(''Main_Callback'',gcbo,''edit-alpha'',guidata(gcbo))',...
    'String','Cluster','FontWeight','bold',...
    'TooltipString','Cluster detection','BackgroundColor',get(hMain,'Color'));




% VIEW PAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XDSP = 8; H = 1; %H = figH - 4.5;
ViewPageCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+95 H 25 1.5],...
    'String',{'page1','page2','page3','page4'},...
    'Callback','monlineview(''Main_Callback'',gcbo,''view-page'',guidata(gcbo))',...
    'HorizontalAlignment','left',...
    'Tag','ViewPageCmb','Value',1,...
    'TooltipString','Select a page for lightbox',...
    'FontWeight','bold','Background','white');

    
% ANATOMY SCALE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XDSP = 8; H = figH - 7.0;
AnatScaleTxt =  uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+127 H-0.3 30 1.5],...
    'String','Anat. Scale:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','AnatScaleTxt',...
    'BackgroundColor',get(hMain,'Color'));
AnatScaleEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+141, H 30 1.5],...
    'String',sprintf('%g  %g  %g',anaminv,anamaxv,anagamma),...
    'Tag','AnatScaleEdt',...
    'Callback','monlineview(''Main_Callback'',gcbo,''update-anatomy'',guidata(gcbo))',...
    'HorizontalAlignment','center',...
    'TooltipString','Scale anatomy [min max gamma]',...
    'FontWeight','Bold');



% AXES FOR LIGHT BOX %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 3; XSZ = 55; YSZ = 20;
XDSP=8;
LightboxAxs = axes(...
    'Parent',hMain,'Tag','LightboxAxs',...
    'Units','char','Position',[XDSP H XSZ*2+10 YSZ*2+8.5],...
    'Box','off','color','black','Visible','off');



% AXES FOR COLORBAR %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 27.5;
XDSP=XDSP+XSZ+7;
ColorbarAxs = axes(...
    'Parent',hMain,'Tag','ColorbarAxs',...
    'units','char','Position',[XDSP+12+XSZ H XSZ*0.1 YSZ],...
    'FontSize',8,...
    'Box','off','YAxisLocation','left','XTickLabel',{},'XTick',[]);

% DATA FOR COLOR BAR %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DataCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+12+XSZ+12 H+YSZ-1.5 30 1.5],...
    'Callback','monlineview(''Main_Callback'',gcbo,''select-stat'',guidata(gcbo))',...
    'String',{'Response'},...
    'Tag','DataCmb','Value',1,...
    'TooltipString','Select data to plot',...
    'FontWeight','bold');
SelectValueCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+12+XSZ+12 H+YSZ-7.5 30 1.5],...
    'Callback','monlineview(''Main_Callback'',gcbo,''select-stat'',guidata(gcbo))',...
    'String',{'positive','negative','pos+neg'},...
    'Tag','SelectValueCmb','Value',3,...
    'TooltipString','SubSelect value to plot',...
    'FontWeight','bold');



% COLORBAR MIN-MAX %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ColorbarMinMaxTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+12+XSZ+12, H+YSZ-3.5 20 1.25],...
    'String','min-max: ','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'BackgroundColor',get(hMain,'color'));
ColorbarMinMaxEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+12+XSZ+25, H+YSZ-3.5 17 1.5],...
    'String','','Tag','ColorbarMinMaxEdt',...
    'Callback','monlineview(''Main_Callback'',gcbo,''update-cmap'',guidata(gcbo))',...
    'HorizontalAlignment','center',...
    'TooltipString','set colorbar min max',...
    'FontWeight','Bold');

% COLORBAR GAMAMA SETTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+12+XSZ+12, H+YSZ-5.5 20 1.25],...
    'String','gamma: ','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'BackgroundColor',get(hMain,'color'));
GammaEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+12+XSZ+25, H+YSZ-5.5 17 1.5],...
    'Callback','monlineview(''Main_Callback'',gcbo,''update-cmap'',guidata(gcbo))',...
    'String',num2str(ANAP.monlineview.gamma),'Tag','GammaEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set a gamma value for color bar',...
    'FontWeight','bold');


% INFORMATION TEXT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%H = 13.5;
H = 27.5;
InfoTxt = uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','char','Position',[XDSP+12+XSZ+12 H 30 10],...
    'String',{'session','group','datsize','resolution'},...
    'HorizontalAlignment','left',...
    'FontName','Comic Sans MS','FontSize',9,...
    'TooltipString','Double-click invokes ACQP/METHOD/RECO window',...
    'Callback','monlineview(''Main_Callback'',gcbo,''show-pvpar'',guidata(gcbo))',...
    'Tag','InfoTxt','Background','white');


% TIME COURSE AXES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TCXSZ = 42;  H = 3;
TimeCourseAxs = axes(...
    'Parent',hMain,'Tag','TimeCourseAxs',...
    'Units','char','Position',[XDSP+12+XSZ H TCXSZ YSZ],...
    'Box','off','color','white');
DrawModelCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+12+XSZ H+YSZ 20 1.5],...
    'Tag','DrawModelCheck','Value',0,...
    'String','DrawModel','FontWeight','bold',...
    'Callback','monlineview(''Main_Callback'',gcbo,''redraw-timecourse'',guidata(gcbo))',...
    'TooltipString','draw model on/off','BackgroundColor',get(hMain,'Color'));
TCHoldCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+12+XSZ+TCXSZ-12 H+YSZ 20 1.5],...
    'Tag','TCHoldCheck','Value',0,...
    'String','Hold On','FontWeight','bold',...
    'TooltipString','hold on/off','BackgroundColor',get(hMain,'Color'));







% get widgets handles at this moment
HANDLES = findobj(hMain);


% INITIALIZE THE APPLICATION
setappdata(hMain,'ONLINE',ONLINE);
setappdata(hMain,'STATMAP',[]);
setappdata(hMain,'ANAP',ANAP);
%setappdata(hMain,'MASKTHRESHOLD',mean(ONLINE.dat(:))*0.7);
setappdata(hMain,'TC_COLORS','rbgcmy');
%setappdata(hMain,'TC_COLORS',lines(64));
setappdata(hMain,'ROI',[]);
Main_Callback(LightboxAxs,'init');
set(hMain,'visible','on');



% NOW SET "UNITS" OF ALL WIDGETS AS "NORMALIZED".
HANDLES = HANDLES(HANDLES ~= hMain);
set(HANDLES,'units','normalized');



% RETURNS THE WINDOW HANDLE IF REQUIRED.
if nargout,
  varargout{1} = hMain;
end

return;






% ==================================================================
function Main_Callback(hObject,eventdata,handles)
% ==================================================================
%fprintf('Main_Callback.%s\n',eventdata);
wgts = guihandles(hObject);
switch lower(eventdata),
 case {'init'}
  ANAP  = getappdata(wgts.main,'ANAP');
  ONLINE = getappdata(wgts.main,'ONLINE');
  MINV = -1;  MAXV = 1;
  % set min/max value for scaling
  set(wgts.ColorbarMinMaxEdt,'string',sprintf('%.1f  %.1f',MINV,MAXV));
  
  % set information text
  pvpar = ONLINE.pvpar;
  INFTXT = {};
  if isvector(ONLINE.scanreco),
    INFTXT{end+1} = sprintf('%s  %d/%d',ONLINE.session,ONLINE.scanreco(1),ONLINE.scanreco(2));
  else
    INFTXT{end+1} = sprintf('%s  [%s]/%d',ONLINE.session,...
                            deblank(sprintf('%d ',ONLINE.scanreco(:,1))),ONLINE.scanreco(1,2));
  end
  INFTXT{end+1} = sprintf('%s',pvpar.acqp.ACQ_time(2:end-1));
  INFTXT{end+1} = sprintf('%s',pvpar.acqp.PULPROG);
  INFTXT{end+1} = sprintf('[%dx%dx%d/%d]',pvpar.nx,pvpar.ny,pvpar.nsli,pvpar.nt);
  INFTXT{end+1} = sprintf('[%gx%gx%g]',ONLINE.ds(1),ONLINE.ds(2),ONLINE.ds(3));
  INFTXT{end+1} = sprintf('nseg=%d, imgtr=%gs',pvpar.nseg,pvpar.imgtr);
  if isfield(ONLINE.anap,'apply_hrf'),
    INFTXT{end+1} = sprintf('HRF=%s',ONLINE.anap.apply_hrf);
  end
  
  set(wgts.InfoTxt,'String',INFTXT);
  
  % initialize view
%   if nargin < 3,
%     OrthoView_Callback(hObject(1),'init');
%   else
%     OrthoView_Callback(hObject(1),'init',handles);
%   end
  if nargin < 3,
    LightboxView_Callback(hObject(1),'init');
  else
    LightboxView_Callback(hObject(1),'init',handles);
  end
  
  % initialize the statistical map
  Main_Callback(hObject,'init-stat-widget',[]);
  
  %Main_Callback(hObject,'redraw',[]);
  
 case {'init-stat-widget'} % niko fix
  % INITIALIZE WIDGETS FOR THE SELECTED STATISTICS
  StatName = get(wgts.StatCmb,'String'); StatName = StatName{get(wgts.StatCmb,'Value')};
  ONLINE = getappdata(wgts.main,'ONLINE');
   switch lower(StatName),
    case {'corr'}
     set(wgts.DataCmb,'String',{'R_value','Response','tSNR'},'Value',1);
     %set(wgts.DataCmb,'String',{'R_value'},'Value',1);
    case {'t-test','ttest'}
     set(wgts.DataCmb,'String',{'T_value','Response','tSNR'},'Value',1);
     %set(wgts.DataCmb,'String',{'T_value'},'Value',1);
    case {'glm'}
     set(wgts.DataCmb,'String',{'T_value','Beta','Response','tSNR'},'Value',1);
    case {'none'}
     set(wgts.DataCmb,'String',{'Response','tSNR'},'Value',1);
   end
   Main_Callback(hObject,'select-stat',[]);  % will update map/time-course
  
 case {'init-statmap'} % niko
   % PREPARE STATISTICAL MAP STRUCTURE
   ONLINE = getappdata(wgts.main,'ONLINE');
   STATMAP = getappdata(wgts.main,'STATMAP');
   alpha1 = str2double(get(wgts.AlphaEdt,'String'));
   StatName = get(wgts.StatCmb,'String'); StatName = StatName{get(wgts.StatCmb,'Value')};
   if ~isempty(alpha1),
     switch lower(StatName),
      case {'corr'}
       STATMAP = subGetStatCorr(ONLINE,wgts,alpha1);
      case {'t-test','ttest'}
       STATMAP = subGetStatTtest(ONLINE,wgts,alpha1);
      case {'glm'}
       STATMAP = subGetStatGlm(ONLINE,wgts,alpha1);
      otherwise
       STATMAP = subGetStatNull(ONLINE,wgts,alpha1);
     end
     setappdata(wgts.main,'STATMAP',STATMAP);
     %Main_Callback(hObject,'redraw',[]);
   end

          
 case {'select-stat'}
  DATNAME = get(wgts.DataCmb,'String');
  DATNAME = DATNAME{get(wgts.DataCmb,'Value')};
  ANAP = getappdata(wgts.main,'ANAP');
  ONLINE = getappdata(wgts.main,'ONLINE');
  switch lower(DATNAME),
   case {'statv','stat','t_value','f_value'}
    MINV = -10;   MAXV = 10;
    StatName = get(wgts.StatCmb,'String'); StatName = StatName{get(wgts.StatCmb,'Value')};
    if strcmpi(StatName,'glm') && length(ANAP.monlineview.glmana.minmax) == 2,
      MINV = ANAP.monlineview.glmana.minmax(1);  MAXV = ANAP.monlineview.glmana.minmax(2);
    end
   case {'r_value','r-value','r'}
    MINV = -1;  MAXV = 1;
    if length(ANAP.monlineview.corana.minmax) == 2,
      MINV = ANAP.monlineview.corana.minmax(1);  MAXV = ANAP.monlineview.corana.minmax(2);
    end
   case {'amplitude','response'}
    tmpv = ceil(max(ONLINE.resp.dat(:))*0.7);
    %MINV = -3;  MAXV = 3;
    MINV = -tmpv;  MAXV = tmpv;
    if length(ANAP.monlineview.response.minmax) == 2,
      MINV = ANAP.monlineview.response.minmax(1);  MAXV = ANAP.monlineview.response.minmax(2);
    end
   case {'beta'}
    MINV = -3;  MAXV = 3;
    if length(ANAP.monlineview.glmana.betaminmax) == 2,
      MINV = ANAP.monlineview.glmana.betaminmax(1);  MAXV = ANAP.monlineview.glmana.betaminmax(2);
    end
   case {'tsnr'}
    MINV = 0;  MAXV = 100;
    if length(ANAP.monlineview.tsnr.minmax) == 2,
      MINV = ANAP.monlineview.tsnr.minmax(1);  MAXV = ANAP.monlineview.tsnr.minmax(2);
    end
 
   otherwise
    MINV = -3;  MAXV = 3;
  end
  MINMAX = getappdata(wgts.main,'MINMAX');
  if isfield(MINMAX,DATNAME),
    MINV = MINMAX.(DATNAME)(1);  MAXV = MINMAX.(DATNAME)(2);
  else
    MINMAX.(DATNAME) = [MINV MAXV];
    setappdata(wgts.main,'MINMAX',MINMAX);
  end
  
  % set min/max value for scaling
  set(wgts.ColorbarMinMaxEdt,'string',sprintf('%.1f  %.1f',MINV,MAXV));
  
  Main_Callback(hObject,'init-statmap',[]);
  Main_Callback(hObject,'update-cmap',[]);  % redraw image only
  Main_Callback(hObject,'redraw-timecourse',[]);

 
 case {'update-cmap'}
  tmpv = str2num(get(wgts.ColorbarMinMaxEdt,'String'));
  MINMAX = getappdata(wgts.main,'MINMAX');
  DATNAME = get(wgts.DataCmb,'String');
  DATNAME = DATNAME{get(wgts.DataCmb,'Value')};
  if length(tmpv) ~= 2,
    MINV = MINMAX.(DATNAME)(1);
    MAXV = MINMAX.(DATNAME)(2);
    set(wgts.ColorbarMinMaxEdt,'String',sprintf('%.1f  %.1f',MINV,MAXV));
  else
    MINV = tmpv(1);  MAXV = tmpv(2);
    MINMAX.(DATNAME) = [MINV MAXV];
    setappdata(wgts.main,'MINMAX',MINMAX);
  end
  
  cmap = subGetColorMap(wgts);
  setappdata(wgts.main,'CMAP',cmap);
  % update tick for colorbar
  GRAHANDLE = getappdata(wgts.main,'GRAHANDLE');
  if ~isempty(GRAHANDLE),
    ydat = (0:255)/255 * (MAXV - MINV) + MINV;
    set(wgts.main,'CurrentAxes',wgts.ColorbarAxs);
    colormap(cmap);
    set(GRAHANDLE.colorbar,'ydata',ydat);
    set(wgts.ColorbarAxs,'ylim',[MINV MAXV]);
  end
  
  % now draw a color bar
  set(wgts.main,'CurrentAxes',wgts.ColorbarAxs);
  ydat = (0:255)/255 * (MAXV - MINV) + MINV;
  hColorbar = imagesc(1,ydat,(0:255)'); colormap(cmap);
  set(wgts.ColorbarAxs,'Tag','ColorbarAxs');  % set this again, some will reset.
  set(wgts.ColorbarAxs,'ylim',[MINV MAXV],...
                    'YAxisLocation','left','XTickLabel',{},'XTick',[],'Ydir','normal');
  
  GRAHANDLE.colorbar   = hColorbar;

  Main_Callback(hObject,'redraw-image',[]);
  
  
 case {'edit-alpha'}
  alpha1 = str2double(get(wgts.AlphaEdt,'String'));
  if ~isempty(alpha1),
    Main_Callback(hObject,'init-statmap',[]);
    Main_Callback(hObject,'redraw',[]);
  end
  
 case {'redraw'}
  % UPDATES BOTH IMAGES AND TIME-COURSE PLOT
%   ViewMode = get(wgts.ViewModeCmb,'String');
%   ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
%   if strcmpi(ViewMode,'orthogonal'),
%     OrthoView_Callback(hObject,'redraw',[]);
%   else
    LightboxView_Callback(hObject,'redraw',[]);
%   end
  Main_Callback(hObject,'redraw-timecourse',[]);

 case {'redraw-image'}
  % UPDATES IMAGES ONLY
%   ViewMode = get(wgts.ViewModeCmb,'String');
%   ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
%   if strcmpi(ViewMode,'orthogonal'),
%     OrthoView_Callback(hObject,'redraw',[]);
%   else
    LightboxView_Callback(hObject,'redraw',[]);
%   end

 case {'redraw-timecourse'}
  subPlotTimeCourse(wgts);
  drawnow;
 
 case {'view-page'}
  %ViewMode = get(wgts.ViewModeCmb,'String');
  %ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  ViewMode = 'lightbox-trans';
  if ~isempty(strfind(ViewMode,'lightbox')),
    LightboxView_Callback(hObject,'redraw',[]);
  end
 
 case {'dir-reverse'}
  %ViewMode = get(wgts.ViewModeCmb,'String');
  %ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  ViewMode = 'lightbox-trans';
  if ~isempty(strfind(ViewMode,'lightbox')),
    LightboxView_Callback(hObject,'redraw',[]);
  else
    OrthoView_Callback(hObject,'dir-reverse',[]);
  end
  
 case {'update-anatomy'}
  anascale = str2num(get(wgts.AnatScaleEdt,'String'));
  if length(anascale) == 3,
    ONLINE = getappdata(wgts.main,'ONLINE');
    ONLINE.anargb = subScaleAnatomy(ONLINE.ana,anascale(1),anascale(2),anascale(3));
    ONLINE.anascale = anascale;
    setappdata(wgts.main,'ONLINE',ONLINE);
    Main_Callback(hObject,'redraw-image',[]);
  end

 case {'button-timecourse'}
  click = get(wgts.main,'SelectionType');
  if strcmpi(click,'open'),
    % doublze click
    ONLINE = getappdata(wgts.main,'ONLINE');
    subZoomInTC(wgts,ONLINE);
  end

 case {'show-pvpar'}
  if ~strcmp(get(wgts.main,'SelectionType'),'open'), return;  end
  
  ONLINE = getappdata(wgts.main,'ONLINE');
  clear monlinepvpar;
  if isobject(wgts.main), 
    monlinepvpar(ONLINE,'hfig',wgts.main.Number+100);
  else
    monlinepvpar(ONLINE,'hfig',wgts.main+100);
  end
  return
 case {'show-pvpar2'}
  ONLINE = getappdata(wgts.main,'ONLINE');
  clear monlinepvpar;
  if isobject(wgts.main), 
    monlinepvpar(ONLINE,'hfig',wgts.main.Number+100);
  else
    monlinepvpar(ONLINE,'hfig',wgts.main+100);
  end
  return
  
 otherwise
  fprintf('WARNING %s: Main_Callback() ''%s'' not supported yet.\n',mfilename,eventdata);
end
  
return;



% ==================================================================
% SUBFUNCTION to handle ROI
function ROI_Callback(hObject,eventdata,handles)
if ~strcmpi(eventdata,'roi-action'), return;  end

wgts = guihandles(hObject);


ROI = getappdata(wgts.main,'ROI');

RoiAction = get(wgts.RoiActCmb,'String');
RoiAction = RoiAction{get(wgts.RoiActCmb,'Value')};

set(wgts.main,'CurrentAxes',wgts.LightboxAxs);

switch lower(RoiAction),
 case {'coordinate'}
  set(wgts.RoiActCmb,'Enable','off');
  tmpxy = ginput(1);
  set(wgts.RoiActCmb,'Enable','on');
  [tmp epix epiy epiz] = subGetROI(wgts,[],tmpxy(1),tmpxy(2));
  if ~isempty(epix),
    fprintf('  XYZ=[%d %d %d]\n',epix,epiy,epiz);
  end

 case {'append','replace'}
  if strcmpi(RoiAction,'replace'),
    ROI = [];
    setappdata(wgts.main,'ROI',[]);
    delete(findobj(wgts.LightboxAxs,'tag','ROI'));  drawnow;
  end
  % add ROIs
  set(wgts.RoiActCmb,'Enable','off');
  while 1,
    try
      [anamask,anapx,anapy] = monline_roipoly;
    catch
      % Note that Matlab 7.5 roipoly() will crash by right-click.
      % check user interaction
      click = get(wgts.main,'SelectionType');
      if strcmpi(click,'alt'),
        break;
      else
        lasterr
      end
    end
    % check user interaction
    click = get(wgts.main,'SelectionType');
    if strcmpi(click,'extend'),
      set(wgts.Sticky,'Value',0);
      %fprintf('click-extend');
      break;
    elseif strcmpi(click,'alt'),
      %fprintf('click-alt');
      break;
    else
      %fprintf('click-%s',click);
    end;
    % check size of poly, if very small ignore it.
    %length(anapx), length(anapy)
    if length(anapx)*length(anapy) < 1,  break;  end

    anamask = logical(anamask'); % transpose "mask"
    % now register the new roi
    N = length(ROI) + 1;
    ROI{N} = subGetROI(wgts,anamask,anapx,anapy);
    
    % draw the polygon
    set(wgts.main,'CurrentAxes',wgts.LightboxAxs);
    plot(anapx,anapy,'color',[0.4 1.0 0.4],'tag','ROI');
    
    % put some text
    if N == 1,
      text(max(get(gca,'xlim')),0,'ROI: ON','tag','ROI',...
           'color',[0.9 0.9 0.5],'VerticalAlignment','bottom',...
           'HorizontalAlignment','right',...
           'FontName','Comic Sans MS','FontSize',8,'Fontweight','bold');
    end
  end
  setappdata(wgts.main,'ROI',ROI);
  set(wgts.RoiActCmb,'Enable','on');
  
 case {'delete','clear'}
  ROI = [];
  setappdata(wgts.main,'ROI',[]);
  delete(findobj(wgts.LightboxAxs,'tag','ROI'));  drawnow;
  
 case {'export as roisig' 'export'}
  subExportROI(wgts);
  
 otherwise
  fprintf('WARNING %s: ROI_Callback() ''%s'' not supported yet.\n',mfilename,RoiAction);
end


% set to 'no action'
set(wgts.RoiActCmb,'Value',1);

% update time course
Main_Callback(hObject,'redraw-timecourse',[]);

return


% ==================================================================
% SUBFUNCTION to get ROI info
function [ROI, epix, epiy, epiz] = subGetROI(wgts,anamask,anapx,anapy)

ONLINE = getappdata(wgts.main,'ONLINE');

pagestr = get(wgts.ViewPageCmb,'String');
pagestr = pagestr{get(wgts.ViewPageCmb,'Value')};
ipage = sscanf(pagestr,'Page%d:');


episz = [size(ONLINE.dat,2), size(ONLINE.dat,3), size(ONLINE.dat,4)];
anasz = [size(ONLINE.ana,1), size(ONLINE.ana,2), size(ONLINE.ana,3)];
nmaximages = size(ONLINE.dat,4);
[NRow NCol] = subGetNRowNCol(nmaximages,[anasz(1) anasz(2)]);


nx = anasz(1); ny = anasz(2);

% stupid bug of matlab...
if NCol*nx ~= size(anamask,1) || NRow*ny ~= size(anamask,2),
  anamask = monline_roipoly(ones(NCol*nx,NRow*ny)',anapx,anapy);
  anamask = logical(anamask'); % transpose "mask"
  if length(anapx) < 3,
    anamask(round(anapx),round(anapy)) = 1;
  end
end




[anaX anaY] = find(anamask > 0);
epix = zeros(1,length(anaX));
epiy = zeros(1,length(anaX));
epiz = zeros(1,length(anaX));
for N=1:length(anaX),
  tmpslice = floor((ny*NRow-anaY(N))/ny)*NCol + floor(anaX(N)/nx)+1  + NRow*NCol*(ipage-1);
  tmpx = mod(anaX(N),nx);
  tmpy = mod(ny*NRow-anaY(N),ny);
  
  epix(N) = round(tmpx/nx*episz(1));
  epiy(N) = round(tmpy/ny*episz(2));
  epiz(N) = tmpslice;
end

%[epix(:) epiy(:) epiz(:)]

tmpidx = find(epix >= 1 & epix <= nx & epiy >= 1 & epiy <= ny & epiz >= 1 & epiz <= episz(3));
epix = epix(tmpidx);
epiy = epiy(tmpidx);
epiz = epiz(tmpidx);

ROI.name = 'test';
ROI.epiidx = sub2ind(episz,epix,epiy,epiz); % epix as y of original data
ROI.anapx  = anapx;
ROI.anapy  = anapy;

%tmpdat = zeros(episz);
%tmpdat(ROI.epiidx) = 1;
%figure(10);
%imagesc(squeeze(tmpdat(:,:,epiz(1)))');


return


% ==================================================================
% SUBFUNCTION to export ROI data
function subExportROI(wgts)
ROI    = getappdata(wgts.main,'ROI');
ONLINE = getappdata(wgts.main,'ONLINE');
if isempty(ROI)
  fprintf('%s : no ROI data to export.\n',mfilename);
  return
end

tmpidx = [];
for N=1:length(ROI),
  tmpidx = cat(2,tmpidx,ROI{N}.epiidx(:)');
end
tmpidx = sort(unique(tmpidx));

imgsz = size(ONLINE.dat);
ONLINE.dat = reshape(ONLINE.dat,[imgsz(1) prod(imgsz(2:end))]);
tcdat = ONLINE.dat(:,tmpidx);

[ix iy iz] = ind2sub(imgsz(2:end), tmpidx);

ROISIG = ONLINE;
ROISIG.dat    = tcdat;
ROISIG.coords = [ix(:), iy(:), iz(:)];


if isfield(ROISIG,'tripilot'),  ROISIG = rmfield(ROISIG,'tripilot');  end
if isfield(ROISIG,'resp')
  ROISIG.resp.dat = ROISIG.resp.dat(tmpidx);
end
if isfield(ROISIG,'ttest')
  ROISIG.ttest.dat = ROISIG.ttest.dat(tmpidx);
  ROISIG.ttest.p   = ROISIG.ttest.p(tmpidx);
end
if isfield(ROISIG,'glm')
  ROISIG.glm.dat  = ROISIG.glm.dat(tmpidx);
  ROISIG.glm.p    = ROISIG.glm.p(tmpidx);
  ROISIG.glm.beta = ROISIG.glm.beta(tmpidx);
end
if isfield(ROISIG,'corr')
  ROISIG.corr.dat = ROISIG.corr.dat(tmpidx);
  ROISIG.corr.p   = ROISIG.corr.p(tmpidx);
end

assignin('base', 'ROISIG', ROISIG);

fprintf('%s %s : exported as ROISIG in the workspace (base).\n',datestr(now,'HH:MM:SS'),mfilename);

return




% ==================================================================
% SUBFUNCTION to handle lightbox view
function LightboxView_Callback(hObject,eventdata,handles)
% ==================================================================
%fprintf('LightboxView.%s\n',eventdata);  
wgts = guihandles(get(hObject,'Parent'));
ONLINE = getappdata(wgts.main,'ONLINE');
ANA  = getappdata(wgts.main,'ANA');
STATMAP = getappdata(wgts.main, 'STATMAP');
MINMAX  = getappdata(wgts.main, 'MINMAX');
ALPHA   = str2double(get(wgts.AlphaEdt,'String'));
CMAP    = getappdata(wgts.main,'CMAP');
% ViewMode = get(wgts.ViewModeCmb,'String');
% ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
% switch lower(ViewMode),
%  case {'lightbox-cor'}
%   iDimension = 2;
%  case {'lightbox-sag'}
%   iDimension = 1;
%  case {'lightbox-trans'}
%   iDimension = 3;
%  otherwise
  iDimension = 3;
% end

 

nmaximages = size(ONLINE.dat,4);
[NRow NCol] = subGetNRowNCol(nmaximages,size(ONLINE.ana));

switch lower(eventdata),
 case {'init'}
  NPages = floor((nmaximages-1)/NRow/NCol)+1;
  tmptxt = {};
  for iPage = 1:NPages,
    tmptxt{iPage} = sprintf('Page%d: %d-%d',iPage,...
         (iPage-1)*NRow*NCol+1,min([nmaximages,iPage*NRow*NCol]));
  end
  set(wgts.ViewPageCmb,'String',tmptxt,'Value',1);
  %LightboxView_Callback(hObject,'redraw',[]);

  
 case {'redraw'}
  DATNAME = get(wgts.DataCmb,'String');
  DATNAME = DATNAME{get(wgts.DataCmb,'Value')};
  MINV = MINMAX.(DATNAME)(1);  MAXV = MINMAX.(DATNAME)(2);

  axes(wgts.LightboxAxs);  cla;
  pagestr = get(wgts.ViewPageCmb,'String');
  pagestr = pagestr{get(wgts.ViewPageCmb,'Value')};
  ipage = sscanf(pagestr,'Page%d:');
  SLICES = (ipage-1)*NRow*NCol+1:min([nmaximages,ipage*NRow*NCol]);
  Xdim = 1;  Ydim = 2;
  INFSTR = 'Trans';
  Yrev = 0;
  nX = size(ONLINE.anargb,1);
  nY = size(ONLINE.anargb,2);
  X = 1:nX;  Y = nY:-1:1;
  
  for N = 1:length(SLICES),
    iSlice = SLICES(N);
    tmpimg = squeeze(ONLINE.anargb(:,:,iSlice,:));
    tmps = squeeze(STATMAP.dat(:,:,iSlice));
    tmpp = squeeze(STATMAP.p(:,:,iSlice));
    tmpm = squeeze(STATMAP.mask.dat(:,:,iSlice));
    if get(wgts.OverlayCheck,'Value') == 0,
      tmpp(:) = 1;
    else
      idx = find(tmpm(:) == 0);
      tmps(idx) = 0;
      tmpp(idx) = 1;
    end

    tmpimg = subFuseImage(tmpimg,tmps,MINV,MAXV,tmpp,ALPHA,CMAP);
    % iCol = floor((N-1)/NCol)+1;
    % iRow = mod((N-1),NCol)+1;
    % offsX = nX*(iRow-1);
    % offsY = nY*NRow - iCol*nY;
    iRow = floor((N-1)/NCol)+1;
    iCol = mod((N-1),NCol)+1;
    offsX = nX*(iCol-1);
    offsY = nY*(NRow - iRow);
    %fprintf('%3d: [%d %d] -- [%d %d]\n',N,iRow,iCol,offsX,offsY);
    tmpimg = permute(tmpimg,[2 1 3]);
    tmpx = X + offsX;  tmpy = Y + offsY;
    image(tmpx,tmpy,tmpimg);  hold on;
    
    text(min(tmpx)+1,max(tmpy),sprintf('slice %d',iSlice),...
       'color',[0.9 0.9 0.5],'VerticalAlignment','top',...
       'FontName','Comic Sans MS','FontSize',8,'Fontweight','bold');

  end

  haxs = wgts.LightboxAxs;
  set(haxs,'Tag','LightboxAxs','color','black');
  set(haxs,'XTickLabel',{},'YTickLabel',{},'XTick',[],'YTick',[]);
  set(haxs,'xlim',[0 nX*NCol],'ylim',[0 nY*NRow]);
  set(haxs,'YDir','normal');
  set(get(haxs,'Children'),...
      'ButtonDownFcn','monlineview(''LightboxView_Callback'',gcbo,''button-lightbox'',guidata(gcbo))');
  set(haxs,...
      'ButtonDownFcn','monlineview(''LightboxView_Callback'',gcbo,''button-lightbox'',guidata(gcbo))');
  
  subDrawROIs(wgts);
  drawnow;
  
 case {'button-lightbox'}
  click = get(wgts.main,'SelectionType');
  if strcmpi(click,'open'),
    % double click
    ONLINE = getappdata(wgts.main,'ONLINE');
    subZoomInLightBox(wgts,ONLINE);
  end

  
 otherwise
  fprintf('WARNING %s: LightboxView_Callback() ''%s'' not supported yet.\n',...
          mfilename,eventdata);
end

return;


% ==================================================================
% SUBFUNCTION to scale anatomy image
function ANARGB = subScaleAnatomy(ANA,MINV,MAXV,GAMMA)
% ==================================================================
if isstruct(ANA),
  tmpana = double(ANA.dat);
else
  tmpana = double(ANA);
end
clear ANA;
tmpana = (tmpana - MINV) / (MAXV - MINV);
tmpana = round(tmpana*255) + 1; % +1 for matlab indexing
tmpana(tmpana(:) <   0) =   1;
tmpana(tmpana(:) > 256) = 256;
anacmap = gray(256).^(1/GAMMA);
for N = size(tmpana,3):-1:1,
  ANARGB(:,:,:,N) = ind2rgb(tmpana(:,:,N),anacmap);
end

ANARGB = permute(ANARGB,[1 2 4 3]);  % [x,y,rgb,z] --> [x,y,z,rgb]

  
return;



% ==================================================================
% SUBFUNCTION to fuse anatomy and functional images
function IMG = subFuseImage(ANARGB,STATV,MINV,MAXV,PVAL,ALPHA,CMAP)
% ==================================================================
if ndims(ANARGB) == 2,
  % image is just a vector, squeezed, so make it 2D image with RGB
  ANARGB = permute(ANARGB,[1 3 2]);
end

IMG = ANARGB;
if isempty(STATV) || isempty(PVAL) || isempty(ALPHA),  return;  end

PVAL(isnan(PVAL(:))) = 1;  % to avoid error;

imsz = [size(ANARGB,1) size(ANARGB,2)];
if any(imsz ~= size(STATV)),
  if datenum(version('-date')) >= datenum('January 29, 2007'),
    STATV = imresize_old(STATV,imsz,'nearest',0);
    PVAL  = imresize_old(PVAL, imsz,'nearest',0);
  else
    STATV = imresize(STATV,imsz,'nearest',0);
    PVAL  = imresize(PVAL, imsz,'nearest',0);
    %STATV = imresize(STATV,imsz,'bilinear',0);
    %PVAL  = imresize(PVAL, imsz,'bilinear',0);
  end
end


tmpdat = repmat(PVAL,[1 1 3]);   % for rgb
idx = find(tmpdat(:) < ALPHA);
if ~isempty(idx),
  % scale STATV from MINV to MAXV as 0 to 1
  STATV = (STATV - MINV)/(MAXV - MINV);
  STATV = round(STATV*255) + 1;  % +1 for matlab indexing
  STATV(STATV(:) <   0) =   1;
  STATV(STATV(:) > 256) = 256;
  % map 0-256 as RGB
  STATV = ind2rgb(STATV,CMAP);
  % replace pixels
  %fprintf('\nsize(IMG)=  '); fprintf('%d ',size(IMG));
  %fprintf('\nsize(STATV)='); fprintf('%d ',size(STATV));
  IMG(idx) = STATV(idx);
end


return;



% ==================================================================
% SUBFUNCTION to get a color map
function CMAP = subGetColorMap(wgts)
% ==================================================================
DATNAME = get(wgts.DataCmb,'String');
DATNAME = DATNAME{get(wgts.DataCmb,'Value')};

switch lower(DATNAME),
 case {'stat','statv'}
  CMAP = hot(256);
 case {'tsnr'}
  CMAP = jet(256);
 otherwise   
  MINV = str2num(get(wgts.ColorbarMinMaxEdt,'String'));
  MINV = MINV(1);
  if MINV >= 0,
    CMAP = hot(256);
  else
    % posmap = hot(128);
    % negmap = zeros(128,3);
    % negmap(:,3) = (1:128)'/128;
    % %negmap(:,2) = flipud(brighten(negmap(:,3),-0.5));
    % negmap(:,3) = brighten(negmap(:,3),0.5);
    % negmap = flipud(negmap);
    % CMAP = [negmap; posmap];
  
    posmap = hot(128);
    negmap = zeros(128,3);
    negmap(1:64,3) = (1:64)'/64;
    negmap(65:end,3) = 1;
    negmap(65:end,2) = (1:64)'/64;
    CMAP = [flipud(negmap); posmap];
  end
end

%cmap = cool(256);
%cmap = autumn(256);
gammav = str2double(get(wgts.GammaEdt,'String'));
if ~isempty(gammav),
  CMAP = CMAP.^(1/gammav);
end


return;


% ==================================================================
% SUBFUNCTION to do cluster analysis
function STATMAP = subDoClusterAnalysis(STATMAP,fname,anap)
% ==================================================================

if isfield(anap,'mview'),
  anap = anap.mview;
else
  anap = [];
end

if strcmpi(fname,'mcluster3'),
  B = 5;  cutoff = round((2*(B-1)+1)^3*0.3);
  % overwrite settings with anap.mcluster3
  if isfield(anap,'mcluster3'),
    if isfield(anap.mcluster3,'B') && ~isempty(anap.mcluster3.B),
      B = anap.mcluster3.B;
    end
    if isfield(anap.mcluster3,'cutoff') && ~isempty(anap.mcluster3.cutoff),
      cutoff = anap.mcluster3.cutoff;
    end
  end
  STATMAP.mask.func = fname;
  STATMAP.mask.mcluster3_B = B;
  STATMAP.mask.mcluster3_cutoff = cutoff;
  idx = find(STATMAP.mask.dat(:) > 0);
  [ix,iy,iz] = ind2sub(size(STATMAP.p),idx);
  coords = zeros(length(ix),3);
  coords(:,1) = ix(:);  coords(:,2) = iy(:); coords(:,3) = iz(:);
  fprintf('%s.mcluster3(n=%d,B=%d,cutoff=%d): %s-',...
          mfilename,size(coords,1),B,cutoff,datestr(now,'HH:MM:SS'));
  coords = mcluster3(coords, STATMAP.mask.mcluster3_B, STATMAP.mask.mcluster3_cutoff);
  fprintf('%s\n',datestr(now,'HH:MM:SS'));
  STATMAP.mask.dat(:)   = 0;
  if ~isempty(coords),
    idx = sub2ind(size(STATMAP.p),coords(:,1),coords(:,2),coords(:,3));
    STATMAP.mask.dat(idx) = 1;
  end
elseif strcmpi(fname,'mcluster'),
  B = 5;  cutoff = 10;
  % overwrite settings with anap.mcluster3
  if isfield(anap,'mcluster'),
    if isfield(anap.mcluster,'B') && ~isempty(anap.mcluster.B),
      B = anap.mcluster.B;
    end
    if isfield(anap.mcluster,'cutoff') && ~isempty(anap.mcluster.cutoff),
      cutoff = anap.mcluster.cutoff;
    end
  end
  STATMAP.mask.func = fname;
  STATMAP.mask.mcluster_B = B;
  STATMAP.mask.mcluster_cutoff = cutoff;
  idx = find(STATMAP.mask.dat(:) > 0);
  [ix,iy,iz] = ind2sub(size(STATMAP.p),idx);
  fprintf('%s.mcluster(n=%d,B=%d,cutoff=%d): %s-',...
          mfilename,length(ix),B,cutoff,datestr(now,'HH:MM:SS'));
  slices = sort(unique(iz));
  coords = [];
  for N = 1:length(slices),
    idx = find(iz == slices(N));
    [tmpx tmpy] = mcluster(ix(idx),iy(idx),B,cutoff);
    if isempty(tmpx),  continue;  end
    coords = cat(1,coords, [tmpx(:), tmpy(:), ones(length(tmpx),1)*slices(N)]);
  end
  fprintf('%s\n',datestr(now,'HH:MM:SS'));
  STATMAP.mask.dat(:)   = 0;
  if ~isempty(coords),
    idx = sub2ind(size(STATMAP.p),coords(:,1),coords(:,2),coords(:,3));
    STATMAP.mask.dat(idx) = 1;
  end
elseif strcmpi(fname,'spm_bwlabel'),
  CONN = 26;	% must be 6(surface), 18(edges) or 26(corners)
  MINVOXELS = CONN*0.8;
  % overwrite settings with anap.mcluster3
  if isfield(anap,'spm_bwlabel'),
    if isfield(anap.spm_bwlabel,'conn') && ~isempty(anap.spm_bwlabel.conn),
      CONN = anap.spm_bwlabel.conn;
    end
    if isfield(anap.spm_bwlabel,'minvoxels') && ~isempty(anap.spm_bwlabel.minvoxels),
      MINVOXELS = anap.spm_bwlabel.minvoxels;
    end
  end
  STATMAP.mask.func = fname;
  STATMAP.mask.spm_bwlabel_conn = CONN;
  STATMAP.mask.minvoxels = MINVOXELS;
  fprintf('%s.spm_bwlabel(CONN=%d): %s-',...
          mfilename,CONN,datestr(now,'HH:MM:SS'));
  tmpdat = double(STATMAP.mask.dat);
  [tmpdat tmpn] = spm_bwlabel(tmpdat, CONN);
  hn = histc(tmpdat(:),1:tmpn);
  ci = find(hn >= MINVOXELS);
  STATMAP.mask.dat(:) = 0;
  for iCluster = 1:length(ci),
    STATMAP.mask.dat(tmpdat(:) == ci(iCluster)) = iCluster;
  end
  STATMAP.mask.nclusters = length(hn);
  fprintf('%s\n',datestr(now,'HH:MM:SS'));
elseif strcmpi(fname,'bwlabeln'),
  CONN = 18;	% must be 6(surface), 18(edges) or 26(corners)
  MINVOXELS = CONN*0.8;
  % overwrite settings with anap.mcluster3
  if isfield(anap,'bwlabeln'),
    if isfield(anap.bwlabeln,'conn') && ~isempty(anap.bwlabeln.conn),
      CONN = anap.bwlabeln.conn;
    end
    if isfield(anap.bwlabeln,'minvoxels') && ~isempty(anap.bwlabeln.minvoxels),
      MINVOXELS = anap.bwlabeln.minvoxels;
    end
  end
  STATMAP.mask.func = fname;
  STATMAP.mask.bwlabeln_conn = CONN;
  STATMAP.mask.minvoxels = MINVOXELS;
  nvox = length(find(STATMAP.mask.dat(:)>0));
  
  tmpverbose = 0;
  if tmpverbose,
    fprintf('%s.bwlabeln(CONN=%d): nvox=%d %s-',...
            mfilename,CONN,nvox,datestr(now,'HH:MM:SS'));
  end
  tmpdat = double(STATMAP.mask.dat);
  [tmpdat tmpn] = bwlabeln(tmpdat, CONN);
  hn = histc(tmpdat(:),1:tmpn);
  ci = find(hn >= MINVOXELS);
  STATMAP.mask.dat(:) = 0;
  for iCluster = 1:length(ci),
     STATMAP.mask.dat(tmpdat(:) == ci(iCluster)) = iCluster;
  end
  STATMAP.mask.nclusters = length(hn);
  if tmpverbose,
    fprintf('%s\n',datestr(now,'HH:MM:SS'));
  end
else
  SATAMAP.mask.func = 'unknown';
end


return;


% ==================================================================
% SUBFUNCTION to generate statistical data for 'none'
function STATMAP = subGetStatNull(ONLINE,wgts,alpha1)
% ==================================================================
ANAP = getappdata(wgts.main,'ANAP');
EPIDIM = [size(ONLINE.dat,2) size(ONLINE.dat,3) size(ONLINE.dat,4)];

SelectValue = get(wgts.SelectValueCmb,'String');
SelectValue = SelectValue{get(wgts.SelectValueCmb,'Value')};

STATMAP = ONLINE.resp;
DATNAME = get(wgts.DataCmb,'String');
DATNAME = DATNAME{get(wgts.DataCmb,'Value')};
switch lower(DATNAME),
 case {'response','amplitude'}
  %STATMAP.dat = ONLINE.resp.dat;
  % do nothing
 case {'tsnr'}
  STATMAP.dat = ONLINE.snr;
 otherwise
  fprintf('\n WARNING %s: ''%s'' not supported in subGetStatNull().',mfilename,DATNAME);
end
STATMAP.p = zeros(size(STATMAP.dat),class(STATMAP.dat));


switch lower(SelectValue),
 case {'positive','pos','pos value','pos corr'}
  idx = find(ONLINE.resp.dat(:) < 0);
  STATMAP.dat(idx) = 0;
  STATMAP.p(idx) = 1;
 case {'negative','neg','neg value','neg corr'}
  idx = find(ONLINE.resp.dat(:) > 0);
  STATMAP.dat(idx) = 0;
  STATMAP.p(idx) = 1;
end

STATMAP.mask.alpha = alpha1;
STATMAP.mask.mask_black = get(wgts.MaskBlackCheck,'Value');
STATMAP.mask.mask_snr   = get(wgts.MaskBySnrCheck,'Value');
STATMAP.mask.cluster = get(wgts.ClusterCheck,'value');
STATMAP.mask.dat   = ones(EPIDIM,'int8');

if STATMAP.mask.mask_black > 0,
  tmpv = nanmean(ONLINE.ana(:))*0.5;
  STATMAP.mask.dat(ONLINE.ana(:) < tmpv) = 0;
end

if STATMAP.mask.mask_snr > 0,
  tmpv = str2double(get(wgts.MaskBySnrEdt,'String'));
  if any(tmpv),
    STATMAP.mask.dat(ONLINE.snr(:) < tmpv(1)) = 0;
  end
end


return;



% ==================================================================
% SUBFUNCTION to retrieve statistical data correlation analysis data
function STATMAP = subGetStatGlm(ONLINE,wgts,alpha1)
% ==================================================================
ANAP = getappdata(wgts.main,'ANAP');
EPIDIM = [size(ONLINE.dat,2) size(ONLINE.dat,3) size(ONLINE.dat,4)];

SelectValue = get(wgts.SelectValueCmb,'String');
SelectValue = SelectValue{get(wgts.SelectValueCmb,'Value')};

STATMAP = ONLINE.glm;
STATMAP = subAdjustPvalues(STATMAP,wgts);

DATNAME = get(wgts.DataCmb,'String');
DATNAME = DATNAME{get(wgts.DataCmb,'Value')};
switch lower(DATNAME),
 case {'t_value' 't-value'}
  % do nothing, use STATMAP.dat as it is
 case {'beta'}
  STATMAP.dat = STATMAP.beta;
 case {'response','amplitude'}
  STATMAP.dat = ONLINE.resp.dat;
 case {'tsnr'}
  STATMAP.dat = ONLINE.snr;
 otherwise
  fprintf('\n WARNING %s: ''%s'' not supported in subGetStatGlm().',mfilename,DATNAME);
end

switch lower(SelectValue),
 case {'positive','pos','pos value','pos corr'}
  idx = find(ONLINE.glm.dat(:) < 0);
  STATMAP.dat(idx) = 0;
  STATMAP.p(idx) = 1;
 case {'negative','neg','neg value','neg corr'}
  idx = find(ONLINE.glm.dat(:) > 0);
  STATMAP.dat(idx) = 0;
  STATMAP.p(idx) = 1;
end


STATMAP.mask.alpha   = alpha1;
STATMAP.mask.mask_black = get(wgts.MaskBlackCheck,'Value');
STATMAP.mask.mask_snr   = get(wgts.MaskBySnrCheck,'Value');
STATMAP.mask.cluster = get(wgts.ClusterCheck,'value');
STATMAP.mask.dat     = zeros(EPIDIM,'int8');
STATMAP.mask.dat(STATMAP.p(:) < alpha1) = 1;

if STATMAP.mask.mask_black > 0,
  tmpv = nanmean(ONLINE.ana(:))*0.5;
  STATMAP.mask.dat(ONLINE.ana(:) < tmpv) = 0;
end

if STATMAP.mask.mask_snr > 0,
  tmpv = str2double(get(wgts.MaskBySnrEdt,'String'));
  if any(tmpv),
    STATMAP.mask.dat(ONLINE.snr(:) < tmpv(1)) = 0;
  end
end

if STATMAP.mask.cluster > 0 && alpha1 < 1,
  STATMAP = subDoClusterAnalysis(STATMAP,'bwlabeln',[]);
end


return;



% ==================================================================
% SUBFUNCTION to retrieve statistical data correlation analysis data
function STATMAP = subGetStatCorr(ONLINE,wgts,alpha1)
% ==================================================================
ANAP = getappdata(wgts.main,'ANAP');
EPIDIM = [size(ONLINE.dat,2) size(ONLINE.dat,3) size(ONLINE.dat,4)];

SelectValue = get(wgts.SelectValueCmb,'String');
SelectValue = SelectValue{get(wgts.SelectValueCmb,'Value')};

STATMAP = ONLINE.corr;
STATMAP = subAdjustPvalues(STATMAP,wgts);

DATNAME = get(wgts.DataCmb,'String');
DATNAME = DATNAME{get(wgts.DataCmb,'Value')};
switch lower(DATNAME),
 case {'r_value' 'r-value'}
  % do nothing, use STATMAP.dat as it is
 case {'response','amplitude'}
  STATMAP.dat = ONLINE.resp.dat;
 case {'tsnr'}
  STATMAP.dat = ONLINE.snr;
 otherwise
  fprintf('\n WARNING %s: ''%s'' not supported in subGetStatCorr().',mfilename,DATNAME);
end

switch lower(SelectValue),
 case {'positive','pos','pos value','pos corr'}
  idx = find(ONLINE.corr.dat(:) < 0);
  STATMAP.dat(idx) = 0;
  STATMAP.p(idx) = 1;
 case {'negative','neg','neg value','neg corr'}
  idx = find(ONLINE.corr.dat(:) > 0);
  STATMAP.dat(idx) = 0;
  STATMAP.p(idx) = 1;
end


STATMAP.mask.alpha   = alpha1;
STATMAP.mask.mask_black = get(wgts.MaskBlackCheck,'Value');
STATMAP.mask.mask_snr   = get(wgts.MaskBySnrCheck,'Value');
STATMAP.mask.cluster = get(wgts.ClusterCheck,'value');
STATMAP.mask.dat     = zeros(EPIDIM,'int8');
STATMAP.mask.dat(STATMAP.p(:) < alpha1) = 1;

if STATMAP.mask.mask_black > 0,
  tmpv = nanmean(ONLINE.ana(:))*0.5;
  STATMAP.mask.dat(ONLINE.ana(:) < tmpv) = 0;
end

if STATMAP.mask.mask_snr > 0,
  tmpv = str2double(get(wgts.MaskBySnrEdt,'String'));
  if any(tmpv),
    STATMAP.mask.dat(ONLINE.snr(:) < tmpv(1)) = 0;
  end
end

if STATMAP.mask.cluster > 0 && alpha1 < 1,
  STATMAP = subDoClusterAnalysis(STATMAP,'bwlabeln',[]);
end


return;


% ==================================================================
% SUBFUNCTION to retrieve statistical data correlation analysis data
function STATMAP = subGetStatTtest(ONLINE,wgts,alpha1)
% ==================================================================
ANAP = getappdata(wgts.main,'ANAP');
EPIDIM = [size(ONLINE.dat,2) size(ONLINE.dat,3) size(ONLINE.dat,4)];

SelectValue = get(wgts.SelectValueCmb,'String');
SelectValue = SelectValue{get(wgts.SelectValueCmb,'Value')};

STATMAP = ONLINE.ttest;
STATMAP = subAdjustPvalues(STATMAP,wgts);

DATNAME = get(wgts.DataCmb,'String');
DATNAME = DATNAME{get(wgts.DataCmb,'Value')};
switch lower(DATNAME),
 case {'t_value' 't-value'}
  % do nothing, use STATMAP.dat as it is
 case {'response','amplitude'}
  STATMAP.dat = ONLINE.resp.dat;
 case {'tsnr'}
  STATMAP.dat = ONLINE.snr;
 otherwise
  fprintf('\n WARNING %s: ''%s'' not supported in subGetStatTtest().',mfilename,DATNAME);
end

switch lower(SelectValue),
 case {'positive','pos','pos value','pos corr'}
  idx = find(ONLINE.ttest.dat(:) < 0);
  STATMAP.dat(idx) = 0;
  STATMAP.p(idx) = 1;
 case {'negative','neg','neg value','neg corr'}
  idx = find(ONLINE.ttest.dat(:) > 0);
  STATMAP.dat(idx) = 0;
  STATMAP.p(idx) = 1;
end

STATMAP.mask.alpha   = alpha1;
STATMAP.mask.mask_black = get(wgts.MaskBlackCheck,'Value');
STATMAP.mask.mask_snr   = get(wgts.MaskBySnrCheck,'Value');
STATMAP.mask.cluster = get(wgts.ClusterCheck,'value');
STATMAP.mask.dat     = zeros(EPIDIM,'int8');
STATMAP.mask.dat(STATMAP.p(:) < alpha1) = 1;


if STATMAP.mask.mask_black > 0,
  tmpv = nanmean(ONLINE.ana(:))*0.5;
  STATMAP.mask.dat(ONLINE.ana(:) < tmpv) = 0;
end

if STATMAP.mask.mask_snr > 0,
  tmpv = str2double(get(wgts.MaskBySnrEdt,'String'));
  if any(tmpv),
    STATMAP.mask.dat(ONLINE.snr(:) < tmpv(1)) = 0;
  end
end

if STATMAP.mask.cluster > 0 && alpha1 < 1,
  STATMAP = subDoClusterAnalysis(STATMAP,'bwlabeln',[]);
end


return;


% ==================================================================
% SUBFUNCTION to adjust P values for multiple testing correction
function STATMAP = subAdjustPvalues(STATMAP,wgts)
% ==================================================================

TestingCorr = get(wgts.TestingCorrCmb,'String'); TestingCorr = TestingCorr{get(wgts.TestingCorrCmb,'Value')};
STATMAP.p_orig = STATMAP.p;
switch lower(TestingCorr),
 case {'bonferroni'}
  STATMAP.p = STATMAP.p_orig * numel(STATMAP.p);
 case {'bonferroni-holm' 'holm'}
  STATMAP.p = pval_adjust(STATMAP.p,'holm');
 case {'hochberg'}
  STATMAP.p = pval_adjust(STATMAP.p,'hochberg');
 case {'hommel'}
  % this tooks forever...
  STATMAP.p = pval_adjust(STATMAP.p,'hommel');
 case {'by' 'benjamini-yekutieli'}
  STATMAP.p = pval_adjust(STATMAP.p,'BY');
 case {'bh(fdr)' 'bh' 'fdr' 'benjamini-hochberg'}
  STATMAP.p = pval_adjust(STATMAP.p,'fdr');
 case {'sidak'}
  STATMAP.p = pval_adjust(STATMAP.p,'sidak');
  
end

return



% ==================================================================
% SUBFUNCTION to align base line
function IDX = subGetPreStim(SIG,TWIN)
% ==================================================================
IDX = [];
if ~isfield(SIG,'stm') || isempty(SIG.stm),  return;  end
stype = SIG.stm.stmtypes;
stimv = SIG.stm.v{1};
stimt = SIG.stm.time{1};
if isempty(stimv) || isempty(stimt),  return;  end

TIDX = (0:size(SIG.dat,1)-1)*SIG.dx;

% look for the first stimulus
for N = 1:length(stimv),
  if stimt(N) > 0 && ~any(strcmpi(stype{abs(stimv(N))+1},{'blank','none','nostim'})),
    IDX = find(TIDX >= TWIN(1)+stimt(N) & TIDX < TWIN(2)+stimt(N));
    break;
  end
end

return;



% ==================================================================
% SUBFUNCTION to plot time course
function subPlotTimeCourse(wgts)
% ==================================================================
%fprintf('subPlotTimeCourse\n');
ONLINE  = getappdata(wgts.main, 'ONLINE');
STATMAP = getappdata(wgts.main, 'STATMAP');
ROI = getappdata(wgts.main,'ROI');

TC_COLORS = getappdata(wgts.main,'TC_COLORS');
if isempty(TC_COLORS),  TC_COLORS  = 'rbgcmyk';  end
if isempty(STATMAP),  return;  end

set(wgts.main,'CurrentAxes',wgts.TimeCourseAxs);
haxs = wgts.TimeCourseAxs;

POS = get(haxs,'pos');
if get(wgts.TCHoldCheck,'Value') == 0,
  % cla;
  delete(allchild(wgts.TimeCourseAxs));
  set(haxs,'UserData',[]);
end

DATNAME = get(wgts.DataCmb,'String');
DATNAME = DATNAME{get(wgts.DataCmb,'Value')};
StatName = get(wgts.StatCmb,'String'); StatName = StatName{get(wgts.StatCmb,'Value')};
SelectValue = get(wgts.SelectValueCmb,'String');
SelectValue = SelectValue{get(wgts.SelectValueCmb,'Value')};

hDATA = get(haxs,'UserData');
if ~isempty(hDATA),  hold on;  end

tmpt = (1:size(ONLINE.dat,1));


TestingCorr = get(wgts.TestingCorrCmb,'String'); TestingCorr = TestingCorr{get(wgts.TestingCorrCmb,'Value')};
if strcmpi(TestingCorr,'none'),
  padjtxt = '';
else
  padjtxt = ['*' TestingCorr];
end


tmpidx = {};  tmptxt = {};
if isempty(ROI),
  switch lower(SelectValue),
   case {'pos','positive','neg','negative'}
    % plot either pos or neg
    tmpidx{1} = find(STATMAP.mask.dat(:) > 0);
    tmptxt{1} = sprintf('%s(P%s<%s,%s,Nvox=%d)',StatName,padjtxt,get(wgts.AlphaEdt,'string'),...
                        SelectValue,length(tmpidx{1}));
   otherwise
    % plot both pos and neg
    tmpidx{1} = find(STATMAP.mask.dat(:) > 0 & STATMAP.dat(:) > 0);
    tmptxt{1} = sprintf('%s(P%s<%s,pos,Nvox=%d)',StatName,padjtxt,get(wgts.AlphaEdt,'string'),...
                        length(tmpidx{1}));
    tmpidx{2} = find(STATMAP.mask.dat(:) > 0 & STATMAP.dat(:) < 0);
    tmptxt{2} = sprintf('%s(P%s<%s,neg,Nvox=%d)',StatName,padjtxt,get(wgts.AlphaEdt,'string'),...
                        length(tmpidx{2}));
  end
else
  tmpidx{1} = [];
  for N=1:length(ROI),
    tmpidx{1} = cat(2,tmpidx{1},ROI{N}.epiidx(:)');
  end
  tmpidx{1} = unique(tmpidx{1});
  tmptxt{1} = sprintf('ROI-Nvox=%d',length(tmpidx{1}));
end

imgsz = size(ONLINE.dat);
ONLINE.dat = reshape(ONLINE.dat,[imgsz(1) prod(imgsz(2:end))]);
for N = 1:length(tmpidx),
  if ischar(TC_COLORS),
    tmpcol = TC_COLORS(mod(length(hDATA),length(TC_COLORS))+1);
  else
    tmpcol = TC_COLORS(mod(length(hDATA),size(TC_COLORS,1))+1,:);
  end
  if isempty(tmpidx{N}),
    tcdat = [];
    hDATA(end+1) = plot(tmpt,zeros(size(tmpt)),'color',tmpcol,...
                        'tag','tcdat','UserData',tmptxt{N});
  else
    tcdat = ONLINE.dat(:,tmpidx{N});
    tmpm = nanmean(tcdat,2);
    tmps = nanstd(tcdat,[],2) / sqrt(size(tcdat,2));
    hDATA(end+1) = errorbar(tmpt,tmpm,tmps,'color',tmpcol,'tag','tcdat','UserData',tmptxt{N});
  end
  grid on;  hold on;
end
% draw model if needed.
if get(wgts.DrawModelCheck,'Value') == 0
  for N = 1:length(hDATA),
    if strcmp(get(hDATA(N),'tag'),'tcmodel')
      set(hDATA(N),'Visible','off');
      break;
    end
  end
else
  h_tcmodel = [];
  for N = 1:length(hDATA),
    if strcmp(get(hDATA(N),'tag'),'tcmodel')
      h_tcmodel = hDATA(N);
      break;
    end
  end
  ylm = get(wgts.TimeCourseAxs,'ylim');
  ydata = ONLINE.stm.mdl{1};
  ydata = ydata / max(ydata(:)) * ylm(2)*0.5;
  if ishandle(h_tcmodel)
    set(h_tcmodel,'ydata',ydata,'xdata',tmpt);
    set(h_tcmodel,'Visible','on');
  else
    h_tcmodel = plot(tmpt,ydata,'color',[0.8 0.8 0.1],'linewidth',2,...
                     'tag','tcmodel','UserData','model');
    hDATA(end+1) = h_tcmodel;
  end
end

set(haxs,'UserData',hDATA);

if get(wgts.TCHoldCheck,'Value') == 0,
  set(haxs,'xlim',[min([0 tmpt(1)]),tmpt(end)+1],'Tag','TimeCourseAxs');
  xlabel('Time in volumes');
  tmpylabel = 'Arbitral Units';
  if isfield(ONLINE,'anap') && isfield(ONLINE.anap,'xform'),
    switch lower(ONLINE.anap.xform),
     case {'tosdu','sdu'}
      tmpylabel = 'SDU';
     case {'percent','percentage'}
      tmpylabel = 'Percent Changes';
    end
  end

  TestingCorr = get(wgts.TestingCorrCmb,'String'); TestingCorr = TestingCorr{get(wgts.TestingCorrCmb,'Value')};
  if strcmpi(TestingCorr,'none'),
    padjtxt = '';
  else
    padjtxt = ['*' TestingCorr];
  end
  
  ylabel(tmpylabel);
  if isempty(ROI),
    if length(tmpidx) == 1,
      tmpstr = sprintf('Nvox=%d P%s<%s',...
                       size(tcdat,2),padjtxt,get(wgts.AlphaEdt,'String'));
    else
      tmpstr = sprintf('Nvox=%d/%d P%s<%s',...
                       length(tmpidx{1}),length(tmpidx{2}),padjtxt,get(wgts.AlphaEdt,'String'));
    end
  else
    tmpstr = sprintf('Nvox=%d ROI',size(tcdat,2));
  end
  text(0.01,0.99,strrep(tmpstr,'_','\_'),'units','normalized',...
       'FontName','Comic Sans MS','tag','Nvox',...
       'HorizontalAlignment','left','VerticalAlignment','top');
  text(0.99,0.01,'mean+-sem','units','normalized',...
       'FontName','Comic Sans MS','tag','Info',...
       'HorizontalAlignment','right','VerticalAlignment','bottom');
  set(haxs,'layer','top');
  set(haxs,...
      'ButtonDownFcn','monlineview(''Main_Callback'',gcbo,''button-timecourse'',guidata(gcbo))');
  subDrawStimIndicators(haxs,ONLINE,1);
else
  delete(findobj(haxs,'type','text','tag','Nvox'));
  %delete(findobj(haxs,'type','text'));
  legtxt = {};
  for N = 1:length(hDATA),
    legtxt{N} = get(hDATA(N),'UserData');
  end
  legend(haxs,legtxt);
  subDrawStimIndicators(haxs,ONLINE,0);
end
  
set(allchild(haxs),...
    'ButtonDownFcn','monlineview(''Main_Callback'',gcbo,''button-timecourse'',guidata(gcbo))');
set(haxs,'pos',POS,'Tag','TimeCourseAxs');

return;


% ==================================================================
% SUBFUNCTION to draw stimulus indicators
function subDrawStimIndicators(haxs,SIG,DRAW_OBJ)
% ==================================================================

if DRAW_OBJ > 0,
  % draw stimulus indicators
  ylm   = get(haxs,'ylim');  tmph = ylm(2)-ylm(1);
  drawL = [];  drawR = [];
  if isfield(SIG,'stm') && ~isempty(SIG.stm),
    stimv = SIG.stm.v{1};
    stimt = SIG.stm.tvol{1};  stimt(end+1) = sum(SIG.stm.dtvol{1});
    stimdt = SIG.stm.dtvol{1};
    for N = 1:length(stimv),
      if any(strcmpi(SIG.stm.stmtypes{stimv(N)+1},{'blank','none','nostim'})),
        continue;
      end
      if stimt(N) == stimt(N+1) || length(stimv) == 1,
        tmpw = stimdt(N);
      else
        tmpw = stimt(N+1) - stimt(N);
      end
      if ~any(drawL == stimt(N)),
        line([stimt(N), stimt(N)],ylm,'color','k','tag','stim-line');
        drawL(end+1) = stimt(N);
      end
      if isempty(drawR) || ~any(drawR(:,1) == stimt(N) & drawR(:,2) == tmpw),
        rectangle('Position',[stimt(N) ylm(1) tmpw tmph],...
                  'facecolor',[0.92 0.95 0.95],'linestyle','none',...
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
else
  ylm   = get(haxs,'ylim');  tmph = ylm(2)-ylm(1);
  if isfield(SIG,'stm') && ~isempty(SIG.stm),
    stimv = SIG.stm.v{1};
    stimt = SIG.stm.tvol{1};  stimt(end+1) = sum(SIG.stm.dtvol{1});
    stimdt = SIG.stm.dtvol{1};
    for N = 1:length(stimv),
      if any(strcmpi(SIG.stm.stmtypes{stimv(N)+1},{'blank','none','nostim'})),
        %if any(strcmpi(SIG.stm.stmpars.stmTypes{stimv(N)+1},{'blank','none','nostim'})),
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
        if pos(1) == stimt(N) && pos(3) < tmpw,
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

subSetFront(findobj(haxs,'tag','stim-line'));
subSetBack(findobj(haxs,'tag','stim-rect'));
% set indicators' handles invisible to use legend() funciton.
set(findobj(haxs,'tag','stim-line'),'handlevisibility','off');
set(findobj(haxs,'tag','stim-rect'),'handlevisibility','off');

return;


% ==================================================================
% SUBFUNCTION to zoom-in plot
function subZoomInLightBox(wgts,SIG)
% ==================================================================
StatName = get(wgts.StatCmb,'String');   StatName = StatName{get(wgts.StatCmb,'Value')};
DatName  = get(wgts.DataCmb,'String');   DatName  = DatName{get(wgts.DataCmb,'Value')};
SelectValue = get(wgts.SelectValueCmb,'String');
SelectValue = SelectValue{get(wgts.SelectValueCmb,'Value')};

%ViewMode = get(wgts.ViewModeCmb,'String');
%ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
ViewMode = 'lightbox-trans';
switch lower(ViewMode),
 case {'lightbox-cor'}
  %DX = ROITS{1}{1}.ds(1);  DY = ROITS{1}{1}.ds(3);
  %tmpxlabel = 'X (mm)';  tmpylabel = 'Z (mm)';
 case {'lightbox-sag'}
  %DX = ROITS{1}{1}.ds(2);  DY = ROITS{1}{1}.ds(3);
  %tmpxlabel = 'Y (mm)';  tmpylabel = 'Z (mm)';
 case {'lightbox-trans'}
  DX = SIG.anads(1);  DY = SIG.anads(2);
  tmpxlabel = 'X (mm)';  tmpylabel = 'Y (mm)';
end

% since 2014b, graphic handles as objects, numeric numbers...
if isobject(wgts.main),
  hfig = wgts.main.Number + 1005;
else
  hfig = wgts.main + 1005;
end
hsrc = wgts.LightboxAxs;

TestingCorr = get(wgts.TestingCorrCmb,'String'); TestingCorr = TestingCorr{get(wgts.TestingCorrCmb,'Value')};
if strcmpi(TestingCorr,'none'),
  padjtxt = '';
else
  padjtxt = ['*' TestingCorr];
end


tmpstr = sprintf('%s %d/%d',SIG.session,SIG.scanreco);
tmpstr = sprintf('%s %s(%s,P%s<%s,cluster=%d)',...
                 tmpstr,StatName,SelectValue,...
                 padjtxt,get(wgts.AlphaEdt,'String'),get(wgts.ClusterCheck,'value'));


figure(hfig);  clf;
pos = get(hfig,'pos');
pos = [pos(1)-(680-pos(3)) pos(2)-(500-pos(4)) 680 500];
% sometime, wiondow is outside the screen....why this happens??
[scrW scrH] = subGetScreenSize('pixels');
if pos(1) < -pos(3) || pos(1) > scrW,  pos(1) = 1;  end
if pos(2)+pos(4) < 0 || pos(2)+pos(4)+70 > scrH,  pos(2) = scrH-pos(4)-70;  end
set(hfig,'Name',tmpstr,'pos',pos);
haxs = copyobj(hsrc,hfig);
set(haxs,'ButtonDownFcn','');  % clear callback function
set(hfig,'Colormap',get(wgts.main,'Colormap'));
h = findobj(haxs,'type','image');
set(h,'ButtonDownFcn','');  % clear callback function
for N = 1:length(h),
  set(h(N),'xdata',get(h(N),'xdata')*DX,'ydata',get(h(N),'ydata')*DY);
  nx = length(get(h(N),'xdata'));  ny = length(get(h(N),'ydata'));
end
h = findobj(haxs,'type','text');
for N = 1:length(h),
  tmppos = get(h(N),'pos');
  tmppos(1) = tmppos(1)*DX;  tmppos(2) = tmppos(2)*DY;
  set(h(N),'pos',tmppos);
end
set(haxs,'Position',[0.08 0.1 0.75 0.75],'units','normalized');
h = findobj(haxs,'type','line');
for N =1:length(h),
  set(h(N),'xdata',get(h(N),'xdata')*DX,'ydata',get(h(N),'ydata')*DY);
end

h = findobj(haxs,'tag','ScaleBar');
if ~isempty(h),
  %if length(h) > 1,
  %  delete(h(1:end-1));
  %end
  %h = h(end);
  for N = 1:length(h),
    tmppos = get(h(N),'pos');
    tmppos([1 3]) = tmppos([1 3])*DX;
    tmppos([2 4]) = tmppos([2 4])*DY;
    set(h(N),'pos',tmppos);
  end
end


set(haxs,'xlim',get(haxs,'xlim')*DX,'ylim',get(haxs,'ylim')*DY);
set(haxs,'xtick',[0 10 20 30 40 50 60 70 80 90 100 110 120]);
set(haxs,'ytick',[0 10 20 30 40 50 60 70 80 90 100 110 120]);
xlabel(tmpxlabel);  ylabel(tmpylabel);
title(haxs,strrep(tmpstr,'_','\_'));
daspect(haxs,[1 1 1]);
pos = get(haxs,'pos');
hbar = copyobj(wgts.ColorbarAxs,hfig);
set(hbar,'pos',[0.85 pos(2) 0.045 pos(4)],'YAxisLocation','right');    
ylabel(hbar,strrep(DatName,'_',' '));
  

%clear callbacks
set(haxs,'ButtonDownFcn','');
set(allchild(haxs),'ButtonDownFcn','');


% make font size bigger
set(haxs,'FontSize',10);
set(get(haxs,'title'),'FontSize',10);
set(get(haxs,'xlabel'),'FontSize',10);
set(get(haxs,'ylabel'),'FontSize',10);
set(hbar,'FontSize',10);
set(get(hbar,'ylabel'),'FontSize',10);


return;


% ==================================================================
% SUBFUNCTION to zoom-in plot
function subZoomIn(planestr,wgts,ROITS)
% ==================================================================

RoiName  = get(wgts.RoiCmb,'String');    RoiName  = RoiName{get(wgts.RoiCmb,'Value')};
StatName = get(wgts.StatCmb,'String');   StatName = StatName{get(wgts.StatCmb,'Value')};
ModelNo  = get(wgts.ModelCmb,'String');  ModelNo  = ModelNo{get(wgts.ModelCmb,'Value')};
TrialNo  = get(wgts.TrialCmb,'String');  TrialNo  = TrialNo{get(wgts.TrialCmb,'Value')};
DatName  = get(wgts.DataCmb,'String');   DatName  = DatName{get(wgts.DataCmb,'Value')};

% since 2014b, graphic handles as objects, numeric numbers...
if isobject(wgts.main),
  hmain = wgts.main.Number;
else
  hmain = wgts.main;
end

switch lower(planestr)
 case {'coronal'}
  hfig = hmain + 1001;
  hsrc = wgts.CoronalAxs;
  DX = ROITS{1}{1}.ds(1);  DY = ROITS{1}{1}.ds(3);
  N = str2double(get(wgts.CoronalEdt,'String'));
  tmpstr = sprintf('CORONAL %03d:\n%s %d',N, ROITS{1}{1}.session,ROITS{1}{1}.scanreco(1));
  tmpxlabel = 'X (mm)';  tmpylabel = 'Z (mm)';
 case {'sagital'}
  hfig = hmain + 1002;
  hsrc = wgts.SagitalAxs;
  DX = ROITS{1}{1}.ds(2);  DY = ROITS{1}{1}.ds(3);
  N = str2double(get(wgts.SagitalEdt,'String'));
  tmpstr = sprintf('SAGITAL %03d:\n%s %d',N,ROITS{1}{1}.session,ROITS{1}{1}.scanreco(1));
  tmpxlabel = 'Y (mm)';  tmpylabel = 'Z (mm)';
 case {'transverse'}
  hfig = hmain + 1003;
  hsrc = wgts.TransverseAxs;
  DX = ROITS{1}{1}.ds(1);  DY = ROITS{1}{1}.ds(2);
  N = str2double(get(wgts.TransverseEdt,'String'));
  tmpstr = sprintf('TRANSVERSE %03d:\n%s %d',N,ROITS{1}{1}.session,ROITS{1}{1}.scanreco(1));
  tmpxlabel = 'X (mm)';  tmpylabel = 'Y (mm)';
end

TestingCorr = get(wgts.TestingCorrCmb,'String'); TestingCorr = TestingCorr{get(wgts.TestingCorrCmb,'Value')};
if strcmpi(TestingCorr,'none'),
  padjtxt = '';
else
  padjtxt = ['*' TestingCorr];
end

tmpstr = sprintf('%s P%s<%s ROI=%s Model=%s/%s',tmpstr,padjtxt,get(wgts.AlphaEdt,'String'),...
                 RoiName,StatName,ModelNo);
if length(get(wgts.TrialCmb,'String')) > 1,
  tmpstr = sprintf('%s Trial=%s',tmpstr,TrialNo);
end

figure(hfig);  clf;
set(hfig,'PaperPositionMode',	'auto');
set(hfig,'PaperOrientation', 'landscape');
set(hfig,'PaperType',			'A4');
pos = get(hfig,'pos');
pos = [pos(1)-(680-pos(3)) pos(2)-(500-pos(4)) 680 500];
% sometime, wiondow is outside the screen....why this happens??
[scrW scrH] = subGetScreenSize('pixels');
if pos(1) < -pos(3) || pos(1) > scrW,  pos(1) = 1;  end
if pos(2)+pos(4) < 0 || pos(2)+pos(4)+70 > scrH,  pos(2) = scrH-pos(4)-70;  end
set(hfig,'Name',tmpstr,'pos',pos);
haxs = copyobj(hsrc,hfig);
set(haxs,'ButtonDownFcn','');  % clear callback function
set(hfig,'Colormap',get(wgts.main,'Colormap'));
h = findobj(haxs,'type','image');
set(h,'ButtonDownFcn','');  % clear callback function
set(h,'xdata',get(h,'xdata')*DX,'ydata',get(h,'ydata')*DY);
nx = length(get(h,'xdata'));  ny = length(get(h,'ydata'));

set(haxs,'Position',[0.08 0.1 0.75 0.75],'units','normalized');
h = findobj(haxs,'type','line');
for N =1:length(h),
  set(h(N),'xdata',get(h(N),'xdata')*DX,'ydata',get(h(N),'ydata')*DY);
end
set(haxs,'xlim',get(haxs,'xlim')*DX,'ylim',get(haxs,'ylim')*DY);
set(haxs,'xtick',[0 10 20 30 40 50 60 70 80 90 100 110 120]);
set(haxs,'ytick',[0 10 20 30 40 50 60 70 80 90 100 110 120]);

h = findobj(haxs,'tag','ScaleBar');
if ~isempty(h),
  %if length(h) > 1,
  %  delete(h(1:end-1));
  %end
  %h = h(end);
  for N = 1:length(h),
    tmppos = get(h(N),'pos');
    tmppos([1 3]) = tmppos([1 3])*DX;
    tmppos([2 4]) = tmppos([2 4])*DY;
    set(h(N),'pos',tmppos);
  end
  htxt = findobj(haxs,'tag','ScaleBarTxt');
  tmppos = get(htxt(1),'pos');
  tmppos(1) = tmppos(1)*DX;  tmppos(2) = tmppos(2)*DY;
  set(htxt(1),'pos',tmppos);
end

xlabel(tmpxlabel);  ylabel(tmpylabel);
title(haxs,strrep(tmpstr,'_','\_'));
daspect(haxs,[1 1 1]);
pos = get(haxs,'pos');
hbar = copyobj(wgts.ColorbarAxs,hfig);
set(hbar,'pos',[0.85 pos(2) 0.045 pos(4)]);    
ylabel(hbar,strrep(DatName,'_',' '));

%clear callbacks
set(haxs,'ButtonDownFcn','');
set(allchild(haxs),'ButtonDownFcn','');

% make font size bigger
set(haxs,'FontSize',10);
set(get(haxs,'title'),'FontSize',10);
set(get(haxs,'xlabel'),'FontSize',10);
set(get(haxs,'ylabel'),'FontSize',10);
set(hbar,'FontSize',10);
set(get(hbar,'ylabel'),'FontSize',10);

return;


% ==================================================================
% SUBFUNCTION to zoom-in plot (TIME COURSE)
function subZoomInTC(wgts,SIG)
% ==================================================================

StatName = get(wgts.StatCmb,'String');   StatName = StatName{get(wgts.StatCmb,'Value')};
DatName  = get(wgts.DataCmb,'String');   DatName  = DatName{get(wgts.DataCmb,'Value')};
SelectValue = get(wgts.SelectValueCmb,'String');
SelectValue = SelectValue{get(wgts.SelectValueCmb,'Value')};

% since 2014b, graphic handles as objects, numeric numbers...
if isobject(wgts.main),
  hfig = wgts.main.Number + 1004;
else
  hfig = wgts.main + 1004;
end
hsrc = wgts.TimeCourseAxs;

%PlotMode = get(wgts.TimeCourseCmb,'String');
%PlotMode = PlotMode{get(wgts.TimeCourseCmb,'Value')};
PlotMode = 'voxel time course';
switch lower(PlotMode),
 case {'voxel time course'}
  tmpstr = sprintf('BOLD Time Course\n%s %d/%d',SIG.session,SIG.scanreco);
 case {'distribution (mean)'}
  tmpstr = sprintf('Distribution (mean)\n%s %d/%d',SIG.session,SIG.scanreco);
 case {'distribution (max)'}
  tmpstr = sprintf('Distribution (max)\n%s %d/%d',SIG.session,SIG.scanreco);
 otherwise
  error(' ERROR %s: unsupported plotting mode, %s',mfilename,PlotMode);
end

TestingCorr = get(wgts.TestingCorrCmb,'String'); TestingCorr = TestingCorr{get(wgts.TestingCorrCmb,'Value')};
if strcmpi(TestingCorr,'none'),
  padjtxt = '';
else
  padjtxt = ['*' TestingCorr];
end

if length(get(hsrc,'UserData')) > 1,
  % multiple plot with "hold-on"
  tmpstr = sprintf('%s %s(%s,P%s<%s,cluster=%d)',...
                   tmpstr,StatName,SelectValue,...
                   padjtxt,get(wgts.AlphaEdt,'String'),get(wgts.ClusterCheck,'value'));
else
  tmpstr = sprintf('%s %s(%s,P%s<%s,cluster=%d)',...
                   tmpstr,StatName,SelectValue,...
                   padjtxt,get(wgts.AlphaEdt,'String'),get(wgts.ClusterCheck,'value'));
end


figure(hfig);  clf;
set(hfig,'PaperPositionMode',	'auto');
set(hfig,'PaperOrientation', 'landscape');
set(hfig,'PaperType',			'A4');
pos = get(hfig,'pos');
pos = [pos(1)-(680-pos(3)) pos(2)-(500-pos(4)) 680 500];
% sometime, wiondow is outside the screen....why this happens??
[scrW scrH] = subGetScreenSize('pixels');
if pos(1) < -pos(3) || pos(1) > scrW,  pos(1) = 1;  end
if pos(2)+pos(4) < 0 || pos(2)+pos(4)+70 > scrH,  pos(2) = scrH-pos(4)-70;  end

set(hfig,'Name',tmpstr,'pos',pos);

if 0,
  haxs = axes;
  subCompCopy(hsrc,haxs);
else
  haxs = copyobj(hsrc,hfig);
  set(haxs,'pos',[0.1300    0.1100    0.7750    0.8150]);
  title(strrep(tmpstr,'_','\_'));
  % FU__ING MATLAB(R14), copyobj() makes lines in legend all black. ----------
  erb = findobj(haxs,'tag','tcdat');
  for N = 1:length(erb),
    tmph = findobj(erb(N),'type','line');
    if ~isempty(tmph),
      set(erb(N),'color',get(tmph(1),'color'));
    end
  end
  % FU__ING MATLAB(R2007b), copyobj() makes lines's IconDisplayStyle as 'off'. 
  for N = 1:length(erb),
    try
      hAnnotation = get(erb(N),'Annotation');
      hLegendEntry = get(hAnnotation','LegendInformation');
      if ishandle(hLegendEntry) && strcmpi(get(hLegendEntry,'IconDisplayStyle'),'off'),
        set(hLegendEntry,'IconDisplayStyle','on');
      end
    catch
      break;
    end
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
  legend(haxs,legtxt);
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


return;


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


% ==================================================================
% SUBFUNCTION to plot ROIs
function subDrawROIs(wgts)
% ==================================================================
ROI = getappdata(wgts.main,'ROI');

set(wgts.main,'CurrentAxes',wgts.LightboxAxs);
delete(findobj(wgts.LightboxAxs,'tag','ROI'));
for N=1:length(ROI),
  hold on;
  plot(ROI{N}.anapx,ROI{N}.anapy,'color',[0.4 1.0 0.4],'tag','ROI');
end

return


% ==================================================================
% FUNCTION to bring graphics to the front
function varargout = subSetFront(handles)
handles = handles(ishandle(handles));
if isempty(handles),  return;  end


% get the current order of handles
hParent = get(handles(1),'Parent');
hChildren = get(hParent,'Children');

% change the order
for N = length(handles):-1:1,
  tmpflags = hChildren == handles(N);
  idx  = find(tmpflags);
  if ~isempty(idx),
    idx2 = find(~tmpflags);
    hChildren = hChildren([idx idx2(:)']);
  end
end

% set the new order of handles
set(hParent,'Children',hChildren);
%drawnow;	% update to draw

return;


% ==================================================================
% FUNCTION to bring graphics to the back
function varargout = subSetBack(handles)
handles = handles(ishandle(handles));
if isempty(handles),  return;  end


% get the current order of handles
hParent = get(handles(1),'Parent');
hChildren = get(hParent,'Children');

% change the order
for N = length(handles):-1:1,
  tmpflags = hChildren == handles(N);
  idx  = find(tmpflags);
  if ~isempty(idx),
    idx2 = find(~tmpflags);
    hChildren = hChildren([idx2(:)' idx]);
  end
end

% set the new order of handles
set(hParent,'Children',hChildren);
%drawnow;	% update to draw

return;



% ==================================================================
% FUNCTION to get nrow/ncol for a single page
function [NRow, NCol] = subGetNRowNCol(nmaximages,imgdim)

if 1,
  xfov = imgdim(1);
  yfov = imgdim(2);

  nslices = min([25 nmaximages]);
  
  NRow = ceil(sqrt(nslices*xfov/yfov));
  NCol = round(nslices/NRow);

  if NCol*NRow <= nslices-1,
    if xfov > yfov,
      NRow = NRow + 1;
    else
      NCol = NCol + 1;
    end
  end
else  
  if nmaximages <= 2,
    NRow = 2;  NCol = 1;  %  2 images in a page
  elseif nmaximages <= 4,
    NRow = 2;  NCol = 2;  %  4 images in a page
  elseif nmaximages <= 9
    NRow = 3;  NCol = 3;  %  9 images in a page
  elseif nmaximages <= 12
    NRow = 4;  NCol = 3;  % 12 images in a page
  elseif nmaximages <= 16
    NRow = 4;  NCol = 4;  % 16 images in a page
  else
    NRow = 5;  NCol = 4;  % 20 images in a page
  end
end


return
