function [aout]=kalARoffDraw(y,w,b,P,N,ARamp,sigma_e,sigma_nu,ma,sigma_a,d)

%Kalman filter to draw values from AR distribution.
%
%Arthur Gretton
%02/07/00
%03/07/00 : bug removed in generation of aout quantity.
%09/07/00 : offset added.

%Initialise Kalman filter variables
M_nn=sigma_a*eye(P);      %=M[-1,-1]
a_nn=ma;                  %=a[-1,-1]
B=[zeros(P-1,1) eye(P-1);ARamp(P:-1:1)'];
c=[zeros(P-1,1);1];
h=zeros(P,1);

a_nnArch=zeros(P,N);
M_nnArch=zeros(P,N*P);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Forward step
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for j=1:N
  %Kalman filter steps
  h(P)=sin(w*j+b*j^2);                 %Define scaling vector h
  a_n1n = B*a_nn;                      %Prediction
  M_n1n = B*M_nn*B' + c*c'*sigma_e;    %Min prediction MSE matrix
  k=(M_n1n*h)/(sigma_nu + h'*M_n1n*h); %Kalman gain matrix
  a_nn= a_n1n + k*(y(j) -h'*(a_n1n + d));             %Correction,
                                                      %INCLUDES OFFSET
  M_nn=(eye(P) - k*h')*M_n1n;          %mimimum MSE matrix

  %Store A_nn and M_nn
  a_nnArch(:,j)=a_nn;
  M_nnArch(:,((j-1)*P+1):(j*P))=M_nn;
end

%Initialisation : backwards archives
a_drawn=zeros(P,N+1);   %Contains array of points drawn from the
                        %Gaussian distribution
a_drawn(:,N)=multigauss(a_nn,inv(M_nn));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Backwards step
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for j=N-1:-1:1
  a_nnj=a_nnArch(:,j);  %Starting values for recursion 
  M_nnj=M_nnArch(:,((j-1)*P+1):(j*P));
  for k=1:P
    Kj=(M_nnj*B(k,:)')/(sigma_e*(k==P) + B(k,:)*M_nnj*B(k,:)');
    a_nnj = a_nnj + Kj*(a_drawn(k,j+1) - B(k,:)*a_nnj);
    M_nnj = (eye(P) - Kj*B(k,:))*M_nnj;
  end
  %Note : only the top left hand entry actually contains non-zero
  %variance, since this is the only new variable that must be drawn;
  %the others were drawn on previous iterations.
  a_drawn(:,j)=[a_nnj(1)+sqrt(M_nnj(1,1))*randn ; a_nnj(2:P)];
end

%Special case : first point in the series
a_nnj=ma;  %Starting values for recursion
M_nnj=sigma_a;
for k=1:P
  Kj=(M_nnj*B(k,:)')/(sigma_e*(k==P) + B(k,:)*M_nnj*B(k,:)');
  a_nnj = a_nnj + Kj*(a_drawn(k,1) - B(k,:)*a_nnj);%here j+1=1,
                                                   %since j=0
  M_nnj = (eye(P) - Kj*B(k,:))*M_nnj;
end
a_start=[a_nnj(1)+sqrt(M_nnj(1,1))*randn ; a_nnj(2:P)];

%Note : taking the last column of a_drawn as the state vector is
%legitimate, since the state vector values determined in previous
%iterations do not evolve in the next iteration.
aout=[a_start' a_drawn(P,:)]';
