function [out1,out2,out3] = mhist(y,x)
%MHIST - Generate histograms of variable y over time x
% MHIST(Y) bins the elements of Y into 10 equally spaced containers
%   and returns the number of elements in each container.  If Y is a
%   matrix, HIST works down the columns.
%
% MHIST(Y,M), where M is a scalar, uses M bins.
%
% MHIST(Y,X), where X is a vector, returns the distribution of Y
%   among bins with centers specified by X.  Note: Use MHISTC if it is
%   more natural to specify bin edges instead.
%
% [out1,out2] = MHIST(y,x)
%
% See also HIST HISTC MYHIST SIGHIST EXPGETHIST
%
% NKL, 14.10.01

if min(size(y))==1, y = y(:); end
if isstr(x) | isstr(y)
    error('Input arguments must be numeric.')
end
[m,n] = size(y);
if isempty(y),
    if length(x) == 1,
       x = 1:x;
    end
    nn = zeros(size(x)); % No elements to count
else
    if length(x) == 1
        miny = min(min(y));
        maxy = max(max(y));
    	  if miny == maxy,
    		  miny = miny - floor(x/2) - 0.5; 
    		  maxy = maxy + ceil(x/2) - 0.5;
     	  end
        binwidth = (maxy - miny) ./ x;
        xx = miny + binwidth*(0:x);
        xx(length(xx)) = maxy;
        x = xx(1:length(xx)-1) + binwidth/2;
    else
        xx = x(:)';
        miny = min(min(y));
        maxy = max(max(y));
        binwidth = [diff(xx) 0];
        xx = [xx(1)-binwidth(1)/2 xx+binwidth/2];
        xx(1) = min(xx(1),miny);
        xx(end) = max(xx(end),maxy);
    end
    nbin = length(xx);
    % Shift bins so the internal is ( ] instead of [ ).
    xx = full(real(xx)); y = full(real(y)); % For compatibility
    bins = xx + max(eps,eps*abs(xx));
    nn = histc(y,[-inf bins],1);
    
    % Combine first bin with 2nd bin and last bin with next to last bin
    nn(2,:) = nn(2,:)+nn(1,:);
    nn(end-1,:) = nn(end-1,:)+nn(end,:);
    nn = nn(2:end-1,:);

	[hmax,idx]=max(nn);
	hidx = xx(idx);
end
if nargout == 2,
	out1 = bar(x,nn,'hist');
	out2 = hidx;
else
	out1 = x;
	out2 = nn;
	out3 = hidx;
end;
	
