function e = T1mse(params,x,y)
% Function computers mean square error between data m*(1-exp(-x/T));

m = params(1);
T = params(2);
ly = m * (1 - exp(-x/T));
e = sum( (y-ly).^2 );
