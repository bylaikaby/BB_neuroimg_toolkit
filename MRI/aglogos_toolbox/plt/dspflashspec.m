function dspflashspec(Sig)
%DSPFLASHSPEC - Show spectral power distribution of a signal
% DSPFLASHSPEC is usually used to plot the results of the function
% flashspec etc.

f = [0:size(Sig.dat,1)-1]*Sig.dx;
plot(f, Sig.dat(:,1),'color','k','linewidth',1);
set(gca,'xscale','log');
set(gca,'xlim',[10 3000]);
grid on;
line([30 30],get(gca,'ylim'),'color','r','linewidth',2);
line([100 100],get(gca,'ylim'),'color','r','linewidth',2);
line([600 600],get(gca,'ylim'),'color','b','linewidth',2);
line([2900 2900],get(gca,'ylim'),'color','b','linewidth',2);

