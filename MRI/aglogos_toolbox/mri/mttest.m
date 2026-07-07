function [thr, pval, zmap] = mttest(x,y,alpha,tail)
%MTTEST - T-Test for imaging data
%	[thr, pval, zmap] = MTTEST(x,y,alpha,tail)
%	For TAIL =  0,  alternative: "mean is not M".
%	For TAIL =  1,  alternative: "mean is greater than M"
%	For TAIL = -1,  alternative: "mean is less than M"
%	TAIL = 0 by default.
%	NKL, 28.05.01

if nargin < 4, tail = 0; end 
if nargin < 3, alpha = 0.05; end 
if nargin < 2, error('x,y input is required'); end;

dfx			= size(x,3) - 1;
dfy			= size(y,3) - 1;
dfe			= dfx + dfy;
xcol		= reshape(x,[size(x,1)*size(x,2) size(x,3)]);
ycol		= reshape(y,[size(y,1)*size(y,2) size(y,3)]);

idx			= find(xcol,1);
tmpxcol		= xcol(idx,:);
tmpycol		= ycol(idx,:);
msx			= dfx * var(tmpxcol);
msy			= dfy * var(tmpycol);

difference	= mean(tmpxcol) - mean(tmpycol);
pooleds		= sqrt((msx + msy) * (1/(dfx + 1) + 1/(dfy + 1)) / dfe);
tmp			= difference ./ pooleds;
ratio		= zeros(size(x,1),size(x,2));
ratio(idx)	= tmp(:);

% SIGNIFICANCE PROBABILITY FOR THE TAIL = 1
significance  = 1 - tcdf(ratio,dfe);

% FOR OTHER NULL HYPOTHESES.
if tail == -1
    significance = 1 - significance;
elseif tail == 0
    significance = 2 * min(significance,1 - significance);
end

% ACCEPT ONLY IF THE ACTUAL SIGNIFICANCE EXCEEDS THE DESIRED SIGNIFICANCE
h = zeros(size(significance,1),size(significance,2));;
h(find(abs(significance)<=abs(alpha))) = 1;

zmap = reshape(ratio,[size(x,1) size(y,2)]);
pval = reshape(significance,[size(x,1) size(y,2)]);
thr  = reshape(h,[size(x,1) size(y,2)]);
return;

% function [thr, pval, zmap] = mttest(x,y,alpha,tail, mask)
% %MTTEST - T-Test for imaging data
% %	[thr, pval, zmap] = MTTEST(x,y,alpha,tail)
% %	For TAIL =  0,  alternative: "mean is not M".
% %	For TAIL =  1,  alternative: "mean is greater than M"
% %	For TAIL = -1,  alternative: "mean is less than M"
% %	TAIL = 0 by default.
% %	NKL, 28.05.01

% if nargin < 5, mask=ones(size(x,1),size(x,2)); end 
% if nargin < 4, tail = 0; end 
% if nargin < 3, alpha = 0.05; end 
% if nargin < 2, error('x,y input is required'); end;

% dfx			= size(x,3) - 1;
% dfy			= size(y,3) - 1;
% dfe			= dfx + dfy;
% xcol		= mreshape(x);
% ycol		= mreshape(y);
% idx			= find(mask(:));

% tmpxcol		= xcol(:,idx);
% tmpycol		= ycol(:,idx);
% msx			= dfx * var(tmpxcol);
% msy			= dfy * var(tmpycol);

% difference	= mean(tmpxcol) - mean(tmpycol);
% pooleds		= sqrt((msx + msy) * (1/(dfx + 1) + 1/(dfy + 1)) / dfe);
% tmp			= difference ./ pooleds;
% ratio		= zeros(size(x,1),size(x,2));
% ratio(idx)	= tmp(:);

% % SIGNIFICANCE PROBABILITY FOR THE TAIL = 1
% significance  = 1 - tcdf(ratio,dfe);

% % FOR OTHER NULL HYPOTHESES.
% if tail == -1
%     significance = 1 - significance;
% elseif tail == 0
%     significance = 2 * min(significance,1 - significance);
% end

% % ACCEPT ONLY IF THE ACTUAL SIGNIFICANCE EXCEEDS THE DESIRED SIGNIFICANCE
% h = zeros(size(significance,1),size(significance,2));;
% h(find(abs(significance)<=abs(alpha))) = 1;

% zmap = reshape(ratio,[size(x,1) size(y,2)]);
% pval = reshape(significance,[size(x,1) size(y,2)]);
% thr  = reshape(h,[size(x,1) size(y,2)]);



