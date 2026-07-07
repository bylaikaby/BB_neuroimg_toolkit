function mnsee_horizontal(SESSION,GRPNAME,HSEL,PROJOUT)
%MNSEE_HORIZONTAL - Plots images of optic pathway in different time
%  MNSEE_HORIZONTAL(SESSION,GRPNAME,HSEL) Plots horizontal images given by HSEL.
%
%  VERSION :
%    0.90 17.06.05 YM  pre-release
%
%  See also

if nargin < 2,  help mnsee_horizontal; return;  end

if nargin < 3,  HSEL = []; end
if nargin < 4,  PROJOUT = {};  end

USE_PCA = 0;
%PROJOUT = {'muscle'};


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);

if isempty(HSEL),
  switch lower(Ses.name),
   case {'d03se1'}
    HSEL = [61:65];	% can see optic nerve, ciasm, tract.
   otherwise
    HSEL = [61:65];
  end
end
if ischar(PROJOUT) & ~isempty(PROJOUT),  PROJOUT = { PROJOUT };  end



% LOADING ANATOMY DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
anaImg = anaload(Ses,grp);
nX = size(anaImg.dat,1);  nY = size(anaImg.dat,2);  nS = size(anaImg.dat,3);
nT = length(grp.exps);



% LOAD roiTs for PROJOUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(PROJOUT),
  roiPrj = {};
  for N = 1:length(PROJOUT),
    tmpts = mn_roits_get(Ses,grp,PROJOUT{N},[],USE_PCA);
    tmpts = mn_roits_cat(tmpts);
    if ~isempty(tmpts) & ~isempty(tmpts.dat),
      roiPrj{end+1} = tmpts;
    end
  end
  BASEDAT = zeros(nT,length(roiPrj));
  for N = 1:length(roiPrj),
    BASEDAT(:,N) = mean(roiPrj{N}.dat,2);
  end
end



% LOAD TIME COURSE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
IMGDAT = zeros(nX,length(HSEL),nS,nT,'int16');
for iSlice = 1:nS,
  tcImg = mn_tcslice_load(Ses,grp,iSlice);
  if USE_PCA > 0,
    tmpdat = tcImg.pca_denoised;
  else
    tmpdat = tcImg.dat;
  end
  tmpdat = tmpdat(:,HSEL,1,:);
  if ~isempty(PROJOUT),
    %sz = [nX length(HSEL) 1 nT];
    tmpdat = permute(tmpdat,[4 1 2 3]);
    tmpdat = reshape(tmpdat,[nT nX*length(HSEL)*1]);
    tmpdat = double(tmpdat);
    tmpdat = mn_roits_projout(struct('dat',tmpdat),BASEDAT);
    tmpdat = int16(round(tmpdat.dat));
    tmpdat = reshape(tmpdat,[nT nX,length(HSEL),1]);
    tmpdat = permute(tmpdat,[2 3 4 1]);
  end
  IMGDAT(:,:,iSlice,:) = tmpdat;
end


% LOAD roiTs for NORMALIZATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%roiNorm = mn_roits_get(Ses,grp,'copn',[],USE_PCA);
%roiNorm = mn_roits_get(Ses,grp,'pituitary',[],USE_PCA);
roiNorm = mn_roits_get(Ses,grp,'global',[],USE_PCA);
roiNorm = mn_roits_cat(roiNorm);
%NORMDAT = mean(roiNorm.dat,2);
NORMDAT = double(median(roiNorm.dat,2));


IMGDAT = double(IMGDAT);
% NORMALIZE TIME COURSES
for iT = 1:size(IMGDAT,4),
  IMGDAT(:,:,:,iT) = IMGDAT(:,:,:,iT) / NORMDAT(iT);
end


% convert into SDU
if 1,
  MIMG = mean(IMGDAT(:,:,:,1:5),4);
  SIMG = std(IMGDAT(:,:,:,1:5),[],4);
%  idx = find(SIMG(:) == 0);
%  SIMG(idx) = 1;	% to avoid error
%  for iT = 1:size(IMGDAT,4),
%    tmpimg = IMGDAT(:,:,:,iT);
%    tmpimg = (IMGDAT(:,:,:,iT) - MIMG(:,:,:)) ./ SIMG(:,:,:);
%    tmpimg(idx) = 0;
%   IMGDAT(:,:,:,iT) = tmpimg;
%  end
  IMGCV = IMGDAT;
  for iT = 1:size(IMGDAT,4),
    if iT <= 5,
      tmpm = MIMG;
      tmps = SIMG;
    else
      tmpm = mean(IMGDAT(:,:,:,1:iT),4);
      tmps = std(IMGDAT(:,:,:,1:iT),[],4);
    end
    idx = find(tmpm(:) <= 0.6);
    tmps(idx) = 0;
    tmpm(idx) = 1;
    IMGCV(:,:,:,iT) = tmps ./ tmpm;
    %IMGCV(:,:,:,iT) = tmps;
  end
  IMGDAT = IMGCV;
end




% PLOT IMAGES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hWin = subPlotImage(Ses,grp,HSEL,IMGDAT,USE_PCA,PROJOUT);
if isempty(PROJOUT),
  figfile = sprintf('%s_%s_%s_%03d-%03d.fig',Ses.name,grp.name,mfilename,HSEL(1),HSEL(end));
else
  figfile =  sprintf('%s_%s_%s_%03d-%03d_projout.fig',Ses.name,grp.name,mfilename,HSEL(1),HSEL(end));
end
saveas(hWin,figfile);


if nargout,
  varargout{1} = tcImg;
end



return;





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot images
function hWin = subPlotImage(Ses,grp,HSEL,IMGDAT,USE_PCA,PROJOUT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t = mn_exptime(Ses,grp);
IMGDAT = squeeze(mean(IMGDAT,2));
nX = size(IMGDAT,1);
nY = size(IMGDAT,2);
X = [0:nX-1];  Y = [nY-1:-1:0];

% will limit display images 8by5.
if length(t) > 8*5,
  T_IDX = round(1:length(t)/8/5:length(t));
else
  T_IDX = 1:length(t);
end


NRow = 8;
NCol = ceil(length(T_IDX)/8);


tmptitle = sprintf('%s: %s %s Horizontal Section',mfilename,Ses.name,grp.name);
hWin = figure('Name',tmptitle);
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName',  'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');
set(gcf,'PaperOrientation',     'landscape');


colormap(jet(256));
for N = 1:length(T_IDX),
  tmpimg = squeeze(IMGDAT(:,:,T_IDX(N)));
  iCol = floor((N-1)/NRow)+1;
  iRow = mod((N-1),NRow)+1;
  offsX = nX*(iRow-1);
  offsY = nY*NCol - iCol*nY;
  
  tmpx = X + offsX;  tmpy = Y + offsY;
  imagesc(tmpx,tmpy,tmpimg');  hold on;
  text(min(tmpx),min(tmpy),sprintf('T=%.1fhr',t(T_IDX(N))),...
       'color',[0.9 0.9 0.5],'VerticalAlignment','bottom',...
       'FontName','Comic Sans MS','FontSize',8,'Fontweight','bold');
  %set(gca,'xlim',[0 nX*NRow],'ylim',[0 nY*NCol],'YDir','normal');
end
set(gca,'XTickLabel',{},'YTickLabel',{},'XTick',[],'YTick',[]);
set(gca,'xlim',[0 nX*NRow],'ylim',[0 nY*NCol]);
set(gca,'YDir','normal');
daspect([1 1 1])
tmptxt = sprintf('%s %s: Horizontal Section [%d-%d]',Ses.name,grp.name,HSEL(1),HSEL(end));
title(strrep(tmptxt,'_','\_'));
clim = get(gca,'clim');
%set(gca,'clim',[0 clim(2)]);

colorbar;
if isempty(PROJOUT),
  tmptxt = sprintf('USE_PCA=%d, ProjOut(none)',USE_PCA);
else
  tmptxt = sprintf('USE_PCA=%d, ProjOut(%s',USE_PCA,PROJOUT{1});
  for N=2:length(PROJOUT),  tmptxt = sprintf('%s+%s',tmptxt,PROJOUT{N});  end
  tmptxt = sprintf('%s)',tmptxt);
end
xlabel(strrep(tmptxt,'_','\_'));


return;

