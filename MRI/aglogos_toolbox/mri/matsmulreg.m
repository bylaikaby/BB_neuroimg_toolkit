function mregTs = matsmulreg(SESSION,FileTag,ConVector,pVal)
%MATSMULREG - Apply multiple regression analysis to the roiTs data.
% MATSMULREG (SESSION,FileTag,ConVector,pVal) applies multiple regression analysis to the ROI
% time series extracted with the MAREATS function. FileTag is ExpNo or GrpName;
%
% SESSION: Session Name
% ExpNo: Experiment Number
% ConVector: Contrast vector denoting the coefficient of each regressor
% pVal: for selecting significant voxels
%
% EXAMPLE:
%   tmp = mkmultreg('j02x31',2);
%   mdl = cat(2,tmp{1}.dat,tmp{2}.dat,tmp{3}.dat);
%   mdl(:,end+1) = 1; add a constant component for multi-regression analysis
%   stats = mulregress(roiTs{1}.dat, mdl);    run multi-regression analysis
%   stats = 
%           Q: [80x4 double]
%           R: [4x4 double]
%        perm: [4 1 2 3]
%        beta: [4x27167 double]
%     stdbeta: [4x27167 double]
%        yhat: [80x27167 double]
%           r: [80x27167 double]
%         dfe: 76
%         dfr: 3
%       ymean: [1x27167 double]
%         sse: [1x27167 double]
%         ssr: [1x27167 double]
%         sst: [1x27167 double]
%        xtxi: [4x4 double]
%        covb: [4x4x27167 double]
%       tstat: [1x1 struct]  <--- T statistics for each regressor
%       fstat: [1x1 struct]  <--- F statistics for overall fitting
%
%   figure;
%   subplot(2,2,1);
%   plot(mdl);  legend('1','2','3','4');
%
%   subplot(2,2,2); COL = 'bgr';
%   for N = 1:3,                (contrast vector of [1 0 0 0], [0 1 0 0], [0 0 1 0])
%       idx = find(stats.tstat.pval(N,:) < 0.01);
%       plot(mean(roiTs{1}.dat(:,idx),2),COL(N))
%       hold on;
%   end
%   making contrast, for an example, contrast-vector as [1 -0.33 -0.33 -0.33]
%   cont = mulregress_contrast(stats.beta,stats.covb,[1 -0.33 -0.33 -0.33],stats.dfe);
%
%   subplot(2,1,2);
%   cont = mulregress_contrast(stats.beta,stats.covb,[0.7 0.5 1 0],stats.dfe);
%   idx = find(cont.tstat.pval < 0.01);
%   plot(mean(roiTs{1}.dat(:,idx),2))
%  
%   NKL 11.08.05

if nargin < 4,
  pVal = 0.01;
end;

if nargin < 3,
  ConVector = [0.7 0.5 1 0];
end;

if nargin < 2,
  help matsmultreg;
  return;
end;

Ses = goto(SESSION);                    % Read session info

if ~isa(FileTag,'char'),
  FileTag = catfilename(Ses,ExpNo);
end;

load(FileTag);

mdl = [];
for N=1:length(roiTs{1}.mdl),
  mdl = cat(2,mdl,roiTs{1}.mdl{N});
end;
mdl(:,end+1) = 1;   % add a constant component for multi-regression analysis

for N=1:length(roiTs),
  stats{N} = SubFunMulReg(roiTs{1}.dat, mdl);
end;

% MODELS: [pulse, adapt-continuous, adapt-rebound, constant]
MODEL{1} = [1 0 0 0];
MODEL{2} = [0.7 0.5 0 0];
MODEL{3} = [0.7 0.5 1 0];

%%
%%
%%
%%

pVal = 0.001;
for N=1:length(roiTs),
  for M=1:length(roiTs{N}.r),   % Number of models
    cont = mulregress_contrast(stats{N}.beta,stats{N}.covb,MODEL{M},stats{N}.dfe);
    idx{N}{M} = find(cont.tstat.pval < pVal);
  end;
end;

regTs = mroitssel(roiTs,0,idx);

dspmulreg(regTs);
return;


% figure;
% subplot(2,2,1);  plot(mdl);  legend('1','2','3','4');
% % plotting, this is the same as contrast vector of [1 0 0 0], [0 1 0 0], [0 0 1 0]
% subplot(2,2,2); COL = 'bgr';
% for N = 1:3,
%   idx = find(stats.tstat.pval(N,:) < 0.01);
%   plot(mean(roiTs{1}.dat(:,idx),2),COL(N))
%   hold on;
% end
% % making contrast, for an example, contrast-vector as [1 -0.33 -0.33 -0.33]
% % cont = mulregress_contrast(stats.beta,stats.covb,[1 -0.33 -0.33 -0.33],stats.dfe);
% subplot(2,1,2);
% cont = mulregress_contrast(stats.beta,stats.covb,[0.7 0.5 1 0],stats.dfe);
% idx = find(cont.tstat.pval < 0.01);
% plot(mean(roiTs{1}.dat(:,idx),2))
% return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function STATS = SubFunMulReg(y,X)
% This is a quick solution. We'll check the function and return all arguments. But for now
% it's saving time and space....
% cont = mulregress_contrast(stats.beta,stats.covb,[0.7 0.5 1 0],stats.dfe);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 2,  help mulregress; return;  end

% Check that matrix (X) and left hand side (y) have compatible dimensions
[n,ncolX] = size(X);

if isvector(y),  y = y(:);  end
if ndims(y) > 2,
  error('%s:regress:InvalidData', 'Y must be a vector/matrix.',mfilename);
elseif size(y,1) ~= n
  error('%s:regress:InvalidData', ...
        'The number of rows in Y must equal the number of rows in X.',mfilename);
end
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
STATS.perm  = perm;			% permutation vector from QR decompositon
STATS.beta  = beta;			% Regression coefficients
STATS.dfe   = dfe;			% Degrees of freedom for error
STATS.covb  = covb;			% Covariance of regression coefficients
return;

