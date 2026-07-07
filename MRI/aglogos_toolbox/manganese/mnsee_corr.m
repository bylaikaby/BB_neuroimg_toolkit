function mnsee_corr(SESSION,GRPNAME,R,ALPHA,MODEL)
%MNSEE_CORR - shows results of MNALLCORR.
%  MNSEE_CORR(SESSION,GRPNAME,ALPHA) shows results of MNALLCORR.
%
%  VERSION :
%    0.90 27.06.05 YM  pre-release.
%    0.91 27.06.05 YM  bug fix.
%
%  See also MNALLCORR

if nargin < 2,  help mnsee_corr; return;  end


if nargin < 3,  R = 0.7;      end
if nargin < 4,  ALPHA = 0.2;  end
if nargin < 5,  MODEL = {};  end


% CONTROL FLAGS, SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
USE_REALIGNED = 1;
USE_PCA       = 1;

DO_MASKING    = 1;
DO_CLUSTER    = 1;

GAMMA         = 1.2;

if isempty(MODEL),  MODEL = {'plgn','mlgn','sc'};  end
if ischar(MODEL),   MODEL = { MODEL };  end


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


if DO_MASKING > 0,
  maskidx = find(anaImg.dat(:) < 4000);
end  


% LOAD AND PLOT RESULTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(' loading/plotting data...');
NImagesPlot = 20;
iImage = 0;  SLICES = [];
ALLCORR = load('allcorr.mat',grp.name);
ALLCORR = ALLCORR.(grp.name){1};

for iModel = 1:length(MODEL),
  ROINAME= MODEL{iModel};
  idxModel = find(strcmpi(ALLCORR.modelname,ROINAME));
  CORR_R = reshape(ALLCORR.r{idxModel},[nX nY nS]);
  CORR_P = reshape(ALLCORR.p{idxModel},[nX nY nS]);
  % mask out almost black regions
  if DO_MASKING > 0,
    CORR_P(maskidx) = 1;
    CORR_R(maskidx) = 0;
  end
  
  iImage = 0;  SLICES = [];
  for iSlice = 1:nS,
    iImage = iImage + 1;
    % detect clusters
    if DO_CLUSTER > 0,
      tmpR = squeeze(CORR_R(:,:,iSlice));
      tmpP = squeeze(CORR_P(:,:,iSlice));
      [px py] = find(tmpR >= R);
      if ~isempty(px),
        [px py] = mcluster(px,py);
        if ~isempty(px),
          idx = sub2ind([nX nY],px,py);
          tmpsel = tmpP(idx);
          tmpP(:) = 1;
          tmpP(idx) = tmpsel(:);
          tmpsel = tmpR(idx);
          tmpR(:) = 0;
          tmpR(idx) = tmpsel(:);
          CORR_P(:,:,iSlice) = tmpP;
          CORR_R(:,:,iSlice) = tmpR;
        else
          CORR_P(:,:,iSlice) = 1;
          CORR_R(:,:,iSlice) = 0;
        end
      end
    end
    SLICES(iImage) = iSlice;
    % plot data if iImage==NImagesPlot
    if iImage == NImagesPlot | iSlice == nS,
      hWin = subPlotData(Ses,grp,anaImg,ANARGB,ROINAME,CORR_R(:,:,SLICES),R,...
                         CORR_P(:,:,SLICES),ALPHA,SLICES);
      figfile = sprintf('%s_%s_%s_%s_%03d-%03d.fig',...
                        Ses.name,grp.name,mfilename,ROINAME,SLICES(1),SLICES(end));
      saveas(hWin,figfile);
      iImage  = 0;
      SLICES  = [];
    end
  end
end


fprintf('\n%s %s: done.\n',datestr(now,'HH:MM:SS'),mfilename);

return;





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot data
function hWin = subPlotData(Ses,grp,anaImg,ANARGB,ROINAME,CORR_R,R,CORR_P,ALPHA,SLICES)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmptitle = sprintf('%s: %s %s Corr.(%s) %d-%d R=%.2f',...
                   mfilename,Ses.name,grp.name,ROINAME,SLICES(1),SLICES(end),R);
hWin = figure('Name',tmptitle);
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName',  'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');
set(gcf,'PaperOrientation',     'portrait');


NRow = 4;
NCol = ceil(length(SLICES)/NRow);

nX = size(ANARGB,1);
nY = size(ANARGB,2);
X = [0:nX-1];  Y = [nY-1:-1:0];

%COLORCODE = jet(512);
%COLORCODE = COLORCODE(257:512,:);
COLORCODE = subColorCode('cool',256);
%COLORCODE = subColorCode('jet',256);
%COLORCODE = subColorCode('mri',256);
%COLORCODE = subColorCode('spring',256);

for N = 1:length(SLICES),
  tmpana = squeeze(ANARGB(:,:,:,SLICES(N)));
  tmpP = squeeze(CORR_P(:,:,N));
  tmpR = squeeze(CORR_R(:,:,N));
  iCol = floor((N-1)/NRow)+1;
  iRow = mod((N-1),NRow)+1;
  offsX = nX*(iRow-1);
  offsY = nY*NCol - iCol*nY;
  
  tmpimg = subFuseImage(tmpana,tmpR,R,tmpP,ALPHA,COLORCODE);

  tmpimg = permute(tmpimg,[2 1 3]);
  tmpx = X + offsX;  tmpy = Y + offsY;
  image(tmpx,tmpy,tmpimg);  hold on;
  text(min(tmpx)+1,min(tmpy)+1,sprintf('COR=%d',SLICES(N)),...
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
Y = [0:length(COLORCODE)-1]/(length(COLORCODE)-1);
Y = Y*(1-R) + R;
tmpimg = ind2rgb(0:length(COLORCODE)-1,COLORCODE);
image(0,Y,permute(tmpimg,[2 1 3]));
set(gca,'YAxisLocation','right','Ydir','normal');
title('CORR-R');
set(gca,'XTickLabel',{},'XTick',[]);


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to fuse image by corr.R
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function IMG = subFuseImage(ANARGB,RDAT,R,PDAT,ALPHA,COLORCODE)

IMG = ANARGB;

RDAT(find(isnan(RDAT(:)))) = 0; % to avoid error

tmpdat = repmat(RDAT,[1 1 3]);
idx = find(tmpdat(:) >= R);
if ~isempty(idx),
  % scale R from R to 1 as 0 to 256
  RDAT = (RDAT - R) / (1 - R)*256;
  RDAT = round(RDAT);
  RDAT = RDAT + 1;   % +1 for matlab indexing
  RDAT(find(RDAT(:) <   0)) = 0;  % to avoid error
  RDAT(find(RDAT(:) > 256)) = 256;  % to avoid error
  % map 0-255 as RGB
  RDAT = ind2rgb(RDAT,COLORCODE);
  % replace pixels
  IMG(idx) = RDAT(idx);
end

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to get a color code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function c = subColorCode(colorname,nlevels)

switch lower(colorname)
 case {'default','defalt','defult'}
  % Matlab does change colormap size to 64x3, so get original size.
  norig = size(colormap,1);
  c = colormap(colorname);
  n = size(c,1);
 
 case { 'mri' }
  h = round(nlevels/2);
  c = hot(h);
  c1 = zeros(h,3);
  c1(:,3) = [0:h-1]'./h;
  c = cat(1,flipud(c1),c);
  n = size(c,1);
  
 case { 'autumn','bone','colorcube','cool','copper',...
	'flag','gray','hot','hsv','jet','lines','pink','prism',...
	'spring','summer','white','winer' }
  % Matlab doen't change colormap size.
  c = eval(sprintf('colormap(%s(%d))',colorname,nlevels));
  n = size(c,1);
 
 case { 'r' }
  x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  c(:,[2 3]) = 0;
 case { 'g' }
  x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  c(:,[1 3]) = 0;
 case { 'b' }
  x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  c(:,[1 2]) = 0;
 case { 'c' }
  x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  c(:,1) = 0;
 case { 'm' }
  x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  c(:,2) = 0;
 case { 'y' }
  x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  c(:,3) = 0;
 case { 'k' }
  %x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  % black is meaning less, so use 'yellow'
  x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  c(:,3) = 0;
  
 otherwise
  fprintf(' not supported ''%s''\n',colorname);
  return;
end

% change number of levels for image
if nlevels ~= n,
  c = interp1(1:n,c,1:(n - 1)/(nlevels - 1):n,'linear');
end

return;
