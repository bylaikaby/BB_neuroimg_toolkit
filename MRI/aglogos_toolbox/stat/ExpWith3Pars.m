function F = ExpWith3Pars(P,x)
%EXPWITH3PARS - Compute exponential with (P,x)
% F = ExpWith3Pars(P,x) Computes exponential with (P,x)
% pfvdm F=myfun(x,xdata)
% F=x(3).*exp(-xdata./x(1))+x(3).*exp(-xdata./x(2));

if length(P) == 2
    F  = P(1).*exp(-x./P(2));
elseif length(P) == 3
    F  = P(1).*exp(-x./P(2)) + P(3);
else
    stop
end