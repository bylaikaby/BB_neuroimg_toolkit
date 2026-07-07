function varargout = mroi_cursor(CursorType,hFigure)
%MROI_CURSOR - Utility of MROI that changes the cursor shape
%  MROI_CURSOR(CURSORTYPE) makes the pointer as CURSORTYPE.
%  [POINTER, SHAPEDATA, HOTSPOT] = MROI_CURSOR(CURSORTYPE,GCF) makes
%  the pointer of GCF as CURSORTYPE and returns the previous pointer data
%  (before change).
%
%  MROI_CURSOR will call set(handle,'Pointer',...).
%
%  Supported CURSORTYPE:
%    crosshair, arrow, watch, circle, fullcross, white dot, black dot, reset
%
%  EXAMPLE :
%     mroi_cursor('dot');     % the same as mroi_cursor('black dot');
%     mroi_cursor('reset');   % the same as mroi_cursor('arrow').
%
%  NOTE :
%    If want to change the cursor after ROIPOLY call, I must use TIMER to overwrite
%    cursor setting by ROIPOLY/GETLINE, avoiding focus-lock by ROIPOLY.
%    The code should be like,
%      >> figure;  imagesc(rand(10,10));
%      >> tobj = timer('TimerFcn','mroi_cursor(''circle'');','StartDelay',0.1);
%      >> start(tobj);  [mask,x,y] = roipoly;
%      >> delete(tobj);
%
%  VERSION :
%    0.90 30.05.01  YM  pre-release
%    0.91 21.11.19  YM  clean-up.
%
%  See also MROI, ROIPOLY, GETLINE, FIGURE, TIMER

if nargin == 0,  help mroi_cursor; return;  end

if nargin < 2;   hFigure = [];  end

if isempty(hFigure) || ~ishandle(hFigure)
  hf = gcf;		% figure handle to change cursor
end


if nargout
  varargout{1} = get(hf,'Pointer');
  varargout{2} = get(hf,'PointerShapeCData');
  varargout{3} = get(hf,'PointerShapeHotSpot');
end


switch lower(CursorType)
 case {'crosshair'}
  set(hf,'Pointer','crosshair');
 case {'arrow'}
  set(hf,'Pointer','arrow');
 case {'watch'}
  set(hf,'Poiter','watch');
 case {'circle'}
  set(hf,'Pointer','circle');
 case {'cross'}
  set(hf,'Pointer','cross');
 case {'feur'}
  set(hf,'Pointer','fleur');
 case {'fullcross'}
  set(hf,'Pointer','fullcross');
 case {'ibeam'}
  set(hf,'Pointer','ibeam');

 case {'white dot','white-dot', 'whitedot'}
  P = ones(16,16);
  P(:) = NaN;
  P(8:10,8:10) = 2;	% 2 looks as white
  set(hf,'Pointer','custom',...
         'PointerShapeCData',P,'PointerShapeHotSpot',[9 9]);
 case {'black dot','black-dot','blackdot', 'dot'}
  P = ones(16,16);
  P(:) = NaN;
  P(8:10,8:10) = 1;	% 1 looks as black

  set(hf,'Pointer','custom',...
         'PointerShapeCData',P,'PointerShapeHotSpot',[9 9]);

 case {'reset'}
  set(hf,'Pointer','arrow');
 otherwise
  set(hf,'Pointer','arrow');
end

return;

