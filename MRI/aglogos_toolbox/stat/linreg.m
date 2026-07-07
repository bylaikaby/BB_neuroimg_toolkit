function [intercept,slope,res] = linreg(x,y)
%LINREG - performs linear regression between vectors x and y
%	[slope,intercept,res] = LINREG(x,y) - linear regression
%
%	NOTES:
%   [b,bint,r,rint,stats] = regress(y,X) returns an estimate of in b, a
%   95% confidence interval for beta, in the p-by-2 vector bint. The residuals
%   are in r and a 95% confidence interval for each residual, is in the
%   n-by-2 vector rint. The vector, stats, contains the R2 statistic along
%   with the F and p values for the regression.
%	NKL, 06.04.01
%
%  REGRESS Multiple linear regression using least squares.
%     B = REGRESS(Y,X) returns the vector B of regression coefficients in the
%     linear model Y = X*B.  X is an n-by-p design matrix, with rows
%     corresponding to observations and columns to predictor variables.  Y is
%     an n-by-1 vector of response observations.
%
%     [B,BINT] = REGRESS(Y,X) returns a matrix BINT of 95% confidence
%     intervals for B.
% 
%     [B,BINT,R] = REGRESS(Y,X) returns a vector R of residuals.
% 
%     [B,BINT,R,RINT] = REGRESS(Y,X) returns a matrix RINT of intervals that
%     can be used to diagnose outliers.  If RINT(i,:) does not contain zero,
%     then the i-th residual is larger than would be expected, at the 5%
%     significance level.  This is evidence that the I-th observation is an
%     outlier.
% 
%     [B,BINT,R,RINT,STATS] = REGRESS(Y,X) returns a vector STATS containing
%     the R-square statistic, the F statistic and p value for the full model,
%     and an estimate of the error variance.
% 
%     [...] = REGRESS(Y,X,ALPHA) uses a 100*(1-ALPHA)% confidence level to
%     compute BINT, and a (100*ALPHA)% significance level to compute RINT.
% 
%     X should include a column of ones so that the model contains a constant
%     term.  The F statistic and p value are computed under the assumption
%     that the model contains a constant term, and they are not correct for
%     models without a constant.  The R-square value is one minus the ratio of
%     the error sum of squares to the total sum of squares.  This value can
%     be negative for models without a constant, which indicates that the
%     model is not appropriate for the data.
% 
%     If columns of X are linearly dependent, REGRESS sets the maximum
%     possible number of elements of B to zero to obtain a "basic solution",
%     and returns zeros in elements of BINT corresponding to the zero
%     elements of B.
% 
%     REGRESS treats NaNs in X or Y as missing values, and removes them.
    
  
EXAMPLE = 0;
if EXAMPLE,
	x = [1:16]';
	y = 2 * x + 4 + 4*rand(size(x,1),1);
end;

x = x(:);
y = y(:);

lx = [ones(length(x),1) x];
[b,bint,r,rint,stats] = regress(y,lx);

intercept = b(1);
slope = b(2);
res.bint = bint;
res.r = r;
res.rint = rint;
res.stats = stats;

if ~nargout,
	plot(x,y,'s');
	hold on;
	plot(x,intercept+slope*x,'r');
end;
