function varargout = figtitle(titlestr,varargin)
%FIGTITLE - puts a titile to the current figure window
%  H = FIGTITLE(TITLESTR,...) puts a title to the current figure window and
%  returns its handle.
%
%  EXAMPLE :
%    figtitle('mytitle','color','red');
%
%  VERSION :
%    0.90 11.10.05 YM  pre-release
%    0.91 12.10.05 YM  makes 'special' axes invisible.
%
%  See also FIGLABEL, TITLE, TEXT

if nargin == 0,  help figtitle; return;  end

% SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SPECIAL_AXES_TAG = 'XXXmylabelXXX';
SPECIAL_TITLE_TAG = 'XXXmytitleXXX';

OPTS = { 'Tag',SPECIAL_TITLE_TAG,...
         'Units','normalized',...
         'FontName','Comic Sans MS',...
         'FontSize',10,...
         'FontWeight','normal',...
         'HorizontalAlignment','center','VerticalAlignment','top' };

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
titlestr = strrep(titlestr,'_','\_');
htxt = findobj(gcf,'type','text','tag',SPECIAL_TITLE_TAG);
if isempty(htxt),
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
  htxt = feval(@text, 0.5, 0.97, titlestr, OPTS{:});
else
  if nargin == 1,
    set(htxt,'string',titlestr);
  else
    feval(@set,htxt,'string',titlestr,varargin{:});
  end
end
set(htxt,'tag',SPECIAL_TITLE_TAG);
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
