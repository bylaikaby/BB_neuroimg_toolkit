function dpsi = choose_metric5_dpsi(u)
%CHOOSE_METRIC5_DPSI - speed-improved DPSI function for choose_metric(5).
%  CHOOSE_METRIC5_DPSI(u) is a speed-improved DPSI function for choose_metric(5).
%
%  NOTE :
%    This improved function gives the same performance as its mex version (choose_metric5_dpsiC).
%
%  VERSION :
%    0.90 25.01.17 YM  pre-release, derived from choose_metric.m.
%
%  See also choose_metric choose_metric5_psi choose_metric5_dpsiC.c


%% mex version: 3.183s (2400 loops, size(u)=[16384 1]) on MATALB R2011b.
% dpsi = choose_metric5_dpsiC(u);
% return



%% original: 6.449s (2400 loops, size(u)=[16384 1]) on MATALB R2011b.
% v = @(u) sqrt(u.*conj(u))/sqrt(u'*u);
% dpsi = -(v(u).*(1+log(v(u)))./conj(u) - sign(u).*v(u) * (v(u)'*(1 + log(v(u)))) / sqrt(u'*u));
% return



%% speed improved: 3.039s (2400 loops, size(u)=[16384 1]) on MATALB R2011b.
sqrtuu = sqrt(u'*u);
cu     = conj(u);
vu     = sqrt(u.*cu)/sqrtuu;
logvu1 = 1+log(vu);

%dpsi = -(vu.*(logvu1)./cu - sign(u).*vu * (vu'*(logvu1)) / sqrtuu);
tmpv = vu'*(logvu1);
dpsi = -(vu.*(logvu1)./cu - sign(u).*vu * tmpv / sqrtuu);
%dpsi = sign(u).*vu * (vu'*(logvu1)) / sqrtuu - vu.*(logvu1)./cu;

%v2   = vu'*(logvu1);
%dpsi = -(vu.*(logvu1)./cu - sign(u).*vu * v2 / sqrtuu);

%if ~isreal(u),  keyboard;  end
%if ~isvector(u),  keyboard;  end
