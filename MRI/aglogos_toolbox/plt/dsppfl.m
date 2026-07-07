function dsppfl(pfl)
%DSPPFL - display image and intensity profiles
% NKL, 29.12.02

figure('position',[50 100 900 500]);
subplot('position',[0.05 0.08 .3 .82]);
imagesc(pfl.dat');
colormap(gray);
daspect([1 1 1]);
hold on
for N=1:size(pfl.x,2),
	plot(pfl.y(:,N),pfl.x(:,N),'r');
end;

subplot('position',[0.45 0.08 .52 .82]);
area(hnanmean(pfl.v,2),'facecolor',[.5 .5 .7],'edgecolor','k','linewidth',2);
y = get(gca,'ylim');
set(gca,'ylim',[y(1) y(2)*1.2]);
set(gca,'xlim',[1 size(pfl.v,1)]);
set(gca,'xtick',[0:5:size(pfl.v,1)]);
grid on;
xlabel('Voxel Number');
ylabel('Voxel Intensity');
