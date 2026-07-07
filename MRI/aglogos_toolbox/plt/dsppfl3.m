function dsppfl3(pfl)
%DSPPFL3 - display image and intensity profiles
% NKL, 29.12.02

if nargin < 1,
	error('dsppfl3: usage - dsppfl3(pfl_structure), e.g. pfl_MovBlk');
end;

mfigure([10 80 500 800]);
msubplot(2,1,1);
[x,y]=meshgrid([1:size(pfl.ana,1)],[1:size(pfl.ana,2)]);
z = x*0 + y*0;
obj = mesh(x,y,z,pfl.ana');
set(gca,'YDir','reverse');
view(35,75)
colormap(gray);
hold on
plot3(pfl.y,pfl.x,pfl.v);
set(obj,'FaceColor','texturemap');
set(obj,'CData',pfl.ana');

msubplot(2,1,2);
pfl.dat(find(~pfl.dat))=NaN;
surf(x,y,pfl.dat');
shading interp
hold on
set(gca,'clim',[0 max(pfl.dat(:))]);
set(gca,'zlim',[0 max(pfl.dat(:))]);
set(gca,'YDir','reverse');
view(35,75)
hold on
obj = mesh(x,y,z,pfl.ana');

colormap(gray);
