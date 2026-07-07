function stat = mgetcor(model,img,dx,aval,mask,R_THRESHOLD)
%MGETCOR - Computer correlation map by applying xcor to model/img
% stat = MGETCOR(model,img,dx,aval,mask,R_THRESHOLD), whereby
%   model       = a vector with the model data
%   img         = a XxYxT array
%   dx          = time resolution
%   aval        = alpha value
%   mask        = ROI-mask
%   R_THREDHOLD = threshold for r-values
%
%   EXAMPLES 1
%   load file with image (e.g. tcImg or epi13)
%   mdl = mkmodel(ImageStructure) (e.g. mkmodel(tcImg) or mkmodel(epi13)
%   stat = mgetcor(mdl{1}.dat,epi13.dat(:,:,Slice,:));
%
%   EXAMPLES 2
%   stat = mgetcor(Model,tcImg.dat(:,:,SliceNo,:),tcImg.dx,bonfaval,mask,R);
%   NKL,  25.12.03

if ~exist('R_THRESHOLD','var'),
  R_THRESHOLD = 0.1;
end;

if ~exist('mask','var'),
  mask = ones(size(img,1),size(img,2));
end;

if ~exist('val','var'),
  aval = 0.01;
end;

if ~exist('dx','var'),
  dx = 1;
end;

if nargin < 2,
  error('usage: stat = mgetcor(model,img,...)');
end;

img = squeeze(img);

try,
  nlags = round(3.0 / dx);			% Plus/minus 4 second shifts for xcorr

  img = img .* double(repmat(mask,[1 1 size(img,3)]));
  tcols = mreshape(img);
  tcols = detrend(tcols);
  
  for C=1:size(tcols,2),
    if any(tcols(:,C)),
      tmp = mcor(model,tcols(:,C),aval,nlags);
      lr(C) = tmp.r;
      lacpt(C) = tmp.acpt;
    else
      lr(C) = 0;
      lacpt(C) = 0;
    end;
  end;
  lr = lr(:);
  lacpt = lacpt(:);
  lr = lr .* lacpt;
  lr(find(lr<R_THRESHOLD)) = 0;
  map = reshape(lr,[size(img,1) size(img,2)]);
  
  [x,y]=find(map);
  % GET RID OF SINGLE VOXELS
  if ~(isempty(x) | isempty(y)),
	[px,py]=mcluster(x,y);
  else
	px = x;
	py = y;
	stat.map = NaN*ones(size(map));
	stat.dims = [];
	return;
  end;
  
  if nargout,
    stat.map = NaN*ones(size(map));
    for N=1:size(px,1),
      stat.map(px(N),py(N))=map(px(N),py(N));
    end;
    stat.dims = [px py];
  end;
catch,
  disp(lasterr);
  keyboard;
end;
return;
