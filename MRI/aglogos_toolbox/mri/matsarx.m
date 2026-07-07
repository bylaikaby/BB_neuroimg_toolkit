function fm = mvitarx(m,dx)
%MATSARX - Autoregression for filtering respiratory artifacts
% MVITARX (data, srate) Applies autoregression to model single or
% multiple-sinusoidals for removing respiratory artifacts from the
% fMRI data.
%
% 06/03/04 Compared with breatheModel_MRI.m, this version
% iteratively removes simusoidal components, starting with the
% fundamental (which is largest). Thus phase is permitted to differ
% between harmonics.
% 07/03/04 Compared with breatheModel_MRI2.m, this version finds
% the phase by maximising the projection
% of the sinusoid on the observations, rather than using the
% reconstruction error.
% We need a priori the correct frequency, the driving noise variance
% for the autoregressive process, and the number of poles in the filter.
% An improvement: you could:
% 1)  Reconstruct max likelihood y-b*sin() using the b_est from
% projection, and forwards/backwards kalman
% 2)  Find a new b by subtracting reconstruction from original
% observations (Gaussian noise is averaged out)
% This might be more accurate, since you'd then get "natural"
% components at the freq and phase of breathing
% due to smoothing effect of AR filter.
% harmonics MIGHT have different phase to fundamental (?)
% Arthur Gretton
% 04/03/04

fdat = fft(m,2048,1);
LEN = size(fdat,1)/2;
famp = abs(fdat(1:LEN,:));
freq = ((1/dx)/2) * [0:LEN-1]/(LEN-1);
freq = freq(:);
famp = mean(famp,2);
idx1 = find(freq>0.35 & freq < 0.46);
idx2 = find(freq>0.70 & freq < 0.92);
idx3 = find(freq>1.05 & freq < 1.38);
idx4 = find(freq>1.40 & freq < 1.80);
[mf, f1] = max(famp(idx1));
[mf, f2] = max(famp(idx2));
[mf, f3] = max(famp(idx3));
[mf, f4] = max(famp(idx4));
f1 = f1 + idx1(1) - 1;
f2 = f2 + idx2(1) - 1;
f3 = f3 + idx3(1) - 1;
f4 = f4 + idx4(1) - 1;

srate = 1/dx;
nyq = srate/2;
w_array = [freq(f1) freq(f2) freq(f3) freq(f4)]/nyq;
w_array = w_array * pi;
w_array(1) = 0.619 ;

numHarmonics = length(w_array);            %number of harmonics to be removed
numPhases = 100;  %number of phase shifts used in line search
phaseArray = linspace(0,pi,numPhases);

for VoxNo=1:size(m,2),
  y=m(:,VoxNo);            %for the moment, take one component
  N = size(y,1);            %Number of points in signal
  n=(1:N)';                    %Time index
  
  phiEstArray = zeros(numHarmonics,1); %Contains phase estimates for each harmonic
  dEstArray = zeros(numHarmonics,1); %Contains phase estimates for each harmonic
  dArray = zeros(numPhases,numHarmonics);     %scale coefficients of all harmonics
  breathe_est_noNorm = zeros(N); %contains breathing sinusoids

  y_deflated = y;   %temporary copy of y, can be deflated by algorithm

  for whichHarmonic = numHarmonics:-1:1
    for k=1:length(phaseArray)
      %subtract breathing component for current phase estimate
      %Columns are approximately ORTHOGONAL (exact if sinusoids
      %have complete cycles)
      phi_est = phaseArray(k);
      breathe_est_noNorm = sin(w_array(whichHarmonic)*n+phi_est);
    
      %note: d below is multiplied directly by vector
      %sin(w_array(whichHarmonic)*n+phi_est) to get breathing
      %signal
      dArray(k,whichHarmonic) = ...
          y_deflated'*breathe_est_noNorm*...
          diag(diag(inv(breathe_est_noNorm'*breathe_est_noNorm)));
    end

    %Get results at max PROJECTION AMPLITUDE
    currentDArray = dArray(:,whichHarmonic);
    dEstArray(whichHarmonic) = ...
        currentDArray(abs(currentDArray)==max(abs(currentDArray)));
    %  dEstArray(whichHarmonic) = max(dArray(:,whichHarmonic));
    %  %debug: check what happens if you take largest component
    phiEstArray(whichHarmonic) = ...
        phaseArray(abs(currentDArray)==max(abs(currentDArray)));

    %Project out the breathing component we found
    breathe_atOptim = sin(w_array(whichHarmonic)*n+  phiEstArray(whichHarmonic) );
    y_deflated = (eye(N) - breathe_atOptim *...
                  inv(breathe_atOptim'*breathe_atOptim)*breathe_atOptim' )*...
        y_deflated;
  end  

  breathe_est_noNorm = zeros(N,numHarmonics); %contains breathing sinusoids
  for l=1:numHarmonics   %construct harmonics at estimated phase
    breathe_est_noNorm(:,l) = sin(w_array(l)*n+ phiEstArray(l) );
  end
  %estimated spectrum with breathing removed
  fm(:,VoxNo) = y - breathe_est_noNorm*dEstArray;
end;

