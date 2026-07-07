function plot_fidtkcca(RES,varargin)
%
%
%  EXAMPLE :
%    res = fidtkcca('ratpe2',2);
%    plot_fidtkcca(res)
%
%  VERSION :
%    0.90 21.05.14 YM  pre-release
%
%  See also fidtkcca

if nargin < 1,  eval(['help ' mfilename]); return;  end


if length(RES.exps) > 1
  % grouped data
  RES.canonical_correlogram = nanmean(RES.canonical_correlogram,3);
  RES.fmri.weights = nanmean(RES.fmri.weights,3);
  for iCh = 1:numel(RES.ephys)
    RES.ephys(iCh).weights  = nanmean(RES.ephys(iCh).weights,3);
    RES.ephys(iCh).xcorr    = nanmean(RES.ephys(iCh).xcorr,2);
    RES.ephys(iCh).ccr_conv = nanmean(RES.ephys(iCh).ccr_conv,2);
    RES.ephys(iCh).ccp_conv = nanmean(RES.ephys(iCh).ccp_conv,2);
  end
end




T_LAG = RES.lags*RES.dx;

hfig = figure;
tmppos = get(hfig,'pos');
tmppos(2) = tmppos(2)-tmppos(4);
tmppos(4) = tmppos(4)*2;
tmppos(3) = tmppos(3)*1.5;
set(hfig,'pos',tmppos);

subplot(2,2,1);
plot(T_LAG,RES.canonical_correlogram);
set(gca,'xlim',[T_LAG(1) T_LAG(end)]);  grid on;
xlabel('Lags (s)');
ylabel('canonical r');
title(sprintf('canonical correlogram %s-%s',RES.opts.sigs{1},RES.opts.sigs{2}));

subplot(2,2,3);
col = lines(64);
legtxt = {};
for iCh = 1:numel(RES.ephys)
  tmpres = RES.ephys(iCh);
  tmpcol = col(mod(iCh-1,size(col,1))+1,:);
  tmpt = tmpres.lags*tmpres.dx;
  plot(tmpt,tmpres.xcorr,'color',tmpcol);
  hold on;
  legtxt{iCh} = tmpres.ele;
end
set(gca,'xlim',[T_LAG(1) T_LAG(end)]);  grid on;
xlabel('Lags (s)');
ylabel('corr.coef r');
title('weighted xcorr');
legend(legtxt);


Nrow = 1 + numel(RES.ephys);

subplot(Nrow,2,2);
bar(1:length(RES.fmri.weights),RES.fmri.weights,'b');
set(gca,'xlim',[0 length(RES.fmri.weights)+1]);
ylabel('value');
title(sprintf('%s weights',RES.opts.sigs{2}));
tmpw = [];
for iCh = 1:numel(RES.ephys)
  tmpw = cat(3,tmpw,RES.ephys(iCh).weights);
end
tmpwm = nanmean(tmpw(:));
tmpws = nanstd(tmpw(:));
for iCh = 1:numel(RES.ephys)
  if iCh == 1,
    bname = {};
    for K = 1:length(RES.ephys(iCh).band)
      bname{K} = RES.ephys(iCh).band{K}{2};
    end
  end
  subplot(Nrow,2,(1+iCh)*2);
  tmpres = RES.ephys(iCh);
  tmpt = tmpres.lags*tmpres.dx;
  tmpw = tmpres.weights;
  tmpw = (tmpw - tmpwm) / tmpws;
  imagesc(tmpt,1:size(tmpw,1),abs(tmpw));
  set(gca,'clim',[0 3]);
  tmpd = (tmpt(2)-tmpt(1))/2;
  set(gca,'xlim',[tmpt(1)-tmpd tmpt(end)+tmpd]);
  set(gca,'ytick',1:size(tmpw,1),'yticklabel',bname,'ydir','normal');
  title(sprintf('%s normalized weight (abs)',tmpres.ele));
end
%colormap(jet(256));
colormap(summer(256));
xlabel('Lags (s)');


if length(RES.exps) > 1
  % grouped data
  tmptxt = sprintf('tkcca %s %s(nexp=%d)',RES.session,RES.grpname,length(RES.exps));
else
  tmptxt = sprintf('tkcca %s Exp=%d',RES.session,RES.exps);
end
figtitle(tmptxt);
set(gcf,'Name',tmptxt);


return
