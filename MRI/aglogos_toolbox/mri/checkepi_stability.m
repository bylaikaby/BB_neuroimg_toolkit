function [IDATA, IMGP] = checkepi_stability(DATA_DIR,STUDY_NAME,SCAN_RECO,varargin)
%
%
%  EXAMPLE :
%    >> DATA_DIR   = '\\10.102.5.251\ids1_mridata\7040\RawData';
%    >> STUDY_NAME = '20250902_095533_GeneralTest_20250902a_2_8';
%    >> SCAN_RECO  = [41 1];
%    >> SAVE_ROOT  = 'E:\DataMatlab';
%
%    >> checkepi_stability(DATA_DIR,STUDY_NAME,SCAN_RECO,'save_root',SAVE_ROOT);
%
%  VERSION :
%    0.90 2025.09.03 YM  derived from test_20250902.m.
%    0.91 2025.09.04 YM  adds more plots.
%
%  See also checkepi pvread_2dseq pv_imgpar mcentroid checkepi_spm_realign


SAVE_ROOT = 'E:\DataMatlab';

for N = 1:2:length(varargin)
  switch lower(varargin{N})
    case {'saveroot' 'save_root'}
      SAVE_ROOT = varargin{N+1};
  end
end




imgfile = fullfile(DATA_DIR,STUDY_NAME,sprintf('%d/pdata/%d/2dseq',SCAN_RECO(1),SCAN_RECO(2)));

% SIMPLE EVALUATION by MASS CENTROID ---------------------------------------------------
fprintf('%s: reading %s...',mfilename,imgfile);
[IDATA,IMGP] = pvread_2dseq(imgfile);  IDATA = double(IDATA);
%IMGP  = pv_imgpar(imgfile);
fprintf('done.\n');

inftxt = sprintf('InterVolTime=%gs nseg=%d Vol=[%d %d %d] Vox=[%g %g %g]mm',IMGP.imgtr,IMGP.nseg,IMGP.imgsize(1),IMGP.imgsize(2),IMGP.imgsize(3),IMGP.dimsize(1),IMGP.dimsize(2),IMGP.dimsize(3)); 

fprintf('  centroid...');
tcImg.centroid = mcentroid(IDATA,IMGP.dimsize(1:3));

H = figure('Name',sprintf('%s: %s [%d %d]',mfilename,STUDY_NAME, SCAN_RECO(1), SCAN_RECO(2)));
tmppos = get(gcf,'pos');  tmpy = tmppos(2)+tmppos(4); tmppos(3:4) = round(tmppos(3:4)*1.5); tmppos(2) = tmpy - tmppos(4); set(H,'pos',tmppos);
tmpt = 1:IMGP.imgsize(4);
subplot(2,2,1);
plot(tmpt,tcImg.centroid); grid on;
xlabel('Time in Volumes');
ylabel('X,Y,Z');
text(0.02,0.07,strrep(inftxt,'_','\_'),'units','normalized')
title(sprintf('Mass Centroid ScanReco=[%d %d]',SCAN_RECO(1),SCAN_RECO(2)));

tmpm = mean(tcImg.centroid,2);
tmps = std(tcImg.centroid,0,2);
tmpmin = min(tcImg.centroid,[],2);
tmpmax = max(tcImg.centroid,[],2);
DIM_STR = {'X' 'Y' 'Z'};
fprintf('\n');
for N = 1:length(tmpm)
  fprintf('%s: %g+/-%g, min/max=%g/%g\n',DIM_STR{N},tmpm(N),tmps(N),tmpmin(N),tmpmax(N));
end



% image intensities over the time
fprintf(' mean/std...');
tmpm = nanmean(IDATA,4);
tmps = nanstd(IDATA,[],4);
tmpidx = tmps(:) < eps;
tmpm(tmpidx) = 0;
tmps(tmpidx) = 1;
SNRDAT = tmpm ./ tmps;

CURDAT = IDATA;
CURDAT = reshape(CURDAT,[prod(IMGP.imgsize(1:3)) IMGP.imgsize(4)]);
tmpm = nanmean(CURDAT,1);
tmps = nanstd(CURDAT,0,1);

tSNR_thr = 12;
thrsel = (SNRDAT(:) > tSNR_thr);
tmpm2 = nanmean(CURDAT(thrsel,:),1);
tmps2 = nanstd(CURDAT(thrsel,:),0,1);

subplot(2,2,3);
tmpt = 1:IMGP.imgsize(4);
X = [tmpt fliplr(tmpt)];
Y = [tmpm - tmps fliplr(tmpm+tmps)];
patch(X,Y,[0.7 0.7 0.9],'edgecolor','none','FaceAlpha',.3,'HandleVisibility','off');
hold on;
plot(tmpt,tmpm,'linewidth',2);
Y = [tmpm2-tmps2 fliplr(tmpm2+tmps2)];
patch(X,Y,[0.9 0.7 0.7],'edgecolor','none','FaceAlpha',.3,'HandleVisibility','off');
plot(tmpt,tmpm2,'linewidth',2);
grid on;

legend({'mean+/-sd (all voxels)' sprintf('mean+/-sd (tSNR>%g)',tSNR_thr)});
title(sprintf('Mean Image Intensity ScanReco=[%d %d]',SCAN_RECO(1),SCAN_RECO(2)));
xlabel('Time in Volumes');
ylabel('Image Intensity');
text(0.02,0.07,strrep(inftxt,'_','\_'),'units','normalized')


% mean intensities along each axis
fprintf(' XYZ intensities...');
tmpvol = IDATA;
tmpvol = reshape(tmpvol,[prod(IMGP.imgsize(1:3)) IMGP.imgsize(4)]);
tmpvol(~thrsel,:) = NaN;
tmpvol = nanmean(tmpvol,2);
tmpvol = reshape(tmpvol,IMGP.imgsize(1:3));
subplot(2,2,2);
plot(nanmean(nanmean(tmpvol,2),3));  hold on;
plot(nanmean(nanmean(tmpvol,1),3));
plot(squeeze(nanmean(nanmean(tmpvol,1),2)));
grid on;
ylm = get(gca,'ylim');
set(gca,'xlim',[0 max(IMGP.imgsize(1:3))],'ylim',[0 ylm(2)]);
legend({'X' 'Y' 'Z'},'location','northwest');
title(sprintf('Intensities in XYZ space (tSNR>%g)',tSNR_thr));
xlabel('XYZ axis');
ylabel('Mean Intensity');



% intensity distribution
fprintf(' distribution...');
minv = min(0,min(IDATA(:)));
maxv = max(IDATA(:))*1.2;

edges0 = 0:(maxv/250):maxv;
histdata = zeros(size(IDATA,4),length(edges0)-1);
for K = 1:size(IDATA,4)
  tmpvol = IDATA(:,:,:,K);
  tmpN = histcounts(tmpvol(thrsel),edges0);
  histdata(K,:) = tmpN(:)';
end
tmpy = (edges0(1:end-1) + edges0(2:end))/2;
subplot(2,2,4);
surf(1:IMGP.imgsize(4),tmpy,histdata','linestyle','none');
title(sprintf('Intensity Distribution in time (tSNR>%g)',tSNR_thr));
xlabel('Time in Volumes');
ylabel('Voxel Intensity');
zlabel('# of Voxels');
set(gca,'ydir','reverse');



SAVE_DIR = fullfile(SAVE_ROOT,STUDY_NAME);
if ~exist(SAVE_DIR,'dir')
  mkdir(SAVE_DIR);
end



figfile = fullfile(SAVE_DIR,sprintf('%s_scan%d-%d_%s.fig',STUDY_NAME,SCAN_RECO(1),SCAN_RECO(2),mfilename));
saveas(H,figfile);

fprintf(' done.\n');
