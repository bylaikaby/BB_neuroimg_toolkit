function varargout = mulregress(y,X)
%MULREGRESS - runs multiple linear regression analysis.
%  STATS = MULREGRESS(Y,X) does multiple linear regression analysis.
%    Y as data (t,n),  X as model(s) (t,nmodels) and it is recommended 
%    to include a constant component in models.
%
%  STATS structure will be like, (5 models, 1000 data voxels, 80 time points)
%    STATS = 
%           Q: [80x5 double]
%           R: [5x5 double]
%        perm: [5 2 1 4 3]
%        beta: [5x1000 double]    <-- regression coeffs. for each voxels
%     stdbeta: [5x1000 double]    <-- standardized coeffs.
%        yhat: [80x1000 double]   <-- projection to models
%           r: [80x1000 double]   <-- residuals
%         dfe: 75                 <-- degrees of freedom for error
%         dfr: 4                  <-- degrees of freedom for residuals
%       ymean: [1x1000 double]    <-- mean of y (data)
%         sse: [1x1000 double]    <-- sum of squared errors
%         ssr: [1x1000 double]    <-- regression sum of squares
%         sst: [1x1000 double]    <-- total sum of squares
%        xtxi: [5x5 double]
%        covb: [5x5x1000 double]  <-- covariance matrix of beta for each voxel
%       tstat: [1x1 struct]       <-- t statistics for each regressor, p of two-sided.
%       fstat: [1x1 struct]       <-- F statistics for overall fitting
%
%   STATS.tstat = 
%        dfe: 75                  <-- degrees of freedom
%         se: [5x1000 double]     <-- standard error for each beta/voxel
%          t: [5x1000 double]     <-- t statistics for each beta/voxel
%       pval: [5x1000 double]     <-- p values for each beta/voxel (both-sided)
%       tail: 'both'              <-- t test tail
%   STATS.fstat = 
%        dfe: 75
%        dfr: 4
%          f: [1x1000 double]     <-- F statistics for each voxel
%       pval: [1x1000 double]     <-- p values for each voxel
%
%
%  EXAMPLE :
%    >> mdl = (PREPARE MODELS INCLUDING A CONSTANT COMPONENT)
%    >> stats = mulregress(roiTs{1}.dat, mdl);
%    >> figure;
%    >> % plotting voxels that have a significant "beta" for each regressor (both-sided).
%    >> for N=1:size(model,2),
%    >>   idx = find(stats.tstat.pval(N,:) < 0.01);
%    >>   plot(mean(roiTs{1}.dat(:,idx),2);  hold on;
%    >> end
%    >>
%    >> % making contrast
%    >> CONTVEC = zeros(1,size(mdl,2);        % [0  0  0...0]
%    >> CONTVEC(1) = 1;  CONTVEC(2) = -1;     % [1 -1  0...0]
%    >> cont = mulregress_contrast(stats.beta,stats.covb,CONTVEC,stats.dfe);
%
%  NOTES :
%    It is recommended to include a constant component in models.
%    It may be neccesary that to normalize models somehow, by norm or SDU etc.
%
%  VERSION :
%    0.90 29.06.05 YM   pre-release
%    0.91 30.06.05 YM   bug fix for "degrees of freedom".
%    0.92 01.07.05 YM   adds "stdbeta", but formula NOT CONFIRMED.
%    0.93 06.02.12 YM   use mroi_file().
%
%  See also MULREGRESS_CONTRAST, REGRESS, REGSTATS, X2FX, VREGRESS


if nargin < 2,  help mulregress; return;  end


% CHECK DEBUG MODE OR NOT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DEBUG = 0;
if ischar(y) & strcmpi(y,'debug'),
  DEBUG = 1;
  fprintf('%s %s: DEBUG: loading...',datestr(now,'HH:MM:SS'),mfilename);
  [y X nX nY nS] = subLoadExample();
  fprintf(' processing...');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




% Check that matrix (X) and left hand side (y) have compatible dimensions
[n,ncolX] = size(X);

if isvector(y),  y = y(:);  end
if ndims(y) > 2,
  error('%s:regress:InvalidData', 'Y must be a vector/matrix.',mfilename);
elseif size(y,1) ~= n
  error('%s:regress:InvalidData', ...
        'The number of rows in Y must equal the number of rows in X.',mfilename);
end



% create desired models %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Xi = X;
%X  = x2fx(Xi,model);	% moded: 'linear','interaction','quadratic','purequadratic'


% Check whether "X" contains a constant model that will affects degrees of freedom.
% If exists a "const", then ignore it from degrees of freedom.
NoConst = 1;
for N = 1:size(X,2),
  if all(X(:,N) == X(1,N)),
    NoConst = 0;  break;
  end
end



% orthogonalize models %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[n, ncolX] = size(X);
[Q,R,perm] = qr(X,0);
p = sum(abs(diag(R)) > max(n,ncolX)*eps(R(1)));
if p < ncolX
  warning('%s:regress:RankDefDesignMat', ...
          'X is rank deficient to within machine precision.',mfilename);
  R = R(1:p,1:p);
  Q = Q(:,1:p);
  perm = perm(1:p);
end


% Get back to the original order of X %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Q = Q(:,perm);
%R = R(perm,perm);
%perm = 1:length(perm);  % later proc may use...


% compute statistics %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
beta(perm,:) = R\(Q'*y);					% Regression coefficients
yhat         = X * beta;					% Fitted values of the response data
residuals    = y - yhat;					% Residuals of full model
if NoConst == 1,
  dfe        = n - p - 1;					% Degrees of freedom for error
  dfr        = p;							% Degrees of freedom for residuals
else
  % Ignores contribution of the const. component, see regress().
  dfe        = n - p;
  dfr        = p - 1;
end
ybar         = mean(y,1);					% mean of y
sse          = zeros(1,size(y,2));
ssr          = zeros(1,size(y,2));
sst          = zeros(1,size(y,2));
for N = 1:size(y,2),
  sse(N)     = norm(residuals(:,N))^2;       % sum of squared errors
  ssr(N)     = norm(yhat(:,N) - ybar(N))^2;  % regression sum of squares
  sst(N)     = norm(y(:,N)    - ybar(N))^2;  % total sum of squares
end
mse          = sse ./ dfe;					 % Mean squared error
%h            = sum(abs(Q).^2,2);
ri           = R\eye(p);
xtxi         = ri*ri';
xtxi         = xtxi(perm,perm);
covb         = zeros(size(xtxi,1),size(xtxi,2),size(y,2));
for N = 1:size(y,2),
  covb(:,:,N) = xtxi * mse(N);				% Covariance of regression coefficients
end

% standarized beta, 01.07.05 YM: I'm not sure this is correct or not....
sxx          = zeros(size(X,2),1);
xbar         = mean(X,1);
for N = 1:size(X,2),
  sxx(N)     = norm(X(:,N) - xbar(N))^2;
end
stdbeta      = zeros(size(beta));
for N = 1:size(beta,2),
  stdbeta(:,N) = beta(:,N) .* sqrt(sxx./sst(N));
end


% t statistics %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tstat.dfe    = dfe;
tstat.se     = zeros(size(covb,1),size(y,2));
for N = 1:size(y,2),
  tstat.se(:,N)  = sqrt(diag(covb(:,:,N)));
end
tstat.t      = beta ./ tstat.se;
tstat.pval   = 2*(tcdf(-abs(tstat.t), dfe));	% both-sided
tstat.tail   = 'both';


% F statistics %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fstat.dfe    = dfe;
fstat.dfr    = dfr;
fstat.f      = (ssr/dfr) ./ (sse/dfe);
fstat.pval   = 1 - fcdf(fstat.f, dfr, dfe);



% PREPARE "STATS" structure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
STATS.Q     = Q;			% Q from the QR eecomposition of the design matrix
STATS.R     = R;			% R from the QR decomposition of the design matrix
STATS.perm  = perm;			% permutation vector from QR decompositon
STATS.beta  = beta;			% Regression coefficients
STATS.stdbeta = stdbeta;
STATS.yhat  = yhat;			% Fitted values of the response data
STATS.r     = residuals;	% Residuals of full model
STATS.dfe   = dfe;			% Degrees of freedom for error
STATS.dfr   = dfr;			% Degrees of freedom for residuals
STATS.ymean = ybar;			% mean of y
STATS.sse   = sse;			% Sum of squared errors
STATS.ssr   = ssr;			% Regression sum of squares
STATS.sst   = sst;			% Total sum of squares
%STATS.h     = h;
%STATS.ri    = ri;
%STATS.xtxi  = xtxi;
STATS.xtxi  = xtxi;
STATS.covb  = covb;			% Covariance of regression coefficients

STATS.tstat = tstat;		% t statistics for coefficients
STATS.fstat = fstat;		% F statistic for full model



% RETURN THE RESULT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout,
  varargout{1} = STATS;
end



if DEBUG > 0,
  fprintf(' plotting...');
  figure('name',sprintf('%s: DEBUG',mfilename));
  subplot(2,3,1);
  imagesc(reshape(sse,  [nX,nY])'); colorbar;  title('sse=norm(y-yhat)^2');
  subplot(2,3,2);
  imagesc(reshape(mse,  [nX,nY])'); colorbar;  title('mse=sse/dfe=norm(y-yhat)^2/dfe');
  subplot(2,3,4);
  imagesc(reshape(sst,  [nX,nY])'); colorbar;  title('sst=norm(y-ymean)^2');
  subplot(2,3,5);
  imagesc(reshape(ssr,  [nX,nY])'); colorbar;  title('ssr=norm(yhat-ymean)^2');
  subplot(2,3,6);
  imagesc(reshape(fstat.f, [nX,nY])'); colorbar;  title('F=(ssr/dfr)/(sse/dfe)');
  fprintf(' done.\n');
end


return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to load example data for debug
function [y X nX nY nS] = subLoadExample(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% CONTROL FLAGS / SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
USE_PCA = 1;
XYFILT_HSIZE     = 3;
XYFILT_SIGMA     = 0.8;
SLICE   = 51;

% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto('d03se1');
grp = getgrp(Ses,'mdeftinj');
fprintf(' %s(%s-sl%d)',Ses.name,grp.name,SLICE);

% load data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tcImg = mn_tcslice_load(Ses,grp,SLICE);
nX = size(tcImg.dat,1);  nY = size(tcImg.dat,2);  nS = size(tcImg.dat,3);
nT = size(tcImg.dat,4);
if USE_PCA > 0,
  y = double(tcImg.pca_denoised);
else
  y = double(tcImg.dat);
end

% XY filtering %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
h = fspecial('gaussian',XYFILT_HSIZE,XYFILT_SIGMA);
for N = 1:size(y,3),
  for iT = 1:size(y,4),
    y(:,:,N,iT) = filter2(h,y(:,:,N,iT),'same');
  end
end

% convert dimension %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
y = reshape(y,[nX*nY*nS,nT]);
y = permute(y,[2 1]);

% load models %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MODELS = { 'plgn','mlgn','sc','v1','arteries' };
X = [];
ROI = load(mroi_file(Ses,grp.grproi));
ROI = ROI.(grp.grproi);
for N = 1:length(MODELS),
  tmpts = mn_roits_cat(mn_roits_get(ROI,grp,MODELS{N},[],USE_PCA));
  if ~isempty(tmpts) & ~isempty(tmpts.dat),
    tmpdat = mean(double(tmpts.dat),2);
    X = cat(2,X,tmpdat);
  end
end

% normalize data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(' normalizing...');
TC_GLOBAL = load('tcglobal.mat',grp.name);
TC_GLOBAL = TC_GLOBAL.(grp.name);
for N = 1:length(TC_GLOBAL.dat),
  y(N,:) = y(N,:) / TC_GLOBAL.dat(N);
  X(N,:) = X(N,:) / TC_GLOBAL.dat(N);
end

% adds a constant component
X(:,end+1) = 1;

return;
