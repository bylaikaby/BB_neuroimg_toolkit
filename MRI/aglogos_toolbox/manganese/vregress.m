function [b,bint,r,rint,stats,RSS,TSS,TSTAT] = vregress(y,X,alpha)
%VREGRESS - Vectorized version of Matlab's REGRESS.
%  [b,bint,r,rint,stats] = VREGRESS(y,X,alpha) is a vectorized version 
%  of Matlab's REGRESS().  'y' can be a matrix of (t,n).
%
%  [b,bint,r,rint,stats,TSTAT,RSS,TSS] = VREGRESS(y,X,alpha) returns also
%  TSTAT(T-statistics for coefficients), 
%  RSS(Regression sum of squares) and TSS (Total sum of squares).
%
%     yhat   = X*b;                            % Predicted responses at each data point.
%     RSS(N) = norm(yhat(:,N) - mean_y(N))^2;  % Regression sum of square
%     TSS(N) = norm(y(:,N)    - mean_y(N))^2;  % Total sum of squares
%
%
%  VREGRESS('debug',[]) runs in the debug mode.
%
%
%  SEE REGRESS() FOR DETAIL.
%
%  NOTES :
%    Unlike "REGRESS", "y" and "X" MUST NOT CONTAIN "NaN".
%    I switched to use MULREGRESS() instead of this function.
%
%  REFERENCES :
%    [1] Chatterjee, S. and A.S. Hadi (1986) "Influential Observations,
%        High Leverage Points, and Outliers in Linear Regression",
%        Statistical Science 1(3):379-416.
%    [2] Draper N. and H. Smith (1981) Applied Regression Analysis, 2nd
%        ed., Wiley.
%
%  VERSION :
%    0.90 28.06.05 YM  pre-release.
%    0.91 29.06.05 YM  adds a debug mode, clean up codes.
%    0.92 06.02.12 YM  use mroi_file().
%
%  See also REGRESS, MULREGRESS


if  nargin < 2
  error('%s:TooFewInputs', ...
        'REGRESS requires at least two input arguments.',mfilename);
elseif nargin == 2
  alpha = 0.05;
end


% CHECK DEBUG MODE OR NOT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DEBUG = 0;
if nargin > 1 & ischar(y) & strcmpi(y,'debug'),
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

havenans = 0;
% Remove missing values, if any
% wasnan = (isnan(y) | any(isnan(X),2));
% havenans = any(wasnan);
% if havenans
%    y(wasnan) = [];
%    X(wasnan,:) = [];
%    n = length(y);
% end


% Use the rank-revealing QR to remove dependent columns of X.
[Q,R,perm] = qr(X,0);
p = sum(abs(diag(R)) > max(n,ncolX)*eps(R(1)));
if p < ncolX
  warning('%s:regress:RankDefDesignMat', ...
          'X is rank deficient to within machine precision.',mfilename);
  R = R(1:p,1:p);
  Q = Q(:,1:p);
  perm = perm(1:p);
end


% Compute the LS coefficients, filling in zeros in elements corresponding
% to rows of X that were thrown out.
b = zeros(ncolX,size(y,2));
b(perm,:) = R \ (Q'*y);


if nargout >= 2 | DEBUG > 0,
  % Find a confidence interval for each component of x
  % Draper and Smith, equation 2.6.15, page 94
  RI = R\eye(p);
  nu = max(0,n-p);                % Residual degrees of freedom
  yhat = X*b;                     % Predicted responses at each data point.
  r = y-yhat;                     % Residuals.
  normr = zeros(1,size(r,2));
  for N = 1:size(r,2),
    normr(N) = norm(r(:,N));
  end
  if nu ~= 0
    rmse = normr/sqrt(nu);    % Root mean square error.
    tval = tinv((1-alpha/2),nu);
  else
    rmse = NaN;
    tval = 0;
  end
  s2 = rmse.^2;                    % Estimator of error variance.
  se = zeros(ncolX,size(r,2));
  tmpv = sqrt(sum(abs(RI).^2,2));
  for N = 1:size(r,2),
    se(perm,N) = rmse(N) * tmpv;
  end
  bint = zeros(size(b,1),2,size(b,2));
  for N = 1:size(b,2),
    bint(:,:,N) = [b(:,N)-tval*se(:,N), b(:,N)+tval*se(:,N)];
  end
  
  % compute T-statistics
  zeroidx = find(se(:) == 0);
  se(zeroidx) = 1;
  TSTAT = b ./ se;
  se(zeroidx) = 0;
  TSTAT(zeroidx) = 0;

  % Find the standard errors of the residuals.
  % Get the diagonal elements of the "Hat" matrix.
  % Calculate the variance estimate obtained by removing each case (i.e. sigmai)
  % see Chatterjee and Hadi p. 380 equation 14.
  if nargout >= 4 | DEBUG > 0,
    hatdiag = sum(abs(Q).^2,2);
    ok = ((1-hatdiag) > sqrt(eps(class(hatdiag))));
    hatdiag(~ok) = 1;
    if nu > 1
      denom = (nu-1) .* (1-hatdiag);
      sigmai = zeros(length(denom),size(r,2));
      for N = 1:size(r,2),
        sigmai(ok,N) = sqrt(max(0,(nu*s2(N)/(nu-1)) - (r(ok,N) .^2 ./ denom(ok))));
      end
      ser = zeros(size(sigmai,1),size(sigmai,2));
      tmpv = sqrt(1-hatdiag);
      for N = 1:size(ser,2),
        ser(:,N) = tmpv .* sigmai(:,N);
      end
      ser(~ok,:) = Inf;
    elseif nu == 1
      ser = zeros(length(hatdiag),length(rmse));
      tmpv = sqrt(1-hatdiag);
      for N = 1:size(ser,2),
        ser(:,N) = tmpv .* rmse(N);
      end
      ser(~ok,:) = Inf;
    else % if nu == 0
      ser = rmse*ones(size(y,1),size(y,2)); % == Inf
    end

    % Create confidence intervals for residuals.
    rint = zeros(size(r,1),2,size(r,2));
    for N = 1:size(r,2),
      rint(:,:,N) = [(r(:,N)-tval*ser(:,N)) (r(:,N)+tval*ser(:,N))];
    end
  end

  % Calculate R-squared and the other statistics.
  if nargout >= 5 | DEBUG > 0,
    % There are several ways to compute R^2, all equivalent for a
    % linear model where X includes a constant term, but not equivalent
    % otherwise.  R^2 can be negative for models without an intercept.
    % This indicates that the model is inappropriate.
    SSE = normr.^2;              % Error sum of squares.
    RSS = zeros(1,size(y,2));    % Regression sum of squares.
    TSS = zeros(1,size(y,2));    % Total sum of squares.
    tmpm = mean(y,1);
    for N = 1:size(y,2),
      RSS(N) = norm(yhat(:,N) - tmpm(N))^2;
      TSS(N) = norm(y(:,N)    - tmpm(N))^2;
    end
    zeroidx = find(TSS(:) == 0);
    TSS(zeroidx) = 1;
    r2 = 1 - SSE ./ TSS;         % R-square statistic.
    TSS(zeroidx) = 0;
    if p > 1
      zeroidx = find(s2(:) == 0);
      s2(zeroidx) = 1;
      F = (RSS/(p-1)) ./ s2;     % F statistic for regression
      s2(zeroidx) = 0;
    else
      F = NaN(size(RSS));
    end
    prob = 1 - fcdf(F,p-1,nu);   % Significance probability for regression
    stats = [r2; F; prob; s2;];

    % All that requires a constant.  Do we have one?
    if ~any(all(X==1,1))
      % Apparently not, but look for an implied constant.
      b0 = R\(Q'*ones(n,1));
      if (sum(abs(1-X(:,perm)*b0))>n*sqrt(eps(class(X))))
        warning('%s:regress:NoConst',...
                ['R-square and the F statistic are not well-defined' ...
                 ' unless X has a column of ones.\nType "help' ...
                 ' regress" for more information.'],mfilename);
      end
    end
  end

  % Restore NaN so inputs and outputs conform
  if havenans
    if nargout >= 3 | DEBUG > 0,
      tmp = repmat(NaN,length(wasnan),1);
      tmp(~wasnan) = r;
      r = tmp;
      if nargout >= 4 | DEBUG > 0,
        tmp = repmat(NaN,length(wasnan),2);
        tmp(~wasnan,:) = rint;
        rint = tmp;
      end
    end
  end

end % nargout >= 2


if DEBUG > 0,
  fprintf(' plotting...');
  figure('name',sprintf('%s: DEBUG',mfilename));
  subplot(2,3,1);
  imagesc(reshape(normr,[nX,nY])'); colorbar;  title('normr=norm(y-yhat)');
  subplot(2,3,2);
  imagesc(reshape(rmse, [nX,nY])'); colorbar;  title('rmse=normr/sqrt(nu)');
  subplot(2,3,3);
  imagesc(reshape(s2,   [nX,nY])'); colorbar;  title('s2=rmse.^2=norm(y-yhat)^2/nu');
  subplot(2,3,4);
  imagesc(reshape(TSS,  [nX,nY])'); colorbar;  title('TSS=norm(y-ymean)^2');
  subplot(2,3,5);
  imagesc(reshape(RSS,  [nX,nY])'); colorbar;  title('RSS=norm(yhat-ymean)^2');
  subplot(2,3,6);
  imagesc(reshape(F,    [nX,nY])'); colorbar;  title('F=RSS/s2/(p-1)');
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




