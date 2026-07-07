function mnttest2(SESSION,GRPNAME,TWIN1,TWIN2,TAIL)
%MNTTEST2 - Applies 2 sample T-test to tcImg in TC_SLICE_REALINGED.
%  MNTTEST2(SEESION,GRPNAME) applies 2 sample T-test to tcImg in TC_SLICE_REALIGNED.
%
%  EXAMPLE :
%    >> mnttest2('rat7tkw1','mdeftinj')
%
%  NOTE :
%    TAIL='both'  :  mean(dat(TWIN1)) ~= mean(dat(TWIN2))
%    TAIL='right' :  mean(dat(TWIN1)) <  mean(dat(TWIN2))
%    TAIL='left'  :  mean(dat(TWIN1)) >  mean(dat(TWIN2))
%
%    Control flags/settings can be set in the description file like
%     ANAP.mnttest2.use_realigned  = 1;
%     ANAP.mnttest2.use_pca        = 0;
%     ANAP.mnttest2.normalize      = 'global';	% none|global|regress|matfile
%     ANAP.mnttsst2.normalize_stat = 'mean';    % mean|median
%     ANAP.mnttsst2.normalize_ignore_outliers = 0;
%     ANAP.mnttest2.smooth         = 0;
%     ANAP.mnttest2.twin1          = [];
%     ANAP.mnttest2.twin2          = [];
%     ANAP.mnttest2.tail           = 'right';     % both|right|left
%
%  VERSION :
%    0.90 16.06.05 YM  pre-release
%    0.91 22.06.05 YM  supports normalization.
%    0.92 23.06.05 YM  bug fix on normalization, supports XY smoothing.
%    0.93 06.07.05 YM  saves data not into tcImg but into a mapfile, for MNVIEW().
%    0.94 20.03.08 YM  'normalize' can be as a matlab file.
%    0.95 21.04.08 YM  TAIL is the same meaning as mnttest().
%    0.96 31.08.10 YM  more options for normalization
%
%  See also MNTTEST MNVIEW, MNSEE_TTEST, MNDENOISE_PCA, MN_ROITS_TTEST MNNORMALIZE

if nargin < 2,  help mnttest2; return;  end

if nargin < 3,  TWIN1 = [];  end
if nargin < 4,  TWIN2 = [];  end
if nargin < 5,  TAIL  = '';  end


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

% params for normalization
NORM_STAT        = 'mean';   % keep as 'mean' for compatibility
NORM_IGNORE_OUTLIERS = 0;    % keep as zero for compatibility


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);
anap = getanap(Ses,grp);


% update conrol flags
if isfield(anap,'mnttest2'),
  tmpanap = anap.mnttest2;
  if isfield(tmpanap,'use_realigned') && ~isempty(tmpanap.use_realigned),
    USE_REALIGNED = tmpanap.use_realigned;
  end
  if isfield(tmpanap,'use_pca') && ~isempty(tmpanap.use_pca),
    USE_PCA = tmpanap.use_pca;
  end
  if isfield(tmpanap,'normalize') && ~isempty(tmpanap.normalize),
    DO_NORMALIZATION = tmpanap.normalize;
  end
  if isfield(tmpanap,'normalize_stat') && ~isempty(tmpanap.normalize_stat),
    NORM_STAT = tmpanap.normalize_stat;
  end
  if isfield(tmpanap,'normalize_ignore_outliers') && ~isempty(tmpanap.normalize_ignore_outliers),
    NORM_IGNORE_OUTLIERS = tmpanap.normalize_ignore_outliers;
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
  if isfield(tmpanap,'twin1') && isempty(TWIN1),
    TWIN1 = tmpanap.twin1;
  end
  if isfield(tmpanap,'twin2') && isempty(TWIN2),
    TWIN2 = tmpanap.twin2;
  end
  if isfield(tmpanap,'tail') && isempty(TAIL),
    TAIL = tmpanap.tail;
  end
  clear tmpanap;
end


switch lower(Ses.name),
 case {'m02th1'}
  if isempty(TWIN1),  TWIN1 = [ 1:20];  end
  if isempty(TWIN2),  TWIN2 = [61:80];  end
 case {'d03se1'}
  %if isempty(TWIN1),  TWIN1 = [ 1:12];  end
  %if isempty(TWIN2),  TWIN2 = [20:31];  end
  %if isempty(TWIN1),  TWIN1 = [ 1:5];  end
  %if isempty(TWIN2),  TWIN2 = [20:25];  end
  if isempty(TWIN1),  TWIN1 = [ 1:7];  end
  if isempty(TWIN2),  TWIN2 = [26:32];  end
 case {'o02wu1'}
  tmpt = mn_exptime(Ses,grp);
  if isempty(TWIN1),
    tmpidx = find(tmpt < 24);
    TWIN1 = [min(tmpidx):max(tmpidx)];
  end
  if isempty(TWIN2),
    tmpidx = find(tmpt > 24);
    TWIN2 = [min(tmpidx):max(tmpidx)];
  end
end

if isempty(TWIN1) | isempty(TWIN2),
  fprintf('%s ERROR: unknown session, please add ANAP.%s.twin1/twin2 in %s.m\n',...
          mfilename,mfilename,Ses.name);
  return;
end
if isempty(TAIL),  TAIL = 'right';  end


fprintf('%s %s: %s %s USE_REALIGNED=%d, USE_PCA=%d, DO_NORMALIZATION=%s(%s,outliers=%g), DO_SMOOTH=%d(hsz=%g,s=%g)\n',...
        datestr(now,'HH:MM:SS'),mfilename,Ses.name,grp.name,...
        USE_REALIGNED,USE_PCA,DO_NORMALIZATION,NORM_STAT,NORM_IGNORE_OUTLIERS,...
        DO_SMOOTH,SMOOTH_HSIZE,SMOOTH_SIGMA);


% LOADING ANATOMY DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('%s %s: getting dimension from ana...',datestr(now,'HH:MM:SS'),mfilename);
anaImg = anaload(Ses,grp);
nX = size(anaImg.dat,1);  nY = size(anaImg.dat,2);  nS = size(anaImg.dat,3);
nT = length(grp.exps);

clear anaImg;
fprintf('[x y slice time]=[%d %d %d %d]\n',nX,nY,nS,nT);




TSTAT = zeros(nX,nY,nS);
PVAL  = zeros(nX,nY,nS);
% RUN T-TEST AND SAVE THE RESULT AS .ttest FIELD IN tcImg
fprintf('%s %s: 2 sample(%s),[%d-%d] vs [%d-%d]\n ',...
        datestr(now,'HH:MM:SS'),mfilename,...
        TAIL,TWIN1(1),TWIN1(end),TWIN2(1),TWIN2(end));

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
    % normalize or convet into int16 to double precision.
    % do not apply normalization to "tcImg" since it is saved later.
    if ~isempty(DO_NORMALIZATION) && ~strcmpi(DO_NORMALIZATION,'none'),
      tcProc = mnnormalize(tcImg,DO_NORMALIZATION,...
                           'NORM_STAT',NORM_STAT,'IGNORE_OUTLIERS',NORM_IGNORE_OUTLIERS);
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
  fprintf(' ttest2...');
  %tmpttest = subDoTTest2(tcAll,USE_PCA,TWIN1,TWIN2,TAIL);	% one-time cause memory problem...
  %TSTAT = tmpttest.tstat;
  %PVAL  = tmpttest.p;
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
    % apply T-test
    if SAVEAS_MATFILE > 0,
      tmpttest = subDoTTest2(tcProc,USE_PCA,TWIN1,TWIN2,TAIL);
      TSTAT(:,:,iSlice) = tmpttest.tstat;
      PVAL(:,:,iSlice)  = tmpttest.p;
    end
  end
  if USE_TEMP_FILE > 0,  rmdir(TMPDIR,'s');  end
else
  fprintf('sli: ');
  for iSlice = 1:nS,
    fprintf('.');
    [tcImg, matfile] = mn_tcslice_load(Ses,grp,iSlice,USE_REALIGNED);

    % temporal average to improve S/N
    if 0,
      % tcProc.dat = (x,y,z,t)
      tmpsz  = size(tcProc.dat);
      tcProc.dat = reshape(tcProc.dat,[prod(tmpsz(1:3)) tmpsz(4)]);
      TMPDAT = tcProc.dat;
      tcProc.dat = double(tcProc.dat);
      for T = TWIN1,
        if T+1 > TWIN1(end),
          tcProc.dat(:,T) = nanmean(TMPDAT(:,[T TWIN1(1) TWIN1(2)]),2);
        elseif T+2 > TWIN1(end)
          tcProc.dat(:,T) = nanmean(TMPDAT(:,[T T+1 TWIN1(1)]),2);
        else
          tcProc.dat(:,T) = nanmean(TMPDAT(:,[T T+1 T+2]),2);
        end
      end
      for T = TWIN2,
        if T+1 > TWIN2(end),
          tcProc.dat(:,T) = nanmean(TMPDAT(:,[T TWIN1(1) TWIN2(2)]),2);
        elseif T+2 > TWIN2(end)
          tcProc.dat(:,T) = nanmean(TMPDAT(:,[T T+1 TWIN2(1)]),2);
        else
          tcProc.dat(:,T) = nanmean(TMPDAT(:,[T T+1 T+2]),2);
        end
      end
      tcProc.dat = reshape(tcProc.dat,tmpsz);
      clear tmpsz TMPDAT;
    end
    
    
    % normalize or convet into int16 to double precision.
    % do not apply normalization to "tcImg" since it is saved later.
    if ~isempty(DO_NORMALIZATION) && ~strcmpi(DO_NORMALIZATION,'none'),
      tcProc = mnnormalize(tcImg,DO_NORMALIZATION,...
                           'NORM_STAT',NORM_STAT,'IGNORE_OUTLIERS',NORM_IGNORE_OUTLIERS);
    else
      tcProc = tcImg;
      tcProc.dat = double(tcProc.dat);
      if isfield(tcProc,'pca_denoised'),
        tcProc.pca_denoised = double(tcProc.pca_denoised);
      end
    end
    
    
    
    
    if DO_XYFILTER > 0,
      tcProc = subXYFilter(tcProc,XYFILT_HSIZE,XYFILT_SIGMA);
    end
    % apply T-test
    if SAVEAS_MATFILE > 0,
      tmpttest = subDoTTest2(tcProc,USE_PCA,TWIN1,TWIN2,TAIL);
      TSTAT(:,:,iSlice) = tmpttest.tstat;
      PVAL(:,:,iSlice)  = tmpttest.p;
    else
      tmpttest = subDoTTest2(tcProc,0,TWIN1,TWIN2,TAIL);
      tmpttest.normalize = DO_NORMALIZATION;
      tmpttest.smooth  = DO_SMOOTH;
      tcImg.ttest = tmpttest;
      if isfield(tcImg,'pca_denoised') & ~isempty(tcImg.pca_denoised),
        tmpttest = subDoTTest2(tcProc,1,TWIN1,TWIN2,TAIL);
        tcImg.ttest.pca_p = tmpttest.p;
        tcImg.ttest.pca_tstat = tmpttest.tstat;
      end
      if USE_PCA > 0,
        TSTAT(:,:,iSlice) = tcImg.ttest.pca_tstat;
        PVAL(:,:,iSlice)  = tcImg.ttest.pca_p;
      else
        TSTAT(:,:,iSlice) = tcImg.ttest.tstat;
        PVAL(:,:,iSlice)  = tcImg.ttest.p;
      end
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
STATS.mapname = 'ttest2';
STATS.datname = 'tstat';
STATS.tsel1   = tmpttest.tsel1;
STATS.tsel2   = tmpttest.tsel2;
STATS.tail    = TAIL;
STATS.df      = tmpttest.df;	% degrees of freedom
STATS.dat     = TSTAT;			% t statistics
STATS.p       = PVAL;			% p value
STATS.flags.use_realigned  = USE_REALIGNED;
STATS.flags.use_pca        = USE_PCA;
STATS.flags.normalize      = DO_NORMALIZATION;
STATS.flags.normalize_stat = NORM_STAT;
STATS.flags.normalize_ignore_outlisers = NORM_IGNORE_OUTLIERS;
STATS.flags.smooth         = DO_SMOOTH;
STATS.flags.smooth_hsize   = SMOOTH_HSIZE;
STATS.flags.smooth_sigma   = SMOOTH_SIGMA;


if nargout,
  varargout{1} = STATS;
else
  if SAVEAS_MATFILE > 0,
    matfile = sprintf('ttest2_realign(%d)_pca(%d)_normalize(%s-%s-%g)_smooth(%d).mat',...
                      USE_REALIGNED,USE_PCA,DO_NORMALIZATION,NORM_STAT,NORM_IGNORE_OUTLIERS,DO_SMOOTH);
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
% SUBFUNCTION to apply 2 samples T-test for roiTs
function TTEST = subDoTTest2(tcImg,USE_PCA,TWIN1,TWIN2,TAIL)
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

%tsel1 = [TWIN1(1):TWIN1(2)];
%tsel2 = [TWIN2(1):TWIN2(2)];
tsel1 = TWIN1;
tsel2 = TWIN2;


y = tmpdat(tsel1,:);
x = tmpdat(tsel2,:);


% ttest2(x,y,alpha,tail)
% 'both'  : Means are not equal (two-tailed test)
% 'right' : Mean of x is greater than mean of y (right-tail test)
% 'left'  : Mean of x is less than mean of y (left-tail test)


% to avoid error of zero division
idx = find(var(x) ~= 0 | var(y) ~= 0);
nvoxels = size(tmpdat,2);
P = ones(1,nvoxels);
T = zeros(1,nvoxels);
if ~isempty(idx),
  [h, signif, ci, stat] = ttest2(x(:,idx),y(:,idx), 0.01, TAIL);
  P(idx) = signif(:);
  T(idx) = stat.tstat(:);
else
  % to avoid error, when getting stat.df
  x = rand(size(x,1),1);
  y = rand(size(y,1),1);
  x = (x - mean(x(:))) / std(x(:));
  y = (y - mean(y(:))) / std(y(:));
  [h,signif,ci,stat] = ttest2(x,y, 0.01, TAIL);
end


%TTEST.dat   = datname;
TTEST.tsel1 = int16(tsel1);
TTEST.tsel2 = int16(tsel2);
TTEST.tail  = TAIL;
TTEST.df    = stat.df(1);
TTEST.p     = reshape(P,szdat(1:end-1));
TTEST.tstat = reshape(T,szdat(1:end-1));


return;

