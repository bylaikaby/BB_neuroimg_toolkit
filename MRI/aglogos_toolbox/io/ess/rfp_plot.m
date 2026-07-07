function rfp_plot(RFPFILE,varargin)
%RFP_PLOT - plots receptive fields from a RFP file.
%  RFP_PLOT(RFPFILE,...) plots receptive fields from a RFP file.
%
%  OPTIONS :
%    'xlim'     : range of X axes in degrees
%    'ylim'     : range of Y axes in degrees
%    'axes'     : axes handle to plot
%    'div'      : division for gridding
%    'stimpos'  : stimulus position as [center-x center-y width height]
%
%  EXAMPLE :
%    rfp = rfp_read('y:/temp/B06_2803(2016).rfp')
%    rfp_plot(rfp,'xlim',[-15 10]);
%    or
%    rfp_plot('y:/temp/B06_2803(2016).rfp')
%
%  NOTE :
%    'rfp' file can be created with MriStim program by hand-plotting of 
%    receptive fields.
%
%  VERSION :
%    0.90 31.03.08 YM  pre-release
%
%  See also rfp_read

if nargin < 1,  eval(sprintf('help %s',mfilename)); return;  end

if isfield(RFPFILE,'rf') && iscell(RFPFILE.rf),
  % RFPFILE as 'RFP' structure returned by rfp_read()
  RFP = RFPFILE;
  RFPFILE = RFP.file;
else
  % RFPFILE as a filename
  RFP = rfp_read(RFPFILE);
end


XLIM    = [-10 10];   % range of X in degrees
YLIM    = [-10 10];   % range of Y in degrees
hAxs    = [];         % handle of axes to plot
GDIV    = 2;          % grid size in degrees
STIMPOS = [];         % stimulus position as [centerX centerY width height]

for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'xlim'}
    XLIM = sort(varargin{N+1});
   case {'ylim'}
    YLIM = sort(varargin{N+1});
   case {'axes','haxes'}
    hAxs = varargin{N+1};
   case {'stimpos','stmpos','stim','stm','stimulus'}
    STIMPOS = varargin{N+1};
  end
end

if ishandle(hAxs),
  axes(hAxs);
else
  tmptxt = sprintf('%s  nRFs=%d',RFP.file,RFP.n);
  figure('Name',tmptxt,...
         'DefaultAxesFontName','Comic Sans MS',...
         'PaperType','A4','PaperOrientation','landscape');
  hAxs = subplot(1,1,1);
  title(strrep(tmptxt,'_','\_'),'FontWeight','bold');
end


set(gca,'FontSize',10,'FontName','Comic Sans MS');
xlabel('hor. meridian in degrees');
ylabel('ver. meridian in degrees');
set(gca,'NextPlot','add');
set(gca,'XLim',XLIM);
set(gca,'YLim',YLIM);


% draw grids %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(GDIV),
  xg = [-GDIV:-GDIV:XLIM(1), 0:GDIV:XLIM(2)];
  for N=xg
    if N ~= 0
      line([N N],YLIM,'LineStyle',':','Color',[0.5 0.5 0.5],'LineWidth',0.5);
    end
  end
  yg = [-GDIV:-GDIV:YLIM(1), 0:GDIV:YLIM(2)];
  for N=yg
    if N ~= 0
      line(XLIM,[N N],'LineStyle',':','Color',[0.5 0.5 0.5],'LineWidth',0.5);
    end
  end
end
line([0 0],YLIM,'LineStyle','-','Color','black','LineWidth',0.5);
line(XLIM,[0 0],'LineStyle','-','Color','black','LineWidth',0.5);


% draw stimulus %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(STIMPOS) & isvector(STIMPOS),
  xc = STIMPOS(1)-STIMPOS(3)/2;  yc = STIMPOS(2)-STIMPOS(4)/2;
  tmppos = [xc, yc, STIMPOS(3), STIMPOS(4)];
  rectangle('Position',tmppos,'Curvature',[1 1],...
	    'EdgeColor',[0.85 0.85 0],'LineStyle','--','LineWidth',0.6);
  text(STIMPOS(1),STIMPOS(2)+STIMPOS(4)/2,'stim','FontSize',6,'Units','Data');
end


% draw receptive fields %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for N=1:length(RFP.rf),
  rf = RFP.rf{N};
  subDrawRF(rf.center,rf.size,rf.angle,rf.color,rf.inf);
end


daspect([2 2 1]);

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sub-function to draw RF
function subDrawRF(pos,sz,ang,col,info)

if ang == 0
  x(1) = sz(1)/2;     y(1) = sz(2)/2;
  x(2) =  x(1);       y(2) = -y(1);
  x(3) = -x(1);       y(3) = -y(1);
  x(4) = -x(1);       y(4) =  y(1);
else
  cv = cos(ang/180*pi);  sv = sin(ang/180*pi);
  xw = sz(1)/2;       yw = sz(2)/2;
  x(1) =  xw*cv - yw*sv;  y(1) =  xw*sv + yw*cv;
  x(2) =  xw*cv + yw*sv;  y(2) =  xw*sv - yw*cv;
  x(3) = -xw*cv + yw*sv;  y(3) = -xw*sv - yw*cv;
  x(4) = -xw*cv - yw*sv;  y(4) = -xw*sv + yw*cv;
end

x = x + pos(1);  y = y + pos(2);
x(5) = x(1);     y(5) = y(1);

switch col
 case 'lightgray'
  col = [0.7 0.7 0.7];
 case 'black'
 case 'gray50'
  col = [0.5 0.5 0.5];
 case 'red'
 case 'orange'
  col = [1.0 0.5 0];
 case 'yellow'
 case 'green'
 case 'cyan'
 case 'blue'
 case 'purple'
  col = [1.0 0 1.0];
 case 'magenta'
end
  

for i=1:4
  line([x(i),x(i+1)],[y(i), y(i+1)],'Color',col,'LineWidth',0.6);
end

text(x(4),y(4)-0.2,info,'FontSize',8,'Units','data');

return
