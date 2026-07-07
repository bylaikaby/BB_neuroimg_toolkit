function showinjmodel(SesName, GrpName)
%SHOWINJMODEL - Show models generated with INJMKMODEL
%  
% NKL 06.02.10
  
DEBUG   = 0;
ROINAME = {'V1','V2'};
MDLNAME = {'V1','V2'};
MDLNAME = {};
ALPHA   = [0.001 0.001];
GETMDL  = 0;

if nargin < 2,
  GrpName = 'esinj';
end;

Ses = goto(SesName);
grp = getgrp(Ses,GrpName);
anap = getanap(Ses,GrpName);
inj = anap.inj;

load(sprintf('Mdl_%s.mat',GrpName),'model');
t = [0:size(model.dat,1)-1] * model.dx;

mfigure([100 100 900 950]);
t = [0:size(model.dat,1)-1] * model.dx;
model.dat = mean(model.dat,3);
POS = [1 3 5 7 9];
for N=1:size(model.dat,2),
  subplot(5,2,POS(N));
  plot(t, model.dat(:,N),'color','k','linewidth',1.5);
  set(gca,'xlim',[t(1) t(end)]);
  set(gca,'xtick',[t(1):500:t(end)]);
  grid on;
  drawstmlines(model,'linestyle','none','facecolor',[1 .7 .7]);
  title(sprintf('ROI = %s', model.name{N}));
end;

subplot(1,2,2);
imagesc(model.dat);
colormap(gray);
mdlname = '';
for N=1:length(model.name),
  mdlname = strcat(mdlname,'.',model.name{N});
end;
sesname = '';
for N=1:length(model.SESSION),
  sesname = strcat(sesname,'.',model.SESSION{N});
end;
title(sprintf('%s\n%s', mdlname,sesname));
axis off;
return;

