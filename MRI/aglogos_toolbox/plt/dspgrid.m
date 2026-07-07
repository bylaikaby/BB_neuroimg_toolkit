function dspgrid(imggrd)
%DSPGRID - display grid w/ vertical lines over cortex
%	DSPGRID(tcImg,roi,cond)
%	NKL, 17.11.02

imagesc(imggrd.dat');
colormap(gray);
daspect([1 1 1]);
hold on

D = imggrd.D;
for K=1:length(imggrd.x)-1,
	p(:,K) = getortho([imggrd.x(K); imggrd.y(K)],[imggrd.x(K+1); imggrd.y(K+1)],D);
end;

for K=1:length(imggrd.x)-1,
   line([imggrd.y(K) p(2,K)],[imggrd.x(K) p(1,K)],'color','y');
end;

for N=1:size(imggrd.x,2),
	plot(imggrd.y(:,N),imggrd.x(:,N),'r+');
end;
return;
