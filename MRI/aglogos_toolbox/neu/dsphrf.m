function dsphrf(hrf)
%DSPHRF - Plot a HRFs for different neural signals (e.g. blp)
% DSPHRF (hrf), depending on input arguments, plots the time course of a band or all bands
% in spectrogram form.
%
% NKL, 01.06.08

if nargin < 1,                  % roiTs must be defined as input
  help dsphrf;
  return;
end;

mfigure([100 250 1300 650]);

hrfNames = {'dethe','alpha','nm1','nm2','gamma','hgamma','mua'};
hrf.dat = nanmean(hrf.dat,3);

t = [0:size(hrf.dat,1)-1]*hrf.dx;

if strcmp(hrf.info.signame,'ClnSpc'),
  for N=1:size(hrf.dat,2),
    plot(t,nanmean(hrf.dat,2),'color','k','linewidth',1);
    ylabel('r Value');
    xlabel('Time in seconds');
    set(gca,'xlim',[t(1) t(end)]);
    set(gca,'xtick',[t(1):2:t(end)]);
    grid on;
    title('Mean ClnSpc');
  end;
else
  for N=1:size(hrf.dat,2),
    subplot(2,4,N);
    plot(t,hrf.dat(:,N),'color','k','linewidth',1);
    ylabel('Area-normalized amplitude');
    xlabel('Time in seconds');
    set(gca,'xlim',[t(1) t(end)]);
    set(gca,'xtick',[t(1):2:t(end)]);
    grid on;
    title(hrfNames{N});
  end;
end;
return;
  
legend(hrfNames);


