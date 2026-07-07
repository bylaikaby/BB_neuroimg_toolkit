function showbold(SesName, RoiName, PVAL)
%SHOWBOLD - Show BOLD responses to stimulus for each SUPERGROUP (SCA Experiments)
% SHOWBOLD (SesName,GrpName,RoiName)
% 
% NKL 16.02.09

if nargin < 3,
  PVAL = 0.01;
end;

if nargin < 2,
  RoiName = 'brain';
end;

if nargin < 1,
  help showbold;
  return;
end;

Ses = goto(SesName);
anap = Ses.anap;

t1grp = anap.t1grp;
t1ana = anap.t1ana;
NoSupGrp = length(t1grp);

YLIM    = t1ana.boldylim;
BSTRP   = t1ana.bstrp;
COL     = t1ana.color;
MODEL   = t1ana.model;
ROW     = t1ana.nplots(1);
CLM     = t1ana.nplots(2);

if ROW == 2,
  mfigure([100 100 1300 1000]);
else
  mfigure([100 100 1300 600]);
end;

for SG = 1:NoSupGrp,
  iG = 1;
  for G = 1:length(t1grp{SG}.grp),
    Sig             = sigload(Ses,t1grp{SG}.grp{G},'troiTs');
    if Sig{1}.dx > 2, continue; end;
    Sig             = mvoxselect(Sig,RoiName,MODEL,[],PVAL);
    roiTs{iG}        = xform(Sig,'zerobase');
    str.color(iG)    = COL(G);
    str.legend{iG}   = t1grp{SG}.grp{G};
    iG = iG + 1;
  end;
  
  str.plottype      = 'ci';    % options: mean, err, ci
  str.bstrp         = BSTRP;
  str.ylim          = YLIM;
  str.linewidth     = 2;
  TR_TXT = sprintf('%d ',t1grp{SG}.TR);
  str.title         = sprintf('%s<%s>,%s\nTR=%s,TE=%g,FA=%d',...
                      upper(t1grp{SG}.grpname), RoiName, MODEL, TR_TXT,t1grp{SG}.TE, t1grp{SG}.FA);
  subplot(ROW,CLM,SG);
  subPlotTC(roiTs, str);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subPlotTC(roiTs, str)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for N=1:length(roiTs),
  t = [1:size(roiTs{N}.dat,1)]*roiTs{N}.dx;
  y = hnanmean(roiTs{N}.dat,2);
  if ~isnan(y) & ~all(y==0),
    Boot = bootstrp(str.bstrp,@hnanmean,roiTs{N}.dat');
    Cinter = prctile(Boot,[5,95]); % the 1 and 99% intervals
    switch str.color(N),
     case 'r',
      COL_FACE = [1 .7 .7];
     case 'b',
      COL_FACE = [.7 .7 1];
     case 'g',
      COL_FACE = [.7 1 .7];
     otherwise,
      COL_FACE = [.8 .8 .8];
    end;
    if size(Cinter,2) == size(t,2),
      ciplot(Cinter(1,:),Cinter(2,:),t,COL_FACE);
    end;
  end;
  hold on
  hd(N) = plot(t, y,'linewidth',1,'color',str.color(N),'linewidth',str.linewidth);
end;

set(gca,'xlim',[t(1) t(end)]);;
if ~isempty(str.ylim),
  set(gca,'ylim',str.ylim);
end;

drawstmlines(roiTs{1});
box on; set(gca,'ygrid','on');
hold off;
set(gca,'layer','top');
xlabel('Time in seconds');
ylabel('Percent Signal Change');
if exist('hd','var') & ~isempty(hd),
  [h, h1] = legend(hd,str.legend{:},'Location','northwest');
  set(h,'FontWeight','normal','FontSize',8,'color',[.7 .7 .7],'edgecolor','k');
  set(h,'xcolor','w','ycolor','w');
end
title(str.title);
return;



