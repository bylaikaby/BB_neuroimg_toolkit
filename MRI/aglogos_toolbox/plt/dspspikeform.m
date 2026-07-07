function dspspikeform(Spf)
%DSPSPIKEFORM - show spike wave forms
% DSPSPIKEFORM shows the results of the function getspkform,
% which detect the spike location and move the spike wave form
% into an array with columns the detected spikes.
% NKL 29.05.03	
for N=1:length(Spf),
  t = [0:size(Spf.dat,1)-1]*Spf.dx*1000;
  eb = errorbar(t,mean(Spf.dat,2),std(Spf.dat,1,2));
  hold on;
  plot(t,mean(Spf.dat,2),'linewidth',2,'color','r');
  set(gca,'xlim',[t(1) t(end)]);
  line([Spf.SpikePreTime Spf.SpikePreTime],get(gca,'ylim'),...
	   'linewidth',1,'color','r','linestyle',':');
end;
xlabel('Time in milliseconds');
ylabel('ADC points');
title(sprintf('%s, %s, %d', Spf.session,Spf.grpname,Spf.ExpNo));
grid on;
