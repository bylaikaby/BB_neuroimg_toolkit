function varargout = mnnormalize(varargin)
%MNNORMALIZE - computes data for normalization or normalize the given signal.
%  mnnormalize(SESSION,GRPNAME) computes data for normalization and save to matfiles.
%  mnnormalize(SIG,NORM) normalize the givn signal by "NORM".
%
%  USAGE :
%    mnnormalize('o02wu1','mdeftinj');     % creating data for normalization
%    tcImg = mnnormalize(tcImg,'global');  % normalize 'tcImg' by 'global'
%
%  NOTES :
%    If memory problem, run Matlab witout java, (-nojvm).
%
%  NOTES 2: 
%    Any mat file can be used as normalization data.  The matfile should have
%    the signal structure named as the group name like following.
%       (grpname).dat  :  must be a vector, the same length as grouped scans, (grp.exps).
%    If the 'grpname' is 'mdeftinj', then it should be like
%       mdeftinj.dat = [323.32 135.23 ... 100.03].
%
%  Example : 
%    Create your own data for normalization.
%    >> mdeftinj = [];                  % createting the data (use the group name)
%    >> mdeftinj.dat = [1 2 3 ... 10];  % setting data for normalization as .dat
%    >> save('mynorm.mat','mdeftinj');  % save data as a matlab file.
%    Then edit the session file to set normalization method for any statistics.
%     ANAP.mnttest.normalize     = 'mynorm.mat';	% none|global|regress|matfile
%     or 
%     ANAP.mnttest2.normalize    = 'mynorm.mat';	% none|global|regress|matfile
%
%  VERSION :
%    0.90 12.07.05 YM   pre-release
%    0.91 19.07.05 YM   avoid memory problem of 'm02th1'.
%    0.92 20.03.08 YM   supports user-defined matfile for normalization.
%    0.93 31.08.10 YM   more options for normalization
%    0.94 17.01.12 YM   ignore pca-denoised data when not available.
%
%  See also mk_water mnttest mnttest2

if nargin < 2,  help mnnormalize;  return;  end


% calld like mnnormalize(Sig,Norm,...)
if any(issig(varargin{1})),
  Sig = varargin{1};
  NORM_STAT       = 'mean';  % kee as 'mean' for compatibility
  IGNORE_OUTLIERS = 0;       % keep as zero for compatibility
  for N = 3:2:length(varargin),
    switch lower(varargin{N})
     case {'ignore_outliers','ignoreoutliers'}
      IGNORE_OUTLIERS = varargin{N+1};
     case {'norm_stat','normstat'}
      NORM_STAT = varargin{N+1};
    end
  end
  
  if iscell(Sig),
    for N = 1:length(Sig),
      [tmpsig,NORMSIG] = subNormalize(Sig{N},varargin{2},NORM_STAT,IGNORE_OUTLIERS);
      Sig{N} = tmpsig;
    end
  else
    [Sig, NORMSIG] = subNormalize(Sig,varargin{2},NORM_STAT,IGNORE_OUTLIERS);
  end

  if nargout,
    varargout{1} = Sig;
    if nargout > 1,  varargout{2} = NORMSIG;  end
  end
  return;
end


% if isstruct(varargin{1}) && isfield(varargin{1},'dat'),
%   [Sig, NORMSIG] = subNormalize(varargin{1},varargin{2});
%   if nargout,
%     varargout{1} = Sig;
%     if nargout > 1,  varargout{2} = NORMSIG;  end
%   end
%   return;
% elseif iscell(varargin{1}),
%   Sig = varargin{1};
%   for N = 1:length(Sig),
%     [tmpsig,NORMSIG] = subNormalize(Sig{N},varargin{2});
%     Sig{N} = tmpsig;
%   end
%   if nargout,
%     varargout{1} = Sig;
%     if nargout > 1,  varargout{2} = NORMSIG;  end
%   end
%   return;
% end



% called like mnnormalize(Ses,grp) to create 'tcglobal.mat' and 'tcregress.mat'.
USE_REALIGNED = 1;
Ses = goto(varargin{1});
grp = getgrp(Ses,varargin{2});
fprintf('%s %s: %s(%s) USE_REALIGNED=%d\n',datestr(now,'HH:MM:SS'),mfilename,...
        Ses.name,grp.name,USE_REALIGNED);
subComputeGlobal(Ses,grp,USE_REALIGNED,{'brain'});
subComputeRegress(Ses,grp,USE_REALIGNED,{'brain'});

fprintf('%s %s: done.\n',datestr(now,'HH:MM:SS'),mfilename);

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to normalize "Sig" with "NormSig"
function [Sig NormSig] = subNormalize(Sig,NormSig,NORM_STAT,IGNORE_OUTLIERS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(NORM_STAT),        NORM_STAT = 'mean';   end
if isempty(IGNORE_OUTLIERS),  IGNORE_OUTLIERS = 0;  end

if isnumeric(NormSig) && length(NormSig) == 1,
  if NormSig < 0,
    NormSig = 'none';
  elseif NormSig == 1,
    NormSig = 'global';
  else
    NormSig = 'regress';
  end
end
if ischar(NormSig),
  Ses = goto(Sig.session);
  grp = getgrp(Ses,Sig.grpname);
  if strcmpi(NormSig,'global'),
    if exist('tcglobal.mat','file') == 0,
      fprintf('\n%s ERROR: please run "%s(''%s'',''%s'')" first.\n',mfilename,mfilename,...
              Ses.name,grp.name);
    end
    NormSig = load('tcglobal.mat',grp.name);
    NormSig = NormSig.(grp.name);
  elseif ~isempty(strfind(NormSig,'regress')),
    if exist('tcregress.mat','file') == 0,
      fprintf('\n%s ERROR: please run "%s(''%s'',''%s'')" first.\n',mfilename,mfilename,...
              Ses.name,grp.name);
    end
    NormSig = load('tcregress.mat',grp.name);
    NormSig = NormSig.(grp.name);
  elseif ~isempty(strfind(NormSig,'water')),
    if exist('tcwater.mat','file') == 0,
      fprintf('\n%s ERROR: please run "%s(''%s'',''%s'')" first.\n',mfilename,'mk_water',...
              Ses.name,grp.name);
    end
    NormSig = load('tcwater.mat',grp.name);
    NormSig = NormSig.(grp.name);
  elseif exist(NormSig,'file'),
    NormSig = load(NormSig,grp.name);
    NormSig = NormSig.(grp.name);
  elseif isempty(NormSig) || strcmpi(NormSig,'none'),
    % no need to normalize data
    NormSig = {};
    return;
  else
    % mnnormalize(Sig,roiname)
    NormSig = mn_roits_cat(mn_roits_get(Ses,grp,NormSig));
    %if isempty(strfind(NormSig.name,'regress')),
    %  NormSig.dat = nanmedian(NormSig.dat,2);
    %end
    if 0,
      TWIN1 = [1:6];
      TWIN2 = [15:18];
      TMPDAT = NormSig.dat;
      NormSig.dat = double(NormSig.dat);
      for T = TWIN1,
        if T+1 > TWIN1(end),
          NormSig.dat(T,:) = nanmean(TMPDAT([T TWIN1(1) TWIN1(2)],:),1);
        elseif T+2 > TWIN1(end)
          NormSig.dat(T,:) = nanmean(TMPDAT([T T+1 TWIN1(1)],:),1);
        else
          NormSig.dat(T,:) = nanmean(TMPDAT([T T+1 T+2],:),1);
        end
      end
      for T = TWIN2,
        if T+1 > TWIN2(end),
          NormSig.dat(T,:) = nanmean(TMPDAT([T TWIN1(1) TWIN2(2)],:),1);
        elseif T+2 > TWIN2(end)
          NormSig.dat(T,:) = nanmean(TMPDAT([T T+1 TWIN2(1)],:),1);
        else
          NormSig.dat(T,:) = nanmean(TMPDAT([T T+1 T+2],:),1);
        end
      end
      clear tmpsz TMPDAT;
    end
  end
end


if isempty(strfind(NormSig.name,'regress')) && ~isvector(NormSig.dat),
  % ignore OUTLIERS
  if size(NormSig.dat,2) < 10,  IGNORE_OUTLIERS = 0;  end
  if any(IGNORE_OUTLIERS),
    NDAT = zeros(size(NormSig.dat,1),1);
    for T = 1:size(NormSig.dat,1),
      tmpdat = zscore(double(NormSig.dat(T,:)));
      tmpidx = abs(tmpdat) < IGNORE_OUTLIERS;
      switch lower(NORM_STAT)
       case { 'median' }
        NDAT(T) = double(nanmedian(NormSig.dat(T,tmpidx)));
       otherwise
        NDAT(T) = nanmean(NormSig.dat(T,tmpidx));
      end
    end
    NormSig.dat = NDAT;
  else
    switch lower(NORM_STAT)
     case { 'median' }
      NormSig.dat = double(nanmedian(NormSig.dat,2));
     otherwise
      NormSig.dat = nanmean(NormSig.dat,2);
    end
  end
end


for N = 1:2,
  if N == 1,
    datname = 'dat';
  else
    if ~isfield(Sig,'pca_denoised') || isempty(Sig.pca_denoised),
      break;
    end
    if ~isfield(NormSig,'pca_denoised') || isempty(NormSig.pca_denoised),
      break;
    end
    datname = 'pca_denoised';
  end
  Sig.(datname) = double(Sig.(datname));
  if ~isempty(strfind(NormSig.name,'regress')),
    if ndims(Sig.(datname)) == 4,
      % for tcImg
      if strcmpi(datname,'dat'),
        m = NormSig.mbase;
      else
        m = NormSig.pca_mbase;
      end
      szdat = size(Sig.(datname));
      [iX iY iZ] = ind2sub(szdat(1:3),1:prod(szdat(1:3)));
      iZ(:) = Sig.slice;
      for T = 1:size(Sig.(datname),4),
        tmpb = NormSig.(datname)(:,T);
        tmpimg = Sig.(datname)(:,:,:,T);
        tmpf = tmpb(1)*iX + tmpb(2)*iY + tmpb(3)*iZ + tmpb(4);
        tmpf = reshape(tmpf,szdat(1:3));
        Sig.(datname)(:,:,:,T) = tmpimg .* tmpf / m;
      end
    else
      % for roiTs
      if Sig.flags.use_pca > 0,
        m = NormSig.pca_mbase;
      else
        m = NormSig.mbase;
      end
      slices = sort(unique(Sig.coords(:,3)));
      for iSlice = 1:length(slices)
        idx = find(Sig.coords(:,3) == slices(iSlice));
        tmpdat = Sig.(datname)(:,idx);
        iX = double(Sig.coords(idx,1));
        iY = double(Sig.coords(idx,2));
        iZ = double(Sig.coords(idx,3));
        for T = 1:size(tmpdat,1),
          tmpb = NormSig.(datname)(:,T);
          tmpf = tmpb(1)*iX + tmpb(2)*iY + tmpb(3)*iZ + tmpb(4);
          tmpdat(T,:) = tmpdat(T,:) .* tmpf' / m;
        end
        Sig.(datname)(:,idx) = tmpdat;
      end
    end
  else
    if ndims(Sig.(datname)) == 4,
      % (x,y,z,t)
      for T = 1:size(Sig.(datname),4),
        Sig.(datname)(:,:,:,T) = Sig.(datname)(:,:,:,T) / NormSig.(datname)(T);
      end
    else
      % (t,voxels)
      for T = 1:size(Sig.(datname),1),
        Sig.(datname)(T,:) = Sig.(datname)(T,:) / NormSig.(datname)(T);
      end
    end
  end
end


return;

  


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to compute a global time course
function subComputeGlobalOLD(Ses,grp,USE_REALIGNED,DUMMY)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' global-tc: ');

% load anatomy to get dimension
anaImg = anaload(Ses,grp);
nX = size(anaImg.dat,1);  nY = size(anaImg.dat,2);  nS = size(anaImg.dat,3);
nT = length(grp.exps);

clear anaImg;

% start from 20 to avoid a very bright eye.
SLICES = 20:nS-2;
SLICES = 35:nS-5;	% for o02wu1/wx1

fprintf('slice[%d:%d] ',SLICES(1),SLICES(end));

Nvoxels = 0;
TC_DAT  = zeros(nX*nY*length(SLICES),nT,'int16');


fprintf('.');
% PROCESS FOR .DAT
for iSlice = 1:length(SLICES);
  tmpslice = SLICES(iSlice);
  tcImg = mn_tcslice_load(Ses,grp,tmpslice,USE_REALIGNED);
  tmptc = reshape(tcImg.dat,[nX*nY*1, nT]);
  [zero1,zero2] = find(tmptc <= 0);
  tmptc(unique(zero1),:) = [];
  TC_DAT([1:size(tmptc,1)]+Nvoxels,:) = tmptc;
  Nvoxels = Nvoxels + size(tmptc,1);
end
TC_DAT  = TC_DAT(1:Nvoxels,:);
RAW_AVG = nanmean(TC_DAT,1);
RAW_MED = double(nanmedian(TC_DAT,1));
clear TC_DAT;

fprintf('.');
% PROCESS FOR .PCA_DENOISED
PCA_AVG = [];  PCA_MED = [];
if isfield(tcImg,'pca_denoised'),
  Nvoxels = 0;
  TC_DAT  = zeros(nX*nY*length(SLICES),nT,'int16');
  for iSlice = 1:length(SLICES);
    tmpslice = SLICES(iSlice);
    tcImg = mn_tcslice_load(Ses,grp,tmpslice,USE_REALIGNED);
    tmptc = reshape(tcImg.pca_denoised,[nX*nY*1, nT]);
    [zero1, zero2] = find(tmptc <= 0);
    tmptc(unique(zero1),:) = [];
    TC_DAT([1:size(tmptc,1)]+Nvoxels,:) = tmptc;
    Nvoxels = Nvoxels + size(tmptc,1);
  end
  TC_DAT  = TC_DAT(1:Nvoxels,:);
  PCA_AVG = nanmean(TC_DAT,1);
  PCA_MED = double(nanmedian(TC_DAT,1));
  clear TC_DAT;
end


NormSig.session = Ses.name;
NormSig.grpname = grp.name;
NormSig.ExpNo   = grp.exps;
NormSig.name    = 'global';
NormSig.slice   = SLICES;
NormSig.dat          = RAW_AVG(:);	    % make sure as a column vector
NormSig.pca_denoised = PCA_AVG(:);	    % make sure as a column vector
NormSig.coords  = ones(1,1,'int16');
NormSig.t       = mn_exptime(Ses,grp);
NormSig.median.dat          = RAW_MED(:);
NormSig.median.pca_denoised = PCA_MED(:);


SigName = grp.name;
matfile = 'tcglobal.mat';
eval(sprintf('%s = NormSig;',SigName));
fprintf('''%s''-->%s...',SigName,matfile);
if exist(matfile,'file') == 0,
  save(matfile,SigName);
else
  save(matfile,SigName,'-append');
end
fprintf(' done.\n');


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to compute regression coeffs for normalizaton
function subComputeGlobal(Ses,grp,USE_REALIGNED,BASE_RGN)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' global-tc: ');
RAW_AVG = [];  PCA_BETA = [];
% regression for RAW/PCA
for USE_PCA = 0:1,
  fprintf('.');
  roits = mn_roits_cat(mn_roits_get(Ses,grp,BASE_RGN,[],USE_PCA));
  if isempty(roits),  continue;  end
  if isempty(RAW_AVG),
    RAW_AVG = zeros(1,size(roits.dat,1));
    RAW_MED = zeros(1,size(roits.dat,1));
    PCA_AVG = zeros(1,size(roits.dat,1));
    PCA_MED = zeros(1,size(roits.dat,1));
    SLICE = roits.slice;
  end
  for T = 1:size(roits.dat,1),
    Y = roits.dat(T,:);
    idx = find(Y(:) > 100 & Y(:) < 10000);
    Y = double(Y(idx));
    if USE_PCA == 0,
      RAW_AVG(T) = nanmean(Y(:));
      RAW_MED(T) = nanmedian(Y(:));
    else
      PCA_AVG(T) = nanmean(Y(:));
      PCA_MED(T) = nanmedian(Y(:));
    end
  end
end


NormSig.session = Ses.name;
NormSig.grpname = grp.name;
NormSig.ExpNo   = grp.exps;
NormSig.name    = 'global';
NormSig.slice   = SLICE;
NormSig.dat          = RAW_AVG(:);	    % make sure as a column vector
NormSig.pca_denoised = PCA_AVG(:);	    % make sure as a column vector
NormSig.coords  = ones(1,1,'int16');
NormSig.t       = mn_exptime(Ses,grp);
NormSig.median.dat          = RAW_MED(:);
NormSig.median.pca_denoised = PCA_MED(:);

SigName = grp.name;
matfile = 'tcglobal.mat';
eval(sprintf('%s = NormSig;',SigName));
fprintf('''%s''-->%s...',SigName,matfile);
if exist(matfile,'file') == 0,
  save(matfile,SigName);
else
  save(matfile,SigName,'-append');
end
fprintf(' done.\n');


return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to compute regression coeffs for normalizaton
function subComputeRegress(Ses,grp,USE_REALIGNED,BASE_RGN)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' regress-tc: ');
RAW_BETA = [];  PCA_BETA = [];
% regression for RAW/PCA
for USE_PCA = 0:1,
  fprintf('.');
  roits = mn_roits_cat(mn_roits_get(Ses,grp,BASE_RGN,[],USE_PCA));
  if isempty(roits),  continue;  end
  basedat = nanmean(double(roits.dat([1 2],:)),1);
  if isempty(RAW_BETA),
    RAW_BETA = zeros(4,size(roits.dat,1));
    PCA_BETA = zeros(4,size(roits.dat,1));
    baseRAW  = NaN;
    basePCA  = NaN;
    SLICE = roits.slice;
  end
  for T = 1:size(roits.dat,1),
    Y = double(roits.dat(T,:));
    idx = find(Y(:) > 100 & Y(:) < 10000);
    Y = basedat(idx) ./ Y(idx);
    X = double(roits.coords(idx,:));
    X(:,end+1) = 1;
    stats = mulregress(Y,X);
    if USE_PCA == 0,
      RAW_BETA(:,T) = stats.beta;
    else
      PCA_BETA(:,T) = stats.beta;
    end
  end
  if USE_PCA == 0,
    baseRAW = basedat;
  else
    basePCA = basedat;
  end
end


NormSig.session = Ses.name;
NormSig.grpname = grp.name;
NormSig.ExpNo   = grp.exps;
if ischar(BASE_RGN),
  NormSig.name    = sprintf('regress-%s',BASE_RGN);
else
  NormSig.name    = 'regress';
  for N=1:length(BASE_RGN),
    NormSig.name  = sprintf('%s-%s',NormSig.name,BASE_RGN{N});
  end
end
NormSig.slice   = SLICE;
NormSig.dat     = RAW_BETA;
%NormSig.base    = baseRAW;		% slow down normalization
NormSig.mbase   = nanmean(baseRAW(:));
NormSig.pca_denoised = PCA_BETA;
%NormSig.pca_base = basePCA;    % slow down normalization
NormSig.pca_mbase = nanmean(basePCA(:));
NormSig.coords  = ones(1,1,'int16');
NormSig.t       = mn_exptime(Ses,grp);


SigName = grp.name;
matfile = 'tcregress.mat';
eval(sprintf('%s = NormSig;',SigName));
fprintf('''%s''-->%s...',SigName,matfile);
if exist(matfile,'file') == 0,
  save(matfile,SigName);
else
  save(matfile,SigName,'-append');
end
fprintf(' done.\n');


return;

