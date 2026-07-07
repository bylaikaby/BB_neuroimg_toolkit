function canvassize(hAx,width,height,varargin)
%CANVASSIZE - Set the canvas size in pixels
%  CANVASSIZE(hAxes,Width,Height) sets the canvas size in pixels.
%
%  NOTE :
%    The funcion uses getframe() function to determine the bitmap size.
%
%  EXAMPLE :
%    plot(rand(10,2));
%    canvassize(gca,512,512)
%    f = getframe(gca)
%    size(f.cdata)
%
%  VERSION :
%    0.90 19.06.2012 YM  pre-release
%
%  See also set getframe

if nargin < 2,  help canvassize; return;  end

if nargin < 3,  height = width;  end


hFig = get(hAx,'parent');

pos = get(hAx,'pos');
f = getframe(hAx);

% Get scaling factor for X and Y.
% note f.cdata as (y,x,color)
%size(f.cdata)
sx = width/size(f.cdata,2);
sy = height/size(f.cdata,1);


if sx > 1 || sy > 1,
  oldUnits = get(hFig,'units');
  set(hFig,'units','pixels');
  
  [scrW scrH] = sub_screensize(get(hFig,'units'));
  fpos = get(hFig,'pos');
  fpos(3) = fpos(3) * max(1,sx);
  fpos(4) = fpos(4) * max(1,sy);
  if fpos(1) + fpos(3) > scrW
    fpos(1) = scrW - fpos(3) - 90;
  end
  if fpos(2) + fpos(4) > scrH
    fpos(2) = scrH - fpos(4) - 90;
  end
  set(hFig,'pos',fpos);
  
  set(hFig,'units',oldUnits);
  
  
  % re-calculate scaling after resized window
  pos = get(hAx,'pos');
  f = getframe(hAx);
  sx = width/size(f.cdata,2);
  sy = height/size(f.cdata,1);
  
end

pos(3) = pos(3) * sx;
pos(4) = pos(4) * sy;

set(hAx,'pos',pos);

return




function [scrW scrH] = sub_screensize(Units)

oldUnits = get(0,'Units');
set(0,'Units',Units);
sz = get(0,'ScreenSize');
set(0,'Units',oldUnits);

scrW = sz(3);  scrH = sz(4);

  
  
