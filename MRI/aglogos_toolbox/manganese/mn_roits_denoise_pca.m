function pcaTs = mn_roits_denoise_pca(roiTs, nopcs)
%MN_ROITS_DENOISE_PCA - Denoise roiTs base on PCA
% PCATS = MN_ROITS_DENOISE_PCA (ROITS,NOPCS) extracts PCs of
% data and project data onto them.
%
%  VERSION :
%    0.90 12.12.04 YM  pre-release
%    0.91 14.06.05 YM  adapted for m02th1.
%
%  See also MNALLCORR

if nargin < 1,  help mn_roits_denoise_pca;  return;  end;
if nargin < 2,  nopcs = [];  end

if isempty(nopcs), nopcs = 18;  end


for N = 1:length(roiTs),
  [PC, eVar, Proj, SigMean] = subDoPCA(roiTs{N},nopcs);
  pcaTs{N} = rmfield(roiTs{N},'dat');
  if isa(roiTs{N}.dat,'int16'),
    pcaTs{N}.dat  = int16(subGetReco(PC, eVar, Proj, SigMean));
  else
    pcaTs{N}.dat  = subGetReco(PC, eVar, Proj, SigMean);
  end
  pcaTs{N}.pca.nopcs = nopcs;
  pcaTs{N}.pca.pc    = PC;
  pcaTs{N}.pca.evar  = eVar;
  pcaTs{N}.mdat = SigMean;
end;


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [PC, eVar, Proj, SigMean] = subDoPCA(roiTs,nopcs);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dat		= double(roiTs.dat');			% transpose dat (T,N)->(N,T)
SigMean	= mean(dat,1);					% mean value along N
for N = 1:size(dat,2),
  dat(:,N) = dat(:,N) - SigMean(N);		% center the data
end
tmpcov	= cov(dat);						% compute covariance matrix

% [U,eVar,PC] = SVDS(dat,nopcs) computes the the nopcs first singular
% vectors of dat. If A is NT-by-N and K singular values are
% computed, then U is NT-by-K with orthonormal columns, eVar is K-by-K
% diagonal, and V is N-by-K with orthonormal columns.
[U, eVar, PC] = svds(tmpcov, nopcs);	% find singular values
eVar  = diag(eVar);						% turn diagonal mat into vector.
SigMean = SigMean(:);					% return mean
Proj = dat * PC;						% Proj centered dat onto PCs.

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Reco = subGetReco(PC, eVar, Proj, SigMean)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reconstruct each voxel's time series by getting the mean and the first NOPCS
for K=size(Proj,1):-1:1,
  Reco(:,K) = PC * Proj(K,:)';
end;

% paste back the mean
for K=size(Proj,1):-1:1,
  Reco(:,K) = Reco(:,K) + SigMean;
end


return;


