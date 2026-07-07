function dspxcor(xcor,NoModel)
%DSPXCOR - Display xcorr maps and time series (the xcor structure)
% DSPXCOR(xcor) is used to display the activity maps and the time
% series of the activated voxels. The xcor structure has the
% following fields:
%
%    session: 'm02lx1'
%    grpname: 'movie1'
%      ExpNo: 1
%        dir: [1x1 struct]
%        dsp: [1x1 struct]
%        ana: [136x88x2 double]
%        epi: [34x22x2 double]
%       aval: 0.0100
%         ds: [0.7500 0.7500]
%         dx: 0.2500
%        mdl: [1x1 struct]
%        dat: [34x22x2 double]
%      tosdu: [1x1 struct]
%        pts: [1560x2 double]
%     ptserr: [1560x2 double]%
%
% NKL, 11.04.04

if nargin < 2,
  NoModel = 1;
end;

if nargin < 1,
  help dspxcor;
  return;
end;

if isstruct(xcor),
  tmp=xcor; clear xcor;
  xcor{1}=tmp;
end;

mfigure([10 100 500 800]);
set(gcf,'color',[0 0 .1]);
txt = sprintf('DSPXCOR: Session: %s, ExpNo: %d\n', ...
              xcor{NoModel}.session, xcor{NoModel}.ExpNo);
suptitle(txt,'r',11);
subplot(2,1,1);
ascan = mgetcollage(xcor{NoModel}.ana);
fscan = mgetcollage(xcor{NoModel}.dat);
dspfused(ascan,fscan);
set(gca,'xcolor','w','ycolor','w');

subplot(2,1,2);
t = [0:size(xcor{NoModel}.pts,1)-1] * xcor{NoModel}.dx;
if length(t) > 250,
  plot(t,xcor{NoModel}.pts);
else
  eb = errorbar([t t],xcor{NoModel}.pts,xcor{NoModel}.ptserr);
  set(eb(1),'LineWidth',1,'Color','k');
  set(eb(2),'LineStyle','none','Color','k');
end;

set(gca,'xlim',[t(1) t(end)]);
set(gca,'color',[.78 .85 .85]);
set(gca,'xcolor','y','ycolor','y');
set(gca,'linewidth',2);
box on;
drawstmlines(xcor{NoModel}.mdl,'linewidth',2,'color','r','linestyle',':');
xlabel('SD Units');
xlabel('Time in seconds');
grid on;
return;



