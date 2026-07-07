function showxcorplot(SESSION,GrpName,Mode,pptstate)
%SHOWXCORPLOT - show sesroi results (ROIs xcor data etc.) for group
% SHOWXCORPLOT(SESSION,GrpName,Mode) - shows correlation maps superimposed on
% anatomical scans, and if exists also the activated voxels in different
% regions of interest, such as different visual areas etc.
%
% THE DIFFERENCE FROM SHOWXCOR is that this function does not use
% xscore maps that are color coded; it rather displays the
% anatomical images and plots on them the significantly activated voxels.
%
% Example: SHOWXCORPLOT('j02l61','gpatcc1');
% Mode = 0 -- Zscore maps superimposed on anatomy/EPI
% Mode = 1 -- Signficantly activated voxels & time courses
%	
% NKL, 25.10.02

global DispPars DISPMODE PPTSTATE
DISPMODE = getdispmode;
if isempty(DISPMODE),
  DISPMODE=1;				% DEFAULT SHOW AVERAGE OBSP/CHAN
end;

PPTSTATE = getpptstate;
if isempty(PPTSTATE),
  PPTSTATE = 1;				% DEFAULT NO PPT OUTPUT
  setpptstate(PPTSTATE);
end;
initDispPars(DISPMODE,PPTSTATE);

if nargin < 4,
  pptstate = 0;
end;

if nargin < 3,
  Mode = 0;
end;

if nargin < 2,
	error('usage: showxcorplot(SESSION,GrpName);');
end;

Ses = goto(SESSION);
img=load('tcimg.mat');
xc=load('xcor.mat');
eval(sprintf('tcImg = img.%s;', GrpName));
clear img;
eval(sprintf('xcor = xc.XCOR%s;', GrpName));
xcor=xcor{1};

DispPars.pptstate = pptstate;
DispPars.printer = 0;

if ~Mode,
  mfigure([50 50 900 700]);
  orient portrait
  set(gcf,'PaperType','A4','InvertHardCopy','off');
  set(gcf,'color','k');
  txt = sprintf('Session: %s, Group: %s', xcor.session, xcor.grpname);
  dspxcor(mslicemerge(xcor));
  DispPars.pptout = 'meta';
  suptitle(txt,'r',11);
  PPTTITLE = sprintf('ZMAP_%s_%s',xcor.session,xcor.grpname);
  if DispPars.pptstate,
	pptout(PPTTITLE,DispPars.pptout);
  end;
else
  dspXcor(xcor);
  DispPars.pptout = 'jpeg';
  DispPars.pptout = 'meta';
  PPTTITLE = sprintf('XCOR_%s_%s',xcor.session,xcor.grpname);
  if DispPars.pptstate,
	pptout(PPTTITLE,DispPars.pptout);
  end;
  
  dspTc(xcor);
  DispPars.pptout = 'meta';
  PPTTITLE = sprintf('TC_%s_%s',xcor.session,xcor.grpname);
  if DispPars.pptstate,
	pptout(PPTTITLE,DispPars.pptout);
  end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dspXcor(xcor)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NoSlice = size(xcor.ana,3);
if NoSlice <= 4,
  X=2; Y=2;
elseif NoSlice > 4 & NoSlice <=6
  X=2; Y=3;
else
  X=4; Y=3;
end;
  
mfigure([50 100 750 600]);
set(gcf,'PaperType','A4','InvertHardCopy','off');
txt = sprintf('Session: %s, Group: %s', xcor.session, xcor.grpname);
suptitle(txt,'r',10);
orient portrait
LUTSIZE = 64;
ana = uint8(LUTSIZE*xcor.ana/max(xcor.ana(:)));

for SliceNo = 1:NoSlice,
  msubplot(X,Y,SliceNo);
  subimage(ana(:,:,SliceNo)',gray(LUTSIZE));
  daspect([1 1 1]);
  axis off;
  hold on

  if any(size(xcor.ana(:,:,SliceNo)) ~= size(xcor.dat(:,:,SliceNo))),
	f = size(xcor.ana(:,:,SliceNo)) ./ size(xcor.dat(:,:,SliceNo));
  else
	f = [1 1];
  end;
  [px, py] = find(xcor.dat(:,:,SliceNo)>0);
  px = px * f(1);
  py = py * f(2);
  plot(px,py,'r.','markersize',4);
  [px, py] = find(xcor.dat(:,:,SliceNo)<0);
  px = px * f(1);
  py = py * f(2);
  plot(px,py,'b.','markersize',4);
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dspTc(xcor)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEAN TIME COURSE OF ACTIVATED VOXELS
mfigure([510 150 350 300]);
orient portrait
set(gcf,'PaperType','A4','InvertHardCopy','off');
txt = sprintf('Session: %s, Group: %s', xcor.session, xcor.grpname);
suptitle(txt,'r',10);
% subplot(2,1,1);
t = [0:size(xcor.pts,1)-1]*xcor.dx;
y = hnanmean(xcor.pts,2);
mdl = xcor.mdl.dat;
mdl = max(y(:)) * (mdl ./ max(mdl(:)));
plot(t,mdl,'color',[.8 1 .8],'linewidth',3);
hold on;
plot(t, y,'r');
set(gca,'xlim',[t(1) t(end)]);
set(gca,'ygrid','on');
xlabel('Time in seconds');
ylabel('SD Units');
drawstmlines(xcor,'color','k','linestyle',':');
title('Time Course of Activated Voxels');

% subplot(2,1,2);
return;


