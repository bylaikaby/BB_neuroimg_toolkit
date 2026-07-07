function roits2model(SesName,GrpName,RoiName,ContrastName,PVAL)
%ROITS2MODEL - Select a roiTs and makes it a model for GLM or CORR analysis
% ROITS2MODEL (SesName,GrpName,RoiName,ContrastName)
%  
% Examples:
% roits2model('l02dq1','visesmix',[],{'pvspes','pvsnes'});
% roits2model('i04dj1','visescomb',[],{'Incr','Decr'});  
%
% NKL 06.10.06

if nargin < 5,
  PVAL = 0.05;
end;

if nargin < 4,
  help roits2model;
  return;
end;

Ses = goto(SesName);
grp = getgrpbyname(Ses,GrpName);
anap=getanap(Ses,GrpName);

if ~isempty(grp.refgrp.grpexp) & ~strcmp(grp.refgrp.grpexp,grp.name),
  refgrp = getgrpbyname(Ses,grp.refgrp.grpexp);
  glm = refgrp.glmconts;
else
  glm = grp.glmconts;
end;

if exist('RoiName') & ischar(RoiName),
  RoiName = {RoiName};
end;

if isempty(RoiName),
  K=1;
  for N=1:length(Ses.roi.names),
    if any(strcmp(lower(anap.mareats.IEXCLUDE),lower(Ses.roi.names{N}))),
      continue;
    end;
    RoiName{K} = Ses.roi.names{N};
    K=K+1;
  end;
end;

if isempty(ContrastName),
  glmidx = [1:length(glm)];
else
  if ischar(ContrastName), ContrastName = {ContrastName};  end;
  glmidx = [];
  for N = 1:length(ContrastName),
    for C=1:length(glm),
      if strcmp(lower(glm{C}.name),lower(ContrastName{N})),
        glmidx = cat(1,glmidx,C);
      end;
    end;
  end;
end;

for Model = 1:length(ContrastName),
  mdl = sprintf('glm[%d]',glmidx(Model));
  for Roi = 1:length(RoiName),
    roiTs{Model}{Roi} = mvoxselect(Ses,GrpName,RoiName{Roi},mdl,[],PVAL);
    roiTs{Model}{Roi} = xform(roiTs{Model}{Roi},'zerobase','prestim');
    roiTs{Model}{Roi}.dat = hnanmean(roiTs{Model}{Roi}.dat,2);
    
    if Roi==1,
      ts{Model} = roiTs{Model}{Roi};
    else
      ts{Model}.dat = cat(2,ts{Model}.dat,roiTs{Model}{Roi}.dat);
    end;
  end;
end;

if length(ContrastName)>1 & length(RoiName)>1,
  for N=1:length(ContrastName),
    dat(:,N) = hnanmean(ts{N}.dat,2);
  end;
  ts = ts{1};
  ts.dat = dat;
end;
  
ts.contrast = ContrastName;
ts.roiname = RoiName;

% DRAW NOW
colmap = [1 0 0; 0 0 1; 0 1 0; 1 1 0; 0 1 1; 1 0 1; 0 0 0];
mfigure([70 150 600 400]);
set(gcf,'DefaultAxesfontsize',	14);
set(gcf,'DefaultAxesfontweight','normal');
set(gcf,'color','k');
subPlotTimeCourse({ts},colmap,{ContrastName});

% AND SAVE THE MODEL
subMakeModel(Ses,GrpName,ts);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subMakeModel(Ses, GrpName, ts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
anap = getanap(Ses,GrpName);
pars = getsortpars(Ses,GrpName);

model.session = Ses.name;
model.grpname = GrpName;
model.dx      = pars.trial.imgtr;

model.dat = ts.dat;
model.contrast = ts.contrast;
model.roiname = ts.roiname;

model.info.chan = {'blank->pinwheel->pinwheel+microstim->pinwheel->blank'};
model.stm = expgetstm(Ses,GrpName);
filename = sprintf('roimodel_%s.mat',GrpName);
save(filename,'model');
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subPlotTimeCourse(roiTs,colmap,Modelname)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
txt = sprintf('Session: %s, Group: %s',...
              roiTs{1}.session, roiTs{1}.grpname);
for N=1:length(roiTs),
  t = [0:size(roiTs{N}.dat,1)-1] * roiTs{N}.dx;
  t = t(:);
  plot(t, roiTs{N}.dat,'color','k','linewidth',2);
end
drawstmlines(roiTs{1},'linewidth',2,'color',[0 0 0],'linestyle',':');
set(gca,'xlim',[t(1) t(end)]);
ylabel('Modulation in Baseline-SD Units');
xlabel('Time in seconds');
title(txt,'color','r');
set(gca,'xcolor','g','ycolor','g');
set(gca,'linewidth',2);
grid on;
box on;
return;

