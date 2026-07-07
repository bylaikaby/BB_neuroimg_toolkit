function dspfratio(blp,idx)
%DSPFRATIO - Display the F-Ratio of all regressors (N=45) as surface
% DSPFRATIO(blp)
%   blp.sesname = SesName;
%   blp.grpname = GrpName;
%   blp.roiname = RoiName;
%   blp.xlabel  = 'Center Frequency in Hz';
%   blp.ylabel  = 'F-Ratio';
%   blp.x       = [1:length(F_ratB)]';
%   blp.y       = double(F_ratB(:));
%   blp.p       = double(p_ratB(:));
%   blp.betas   = betas;
%   blp.pvalues = pvalues;
%
%   blp.xlim          = [0 length(F_ratB)+1];
%   blp.xticklabel    = grp.bandnames;
%
% >> dspfratio(blp,[2 7 10 12 13]);       -- Very good!
% >> dspfratio(blp,[1 2 3 6 7 11 12 13])  -- All
% >> dspfratio(blp);
%
% NKL 19.01.2008
%
%  See also algetfratio

if nargin < 2,
  idx = [1:size(blp.y,2)];
end;

blp.y = blp.y(:,idx);
blp.p = blp.p(:,idx);
if size(blp.betas,2)>length(idx),
  blp.betas = blp.betas(:,idx);
  blp.serror = blp.serror(:,idx);
end;

subplot(2,1,1);
m = hnanmean(blp.y,2);
s = std(blp.y,1,2)/sqrt(size(blp.y,2));
hd2 = errorbar(blp.x, m, s);
eb = findall(hd2);
set(eb(1),'LineWidth',2,'Color','k');
set(eb(2),'LineWidth',2,'Color','b','marker','none','linestyle','none',...
          'markeredgecolor','k','markerfacecolor','b','markersize',12);
hold on;
% bar(blp.x, hnanmean(blp.y,2),'facecolor','k','edgecolor','g');
bar(blp.x, hnanmean(blp.y,2),'facecolor','k','edgecolor','g');
set(gca,'xlim', blp.xlim);
set(gca,'xtick',[1:length(blp.xticklabel)]);
set(gca,'xticklabel', blp.xticklabel);
ylabel('F Ratio');
title('F Ratio for Different Bands','fontweight','bold');
for N=1:length(blp.x),
  text(blp.x(N), 1, sprintf('%.6f', median(blp.p(N,:),2)),'fontsize',8,...
       'rotation',90,'color','w','fontweight','normal');
end;
YLIM = get(gca,'ylim');

subplot(2,1,2);
m = hnanmean(blp.betas,2);
s = hnanmean(blp.serror,2);
hd2 = errorbar(blp.x, m, s);
eb = findall(hd2);
set(eb(1),'LineWidth',2,'Color','k');
set(eb(2),'LineWidth',2,'Color','b','marker','none','linestyle','none',...
          'markeredgecolor','k','markerfacecolor','b','markersize',12);
hold on;
bar(blp.x, hnanmean(blp.betas,2),'facecolor','k','edgecolor','g');
set(gca,'xlim', blp.xlim);
set(gca,'xtick',[1:length(blp.xticklabel)]);
set(gca,'xticklabel', blp.xticklabel);
ylabel('Beta');
title('Beta values for Different Bands','fontweight','bold');
YLIM = get(gca,'ylim');
txt = sprintf('algetfratio(''%s'',''%s'') - IDX: ', blp.arg1, blp.arg2);
txt1 = sprintf('%d ', idx);
suptitle(strcat(txt,txt1));





