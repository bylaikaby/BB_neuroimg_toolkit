function showspkform(SESSION, FILESPEC)
%SHOWSPKFORM - Show spike wave forms averaged after amplitude selection (wform field)
% showspkform(SESSION, FILESPEC) - assumes that SESSPKTRIGAVR was run for Cln and with a window
% of less than or equal to 0.05ms.
%

BSTRP       = 1000;         % low and high confidence interval
CIVAL       = [1 99];       % low and high confidence interval

if nargin < 2,
  help showspkform;
  return;
end;

Sig = sigload(SESSION, FILESPEC, 'SpktCln');
if iscell(Sig),
  Sig = Sig{1};
end;

if ischar(FILESPEC),
  grp = getgrpbyname(SESSION, FILESPEC);
else
  grp = getgrp(SESSION, FILESPEC);
end;

if ~isfield(Sig,'wform'),
  fprintf('SHOWSPKFORM: No wform field found\n');
  help showspkform;
  return;
end;

t = [0:size(Sig.wform,1)-1] * 1000 * Sig.dx;  % in ms
if ~isfield(grp,'spktrgavg'),
  lag = 0.025;
  range = {[0.1 0.3], [0.4 0.7], [0.85 1]}; % fraction of amplitudes
else
  lag = grp.spktrgavg;
  range = grp.spktrgrange;
end;
lag = lag * 1000;

mfigure([100 200 700 900]);
set(gcf,'DefaultAxesfontsize',12);

t = t - lag;
y = Sig.wform;
s = size(y);
y = reshape(y,[s(1) s(2) prod(s(3:end))]);
mu = hnanmean(y,3);

for N=1:size(mu,2),
  subplot(size(mu,2),1,N);
  Boot = bootstrp(BSTRP,@hnanmean,mu');
  Cinter = prctile(Boot,CIVAL);
  ciplot(Cinter(1,:),Cinter(2,:),t,[.8 .8 .8]);
  hold on
  plot(t, mu(:,N),'color','k','linewidth',2);
  ylabel('SD Units');
  set(gca,'xlim',[-5 5]);
  ylim = get(gca,'ylim');
  maxylim = max(abs(ylim));
  ylim = [-maxylim maxylim];
  set(gca,'ylim',ylim);
  grid on;
  title(sprintf('Range: [%3d-%3d] percent', round(range{N}*100)));
end;
xlabel('Time in mseconds');

if ischar(FILESPEC),
  suptitle(sprintf('Session %s, Group %s', SESSION, FILESPEC));
else
  suptitle(sprintf('Session %s, Experiment %d', SESSION, FILESPEC));
end;

