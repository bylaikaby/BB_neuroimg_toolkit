function varargout = mnsnmap(SESSION,GRPNAME,varargin)
%MNSNMAP - Creates a statistical map of SN.
%  MNSNMAP(SES,GRPNAME,...) creates a statistical map of SN.
%  Sigal to Noise ratio (SN) = mean/std
%
%  Supported options are :
%    'twin'   : time window (indices) to compute the SN map
%    'smooth' : apply spatial smoothing [0|1]
%    'hsize'  : kernel size  for spatial smoothing
%    'sigma'  : kernel sigma for spatial smoothing
%
%  Note that parameters can be set in the session file.
%    ANAP.mnsnmap.use_realigned = 1;
%    ANAP.mnsnmap.smooth        = 0;
%    ANAP.mnsnmap.twin          = [1:6];
%
%  EXAMPLE :
%    >> mnsnmap('rat361','mdeftinj','twin',[1:6])
%    >> mnview('rat361','mdeftinj')
%
%  VERSION :
%    0.90 16.09.10 YM  pre-release
%
%  See also mnview mncvmap

if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);
anap = getanap(Ses,grp);


% OPTIONS
USE_REALIGNED    = 1;
USE_PCA          = 0;
DO_XYFILTER      = 0;
DO_SMOOTH        = 0;
SAVEAS_MATFILE   = 1;
MAP_TWIN         = [];

% params for XYZ filtering
SMOOTH_HSIZE     = 3;
SMOOTH_SIGMA     = 0.8;


% check ANAP
if isfield(anap,'mnsnmap'),
  tmpanap = anap.mnsnmap;
  if isfield(tmpanap,'use_realigned') && ~isempty(tmpanap.use_realigned),
    USE_REALIGNED = tmpanap.use_realigned;
  end
  if isfield(tmpanap,'use_pca') && ~isempty(tmpanap.use_pca),
    USE_PCA = tmpanap.use_pca;
  end
  if isfield(tmpanap,'smooth') && ~isempty(tmpanap.smooth),
    DO_SMOOTH = tmpanap.smooth;
  end
  if isfield(tmpanap,'smooth_hsize') && ~isempty(tmpanap.smooth_hsize),
    SMOOTH_HSIZE = tmpanap.smooth_hsize;
  end
  if isfield(tmpanap,'smooth_sigma') && ~isempty(tmpanap.smooth_sigma),
    SMOOTH_SIGMA = tmpanap.smooth_sigma;
  end
  if isfield(tmpanap,'twin') && isempty(MAP_TWIN),
    MAP_TWIN = tmpanap.twin;
  end
  clear tmpanap;
end


% check input arguments
for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'realign','use_realigned'}
    USE_REALIGNED = varargin{N+1};
   case {'pca','use_pca'}
    USE_PCA = varargin{N+1};
   case {'smooth','xysmooth'}
    DO_SMOOTH = varargin{N+1};
   case {'hsize','xyhsize'}
    SMOOTH_HSIZE = varargin{N+1};
   case {'sigma','xysigma'}
    SMOOTH_SIGMA = varargin{N+1};
   case {'twin','period','periods'}
    MAP_TWIN = varargin{N+1};
   case {'save'}
    SAVEAS_MATFILE = varargin{N+1};
  end
end



fprintf('%s %s: %s %s USE_REALIGNED=%d, USE_PCA=%d, DO_SMOOTH=%d(hsz=%g,s=%g)\n',...
        datestr(now,'HH:MM:SS'),mfilename,Ses.name,grp.name,...
        USE_REALIGNED,USE_PCA,DO_SMOOTH,SMOOTH_HSIZE,SMOOTH_SIGMA);


% LOADING ANATOMY DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('%s %s: getting dimension from ana...',datestr(now,'HH:MM:SS'),mfilename);
anaImg = anaload(Ses,grp);
nX = size(anaImg.dat,1);  nY = size(anaImg.dat,2);  nS = size(anaImg.dat,3);
nT = length(grp.exps);

clear anaImg;
fprintf('[x y slice time]=[%d %d %d %d]\n',nX,nY,nS,nT);


SSTAT = zeros(nX,nY,nS);
PVAL  = zeros(nX,nY,nS);
% RUN ANALYSIS
fprintf('%s %s: snr [%s]\n ',...
        datestr(now,'HH:MM:SS'),mfilename,deblank(sprintf('%d ',MAP_TWIN)));

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
  fprintf('sli: ');
  for iSlice = 1:nS,
    fprintf('.');
    [tcImg, matfile] = mn_tcslice_load(Ses,grp,iSlice,USE_REALIGNED);
    tcProc = tcImg;
    tcProc.dat = double(tcProc.dat);
    if isfield(tcProc,'pca_denoised'),
      tcProc.pca_denoised = double(tcProc.pca_denoised);
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
    if mod(iSlice,50) == 0, fprintf(' %d\n      ',iSlice);  end
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
  fprintf(' snmap...');
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
    % compute SN
    if SAVEAS_MATFILE > 0,
      tmpsn = subComputeSN(tcProc,USE_PCA,MAP_TWIN);
      SSTAT(:,:,iSlice) = tmpsn.snr;
      PVAL(:,:,iSlice)  = tmpsn.p;
    end
  end
  if USE_TEMP_FILE > 0,  rmdir(TMPDIR,'s');  end
else
  fprintf('sli: ');
  for iSlice = 1:nS,
    fprintf('.');
    [tcImg, matfile] = mn_tcslice_load(Ses,grp,iSlice,USE_REALIGNED);

    tcProc = tcImg;
    tcProc.dat = double(tcProc.dat);
    
    if DO_XYFILTER > 0,
      tcProc = subXYFilter(tcProc,XYFILT_HSIZE,XYFILT_SIGMA);
    end
    % compute SN
    if SAVEAS_MATFILE > 0,
      tmpsn = subComputeSN(tcProc,USE_PCA,MAP_TWIN);
      SSTAT(:,:,iSlice) = tmpsn.snr;
      PVAL(:,:,iSlice)  = tmpsn.p;
    else
      tmpsn = subComputeSN(tcProc,0,MAP_TWIN);
      tmpsn.smooth  = DO_SMOOTH;
      tcImg.snmap = tmpsn;
      if isfield(tcImg,'pca_denoised') & ~isempty(tcImg.pca_denoised),
        tmpttest = subComputeSN(tcProc,1,MAP_TWIN);
        tcImg.snmap.pca_p   = tmpsn.p;
        tcImg.snmap.pca_snr = tmpsn.snr;
      end
      if USE_PCA > 0,
        SSTAT(:,:,iSlice) = tcImg.snmap.pca_snr;
        PVAL(:,:,iSlice)  = tcImg.snmap.pca_p;
      else
        SSTAT(:,:,iSlice) = tcImg.snmap.snr;
        PVAL(:,:,iSlice)  = tcImg.snmap.p;
      end
      SSTAT(:,:,iSlice) = tmpsn.snr;
      PVAL(:,:,iSlice)  = tmpsn.p;
      save(matfile,'tcImg');
    end
    if mod(iSlice,50) == 0, fprintf(' %d\n      ',iSlice);  end
  end
end


% make a structure for output
STATS = {};
STATS.session = Ses.name;
STATS.grpname = grp.name;
STATS.ExpNo   = int16(grp.exps);
STATS.mapname = 'snmap';
STATS.datname = 'snr';
STATS.tsel    = tmpsn.tsel;
STATS.dat     = SSTAT;			% t statistics
STATS.p       = PVAL;			% p value
STATS.flags.use_realigned  = USE_REALIGNED;
STATS.flags.smooth         = DO_SMOOTH;
STATS.flags.smooth_hsize   = SMOOTH_HSIZE;
STATS.flags.smooth_sigma   = SMOOTH_SIGMA;


if nargout,
  varargout{1} = STATS;
else
  if SAVEAS_MATFILE > 0,
    matfile = sprintf('snmap_realign(%d)_smooth(%d).mat',...
                      USE_REALIGNED,DO_SMOOTH);
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

tcFilt.dat = double(tcFilt.dat);
for iSlice = 1:size(tcFilt.dat,3),
  for iT = 1:size(tcFilt.dat,4),
    tcFilt.dat(:,:,iSlice,iT) = filter2(h,tcFilt.dat(:,:,iSlice,iT),'same');
  end
end

if isfield(tcFilt,'pca_denoised') && ~isempty(tcFilt.pca_denoised),
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

if isfield(tcFilt,'dat') && ~isempty(tcFilt.dat),
  tcFilt.dat = double(tcFilt.dat);
  for iT = 1:size(tcFilt.dat,4),
    spm_conv_vol(tcImg.dat(:,:,:,iT),tcFilt.dat(:,:,:,iT),fx,fy,fz,-[x,y,z]);
  end
end

if isfield(tcFilt,'pca_denoised') && ~isempty(tcFilt.pca_denoised),
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


if isfield(tcFilt,'dat') && ~isempty(tcFilt.dat),
  tcFilt.dat = double(tcFilt.dat);
  for iT = 1:size(tcFilt.dat,4),
    tcFilt.dat(:,:,:,iT) = convn(tcFilt.dat(:,:,:,iT),h,'same');
  end
end

if isfield(tcFilt,'pca_denoised') && ~isempty(tcFilt.pca_denoised),
  tcFilt.pca_denoised = double(tcFilt.pca_denoised);
  for iT = 1:size(tcFilt.pca_denoised,4),
    tcFilt.pca_denoised(:,:,:,iT) = convn(tcFilt.pca_denoised(:,:,:,iT),h,'same');
  end
end


  
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to compute SN
function SNMAP = subComputeSN(tcImg,USE_PCA,TWIN)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if USE_PCA,
  datname = 'pca_denoised';
else
  datname = 'dat';
end

if isempty(TWIN),
  TWIN = 1:size(tcImg.(datname),4);
end

tmpdat = tcImg.(datname)(:,:,:,TWIN);  % (x,y,z,t)
szdat  = size(tmpdat);

if ~strcmpi(class(tmpdat),'double'),
  tmpdat = double(tmpdat);
end
tmpdat = reshape(tmpdat,[prod(szdat(1:end-1)) szdat(end)]);  % (xyz,t)
tmpdat = permute(tmpdat,[2 1]);  % (xyz,t) --> (t,xyz)


tmpm = nanmean(tmpdat,1);
tmps = nanstd(tmpdat,[],1);

% avoid zero division
tmpidx = tmps < eps;
tmpm(tmpidx) = 0;
tmps(tmpidx) = 1;

S = tmpm ./ tmps;
P = zeros(size(S));


SNMAP.tsel  = TWIN;
SNMAP.p     = reshape(P,szdat(1:end-1));
SNMAP.snr   = reshape(S,szdat(1:end-1));


return;
