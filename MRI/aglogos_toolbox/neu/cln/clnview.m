function varargout = clnview(varargin)
%CLNVIEW - displays adf/cln spectrum
%  CLNVIEW(SESSION,GRPNAME) displays adf/cln spectrum.
%
%
%  VERSION :
%    0.90 29.09.11 YM  pre-release
%
%  See also adf_read clnmain clnadf


if nargin == 0,  help clnview; return;  end

% execute callback function then return;
if ischar(varargin{1}) && ~isempty(findstr(varargin{1},'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return;
end



ANAP.adffile  = '';
ANAP.clnfile  = '';
ANAP.physchan = [];
ANAP.gradchan = [];
ANAP.spc      = 'spectrogram';
ANAP.spc_twin = 2.0;

if nargin > 1 && isnumeric(varargin{2}),
  % called like clnview(Ses,ExpNo)
  Ses = getses(varargin{1});
  ExpNo = varargin{2}(1);
  grp = getgrp(Ses,ExpNo);
  if ~isrecording(Ses,ExpNo),
    fprintf('%s ERROR: %s ExpNo=%d  not recording.\n',mfilename,Ses.name,ExpNo);
    return;
  end
  
  ANAP.adffile = catfilename(Ses,ExpNo,'adfw');
  ANAP.clnfile = catfilename(Ses,ExpNo,'cln');
  ANAP.physchan = grp.hardch;
  ANAP.gradchan = grp.gradch;
else
  Ses = [];
  ExpNo = [];
end




% GET SCREEN SIZE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[scrW scrH] = subGetScreenSize('char');
% 288x60.3 char. for 1440x900 pixels
% 320x92.3 char. for 1600x1200
figW = 175; figH = 55;
figX = 2;  figY = scrH-figH-6;


% CREATE A MAIN FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hMain = figure(...
    'Name',sprintf('%s %s',mfilename,datestr(now)),...
    'NumberTitle','off', 'toolbar','figure',...
    'Tag','main', 'units','char', 'pos',[figX figY figW figH],...
    'HandleVisibility','on', 'Resize','on',...
    'DoubleBuffer','on', 'BackingStore','on', 'Visible','on',...
    'DefaultAxesFontSize',10,...
    'DefaultAxesfontweight','bold',...
    'PaperPositionMode','auto', 'PaperType','A4', 'PaperOrientation', 'landscape');
BKGCOL = get(hMain,'color');




% WIDGETS FOR ADF/ADFW %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XDSP = 3; H = figH - 2.5;
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H-0.3 30 1.5],...
    'String','ADF:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','AdfTxt',...
    'BackgroundColor',get(hMain,'Color'));
AdfFileEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+7 H 100 1.5],...
    'Callback','clnview(''Main_Callback'',gcbo,''adf-init'',guidata(gcbo))',...
    'String',ANAP.adffile,'Tag','AdfFileEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','adf/adfwfile',...
    'FontWeight','Bold');
tmptxt = {'average'};
for N = 1:length(ANAP.physchan),
  tmptxt{end+1} = sprintf('%d',ANAP.physchan(N));
end
AdfChanCmb = uicontrol(...
   'Parent',hMain,'Style','Popupmenu',...
   'Units','char','Position',[XDSP+108 H 17 1.5],...
   'Callback','clnview(''Main_Callback'',gcbo,''adf-proc'',guidata(gcbo))',...
   'String',tmptxt,'Tag','AdfChanCmb','Value',1,...
   'TooltipString','Select a channel',...
   'FontWeight','bold');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+128 H-0.3 30 1.5],...
    'String','GRA:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','GraTxt',...
    'BackgroundColor',get(hMain,'Color'));
GraChanEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+135 H 10 1.5],...
    'Callback','clnview(''Main_Callback'',gcbo,''gra-read'',guidata(gcbo))',...
    'String',num2str(ANAP.gradchan),'Tag','GraChanEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','gradient channel',...
    'FontWeight','Bold');



% WIDGETS FOR CLN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XDSP = 3; H = figH - 4.5;
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H-0.3 30 1.5],...
    'String','CLN:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','ClnTxt',...
    'BackgroundColor',get(hMain,'Color'));
ClnFileEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+7 H 100 1.5],...
    'Callback','clnview(''Main_Callback'',gcbo,''cln-init'',guidata(gcbo))',...
    'String',ANAP.clnfile,'Tag','ClnFileEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','clnfile',...
    'FontWeight','Bold');
ClnChanCmb = uicontrol(...
   'Parent',hMain,'Style','Popupmenu',...
   'Units','char','Position',[XDSP+108 H 17 1.5],...
   'Callback','clnview(''Main_Callback'',gcbo,''cln-proc'',guidata(gcbo))',...
   'String',{'average'},'Tag','ClnChanCmb','Value',1,...
   'TooltipString','Select a channel',...
   'FontWeight','bold');


% WIDGETS FOR SPC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XDSP = 3; H = figH - 6.5;
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H-0.3 30 1.5],...
    'String','SPC:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','SpcTxt',...
    'BackgroundColor',get(hMain,'Color'));
SpcMethodCmb = uicontrol(...
   'Parent',hMain,'Style','Popupmenu',...
   'Units','char','Position',[XDSP+7 H 22 1.5],...
   'Callback','clnview(''Main_Callback'',gcbo,''spc-proc'',guidata(gcbo))',...
   'String',{'spectrogram','pwelch','fft'},'Tag','SpcMethodCmb','Value',1,...
   'TooltipString','Select a method',...
   'FontWeight','bold');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+32 H-0.3 30 1.5],...
    'String','Twin(s):','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','TWinTxt',...
    'BackgroundColor',get(hMain,'Color'));
SpcTWinEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+43 H 15 1.5],...
    'Callback','clnview(''Main_Callback'',gcbo,''spc-proc'',guidata(gcbo))',...
    'String',num2str(1.0),'Tag','SpcTWinEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','Time window (s)',...
    'FontWeight','Bold');

SpcRunBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[XDSP+65 H 12 1.5],...
    'Callback','clnview(''Main_Callback'',gcbo,''spc-proc'',guidata(gcbo))',...
    'Tag','SpcRunBtn','String','Run SPC','FontWeight','bold',...
    'TooltipString','Compute spc',...
    'BackgroundColor',[0.5 0.8 0.8],'ForegroundColor',[0 0 0]);



% AXES FOR SINGLE VIEW %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XDSP = 10;  H = 5;  XSZ = figW-2*XDSP;  YSZ = figH - H - 10;
SingleViewAxs = axes(...
    'Parent',hMain,'Tag','ViewAxs',...
    'Units','char','Position',[XDSP H XSZ YSZ],...
    'Box','off','Visible','on','FontWeight','bold');

% STATUS MESSAGING
StatusFrame = axes(...
    'Parent',hMain,'Units','char','color',get(hMain,'color'),'xtick',[],...
    'ytick',[],'Position',[XDSP 0.35 XSZ 1.8],...
    'Box','on','linewidth',1,'xcolor',[0.5 0 0.5],'ycolor',[0.5 0 0.5],...
    'color',BKGCOL);
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+1.5 0.35 11 1.5],...
    'String','Status : ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
StatusField = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+12 0.65 figW-12*2-10 1.2],...
    'String','ready','FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left','Tag','StatusField','BackgroundColor',BKGCOL);




% get widgets handles at this moment
HANDLES = findobj(hMain);


% INITIALIZE THE APPLICATION
setappdata(hMain,'SES',Ses);
setappdata(hMain,'ExpNo',ExpNo);
Main_Callback(hMain,'init');
set(hMain,'visible','on');



% NOW SET "UNITS" OF ALL WIDGETS AS "NORMALIZED".
HANDLES = HANDLES(HANDLES ~= hMain);
set(HANDLES,'units','normalized');


% RETURNS THE WINDOW HANDLE IF REQUIRED.
if nargout,
  varargout{1} = hMain;
end

return






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Main_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(hObject);

switch lower(eventdata),
 case {'init'}
  Main_Callback(wgts.main,'adf-init');
  Main_Callback(wgts.main,'cln-init');
  
 case {'adf-init'}
  ADFFILE = get(wgts.AdfFileEdt,'String');
  if isempty(ADFFILE),  return;  end
  if ~exist(ADFFILE,'file'),
    set(wgts.StatusField,'String',sprintf('ERROR : adffile not found.'));
    return
  end
  if isempty(getappdata(wgts.main,'SES')),
    [nchan nobs sampt obslens] = adf_info(ADFFILE);
    GRACH = nchan;
    [fp fr fe] = fileparts(ADFFILE);
    ADFFILE2 = fullfile(fp,sprintf('%s_2%s',fr,fe));
    if exist(ADFFILE2,'file'),
      [nchan2 nobs sampt obslens] = adf_info(ADFFILE2);
      nchan = nchan + nchan2;
    end
    tmptxt = {'average'};
    for N = 1:nchan,
      tmptxt{end+1} = sprintf('%d',N);
    end
    set(wgts.AdfChanCmb,'String',tmptxt,'Value',1);
    set(wgts.GraChanEdt,'String',sprintf('%d',max(GRACH,1)));
  end
  
 case {'adf-proc'}
  CH = get(wgts.AdfChanCmb,'String');
  CH = CH{get(wgts.AdfChanCmb,'value')};
  if any(strcmpi(CH,'average')),
    tmpstr = get(wgts.AdfChanCmb,'String');
    tmpch = [];
    for N = 1:length(tmpstr),
      tmpv = str2double(tmpstr{N});
      if any(tmpv),  tmpch(end+1) = tmpv;  end
    end
    GRA = str2double(get(wgts.GraChanEdt,'String'));
    tmpch(tmpch == GRA) = [];
    CH = tmpch;
  else
    CH = str2double(CH);
  end
  
  for N = 1:length(CH),
    set(wgts.StatusField,'String',sprintf('ADF reading(%d)...',CH(N))); drawnow;
    SIG = sub_adfread(wgts,CH(N));
    set(wgts.StatusField,'String',sprintf('%s spc.',get(wgts.StatusField,'String'))); drawnow;
    tmp = sub_spc(wgts,SIG,'adf');
    if N == 1,
      SPC = tmp;
    else
      SPC.dat = cat(3,SPC.dat,tmp.dat);
    end
  end
  set(wgts.StatusField,'String',sprintf('%s plot.',get(wgts.StatusField,'String'))); drawnow;
  sub_plot(wgts,SPC);
  set(wgts.StatusField,'String',sprintf('%s done.',get(wgts.StatusField,'String'))); drawnow;

  
 case {'gra-proc'}
  CH = str2double(get(wgts.GraChanEdt,'String'));
  set(wgts.StatusField,'String',sprintf('GRA reading(%d)...',CH)); drawnow;
  SIG = sub_adfread(wgts,CH);
  set(wgts.StatusField,'String',sprintf('%s spc.',get(wgts.StatusField,'String'))); drawnow;
  SPC = sub_spc(wgts,SIG,'gra');
  set(wgts.StatusField,'String',sprintf('%s plot.',get(wgts.StatusField,'String'))); drawnow;
  sub_plot(wgts,SPC);
  set(wgts.StatusField,'String',sprintf('%s done.',get(wgts.StatusField,'String'))); drawnow;
 
 case {'cln-init'}
  set(wgts.StatusField,'String',sprintf('CLN reading...')); drawnow;
  CLNFILE = get(wgts.ClnFileEdt,'String');
  if isempty(CLNFILE),  return;  end
  if ~exist(CLNFILE,'file'),
    set(wgts.StatusField,'String',sprintf('ERROR : Cln not found.'));
    return
  end
  CLN = load(CLNFILE,'Cln');
  CLN = CLN.Cln;
  if isfield(CLN,'dxorg'),
    CLN.dx = CLN.dxorg;
  end
  
  tmptxt = {'average'};
  for N = 1:size(CLN.dat,2),
    tmptxt{end+1} = sprintf('%d',N);
  end
  set(wgts.ClnChanCmb,'String',tmptxt,'Value',1);
  set(wgts.StatusField,'String',sprintf('%s done.',get(wgts.StatusField,'String'))); drawnow;
  
  setappdata(wgts.main,'CLN',CLN);
  
 case {'cln-proc'}
  CLN = getappdata(wgts.main,'CLN');
  
  CH = get(wgts.ClnChanCmb,'String');
  CH = CH{get(wgts.ClnChanCmb,'value')};
  if any(strcmpi(CH,'average')),
    tmpstr = get(wgts.ClnChanCmb,'String');
    tmpch = [];
    for N = 1:length(tmpstr),
      tmpv = str2double(tmpstr{N});
      if any(tmpv),  tmpch(end+1) = tmpv;  end
    end
    CH = tmpch;
  else
    CH = str2double(CH);
  end
  
  for N = 1:length(CH),
    set(wgts.StatusField,'String',sprintf('CLN spc(%d)...',CH(N))); drawnow;
    SIG = CLN;
    SIG.dat = SIG.dat(:,CH(N));
    tmp = sub_spc(wgts,SIG,'Cln');
    if N == 1,
      SPC = tmp;
    else
      SPC.dat = cat(3,SPC.dat,tmp.dat);
    end
  end
  set(wgts.StatusField,'String',sprintf('%s plot.',get(wgts.StatusField,'String'))); drawnow;
  sub_plot(wgts,SPC);
  set(wgts.StatusField,'String',sprintf('%s done.',get(wgts.StatusField,'String'))); drawnow;
  
  
 case {'spc-proc'}
  Main_Callback(wgts.main,'adf-proc');
  Main_Callback(wgts.main,'gra-proc');
  Main_Callback(wgts.main,'cln-proc');

 otherwise

end


return



% ==============================================================================================
function SIG = sub_adfread(wgts,CH)
% ==============================================================================================
ADFFILE = get(wgts.AdfFileEdt,'String');
if isempty(ADFFILE),  return;  end
if ~exist(ADFFILE,'file'),
  set(wgts.StatusField,'String',sprintf('ERROR : adffile not found.'));
  return
end
[nchan nobs sampt obslens] = adf_info(ADFFILE);

if CH > nchan,
  [fp fr fe] = fileparts(ADFFILE);
  ADFFILE = fullfile(fp,sprintf('%s_2%s',fr,fe));
  CH = CH - nchan;
end


wv = adf_read(ADFFILE,0,CH-1);


SIG.dx = sampt/1000;  % in sec
SIG.dat = wv(:);

return



% ==============================================================================================
function SPC = sub_spc(wgts,SIG,NAME)
% ==============================================================================================

SPC_METHOD = get(wgts.SpcMethodCmb,'String');
SPC_METHOD = SPC_METHOD{get(wgts.SpcMethodCmb,'Value')};

TWIN_Sec = str2double(get(wgts.SpcTWinEdt,'String'));

NFFT = round(TWIN_Sec/SIG.dx);
%WinFct = 'hanning';
%WINDOW = feval(WinFct,NFFT);
WINDOW = NFFT;
NOVERLAP = 0;

Fs = 1/SIG.dx;


switch lower(SPC_METHOD),
 case {'spectrogram'}
  [s f t] = spectrogram(SIG.dat,WINDOW,NOVERLAP,NFFT,Fs);
  s = abs(s);
  s = nanmean(s,2);
 case {'pwelch'}
  [pxx f] = pwelch(SIG.dat,WINDOW,NOVERLAP,NFFT,Fs);
  s = sqrt(pxx);
end


SPC.name = NAME;
SPC.f    = f;
SPC.dat  = s(:);


return



% ==============================================================================================
function sub_plot(wgts,SPC)
% ==============================================================================================

set(wgts.main,'CurrentAxes',wgts.ViewAxs);
if any(findobj(wgts.ViewAxs,'type','line')),
  hold on;
else
end

h = findobj(wgts.ViewAxs,'tag',SPC.name);

if isempty(h),
  switch lower(SPC.name),
   case {'adf'}
    tmpcol = 'b';
   case {'gra'}
    tmpcol = 'k';
   case {'cln'}
    tmpcol = 'r';
   otherwise
    tmpcol = 'g';
  end
  plot(SPC.f,SPC.dat,'color',tmpcol,'tag',SPC.name);
  grid on;
  xlabel('Frequency (Hz)');
else
  set(h,'ydata',SPC.dat,'xdata',SPC.f);
  drawnow;
end


tmptxt = {};
hall = findobj(wgts.ViewAxs,'type','line');
for N = 1:length(hall),
  tmptxt{N} = get(hall(N),'tag');
end
legend(tmptxt);


% sometimes plotting function resets 'tag'...
set(wgts.ViewAxs,'tag','ViewAxs');

return






% ==============================================================================================
function [scrW scrH] = subGetScreenSize(Units)
% ==============================================================================================
% FUNCTION to get screen size
oldUnits = get(0,'Units');
set(0,'Units',Units);
sz = get(0,'ScreenSize');
set(0,'Units',oldUnits);
scrW = sz(3);  scrH = sz(4);
return
