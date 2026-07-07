function c = mncolorcode(colorname,nlevels)
%MNCOLORCODE - Get a color table
%  C = MNCOLORCODE(COLORNAME,NLEVELS) gets a color table.
%
%  VERSION :
%    0.90 28.06.05 YM  pre-release
%
%  See also MNSEE_TTEST, MNSEE_REGRESS

if nargin < 1, help mncolorcode; return;  end

if nargin < 2, nlevels = 256;  end


switch lower(colorname)
 case {'default','defalt','defult'}
  % Matlab does change colormap size to 64x3, so get original size.
  norig = size(colormap,1);
  c = colormap(colorname);
  n = size(c,1);
 
 case { 'mri' }
  h = round(nlevels/2);
  c = hot(h);
  c1 = zeros(h,3);
  c1(:,3) = [0:h-1]'./h;
  c = cat(1,flipud(c1),c);
  n = size(c,1);
  
 case { 'autumn','bone','colorcube','cool','copper',...
	'flag','gray','hot','hsv','jet','lines','pink','prism',...
	'spring','summer','white','winer' }
  % Matlab doen't change colormap size.
  c = eval(sprintf('colormap(%s(%d))',colorname,nlevels));
  n = size(c,1);
 
 case { 'r' }
  x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  c(:,[2 3]) = 0;
 case { 'g' }
  x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  c(:,[1 3]) = 0;
 case { 'b' }
  x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  c(:,[1 2]) = 0;
 case { 'c' }
  x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  c(:,1) = 0;
 case { 'm' }
  x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  c(:,2) = 0;
 case { 'y' }
  x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  c(:,3) = 0;
 case { 'k' }
  %x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  % black is meaning less, so use 'yellow'
  x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  c(:,3) = 0;
  
 otherwise
  fprintf(' not supported ''%s''\n',colorname);
  return;
end

% change number of levels for image
if nlevels ~= n,
  c = interp1(1:n,c,1:(n - 1)/(nlevels - 1):n,'linear');
end

return;
