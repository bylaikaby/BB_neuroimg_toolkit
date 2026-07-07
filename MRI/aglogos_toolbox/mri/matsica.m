function icaTs = matsica(roiTs,RESPLIM1,RESPLIM2)
%MATSICA - Removal of resp artifacts by detecting independent sources
% MATSICA Compute the demixing matrix by using a 2nd order
% method like that of Molgedey and Schuster. The algorithm is
% called AMUSE, and it's faster than flexICA or erica.

if nargin == 1,
  RESPLIM1 = 0.38;
  RESPLIM2 = 0.44;
end;

icaTs = roiTs;

for RoiNo = 2:length(icaTs.roi),

  % COMPUTE DEMIXING MATRIX
  W = amuse(icaTs.roi{RoiNo}.dat');
  
  % USE IT TO GENERATE THE INDEPENDENT SOURCES
  demixedSources = W * icaTs.roi{RoiNo}.dat';
  
  % GET THE SPECTRA OF THE INDEPENDENT SOURCES
  tmpSig = rmfield(icaTs.roi{RoiNo},'dat');
  tmpSig.dat = demixedSources';
  [famp,fang,freq] = msigfft(tmpSig);
  
  % FIND THE INDEPENDENT SOURCE WHOSE SPECTRUM HAS A MAX IN RESPFREQ
  ix = find(freq>RESPLIM1 & freq < RESPLIM2);
  
  % WE SEARCH.. ALTHOUGH IT SEEMS THAT THE ALGORITHM IS RETURNING
  % THE MOST 'INDEPENDENT SOURCE AS FIRST COMPONENT
  for N=1:size(famp,2),
    tmp(N) = max(famp(ix,N));
  end;
  
  [maxtmp,k] = max(tmp);
  RespSig = tmpSig.dat(:,k);
  
  % NO SET THE VECTOR WITH THE MAX-RESPFREQ TO ZERO
  tmp = demixedSources';
  tmp(:,k) = zeros(size(tmp,1),1);
  
  % AND RECONSTRUCT THE SIGNAL WITHOUT THE RESP-ARTIFACT
  icaTs.roi{RoiNo}.dat = (inv(W) * tmp')';
  
  clear tmp, tmpSig;
end;
