function varargout = mulregress_contrast(BETA,COVB,CONTVEC,dfe)
%MULREGRESS_CONTRAST - Returns statistics for given contrast vector.
%  STATS = MULREGRESS_CONTRAST(BETA,COVB,CONTVEC,DFE) returns statistics for 
%  given contrast vector, "CONTVEC".  "COVB" is a covariance matrix of
%  regression coefficients and must be symmetric.  "DFE" is degrees of freedom
%  for error, n-p-1 for usual cases, n-p for models with a const. component.
%
%  !!!!!!!!!!!!!!!!!!!!!!!!!
%  AT THIS MOMENT (01.Jul.2005), I FOUND NO BOOK/LITERATURE DISCRIBING 
%  THIS KIND OF FUNCTION.  SO THERE IS NO GURANTEE THAT I MADE ARE CORRECT.
%  !!!!!!!!!!!!!!!!!!!!!!!!!
%
%  STATS structure will be like, (5 models, 1000 data)
%   STATS = 
%    contrast: [1 -1 0 0 0]       <-- contrast vector
%        beta: [1x1000 double]    <-- new beta by given contrast vector
%       tstat: [1x1 struct]       <-- t statistics
%   STATS.tstat = 
%         dfe: 75                 <-- degrees of freedom
%          se: [1x1000 double]    <-- standard error
%           t: [1x1000 double]    <-- t values
%        pval: [1x1000 double]    <-- p values (right side)
%        tail: 'right'            <-- t test tail
%
%  EXAMPLE :
%    >> mdl = (PREPARE MODELS INCLUDING A CONSTANT COMPONENT)
%    >> stats = mulregress(roiTs{1}.dat, mdl);
%    >> figure;
%    >> % plotting voxels that have a significant "beta" for each regressor (both-sided).
%    >> for N=1:size(model,2),
%    >>   idx = find(stats.tstat.pval(N,:) < 0.01);
%    >>   plot(mean(roiTs{1}.dat(:,idx),2);  hold on;
%    >> end
%    >>
%    >> % making contrast
%    >> CONTVEC = zeros(1,size(mdl,2);        % [0  0  0...0]
%    >> CONTVEC(1) = 1;  CONTVEC(2) = -1;     % [1 -1  0...0]
%    >> cont = mulregress_contrast(stats.beta,stats.covb,CONTVEC,stats.dfe);
%
%  VERSION :
%    0.90 01.07.05 YM   pre-release
%    0.91 09.08.05 YM   should ignore negative t-values (one-sided(right) t-test).
%
%  See also MULREGRESS

if nargin < 4,  help mulregress_contrast; return;  end


NumModels = size(COVB,1);


% make sure that "CONTVEC" is a row vector %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CONTVEC = CONTVEC(:)';

% check the size of "CONTVEC" %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if length(CONTVEC) < NumModels,
  CONTVEC(length(CONTVEC)+1:NumModels) = 0;
elseif length(CONTVEC) > NumModels,
  CONTVEC = CONTVEC(1:NumModels);
end

CC = CONTVEC'*CONTVEC;

newbeta    = zeros(1,size(COVB,3));
tstat.dfe  = dfe;
tstat.se   = zeros(1,size(COVB,3));
for N = 1:size(COVB,3),
  newbeta(N)     = CONTVEC * BETA(:,N);
  tstat.se(N)    = sqrt(sum(diag(COVB(:,:,N)*CC)));
end
tstat.t      = newbeta ./ tstat.se;
%tstat.pval   = 2*(tcdf(-abs(tstat.t), dfe));	% two-tailed
tstat.pval   = tcdf(-tstat.t, dfe);	% right one-tailed test
%tstat.pval   = tcdf(tstat.t, dfe);	% left one-tailed test


% IGNORE NEGATIVE T-VALUES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
idx = find(newbeta < 0);
if ~isempty(idx),
  tstat.t(idx)      = 0;
  tstat.pval(idx)   = 1;
end
tstat.tail = 'right';

% PREPARE THE STRUCTURE FOR OUTPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
STATS.contrast = CONTVEC;
STATS.beta  = newbeta;
STATS.tstat = tstat;

if nargout,
  varargout{1} = STATS;
end
return;

