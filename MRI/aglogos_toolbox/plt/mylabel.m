function h = mylabel(varargin)
%MYLABEL - Y-axis label by text() function.
%  H = MYLABEL('text',...)    adds Y-axis text on the current axis.
%  H = MYLABEL(AX,'text',...) adds Y-axis text to the specified axes.
%
%  This function uses text() instead of ylabel() so that different axes can have the same
%  position and alignment.
%
%  Supported options are:
%   'YaxisLocation' : right or left
%   'Position'      : exact postion in normalized units. e.g. [-0.0653  0.5  0] for left-location.
%   'FontName'      : font name
%   'FontSize'      : font size
%   'FontWeight'    : font weight
%   'Color'         : text color
%
%
%  EXAMPLE :
%    >> plot(1,100);
%    >> mylabel(gca,'Y-Label','location','right','fontsize',12)
%    >> mylabel(gca,'Y-Label','position', [1.0653 0.5],'fontsize',12)
%
%  VERSION :
%    0.90 30.09.20 YM  pre-release
%
%  See also ylabel text

if nargin < 1, eval(['help ' mfilename]); return;  end

if ishandle(varargin{1})
  % called like mylabel(axs,label,...)
  hAx      = varargin{1};
  StrLabel = varargin{2};
  iarg     = 3;
else
  % called like mylabel(label,...)
  hAx      = gca;
  StrLabel = varargin{1};
  iarg     = 2;
end



YaxisLocation = 'right';
POS_XYZ       = [];
FontName      = get(hAx,'FontName');
FontSize      = get(hAx,'LabelFontSizeMultiplier') * get(hAx,'FontSize');
FontWeight    = get(hAx,'FontWeight');
TextColor     = get(hAx,'YColor');

for N = iarg:2:length(varargin)
  switch lower(varargin{N})
   case {'location' 'yaxislocation'}
    YaxisLocation = varargin{N+1};
   case {'position' 'pos'}
    POS_XYZ = varargin{N+1};
   case {'fontname'}
    FontName = varargin{N+1};
   case {'fontsize'}
    FontSize = varargin{N+1};
   case {'fontweight'}
    FontWeight = varargin{N+1};
   case {'color','textcolor' 'fontcolor'}
    TextColor = varargin{N+1};
  end
end


if isempty(POS_XYZ)
  if strcmpi(YaxisLocation,'left')
    POS_XYZ = [-0.0653  0.5  0];
  else
    POS_XYZ = [ 1.0653  0.5  0];
  end
end



if length(POS_XYZ) == 2,  POS_XYZ(3) = 0;  end

delete(findobj(hAx,'tag','mylabel'));  % delte old one if exists.

h = text(hAx,POS_XYZ(1),POS_XYZ(2),POS_XYZ(3),StrLabel,'units','normalized','rotation',90,...
         'horizontalalignment','center','verticalalignment','top',...
         'FontName',FontName,'FontSize',FontSize,'FontWeight',FontWeight,'Color',TextColor,...
         'tag','mylabel');
