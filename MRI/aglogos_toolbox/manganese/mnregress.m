function varargout = mnregress(SESSION,GRPNAME,MODELS,varargin)
%MNREGRESS - Runs multi-regression analysis with given models.
%  MNREGRESS(SESSION,GRPANME,MODELS) runs multi-regression analysis with
%  given MODELS.  MODELS can be a cell array of ROI name or numeric matrix.
%
%  SEE REGRESS() FOR DETAIL.
%
%  NOTES :
%
%  VERSION :
%    0.90 28.06.05 YM   pre-release
%    0.91 07.07.05 YM   modified to save data separately for MNVIEW().
%    0.92 12.09.10 YM   calls mnglm() to evaluate contrasts.
%    0.93 06.02.12 YM   use mroi_file().
%
%  See also REGRESS, VREGRESS, MNSEE_REGRESS, MNVIEW, MNGLM, MNGLMANA

if nargin < 2,  help mnregress; return;  end

if nargin < 3,  MODELS = {};  end



% CONTROL FLAGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DEBUG         = 0;
USE_REALIGNED = 1;
USE_PCA       = 0;
SAVEAS_MATFILE   = 1;

DO_NORMALIZATION = 'global';
DO_XYFILTER      = 1;
DO_STANDARDIZE   = 1;


ALPHA = 0.05;


% params for XY filtering
XYFILT_HSIZE     = 3;
XYFILT_SIGMA     = 0.8;

if isempty(MODELS),  MODELS = { 'plgn','mlgn','sc','v1','arteries' };  end


for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'alpha'}
    ALPHA = varargin{N+1};
   case {'use_pca', 'usepca','pca'}
    USE_PCA = varargin{N+1};
   case {'xyfilter'}
    DO_XYFILTER = varargin{N+1};
   case {'hsize','xyfilter_hsize'}
    XYFILT_HSIZE = varargin{N+1};
   case {'sigma','xyfilter_sigma'}
    XYFILT_SIGMA = varargin{N+1};
   case {'normalization','normalize'}
    DO_NORMALIZATION = varargin{N+1};
  end
end






% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);

fprintf('%s %s: %s(%s) USE_REALIGNED=%d, USE_PCA=%d, ',...
        datestr(now,'HH:MM:SS'),mfilename,Ses.name,grp.name,...
        USE_REALIGNED,USE_PCA);
fprintf('normalize=%s, DO_XYFILTER=%d, DO_STANDARDIZE=%d\n',...
        DO_NORMALIZATION,DO_XYFILTER,DO_STANDARDIZE);


% GET MODELs IF "MODELS" IS A CELL ARRAY OF STRINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(MODELS), MODELS = { MODELS };  end
if iscell(MODELS),
  fprintf('%s %s: loading models(%d)...',datestr(now,'HH:MM:SS'),mfilename,length(MODELS));
  TC_MODEL = [];  MODEL_IDX = [];
  ROI = load(mroi_file(Ses,grp.grproi));
  ROI = ROI.(grp.grproi);
  ROI.roinames = union(ROI.roinames,Ses.roi.names);
  for N = 1:length(MODELS),
    tmpts = mn_roits_cat(mn_roits_get(ROI,grp,MODELS{N},[],USE_PCA));
    if ~isempty(tmpts) && ~isempty(tmpts.dat),
      tmpdat = mean(double(tmpts.dat),2);
      TC_MODEL = cat(2,TC_MODEL,tmpdat);
      MODEL_IDX(end+1) = N;
      fprintf('%s.',MODELS{N});
    end
  end
  MODELS = MODELS(MODEL_IDX);
  clear ROI MODEL_IDX tmpdat tmpts;
  fprintf(' done.\n');
else
  TC_MODEL = double(MODELS);
  MODELS = {};
  for N = 1:size(TC_MODEL),
    MODELS{N} = sprintf('model%d',N);
  end
end


% LOAD GLOBAL TIME COURSE IF NEEDED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(DO_NORMALIZATION) || any(strcmpi(DO_NORMALIZATION,{'none','no'}))
  TC_NORM = [];
else
  %TC_NORM = load('tcglobal.mat',grp.name);
  %TC_NORM = TC_NORM.(grp.name);
  tmpsig.session = Ses.name;
  tmpsig.grpname = grp.name;
  tmpsig.dat = rand(size(TC_MODEL,1),1);
  tmpsig.dx  = 1;
  [tmpsig TC_NORM] = mnnormalize(tmpsig,DO_NORMALIZATION);
  %TC_NORM = mn_roits_cat(mn_roits_get(Ses,grp,DO_NORMALIZATION,[]));
  %if ~isvector(TC_NORM.dat),
  %  TC_NORM.dat = nanmean(TC_NORM.dat,2);
  %end
  %keyboard
end



% DO NORMALIZATION FOR MODELS, IF THEY COME FROM ROIs %%%%%%%%%%%%%%%%%%%%%%%%%%
if iscell(MODELS) && isfield(TC_NORM,'dat') && ~isempty(TC_NORM.dat)
  for N = 1:size(TC_MODEL,2),
    TC_MODEL(:,N) = TC_MODEL(:,N) ./ TC_NORM.dat;
  end
end



% MAKE SURE THAT MODEL TIME COURSE HAVE "CONSTANT" components %%%%%%%%%%%%%%%%%%
CONSTANT_FOUND = 0;
for N = 1:size(TC_MODEL,2),
  if all(TC_MODEL(:,N) == TC_MODEL(1,N)),
    CONSTANT_FOUND = 1;  break;
  end
end
if CONSTANT_FOUND == 0,
  TC_MODEL(:,end+1) = 1;
  MODELS{end+1} = 'const';
end


% STANDARDIZE MODELS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if DO_STANDARDIZE > 0,
  for N = 1:size(TC_MODEL,2),
    if all(TC_MODEL(:,N) == TC_MODEL(1,N)),
      % no need to standardize a const.
      continue;
    end
    TC_MODEL(:,N) = (TC_MODEL(:,N) - mean(TC_MODEL(:,N),1)) / std(TC_MODEL(:,N),[],1);
  end
end



% LOAD ANATOMY TO GET IMAGE DIMENSIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
anaImg = anaload(Ses,grp);
nX = size(anaImg.dat,1);  nY = size(anaImg.dat,2);  nS = size(anaImg.dat,3);
nT = length(grp.exps);
clear anaImg;

if DEBUG,
  %SLICES = 100:120;
  SLICES = 51;
else
  SLICES = 1:nS;
end


% Use the rank-revealing QR to remove dependent columns of X. %%%%%%%%%%%%%%%%%%
% GET DEGREES OF FREEDOM FOR MODEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[Q,R,perm] = qr(TC_MODEL,0);
p = sum(abs(diag(R)) > max(size(size(TC_MODEL)))*eps(R(1)));
DEG_FREEDOM = max(0,size(TC_MODEL,1)-p);      % Residual degrees of freedom



BETA  = zeros(nX,nY,nS,size(TC_MODEL,2));
SSE   = zeros(nX,nY,nS);
SSR   = zeros(nX,nY,nS);
SST   = zeros(nX,nY,nS);
MSE   = zeros(nX,nY,nS);
TVAL  = zeros(nX,nY,nS,size(TC_MODEL,2));
TPVAL = zeros(size(TVAL));
FVAL  = zeros(nX,nY,nS);
FPVAL = zeros(size(FVAL));


% RUN MULTI-REGRESSION ANALYSIS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('%s %s: multi-regression',datestr(now,'HH:MM:SS'),mfilename);
if CONSTANT_FOUND > 0,
  fprintf('(%d)\n ',size(TC_MODEL,2));
else
  fprintf('(%d+const)\n ',size(TC_MODEL,2)-1);
end

for iSlice = SLICES,
  fprintf('.');
  [tcImg, matfile] = mn_tcslice_load(Ses,grp,iSlice,USE_REALIGNED);
  if USE_PCA > 0,
    y = double(tcImg.pca_denoised);
  else
    y  = double(tcImg.dat);
  end

  % Do normalization if required.
  if isfield(TC_NORM,'dat') && ~isempty(TC_NORM.dat),
    y = subDoNormalize(y,TC_NORM.dat);
  end
  % Do xy-filtering if required.
  if DO_XYFILTER > 0,
    y = subDoXYFilter(y,XYFILT_HSIZE,XYFILT_SIGMA);
  end
  
  % 29.06.05 YM: I should not standardize "data", since it makes high coef. everywhere...
  % Do standardization
  %if DO_STANDARDIZE,
  %  y = subDoStandardize(y);
  %end

  % convert dimension for regress().
  y  = reshape(y,[nX*nY*1, nT]);  % (x,y,s,t) --> (xys,t)
  y  = permute(y,[2 1]);          % (xys,t)   --> (t,xys)
  
  stats = subDoRegress(y,TC_MODEL,nX,nY);
  
  if SAVEAS_MATFILE > 0,
    BETA(:,:,iSlice,:)  = stats.beta;
    SSE(:,:,iSlice)     = stats.sse;
    SSR(:,:,iSlice)     = stats.ssr;
    SST(:,:,iSlice)     = stats.sst;
    MSE(:,:,iSlice)     = stats.mse;
    TVAL(:,:,iSlice,:)  = stats.tstat.t;
    TPVAL(:,:,iSlice,:) = stats.tstat.pval;
    FVAL(:,:,iSlice)    = stats.fstat.f;
    FPVAL(:,:,iSlice)   = stats.fstat.pval;
  else
    % make "MULREG" structure
    MULREG.normalize     = DO_NORMALIZATION;
    MULREG.xyfilter      = DO_XYFILTER;
    MULREG.xyfilt_hsize  = XYFILT_HSIZE;
    MULREG.xyfilt_sigma  = XYFILT_SIGMA;
    %MULREG.standardize   = DO_STANDARDIZE;
    MULREG.use_pca       = USE_PCA;
    MULREG.tag           = MODELS;
    MULREG.model.dat     = TC_MODEL;
    MULREG.model.Q       = stats.Q;
    MULREG.model.R       = stats.R;
    MULREG.dfe           = stats.dfe;
    MULREG.dfr           = stats.dfr;
    MULREG.beta          = stats.beta;
    MULREG.sse           = stats.sse;
    MULREG.ssr           = stats.ssr;
    MULREG.sst           = stats.sst;
    MULREG.mse           = stats.mse;
    MULREG.xtxi          = stats.xtxi;
    MULREG.tstat         = stats.tstat;
    MULREG.fstat         = stats.fstat;
  
    % save it
    %if DEBUG == 0,
      tcImg.regress = MULREG;
      save(matfile,'tcImg');
    %end
  end

  if mod(iSlice,50) == 0, fprintf(' %d\n ',iSlice);  end
  
end


% make a sturcture for output
STATS = {};
STATS.session = Ses.name;
STATS.grpname = grp.name;
STATS.ExpNo   = int16(grp.exps);
STATS.mapname = 'mulregress';
STATS.datname = 'Fstat';
STATS.dat     = FVAL;			% F statistics
STATS.p       = FPVAL;			% p value
STATS.tag     = MODELS;
STATS.model.dat     = single(TC_MODEL);	% to save memory
STATS.model.Q       = stats.Q;
STATS.model.R       = stats.R;
STATS.dfe           = stats.dfe;
STATS.dfr           = stats.dfr;
STATS.beta          = BETA;
STATS.sse           = SSE;
STATS.ssr           = SSR;
STATS.sst           = SST;
STATS.mse           = MSE;
STATS.xtxi          = stats.xtxi;
STATS.tstat.df      = stats.dfe;
STATS.tstat.t       = single(TVAL);	% to save memory
STATS.tstat.p       = TPVAL;
STATS.flags.use_realigned = USE_REALIGNED;
STATS.flags.use_pca       = USE_PCA;
STATS.flags.normalize     = DO_NORMALIZATION;
STATS.flags.xyfilter      = DO_XYFILTER;
STATS.flags.xyfilt_hsize  = XYFILT_HSIZE;
STATS.flags.xyfilt_sigma  = XYFILT_SIGMA;


if nargout,
  varargout{1} = STATS;
else
  if SAVEAS_MATFILE > 0,
    matfile = sprintf('glm_pca(%d)_normalize(%s)_xyfilter(%d)_regress.mat',...
                      USE_PCA,DO_NORMALIZATION,DO_XYFILTER);
    fprintf(' saving to ''%s''...',matfile);
    save(matfile,'STATS');
  end
end


fprintf('\n%s %s done.\n',datestr(now,'HH:MM:SS'),mfilename);



if nargout == 0 && any(SAVEAS_MATFILE)
  REGFILE = matfile;
  CONTVEC = zeros(1,size(TC_MODEL,2));
  for N = 1:size(TC_MODEL,2)-1,
    CONTVEC(:) = 0;
    CONTVEC(N) = 1;
    savefile = sprintf('glm_pca(%d)_normalize(%s)_xyfilter(%d)_model(%d).mat',...
                       USE_PCA,DO_NORMALIZATION,DO_XYFILTER,N);
    mnglm(Ses,grp,CONTVEC,REGFILE,'savefile',savefile);
  end
end




return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNTION to normalize data
function y = subDoNormalize(y,NORMDAT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for iT = 1:size(y,4),
  y(:,:,:,iT) = y(:,:,:,iT) / NORMDAT(iT);
end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNTION to apply XY filter
function y = subDoXYFilter(y,HSIZE,SIGMA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
h = fspecial('gaussian',HSIZE,SIGMA);

for iSlice = 1:size(y,3),
  for iT = 1:size(y,4),
    y(:,:,iSlice,iT) = filter2(h,y(:,:,iSlice,iT),'same');
  end
end
    
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNTION to standardize
function y = subDoStandardize(y)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tmpm = mean(y,4);
tmps = std(y,[],4);
tmps(tmps(:)==0) = 1;	% to avoid zero divide

tmpm = repmat(tmpm,[1 1 1 size(y,4)]);
tmps = repmat(tmps,[1 1 1 size(y,4)]);

y = (y - tmpm) ./ tmps;

    
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to do multiple linear regression
function stats = subDoRegress(y,X,nX,nY)

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % It takes forever calling Matlab's regress()...
%   BETA  = zeros(size(TC_MODEL,2),size(y,2));	% (model,xys)
%   RESI  = zeros(size(y,1),size(y,2));			% (t,xys)
  
%   RSQRD = zeros(1,size(y,2));
%   FSTAT = zeros(1,size(y,2));
%   PFULL = zeros(1,size(y,2));
%   E_ERR = zeros(1,size(y,2));

%   tic
%   for N = 1:size(y,2),
%     [b,bint,r,rint,stats] = regress(y(:,N),TC_MODEL,ALPHA);
%     BETA(:,N) = b(:);
%     RESI(:,N) = r(:);
    
%     RSQRD(N) = stats(1);
%     FSTAT(N) = stats(2);
%     PFULL(N) = stats(3);
%     E_ERR(N) = stats(4);
%   end
%   yhat = X*b;                  % Predicted responses at each data point.
%   RSS = zeros(1,size(y,2));    % Regression sum of squares.
%   TSS = zeros(1,size(y,2));    % Total sum of squares.
%   tmpm = mean(y,1);
%   for N = 1:size(y,2),
%     RSS(N) = norm(yhat(:,N) - tmpm(N))^2;
%     TSS(N) = norm(y(:,N)    - tmpm(N))^2;
%   end
  %toc
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


  %[b2,bint2,r2,rint2,stats2] = regress(y(:,1000),TC_MODEL,ALPHA);
  %[BETA,bint,RESI,rint,stats,TSTAT,RSS,TSS] = vregress(y,TC_MODEL,ALPHA);
  %RSQRD = stats(1,:);
  %FSTAT = stats(2,:);
  %PFULL = stats(3,:);
  %E_ERR = stats(4,:);


  % convert dimenstion
  %BETA  = permute(BETA, [2 1]);   % (model,xys) --> (xys,models)
  %BETA  = reshape(BETA, [nX,nY,1,size(TC_MODEL,2)]);	% (xys,models) --> (x,y,s,models)
  %TSTAT = permute(TSTAT,[2 1]);   % (model,xys) --> (xys,models)
  %TSTAT = reshape(TSTAT,[nX,nY,1,size(TC_MODEL,2)]);	% (xys,models) --> (x,y,s,models)

  %RESI  = permute(RESI, [2 1]);	% (t,xys) --> (xys,t)
  %RESI  = reshape(RESI, [nX,nY,1,size(y,1)]);	% (xys,t) --> (x,y,s,t)
  
  %RSQRD = reshape(RSQRD,[nX,nY,1]);		% (1,xys) --> (x,y,s)
  %FSTAT = reshape(FSTAT,[nX,nY,1]);
  %PFULL = reshape(PFULL,[nX,nY,1]);
  %E_ERR = reshape(E_ERR,[nX,nY,1]);

  %TSS   = reshape(TSS,  [nX,nY,1]);


  nModels = size(X,2);  nT = size(X,1);
  stats = mulregress(y,X);
  stats.beta       = reshape(permute(stats.beta,[2,1]), [nX,nY,1,nModels]);
  stats.yhat       = reshape(permute(stats.yhat,[2,1]), [nX,nY,1,nT]);
  stats.r          = reshape(permute(stats.r,   [2,1]), [nX,nY,1,nT]);
  stats.ymean      = reshape(stats.ymean,[nX,nY,1]);
  stats.sse        = reshape(stats.sse,  [nX,nY,1]);
  stats.ssr        = reshape(stats.ssr,  [nX,nY,1]);
  stats.sst        = reshape(stats.sst,  [nX,nY,1]);
  stats.mse        = stats.sse ./ stats.dfe;
  stats.tstat.se   = reshape(permute(stats.tstat.se,  [2,1]), [nX,nY,1,nModels]);
  stats.tstat.t    = reshape(permute(stats.tstat.t,   [2,1]), [nX,nY,1,nModels]);
  stats.tstat.pval = reshape(permute(stats.tstat.pval,[2,1]), [nX,nY,1,nModels]);
  stats.fstat.f    = reshape(stats.fstat.f,    [nX,nY,1]);
  stats.fstat.pval = reshape(stats.fstat.pval, [nX,nY,1]);

return;
