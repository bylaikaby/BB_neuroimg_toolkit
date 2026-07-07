function r2val = multreg(SESSION)
%MULTREG - Multiple regression analysis
%	r2val = MULTREG(SESSION)
%	NEEDS WORK...
%	NKL, 01.01.03

if nargin < 1,	SESSION	= 'a003x1'; end;

Ses			= hgetses(SESSION);
WorkSpace	= strcat(Ses.sysp.matdir,'workspace');
cd(WorkSpace);
load(Ses.name);

ESTSIG	= {'Lfp2080_Pts'; 'AvgMua_Pts'; 'Sdf_Pts'};
SIG		= {'Pts'};

%   [b,bint,r,rint,stats] = regress(y,X) returns an estimate of in b, a
%   95% confidence interval for beta, in the p-by-2 vector bint. The residuals
%   are in r and a 95% confidence interval for each residual, is in the
%   n-by-2 vector rint. The vector, stats, contains the R2 statistic along
%   with the F and p values for the regression.

[b,a] = butter(6,0.33,'low');

for n=1:length(ESTSIG),
	eval(sprintf('sig1 = %s;', char(SIG{1})));
	eval(sprintf('sig2 = %s;', char(ESTSIG{n})));
	GrpName = fieldnames(sig2);
	tmp = [];
	for g=1:length(GrpName),
		eval(sprintf('x = sig1.%s;', char(GrpName(g))));
		eval(sprintf('y = sig2.%s;', char(GrpName(g))));
		x = [ones(length(x),1) filtfilt(b,a,x)];
		x = x(20:120,:);
		y = y(20:120);
		[b,bint,r,rint,stats] = regress(y,x);
		tmp(g) = stats(1);
	end;
	r2val{n} = tmp;
end;




