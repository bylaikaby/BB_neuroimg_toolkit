function dsprms(rms)
%DSPRMS - Display the RMS values as bar graphs
% DSPRMS Displays the RMS values as bars, whereby each bar
% corresponds to one epoch.
% NKL 28.06.04

COLOR = 'kgbmcy';
hd = bar(rms.dat);
ylabel('RMS');
xlabel('Channel Number');
for N=1:length(hd),
  if strncmp(rms.names{N},'stim',4) | strncmp(rms.names{N},'movi',4),
    set(hd(N),'facecolor','r','edgecolor','r');
  else
    set(hd(N),'facecolor',COLOR(N),'edgecolor',COLOR(N));
  end;
end;

title('Signal RMS Value');
set(gca,'xlim',[0 16],'xtick',[0:2:16]);
