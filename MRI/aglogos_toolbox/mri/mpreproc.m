function tcImg = mpreproc(tcImg,ARGS)
%MPREPROC - Preprocess the 2dseq imaging data
% tcImg = MPREPROC(tcImg) is meant to be use only for generating
% averages within a group. It is used to run mcorana over the group
% data and generate activation maps as defined in the
% Ses.grp.actmap field. The function does not have the complete
% preprocessing data that we are using to process AreaTS (ses
% mareats).
% NKL, 17.04.04
  
% ======================================================================
% DEFAULT SETTINGS & OPERATIONS
% ======================================================================
DEF.IFFTFILT                = 1;		% Get rid of linear trends
DEF.IDETREND                = 0;		% Get rid of linear trends
DEF.ITMPFLT_LOW             = 0;		% Reduce samp. rate by this factor
DEF.IDENOISE                = 0;		% Remove respiratory art. (not used)
DEF.IFILTER                 = 1;		% Filter w/ a small kernel
DEF.IFILTER_KSIZE           = 3;		% Kernel size
DEF.IFILTER_SD              = 1.25;		% SD (if half about 90% of flt in kernel)
DEF.ITOSDU                  = 0;        % Express time series in SD units

if nargin < 1,
  help mpreproc;
  return;
end;

if exist('ARGS','var'),
  ARGS = sctcat(ARGS,DEF);
else
  ARGS = DEF;
end;
pareval(ARGS);

if IFFTFILT,
  fprintf(' fftflt.');
  tcImg = mtcimgfft(tcImg);
end;

if IDETREND,
  fprintf(' detrend.');
  tcImg = mdetrend(tcImg);
end;

if IDENOISE,
  fprintf(' denoise.');
  tcImg = DenoiseImg(tcImg);
end;

if ITMPFLT_LOW,
  fprintf(' T-filtering(LP).');
  nyq = (1/tcImg.dx)/2;
  [b,a] = butter(4,ITMPFLT_LOW/nyq,'low');
  for NS=1:size(tcImg.dat,3),
    tmp = squeeze(tcImg.dat(:,:,NS,:));
    for C=1:size(tmp,1),
      for R=1:size(tmp,2),
        tmp(C,R,:) = filtfilt(b,a,tmp(C,R,:));
      end;
    end;
    tcImg.dat(:,:,NS,:) = tmp;
  end;
  clear tmp;
end;

if ITOSDU,
  fprintf(' tosdu.');
  tcImg = tosdu(tcImg);
end;

if IFILTER,
  fprintf(' XY-filtering.');
  for NS=1:size(tcImg.dat,3),
    tcImg.dat(:,:,NS,:) = mconv(squeeze(tcImg.dat(:,:,NS,:)), ...
                                IFILTER_KSIZE,IFILTER_SD);
  end;
end
fprintf(' done.\n');
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sig = DenoiseImg(Sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
frange = GetRespRate(Sig);
nyq = (1/Sig.dx) / 2;
for N=1:length(frange),
  frange{N}=frange{N}/nyq;
end;

if ~isempty(frange{1}),
  [b,a] = butter(4,frange{1},'stop');
else
  fprintf('\n mpreproc: all freq ranges are empty.  applying detrend() only...');
end
if ~isempty(frange{2}),
  [b1,a1] = butter(4,frange{2},'stop');
end
mimg = mean(Sig.dat,4);
SIZE = squeeze(size(Sig.dat(:,:,1,:)));
for SliceNo=1:size(Sig.dat,3),
  tmpimg = squeeze(Sig.dat(:,:,SliceNo,:));
  tmpimg = mreshape(tmpimg);
  for N=1:size(tmpimg,2),
    if ~isempty(frange{1}),
      tmpimg(:,N) = filtfilt(b,a,tmpimg(:,N));
    end
    if ~isempty(frange{2}),
      tmpimg(:,N) = filtfilt(b1,a1,tmpimg(:,N));
    end
  end;
  Sig.dat(:,:,SliceNo,:) = mreshape(tmpimg,SIZE,'m2i');
end;
Sig.dat = Sig.dat + repmat(mimg,[1 1 1 size(Sig.dat,4)]);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function frange = GetRespRate(tcImg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tcImg.dat = tcImg.dat(:,:,1,:);
[famp,fang,freq] = msigfft(tcImg);
famp = mean(famp,2);

idx1 = find(freq>0.35 & freq < 0.46);
idx2 = find(freq>0.70 & freq < 0.92);

[mf, f1] = max(famp(idx1));
[mf, f2] = max(famp(idx2));

if ~isempty(idx1),
  f1 = f1 + idx1(1) - 1;
  frange{1} = [freq(f1)-0.020 freq(f1)+0.020];
else
  f1 = [];  frange{1} = [];
end
if ~isempty(idx2),
  f2 = f2 + idx2(1) - 1;
  frange{2} = [freq(f2)-0.020 freq(f2)+0.020];
else
  f2 = [];  frange{2} = [];
end
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [PC, eVar, Proj, SigMean] = doPCA(dat, nopcs)
% NOT APPLIED YET!!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dat		= dat';							% transpose dat (T,N)->(N,T)
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tcImg = mdetrend(tcImg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%MDETREND - Detrend data of tcImg
% OtcImg = MDETREND(tcImg) detrend the data without removing the mean
% NKL, 24.04.04
  
for NS = 1:size(tcImg.dat,3),
  tcols = mreshape(squeeze(tcImg.dat(:,:,NS,:)));
  dims = size(squeeze(tcImg.dat(:,:,NS,:)));
  m = repmat(mean(tcols),[size(tcols,1) 1]);
  tcols = detrend(tcols) + m;
  tcImg.dat(:,:,NS,:) = mreshape(tcols,dims,'m2i');
end;
