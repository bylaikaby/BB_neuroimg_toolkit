function xy = mycov(x,varargin)
%MYCOV Covariance matrix.
%   MYCOV() IS LESS MEMORY EATING VERSION OF MATLAB'S COV().
%
% VERSION : 0.90 07.09.04 YM  modified from matlab7's cov().
%
% See also COV

if nargin==0 
  error('mycov:NotEnoughInputs','Not enough input arguments.'); 
end
if nargin>3, error('mycov:TooManyInputs', 'Too many input arguments.'); end
if ndims(x)>2, error('mycov:InputDim', 'Inputs must be 2-D.'); end

nin = nargin;

% Check for cov(x,flag) or cov(x,y,flag)
if (nin==3) || ((nin==2) && (length(varargin{end})==1));
  flag = varargin{end};
  nin = nin - 1;
else
  flag = 0;
end

if nin == 2,
  x = x(:);
  y = varargin{1}(:);
  if length(x) ~= length(y), 
    error('mycov:XYlengthMismatch', 'The lengths of x and y must match.');
  end
  x = [x y];
end

if length(x)==numel(x)
  x = x(:);
end

[m,n] = size(x);

if m==1,  % Handle special case
  xy = zeros(class(x));

else
  % mofified HERE: BEGIN==========================================
  % ORIGINAL CODE
  %xc = x - repmat(sum(x)/m,m,1);  % Remove mean
  % 07.09.04 YM: to avoid memory problem, use a for-loop
  xc = x;  clear x;
  sumx = sum(xc)/m;
  for N = m:-1:1,
    xc(N,:) = xc(N,:) - sumx;
  end
  clear sumx;
  % mofified HERE: END============================================
  
  if flag
    xy = xc' * xc / m;
  else
    xy = xc' * xc / (m-1);
  end
  xy = 0.5*(xy+xy');
end
