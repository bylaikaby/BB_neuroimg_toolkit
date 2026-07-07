function [likelihood]=ARkalOutlier(y,P,N,ARamp,tauSq,yVars,ma,sigmaSq_a,getlog)
%Kalman filter to determine likelihood.  ymean and yvar contain the
%parameters for the normal distribution representing the likelihood.
%
%Arthur Gretton

%01/04/04 : compared to ARoffkal.m, this has no offset and
%           allows the observation noise to have outliers

%Initialise Kalman filter variables
M_nn=sigmaSq_a*eye(P);      %=M[-1,-1]
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
  h(P)=1;                            %CONSTANT, NO SINE TERM
  a_n1n = B*a_nn;                    %Prediction
  M_n1n = B*M_nn*B' + c*c'*tauSq;    %Min prediction MSE matrix
  k=(M_n1n*h)/(yVars(j) + h'*M_n1n*h); %Kalman gain matrix, VARIANCE ARRAY HERE
  a_nn= a_n1n + k*(y(j) -h'*a_n1n);%Correction, NO OFFSET
  M_nn=(eye(P) - k*h')*M_n1n;          %mimimum MSE matrix

  
  %mean and variance for y
  ymean=h'*a_n1n;      %NO OFFSET

  %debug
  %dba(j)=ymean;

  yvar=h'*M_n1n*h + yVars(j);
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
