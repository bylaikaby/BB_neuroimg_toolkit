function dspxcorts(roiTs,thr)
%DSPXCORTS - Display all time series in the structure roiTs
% DSPXCORTS(Roi) is used to display the time series of the voxels
% within selected ROIs by means of the MROI program.
%
% NKL, 11.04.04

if nargin < 1,
  help dspxcorts;
  return;
end;

if ~exist('thr'),
  thr = 0;
end;

mfigure([10 30 1000 800]);
set(gcf,'color','k');
for N=1:length(roiTs),
  subplot(2,3,N);
  DOroiTs(roiTs{N},thr);
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
function DOroiTs(roiTs,thr)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
if thr,
  roiTs = mroitssel(roiTs,thr);
end;

COL = 'rgbcmyrgbcmyrgbcmyrgbcmy';
INCR = 2;
KK=1;
for N=1:length(roiTs)
  t = [0:size(roiTs{N}.dat,1)-1] * roiTs{N}.dx;
  y = roiTs{N}.dat;
  if ~isempty(y),
    yerr = hnanstd(y,2)/sqrt(size(y,2));
    y = hnanmean(y,2);
    hd(KK) = plot(t,y,'color',COL(N),'linewidth',2);
    hold on;
    roinames{KK} = roiTs{N}.name;
    KK=KK+1;
  end;
  set(gca,'xlim',[t(1) t(end)]);
end;
drawstmlines(roiTs{1},'linewidth',2,'color','b','linestyle',':');
set(gca,'xcolor','w','ycolor','w','color',[.7 .7 .7]);
[h, h1] = legend(hd,roinames{:},2);
set(h,'FontWeight','normal','FontSize',8,'color',[.5 .5 .5]);
set(h,'xcolor','w','ycolor','w');
set(h1(1),'fontsize',8,'fontweight','bold','color','w');
xlabel('SD Units');
xlabel('Time in seconds');
grid on;

ax3 = axes('position',get(gca,'position'));
set(ax3,'YAxisLocation','right','color','none', ...
        'xgrid','off','ygrid','off','box','off','yscale','linear',...
        'xticklabel',[],'yticklabel',[]);
set(ax3,'ydir','reverse');
pos = get(ax3,'position');
rmx = pos(1) + pos(3);
tmx = pos(2) + pos(4);
pos(3) = pos(3)/2; pos(4) = pos(4)/2;
pos(1) = rmx - pos(3);
pos(2) = tmx - pos(4) - 0.003;
set(ax3,'position',pos);
matsmap(roiTs);
return;
