function pcaTs = matspca(roiTs, nopcs)
%MATSPCA - Compute principal components of the roiTs data
% [PC, eVar, Proj, SigMean] = MATSPCA (dat, nopcs) extracts PCs of
% data and eliminated the ones resp-correlation etc..

if nargin < 2,
  nopcs = 100;
end;

if nargin < 1,
  help matspca;
  return;
end;

for N=1:length(roiTs),
  [PC, eVar, Proj, SigMean] = DoPCA(roiTs{N},nopcs);
  pcaTs{N} = rmfield(roiTs{N},'dat');
  pcaTs{N}.dat = PC;
  pcaTs{N}.reco = getreco(PC, eVar, Proj);
  pcaTs{N}.mdat = SigMean/max(SigMean(:));
  pcaTs{N}.vdat = mean(pcaTs{N}.dat,2);
  pcaTs{N}.vdat = pcaTs{N}.vdat/max(pcaTs{N}.vdat(:));
end;
return;

% DEBUGGING
mx1 = max(SigMean(:));
y = mean(Reco,2);
y = y(:);
hold off;
plot(SigMean,'k');
hold on;
plot(mx1*y/max(y),'r:');
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [PC, eVar, Proj, SigMean] = DoPCA(roiTs,nopcs);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SigMean = mean(roiTs.dat,2);
dat = roiTs.dat - repmat(SigMean,[1 size(roiTs.dat,2)]);
clear roiTs;
dat = dat';  
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
function Reco = getreco(PC, eVar, Proj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reconstruct each voxel's time series by getting the mean and the first NOPCS
for K=size(Proj,1):-1:1,
  Reco(:,K) = PC * Proj(K,:)';
end;
return;


