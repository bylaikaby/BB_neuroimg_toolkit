function mkrfgrid(x,y,w,h)
%MKRFGRID - Draw monitor grid
%
% NKL, 28.04.03

if nargin < 4,
  h = 9;
end;

if nargin < 3,
  w = 12;
end;

if nargin < 2,
  y = -5.7 - h/2;
end;

if nargin < 1,
  x = 2 - w/2;
end;


mfigure([100 100 780 600],'Visual Field Plot');

rectangle('Position', [-15 -11.5 30 23],'linewidth',3,'edgecolor','r');
hold on;
set(gca,'xlim',[-16 16]);
set(gca,'ylim',[-13 13]);
line([0 0],get(gca,'ylim'),'linewidth',2,'color','b');
line(get(gca,'xlim'),[0 0],'linewidth',2,'color','b');
set(gca,'xtick',[-16:16]);
set(gca,'ytick',[-13:13]);
grid on
xlabel('X Dimension');
ylabel('Y Dimension');
rectangle('Position', [-0.2 -0.2 .4 .4],'facecolor','k','edgecolor','k');
rectangle('Position', [x y w h],'edgecolor','g','linewidth',2);
line([x+w/2 x+w/2],[y y+h],'linewidth',2,'color','r','linestyle',':');
line([x x+w],[y+h/2 y+h/2],'linewidth',2,'color','r','linestyle',':');


