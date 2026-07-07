function varargout = mreg2d_gui(varargin)
%MREG2D_GUI - GUI to generate transformed images matching with reference images.
%  MREG2D_GUI() generates transformed images which matches with
%  reference images. The program works like following.
%    1)  Define fiducial points with GUI.
%    2)  "TRANSFORM" button does following things.
%       mytform  = cp2tform(reg_points,ref_points,METHOD)
%       newimage = imtransform(reg_rgb, mytform,...)
%    1) and 2) should be done for all slices.
%    3)  "SAVE" button saves fiducial point information.
%
%  EXAMPLE :
%    mreg2d_gui(ReferenceFile,SourceFile);  % Files must be in ANALYZE format.
%
%  NOTE :
%    Note that imtransform() function requires coordinates in pixels
%    (not physical 'mm').
%
%  NOTE :
%
%  VERSION :
%    0.90 28.02.12 YM  pre-release
%
%  See also mana2epi cp2tform imtransform anz_read

if ~nargin,  eval(sprintf('help %s',mfilename)); return;  end


% execute callback function then return;
if nargin > 0 && ischar(varargin{1}) && ~isempty(findstr(varargin{1},'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return;
end


REFFILE = varargin{1};
SRCFILE = varargin{2};




% ====================================================================
% DISPLAY PARAMETERS FOR THE PLACEMENT OF AXIS ETC.
% ====================================================================
[scrW scrH] = getScreenSize('char');
figW = 250.0;   % 288x60.3 char. for 1440x900 pixels.
figH =  50.0;
figX =   1.0;
figY = scrH-figH-6;


hMain = figure(...
'Name','MREG2D_GUI: Graphical User Interface for 2D registration',...
    'NumberTitle','off', 'toolbar','figure',...
    'Tag','main', 'units','char', 'pos',[figX figY figW figH],...
    'HandleVisibility','on', 'Resize','on',...
    'DoubleBuffer','on', 'BackingStore','on', 'Visible','on',...
    'DefaultAxesFontSize',10,...
    'PaperPositionMode','auto', 'PaperType','A4', 'PaperOrientation', 'landscape');


% ====================================================================
% ====================================================================
H = figH - 2;
IMGXOFS     = 3;
BKGCOL = get(hMain,'Color');

uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS-9 H-0.2 20 1.5],...
    'String','Reference: ','FontWeight','bold','foregroundcolor',[0.6 0 0],...
    'HorizontalAlignment','right','fontsize',9,...
    'BackgroundColor',BKGCOL);
RefFileEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFS+12 H 90 1.5],...
    'String',REFFILE,'Tag','RefFileEdt',...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''reset-ref-redraw'',[])',...
    'HorizontalAlignment','left',...
    'TooltipString','',...
    'FontWeight','bold');


uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS-9 H-2.2 20 1.5],...
    'String','Source: ','FontWeight','bold','foregroundcolor',[0 0.5 0],...
    'HorizontalAlignment','right','fontsize',9,...
    'BackgroundColor',BKGCOL);
SrcFileEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFS+12 H-2 90 1.5],...
    'String',SRCFILE,'Tag','SrcFileEdt',...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''reset-src-redraw'',[])',...
    'HorizontalAlignment','left',...
    'TooltipString','',...
    'FontWeight','bold');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+112 H-2.2 20 1.5],...
    'String','Rotate XYZ (deg) : ','FontWeight','bold','foregroundcolor',[0 0.5 0],...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
SrcRotateEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFS+135 H-2 25 1.5],...
    'String','0   0   0','Tag','SrcRotateEdt',...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''reslice-src-redraw'',[])',...
    'HorizontalAlignment','center',...
    'TooltipString','rotate XYZ',...
    'FontWeight','bold');
V_PERMUTE = '';
V_FLIPDIM = '';
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+105 H-4.2 15 1.5],...
    'String','Permute: ','FontWeight','bold','foregroundcolor',[0 0.5 0],...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
SrcPermuteEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFS+117 H-4 15 1.5],...
    'String',V_PERMUTE,'Tag','SrcPermuteEdt',...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''load-src-redraw'',[])',...
    'HorizontalAlignment','center',...
    'TooltipString','permute',...
    'FontWeight','bold');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+135 H-4.2 15 1.5],...
    'String','Flipdim: ','FontWeight','bold','foregroundcolor',[0 0.5 0],...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
SrcFlipdimEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFS+145 H-4 15 1.5],...
    'String',V_FLIPDIM,'Tag','SrcFlipdimEdt',...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''load-src-redraw'',[])',...
    'HorizontalAlignment','center',...
    'TooltipString','flipdim',...
    'FontWeight','bold');
clear fp fr fe V_PERMUTE V_FLIPDIM;
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS-9 H-4.2 20 1.5],...
    'String','Resliced: ','FontWeight','bold','foregroundcolor',[0 0.5 0],...
    'HorizontalAlignment','right','fontsize',9,...
    'BackgroundColor',BKGCOL);
SrcReslicedEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFS+12 H-4 90 1.5],...
    'String','','Tag','SrcReslicedEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','',...
    'FontWeight','bold');



H = H - 2;



H = H - 4;
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS H-0.3 20 1.5],...
    'String','Fiducial Point: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
PointActionCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMGXOFS+18 H 32 1.5],...
    'String',{'No Action' 'Append' 'Replace' 'Remove END' 'Remove X' 'Remove ALL' 'CLEAR ALL SLICES'},...
    'Value',1,...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''point-action'',[])',...
    'TooltipString','Select action',...
    'Tag','PointActionCmb','FontWeight','Bold');
PointCursorCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMGXOFS+52 H 25 1.5],...
    'String',{'crosshair','black dot','white dot','circle','cross','fluer','fullcross','ibeam','arrow'},...
    'TooltipString','pointer',...
    'Tag','PointCursorCmb','Value',4,'FontWeight','Bold');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+6.5 H-2.3 20 1.5],...
    'String','marker: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
MarkerCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMGXOFS+18 H-2 13 1.5],...
    'String',{'+','o','*' '.' 'x' 'square' 'diamond' '^' 'v' '>' '<' 'pentagram' 'hexagram'},...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''marker-type'',[])',...
    'TooltipString','maker type',...
    'Tag','MarkerCmb','Value',1,'FontWeight','Bold');
MarkerColorEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFS+32 H-2 18 1.5],...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''marker-color'',guidata(gcbo))',...
    'String','1.0  1.0  0.0','Tag','MarkerColorEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set marker color',...
    'FontWeight','bold');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+52 H-2.3 20 1.5],...
    'String','label: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
TextColorEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFS+59 H-2 18 1.5],...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''text-color'',guidata(gcbo))',...
    'String','0.3  0.3  1.0','Tag','TextColorEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set text color',...
    'FontWeight','bold');



uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+92 H-2.3 15 1.5],...
    'String','Trans. Type: ','FontWeight','bold',...
    'HorizontalAlignment','right','fontsize',9,...
    'BackgroundColor',BKGCOL);
TransformCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMGXOFS+108 H-2 25 1.5],...
    'String',{'linear conformal','affine','projective','polynomial','piecewise linear','lwm'},...
    'Value',6,...
    'TooltipString','Transformation Type, see/help cp2tform.m',...
    'Tag','TransformCmb','FontWeight','Bold');
uicontrol(...
    'Parent',hMain,'Style','pushbutton',...
    'Units','char','Position',[IMGXOFS+135 H-2 25 1.5],...
    'String','TRANSFORM','FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left',...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''transform'',[])');

uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+176 H-2.3 15 1.5],...
    'String','Trans. Data: ','FontWeight','bold',...
    'HorizontalAlignment','right','fontsize',9,...
    'BackgroundColor',BKGCOL);
uicontrol(...
    'Parent',hMain,'Style','pushbutton',...
    'Units','char','Position',[IMGXOFS+192 H-2 25 1.5],...
    'String','LOAD','FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left',...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''load-redraw'',[])');
uicontrol(...
    'Parent',hMain,'Style','pushbutton',...
    'Units','char','Position',[IMGXOFS+218 H-2 25 1.5],...
    'String','SAVE','FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left',...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''save-src'',[])');
ForceTransformCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[IMGXOFS+205 H 40 1.5],...
    'Tag','ForceTransformCheck','Value',0,...
    'String','Force Transformation on SAVE','FontWeight','bold',...
    'TooltipString','Foce transformation before saving','BackgroundColor',get(hMain,'Color'));





% ====================================================================
% AXES
% ====================================================================
IMGYOFS = figH * 0.15;
IMGW = figW/3;
IMGH = 30;

H = IMGYOFS + IMGH + 0.2;
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS H-0.1 20 1.5],...
    'String','Reference : ','FontWeight','bold','foregroundcolor',[0.6 0 0],...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
RefSliceEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFS+37, H 7 1.5],...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''ref-slice'',guidata(gcbo))',...
    'String','1','Tag','RefSliceEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','anatomy slice',...
    'FontWeight','bold');
RefSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[IMGXOFS+45 H IMGW*0.38 1.2],...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''ref-slider'',guidata(gcbo))',...
    'Tag','RefSldr','SliderStep',[1 4],'Value',1,'Min',1,'Max',2,...
    'TooltipString','anatomy slice');
RefAxs = axes(...
    'Parent',hMain,'Tag','RefAxs',...
    'Units','char','Color','k','layer','top',...
    'Position',[IMGXOFS IMGYOFS IMGW*0.92 IMGH],...
    'xticklabel','','yticklabel','','xtick',[],'ytick',[]);
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS IMGYOFS-2.7 35 1.5],...
    'String','Scale [min max] :','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
RefScaleEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFS+22, IMGYOFS-2.5 25 1.5],...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''redraw-ref'',guidata(gcbo))',...
    'String','','Tag','RefScaleEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','anatomy scale [min max]',...
    'FontWeight','bold');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+55 IMGYOFS-2.7 35 1.5],...
    'String','Gamma :','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
RefGammaEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFS+67, IMGYOFS-2.5 10 1.5],...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''redraw-ref'',guidata(gcbo))',...
    'String','1.5','Tag','RefGammaEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','anatomy gamma',...
    'FontWeight','bold');

uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+IMGW IMGYOFS-2.7 35 1.5],...
    'String','Scale [min max] :','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
SrcScaleEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFS+IMGW+22, IMGYOFS-2.5 25 1.5],...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''redraw-src'',guidata(gcbo))',...
    'String','','Tag','SrcScaleEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','anatomy scale [min max]',...
    'FontWeight','bold');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+IMGW+55 IMGYOFS-2.7 35 1.5],...
    'String','Gamma :','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
SrcGammaEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFS+IMGW+67, IMGYOFS-2.5 10 1.5],...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''redraw-src'',guidata(gcbo))',...
    'String','1.5','Tag','SrcGammaEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','anatomy gamma',...
    'FontWeight','bold');

uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+IMGW H-0.1 20 1.5],...
    'String','Source : ','FontWeight','bold','foregroundcolor',[0 0.5 0],...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
SrcAxs = axes(...
    'Parent',hMain,'Tag','SrcAxs',...
    'Units','char','Color','k','layer','top',...
    'Position',[IMGXOFS+IMGW IMGYOFS IMGW*0.92 IMGH],...
    'xticklabel','','yticklabel','','xtick',[],'ytick',[]);
YorkCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[IMGXOFS+IMGW+20 H 40 1.5],...
    'Tag','YorkCheck','Value',1,...
    'String','York','FontWeight','bold',...
    'TooltipString','yoked slice','BackgroundColor',get(hMain,'Color'));
SrcSliceEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFS+IMGW+34 H 10 1.5],...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''src-slice'',guidata(gcbo))',...
    'String','1','Tag','SrcSliceEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','reg slice',...
    'FontWeight','bold');
SrcSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[IMGXOFS+IMGW+45 H IMGW*0.38 1.2],...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''src-slider'',guidata(gcbo))',...
    'Tag','SrcSldr','SliderStep',[1 4],'Value',1,'Min',1,'Max',2,...
    'TooltipString','reg slice');



ImageOffCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[IMGXOFS+IMGW IMGYOFS-4.7 25 1.5],...
    'Tag','ImageOffCheck','Value',0,...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''image-off'',[])',...
    'String','Image Off','FontWeight','bold',...
    'TooltipString','hide image','BackgroundColor',get(hMain,'Color'));
GridOnCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[IMGXOFS+IMGW+20 IMGYOFS-4.7 25 1.5],...
    'Tag','GridOnCheck','Value',0,...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''grid-onoff'',[])',...
    'String','Grid On','FontWeight','bold',...
    'TooltipString','Grid On','BackgroundColor',get(hMain,'Color'));
EdgeOnCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[IMGXOFS+IMGW+35 IMGYOFS-4.7 25 1.5],...
    'Tag','EdgeOnCheck','Value',0,...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''src-slice'',[])',...
    'String','Edge On','FontWeight','bold',...
    'TooltipString','Edge On','BackgroundColor',get(hMain,'Color'));
WhiteBkgCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[IMGXOFS+IMGW+62 IMGYOFS-4.7 25 1.5],...
    'Tag','WhiteBkgCheck','Value',0,...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''update-bkg'',[])',...
    'String','White BKG','FontWeight','bold',...
    'TooltipString','White BKG','BackgroundColor',get(hMain,'Color'));


uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+IMGW+IMGW H-0.1 30 1.5],...
    'String','Reference+Register : ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
OverlayUpdateCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[IMGXOFS+IMGW+IMGW+57 H 25 1.5],...
    'Tag','OverlayUpdateCheck','Value',1,...
    'String','AutoUpdate','FontWeight','bold',...
    'TooltipString','Update by Ref/Src','BackgroundColor',get(hMain,'Color'));
OverlayAxs = axes(...
    'Parent',hMain,'Tag','OverlayAxs',...
    'Units','char','Color','k','layer','top',...
    'Position',[IMGXOFS+IMGW+IMGW IMGYOFS IMGW*0.92 IMGH],...
    'xticklabel','','yticklabel','','xtick',[],'ytick',[]);
OverlayCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[IMGXOFS+IMGW+IMGW IMGYOFS-2.7 25 1.5],...
    'Tag','OverlayCheck','Value',1,...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''redraw-overlay'',[])',...
    'String','Overlay','FontWeight','bold',...
    'TooltipString','Overlay the registration','BackgroundColor',get(hMain,'Color'));
ReferenceCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[IMGXOFS+IMGW+IMGW+15 IMGYOFS-2.7 25 1.5],...
    'Tag','ReferenceCheck','Value',1,...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''redraw-overlay'',[])',...
    'String','Reference','FontWeight','bold',...
    'TooltipString','show the reference','BackgroundColor',get(hMain,'Color'));
TransformedCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[IMGXOFS+IMGW+IMGW+33 IMGYOFS-2.7 25 1.5],...
    'Tag','TransformedCheck','Value',1,...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''redraw-overlay'',[])',...
    'String','Transformed','FontWeight','bold',...
    'TooltipString','Overlay the registration','BackgroundColor',get(hMain,'Color'));
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+IMGW+IMGW IMGYOFS-4.7 35 1.5],...
    'String','XLim :','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
OverlayXlimEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFS+IMGW+IMGW+8, IMGYOFS-4.5 20 1.5],...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''redraw-overlay'',guidata(gcbo))',...
    'String','','Tag','OverlayXlimEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','X limit [min max]',...
    'FontWeight','bold');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+IMGW+IMGW+30 IMGYOFS-4.7 35 1.5],...
    'String','YLim :','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
OvelayYlimEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFS+IMGW+IMGW+38, IMGYOFS-4.5 20 1.5],...
    'Callback','mreg2d_gui(''Main_Callback'',gcbo,''redraw-overlay'',guidata(gcbo))',...
    'String','','Tag','OverlayYlimEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','Y limit [min max]',...
    'FontWeight','bold');




InfoTxt = uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','char','Position',[IMGXOFS+IMGW+IMGW IMGYOFS+IMGH+7 IMGW*0.92 5],...
    'String',{'file','datsize','resolution'},...
    'HorizontalAlignment','left',...
    'FontName','Comic Sans MS','FontSize',9,...
    'Tag','InfoTxt','Background','white');

StatusFrame = axes(...
    'Parent',hMain,'Units','char','color',get(hMain,'color'),'xtick',[],...
    'ytick',[],'Position',[IMGXOFS 0.35 IMGW+IMGW-7 1.8],...
    'Box','on','linewidth',1,'xcolor',[0.5 0 0.5],'ycolor',[0.5 0 0.5],...
    'color',BKGCOL);
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+1.5 0.35 11 1.5],...
    'String','Status : ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
StatusField = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+12 0.65 145 1.2],...
    'String','ready','FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left','Tag','StatusField','BackgroundColor',BKGCOL);





wgts = guihandles(hMain);



mreg2d_gui('Main_Callback',hMain,'init');
set(hMain,'visible','on');

if nargout,  varargout{1} = hMain;  end


return



% ====================================================================
% MAIN CALLBACK
function Main_Callback(hObject,eventdata,handles)
% ====================================================================

wgts = guihandles(hObject);

switch lower(eventdata),
 case {'init'}
  % CHANGE 'UNITS' OF ALL WIDGETS FOR SUCCESSFUL PRINT
  % the following is as dirty as it can be... but it allows
  % rescaling and also correct printing... leave it so, until you
  % find a better solution!
  handles = findobj(wgts.main);
  for N=1:length(handles),
    try
      set(handles(N),'units','normalized');
    catch
    end
  end
  % DUE TO BUG OF MATLAB 7.5, 'units' for figure must be 'pixels'
  % otherwise roipoly() will crash.
  set(wgts.main,'units','pixels');
  
  if any(strcmpi(spm('ver'),{'SPM2','SPM5'})),
    spm_defaults;
  else
    spm_get_defaults;
  end
  % re-evaluate session/group info.

  Main_Callback(wgts.main,'load-redraw');


 case {'load-redraw'}
  Main_Callback(wgts.main,'load-ref');
  Main_Callback(wgts.main,'load-src');
  Main_Callback(wgts.main,'redraw');

 case {'load-ref'}
  % loading the reference-volume
  StatusTxt = 'Loading Reference...';
  set(wgts.StatusField,'String',StatusTxt);  drawnow;
  REF = sub_anzload(wgts,'ref');
  set(wgts.StatusField,'String',sprintf('%s done.',StatusTxt));  drawnow;
  setappdata(wgts.main,'REF',REF);
    
  
  % set slider edit value
  N = size(REF.dat,3);
  tmpv = str2double(get(wgts.RefSliceEdt,'String'));
  if any(tmpv) && tmpv < 1 && tmpv > N,
    tmpv = 1;
    set(wgts.RefSliceEdt,   'String', sprintf('%d',tmpv));
  end
  % set slider, add +0.01 to prevent error.
  set(wgts.RefSldr,     'Min',1,'Max',N+0.01,'Value',tmpv);
  % set slider step, it is normalized from 0 to 1, not min/max
  set(wgts.RefSldr,     'SliderStep',[1, 2]/max(1,N-1));
  
  tmptxt = {};
  tmptxt{1} = sprintf('REF : size[%s] vox[%s]mm',...
                      deblank(sprintf('%d ',size(REF.dat))),...
                      deblank(sprintf('%g ',REF.ds)));
  set(wgts.InfoTxt,'String',tmptxt);
  
  % ana scale
  minv = 0;
  maxv = round(max(REF.dat(:))*0.8/100)*100;
  set(wgts.RefScaleEdt, 'String', sprintf('%g  %g',minv,maxv));

  % load transformed images
  RefFile = get(wgts.RefFileEdt,'String');
  SrcFile = get(wgts.SrcFileEdt,'String');
  [fp fref] = fileparts(RefFile);
  [fp fsrc] = fileparts(SrcFile);
  tname = sprintf('%s_ref(%s)_mreg2d_tform.mat',fsrc,fref);
  tfile = fullfile(fp,tname);
  vname = 'TFORM';
  T_IMAGE = [];
  if exist(tfile,'file'),
    StatusTxt = sprintf('%s mreg2d_tform...',StatusTxt);
    set(wgts.StatusField,'String',StatusTxt');  drawnow;
    T_IMAGE = load(tfile,vname);
    if isfield(T_IMAGE,vname),
      T_IMAGE = T_IMAGE.(vname);
    else
      T_IMAGE = [];
    end
    StatusTxt = sprintf('%s done.',StatusTxt);
    set(wgts.StatusField,'String',StatusTxt');  drawnow;
  end
  if isempty(T_IMAGE),
    T_IMAGE.date      = datestr(now);
    T_IMAGE.points    = [];
    T_IMAGE.regimg    = [];
  end
  if ~isempty(T_IMAGE.points) && isfield(T_IMAGE.points,'regx'),
    clear tmppoints;
    for N = 1:length(T_IMAGE.points)
      tmppoints(N).refx  = T_IMAGE.points(N).refx;
      tmppoints(N).refy  = T_IMAGE.points(N).refy;
      tmppoints(N).srcx  = T_IMAGE.points(N).regx;
      tmppoints(N).srcy  = T_IMAGE.points(N).regy;
      tmppoints(N).slice = T_IMAGE.points(N).slice;
    end
    T_IMAGE.points = tmppoints;
    clear tmppoints;
  end
  

  setappdata(wgts.main,'T_IMAGE',T_IMAGE);

 case {'load-src'}
  % loading the volume for registration
  StatusTxt = 'Loading Source...';
  set(wgts.StatusField,'String',StatusTxt);  drawnow;
  SRC = sub_anzload(wgts,'src');
  set(wgts.StatusField,'String',sprintf('%s done.',StatusTxt));  drawnow;
  setappdata(wgts.main,'SRC',SRC);
    
  
  % set slider edit value
  N = size(SRC.dat,3);
  tmpv = str2double(get(wgts.SrcSliceEdt,'String'));
  if any(tmpv) && tmpv < 1 && tmpv > N,
    tmpv = 1;
    set(wgts.SrcSliceEdt,   'String', sprintf('%d',tmpv));
  end
  % set slider, add +0.01 to prevent error.
  set(wgts.SrcSldr,     'Min',1,'Max',N+0.01,'Value',tmpv);
  % set slider step, it is normalized from 0 to 1, not min/max
  set(wgts.SrcSldr,     'SliderStep',[1, 2]/max(1,N-1));
  
  %tmptxt = {};
  tmptxt = get(wgts.InfoTxt,'String');
  tmptxt{2} = sprintf('SRC : size[%s] vox[%s]mm',...
                      deblank(sprintf('%d ',size(SRC.dat))),...
                      deblank(sprintf('%g ',SRC.ds)));
  set(wgts.InfoTxt,'String',tmptxt);
  
  % ana scale
  minv = 0;
  maxv = round(max(SRC.dat(:))*0.8/100)*100;
  set(wgts.SrcScaleEdt, 'String', sprintf('%g  %g',minv,maxv));

  T_IMAGE = getappdata(wgts.main,'T_IMAGE');
  if ~isempty(T_IMAGE) && ~isempty(SRC),
    iSlice = round(str2double(get(wgts.RefSliceEdt,'String')));
    if isfield(T_IMAGE,'points') && length(T_IMAGE.points) >= iSlice
      tmpslice = T_IMAGE.points(iSlice).slice;
      if any(tmpslice),
        set(wgts.SrcSliceEdt, 'String', sprintf('%d',tmpslice));
        set(wgts.SrcSldr,      'Value', tmpslice);
      end
    end
  end
  
 
 case {'save-src'}
  SRC = getappdata(wgts.main,'SRC');
  T_IMAGE = getappdata(wgts.main,'T_IMAGE');
  if isempty(T_IMAGE),  return;  end
  T_IMAGE.date = datestr(now);
  if get(wgts.ForceTransformCheck,'Value') > 0,
    REF = getappdata(wgts.main,'REF');
    for N = 1:size(SRC.dat,3),
      if length(T_IMAGE.points) < N || isempty(T_IMAGE.points(N).refx),
        tmptxt = sprintf('SLICE(%d) ERROR : CANT''T TRANSFORM, NO FIDUCIAL POINTS.',N);
        set(wgts.StatusField,'String',tmptxt);
        return
      end
      if length(T_IMAGE.regimg) >= N && isfield(T_IMAGE.regimg(N),'tform') && isfield(T_IMAGE.regimg(N).tform,'method'),
        tmpmethod = T_IMAGE.regimg(N).tform.method;
      else
        tmpmethod = '';
      end
      tmpform = sub_transform(wgts,SRC,T_IMAGE,N,'verbose',1,'method',tmpmethod);
      if isempty(tmpform.img),  return;  end
      if isempty(T_IMAGE.regimg)
        T_IMAGE = rmfield(T_IMAGE,'regimg');  % avoid error...
      end
      T_IMAGE.regimg(N) = tmpform;
    end
  else
    % apply "transform" if needed.
    for N = 1:length(T_IMAGE.points),
      PINFO = T_IMAGE.points(N);
      if isempty(PINFO.refx),  continue;  end
      DO_TRANSFORM = 1;
      if length(T_IMAGE.regimg) >= N,
        tmptform = T_IMAGE.regimg(N);
        if isfield(tmptform,'tform') && isfield(tmptform.tform,'input_points'),
          input_points = [PINFO.srcx(:) PINFO.srcy(:)];
          if isequal(input_points,tmptform.tform.input_points),
            continue;
          end
        end
      end
      if DO_TRANSFORM == 0,  continue;  end
      if length(T_IMAGE.regimg) >= N && isfield(T_IMAGE.regimg(N),'tform') && isfield(T_IMAGE.regimg(N).tform,'method'),
        tmpmethod = T_IMAGE.regimg(N).tform.method;
      else
        tmpmethod = '';
      end
      tmptform = sub_transform(wgts,SRC,T_IMAGE,N,'verbose',1,'method',tmpmethod);
      if isempty(tmptform.img),  continue;  end
      if isempty(T_IMAGE.regimg)
        T_IMAGE = rmfield(T_IMAGE,'regimg');  % avoid error...
      end
      T_IMAGE.regimg(N) = tmptform;
    end
  end

  setappdata(wgts.main,'T_IMAGE',T_IMAGE);
  RefFile = get(wgts.RefFileEdt,'String');
  SrcFile = get(wgts.SrcFileEdt,'String');
  [fp fref] = fileparts(RefFile);
  [fp fsrc] = fileparts(SrcFile);
  tname = sprintf('%s_ref(%s)_mreg2d_tform.mat',fsrc,fref);
  tfile = fullfile(fp,tname);
  vname = 'TFORM';
  eval([vname ' = T_IMAGE;']);
  set(wgts.StatusField,'String',sprintf(' Saving ''%s'' to ''%s''...',vname,tname));
  drawnow;
  if exist(tfile,'file'),
    copyfile(tfile,sprintf('%s.bak',tfile),'f');
    save(tfile,vname,'-append');
  else
    save(tfile,vname);
  end
  set(wgts.StatusField,'String',sprintf('%s done.',get(wgts.StatusField,'String')));


  % make matching volume
  sub_save_matched_volume(wgts);

  
 case {'reslice-src-redraw'};
  Rxyz = str2num(get(wgts.MriRotateEdt,'String'));
  if length(Rxyz) == 3 && any(Rxyz),
    IMGFILE = get(wgts.RefFileEdt,'String');
    set(wgts.StatusField,'String',sprintf(' SPM_RESLICE(Rxyz=[%g %g %g])...',Rxyz)); drawnow;
    IMGFILE = sub_spm_reslice(IMGFILE,Rxyz);
    set(wgts.StatusField,'String',sprintf('%s done.',get(wgts.StatusField,'String'))); drawnow;
    [fp fr fe] = fileparts(IMGFILE);
    set(wgts.SrcReslicedEdt,'String',sprintf('%s%s',fr,fe));
  else
    set(wgts.SrcReslicedEdt,'String','');
  end
  
  Main_Callback(wgts.main,'load-src-redraw');
  
 case {'reset-src-redraw'}
  set(wgts.SrcReslicedEdt,'String','');
  Main_Callback(wgts.main,'load-src-redraw');
  
 case {'load-ref-redraw'}
  Main_Callback(wgts.main,'load-ref');
  Main_Callback(wgts.main,'redraw-ref');
  
 case {'load-src-redraw'}
  Main_Callback(wgts.main,'load-src');
  Main_Callback(wgts.main,'redraw-src');
  
  
 case {'ref-slice', 'ref-slider'}
  REF = getappdata(wgts.main,'REF');
  if strcmpi(eventdata,'ref-slice')
    iSlice = round(str2double(get(wgts.RefSliceEdt,'String')));
    if isempty(iSlice),  return;  end
    if iSlice < 1,  iSlice = 1;  end
    if iSlice > size(REF.dat,3),  iSlice = size(REF.dat,3);  end
    set(wgts.RefSldr,'Value',iSlice);
  else
    %get(wgts.RefSldr,'Value')
    %get(wgts.RefSldr,'SliderStep')
    iSlice = round(get(wgts.RefSldr,'Value'));
    if iSlice < 1,  iSlice = 1;  end
    if iSlice > size(REF.dat,3),  iSlice = size(REF.dat,3);  end
    set(wgts.RefSliceEdt,'String',sprintf('%d',iSlice));
  end
  Main_Callback(wgts.main,'redraw-ref');
  delete(findobj(wgts.SrcAxs,'tag','fpoint'));
  delete(findobj(wgts.SrcAxs,'tag','fpoint-text'));
  T_IMAGE = getappdata(wgts.main,'T_IMAGE');
  if length(T_IMAGE.points) >= iSlice && any(T_IMAGE.points(iSlice).slice),
    tmpslice = T_IMAGE.points(iSlice).slice;
    if length(T_IMAGE.regimg) >= iSlice && isfield(T_IMAGE.regimg(iSlice),'tform') && isfield(T_IMAGE.regimg(iSlice).tform,'method'),
      tmpmethod = T_IMAGE.regimg(iSlice).tform.method;
      tmpk = find(strcmpi(get(wgts.TransformCmb,'String'),tmpmethod));
      if any(tmpk),
        set(wgts.TransformCmb,'Value',tmpk);
      end
    end
    set(wgts.SrcSliceEdt,'String',sprintf('%d',tmpslice));
    set(wgts.SrcSldr,    'Value',tmpslice);
    Main_Callback(wgts.main,'redraw-src');  drawnow;
  elseif get(wgts.YorkCheck,'Value') > 0,
    SRC = getappdata(wgts.main,'SRC');
    if iSlice > 0 && iSlice <= size(SRC.dat,3),
      set(wgts.SrcSliceEdt,'String',sprintf('%d',iSlice));
      set(wgts.SrcSldr,'Value',iSlice);
      Main_Callback(wgts.main,'redraw-src');
    end
  end
  Main_Callback(wgts.main,'redraw-overlay');
  
 case {'src-slice','src-slider'}
  SRC = getappdata(wgts.main,'SRC');
  if isempty(SRC),  return;  end
  if strcmpi(eventdata,'src-slice')
    iSlice = str2double(get(wgts.SrcSliceEdt,'String'));
    if isempty(iSlice),  return;  end
    if iSlice < 1,  iSlice = 1;  end
    if iSlice > size(SRC.dat,3),  iSlice = size(SRC.dat,3);  end
    set(wgts.SrcSldr,'Value',iSlice);
  else
    iSlice = round(get(wgts.SrcSldr,'Value'));
    if iSlice < 1,  iSlice = 1;  end
    if iSlice > size(SRC.dat,3),  iSlice = size(SRC.dat,3);  end
    set(wgts.SrcSliceEdt,'String',sprintf('%d',iSlice));
  end
  if get(wgts.YorkCheck,'Value') > 0,
    REF = getappdata(wgts.main,'REF');
    if iSlice > 0 && iSlice <= size(REF.dat,3),
      set(wgts.RefSliceEdt,'String',sprintf('%d',iSlice));
      set(wgts.RefSldr,'Value',iSlice);
      Main_Callback(wgts.main,'redraw-ref');
    end
  end
  Main_Callback(wgts.main,'redraw-src');
  Main_Callback(wgts.main,'redraw-overlay');
  
 
 case {'redraw'}
  Main_Callback(wgts.main,'redraw-ref');
  Main_Callback(wgts.main,'redraw-src');
  Main_Callback(wgts.main,'redraw-overlay');
  
 case {'redraw-ref'}
  sub_DrawREF(wgts);
  iSlice = round(get(wgts.RefSldr,'Value'));
  T_IMAGE = getappdata(wgts.main,'T_IMAGE');
  npts = 0;  tmptxt = 'NaN';
  if length(T_IMAGE.points) >= iSlice
    tmpslice = T_IMAGE.points(iSlice).slice;
    npts = length(T_IMAGE.points(iSlice).refx);
    tmptxt = sprintf('%d',tmpslice);
  end
  set(wgts.StatusField,'String',sprintf('SLICE(%d) : npoints=%d src=%s',iSlice,npts,tmptxt));
  
 case {'redraw-src'}
  sub_DrawSRC(wgts);
  
 case {'redraw-overlay'}
  sub_DrawOverlay(wgts);
  
 case {'image-off'}
  h = findobj(wgts.RefAxs,'tag','image-ref');
  if ishandle(h),
    set(wgts.RefAxs,'color','k');
    if get(wgts.ImageOffCheck,'value')
      set(h,'visible','off');
    else
      set(h,'visible','on');
    end
  else
    Main_Callback(wgts.main,'redraw-ref');
  end
  h = findobj(wgts.SrcAxs,'tag','image-src');
  if ishandle(h),
    set(wgts.SrcAxs,'color','k');
    if get(wgts.ImageOffCheck,'value')
      set(h,'visible','off');
    else
      set(h,'visible','on');
    end
  else
    Main_Callback(wgts.main,'redraw-src');
  end
  drawnow;
  
 case {'update-bkg'}
  sub_DrawREF(wgts);
  sub_DrawSRC(wgts);
  
 case {'transform'}
  iSlice = round(str2double(get(wgts.RefSliceEdt,'String')));
  if isempty(iSlice) || isnan(iSlice),  return;  end
  SRC = getappdata(wgts.main,'SRC');
  T_IMAGE = getappdata(wgts.main,'T_IMAGE');
  if isempty(T_IMAGE),  return;  end
  if isfield(T_IMAGE,'regimg') && isempty(T_IMAGE.regimg),
    T_IMAGE = rmfield(T_IMAGE,'regimg');
  end
  T_IMAGE.regimg(iSlice) = sub_transform(wgts,SRC,T_IMAGE,iSlice,'verbose',1);
  setappdata(wgts.main,'T_IMAGE',T_IMAGE);
  
  %iSlice
  %T_IMAGE.regimg(iSlice)
  
  tmpslice = round(get(wgts.SrcSldr,'Value'));
  if ~isempty(T_IMAGE.regimg(iSlice).img) && ~any(T_IMAGE.regimg(iSlice).slice == tmpslice),
    % move the volume to the correct one
    tmpslice = T_IMAGE.regimg(iSlice).slice;
    set(wgts.SrcSliceEdt,'String',sprintf('%d',tmpslice));
    set(wgts.SrcSldr,    'Value', tmpslcie);
    Main_Callback(wgts.main,'redraw-src');
  end
  Main_Callback(wgts.main,'redraw-overlay');

  
 case {'grid-onoff'}
  if get(wgts.GridOnCheck,'Value') > 0,
    set(wgts.RefAxs,    'XGrid','on', 'YGrid','on');
    set(wgts.SrcAxs,    'XGrid','on', 'YGrid','on');
    set(wgts.OverlayAxs,'XGrid','on', 'YGrid','on');
  else
    set(wgts.RefAxs,    'XGrid','off','YGrid','off');
    set(wgts.SrcAxs,    'XGrid','off','YGrid','off');
    set(wgts.OverlayAxs,'XGrid','off','YGrid','off');
  end

 case {'marker-type'}
  tmpmarker = get(wgts.MarkerCmb,'String');
  tmpmarker = tmpmarker{get(wgts.MarkerCmb,'Value')};
  set(findobj(wgts.RefAxs,    'tag','fpoint'),'marker',tmpmarker);
  set(findobj(wgts.SrcAxs,    'tag','fpoint'),'marker',tmpmarker);
  set(findobj(wgts.OverlayAxs,'tag','fpoint'),'marker',tmpmarker);
 case {'marker-color'}
  tmpcolor = sub_get_color(wgts.MarkerColorEdt,[1.0 1.0 0.0]);
  set(findobj(wgts.RefAxs,    'tag','fpoint'),'color',tmpcolor);
  set(findobj(wgts.SrcAxs,    'tag','fpoint'),'color',tmpcolor*0.7);
  set(findobj(wgts.OverlayAxs,'tag','fpoint'),'color',tmpcolor);
 case {'text-color'}
  tmpcolor = sub_get_color(wgts.TextColorEdt,[0.3 0.3 1.0]);
  set(findobj(wgts.RefAxs,    'tag','fpoint-text'),'color',tmpcolor);
  set(findobj(wgts.SrcAxs,    'tag','fpoint-text'),'color',tmpcolor);
  set(findobj(wgts.OverlayAxs,'tag','fpoint-text'),'color',tmpcolor);
  
 case {'point-action'}
  cmdstr = get(wgts.PointActionCmb,'String');
  cmdstr = cmdstr{get(wgts.PointActionCmb,'Value')};
  if strcmpi(cmdstr,'no action'),  return;  end
  % disable widgets
  set(wgts.PointActionCmb,'Enable','off');
  set(wgts.RefSliceEdt,   'Enable','off');
  set(wgts.RefSldr,       'Enable','off');
  set(wgts.SrcSliceEdt, 'Enable','off');
  set(wgts.SrcSldr,     'Enable','off');
  try
    Point_Function(wgts,cmdstr);
  catch
  end
  set(wgts.PointActionCmb,'Enable','on');
  set(wgts.RefSliceEdt,   'Enable','on');
  set(wgts.RefSldr,       'Enable','on');
  set(wgts.SrcSliceEdt, 'Enable','on');
  set(wgts.SrcSldr,     'Enable','on');
  
  set(wgts.PointActionCmb,'Value',1);
  
 otherwise
end
  

return




% ====================================================================
% MAIN CALLBACK
function Point_Function(wgts,cmdstr)
% ====================================================================

T_IMAGE = getappdata(wgts.main,'T_IMAGE');
iSlice = round(str2double(get(wgts.RefSliceEdt,'String')));
if isempty(iSlice) || isnan(iSlice),  return;  end

if length(T_IMAGE.points) < iSlice,
  T_IMAGE.points(iSlice).refx  = [];
  T_IMAGE.points(iSlice).refy  = [];
  T_IMAGE.points(iSlice).srcx  = [];
  T_IMAGE.points(iSlice).srcy  = [];
  T_IMAGE.points(iSlice).slice = [];
end


switch lower(cmdstr),
 case {'append'}
  REF   = getappdata(wgts.main,'REF');
  SRC = getappdata(wgts.main,'SRC');
  
  NEW_POINTS = T_IMAGE.points(iSlice);
  OLD_POINTS = T_IMAGE.points(iSlice);

  set(wgts.StatusField,'String','Left-Click to set a point,  Right-Click to quit.');

  marker = get(wgts.MarkerCmb,'String');
  marker = marker{get(wgts.MarkerCmb,'Value')};
  mkrcol = sub_get_color(wgts.MarkerColorEdt,[1.0 1.0 0.0]);
  txtcol = sub_get_color(wgts.TextColorEdt,  [0.3 0.3 1.0]);

  while 1,
    tmpcursor = get(wgts.PointCursorCmb,'String');
    tmpcursor = tmpcursor{get(wgts.PointCursorCmb,'Value')};
    tobj = timer('TimerFcn',sprintf('mroi_cursor(''%s'');',tmpcursor),...
                 'StartDelay',0.1);
    start(tobj);
    try
      [x y] = ginput(1);
    catch
      lasterr
      click = get(wgts.main,'SelectionType');
      if strcmpi(click,'alt'),
        wait(tobj);  delete(tobj);
        break;
      else
        lasterr;
      end
    end
    % delete the timer object and restore the cursor
    wait(tobj);  delete(tobj);
    set(wgts.main,'Pointer','arrow');

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
    end
    
    % note that ginput() will select the current axes
    if wgts.RefAxs == gca,
      xlm = get(gca,'xlim');
      if x < xlm(1) || x > xlm(2)*1.2,  continue;  end
      ylm = get(gca,'ylim');
      if y < ylm(1) || y > ylm(2)*1.2,  continue;  end
      
      NEW_POINTS.refx(end+1) = x;
      NEW_POINTS.refy(end+1) = y;
      N = length(NEW_POINTS.refx);
      
      tmpcolor = mkrcol;
      txtoffs = ceil(0.4/REF.ds(1));
    elseif wgts.SrcAxs == gca,
      xlm = get(gca,'xlim');
      if x < xlm(1) || x > xlm(2)*1.2,  continue;  end
      ylm = get(gca,'ylim');
      if y < ylm(1) || y > ylm(2)*1.2,  continue;  end

      NEW_POINTS.srcx(end+1) = x;
      NEW_POINTS.srcy(end+1) = y; 
      N = length(NEW_POINTS.srcx);
      
      tmpcolor = mkrcol*0.7;
      txtoffs = ceil(0.4/SRC.ds(1));
    else
      continue;
    end
    hold on;
    plot(x,y,'marker',marker,'color',tmpcolor,'markersize',10,'tag','fpoint');
    text(x+txtoffs,y-txtoffs,sprintf('%d',N),'color',txtcol,'fontsize',8,...
         'tag','fpoint-text');
    hold off;
  end
  
  if length(NEW_POINTS.refx) ~= length(NEW_POINTS.srcx),
    n = min(length(NEW_POINTS.refx), length(NEW_POINTS.srcx));
    NEW_POINTS.refx = NEW_POINTS.refx(1:n);
    NEW_POINTS.refy = NEW_POINTS.refy(1:n);
    NEW_POINTS.srcx = NEW_POINTS.srcx(1:n);
    NEW_POINTS.srcy = NEW_POINTS.srcy(1:n);
    DO_REDRAW = 1;
  else
    DO_REDRAW = 0;
  end
  
  NEW_POINTS.slice = round(str2double(get(wgts.SrcSliceEdt,'String')));
  if ~isequal(OLD_POINTS,NEW_POINTS),
    if isfield(T_IMAGE,'regimg') && length(T_IMAGE.regimg) >= iSlice,
      T_IMAGE.regimg(iSlice).img    = [];
      T_IMAGE.regimg(iSlice).dxy    = [];
      T_IMAGE.regimg(iSlice).slice  = [];
      T_IMAGE.regimg(iSlice).tform  = [];
    end
  end
  
  T_IMAGE.points(iSlice) = NEW_POINTS;
  setappdata(wgts.main,'T_IMAGE',T_IMAGE);
  if DO_REDRAW,
    Main_Callback(wgts.main,'redraw-ref');
    Main_Callback(wgts.main,'redraw-src');
  end

  n = length(T_IMAGE.points(iSlice).refx);
  set(wgts.StatusField,'String',sprintf('SLICE(%d) : npoints=%d',iSlice,n));
  
 case {'replace'}
  Point_Function(wgts,'Remove ALL');
  Point_Function(wgts,'Append');
  
 case {'remove end'}
  T_IMAGE.points(iSlice).refx(end) = [];
  T_IMAGE.points(iSlice).refy(end) = [];
  T_IMAGE.points(iSlice).srcx(end) = [];
  T_IMAGE.points(iSlice).srcy(end) = [];
  if isfield(T_IMAGE,'regimg') && length(T_IMAGE.regimg) >= iSlice,
    T_IMAGE.regimg(iSlice).img    = [];
    T_IMAGE.regimg(iSlice).dxy    = [];
    T_IMAGE.regimg(iSlice).slice  = [];
    T_IMAGE.regimg(iSlice).tform  = [];
  end
  setappdata(wgts.main,'T_IMAGE',T_IMAGE);
  Main_Callback(wgts.main,'redraw-ref');
  Main_Callback(wgts.main,'redraw-src');
  Main_Callback(wgts.main,'redraw-src');
  drawnow;
  
 case {'remove x'}
  npoints  = length(T_IMAGE.points(iSlice).refx);
  tmptitle = sprintf('%s: remove points',mfilename);
  tmptxt   = sprintf('Enter point indices (1-%d) for the current slice.',npoints);
  answer = inputdlg({ tmptxt },tmptitle,1,{''});
  if ~isempty(answer),
    tmpidx = str2num(answer{1});
    tmpidx = tmpidx(tmpidx > 0 & tmpidx <= npoints);
    if any(tmpidx),
      T_IMAGE.points(iSlice).refx(tmpidx)   = [];
      T_IMAGE.points(iSlice).refy(tmpidx)   = [];
      T_IMAGE.points(iSlice).srcx(tmpidx) = [];
      T_IMAGE.points(iSlice).srcy(tmpidx) = [];
      if isfield(T_IMAGE,'regimg') && length(T_IMAGE.regimg) >= iSlice,
        T_IMAGE.regimg(iSlice).img    = [];
        T_IMAGE.regimg(iSlice).dxy    = [];
        T_IMAGE.regimg(iSlice).slice  = [];
        T_IMAGE.regimg(iSlice).tform  = [];
      end
      setappdata(wgts.main,'T_IMAGE',T_IMAGE);
      Main_Callback(wgts.main,'redraw-ref');
      Main_Callback(wgts.main,'redraw-src');
      drawnow;
    end
  end
  
 case {'remove all'}
  T_IMAGE.points(iSlice).refx = [];
  T_IMAGE.points(iSlice).refy = [];
  T_IMAGE.points(iSlice).srcx = [];
  T_IMAGE.points(iSlice).srcy = [];
  if isfield(T_IMAGE,'regimg') && length(T_IMAGE.regimg) >= iSlice,
    T_IMAGE.regimg(iSlice).img    = [];
    T_IMAGE.regimg(iSlice).dxy    = [];
    T_IMAGE.regimg(iSlice).slice  = [];
    T_IMAGE.regimg(iSlice).tform  = [];
  end
  setappdata(wgts.main,'T_IMAGE',T_IMAGE);
  delete(findobj(wgts.RefAxs,    'tag','fpoint'));
  delete(findobj(wgts.RefAxs,    'tag','fpoint-text'));
  delete(findobj(wgts.SrcAxs,    'tag','fpoint'));
  delete(findobj(wgts.SrcAxs,    'tag','fpoint-text'));
  delete(findobj(wgts.OverlayAxs,'tag','fpoint'));
  delete(findobj(wgts.OverlayAxs,'tag','fpoint-text'));
  n = length(T_IMAGE.points(iSlice).refx);
  set(wgts.StatusField,'String',sprintf('SLICE(%d) : npoints=%d',iSlice,n));
  drawnow;
 
 case {'clear all slices'}
  T_IMAGE.points = [];
  T_IMAGE.regimg  = [];
  setappdata(wgts.main,'T_IMAGE',T_IMAGE);
  delete(findobj(wgts.RefAxs,    'tag','fpoint'));
  delete(findobj(wgts.RefAxs,    'tag','fpoint-text'));
  delete(findobj(wgts.SrcAxs,    'tag','fpoint'));
  delete(findobj(wgts.SrcAxs,    'tag','fpoint-text'));
  delete(findobj(wgts.OverlayAxs,'tag','fpoint'));
  delete(findobj(wgts.OverlayAxs,'tag','fpoint-text'));
  n = length(T_IMAGE.points(iSlice).refx);
  set(wgts.StatusField,'String',sprintf('SLICE(%d) : npoints=%d',iSlice,n));
  drawnow;
  
 otherwise
  
end


return
  


% ========================================================================
function IMG = sub_anzload(wgts,TYPE)
% ========================================================================


switch lower(TYPE)
 case {'ref' 'reference'}
  IMGFILE = get(wgts.RefFileEdt,'String');
 case {'src' 'source'}
  IMGFILE = get(wgts.SrcFileEdt,'String');
end



if ~exist(IMGFILE,'file'),
  error('\n ERROR %s:  ''%s'' not found.\n',mfilename,IMGFILE);
end


%[IMG HDR] = anz_read(IMGFILE);
%REF.ds  = double(HDR.dime.pixdim(2:4));
%REF.dat = double(IMG);

V = spm_vol(IMGFILE);

[fp fr fe] = fileparts(IMGFILE);
IMG.file = sprintf('%s%s',fr,fe);
IMG.ds  = abs(double(V.mat([1 6 11])));
IMG.dat = double(spm_read_vols(V));

maxv = max(IMG.dat(:));
if maxv < 35,
  % most likely rhesus_7_model-MNI.nii....
  minv = min(IMG.dat(:));
  IMG.dat = (IMG.dat - minv)/(maxv-minv)*1000;
end



switch lower(TYPE)
 case {'ref' 'reference'}
  IMG.permute = [];
  IMG.flipdim = [];
 
 case {'src' 'source'}
  tmpv = str2num(get(wgts.SrcPermuteEdt,'String'));
  if length(tmpv) == 3,
    IMG.ds = IMG.ds(tmpv);
    IMG.dat = permute(IMG.dat,tmpv);
  end
  IMG.permute = tmpv;
  tmpv = str2num(get(wgts.SrcFlipdimEdt,'String'));
  for N = 1:length(tmpv),
    IMG.dat = flipdim(IMG.dat,tmpv(N));
  end
  IMG.flipdim = tmpv;
  
end


return



% ========================================================================
function NEW_DATA = sub_transform(wgts,SRC,T_IMAGE,iRefSlice,varargin)
% ========================================================================


VERBOSE = 0;
METHOD  = '';
for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'verbose'}
    VERBOSE = varargin{N+1};
   case {'method'}
    METHOD  = varargin{N+1};
  end
end


NEW_DATA.img     = [];
NEW_DATA.dxy     = [];
NEW_DATA.slice   = [];
NEW_DATA.tform.func         = '';
NEW_DATA.tform.method       = '';
NEW_DATA.tform.reg_resize   = [];
NEW_DATA.tform.base_points  = [];
NEW_DATA.tform.input_points = [];
NEW_DATA.tform.tform        = [];
NEW_DATA.tform.xdata        = [];
NEW_DATA.tform.ydata        = [];

if length(T_IMAGE.points) < iRefSlice || isempty(T_IMAGE.points(iRefSlice).refx),
  if VERBOSE,
    set(wgts.StatusField,'String','WARNING: no fiducial points for transform.');
  end  
  return
end

  
REF    = getappdata(wgts.main,'REF');
PINFO  = T_IMAGE.points(iRefSlice);


if isempty(METHOD),
  METHOD = get(wgts.TransformCmb,'String');
  METHOD = METHOD{get(wgts.TransformCmb,'Value')};
end
% check # of points
n = length(PINFO.refx);
minn = 0;
switch lower(METHOD),
 case {'lwm'}
  if n < 12,  minn = 12;  end
 case {'linear conformal'}
  if n <  2,  minn =  2;  end
 case {'affine'}
  if n <  3,  minn =  3;  end
 case {'projective','piecewise linear'}
  if n <  4,  minn =  4;  end
 case {'polynomial'}
  if n < 10,  minn = 10;  end
end
if minn > 0,
  StatusTxt = sprintf('SLICE(%d) ERROR : Min.Control Points=%d for ''%s'', see/help cp2tform.m.',...
                      iRefSlice,minn,METHOD);
  set(wgts.StatusField,'String',StatusTxt);  drawnow;
  return;
end


tmpslice = round(str2double(get(wgts.SrcSliceEdt,'String')));
tmpimg = squeeze(SRC.dat(:,:,tmpslice));

input_points = [PINFO.srcx(:)   PINFO.srcy(:)];
base_points  = [PINFO.refx(:)   PINFO.refy(:)];

if VERBOSE,
  StatusTxt = sprintf('SLICE(%d) : npoints=%d src=%d.',...
                      iRefSlice,size(input_points,1),PINFO.slice);
  set(wgts.StatusField,'String',StatusTxt);  drawnow;
end


if 1,
  nx = size(REF.dat,1);
  ny = size(REF.dat,2);
  %xdata = 1:nx;
  %ydata = 1:ny;
  % make larger to keep atlas detail
  sx = floor(REF.ds(1)/SRC.ds(2));
  sy = floor(REF.ds(2)/SRC.ds(1));

  if sx > 1,
    nx = nx * sx;
    base_points(:,1) = base_points(:,1) * sx;
  end
  if sy > 1,
    ny = ny * sy;
    base_points(:,2) = base_points(:,2) * sy;
  end
  xdata = [1 nx];
  ydata = [1 ny];

  if VERBOSE,
    StatusTxt = sprintf('%s size[%dx%d].',StatusTxt,nx,ny);
    set(wgts.StatusField,'String',StatusTxt);  drawnow;
  end 
  
  NEW_DATA.dxy     = [REF.ds(1)*size(REF.dat,1)/nx REF.ds(2)*size(REF.dat,2)/ny];
else
  % imtransform() doesn't accept floating values as coordinates...
  fov = [REF.ds(1)*size(REF.dat,1)  REF.ds(2)*size(REF.dat,2)];
  dx = SRC.ds(1);
  dy = SRC.ds(2);
  nx = round(fov(1)/dx);
  ny = round(fov(2)/dy);
  xdata = [1 nx]*dx - dx/2;
  ydata = [1 ny]*dy - dy/2;
end


tic;

if VERBOSE,
  StatusTxt = sprintf('%s cp2tform(''%s'').',StatusTxt,METHOD);
  set(wgts.StatusField,'String',StatusTxt);  drawnow;
end 
mytform = cp2tform(input_points,base_points,METHOD);
if VERBOSE,
  StatusTxt = sprintf('%s imtransform()...',StatusTxt);
  set(wgts.StatusField,'String',StatusTxt);  drawnow;
end 


if size(tmpimg,3) > 2,
  tmpimg = permute(tmpimg,[2 1 3]);
  % note that tmpimg as (y,x,color)
  regimg = imtransform(tmpimg, mytform,'nearest','xdata',xdata,'ydata',ydata,'size',[ydata(2) xdata(2)],'FillValues',[255;255;255]);
  regimg = permute(regimg,[2 1 3]);
else
  tmpimg = tmpimg';
  % note that tmpimg as (y,x)
  regimg = imtransform(tmpimg, mytform,'nearest','xdata',xdata,'ydata',ydata,'size',[ydata(2) xdata(2)],'FillValues',0);
  regimg = regimg';
end

%size(regimg)
%xdata
%ydata

NEW_DATA.img    = regimg;
NEW_DATA.slice  = PINFO.slice(1);


NEW_DATA.tform.func         = 'imtransform';
NEW_DATA.tform.method       = METHOD;
NEW_DATA.tform.reg_resize   = [nx ny];
NEW_DATA.tform.base_points  = base_points;
NEW_DATA.tform.input_points = input_points;
NEW_DATA.tform.tform        = mytform;
NEW_DATA.tform.xdata        = xdata;
NEW_DATA.tform.ydata        = ydata;

T1 = toc;

if VERBOSE,
  StatusTxt = sprintf('%s done (%gs).',StatusTxt,T1);
  set(wgts.StatusField,'String',StatusTxt);  drawnow;
end 

return



% ========================================================================
function sub_DrawREF(wgts,haxs,cmap)
% ========================================================================

if nargin < 2,
  haxs = wgts.RefAxs;
end
if nargin < 3,
  cmap = gray(256);
end
  

iSlice = round(str2double(get(wgts.RefSliceEdt,'String')));
if isempty(iSlice) || isnan(iSlice),  return;  end

REF = getappdata(wgts.main,'REF');
if isempty(REF),  return;  end


AnaScale = str2num(get(wgts.RefScaleEdt,'String'));
if length(AnaScale) < 2,  return;  end
AnaGamma = str2double(get(wgts.RefGammaEdt,'String'));
if isempty(AnaGamma),  return;  end

cmap = cmap.^(1/AnaGamma);

tmpana = squeeze(REF.dat(:,:,iSlice));

if get(wgts.ImageOffCheck,'Value')
  tmpana(:) = 1;
else
  tmpana = (tmpana - AnaScale(1)) / (AnaScale(2) - AnaScale(1));
  tmpana = round(tmpana*256);
  tmpana(tmpana(:) > 256) = 256;
  tmpana(tmpana(:) <   1) =   1;
end
tmpana = ind2rgb(tmpana',cmap);

if get(wgts.WhiteBkgCheck,'value') > 0,
  tmpsz = size(tmpana);
  tmpana = reshape(tmpana,[tmpsz(1)*tmpsz(2) tmpsz(3)]);
  tmpidx = tmpana(:,1) == 0 & tmpana(:,2) == 0 & tmpana(:,3) == 0;
  tmpana(tmpidx,:) = 1;
  tmpana = reshape(tmpana,tmpsz);
  clear tmpsz tmpidx;
end


if 1
  tmpX = 1:size(tmpana,2);
  tmpY = 1:size(tmpana,1);
else
  % imtransform() doesn't accept floating values as coordinates...
  tmpX = (1:size(tmpana,2)) * REF.ds(1) - REF.ds(1)/2;
  tmpY = (1:size(tmpana,1)) * REF.ds(2) - REF.ds(2)/2;
end
  
set(wgts.main,'CurrentAxes',haxs);
TagAxs = get(haxs,'tag');

h = findobj(haxs,'tag','image-ref');
xlm = [tmpX(1) tmpX(end)];
ylm = [tmpY(1) tmpY(end)];


h = findobj(haxs,'tag','image-ref');
if ishandle(h),
  delete(findobj(haxs,'tag','fpoint'));
  delete(findobj(haxs,'tag','fpoint-text'));
  set(h,'cdata',tmpana,'xdata',tmpX,'ydata',tmpY,'tag','image-ref');
else
  h = image(tmpX,tmpY,tmpana,'tag','image-ref');
end
%image(tmpX,tmpY,tmpana,'tag','image-ref');
set(gca,'fontsize',5);
set(gca,'xcolor',[0.8 0 0.8],'ycolor',[0.8 0 0.8]);
%set(gca,'xcolor',[0.8 0 0.0],'ycolor',[0.8 0 0.0]);
set(gca,'tag',TagAxs);
if get(wgts.GridOnCheck,'Value') > 0,
  grid on;
end


if ~isempty(xlm), set(gca,'xlim',xlm);  end
if ~isempty(xlm), set(gca,'ylim',ylm);  end
%daspect([1 1 1]);


T_IMAGE = getappdata(wgts.main,'T_IMAGE');
if ~isfield(T_IMAGE,'points'),  return;  end
if length(T_IMAGE.points) < iSlice,  return;  end
points = T_IMAGE.points(iSlice);

txtoffs = ceil(0.4/REF.ds(1));


marker = get(wgts.MarkerCmb,'String');
marker = marker{get(wgts.MarkerCmb,'Value')};
mkrcol = sub_get_color(wgts.MarkerColorEdt,[1.0 1.0 0.0]);
txtcol = sub_get_color(wgts.TextColorEdt,  [0.3 0.3 1.0]);


hold on;
for N = 1:length(points.refx),
  tmpx = points.refx(N);
  tmpy = points.refy(N);
  plot(tmpx,tmpy,'marker',marker,'color',mkrcol,'markersize',10,'tag','fpoint');
  text(tmpx+txtoffs,tmpy-txtoffs,sprintf('%d',N),'color',txtcol,'fontsize',8,...
       'tag','fpoint-text');
end
hold off;


return



% ========================================================================
function sub_DrawSRC(wgts,haxs,cmap)
% ========================================================================

if nargin < 2,
  haxs = wgts.SrcAxs;
end
if nargin < 3,
  cmap = gray(256);
end
  


iSlice = round(get(wgts.SrcSldr,'Value'));
if isempty(iSlice) || isnan(iSlice),  return;  end

SRC = getappdata(wgts.main,'SRC');
if isempty(SRC),  return;  end
if iSlice < 1,  iSlice = 1;  end
if iSlice > size(SRC.dat,3),  iSlice = size(SRC.dat,3);  end


AnaScale = str2num(get(wgts.SrcScaleEdt,'String'));
if length(AnaScale) < 2,  return;  end
AnaGamma = str2double(get(wgts.SrcGammaEdt,'String'));
if isempty(AnaGamma),  return;  end

cmap = cmap.^(1/AnaGamma);

tmpimg = squeeze(SRC.dat(:,:,iSlice));

if get(wgts.ImageOffCheck,'Value')
  tmpimg(:) = 1;
else
  tmpimg = (tmpimg - AnaScale(1)) / (AnaScale(2) - AnaScale(1));
  tmpimg = round(tmpimg*256);
  tmpimg(tmpimg(:) > 256) = 256;
  tmpimg(tmpimg(:) <   1) =   1;
end
tmpimg = ind2rgb(tmpimg',cmap);

if get(wgts.EdgeOnCheck,'Value'),
  tmpimg = sub_imgedge(tmpimg);
  %tmpimg = 1 - tmpimg;
end

if get(wgts.WhiteBkgCheck,'value') > 0,
  if get(wgts.EdgeOnCheck,'Value'),
    tmpimg = 1 - tmpimg;
  else
    tmpsz = size(tmpimg);
    tmpimg = reshape(tmpimg,[tmpsz(1)*tmpsz(2) tmpsz(3)]);
    tmpidx = tmpimg(:,1) == 0 & tmpimg(:,2) == 0 & tmpimg(:,3) == 0;
    tmpimg(tmpidx,:) = 1;
    tmpimg = reshape(tmpimg,tmpsz);
    clear tmpsz tmpidx;
  end
end



dx = SRC.ds(1);
dy = SRC.ds(2);

if 1
  tmpX = 1:size(tmpimg,2);
  tmpY = 1:size(tmpimg,1);
else
  % imtransform() doesn't accept floating values as coordinates...
  tmpX = (1:size(tmpimg,2)) * dx - dy/2;
  tmpY = (1:size(tmpimg,1)) * dy - dy/2;
end
  
set(wgts.main,'CurrentAxes',wgts.SrcAxs);
h = findobj(wgts.SrcAxs,'tag','image-src');
if any(h),
  xlm = get(wgts.SrcAxs,'xlim');  ylm = get(wgts.SrcAxs,'ylim');
else
  xlm = [];  ylm = [];
end

%tmpimg = imresize(tmpimg,round([size(tmpimg,1) size(tmpimg,2)]/3));
%tmpimg(tmpimg(:) < 0) = 0;
%tmpimg(tmpimg(:) > 1) = 1;
%tmpX = 1:size(tmpimg,2);
%tmpY = 1:size(tmpimg,1);

h = findobj(wgts.SrcAxs,'tag','image-src');
if ishandle(h),
  delete(findobj(wgts.SrcAxs,'tag','fpoint'));
  delete(findobj(wgts.SrcAxs,'tag','fpoint-text'));
  set(h,'cdata',tmpimg,'xdata',tmpX,'ydata',tmpY,'tag','image-src');
else
  h = image(tmpX,tmpY,tmpimg,'tag','image-src');
end
%image(tmpX,tmpY,tmpimg,'tag','image-src');
%h = imshow(tmpimg,'xdata',tmpX,'ydata',tmpY);
%set(h,'tag','image-src');
set(gca,'fontsize',5);
set(gca,'xcolor',[0.8 0 0.8],'ycolor',[0.8 0 0.8]);
%set(gca,'xcolor',[0 0.8 0],'ycolor',[0 0.8 0]);
set(gca,'tag','SrcAxs');
if get(wgts.GridOnCheck,'Value') > 0,
  grid on;
end

if ~isempty(xlm),
  set(gca,'xlim',xlm);  set(gca,'ylim',ylm);
else
  %daspect([1 1 1]);
end


iRefSlice = round(str2double(get(wgts.RefSliceEdt,'String')));
if isempty(iRefSlice) || isnan(iRefSlice),  return;  end

T_IMAGE = getappdata(wgts.main,'T_IMAGE');
if ~isfield(T_IMAGE,'points'),  return;  end
if length(T_IMAGE.points) < iRefSlice,  return;  end
points = T_IMAGE.points(iRefSlice);

marker = get(wgts.MarkerCmb,'String');
marker = marker{get(wgts.MarkerCmb,'Value')};
mkrcol = sub_get_color(wgts.MarkerColorEdt,[1.0 1.0 0.0]);
txtcol = sub_get_color(wgts.TextColorEdt,  [0.3 0.3 1.0]);

txtoffs = ceil(0.4/SRC.ds(1));

hold on;
for N = 1:length(points.srcx),
  tmpx = points.srcx(N);
  tmpy = points.srcy(N);
  plot(tmpx,tmpy,'marker',marker,'color',mkrcol*0.7,'markersize',10,'tag','fpoint');
  text(tmpx+txtoffs,tmpy-txtoffs,sprintf('%d',N),'color',txtcol,'fontsize',8,...
       'tag','fpoint-text');
end
hold off;

if isfield(T_IMAGE.regimg(iRefSlice),'tform'),
  if isfield(T_IMAGE.regimg(iRefSlice).tform,'method'),
    tmpmethod = T_IMAGE.regimg(iRefSlice).tform.method;
    if ~isempty(tmpmethod),
      tmpk = find(strcmpi(get(wgts.TransformCmb,'String'),tmpmethod));
      if any(tmpk),
        set(wgts.TransformCmb,'Value',tmpk);
      end
    end
  end
end


return




% ========================================================================
function sub_DrawOverlay(wgts)
% ========================================================================

if get(wgts.OverlayUpdateCheck,'Value') == 0,  return;  end


iRefSlice = round(str2double(get(wgts.RefSliceEdt,'String')));
if isempty(iRefSlice) || isnan(iRefSlice),  return;  end

REF = getappdata(wgts.main,'REF');
if isempty(REF),  return;  end

RefScale = str2num(get(wgts.RefScaleEdt,'String'));
if length(RefScale) < 2,  return;  end
RefGamma = str2double(get(wgts.RefGammaEdt,'String'));
if isempty(RefGamma),  return;  end

SrcScale = str2num(get(wgts.SrcScaleEdt,'String'));
if length(SrcScale) < 2,  return;  end
SrcGamma = str2double(get(wgts.SrcGammaEdt,'String'));
if isempty(SrcGamma),  return;  end

cmapRef = gray(256);  cmapRef(:,[2 3]) = 0;
cmapRef = cmapRef.^(1/RefGamma);
cmapSrc = gray(256);  cmapSrc(:,[1 3]) = 0;
cmapSrc = cmapSrc.^(1/SrcGamma);


NEW_SRC.img    = [];
NEW_SRC.dxy    = [];
NEW_SRC.slice  = [];
NEW_SRC.tform.reg_resize = [];


% get the current SRC slice.
SRC = getappdata(wgts.main,'SRC');
iSrcSlice = round(str2double(get(wgts.SrcSliceEdt,'String')));
if isempty(iSrcSlice) || isnan(iSrcSlice),
  iSrcSlice = round(get(wgts.SrcSldr,'Value'));
end

% check the existing transformation
T_IMAGE = getappdata(wgts.main,'T_IMAGE');
if isfield(T_IMAGE,'regimg') && length(T_IMAGE.regimg) >= iRefSlice,
  NEW_SRC = T_IMAGE.regimg(iRefSlice);
end

if isempty(NEW_SRC.img) || NEW_SRC.slice ~= iSrcSlice || get(wgts.TransformedCheck,'Value') == 0,
  % use the current
  NEW_SRC.img = squeeze(SRC.dat(:,:,iSrcSlice));
  NEW_SRC.tform = [];
  NEW_SRC.tform.reg_resize = [size(NEW_SRC.img,1), size(NEW_SRC.img,2)];
end

tmpref = squeeze(REF.dat(:,:,iRefSlice));
if isfield(NEW_SRC,'tform') && ~isempty(NEW_SRC.tform.reg_resize),
  SX = NEW_SRC.tform.reg_resize(1) / size(tmpref,1);
  SY = NEW_SRC.tform.reg_resize(2) / size(tmpref,2);
  if SX ~= 1 || SY ~= 1,
    tmpref = imresize(tmpref,NEW_SRC.tform.reg_resize);
  end
end

tmpref = (tmpref - RefScale(1)) / (RefScale(2) - RefScale(1));
tmpref = round(tmpref*256);
tmpref(tmpref(:) > 256) = 256;
tmpref(tmpref(:) <   1) =   1;
tmpref = ind2rgb(tmpref',cmapRef);


if get(wgts.OverlayCheck,'Value') > 0 && ~isempty(NEW_SRC.img),
  if get(wgts.ReferenceCheck,'Value') == 0,
    tmpref(:) = 0;
  end
  
  tmpsrc = NEW_SRC.img;
  tmpsrc = (tmpsrc - SrcScale(1)) / (SrcScale(2) - SrcScale(1));
  tmpsrc = round(tmpsrc*256);
  tmpsrc(tmpsrc(:) > 256) = 256;
  tmpsrc(tmpsrc(:) <   1) =   1;
  tmpsrc = ind2rgb(tmpsrc',cmapSrc);

  if get(wgts.EdgeOnCheck,'Value'),
    tmpsrc = sub_imgedge(tmpsrc);
  end
  
  % now fuse images
  sz_ref = size(tmpref);
  tmpref = reshape(tmpref,[sz_ref(1)*sz_ref(2) sz_ref(3)]);
  sz_src = size(tmpsrc);
  tmpsrc = reshape(tmpsrc,[sz_src(1)*sz_src(2) sz_src(3)]);

  if 1,
    tmpidx = find(tmpsrc(:,1) > 0.0 | tmpsrc(:,2) > 0.0 | tmpsrc(:,3) > 0.0);
    tmpref(tmpidx,:) = tmpref(tmpidx,:) + tmpsrc(tmpidx,:);
    tmpref(tmpref(:) < 0) = 0;
    tmpref(tmpref(:) > 1) = 1;
  else
    tmpidx = find(tmpsrc(:,1) > 0.0 | tmpsrc(:,2) > 0.0 | tmpsrc(:,3) > 0.0);
    %tmpidx = find(tmpsrc(:,1) < 1.0 | tmpsrc(:,2) < 1.0 | tmpsrc(:,3) < 1.0);
    %tmpref(tmpidx,:) = tmpsrc(tmpidx,:);
    tmpref(tmpidx,:) = (tmpref(tmpidx,:) + tmpsrc(tmpidx,:))/2;
  end

  tmpref = reshape(tmpref,sz_ref);
  tmpsrc = reshape(tmpsrc,sz_src);
end

tmpX = 1:size(tmpref,2);
tmpY = 1:size(tmpref,1);
set(wgts.main,'CurrentAxes',wgts.OverlayAxs);

h = findobj(wgts.SrcAxs,'tag','image-tform');
if ishandle(h),
 delete(findobj(wgts.SrcAxs,'tag','fpoint'));
 delete(findobj(wgts.SrcAxs,'tag','fpoint-text'));
 set(h,'cdata',tmpref,'xdata',tmpX,'ydata',tmpY,'tag','image-tform');
else
 h = image(tmpX,tmpY,tmpref,'tag','image-tform');
end
%h = image(tmpX,tmpY,tmpref,'tag','image-tform');

if get(wgts.GridOnCheck,'Value') > 0,
  grid on;
end

if isfield(NEW_SRC,'tform') && isfield(NEW_SRC.tform,'base_points'),
  base_points = NEW_SRC.tform.base_points;
  txtoffs = ceil(0.4/NEW_SRC.dxy(1));
  marker = get(wgts.MarkerCmb,'String');
  marker = marker{get(wgts.MarkerCmb,'Value')};
  mkrcol = sub_get_color(wgts.MarkerColorEdt,[1.0 1.0 0.0]);
  txtcol = sub_get_color(wgts.TextColorEdt,  [0.3 0.3 1.0]);
  hold on;
  for N = 1:length(base_points),
    x = base_points(N,1);
    y = base_points(N,2);
    plot(x,y,'marker',marker,'color',mkrcol,'markersize',10,'tag','fpoint');
    text(x+txtoffs,y-txtoffs,sprintf('%d',N),'color',txtcol,'fontsize',8,...
         'tag','fpoint-text');
  end
  tmptxt = sprintf('Transformed : Ref(%d)-Src(%d)',iRefSlice,NEW_SRC.slice);
  text(0.01,0.99,tmptxt,'color','y','units','normalized',...
       'VerticalAlignment','top');
  hold off;
else
  text(0.01,0.99,'No Transformation','color','y','units','normalized',...
       'VerticalAlignment','top');
end

xlm = str2num(get(wgts.OverlayXlimEdt,'String'));
ylm = str2num(get(wgts.OverlayYlimEdt,'String'));
if length(xlm)==2, set(gca,'xlim',xlm);  end
if length(ylm)==2, set(gca,'ylim',ylm);  end

set(gca,'fontsize',5);
set(gca,'xcolor',[0.8 0 0.8],'ycolor',[0.8 0 0.8]);
set(wgts.OverlayAxs,'Tag','OverlayAxs');

return


% ========================================================================
function IMG = sub_imgedge(IMG)
% ========================================================================

IMG(:,:,1) = edge(IMG(:,:,1),'canny');
IMG(:,:,2) = edge(IMG(:,:,2),'canny');
IMG(:,:,3) = edge(IMG(:,:,3),'canny');
%IMG = 1 - IMG;
% tmpsz = size(IMG);
% IMG = reshape(IMG,[prod(tmpsz(1:2)) tmpsz(3)]);
% IMG(IMG(:,1) > .8 & IMG(:,2) > .8 & IMG(:,3) > .8, 3) = 0;
% IMG(IMG(:,1) < .1 & IMG(:,2) < .1 & IMG(:,3) < .1, :) = 1;
% IMG = reshape(IMG,tmpsz);

return



% ========================================================================
function colv = sub_get_color(hEdt,DefaultColor)
% ========================================================================

colv = [];
tmpv = get(hEdt,'String');

% rgbcmykw
switch lower(tmpv)
 case {'r' 'red'}
  colv = [1.0  0.0  0.0];
 case {'g' 'green'}
  colv = [0.0  1.0  0.0];
 case {'b' 'blue'}
  colv = [0.0  0.0  1.0];
 case {'c' 'cyan'}
  colv = [0.0  1.0  1.0];
 case {'m' 'magenta'}
  colv = [1.0  0.0  1.0];
 case {'y' 'yellow'}
  colv = [1.0  1.0  0.0];
 case {'k' 'black'}
  colv = [0.0  0.0  0.0];
 case {'w' 'white'}
  colv = [1.0  1.0  1.0];
 otherwise
  tmpv = str2num(tmpv);
  if length(tmpv) == 3,  colv = tmpv;  end
end


if isempty(colv),  colv = DefaultColor;  end


return


% ========================================================================
function NEWFILE = sub_spm_reslice(IMGFILE,Rxyz)

M = sub_affine_mat([1 1 1],[0 0 0],Rxyz);


% initialize spm package, bofore any use of spm_xxx functions
if any(strcmpi(spm('ver'),{'SPM2','SPM5'})),
  spm_defaults;
else
  spm_get_defaults;
end

V0 = spm_vol(IMGFILE);
VX = spm_vol(IMGFILE);

VX.mat = M*VX.mat;
spm_reslice([V0 VX],struct('which',1,'mean',0));

[fp fr fe] = fileparts(IMGFILE);

NEWFILE = fullfile(fp,sprintf('r%s%s',fr,fe));

return



% ========================================================================
function M = sub_affine_mat(Sxyz,Txyz,Rxyz)
% ========================================================================

T = eye(4);  T(1:3,4) = Txyz(:);
S = eye(4);  S([1 6 11]) = Sxyz;

Rxyz = Rxyz/180*pi;
Rx = eye(4); A = Rxyz(1); Rx([6 7 10 11]) = [cos(A)  sin(A) -sin(A) cos(A)];
Ry = eye(4); A = Rxyz(2); Ry([1 3  9 11]) = [cos(A) -sin(A)  sin(A) cos(A)];
Rz = eye(4); A = Rxyz(3); Rz([1 2  5  6]) = [cos(A)  sin(A) -sin(A) cos(A)];

M = Rz*Ry*Rx*T*S;  % scale, translate then rotate around xyz

return



% ========================================================================
function sub_save_matched_volume(wgts)
% ========================================================================

set(wgts.StatusField,'String',' Making the matched volume...'); drawnow;

T_IMAGE = getappdata(wgts.main,'T_IMAGE');
SRC     = getappdata(wgts.main,'SRC');
REF     = getappdata(wgts.main,'REF');

srcsz = size(SRC.dat);
refsz = size(REF.dat);

try
NEWVOL.date = datestr(now);
NEWVOL.file = get(wgts.SrcFileEdt,'String');
NEWVOL.reference = get(wgts.RefFileEdt,'String');
NEWVOL.ds   = REF.ds;
if size(SRC.dat,4) > 1
  % (x,y,rgb,z)
  NEWVOL.dat = zeros([refsz(1) refsz(2) size(SRC.dat,4) refsz(3)],class(SRC.dat));
else
  % (x,y,z)
  NEWVOL.dat = zeros([refsz(1) refsz(2) refsz(3)],class(SRC.dat));
end

for N = 1:length(T_IMAGE.regimg),
  tmpimg = T_IMAGE.regimg(N).img;  % as (x,y) or (x,y,rgb)
  if isempty(tmpimg), continue;  end
  if size(SRC.dat,4) > 1,
    NEWVOL.dat(:,:,:,N) = tmpimg;
  else
    NEWVOL.dat(:,:,N) = tmpimg;
  end
end

if size(SRC.dat,4) > 1,
  NEWVOL.dat = permute(NEWVOL.dat,[1 2 4 3]);  % as (x,y,z,rgb)
end
catch
  lasterr
  keyboard
end


% undo "flipdim"
for N = 1:length(SRC.flipdim),
  NEWVOL.dat = flipdim(NEWVOL.dat,SRC.flipdim(N));
end
% undo "permute"
if any(SRC.permute),
  inverseorder(SRC.permute) = 1:numel(SRC.permute);
  NEWVOL.ds  = NEWVOL.ds(inverseorder);
  if size(SRC.dat,4) > 1,
    inverseorder(4) = 4;   % no permute for rgb=4
  end
  NEWVOL.dat = permute(NEWVOL.dat,inverseorder);
end


RefFile = get(wgts.RefFileEdt,'String');
SrcFile = get(wgts.SrcFileEdt,'String');
[fp fref] = fileparts(RefFile);
[fp fsrc] = fileparts(SrcFile);
matfile = sprintf('%s_ref(%s)_mreg2d_volume.mat',fsrc,fref);
fname = fullfile(fp,matfile);
if exist(fname,'file'),
  copyfile(fname,sprintf('%s.bak',fname),'f');
end
vname = 'TVOL';
eval(sprintf('%s = NEWVOL;',vname));
set(wgts.StatusField,'String',sprintf(' Saving ''%s'' to ''%s''...',vname,matfile)); drawnow;
save(fname,vname);
set(wgts.StatusField,'String',sprintf('%s done.',get(wgts.StatusField,'String'))); drawnow;

return



