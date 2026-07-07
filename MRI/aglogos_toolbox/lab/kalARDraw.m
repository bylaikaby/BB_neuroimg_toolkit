function [xout]=kalARDraw(y,P,N,ARamp,tauSq,yVars,ma,sigma_a)

%Kalman filter to draw output of AR process (pre-observation noise).
%
%Arthur Gretton

%31/03/04 : compared with kalARoffDraw.m, no offset, since used for outlier removal in MRI signals
%           No sine or chirp. Array of observation noises is input,
%           since some observations (outliers) have higher variance.

%Initialise Kalman filter variables
M_nn=sigma_a*eye(P);      %=M[-1,-1]
x_nn=ma;                  %=a[-1,-1]
B=[zeros(P-1,1) eye(P-1);ARamp(P:-1:1)'];
c=[zeros(P-1,1);1];
h=zeros(P,1);
h(P)=1;                            %NO SINE OR CHIRP

x_nnArch=zeros(P,N);
M_nnArch=zeros(P,N*P);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Forward step
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for j=1:N
  %Kalman filter steps
  x_n1n = B*x_nn;                      %Prediction
  M_n1n = B*M_nn*B' + c*c'*tauSq;    %Min prediction MSE matrix
  k=(M_n1n*h)/(yVars(j) + h'*M_n1n*h); %Kalman gain matrix         **THIS IS ONLY PLACE WHERE SIGMASQ COMES IN**
  x_nn= x_n1n + k*(y(j) -h'*x_n1n );   %Correction, NO OFFSET       . **THIS IS ONLY PLACE WHERE Y COMES IN**
  M_nn=(eye(P) - k*h')*M_n1n;          %mimimum MSE matrix

  %Store x_nn and M_nn
  x_nnArch(:,j)=x_nn;
  M_nnArch(:,((j-1)*P+1):(j*P))=M_nn;
end

%Initialisation : backwards archives
x_drawn=zeros(P,N+1);   %Contains array of points drawn from the
                        %Gaussian distribution
x_drawn(:,N)=multigauss(x_nn,inv(M_nn));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Backwards step
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for j=N-1:-1:1
  x_nnj=x_nnArch(:,j);  %Starting values for recursion 
  M_nnj=M_nnArch(:,((j-1)*P+1):(j*P));
  for k=1:P
    Kj=(M_nnj*B(k,:)')/(tauSq*(k==P) + B(k,:)*M_nnj*B(k,:)');
    x_nnj = x_nnj + Kj*(x_drawn(k,j+1) - B(k,:)*x_nnj);
    M_nnj = (eye(P) - Kj*B(k,:))*M_nnj;
  end
  %Note : only the top left hand entry actually contains non-zero
  %variance, since this is the only new variable that must be drawn;
  %the others were drawn on previous iterations.
  x_drawn(:,j)=[x_nnj(1)+sqrt(M_nnj(1,1))*randn ; x_nnj(2:P)];
end

%Special case : first point in the series
x_nnj=ma;  %Starting values for recursion
M_nnj=sigma_a;
for k=1:P
  Kj=(M_nnj*B(k,:)')/(tauSq*(k==P) + B(k,:)*M_nnj*B(k,:)');
  x_nnj = x_nnj + Kj*(x_drawn(k,1) - B(k,:)*x_nnj);%here j+1=1,
                                                   %since j=0
  M_nnj = (eye(P) - Kj*B(k,:))*M_nnj;
end
x_start=[x_nnj(1)+sqrt(M_nnj(1,1))*randn ; x_nnj(2:P)];

%Note : taking the last column of x_drawn as the state vector is
%legitimate, since the state vector values determined in previous
%iterations do not evolve in the next iteration.
xout=[x_start' x_drawn(P,:)]';
