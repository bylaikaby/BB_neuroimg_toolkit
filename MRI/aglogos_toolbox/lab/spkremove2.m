
%REMOVE THE BREATHING FIRST!  Actually this does not make much difference

%Compared to spkremove, this version uses a simple procedure to remove the breathing before
%attempting to remove the spikes. (removed)

%This version works on INDIVIDUAL VOXELS, and not the average over all voxels


%DEBUG
clear all
close all


%%% tcimgload('m02lx1',1);
% GO TO THE DATA DIRECTORY
% cd('//wks20/tmp');
load('spkremoveData.mat');
tcImg = tosdu(tcImg);
tcImg.dat = squeeze(tcImg.dat(:,:,1,:));
tcImg.dat = mreshape(tcImg.dat);
Sig = tcImg;
Sig.dat = detrend(Sig.dat);
K=1;
for N=1:size(Sig.dat,2),
  tmp = find(Sig.dat(:,N)>3);
  if length(tmp) > 5,
    ix(K) = N;
    K=K+1;
  end;
end;
ix = ix(:);
if 0,
  plot(mean(Sig.dat(:,ix),2));
else
  plot(mean(Sig.dat'));
  %  plot(Sig.dat(:,ix));
end;



%keyboard
%%% ARTHUR: HERE YOU HAVE A 1560x748 array
%%% You can take the average or experiment with each column
%keyboard
%Sig.dat = mean(Sig.dat,2);
Sig.dat =Sig.dat(:,323);  %example with well defined spikes

DIM=1;
NPTS = size(Sig.dat,DIM);
n=(1:NPTS)';               % Time index of signal



%remove the breathing component
%DEBUG
%Sig.dat = breathe_remove(Sig.dat,[0.619 1.2365 2.473],length(Sig.dat));

%Check breathing component really removed
freqaxis = [-pi:2*pi/NPTS:pi-pi/NPTS];  %See p. 77 Buck, Daniel, Singer
fourtrans = abs(fftshift(fft(Sig.dat)));
semilogy(freqaxis,fourtrans.^2)
fprintf('enter to continue\n');
pause
close all


m = mean(Sig.dat(:));
DI = 150;
K=1;
for N=1:DI:length(Sig.dat),
  ibeg = N;
  iend = N+DI-1;
  if iend > length(Sig.dat),
    iend = length(Sig.dat);
  end;
  
  sd(K) = std(Sig.dat(ibeg:iend,1,1));
  K=K+1;
end;
sd = median(sd);

%function spkremove(Sig,ARGS)
%SPKREMOVE - Remove spike-like artifacts from neuro/img signals
% SPKREMOVE (Sig) removes irregular, spike like artifacts from
% either the imaging or neural signals.
%
%01/04/04 Uses the noise variance drawing procedure of 1st year report.
%18/04/04 Outlier drawing procedure from p. 550 Carter and Kohn 1994
%
% Author : Arthur Gretton
% 31/03/04

DEF.NITERATIONS     = 400;
DEF.BURNIN          = 0;
DEF.NP              = 8;   %number of poles
DEF.NOUTLIERS       = 10;
DEF.OTLSCALE        = 2000000;  %debug: outlier scaling factor
DEF.ALPHA_SIGMASQ   = 0.001; 
DEF.BETA_SIGMASQ    = 0.001;
DEF.ALPHA_TAUSQ     = 0.001; 
DEF.BETA_TAUSQ      = 0.001;  
DEF.SIGMASQ_A       = 1;       
DEF.SIGMASQ_B       = 1000;    
DEF.SIG_TAUSQPVAR   = 0.00005; 
DEF.SIG_SIGMASQPVAR = 0.00005;


if exist('ARGS','var'),
  ARGS = sctcat(ARGS,DEF);
else
  ARGS = DEF;
end;
pareval(ARGS);

if strcmp('tcImg',Sig.dir.dname),
  DIM = 4;
else
  DIM = 1;
end;



p_out = NOUTLIERS/NPTS;
spikeVarScale = OTLSCALE;

%Prior paramters
% 0.001;      %Gamma prior hyperparameter on sigmaSq
alpha_sigmaSq   = ALPHA_SIGMASQ;
% 0.001;     %Gamma prior hyperparameter on sigmaSq  (small = close to Jeffries)
beta_sigmaSq    = BETA_SIGMASQ;
% 0.001;      %Gamma prior hyperparameter on sigma_tauSq
alpha_tauSq     = ALPHA_TAUSQ;
% 0.001;     %Gamma prior hyperparameter on sigma_tauSq
beta_tauSq      = BETA_TAUSQ;
ma=zeros(NP,1);     %Mean : generative process for initial x_0
% =1;         %Variance : generative process for initial x_0
sigmaSq_a       = SIGMASQ_A;
mb=zeros(NP,1);     %Mean : prior on AR coefficients b
% =1000;      %Variance : prior on AR coefficients b (very diffuse)
sigmaSq_b       = SIGMASQ_B;

%MCMC chirp proposal parameters for random walk
sig_tauSqpvar   = SIG_TAUSQPVAR;
% =0.005;            %MCMC std dev, sigma_tauSq proposal
sig_sigmaSqpvar = SIG_SIGMASQPVAR;
% =0.05;           %MCMC std dev, sigma_sigmaSq proposal

%Starting parameters
%ARamp=ARcoeffGen(0.4*ones(1,NP/2),linspace(pi/8,pi/2,NP/2));
%ARamp = [2.4138   -4.1050    5.2599   -5.2405    4.1772   -2.5646    1.1248   -0.3098]';
ARamp = [0.0519   -0.0130    0.0257    0.0273   -0.0878    0.0595   -0.0091   -0.0376]';
%  ARamp = ARamp0;
tauSq=0.3;   %
sigmaSq=0.45;         %sd^2;
%  outlIndArray=outlIndArray0;   %DEBUG: fixed at true value
outlIndArray = zeros(NPTS,1);     %starting assumption is no outliers
yStds = sqrt(sigmaSq) * ( (sqrt(spikeVarScale)-1)*outlIndArray + 1); %standard devs of each y

y = Sig.dat;
%note: observation *variances* passsed in
x=kalARDraw(y,NP,NPTS,ARamp,tauSq, yStds.^2 ,ma,sigmaSq_a);
%Variable definitions, used for speed
Ux=zeros(NPTS,NP);        %Satisfies :e=a-Ua*b, where e is excitation
                      %signal, and a is truncated to exclude first
		      %samples.

B=zeros(NPTS,NPTS+NP);       %Satisfies : e=Ba, where a NOT truncated.

%The following variables are archives
tauSqsamples=zeros(1,NITERATIONS);
sigmaSqsamples=zeros(1,NITERATIONS);
ARampsamples=zeros(NP,NITERATIONS);
outlierIndexSamples = zeros(NPTS,NITERATIONS);

for j=1:NITERATIONS
  if j>0   %Don't draw new AR parameters until noise terms stabilise
  
    %Draw AR coefficients
    for i=1:NPTS
      Ux(i,:) = x(NP+i-1:-1:i)';
    end
    Phi = (Ux'*Ux/tauSq + eye(NP)/sigmaSq_b);
    ARfreqs=[10*ones(NP,1)];
    %Proposal rejects poles on real axis and freqs greater than pi
    attemptDraws = 1;
    ARampPrev = ARamp;
    while  max(ARfreqs)>pi | sum(ARfreqs==0)>0 |  sum(abs(ARfreqs)==pi)>0 
      ARamp = multigauss(Phi\(Ux'*x(NP+1:NPTS+NP)/tauSq + mb/sigmaSq_b) , ...
                         Phi);
      ARfreqs=-angle(roots([-(ARamp(NP:-1:1))' 1]));
      attemptDraws=attemptDraws+1;
      if attemptDraws==10	
	ARamp = ARampPrev;
	ARfreqs=-angle(roots([-(ARamp(NP:-1:1))' 1]));
	disp('Did not draw AR coeffs this iteration')
	break
      end
    end

    fprintf('Freq :%6.2d, %6.2d\n',abs(ARfreqs(1)),abs(ARfreqs(3)) );
    %  fprintf('ARamp : %6.2d, %6.2d, %6.2d, %6.2d\n',ARamp);
 
    %note noise *variances* passed in

      end       %if j>20

    x=kalARDraw(y,NP,NPTS,ARamp,tauSq,yStds.^2,ma,sigmaSq_a);
   
   %Draw the indicator variables for the noise
   probNoSpikeArray = 1/sqrt(sigmaSq)*...
       exp(-1/sigmaSq*(y - x(NP+1:NP+NPTS)).^2) * (1-p_out);
   probSpikeArray = 1/sqrt(sigmaSq*spikeVarScale)*...
       exp(-1/sigmaSq/spikeVarScale*(y - x(NP+1:NP+NPTS)).^2) * ...
       p_out;
   
  
   
   %normalised prob of outlier
   probNoSpikeArray_norm =  probNoSpikeArray./(probNoSpikeArray+probSpikeArray);
   outlIndArray = rand(NPTS,1)>probNoSpikeArray_norm;
   %update standard devs of y
   yStds = sqrt(sigmaSq) * ( (sqrt(spikeVarScale)-1)*outlIndArray + 1);
  
    sum(outlIndArray)
    
  
  %Draw the excitation variance
  fprintf('tauSq : %6.2d\n',tauSq);
  u=rand;
  v=rand;
  tauSqnew = -10;
  while tauSqnew<0
    tauSqnew=sqrt(sig_tauSqpvar)*randn + tauSq;  %Generate new tauSq
  end
  prob=min([0 (ARkalOutlier(y,NP,NPTS,ARamp,tauSqnew,yStds.^2,ma,sigmaSq_a,1)-...
               ARkalOutlier(y,NP,NPTS,ARamp,tauSq,yStds.^2,ma,sigmaSq_a,1)+...
               log(tauSqnew^-(alpha_tauSq+1)*exp(-beta_tauSq/tauSqnew))-...
               log(tauSq^-(alpha_tauSq+1)*exp(-beta_tauSq/tauSq)) )]);
  if log(u)<prob
    tauSq=tauSqnew;
  end
  %   tauSq = tauSq0;  %DEBUG
  
  
  %Draw the noise variance
  u=rand;
  v=rand;
  sigmaSqNew = -10;
  while sigmaSqNew<0
    sigmaSqNew=sqrt(sig_sigmaSqpvar)*randn + sigmaSq;  %Generate new sigmaSq (dual proposal size cut)
    yStdsNew = sqrt(sigmaSqNew) * ( (sqrt(spikeVarScale)-1)*outlIndArray + 1); %update standard devs of y
    
  end
  prob=min([0 (ARkalOutlier(y,NP,NPTS,ARamp,tauSq,yStdsNew.^2,ma,sigmaSq_a,1)-...
               ARkalOutlier(y,NP,NPTS,ARamp,tauSq,yStds.^2,ma,sigmaSq_a,1)+...
               log(sigmaSqNew^-(alpha_sigmaSq+1)*exp(-beta_sigmaSq/sigmaSqNew))/-...
               log(sigmaSq^-(alpha_sigmaSq+1)*exp(-beta_sigmaSq/sigmaSq)) )]);
  if log(u)<prob
    sigmaSq=sigmaSqNew;
    yStds = yStdsNew;
  end
  fprintf('sigmaSq : %6.2d\n',sigmaSq);
  %    sigmaSq = sigmaSq0;  %DEBUG
  
  %Archive the samples
  tauSqsamples(j)= tauSq;
  sigmaSqsamples(j)= sigmaSq;
  ARampsamples(:,j)= ARamp;
  outlierIndexSamples(:,j) = outlIndArray;
end

%plot mean of outlier indices over entire sample run
plot(n,mean(outlierIndexSamples'));

%It is a good idea to replace output corrupted by outlier with DRAWN
%pattern, rather than expected pattern, since the latter may have too
%little variation (I think this was mentioned in Godsill98).

%note : 1./abs(roots([-(ARamp(NP:-1:1))' 1])) gives magnitudes of
%poles,