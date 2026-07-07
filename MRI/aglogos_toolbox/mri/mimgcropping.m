function varargout = mimgcropping(varargin)
%MIMGCROPPING - GUI for image cropping (fMRI)
%  MIMGCROPPING(ANAFILE,EPIFILE,...)
%  MIMGCROPPING(Ses,Grp)
%  MIMGCROPPING(Ses,ExpNo) runs GUI for image cropping (fMRI).
%
%  EXAMPLE :
%    mimgcropping('i073d1',6)
%
%  EXAMPLE :
%    anafile = '\\Wks8\guest\I07.3d1\39\pdata\1\2dseq';
%    epifile = '\\Wks8\guest\I07.3d1\22\pdata\1\2dseq';
%    mimgcropping(anafile,epifile);
%
%  VERSION :
%    0.90 08.03.12 YM  pre-release
%    0.91 15.03.12 YM  GUI implemented.
%    0.92 16.03.12 YM  ActionCmb supported.
%
%  See also pvread_2dseq anz_read getrect


% execute callback function then return; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(varargin{1}) && ~isempty(findstr(varargin{1},'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return;
end




if any(findstr(varargin{1},'2dseq')),
  % called like mimgcropping(X/2dseq,/Y/2dseq)
  ANAFILE = varargin{1};
  EPIFILE = varargin{2};
  Ses = [];
  grp = [];
  ExpNo = [];
else
  % called like mimgcropping(ses,grpexp)
  Ses = getses(varargin{1});
  grp = getgrp(Ses,varargin{2});
  if isnumeric(varargin{2}),
    ExpNo = varargin{2}(1);
  else
    ExpNo = grp.exps(1);
  end

  EPIFILE = expfilename(Ses,ExpNo,'2dseq');
  
  if isfield(grp,'ana') && ~isempty(grp.ana)
    ANAPAR = Ses.ascan.(grp.ana{1}){grp.ana{2}};
    ANAPAR.name  = grp.ana{1};
    ANAPAR.slice = grp.ana{3};
    if ~isfield(ANAPAR,'dirname') || isempty(ANAPAR.dirname)
      ANAPAR.dirname = Ses.sysp.dirname;
    end
    ANAFILE = sprintf('%d/pdata/%d/2dseq',ANAPAR.scanreco(1),ANAPAR.scanreco(2));
    ANAFILE = fullfile(Ses.sysp.DataMri,ANAPAR.dirname,ANAFILE);
  else
    ANAFILE = '';
  end
end


% GET SCREEN SIZE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[scrW scrH] = subGetScreenSize('char');
% 288x60.3 char. for 1440x900 pixels.
figW = 160; figH = 40;
figX = 31;  figY = scrH-figH-15;


% CREATE A MAIN FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmptxt = mfilename;
if ~isempty(Ses)
  tmptxt = sprintf('%s  %s  exp=%d(%s)',tmptxt, Ses.name,ExpNo,grp.name);
end
hMain = figure(...
    'Name',tmptxt,...
    'NumberTitle','off', 'toolbar','figure',...
    'Tag','main', 'units','char', 'pos',[figX figY figW figH],...
    'HandleVisibility','on', 'Resize','on',...
    'DoubleBuffer','on', 'BackingStore','on', 'Visible','on',...
    'PaperPositionMode','auto', 'PaperType','A4', 'PaperOrientation', 'landscape');

BKGCOL = get(hMain,'Color');


IMGXOFFS =  8;
IMGYOFFS =  4;
IMGW     = 70;
IMGH     = 30;


% FILES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFFS figH-2.2 20 1.5],...
    'String','Anatomy :','FontWeight','bold','foregroundcolor',[0.6 0 0],...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
AnaFileEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFFS+12 figH-2 77 1.5],...
    'String',ANAFILE,'Tag','AnaFileEdt',...
    'Callback','mimgcropping(''Main_Callback'',gcbo,''load-ana'',[])',...
    'HorizontalAlignment','left',...
    'TooltipString','',...
    'FontWeight','bold');
AnaInfoTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFFS+91 figH-2 60 1.25],...
    'String','','FontWeight','bold','FontSize',8,...
    'HorizontalAlignment','left','Tag','AnaInfoTxt',...
    'BackgroundColor',get(hMain,'Color'));

uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFFS figH-4.2 20 1.5],...
    'String','EPI :','FontWeight','bold','foregroundcolor',[0 0.5 0],...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
EpiFileEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFFS+12 figH-4 77 1.5],...
    'String',EPIFILE,'Tag','EpiFileEdt',...
    'Callback','mimgcropping(''Main_Callback'',gcbo,''load-epi'',[])',...
    'HorizontalAlignment','left',...
    'TooltipString','',...
    'FontWeight','bold');
EpiInfoTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFFS+91 figH-4 60 1.25],...
    'String','','FontWeight','bold','FontSize',8,...
    'HorizontalAlignment','left','Tag','EpiInfoTxt',...
    'BackgroundColor',get(hMain,'Color'));



% AXES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
AnaAxs = axes(...
    'Parent',hMain,'Tag','AnaAxs',...
    'Units','char','Color','k','layer','top',...
    'Position',[IMGXOFFS IMGYOFFS IMGW IMGH],...
    'xticklabel','','yticklabel','','xtick',[],'ytick',[]);
daspect(AnaAxs,[2 2 1]);
EpiAxs = axes(...
    'Parent',hMain,'Tag','EpiAxs',...
    'Units','char','Color','k','layer','top',...
    'Position',[IMGXOFFS+IMGW+7 IMGYOFFS IMGW IMGH],...
    'xticklabel','','yticklabel','','xtick',[],'ytick',[]);
daspect(EpiAxs,[2 2 1]);
% EpiAvrAxs = axes(...
%     'Parent',hMain,'Tag','EpiAvrAxs',...
%     'Units','char','Color','k','layer','top',...
%     'Position',[IMGXOFFS+IMGW+IMGW+14 IMGYOFFS IMGW IMGH],...
%     'xticklabel','','yticklabel','','xtick',[],'ytick',[]);
% daspect(EpiAvrAxs,[2 2 1]);




% ====================================================================
% SLICE/IMAGE SELECTION
% ====================================================================
% uicontrol(...
%     'Parent',hMain,'Style','Text',...
%     'Units','char','Position',[IMGXOFFS IMGYOFFS+IMGH-1 18 1.25],...
%     'String','ANA :','FontWeight','bold','foregroundcolor',[0.6 0 0],...
%     'HorizontalAlignment','left','fontsize',9,...
%     'BackgroundColor',BKGCOL);
AnaGridCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[IMGXOFFS IMGYOFFS+IMGH-1 40 1.5],...
    'Tag','AnaGridCheck','Value',0,...
    'Callback','mimgcropping(''Main_Callback'',gcbo,''grid-ana'',[])',...
    'String','Grid','FontWeight','bold',...
    'TooltipString','Grid on/off','BackgroundColor',get(hMain,'Color'));
AnaImageCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMGXOFFS+12 IMGYOFFS+IMGH-1 16 1.5],...
    'String',{'slice' 'average'},...
    'Value',1,...
    'Callback','mimgcropping(''Main_Callback'',gcbo,''redraw-ana'',[])',...
    'TooltipString','Select the image',...
    'Tag','AnaImageCmb','FontWeight','Bold');
AnaSliceTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFFS+31 IMGYOFFS+IMGH-1 15 1.25],...
    'String','0','FontWeight','bold','FontSize',9,...
    'HorizontalAlignment','left','Tag','AnaSliceTxt',...
    'BackgroundColor',get(hMain,'Color'));
AnaSliceSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[IMGXOFFS+37 IMGYOFFS+IMGH-1 IMGW-37 1.5],...
    'Callback','mimgcropping(''Main_Callback'',gcbo,''slice-ana'',[])',...
    'Tag','AnaSliceSldr','SliderStep',[1 4],...
    'TooltipString','Set current slice');


% uicontrol(...
%     'Parent',hMain,'Style','Text',...
%     'Units','char','Position',[IMGXOFFS+IMGW+7 IMGYOFFS+IMGH-1 18 1.25],...
%     'String','EPI :','FontWeight','bold','foregroundcolor',[0 0.5 0],...
%     'HorizontalAlignment','left','fontsize',9,...
%     'BackgroundColor',BKGCOL);
EpiGridCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[IMGXOFFS+IMGW+7 IMGYOFFS+IMGH-1 40 1.5],...
    'Tag','EpiGridCheck','Value',0,...
    'Callback','mimgcropping(''Main_Callback'',gcbo,''grid-epi'',[])',...
    'String','Grid','FontWeight','bold',...
    'TooltipString','Grid on/off','BackgroundColor',get(hMain,'Color'));
EpiImageCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMGXOFFS+IMGW+7+12 IMGYOFFS+IMGH-1 16 1.5],...
    'String',{'slice' 'average'},...
    'Value',1,...
    'Callback','mimgcropping(''Main_Callback'',gcbo,''redraw-epi'',[])',...
    'TooltipString','Select the image',...
    'Tag','EpiImageCmb','FontWeight','Bold');
EpiSliceTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFFS+IMGW+7+31 IMGYOFFS+IMGH-1 15 1.25],...
    'String','0','FontWeight','bold','FontSize',9,...
    'HorizontalAlignment','left','Tag','EpiSliceTxt',...
    'BackgroundColor',get(hMain,'Color'));
EpiSliceSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[IMGXOFFS+IMGW+7+37 IMGYOFFS+IMGH-1 IMGW-37 1.5],...
    'Callback','mimgcropping(''Main_Callback'',gcbo,''slice-epi'',[])',...
    'Tag','EpiSliceSldr','SliderStep',[1 4],...
    'TooltipString','Set current slice');


% SCALE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFFS IMGYOFFS-2.7 35 1.5],...
    'String','Scale :','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
AnaScaleEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFFS+9, IMGYOFFS-2.5 22 1.5],...
    'Callback','mimgcropping(''Main_Callback'',gcbo,''redraw-ana'',guidata(gcbo))',...
    'String','','Tag','AnaScaleEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','anatomy scale [min max gamma]',...
    'FontWeight','bold');
AnaActionCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMGXOFFS+33 IMGYOFFS-2.5 16 1.5],...
    'String',{'No Action' 'rectangle' 'coordinate'},...
    'Value',1,...
    'Callback','mimgcropping(''Main_Callback'',gcbo,''action-ana'',[])',...
    'TooltipString','',...
    'Tag','AnaActionCmb','FontWeight','Bold');
% uicontrol(...
%     'Parent',hMain,'Style','pushbutton',...
%     'Units','char','Position',[IMGXOFFS+35 IMGYOFFS-2.5 14 1.5],...
%     'String','ANA-rect','FontWeight','bold','fontsize',9,...
%     'HorizontalAlignment','left',...
%     'TooltipString','draw a rectangle',...
%     'Callback','mimgcropping(''Main_Callback'',gcbo,''getrect-ana'',[])');
AnaRectEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFFS+50, IMGYOFFS-2.5 20 1.5],...
    'Callback','mimgcropping(''Main_Callback'',gcbo,''set-rect-ana'',guidata(gcbo))',...
    'String','','Tag','AnaRectEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','anatomy crop [xmin ymin width height]',...
    'FontWeight','bold');

uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFFS+IMGW+7 IMGYOFFS-2.7 35 1.5],...
    'String','Scale :','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
EpiScaleEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFFS+IMGW+7+9, IMGYOFFS-2.5 22 1.5],...
    'Callback','mimgcropping(''Main_Callback'',gcbo,''redraw-epi'',guidata(gcbo))',...
    'String','','Tag','EpiScaleEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','epi scale [min max gamma]',...
    'FontWeight','bold');
EpiActionCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMGXOFFS+IMGW+7+33 IMGYOFFS-2.5 16 1.5],...
    'String',{'No Action' 'rectangle' 'coordinate'},...
    'Value',1,...
    'Callback','mimgcropping(''Main_Callback'',gcbo,''action-epi'',[])',...
    'TooltipString','',...
    'Tag','EpiActionCmb','FontWeight','Bold');
% uicontrol(...
%     'Parent',hMain,'Style','pushbutton',...
%     'Units','char','Position',[IMGXOFFS+IMGW+7+35 IMGYOFFS-2.5 14 1.5],...
%     'String','EPI-rect','FontWeight','bold','fontsize',9,...
%     'HorizontalAlignment','left',...
%     'TooltipString','draw a rectangle',...
%     'Callback','mimgcropping(''Main_Callback'',gcbo,''getrect-epi'',[])');
EpiRectEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFFS+IMGW+7+50, IMGYOFFS-2.5 20 1.5],...
    'Callback','mimgcropping(''Main_Callback'',gcbo,''set-rect-epi'',guidata(gcbo))',...
    'String','','Tag','EpiRectEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','epi crop [xmin ymin width height]',...
    'FontWeight','bold');






% get widgets handles at this moment
HANDLES = findobj(hMain);


% INITIALIZE THE APPLICATION
setappdata(hMain,'Ses',Ses);
setappdata(hMain,'grp',grp);
setappdata(hMain,'ExpNo',ExpNo);
setappdata(hMain,'EPI',[]);
setappdata(hMain,'ANA',[]);

Main_Callback(AnaAxs,'init');
set(hMain,'visible','on');

% NOW SET "UNITS" OF ALL WIDGETS AS "NORMALIZED".
HANDLES = HANDLES(find(HANDLES ~= hMain));
set(HANDLES,'units','normalized');

% RETURNS THE WINDOW HANDLE IF REQUIRED.
if nargout,
  varargout{1} = hMain;
end




return



% ==================================================================
function Main_Callback(hObject,eventdata,handles)
% ==================================================================
wgts = guihandles(hObject);

switch lower(eventdata),
 case {'init'}
  Main_Callback(hObject,'load-ana',[]);
  Main_Callback(hObject,'load-epi',[]);
  
 case {'load-epi'}
  EPIFILE = get(wgts.EpiFileEdt,'String');
  if exist(EPIFILE,'file')
    fprintf(' reading epi...');
    EPI = sub_ReadData(EPIFILE);
    fprintf(' done.\n');
    
    minv = min(EPI.avr(:));
    maxv = max(EPI.avr(:))*1.2;
    if maxv > 10,
      minv = floor(minv/10)*10;
      maxv = floor(maxv/10)*10;
    end
    set(wgts.EpiScaleEdt,'String',sprintf('%g   %g   1.5',minv,maxv));

    N = size(EPI.dat,3);
    iSlice = round(N/2);
    set(wgts.EpiSliceTxt, 'String',sprintf('%d',iSlice));
    set(wgts.EpiSliceSldr,'Min',1,'Max',N+0.01,'Value',iSlice);
    set(wgts.EpiSliceSldr,'SliderStep',[1, 2]/max(1,N-1));
    
    tmptxt = sprintf('[%s]  vox=[%s]mm',...
                     deblank(sprintf('%d ',EPI.size)),...
                     deblank(sprintf('%g ',EPI.ds)));
    if isfield(EPI,'imgp') && ~isempty(EPI.imgp),
      tmptxt = sprintf('%s  Ts=%gs',tmptxt,EPI.imgp.imgtr);
    end
    set(wgts.EpiInfoTxt,'String',tmptxt);

    set(wgts.EpiRectEdt,'String',sprintf('1  1  %d  %d',size(EPI.dat,1),size(EPI.dat,2)));
  else
    EPI = [];
    set(wgts.EpiInfoTxt,'String','not found');
  end
  setappdata(wgts.main,'EPI',EPI);
  Main_Callback(hObject,'redraw-epi',[]);
  
 case {'load-ana'}
  ANAFILE = get(wgts.AnaFileEdt,'String');
  if exist(ANAFILE,'file')
    fprintf(' reading ana...');
    ANA = sub_ReadData(ANAFILE);
    fprintf(' done.\n');

    minv = min(ANA.avr(:));
    maxv = max(ANA.avr(:))*2.0;
    if maxv > 10,
      minv = floor(minv/10)*10;
      maxv = floor(maxv/10)*10;
    end
    set(wgts.AnaScaleEdt,'String',sprintf('%g   %g   1.5',minv,maxv));

    N = size(ANA.dat,3);
    iSlice = round(N/2);
    set(wgts.AnaSliceTxt, 'String',sprintf('%d',iSlice));
    set(wgts.AnaSliceSldr,'Min',1,'Max',N+0.01,'Value',iSlice);
    set(wgts.AnaSliceSldr,'SliderStep',[1, 2]/max(1,N-1));
    
    tmptxt = sprintf('[%s]  vox=[%s]mm',...
                     deblank(sprintf('%d ',ANA.size)),...
                     deblank(sprintf('%g ',ANA.ds)));
    set(wgts.AnaInfoTxt,'String',tmptxt);
    
    set(wgts.AnaRectEdt,'String',sprintf('1  1  %d  %d',size(ANA.dat,1),size(ANA.dat,2)));
  else
    ANA = [];
    set(wgts.AnaInfoTxt,'String','not found');
  end
  setappdata(wgts.main,'ANA',ANA);
  Main_Callback(hObject,'redraw-ana',[]);
  
  
 case {'redraw'}
  Main_Callback(hObject,'redraw-epi',[]);
  Main_Callback(hObject,'redraw-ana',[]);
  
 case {'redraw-epi'}
  sub_DrawImage(wgts,'EPI');
  set(wgts.EpiAxs,'tag','EpiAxs');
  
 case {'redraw-ana'}
  sub_DrawImage(wgts,'ANA');
  set(wgts.AnaAxs,'tag','AnaAxs');

 case {'slice-epi'}
  set(wgts.EpiImageCmb,'value',1);
  sub_DrawImage(wgts,'EPI');
  
 case {'slice-ana'}
  set(wgts.AnaImageCmb,'value',1);
  sub_DrawImage(wgts,'ANA');


 case {'grid-epi'}
  hAxs = wgts.EpiAxs;
  if get(wgts.EpiGridCheck,'value') > 0,
    set(hAxs,'xgrid','on','ygrid','on','layer','top');
  else
    set(hAxs,'xgrid','off','ygrid','off','layer','top');
  end
  
 case {'grid-ana'}
  hAxs = wgts.AnaAxs;
  if get(wgts.AnaGridCheck,'value') > 0,
    set(hAxs,'xgrid','on','ygrid','on','layer','top');
  else
    set(hAxs,'xgrid','off','ygrid','off','layer','top');
  end
  
 
 case {'action-epi'}
  ActionStr = get(wgts.EpiActionCmb,'String');
  ActionStr = ActionStr{get(wgts.EpiActionCmb,'value')};
  set(wgts.main,'CurrentAxes',wgts.EpiAxs);
  set(wgts.EpiActionCmb,'Enable','off');
  switch lower(ActionStr)
   case {'rectangle'}
    rect = getrect(wgts.EpiAxs);
    if ~isempty(rect),
      rect = round(rect);
      set(wgts.EpiRectEdt,'String',sprintf('%d  %d  %d  %d',rect(1),rect(2),rect(3),rect(4)));
      Main_Callback(hObject,'set-rect-epi',[]);
    end
   case {'coordinate'}
    while 1
      tmpxy = ginput(1);
      % check right-click
      click = get(wgts.main,'SelectionType');
      if strcmpi(click,'alt'),  break;  end
      % if empty, break
      if isempty(tmpxy),  break;  end
      % print-out the value
      if wgts.EpiAxs == gca
        tmpz = round(get(wgts.EpiSliceSldr,'Value'));
        fprintf('  EPI_XYZ=[%g %g %g]\n',tmpxy(1),tmpxy(2),tmpz);
      else
        tmpz = round(get(wgts.AnaSliceSldr,'Value'));
        fprintf('  ANA_XYZ=[%g %g %g]\n',tmpxy(1),tmpxy(2),tmpz);
      end
    end
  end
  set(wgts.EpiActionCmb,'Enable','on');
  set(wgts.EpiActionCmb,'value',1);
  
 case {'action-ana'}
  ActionStr = get(wgts.AnaActionCmb,'String');
  ActionStr = ActionStr{get(wgts.AnaActionCmb,'value')};
  set(wgts.main,'CurrentAxes',wgts.AnaAxs);
  set(wgts.AnaActionCmb,'Enable','off');
  switch lower(ActionStr)
   case {'rectangle'}
    rect = getrect(wgts.AnaAxs);
    if ~isempty(rect),
      rect = round(rect);
      set(wgts.AnaRectEdt,'String',sprintf('%d  %d  %d  %d',rect(1),rect(2),rect(3),rect(4)));
      Main_Callback(hObject,'set-rect-ana',[]);
    end
   case {'coordinate'}
    while 1
      tmpxy = ginput(1);
      % check right-click
      click = get(wgts.main,'SelectionType');
      if strcmpi(click,'alt'),  break;  end
      % if empty, break
      if isempty(tmpxy),  break;  end
      % print-out the value
      if wgts.EpiAxs == gca
        tmpz = round(get(wgts.EpiSliceSldr,'Value'));
        fprintf('  EPI_XYZ=[%g %g %g]\n',tmpxy(1),tmpxy(2),tmpz);
      else
        tmpz = round(get(wgts.AnaSliceSldr,'Value'));
        fprintf('  ANA_XYZ=[%g %g %g]\n',tmpxy(1),tmpxy(2),tmpz);
      end
    end
  end
  set(wgts.AnaActionCmb,'Enable','on');
  set(wgts.AnaActionCmb,'value',1);
 
 
 case {'getrect-epi'}
  set(wgts.main,'CurrentAxes',wgts.EpiAxs);
  rect = getrect(wgts.EpiAxs);
  if ~isempty(rect),
    rect = round(rect);
    set(wgts.EpiRectEdt,'String',sprintf('%d  %d  %d  %d',rect(1),rect(2),rect(3),rect(4)));
    Main_Callback(hObject,'set-rect-epi',[]);
  end
 
 case {'getrect-ana'}
  set(wgts.main,'CurrentAxes',wgts.AnaAxs);
  rect = getrect(wgts.AnaAxs);
  if ~isempty(rect),
    rect = round(rect);
    set(wgts.AnaRectEdt,'String',sprintf('%d  %d  %d  %d',rect(1),rect(2),rect(3),rect(4)));
    Main_Callback(hObject,'set-rect-ana',[]);
  end
  
 case {'set-rect-epi'}
  EPI = getappdata(wgts.main,'EPI'); 
  ANA = getappdata(wgts.main,'ANA'); 
  rect = str2num(get(wgts.EpiRectEdt,'String'));
  if length(rect) == 4,
    tmpx = (rect(1)-1)*EPI.ds(1);
    tmpy = (rect(2)-1)*EPI.ds(2);
    tmpw = rect(3)*EPI.ds(1);
    tmph = rect(4)*EPI.ds(2);
    
    newx = round(tmpx/ANA.ds(1)) + 1;
    newy = round(tmpy/ANA.ds(2)) + 1;
    neww = round(tmpw/ANA.ds(1));
    newh = round(tmph/ANA.ds(2));
    
    set(wgts.AnaRectEdt,'String',sprintf('%d  %d  %d  %d',newx,newy,neww,newh));
    Main_Callback(hObject,'redraw',[]);
  end
  
 case {'set-rect-ana'}
  EPI = getappdata(wgts.main,'EPI'); 
  ANA = getappdata(wgts.main,'ANA'); 
  rect = str2num(get(wgts.AnaRectEdt,'String'));
  if length(rect) == 4,
    tmpx = (rect(1)-1)*ANA.ds(1);
    tmpy = (rect(2)-1)*ANA.ds(2);
    tmpw = rect(3)*ANA.ds(1);
    tmph = rect(4)*ANA.ds(2);
    
    newx = round(tmpx/EPI.ds(1)) + 1;
    newy = round(tmpy/EPI.ds(2)) + 1;
    neww = round(tmpw/EPI.ds(1));
    newh = round(tmph/EPI.ds(2));
    
    set(wgts.EpiRectEdt,'String',sprintf('%d  %d  %d  %d',newx,newy,neww,newh));
    Main_Callback(hObject,'redraw',[]);
  end
  
  
 otherwise
  fprintf('WARNING %s: Main_Callback() ''%s'' not supported yet.\n',mfilename,eventdata);
  
end

return



% ==================================================================
function SIG = sub_ReadData(FILENAME)
% ==================================================================

[fp fr fe] = fileparts(FILENAME);
if strcmpi(fr,'2dseq')
  [img imgp] = pvread_2dseq(FILENAME);
  SIG.format = '2dseq';
  SIG.size = size(img);
  SIG.dat  = single(img);
  SIG.dat  = nanmean(SIG.dat,4);
  SIG.ds   = imgp.dimsize(1:3);
  SIG.imgp = imgp;
  SIG.avr  = squeeze(nanmean(SIG.dat,3));
elseif any(strcmpi(fe,{'.img' '.hdr'}))
  [img hdr] = anz_read(FILENAME);
  SIG.format = 'analyze';
  SIG.size = size(img);
  SIG.dat  = single(img);
  SIG.dat  = nanmean(SIG.dat,4);
  SIG.ds   = hdr.dime.pixdim(1:3);
  SIG.hdr  = hdr;
  SIG.avr  = squeeze(nanmean(SIG.dat,3));
else
  fprintf(' unknown format....');
  SIG = [];
end

return


% ==================================================================
function sub_DrawImage(wgts,TYPE)
% ==================================================================
if strcmpi(TYPE,'epi')
  hAxs = wgts.EpiAxs;
  SIG = getappdata(wgts.main,'EPI'); 
  iSlice = round(get(wgts.EpiSliceSldr,'Value'));
  SCALE  = str2num(get(wgts.EpiScaleEdt,'String'));
  GAMMA  = 1.5;
  if length(SCALE) > 2,  GAMMA = SCALE(3);  end
  METHOD = get(wgts.EpiImageCmb,'String');
  METHOD = METHOD{get(wgts.EpiImageCmb,'Value')};
  set(wgts.EpiSliceTxt, 'String',sprintf('%d',iSlice));
  rect = str2num(get(wgts.EpiRectEdt,'String'));
  GridOn = get(wgts.EpiGridCheck,'value');
else
  hAxs = wgts.AnaAxs;
  SIG = getappdata(wgts.main,'ANA');
  ANA = getappdata(wgts.main,'ANA');
  iSlice = round(get(wgts.AnaSliceSldr,'Value'));
  SCALE  = str2num(get(wgts.AnaScaleEdt,'String'));
  GAMMA  = 1.5;
  if length(SCALE) > 2,  GAMMA = SCALE(3);  end
  METHOD = get(wgts.AnaImageCmb,'String');
  METHOD = METHOD{get(wgts.AnaImageCmb,'Value')};
  set(wgts.AnaSliceTxt, 'String',sprintf('%d',iSlice));
  rect = str2num(get(wgts.AnaRectEdt,'String'));
  GridOn = get(wgts.AnaGridCheck,'value');
end

if isempty(SIG),  return;  end

set(wgts.main,'CurrentAxes',hAxs);
cla;
if strcmpi(METHOD,'slice')
  tmpimg = squeeze(SIG.dat(:,:,iSlice));
else
  tmpimg = SIG.avr;
end
if ~isempty(SCALE),
  minv = SCALE(1);  maxv = SCALE(2);
  cmap = gray(256).^(1/GAMMA);
  tmpimg = double(tmpimg);
  tmpimg = (tmpimg - minv) / (maxv - minv);
  tmpimg(tmpimg(:) < 0) = 0;
  tmpimg(tmpimg(:) > 1) = 1;
  tmpimg = uint8(round(tmpimg*255));
  tmpimg = ind2rgb(tmpimg,cmap);
  image(permute(tmpimg,[2 1 3]));
else
  imagesc(tmpimg');
end
set(gca,'fontsize',5);
set(gca,'xcolor',[0.8 0 0.8],'ycolor',[0.8 0 0.8]);
set(gca,'xlim',[0.5 size(tmpimg,1)+0.5],'ylim',[0.5 size(tmpimg,2)+0.5]);

if any(GridOn),
  set(gca,'xgrid','on','ygrid','on','layer','top');
else
  set(gca,'xgrid','off','ygrid','off','layer','top');
end


if length(rect) == 4,
  hold on;
  rectangle('position',[rect(1)-0.5 rect(2)-0.5 rect(3) rect(4)],...
            'edgecolor',[1 1 0],'facecolor','none','linewidth',2);
end  

daspect(hAxs,[2 2 1]);

if isfield(SIG,'imgp') && isfield(SIG.imgp,'PULPROG'),
  PULPROG = SIG.imgp.PULPROG;
  PULPROG = strrep(PULPROG,'<','');
  PULPROG = strrep(PULPROG,'>','');
  PULPROG = strrep(PULPROG,'.ppg','');
  if ~isempty(PULPROG),
    text(0.02,0.97,PULPROG,'units','normalized','color',[0.7 0.7 0],'fontweight','bold');
  end
end


if strcmpi(TYPE,'epi')
  set(hAxs,'tag','EpiAxs');
else
  set(hAxs,'tag','AnaAxs');
end

return



% ==================================================================
% FUNCTION to get screen size
% ==================================================================
function [scrW scrH] = subGetScreenSize(Units)
oldUnits = get(0,'Units');
set(0,'Units',Units);
sz = get(0,'ScreenSize');
set(0,'Units',oldUnits);

scrW = sz(3);  scrH = sz(4);

return;
