function dspseqroits(roiTs)
%DSPSEQROITS - Display time series of sequential ROIs (e.g. Riv-Waves)
% DSPSEQROITS(roiTs) Displays ROIs that are neighboring and sequential along a particular
% cortical area. The function is suited for plotting the rivalry waves (Wilson/Blake stuff).
%
% NKL, 11.04.04

if nargin < 1,
  help dspseqroits;
  return;
end;
COL = 'rgbcmyrgbcmyrgbcmyrgbcmy';

if isstruct(roiTs),
  fprintf('DSPSEQROITS: Expects a cell array\n');
  return;
end;

SesName = roiTs{1}.session;
ExpNo = roiTs{1}.ExpNo(1);

mfigure([10 100 600 600]);
set(gcf,'color','k');
txt = sprintf('DSPROITS: Session: %s, ExpNo: %d\n', SesName, ExpNo);
suptitle(txt,'r',11);

KK=1;
sortpar = getsortpars(SesName,ExpNo);

for N=1:length(roiTs)
  ts = sigsort(roiTs{N},sortpar.trial);
  t = [0:size(ts.dat,1)-1] * ts.dx;
  % Average all trials and then all voxels (Time X NVox X NTrial)
  y = hnanmean(hnanmean(ts.dat,3),2);
  if ~isempty(y),
    hd(N) = plot(t,y,COL(N));
    hold on;
  end;
  set(gca,'xlim',[t(1) t(end)]);
  roinames{N} = sprintf('R%d',N);
end;

drawstmlines(ts,'linewidth',2,'color','b','linestyle',':');
set(gca,'xcolor','w','ycolor','w','color',[.7 .7 .7]);
[h, h1] = legend(hd,roinames{:},2);
set(h,'FontWeight','normal','FontSize',8,'color',[.5 .5 .5]);
set(h,'xcolor','w','ycolor','w');
set(h1(1),'fontsize',8,'fontweight','bold','color','w');
xlabel('SD Units');
xlabel('Time in seconds');
grid on;
return;
