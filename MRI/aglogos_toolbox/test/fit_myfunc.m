function FIT = fit_myfunc(XDATA,DATA,varargin)
% XDATA as a vector with length of nx
% DATA  as a matrix of (nx,nsamples)
%
% FIT.fh        = fh;         % function to fit
% FIT.x         = XDATA;      % x data
% FIT.params    = FITPARS;    % fitted parameters
%
% To see fitted curve for i-th data,
%  plot(FIT.x,FIT.fh(FIT.params(:,i),FIT.x))

  
XDATA = XDATA(:);

if isvector(DATA),  DATA = DATA(:);  end




% Y = A*normpdf(X,mu,sigma) + B
% p(2) as mu, p(3) as sigma
fh = @(p,xdata)(p(1)*normpdf(xdata,p(2),p(3)) + p(4));




TOLFUN  = 1.0e-4;
MAXITER = 60;
options = optimset('TolFun',TOLFUN,'MaxIter',MAXITER,'Display','off');

pini    = [1.0 0 1.0  0];

FITPARS   = [];
TIME2PEAK = [];
AMPLITUDE = [];


for N = 1:size(DATA,2),
  tmpdat = DATA(:,N);
  tmppini = pini;
  [maxv maxi] = max(tmpdat);
  tmppini(2) = XDATA(maxi);
  tmppini(1) = maxv / max(fh(tmppini,XDATA));
  
  [p,resnorm,residual,exitflag] = lsqcurvefit(fh,tmppini,XDATA,tmpdat,[],[],options);
  yreco = fh(p,XDATA) - p(4);  % subtract DC offset
  [maxv maxi] = max(yreco);
  FITPARS(:,N) = p(:);
  TIME2PEAK(N) = XDATA(maxi(1));
  AMPLITUDE(N) = yreco(maxi(1));
end

FIT.fh        = fh;
FIT.x         = XDATA;
FIT.params    = FITPARS;
FIT.time2peak = TIME2PEAK;
FIT.amplitude = AMPLITUDE;

return
