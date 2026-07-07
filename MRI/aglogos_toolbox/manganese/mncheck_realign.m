function mncheck_realign(SESSION,GRPNAME,RoiName)
%MNCHECK_REALIGN - plots statistics between RAW and REALIGNED data.
%  MNCHECK_REALIGN(SESSION,GRPNAME,ROINAME) plots statistics of voxels
%  in given ROINAME, time courses, coefficient of variation, differential
%  images.
%
%  RAW data should be in "TC_SLICE_RAW" directory,
%  REALIGNED data should be in "TC_SLICE_REALINED" directory.
%
%  VERSION :
%    0.90 07.06.05 YM  pre-release.
%    0.91 08.06.05 YM  use MROIGET and MROICAT for ROI selection.
%    0.92 06.02.12 YM  use mroi_file().
%
%  See also MNREALIGN, MROIGET, MROICAT

if nargin == 0,  help mncheck_realign; return; end

if nargin < 3,  RoiName = 'cer';  end
  

Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);

fprintf(' %s: processing roi(%s)...',mfilename,RoiName);
ROI = load(mroi_file(Ses,grp.grproi));
ROI = ROI.(grp.grproi);
ROI.roinames = union(ROI.roinames,Ses.roi.names);
ROI = subSelectROI(ROI,RoiName);
% limits data-set to avoid memory problem of my computer, Win24.
if any(strcmpi(RoiName,'brain')) & length(ROI.roi) > 30,
  fprintf(' limiting roi to 30 to avoid memory-problem...');
  idx = randperm(length(ROI.roi));
  idx = sort(idx(1:30));
  ROI.roi = ROI.roi(idx);
end
fprintf(' done.\n');

if length(ROI.roi) == 0,
  fprintf(' %s ERROR: roi ''%s'' not defined yet.\n',mfilename,RoiName);
  return;
end


fprintf(' %s: reading tc',mfilename);
TC_RAW = [];
TC_REALIGNED = [];
for iRoi = 1:length(ROI.roi),
  fprintf('.');
  
  tmproi  = ROI.roi{iRoi};
  slice   = tmproi.slice;
  mask    = tmproi.mask;

  idx = find(mask(:) > 0);
  if isempty(idx),  continue;  end
  
  % LOAD DATA WITHOUT REALIGNMENT
  tcImg = mn_tcslice_load(Ses,grp,slice,0);
  sz = size(tcImg.dat);
  tmpdat = reshape(tcImg.dat,[prod(sz(1:end-1)),sz(end)]);
  tmpdat = tmpdat(idx,:);
  if isempty(TC_RAW),
    TC_RAW = tmpdat;
  else
    TC_RAW = cat(1,TC_RAW,tmpdat);
  end
  
  % LOAD DATA WITH REALIGNMENT
  tcImg = mn_tcslice_load(Ses,grp,slice,1);
  sz = size(tcImg.dat);
  tmpdat = reshape(tcImg.dat,[prod(sz(1:end-1)),sz(end)]);
  tmpdat = tmpdat(idx,:);
  if isempty(TC_REALIGNED),
    TC_REALIGNED = tmpdat;
  else
    TC_REALIGNED = cat(1,TC_REALIGNED,tmpdat);
  end
end
fprintf(' done.\n');

DS = tcImg.ds;
DX = tcImg.dx;

fprintf(' %s: plotting data...',mfilename);
h = subPlotTC(TC_RAW, TC_REALIGNED,tcImg,ROI);
figfile = sprintf('%s_%s_%s_%s.fig',Ses.name,grp.name,mfilename,RoiName);
saveas(h,figfile);
fprintf(' saved as ''%s''.\n',figfile);


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to select ROI by "RoiName"
function ROI = subSelectROI(ROI,RoiName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ROI = mroiget(ROI,[],RoiName);
ROI = mroicat(ROI);

% sort by slice
ROISLICE = zeros(1,length(ROI.roi));
for N = 1:length(ROI.roi),
  ROISLICE(N) = ROI.roi{N}.slice;
end
[ROISLICE, idx] = sort(ROISLICE);
ROI.roi = ROI.roi(idx);


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot data
function hWin = subPlotTC(TC_RAW,TC_REALIGNED,tcImg,ROI)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RoiName = ROI.roi{1}.name;

tmptitle = sprintf('%s: %s %s',mfilename,tcImg.session,tcImg.grpname);
hWin = figure('Name',tmptitle);
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName',  'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');

TC_RAW = single(TC_RAW);
TC_REALIGNED = single(TC_REALIGNED);

M_RAW = mean(TC_RAW,1);
S_RAW = std(TC_RAW,[],1);
M_REALIGNED = mean(TC_REALIGNED,1);
S_REALIGNED = std(TC_REALIGNED,[],1);

% plot mean time course
T = [1:size(TC_RAW,2)];
subplot(2,2,1);
plot(T,M_RAW,'color','r','linewidth',2);  hold on; grid on;
plot(T,M_REALIGNED,'color','b','linewidth',2);
%plot(T,M_RAW+S_RAW,'color','r','linestyle','--');
%plot(T,M_RAW-S_RAW,'color','r','linestyle','--');
%plot(T,M_REALIGNED-S_REALIGNED,'color','b','linestyle','--');
%plot(T,M_REALIGNED+S_REALIGNED,'color','b','linestyle','--');
set(gca,'xlim',[0 max(T)]);
legend('RAW','REALIGNED');
xlabel('Experiment Number');
ylabel('Mean Voxel Value');
title('Voxel Time Course');
inftxt = sprintf('%s %s ROI=''%s'' NumVoxels=%d',...
                 tcImg.session,tcImg.grpname,...
                 RoiName,size(TC_RAW,1));
text(0.02,0.07,inftxt,'units','normalized','fontname','Comic Sans MS')


[tmpv,MAX_DIFF] = max(abs(M_RAW-M_REALIGNED));
ylm = get(gca,'ylim');
line([MAX_DIFF,MAX_DIFF],ylm,'color','k');
text(MAX_DIFF,mean(ylm(:)),'MAX-DIFF',...
     'horizontalalignment','center','fontweight','bold');


% plot CV (=s/m*100)
subplot(2,2,2);
if 0,
plot(T,S_RAW./M_RAW*100,'color','r','linewidth',2); hold on; grid on;
plot(T,S_REALIGNED./M_REALIGNED*100,'color','b','linewidth',2);
set(gca,'xlim',[0 max(T)]);
legend('RAW','REALIGNED');
xlabel('Experiment Number');
ylabel('Coefficient of Variation (std/mean*100)');
title('CV Time Course');
inftxt = sprintf('%s %s ROI=''%s'' NumVoxels=%d',...
                 tcImg.session,tcImg.grpname,...
                 RoiName,size(TC_RAW,1));
text(0.02,0.07,inftxt,'units','normalized','fontname','Comic Sans MS')
else
M_RAW = mean(TC_RAW,2);
S_RAW = std(TC_RAW,[],2);
M_REALIGNED = mean(TC_REALIGNED,2);
S_REALIGNED = std(TC_REALIGNED,[],2);

% avoid zero divide
idx = find(M_RAW(:) > 0 & M_REALIGNED(:) > 0);
M_RAW = M_RAW(idx);  S_RAW = S_RAW(idx);
M_REALIGNED = M_REALIGNED(idx);  S_REALIGNED = S_REALIGNED(idx);

CV_RAW = S_RAW./M_RAW*100;
CV_REALIGNED = S_REALIGNED./M_REALIGNED*100;

plot(CV_RAW,CV_REALIGNED,...
     'color','b','linestyle','none','marker','.');
grid on; hold on;
x = mean(CV_RAW(:));
y = mean(CV_REALIGNED(:));
plot(x,y,...
     'color','r','marker','o','markerfacecolor','r');
x2 = std(CV_RAW(:));
y2 = std(CV_REALIGNED(:));
line([x-x2 x+x2],[y y],'color','r','linewidth',2);
line([x x],[y-y2 y+y2],'color','r','linewidth',2);

xlabel('CV of RAW');
ylabel('CV of REALIGNED');
title('Coefficient of Variation, RAW vs. REALIGNED');
inftxt = sprintf('%s %s ROI=''%s'' NumVoxels=%d',...
                 tcImg.session,tcImg.grpname,...
                 RoiName,length(CV_RAW));
text(0.02,0.95,inftxt,'units','normalized','fontname','Comic Sans MS')
%xlm = get(gca,'xlim');
%ylm = get(gca,'ylim');
%maxv = max([xlm ylm]);
maxv = 100;
set(gca,'xlim', [0 maxv]);
set(gca,'ylim', [0 maxv]);
line([0 maxv],[0,maxv],'color','k');

end

% now plot difference between reference data
slice = ROI.roi{round(length(ROI.roi)/2 + 0.5)}.slice;
matfile = sprintf('TC_SLICE_RAW/%s_%s_sl%03d.mat',...
                  tcImg.session,tcImg.grpname,slice);
tcImgRAW = load(matfile,'tcImg');
tcImgRAW = tcImgRAW.tcImg;

matfile = sprintf('TC_SLICE_REALIGNED/%s_%s_sl%03d.mat',...
                  tcImg.session,tcImg.grpname,slice);
tcImgREALIGNED = load(matfile,'tcImg');
tcImgREALIGNED = tcImgREALIGNED.tcImg;


IMG_REF = tcImgRAW.dat(:,:,1,1);
IMG_RAW = tcImgRAW.dat(:,:,1,MAX_DIFF);
IMG_REALIGNED = tcImgREALIGNED.dat(:,:,1,MAX_DIFF);

DIF_RAW = IMG_RAW - IMG_REF;
DIF_REALIGNED = IMG_REALIGNED - IMG_REF;

maxv = max([DIF_RAW(:); DIF_REALIGNED(:)]);

X = [0:size(IMG_REF,1)-1] * tcImgRAW.ds(1);
Y = [0:size(IMG_REF,2)-1] * tcImgRAW.ds(2);

subplot(2,2,3);
imagesc(X,Y,DIF_RAW');
set(gca,'clim',[0 maxv]);
title('Diff Image of RAW');
xlabel('X in mm');
ylabel('Y in mm');
inftxt = sprintf('%s %s SLICE=%d Exp%d-Exp1',...
                 tcImg.session,tcImg.grpname,slice,MAX_DIFF);
text(0.02,0.07,inftxt,'units','normalized',...
     'color',[1 1 1],'fontname','Comic Sans MS')
colorbar('fontsize',6);


subplot(2,2,4);
imagesc(X,Y,DIF_REALIGNED');
set(gca,'clim',[0 maxv]);
title('Diff Image of REALIGNED');
xlabel('X in mm');
ylabel('Y in mm');
inftxt = sprintf('%s %s SLICE=%d Exp%d-Exp1',...
                 tcImg.session,tcImg.grpname,slice,MAX_DIFF);
text(0.02,0.07,inftxt,'units','normalized',...
     'color',[1 1 1],'fontname','Comic Sans MS')
colorbar('fontsize',6);


return;
