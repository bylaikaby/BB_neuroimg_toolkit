function [likelihood]=ARoffkal(y,w,b,P,N,ARamp,sigma_e,sigma_nu,ma,sigma_a,d,getlog)
%Kalman filter to determine likelihood.  ymean and yvar contain the
%parameters for the normal distribution representing the likelihood.
%
%Arthur Gretton
%31/05/00
%03/06/00 : correction term in Kalman filter fixed
%09/07/00 : offset added.


%Initialise Kalman filter variables
M_nn=sigma_a*eye(P);      %=M[-1,-1]
a_nn=ma;                  %=a[-1,-1]
B=[zeros(P-1,1) eye(P-1);ARamp(P:-1:1)'];
c=[zeros(P-1,1);1];
h=zeros(P,1);

%Initialise vectors for mean and variance of y, and likelihood.
if getlog
  likelihood=0;
else
  likelihood=1;
end
  

%debug
%dba=zeros(1,N);

for j=1:N
  %Kalman filter steps
  h(P)=sin(w*j+b*j^2);                 %Define scaling vector h
  a_n1n = B*a_nn;                      %Prediction
  M_n1n = B*M_nn*B' + c*c'*sigma_e;    %Min prediction MSE matrix
  k=(M_n1n*h)/(sigma_nu + h'*M_n1n*h); %Kalman gain matrix
  a_nn= a_n1n + k*(y(j) -h'*(a_n1n + d));%Correction, INCLUDES OFFSET
  M_nn=(eye(P) - k*h')*M_n1n;          %mimimum MSE matrix

  
  %mean and variance for y
  ymean=h'*(a_n1n + d);      %INCLUDES OFFSET

  %debug
  %dba(j)=ymean;

  yvar=h'*M_n1n*h + sigma_nu;
  if getlog
    likelihood = likelihood-1/2*log(yvar) + (-(y(j)-ymean)^2/2/yvar);
  else
    likelihood = likelihood*1/sqrt(yvar)*exp(-(y(j)-ymean)^2/2/yvar);
  end
%  likelihood
%  pause
  
end


%plot(y,'r')
%hold on
%plot(dba)
%hold off
