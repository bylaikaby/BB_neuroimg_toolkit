%Plot of AR likelihood vs frequency, when AR used to estimate
%chirp*AR envelope
%
%Author : Arthur Gretton
%
%Requires: ARKAL, MULTIGAUSS
%This version uses a chirp signal modulated by an AR process, and
%estimates it with chirp modulated by AR.

clear all
close all




%Signal length, iterations, burn in
N=300;           %Number of points in signal.
burnin = 000;    %burn in time : means are only calculated, and
                 %data stored, once this has elapsed
		 
n=(1:N)';        %Time index
sigma_e0 = 0.8;
sigma_nu0=0.5; %noise variance
P=2;         %Single complex pair

%Chirp parameters : chirp = AR envelope * sin (w0*n+b0*n^2)
b0 = 0.002;      %Rate of chirp
w0 = 0.5;        %constant frequency term
ARamp0 = ARcoeffGen(0.9,2);
ma=zeros(P,1);  %Mean : generative process for initial a_0
sigma_a=1;      %Variance : generative process for initial a_0

%Generate true signal
a0=zeros(P+N,1);                        %Contains true value of all amplitudes
a0(1:P) = randn(P,1)*sqrt(sigma_a) + ma;%Generate initial amplitudes
for i=1:N
  a0(i+P)= a0(i+P-1:-1:i)'*ARamp0 + sqrt(sigma_e0)*randn;
end
y=a0(P+1:N+P).*sin(w0*n+b0*n.^2) + sqrt(sigma_nu0) * randn(size(n));

freqaxis = linspace(-pi,pi,length(y));
fourtrans = abs(fftshift(fft(y)));
plot(freqaxis,fourtrans)

(w0>pi - N*b0) %MUST BE EQUAL TO ZERO
fprintf('enter to continue\n');
pause

%Prior paramters
alpha_e=0.001;      %Gamma function hyperparameter on sigma_e
beta_e=0.001;     %Gamma function hyperparameter on sigma_e
alpha_nu=0.001;      %Gamma function hyperparameter on sigma_nu
beta_nu=0.001;     %Gamma function hyperparameter on sigma_nu
mb=zeros(P,1);  %Mean : prior on AR coefficients b
sigma_b=1000;     %Variance : prior on AR coefficients b

%MCMC chirp proposal parameters for random walk
sig_epvar=0.7;            %MCMC std dev, sigma_e proposal
sig_nupvar=0.5;           %MCMC std dev, sigma_nu proposal



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%Variable definitions, used for speed
Ua=zeros(N,P);        %Satisfies :e=a-Ua*b, where e is excitation
                      %signal, and a is truncated to exclude first
		      %samples.
B=zeros(N,N+P);       %Satisfies : e=Ba, where a NOT truncated.


%Initialisation
sigma_e = 2;         %Starting AR excitation variance
sigma_nu = 0.5;        %Starting noise variance
a = [randn(P,1)*sqrt(sigma_a) + ma ; y]; %Starting amplitude estimate

ARamp = [0.5;-0.5];
%ARamp = [0.5;-0.5;0.5;-0.5];

M=200;	         %Total number of samples.
ARfreqs=linspace(0,pi,M);
chirpFreqs=linspace(0,pi,M);
likelihoodArch=zeros(length(ARfreqs),length(chirpFreqs));

Sigma_esamples=zeros(length(ARfreqs),length(chirpFreqs));
Sigma_nusamples=zeros(length(ARfreqs),length(chirpFreqs));




for k=1:length(chirpFreqs)
  for j=1:length(ARfreqs)
    ARamp=ARcoeffGen(0.9,ARfreqs(j));
    w=chirpFreqs(k);
    b=0;

  
    [sigma_e, sigma_nu] = varclimb(y,w,b,P,N,ARamp,sigma_e, ...
					 sigma_nu,ma,sigma_a);
    fprintf('Sigma_e : %6.2d\n',sigma_e);
    fprintf('Sigma_nu : %6.2d\n',sigma_nu);
    Sigma_esamples(j,k)= sigma_e;
    Sigma_nusamples(j,k)= sigma_nu;
    
    likelihoodArch(j,k)=ARkal(y,w,b,P,N,ARamp,sigma_e,sigma_nu,ma,sigma_a,1);
    fprintf('Likelihood : %6.2d\n',likelihoodArch(j,k))
  
  
    fprintf('j=%i, k=%i\n',j,k);
    
end
end


contour(chirpFreqs,ARfreqs,likelihoodArch);
ylabel('AR frequency');
xlabel('chirp frequency \omega');

[u,v]=find(likelihoodArch==max(max(likelihoodArch)))
ARkal(y,w0,b0,P,N,ARamp0,sigma_e0,sigma_nu0,ma,sigma_a,1)
max(max(likelihoodArch))
ARfreqs(u)
chirpFreqs(v)


%Contour : go along columns (left to right) = go across x axis
%(left to right).  Go down rows (top to bottom)=go up y axis
%(bottom to top)
if 0
likelihood=zeros(3,2);
for k=1:2
  for j=1:3
    likelihoodArch(j,k)=j+k;
  end
end
contour(1:2,1:3,likelihoodArch)
end