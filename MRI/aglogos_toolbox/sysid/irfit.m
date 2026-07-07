function RESULTS = irfit(ir,varname,ARGS)
%IRFIT - Fit a function to the Impulse-Response Data
% irfit(ir,varname,ARGS) - fit a function to the Impulse-Response Data
% y=x(1)*gampdf(xdata,x(2),x(3)).*(x(4)*cos(2*pi/size(x).*x+pi/x(5)))+x(6);
% ======================================================================
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
% ======================================================================
% NKL, 03.04.01

par.mn		= [1 5 5 2 20 0];
par.fmn		= [1 5 5 2 20 0];
par.a00		= [1 2 2 0.5 55 2];
par.b00		= [5 3 9 2 -10 1];
par.b97		= [1 2 2 0.5 55 2];
par.d97		= [1 2 2 0.5 55 2];
par.h97		= [1 2 2 0.5 55 2];
par.h00		= [1 2 2 0.5 55 2];
par.k00		= [1 2 2 0.5 55 2];

eval(sprintf('x = par.%s;',varname));
NUM_OF_PARS = length(x);

DOPLOT		= 1;
DOPRINT		= 0;
MAXITER		= 500;
MAXFUNEVALS = 200*NUM_OF_PARS;
TOLFUN		= 1.0000e-006;

if nargin > 2,
	tmp = fieldnames(ARGS);
	for i = 1:length(tmp),
		eval(sprintf('%s = %s;',tmp{i},strcat('ARGS.',tmp{i})),'');
	end;
end;

xdata = ir.t;
eval(sprintf('ydata = ir.%s;',varname));

options=optimset('MaxFunEvals',MAXFUNEVALS,'MaxIter',MAXITER,'TolFun',TOLFUN);

% LOWER END UPPER BOUNDS
lb = [.1 1 1 1 0 -2];
ub = [2 8 8 4 45 2];

% exitflag > 0 -- function converged to a solution x
% exitflag = 0 -- max number of evaluation/iterrations was reached
% exitflag < 0 -- function did not converge to a solution

[X,resnorm,residual,exitflag,output,LAMBDA,JACOB,usroptions] = ...
		lsqcurvefit('irmodel',x,xdata,ydata,lb,ub,options);

Y = irmodel(X,xdata);

if nargout,
	RESULTS.X = X;
	RESULTS.resnorm = resnorm;
	RESULTS.residual = residual;
	RESULTS.exitflat = exitflag;
	RESULTS.output = output;
%	RESULTS.options = usroptions;
	RESULTS.Y = Y;
end;

if ~DOPLOT,
	return;
end;

figure('position',[60 70 512 750]);
% figure('Position',[20 80 600 850]);
fs = get(gcf,'defaultaxesfontsize');

subplot('position',[0.13 0.48 0.78 0.43]);
if strcmp(varname,'fmn'),
	ed = errorbar(ir.t,ir.mn,ir.sd);
	set(ed(1),'Color','k');
	set(ed(2),'LineWidth',2,'Color','b');
else
	ed = plot(ir.t,eval(sprintf('ir.%s',varname)));
	set(ed,'LineWidth',1,'Color','b');
end;

hold on
plot(ir.t,Y,'Color','r','LineWidth',2);
grid on;

set(gca,'YColor','k');
set(gca,'FontWeight','bold','FontSize',9);
set(gca,'Xlim',[ir.t(1) ir.t(end)]);

xlabel('Time in Seconds','FontWeight','bold','FontSize',9);
ylabel('Normalized Response','FontWeight','bold','FontSize',9);
title(sprintf('VARNAME: %s',varname));
subplot('position',[0.13 0.08 0.78 0.33]);
axis off;
set(gca,'ylim',[0 1000]);
set(gca,'xlim',[0 1000]);
cy = 1000 - [10:57:950]';
cx = ones(length(cy(:)),1) * 5;

%txt{1}	= ir.label;
txt{1}	= 'No stimulus condition';
% txt{2}	= strcat('Monkeys...',sprintf('%s ',ir.monk{:}));
txt{2}	= strcat('Monkeys...',sprintf('%s ',ir.monk{1}));
txt{3}	= strcat('Variables Tested...',sprintf('%s ',ir.vars{:}));
txt{4}	= strcat('Optimal Parameters...',sprintf('%3.2f, ',X));
txt{5}	= sprintf('ExitFlag = %d ',exitflag);
txt{6}	='ExitFlag > 0 -- function converged to a solution x';
txt{7}	='Exitflag = 0 -- max NO of evaluation/iterrations was reached';
txt{8}	='Exitflag < 0 -- function did not converge to a solution';
txt{9}	= sprintf('ResNorm = %f',resnorm);
txt{10} = strcat('Algorithm: ',output.algorithm);
txt{11}	= sprintf('FuncCount = %d ',output.funcCount);
txt{12}	= sprintf('Iterations = %d ',output.iterations);
txt{13}	= sprintf('PCG (Precond. Conj. Gradient) Iterations = %d ',output.iterations);
txt{14}	= sprintf('Tolerance (TolFun) = %f',usroptions.TolFun);
txt{15}	= sprintf('Tolerance (TolPCG) = %f',usroptions.TolPCG);
txt{16} = sprintf('LevenbergMarquardt = %s',usroptions.LevenbergMarquardt);
txt{17} = sprintf('LineSearchType = %s',usroptions.LineSearchType);

for N=1:length(txt),
	text(0,cy(N),txt{N},'FontWeight','bold','FontSize',9,'Color','k');
end;

VARS = cat(2,ir.vars{:});
suptitle(sprintf('irfit(ir,''%s''): Variables: %s',varname,VARS));

orient(gcf,'portrait');
set(gcf,'PaperPositionMode','auto');
set(gcf,'PaperType','A4');

if (DOPLOT & DOPRINT),
	print;
	close all;
end;

if (DOPLOT & ~DOPRINT),
	pause;
	close all;
end;
