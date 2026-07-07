function fig = mfigure(POS,TITLE,titlecolor,titlesize,varargin)
%MFIGURE - modified figure() command w/ other defaults...
% MFIGURE(POS,TITLE,TITLECOLOR,TITLESIZE,...)
% MFIGURE(POS,TITLE,TITLECOLOR,TITLESIZE,'PropertyName',PropertyValue,...)
%
% NKL, 9.05.02

if nargin < 4,
  titlecolor = 'k';
end;

if nargin < 3,
  titlesize = 9;
end;

if nargin < 2,
  TITLE = '';
end;

if ~nargin,
  [wx,wy] = getScreenSize;
  yofs=10;
  POS = [1 yofs wx-7 wy-yofs+1];
end;


if ~isempty(POS),
f = figure('position',POS);
else
f = figure;
end

% set(gcf,'DefaultLineLineWidth',	1.5);
set(gcf,'DefaultAxesBox',		'off')
orient landscape;

if ~isempty(TITLE),
  suptitle(TITLE,titlecolor,titlesize);
end

% for better draw
set(gcf,'BackingStore','on','DoubleBuffer','on');

% check the position of the figure, due to Matlab's bug,
% sometimes the figure appears outside the monitor....
[scrW scrH] = getScreenSize;
tmpunits = get(gcf,'units');
set(gcf,'units','pixels');
pos = get(gcf,'pos');
if pos(1) > scrW | pos(1) < 0,
  pos(1) = 4;
end
if pos(2)+pos(4) > scrH | pos(2)+pos(4) < 0,
  pos(2) = scrH-pos(4)-70;  % 70 as menu/tool bar
end
set(gcf,'pos',pos);
set(gcf,'units',tmpunits);

% pass varargin as 'PropertyName',PropertyValue
if ~isempty(varargin),
  set(gcf,varargin{:});
end

% set(gcf,'DefaultAxesfontsize',	11);
% set(gcf,'DefaultAxesFontName',  'Arial Narrow');

set(gcf,'DefaultAxesfontsize', 8);
set(gcf,'DefaultAxesFontName',  'Arial Narrow');
set(gcf,'color','w');

if nargout,
  fig = f;
end;




