function varargout = addsubaxes(hax,WHERE,varargin)
%ADDSUBAXES - adds a sub-axes to the given parent axes.
%  AX = ADDSUBAXES(hAx,WHERE,...) adds a sub-axes to the given parent axes.
%  "WHERE" can be a char-string or a cell array of strings: 'left', 'right', 'top' or 'bottom'.
%  [AX1,AX2,...] = ADDSUBAXES(hAx,{WHERE1,WHERE2,...}) 
%
%  Supported options are:
%    'width'  : width of left/right axes, fractional size of the given parent axes.
%    'height' : height of top/bottom axes, fractional size of the given parent axes.
%    'gap'    : gap between subaxes, fractional size of the given parent axes.
%
%  EXAMPLE :
%    >> data = rand(100,50);
%    >> figure;  hax = axes;
%    >> imagesc(data');  set(hax,'ydir','normal')
%    >> [htop,hleft] = addsubaxes(hax,{'top' 'left'});
%    >> plot(htop,1:100,nanmean(data,2)); % "top"
%    >> plot(hleft,nanmean(data,1),1:50);  % "left": note reversed XY
%
%  VERSION :
%    0.90 19.03.19 YM  pre-release
%    0.91 05.12.19 YM  minor bug fix.
%
%  See also axes

if nargin < 1,  eval(['help ' mfilename]);  return;  end

R_WIDTH  = 0.15;  % ratio to the size of "hax"
R_HEIGHT = 0.15;  % ratio to the size of "hax"
R_GAP    = 0.05;  % ratio to the size of "hax"
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'width' 'w'}
    R_WIDTH = varargin{N+1};
   case {'height' 'h'} 
    R_HEIGHT = varargin{N+1};
   case {'gap'}
    R_GAP = varargin{N+1};
 end
end

parent_pos = get(hax,'position');


if ischar(WHERE),  WHERE = {WHERE};  end

IS_LEFT   = any(strcmpi(WHERE,'left'));
IS_RIGHT  = any(strcmpi(WHERE,'right'));
IS_TOP    = any(strcmpi(WHERE,'top'));
IS_BOTTOM = any(strcmpi(WHERE,'bottom'));

newW = parent_pos(3);  newH = parent_pos(4);
if any(IS_LEFT) || any(IS_RIGHT)
  if any(IS_LEFT) && any(IS_RIGHT)
    newW = (1 - 2*R_WIDTH - 2*R_GAP)*parent_pos(3);
  else
    newW = (1 - R_WIDTH - R_GAP)*parent_pos(3);
  end
end
if any(IS_TOP) || any(IS_BOTTOM)
  if any(IS_TOP) && any(IS_BOTTOM)
    newH = (1 - 2*R_HEIGHT -2*R_GAP)*parent_pos(4);
  else
    newH = (1 - R_HEIGHT - R_GAP)*parent_pos(4);
  end
end

if any(IS_LEFT)
  newX = parent_pos(1) + (R_WIDTH + R_GAP)*parent_pos(3);
else
  newX = parent_pos(1);
end
if any(IS_BOTTOM)
  newY = parent_pos(2) + (R_HEIGHT + R_GAP)*parent_pos(4);
else
  newY = parent_pos(2);
end

for N = 1:numel(WHERE)
  switch lower(WHERE{N})
   case {'left'}
    tmpX = parent_pos(1);
    tmpY = newY;
    tmpW = R_WIDTH*parent_pos(3);
    tmpH = newH;
   case {'right'}
    tmpX = parent_pos(1) + (1 - R_WIDTH)*parent_pos(3);
    tmpY = newY;
    tmpW = R_WIDTH*parent_pos(3);
    tmpH = newH;
   case {'top'}
    tmpX = newX;
    tmpY = parent_pos(2) + (1 - R_HEIGHT)*parent_pos(4);
    tmpW = newW;
    tmpH = R_HEIGHT*parent_pos(4);
   case {'bottom'}
    tmpX = newX;
    tmpY = parent_pos(2);
    tmpW = newW;
    tmpH = R_HEIGHT*parent_pos(4);
   case {'center'}
    tmpX = newX;
    tmpY = newY;
    tmpW = newW;
    tmpH = newH;
  end
  tmpax = axes('position',[tmpX tmpY tmpW tmpH]);
  if strcmpi(WHERE{N},'center')
    set(tmpax,'color','none');
  end
  varargout{N} = tmpax;
end


set(hax,'position',[newX newY newW newH]);
return


