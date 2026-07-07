function qview(varargin)
%QVIEW - Displays the tcImg data
% QVIEW (SesName, ExpNo) shows the data of experiment ExpNo
% QVIEW (SesName, GrpName) shows the GrpName structure in tcImg.mat 
% QVIEW (ScanDir, ScanNo) load a 2dseq file from ScanDir/ScanNo
% QVIEW (tcImg) displays the dat field of the structure

if nargin < 1,
  help qview;
  return;
end;

persistent hsingleton;	% keep the figure handle.

myinput = varargin{1};

% Check if program is active and input is the name of a callback
% if yes, execute callback function then return;
if isstr(myinput) & ~isempty(findstr(myinput,'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return;
else
  % FIRST INPUT
  if isa(varargin{1},'char') & findstr(varargin{1},'.'),
    tcImg = scanload(varargin{:});
  elseif isstruct(varargin{1}),
    tcImg = varargin{1};
  elseif isnumeric(varargin{1}),
    tcImg.dat = varargin{1};
    tcImg.ds = [1 1 1];
  elseif isa(varargin{1},'char'),
    SesName = varargin{1};
    if nargin < 2,
      help qview;
      return;
    end;
    if isa(varargin{2},'char'),
      GrpName = varargin{2};
      if ~exist('tcImg.mat','file'),
        fprintf('QVIEW: tcImg.mat file was not found\n');
        return;
      end;
      tcImg = matsigload('tcImg.mat',GrpName);
      if isempty(tcImg),
        fprintf('QVIEW: %s was not found in tcImg.mat\n',GrpName);
        return;
      end;
    elseif isa(varargin{2},'double'),
      ExpNo = varargin{2};
      tcImg = sigload(SesName,ExpNo,'tcImg');
    else
      fprintf('QVIEW: cannot parse input arguments\n');
    end;
  end;
end

if size(tcImg.dat,4)==1,
  s=size(tcImg.dat);
  tcImg.dat = reshape(tcImg.dat,[s(1) s(2) 1 s(3)]);
end;

if ishandle(hsingleton),
  close(hsingleton);
end

hMain = figure(...
    'Name','Quick VIEW of tcImg data','NumberTitle','off', ...
    'Tag','main', 'MenuBar', 'none', ...
    'HandleVisibility','on','Resize','off',...
    'DoubleBuffer','on', 'BackingStore','on','Visible','off',...
    'Position',[50 50 900 800],'UserData',[900 800],...
    'units','normalized','Color',[.1 .1 .2],'DefaultAxesfontsize',10,...
    'DefaultAxesFontName', 'Comic Sans MS',...
    'DefaultAxesfontweight','bold');
hsingleton = hMain;

SliceBarTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','normalized','Position',[0.01 0.02 0.14 0.03],...
    'String','Time Point: 1','FontWeight','bold','FontSize',9,...
    'ForegroundColor','r','HorizontalAlignment','left','Tag','SliceBarTxt',...
    'BackgroundColor',get(hMain,'Color'));
SliceBarSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','normalized','Position',[0.15 0.02 0.83 0.03],...
    'Callback','qview(''Main_Callback'',gcbo,''slice-slider'',[])',...
    'Tag','SliceBarSldr','SliderStep',[1 4],...
    'TooltipString','Set current slice');

set(hMain,'Visible','on');

if nargout,
  varargout{1} = hMain;
end;

%% INITIALIZE
TimePoint = 1;

ImgAxs = subplot('position',[.1 .15 .9 .8]);

wgts = guihandles(hMain);
setappdata(wgts.main,'tcImg',tcImg);
setappdata(wgts.main,'ImgAxs',ImgAxs);
qview('Main_Callback',hMain,'init');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Main_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOW GET ALL WIDGETS, GLOBALS, AND ROINAMES
wgts = guihandles(hObject);
tcImg  = getappdata(wgts.main,'tcImg');
ImgAxs  = getappdata(wgts.main,'ImgAxs');

switch lower(eventdata),
 case {'init'}
  nslices = size(tcImg.dat,4);
  range = [1 nslices];
  if nslices < 2,
    slideStep(1) = 0.0000001; slideStep(2) = 1.1;
    nslices = 1.1;
  else
    slideStep(1) = 1/(range(2)-range(1));
    slideStep(2) = 5/(range(2)-range(1));
  end;
  set(wgts.SliceBarSldr,'Min',1,'Max',nslices,...
                    'SliderStep',slideStep,'Value',1);
  Main_Callback(wgts.SliceBarSldr,'slice-slider',[]);

 case {'slice-slider'}
  SLICE = round(get(wgts.SliceBarSldr,'Value'));
  set(wgts.SliceBarTxt,'String',sprintf('Time Point: %d',SLICE));
  figure(wgts.main);
  axes(ImgAxs);
  imagesc(mgetcollage(tcImg.dat(:,:,:,SLICE))');
  % img = mgetcollage(tcImg.dat(:,:,:,SLICE));
  % imagesc(imadjust(img'/max(img(:)),[0 0.95],[0 1],0.75));
  colormap(gray);
  daspect([1 1 1]);
  set(gca,'xtick',[],'ytick',[]);
  set(gca,'box','on','xcolor','r','ycolor','r');

 otherwise
end
return;

