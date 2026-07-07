function RES = mrineucor_cluster(varargin)
%MRINEUCOR_CLUSTER - Run mds/kmeans.
%    MRINEUCOR_CLUSTER(SES,GRPEXP,...)
%    RES = MRINEUCOR_CLUSTER(RES,...) runs mds/kmeans.
%
%  VERSION :
%    0.90 16.02.12 YM  pre-release
%    0.91 17.02.12 YM  use jd_kmeans().
%
%  See also sesmrineucor run_mds kmeans jd_kmeans


if issig(varargin{1}),
  % called like mrineucor_cluster(RES,...)
  RES = varargin{1};
  iOPT = 2;
  SaveFilename = '';
else
  % called like mrineucor_cluster(SES,GRPEXP,...)
  Ses = goto(varargin{1});
  GrpExp = varargin{2};
  MriSig       = 'roiTs';
  NeuSig       = 'blp';
  RoiName      = 'all';
  NeuChans     = [];
  NeuBands     = [];
  for N = 3:2:length(varargin)
    switch lower(varargin{N}),
     case {'roi','roiname','roinames'}
      RoiName = varargin{N+1};
     case {'neusig','neu'},
      NeuSig = varargin{N+1};
     case {'mrisig','mri'},
      MriSig = varargin{N+1};
     case {'ele','elename','elenames','chan','chans'}
      NeuChans = varargin{N+1};
     case {'band','bands','bandname','bandnames'}
      NeuBands = varargin{N+1};
    end
  end
  SaveFilename = tcorr_filename(Ses,GrpExp,MriSig,RoiName,NeuSig,NeuChans);
  RES = load(filename,'RES');
  RES = RES.RES;
  iOPT = 3;
end


RUN_MDS  =  1;
MDS_DIST   = 'correlation';  % see pdist()
MDS_ITER = 20;

N_CLUST  =  3;
CLS_DIST = 'sqEuclidean';  % see kmeans()
DO_PLOT  =  1;
for N = iOPT:2:length(varargin)
  switch lower(varargin{N})
   case {'mds'}
    RUN_MDS = varargin{N+1};
   case {'mdsdist' 'dist' 'distance'}
    MDS_DIST = varargin{N+1};
   case {'maxiteration' 'iteration' 'iter' 'maxiter' 'replicates'}
    MDS_ITER = varargin{N+1};
   
   case {'nclust' 'clust'}
    N_CLUST = varargin{N+1};
   case {'clustdist'}
    CLS_DIST = varargin{N+1};
   
   case {'plot'}
    DO_PLOT = varargin{N+1};
  end
end

if ~isfield(RES,'mds'),  RUN_MDS = 1;  end


DATA = nanmean(RES.dat,5);

NChan = size(DATA,2);
NBand = size(DATA,3);
NVox  = size(DATA,4);


% RUN MDS ================================================================================
if any(RUN_MDS),
  if isfield(RES,'mds'),  RES = rmfield(RES,'mds');  end
  MDSCOORDS = zeros(NVox,2,NChan,NBand);
  if any(DO_PLOT),
    hfig = figure; haxs = axes();
  else
    haxs = [];
  end
  for C = 1:NChan
    for B = 1:NBand
      if any(DO_PLOT) && ishandle(hfig),
        set(hfig,'Name',sprintf('%s(%s) Chan=%d/%d Band=%d/%d',...
                                RES.session,RES.grpname,C,NChan,B,NBand));
      end
      tmpr = squeeze(DATA(:,C,B,:));
      if 0,
        tmpdist = pdist(tmpr',MDS_DIST);
        [tmpcoords,stress] = mdscale(tmpdist,2,'criterion','stress','Replicates',MDS_ITER);
        mres.mdscoords = tmpcoords;
      else
        % takes more time (x1.8) but looks nicer...
        mres = run_mds(tmpr','iteration',MDS_ITER,'dist',MDS_DIST,...
                       'plot',DO_PLOT,'axes',haxs);
      end
      MDSCOORDS(:,:,C,B) = mres.mdscoords;
    end
  end
  
  % (vox,mdsXY,chan,band) --> (mdsXY,chan,band,vox)
  MDSCOORDS = permute(MDSCOORDS,[2 3 4 1]);

  RES.mds.maxiter = MDS_ITER;
  RES.mds.dist    = MDS_DIST;
  RES.mds.coords  = MDSCOORDS;
  RES.mds.dimname = { 'mdsXY' 'chan' 'band' 'voxel' };
  clear MDSCOORDS;
end




% RUN KMEANS =============================================================================
CLUST_SORT = 'density+polarity';
if isfield(RES,'clust'),  RES = rmfield(RES,'clust');  end

METHOD = 3;

for C = 1:NChan
  for B = 1:NBand
    %tmpr = squeeze(DATA(:,C,B,:));  % as (lag,vox)
    tmpr = squeeze(RES.mds.coords(:,C,B,:));  % as (xy,vox)
    maxK = round(1+log2(size(tmpr,2)));
    if METHOD == 1,
      [NumK p IDX CC sumd CD] = jd_kmeans(tmpr',maxK,'distance',CLS_DIST);
      minvox = round(size(tmpr,2)*0.01);
      [tmpc tmpt] = dbscan(tmpr',max(1,minvox));
      fprintf('Ch%d-Band%d: dbscan=%d NumK=%d\n',C,B,...
              length(find(unique(tmpc)>0)),NumK);
    elseif METHOD == 2,
      minvox = round(size(tmpr,2)*0.01);
      [IDX tmpt] = dbscan(tmpr',max(1,minvox));
      CLS_DIST = 'euclidean';
      NumK = length(find(unique(IDX) > 0));
      fprintf('Ch%d-Band%d: dbscan=%d\n',C,B,NumK);
      p = [];
      CC = NaN(NumK,size(tmpr,1));
      sumd = [];
      CD = NaN(length(IDX),NumK);
      for N = 1:NumK,
        tmpidx = (IDX == N);
        CC(N,:) = nanmean(tmpr(:,tmpidx),2)';
        tmpd = tmpr - (CC(N,:)')*ones(1,size(tmpr,2));
        tmpd = sqrt(sum(tmpd.^2,1));
        CD(:,N) = tmpd(:);
      end
    elseif METHOD == 3,
      minvox = round(size(tmpr,2)*0.01);
      [IDX tmpt] = dbscan(tmpr',max(1,minvox));
      NumK1 = length(find(unique(IDX) > 0));
      [NumK2 p IDX CC sumd CD] = jd_kmeans(tmpr',maxK,'distance',CLS_DIST);
      NumK = max(NumK1,NumK2);
      fprintf('Ch%d-Band%d: dbscan=%d jd_kmeans=%d : NumK=%d\n',C,B,...
              NumK1,NumK2,NumK);
      [IDX CC sumd CD] = kmeans(tmpr',NumK,'distance',CLS_DIST);
    else
      N_CLUST = 3;
      [IDX CC sumd CD] = kmeans(tmpr',N_CLUST,'distance',CLS_DIST);
      NumK = N_CLUST;
      p = [];
    end
    % IDX as (vox)
    % CC  as (clust,var)
    % CD  as (vox,clust)
    switch lower(CLUST_SORT),
     case {'distance'}
      [IDX CC CD] = sub_sort_distance(NumK,IDX,CC,CD);
     case {'density'}
      [IDX CC CD] = sub_sort_density(NumK,IDX,CC,CD);
     case {'population'}
      % sort by num. populations
      [IDX CC CD] = sub_sort_population(NumK,IDX,CC,CD);
     case {'density+polarity'}
      % first sort by num. populations then check the polarity around +0-+6.
      [IDX CC CD] = sub_sort_density(NumK,IDX,CC,CD);
      if NumK > 1,
        tmpt = RES.lags_pts * RES.dx;
        tmpti = find(tmpt >= 0 & tmpt <= 6);
        tmpdata = squeeze(DATA(:,C,B,:));
        tmpv1 = nanmean(nanmean(tmpdata(tmpti,IDX==1),2),1);
        tmpv2 = nanmean(nanmean(tmpdata(tmpti,IDX==2),2),1);
        if tmpv1 < tmpv2,
          % swap 1 and 2
          tmpi1 = (IDX == 1);
          tmpi2 = (IDX == 2);
          if ~isempty(CC), CC([1 2],:) = CC([2 1],:);  end
          if ~isempty(CD), CD(:,[1 2]) = CD(:,[2 1]);  end
          IDX(tmpi1) = 2;
          IDX(tmpi2) = 1;
        end
      end
      
      
    end

    RES.clust(C,B).distance = CLS_DIST;
    RES.clust(C,B).nclust = NumK;
    RES.clust(C,B).costf  = p;
    RES.clust(C,B).index  = IDX(:)';
    RES.clust(C,B).center = CC;
    RES.clust(C,B).clustd = CD;
    RES.clust_dimname = {'chan' 'band'};
  end
end

if nargout == 0 && any(SaveFilename),
  save(SaveFilename,'RES','-append');
end

return



% ==========================================================
function [IDX CC CD] = sub_sort_distance(NumK,IDX,CC,CD)
% ==========================================================
tmpN = zeros(1,NumK);
for N = 1:NumK,
  tmpN(N) = nanmean(abs(CD((IDX==N),N)),1);
end
[newV newI] = sort(tmpN,'ascend');
if ~isequal(newI,1:NumK),
  if ~isempty(CC), CC = CC(newI,:);  end
  if ~isempty(CD), CD = CD(:,newI);  end
  newV = 1:NumK;
  IDX(IDX > 0) = newI(IDX(IDX > 0));
end
return


      
% ==========================================================
function [IDX CC CD] = sub_sort_density(NumK,IDX,CC,CD)
% ==========================================================
tmpN = zeros(1,NumK);
for N = 1:NumK,
  tmpidx  = abs(CD((IDX==N),N)) < 0.1;
  tmpN(N) = length(find(tmpidx > 0));
end
[newV newI] = sort(tmpN,'descend');
if ~isequal(newI,1:NumK),
  if ~isempty(CC), CC = CC(newI,:);  end
  if ~isempty(CD), CD = CD(:,newI);  end
  newV = 1:NumK;
  IDX(IDX > 0) = newI(IDX(IDX > 0));
end
return


% ==========================================================
function [IDX CC CD] = sub_sort_population(NumK,IDX,CC,CD)
% ==========================================================
% sort by num. populations
tmpN = zeros(1,NumK);
for N = 1:NumK,
  tmpN(N) = length(find(IDX == N));
end
[newV newI] = sort(tmpN,'descend');
if ~isequal(newI,1:NumK),
  if ~isempty(CC), CC = CC(newI,:);  end
  if ~isempty(CD), CD = CD(:,newI);  end
  newV = 1:NumK;
  IDX(IDX > 0) = newI(IDX(IDX > 0));
end
return
