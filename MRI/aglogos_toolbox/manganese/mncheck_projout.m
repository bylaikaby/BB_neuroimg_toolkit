function varargout = mncheck_projout(SESSION,GRPNAME,RoiName,BASE_ROI,USE_PCA)
%MNCHECK_PROJOUT - load roiTs and project baseline component and plot results.
%  [ROITS] = MNCHECK_PROJOUT(SESSION,GRPNAME,ROINAME,BASE_ROI,[USE_PCA=0]) loads roiTs 
%  and project baseline component of BASE_ROI and plot results.
%  If USE_PCA==1, then use tcImg.pca_denoised as time course data.
%
%  VERSION :
%    0.90 09.06.05 YM  pre-release.
%    0.91 15.06.05 YM  supports USE_PCA.
%
%  See also MN_ROITS_GET, MN_ROITS_CAT, MN_ROITS_PROJOUT

if nargin < 2,  help mncheck_projout; return;  end

if nargin < 3,  RoiName = {};         end
if nargin < 4,  BASE_ROI = 'muscle';  end
if nargin < 5,  USE_PCA = 0;          end



% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);

if ~any(strcmpi(Ses.roi.names,BASE_ROI)),
  fprintf('%s ERROR: BASE_ROI ''%s'' not found.\n',mfilename,BASE_ROI);
  return;
end


% LOAD TIME COURSE FOR EACH ROI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('%s %s: reading...\n ',datestr(now,'HH:MM:SS'),mfilename);
ROI = load(mroi_file(Ses,grp.grproi));
ROI = ROI.(grp.grproi);
ROI.roinames = union(ROI.roinames,Ses.roi.names);
roiTsBASE = mn_roits_get(ROI,GRPNAME,BASE_ROI,[],USE_PCA);
if isempty(roiTsBASE),
  fprintf('%s ERROR: BASE_ROI ''%s'' is empty.\n',mfilename,BASE_ROI);
  return;
end
roiTsBASE = mn_roits_cat(roiTsBASE);
if isempty(RoiName),  RoiName = Ses.roi.names;  end
if ischar(RoiName),   RoiName = { RoiName; };   end
for iRoi = 1:length(RoiName),
  if ~any(strcmpi(Ses.roi.names,RoiName{iRoi})),
    fprintf('%s ERROR: ROI ''%s'' not found.\n',mfilename,RoiName{iRoi});
    return;
  end
end
roiTs = {};
for iRoi = 1:length(RoiName),
  fprintf('%s.',RoiName{iRoi});
  if strcmpi(RoiName{iRoi},BASE_ROI),
    roiTs{end+1} = roiTsBASE;
  else
    tmpts = mn_roits_get(ROI,GRPNAME,RoiName{iRoi},[],USE_PCA);
    if isempty(tmpts), continue; end
    tmpts = mn_roits_cat(tmpts);
    if ~isempty(tmpts.dat),
      roiTs{end+1} = tmpts;
    end
  end
end
fprintf(' done.\n');


% PROJECT-OUT "BASE-ROI" %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('%s %s: projecting ''%s'' out',datestr(now,'HH:MM:SS'),mfilename,BASE_ROI);
BASEDAT = mean(roiTsBASE.dat,2);
for iRoi = 1:length(roiTs),
  fprintf('.[%d]',size(roiTs{iRoi}.dat,2));
  tmpts = mn_roits_projout(roiTs{iRoi},BASEDAT);
  tmpts.dat = int16(round(tmpts.dat));
  roiTs{iRoi} = tmpts;
end
fprintf(' done.\n');



% APPLY TTEST %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('%s %s: t-test',datestr(now,'HH:MM:SS'),mfilename);
for iRoi = 1:length(roiTs),
  fprintf('.[%d]',size(roiTs{iRoi}.dat,2));
  roiTs{iRoi} = mn_roits_ttest(roiTs{iRoi});
end
fprintf(' done.\n');



% PLOT mean time courses %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('%s %s: plotting data...',datestr(now,'HH:MM:SS'),mfilename);
h = subPlotData(roiTs,BASE_ROI,0.05);
figfile = sprintf('%s_%s_%s_%s.fig',Ses.name,grp.name,mfilename,BASE_ROI);
saveas(h,figfile);
fprintf(' saved as ''%s''.\n',figfile);


if nargout,
  varargout{1} = roiTs;
else
end

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot data
function hWin = subPlotData(roiTs, BASE_ROI, ALPHA);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmptitle = sprintf('%s: %s %s',mfilename,roiTs{1}.session,roiTs{1}.grpname);
hWin = figure('Name',tmptitle);
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName',  'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');


COL = jet(length(roiTs));

T = [1:size(roiTs{1}.dat,1)];


ROI_MEAN = zeros(size(roiTs{1}.dat,1),length(roiTs));
NVOXELS  = zeros(1,length(roiTs));
for N = 1:length(roiTs),
  ROI_MEAN(:,N) = mean(roiTs{N}.dat,2);
  NVOXELS(N)    = size(roiTs{N}.dat,2);
end

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
  legtxt{N} = sprintf('%s N=%d',legtxt{N},NVOXELS(N));
end
xlabel('Experiment Number');
ylabel('Mean Voxel Value');
title(sprintf('Time Course of Voxels (PROJ-OUT %s)',BASE_ROI));
h = legend(legtxt);  set(h,'fontsize',6);
inftxt = sprintf('%s %s ALPHA=ALL',roiTs{1}.session,roiTs{1}.grpname);
text(0.02,0.07,inftxt,'units','normalized','fontname','Comic Sans MS')
set(gca,'xlim',[0 max(T)]);
set(gca,'layer','top');


% plot normalized time course
subplot(2,2,2);
for N = 1:length(roiTs),
  plot(T,ROI_MEAN(:,N)/ROI_MEAN(1,N),'color',COL(N,:),'linewidth',2);  grid on;  hold on;
end
xlabel('Experiment Number');
ylabel('Normalized Value');
title(sprintf('Normalized Time Course of Voxels (RPOJ-OUT %s)',BASE_ROI));
h = legend(legtxt);  set(h,'fontsize',6);
inftxt = sprintf('%s %s ALPHA=ALL',roiTs{1}.session,roiTs{1}.grpname);
text(0.02,0.07,inftxt,'units','normalized','fontname','Comic Sans MS')
set(gca,'xlim',[0 max(T)]);
set(gca,'layer','top');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOT SELECTED VOXELS BY ALPHA

ROI_MEAN = zeros(size(roiTs{1}.dat,1),length(roiTs));
NVOXELS  = zeros(1,length(roiTs));
for N = 1:length(roiTs),
  if any(strcmpi(roiTs{N}.name,BASE_ROI)),
    ROI_MEAN(:,N) = mean(roiTs{N}.dat,2);
    NVOXELS(N) = size(roiTs{N}.dat,2);
  else
    idx = find(roiTs{N}.ttest.p < ALPHA);
    if ~isempty(idx),
      ROI_MEAN(:,N) = mean(roiTs{N}.dat(:,idx),2);
      NVOXELS(N) = length(idx);
    end
  end
end


TWIN1 = roiTs{1}.ttest.twin1;
TWIN2 = roiTs{1}.ttest.twin2;

BKGC = [0.9 0.9 0.9];

subplot(2,2,3);
hTWIN1 = rectangle('position',[0 0 1 1],'facecolor',BKGC,'edgecolor',BKGC);
grid on; hold on;
hTWIN2 = rectangle('position',[0 0 1 1],'facecolor',BKGC,'edgecolor',BKGC);
for N = 1:length(roiTs),
  plot(T,ROI_MEAN(:,N),'color',COL(N,:),'linewidth',2);  grid on;  hold on;
  if iscell(roiTs{N}.name),
    legtxt{N} = roiTs{N}.name{1};
  else
    legtxt{N} = roiTs{N}.name;
  end
  legtxt{N} = sprintf('%s N=%d',legtxt{N},NVOXELS(N));
end
xlabel('Experiment Number');
ylabel('Mean Voxel Value');
title(sprintf('Time Course of Selected Voxels (PROJ-OUT %s)',BASE_ROI));
h = legend(legtxt);  set(h,'fontsize',6);
inftxt = sprintf('%s %s ALPHA=%.2f',roiTs{1}.session,roiTs{1}.grpname,ALPHA);
text(0.02,0.07,inftxt,'units','normalized','fontname','Comic Sans MS')
set(gca,'xlim',[0 max(T)]);
ylm = get(gca,'ylim');
set(hTWIN1,'position',[TWIN1(1) ylm(1) TWIN1(2)-TWIN1(1)  ylm(2)-ylm(1)]);
set(hTWIN2,'position',[TWIN2(1) ylm(1) TWIN2(2)-TWIN2(1)  ylm(2)-ylm(1)]);
set(gca,'layer','top');


% plot normalized time course
subplot(2,2,4);
hTWIN1 = rectangle('position',[0 0 1 1],'facecolor',BKGC,'edgecolor',BKGC);
grid on; hold on;
hTWIN2 = rectangle('position',[0 0 1 1],'facecolor',BKGC,'edgecolor',BKGC);
for N = 1:length(roiTs),
  %tmpm = mean(ROI_MEAN(1:2,N),1);
  tmpm = ROI_MEAN(1,N);
  if tmpm == 0,  tmpm = 1;  end
  plot(T,ROI_MEAN(:,N)/tmpm,'color',COL(N,:),'linewidth',2);  grid on;  hold on;
end
xlabel('Experiment Number');
ylabel('Normalized Value');
title(sprintf('Normalized Time Course of Selected Voxels (PROJ-OUT %s)',BASE_ROI));
h = legend(legtxt);  set(h,'fontsize',6);
inftxt = sprintf('%s %s ALPHA=%.2f',roiTs{1}.session,roiTs{1}.grpname,ALPHA);
text(0.02,0.07,inftxt,'units','normalized','fontname','Comic Sans MS')
set(gca,'xlim',[0 max(T)]);
ylm = get(gca,'ylim');
set(hTWIN1,'position',[TWIN1(1) ylm(1) TWIN1(2)-TWIN1(1)  ylm(2)-ylm(1)]);
set(hTWIN2,'position',[TWIN2(1) ylm(1) TWIN2(2)-TWIN2(1)  ylm(2)-ylm(1)]);
set(gca,'layer','top');




return;
