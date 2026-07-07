function varargout = sigttest(varargin)
%SIGTTEST - Performs a t-test between signals
% H = SIGTTEST(Sig) performs a T-test of the hypothesis that the data in the
%   vector Sig.dat come from a distribution with mean zero, and returns the
%   result of the test in H.  H==0 indicates that the null hypothesis
%   ("mean is zero") cannot be rejected at the 5% significance level.  H==1
%   indicates that the null hypothesis can be rejected at the 5% level.  The
%   data are assumed to come from a normal distribution with unknown
%   variance.
%   If Sig has an stm field and blank-stimulus intervals exist,
%   then SIGTTEST will compare the blank-epochs of the signal with
%   the nonblank epochs.
% 
% H = SIGTTEST(Sig1,M) performs a T-test of the hypothesis that
%   the data in the vector Sig1.dat come from a distribution with mean M.
% 
% H = SIGTTEST(Sig1,Sig2) performs a paired T-test of the hypothesis that two
%   matched samples, in the vectors Sig1.dat and Sig2.dat, come from
%   distributions with equal means.  The difference X-Y is assumed to
%   come from a normal distribution with unknown variance.
%
% [H, t] = SIGTTEST(...) returns the reject/accept H0 and t-value
% [H, t, p] = SIGTTEST(...) returns the reject/accept H0 and t,p values
%
% See also TTEST MTEST SIGSTS
% 
% NKL 30.05.04  
    
if nargin < 1,
  help sigttest;
  return;
end;

tmp = varargin{1};
if isfield(tmp,'stm'),
  g1 = sigselepoch(tmp,'blank');
  g2 = sigselepoch(tmp,'nonblank');
  if isempty(g2.dat),
    fprintf('\nSIGTTEST: No stimulus period was found\n');
    fprintf('SIGTTEST: Check if recordings were for spontaneous activity\n');
    fprintf('SIGTTEST: To run this with spont-activity set grp.epoch\n');
    tmp = g1.dat;
    g1.dat = tmp(1:2:end,:,:);
    g2.dat = tmp(2:2:end,:,:);
  end;
end;

if exist('g1','var') & ~isempty(g1.dat) & ...
      exist('g2','var') & ~isempty(g2.dat),
  Grp1 = g1.dat;
  Grp2 = g2.dat;
else
  Grp1 = tmp.dat;
  if nargin == 1,
    Grp2 = zeros(size(Grp1));
  end;
end;

if nargin == 2,
  if isstruct(varargin{2}),
    tmp = varargin{2};
    Grp2 = tmp.dat;
  elseif isa(varargin{2},'double'),
    Grp2 = varargin{2} * ones(size(Grp1));
  end;
end;

if nargin == 3,
  alphaVal = varargin{3};
end;

if ~exist('alphaVal'),
  alphaVal = 0.01;
end;

alphaVal = alphaVal / size(Grp1,2);
dfx	= size(Grp1,1) - 1; 
dfy	= size(Grp2,1) - 1; 
dfe	= dfx + dfy;

bkg=mean(Grp1,1);
stm=mean(Grp2,1);
bkgstd  = std(Grp1,1,1);
stmstd  = std(Grp2,1,1);

difference	= stm-bkg;
bkgvar  = bkgstd.^2 * dfx;
stmvar  = stmstd.^2 * dfy;
pooleds	= sqrt((bkgvar + stmvar)*(1/(dfx+1)+1/(dfy+1))/dfe);
t = difference./pooleds;
pval = 1 - tcdf(t,dfe);
pval = 2 * min(pval,1-pval);

t(find(abs(pval)>alphaVal)) = 0; % not significants are zeroed
H = t;
H(find(t))=1;

varargout{1} = H;
if nargout >= 2,
  varargout{2} = t;
end;
if nargout == 3,
  varargout{3} = pval;
end;
return;




