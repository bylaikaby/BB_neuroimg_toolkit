function varargout = mncheck_roits(SESSION,GRPNAME,NORM,PROJOUT,USE_PCA)
%MNCHECK_ROITS - load roiTs and plot their time course.
%  [ROITS] = MNCHECK_ROITS(SESSION,GRPNAME,ROINAME,BASEROI,[USE_PCA=0]) loads roiTs 
%  and plot them.
%  If USE_PCA==1, then use tcImg.pca_denoised as time course data.
%
%  VERSION :
%    0.90 08.06.05 YM  pre-release.
%    0.91 15.06.05 YM  supports USE_PCA.
%    0.92 24.06.05 YM  use mnplot_roits() funciton.
%
%  See also MN_ROITS_GET, MN_ROITS_CAT, MNCHECK_PROJOUT

if nargin < 2,  help mncheck_roits; return;  end

if nargin < 3,  NORM = 'global';  end
if nargin < 4,  PROJOUT = {};     end
if nargin < 5,  USE_PCA = 1;      end


ROIs = {'opn','xasm','opt','plgn','mlgn','pul','sc','v1','cer','muscle'};
ALPHA = 1.0;


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);



% PLOT mean time courses %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('%s %s: plotting data...\n',datestr(now,'HH:MM:SS'),mfilename);
[roiTs, hWin] = mnplot_roits(Ses,grp,ROIs,ALPHA,NORM,PROJOUT,USE_PCA);
figfile = sprintf('%s_%s_%s.fig',Ses.name,grp.name,mfilename);
saveas(hWin,figfile);
fprintf(' saved as ''%s''.\n',figfile);


if nargout,
  varargout{1} = roiTs;
end

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot data
function hWin = subPlotData(roiTs, BASE_ROI);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmptitle = sprintf('%s: %s %s',mfilename,roiTs{1}.session,roiTs{1}.grpname);
hWin = figure('Name',tmptitle);
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName',  'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');


ROI_MEAN = zeros(size(roiTs{1}.dat,1),length(roiTs));
for N = 1:length(roiTs),
  ROI_MEAN(:,N) = mean(roiTs{N}.dat,2);
end


%COL = 'rgbcmykrgbcmykrgbcmyk';
COL = jet(length(roiTs));

T = [1:size(roiTs{1}.dat,1)];

legtxt = {};

% plot mean voxel value
subplot(2,2,1);
for N = 1:length(roiTs),
  plot(T,ROI_MEAN(:,N),'color',COL(N,:),'linewidth',2);  grid on;  hold on;
  if iscell(roiTs{N}.name),
    legtxt{N} = roiTs{N}.name{1};
  else
    legtxt{N} = roiTs{N}.name;
  end
  legtxt{N} = sprintf('%s N=%d',legtxt{N},size(roiTs{N}.dat,2));
end
xlabel('Experiment Number');
ylabel('Mean Voxel Value');
title('Time Course of Mean Voxel Value');
h = legend(legtxt);  set(h,'fontsize',6);
inftxt = sprintf('%s %s',roiTs{1}.session,roiTs{1}.grpname);
text(0.02,0.07,inftxt,'units','normalized','fontname','Comic Sans MS')
set(gca,'xlim',[0 max(T)]);


% plot normalized time course
subplot(2,2,2);
for N = 1:length(roiTs),
  plot(T,ROI_MEAN(:,N)/ROI_MEAN(1,N),'color',COL(N,:),'linewidth',2);  grid on;  hold on;
end
xlabel('Experiment Number');
ylabel('Normalized Value');
title('Time Course of Normalized Voxel Value');
h = legend(legtxt);  set(h,'fontsize',6);
inftxt = sprintf('%s %s',roiTs{1}.session,roiTs{1}.grpname);
text(0.02,0.07,inftxt,'units','normalized','fontname','Comic Sans MS')
set(gca,'xlim',[0 max(T)]);



% plot time course that "brain" componet is project out.
ROI_IDX = 0;
for N = 1:length(roiTs),
  if any(strcmpi(roiTs{N}.name,BASE_ROI)),
    ROI_IDX = N;
    break;
  end
end

if ROI_IDX == 0,
  return;
end

% make a unit vector of "global" component.
pdat = ROI_MEAN(:,ROI_IDX);
pdat = pdat - mean(pdat(:));
pdat = pdat / sqrt(sum(pdat(:).*pdat(:)));

% project out the "global" component.
offs = [];
mdat = [];
for N = length(roiTs):-1:1,
  tmpdat = ROI_MEAN(:,N);
  offs(N) = mean(tmpdat(:));
  tmpdat = tmpdat - offs(N);
  tmpdat = tmpdat - sum(tmpdat(:).*pdat(:)) * pdat;
  mdat(:,N) = tmpdat + offs(N);
end

subplot(2,2,3);
for N = 1:length(roiTs),
  plot(T,mdat(:,N),'color',COL(N,:),'linewidth',2);  grid on;  hold on;
end
xlabel('Experiment Number');
ylabel('Voxel Value (RPOJ-OUT)');
title(sprintf('Time Course of Voxel Value (project-out %s)',BASE_ROI));
h = legend(legtxt);  set(h,'fontsize',6);
inftxt = sprintf('%s %s BASE=''%s''',roiTs{1}.session,roiTs{1}.grpname,BASE_ROI);
text(0.02,0.07,inftxt,'units','normalized','fontname','Comic Sans MS')
set(gca,'xlim',[0 max(T)]);

subplot(2,2,4);
for N = 1:length(roiTs),
  plot(T,mdat(:,N)/mdat(1,N),'color',COL(N,:),'linewidth',2);  grid on;  hold on;
end
xlabel('Experiment Number');
ylabel('Normalized Value (RPOJ-OUT)');
title(sprintf('Time Course of Normalized Voxel Value (project-out %s)',BASE_ROI));
h = legend(legtxt);  set(h,'fontsize',6);
inftxt = sprintf('%s %s BASE=''%s''',roiTs{1}.session,roiTs{1}.grpname,BASE_ROI);
text(0.02,0.07,inftxt,'units','normalized','fontname','Comic Sans MS')
set(gca,'xlim',[0 max(T)]);



return;
