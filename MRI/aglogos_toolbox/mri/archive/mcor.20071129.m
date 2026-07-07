function varargout = mcor(x,y,nlags)
%MCOR - Computes the coeff of correlation of model x to the columns of y
% MCOR Is used by mcorimg or mareats to compute cross correlation coefficients between a
% model defined in x and the time series of voxels, which of which is a column in the
% twodimensional matrix y.
%  
% r = MCOR(x,y) returns the correlation coefficients of model x and time series y. Default
% computation mode is 1 (see below).
%  
% r = MCOR(x,y,nlags) computes correlations after shifting appropriately the model with
% respect to the data or vice versa. Default nlags is 2;
%  
% [r, p] = MCOR(x,y,...) returns the correlation coefficients and their p value. Values
% below 0.05 are significant.
%
% Modes of computing r-values
%   mode == 0  corrcoef([x(:) y]); (fastest by very little)
%   mode == 1  loops all y columns [r,p] = corrcoef(x, y(:,N)]);
%   mode == 2  loops all y columns, computing manually r and p (not big advantage)
%   mode == 3  compensate model-data t-shifts, then compute r (20% slower - best results)
%
% If no lags are defined the function is using mode 1, otherwise 3.
%  
% NKL, 18.07.04
%
% See also MCORTST MCORANA MCORIMG MKMODEL MKSTMMODEL

  
DEBUG = 0;  
if ~nargin,                 % DEGUGGING with model-data
  tic;                      % Mark time to assess performance
  mode  = 3;                % see switch below
  DEBUG = 1;                % Set debugging mode
  NCOL	= 1000;             % Number of variables
  FREQ  = 1;                % Sinewave frequency
  HPERIOD = (1/FREQ)/2;		% Sinewave half-period
  JITTER = 3;               % Amplitude Noise jitter
  PHASEJITTER = 1.2;        % Phase Noise jitter
  nlags = 50;				% Lags to use for xcor
  len	= 200;				% Length of record
  Fs	= 100;              % 1 KHz sampling rate
  sampt = 1/Fs;             % Sampling rate
  t		= sampt * [1:len]'; % Time vector
  omega = 2*pi*FREQ;        % Frequency
  x0	= sin(omega*t);     % Signal
  x		= x0;               
  phase	= HPERIOD*omega*(PHASEJITTER*rand(NCOL,1)-0.5);
  for N=1:NCOL,
	y(:,N) = sin(omega*t+phase(N)) + JITTER*(rand(len,1)-0.5);
  end;
  y = -y;
  mfigure([1 60 1200 800]);
  subplot(2,2,1);
  plot(t,y,'r'); hold on; plot(t,x,'linewidth',2,'color','k');
  legend('DATA','MODEL');
  title('Sine Model -> Sine+Noise Data');
else
  if nargin & nargin < 2,
    help mcor;
    return;
  end;
  if nargin < 3,
    nlags = 0;
  end;
end;

if nlags,
  mode = 3;
else
  mode = 1;
end;


% mcor(x,y,mode),
% mode == 0     % corrcoef([x(:) y]); (fastest by very little)
% mode == 1     % loops all y columns [r,p] = corrcoef(x, y(:,N)]);
% mode == 2     % loops all y columns, computing manually r and p
% mode == 3     % xcorr

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AFTER CHECKING THE TIMES, THE ONLY MEANINGFUL MODES ARE 1 AND 3
% 1 -- IF WE DON'T CARE FOR SLIGHT TIME-SHIFTS
% 2 -- IF WE DO...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch mode,
  case 0,                           % This could be "quick&Dirty" but it doesn't save much
                                    % time really!
   [r p] = corrcoef([x(:) y]);
   r = r(1,2:end);
   p = p(1,2:end);
 case 1,                            % case 0 is by only 7% faster
   p = ones(size(y,2),1);
   r = zeros(size(y,2),1);
   
   %idxany = any(y,1);
   %for N = idxany,
   %  [tmpr tmpp] = corrcoef(x,y(:,N));
   %  r(N) = tmpr(1,2); p(N) = tmpp(1,2);
   %end

   for N=1:length(p),
     if any(y(:,N)),
       [tmpr,tmpp] = corrcoef(x,y(:,N));
       r(N) = tmpr(1,2); p(N) = tmpp(1,2);
     end;
   end;
 
 case 2,                            % Doing explicitly corrcoeff's job
   p = ones(size(y,2),1);;          % Is not saving much time (case 1 is fine)
   r = zeros(size(y,2),1);
   for N=1:length(p),
     c = cov(x,y(:,N));
     d = diag(c);
     denom=d*d';
     if denom > 0,
       tmp = c./sqrt(denom);
       r(N) = tmp(1,2);
       r2 = r(N) * r(N);
       s2 = sqrt((1-r2)/(size(x,1)-2));
       ts = abs(r(N)/s2);
       p(N) = 1.0 - tcdf(ts,size(x,1)-2);
     end;
   end;
 
 case 3,                            % Doing explicitly corrcoeff's job
   p    = ones(size(y,2),1);
   r    = zeros(size(y,2),1);
   dx   = zeros(size(y,2),1);
   
   % FIRST COMPUTE MAX(r) BY SHIFTING MODEL/DATA
   for N=1:length(p),
     if any(y(:,N)),
       [tmpr,lags] = xcorr(x,y(:,N),nlags,'coef');
       [mx,mxi] = max(abs(tmpr));
       dx(N) = lags(mxi);
     end
   end;

   % NOW USE THE SHIFTED DATA TO COMPUTE CORRCOEFF
   nanbuf = NaN * ones(size(x));
   for N=1:length(p),
     if any(y(:,N)),
       if dx(N)<=0,
         sy = nanbuf;
         sy(1:end+dx(N)) = y(1-dx(N):end,N);
         if all(sy == 0),
           tmpr = zeros(2,2);  tmpp = ones(2,2);
         else
           [tmpr,tmpp] = corrcoef(x(:),sy,'rows','pairwise');
         end
       else
         sx = nanbuf;
         sx(1:end-dx(N)) = x(dx(N)+1:end);
         if all(sx == 0),
           tmpr = zeros(2,2);  tmpp = ones(2,2);
         else
           [tmpr,tmpp] = corrcoef(sx,y(:,N),'rows','pairwise');
         end
       end;
       r(N) = tmpr(1,2); p(N) = tmpp(1,2);
     end;
   end
 
 otherwise,
  fprintf('MCOR: Unknown mode\n');
  help mcor;
  keyboard;
end;

if DEBUG,
  toc
  subplot(2,2,2);
  plot(x0,'linewidth',2,'color','k');
  hold on
  plot(y,'r');
  plot(x,'g--');
  if ~exist('dx'),
    dx = 1;
    sdx = dx*sampt*omega;
    title(sprintf('phase=%5.3f,  IDX=%d,  DX=%5.3f',phase(1),dx,sdx));
    legend('MODEL','DATA','SHIFTED-MODEL');
    hold off;
  else
    [mmin,mminix] = min(dx);
    [mmax,mmaxix] = max(dx);
    plot(x,'color','r','linewidth',2);
    hold on;
    plot(y(:,mminix),'g');
    plot(y(:,mmaxix),'b');
    plot(y(-dx(mminix)+1:end,mminix),'g','linewidth',2);
    plot(x(dx(mmaxix)+1:end),'b','linewidth',2);   
  end;
  
  subplot(2,2,3);
  hist(r,30);
  title('Distribution of r-values');
  subplot(2,2,4);
  if exist('p','var'),
    hist(p,30);
  end;
  title('Distribution of p-values');
  suptitle('MCOR: Modelled data to test mcor(x,y,...)','r');
end;

if nargout,
  varargout{1} = r;
end;

if nargout == 2,
  varargout{2} = p;
end;

if nargout > 2,
  varargout{2} = p;
  varargout{3} = dx;
end;

return;


