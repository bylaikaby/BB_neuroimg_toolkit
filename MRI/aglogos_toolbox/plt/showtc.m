function showtc(tcImg)
%SHOWTC - Get time series of a roipoly-defined region of interest
%	SHOWTC(img,Roi) - get TCs from a given ROI
%	NKL, 24.02.01

if nargin < 1,
  error('showtc: usage: show(tcImg)');
end;

Roi = mgetroi(tcImg);

for S=1:size(tcImg.dat,3),
  tcols = mreshape(squeeze(tcImg.dat(:,:,S,:)));
  tcols = tcols(:,find(Roi{S}.mask(:)));
  tc(:,S) = hnanmean(tcols,2);
  tcerr(:,S) = hnanstd(tcols,2);
end;

tc = hnanmean(tc,2);
tcerr = hnanmean(tcerr,2);


keyboard


function Roi = mgetroi(tcImg)
  tcImg.dat = mean(tcImg.dat,4);
  for S=1:size(tcImg.dat,3),
	DisplayImage(squeeze(tcImg.dat(:,:,S)));
	hold on;
	[Roi{S}.mask,Roi{S}.x,Roi{S}.y] = roipoly;	% Brain ROI
  end;
  close all;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DisplayImage(img)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
f = size(img);
f = f(1)/f(2);
figure(...
	'Units', 'normalized', ...
	'Position', [0.2 0.2 f*0.4 0.4],...
	'menubar','none',...
	'color',[0 0 0],...
	'menubar','none', ...
	'toolbar','none', ...
	'doublebuffer','off', ...
	'backingstore','off', ...
	'integerhandle','off', ...
	'PaperPositionMode','auto',...
	'PaperType','A4','InvertHardCopy','off');
imagesc(img');
colormap(gray);
daspect([1 1 1]);
axis off;
set(gca, 'Units', 'normalized', 'Position', [0 0 1 1]);
return;


