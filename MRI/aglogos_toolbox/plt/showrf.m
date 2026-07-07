function showrf(SESSION,FileTag,Chan)
%SHOWRF - Show site-RF structure for different frequency bands
% SHOWRF(SESSION,FileTag,Chan,ImgContrast), whereby SESSION is the session name and
% FileTag is either an experiment number or a group name, displays
% the site RF structure computed by means of reverse correlation.
%
ImgContrast = 'lum';

if nargin < 3, Chan = []; end;
if nargin < 2,
  error('showrf: usage showrf(SESSION,GrpName);');
end;

Ses = goto(SESSION);
SigNames = getrfsigs(Ses);

Filter = 0;
if isfield(Ses.anap.revcor,'Filter'),
  if Ses.anap.revcor.Filter,
    Filter = Ses.anap.revcor.Filter;
  end;
end;

% ------------------------------------------------------------------------
% LOAD DATA
% ------------------------------------------------------------------------
if isa(FileTag,'char'),
  GrpName = FileTag;
  filename = strcat(GrpName,'.mat');
  grp = getgrpbyname(Ses,GrpName);
else
  ExpNo = FileTag;
  filename = catfilename(Ses,ExpNo,'mat');
  grp = getgrp(Ses,ExpNo);
  GrpName = grp.name;
end;
anap = getanap(Ses,grp.exps(1));

Sig = loadrfsigs(Ses,GrpName);

if length(Chan) > 1,
  for N=1:length(Chan),
    subPlot(Ses, GrpName, Sig, Chan(N), ImgContrast, Filter);
  end;
else
  subPlot(Ses, GrpName, Sig, Chan, ImgContrast, Filter);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subPlot(Ses, GrpName, Sig, Chan, ImgContrast, Filter)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for N=1:length(Sig),
  if isempty(Chan) | Chan==0,
    if ~isempty(Ses.anap.revcor.SelRFChan),
      Sig{N}.dat = Sig{N}.dat(:,:,:,:,Ses.anap.revcor.SelRFChan);
    end;
    Sig{N}.dat = hnanmean(Sig{N}.dat,5);
  else
    Sig{N}.dat = Sig{N}.dat(:,:,:,:,Chan);
  end;
end;
  
SAME_SCALE = 0;
tit=sprintf('CMD: showrf (''%s'', ''%s'', Chan=%d);', Ses.name, GrpName, Chan);

mfigure([100 100 600 800]);
set(gcf,'color','w');
h = [];
for N=1:length(Sig),
  h(N) = msubplot(3,2,N);
  subDisplayRF(Sig{N},ImgContrast,Filter);
  clim(N,:) = get(gca,'clim');
end;
allclim = [min(clim(:)) max(clim(:))];
  
if SAME_SCALE,
  for N=1:length(Sig),
    set(h(N),'clim',allclim);
  end;
end;

if ~isfield(Ses.anap.revcor, 'RFPLOT') | ~Ses.anap.revcor.RFPLOT,
  suptitle(tit);
end;

return;
% NOW DISPLAY THE MANUAL RF PLOTTING
par = expgetpar(Ses, GrpName);
plotrf('rfp',par.rfp);
set(gca,'xlim',[-15 15],'ylim',[-15 15]);
hold on;
mkrfgrid(Ses.anap.revcor.MovPos);
suptitle(tit);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subDisplayRF(Sig,ImgContrast,Filter)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if iscell(Sig),
  Sig = Sig{1};
end;
tmp = squeeze(Sig.dat);
if strcmp(ImgContrast,'lum'),
  tmp = hnanmean(tmp,3);
elseif strcmp(ImgContrast,'col'),
  R = tmp(:,:,1);
  G = tmp(:,:,2);
  B = tmp(:,:,3);
  RG = hnanmean(tmp(:,:,1:2),3);
  tmp = sqrt((R-G).^2+(B-RG).^2);
elseif strcmp(ImgContrast,'mix'),
  tmpL = hnanmean(tmp,3);
  R = tmp(:,:,1);
  G = tmp(:,:,2);
  B = tmp(:,:,3);
  RG = hnanmean(tmp(:,:,1:2),3);
  tmpC = sqrt((R-G).^2+(B-RG).^2);
  tmp = sqrt(tmpL.*tmpL+tmpC.*tmpC);
else
  fprintf('Image Contrast values: "lum" or "col"\n');
end;

if Filter,
  tmp = mconv(tmp,7,1.5);
end;

imagesc(tmp);
daspect([ 1 1 1]);
axis off;
mytext = sprintf('Signal: %s', upper(Sig.dir.dname));
title(mytext,'color','k','fontsize',12,'fontweight','bold','interpreter','none');
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mkrfgrid(movpos)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
w = movpos(3);
h = movpos(4);
x = movpos(1)-w/2;
y = movpos(2)-h/2;
rectangle('Position', [x y w h],'linewidth',3,'edgecolor','r');

