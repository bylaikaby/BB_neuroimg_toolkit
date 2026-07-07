function [oSig] = sigrmarchfact(Sig)
%SIGRMARCHFACT - Remove artifacts by projecting out sinusoids
% oSig = SIGRMARCHFACT (Sig) projects out sinusoids that were found after "strong" zero-padding
% (about 10x the initial data length).  Detection of the breathing frequencies occurs on the
% average of the voxel spectra.  Removal takes place on the individual spectra, to account for
% disparities in the phase between voxels.
%
% Criterion for removal: choose a factor that is some fraction of largest component found.
% Hypothesis: the units are comparable, i.e. a "large" perturbation due to breathing is
% "large" on the same scale across all voxels.
%
% Compared to matsart.m, this version uses the power spectrum to decide whether a breathing
% component is present.
% Idea: if fundamental too small, then assume remaining components are also not
% removable. PROBLEM: sometimes fundamental is there, but not harmonics
%
% New version: compared with matsart_powSpecOLD.m, check that ALL harmonics are significant
% before removing (not just fundamental). But do not look for harmonics if fundamental
% is absent.
%
% Arthur Gretton,  13.05.04
% Yusuke Murayama, 17.04.05   derived from Arthur's matsrmresp.m.



FRANGES{01} = [49 51];	% remove 50/100/150Hz (power line) noise,
FRANGES{02} = [29 31];	% remove 30/60/90Hz monitor noise

oSig = subRemoveArchfact(Sig, FRANGES);


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
function oSig = subRemoveArchfact(Sig, FRANGES);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

%fprintf(' %s:',mfilename);

%amount by which breathing harmonics must exceed median spectrum before they're removed
spectrumScaleFactors = [2 1 1]; 

if size(Sig.dat,1)*Sig.dx > 30,
  PADLEN = getpow2(round(30/Sig.dx),'ceiling');
else
  PADLEN = getpow2(size(Sig.dat,1),'ceiling') * 8;
end

if 1/Sig.dx < 10,
  % likely comes from imaging data.
  Sig.dat = detrend(Sig.dat);
end

%fprintf(' fft[%d,%.1fs]...',PADLEN,PADLEN*Sig.dx);
fdat = abs(fftshift(fft(Sig.dat,PADLEN,1)));
a = mean(fdat,2);                     %mean of the spectrum
N = size(Sig.dat,1);
n = (0:N-1)'*Sig.dx;                    %Time index
%myEye = eye(N);

Fs = 1/Sig.dx;
LEN = PADLEN/2;
fr = (Fs/2) * [0:LEN-1]/(LEN-1);
fr = fr(:);


oSig = Sig;
a = a(LEN+1:end);


for iF = 1:length(FRANGES),
  %frange{1} = [0.38 0.43];
  frange{1} = FRANGES{iF};
  frange{2} = frange{1} * 2;
  frange{3} = frange{1} * 3;

  fprintf(' %s %s [%.1f %.1f]x3harm.: %s[NCh=%d]', gettimestring, mfilename,...
          frange{1}(1), frange{1}(2), Sig.dir.dname, size(Sig.dat,2));

  % 30.08.04 YM: checks Sig.dx whether we can apply the operation or not.
  if Fs/2 < frange{1}(1), 
    continue;
  end

  a = mean(fdat,2);                     %mean of the spectrum
  a = a(LEN+1:end);
  
  %find the frequencies using FFT with zero padding at 10*length(y)
  fr1 = (fr>frange{1}(1) & fr<frange{1}(2));
  fr2 = (fr>frange{2}(1) & fr<frange{2}(2));
  fr3 = (fr>frange{3}(1) & fr<frange{3}(2));

  w_array = zeros(3,1);
  w_array(1) = 2*pi*fr(fr1 & (a==max(a(fr1))));
  w_array(2) = 2*pi*fr(fr2 & (a==max(a(fr2))));
  w_array(3) = 2*pi*fr(fr3 & (a==max(a(fr3))));


  numHarmonics = length(w_array);

  %Do line search over phases to find maximum likelihood
  numPhases = 100;  %number of phase shifts used in line search
  phaseArray = linspace(0,pi,numPhases);
  dArray = zeros(numPhases,numHarmonics);     %scale coefficients of all harmonics
  %breathe_est_noNorm = zeros(N); %contains breathing sinusoids


  for VoxNo = 1:size(Sig.dat,2),
    fprintf('.');
    y = oSig.dat(:,VoxNo);
    y_deflated = y;   %temporary copy of y, can be deflated by algorithm

    %Look at power spectrum to see whether sinusoid present at breathing freq
    [a,freqaxis] = psd(y,[],Fs,100);
    freqaxis=freqaxis';
    amp_w = (( ones(numHarmonics,1)*freqaxis ) < ( w_array/2/pi*ones(1,length(freqaxis)) ))   .* (ones(numHarmonics,1)*freqaxis);
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
        %y_deflated = (myEye - breathe_atOptim*inv(breathe_atOptim'*breathe_atOptim)*breathe_atOptim' ) * y_deflated;
        y_deflated = y_deflated - breathe_atOptim*inv(breathe_atOptim'*breathe_atOptim)*(breathe_atOptim'*y_deflated);
        %    y_deflated = y_deflated - dEstArray(whichHarmonic)*breathe_atOptim;
      
      end 
    end

    oSig.dat(:,VoxNo) = y_deflated;
  end
  fprintf(' done.\n');
end;



return;
