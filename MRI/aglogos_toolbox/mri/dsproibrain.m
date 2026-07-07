function dsproibrain(sig)
%DSPROIBRAIN - Display multi-slice anatomical scans
%	DSPROIBRAIN(sig) is used to display volumes, such as our
%	anatomical or EPI13 scans.
%	NKL, 13.12.01

if nargin < 1,
	error('usage: dsproibrain(sig);');
end;

L = size(sig.ana,3);
if L <= 6,
  X=2; Y=3;
elseif L>6 & L <= 13,
	X=4; Y=4;
else
	X=6; Y=ceil(L/X);
end;

mfigure([1 50 1100 850]);		% When META is saved
set(gcf,'color',[0 0 0]);
suptitle(sprintf('Ses: %s, Scan: %d, ScanName %s',...
	sig.session, sig.dir.scanreco(1), sig.dir.dname), 'r',9);

for Slice=1:L,
	msubplot(X,Y,Slice);
	imagesc(sig.ana(:,:,Slice)');
	text(20,20,sprintf('%4d',Slice),'color','r');
	colormap(gray);
	daspect([1 1 1]);
	hold on;
	r = sig.roi{Slice};
	plot(r.anax, r.anay,'y');
	axis off;
end;

mfigure([50 70 1100 850]);
set(gcf,'color',[0 0 0]);
suptitle(sprintf('Ses: %s, Scan: %d, ScanName %s',...
	sig.session, sig.dir.scanreco(1), sig.dir.dname), 'r',9);

for Slice=1:L,
	msubplot(X,Y,Slice);
	imagesc(sig.img(:,:,Slice)');
	text(20,20,sprintf('%4d',Slice),'color','r');
	colormap(gray);
	daspect([1 1 1]);
	hold on;
	r = sig.roi{Slice};
	plot(r.x, r.y,'y');
	axis off;
end;



