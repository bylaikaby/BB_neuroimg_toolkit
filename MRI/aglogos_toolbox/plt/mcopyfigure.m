function mcopyfigure(hFig, POSITION)
%MCOPYFIGURE - Copy the figure to clipboard.
%  MCOPYFIGURE(FigHandle) copies the figure to clipboard.
%  This is a solution for "print(gcf,'-dmeta')" which ignores 
%  transparency of figure background.
%  While running the function, DO NOT TOUCH ANY KEY!
%
%  NOTE :
%    This function mimics key events of "copy figure" 
%    (Alt-E, F, Enter) by using java.awt.Robot.
%
%  EXAMPLE :
%    figure; plot(rand(10,2));
%    mcopyfigure(gcf)   % DO NOT TOUCH ANY KEY!
%
%  VERSION :
%    0.90 12.07.13 YM  pre-release
%
%  See also java java.awt.Robot java.awt.event.KeyEvent

if nargin < 1,  eval(['help ' mfilename]); return;  end

% "copy figure": Alt-E, F, Enter
% it seems that focusing to the figure is needed every KeyPress/Release...

robot = java.awt.Robot;

if nargin < 2,
  POSITION = [100 100 800 600];
end;

% hOld = get(0,'CurrentFigure');
% if ~isempty(POSITION),
%   set(hFig,'position',POSITION);
% end;

% Alt-E
figure(hFig);
robot.keyPress(java.awt.event.KeyEvent.VK_ALT);
figure(hFig);
robot.keyPress(java.awt.event.KeyEvent.VK_E);
figure(hFig);
robot.keyRelease(java.awt.event.KeyEvent.VK_E);
figure(hFig);
robot.keyRelease(java.awt.event.KeyEvent.VK_ALT);
figure(hFig);
robot.keyPress(java.awt.event.KeyEvent.VK_F);
figure(hFig);
robot.keyRelease(java.awt.event.KeyEvent.VK_F);
% Enter

figure(hFig);
robot.keyPress(java.awt.event.KeyEvent.VK_ENTER);
% figure(hFig);
% robot.keyRelease(java.awt.event.KeyEvent.VK_ENTER);

% if ishandle(hOld),
%   set(0,'CurrentFigure',hOld);
% end
return
