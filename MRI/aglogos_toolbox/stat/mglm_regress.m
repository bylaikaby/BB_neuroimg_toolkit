function GLMREGR = mglm_regress(Y,DesignMatrix,varargin)
%MGLM_REGRESS - Run multiple linear regression.
%  GLMREGR = MGLM_REGRESS(Y,DesingMatrix,...) runs multiple linear regression.
%
%  INPUT :
%    Y            : data as (var,samples), for example (time,voxels)
%    DesignMatrix : a design matrix as (var,regressors)
%
%  OUTPUT :
%    GLMREGR.X         : design matrix
%    GLMREGR.beta      : betas
%    GLMREGR.df        : degree of freedom
%    GLMREGR.ss        : sum of squared error
%    GLMREGR.serrors   : standard errors
%    GLMREGR.Fstat.F   : F statistics without the constant.
%    GLMREGR.Fstat.p   : p value
%
%  EXAMPLE :
%    >> Y = rand(100,20);
%    >> DesignMatrix = Y(:,1:3);
%    >> glmregr = mglm_regress(Y,DesignMatrix);
%    >> tcont1 = mglm_tcont(glmregr,[1 0 0],'name','1+');
%    >> tcont2 = mglm_tcont(glmregr,[0 1 0],'name','2+');
%    >> tcont3 = mglm_tcont(glmregr,[0 0 1],'name','3+');
%
%  NOTE :
%    - The funciton adds the constant component to the last, if needed.
%
%  VERSION :
%    0.90 24.06.14 YM  pre-release
%
%  See also regress matregressmod mglm_tcont

if nargin < 2,  eval(['help ' mfilename]); return;  end

if iscell(DesignMatrix)
  for N = 1:numel(DesignMatrix),
    GLMREGR(K) = mglm_regress(Y,DesignMatrix{N},varargin{:});
  end
  GLMREGR = reshape(GLMREGR,size(DesignMatrix));
  return
end


% 
for N = 1:2:length(varargin)
  switch lower(varargin{N})
  end
end


X = DesignMatrix;
if all(X(:,end) == X(1,end)),
  % ok, the last column is the constant, do nothing.
else
  % adds the constant
  X(:,end+1) = 1;
end


% reshape data
ysize = size(Y);
Y = reshape(Y,[ysize(1) prod(ysize(2:end))]);

% fill with zero if NaN.
Y(isnan(Y(:))) = 0;
X(isnan(X(:))) = 0;

STATS = sub_regressmod(Y,X);
Fstat = sub_Fcontrasts(Y,X,STATS);


% recover the original dimension
Y = reshape(Y,ysize);
STATS.beta    = reshape(STATS.beta,    [size(STATS.beta,1),    ysize(2:end)]);
STATS.df      = reshape(STATS.df,      [size(STATS.df,1),      ysize(2:end)]);
STATS.mu      = reshape(STATS.mu,      [size(STATS.mu,1),      ysize(2:end)]);
STATS.res     = reshape(STATS.res,     [size(STATS.res,1),     ysize(2:end)]);
STATS.ss      = reshape(STATS.ss,      [size(STATS.ss,1),      ysize(2:end)]);
STATS.serrors = reshape(STATS.serrors, [size(STATS.serrors,1), ysize(2:end)]);
Fstat.F       = reshape(Fstat.F,       [size(Fstat.F,1),       ysize(2:end)]);
Fstat.p       = reshape(Fstat.p,       [size(Fstat.p,1),       ysize(2:end)]);


GLMREGR.X       = X;
GLMREGR.beta    = STATS.beta;
GLMREGR.df      = STATS.df;
GLMREGR.ss      = STATS.ss;
GLMREGR.serrors = STATS.serrors;
GLMREGR.Fstat   = Fstat;

return



% --------------------------------------------------------
% This is vectorized version of MATALB's regress().
function stats = sub_regressmod(Y,X)
% --------------------------------------------------------
% Check that matrix (X) and left hand side (y) have compatible dimensions
[n,ncolX] = size(X);
if size(Y,1) ~= n
  error('stats:regress:InvalidData', ...
        'The number of rows in Y must equal the number of rows in X.');
end

% DON'T CHECK "NaN", NaN in Y,X is already filled with zero.
% % Remove missing values, if any
% wasnan = (isnan(y) | any(isnan(X),2));
% havenans = any(wasnan);
% if havenans
%   y(wasnan) = [];
%   X(wasnan,:) = [];
%   n = length(y);
% end


% Use the rank-revealing QR to remove dependent columns of X.
[Q,R,perm] = qr(X,0);
p = sum(abs(diag(R)) > max(n,ncolX)*eps(R(1)));
if p < ncolX
  warning('stats:regress:RankDefDesignMat', ...
          'X is rank deficient to within machine precision.');
  R = R(1:p,1:p);
  Q = Q(:,1:p);
  perm = perm(1:p);
end

% Compute the LS coefficients, filling in zeros in elements corresponding
% to rows of X that were thrown out.
b = zeros(ncolX,size(Y,2));
b(perm,:) = R \ (Q'*Y);

% Find a confidence interval for each component of x
% Draper and Smith, equation 2.6.15, page 94
RI = R\eye(p);
nu = max(0,n-p);                % Residual degrees of freedom
yhat = X*b;                     % Predicted responses at each data point.
r = Y-yhat;                     % Residuals.

% normr = norm(r);
% if nu ~= 0
%   rmse = normr/sqrt(nu);    % Root mean square error.
% else
%   rmse = NaN;
% end
% s2 = rmse^2;                    % Estimator of error variance.
% se = zeros(ncolX,1);
% se(perm,:) = rmse*sqrt(sum(abs(RI).^2,2));

normr = zeros(size(r,2),1);
for N = 1:size(r,2),  normr(N) = norm(r(:,N));  end
if nu ~= 0
  rmse = normr/sqrt(nu);    % Root mean square error.
else
  rmse = NaN(size(normr));
end
s2 = rmse.^2;                    % Estimator of error variance.
se = zeros(ncolX,length(rmse));
for N = 1:size(se,2)
  se(perm,N) = rmse(N).*sqrt(sum(abs(RI).^2,2));
end

stats.beta    = b;
stats.df      = nu*ones(1,size(Y,2));
stats.mu      = yhat;
stats.res     = r;
stats.ss      = sum(abs(r).^2,1);
stats.serrors = se;

return



% --------------------------------------------------------
% Compute 'F' contrast
function FSTAT = sub_Fcontrasts(Y,X,STATS)
% --------------------------------------------------------

if isa(X,'single'),  X = double(X);  end

% contrast
c = eye(size(X,2));
c(end,end) = 0;  % the last as "constant".


C0 = eye(size(c,1)) - c'*c;
% Find the orthogonal contrast matrix to the original
X0 = X*C0;

% Similarly find the corresponding design Matrices
R0 = eye(size(X,1)) - X0*pinv(X0);
R  = eye(size(X,1)) - X*pinv(X);
M = R0 - R;

rankM = rank(M);


Fnum   = dot(STATS.beta, X'*M*X*STATS.beta, 1);
Fdenom = dot(Y, R*Y, 1);

tmpi = (Fdenom ~= 0);
F = zeros(1,size(Y,2));
F(tmpi) = (Fnum(tmpi).*STATS.df(tmpi)) ./ (Fdenom(tmpi)*length(c));

curdf = max(STATS.df(:));
computedpval = fpdf(F,rankM,curdf);


FSTAT.F = F;
FSTAT.p = computedpval;


return

