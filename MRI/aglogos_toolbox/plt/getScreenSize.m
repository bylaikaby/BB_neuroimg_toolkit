function [scrW, scrH] = getScreenSize(Units)
%GETSCREENSIZE - get screen size of the monitor
% PURSPOE : To get screen size of the display.
% USAGE : [scrW, scrH] = getScreenSize(Units)
%         "Units" : 'char' or 'pixels'.
% VERSION : 
%   0.90 19.12.03  YM
%   0.91 01.10.19  YM  use groot for R2014b~.
%
% See also MGUI, DGZVIEWER, ADFVIEWER, IMGVIEWER

if nargin == 0, Units = 'pixels';  end


if verLessThan('MATLAB','8.4')
  % MATLAB R2014a and earlier...
  r = 0;
else
  % MATLAB R2014b and later...
  r = groot;
end

oldUnits = get(r,'Units');
set(r,'Units',Units);
sz = get(0,'ScreenSize');
set(r,'Units',oldUnits);

scrW = sz(3);  scrH = sz(4);
