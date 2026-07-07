function dsproi(Roi,TCONLY)
%DSPROI - Display ROI created with ICS
%
% NKL, 23.05.07

if nargin < 2,
  TCONLY = 0;
end;

if nargin < 1,
  help dsproi;
  return;
end;

for N=1:length(Roi.roinames),
  mask{N} = [];
  for K=1:length(Roi.roi),
    if strcmp(Roi.roinames{N},Roi.roi{K}.name),
      mask{N} = cat(3,mask{N},Roi.roi{K}.mask);
    end;
  end;
end;

mfigure([50,300 800 600]);
if size(Roi.ana,3) <= 9,
  NCol = 3; NRow = 3;
else
  NCol = 4; NRow = 4;
end;

ROICOLORS = 'rgbymk';

Ses = goto(Roi.session,Roi.grpname);
anap = getanap(Roi.session,Roi.grpname);

if TCONLY,
  subPlotTC(Roi);
  return;
end;

if ~isfield(anap,'ImgDistort'),
  anap.ImgDistort = 0;
end

if ~anap.ImgDistort,
  grp = getgrpbyname(Roi.session,Roi.grpname);
  AnaFile = sprintf('%s.mat',grp.ana{1});
  if exist(AnaFile,'file') & ~isempty(who('-file',AnaFile,grp.ana{1})),
    tmp = load(AnaFile,grp.ana{1});
    eval(sprintf('anaImg = tmp.%s;',grp.ana{1}));
    anaImg = anaImg{grp.ana{2}};
  end
  for N=1:size(anaImg.dat,3),
    tmpImg.dat(:,:,N) = imresize(anaImg.dat(:,:,N),size(mask{1}(:,:,N)));
  end;
  Roi.ana = tmpImg.dat;
  clear anaImg tmpImg;
end;

nslices = size(Roi.ana,3);

for N = 1:nslices,
  subplot(NRow,NCol,N);
  imagesc(Roi.ana(:,:,N)');
  colormap(gray);
  axis off;
  hold on
  
  ax(N) = axes('position',get(gca,'position'));

  [x,y] = find(squeeze(mask{1}(:,:,N)));
  plot(x,y,'linestyle','none','marker','s','markerfacecolor','r','markersize',2,'markeredgecolor','r');
  hold on;
  [x,y] = find(squeeze(mask{2}(:,:,N)));
  plot(x,y,'linestyle','none','marker','s','markerfacecolor','b','markersize',2,'markeredgecolor','b');
  set(ax(N),'color','none','ydir','reverse');
  set(ax(N),'xlim',[1 size(Roi.ana,1)]);
  set(ax(N),'ylim',[1 size(Roi.ana,2)]);
end;

mfigure([852,300 600 600]);
subPlotTC(Roi);
plot(t,0.5*(mean(rts1.dat,2)+mean(rts2.dat,2)),'color','k','linewidth',2);
set(gca,'xlim',[t(1) t(end)]);
ylabel('Arbitrary Units');
xlabel('Time in Seconds');
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subPlotTC(Roi)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tcImg = sigload(Roi.session,Roi.ExpNo,'tcImg');
rts1 = getTC(tcImg,Roi,Roi.roinames{1});
t = [0:size(rts1.dat,1)-1]*rts1.dx;
plot(t,mean(rts1.dat,2),'color','r');
hold on;
rts2 = getTC(tcImg,Roi,Roi.roinames{2});
plot(t,mean(rts2.dat,2),'color','b');
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function rts = getTC(tcImg, Roi, RoiName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
oRoi = mroicat(Roi);
oRoi = mroiget(oRoi,[],RoiName);
if isempty(oRoi.roi),
  rts = {};
  return;
end;
rts.name = RoiName;

for N=1:length(oRoi.roi),
  rts.mask(:,:,N) = oRoi.roi{N}.mask;
  rts.roiSlices(N) = oRoi.roi{N}.slice;
end;

ofs = 1;
for N=1:length(rts.roiSlices),
  mask = rts.mask(:,:,N);
  [x,y] = find(mask);
  coords = [x y ones(length(x),1)*rts.roiSlices(N)];
  
  rts.ntc{N} = [ofs ofs+length(x)-1];
  ofs = ofs + length(x);
  tc = mtcfromcoords(tcImg,coords);
  ix = find(mask(:));
  if N==1,
    rts.ix = ix;
    rts.coords = coords;
    rts.dat = tc;
  else
    rts.ix = cat(1,rts.ix,ix);
    rts.coords = cat(1,rts.coords,coords);
    rts.dat = cat(2,rts.dat,tc);
  end;
end;
rts.dx = tcImg.dx;










