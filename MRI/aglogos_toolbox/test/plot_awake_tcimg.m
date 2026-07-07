function plot_awake_tcimg(Ses,ExpNo,UseRealigned)

if ~exist('UseRealigned','var'),  UseRealigned = 0;  end
if isempty(UseRealigned),         UseRealigned = 0;  end
  
% GET BASIC INFO
Ses  = goto(Ses);
grp  = getgrp(Ses,ExpNo);
par  = expgetpar(Ses,ExpNo);
spar = getsortpars(Ses,ExpNo);
%tcImg = sigload(Ses,ExpNo,'tcImg.bak');
tcImg = sigload(Ses,ExpNo,'tcImg');


if ~isfield(tcImg,'centroid'),
  if length(tcImg.ds) < 3,
    tmppar = expgetpar(Ses,grp.name);
    tcImg.ds(3) = tmppar.pvpar.slithk;
    clear tmppar;
  end
  tcImg.centroid = mcentroid(tcImg.dat,tcImg.ds);
end


tmpsz  = size(tcImg.dat);
tmpdat = tcImg.dat;
tmpdat = reshape(tmpdat,[prod(tmpsz(1:3)) tmpsz(4)]);
tmpdat = mean(tmpdat,1);


T = [0:length(tmpdat)-1]*tcImg.dx + tcImg.dx/2;
T = [0:length(tmpdat)-1]*tcImg.dx + tcImg.dx;

%T = 1:length(tmpdat);

figure; showfig;
subplot(2,1,1);
plot(T,tmpdat);
set(gca,'xlim',[0 max(T)],'layer','top');
ylabel('mean tcImg.dat');
xlabel('Time in sec');
title(sprintf('mean tcImg.dat: %s ExpNo=%d(%s)',Ses.name,ExpNo,grp.name));
grid on;
subPlotStimulus(gca,par,spar.trial);

centdat = tcImg.centroid;
for N=1:3,
  centdat(N,:) = centdat(N,:)-centdat(N,1);
end
subplot(2,1,2);
plot(T,centdat');
set(gca,'xlim',[0 max(T)],'layer','top');
ylabel('centroid in mm (0=T0)');
xlabel('Time in sec');
title(sprintf('centroid: %s ExpNo=%d(%s)',Ses.name,ExpNo,grp.name));
grid on;
subPlotStimulus(gca,par,spar.trial);




return;









function subPlotStimulus(hAxs,par,sortPar)
hold on;

%return

ylm  = get(hAxs,'ylim');
tmph = ylm(2)-ylm(1);
H = [];
for N = 1:length(sortPar.label),
  OBS = sortPar.obs{N};
  TONSET = sortPar.tonset{N};
  dt     = sortPar.dtvol{N}*sortPar.imgtr;
  if length(dt) > 1,  dt = dt(2);  end
  for K = 1:length(TONSET),
    tmpt = TONSET{K};
    if length(tmpt) > 1, tmpt=tmpt(2);  end
    %line([tmpt tmpt],ylm,   'color','k');
    %line([tmpt tmpt]+dt,ylm,'color','k');
    H(end+1) = rectangle('pos',[tmpt ylm(1) dt, ylm(2)-ylm(1)],...
                         'linestyle','none','facecolor',[1 0.9 0.9]);
  end
end
setback(H);


evt = par.evt;
tmpy =(ylm(2)-ylm(1))*0.8 + ylm(1);
for N = 1:length(evt.obs{1}.trialCorrect),
  if evt.obs{1}.trialCorrect(N) <= 0,  continue;  end
  tmpt = evt.obs{1}.times.ttype(N)/1000;
  line([tmpt tmpt],ylm,   'color','k');
  text(tmpt,tmpy,sprintf('%d',N),'fontsize',6);
end

for N = 1:length(evt.obs{1}.times.rwd),
  tmpt = evt.obs{1}.times.rwd(N)/1000;
  line([tmpt tmpt],ylm,   'color','r');
end


return

