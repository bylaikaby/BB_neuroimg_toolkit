function YDATA = irmodel(x,xdata)
%IRMODEL - Make an IR model
% IRMODEL (x,xdata) - returns the evaluation of one of two models
% (a gamma function only, or a gamma function + cos) for the points
% defined in the xdata.
% G+cos Initial Pars = [0.5282 3.0122 5.1973 1.5910 29.1681 0.0011];
% G Initial Pars = [3 1];
% NKL, 06 April 2004

if isempty(x),
	x = pars;
end;

xdata = xdata(:);
YDATA = x(1) * gampdf(xdata,x(2),x(3));

