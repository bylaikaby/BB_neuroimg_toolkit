%CHRONAXIE - Demo for chronaxie computation
%
clear all;
mfigure([100 100 550 500]);
set(gcf,'color','k');

ofs=100;
for N=1:4,
  cur = [0:550];
  v = 20+1.125*140*cumsum(normpdf(cur,225,100));
  plot(cur+ofs,v,'c');
  hold on;
  
  cur = [0:70:550];
  r = 20*rand(1,length(cur));
  v = v(cur+1)+r-10;
  plot(cur+ofs,v,'rs','markersize',10,'markerfacecolor','w');
  set(gca,'xcolor','w','ycolor','w','color','k');
  set(gca,'ylim',[0 200]);
  set(gca,'xlim',[0 1600]);
  xlabel('Current in mA');
  ylabel('Volume in mm3');
  ofs=ofs+300;
end;
