function filename = plotRF(varargin)
%PLOTRF - Display receptive fields from a rfpfile.
%  PLOTRF(varargin) plots receptive fields from a rfpfile.
%
%  USAGE : filename = plotRF('file','dir','xlim','ylim','grid','stim')
%
%  EXAMPLE :
%    >> rfpfile = catfilename('m02lx1',1,'rfp');
%    >> plotRF('file',rfpfile);
%    or 
%    >> par = expgetpar('m02lx1',1);
%    >> plotRF('rfp',par.rfp);
%
%  VERSION :
%    1.00  29-Aug-2000  YM
%    1.03  28-Nov-2000  YM
%    1.04  16-Jan-2006  YM  support to be called by SESPLOTRF.
%
%  See also SESPLOTRF

global RFP
spl=0;

lArgin = varargin;
while length(lArgin) >= 2,
  prop = lower(lArgin{1});
  val = lArgin{2};
  lArgin = lArgin(3:end);
  switch lower(prop),
   case {'readfile','rfile','file','rffile','rfpfile'}
    rffile = val;
   case {'readdir','rdir','dir','directory'}
    rfdir = val;
   case {'xlim'}
    xlm = val;
   case {'ylim'}
    ylm = val;
   case {'subplot'}
    spl = val;
   case {'grid', 'div', 'griddiv','gdiv'}
    gdiv = val;
   case {'stim', 'stimulus'}
    stim = val;
   case {'rfp'}
    RFP = val;
  end
end

if ~exist('RFP','var') | isempty(RFP),
  if ~exist('rffile','var'),
    [RFP rffile] = subLoadRFFile;
  else
    if exist('rfdir','var'), rffile = sprintf('%s/%s',rfdir,rffile);, end
    RFP = subLoadRFFile(rffile);
  end
end

if ~exist('xlm','var'), xlm = [-10 10];,  end
if ~exist('ylm','var'), ylm = [-10 10];,  end
if ~exist('gdiv','var'), gdiv = 2;,         end

tmp = sprintf('%s  nRFs=%d',RFP.file,RFP.n);
if ~spl,
  figure('Name',tmp,...
         'DefaultAxesFontName','Comic Sans MS',...
         'PaperType','A4','PaperOrientation','landscape');
  subplot('111');
  title(strrep(tmp,'_','\_'),'FontWeight','bold');
end;

set(gca,'FontSize',10,'FontName','Comic Sans MS');
xlabel('hor. meridian in degrees');
ylabel('ver. meridian in degrees');
set(gca,'NextPlot','add');
set(gca,'XLim',xlm);  set(gca,'YLim',ylm);

% draw grids
%xg = [-gdiv:-gdiv:(xlm(1)+gdiv/2), 0:gdiv:(xlm(2)-gdiv/2)];
xg = [-gdiv:-gdiv:xlm(1), 0:gdiv:xlm(2)];
for i=xg
  if i ~= 0
    line([i i],ylm,'LineStyle',':','Color',[0.5 0.5 0.5],'LineWidth',0.5);
  end
end
%yg = [-gdiv:-gdiv:(ylm(1)+gdiv/2), 0:gdiv:(ylm(2)-gdiv/2)];
yg = [-gdiv:-gdiv:ylm(1), 0:gdiv:ylm(2)];
for i=yg
  if i ~= 0
    line(xlm,[i i],'LineStyle',':','Color',[0.5 0.5 0.5],'LineWidth',0.5);
  end
end
line([0 0],ylm,'LineStyle','-','Color','black','LineWidth',0.5);
line(xlm,[0 0],'LineStyle','-','Color','black','LineWidth',0.5);

% draw a stimulus
if exist('stim','var')
  xc = stim(1)-stim(3)/2;  yc = stim(2)-stim(4)/2;
  stimpos = [xc, yc, stim(3), stim(4)];
  rectangle('Position',stimpos,'Curvature',[1 1],...
	    'EdgeColor',[0.85 0.85 0],'LineStyle','--','LineWidth',0.6);
  text(stim(1),stim(2)+stim(4)/2,'stim','FontSize',6,'Units','Data');
end

% draw receptive fields
for i=1:RFP.n
  rf = RFP.rf{i};
  %subDrawRF(rf.center,rf.size,rf.angle,rf.color,RFP.inf{i});
  subDrawRF(rf.center,rf.size,rf.angle,rf.color,rf.inf);
end

% adjust aspect ratio
%xlen = abs(xlm(2)-xlm(1));
%ylen = abs(ylm(2)-ylm(1));
daspect([1 1 1]);

if nargout ~= 0, filename = rffile;  end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sub-function to draw RF
function subDrawRF(pos,sz,ang,col,inf)

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

text(x(4),y(4)-0.2,inf,'FontSize',8,'Units','data');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sub-function to load a RF file
function [rfinf, fname] = subLoadRFFile(rffile)

RFPath = pwd;
  
% initialize output
rfinf = [];

% pick up a file
if ~exist('rffile','var')
  %[f,d] = pickfile('Select a RF file',pwd,'*.rfp');
  %[f,d] = pickfile('Select a RF file',RFPath,'*.rfp');
  [f,d] = uigetfile( ...
	  {'*.rfp', 'All RF Parameter Files (*.rfp)'; ...
	   '*.*',   'All Files (*.*)'}, ...
	  'Pick a RFP file');
  if isequal(f,0) | isequal(d,0), return; end
  rffile = sprintf('%s/%s',d,f);
end

rffile = strrep(rffile,'\','/');
[rdir,rfile,fe] = fileparts(rffile);
if ~length(rdir), rdir = RFPath;  end
rfullpath = sprintf('%s/%s%s',rdir,rfile,fe);
rfinf.file = rfile;


% read text
fid = fopen(rfullpath,'r');
i = 1;
while 1
  line = fgets(fid,80);
  line = line(1:length(line)-1);
  if ~isstr(line),break,end;
  % remove comments following '#'
  ci = findstr(line,'#');
  if length(ci), line = line(1:ci(1)); end
  txtline{i} = line;
  i=i+1;
end
fclose(fid);

rfinf.inf = {};
% find parameters
nrf = 0;
for i=1:length(txtline)
  [t0,r0] = strtok(txtline{i});
  if findstr(t0,'beginLoadNewRF')
    %nrf = nrf + 1;
  elseif findstr(t0,'endLoadNewRF')
    nrf = nrf + 1;
  elseif findstr(t0,'loadRFCenter')
    [t1,r1] = strtok(r0,' ');
    [t2,r2] = strtok(r1,' ');
    rfinf.rf{nrf+1}.center(1) = str2num(t1);
    rfinf.rf{nrf+1}.center(2) = str2num(t2);
  elseif findstr(t0,'loadRFSize')
    [t1,r1] = strtok(r0,' ');
    [t2,r2] = strtok(r1,' ');
    rfinf.rf{nrf+1}.size(1) = str2num(t1);
    rfinf.rf{nrf+1}.size(2) = str2num(t2);
  elseif findstr(t0,'loadRFAngle')
    [t1,r1] = strtok(r0);
    rfinf.rf{nrf+1}.angle = str2num(t1);
  elseif findstr(t0,'loadRFColor')
    [t1,r1] = strtok(r0);
    rfinf.rf{nrf+1}.color = t1;
  elseif findstr(t0,'loadRFText')
    istr = findstr(r0,'"');
    %[t1,r1] = strtok(r0,' "')
    %rfinf.inf{nrf+1} = r0(istr(1)+1:istr(2)-1);
    rfinf.rf{nrf+1}.inf = r0(istr(1)+1:istr(2)-1);
  end
end

rfinf.n = nrf;
% backward compatibility
%if length(rfinf.inf) == 0, rfinf.inf = chrfinf(rfinf.file);  end

if nargout > 1, fname = rfullpath;  end