function plot_mrineucor(RES)
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
%  See also sesmrineucor expmrineucor


RES.dat = nanmean(RES.dat,5);


NChan = size(RES.dat,2);
NBand = size(RES.dat,3);
NVox  = size(RES.dat,4);


lags_sec = RES.lags_pts * RES.dx;

[maxv maxi] = max(abs(RES.dat),[],1);


maxlags = lags_sec(maxi);  % as (t,chan,band,vox)
%minlags = lags_sec(mini);  % as (t,chan,band,vox)

BANDS = 4:8;
NBand = length(BANDS);

for C = 1:NChan
  figure('Name',sprintf('%s %s(nexp=%d) Mri(%s) Neu(%s)',...
                        RES.session,RES.grpname,length(RES.exps),...
                        sub_text(RES.opts.roiname),...
                        sub_text(RES.opts.elename{C}) ));
  tmppos = get(gcf,'pos');
  tmppos(2) = tmppos(2) - tmppos(4);
  tmppos(4) = tmppos(4)*2;
  set(gcf,'pos',tmppos);
  
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
    
    
    subplot(NBand,2,2*(NBand-K)+1);
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
    if K == 1,
      xlabel('lags(s)');
    elseif K == NBand,
      title('max/min-lag histogram');
    end
    ylabel(RES.opts.band{B}{2});
    set(gca,'xlim',[lags_sec(1) lags_sec(end)]);
    set(gca,'layer','top');
    ylm = get(gca,'ylim'); ymax = max(abs(ylm));  set(gca,'ylim',[-ymax ymax]);
    
    
    subplot(NBand,2,2*(NBand-K)+2);

    plot(lags_sec,tmpm1,'r');
    hold on;
    plot(lags_sec,tmpm2,'b');
%    tmpm = nanmean(tmpr,2);
%    tmps = nanstd(tmpr,[],2) / sqrt(size(tmpr,2));
%    ciplot(tmpm-tmps,tmpm+tmps,lags_sec,[0.7 0.7 0.9]);
%    hold on;
%    plot(lags_sec,tmpm,'color','b');
    if K == 1,
      xlabel('lags(s)');
    elseif K == NBand,
      title('averaged corr coef');
    end
    set(gca,'xlim',[lags_sec(1) lags_sec(end)]);
    set(gca,'layer','top');
    grid on;
  end
end


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


