function YDATA = mhrf(pars,xdata)
%MHRF - Make an Impluse Function model
% MHRF (pars,xdata) - returns the evaluation of one of two models
% (a gamma function only, or a gamma function + cos) for the points
% defined in the xdata.
% NKL, 06 April 2004

time = [0:length(xdata.dat)-1]*xdata.dt - xdata.ofs;

if 0,
  YDATA	= conv(xdata.dat,gampdf(time,pars(2),pars(3)));
  YDATA   = YDATA(:);
  YDATA   = pars(1) * YDATA(1:length(time));
else
  YDATA	= pars(1) * gampdf(time,pars(2),pars(3));
  YDATA   = YDATA(:);
end;



