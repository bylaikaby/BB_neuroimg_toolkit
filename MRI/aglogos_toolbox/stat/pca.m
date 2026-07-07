function [PC, eVar, Proj, m] = pca(dat,npc)
%PCA - Applies Principal Component Analysi on the data
%	PCA - Uses the singular value decomposition routine of Matlab.
%   If A is M-by-N, SVDS(A,...) manipulates a few eigenvalues and vectors
%   returned by EIGS(B,...), where B = [SPARSE(M,M) A; A' SPARSE(N,N)],
%   to find a few singular values and vectors of A.  The positive
%   eigenvalues of the symmetric matrix B are the same as the singular
%   values of A.
%   S = SVDS(A) returns the 6 largest singular values of A.
%   S = SVDS(A,K) computes the K largest singular values of A.
%   S = SVDS(A,K,SIGMA) computes the K singular values closest to the 
%   scalar shift SIGMA.  For example, S = SVDS(A,K,0) computes the K
%   smallest singular values.
%
%   Practically, the idea is to compute:
%	1. The mean waveform
%	2. The most frequent variations around the mean (PCs w/ high eigenvalue)
%	Every single vector (e.g. one of the spike wave forms) can than
%	be reconstructed by linear combination of the mean waveform and the
%	first few components.
%	3. The coefficient of each component (the dot product of each
%	wave form with the PC will signify "how much" different that
%	wave form is from the mean in the direction of the 1st,
%	2nd.. etc. component. So, a number of such coefficients can be
%	used for classification etc.
%
%   PC stands for the npc first Principal Components
%   eVar: Eigenvalue
%	Proj: The coordinates of each vector in the PC space
%	m: The mean wave form
%
%	EXAMPLE:
%   Assuming matrix X with 100 spike wave forms:
%	[PC, eVar, Proj, m] = pca(X,5);
%
%	PC will contain the first 5 principal components
%
%	eVar/sum(eVar) their explained variance as percent of total
%
%	Proj(1:100,1:5) will have the 5 coefficients (coord) of each of ...
%	the 100 vectors.
%
%	m will be the mean spike form
%
%	TO VISUALIZE ANY CLASTERING OF SPIKE FORMS TYPE:
%	plot(Proj(:,1),Proj(:,2), plot(Proj(:,2),Proj(:,3), etc. This
%	will show whether forms separate along any of the directions.
%
%	TO VISUALIZE HOW WELL THE COMPONENTS RECONSTRCUT THE ORIGINAL FORMS
%   Say, the K=20th original form...
%	reco = PC * Proj(K,:)';
%   plot(X(:,K));
%	hold on;
%   plot(reco,'r');

datcenter = dat';							% invert the matrix in this case
m = mean(datcenter);                        % mean value

% MODIFIED HERE: BEGIN =====================================================
% ORIGINAL CODE
% datcenter = dat-repmat(m,[size(dat,1),1]);	% center the data
% tmp = cov(datcenter);                       % compute covariance matrix
% 07.09.04 YM: to avoid memory problem, use a for-loop
if any(m ~= 0),
  for N = size(datcenter,1):-1:1,
    datcenter(N,:) = datcenter(N,:) - m;
  end
end
tmp = mycov(datcenter);                       % compute covariance matrix
% MODIFIED HERE: END =======================================================


[U, eVar, PC] = svds(tmp, npc);			% find singular values
eVar = diag(eVar);						% turn diagonal mat into vector.

if nargout >= 3,
  m = m(:);								% return mean
  Proj = datcenter * PC;				% Proj centered dat onto PCs.
  Proj = Proj';							% invert back the matrix.
end


return;



  
%%%%%%%%%%%%%%%%%%%
%%%%% EXAMPLE OF RECONSTRUCTING INDIVIDUAL SIGNALS FROM PC COMPONENTS
%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Reco = getreco(Spf)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NPC=5;
for ObspNo=1:size(Spf,2)
  for ChanNo=1:size(Spf,1),
	[PC, eVar, Proj, SigMean] = pca(Sig{ChanNo,ObspNo}.dat,NPC);
	for K=1:size(Sig{ChanNo,ObspNo}.dat,2),
	  Spf{ChanNo,ObspNo}.reco(:,K) = PC * Proj(K,:)' + SigMean;
	end;
  end;
end;

