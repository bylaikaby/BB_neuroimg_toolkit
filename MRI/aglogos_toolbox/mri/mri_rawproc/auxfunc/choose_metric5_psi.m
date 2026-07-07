function psi = choose_metric5_psi(u)
%CHOOSE_METRIC5_PSI - speed-improved PSI function for choose_metric(5).
%    CHOOSE_METRIC5_PSI(u) is a speed-improved PSI function for choose_metric(5).
%
%  VERSION :
%    0.90 25.01.17 YM  pre-release, derived from choose_metric.m.
%
%  See also choose_metric choose_metric5_dpsi choose_metric5_dpsiC.c


%% mex version: 1.062247s (2400 loops, size(u)=[16384 1]) on MATALB R2011b.
% psi = choose_metric5_psiC(u);
% return



%% original: 2.073089s (2400 loops, size(u)=[16384 1]) on MATALB R2011b.
% v = @(u) sqrt(u.*conj(u))/sqrt(u'*u);
% psi = -v(u)'*log(v(u));
% return



%% speed improved: 1.281697s (2400 loops, size(u)=[16384 1]) on MATALB R2011b.
vu  = sqrt(u.*conj(u))/sqrt(u'*u);
psi = -vu'*log(vu);
