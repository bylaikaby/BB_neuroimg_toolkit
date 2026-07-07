function mdiffmap(Ses,GRPEXP1,MODEL1,TRIAL1,GRPEXP2,MODEL2,TRIAL2,ALPHA1,ALPHA2)
%MDIFFMAP - plots a differential map
%  MDIFFMAP(SES,GRPEXP1,MODEL1,TRIAL1,GRPEXP2,MODEL2,TRIAL2,ALPHA) 
%  plots a differential map.
%  "MODEL" should be a string like 'cor[1]' or 'glm[4]' specifying statistical
%  name and model/contrast number.
%
%  VERSION :
%    0.90 02.05.06 YM  pre-release
%
%  See also

if nargin < 4,  eval(sprintf('help %s;',mfilename)); return;  end

if ~exist('ALPHA1','var'), ALPHA1 = [];  end
if ~exist('ALPHA2','var'), ALPHA2 = [];  end
if ~exist('MODEL2','var'), MODEL2 = MODEL1;  end


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(Ses);
if isempty(MODEL2),  MODEL2 = MODEL1;  end
if isempty(TRIAL1),  TRIAL1 = 1;       end
if isempty(TRIAL2),  TRIAL2 = TRIAL1;  end
if isempty(ALPHA1),  ALPHA1 = 0.1;     end
if isempty(ALPHA2),  ALPHA2 = ALPHA1;  end
ANAP = getanap(Ses,GRPEXP1);

% LOAD AND PROCESS DATA
fprintf('loading...');
[MAP1 TC1] = subGetData(Ses,GRPEXP1,MODEL1,TRIAL1,ALPHA1);
[MAP2 TC2] = subGetData(Ses,GRPEXP2,MODEL2,TRIAL2,ALPHA2);


% LOAD ANATOMY
ANA  = anaload(Ses,GRPEXP1);
ANA.ds(3) = MAP1.ds(3);
tmpana   = double(ANA.dat);
anaminv  = 0;
anamaxv  = 0;
anagamma = 1.8;
if isfield(ANAP,'mview') & isfield(ANAP.mview,'anascale') & ~isempty(ANAP.mview.anascale),
  if length(ANAP.mview.anascale) == 1,
    anamaxv = ANAP.mview.anascale(1);
  else
    anaminv = ANAP.mview.anascale(1);
    anamaxv = ANAP.mview.anascale(2);
    if length(ANAP.mview.anascale) > 2,
      anagamma = ANAP.mview.anascale(3);
    end
  end
end
if anamaxv == 0,  anamaxv = round(mean(tmpana(:))*3.5);  end
ANA.rgb = subScaleAnatomy(ANA.dat,anaminv,anamaxv,anagamma);
ANA.scale = [anaminv anamaxv anagamma];
ANA.episcale = size(ANA.dat)./size(MAP1.dat);
if length(ANA.episcale) < 3,  ANA.episcale(3) = 1;  end
clear tmpana anaminv anamaxv anagamma anacmap;


% PLOT DIFFERENTIAL MAPS
fprintf('plotting...');
GAMMAV  = 1.5;
MINMAXV = [0 1.0];
CMAP = subGetColorMap('',GAMMAV,0);
%subPlotData(MAP1,MAP2,ANA,TC1,TC2,MINMAX,CMAP);

% make differential map
DMAP = MAP1;
tmpmap1 = MAP1.mask.dat;  tmpmap1(tmpmap1(:) > 0) = 1;
tmpmap2 = MAP2.mask.dat;  tmpmap2(tmpmap2(:) > 0) = 1;
DMAP.dat = double(tmpmap1) - double(tmpmap2);
idx = find(MAP2.p(:) < MAP1.p(:));
DMAP.p(idx) = MAP2.p(idx);
DMAP.mask.dat(find(DMAP.mask.dat(:) > 0)) = 1;
idx = find(MAP2.mask.dat(:) > 0);
DMAP.mask.dat(idx) = 1;

MINV = min(MINMAXV);
MAXV = max(MINMAXV);

if isnumeric(GRPEXP1),
  map1str = sprintf('ExpNo(%d)',GRPEXP1);
else
  map1str = sprintf('%s',GRPEXP1);
end
if isnumeric(GRPEXP2),
  map2str = sprintf('ExpNo(%d)',GRPEXP2);
else
  map2str = sprintf('%s',GRPEXP2);
end


figure; subplot(111);
subPlotMap(MAP1,ANA,MINV,MAXV,MAP1.mask.alpha,CMAP);
title(sprintf('%s: %s %s P<%g',Ses.name,map1str,MODEL1,MAP1.mask.alpha));
subColorBar(MINV,MAXV,CMAP);
ylabel(MAP1.datname);
figure; subplot(111);
subPlotMap(MAP2,ANA,MINV,MAXV,MAP2.mask.alpha,CMAP);
title(sprintf('%s: %s %s P<%g',Ses.name,map2str,MODEL2,MAP2.mask.alpha));
subColorBar(MINV,MAXV,CMAP);
ylabel(MAP2.datname);
figure; subplot(111);
tmpcmap = repmat([0.9 0.9 0],256,1);
tmpcmap(end,:) = [1 0 0];      % red
tmpcmap(1,:)   = [0 0.8 0];      % green
tmpcmap = tmpcmap.^(1/GAMMAV);
ALPHA = max([MAP1.mask.alpha MAP2.mask.alpha]);
subPlotMap(DMAP,ANA,-1,1,ALPHA,tmpcmap);
title(sprintf('%s: diff map, %s/%s-%s/%s',Ses.name,map1str,MODEL1,map2str,MODEL2));
h = subColorBar(-1,1,tmpcmap([1,2,end],:));
set(h,'YTickLabel',{map2str,'overlap',map1str},'YTick',[-1 0 1]);

fprintf(' done.\n');

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to get data
function [STATMAP TC] = subGetData(Ses,GRPEXP,MODEL,TRIAL,ALPHA, DO_CULSTER)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('DO_CLUSTER','var'),  DO_CLUSTER = 1;  end

anap = getanap(Ses,GRPEXP);
if isfield(anap,'gettrial') & anap.gettrial.status > 0,
  ROITS = sigload(Ses,GRPEXP,'troiTs');
else
  ROITS = sigload(Ses,GRPEXP,'roiTs');
  % make roiTs{x} as a cell array, compatible to troiTs
  for N = 1:length(ROITS),  ROITS{N} = { ROITS{N} };  end
end

for N = 1:length(ROITS),
  if ~iscell(ROITS{N}),  ROITS{N} = { ROITS{N} };  end
  ROITS{N} = { ROITS{N}{TRIAL} };
end


tmpc = findstr(MODEL,'[');
if ~isempty(tmpc),
  ModelNo = eval(MODEL(tmpc(1):end));
  MODEL = MODEL(1:tmpc(1)-1);
else
  ModelNo = 1;
end

switch lower(MODEL),
 case { 'glm' }
  STATMAP = subGetStatGLM(ROITS,ALPHA,'all',ModelNo);
 case { 'cor','corr' }
 otherwise
  STATMAP = subGetStatCorr(ROITS,ALPHA,'all',ModelNo);
end
% make sure, not a cell array.
STATMAP = STATMAP{1};
STATMAP.ds = ROITS{1}{1}.ds;

STATMAP.mask.cluster = DO_CLUSTER;
if STATMAP.mask.cluster > 0,
  if isfield(anap,'mview') & isfield(anap.mview,'clusterfunc'),
    fname = anap.mview.clusterfunc;
  else
    fname = 'bwlabeln';
  end
  STATMAP = subDoClusterAnalysis(STATMAP,fname,anap);
end


% prepare time series of all voxels
EPIDIM = size(ROITS{1}{1}.ana);
for T = 1:length(ROITS{1}),
  TC{T}.session = ROITS{1}{T}.session;
  TC{T}.grpname = ROITS{1}{T}.grpname;
  TC{T}.ExpNo   = ROITS{1}{T}.ExpNo;
  TC{T}.dat     = [];
  TC{T}.dx      = ROITS{1}{T}.dx;
  TC{T}.ds      = ROITS{1}{T}.ds;
  TC{T}.coords  = [];
  TC{T}.stm     = ROITS{1}{T}.stm;
  TC{T}.labels  = ROITS{1}{T}.stm.labels;
  if isfield(ROITS{1}{T},'mdl'),
    TC{T}.mdl = ROITS{1}{T}.mdl;
  end
  for N = 1:length(ROITS),
    if N == 1,
      tmpdat    = ROITS{N}{T}.dat;
      tmpcoords = ROITS{N}{T}.coords;
    else
      tmpdat    = cat(2,tmpdat,ROITS{N}{T}.dat);
      tmpcoords = cat(1,tmpcoords,ROITS{N}{T}.coords);
    end
  end
  % avoid multiple data of the same voxel.
  tmpcoords = double(tmpcoords);
  idx = sub2ind(EPIDIM,tmpcoords(:,1),tmpcoords(:,2),tmpcoords(:,3));
  [uidx, m] = unique(idx);
  tmpdat = tmpdat(:,m);
  tmpcoords = tmpcoords(m,:);
  TC{T}.dat = tmpdat;
  TC{T}.coords = tmpcoords;
  TC{T}.sub2ind = sub2ind(EPIDIM,tmpcoords(:,1),tmpcoords(:,2),tmpcoords(:,3));
end


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to generate statistical data correlation analysis
function STATMAP = subGetStatCorr(ROITS,alpha,RoiName,ModelNo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
STATMAP = {};
EPIDIM = size(ROITS{1}{1}.ana);
DATNAME = 'r';
anap = getanap(ROITS{1}{1}.session,ROITS{1}{1}.grpname);
IncludeNegative = 0;

for T = 1:length(ROITS{1}),
  tmpmap.session = ROITS{1}{T}.session;
  tmpmap.grpname = ROITS{1}{T}.grpname;
  tmpmap.ExpNo   = ROITS{1}{T}.ExpNo;
  tmpmap.dat     = zeros(EPIDIM);
  tmpmap.p       = ones(EPIDIM);
  tmpmap.coords  = [];
  tmpmap.datname = DATNAME;
  for N = 1:length(ROITS),
    if ~strcmpi(RoiName,'all') & ~any(strcmpi(ROITS{N}{T}.name,RoiName)),  continue;  end
    xyz = double(ROITS{N}{T}.coords);
    tmpR = ROITS{N}{T}.r{ModelNo};
    switch lower(DATNAME),
     case {'r','rvalue','r_value','r-value','r value'}
      tmpV = tmpR;
     otherwise
      tmpV = ROITS{N}{T}.amp;
    end
    tmpP = ROITS{N}{T}.p{ModelNo};
    if IncludeNegative == 0,
      idx = find(tmpR(:) < 0);
      tmpV(idx) = 0;
      tmpP(idx) = 1;
    end
    idx = sub2ind(EPIDIM,xyz(:,1),xyz(:,2),xyz(:,3));
    if length(idx) ~= length(tmpV),
      % some version of grouping cause this problem....
      idx = idx(1:length(tmpV));
    end
    try,
      tmpmap.dat(idx) = tmpV(:);
      tmpmap.p(idx)   = tmpP(:);
    catch,
      keyboard
    end
  end
  
  tmpmap.mask.alpha   = alpha;
  tmpmap.mask.cluster = 0;
  tmpmap.mask.dat     = zeros(EPIDIM,'int8');
  idx = find(tmpmap.p(:) < alpha);
  tmpmap.mask.dat(idx) = 1;
  STATMAP{T} = tmpmap;
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to generate statistical data correlation analysis
function STATMAP = subGetStatGLM(ROITS,alpha,RoiName,ModelNo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
STATMAP = {};
EPIDIM = size(ROITS{1}{1}.ana);
DATNAME = 'beta';
anap = getanap(ROITS{1}{1}.session,ROITS{1}{1}.grpname);

for T = 1:length(ROITS{1}),
  tmpmap.session = ROITS{1}{T}.session;
  tmpmap.grpname = ROITS{1}{T}.grpname;
  tmpmap.ExpNo   = ROITS{1}{T}.ExpNo;
  tmpmap.dat     = zeros(EPIDIM);
  tmpmap.p       = ones(EPIDIM);
  tmpmap.coords  = [];
  tmpmap.datname = DATNAME;
  for N = 1:length(ROITS),
    if ~strcmpi(RoiName,'all') & ~any(strcmpi(ROITS{N}{T}.name,RoiName)),  continue;  end
    xyz = double(ROITS{N}{T}.coords(ROITS{N}{T}.glmcont(ModelNo).selvoxels,:));
    if isempty(xyz), continue;  end
    switch lower(DATNAME),
     case {'statv','stat'}
      tmpV = ROITS{N}{T}.glmcont(ModelNo).statv;
     case {'beta'}
      if isfield(ROITS{N}{T}.glmcont(ModelNo),'BetaMag') & ~isempty(ROITS{N}{T}.glmcont(ModelNo).BetaMag),
        tmpV = ROITS{N}{T}.glmcont(ModelNo).BetaMag;
      else
        fprintf(' WARNING %s: no .glmcont{}.BetaMag...\n',mfilename);
        % no way...
        tmpV = zeros(1,length(ROITS{N}{T}.glmcont(ModelNo).statv));
      end
     otherwise
      tmpV = ROITS{N}{T}.amp(ROITS{N}{T}.glmcont(ModelNo).selvoxels);
    end
    tmpP = ROITS{N}{T}.glmcont(ModelNo).pvalues;
    idx = sub2ind(EPIDIM,xyz(:,1),xyz(:,2),xyz(:,3));
    if length(idx) ~= length(tmpV),
      % some version of grouping cause this problem....
      idx = idx(1:length(tmpV));
    end
    try,
      tmpmap.dat(idx) = tmpV(:);
      tmpmap.p(idx)   = tmpP(:);
    catch,
      keyboard
    end
    % if alpha = 1.0, need to show everything of roi.
    if alpha >= 1.0,
      xyz = double(ROITS{N}{T}.coords);
      idx = sub2ind(EPIDIM,xyz(:,1),xyz(:,2),xyz(:,3));
      tmpmap.p(idx) = 0.99;
    end
  end
  
  
  tmpmap.mask.alpha   = alpha;
  tmpmap.mask.cluster = 0;
  tmpmap.mask.dat     = zeros(EPIDIM,'int8');
  idx = find(tmpmap.p(:) < alpha);
  tmpmap.mask.dat(idx) = 1;
  STATMAP{T} = tmpmap;
end

  
  
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to do cluster analysis
function STATMAP = subDoClusterAnalysis(STATMAP,fname,anap)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isfield(anap,'mview'),
  anap = anap.mview;
else
  anap = [];
end

if strcmpi(fname,'mcluster3'),
  B = 5;  cutoff = round((2*(B-1)+1)^3*0.3);
  % overwrite settings with anap.mcluster3
  if isfield(anap,'mcluster3'),
    if isfield(anap.mcluster3,'B') & ~isempty(anap.mcluster3.B),
      B = anap.mcluster3.B;
    end
    if isfield(anap.mcluster3,'cutoff') & ~isempty(anap.mcluster3.cutoff),
      cutoff = anap.mcluster3.cutoff;
    end
  end
  STATMAP.mask.func = fname;
  STATMAP.mask.mcluster3_B = B;
  STATMAP.mask.mcluster3_cutoff = cutoff;
  idx = find(STATMAP.mask.dat > 0);
  [ix,iy,iz] = ind2sub(size(STATMAP.p),idx);
  coords = zeros(length(ix),3);
  coords(:,1) = ix(:);  coords(:,2) = iy(:); coords(:,3) = iz(:);
  fprintf('%s.mcluster3(n=%d,B=%d,cutoff=%d): %s-',...
          mfilename,size(coords,1),B,cutoff,datestr(now,'HH:MM:SS'));
  coords = mcluster3(coords, STATMAP.mask.mcluster3_B, STATMAP.mask.mcluster3_cutoff);
  fprintf('%s\n',datestr(now,'HH:MM:SS'));
  idx = sub2ind(size(STATMAP.p),coords(:,1),coords(:,2),coords(:,3));
  STATMAP.mask.dat(:)   = 0;
  STATMAP.mask.dat(idx) = 1;
elseif strcmpi(fname,'mcluster'),
  B = 5;  cutoff = 10;
  % overwrite settings with anap.mcluster3
  if isfield(anap,'mcluster'),
    if isfield(anap.mcluster,'B') & ~isempty(anap.mcluster.B),
      B = anap.mcluster.B;
    end
    if isfield(anap.mcluster,'cutoff') & ~isempty(anap.mcluster.cutoff),
      cutoff = anap.mcluster.cutoff;
    end
  end
  STATMAP.mask.func = fname;
  STATMAP.mask.mcluster_B = B;
  STATMAP.mask.mcluster_cutoff = cutoff;
  idx = find(STATMAP.mask.dat > 0);
  [ix,iy,iz] = ind2sub(size(STATMAP.p),idx);
  fprintf('%s.mcluster(n=%d,B=%d,cutoff=%d): %s-',...
          mfilename,length(ix),B,cutoff,datestr(now,'HH:MM:SS'));
  slices = sort(unique(iz));
  coords = [];
  for N = 1:length(slices),
    idx = find(iz == slices(N));
    [tmpx tmpy] = mcluster(ix(idx),iy(idx),B,cutoff);
    if isempty(tmpx),  continue;  end
    coords = cat(1,coords, [tmpx(:), tmpy(:), ones(length(tmpx),1)*slices(N)]);
  end
  fprintf('%s\n',datestr(now,'HH:MM:SS'));
  idx = sub2ind(size(STATMAP.p),coords(:,1),coords(:,2),coords(:,3));
  STATMAP.mask.dat(:)   = 0;
  STATMAP.mask.dat(idx) = 1;
elseif strcmpi(fname,'spm_bwlabel'),
  CONN = 26;	% must be 6(surface), 18(edges) or 26(corners)
  MINVOXELS = CONN*0.8;
  % overwrite settings with anap.mcluster3
  if isfield(anap,'spm_bwlabel'),
    if isfield(anap.spm_bwlabel,'conn') & ~isempty(anap.spm_bwlabel.conn),
      CONN = anap.spm_bwlabel.conn;
    end
    if isfield(anap.spm_bwlabel,'minvoxels') & ~isempty(anap.spm_bwlabel.minvoxels),
      MINVOXELS = anap.spm_bwlabel.minvoxels;
    end
  end
  STATMAP.mask.func = fname;
  STATMAP.mask.spm_bwlabel_conn = CONN;
  STATMAP.mask.minvoxels = MINVOXELS;
  fprintf('%s.spm_bwlabel(CONN=%d): %s-',...
          mfilename,CONN,datestr(now,'HH:MM:SS'));
  tmpdat = double(STATMAP.mask.dat);
  [tmpdat tmpn] = spm_bwlabel(tmpdat, CONN);
  hn = histc(tmpdat(:),[1:tmpn]);
  ci = find(hn >= MINVOXELS);
  STATMAP.mask.dat(:) = 0;
  for iCluster = 1:length(ci),
    tmpi = find(tmpdat(:) == ci(iCluster));
    STATMAP.mask.dat(tmpi) = iCluster;
  end
  STATMAP.mask.nclusters = length(hn);
  fprintf('%s\n',datestr(now,'HH:MM:SS'));
elseif strcmpi(fname,'bwlabeln'),
  CONN = 18;	% must be 6(surface), 18(edges) or 26(corners)
  MINVOXELS = CONN*0.8;
  % overwrite settings with anap.mcluster3
  if isfield(anap,'bwlabeln'),
    if isfield(anap.bwlabeln,'conn') & ~isempty(anap.bwlabeln.conn),
      CONN = anap.bwlabeln.conn;
    end
    if isfield(anap.bwlabeln,'minvoxels') & ~isempty(anap.bwlabeln.minvoxels),
      MINVOXELS = anap.bwlabeln.minvoxels;
    end
  end
  STATMAP.mask.func = fname;
  STATMAP.mask.bwlabeln_conn = CONN;
  STATMAP.mask.minvoxels = MINVOXELS;
  fprintf('%s.bwlabeln(CONN=%d): %s-',...
          mfilename,CONN,datestr(now,'HH:MM:SS'));
  tmpdat = double(STATMAP.mask.dat);
  [tmpdat tmpn] = bwlabeln(tmpdat, CONN);
  hn = histc(tmpdat(:),[1:tmpn]);
  ci = find(hn >= MINVOXELS);
  STATMAP.mask.dat(:) = 0;
  for iCluster = 1:length(ci),
    tmpi = find(tmpdat(:) == ci(iCluster));
    STATMAP.mask.dat(tmpi) = iCluster;
  end
  STATMAP.mask.nclusters = length(hn);
  fprintf('%s\n',datestr(now,'HH:MM:SS'));
else
  SATAMAP.mask.func = 'unknown';
end


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to get a color map
function CMAP = subGetColorMap(DATNAME,gammav,INCLUDE_NEGATIVE)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch lower(DATNAME),
 case {'stat','statv'}
  CMAP = hot(256);
 otherwise
  if INCLUDE_NEGATIVE == 0,
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
if ~isempty(gammav),
  CMAP = CMAP.^(1/gammav);
end


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to scale anatomy image
function ANARGB = subScaleAnatomy(ANA,MINV,MAXV,GAMMAV)
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
anacmap = gray(256).^(1/GAMMAV);
for N = size(tmpana,3):-1:1,
  ANARGB(:,:,:,N) = ind2rgb(tmpana(:,:,N),anacmap);
end

ANARGB = permute(ANARGB,[1 2 4 3]);  % [x,y,rgb,z] --> [x,y,z,rgb]

  
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




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot maps
function subPlotMap(STATMAP,ANA,MINV,MAXV,ALPHA,CMAP)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nmaximages = size(STATMAP.dat,3);
minsize    = min(size(STATMAP.dat));
if minsize <= 2,
  NRow = 2;  NCol = 1;  %  2 images in a page
elseif minsize <= 4,
  NRow = 2;  NCol = 2;  %  4 images in a page
elseif minsize <= 9
  NRow = 3;  NCol = 3;  %  9 images in a page
elseif minsize <= 12
  NRow = 4;  NCol = 3;  % 12 images in a page
elseif minsize <= 16
  NRow = 4;  NCol = 4;  % 16 images in a page
else
  NRow = 5;  NCol = 4;  % 20 images in a page
end

Xdim = 1;  Ydim = 2;

nX = size(STATMAP.dat,Xdim);  nY = size(STATMAP.dat,Ydim);
X = [0:size(ANA.dat,Xdim)-1]/ANA.episcale(Xdim);
Y = [0:size(ANA.dat,Ydim)-1]/ANA.episcale(Ydim);
Y = fliplr(Y);

for N = 1:size(STATMAP.dat,3),
  iSlice = N;
  % anatomy
  tmpimg = squeeze(ANA.rgb(:,:,iSlice,:));
  tmpana = squeeze(ANA.dat(:,:,iSlice));
  % functional
  tmps = squeeze(STATMAP.dat(:,:,iSlice));
  tmpp = squeeze(STATMAP.p(:,:,iSlice)); 
  tmpm = squeeze(STATMAP.mask.dat(:,:,iSlice));
  idx = find(tmpm(:) == 0);
  tmps(idx) = 0;
  tmpp(idx) = 1;
  tmpimg = subFuseImage(tmpimg,tmps,MINV,MAXV,tmpp,ALPHA,CMAP);

  iCol = floor((N-1)/NCol)+1;
  iRow = mod((N-1),NCol)+1;
  offsX = nX*(iRow-1);
  offsY = nY*NRow - iCol*nY;
  tmpimg = permute(tmpimg,[2 1 3]);
  tmpx = X + offsX;  tmpy = Y + offsY;
  image(tmpx,tmpy,tmpimg);  hold on;
  text(min(tmpx)+1,max(tmpy),sprintf('Trans=%d',iSlice),...
       'color',[0.9 0.9 0.5],'VerticalAlignment','top',...
       'FontName','Comic Sans MS','FontSize',8,'Fontweight','bold');
end
set(gca,'FontName','Comic Sans MS','FontWeight','bold');
set(gca,'XTickLabel',{},'YTickLabel',{},'XTick',[],'YTick',[]);
set(gca,'xlim',[0 nX*NCol],'ylim',[0 nY*NRow]);
set(gca,'YDir','normal');


DX = STATMAP.ds(1);  DY = STATMAP.ds(2);
h = findobj(gca,'type','image');
set(h,'ButtonDownFcn','');  % clear callback function
for N = 1:length(h),
  set(h(N),'xdata',get(h(N),'xdata')*DX,'ydata',get(h(N),'ydata')*DY);
end
h = findobj(gca,'type','text');
for N = 1:length(h),
  tmppos = get(h(N),'pos');
  tmppos(1) = tmppos(1)*DX;  tmppos(2) = tmppos(2)*DY;
  set(h(N),'pos',tmppos);
end
set(gca,'xlim',get(gca,'xlim')*DX,'ylim',get(gca,'ylim')*DY);

daspect(gca,[2 2 1]);
set(gca,'color','k');


return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
% SUBFUNCTION to plot a color bar
function hAxs = subColorBar(MINV,MAXV,CMAP)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

set(gca,'pos',[0.1300    0.1100    0.6798    0.8150],'units','normalized');

hAxs = axes('pos',[0.850    0.1100  0.05    0.8150]);
ncol = size(CMAP,1);
ydat = [0:ncol-1]/(ncol-1) * (MAXV - MINV) + MINV;
imagesc(1,ydat,[0:ncol-1]'); colormap(CMAP);
set(hAxs,'FontName','Comic Sans MS','FontWeight','bold');
set(hAxs,'YAxisLocation','right','YDir','normal');
set(hAxs,'XTickLabel',[],'XTick',[]);

return;
