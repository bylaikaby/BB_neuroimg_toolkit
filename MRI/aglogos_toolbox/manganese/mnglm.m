function varargout = mnglm(SESSION,GRPNAME,CONTVEC,REGFILE,varargin)
%MNGLM - runs general linear model analysis.
%  MNGLM(SESSION,GRPNAME,CONTVEC,REGFILE) runs general linear model analysis with
%  the given contrast vector (CONTVEC).
%
%  NOTES :
%
%  VERSION :
%    0.90 07.07.05 YM   pre-release
%    0.91 13.09.10 YM   called by mnregress().
%
%  See also MULREGRESS, MNREGRESS, MNVIEW

if nargin < 2,  help mnglm; return;   end

if nargin < 3,  CONTVEC = [];  end

if nargin < 4,
  REGFILE = 'mulregress_pca(1)_normalize(1)_xyfilter(1).mat';
end  


% CONTROL FLAGS/SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SAVEFILE = '';
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'save','savefile'}
    SAVEFILE = varargin{N+1};
  end
end


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);


% LOAD REGRESSION DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('%s %s: loading ''%s''...',datestr(now,'HH:MM:SS'),mfilename,REGFILE);
REG = load(REGFILE,'STATS');
REG = REG.STATS;
REG = rmfield(REG,{'dat','p','sse','ssr','sst','tstat'});

% needs only beta, mse, xtxi
BETA = REG.beta;
MSE  = double(REG.mse);
XTXI = double(REG.xtxi);
flags = REG.flags;


% PREPARE THE CONTRAST VECTOR IF NEEDED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(CONTVEC),
  CONTVEC = ones(1,length(REG.tag));
  CONTVEC(find(strcmpi(REG.tag,'const'))) = 0;
  tmpvec = [];
  while isempty(tmpvec),
    fprintf('\n models(n=%d) are [%s',length(REG.tag),REG.tag{1});
    for N = 2:length(REG.tag), fprintf(' %s',REG.tag{N}); end
    fprintf('].');
    fprintf('\n Q: contrast-vector [%d',CONTVEC(1));
    fprintf(' %d',CONTVEC(2:end));  fprintf('] ?: ');
    c = input('','s');
    tmpvec = str2num(c);
  end
  CONTVEC = tmpvec;
end

if length(CONTVEC) > length(REG.tag),
  CONTVEC = CONTVEC(1:length(REG.tag));
end
if length(CONTVEC) < length(REG.tag),
  CONTVEC(end+1:length(REG.tag)) = 0;
end

fprintf('%s %s: [%s(%d)',datestr(now,'HH:MM:SS'),mfilename,REG.tag{1},CONTVEC(1));
for N = 2:length(CONTVEC),
  fprintf(' %s(%d)',REG.tag{N},CONTVEC(N));
end
fprintf(']\n ');

% LOAD "Y" AND COMPUTE STATISTICS WITH THE GIVEN "CONRAST VECTOR" %%%%%%%
nX = size(MSE,1);  nY = size(MSE,2);  nS = size(MSE,3);
NEWBETA = zeros(nX,nY,nS);
TSTAT   = zeros(nX,nY,nS);
PVAL    = zeros(nX,nY,nS);
for iSlice = 1:nS,
  fprintf('.');
  % get beta as (nmodels,nvoxels)
  tmpb = double(squeeze(BETA(:,:,iSlice,:)));
  sz  = size(tmpb);
  tmpb = permute(reshape(tmpb,[prod(sz(1:end-1)), sz(end)]),[2 1]);
  % get cov-beta as (nmodels,nmodels,nvoxels)
  tmpmse  = squeeze(MSE(:,:,iSlice));
  tmpmse  = reshape(tmpmse,[1, nX*nY]);
  tmpcovb = zeros(size(XTXI,1),size(XTXI,2),nX*nY);
  for iVox = 1:nX*nY,
    tmpcovb(:,:,iVox) = XTXI * tmpmse(iVox);
  end
  % get statistics
  stats = mulregress_contrast(tmpb,tmpcovb,CONTVEC,REG.dfe);

  % keep the result
  NEWBETA(:,:,iSlice) = reshape(stats.beta,      [nX,nY]);
  TSTAT(:,:,iSlice)   = reshape(stats.tstat.t,   [nX,nY]);
  PVAL(:,:,iSlice)    = reshape(stats.tstat.pval,[nX,nY]);

  if mod(iSlice,50) == 0, fprintf(' %d\n ',iSlice);  end
end


% make a sturcture for output
STATS = {};
STATS.session  = Ses.name;
STATS.grpname  = grp.name;
STATS.ExpNo    = int16(grp.exps);
STATS.mapname  = 'glm';
STATS.datname  = 'tstat';
STATS.dat      = TSTAT;			% t statistics
STATS.p        = PVAL;			% p value
STATS.tag      = REG.tag;
STATS.contrast = CONTVEC;
STATS.model    = REG.model;
STATS.dfe      = REG.dfe;
STATS.dfr      = REG.dfr;
STATS.beta     = BETA;
STATS.flags.use_realigned = flags.use_realigned;
STATS.flags.use_pca       = flags.use_pca;
STATS.flags.normalize     = flags.normalize;
STATS.flags.xyfilter      = flags.xyfilter;
STATS.flags.xyfilt_hsize  = flags.xyfilt_hsize;
STATS.flags.xyfilt_sigma  = flags.xyfilt_sigma;


if nargout,
  varargout{1} = STATS;
else
  if any(SAVEFILE),
    matfile = SAVEFILE;
  else
    matfile = sprintf('glm_pca(%d)_normalize(%s)_xyfilter(%d).mat',...
                      flags.use_pca,flags.normalize,flags.xyfilter);
  end
  fprintf(' saving to ''%s''...',matfile);
  save(matfile,'STATS');
end


fprintf('\n%s %s done.\n',datestr(now,'HH:MM:SS'),mfilename);


return;
