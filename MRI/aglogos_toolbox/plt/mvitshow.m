function mvitshow(ecg,resp)
%MVITSHOW - show ECG and PLETH traces
%	mvitshow(ecg,resp) - show ECG and PLETH traces

rows = size(ecg.raw,2);
figure('Position',[10 60 1000 850]);
for K=1:rows,
  t = ecg.rawdx * [1:size(ecg.raw,1)];
  subplot(rows,2,2*K-1);
  plot(t,ecg.raw(:,K));
  line([ecg.beg ecg.beg],get(gca,'ylim'),'Color','r');
  line([ecg.end ecg.end],get(gca,'ylim'),'Color','r');
  set(gca,'xlim',[1 t(end)]);
  subplot(rows,2,2*K);
  plot(t,resp.raw(:,K));
  line([ecg.beg ecg.beg],get(gca,'ylim'),'Color','r');
  line([ecg.end ecg.end],get(gca,'ylim'),'Color','r');
  set(gca,'xlim',[1 t(end)]);
end

figure('Position',[100 60 1000 850]);
t = ecg.dx * [1:size(ecg.dat,1)];
subplot(2,1,1);
plot(t,ecg.dat);
line([ecg.beg ecg.beg],get(gca,'ylim'),'Color','r');
line([ecg.end ecg.end],get(gca,'ylim'),'Color','r');
subplot(2,1,2);
plot(t,resp.dat);
line([ecg.beg ecg.beg],get(gca,'ylim'),'Color','r');
line([ecg.end ecg.end],get(gca,'ylim'),'Color','r');


