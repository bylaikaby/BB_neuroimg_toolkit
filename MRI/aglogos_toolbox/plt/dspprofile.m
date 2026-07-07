function dspprofile(tcImg,cond,roi)
%DSPPROFILE - display intenstity profile of cortex
%	DSPPROFILE(tcImg,grd)
%	NKL, 17.11.02

ix1 = getcond(tcImg,cond(1));
ix2 = getcond(tcImg,cond(2));

img1 = mean(tcImg.dat(:,:,ix1),3);
img2 = mean(tcImg.dat(:,:,ix2),3);
tcImg.dat = img1 - img2;

grd = mgetprofiles(tcImg, roi);

figure('position',[50 100 800 500]);
subplot(1,2,1);
imagesc(tcImg.dat);
colormap(gray);
daspect([1 1 1]);
hold on
for N=1:size(grd.x,2),
	plot(grd.x(:,N),grd.y(:,N),'r');
end;

subplot(1,2,2);
plot(hnanmean(grd.v(:,roi.tissue),2),'b');
hold on
plot(hnanmean(grd.v(:,roi.vesix),2),'r:');
plot(hnanmean(grd.v,2),'color','k','linewidth',1.5);
set(gca,'xlim',[1 size(grd.v,1)]);
set(gca,'xtick',[0:5:size(grd.v,1)]);
grid on;
xlabel('Voxel Number');
ylabel('Voxel Intensity');
return;
