function dspglmimg(SCAN,PVAL,ARGS)
%DSPGLMIMG - Display multislice EPI13 test functional data
% DSPGLMIMG(scan) - Displays the result of our typical test scan
% with block design stimulus and 13 brain slices.
%
%  VERSION :
%    0.90 05.10.07 YM  pre-release
%
%  See also SESCSCAN SHOWCSCAN DSPCORIMG

if nargin < 1,
  error('usage: dspglmimg(scan,[thr],[ARGS]);');
end;
if nargin < 2,  PVAL = [];   end
if nargin < 3,  ARGS = [];  end

if isempty(PVAL),  PVAL = 0.05;  end


if iscell(SCAN),
  for N=1:length(SCAN),  dspglmimg(SCAN{N},PVAL,ARGS);  end
  return;
end

SCAN = subPrepareData(SCAN,PVAL);
DoPlot(SCAN,PVAL,ARGS);


return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoPlot(SCAN,Pthr,ARGS)
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

ana = mgetcollage(SCAN.ana);
fun = mgetcollage(SCAN.dat);

% scale into -1/+1 to make compatible to COR analysis
maxv = max(abs(fun(:)))*0.7;
if maxv > 0,
  fun = fun / maxv;
  fun(find(abs(fun(:)) > 1)) = 1;
end


fun(find(fun(:) == 0)) = NaN;
if numel(ana) == 1 & isfield(SCAN,'epi'),
  fprintf(' %s: no anatomy, use ".epi" as anatomy.\n',mfilename);
  ana = mgetcollage(SCAN.epi);
end


msubplot(1,2,1);
% NOTE THAT dspfused() is for COR analysis, so set threshould as 0 to do nothing
dspfused(ana,fun,0,ARGS);
if ~isfield(ARGS,'scanname'),  ARGS.scanname = '';  end
if ~isfield(ARGS,'info'),      ARGS.info     = '';  end
s = sprintf('Session: %s, %s %s GLM', SCAN.session,ARGS.scanname,ARGS.info);
title(s,'color','y','fontsize',14,'fontweight','normal');

NPLOTS = size(SCAN.pts,2);
NCOLS = 6;
HCOLS = NCOLS/2;
NROWS = ceil(NPLOTS/(NCOLS/2)); % The first two columns are for fused images

t = [0:size(SCAN.pts,1)-1] * SCAN.dx;
m = SCAN.mdl.dat;
m = m/max(m(:));
m = m * max(SCAN.pts(:))/2;
YLIM = [min(SCAN.pts(:)) max(SCAN.pts(:))];
YLIM = 1.1 * [-max(abs(YLIM)) max(abs(YLIM))];
if isnan(YLIM(1)) || isnan(YLIM(2)),  YLIM = [-1 1];  end


for SliceNo = 1:NPLOTS,
  K = NCOLS * floor((SliceNo-1)/HCOLS) + mod((SliceNo-1),HCOLS) + HCOLS+1;
  msubplot(NROWS,NCOLS,K);
  plot(t,m,'color',[.8 .7 .7],'linewidth',3);
  hold on;
  ebtmp = errorbar(t,SCAN.pts(:,SliceNo),SCAN.ptserr(:,SliceNo));
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

s = sprintf('%s(Pthr=%.2f): Control Scan: %s %s %s (GLM)',...
            mfilename, Pthr, SCAN.session, ARGS.scanname, ARGS.info);
suptitle(s,'w',14);


if isfield(ARGS,'figtitle') & ~isempty(ARGS.figtitle),
  s = sprintf('%s GLM',ARGS.figtitle);
  set(gcf,'Name',strrep(s,'_','\_'));
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subfunction to prepare data for plotting
function SCAN = subPrepareData(SCAN,PVAL)

COORDS = double(SCAN.coords);

SCAN.dat    = NaN(SCAN.epidim);
SCAN.pts    = NaN(size(SCAN.tcdat,1),SCAN.epidim(3));
SCAN.ptserr = NaN(size(SCAN.pts));
SCAN.nts    = NaN(size(SCAN.pts));
SCAN.ntserr = NaN(size(SCAN.pts));

cont = subGetContrast(SCAN,'pos',PVAL);
if ~isempty(cont) & ~isempty(cont.selvoxels),
  voxcoords = COORDS(cont.selvoxels,:);
  idx = sub2ind(SCAN.epidim,voxcoords(:,1),voxcoords(:,2),voxcoords(:,3));
  SCAN.dat(idx)    = double(cont.BetaMag);
  for N = 1:SCAN.epidim(3),
    found = find(voxcoords(:,3) == N);
    if isempty(found),  continue;  end
    idx = sub2ind(SCAN.epidim,voxcoords(found,1),voxcoords(found,2),voxcoords(found,3));
    SCAN.pts(:,N)    = hnanmean(SCAN.tcdat(:,idx),2);
    SCAN.ptserr(:,N) = hnanstd(SCAN.tcdat(:,idx),2);
  end
end

cont = subGetContrast(SCAN,'neg',PVAL);
if ~isempty(cont) & ~isempty(cont.selvoxels),
  voxcoords = COORDS(cont.selvoxels,:);
  idx = sub2ind(SCAN.epidim,voxcoords(:,1),voxcoords(:,2),voxcoords(:,3));
  SCAN.dat(idx)    = double(-cont.BetaMag);
  for N = 1:SCAN.epidim(3),
    found = find(voxcoords(:,3) == N);
    if isempty(found),  continue;  end
    idx = sub2ind(SCAN.epidim,voxcoords(found,1),voxcoords(found,2),voxcoords(found,3));
    SCAN.nts(:,N)    = hnanmean(SCAN.tcdat(:,idx),2);
    SCAN.ntserr(:,N) = hnanstd(SCAN.tcdat(:,idx),2);
  end
end



SCAN.mdl.dx  = SCAN.dx;
SCAN.mdl.dat = SCAN.DesignMatrices{1}(:,1);


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cont = subGetContrast(SCAN,ContName,PVAL)
cont = [];

for N = 1:length(SCAN.glmcont)
  if strcmpi(SCAN.glmcont(N).cont.name,ContName),
    cont = SCAN.glmcont(N);
    idx = find(cont.pvalues < PVAL);
    cont.selvoxels = cont.selvoxels(idx);
    cont.statv     = cont.statv(idx);
    cont.pvalues   = cont.pvalues(idx);
    cont.allvalues = [];
    if ~isempty(cont.BetaMag),
      cont.BetaMag = cont.BetaMag(idx);
    end
    cont.allbetamag = [];
    
    % do clustering
    cont = subDoClustering(SCAN,cont);
    break;
  end
end

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cont = subDoClustering(SCAN,cont)
if isempty(cont),  return;  end

COORDS = double(SCAN.coords(cont.selvoxels,:));
VOXIDX = sub2ind(SCAN.epidim,COORDS(:,1),COORDS(:,2),COORDS(:,3));

SELVOX = zeros(size(cont.selvoxels));

for N = 1:SCAN.epidim(3),
  found = find(COORDS(:,3) == N);
  if isempty(found),  continue;  end
  px = COORDS(found,1);
  py = COORDS(found,2);
  [px2 py2] = mcluster(px,py);
  if isempty(px2),  continue;  end
  pz2 = ones(size(px2))*N;
  tmpidx = sub2ind(SCAN.epidim,px2,py2,pz2);
  [C, ia, ib] = intersect(VOXIDX,tmpidx);
  SELVOX(ia) = 1;
end
sel = find(SELVOX > 0);
cont.selvoxels = cont.selvoxels(sel);
cont.statv     = cont.statv(sel);
cont.pvalues   = cont.pvalues(sel);
if ~isempty(cont.BetaMag),
  cont.BetaMag = cont.BetaMag(sel);
end

return
