function mnsee_ttest(SESSION,GRPNAME,ALPHA)
%MNSEE_TTEST - shows results of MMTTEST
%  MNSEE_TTEST(SESSION,GRPNAME,ALPHA) shows results of MNTTEST
%
%  VERSION :
%    0.90 23.06.05 YM  pre-release
%    0.91 26.06.05 YM  bug fix, plots T-statistics.
%
%  See also MNTTEST

if nargin < 2,  help mnsee_ttest; return;  end



if nargin < 3,  ALPHA = 0.2;  end


% CONTROL FLAGS, SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
USE_REALIGNED = 1;
USE_PCA       = 1;

DO_MASKING    = 1;
DO_CLUSTER    = 1;

GAMMA         = 1.2;
MAX_TSTAT     = 25;



% GET BASIC INFORMATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);


fprintf('%s %s: %s(%s) ',datestr(now,'HH:MM:SS'),mfilename,Ses.name,grp.name);
fprintf(' USE_REALIGNED=%d, USE_PCA=%d, DO_MASKING=%d, DO_CLUSTER=%d\n',...
        USE_REALIGNED,USE_PCA,DO_MASKING,DO_CLUSTER);


% LOAD ANATOMY DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(' loading anatomy...');
anaImg = anaload(Ses,grp);
nX = size(anaImg.dat,1);  nY = size(anaImg.dat,2);  nS = size(anaImg.dat,3);
nT = length(grp.exps);

% make RGB of anatomy data
tmpana = double(anaImg.dat);
tmpana = tmpana / (max(tmpana(:))*0.7);
if GAMMA ~= 1,
  for N = size(tmpana,3):-1:1,
    tmpana(:,:,N) = imadjust(tmpana(:,:,N),[0.015 0.95],[0 1],1/GAMMA);
  end
end
tmpana = tmpana*255 + 1;   % +1 for matalb indexing.
tmpana = round(tmpana);
tmpana(find(tmpana(:) <   0)) =   0;
tmpana(find(tmpana(:) > 256)) = 256;
for N = size(tmpana,3):-1:1,
  ANARGB(:,:,:,N) = ind2rgb(tmpana(:,:,N),gray(256));
end
clear tmpana;



% LOAD AND PLOT RESULTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(' loading/plotting data...');
NImagesPlot = 20;
iImage = 0;  DSP_SLICES = [];
TTEST_P = [];  TTEST_T = [];
for iSlice = 1:nS,
  iImage = iImage + 1;
  % load data
  tcImg = mn_tcslice_load(Ses,grp,iSlice,USE_REALIGNED);
  if USE_PCA,
    tmpP = tcImg.ttest.pca_p;
    tmpT = tcImg.ttest.pca_tstat;
  else
    tmpP = tcImg.ttest.p;
    tmpT = tcImg.ttest.tstat;
  end
  
  % mask out almost black regions
  if DO_MASKING > 0,
    %idx = find(imgana(:) < 1200);
    imgana = anaImg.dat(:,:,iSlice);
    idx = find(imgana(:) < 4000);
    tmpP(idx) = 1;
    tmpT(idx) = 0;
  end
  % detect clusters
  if DO_CLUSTER > 0,
    [px py] = find(tmpP <= ALPHA);
    if ~isempty(px),
      [px py] = mcluster(px,py);
      if ~isempty(px),
        idx = sub2ind([size(tmpP,1),size(tmpP,2)],px,py);
        tmpsel = tmpP(idx);
        tmpP(:) = 1;
        tmpP(idx) = tmpsel(:);
        tmpsel = tmpT(idx);
        tmpT(:) = 0;
        tmpT(idx) = tmpsel(:);
      else
        tmpP(:) = 1;
        tmpT(:) = 0;
      end
    end
  end

  TTEST_P = cat(3,TTEST_P,tmpP);
  TTEST_T = cat(3,TTEST_T,tmpT);
  DSP_SLICES(iImage) = iSlice;
  
  % plot data if iImage==NImagesPlot
  if iImage == NImagesPlot | iSlice == SLICES(end),
    TTEST_T = abs(TTEST_T);
    hWin = subPlotData(Ses,grp,anaImg,ANARGB,tcImg,...
                       TTEST_T,MAX_TSTAT,TTEST_P,ALPHA,DSP_SLICES);
    figfile = sprintf('%s_%s_%s_%03d-%03d',...
                      Ses.name,grp.name,mfilename,DSP_SLICES(1),DSP_SLICES(end));
    if tcImg.ttest.xyfilter > 0,
      figfile = sprintf('%s_XYSMOOTHING.fig',figfile);
    else
      figfile = sprintf('%s_NO-XYSMOOTHING.fig',figfile);
    end
    saveas(hWin,figfile);
    iImage  = 0;
    TTEST_P = [];
    TTEST_T = [];
    DSP_SLICES  = [];
  end
end


fprintf('\n%s %s: done.\n',datestr(now,'HH:MM:SS'),mfilename);

return;





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot data
function hWin = subPlotData(Ses,grp,anaImg,ANARGB,tcImg,TTEST_T,MAX_TSTAT,TTEST_P,ALPHA,DSP_SLICES)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmptitle = sprintf('%s: %s %s T-Test %d-%d ALPHA=%f',...
                   mfilename,Ses.name,grp.name,DSP_SLICES(1),DSP_SLICES(end),ALPHA);
if tcImg.ttest.xyfilter > 0,
  tmptitle = sprintf('%s XYSMOOTHING',tmptitle);
else
  tmptitle = sprintf('%s NO-XYSMOOTHING',tmptitle);
end
hWin = figure('Name',tmptitle);
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName',  'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');
set(gcf,'PaperOrientation',     'portrait');


PLOT_BY_T = 1;

NRow = 4;
NCol = ceil(length(DSP_SLICES)/NRow);

nX = size(ANARGB,1);
nY = size(ANARGB,2);
X = [0:nX-1];  Y = [nY-1:-1:0];

%COLORCODE = jet(512);
%COLORCODE = COLORCODE(257:512,:);
COLORCODE = mncolorcode('cool',256);
%COLORCODE = mncolorcode('jet',256);
%COLORCODE = mncolorcode('mri',256);
%COLORCODE = mncolorcode('spring',256);

for N = 1:length(DSP_SLICES),
  tmpana = squeeze(ANARGB(:,:,:,DSP_SLICES(N)));
  tmpP = squeeze(TTEST_P(:,:,N));
  tmpT = squeeze(TTEST_T(:,:,N));
  iCol = floor((N-1)/NRow)+1;
  iRow = mod((N-1),NRow)+1;
  offsX = nX*(iRow-1);
  offsY = nY*NCol - iCol*nY;
  
  if PLOT_BY_T,
    tmpimg = subFuseImageWithT(tmpana,tmpT,tmpP,ALPHA,COLORCODE,MAX_TSTAT);
  else
    tmpimg = subFuseImageWithP(tmpana,tmpT,tmpP,ALPHA,COLORCODE);
  end
  tmpimg = permute(tmpimg,[2 1 3]);
  tmpx = X + offsX;  tmpy = Y + offsY;
  image(tmpx,tmpy,tmpimg);  hold on;
  text(min(tmpx)+1,min(tmpy)+1,sprintf('COR=%d',DSP_SLICES(N)),...
       'color',[0.9 0.9 0.5],'VerticalAlignment','bottom',...
       'FontName','Comic Sans MS','FontSize',8,'Fontweight','bold');
  %set(gca,'xlim',[0 nX*NRow],'ylim',[0 nY*NCol],'YDir','normal');
end
set(gca,'XTickLabel',{},'YTickLabel',{},'XTick',[],'YTick',[]);
set(gca,'xlim',[0 nX*NRow],'ylim',[0 nY*NCol]);
set(gca,'YDir','normal');
daspect([1 1 1]);
set(gca,'pos',[0.1300    0.1100    0.7093    0.8150]);
title(strrep(tmptitle,'_','\_'));


% PLOT COLORBAR
axes('pos',[0.8696    0.1100    0.0411    0.1614]);
if PLOT_BY_T,
  Y = [0:length(COLORCODE)-1]/(length(COLORCODE)-1) * MAX_TSTAT;
  tmpimg = ind2rgb(0:length(COLORCODE)-1,COLORCODE);
  image(0,Y,permute(tmpimg,[2 1 3]));
  set(gca,'YAxisLocation','right','Ydir','normal');
  title('T-stat');
else
  Y = [-length(COLORCODE)+1:0]/(length(COLORCODE)-1) * ALPHA;
  Y = abs(Y);
  tmpimg = ind2rgb(0:length(COLORCODE)-1,COLORCODE);
  image(0,Y,permute(tmpimg,[2 1 3]));
  set(gca,'YAxisLocation','right','Ydir','reverse');
  title('P');
end
set(gca,'XTickLabel',{},'XTick',[]);

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to fuse image and t-test P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function IMG = subFuseImageWithP(ANARGB,TDAT,PDAT,ALPHA,COLORCODE)

IMG = ANARGB;

PDAT(find(isnan(PDAT(:)))) = 1; % to avoid error

tmpdat = repmat(PDAT,[1 1 3]);
idx = find(tmpdat(:) < ALPHA);
if ~isempty(idx),
  % scale ALPHA to 0 as 0 to 256
  PDAT = (1 - PDAT/ALPHA)*256;
  PDAT = round(PDAT);
  PDAT = PDAT + 1;   % +1 for matlab indexing
  PDAT(find(PDAT(:) <   0)) = 0;  % to avoid error
  PDAT(find(PDAT(:) > 256)) = 256;  % to avoid error
  % map 0-255 as RGB
  PDAT = ind2rgb(PDAT,COLORCODE);
  % replace pixels
  IMG(idx) = PDAT(idx);
end

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to fuse image and t-test T
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function IMG = subFuseImageWithT(ANARGB,TDAT,PDAT,ALPHA,COLORCODE,MAX_TSTAT)

IMG = ANARGB;

PDAT(find(isnan(PDAT(:)))) = 1; % to avoid error
TDAT(find(isnan(TDAT(:)))) = 0;

tmpdat = repmat(PDAT,[1 1 3]);
idx = find(tmpdat(:) < ALPHA);
if ~isempty(idx),
  % scale TDAT from 0 to 256
  TDAT = TDAT / MAX_TSTAT * 256;
  TDAT = round(TDAT);
  TDAT = TDAT + 1;   % +1 for matlab indexing
  TDAT(find(TDAT(:) <   0)) = 0;  % to avoid error
  TDAT(find(TDAT(:) > 256)) = 256;  % to avoid error
  % map 0-255 as RGB
  TDAT = ind2rgb(TDAT,COLORCODE);
  % replace pixels
  IMG(idx) = TDAT(idx);
end

return;


