function yOut = breathe_remove(y,w_array,N);

%Arthur Gretton
%Breathing removal as a preprocessing step for spike removal

n=(1:N)';                    %Time index


%find the frequencies using MUSIC

[a,radFreqs]=pmusic(detrend(y),100,N*5);
fr1 = (radFreqs>0.5 & radFreqs<1);
fr2 = (radFreqs>1 & radFreqs<1.5);

w_array = [0 0];
w_array(1) = radFreqs(fr1 & (a==max(a(fr1))));
w_array(2) = radFreqs(fr2 & (a==max(a(fr2))));
keyboard

%find the frequencies using FFT with zero padding at 10*length(y)
radFreqs = [-pi:2*pi/10/N:pi-pi/10/N];
a=abs(fftshift(fft([y;zeros(length(y)*9,1)])))';
fr1 = (radFreqs>0.5 & radFreqs<1);
fr2 = (radFreqs>1 & radFreqs<1.5);

w_array = [0 0];
w_array(1) = radFreqs(fr1 & (a==max(a(fr1))));
w_array(2) = radFreqs(fr2 & (a==max(a(fr2))));
keyboard

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
keyboard


%freqAxis = [-pi:2*pi/N:pi-pi/N];
%plot(freqAxis,abs(fftshift(fft(y))),freqAxis,abs(fftshift(fft(y_deflated))),'r');
%