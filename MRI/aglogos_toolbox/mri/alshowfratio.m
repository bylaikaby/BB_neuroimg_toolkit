function alshowfratio(FileSpec)
%ALSHOWFRATIO - Show the F-Ratio of reduced-to-full design matrix for each frequency band
% alshowfratio(SesName, GrpName) shows for one or more sessions the fratio results
%
% EXAMPLES:
%       alshowfratio('kf');           The 5 best sessions
%       alshowfratio('kfall');        All OK sessions
%       alshowfratio('n02gu1');       (Default group = 'fix')
%
% NKL 23.01.2008

if nargin < 1,  help alshowfratio; return;    end;

FileSpec = strcat('alfratio_',FileSpec);

supgroupload(FileSpec);

mfigure([100 100 900 800]);
dspfratio(blp);
return;

  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Multiple Sessions results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subPlotMultipleSessions(fratio)
%mfigure([100 300 900 800]);
mfigure([100 200 700 600]);
m = hnanmean(fratio.y,2);
m = median(fratio.y,2);
s = std(fratio.y,1,2)/sqrt(size(fratio.y,2));
hd2 = errorbar(fratio.x, m, s);
eb = findall(hd2);
set(eb(1),'LineWidth',0.5,'Color','k','linestyle','none','linewidth',2);
set(eb(2),'LineWidth',2,'Color','b','marker','none','linestyle','none',...
          'markeredgecolor','k','markerfacecolor','b','markersize',12);
hold on;
bar(fratio.x, m);
hold on;
st = m+s+1;
p = median(fratio.p,2);
s01 = find(p<0.01);
s001 = find(p<0.001);

if 0,
  plot(fratio.x(s01), st(s01),'linestyle','none','marker','*','markersize',10,...
       'markerfacecolor','g','markeredgecolor','g');
  plot(fratio.x(s001), st(s001),'linestyle','none','marker','*','markersize',10,...
       'markerfacecolor','r','markeredgecolor','r');
else
  for N=1:length(st),
    text(fratio.x(N), 2, sprintf('%.6f', p(N)),'fontsize',10,...
         'rotation',90,'color','w','fontweight','bold');
  end;
end;

set(gca,'xlim',fratio.xlim);
set(gca,'xtick',[1:length(fratio.xticklabel)]);
set(gca,'xticklabel',fratio.xticklabel);
xlabel(fratio.xlabel);
ylabel(fratio.ylabel);
grid on;
s1 = 'F-Ratio for 15 LFP bands (W=10Hz) & MUA';
s2 = sprintf('getfratio(%s,%s)/alshowfratio(fratio,kf)', fratio.arg1, fratio.arg2);
s3 = 'p <= 0.01 (Green Asterisk), p <= 0.001 (Red Asterisk)';
title({s1;s2;s3});
set(gca,'layer','top');
grid off
return;


