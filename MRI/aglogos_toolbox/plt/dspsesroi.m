function dspsesroi(grp)
%DSPSESROI - show sesroi results (ROIs xcor data etc.) for group
%	DSPSESROI(grp)
%	NKL, 25.10.02

ana = grp.xcor{1}.ana;
fun = grp.xcor{1}.dat;

ana = ana/max(abs(ana(:)));
fun(fun<0) = 0;
cimg = cat(1,ana,fun);

imagesc(cimg');
colormap(gray);
hold on
plot(grp.eroi.y,grp.eroi.x,'r');
plot(grp.eroi.y+size(grp.eroi.mask,1),grp.eroi.x,'r');
plot(grp.broi.y,grp.broi.x,'g','linewidth',1);
plot(grp.broi.y+size(grp.broi.mask,1),grp.broi.x,'g','linewidth',1);
