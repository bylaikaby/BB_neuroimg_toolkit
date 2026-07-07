function mguiSetIcon(hButton,iconFilename)
%MGUISETICON - set icon image to the button for MGUI
% PURPOSE : set icon image for the button
% USAGE :   mguiSetIcon(hButton,iconFilename)
%
%  VERSION :
%   0.90 04.Dec.03 YM  pre-release
%   0.91 02.Mar.12 YM  use 'bitmaps' directory if needed.
%
%  See also dgzviewer adfviewer imgviewer

if ~exist(iconFilename,'file'),
  if ~isempty(fileparts(iconFilename)),
    fprintf(' mguiSetIcon: %s not found.\n',iconFilename);
    return;
  end
  fp = fileparts(mfilename('fullpath'));
  iconFilename2 = fullfile(fp,'bitmaps',iconFilename);
  if ~exist(iconFilename2,'file'),
    fprintf(' mguiSetIcon: %s not found.\n',iconFilename);
    return;
  end
  iconFilename = iconFilename2;
  clear iconFilename2;
end

 
[icon,cmap] = imread(iconFilename);
if ndims(icon) == 2,
  icon = ind2rgb(icon,cmap);
end
set(hButton,'CData',icon);
