function varargout = mnview(varargin)
%MNVIEW - displays statistical map for Mn experiments.
%  MNVIEW(SESSION,GRPNAME) displays statistical map for Mn experiments.
%  MNTTEST, MNTTEST2 will create a statistical map of t-test.
%
%  MNVIEW(SESSION,GRPNAME,PERMUTE_VEC) does the same thing but permute
%  data by a given PERMUTE_VEC.
%
%  EXAMPLE :
%    >> mnview('c99sl1','mdeftinj');
%    >> mnview('h008r1','mdeftinj');
%
%  NOTES :
%    Settings can be controlled by ANAP.mnview, GRP.xxx.anap.mnview
%      ANAP.mnview.alpha       = 0.01;
%      ANAP.mnview.anascale    = [];         % as [minv maxv gamma]
%      ANAP.mnview.cluster     = 0;
%      ANAP.mnview.clusterfunc = 'bwlabeln';
%
%  NOTES :
%    This function assumes .dat as (x,y,z) as default, however data are stored
%    in slice by slice of coronal sections for Mn sessions.
%    So default "PERMUTE_VEC" = [1 3 2].
%
%  STATISTICAL MAP :
%    The program expects a structure of statistical map like
%    STATS = 
%       session: 'h008r1'
%       grpname: 'mdeftinj'
%         ExpNo: [1 2 3 4 5 6]
%       mapname: 'ttest'
%       datname: 'tstat'               <--- name of statistical value
%         tbase: [1 2]
%          tsel: [3 4 5 6]
%          tail: 'right'
%            df: 3
%           dat: [146x106x166 double]  <--- statistical value
%             p: [146x106x166 double]  <--- P value
%         flags: [1x1 struct]
%    .dat and .p should have the same dimension as a single volume.
%    .datname denotes name of statistical values stored in .dat.
%
%  VERSION :
%    0.90 06.07.05 YM   pre-release, modified from anaview().
%    0.92 08.07.05 YM   supports 'lightbox' modes.
%    0.93 14.07.05 YM   supports 'clustering' by m_cluster3().
%    0.94 17.07.05 YM   improve/bug fix 'cluster'.
%    0.95 18.07.05 YM   saves 'statistical map'.
%    0.96 09.09.05 YM   supports "spm_bwlabel", "bwlabeln" for clustering.
%    0.97 13.10.05 YM   supports the popup window by "double-click".
%    0.98 07.07.06 YM   supports several colormaps.
%    0.99 21.04.08 YM   improvement, bug fix CoronalEdt/SagitalEdt.
%    1.00 03.07.08 YM   supports 'All ROIs'.
%    1.01 04.07.08 YM   supports the popup in lightbox view..
%    1.02 16.09.10 YM   not update statistical min/max on "select-roi".
%
%  See also ANALOAD, ANAVIEW, MNTTEST, MNTTEST2, MNREGRESS, MNGLM

if nargin == 0,  help mnview; return;  end

% execute callback function then return;
if ischar(varargin{1}) & ~isempty(findstr(varargin{1},'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return;
end


% DEFAULT CONTROL SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ANAP.mnview.alpha       = 0.01;
ANAP.mnview.anascale    = [];         % as [minv maxv gamma]
ANAP.mnview.permute     = [1 3 2];
ANAP.mnview.drawroi     = 0;
ANAP.mnview.cluster     = 0;
ANAP.mnview.clusterfunc = 'bwlabeln';
ANAP.mnview.colormap    = 'autumn';
% functions for cluster detection
ANAP.mnview.mcluster3.B = 5;
ANAP.mnview.mcluster3.cutoff = round((2*(ANAP.mnview.mcluster3.B-1)+1)^3*0.3);
ANAP.mnview.spm_bwlabel.conn = 26;  % must be 6(surface), 18(edges) or 26(corners)
ANAP.mnview.spm_bwlabel.minvoxels = ANAP.mnview.spm_bwlabel.conn*0.8;
ANAP.mnview.bwlabeln.conn    = 26;  % must be 6(surface), 18(edges) or 26(corners)
ANAP.mnview.bwlabeln.minvoxels    = ANAP.mnview.bwlabeln.conn*0.8;



% mnview(Ses,grp/expno,[permute])
Ses = goto(varargin{1});
grp = getgrp(Ses,varargin{2});
if nargin > 2,  ANAP.mnview.permute = varargin{3};  end

% OVERWRITE DEFAULT SETTING BY anap in the session file
anap = getanap(Ses,grp);
tmpf = {'mcluster3','spm_bwlabel','bwlabeln'};
for N = 1:length(tmpf),
  % this is for compatibility for old session files
  if isfield(anap,tmpf{N}),
    ANAP.mnview.(tmpf{N}) = sctmerge(ANAP.mnview.(tmpf{N}),anap.(tmpf{N}));
  end
end
clear tmpf;
if isfield(anap,'mnview'), ANAP.mnview = sctmerge(ANAP.mnview,anap.mnview);  end


% load anatomy data
ANA = load(sprintf('%s.mat',grp.ana{1}),grp.ana{1});
ANA = ANA.(grp.ana{1}){grp.ana{2}};
ANA.grpname = grp.name;
ANA.ExpNo   = grp.exps;
if isempty(ANA),
  fprintf('\n%s ERROR: no way to get anatomy data.\n',mfilename);
  return;
end

% do permutation, if given
if ~isempty(ANAP.mnview.permute),
  ANA.dat = permute(ANA.dat,ANAP.mnview.permute);
end

% converts ANA.dat into RGB
anaminv  = 0;
anamaxv  = 0;
anagamma = 1.8;
if isfield(ANAP,'mnview') & isfield(ANAP.mnview,'anascale') & ~ ...
      isempty(ANAP.mnview.anascale),
  if length(ANAP.mnview.anascale) == 1,
    anamaxv = ANAP.mnview.anascale;
  else
    anaminv = ANAP.mnview.anascale(1);
    anamaxv = ANAP.mnview.anascale(2);
    if length(ANAP.mnview.anascale) > 2,
      anagamma = ANAP.mnview.anascale(3);
    end
  end
end
if anamaxv == 0,
  tmpana = double(ANA.dat);
  anamaxv = round(mean(tmpana(:))*3.5);
end
ANA.rgb = subScaleAnatomy(ANA.dat,anaminv,anamaxv,anagamma);
ANA.scale = [anaminv anamaxv anagamma];
clear tmpana anaminv anamaxv anagamma;


% load ROI
ROI = subLoadROI(Ses,grp);


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

figW = 175; figH = 55;
figX = 31;  figY = scrH-figH-5;

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
    'DefaultAxesfontweight','bold',...
    'PaperPositionMode','auto', 'PaperType','A4', 'PaperOrientation', 'landscape');



% WIDGETS TO SELECT STATISTICAL MAP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XDSP = 10; H = figH - 2.5;
StatmapTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H-0.3 30 1.5],...
    'String','Statistical Map:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','StatmapTxt',...
    'BackgroundColor',get(hMain,'Color'));
%StatmapCmb = uicontrol(...
%    'Parent',hMain,'Style','Popupmenu',...
%    'Units','char','Position',[XDSP+19 H 23 1.5],...
%    'Callback','mnview(''Main_Callback'',gcbo,''combo-statmap'',guidata(gcbo))',...
%    'String',{'none','t-test','corr','multi-regress','user'},'Tag','StatmapCmb','Value',1,...
%    'TooltipString','Select a statistical map',...
%    'FontWeight','bold');
StatmapEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+19 H 107 1.5],...
    'Callback','mnview(''Main_Callback'',gcbo,''edit-statmap'',guidata(gcbo))',...
    'String','','Tag','StatmapEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','statistical map file',...
    'FontWeight','Bold');
StatmapReadBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[XDSP+127 H 16 1.5],...
    'Callback','mnview(''Main_Callback'',gcbo,''browse-statmap'',guidata(gcbo))',...
    'Tag','StatmapReadBtn','String','Browse...',...
    'TooltipString','browse a mapfile','FontWeight','Bold');
StatmapSaveBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[XDSP+143 H 16 1.5],...
    'Callback','mnview(''Main_Callback'',gcbo,''save-statmap'',guidata(gcbo))',...
    'Tag','StatmapSaveBtn','String','Save...',...
    'TooltipString','save a mapfile','FontWeight','Bold');


% P-value %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XDSP = 10; H = figH - 4.5;
AlphaTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H-0.3 30 1.5],...
    'String','Alpha:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','PvalueTxt',...
    'BackgroundColor',get(hMain,'Color'));
AlphaEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+8 H 15 1.5],...
    'Callback','mnview(''Main_Callback'',gcbo,''edit-alpha'',guidata(gcbo))',...
    'String',sprintf('%g',ANAP.mnview.alpha),'Tag','AlphaEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','alpha for significance level',...
    'FontWeight','Bold');

% WIDGETS TO SELECT ROI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XDSP = 10; H = figH - 4.5;
RoiTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+27 H-0.3 30 1.5],...
    'String','ROI:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','RoiTxt',...
    'BackgroundColor',get(hMain,'Color'));
roinames = { 'ALL', 'All ROIs',ROI.roinames{:} };  idx = 1;
RoiCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+33 H 22 1.5],...
    'Callback','mnview(''Main_Callback'',gcbo,''select-roi'',guidata(gcbo))',...
    'String',roinames,'Value',idx(1),'Tag','RoiCmb',...
    'HorizontalAlignment','left',...
    'TooltipString','Select ROI(s) to plot',...
    'FontWeight','Bold');
clear roinames idx;
% CHECK BOX FOR "draw-roi" %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DrawRoiCheck = uicontrol(...
%     'Parent',hMain,'Style','Checkbox',...
%     'Units','char','Position',[XDSP+58 H 20 1.5],...
%     'Callback','mnview(''Main_Callback'',gcbo,''redraw'',guidata(gcbo))',...
%     'Tag','DrawRoiCheck','Value',ANAP.mnview.drawroi,...
%     'String','DrawROI','FontWeight','bold',...
%     'TooltipString','draw ROIs','BackgroundColor',get(hMain,'Color'));

% Superimpose or not %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
StatmapCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+80 H 20 1.5],...
    'Tag','StatmapCheck','Value',1,...
    'Callback','mnview(''Main_Callback'',gcbo,''redraw'',guidata(gcbo))',...
    'String','Overlay','FontWeight','bold',...
    'TooltipString','map on/off','BackgroundColor',get(hMain,'Color'));


% MASING OF BLACK REGIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MaskBlackCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+100 H 20 1.5],...
    'Tag','MaskBlackCheck','Value',0,...
    'Callback','mnview(''Main_Callback'',gcbo,''redraw'',guidata(gcbo))',...
    'String','MaskBlack','FontWeight','bold',...
    'TooltipString','Mask black regrions','BackgroundColor',get(hMain,'Color'));




% CLUSTER DETECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clusterfuncs = {'mcluster3','spm_bwlabel','bwlabeln','unknown'};
idx = find(strcmpi(clusterfuncs,ANAP.mnview.clusterfunc));
if isempty(idx),
  fprintf('WARNING %s: unknown cluster function ''%s''.\n',mfilename,ANAP.mview.clusterfunc);
  idx = 1;
end
ClusterCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+124 H 20 1.5],...
    'Tag','ClusterCheck','Value',ANAP.mnview.cluster,...
    'Callback','mnview(''Main_Callback'',gcbo,''edit-alpha'',guidata(gcbo))',...
    'String','Cluster','FontWeight','bold',...
    'TooltipString','Cluster detection','BackgroundColor',get(hMain,'Color'));
ClusterCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+138 H 21 1.5],...
    'String',clusterfuncs,'Tag','ClusterCmb','Value',idx,...
    'TooltipString','Select a function for clustering',...
    'FontWeight','bold');
clear clusterfuncs idx;



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
    'Callback','mnview(''OrthoView_Callback'',gcbo,''edit-coronal'',guidata(gcbo))',...
    'String','','Tag','CoronalEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set coronal slice',...
    'FontWeight','Bold');
CoronalSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[XDSP+XSZ*0.6 H+YSZ+0.2 XSZ*0.4 1.2],...
    'Callback','mnview(''OrthoView_Callback'',gcbo,''slider-coronal'',guidata(gcbo))',...
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
    'Callback','mnview(''OrthoView_Callback'',gcbo,''edit-sagital'',guidata(gcbo))',...
    'String','','Tag','SagitalEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set sagital slice',...
    'FontWeight','Bold');
SagitalSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[XDSP+10+XSZ*1.6 H+YSZ+0.2 XSZ*0.4 1.2],...
    'Callback','mnview(''OrthoView_Callback'',gcbo,''slider-sagital'',guidata(gcbo))',...
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
    'Callback','mnview(''OrthoView_Callback'',gcbo,''edit-transverse'',guidata(gcbo))',...
    'String','','Tag','TransverseEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set transverse slice',...
    'FontWeight','Bold');
TransverseSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[XDSP+XSZ*0.6 H+YSZ+0.2 XSZ*0.4 1.2],...
    'Callback','mnview(''OrthoView_Callback'',gcbo,''slider-transverse'',guidata(gcbo))',...
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
    'Callback','mnview(''Main_Callback'',gcbo,''view-mode'',guidata(gcbo))',...
    'String',{'orthogonal','lightbox-cor','lightbox-sag','lightbox-trans'},...
    'Tag','ViewModeCmb','Value',1,...
    'TooltipString','Select the view mode',...
    'FontWeight','bold');
ViewPageList = uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','char','Position',[XDSP+10+XSZ H+10 32 9],...
    'String',{'page1','page2','page3','page4'},...
    'Callback','mnview(''Main_Callback'',gcbo,''view-page'',guidata(gcbo))',...
    'HorizontalAlignment','left',...
    'FontName','Comic Sans MS','FontSize',9,...
    'Tag','ViewPageList','Background','white');


% INFORMATION TEXT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
InfoTxt = uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','char','Position',[XDSP+10+XSZ H+2.5 32 7],...
    'String',{'session','group','datsize','resolution'},...
    'HorizontalAlignment','left',...
    'FontName','Comic Sans MS','FontSize',9,...
    'Tag','InfoTxt','Background','white');

% ANATOMY SCALE
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+10+XSZ H-0.3 50 1.5],...
    'String','anascale: ','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'BackgroundColor',get(hMain,'color'));
AnaScaleEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+10+XSZ+12 H 20 1.5],...
    'Callback','mnview(''Main_Callback'',gcbo,''update-anascale'',guidata(gcbo))',...
    'String',deblank(sprintf('%g ',ANA.scale)),'Tag','AnaScaleEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set anatomy scaling, [min max gamma]',...
    'FontWeight','bold');
clear anascale;






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
    'Callback','mnview(''Plot_Callback'',gcbo,[],[])',...
    'String','','Tag','ColorbarMinEdt',...
    'Callback','mnview(''Main_Callback'',gcbo,''update-cmap'',guidata(gcbo))',...
    'HorizontalAlignment','center',...
    'TooltipString','set colorbar minimum',...
    'FontWeight','Bold');
ColorbarMaxEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+10+XSZ+15 H+YSZ-1.5 12 1.5],...
    'String','','Tag','ColorbarMaxEdt',...
    'Callback','mnview(''Main_Callback'',gcbo,''update-cmap'',guidata(gcbo))',...
    'HorizontalAlignment','center',...
    'TooltipString','set colorbar maximum',...
    'FontWeight','Bold');
H = 26;
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+10+XSZ H-0.3 50 1.5],...
    'String','colormap: ','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'BackgroundColor',get(hMain,'color'));
cmaps = {'autumn','winter','spring','summer','hot','cool','jet','hsv','bone','copper','pink','red','green','blue','yellow','cyan','magenta','red256','green256','blue256','yellow256','cyan256','magenta256'};
idx = find(strcmpi(cmaps,ANAP.mnview.colormap));
if isempty(idx),
  fprintf('WARNING %s: unknown colormap name ''%s''.\n',mfilename,ANAP.mview.colormap);
  idx = 1;
end
ColormapCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+10+XSZ+12 H 20 1.5],...
    'Callback','mnview(''Main_Callback'',gcbo,''update-cmap'',guidata(gcbo))',...
    'String',cmaps,'Value',idx,'Tag','ColormapCmb',...
    'TooltipString','Select colormap',...
    'FontWeight','bold');
clear cmaps idx;


% GAMMA SETTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 3;
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+10+XSZ+15, H+YSZ/2+5 30 1.25],...
    'String','Gamma: ','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'BackgroundColor',get(hMain,'color'));
GammaEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+10+XSZ+15, H+YSZ/2+3.5 10 1.5],...
    'Callback','mnview(''Main_Callback'',gcbo,''update-cmap'',guidata(gcbo))',...
    'String','1.0','Tag','GammaEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set a gamma value for image',...
    'FontWeight','bold');



% CHECK BOX FOR X,Y,Z direction %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XReverseCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+10+XSZ+15 H+YSZ/2 20 1.5],...
    'Tag','XReverseCheck','Value',0,...
    'Callback','mnview(''OrthoView_Callback'',gcbo,''dir-reverse'',guidata(gcbo))',...
    'String','X-Reverse','FontWeight','bold',...
    'TooltipString','Xdir reverse','BackgroundColor',get(hMain,'Color'));
YReverseCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+10+XSZ+15 H+YSZ/2-2.5 20 1.5],...
    'Tag','YReverseCheck','Value',0,...
    'Callback','mnview(''OrthoView_Callback'',gcbo,''dir-reverse'',guidata(gcbo))',...
    'String','Y-Reverse','FontWeight','bold',...
    'TooltipString','Ydir reverse','BackgroundColor',get(hMain,'Color'));
ZReverseCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+10+XSZ+15 H+YSZ/2-2.5*2 20 1.5],...
    'Callback','mnview(''OrthoView_Callback'',gcbo,''dir-reverse'',guidata(gcbo))',...
    'Tag','ZReverseCheck','Value',0,...
    'String','Z-Reverse','FontWeight','bold',...
    'TooltipString','Zdir reverse','BackgroundColor',get(hMain,'Color'));


% CHECK BOX FOR "cross-hair" %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CrosshairCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+10+XSZ+15 H+YSZ/2-7.5 20 1.5],...
    'Callback','mnview(''OrthoView_Callback'',gcbo,''crosshair'',guidata(gcbo))',...
    'Tag','CrosshairCheck','Value',1,...
    'String','Crosshair','FontWeight','bold',...
    'TooltipString','show a crosshair','BackgroundColor',get(hMain,'Color'));





% get widgets handles at this moment
HANDLES = findobj(hMain);


% INITIALIZE THE APPLICATION
setappdata(hMain,'ANA',ANA);
setappdata(hMain,'MASKTHRESHOLD',mean(ANA.dat(:))*0.7);
setappdata(hMain,'ANAP',ANAP);
setappdata(hMain,'ROI',ROI);
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
  ANAP = getappdata(wgts.main,'ANAP');
  MINV = -10;  MAXV = 10;
  % set min/max value for scaling
  set(wgts.ColorbarMinEdt,'string',sprintf('%.1f',MINV));
  set(wgts.ColorbarMaxEdt,'string',sprintf('%.1f',MAXV));
  setappdata(wgts.main,'MINV',MINV);
  setappdata(wgts.main,'MAXV',MAXV);
  
  % set information text
  permute_vec = ANAP.mnview.permute;
  INFTXT = {};
  INFTXT{end+1} = sprintf('%s/%s',ANA.session,ANA.grpname);
  if isfield(ANA,'ExpNo'),
    %INFTXT{end+1} = sprintf('ExpNo=[%s]',deblank(sprintf('%d ',ANA.ExpNo)));
  end
  INFTXT{end+1} = sprintf('[%s]',deblank(sprintf('%d ',size(ANA.dat))));
  if isfield(ANA,'ds'),
    INFTXT{end+1} = sprintf('[%s]mm',deblank(sprintf('%g ',ANA.ds)));
  end
  if ~isempty(permute_vec),
    INFTXT{end+1} = sprintf('permute=[%d%s]',permute_vec(1),sprintf(' %d',permute_vec(2:end)));
  end
  set(wgts.InfoTxt,'String',INFTXT);
  
  % initialize view
  if nargin < 3,
    OrthoView_Callback(hObject(1),'init');
  else
    OrthoView_Callback(hObject(1),'init',handles);
  end
  if nargin < 3,
    LightboxView_Callback(hObject(1),'init');
  else
    LightboxView_Callback(hObject(1),'init',handles);
  end
  

 case {'edit-statmap','select-roi'}
  mapfile = get(wgts.StatmapEdt,'String');
  if ~exist(mapfile,'file'),
    setappdata(wgts.main,'STATMAP',[]);
    %Main_Callback(hObject,'redraw');
    return
  end
  STATMAP = load(mapfile);
  fname = fieldnames(STATMAP);
  STATMAP = STATMAP.(fname{1});
  if iscell(STATMAP),  STATMAP = STATMAP{1};  end

  % clear edges
  STATMAP.dat(1:3,:,:) = 0;  STATMAP.p(1:3,:,:)  = 1;
  STATMAP.dat(end-2:end,:,:) = 0;  STATMAP.p(end-2:end,:,:)  = 1;
  STATMAP.dat(:,1:3,:) = 0;  STATMAP.p(:,1:3,:)  = 1;
  STATMAP.dat(:,end-2:end,:) = 0;  STATMAP.p(:,end-2:end,:)  = 1;
  STATMAP.dat(:,:,1:3) = 0;  STATMAP.p(:,:,1:3)  = 1;
  STATMAP.dat(:,:,end-2:end) = 0;  STATMAP.p(:,:,end-2:end)  = 1;
  
  ANAP = getappdata(wgts.main,'ANAP');
  permute_vec = ANAP.mnview.permute;
  if ~isempty(permute_vec),
    STATMAP.dat = permute(STATMAP.dat, permute_vec);
    STATMAP.p   = permute(STATMAP.p,   permute_vec);
    if isfield(STATMAP,'mask') & ~isempty(STATMAP.mask),
      if isfield(STATMAP.mask,'dat') & ~isempty(STATMAP.mask.dat),
        STATMAP.mask.dat = permute(STATMAP.mask.dat, permute_vec);
      end
    end
  end
  if ~isempty(strfind(STATMAP.mapname,'ttest')),
    if strcmpi(STATMAP.tail,'left'),
      STATMAP.dat(find(STATMAP.dat(:) > 0)) = 0;
      STATMAP.dat = -STATMAP.dat;
    elseif strcmpi(STATMAP.tail,'right'),
      STATMAP.dat(find(STATMAP.dat(:) < 0)) = 0;
    else
    end
  end
    
  if ~strcmpi(eventdata,'select-roi'),
    MINV = round(min(STATMAP.dat(:)));  MAXV = round(max(STATMAP.dat(:))*0.7);
    if MAXV == 0;  MAXV = 10;  end
    % set min/max value for scaling
    set(wgts.ColorbarMinEdt,'string',sprintf('%.1f',MINV));
    set(wgts.ColorbarMaxEdt,'string',sprintf('%.1f',MAXV));
    title(wgts.ColorbarAxs,STATMAP.datname,'FontWeight','bold','fontsize',10);
    setappdata(wgts.main,'MINV',MINV);
    setappdata(wgts.main,'MAXV',MAXV);
  end
  if isfield(STATMAP,'mask') & ~isempty(STATMAP.mask),
    if isfield(STATMAP.mask,'alpha'),
      set(wgts.AlphaEdt,'String',sprintf('%g',STATMAP.mask.alpha));
    end
    if isfield(STATMAP.mask,'cluster'),
      set(wgts.ClusterCheck,'Value',STATMAP.mask.cluster > 0);
      if STATMAP.mask.cluster > 0 & isfield(STATMAP.mask,'func'),
        fnames = get(wgts.ClusterCmb,'String');
        tmpv = find(strcmpi(get(wgts.ClusterCmb,'String'),STATMAP.mask.func));
        if isempty(tmpv),
          tmpv = find(strcmpi(get(wgts.ClusterCmb,'String'),'unknown'));
        end
        set(wgts.ClusterCmb,'Value',tmpv);
      end
    end
  else
    set(wgts.ClusterCheck,'Value',0);
    STATMAP.mask.dat = ones(size(STATMAP.p),'int16');
    STATMAP.mask.alpha   = -1;
    STATMAP.mask.cluster = -1;
  end

  setappdata(wgts.main,'STATMAP',STATMAP);

  Main_Callback(hObject,'init-dispmap',[]);
  if strcmpi(eventdata,'select-roi'),
    STATMAP = getappdata(wgts.main,'STATMAP');
    if isfield(STATMAP,'mask') & isfield(STATMAP.mask,'roi_midpts'),
      if ~isempty(STATMAP.mask.roi_midpts),
        xyz = round(STATMAP.mask.roi_midpts);
        set(wgts.SagitalSldr,'Value',xyz(1));
        set(wgts.CoronalSldr,'Value',xyz(2));
        set(wgts.TransverseSldr,'Value',xyz(3));
        set(wgts.SagitalEdt,'String',num2str(xyz(1)));
        set(wgts.CoronalEdt,'String',num2str(xyz(2)));
        set(wgts.TransverseEdt,'String',num2str(xyz(3)));
      end
    end
  end
  Main_Callback(hObject,'update-cmap',[]);  % 'update-cmap' invokes 'redarw'

 case {'init-dispmap'}
  STATMAP = getappdata(wgts.main, 'STATMAP');
  alpha = str2num(get(wgts.AlphaEdt,'String'));
  if isempty(STATMAP) | isempty(alpha),  return;  end

  if STATMAP.mask.alpha ~= alpha | STATMAP.mask.cluster ~= get(wgts.ClusterCheck,'Value'),
    STATMAP.mask.dat(:)  = 0;
    STATMAP.mask.alpha   = alpha;
    STATMAP.mask.cluster = get(wgts.ClusterCheck,'Value');
    idx = find(STATMAP.p(:) < alpha);
    STATMAP.mask.dat(idx) = 1;
    if STATMAP.mask.cluster > 0,
      ANAP = getappdata(wgts.main,'ANAP');
      fname = get(wgts.ClusterCmb,'String');
      fname = fname{get(wgts.ClusterCmb,'Value')};
      if strcmpi(fname,'mcluster3'),
        B = ANAP.mnview.mcluster3.B;
        cutoff = ANAP.mnview.mcluster3.cutoff;
        STATMAP.mask.func = fname;
        STATMAP.mask.mcluster3_B = B;
        STATMAP.mask.mcluster3_cutoff = cutoff;
        [ix,iy,iz] = ind2sub(size(STATMAP.p),idx);
        coords = zeros(length(ix),3);
        coords(:,1) = ix(:);  coords(:,2) = iy(:); coords(:,3) = iz(:);
        fprintf('%s.mcluster3(n=%d,B=%d,cutoff=%d): %s-',...
                mfilename,size(coords,1),B,cutoff,datestr(now,'HH:MM:SS'));
        coords = mcluster3(coords, STATMAP.mask.mcluster3_B, STATMAP.mask.mcluster3_cutoff);
        fprintf('%s\n',datestr(now,'HH:MM:SS'));
        idx = sub2ind(size(STATMAP.p),coords(:,1),coords(:,2),coords(:,3));
        STATMAP.mask.dat(:)   = 0;
        STATMAP.mask.dat(idx) = 1;
      elseif strcmpi(fname,'spm_bwlabel'),
        CONN = ANAP.mnview.spm_bwlabel.conn;
        MINVOXELS = ANAP.mnview.spm_bwlabel.minvoxels;
        STATMAP.mask.func = fname;
        STATMAP.mask.spm_bwlabel_conn = CONN;
        STATMAP.mask.minvoxels = MINVOXELS;
        fprintf('%s.spm_bwlabel(CONN=%d): %s-',...
                mfilename,CONN,datestr(now,'HH:MM:SS'));
        tmpdat = double(STATMAP.mask.dat);
        [tmpdat tmpn] = spm_bwlabel(tmpdat, CONN);
        hn = histc(tmpdat(:),[1:tmpn]);
        ci = find(hn >= MINVOXELS);
        STATMAP.mask.dat(:) = 0;
        for iCluster = 1:length(ci),
          tmpi = find(tmpdat(:) == ci(iCluster));
          STATMAP.mask.dat(tmpi) = iCluster;
        end
        STATMAP.mask.nclusters = length(hn);
        fprintf('%s\n',datestr(now,'HH:MM:SS'));
      elseif strcmpi(fname,'bwlabeln'),
        CONN = ANAP.mnview.bwlabeln.conn;
        MINVOXELS = ANAP.mnview.bwlabeln.minvoxels;
        STATMAP.mask.func = fname;
        STATMAP.mask.bwlabeln_conn = CONN;
        STATMAP.mask.minvoxels = MINVOXELS;
        fprintf('%s.bwlabeln(CONN=%d): %s-',...
                mfilename,CONN,datestr(now,'HH:MM:SS'));
        tmpdat = double(STATMAP.mask.dat);
        [tmpdat tmpn] = bwlabeln(tmpdat, CONN);
        hn = histc(tmpdat(:),[1:tmpn]);
        ci = find(hn >= MINVOXELS);
        STATMAP.mask.dat(:) = 0;
        for iCluster = 1:length(ci),
          tmpi = find(tmpdat(:) == ci(iCluster));
          STATMAP.mask.dat(tmpi) = iCluster;
        end
        STATMAP.mask.nclusters = length(hn);
        fprintf('%s\n',datestr(now,'HH:MM:SS'));
      else
        SATAMAP.mask.func = 'unknown';
      end
    end
  end

  if get(wgts.RoiCmb,'Value') > 1,
    ROI = getappdata(wgts.main,'ROI');
    roiname = get(wgts.RoiCmb,'String');
    roiname = roiname{get(wgts.RoiCmb,'Value')};
    % get the original dimension of the volume
    ANAP = getappdata(wgts.main,'ANAP');
    invorder(ANAP.mnview.permute) = 1:numel(ANAP.mnview.permute);
    imgsz = size(STATMAP.dat);
    imgsz = imgsz(invorder);
    % allocate mask for ROIs
    tmproi = zeros(imgsz,'int8');
    for N = 1:length(ROI.roi),
      if strcmpi(roiname,'all rois') || strcmpi(ROI.roi{N}.name,roiname),
        slice = ROI.roi{N}.slice;
        idx = find(ROI.roi{N}.mask(:) > 0);
        if ~isempty(idx),
          tmpdat = tmproi(:,:,slice);
          tmpdat(idx) = 1;
          tmproi(:,:,slice) = tmpdat;
        end
      end
    end
    tmproi = permute(tmproi,ANAP.mnview.permute);
    idx = find(tmproi(:) == 0);
    STATMAP.mask.dat(idx) = 0;
    %STATMAP.p(idx)   = 1;
    idx = find(tmproi(:) > 0);
    if length(idx) > 0,
      %idx = median(idx(:));
      idx = idx(round(length(idx)/2));
      [ix iy iz] = ind2sub(size(tmproi),idx);
      STATMAP.mask.roi_midpts = [ix iy iz];
    else
      STATMAP.mask.roi_midpts = [];
    end
    clear idx tmproi;
  else
    STATMAP.mask.roi_midpts = [];
  end

  setappdata(wgts.main,'STATMAP',STATMAP);
  
 case {'update-cmap'}
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
  setappdata(wgts.main,'MINV',MINV);
  setappdata(wgts.main,'MAXV',MAXV);
  
  cmap = subGetColormap(wgts);
  axes(wgts.ColorbarAxs);  colormap(cmap);
  setappdata(wgts.main,'CMAP',cmap);

  Main_Callback(hObject,'redraw',[]);

  
  
 case {'update-anascale'}
  anascale = str2num(get(wgts.AnaScaleEdt,'String'));
  if length(anascale) ~= 3,  return;  end
  ANA = getappdata(wgts.main,'ANA');
  if isempty(ANA),  return;  end
  ANA.rgb = subScaleAnatomy(ANA.dat,anascale(1),anascale(2),anascale(3));
  setappdata(wgts.main,'ANA',ANA);  clear ANA anascale;
  Main_Callback(hObject,'redraw',[]);
  
 case {'browse-statmap'}
  mapfile = get(wgts.StatmapEdt,'String');
  [mapfile, pathname] = uigetfile(...
      {'*.mat', 'Mat-files (*.mat)'}, 'Pick a statistial map file',mapfile);
  if ~isequal(mapfile,0) & ~isequal(pathname,0),
    fullpathname = fullfile(pathname,mapfile);
    set(wgts.StatmapEdt,'String',fullpathname);
    Main_Callback(hObject,'edit-statmap',[]);
  end
 case {'save-statmap'}
  STATMAP = getappdata(wgts.main,'STATMAP');
  if ~isempty(STATMAP),
    mapfile = get(wgts.StatmapEdt,'String');
    [mapfile, pathname] = uiputfile(...
        {'*.mat', 'Mat-files (*.mat)'}, 'Save a statistial map file',mapfile);
    if ~isequal(mapfile,0) & ~isequal(pathname,0),
      fullpathname = fullfile(pathname,mapfile);
      set(wgts.StatmapEdt,'String',fullpathname);
      eval('STATS = STATMAP;');
      ANAP = getappdata(wgts.main,'ANAP');
      permute_vec = ANAP.mnview.permute;
      if ~isempty(permute_vec),
        STATS.dat = ipermute(STATS.dat, permute_vec);
        STATS.p   = ipermute(STATS.p,   permute_vec);
        if isfield(STATS,'mask') & ~isempty(STATS.mask),
          if isfield(STATS.mask,'dat') & ~isempty(STATS.mask.dat),
            STATS.mask.dat = ipermute(STATS.mask.dat, permute_vec);
          end
          if isfield(STATS.mask,'roi_midpts') & ~isempty(STATS.mask.roi_midpts),
            invorder(permute_vec) = 1:numel(permute_vec);
            STATS.mask.roi_midpts = STATS.mask.roi_midpts(invorder);
          end
        end
      end
      fprintf('%s %s: saving to ''%s''...',datestr(now,'HH:MM:SS'),mfilename,mapfile);
      save(fullpathname,'STATS');
      clear STATS;
      fprintf(' done.\n');
    end
  end

 case {'edit-alpha'}
  alpha = str2num(get(wgts.AlphaEdt,'String'));
  if ~isempty(alpha),
    ViewMode = get(wgts.ViewModeCmb,'String');
    ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
    Main_Callback(hObject,'init-dispmap',[]);
    if strcmpi(ViewMode,'orthogonal'),
      OrthoView_Callback(hObject,'redraw',[]);
    else
      LightboxView_Callback(hObject,'redraw',[]);
    end
  end
  
 case {'redraw'}
  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  if strcmpi(ViewMode,'orthogonal'),
    OrthoView_Callback(hObject,'redraw',[]);
  else
    LightboxView_Callback(hObject,'redraw',[]);
  end
  
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
  
 otherwise
end
  
return;


       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to handle orthogonal view
function OrthoView_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(get(hObject,'Parent'));
ANA  = getappdata(wgts.main,'ANA');
STATMAP = getappdata(wgts.main, 'STATMAP');
MINV    = getappdata(wgts.main,'MINV');
MAXV    = getappdata(wgts.main,'MAXV');
ALPHA   = str2num(get(wgts.AlphaEdt,'String'));
CMAP    = getappdata(wgts.main,'CMAP');


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
  
  cmap = subGetColormap(wgts);
  setappdata(wgts.main,'CMAP',cmap);
  
  AXISCOLOR = [0.8 0.2 0.8];
  % now draw images
  axes(wgts.SagitalAxs);
  tmpimg = squeeze(ANA.rgb(iX,:,:,:));
  hSag = image(1:nY,1:nZ,permute(tmpimg,[2 1 3]));
  set(hSag,...
      'ButtonDownFcn','mnview(''OrthoView_Callback'',gcbo,''button-sagital'',guidata(gcbo))');
  set(wgts.SagitalAxs,'tag','SagitalAxs');	% set this again, some will reset.
  axes(wgts.CoronalAxs);
  tmimg = squeeze(ANA.rgb(:,iY,:,:));
  hCor = image(1:nX,1:nZ,permute(tmpimg,[2 1 3]));
  set(hCor,...
      'ButtonDownFcn','mnview(''OrthoView_Callback'',gcbo,''button-coronal'',guidata(gcbo))');
  set(wgts.CoronalAxs,'tag','CoronalAxs');  % set this again, some will reset.
  axes(wgts.TransverseAxs);
  tmpimg = squeeze(ANA.rgb(:,:,iZ,:));
  hTra = image(1:nX,1:nY,permute(tmpimg,[2 1 3]));
  set(hTra,...
      'ButtonDownFcn','mnview(''OrthoView_Callback'',gcbo,''button-transverse'',guidata(gcbo))');
  set(wgts.TransverseAxs,'tag','TransverseAxs');	% set this again, some will reset.
  
  % now draw a color bar
  axes(wgts.ColorbarAxs);
  ydat = [0:255]/255 * (MAXV - MINV) + MINV;
  hColorbar = imagesc(1,ydat,[0:255]'); colormap(cmap);
  set(wgts.ColorbarAxs,'Tag','ColorbarAxs');  % set this again, some will reset.
  set(wgts.ColorbarAxs,'ylim',[MINV MAXV],...
                    'YAxisLocation','right','XTickLabel',{},'XTick',[],'Ydir','normal');
  
  haxs = [wgts.SagitalAxs, wgts.CoronalAxs, wgts.TransverseAxs];
  set(haxs,'fontsize',8,'xcolor',AXISCOLOR,'ycolor',AXISCOLOR);
  GRAHANDLE.sagital    = hSag;
  GRAHANDLE.coronal    = hCor;
  GRAHANDLE.transverse = hTra;
  GRAHANDLE.colorbar   = hColorbar;
  
  % draw crosshair(s)
  axes(wgts.SagitalAxs);
  hSagV = line([iY iY],[ 1 nZ],'color','y');
  hSagH = line([ 1 nY],[iZ iZ],'color','y');
  set([hSagV hSagH],...
      'ButtonDownFcn','mnview(''OrthoView_Callback'',gcbo,''button-sagital'',guidata(gcbo))');
  axes(wgts.CoronalAxs);
  hCorV = line([iX iX],[ 1 nZ],'color','y');
  hCorH = line([ 1 nX],[iZ iZ],'color','y');
  set([hCorV hCorH],...
      'ButtonDownFcn','mnview(''OrthoView_Callback'',gcbo,''button-coronal'',guidata(gcbo))');
  axes(wgts.TransverseAxs);
  hTraV = line([iX iX],[ 1 nY],'color','y');
  hTraH = line([ 1 nX],[iY iY],'color','y');
  set([hTraV hTraH],...
      'ButtonDownFcn','mnview(''OrthoView_Callback'',gcbo,''button-transverse'',guidata(gcbo))');
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
  [xi,yi,zi] = meshgrid(iX,1:nY,1:nZ);
  hSag = surface(...
      'xdata',reshape(xi,[nY,nZ]),'ydata',reshape(yi,[nY,nZ]),'zdata',reshape(zi,[nY,nZ]),...
      'cdata',squeeze(ANA.rgb(:,iX,:,:)),...
      'facecolor','texturemap','edgecolor','none',...
      'CDataMapping','direct','linestyle','none');
  [xi,yi,zi] = meshgrid(1:nX,iY,1:nZ);
  hCor = surface(...
      'xdata',reshape(xi,[nX,nZ]),'ydata',reshape(yi,[nX,nZ]),'zdata',reshape(zi,[nX,nZ]),...
      'cdata',squeeze(ANA.rgb(iY,:,:,:)),...
      'facecolor','texturemap','edgecolor','none',...
      'CDataMapping','direct','linestyle','none');
  [xi,yi,zi] = meshgrid(1:nX,1:nY,iZ);
  hTra = surface(...
      'xdata',1:nX,'ydata',1:nY,'zdata',reshape(zi,[nY,nX]),...
      'cdata',permute(squeeze(ANA.rgb(:,:,iZ,:)),[2 1 3]),...
      'facecolor','texturemap','edgecolor','none',...
      'CDataMapping','direct','linestyle','none');

  set(gca,'Tag','TriplotAxs');
  set(gca,'fontsize',8,...
          'xlim',[1 nX],'ylim',[1 nY],'zlim',[1 nZ],'zdir','reverse');
  view(50,36);  grid on;
  xlabel('X'); ylabel('Y');  zlabel('Z');
  
  GRAHANDLE.triSagital = hSag;
  GRAHANDLE.triCoronal = hCor;
  GRAHANDLE.triTransverse = hTra;

  setappdata(wgts.main,'GRAHANDLE',GRAHANDLE);

 case {'redraw'}
  OrthoView_Callback(hObject,'slider-sagital',[]);
  OrthoView_Callback(hObject,'slider-coronal',[]);
  OrthoView_Callback(hObject,'slider-transverse',[]);
  
 case {'slider-sagital'}
  GRAHANDLE = getappdata(wgts.main,'GRAHANDLE');
  MASKTHR   = getappdata(wgts.main,'MASKTHRESHOLD');
  if ~isempty(GRAHANDLE),
    iX = round(get(wgts.SagitalSldr,'Value'));
    tmpimg = squeeze(ANA.rgb(iX,:,:,:));
    if ~isempty(STATMAP) & get(wgts.StatmapCheck,'Value'),
      tmps = squeeze(STATMAP.dat(iX,:,:));
      tmpp = squeeze(STATMAP.p(iX,:,:));
      tmpm = squeeze(STATMAP.mask.dat(iX,:,:));
      idx = find(tmpm(:) == 0);
      tmps(idx) = 0;
      tmpp(idx) = 1;
      if get(wgts.MaskBlackCheck,'Value') > 0,
        tmpana = ANA.dat(iX,:,:);
        idx = find(tmpana(:) < MASKTHR);
        tmps(idx) = 0;
        tmpp(idx) = 1;
      end
      tmpimg = subFuseImage(tmpimg,tmps,MINV,MAXV,tmpp,ALPHA,CMAP);
    end
    set(GRAHANDLE.sagital,'cdata',permute(tmpimg,[2 1 3]));
    set(GRAHANDLE.coronalV,   'xdata',[iX iX]);
    set(GRAHANDLE.transverseV,'xdata',[iX iX]);
    set(wgts.SagitalEdt,'String',sprintf('%d',iX));
    xdata = get(GRAHANDLE.triSagital,'xdata');
    xdata(:) = iX;
    set(GRAHANDLE.triSagital,'xdata',xdata,'cdata',tmpimg);
  end
  
  
 case {'slider-coronal'}
  GRAHANDLE = getappdata(wgts.main,'GRAHANDLE');
  MASKTHR   = getappdata(wgts.main,'MASKTHRESHOLD');
  if ~isempty(GRAHANDLE)
    iY = round(get(wgts.CoronalSldr,'Value'));
    tmpimg = squeeze(ANA.rgb(:,iY,:,:));
    if ~isempty(STATMAP) & get(wgts.StatmapCheck,'Value'),
      tmps = squeeze(STATMAP.dat(:,iY,:));
      tmpp = squeeze(STATMAP.p(:,iY,:));
      tmpm = squeeze(STATMAP.mask.dat(:,iY,:));
      idx = find(tmpm(:) == 0);
      tmps(idx) = 0;
      tmpp(idx) = 1;
      if get(wgts.MaskBlackCheck,'Value') > 0,
        tmpana = ANA.dat(:,iY,:);
        idx = find(tmpana(:) < MASKTHR);
        tmps(idx) = 0;
        tmpp(idx) = 1;
      end
      tmpimg = subFuseImage(tmpimg,tmps,MINV,MAXV,tmpp,ALPHA,CMAP);
    end
    set(GRAHANDLE.coronal,'cdata',permute(tmpimg,[2 1 3]));
    set(GRAHANDLE.sagitalV,   'xdata',[iY iY]);
    set(GRAHANDLE.transverseH,'ydata',[iY iY]);
    set(wgts.CoronalEdt,'String',sprintf('%d',iY));
    ydata = get(GRAHANDLE.triCoronal,'ydata');
    ydata(:) = iY;
    set(GRAHANDLE.triCoronal,'ydata',ydata,'cdata',tmpimg);
  end
  
 case {'slider-transverse'}
  GRAHANDLE = getappdata(wgts.main,'GRAHANDLE');
  MASKTHR   = getappdata(wgts.main,'MASKTHRESHOLD');
  if ~isempty(GRAHANDLE)
    iZ = round(get(wgts.TransverseSldr,'Value'));
    tmpimg = squeeze(ANA.rgb(:,:,iZ,:));
    if ~isempty(STATMAP) & get(wgts.StatmapCheck,'Value'),
      tmps = squeeze(STATMAP.dat(:,:,iZ));
      tmpp = squeeze(STATMAP.p(:,:,iZ));
      tmpm = squeeze(STATMAP.mask.dat(:,:,iZ));
      idx = find(tmpm(:) == 0);
      tmps(idx) = 0;
      tmpp(idx) = 1;
      if get(wgts.MaskBlackCheck,'Value') > 0,
        tmpana = ANA.dat(:,:,iZ);
        idx = find(tmpana(:) < MASKTHR);
        tmps(idx) = 0;
        tmpp(idx) = 1;
      end
      tmpimg = subFuseImage(tmpimg,tmps,MINV,MAXV,tmpp,ALPHA,CMAP);
    end
    tmpimg = permute(tmpimg,[2 1 3]);
    set(GRAHANDLE.transverse,'cdata',tmpimg);
    set(GRAHANDLE.sagitalH,   'ydata',[iZ iZ]);
    set(GRAHANDLE.coronalH,   'ydata',[iZ iZ]);
    set(wgts.TransverseEdt,'String',sprintf('%d',iZ));
    zdata = get(GRAHANDLE.triTransverse,'zdata');
    zdata(:) = iZ;
    set(GRAHANDLE.triTransverse,'zdata',zdata,'cdata',tmpimg);
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
    elseif iY > size(ANA.dat,2),
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
    elseif iZ > size(ANA.dat,3),
      iZ = size(ANA.dat,1);
      set(wgts.TransverseEdt,'String',sprintf('%d',iZ));
    end
    set(wgts.TransverseSldr,'Value',iZ);
    OrthoView_Callback(hObject,'slider-transverse',[]);
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
  elseif strcmpi(click,'open'),
    % double click
    subZoomIn('sagital',wgts,ANA);
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
  elseif strcmpi(click,'open'),
    % double click
    subZoomIn('coronal',wgts,ANA);
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
  elseif strcmpi(click,'open'),
    % double click
    subZoomIn('transverse',wgts,ANA);
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
STATMAP = getappdata(wgts.main, 'STATMAP');
MINV    = getappdata(wgts.main,'MINV');
MAXV    = getappdata(wgts.main,'MAXV');
ALPHA   = str2num(get(wgts.AlphaEdt,'String'));
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

NCol = 5;
NRow = 4;

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
  elseif iDimension == 2,
    nX = size(ANA.dat,1);  nY = size(ANA.dat,3);
    INFSTR = 'Cor';
  else
    nX = size(ANA.dat,1);  nY = size(ANA.dat,2);
    INFSTR = 'Trans';
  end
  X = [0:nX-1];  Y = [nY-1:-1:0];
  MASKTHR   = getappdata(wgts.main,'MASKTHRESHOLD');
  for N = 1:length(SLICES),
    iSlice = SLICES(N);
    if iDimension == 1,
      tmpimg = squeeze(ANA.rgb(iSlice,:,:,:));
      tmpana = squeeze(ANA.dat(iSlice,:,:));
    elseif iDimension == 2,
      tmpimg = squeeze(ANA.rgb(:,iSlice,:,:));
      tmpana = squeeze(ANA.dat(:,iSlice,:));
    else
      tmpimg = squeeze(ANA.rgb(:,:,iSlice,:));
      tmpana = squeeze(ANA.dat(:,:,iSlice));
    end
    if ~isempty(STATMAP) & get(wgts.StatmapCheck,'Value'),
      if iDimension == 1,
        tmps = squeeze(STATMAP.dat(iSlice,:,:));
        tmpp = squeeze(STATMAP.p(iSlice,:,:));
        tmpm = squeeze(STATMAP.mask.dat(iSlice,:,:));
      elseif iDimension == 2,
        tmps = squeeze(STATMAP.dat(:,iSlice,:));
        tmpp = squeeze(STATMAP.p(:,iSlice,:));
        tmpm = squeeze(STATMAP.mask.dat(:,iSlice,:));
      else
        tmps = squeeze(STATMAP.dat(:,:,iSlice));
        tmpp = squeeze(STATMAP.p(:,:,iSlice)); 
        tmpm = squeeze(STATMAP.mask.dat(:,:,iSlice));
      end
      idx = find(tmpm(:) == 0);
      tmps(idx) = 0;
      tmpp(idx) = 1;
      if get(wgts.MaskBlackCheck,'Value') > 0,
        idx = find(tmpana(:) < MASKTHR);
        tmps(idx) = 0;
        tmpp(idx) = 1;
      end
      tmpimg = subFuseImage(tmpimg,tmps,MINV,MAXV,tmpp,ALPHA,CMAP);
    end
    iCol = floor((N-1)/NRow)+1;
    iRow = mod((N-1),NRow)+1;
    offsX = nX*(iRow-1);
    offsY = nY*NCol - iCol*nY;
    tmpimg = permute(tmpimg,[2 1 3]);
    tmpx = X + offsX;  tmpy = Y + offsY;
    image(tmpx,tmpy,tmpimg);  hold on;
    text(min(tmpx)+1,min(tmpy)+1,sprintf('%s=%d',INFSTR,iSlice),...
         'color',[0.9 0.9 0.5],'VerticalAlignment','bottom',...
         'FontName','Comic Sans MS','FontSize',8,'Fontweight','bold');
  end
  axes(wgts.LightboxAxs);
  set(gca,'Tag','LightboxAxs','color','black');
  set(gca,'XTickLabel',{},'YTickLabel',{},'XTick',[],'YTick',[]);
  set(gca,'xlim',[0 nX*NRow],'ylim',[0 nY*NCol]);
  set(gca,'YDir','normal');

  set(allchild(gca),...
      'ButtonDownFcn','mnview(''LightboxView_Callback'',gcbo,''button-lightbox'',guidata(gcbo))');

  
 case {'button-lightbox'}
  click = get(wgts.main,'SelectionType');
  if strcmpi(click,'open'),
    % double click
    subZoomInLightBox(wgts,ANA);
  end
  
 otherwise
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




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to load ROI
function ROI = subLoadROI(Ses,grp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ROI = load('Roi.mat',grp.grproi);
if isfield(ROI,grp.grproi),
  ROI = ROI.(grp.grproi);
else
  ROI.roinames = {};
  ROI.roi   = {};
end

% save memory by freeing un-used big data.
if isfield(ROI,'ana'),  ROI.ana = [];  end
if isfield(ROI,'img'),  ROI.img = [];  end

% limit ROI to Ses.roi
if isfield(Ses,'roi') & isfield(Ses.roi,'names') & ~isempty(Ses.roi.names),
  roinames = unique(Ses.roi.names);
  found = zeros(1,length(ROI.roi));
  for N = 1:length(ROI.roi),
    found(N) = any(strcmpi(roinames,ROI.roi{N}.name));
  end
  ROI.roinames = roinames;
  ROI.roi = ROI.roi(find(found(:) > 0));
end


return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to get a color map
function cmap = subGetColormap(wgts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cmapstr = get(wgts.ColormapCmb,'String');
cmapstr = cmapstr{get(wgts.ColormapCmb,'value')};
switch lower(cmapstr),
 case {'red'}
  cmap = zeros(256,3);  cmap(:,1) = 1;
 case {'green'}
  cmap = zeros(256,3);  cmap(:,2) = 1;
 case {'blue'}
  cmap = zeros(256,3);  cmap(:,3) = 1;
 case {'yellow'}
  cmap = zeros(256,3);  cmap(:,1) = 1;  cmap(:,2) = 1;
 case {'cyan'}
  cmap = zeros(256,3);  cmap(:,2) = 1;  cmap(:,3) = 1;
 case {'magenta'}
  cmap = zeros(256,3);  cmap(:,1) = 1;  cmap(:,3) = 1;
  
 case {'red256'}
  cmap = zeros(256,3);  cmap(:,1) = (0:255)'/255;
 case {'green256'}
  cmap = zeros(256,3);  cmap(:,2) = (0:255)'/255;
 case {'blue256'}
  cmap = zeros(256,3);  cmap(:,3) = (0:255)'/255;
 case {'yellow256'}
  cmap = zeros(256,3);  cmap(:,1) = (0:255)'/255;  cmap(:,2) = (0:255)'/255;
 case {'cyan256'}
  cmap = zeros(256,3);  cmap(:,2) = (0:255)'/255;  cmap(:,3) = (0:255)'/255;
 case {'magenta256'}
  cmap = zeros(256,3);  cmap(:,1) = (0:255)'/255;  cmap(:,3) = (0:255)'/255;
  
 otherwise
  eval(sprintf('cmap = %s(256);',cmapstr));
  %cmap = autumn(256);
end
gammav = str2num(get(wgts.GammaEdt,'String'));
if ~isempty(gammav),
  cmap = cmap.^(1/gammav);
end

return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to fuse anatomy and functional images
function IMG = subFuseImage(ANARGB,STATV,MINV,MAXV,PVAL,ALPHA,CMAP)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
IMG = ANARGB;
if isempty(STATV) | isempty(PVAL) | isempty(ALPHA),  return;  end

PVAL(find(isnan(PVAL(:)))) = 1;  % to avoid error;

tmpdat = repmat(PVAL,[1 1 3]);   % for rgb
idx = find(tmpdat(:) < ALPHA);
if ~isempty(idx),
  % scale STATV from MINV to MAXV as 0 to 1
  STATV = (STATV - MINV)/(MAXV - MINV);
  STATV = round(STATV*255) + 1;  % +1 for matlab indexing
  STATV(find(STATV(:) <   0)) =   1;
  STATV(find(STATV(:) > 256)) = 256;
  % map 0-256 as RGB
  STATV = ind2rgb(STATV,CMAP);
  % replace pixels
  IMG(idx) = STATV(idx);
end

 
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION to get screen size
function [scrW scrH] = subGetScreenSize(Units)
oldUnits = get(0,'Units');
set(0,'Units',Units);
sz = get(0,'ScreenSize');
set(0,'Units',oldUnits);

scrW = sz(3);  scrH = sz(4);

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to zoom-in plot
function subZoomIn(planestr,wgts,ANA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch lower(planestr)
 case {'coronal'}
  hfig = wgts.main + 1001;
  hsrc = wgts.CoronalAxs;
  DX = ANA.ds(1);  DY = ANA.ds(3);
  N = str2num(get(wgts.CoronalEdt,'String'));
  tmpstr = sprintf('CORONAL %03d: %s %s',N, ANA.session,ANA.grpname);
  tmpxlabel = 'X (mm)';  tmpylabel = 'Z (mm)';
 case {'sagital'}
  hfig = wgts.main + 1002;
  hsrc = wgts.SagitalAxs;
  DX = ANA.ds(2);  DY = ANA.ds(3);
  N = str2num(get(wgts.SagitalEdt,'String'));
  tmpstr = sprintf('SAGITAL %03d: %s %s',N,ANA.session,ANA.grpname);
  tmpxlabel = 'Y (mm)';  tmpylabel = 'Z (mm)';
 case {'transverse'}
  hfig = wgts.main + 1003;
  hsrc = wgts.TransverseAxs;
  DX = ANA.ds(1);  DY = ANA.ds(2);
  N = str2num(get(wgts.TransverseEdt,'String'));
  tmpstr = sprintf('TRANSVERSE %03d: %s %s',N,ANA.session,ANA.grpname);
  tmpxlabel = 'X (mm)';  tmpylabel = 'Y (mm)';
end

tmpstr = sprintf('%s P<%s',tmpstr,get(wgts.AlphaEdt,'String'));

figure(hfig);  clf;
pos = get(hfig,'pos');
set(hfig,'Name',tmpstr,'pos',[pos(1)-680+pos(3) pos(2)-500+pos(4) 680 500]);
haxs = copyobj(hsrc,hfig);
set(haxs,'ButtonDownFcn','');  % clear callback function
set(hfig,'Colormap',get(wgts.main,'Colormap'));
h = findobj(haxs,'type','image');
set(h,'ButtonDownFcn','');  % clear callback function
set(h,'xdata',get(h,'xdata')*DX,'ydata',get(h,'ydata')*DY);
nx = length(get(h,'xdata'));  ny = length(get(h,'ydata'));

% to keep actual size correct, do like this...
anasz = size(ANA.dat).*ANA.ds;
maxsz = max(anasz);
%set(haxs,'Position',[0.01 0.1 nx*DX/100 ny*DY/100],'units','normalized');
set(haxs,'Position',[0.01 0.1 nx*DX/maxsz*0.85 ny*DY/maxsz*0.85],'units','normalized');
h = findobj(haxs,'type','line');
for N =1:length(h),
  set(h(N),'xdata',get(h(N),'xdata')*DX,'ydata',get(h(N),'ydata')*DY);
end
set(haxs,'xlim',get(haxs,'xlim')*DX,'ylim',get(haxs,'ylim')*DY);
set(haxs,'xtick',[0 10 20 30 40 50 60 70 80 90 100 110 120]);
set(haxs,'ytick',[0 10 20 30 40 50 60 70 80 90 100 110 120]);
xlabel(tmpxlabel);  ylabel(tmpylabel);
title(haxs,tmpstr);
daspect(haxs,[1 1 1]);
pos = get(haxs,'pos');
hbar = copyobj(wgts.ColorbarAxs,hfig);
set(hbar,'pos',[0.85 pos(2) 0.045 pos(4)]);    

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to zoom-in plot
function subZoomInLightBox(wgts,ANA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RoiName  = get(wgts.RoiCmb,'String');    RoiName  = RoiName{get(wgts.RoiCmb,'Value')};

ViewMode = get(wgts.ViewModeCmb,'String');
ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};

switch lower(ViewMode),
 case {'lightbox-cor'}
  DX = ANA.ds(1);  DY = ANA.ds(3);
  tmpstr = sprintf('CORONAL %s %s',ANA.session,ANA.grpname);
  tmpxlabel = 'X (mm)';  tmpylabel = 'Z (mm)';
 case {'lightbox-sag'}
  DX = ANA.ds(2);  DY = ANA.ds(3);
  tmpstr = sprintf('SAGITAL %s %s',ANA.session,ANA.grpname);
  tmpxlabel = 'Y (mm)';  tmpylabel = 'Z (mm)';
 case {'lightbox-trans'}
  DX = ANA.ds(1);  DY = ANA.ds(2);
  tmpstr = sprintf('TRANSVERSE %s %s',ANA.session,ANA.grpname);
  tmpxlabel = 'X (mm)';  tmpylabel = 'Y (mm)';
end


tmpstr = sprintf('%s P<%s',tmpstr,get(wgts.AlphaEdt,'String'));


hfig = wgts.main + 1005;
hsrc = wgts.LightboxAxs;


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
set(hbar,'pos',[0.85 pos(2) 0.045 pos(4)]);    
  

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
