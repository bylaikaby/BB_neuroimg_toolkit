function [oSig] = matsrmresp(Sig, ExcludeRange)
%MATSRMRESP - Remove respiratory artifacts by projecting out sinusoids
% oSig = MATSRMRESP (Sig) projects out sinusoids that were found after "strong" zero-padding
% (about 10x the initial data length).  Detection of the breathing frequencies occurs on the
% average of the voxel spectra.  Removal takes place on the individual spectra, to account for
% disparities in the phase between voxels.
%
% Criterion for removal: choose a factor that is some fraction of largest component found.
% HYPOTHESIS: the units are comparable, i.e. a "large" perturbation due to breathing is "large"
% on the same scale across all voxels.
%
% Compared to matsart.m, this version uses the power spectrum to decide whether a breathing
% component is present. IDEA: if fundamental too small, then assume remaining components are
% also not removable. PROBLEM: sometimes fundamental is there, but not harmonics
%
% New version: compared with matsart_powSpecOLD.m, check that ALL harmonics are significant
% before removing (not just fundamental). But do not look for harmonics if fundamental
% is absent.
%
% ARTHUR Gretton, 13.05.04
% YM 25.03.06 Small changes and bug-fixing
% NKL 29.01.2013 Small changes and bug-fixing...

VERBOSE = 0;

if iscell(Sig),
  fprintf('\n');
  for N = 1:length(Sig),
    fprintf('%d.', N);
    Sig{N} = matsrmresp(Sig{N},ExcludeRange);
  end
  fprintf('\n');
  oSig = Sig;       % This here is needed; otherwise it will of course crash...
  return;
end

% Amount by which breathing harmonics must exceed median spectrum before they're removed
% spectrumScaleFactors = [1 1 1]; % THE NEXT SCALE GIVES THE BEST RESULT
spectrumScaleFactors = [0.8 0.7 0.5]; 

if nargin < 2,
  ExcludeRange = [0.10 0.14];
end;

Fs = 1/Sig.dx;
Nyq = Fs/2;

frange{1} = ExcludeRange;
frange{2} = frange{1} * 2;
if any(frange{2}>Nyq),  frange{2} = []; end;  
frange{3} = frange{1} * 3;
if any(frange{3}>Nyq),  frange{3} = []; end;  

PADLEN = getpow2(size(Sig.dat,1),'ceiling') * 8;

tmpMean = mean(Sig.dat,1);
Sig.dat = detrend(Sig.dat);
fdat = abs(fftshift(fft(single(Sig.dat),PADLEN,1)));
a = mean(fdat,2);                     %mean of the spectrum
clear fdat;

N = size(Sig.dat,1);
n=(0:N-1)'*Sig.dx;                    %Time index
myEye = eye(N);

LEN = PADLEN/2;
fr = (Fs/2) * [0:LEN-1]/(LEN-1);
fr = fr(:);
a = a(LEN+1:end);

% Find the frequencies using FFT with zero padding at 10*length(y)
fr1 = (fr>frange{1}(1) & fr<frange{1}(2));
fr2 = []; fr3 = [];
if ~isempty(frange{2}),  fr2 = (fr>frange{2}(1) & fr<frange{2}(2)); end;
if ~isempty(frange{3}),  fr3 = (fr>frange{3}(1) & fr<frange{3}(2)); end;

% Check if higher armonics are within the range.. (< Nyq)
w_array = [];
w_array(1) = 2*pi*fr(fr1 & (a==max(a(fr1))));
if ~isempty(find(fr2)),  w_array(2) = 2*pi*fr(fr2 & (a==max(a(fr2)))); end
if ~isempty(find(fr3)),  w_array(3) = 2*pi*fr(fr3 & (a==max(a(fr3)))); end
w_array = w_array(:);

if length(w_array) == 1,
  if VERBOSE,
    fprintf('\n WARNING %s: 2nd/3rd harmonics out of range, respHz=[%g %g],Sig.dx=%g(%gHz)...',...
          mfilename,frange{1}(1),frange{1}(2),Sig.dx,1/Sig.dx);
  else
    fprintf('?.');
  end;
end
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
  
  % Look at power spectrum to see whether sinusoid present at breathing freq
  % This used to be pwelch(y,[],Fs,100); but "Fs" can't be right... as NOOVERLAP is an integer!!!!
  % [a,freqaxis] = pwelch(y,[],[],128);

  [a,freqaxis] = pwelch(y,[],[],[]);    % Get default WINDOW, NOVERLAP and NFFT (256 or next L-power)
  freqaxis=freqaxis';
  amp_w = (( ones(numHarmonics,1)*freqaxis ) < ( w_array/2/pi*ones(1,length(freqaxis)) )).*(ones(numHarmonics,1)*freqaxis);
  w_gridLoc = max(amp_w');   %closest freqs to true freq on low dimensional grid
  a_ind=[];
  for k=1:numHarmonics
    a_ind(k) = find(freqaxis==w_gridLoc(k));   %indices of these approx breathing freqs
  end
  a_ind = sort([a_ind (a_ind+1)]); %since 2 points for each freq
                                   %a_compare_ind = [(a_ind(1)-10:a_ind(1)-4) (a_ind(2)+4:a_ind(2)+10)];
  a_compare_ind = [(10:a_ind(1)-4) (a_ind(2)+4:length(freqaxis))]; %points with which we compare peaks from breathing
  
  %only try to remove peaks when fundamental present
  medianPsd = median(a(a_compare_ind));
  iqrPsd = iqr(a(a_compare_ind));
  if mean(a(a_ind(1:2))) > medianPsd + spectrumScaleFactors(1)*iqrPsd
    harmonicList = 1;  %list of harmonics to remove
    for whichHarmonic = 2:numHarmonics
      if mean(a(a_ind(whichHarmonic*2-1:whichHarmonic*2))) >...
            medianPsd+ spectrumScaleFactors(whichHarmonic)*iqrPsd
        harmonicList = [harmonicList whichHarmonic];
      end
    end
    
    for whichHarmonic = harmonicList
      for k=1:length(phaseArray)
        %subtract breathing component for current phase estimate
        %Columns are approximately ORTHOGONAL (exact if sinusoids have complete cycles)
        phi_est = phaseArray(k);
        breathe_est_noNorm = sin(w_array(whichHarmonic)*n+phi_est);
        btmp(:,k)=breathe_est_noNorm; 
        %note: d below is multiplied directly by vector sin(w_array(whichHarmonic)*n+phi_est) to get breathing signal
        dArray(k,whichHarmonic) = y_deflated'*breathe_est_noNorm*diag(diag(inv(breathe_est_noNorm'*breathe_est_noNorm)));
      end
      
      %Get results at max PROJECTION AMPLITUDE
      currentDArray = dArray(:,whichHarmonic);
      bestIndex = find(abs(currentDArray)==max(abs(currentDArray)));
      bestIndex = bestIndex(1);
      dEstArray(whichHarmonic) = currentDArray(bestIndex);
      %  dEstArray(whichHarmonic) = max(dArray(:,whichHarmonic));  %debug: check what happens if you take largest component
      phiEstArray(whichHarmonic) = phaseArray(bestIndex);
      
      %Project out the breathing component we found
      breathe_atOptim = sin(w_array(whichHarmonic)*n+  phiEstArray(whichHarmonic) );
      y_deflated = (myEye - breathe_atOptim*inv(breathe_atOptim'*breathe_atOptim)*breathe_atOptim' ) * y_deflated;
      %    y_deflated = y_deflated - dEstArray(whichHarmonic)*breathe_atOptim;
      
    end  
  end
  oSig.dat(:,VoxNo) = y_deflated;
end;

oSig.dat = oSig.dat + repmat(tmpMean,[size(oSig.dat,1) 1]);
