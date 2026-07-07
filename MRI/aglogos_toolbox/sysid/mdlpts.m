function YDATA = mdlpts(x,xdata)
%MDLPTS - Make an Impluse Function model
% MDLPTS (x,xdata) - returns the evaluation of one of two models
% (a gamma function only, or a gamma function + cos) for the points
% defined in the xdata.
% NKL, 06 April 2004

MODE=1;
if MODE==1,
  stm = zeros(length(xdata),1);
  stm(find(xdata <x(1))) = 1;
  YDATA	= conv(stm,gampdf(xdata(:),x(2),x(3)));
  YDATA = YDATA(:);
  YDATA = YDATA(1:length(xdata));

elseif MODE==2,
  YDATA	= x(1) * gampdf(xdata(:),x(2),x(3));

else
  xdata	= xdata(:);
  INCR	= 2 * pi / size(xdata,1);
  PHASE	= x(5) * INCR;
  COS	= x(4) * cos(INCR * xdata + PHASE);
  YDATA	= x(1) * gampdf(xdata,x(2),x(3)) .* COS + x(6);
end;

