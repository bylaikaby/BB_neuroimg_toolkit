function test_pca()



dat = rand(1271,500);
nopcs = 6;

tic
[PC, eVar, Proj, SigMean] = doPCA(dat, nopcs);
toc

return




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [PC, eVar, Proj, SigMean] = doPCA(dat, nopcs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('msub.');
% ============================================
dat		= dat';							% transpose dat (T,N)->(N,T)
SigMean	= mean(dat,1);					% mean value along N
for N = 1:size(dat,2),
  dat(:,N) = dat(:,N) - SigMean(N);		% center the data
end


fprintf('cov.');
% 03.08.05 YM:
% Matlab's cov() will cause memory problem if 'dat' is a large matrix.
%tmpcov	= cov(dat);						% compute covariance matrix

% tmpcov = my_cov(dat,0);
keyboard
tic
flag   = 0;
Ndata  = size(dat,1);
Ndims  = size(dat,2);
tmpcov = zeros(Ndims,Ndims);
if flag == 0,  Ndata = Ndata - 1;  end
for iX = 1:Ndims,
  %x = dat(:,iX) - SigMean(iX);
  x = dat(:,iX);
  tmpcov(iX,iX) = sum(x .* x) / Ndata;
  for iY = iX+1:Ndims,
    %y = dat(:,iY) - SigMean(iY);
    y = dat(:,iY);
    tmpcov(iX,iY) = sum(x .* y) / Ndata;
    tmpcov(iY,iX) = tmpcov(iX,iY);
  end
end
toc

fprintf('svds.');
% [U,eVar,PC] = SVDS(dat,nopcs) computes the the nopcs first singular
% vectors of dat. If A is NT-by-N and K singular values are
% computed, then U is NT-by-K with orthonormal columns, eVar is K-by-K
% diagonal, and V is N-by-K with orthonormal columns.
[U, eVar, PC] = svds(tmpcov, nopcs);	% find singular values
clear tmpcov;

fprintf('prj.');
eVar  = diag(eVar);						% turn diagonal mat into vector.
SigMean = SigMean(:);					% return mean
Proj = dat * PC;						% Proj centered dat onto PCs.


fprintf('done.\n');

return





function tmpcov = my_cov_old(dat,flag)
flag   = 0;
Ndata  = size(dat,1);
Ndims  = size(dat,2);
tmpcov = zeros(Ndims,Ndims);
if flag == 0,  Ndata = Ndata - 1;  end
for iX = 1:Ndims,
  %x = dat(:,iX) - SigMean(iX);
  x = dat(:,iX);
  tmpcov(iX,iX) = sum(x .* x) / Ndata;
  for iY = iX+1:Ndims,
    %y = dat(:,iY) - SigMean(iY);
    y = dat(:,iY);
    tmpcov(iX,iY) = sum(x .* y) / Ndata;
    tmpcov(iY,iX) = tmpcov(iX,iY);
  end
end


return



function xy = my_cov(x,varargin)
%MYCOV Covariance matrix.
%   MYCOV() IS LESS MEMORY EATING VERSION OF MATLAB'S COV().
%
% VERSION : 0.90 07.09.04 YM  modified from matlab7's cov().
%
% See also COV

if nargin==0 
  error('mycov:NotEnoughInputs','Not enough input arguments.'); 
end
if nargin>3, error('mycov:TooManyInputs', 'Too many input arguments.'); end
if ndims(x)>2, error('mycov:InputDim', 'Inputs must be 2-D.'); end

nin = nargin;

% Check for cov(x,flag) or cov(x,y,flag)
if (nin==3) || ((nin==2) && (length(varargin{end})==1));
  flag = varargin{end};
  nin = nin - 1;
else
  flag = 0;
end

if nin == 2,
  x = x(:);
  y = varargin{1}(:);
  if length(x) ~= length(y), 
    error('mycov:XYlengthMismatch', 'The lengths of x and y must match.');
  end
  x = [x y];
end

if length(x)==numel(x)
  x = x(:);
end

[m,n] = size(x);

if m==1,  % Handle special case
  xy = zeros(class(x));

else
  % mofified HERE: BEGIN==========================================
  % ORIGINAL CODE
  %xc = x - repmat(sum(x)/m,m,1);  % Remove mean
  % 07.09.04 YM: to avoid memory problem, use a for-loop
  xc = x;  clear x;
  sumx = sum(xc)/m;
  for N = m:-1:1,
    xc(N,:) = xc(N,:) - sumx;
  end
  clear sumx;
  % mofified HERE: END============================================
  
  if flag
    xy = xc' * xc / m;
  else
    xy = xc' * xc / (m-1);
  end
  xy = 0.5*(xy+xy');
end
