function mncorana(SESSION,GRPNAME)
%MNCORANA - Applies correlation analysis to tcImg in TC_SLICE_REALINGED.
%  MNCORANA(SEESION,GRPNAME) applies correlation analysis to tcImg in TC_SLICE_REALIGNED.
%
%  NOTE :
%
%    Control flags/settings can be set in the description file like
%     ANAP.mncorana.model         = [0 0 1 1 0 ... 0];
%     ANAP.mncorana.use_realigned = 1;
%     ANAP.mncorana.use_pca       = 0;
%     ANAP.mncorana.normalize     = 'global';	% none|global|regress
%     ANAP.mncorana.smooth        = 0;
%
%  VERSION :
%    0.90 04.09.06 YM  pre-release, modified from mnttest().
%
%  See also MNTTEST, MNVIEW, MNDENOISE_PCA

if nargin < 2,  help mncorana; return;  end



% CONTROL FLAGS/SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
USE_REALIGNED    = 1;
USE_PCA          = 0;
DO_NORMALIZATION = 'global';	% none,global,regress
DO_XYFILTER      = 0;
DO_SMOOTH        = 1;
SAVEAS_MATFILE   = 1;

% params for XYZ filtering
SMOOTH_HSIZE     = 3;
SMOOTH_SIGMA     = 0.8;




% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);

% update conrol flags
if isfield(Ses.anap,'mncorana'),
  if isfield(Ses.anap.mncorana,'use_realigned') & ~isempty(Ses.anap.mncorana.use_realigned),
    USE_REALIGNED = Ses.anap.mncorana.use_realigned;
  end
  if isfield(Ses.anap.mncorana,'use_pca') & ~isempty(Ses.anap.mncorana.use_pca),
    USE_PCA = Ses.anap.mncorana.use_pca;
  end
  if isfield(Ses.anap.mncorana,'normalize') & ~isempty(Ses.anap.mncorana.normalize),
    DO_NORMALIZATION = Ses.anap.mncorana.normalize;
  end
  if isfield(Ses.anap.mncorana,'smooth') & ~isempty(Ses.anap.mncorana.smooth),
    DO_SMOOTH = Ses.anap.mncorana.smooth;
  end
end


if ~isfield(Ses.anap,'mncorana') | ~isfield(Ses.anap.mncorana,'model'),
  fprintf('%s ERROR: unknown model, please add ANAP.mncorana.model in %s.m\n',...
          mfilename,Ses.name);
  return;
end

if ischar(Ses.anap.mncorana.model),
  MODEL = mn_roits_get(SESSION,GRPNAME,MODEL);
  if ~isempty(DO_NORMALIZATION) & ~strcmpi(DO_NORMALIZATION,'none'),
    MODEL = mnnormalize(MODEL,DO_NORMALIZATION);
  end
  if size(MODEL.dat,2) > 1,
    MODEL.dat = mean(MODEL.dat,2);
  end
else
  MODEL.name = 'user';
  MODEL.dat  = Ses.anap.mncorana.model;
end
MODEL.dat = double(MODEL.dat);


fprintf('%s %s: %s %s USE_REALIGNED=%d, USE_PCA=%d, DO_NORMALIZATION=%s, DO_SMOOTH=%d\n',...
        datestr(now,'HH:MM:SS'),mfilename,Ses.name,grp.name,...
        USE_REALIGNED,USE_PCA,DO_NORMALIZATION,DO_SMOOTH);


% LOADING ANATOMY DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('%s %s: getting dimension from ana...',datestr(now,'HH:MM:SS'),mfilename);
anaImg = anaload(Ses,grp);
nX = size(anaImg.dat,1);  nY = size(anaImg.dat,2);  nS = size(anaImg.dat,3);
nT = length(grp.exps);

clear anaImg;
fprintf('[x y slice time]=[%d %d %d %d]\n',nX,nY,nS,nT);


if length(MODEL.dat) ~= nT,
  fprintf('%s ERROR: model(tlen=%d) must be the same time-length as data, please check ANAP.mncorana.model in %s.m\n',...
          mfilename,lengh(MODEL.dat),Ses.name);
  return;
end


RVAL  = zeros(nX,nY,nS);
PVAL  = zeros(nX,nY,nS);
% RUN CORR.ANA AND SAVE THE RESULT AS A STATISTICAL MAP
fprintf('%s %s: corr.ana(%s)\n ',...
        datestr(now,'HH:MM:SS'),MODEL.name);

if DO_SMOOTH > 0,
  tcAll = [];
  if USE_PCA > 0,
    datname = 'pca_denoised';
  else
    datname = 'dat';
  end
  USE_TEMP_FILE = strcmpi(Ses.name,'m02th1');
  if USE_TEMP_FILE,
    TMPDIR = sprintf('./temp%s',datestr(now,'yymmddHHMM'));
    if ~exist(TMPDIR,'dir'),  mkdir(pwd,TMPDIR);  end
  end
  for iSlice = 1:nS,
    fprintf('.');
    [tcImg, matfile] = mn_tcslice_load(Ses,grp,iSlice,USE_REALIGNED);
    % normalize or convet into int16 to double precision.
    % do not apply normalization to "tcImg" since it is saved later.
    if ~isempty(DO_NORMALIZATION) & ~strcmpi(DO_NORMALIZATION,'none'),
      tcProc = mnnormalize(tcImg,DO_NORMALIZATION);
    else
      tcProc = tcImg;
      tcProc.dat = double(tcProc.dat);
      if isfield(tcProc,'pca_denoised'),
        tcProc.pca_denoised = double(tcProc.pca_denoised);
      end
    end
    if isempty(tcAll),
      tcAll = tcProc;
      tcAll.dat = [];   tcAll.pca_denoised = [];
      if USE_TEMP_FILE == 0,
        tcAll.(datname) = zeros(nX,nY,nS,nT);
      end
    end
    if USE_TEMP_FILE == 0,
      tcAll.(datname)(:,:,iSlice,:) = tcProc.(datname);
    else
      for iT = 1:nT,
        tmpfile = sprintf('%s/temp%04d%04d.img',TMPDIR,iSlice,iT);
        fid = fopen(tmpfile,'wb');
        fwrite(fid,tcProc.(datname)(:,:,1,iT),'double');
        fclose(fid);
      end
    end
    if mod(iSlice,50) == 0, fprintf(' %d\n ',iSlice);  end
  end
  fprintf(' smoothing...');	% do time to time to avoid memory problem
  tmpsig = tcAll;
  for iT = 1:nT,
    if USE_TEMP_FILE == 0,
      tmpsig.(datname) = tcAll.(datname)(:,:,:,iT);
      tmpsig = subSmooth(tmpsig,SMOOTH_HSIZE,SMOOTH_SIGMA);
      tcAll.(datname)(:,:,:,iT) = tmpsig.(datname);
    else
      VOLDAT = zeros(nX,nY,nS);
      for iSlice = 1:nS,
        tmpfile = sprintf('%s/temp%04d%04d.img',TMPDIR,iSlice,iT);
        fid = fopen(tmpfile,'rb');
        tmpdat = reshape(fread(fid,inf,'double'),[nX nY]);
        fclose(fid);
        VOLDAT(:,:,iSlice) = tmpdat;
      end
      tmpsig.(datname) = VOLDAT;
      tmpsig = subSmooth(tmpsig,SMOOTH_HSIZE,SMOOTH_SIGMA);
      for iSlice = 1:nS,
        tmpfile = sprintf('%s/temp%04d%04d.img',TMPDIR,iSlice,iT);
        fid = fopen(tmpfile,'wb');
        fwrite(fid,tmpsig.(datname)(:,:,iSlice),'double');
        fclose(fid);
      end
    end
  end
  %tcAll = subSmooth(tcAll,SMOOTH_HSIZE,SMOOTH_SIGMA);
  fprintf(' corr...');
  for iSlice = 1:nS,
    if USE_TEMP_FILE == 0,
      tcProc.(datname) = tcAll.(datname)(:,:,iSlice,:);
    else
      tcProc.(datname) = zeros(nX,nY,1,nT);
      for iT = 1:nT,
        tmpfile = sprintf('%s/temp%04d%04d.img',TMPDIR,iSlice,iT);
        fid = fopen(tmpfile,'rb');
        tmpdat = reshape(fread(fid,inf,'double'),[nX nY]);
        fclose(fid);
        tcProc.(datname)(:,:,1,iT) = tmpdat;
      end
    end
    % apply corr ana
    if SAVEAS_MATFILE > 0,
      tmpcorr = subDoCorr(tcProc,USE_PCA,MODEL);
      RVAL(:,:,iSlice) = tmpcorr.r;
      PVAL(:,:,iSlice)  = tmpcorr.p;
    end
  end
  if USE_TEMP_FILE > 0,  rmdir(TMPDIR,'s');  end
else
  for iSlice = 1:nS,
    %for iSlice = 95:96
    fprintf('.');
    [tcImg, matfile] = mn_tcslice_load(Ses,grp,iSlice,USE_REALIGNED);
    % normalize or convet into int16 to double precision.
    % do not apply normalization to "tcImg" since it is saved later.
    if ~isempty(DO_NORMALIZATION) & ~strcmpi(DO_NORMALIZATION,'none'),
      tcProc = mnnormalize(tcImg,DO_NORMALIZATION);
    else
      tcProc = tcImg;
      tcProc.dat = double(tcProc.dat);
      if isfield(tcProc,'pca_denoised'),
        tcProc.pca_denoised = double(tcProc.pca_denoised);
      end
    end
    if DO_XYFILTER > 0,
      tcProc = subXYFilter(tcProc,SMOOTH_HSIZE,SMOOTH_SIGMA);
    end
    % apply corr ana
    if SAVEAS_MATFILE > 0,
      tmpcorr = subDoCorr(tcProc,USE_PCA,MODEL);
      RVAL(:,:,iSlice) = tmpcorr.r;
      PVAL(:,:,iSlice)  = tmpcorr.p;
    else
      tmpcorr = subDoCorr(tcProc,0,MODEL);
      tmpcorr.normalize = DO_NORMALIZATION;
      tmpcorr.smooth  = DO_SMOOTH;
      tcImg.corr = tmpcorr;
      if isfield(tcImg,'pca_denoised') & ~isempty(tcImg.pca_denoised),
        tmpcorr = subDoCorr(tcProc,1,MODEL);
        tcImg.corr.pca_p = tmpcorr.p;
        tcImg.corr.pca_rval = tmpcorr.r;
      end
      if USE_PCA > 0,
        RVAL(:,:,iSlice) = tcImg.corr.pca_r;
        PVAL(:,:,iSlice)  = tcImg.corr.pca_p;
      else
        RVAL(:,:,iSlice) = tcImg.corr.r;
        PVAL(:,:,iSlice)  = tcImg.corr.p;
      end
      save(matfile,'tcImg');
    end

    if mod(iSlice,50) == 0, fprintf(' %d\n ',iSlice);  end
  end
end



% make a structure for output
STATS = {};
STATS.session = Ses.name;
STATS.grpname = grp.name;
STATS.ExpNo   = int16(grp.exps);
STATS.mapname = 'corr';
STATS.datname = 'r';
STATS.dat     = RVAL;			% t statistics
STATS.p       = PVAL;			% p value
STATS.flags.use_realigned  = USE_REALIGNED;
STATS.flags.use_pca        = USE_PCA;
STATS.flags.normalize      = DO_NORMALIZATION;
STATS.flags.smooth         = DO_SMOOTH;
STATS.flags.smooth_hsize   = SMOOTH_HSIZE;
STATS.flags.smooth_sigma   = SMOOTH_SIGMA;


if nargout,
  varargout{1} = STATS;
else
  if SAVEAS_MATFILE > 0,
    matfile = sprintf('corr_realign(%d)_pca(%d)_normalize(%s)_smooth(%d).mat',...
                      USE_REALIGNED,USE_PCA,DO_NORMALIZATION,DO_SMOOTH);
    fprintf(' saving to ''%s''...',matfile);
    save(matfile,'STATS');
  end
end

fprintf('\n%s %s done.\n',datestr(now,'HH:MM:SS'),mfilename);


return;





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to apply XY filtering
function tcFilt = subXYFilter(tcImg,HSIZE,SIGMA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tcFilt = tcImg;

h = fspecial('gaussian',HSIZE,SIGMA);

if isfield(tcFilt,'dat') & ~isempty(tcFilt.dat),
  tcFilt.dat = double(tcFilt.dat);
  for iSlice = 1:size(tcFilt.dat,3),
    for iT = 1:size(tcFilt.dat,4),
      tcFilt.dat(:,:,iSlice,iT) = filter2(h,tcFilt.dat(:,:,iSlice,iT),'same');
    end
  end
end

if isfield(tcFilt,'pca_denoised') & ~isempty(tcFilt.pca_denoised),
  tcFilt.pca_denoised = double(tcFilt.pca_denoised);
  for iSlice = 1:size(tcFilt.pca_denoised,3),
    for iT = 1:size(tcFilt.pca_denoised,4),
    tcFilt.pca_denoised(:,:,iSlice,iT) = filter2(h,tcFilt.pca_denoised(:,:,iSlice,iT),'same');
    end
  end
end


  
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to apply smoothing
function tcFilt = subSmoothSPM(tcImg,HSIZE,SIGMA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tcFilt = tcImg;

siz = ([HSIZE HSIZE HSIZE]-1)/2;
x = -siz(1):siz(1);
y = -siz(2):siz(2);
z = -siz(3):siz(3);
fx = exp(-(x.*x)/(2*SIGMA*SIGMA));
fy = exp(-(y.*y)/(2*SIGMA*SIGMA));
fz = exp(-(z.*z)/(2*SIGMA*SIGMA));

fx = fx/sum(fx);  x = (length(fx)-1)/2;
fy = fx/sum(fy);  y = (length(fy)-1)/2;
fz = fx/sum(fz);  z = (length(fz)-1)/2;

if isfield(tcFilt,'dat') & ~isempty(tcFilt.dat),
  tcFilt.dat = double(tcFilt.dat);
  for iT = 1:size(tcFilt.dat,4),
    spm_conv_vol(tcImg.dat(:,:,:,iT),tcFilt.dat(:,:,:,iT),fx,fy,fz,-[x,y,z]);
  end
end

if isfield(tcFilt,'pca_denoised') & ~isempty(tcFilt.pca_denoised),
  tcFilt.pca_denoised = double(tcFilt.pca_denoised);
  for iT = 1:size(tcFilt.pca_denoised,4),
    spm_conv_vol(tcFilt.pca_denoised(:,:,:,iT),tcFilt.pca_denoised(:,:,:,iT),fx,fy,fz,-[x,y,z]);
  end
end


  
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to apply smoothing
function tcFilt = subSmooth(tcImg,HSIZE,SIGMA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tcFilt = tcImg;

siz = ([HSIZE HSIZE HSIZE]-1)/2;
[x y z] = meshgrid(-siz(1):siz(1), -siz(2):siz(2), -siz(3):siz(3));
arg = -(x.*x + y.*y + z.*z)/(2*SIGMA*SIGMA);
h = exp(arg);
h(h < eps*max(h(:))) = 0;
sumh = sum(h(:));
if sumh ~= 0, h = h/sumh;  end


if isfield(tcFilt,'dat') & ~isempty(tcFilt.dat),
  tcFilt.dat = double(tcFilt.dat);
  for iT = 1:size(tcFilt.dat,4),
    tcFilt.dat(:,:,:,iT) = convn(tcFilt.dat(:,:,:,iT),h,'same');
  end
end

if isfield(tcFilt,'pca_denoised') & ~isempty(tcFilt.pca_denoised),
  tcFilt.pca_denoised = double(tcFilt.pca_denoised);
  for iT = 1:size(tcFilt.pca_denoised,4),
    tcFilt.pca_denoised(:,:,:,iT) = convn(tcFilt.pca_denoised(:,:,:,iT),h,'same');
  end
end


  
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to apply 1 samples corr ana for roiTs
function CORR = subDoCorr(tcImg,USE_PCA,MODEL)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if USE_PCA,
  datname = 'pca_denoised';
else
  datname = 'dat';
end

szdat  = size(tcImg.(datname));   % (x,y,z,t)
tmpdat = tcImg.(datname);
if ~strcmpi(class(tmpdat),'double'),
  tmpdat = double(tmpdat);
end
tmpdat = reshape(tmpdat,[prod(szdat(1:end-1)) szdat(end)]);  % (xyz,t)
tmpdat = permute(tmpdat,[2 1]);  % (xyz,t) --> (t,xyz)

if isstruct(MODEL) & isfield(MODEL,'dat'),
  x = MODEL.dat(:);
else
  x = MODEL(:);
end

if 0,
  [R, P] = corrcoef([x(:) tmpdat]);
  R = R(1,2:end);
  P = P(1,2:end);
else
  R = zeros(1,size(tmpdat,2));
  P = ones(1,size(tmpdat,2));
  for N = 1:size(tmpdat,2),
    if ~all(tmpdat(:,N) == 0)
      [tmpr tmpp] = corrcoef(x,tmpdat(:,N));
      R(N) = tmpr(1,2);
      P(N) = tmpp(1,2);
    end
  end
end
%CORR.dat   = datname;
CORR.p = reshape(P,szdat(1:end-1));
CORR.r = reshape(R,szdat(1:end-1));


return;

