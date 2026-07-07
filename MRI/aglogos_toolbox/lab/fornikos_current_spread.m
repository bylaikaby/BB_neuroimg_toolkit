%FORNIKOS_CURRENT_SPREAD

load('y:\mri\matlab\lab\current_spread.mat');

mfigure([100 100 700 550]);
set(gcf,'color','k');
set(gcf,'DefaultAxesfontsize',	14);
set(gcf,'DefaultAxesfontweight','bold');

plot(current,spread,'cs','markersize',8,'markeredgecolor','w','markerfacecolor','c');
hold on;
axis([.1 10000 .01 10]);
box on;
axis square
set(gca,'xscale','log');
set(gca,'yscale','log');
set(gca,'color','k','xcolor','y','ycolor','y');

hold on;
r=[.01:0.01:10];
I=[.1:0.01:10000];
k1=1292;
r = sqrt(I./k1);
plot(I,r,'-w','linewidth',2);hold on;

xlabel('Current in MicroA');
ylabel('Radius in mm');

