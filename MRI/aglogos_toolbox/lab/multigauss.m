function [out]=multigauss(inmean,invar)
%Outputs a Gaussian drawn from the multivvariate distribution
%with mean 'inmean' and ****INVERSE**** variance 'invar'.

P=length(inmean);
[U,S,V] = svd(invar);
out =  (sqrt(S)*U')\randn(P,1) + inmean;