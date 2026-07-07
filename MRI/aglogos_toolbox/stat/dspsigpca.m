function dspsigpca(PCSIG)
%DSPSIGPCA - plots data computed by SIGPCA.
%  DSPSIGPCA(PCSIG) - plots PCSIG, PCs of the signal that computed by SIGPCA.
%
%  VERSION :
%    0.90 05.04.06 YM  pre-release
%
%  See also SIGPCA

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end

if iscell(PCSIG)
  if iscell(PCSIG{1}),
    [NROW NCOL] = subGetRowCol(length(PCSIG{1}));
    for N = 1:length(PCSIG),
      figure('Name',sprintf('%s: %s',datestr(now),mfilename));
      for T = 1:length(PCSIG{N}),
        subplot(NROW,NCOL,T);
        subPlotPCA(PCSIG{N}{T});
        title(sprintf('TRIAL=%d:%s',T,PCSIG{N}{T}.stm.labels{1}));
        if T ~= length(PCSIG{N}), legend('off');  end
      end
      if isfield(PCSIG{N}{1},'name'),
        tmptitle = sprintf('%s: ROI=%s',mfilename,PCSIG{N}{1}.name);
      else
        tmptitle = sprintf('%s: %d',mfilename,N);
      end
      set(gcf,'Name',tmptitle);
    end
  else
    for N = 1:length(PCSIG),
      subPlotPCA(PCSIG{N});
      if isfield(PCSIG{N},'name'),
        tmptitle = sprintf('%s: ROI=%s',mfilename,PCSIG{N}.name);
      else
        tmptitle = sprintf('%s: %d',mfilename,N);
      end
      set(gcf,'Name',tmptitle);
    end
  end
  return;
elseif size(PCSIG.dat,3) > 1,
  % pca of blp
  % PCSIG.dat = (t,pcs,bands)
  error('\n ERROR %s: pca of blp not supported.\n');
  for N = 1:size(PCSIG.dat,3),

  end
end



figure('Name',sprintf('%s: %s',datestr(now),mfilename));
subPlotPCA(PCSIG);


return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [NROW NCOL] = subGetRowCol(NPLOT)
if NPLOT == 1,
  NROW = 1; NCOL = 1;
elseif NPLOT == 2,
  NROW = 1; NCOL = 2;
elseif NPLOT == 3,
  NROW = 1; NCOL = 3;
elseif NPLOT == 4,
  NROW = 2; NCOL = 2;
elseif NPLOT <= 6,
  NROW = 2; NCOL = 3;
elseif NPLOT <= 9,
  NROW = 3; NCOL = 3;
elseif NPLOT <= 12,
  NROW = 3; NCOL = 4;
elseif NPLOT <= 16,
  NROW = 4; NCOL = 4;
else
  NROW = 5; NCOL = 5;
end

return;
 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subPlotPCA(PCSIG)

COL = lines(256); legtxt = {};
for N = 1:size(PCSIG.dat,2),
  if isfield(PCSIG,'t') & ~isemtpy(PCSIG.t),
    t = PCSIG.t;
  else
    t = [0:length(PCSIG.dat)-1]*PCSIG.dx;
  end
  tmph = plot(t, PCSIG.dat(:,N),'color',COL(N,:));
  if N <= 2,  set(tmph,'linewidth',2);  end
  hold on;
  legtxt{N} = sprintf('PC-%d',N);
  stm = PCSIG.stm;
end
legend(legtxt);

grid on;
set(gca,'xlim',[0 max(t)]);
xlabel('Time in sec');  ylabel('Amplitude');
tmptitle = sprintf('%s: %s DX=%.3fs',mfilename,PCSIG.dir.dname,PCSIG.dx);
title(strrep(tmptitle,'_','\_'));

ylm = get(gca,'ylim');  tmph = ylm(2)-ylm(1);
h = [];
if isfield(PCSIG,'stm') & ~isempty(PCSIG.stm),
  if length(PCSIG.stm.time{1}) == 1,
    PCSIG.stm.time{1}(2) = PCSIG.stm.time{1}(1) + PCSIG.stm.dt{1}(1);
  else
    PCSIG.stm.time{1}(end+1) = size(PCSIG.dat,1)*PCSIG.dx;
  end
  for S = 1:length(stm.v{1}),
    if any(strcmpi(PCSIG.stm.stmtypes{stm.v{1}(S)+1},{'blank','none'})),  continue;  end
    ts = PCSIG.stm.time{1}(S);
    te = PCSIG.stm.time{1}(S+1);
    tmpw = te-ts;
    h(end+1) = rectangle('pos',[ts ylm(1) tmpw  tmph],...
                         'facecolor',[0.85 0.85 0.85],'linestyle','none');
    line([ts ts],ylm,'color',[0 0 0]);
    line([te te],ylm,'color',[0 0 0]);
  end
end
% how this happens?
ylm = get(gca,'ylim');  tmph = ylm(2)-ylm(1);
for N = 1:length(h),
  pos = get(h(N),'pos');
  pos(4) = tmph;
  set(h(N),'pos',pos);
end
  

setback(h);

set(gca,'layer','top');

return;
