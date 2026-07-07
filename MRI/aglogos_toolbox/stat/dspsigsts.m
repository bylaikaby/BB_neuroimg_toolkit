function hd = dspsigsts(sts)
%DSPSIGSTS - Display signal statistics
% DSPSIGSTS (sts) - Display statistics of each recording channel. The display mode depends on
% the type of statistics computed by sigsts. Statistic computed for the entire observation
% period (blank+nonblank), indicated by WinLen < 0, will display the mean, median, std and iqr
% of the signal for each channel in bar-plots.
%
% Running statistics (defined through WinLen/Overlap) will be displayed in 4 subplots
% (mean,median, std, iqr) as time plots with multiple timeseries, each for an electrode
% channel.
%
% Blank/Non-Blank Statistics are displayed like the entire-signal statistics, but with two
% adjacent bars, one for each epoch.
%
% Structure returned by sigsts (sts = sigsts(Sig)). Example taken from c98nm1/ExpNo=1
%      mean: [1x15 double]
%     median: [1x15 double]
%        std: [1x15 double]
%        iqr: [1x15 double]
%        dsp: [1x1 struct]
%       chan: [1 2 3 4 5 6 7 8 9 10 11 16 13 14 15]
%
% NKL, 13.12.01

if nargin < 1,
  help dspsigsts;
  return;
end;

figure('position',[30 50 800 800]);
set(gcf,'DefaultAxesfontsize', 8);

if size(sts.mean,1) == 1,       % NO WINDOW/OVERLAP
  COL=4; ROW=4;
  COLOR='kgbrm';
  mx=max([sts.mean(:) sts.std(:) sts.median(:) sts.iqr(:)]);
  mx = max(mx(:));
  for N = 1:length(sts.chan),
    ChanNo = sts.chan(N);
    subplot(ROW,COL,ChanNo);
    y = [sts.mean(:,N) sts.median(:,N) sts.std(:,N) sts.iqr(:,N)]';
    for K=1:4,
      hold on;
      bar(K,y(K),'facecolor',COLOR(K));
    end;
    xlabel('Mean Med STD IQR');
    set(gca,'ylim',[0 mx],'xlim',[0 5],'xtick',[0:5]);
    title(sprintf('[%d]: Chan = %d', N, ChanNo));
  end;

elseif size(sts.mean,1) == 2,   % BLANK/NON-BLANK
  COL=4; ROW=4;
  COLOR='kgbrm';
  mx=max([sts.mean(:) sts.std(:) sts.median(:) sts.iqr(:)]);
  mx = max(mx(:));
  for N = 1:length(sts.chan),
    ChanNo = sts.chan(N);
    subplot(ROW,COL,ChanNo);
    bar([sts.mean(:,N) sts.median(:,N) sts.std(:,N) sts.iqr(:,N)]');
    xlabel('Mean Med STD IQR');
    set(gca,'ylim',[-mx/2 mx],'xlim',[0 5],'xtick',[0:5]);
    title(sprintf('[%d]: Chan = %d', N, ChanNo));
  end;
  
else                            % WINDOWS WITH OVERLAP
  t = [0:size(sts.mean,1)-1]*sts.dx;
  subplot(2,2,1);
  plot(t,sts.mean);
  set(gca,'xlim',[t(1) t(end)]); grid on;
  xlabel('Time (sec)'); title('Running Mean');
  subplot(2,2,2);
  plot(t,sts.median);
  set(gca,'xlim',[t(1) t(end)]); grid on;
  xlabel('Time (sec)'); title('Running Median');
  
  subplot(2,2,3);
  plot(t,sts.std);
  set(gca,'xlim',[t(1) t(end)]); grid on;
  xlabel('Time (sec)'); title('Running STD');
  subplot(2,2,4);
  plot(t,sts.iqr);
  set(gca,'xlim',[t(1) t(end)]); grid on;
  xlabel('Time (sec)'); title('Running IQR');
  
end;

