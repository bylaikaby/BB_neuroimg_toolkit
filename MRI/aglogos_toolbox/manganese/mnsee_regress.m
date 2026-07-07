function mnsee_regress(SESSION,GRPNAME,CONTVEC,ALPHA)
%MNSEE_REGRESS - shows results of MMREGRESS.
%  MNSEE_REGRESS(SESSION,GRPNAME,CONTVEC,ALPHA) shows results of MNREGRESS.
%
%  VERSION :
%    0.90 28.06.05 YM  pre-release
%
%  See also MNREGRESS, REGRESS

if nargin < 2,  help mnsee_regress; return;  end


if nargin < 3,  CONTVEC = [];   end
if nargin < 4,  ALPHA = 0.01;  end



% CONTROL FLAGS, SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DEBUG         = 0;
USE_REALIGNED = 1;
USE_PCA       = 1;

DO_MASKING    = 1;
DO_CLUSTER    = 0;

GAMMA         = 1.2;
MAX_TSTAT     = 20;



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


% LOAD GLOBAL TIME COURSE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TC_GLOBAL = load('tcglobal.mat',grp.name);
TC_GLOBAL = TC_GLOBAL.(grp.name);


if DEBUG > 0,
  SLICES = 41:60;
  SLICES = 51:58;
else
  %SLICES = 1:nS;
  SLICES = 2:2:nS;
end


% LOAD AND PLOT RESULTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(' loading/plotting data...');
NImagesPlot = 20;
iImage = 0;  DSP_SLICES = [];
REGRESS_P = [];  REGRESS_T = [];
for iSlice = SLICES,
  iImage = iImage + 1;
  % load data
  tcImg = mn_tcslice_load(Ses,grp,iSlice,USE_REALIGNED);

  if tcImg.regress.use_pca > 0,
    y = double(tcImg.pca_denoised);
  else
    y = double(tcImg.dat);
  end
  if tcImg.regress.normalize > 0,
    for iT = 1:size(y,4),
      y(:,:,:,iT) = y(:,:,:,iT) / TC_GLOBAL.dat(iT);
    end
  end
  if tcImg.regress.xyfilter > 0,
    % params for XY filtering
    XYFILT_HSIZE = tcImg.regress.xyfilt_hsize;
    XYFILT_SIGMA = tcImg.regress.xyfilt_sigma;
    h = fspecial('gaussian',XYFILT_HSIZE,XYFILT_SIGMA);
    for N = 1:size(y,3),
      for iT = 1:size(y,4),
        y(:,:,N,iT) = filter2(h,y(:,:,N,iT),'same');
      end
    end
  end

  tmpreg = tcImg.regress;
  sz    = size(tcImg.regress.beta);
  BETA  = permute(reshape(tmpreg.beta,[prod(sz(1:end-1)), sz(end)]),[2 1]);
  STATS = mulregress_contrast(BETA,tmpreg.covb,CONTVEC,tmpreg.dfe);

  tmpT = reshape(STATS.tstat.t,   [nX,nY]);
  tmpP = reshape(STATS.tstat.pval,[nX,nY]);

  % remove negative correlation
  idx = find(tmpT(:) < 0);
  tmpT(idx) = 0;
  tmpP(idx) = 1;
  
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

  REGRESS_P = cat(3,REGRESS_P,tmpP);
  REGRESS_T = cat(3,REGRESS_T,tmpT);
  DSP_SLICES(iImage) = iSlice;
  
  % plot data if iImage==NImagesPlot
  if iImage == NImagesPlot | iSlice == SLICES(end),
    hWin = subPlotData(Ses,grp,anaImg,ANARGB,tcImg,...
                       REGRESS_T,MAX_TSTAT,REGRESS_P,ALPHA,DSP_SLICES);
    figfile = sprintf('%s_%s_%s_plgn(+1.5)_mlgn(+1.5)_else(-1)_%03d-%03d',...
                      Ses.name,grp.name,mfilename,DSP_SLICES(1),DSP_SLICES(end));
    if tcImg.regress.xyfilter > 0,
      figfile = sprintf('%s_XYSMOOTHING.fig',figfile);
    else
      figfile = sprintf('%s_NO-XYSMOOTHING.fig',figfile);
    end
    saveas(hWin,figfile);
    iImage  = 0;
    REGRESS_P = [];
    REGRESS_T = [];
    DSP_SLICES  = [];
  end
end


fprintf('\n%s %s: done.\n',datestr(now,'HH:MM:SS'),mfilename);

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to get map for multi-regression
function [TMAP,PMAP] = subGetMap(Y,REGDAT,CONTVEC)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if full-model, then return existing values.
if isempty(REGSEL) | length(REGSEL) == size(REGDAT.model.Q,2),
%  PMAP = REGDAT.full_model.p;
%  TMAP = REGDAT.full_model.f;
%  return;
end

if isempty(CONTVEC),
  CONTVEC = ones(1,length(REGDAT.tag));
elseif length(CONTVEC) > length(REGDAT.tag),
  CONTVEC = CONTVEC(1:length(REGDAT.tag));
end

nX = size(Y,1);  nY = size(Y,2);  nS = size(Y,3);  nT = size(Y,4);


  
return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot data
function hWin = subPlotData(Ses,grp,anaImg,ANARGB,tcImg,REGRESS_T,MAX_TSTAT,REGRESS_P,ALPHA,DSP_SLICES)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmptitle = sprintf('%s: %s %s MulRegress %d-%d ALPHA=%.3g',...
                   mfilename,Ses.name,grp.name,DSP_SLICES(1),DSP_SLICES(end),ALPHA);
if tcImg.regress.xyfilter > 0,
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
  tmpP = squeeze(REGRESS_P(:,:,N));
  tmpT = squeeze(REGRESS_T(:,:,N));
  iCol = floor((N-1)/NRow)+1;
  iRow = mod((N-1),NRow)+1;
  offsX = nX*(iRow-1);
  offsY = nY*NCol - iCol*nY;
  
  tmpimg = subFuseImage(tmpana,tmpT,MAX_TSTAT,tmpP,ALPHA,COLORCODE);

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
tmptitle = sprintf('MulRegress: %s(%s) %d-%d ALPHA=%.3g',...
                   Ses.name,grp.name,DSP_SLICES(1),DSP_SLICES(end),ALPHA);
tmptitle = sprintf('MulRegress: %s(%s) %d-%d',...
                   Ses.name,grp.name,DSP_SLICES(1),DSP_SLICES(end));
title(strrep(tmptitle,'_','\_'));


% PLOT COLORBAR
axes('pos',[0.8696    0.1100    0.0411    0.1614]);
Y = [0:length(COLORCODE)-1]/(length(COLORCODE)-1) * MAX_TSTAT;
tmpimg = ind2rgb(0:length(COLORCODE)-1,COLORCODE);
image(0,Y,permute(tmpimg,[2 1 3]));
set(gca,'YAxisLocation','right','Ydir','normal');
title('T-stat');
set(gca,'XTickLabel',{},'XTick',[]);

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to fuse image and P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function IMG = subFuseImage(ANARGB,TDAT,MAX_TSTAT,PDAT,ALPHA,COLORCODE)

IMG = ANARGB;

PDAT(find(isnan(PDAT(:)))) = 1; % to avoid error

tmpdat = repmat(PDAT,[1 1 3]);
idx = find(tmpdat(:) < ALPHA);
if ~isempty(idx),
  % scale ALPHA to 0 as 0 to 256
  TDAT = TDAT/MAX_TSTAT * 256;
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

