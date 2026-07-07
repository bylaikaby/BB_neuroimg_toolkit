function varargout = figlabel(x,y,textstr,varargin)
%FIGLABEL - puts a text string in the figure window
%  H = FIGLABEL(X,Y,TEXTSTR,...) puts a text string in the current window and
%  returns its handle.
%
%  EXAMPLE :
%    figlabel(0.5,0.5,'testlabel','color','r');
%
%  VERSION :
%    0.90 11.10.05 YM  pre-release
%    0.91 12.10.05 YM  makes 'special' axes invisible.
%
%  See also FIGTITLE, TEXT, AXES

if nargin == 0,  help figlabel; return;  end

% SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SPECIAL_AXES_TAG = 'XXXmylabelXXX';

OPTS = { 'Units','normalized',...
         'FontName','Comic Sans MS',...
         'FontWeight','normal',...
         'HorizontalAlignment','center','VerticalAlignment','middle' };



% CHECK THE CURRENT AXES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hOld = get(gcf,'CurrentAxes');


% PREPARE A HIDDEN AXES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ShowHiddenHandles = get(0,'ShowHiddenHandles');
set(0,'ShowHiddenHandles','on');
haxs = findobj(gcf,'type','axes','tag',SPECIAL_AXES_TAG);
if isempty(haxs),
  haxs = axes('pos',[0 0 1.0 1.0],'units','normalized',...
              'visible','off','tag',SPECIAL_AXES_TAG);
end
set(0,'ShowHiddenHandles',ShowHiddenHandles);


% PUT THE TEXT STRINTG %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(haxs,'HandleVisibility','on');
set(gcf,'CurrentAxes',haxs);
textstr = strrep(textstr,'_','\_');
if nargin > 1,
  optname = OPTS(1:2:end);
  for N = 1:2:length(varargin),
    idx = find(strcmpi(optname,varargin{N}));
    if isempty(idx),
      OPTS(end+1:end+2) = varargin(N:N+1);
    else
      OPTS(2*idx) = varargin(N+1);
    end
  end
end
htxt = feval(@text, x, y, textstr, OPTS{:});
set(haxs,'HandleVisibility','off','visible','off','tag',SPECIAL_AXES_TAG);


% RESTORE THE OLD AXES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(gcf,'CurrentAxes',hOld);


% PREPARE OUTPTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout > 0,
  varargout{1} = htxt;
  if nargout > 1,
    varargout{2} = haxs;
  end
end


return;
