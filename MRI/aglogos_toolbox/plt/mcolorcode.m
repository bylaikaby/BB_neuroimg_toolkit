function cmap = mcolorcode(colorname,nlevels,figh)
%MCOLORCODE - Return the colormap.
% USAGE :   mcolorcode(colorname,[nlevels],[figHandle])
%
% VERSION :
%   0.90  03-Nov-2000  YM
%   0.91  29-Oct-2003  YM  adapted for matlab-mri.
%   0.92  24-Apr-2019  YM  added 'parula', renamed from "colorcode.m".
%
% See also colormap

if ~exist('colorname','var'), colorname = 'default';  end
if ~exist('nlevels','var'),   nlevels = 256;          end
if ~exist('figh','var'),      figh = [];              end

% change colormap first
switch lower(colorname)
 case {'default','current'}
  % get the current colormap
  if ~ishandle(figh),  figh = gcf;  end
  figure(figh);
  if strcmpi(colorname,'default')
    colormap('default');
  end
  c = colormap;  n = size(c,1);
  % change number of levels, if needed.
  if nlevels ~= n
    c = interp1(1:n,c,1:(n - 1)/(nlevels - 1):n,'linear');
    figure(figh);  colormap(c);
  end
  
 case { 'mri' }
  h = round(nlevels/2);
  c = hot(h);
  c1 = zeros(h,3);
  c1(:,3) = (0:h-1)'./h;
  c = cat(1,flipud(c1),c);
  if ishandle(figh),  colormap(c);  end
  
 case { 'autumn','bone','colorcube','cool','copper',...
	'flag','gray','hot','hsv','parula','jet','lines','pink','prism',...
	'spring','summer','white','winer' }
  c = eval(sprintf('%s(%d);',colorname,nlevels));
  if ishandle(figh),  colormap(c);  end
 otherwise
  fprintf(' not supported ''%s''\n',colorname);
  return;
end


% output
if nargout > 0, cmap = c;  end
