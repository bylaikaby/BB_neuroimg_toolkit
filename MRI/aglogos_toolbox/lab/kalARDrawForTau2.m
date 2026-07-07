function [xPred,xPredVar]=kalARDrawForTau(x,P,N,ARamp,tauSq,ma,sigmaSq_a)

%Kalman filter returns predictions of x based on previous x, and the prediction variances.
%This is used to determine the driving noise variance tau^2.
%
%Arthur Gretton

%31/03/04 : offset removed for use with outlier removal in MRI signals
%           Chirp also removed. **Array** of observation noises is input,
%           since some observations (outliers) have higher variance.

%01/04/04 : this is a simplified version of kalARDrawForTau, which might not work.
%           See p. 357 Godsill and Rayner 98.

%Initialise Kalman filter variables
M_nn=sigmaSq_a*eye(P);      %=M[-1,-1]
x_nn=ma;                  %=a[-1,-1]
B=[zeros(P-1,1) eye(P-1);ARamp(P:-1:1)'];
c=[zeros(P-1,1);1];
h=zeros(P,1);

xPred=zeros(N,1);
xPredVar=zeros(N,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Forward step
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for j=1:N
  %Kalman filter steps
  h(P)=1;                            %NO CHIRP
  x_nn = x(j:P+j-1);
  x_n1n = B*x_nn;                      %Prediction
  M_n1n =  + c*c'*tauSq;    %Min prediction MSE matrix
  k=(M_n1n*h)/( 0 + h'*M_n1n*h);     %Kalman gain matrix         **THIS IS ONLY PLACE WHERE SIGMASQ COMES IN**
%  x_nn= x_n1n + k*(y(j) -h'*x_n1n );   %Correction, NO OFFSET       . **THIS IS ONLY PLACE WHERE Y COMES IN**
  M_nn=(eye(P) - k*h')*M_n1n;          %mimimum MSE matrix

  %Store x_n1n and M_n1n
  xPred(j)=x_n1n(end);
  xPredVar(j)=M_n1n(end,end);
  
%  keyboard
  
end

