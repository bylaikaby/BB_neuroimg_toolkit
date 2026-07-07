function yOut = breathe_remove(y,w_array);
N=length(y);

%Arthur Gretton
%Breathing removal as a preprocessing step for spike removal

n=(1:N)';                    %Time index
numHarmonics = length(w_array);

%Do line search over phases to find maximum likelihood
numPhases = 100;  %number of phase shifts used in line search
phaseArray = linspace(0,pi,numPhases);
dArray = zeros(numPhases,numHarmonics);     %scale coefficients of all harmonics
breathe_est_noNorm = zeros(N); %contains breathing sinusoids
y_deflated = y;   %temporary copy of y, can be deflated by algorithm

for whichHarmonic = numHarmonics:-1:1
  fprintf('Harmonic is: %i',whichHarmonic);

  %debug: monitor spectral updates
  %plot(abs(fftshift(fft(y_deflated))));
  %pause


  for k=1:length(phaseArray)
    %subtract breathing component for current phase estimate
    %Columns are approximately ORTHOGONAL (exact if sinusoids have complete cycles)
    phi_est = phaseArray(k);
    breathe_est_noNorm = sin(w_array(whichHarmonic)*n+phi_est);
    
    %note: d below is multiplied directly by vector sin(w_array(whichHarmonic)*n+phi_est) to get breathing signal
    dArray(k,whichHarmonic) = y_deflated'*breathe_est_noNorm*diag(diag(inv(breathe_est_noNorm'*breathe_est_noNorm)));
  end

  %Get results at max PROJECTION AMPLITUDE
  currentDArray = dArray(:,whichHarmonic);
  dEstArray(whichHarmonic) = currentDArray(abs(currentDArray)==max(abs(currentDArray)));
%  dEstArray(whichHarmonic) = max(dArray(:,whichHarmonic));  %debug: check what happens if you take largest component
  phiEstArray(whichHarmonic) = phaseArray(abs(currentDArray)==max(abs(currentDArray)));

  %Project out the breathing component we found
  breathe_atOptim = sin(w_array(whichHarmonic)*n+  phiEstArray(whichHarmonic) );
  y_deflated = (eye(N) - breathe_atOptim*inv(breathe_atOptim'*breathe_atOptim)*breathe_atOptim' ) * y_deflated;
%   y_deflated = y_deflated - dEstArray(whichHarmonic)*sin(w_array(whichHarmonic)*n+phiEstArray(whichHarmonic));

end  
yOut = y_deflated;



