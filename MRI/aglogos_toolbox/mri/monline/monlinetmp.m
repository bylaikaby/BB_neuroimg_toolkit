function varargout = monlinetmp(varargin)
%MONLINETMP - Do online analyis for fMRI
%  MONLINETMP(IMGFILE) does quick analysis of fMRI and shows results.
%
%  EXAMPLE :
%    >> SIG = monlinetmp('//wks4/guest/mridata_wks4/C03.DA1/27/pdata/1/2dseq',0.01,'ttest');
%    >> ANA = monline_ana('//wks4/guest/mridata_wks4/C03.DA1/27/pdata/1/2dseq');
%    >> monlinetmp(SIG,0.05,'ttest',ANA);
%
%
%  VERSION :
%    0.90 16.09.06 YM  pre-release
%
%  See also MONLINE_PROC

if nargin == 0,  eval(sprintf('help %s;',mfilename));  return;  end


% check the input
if ischar(varargin{1}),
  SIG = monline_proc(varargin{1});
elseif isstruct(varargin{1}),
  SIG = varargin{1};
end
ALPHA    = [];
STATNAME = '';
ANA      = {};
if nargin > 1,  ALPHA = varargin{2};     end
if nargin > 2,  STATNAME = varargin{3};  end
if nargin > 3,  ANA   = varargin{4};     end
if isempty(ALPHA),     ALPHA = 0.01;        end
if isempty(STATNAME),  STATNAME = 'ttest';  end
if ~isempty(ANA),
  SIG.ana = ANA.dat;
end



anaminv = 0;
anamaxv = round(mean(SIG.ana(:))*7.0);
anagamma = 1.8;
SIG.anargb = subScaleAnatomy(SIG.ana,anaminv,anamaxv,anagamma);
  
  
nsli = size(SIG.ana,3);
if nsli <= 3,
  NRow = nsli;  NCol = 1;  %  nsli images in a page
elseif nsli <= 4,
  NRow = 2;  NCol = 2;  %  4 images in a page
elseif nsli <= 9
  NRow = 3;  NCol = 3;  %  9 images in a page
elseif nsli <= 12
  NRow = 4;  NCol = 3;  % 12 images in a page
elseif nsli <= 16
  NRow = 4;  NCol = 4;  % 16 images in a page
else
  NRow = 5;  NCol = 4;  % 20 images in a page
end


STAT = SIG.(STATNAME);

switch lower(STATNAME),
 case {'ttest'}
  MINV = 0;  MAXV = max(STAT.dat(:))*0.7;
 otherwise
  MAXV = max(abs(STAT.dat(:)))*0.7;
  MINV = -MAXV;
end


CMAP = subGetColorMap(STATNAME,1.8,MINV);

[scrW scrH] = subGetScreenSize('char');

%figW = 175; figH = 55;
figW = 185; figH = 57;
figX = 31;  figY = scrH-figH-5;

%[figX figY figW figH]
% CREATE A MAIN FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hMain = figure(...
    'Name',sprintf('%s: %s',mfilename,SIG.imgfile),...
    'NumberTitle','off', 'toolbar','figure',...
    'Tag','main', 'units','char', 'pos',[figX figY figW figH],...
    'HandleVisibility','on', 'Resize','on',...
    'DoubleBuffer','on', 'BackingStore','on', 'Visible','on',...
    'DefaultAxesFontSize',10,...
    'DefaultAxesFontName', 'Comic Sans MS',...
    'DefaultAxesfontweight','bold',...
    'PaperPositionMode','auto', 'PaperType','A4', 'PaperOrientation', 'landscape');

set(gca,'pos',[0 0 1100 680]);
% AXES FOR LIGHT BOX %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 3; XSZ = 55; YSZ = 20;
XDSP=10;
LightiboxAxs = axes(...
    'Parent',hMain,'Tag','LightboxAxs',...
    'Units','char','Position',[XDSP H XSZ*2+10 YSZ*2+6.5],...
    'Box','off','color','black','Visible','off');

nX = size(SIG.anargb,1);
nY = size(SIG.anargb,2);
X = 1:nX;  Y = nY:-1:1;
for N = 1:nsli,
  tmpimg = squeeze(SIG.anargb(:,:,N,:));
  tmps   = STAT.dat(:,:,N);
  tmpp   = STAT.p(:,:,N);
  tmpimg = subFuseImage(tmpimg,tmps,MINV,MAXV,tmpp,ALPHA,CMAP);

  iCol = floor((N-1)/NCol)+1;
  iRow = mod((N-1),NCol)+1;
  offsX = nX*(iRow-1);
  offsY = nY*NRow - iCol*nY;
  tmpimg = permute(tmpimg,[2 1 3]);
  tmpx = X + offsX;  tmpy = Y + offsY;
  image(tmpx,tmpy,tmpimg);  hold on;
  text(min(tmpx)+1,max(tmpy),sprintf('slice=%d',N),...
       'color',[0.9 0.9 0.5],'VerticalAlignment','top',...
       'FontName','Comic Sans MS','FontSize',8,'Fontweight','bold');
end
set(gca,'color','black','xlim',[0.5 nX*NCol+0.5],'ylim',[0.5 nY*NRow+0.5]);
set(gca,'ydir','normal');
set(gca,'units','normalized')


if nargout > 0,
  varargout{1} = SIG;
end


return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION to get screen size
function [scrW scrH] = subGetScreenSize(Units)
oldUnits = get(0,'Units');
set(0,'Units',Units);
sz = get(0,'ScreenSize');
set(0,'Units',oldUnits);

scrW = sz(3);  scrH = sz(4);

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to scale anatomy image
function ANARGB = subScaleAnatomy(ANA,MINV,MAXV,GAMMA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isstruct(ANA),
  tmpana = double(ANA.dat);
else
  tmpana = double(ANA);
end
clear ANA;
tmpana = (tmpana - MINV) / (MAXV - MINV);
tmpana = round(tmpana*255) + 1; % +1 for matlab indexing
tmpana(find(tmpana(:) <   0)) =   1;
tmpana(find(tmpana(:) > 256)) = 256;
anacmap = gray(256).^(1/GAMMA);
for N = size(tmpana,3):-1:1,
  ANARGB(:,:,:,N) = ind2rgb(tmpana(:,:,N),anacmap);
end

ANARGB = permute(ANARGB,[1 2 4 3]);  % [x,y,rgb,z] --> [x,y,z,rgb]

  
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to get a color map
function CMAP = subGetColorMap(STATNAME,gammav,MINV)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch lower(STATNAME),
 case {'ttest'}
  CMAP = hot(256);
 otherwise
  if MINV >= 0,
    CMAP = hot(256);
  else
    posmap = hot(128);
    negmap = zeros(128,3);
    negmap(:,3) = [1:128]'/128;
    %negmap(:,2) = flipud(brighten(negmap(:,3),-0.5));
    negmap(:,3) = brighten(negmap(:,3),0.5);
    negmap = flipud(negmap);
    CMAP = [negmap; posmap];
  end
end

%cmap = cool(256);
%cmap = autumn(256);
if ~isempty(gammav) & gammav > 0,
  CMAP = CMAP.^(1/gammav);
end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to fuse anatomy and functional images
function IMG = subFuseImage(ANARGB,STATV,MINV,MAXV,PVAL,ALPHA,CMAP)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ndims(ANARGB) == 2,
  % image is just a vector, squeezed, so make it 2D image with RGB
  ANARGB = permute(ANARGB,[1 3 2]);
end

IMG = ANARGB;
if isempty(STATV) | isempty(PVAL) | isempty(ALPHA),  return;  end

PVAL(find(isnan(PVAL(:)))) = 1;  % to avoid error;

imsz = [size(ANARGB,1) size(ANARGB,2)];
if any(imsz ~= size(STATV)),
  STATV = imresize(STATV,imsz,'nearest',0);
  PVAL  = imresize(PVAL, imsz,'nearest',0);
  %STATV = imresize(STATV,imsz,'bilinear',0);
  %PVAL  = imresize(PVAL, imsz,'bilinear',0);
end


tmpdat = repmat(PVAL,[1 1 3]);   % for rgb
idx = find(tmpdat(:) < ALPHA);
if ~isempty(idx),
  % scale STATV from MINV to MAXV as 0 to 1
  STATV = (STATV - MINV)/(MAXV - MINV);
  STATV = round(STATV*255) + 1;  % +1 for matlab indexing
  STATV(find(STATV(:) <   0)) =   1;
  STATV(find(STATV(:) > 256)) = 256;
  % map 0-256 as RGB
  STATV = ind2rgb(STATV,CMAP);
  % replace pixels
  %fprintf('\nsize(IMG)=  '); fprintf('%d ',size(IMG));
  %fprintf('\nsize(STATV)='); fprintf('%d ',size(STATV));
  IMG(idx) = STATV(idx);
end


return;

  
