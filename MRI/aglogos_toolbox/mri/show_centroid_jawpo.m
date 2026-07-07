function show_centroid_jawpo(SESSION,ExpNo)
%SHOW_CENTROID_JAWPO - plots time courses of image centroid and jaw-pow movement
%  SHOW_CENTROID_JAWPO(SESSION,EXPNO) plots time courses of image centroid and jaw-pow
%  movement.
%
%  EXAMPLE :
%    >> show_centroid_jawpo('b03dp1',1)
%
%  VERSION :
%    0.90 06.10.06 YM  pre-release
%
%  See also EXPGETDGEVT EXPGETPAR MCENTROID

if nargin < 2,  eval(sprintf('help %s;',mfilename));  return;  end


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);
par = expgetpar(Ses,ExpNo);
tcImg = sigload(Ses,ExpNo,'tcImg');
jawpo = par.evt.obs{1}.jawpo;

% compute centroid
if ~isfield(tcImg,'centroid'),
  cent = mcentroid(tcImg.dat,tcImg.ds);
else
  cent = tcImg.centroid;
end

%
mcent = cent;
mcent(1,:) = cent(1,:) - mean(cent(1,:));
mcent(2,:) = cent(2,:) - mean(cent(2,:));
mcent(3,:) = cent(3,:) - mean(cent(3,:));

dcent = sqrt(sum(mcent.*mcent,1));



% plot results
figure;
set(gcf,'Name',sprintf('%s ExpNo=%d(%s)',Ses.name,ExpNo,grp.name));

subplot(2,1,1);
t = [0:size(tcImg.dat,4)-1]*tcImg.dx;
plot(t,mcent);  hold on;
plot(t,dcent,'color','k');
legend('X','Y','Z','Distance');  grid on;
xlabel('Time in seconds');  ylabel('mm');
subDrawStimIndicators(gca,par.stm)
set(gca,'xlim',[0 max(t)],'layer','top');
title('tcImg centroid');
text(0.02,0.95,sprintf('VOX=%.3fx%.3fx%.3fmm',tcImg.ds(1),tcImg.ds(2),tcImg.ds(3)),...
     'units','normalized');


subplot(2,1,2);
t = [0:size(jawpo.dat,1)-1]*jawpo.dx;
plot(t,jawpo.dat);
legend('JAW','PO');  grid on;
xlabel('Time in seconds');  ylabel('ADC');
subDrawStimIndicators(gca,par.stm)
set(gca,'xlim',[0 max(t)],'layer','top');
title('Jaw-Po movement');


dcent2 = resample(dcent(:),size(jawpo.dat,1),length(dcent));
[R P] = corrcoef([dcent2(:) double(jawpo.dat)]);
fprintf('corrcef:');
fprintf(' CENT-JAW=%.3f(P=%.4f) ',R(1,2),P(1,2));
fprintf(' CENT-PO=%.3f(P=%.4f) ',R(1,3),P(1,3));
fprintf(' JAW-POW=%.3f(P=%.4f) ',R(2,3),P(2,3));
fprintf('\n');
R

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to draw stimulus indicators
function subDrawStimIndicators(haxs,STM)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% draw stimulus indicators
ylm   = get(haxs,'ylim');  tmph = ylm(2)-ylm(1);
drawL = [];  drawR = [];

stimv = STM.v{1};
stimt = STM.time{1};  stimt(end+1) = sum(STM.dt{1});
stimdt = STM.dt{1};
for N = 1:length(stimv),
  if any(strcmpi(STM.stmpars.StimTypes{stimv(N)+1},{'blank','none','nostim'})),
    continue;
  end
  if stimt(N) == stimt(N+1),
    tmpw = stimdt(N);
  else
    tmpw = stimt(N+1) - stimt(N);
  end
  if ~any(drawL == stimt(N)),
    line([stimt(N), stimt(N)],ylm,'color','k','tag','stim-line');
    drawL(end+1) = stimt(N);
  end
  if isempty(drawR) | ~any(drawR(:,1) == stimt(N) & drawR(:,2) == tmpw),
    rectangle('Position',[stimt(N) ylm(1) tmpw tmph],...
              'facecolor',[0.88 0.88 0.88],'linestyle','none',...
              'tag','stim-rect');
    drawR(end+1,1) = stimt(N);
    drawR(end  ,2) = tmpw;
  end
  if ~any(drawL == stimt(N)+tmpw),
    line([stimt(N),stimt(N)]+tmpw,ylm,'color','k','tag','stim-line');
    drawL(end+1) = stimt(N)+tmpw;
  end
end


% adjust stimulus indicator size
set(allchild(haxs),'HandleVisibility','on');
ylm = get(haxs,'ylim');  tmph = ylm(2)-ylm(1);
h = findobj(haxs,'tag','stim-line');
set(h,'ydata',ylm);
h = findobj(haxs,'tag','stim-rect');
for N = 1:length(h),
  tmppos = get(h(N),'pos');
  tmppos(2) = ylm(1);  tmppos(4) = tmph;
  set(h(N),'pos',tmppos);
end

setfront(findobj(haxs,'tag','stim-line'));
setback(findobj(haxs,'tag','stim-rect'));
% set indicators' handles invisible to use legend() funciton.
set(findobj(haxs,'tag','stim-line'),'handlevisibility','off');
set(findobj(haxs,'tag','stim-rect'),'handlevisibility','off');

  

return;
