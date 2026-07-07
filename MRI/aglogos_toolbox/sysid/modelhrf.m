function RESULTS = modelhrf(SesName,GrpName)
%MODELHRF - Model the experimentally measured HRF
% MODELHRF (SesName, GrpName) - fit a function to the Impulse-Response Data
% y=x(1)*gampdf(xdata,x(2),x(3)).*(x(4)*cos(2*pi/size(x).*x+pi/x(5)))+x(6);

% REMINDER: HERE ARE THE DEFAULT MATLAB OPTIONS FOR lsqcurvefit
% ======================================================================
% defaultopt = optimset('display','final','LargeScale','on', ...
%   'TolX',1e-6,'TolFun',1e-6,'DerivativeCheck','off',...
%   'Diagnostics','off',...
%   'Jacobian','off','MaxFunEvals','100*numberOfVariables',...
%   'DiffMaxChange',1e-1,'DiffMinChange',1e-8,...
%   'PrecondBandWidth',0,'TypicalX','ones(numberOfVariables,1)',...
%	'MaxPCGIter','max(1,floor(numberOfVariables/2))', ...
%   'TolPCG',0.1,'MaxIter',400,'JacobPattern',[], ...
%   'LineSearchType','quadcubic','LevenbergMarq','on'); 
%
% NKL, 03.04.01

% x = [ 0.1000   11.3368    0.2961];
x = [ 0.0827   13.9471    0.2363];

NUM_OF_PARS     = length(x);
DOPLOT          = 0;
MAXITER         = 500;
MAXFUNEVALS     = 200*NUM_OF_PARS;
TOLFUN          = 1.0000e-006;

if nargin < 2,
  fprintf('MODELHRF: Using Default HRF from N03.Qv1/Spont\n');
  SesName = 'n03qv1';
  GrpName = 'spont';
end;

Ses = goto(SesName);
filename = strcat(GrpName,'.mat');

hrf = sigload(Ses,GrpName,'hrf');

xdata = [0:size(hrf.dat,1)-1] * hrf.dx;

s = size(hrf.dat);
hrf.dat = reshape(hrf.dat,[s(1) prod(s(2:end))]);
ydata = mean(hrf.dat,2);

options=optimset('MaxFunEvals',MAXFUNEVALS,'MaxIter',MAXITER,'TolFun',TOLFUN);

% LOWER END UPPER BOUNDS
lb = [0  0  0];
ub = [5 20 10];

% exitflag > 0 -- function converged to a solution x
% exitflag = 0 -- max number of evaluation/iterrations was reached
% exitflag < 0 -- function did not converge to a solution

[X,resnorm,residual]=lsqcurvefit('irmodel',x,xdata,ydata,lb,ub,options);

Y = irmodel(X,xdata);

if DOPLOT,
  X
  plot(xdata,ydata,'linewidth',2,'linestyle',':','color','c');
  hold on;
  plot(xdata,Y,'r');
  grid on;
  set(gca,'xtick',[0:2:xdata(end)]);
  set(gca,'xlim',[xdata(1) xdata(end)]);
  xlabel('Time in sec');
  hold off;
end;



