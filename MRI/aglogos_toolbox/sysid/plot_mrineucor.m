function plot_mrineucor(RES,varargin)
%PLOT_MRINEUCOR - Plot the result of sesmrineucor().
%  PLOT_MRINEUCOR(RES) plots the result of sesmrineucor().
%
%  NOTE :
%    RES = 
%      session: 'rat7e1'
%      grpname: 'spont'
%         exps: [3 4 5 6 8 9 10 11 12 13]
%         opts: [1x1 struct]
%          ana: [36x42x4 double]
%       coords: [193x3 double]
%     lags_pts: [1x41 double]
%           dx: 1
%          dat: [41x1x8x193x10 double]   <---- corr data as (lag,chan,band,voxel,exp)
%      dimname: {'lag'  'chan'  'band'  'voxel'  'exp'}
%
%
%  EXAMPLE :
%     res = sesmrineucor('rat7e1','spont','mrisig','rproiTs','roi','HP','neusig','rpblp','ele','hipgrouped','convhrf','cohen')
%     plot_mrineucor(res);
%
%  VERSION :
%    0.90 14.02.12 YM  pre-release
%
%  See also sesmrineucor expmrineucor mrineucor_cluster

if nargin < 1,  eval(['help ' mfilename]); return;  end

PLOT_MDS = 0;
BANDS    = 4:8;
CLUST_R  = 0.4;
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'band' 'bands'}
    BANDS  = varargin{N+1};
   case {'mds'}
    PLOT_MDS = varargin{N+1};
   case {'clustr'}
    CLUST_R = varargin{N+1};
  end
end
if isempty(BANDS),  BANDS = 1:size(RES.dat,3);  end


RES.dat = nanmean(RES.dat,5);


NChan = size(RES.dat,2);
NBand = length(BANDS);
NVox  = size(RES.dat,4);


lags_sec = RES.lags_pts * RES.dx;

[maxv maxi] = max(abs(RES.dat),[],1);

maxlags = lags_sec(maxi);  % as (t,chan,band,vox)
%minlags = lags_sec(mini);  % as (t,chan,band,vox)


if PLOT_MDS && ~isfield(RES,'mds'),
  RES = mrineucor_cluster(RES);
end

if isfield(RES,'clust'),
  RES = sub_select_clust(RES,CLUST_R);
end



for C = 1:NChan
  hfig = figure('Name',sprintf('%s %s(nexp=%d) Mri(%s) Neu(%s)',...
                               RES.session,RES.grpname,length(RES.exps),...
                               sub_text(RES.opts.roiname),...
                               sub_text(RES.opts.elename{C}) ));
  if NBand > 1,
    tmppos = get(gcf,'pos');
    tmppos(2) = tmppos(2) - tmppos(4);
    tmppos(4) = tmppos(4)*2;
    set(gcf,'pos',tmppos);
  end
  
  for K = 1:length(BANDS),
    B = BANDS(K);
    tmpr = squeeze(RES.dat(:,C,B,:));
    tmp = sum(tmpr,1);
    idx1 = find(tmp>0);
    idx2 = find(tmp<0);
    tmpr1 = tmpr(:,idx1);
    tmpr2 = tmpr(:,idx2);
    med1 = nanmedian(tmpr1,1);
    med2 = nanmedian(tmpr2,1);
    idx11 = find(med1>0.05);
    idx22 = find(med2<-0.05);
    tmpm1 = nanmean(tmpr1(:,idx11),2);
    tmpm2 = nanmean(tmpr2(:,idx22),2);
    
    if any(PLOT_MDS),
      subplot(NBand,3,3*(NBand-K)+1);
    else
      subplot(NBand,2,2*(NBand-K)+1);
    end
    if any(PLOT_MDS) && isfield(RES,'clust'),
      tmplags = squeeze(maxlags(1,C,B,:));
      tmpclust = RES.clust(C,B).index;
      tmpcolor = 'rgbcmyk';
      for X = 1:RES.clust(C,B).nclust,
        tmpidx = find(tmpclust == X);
        if isempty(tmpidx),  continue;  end
        hmax = hist(tmplags(tmpidx),lags_sec);
        h = bar(lags_sec, hmax,'hist');
        tmpc = tmpcolor(mod(X-1,length(tmpcolor))+1);
        set(h,'facecolor',tmpc,'edgecolor',tmpc);
        set(h,'faceAlpha',0.5);
        hold on;
      end
    else
      tmplags = squeeze(maxlags(1,C,B,:));
      tmplags = tmplags(idx11);
      hmax = hist(tmplags(:),lags_sec);
      tmplags = squeeze(maxlags(1,C,B,:));
      tmplags = tmplags(idx22);
      hmin = hist(tmplags(:),lags_sec);
      h = bar(lags_sec, hmax,'hist');
      set(h,'facecolor','r','edgecolor','r');
      hold on;
      h = bar(lags_sec,-hmin,'hist');
      set(h,'facecolor','b','edgecolor','b');
      ylm = get(gca,'ylim'); ymax = max(abs(ylm));  set(gca,'ylim',[-ymax ymax]);
    end
    if K == 1,
      xlabel('lags(s)');
    elseif K == NBand,
      title('max(abs)-lag histogram');
    end
    ylabel(RES.opts.band{B}{2});
    set(gca,'xlim',[lags_sec(1) lags_sec(end)]);
    set(gca,'layer','top');
    
    
    if any(PLOT_MDS),
      subplot(NBand,3,3*(NBand-K)+2);
    else
      subplot(NBand,2,2*(NBand-K)+2);
    end
    
    if any(PLOT_MDS) && isfield(RES,'clust'),
      tmpclust = RES.clust(C,B).index;
      tmpcolor = 'rgbcmyk';
      for X = 1:RES.clust(C,B).nclust,
        tmpidx = find(tmpclust == X);
        if isempty(tmpidx),  continue;  end
        tmpm = nanmean(tmpr(:,tmpidx),2);
        tmps = nanstd(tmpr(:,tmpidx),[],2) / sqrt(length(tmpidx));
        tmpc = tmpcolor(mod(X-1,length(tmpcolor))+1);
        h = ciplot(tmpm-tmps,tmpm+tmps,lags_sec,tmpc);
        setback(h);
        set(h,'facealpha',0.5);
        hold on;
        plot(lags_sec,tmpm,'color',tmpc);
      end
    else
      tmpm = nanmean(tmpr,2);
      tmps = nanstd(tmpr,[],2) / sqrt(size(tmpr,2));
      ciplot(tmpm-tmps,tmpm+tmps,lags_sec,[0.8 0.8 0.8]);
      hold on;
      plot(lags_sec,tmpm,'color','k','linewidth',2);
      plot(lags_sec,tmpm1,'r');
      hold on;
      plot(lags_sec,tmpm2,'b');
    end
    if K == 1,
      xlabel('lags(s)');
    elseif K == NBand,
      title('averaged corr coef');
    end
    set(gca,'xlim',[lags_sec(1) lags_sec(end)]);
    set(gca,'layer','top');
    grid on;
   
    if any(PLOT_MDS),
      if isempty(tmpr), continue;  end
      haxs = subplot(NBand,3,3*(NBand-K)+3);
      mdscoords = squeeze(RES.mds.coords(:,C,B,:));  % as (xy,vox)
      tmpclust = RES.clust(C,B).index;
      tmpcolor = 'rgbcmyk';
      if 1,
        tmpidx = find(tmpclust == -1);
        if any(tmpidx),
          plot(mdscoords(1,tmpidx),mdscoords(2,tmpidx),'linestyle','none',...
               'marker','o','markersize',1.5,'markerfacecolor','k',...
               'color','k');
          hold on;
        end
        for X = 1:RES.clust(C,B).nclust,
          tmpidx = find(tmpclust == X);
          if isempty(tmpidx),  continue;  end
          tmpc = tmpcolor(mod(X-1,length(tmpcolor))+1);
          plot(mdscoords(1,tmpidx),mdscoords(2,tmpidx),'linestyle','none',...
               'marker','o','markersize',1.5,'markerfacecolor',tmpc,...
               'color',tmpc);
          hold on;
        end
        grid on;
        set(haxs,'xlim',[-2 2],'ylim',[-2 2]);
      else
        edges = -1.9:0.01:1.9;
        densplot(mdscoords','xedges',edges,'yedges',edges,...
                 'smooth',7,'normalize',1,...               
                 'colorbar',0,'xlabel','','ylabel','',...
                 'markersize',1,'surface',0);
        hold on;
        for X = 1:RES.clust(C,B).nclust,
          tmpidx = find(tmpclust == X);
          if isempty(tmpidx),  continue;  end
          tmpx = nanmean(mdscoords(1,tmpidx),2);
          tmpy = nanmean(mdscoords(2,tmpidx),2);
          h = sub_plot_circle(tmpx,tmpy,CLUST_R,'color',tmpcolor(X));
        end
      end
      % text(0.01,0.005,sprintf('nvox=%d',size(tmpr,2)),...
      %      'units','normalized','verticalalignment','bottom');
      if K == 1,
        xlabel('mds');
      elseif K == NBand,
        title('mds');
      end
      drawnow;
    end
  end
end



return

% =========================================================
function RES = sub_select_clust(RES,D)
% =========================================================


% RES.clust(C,B) =
%    distance: 'sqEuclidean'
%      nclust: 2
%       costf: [Inf 0.0650 0.3751 0.2678 0.4122 0.4013 0.3935 0.4030 0.4861 0.4517]
%       index: [1x1022 double]    as (voxel)
%      center: [2x2 double]       as (clust,var)
%      clustd: [1022x2 double]    as (voxel,clust)


NChan = size(RES.dat,2);
NBand = size(RES.dat,3);
NVox  = size(RES.dat,4);

try
for C = 1:NChan
  for B = 1:NBand,
    idx = [];
    nclust = RES.clust(C,B).nclust;
    for L = 1:nclust,
      clustD = squeeze(RES.clust(C,B).clustd(:,L));
      tmpidx = (abs(clustD) > D);
      if isempty(idx),
        idx = tmpidx;
      else
        idx = idx & tmpidx;
      end
    end
    RES.clust(C,B).index(idx) = -1;
  end
end
catch
  keyboard
end

return


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h = sub_plot_circle(x,y,r,varargin)
ang = 0:0.01:2*pi; 
xr  = r*cos(ang);
yr  = r*sin(ang);
h = plot(x+xr,y+yr,'marker','none',varargin{:});

return



% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function txt = sub_text(Vars)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isempty(Vars),
  txt = 'all';
elseif isnumeric(Vars),
  txt = deblank(sprintf('%g ',Vars));
elseif iscell(Vars),
  txt = '';
  for N = 1:length(Vars),
    txt = strcat(txt,sprintf(' %s',Vars{N}));
  end
  txt = strtrim(txt);
elseif ischar(Vars),
  txt = Vars;
else
  txt = '';
end

return


