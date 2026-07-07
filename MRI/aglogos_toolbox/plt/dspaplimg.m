function dspaplimg(ImgSct,ImageID)
%DSPAPLIMG - display one of the stimuli presented during the experiment
% DSPAPLIMG(ImageID) the function uses the file AutoPlotStimuli.mat
% produced by sesautoplot(SESSION) to permit visualization of one
% of the stimuli presented during the experiment. Every observation
% period has different stimulus sequence. Sesautoplot resorts the
% stimuli (and their inducing activation) to permit averaging. The
% order of the "unsorted" data corresponds thus to the stimulus ID.
%
% See also SESAUTOPLOT
%
% VER 1.0 Yusuke Nikos

global DispPars;

img = squeeze(ImgSct.dat(ImageID,:,:,:));

doShowImage(img);

  
function doShowImage(img)
%MIMAGE - show a two-dimensional image at its real dimensions
% MIMAGE(img) display the image without window crap etc.
% NKL 10.05.03
		
f = size(img);
figure(...
	'Position', [100 400 f(2) f(1)],...
	'menubar','none',...
	'color',[0 0 0],...
	'menubar','none', ...
	'toolbar','none', ...
	'doublebuffer','off', ...
	'backingstore','off', ...
	'integerhandle','off', ...
	'PaperPositionMode','auto',...
	'PaperType','A4','InvertHardCopy','off');
imagesc(img);
colormap(gray);
daspect([1 1 1]);
axis off;
set(gca, 'Units', 'normalized', 'Position', [0 0 1 1]);

  
  
  