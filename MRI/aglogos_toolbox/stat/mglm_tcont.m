function TCONT = mglm_tcont(GLMREGR,CONTRAST,varargin)
%MGLM_TCONT - Evalulate a GLM contrast.
%  TCONT = MGLM_TCONT(GLMREGR,CONTRAST...) evaluate a GLM contrast.
%
%  Supported options are :
%    'name'  : a string of the given contrast
%
%  EXAMPLE :
%    >> Y = rand(100,20);
%    >> DesignMatrix = Y(:,1:3);
%    >> glmregr = mglm_regress(Y,DesignMatrix);
%    >> tcont1 = mglm_tcont(glmregr,[1 0 0],'name','1+');
%    >> tcont2 = mglm_tcont(glmregr,[0 1 0],'name','2+');
%    >> tcont3 = mglm_tcont(glmregr,[0 0 1],'name','3+');
%
%  VERSION :
%    0.90 24.06.14 YM  pre-release
%
%  See also regress mglm_regress

if nargin < 1,  eval(['help ' mfilename]); return;  end

if isempty(CONTRAST),
  % ok, go through all regressors with +/- contrasts.
  nregr = size(GLMREGR.X,2);
  contmat = zeros(nregr-1,nregr);
  for N = 1:size(contmat,1)
    contmat(N,N)     =  1;
  end
  contmat = cat(1,contmat,-contmat);  % pos/neg
  for N = 1:size(contmat,1)
    tmpcont = contmat(N,:);
    tmpi = find(tmpcont ~= 0);
    tmpi = tmpi(1);
    if tmpcont(tmpi) == 1,
      tmpname = sprintf('%d+',tmpi);
    elseif tmpcont(tmpi(1)) == -1,
      tmpname = sprintf('%d-',tmpi);
    else
      tmpname = '';
    end
    TCONT(N) = mglm_tcont(GLMREGR,tmpcont,'name',tmpname,varargin{:});
  end
  return
end


NAMESTR = '';
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'name' 'tag'}
    NAMESTR = varargin{N+1};
  end
end


CONTRAST = CONTRAST(:)';

if length(CONTRAST) < size(GLMREGR.X,2)
  CONTRAST(end+1:size(GLMREGR.X,2)) = 0;
end


% reshape data
bsize = size(GLMREGR.beta);
GLMREGR.beta    = reshape(GLMREGR.beta,    [size(GLMREGR.beta,1),    prod(bsize(2:end))]);
GLMREGR.ss      = reshape(GLMREGR.ss,      [size(GLMREGR.ss,1),      prod(bsize(2:end))]);
GLMREGR.df      = reshape(GLMREGR.df,      [size(GLMREGR.df,1),      prod(bsize(2:end))]);
GLMREGR.serrors = reshape(GLMREGR.serrors, [size(GLMREGR.serrors,1), prod(bsize(2:end))]);


X = GLMREGR.X;

tcomputed = zeros(1,size(GLMREGR.beta,2));

BetaMag = CONTRAST*GLMREGR.beta;
TotalVariance = sum(GLMREGR.ss,1)./GLMREGR.df;
%CpiXXC = CONTRAST*pinv(X'*X)*CONTRAST';
Denom = sqrt(TotalVariance*(CONTRAST*pinv(X'*X)*CONTRAST'));
tmpi = (Denom ~= 0);
tcomputed(tmpi) = BetaMag(tmpi) ./ Denom(tmpi);
%isequal(BetaMag0,BetaMag)  % was 1, ok..

curdf = max(GLMREGR.df(:));

% Perform one tailed test on the data, that is only on the right hand side
% of the gaussian distribution are you allowed to do this, meaning
% negative values of t which in a two tailed test would be
% significant are not considered to be a part of the statistics,
tall = tcomputed;
tall(tall < 0) = 0;
computedpval = tpdf(tall,curdf);


TSTAT.contrast = CONTRAST;
TSTAT.df       = curdf;
TSTAT.t        = tcomputed;
TSTAT.p        = computedpval;



% reshape to the original dimension
TSTAT.t = reshape(TSTAT.t, [size(TSTAT.t,1), bsize(2:end)]);
TSTAT.p = reshape(TSTAT.p, [size(TSTAT.p,1), bsize(2:end)]);
GLMREGR.beta    = reshape(GLMREGR.beta,    [size(GLMREGR.beta,1),    bsize(2:end)]);
GLMREGR.ss      = reshape(GLMREGR.ss,      [size(GLMREGR.ss,1),      bsize(2:end)]);
GLMREGR.df      = reshape(GLMREGR.df,      [size(GLMREGR.df,1),      bsize(2:end)]);
GLMREGR.serrors = reshape(GLMREGR.serrors, [size(GLMREGR.serrors,1), bsize(2:end)]);



TCONT.name = NAMESTR;
TCONT.contrast = TSTAT.contrast;
TCONT.df   = TSTAT.df;
TCONT.t    = TSTAT.t;
TCONT.p    = TSTAT.p;


return
