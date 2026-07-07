function oSig = matsart(Sig)
%MATSART - Remove respiratory artifacts by projecting out sinusoids
% oSig = MATSART (Sig) projects out sinusoids that were found after
% "strong" zero-padding (about 10x the initial data length).
% Arthur Gretton, 13.05.04

frange{1} = [0.38 0.43];
frange{2} = frange{1} * 2;
frange{3} = frange{1} * 3;
frange{4} = frange{1} * 4;

PADLEN = GetPow2(size(Sig.dat,1),'ceiling') * 8;
Sig.dat = detrend(Sig.dat);
fdat = abs(fftshift(fft(Sig.dat,PADLEN,1)));
a = mean(fdat,2);
N = size(Sig.dat,1);
n=(0:N-1)'*Sig.dx;                    %Time index

Fs = 1/Sig.dx;
LEN = PADLEN/2;
fr = (Fs/2) * [0:LEN-1]/(LEN-1);
fr = fr(:);

if 0,
  plot(fr,a(LEN+1:end));
end;
a = a(LEN+1:end);

%find the frequencies using FFT with zero padding at 10*length(y)
fr1 = (fr>frange{1}(1) & fr<frange{1}(2));
fr2 = (fr>frange{2}(1) & fr<frange{2}(2));
fr3 = (fr>frange{3}(1) & fr<frange{3}(2));
fr4 = (fr>frange{4}(1) & fr<frange{4}(2));

w_array = zeros(4,1);
w_array(1) = 2*pi*fr(fr1 & (a==max(a(fr1))));
w_array(2) = 2*pi*fr(fr2 & (a==max(a(fr2))));
w_array(3) = 2*pi*fr(fr3 & (a==max(a(fr3))));
w_array(4) = 2*pi*fr(fr4 & (a==max(a(fr4))));

numHarmonics = length(w_array);

%Do line search over phases to find maximum likelihood
numPhases = 100;  %number of phase shifts used in line search
phaseArray = linspace(0,pi,numPhases);
dArray = zeros(numPhases,numHarmonics);     %scale coefficients of all harmonics
breathe_est_noNorm = zeros(N); %contains breathing sinusoids

oSig = Sig;
for VoxNo = 1:size(Sig.dat,2),
  y = Sig.dat(:,VoxNo);
  y_deflated = y;   %temporary copy of y, can be deflated by algorithm
  for whichHarmonic = numHarmonics:-1:1
    % fprintf('Harmonic is: %i',whichHarmonic);
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
  oSig.dat(:,VoxNo) = y_deflated;
end;


