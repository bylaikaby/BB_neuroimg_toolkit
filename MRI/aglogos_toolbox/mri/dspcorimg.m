function dspcorimg(xcor,thr,ARGS)
%DSPCORIMG - Display multislice EPI13 test functional data
% DSPCORIMG(xcor) - Displays the result of our typical test scan
% with block design stimulus and 13 brain slices.
%
% NKL, 13.12.01
%
% See also SESCSCAN SHOWCSCAN DSPGLMIMG

if nargin < 1,
  error('usage: dspcorimg(sig,[thr],[ARGS]);');
end;
if nargin < 2,  thr = [];   end
if nargin < 3,  ARGS = [];  end

if isempty(thr),
  thr = 0.1;
end;

if isstruct(xcor),
  xcor = {xcor};
end;

L = length(xcor);       % Number of models
for N=1:L,
  DoPlot(xcor{N},thr,ARGS);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoPlot(xcor,thr,ARGS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mfigure([1 140 1200 800]);		% When META is saved
set(gcf,'DefaultAxesBox',		'on')
set(gcf,'DefaultAxesfontsize',	8);
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName', 'Comic Sans MS');
orient landscape;
papersize = get(gcf, 'PaperSize');
width = papersize(1)*0.8;
height = papersize(2)*0.8;
left = (papersize(1)- width)/2;
bottom = (papersize(2)- height)/2;
myfiguresize = [left, bottom, width, height];
set(gcf,'PaperPosition', myfiguresize);
set(gcf,'BackingStore','on','DoubleBuffer','on');
set(gcf,'color',[0 0 0.2]);

ana = mgetcollage(xcor.ana);
fun = mgetcollage(xcor.dat);
if numel(ana) == 1 & isfield(xcor,'epi'),
  fprintf(' %s: no anatomy, use ".epi" as anatomy.\n',mfilename);
  ana = mgetcollage(xcor.epi);
end


msubplot(1,2,1);
dspfused(ana,fun,thr,ARGS);
if ~isfield(ARGS,'scanname'),  ARGS.scanname = '';  end
if ~isfield(ARGS,'info'),      ARGS.info     = '';  end
s = sprintf('Session: %s, %s %s %s COR', xcor.session,ARGS.scanname,ARGS.info);
title(s,'color','y','fontsize',14,'fontweight','normal');

NPLOTS = size(xcor.pts,2);
NCOLS = 6;
HCOLS = NCOLS/2;
NROWS = ceil(NPLOTS/(NCOLS/2)); % The first two columns are for fused images

t = [0:size(xcor.pts,1)-1] * xcor.dx;
m = xcor.mdl.dat;
m = m/max(m(:));
m = m * max(xcor.pts(:))/2;
YLIM = [min(xcor.pts(:)) max(xcor.pts(:))];
YLIM = 1.1 * [-max(abs(YLIM)) max(abs(YLIM))];
if isnan(YLIM(1)) || isnan(YLIM(2)),  YLIM = [-1 1];  end


for SliceNo = 1:NPLOTS,
  K = NCOLS * floor((SliceNo-1)/HCOLS) + mod((SliceNo-1),HCOLS) + HCOLS+1;
  msubplot(NROWS,NCOLS,K);
  plot(t,m,'color',[.8 .7 .7],'linewidth',3);
  hold on;
  ebtmp = errorbar(t,xcor.pts(:,SliceNo),xcor.ptserr(:,SliceNo));
  eb = findall(ebtmp);
  set(eb(1),'Color','c');
  set(eb(2),'LineWidth',1.5,'Color','r');
  set(gca,'xlim',[t(1) t(end)],'ylim',YLIM);
  set(gca,'xcolor','r','ycolor','r','color',[.9 .9 .9]);
  set(gca,'xtick',[],'ytick',[]);
  hd = title(sprintf('Slice %d', SliceNo));
  pos = get(hd,'position');
  ylim = get(gca,'ylim');
  pos(2) = ylim(1)*0.9;
  set(hd,'position',pos);
end;

s = sprintf('%s(thr=%.2f): Control Scan: %s %s %s (COR)',...
            mfilename, thr, xcor.session, ARGS.scanname, ARGS.info);
suptitle(s,'w',14);


if isfield(ARGS,'figtitle') & ~isempty(ARGS.figtitle),
  s = sprintf('%s COR',ARGS.figtitle);
  set(gcf,'Name',strrep(s,'_','\_'));
end

return;



