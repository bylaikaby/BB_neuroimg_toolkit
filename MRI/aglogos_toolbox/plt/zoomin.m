function varargout = zoomin(varargin)
%ZOOMIN - plots the selected axes to the new window.
%  ZOOMIN(SrcAxs,[Dst]) copies "SrcAxs" to "Dst".
%  If "Dst" is not given, then create a new figure and axes.
%  H = ZOOMIN(SrcAxs,[Dst]) does the same thing but returns the handle of new axes.
%
%  Note that if "Dst" is a handle of axes, then source axes will be 
%  fit into the "Dst" positon and size, then "Dst" will be deleted.
%  In this case, the handle "Dst" will be no longer useful.  
%
%  EXAMPLE :
%    >> figure; imagesc(rand(10,10));   % plot the source data
%    >> hsrc = gca;                     % keep the handle of the axes
%    >> zoomin(hsrc);                   % zoomin "hsrc"
%    >> figure;  hdst = subplot(221);   % create destination
%    >> zoomin(hsrc,hdst);              % zoomin "hsrc" into "hdst" and delete "hdst".
%
%  VERSION :
%    0.90 30.11.05 YM  pre-release
%
%  See also COPYOBJ

if nargin == 0,  eval(sprintf('help %s;',mfilename));  return;  end

POS = [];
hsrc = varargin{1};
if nargin == 1,
  % called like "zoomin(hsrc)", create a new figure;
  hfig = figure;
else
  % called like "zoomin(hsrc,hdst)", get the destination figure.
  if strcmpi(get(varargin{2},'type'),'axes'),
    DstAxs = varargin{2};
    hfig = get(DstAxs,'Parent');
    POS  = get(DstAxs,'pos');
    UNI  = get(DstAxs,'units');
  else
    hfig = varargin{2};
  end
end

% copy also the color map.
haxs = copyobj(hsrc,hfig);
set(hfig,'colormap',get(get(hsrc,'parent'),'colormap'));


% clear any call-back functions.
h = get(haxs,'Children');
set([gca,h(:)'],'ButtonDownFcn','');


% fit the size to "destination" axes
if ~isempty(POS),
  olduni = get(haxs,'units');		% keep the "unit"
  set(haxs,'pos',POS,'units',UNI);  % fit the size
  set(haxs,'units',olduni);			% back to the original "unit"
  if ishandle(DstAxs),
    delete(DstAxs);
  end
end


if nargout,
  varargout{1} = haxs;
end


return;
