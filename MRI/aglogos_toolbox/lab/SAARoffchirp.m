%Chirp signal parameter estimation
%Chirp has both wo and b0 components
%Chirp has AR envelope.
%
%Author : Arthur Gretton
%
%31/05/00 : Kalman filter + random walk added to sample paramters
%03/06/00 : Kalman filter error eliminated.  This program only uses
%Kalman filter draw for sigma_e and sigma_nu.
%02/07/00 : option for using Kalman filter to draw AR process state
%added. Joint proposal on excitation and noise variances added.
%09/07/00 : offset added, PROPOSAL ON OMEGA AND BETA ADDED
%23/07/00 : added constraint on AR proposal so that frequencies
%greater than pi rejected.
%26/07/00 : added constraint that AR frequencies must be less than
%chirp frequencies, when proposing new AR frequecnies.  Also added
%part that rejects AR poles that are equal to 0 or pi.
%13/08/00 : All proposals on sigma_e and sigma_nu being rejected, so decreased
%the variances by a vactor of 10
%16/08/00 :  for large jump on chirp freq and rate, also use search
%proposal on driving and observation noise.
%16/08/00 : for initialising sigma_e and sigma_nu, use search to obtain
%optimal values.
%16/08/00 : proposal for large jump does not change beta : IN THIS
%VERSION, IT DOES
%16/08/00 : large jump also incorporates move on d
%17/08/00 : uses simulated annealing to initialise the sampler

%Note : program converges to a reasonably good solutions v. quickly
%: in about 50 iterations when N=300, AND N=200.

clear all
close all


%Variable definitions

%Signal length, iterations, burn in
N=500;           %Number of points in signal.
M=10000	         %Total number of iterations.
burnin = 000;    %burn in time : means are only calculated, and
                 %data stored, once this has elapsed
		 
n=(1:N)';        %Time index


%Chirp parameters : chirp = AR envelope * sin (w0*n+b0*n^2)
b0 = 0.002;      %Rate of chirp
w0 = 1;        %constant frequency term
%ARamp0 = ARcoeffGen(0.9,2);
%ARamp0 = [-2.3000 -2.6675 -1.8437 -0.5936]';
ARw0=[0.6 0.8];
ARpoleamp0=[0.7 0.9];
%ARpoleamp0=[0.2 0.4];
%ARpoleamp0=[0.5 0.5];
ARamp0 = ARcoeffGen(ARpoleamp0,ARw0);



%note : ordering is b1 to bN, where b1 multiplies a[n-1] etc
%note : 1./abs(roots([-(ARamp(P:-1:1))' 1])) gives magnitudes of
%poles, and -angle(roots([-(ARamp(P:-1:1))' 1])) gives frequencies
P=length(ARamp0);
d0=15;            %AR offset.


sigma_e0 = 0.8;
sigma_nu0=0.1


%Prior paramters
alpha_e=0.001;      %Gamma function hyperparameter on sigma_e
beta_e=0.001;     %Gamma function hyperparameter on sigma_e
alpha_nu=0.001;      %Gamma function hyperparameter on sigma_e
beta_nu=0.001;     %Gamma function hyperparameter on sigma_e
ma=zeros(P,1);  %Mean : generative process for initial a_0
sigma_a=1;      %Variance : generative process for initial a_0
mb=zeros(P,1);  %Mean : prior on AR coefficients b
sigma_b=1000;     %Variance : prior on AR coefficients b

%MCMC chirp proposal parameters for random walk
wmpvar=0.012;       %MCMC std dev, w proposal
bmpvar=0.000005;       %MCMC std dev, b proposal
dpvar=0.1;       %MCMC std dev, d proposal
sig_epvar=0.1;            %MCMC std dev, sigma_e proposal
sig_nupvar=0.05;           %MCMC std dev, sigma_nu proposal


%Generate signal
a0=zeros(P+N,1);                        %Contains true value of all
					%amplitudes, NOT initial
					%amplitudes.
a0(1:P) = randn(P,1)*sqrt(sigma_a) + ma;%Generate initial amplitudes
for i=1:N
  a0(i+P)= a0(i+P-1:-1:i)'*ARamp0 + sqrt(sigma_e0)*randn;
end
plot(a0)
pause
y=(a0(P+1:N+P) + d0).*sin(w0*n+b0*n.^2) + sqrt(sigma_nu0) * randn(size(n));

%debug : plot frequency spectrum
plot(y)
fprintf('enter to continue\n');
pause
freqaxis = linspace(-pi,pi,length(y));
fourtrans = abs(fftshift(fft(y)));
plot(freqaxis,fourtrans)
(w0>pi - N*b0) %MUST BE EQUAL TO ZERO
fprintf('enter to continue\n');
pause
close all


%Starting parameters
if 0
  w=2.5
  b=rand*(pi-w)/N;	%Starting value for beta : drawn from a
                        %uniform distribition over allowed values.		
  ARamp = ARcoeffGen(0.9,w0)     %Starting AR paramter amplitudes
  sigma_e = 2;         %Starting AR excitation variance
  sigma_nu = 3;        %Starting noise variance
elseif 0
  w=3.0107;
  b=1.4969e-04;
  ARamp=[0.7954   -0.7340    0.2027   -0.0377]';
  sigma_e=35;
  sigma_nu=80;
elseif 0
  w=0.4
  b=b0
  d=d0
  ARamp=ARcoeffGen(ARpoleamp0,[0.2 w0])
  sigma_e=4.125
  sigma_nu=63.775
else
  w=1.5
  b=0.003
  d=mean(abs(y))
  ARamp=ARcoeffGen([0.9 0.9],[0.4 0.5])
  sigma_e=1;
  sigma_nu=2;
  [sigma_e, sigma_nu] = varClimbOff(y,w,b,P,N,ARamp,sigma_e,sigma_nu,ma,sigma_a,d);
  a=kalARoffDraw(y,w,b,P,N,ARamp,sigma_e,sigma_nu,ma,sigma_a,d);
end

%a = [randn(P,1)*sqrt(sigma_a) + ma ; y]; %Starting amplitude estimate

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Variable definitions, used for speed
Ua=zeros(N,P);        %Satisfies :e=a-Ua*b, where e is excitation
                      %signal, and a is truncated to exclude first
		      %samples.
B=zeros(N,N+P);       %Satisfies : e=Ba, where a NOT truncated.
wsamples=zeros(1,M-burnin);         %The following variables are archives
bsamples=zeros(1,M-burnin);
dsamples=zeros(1,M-burnin);
Sigma_esamples=zeros(1,M-burnin);
Sigma_nusamples=zeros(1,M-burnin);
ARampsamples=zeros(P,M-burnin);


%Debug : parameters here fixed at their true values for
%test purposes.
if 0
w=w0;
b=b0;
ARamp=ARamp0;
d=d0;
sigma_e=sigma_e0;
sigma_nu=sigma_nu0;
a=a0;
end
if 1
  load stuckState
  [sigma_e, sigma_nu] = varClimbOff(y,w,b,P,N,ARamp,sigma_e,sigma_nu,ma,sigma_a,d);
  u=rand;
    sigma_enew = -10;
    while sigma_enew<0
      sigma_enew=sqrt(sig_epvar)*randn + sigma_e;  %Generate new sigma_e
    end
    sigma_nunew = -10;
    while sigma_nunew<0
      sigma_nunew=sqrt(sig_nupvar)*randn + sigma_nu;  %Generate new sigma_e
    end
    prob=min([0 (ARoffkal(y,w,b,P,N,ARamp,sigma_enew,sigma_nunew,ma,sigma_a,d,1)-...
	      ARoffkal(y,w,b,P,N,ARamp,sigma_e,sigma_nu,ma,sigma_a,d,1)+...
	      log(sigma_enew^-(alpha_e+1)*exp(-beta_e/sigma_enew))-...
	      log(sigma_e^-(alpha_e+1)*exp(-beta_e/sigma_e))+...
	      log(sigma_nunew^-(alpha_nu+1)*exp(-beta_nu/sigma_nunew))/-...
	      log(sigma_nu^-(alpha_nu+1)*exp(-beta_nu/sigma_nu)) )]);
    if log(u)<prob
      sigma_e=sigma_enew;
      sigma_nu=sigma_nunew;
    end
end


for j=1:M
  j
  
  
  if j<0  %debug, required for burnin
    w=0.4
    b=b0
    d=d0
  end
  
  %Calculate AR coefficients
  for i=1:N
    Ua(i,:) = a(P+i-1:-1:i)';
  end

  Phi = (Ua'*Ua/sigma_e + eye(P)/sigma_b);

  ARfreqs=[10*ones(P,1)];
  while max(ARfreqs)>pi | sum(ARfreqs==0)>0 |  sum(abs(ARfreqs)==pi)>0 ...
	| sum(abs(ARfreqs)>w)>0
    ARamp = multigauss(Phi\(Ua'*a(P+1:N+P)/sigma_e + mb/sigma_b) , ...
		       Phi);
    ARfreqs=-angle(roots([-(ARamp(P:-1:1))' 1]));
  end
  ARamps=max(1./abs(roots([-(ARamp(P:-1:1))' 1])));
  fprintf('Freq :%6.2d, %6.2d\n',abs(ARfreqs(1)),abs(ARfreqs(3)) );
%  fprintf('ARamp : %6.2d, %6.2d, %6.2d, %6.2d\n',ARamp);

 
  %Calculate the amplitudes
  a=kalARoffDraw(y,w,b,P,N,ARamp,sigma_e,sigma_nu,ma,sigma_a,d);
  

  %Debug : parameters here fixed at their true values for
%test purposes.
%w=w0;
%b=b0;
%ARamp=ARamp0;
%d=d0;
%sigma_e=sigma_e0;
%sigma_nu=sigma_nu0;

  %Selection of new omega AND BETA
  u=rand;
  v=rand;    %Determines whether a large jump will occur

  if (v<0.2)  %small jump for local peak exploration
    wnew = 10;
    bnew = 10;
    while (wnew>pi - N*bnew) | (wnew<0) | (bnew<0)
      wnew=sqrt(wmpvar)*randn + w;  %Generate new
                                                   %omega
      bnew=sqrt(bmpvar)*randn + b;  %Generate new beta
    end
    
    prob=min([0 (ARoffkal(y,wnew,bnew,P,N,ARamp,sigma_e,sigma_nu,ma,sigma_a,d,1)-...
		 ARoffkal(y,w,b,P,N,ARamp,sigma_e,sigma_nu,ma,sigma_a,d,1))  ]);
    if log(u)<prob
      w=wnew;
      b=bnew;
    end
    fprintf('w, b : %6.2d  %6.2d\n',w,b);
  else  %large jump, incl. jump on variances, for movement between peaks

    %Propose freq ONLY
    wnew = 10;
    bnew = 10;
    while (wnew>pi - N*bnew) | (wnew<0) | (bnew<0)
      wnew=sqrt(wmpvar*100)*randn + w;  %Generate new
                                                   %omega
      bnew=sqrt(bmpvar)*randn + b;  %Generate new beta
    end
    %Get the MAP sigma_e and sigma_nu at this new freq
    [sigma_eNewMean, sigma_nuNewMean, dNewMean] = varClimbOff2(y,wnew,bnew,P,N,ARamp,sigma_e,sigma_nu,ma, sigma_a,d)
    sigma_enew = -10;
    while sigma_enew<0
      sigma_enew=sqrt(sig_epvar)*randn + sigma_eNewMean;  %Generate new sigma_e
    end
    sigma_nunew = -10;
    while sigma_nunew<0
      sigma_nunew=sqrt(sig_nupvar)*randn + sigma_nuNewMean;  %Generate new sigma_nu
    end
    dnew = -10;
    while dnew<0
      dnew=sqrt(dpvar)*randn + dNewMean;  %Generate new sigma_e
    end

    [sigma_eOldMean, sigma_nuOldMean, dOldMean]=varClimbOff2(y,w,b,P,N,ARamp,sigma_enew, ...
						 sigma_nunew,ma,sigma_a,dnew)

    
    gamma_epvar=sig_epvar;
    gamma_nupvar=sig_nupvar;
    gamma_dpvar=dpvar;

    prob=min([0 (ARoffkal(y,wnew,bnew,P,N,ARamp,sigma_enew,sigma_nunew,ma,sigma_a,dnew,1)-...
		 ARoffkal(y,w,b,P,N,ARamp,sigma_e,sigma_nu,ma,sigma_a,d,1)...
		     +(log(sigma_enew^-(alpha_e+1)*exp(-beta_e/sigma_enew)))...   %Sigma_e prior
		     -(log(sigma_e^-(alpha_e+1)*exp(-beta_e/sigma_e)))...
		     +(log(sigma_nunew^-(alpha_nu+1)*exp(-beta_nu/sigma_nunew)))...   %Sigma_nu prior
		     -(log(sigma_nu^-(alpha_nu+1)*exp(-beta_nu/sigma_nu)))...
		     -(1/2/gamma_epvar*(sigma_e - sigma_eOldMean)^2)...  %Proposal ratio sigma_e
		     +(1/2/gamma_epvar*(sigma_enew-sigma_eNewMean)^2)...
		     -(1/2/gamma_nupvar*(sigma_nu - sigma_nuOldMean)^2)...%Proposal ratio sigma_nu
		     +(1/2/gamma_nupvar*(sigma_nunew-sigma_nuNewMean)^2)...
		     -(1/2/gamma_dpvar*(d - dOldMean)^2)...%Proposal ratio d
		     +(1/2/gamma_dpvar*(dnew-dNewMean)^2)    )])

		 
    if log(u)<prob
      w=wnew;
      b=bnew;
      sigma_e=sigma_enew;
      sigma_nu=sigma_nunew;
    end
    wnew
    bnew
    sigma_enew
    sigma_nunew
    ARoffkal(y,wnew,b,P,N,ARamp,sigma_enew,sigma_nunew,ma, ...
	     sigma_a,d,1)
    ARoffkal(y,w,b,P,N,ARamp,sigma_e,sigma_nu,ma,sigma_a,d,1)
    fprintf('***LARGE JUMP***\n');
    fprintf('w, b : %6.2d  %6.2d\n',w,b);
    fprintf('Sigma_e : %6.2d\n',sigma_e);
    fprintf('Sigma_nu : %6.2d\n',sigma_nu);
  end
  
%debug : find max in likelihood on sigma_e and sigma_nu
%  w=0.4;
%d=d0;
%b=b0;
%ARamp = ARcoeffGen(ARpoleamp0,[0.2 1]);

    %Draw the excitation and noise variances
    u=rand;
    sigma_enew = -10;
    while sigma_enew<0
      sigma_enew=sqrt(sig_epvar)*randn + sigma_e;  %Generate new sigma_e
    end
    sigma_nunew = -10;
    while sigma_nunew<0
      sigma_nunew=sqrt(sig_nupvar)*randn + sigma_nu;  %Generate new sigma_e
    end
    prob=min([0 (ARoffkal(y,w,b,P,N,ARamp,sigma_enew,sigma_nunew,ma,sigma_a,d,1)-...
	      ARoffkal(y,w,b,P,N,ARamp,sigma_e,sigma_nu,ma,sigma_a,d,1)+...
	      log(sigma_enew^-(alpha_e+1)*exp(-beta_e/sigma_enew))-...
	      log(sigma_e^-(alpha_e+1)*exp(-beta_e/sigma_e))+...
	      log(sigma_nunew^-(alpha_nu+1)*exp(-beta_nu/sigma_nunew))/-...
	      log(sigma_nu^-(alpha_nu+1)*exp(-beta_nu/sigma_nu)) )]);
    if log(u)<prob
      sigma_e=sigma_enew;
      sigma_nu=sigma_nunew;
    end
    fprintf('Sigma_e : %6.2d\n',sigma_e);
    fprintf('Sigma_nu : %6.2d\n',sigma_nu);

    %debug
%  d=d0;
%ARamp=ARamp0;
%sigma_e=sigma_e0;
%  sigma_nu=sigma_nu0;
  
  %draw the offset
  u=rand;
  dnew = -10;
  while dnew<0
    dnew=sqrt(dpvar)*randn + d;  %Generate new sigma_e
  end
  prob=min([0 (ARoffkal(y,w,b,P,N,ARamp,sigma_e,sigma_nu,ma,sigma_a,dnew,1)-...
	       ARoffkal(y,w,b,P,N,ARamp,sigma_e,sigma_nu,ma, ...
	sigma_a,d,1))]);
  if log(u)<prob
    d=dnew;
  end
  fprintf('d : %6.2d\n',d);


  
  %Archive the samples
  if j>burnin
    Sigma_esamples(j-burnin)= sigma_e;
    Sigma_nusamples(j-burnin)= sigma_nu;
    ARampsamples(:,j-burnin)= ARamp;
    wsamples(j-burnin)= w;
    bsamples(j-burnin)= b;
    dsamples(j-burnin)= d;
 end
end

%Angles of AR parameters
M=j-1
angleplots=zeros(size(ARampsamples));
for j=1:M
 angleplots(:,j)=-angle(roots([-(ARampsamples(P:-1:1,j))' 1]));
end

%Amplitudes of AR parameters
ampplots=zeros(size(ARampsamples));
for j=1:M
 ampplots(:,j)=1./abs(roots([-(ARampsamples(P:-1:1,j))' 1]));
end




%Plot likelihood vs offset
if 0
d=linspace(0,10,200);
likearch=zeros(length(d),1);
for j=1:length(d)
  likearch(j)=ARoffkal(y,w0,b0,P,N,ARamp0,sigma_e0,sigma_nu0,ma,sigma_a, ...
		    d(j),1);
end

plot(d,likearch)

%Plot driving variance vs offset

sigma_e=linspace(0,3,50);
likearch=zeros(length(sigma_e),1);
for j=1:length(sigma_e)
  likearch(j)=ARoffkal(y,w0,b0,P,N,ARamp0,sigma_e(j),sigma_nu0,ma,sigma_a, ...
		    d0,1);
end

plot(sigma_e,likearch)
sigma_e(find(likearch==max(likearch(2:length(likearch)))))


end


if 0

%plot of the log likelihood for the large jump, illustrating the
%low probability of a succesful move.
freqSize=150;
betaSize=70
chirpFreqs=linspace(0,pi,freqSize);
chirpBeta=linspace(0.0015,0.0025,betaSize);

likelihoodArch=zeros(betaSize,freqSize);
Sigma_esamples=zeros(betaSize,freqSize);
Sigma_nusamples=zeros(betaSize,freqSize);
load stuckState

for k=1:length(chirpFreqs)
  for j=1:length(chirpBeta)
    w=chirpFreqs(k);
    b=chirpBeta(j);

    if ~(w>pi - N*b)
      [sigma_e, sigma_nu, d] = varClimbOff2(y,w,b,P,N,ARamp,sigma_e,sigma_nu,ma,sigma_a,d);
      fprintf('Sigma_e : %6.2d\n',sigma_e);
      fprintf('Sigma_nu : %6.2d\n',sigma_nu);
      Sigma_esamples(j,k)= sigma_e;
      Sigma_nusamples(j,k)= sigma_nu;
    
      likelihoodArch(j,k)=ARoffkal(y,w,b,P,N,ARamp,sigma_e,sigma_nu,ma,sigma_a,d,1);
      fprintf('Likelihood : %6.2d\n',likelihoodArch(j,k))
  
  
      fprintf('j=%i, k=%i\n',j,k);
    end  
  end
end


contour(chirpFreqs,chirpBeta,likelihoodArch);
ylabel('Chirp rate');
xlabel('chirp frequency \omega');

contour(chirpFreqs(1:k-1),chirpBeta,likelihoodArch(:,1:k-1));
mesh(chirpFreqs(1:k-1),chirpBeta,likelihoodArch(:,1:k-1));

end