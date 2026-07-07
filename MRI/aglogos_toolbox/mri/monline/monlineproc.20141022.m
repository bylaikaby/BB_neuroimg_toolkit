function varargout = monlineproc(IMGFILE,iSTIM,iANAP,ANAFILE,ANASLICE,TRIFILE,varargin)
%MONLINEPROC - runs online analysis for fMRI
%  MONLINEPROC(IMGFILE,iSTIM,iANAP,ANAFILE,ANASLICE,TRIFILE) is called by MONLINE
%  to run actual analysis.
%
%  EXAMPLE :
%  If stimulus is like stim(8vol)-blank(8vol)x4repeats, then can be called like
%    >> SIG = monlineproc('\\Wks6\guest\D04.LG1\14\pdata\1\2dseq');
%    >> monlineview(SIG,0.05,'ttest');
%    >> monlinepvpar(SIG)
%
%    >> SIG = 
%      imgfile: '\\Wks6\guest\D04.LG1\14\pdata\1\2dseq'
%         path: '\\Wks6\guest'
%      session: 'D04.LG1'
%     scanreco: [14 1]
%         stim: [1x1 struct]
%          dat: [64x128x128x13 single]   <--- (t,x,y,slice)
%           dx: 6
%          ana: [128x128x13 single]
%          snr: [128x128x13 single]
%     centroid: [64x3 double]
%        pvpar: [1x1 struct]
%         anap: [1x1 struct]
%           ds: [0.7500 0.7500 2]
%        anads: [0.7500 0.7500 2]
%        ttest: [1x1 struct]
%            ttest.mapname: 'ttest2'
%            ttest.datname: 'tstat'
%                ttest.dat: [128x128x13 single]  <--- tstatistics
%                  ttest.p: [128x128x13 single]  <--- pvalue
%                 ttest.df: 62
%               ttest.tail: 'both'
%         resp: [1x1 struct]
%             resp.mapname: 'response'
%             resp.datname: 'response'
%                 resp.dat: [128x128x13 single]
%
%
%  VERSION :
%    0.90 01.10.06 YM  pre-release
%    0.91 13.03.08 YM  bug fix, finishing up.
%    0.92 14.03.08 YM  supports 'sdu','percent'.
%    0.93 18.03.08 YM  bug fix, use 'single' precision to save memory
%    0.94 10.04.08 YM  supports 'tripilot'.
%    0.94 02.09.08 YM  supports trial selection.
%    0.95 29.09.08 YM  bug fix, when 1 slice
%    0.96 17.05.10 YM  use HRF-convolution for the model
%    0.97 17.05.10 YM  supports GLM
%    0.98 23.06.10 YM  accepts multiple IMGFILEs for averaging
%    0.99 03.12.10 YM  supports tSNR
%    1.00 21.01.11 YM  supports ANAP.tfilter as Hz.
%    1.01 22.10.12 YM  problem fix for parallel imaging (double slices).
%
%  See also MONLINE MONLINEVIEW MONLINEPVPAR PVREAD_2DSEQ

if nargin == 0,  eval(sprintf('help %s;',mfliename)); return;  end

if nargin < 2,  iSTIM = [];  end
if nargin < 3,  iANAP = [];  end
if nargin < 4,  ANAFILE = '';  end
if nargin < 5,  ANASLICE = [];  end
if nargin < 5,  TRIFILE = '';  end

if isempty(iSTIM),
  iSTIM.stmtypes = {'stim', 'blank'};
  iSTIM.tvol     = [8 8];
  iSTIM.rep      = 4;
end

% DEFAULT ANALYSIS PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ANAP.imgnormalize = 1;
ANAP.xysmooth     = 0;
ANAP.centroid     = 0;
ANAP.detrend      = 0;
ANAP.tfilter      = 0;
ANAP.xform        = 'tosdu';
ANAP.average      = 0;
ANAP.apply_hrf    = 1;
ANAP.corrana      = 0;
ANAP.ttest        = 1;

% change values by the input
ANAP = subMergeStruct(ANAP,iANAP);


% OPTIONS :
GET_PVPAR_ONLY   = 0;
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'pvparonly' 'getpvparonly'}
    GET_PVPAR_ONLY = varargin{N+1};
  end
end



% RUN ANALYSIS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t0 = clock;

fprintf('%s %s: ',datestr(now,'HH:MM:SS'),mfilename);
fprintf(' pvpar.');
% image information
if ischar(IMGFILE),
  imgfile = IMGFILE;
else
  imgfile = IMGFILE{1};
end
ACQP   = pvread_acqp(imgfile);
RECO   = pvread_reco(imgfile);
IMND   = pvread_imnd(imgfile,'verbose',0);
METHOD = pvread_method(imgfile,'verbose',0);
pvpar  = subGetPvPar(ACQP,RECO,IMND,METHOD);
clear imgfile;

if any(GET_PVPAR_ONLY),
  [sespath sesname scanreco] = sub_scanreco(IMGFILE);
  SIG.imgfile = IMGFILE;
  SIG.path    = sespath;
  SIG.session = sesname;
  SIG.scanreco = scanreco;
  %SIG.stm     = STIM;
  %SIG.dat     = IMGDAT;
  %SIG.dx      = pvpar.imgtr;
  %SIG.ana     = single(ANADAT);
  %SIG.snr     = SNRDAT;
  %SIG.centroid = TCENT;
  SIG.pvpar   = pvpar;
  %SIG.anap    = ANAP;
  %SIG.ds      = pvpar.ds;
  varargout{1} = SIG;
  fprintf(' done(%.1fs).\n',etime(clock,t0));
  return
end



% stimulus information
fprintf(' stim.');
if sum(iSTIM.tvol)*iSTIM.rep ~= pvpar.nt,
  error('\n ERROR %s: stimulus length (%d=sum([%s])*%d) doesn''t match with 2dseq(nt=%d).',...
        mfilename,sum(iSTIM.tvol)*iSTIM.rep,deblank(sprintf('%d ',iSTIM.tvol)),iSTIM.rep,pvpar.nt);
end
STIM = subGetStim(iSTIM,ANAP.average);
if ANAP.apply_hrf > 0,
  fprintf(' model-hrf.');
  STIM = subConvolveHRF(STIM,pvpar.imgtr,'Cohen');
end
fprintf('\n  ');

if iscell(IMGFILE),
  IMGDAT = [];  ANADAT = [];  TCENT = [];  SNRDAT = [];
  for N = 1:length(IMGFILE),
    fprintf('''%s'':',IMGFILE{N});
    [tmpimg tmpana tmpcent tmpsnr] = sub_proc(IMGFILE{N},ACQP,RECO,pvpar,ANAP,iSTIM,STIM);
    if isempty(IMGDAT),
      IMGDAT = tmpimg;
      ANADAT = tmpana;
      TCENT  = tmpcent;
      SNRDAT = tmpsnr;
    else
      IMGDAT = IMGDAT + tmpimg;
      ANADAT = ANADAT + tmpana;
      TCENT  = TCENT  + tmpcent;
      SNRDAT = SNRDAT + tmpsnr;
    end
    fprintf('\n  ');
  end
  IMGDAT = IMGDAT / length(IMGFILE);
  ANADAT = ANADAT / length(IMGFILE);
  TCENT  = TCENT  / length(IMGFILE);
  SNRDAT = SNRDAT / length(IMGFILE);
else
  fprintf('''%s'':',IMGFILE);
  [IMGDAT ANADAT TCENT SNRDAT] = sub_proc(IMGFILE,ACQP,RECO,pvpar,ANAP,iSTIM,STIM);
  %fprintf('\n  ');
end



TRIPILOT = subGetTripilot(TRIFILE);
if exist(ANAFILE,'file') && ANAP.epiana < 1,
  AACQP = pvread_acqp(ANAFILE);
  ARECO = pvread_reco(ANAFILE);
  ANADAT = pvread_2dseq(ANAFILE,'acqp',AACQP,'reco',ARECO);
  if size(ANADAT,3) ~= size(IMGDAT,3) && ~isempty(ANASLICE),
    ANADAT = ANADAT(:,:,ANASLICE);
  end
else
  AACQP = ACQP;
  ARECO = RECO;
end


[sespath sesname scanreco] = sub_scanreco(IMGFILE);


% do statistical analysis
SIG.imgfile = IMGFILE;
SIG.path    = sespath;
SIG.session = sesname;
SIG.scanreco = scanreco;
SIG.stm     = STIM;
SIG.dat     = IMGDAT;
SIG.dx      = pvpar.imgtr;
SIG.ana     = single(ANADAT);
SIG.snr     = SNRDAT;
SIG.centroid = TCENT;
SIG.pvpar   = pvpar;
SIG.anap    = ANAP;
SIG.ds      = pvpar.ds;

SIG.anads(1) = ARECO.RECO_fov(1) / ARECO.RECO_size(1) * 10;
SIG.anads(2) = ARECO.RECO_fov(2) / ARECO.RECO_size(2) * 10;
if length(AACQP.ACQ_slice_offset) > 1,
  SIG.anads(3) = mean(diff(AACQP.ACQ_slice_offset));
else
  %SIG.anads(3) = AACQP.ACQ_slice_sepn;
  SIG.anads(3) = AACQP.ACQ_slice_thick;
end

SIG.tripilot = TRIPILOT;

if ANAP.corrana > 0,
  fprintf(' corr.');
  SIG.corr  = subDoCorrAna(IMGDAT,STIM);
end
if ANAP.glmana > 0,
  fprintf(' glm.');
  SIG.glm = subDoGlmAna(IMGDAT,STIM,1);
end
if ANAP.ttest > 0,
  fprintf(' ttest.');
  SIG.ttest = subDoTTest(IMGDAT,STIM);
end


fprintf(' resp.');
SIG.resp = subGetResponse(IMGDAT,STIM);


fprintf(' done(%.1fs).\n',etime(clock,t0));


% return output, if required
if nargout > 0,
  varargout{1} = SIG;
else
  % show results
  monlineview(SIG);
end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function C = subMergeStruct(A,B)
C = A;
if ~isempty(B),
  fnames = fieldnames(B);
  for N = 1:length(fnames),
    if isstruct(B.(fnames{N})),
      C.(fnames{N}) = subMergeStruct(C.(fnames{N}),B.(fnames{N}));
    else
      C.(fnames{N}) = B.(fnames{N});
    end
  end
end

return;
  



function STIM = subGetStim(iSTIM,DoTrialAverage)

Tvol = iSTIM.tvol;
if DoTrialAverage > 0,
  Rep = 1;
else
  Rep = iSTIM.rep;
end
  
STIM.stmtypes = iSTIM.stmtypes;
STIM.v{1}     = repmat(0:length(iSTIM.stmtypes)-1,[1,Rep]);
STIM.dtvol{1} = repmat(Tvol(:)',[1,Rep]);
STIM.tvol{1}  = [0 cumsum(STIM.dtvol{1})];
STIM.val{1}   = zeros(size(STIM.v{1}));
STIM.boxcar   = [];
STIM.mdl{1}   = [];
STIM.trial    = iSTIM.trial;

for N = 1:length(STIM.v{1}),
  if any(strcmpi(STIM.stmtypes{STIM.v{1}(N)+1},{'blank','none'})),
    STIM.val{1}(N) = 0;
  else
    STIM.val{1}(N) = 1;
  end
end

VAL = STIM.val{1};
TS = STIM.tvol{1} + 1;  % +1 for matlab indexing
TE = STIM.tvol{1};  % +1 for matlab indexing

LEN = max(cumsum(repmat(Tvol(:)',[1,Rep])));
TE(end+1) = LEN;
boxcar = zeros(1,LEN);
for N = 1:length(VAL),
  if VAL(N) ~= 0,
    ts = TS(N);
    te = TE(N+1);
    if ts > LEN,  ts = LEN;  end
    if te > LEN,  te = LEN;  end
    if te < 1,       te = 1;      end
    boxcar(ts:te) = VAL(N);
  end
end
STIM.boxcar = boxcar(1:LEN);
STIM.mdl{1} = boxcar(1:LEN);


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pvpar = subGetPvPar(ACQP,RECO,IMND,METHOD)
pvpar.acqp = ACQP;
pvpar.reco = RECO;
if ~isempty(METHOD),
  pvpar.method = METHOD;
end
if ~isempty(IMND),
  pvpar.imnd   = IMND;
end

% basic info
pvpar.nx   = RECO.RECO_size(1);
pvpar.ny   = RECO.RECO_size(2);
pvpar.nsli = ACQP.NSLICES;
% parallel imaging
if any(strfind(lower(ACQP.PULPROG),'dualslice')),
  pvpar.nsli = pvpar.nsli * 2;
end

pvpar.nt   = ACQP.NR;
if ~isempty(METHOD),
  pvpar.nseg = METHOD.PVM_EpiNShots;
else
  pvpar.nseg = IMND.IMND_numsegments;
  if strcmpi(IMND.EPI_segmentation_mode,'No_Segments')    % glitch for EPI
    pvpar.nseg   = 1;			
  end
end
pvpar.ds(1) = RECO.RECO_fov(1) / RECO.RECO_size(1) * 10;
pvpar.ds(2) = RECO.RECO_fov(2) / RECO.RECO_size(2) * 10;
if length(ACQP.ACQ_slice_offset) > 1,
  pvpar.ds(3) = mean(diff(ACQP.ACQ_slice_offset));
else
  %pvpar.ds(3) = ACQP.ACQ_slice_sepn;
  pvpar.ds(3) = ACQP.ACQ_slice_thick;
end
% timings in seconds
if ~isempty(METHOD),
  pvpar.slitr = ACQP.ACQ_repetition_time/1000/ACQP.NSLICES;
  pvpar.segtr = ACQP.ACQ_repetition_time/1000;
  pvpar.imgtr = ACQP.ACQ_repetition_time/1000*METHOD.PVM_EpiNShots;
  pvpar.effte = METHOD.EchoTime/1000;
  pvpar.recovtr = ACQP.ACQ_recov_time(:)'/1000;
else
  if strncmp(ACQP.PULPROG, '<BLIP_epi',9)
    pvpar.slitr	= IMND.EPI_slice_rep_time/1000;
    pvpar.segtr	= IMND.IMND_rep_time;       
    pvpar.imgtr	= pvpar.segtr * pvpar.nseg;
    if strcmpi(IMND.EPI_scan_mode,'FID')
      pvpar.effte = IMND.EPI_TE_eff/1000;
    else
      pvpar.effte = IMND.IMND_echo_time/1000;
    end
  else
    pvpar.slitr	= IMND.IMND_rep_time;
    pvpar.segtr	= IMND.IMND_acq_time/1000;
    pvpar.imgtr	= pvpar.slitr;
    pvpar.effte	= IMND.IMND_echo_time/1000;
  end
  pvpar.recovtr	= IMND.IMND_recov_time(:)'/1000;
end
  
return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TRIPILOT = subGetTripilot(TRIFILE)

TRIPILOT = [];
if ~exist(TRIFILE,'file'),  return;  end

TACQP  = pvread_acqp(TRIFILE);
TRECO  = pvread_reco(TRIFILE);
TRIDAT = pvread_2dseq(TRIFILE,'acqp',TACQP,'reco',TRECO);
ds = TRECO.RECO_fov ./ TRECO.RECO_size * 10;  % in mm
ds(3) = ds(1);

TRIPILOT.dat = TRIDAT;
TRIPILOT.ds  = ds;
TRIPILOT.pvpar.acqp = TACQP;
TRIPILOT.pvpar.reco = TRECO;


return


function [sespath sesname scanreco] = sub_scanreco(IMGFILE)

if ischar(IMGFILE),  IMGFILE = { IMGFILE };  end
for K = 1:length(IMGFILE),
  p = IMGFILE{K};
  for N = 1:5,
    [p,f,e] = fileparts(p);
    if N == 2,
      recov = str2double(f);
    elseif N == 4,
      scanv = str2double(f);
    elseif N == 5,
      sespath = p;
      sesname = strcat(f,e);
    end
  end
  scanreco(K,:) = [scanv recov];
end
 
return




function [IMGDAT ANADAT TCENT SNRDAT] = sub_proc(IMGFILE,ACQP,RECO,pvpar,ANAP,iSTIM,STIM)

% read raw data
fprintf(' read.');
%ACQP = pvread_acqp(IMGFILE);
%RECO = pvread_reco(IMGFILE);
IMGDAT = pvread_2dseq(IMGFILE,'acqp',ACQP,'reco',RECO);
%IMND   = pvread_imnd(IMGFILE,'verbose',0);
%METHOD = pvread_method(IMGFILE,'verbose',0);
if datenum(version('-date')) >= datenum('August 02, 2005')
  IMGDAT = single(IMGDAT);
else
  % old matlab does't support math for 'single' precision
  IMGDAT = double(IMGDAT);
end
fprintf('[%dx%dx%d/%d]',size(IMGDAT,1),size(IMGDAT,2),size(IMGDAT,3),size(IMGDAT,4));


ANADAT = nanmean(IMGDAT,4);

if size(IMGDAT,4) > 2,
  tmpm = ANADAT;
  tmps = nanstd(IMGDAT,[],4);
  tmpidx = tmps(:) < eps;
  tmpm(tmpidx) = 0;
  tmps(tmpidx) = 1;  % to avoid error
  SNRDAT = tmpm ./ tmps;
  clear tmpm tmps tmpidx;
else
  SNRDAT = zeros(size(ANADAT));
end
%nanmean(SNRDAT(:))

% compute a time course of centroid
TCENT = mcentroid(IMGDAT);  TCENT = TCENT';

% permute dimenstion for matlab functions
IMGDAT = permute(IMGDAT,[4 1 2 3]);  % (x,y,z,t) --> (t,x,y,z)

% image processing, XY-smoothing, detrend, temporal-filtering
if ANAP.centroid > 0,
  fprintf(' centroid.');
  IMGDAT = subDoCentroid(IMGDAT,TCENT);
end

if ANAP.imgnormalize > 0,
  fprintf(' imgnormalize.');
  IMGDAT = subDoImgNormalize(IMGDAT);
end

if ANAP.xysmooth > 0,
  fprintf(' XYsmooth.');
  IMGDAT = subDoXYSmooth(IMGDAT);
end
if ANAP.detrend > 0,
  fprintf(' detrend.');
  IMGDAT = subDoDetrend(IMGDAT);
end
if any(ANAP.tfilter) && ~strcmpi(ANAP.tfilter,'none'),
  nyqf = 1/pvpar.imgtr/2;
  if ischar(ANAP.tfilter) && strcmpi(ANAP.tfilter,'auto'),
    stimdur = diff(STIM.tvol{1});
    trialdur = sum(stimdur(1:length(STIM.stmtypes)));
    FBAND = [1/trialdur * 0.8 0.8];
    % stimdur = [];
    % for N = 1:length(STIM.dtvol{1}),
    %   if ~any(strcmpi(STIM.stmtypes{STIM.v{1}(N)+1},{'none','blank'})),
    %     stimdur = cat(2,stimdur,STIM.dtvol{1}(N));
    %   end
    % end
    % if any(stimdur),
    %   FBAND = [1/(nanmean(stimdur)*2) * 0.8 0.8];
    % else
    %   FBAND = [0 0.8];
    % end
  else
    FBAND = ANAP.tfilter / nyqf;
  end
  fprintf(' t-filter[%g-%g].',FBAND(1)*nyqf,FBAND(2)*nyqf);
  IMGDAT = subDoTFilter(IMGDAT,FBAND);
end

if ~isempty(ANAP.xform) && ~strcmpi(ANAP.xform,'none'),
  fprintf(' xform(%s).',ANAP.xform);
  IMGDAT = subDoTcNormalize(IMGDAT,STIM,ANAP.xform);
end


if ANAP.average > 0 && iSTIM.rep > 1,
  if any(iSTIM.trial),
    fprintf(' average(n=%d).',length(iSTIM.trial));
  else
    fprintf(' average(n=%d).',iSTIM.rep);
  end
  if mod(size(IMGDAT,1),iSTIM.rep) == 0,
    rep   = iSTIM.rep;
    tmpsz = size(IMGDAT);
    IMGDAT = reshape(IMGDAT,[tmpsz(1)/rep rep tmpsz(2:end)]);
    if any(iSTIM.trial),
      IMGDAT = IMGDAT(:,iSTIM.trial,:,:,:);
    end
    IMGDAT = mean(IMGDAT,2);
    IMGDAT = reshape(IMGDAT,[tmpsz(1)/rep tmpsz(2:end)]);
  else
    fprintf('stimulus timings/repeats doen''t match with image dimension.');
  end
end

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function STIM = subConvolveHRF(STIM,IMGTR,HTYPE)

MODEL = STIM.boxcar;

if IMGTR <= 1,
  IRTDX = IMGTR;
else
  IRTDX = IMGTR/ceil(IMGTR);
  x  = (0:length(MODEL)-1)*IMGTR;
  xi = 0:IRTDX:x(end);
  MODEL = interp1(x,MODEL,xi,'linear');
end

IRT = 0:IRTDX:15;

switch lower(HTYPE),
 case {'gampdf','hemo'}
  Lamda = 10;
  Theta = 0.4089;
  IR = gampdf(IRT,Lamda,Theta);
 case {'fgampdf','fhemo'}
  Lamda = 10;
  Theta = 0.278;
  IR = gampdf(IRT,Lamda,Theta);
 case {'cohen'}
  b = 8.6;  c = 0.547;
  IR = (IRT.^b).*exp(-IRT/c);
end

sel = 1:length(MODEL);
if length(IR) >= length(MODEL),
  MODEL(end+1:end+length(IR)) = 0;
end
MODEL = conv(MODEL(:),IR(:));
MODEL = MODEL(sel);

if IRTDX ~= IMGTR,
  MODEL = interp1(xi,MODEL,x,'linear');
end

MODEL = MODEL/max(abs(MODEL));

STIM.mdl{1} = MODEL(:)';

%figure;
%plot([0:length(MODEL)-1]*IMGTR,MODEL);
%hold on;
%plot([0:length(STIM.boxcar)-1]*IMGTR,STIM.boxcar);


return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function STAT = subDoCorrAna(IMGDAT,STIM)
  
szimg = size(IMGDAT);
IMGDAT = reshape(IMGDAT,[szimg(1) prod(szimg(2:end))]);  % (t,x,y,z) --> (t,xyz)

mdldat = STIM.mdl{1}(:);
nvoxels = size(IMGDAT,2);
R = zeros(1,nvoxels);
P = ones(1,nvoxels);
% to avoid error of zero division
idx = find(var(IMGDAT) ~= 0);
for N = idx,
  [r,p] = corrcoef(mdldat,IMGDAT(:,N));
  R(N) = r(1,2);
  P(N) = p(1,2);
end

STAT.mapname = 'corr';
STAT.datname = 'r-value';
STAT.dat     = reshape(R,szimg(2:end));
STAT.p       = reshape(P,szimg(2:end));
STAT.model   = mdldat;

STAT.dat = single(STAT.dat);
STAT.p   = single(STAT.p);


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function STAT = subDoGlmAna(IMGDAT,STIM,USE_SIMPLE_GLM)

szimg = size(IMGDAT);
IMGDAT = reshape(IMGDAT,[szimg(1) prod(szimg(2:end))]);  % (t,x,y,z) --> (t,xyz)

nvoxels = size(IMGDAT,2);
B = zeros(1,nvoxels);
T = zeros(1,nvoxels);
P = ones(1,nvoxels);
% to avoid error on regression
idx = find(var(IMGDAT) ~= 0);

mdldat = STIM.mdl{1}(:);
X = mdldat;
X(:,2) = 1;

if USE_SIMPLE_GLM == 1,
  % 114sec for 128x128x13/64 data.
  [n p] = size(X);
  dfe = max(n-p,0);
  pwts = 1;
  [Q R] = qr(X,0);
  RI = R\eye(p);
  C  = RI * RI';
  %tic
  for N = idx,
    y = IMGDAT(:,N);
    b = regress(y,X);
    mu  = X * b;
    ssr = sum(pwts .* (y - mu).^2);
    %if dfe > 0,
    %  stats.s = sqrt(ssr / dfe);
    %else
    %  stats.s = NaN;
    %end
    stats.s = sqrt(ssr / dfe);
    stats.se = sqrt(diag(C * stats.s^2));
    stats.t = b ./ stats.se;
    stats.p = 2 * tcdf(-abs(stats.t),dfe);
    B(N) = b(1);
    T(N) = stats.t(1);
    P(N) = stats.p(1);
  end
  %toc
elseif USE_SIMPLE_GLM == 2,
  % 181sec for 128x128x13/64 data.
  [n p] = size(X);
  dfe = max(n-p,0);
  pwts = 1;
  [Q R] = qr(X,0);
  RI = R\eye(p);
  C  = RI * RI';
  %tic
  for N = idx,
    y = IMGDAT(:,N);
    stats = regstats(y,mdldat,'linear','tstat');
    B(N) = stats.tstat.beta(2);
    T(N) = stats.tstat.t(2);
    P(N) = stats.tstat.pval(2);
  end
  %toc
else
  % glmfit() takes forever... 392sec for 128x128x13/64 data.
  %tic
  warning off all;
  for N = idx,
    [b dev stats] = glmfit(mdldat,IMGDAT(:,N),'normal');
    B(N) = b(2);
    T(N) = stats.t(2);
    P(N) = stats.p(2);
  end
  warning on all;
  %toc
end


STAT.mapname = 'glm';
STAT.datname = 'ttstat';
STAT.dat     = reshape(T,szimg(2:end));
STAT.p       = reshape(P,szimg(2:end));
STAT.beta    = reshape(B,szimg(2:end));
STAT.model   = mdldat;

STAT.dat = single(STAT.dat);
STAT.p   = single(STAT.p);
STAT.beta= single(STAT.beta);


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function STAT = subDoTTest(IMGDAT,STIM,TAIL)
%if nargin < 3,  TAIL  = 'right';  end
if nargin < 3,  TAIL  = 'both';  end
%    TAIL='both'  :  mean(dat(TWIN1)) ~= mean(dat(TWIN2))
%    TAIL='right' :  mean(dat(TWIN1)) >  mean(dat(TWIN2))
%    TAIL='left'  :  mean(dat(TWIN1)) <  mean(dat(TWIN2))

szimg = size(IMGDAT);
IMGDAT = reshape(IMGDAT,[szimg(1) prod(szimg(2:end))]);  % (t,x,y,z) --> (t,xyz)


%tsel1 = find(STIM.mdl{1} > 0);
%tsel2 = find(STIM.mdl{1} == 0);

tsel1 = STIM.mdl{1} > 0.3;
tsel2 = abs(STIM.mdl{1}) < 0.1;

  
x = IMGDAT(tsel1,:);
y = IMGDAT(tsel2,:);

% to avoid error of zero division
idx = find(var(x) ~= 0 | var(y) ~= 0);
nvoxels = size(IMGDAT,2);
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


STAT.mapname = 'ttest2';
STAT.datname = 'tstat';
STAT.dat   = reshape(T,szimg(2:end));
STAT.p     = reshape(P,szimg(2:end));
STAT.df    = stat.df(1);
STAT.tail  = TAIL;
STAT.ibase = tsel1;
STAT.iresp = tsel2;


STAT.dat = single(STAT.dat);
STAT.p   = single(STAT.p);

  
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function STAT = subGetResponse(IMGDAT,STIM)

szimg = size(IMGDAT);
IMGDAT = reshape(IMGDAT,[szimg(1) prod(szimg(2:end))]);  % (t,x,y,z) --> (t,xyz)

%tsel1 = find(STIM.mdl{1} > 0);
%tsel2 = find(STIM.mdl{1} == 0);
tsel1 = STIM.mdl{1} > 0.3;
%tsel2 = find(abs(STIM.mdl{1}) < 0.1);

%MODEL = STIM.mdl{1};
MODEL = STIM.boxcar;
nrep = ceil(szimg(1)/length(MODEL));
if nrep > 1,
  MODEL = repmat(MODEL(:)',[1 nrep]);
end
%tsel1 = find(MODEL > 0.4);
%tsel2 = find(abs(MODEL) < 0.1);
% use 3 volumes before stimulus
ton = find(diff(MODEL) > 0.5);
if isempty(ton),
  tsel2 = find(abs(STIM.mdl{1}) < 0.1);
else
  tsel2 = zeros(1,length(MODEL));
  for N = 1:length(ton),
    ts = max(1,ton(N)-3);
    te = ton(N);
    tsel2(ts:te) = 1;
  end
  tsel2 = find(tsel2 > 0);
end


resp = nanmean(IMGDAT(tsel1,:),1) - nanmean(IMGDAT(tsel2,:),1);

STAT.mapname = 'response';
STAT.datname = 'response';
STAT.dat     = reshape(resp,szimg(2:end));


STAT.dat = single(STAT.dat);

return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function IMGDAT = subDoImgNormalize(IMGDAT)

thr = 10;		% Percent of max to include in normaliz.
slice_mean = mean(IMGDAT,1);			% Avg. over time.
  
% Find the avg. activation of those pix that are above threshold.
% This excludes areas outside of the brain from the average.
included_voxels  = max(slice_mean(:)) * thr / 100.0;
volume_mean = mean( mean( slice_mean( slice_mean > included_voxels)));
% Normalize images to avg activation of brain (activated) pixles.
if numel(IMGDAT)*8 > 800e+6,
  % If 'IMGDAT' is larger than 800M, then do time by time to avoid memory problem.
  for N = 1:size(IMGDAT,1),
    IMGDAT(N,:,:,:) = 1000/volume_mean * IMGDAT(N,:,:,:);
  end
else
  IMGDAT = 1000/volume_mean * IMGDAT;
end



return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function IMGDAT = subDoCentroid(IMGDAT,TCENT)

m = mean(TCENT);
s = std(TCENT);

for N = 1:3,
  TCENT(:,N) = (TCENT(:,N) - m(N)) / s(N);
end
TCENT = abs(TCENT);


idx = find(TCENT(:,1) > 2.5 | TCENT(:,2) > 2.5 | TCENT(:,3) > 2.5);
okidx = ones(1,size(IMGDAT,1));
okidx(idx) = 0;
okidx = find(okidx);

fprintf('(%d/%d)',length(idx),size(IMGDAT,1));
if ~isempty(idx) && length(okidx) > size(IMGDAT,1)*0.7,
  for N = 1:length(idx),
    tmpidx = idx(N);
    [tmpv tmpsub] = min(abs(okidx-tmpidx));
    tmpsub = okidx(tmpsub);
    IMGDAT(tmpidx,:,:,:) = IMGDAT(tmpsub,:,:,:);
  end

  %tmp = mcentroid(permute(IMGDAT,[2 3 4 1]));
  %figure; set(gcf,'pos',[0 0 560 420]);  plot(tcent);
  %hold on;
  %plot(tmp');
end
  
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function IMGDAT = subDoDetrend(IMGDAT,RECOVER_DC)

if nargin < 2,  RECOVER_DC = 1;  end

szimg = size(IMGDAT);
IMGDAT = reshape(IMGDAT,[szimg(1) prod(szimg(2:end))]);  % (t,x,y,z) --> (t,xyz)

if RECOVER_DC,
  tmpm = mean(IMGDAT,1);
end

IMGDAT = detrend(IMGDAT);

if RECOVER_DC,
  for N=1:size(IMGDAT,2),
    IMGDAT(:,N) = IMGDAT(:,N) + tmpm(N);
  end
end


IMGDAT = reshape(IMGDAT,szimg);

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function IMGDAT = subDoXYSmooth(IMGDAT,KSIZE,KSD)

if nargin < 2,  KSIZE = 3;  end
if nargin < 3,  KSD   = 1.5;  end

h = fspecial('gaussian',KSIZE,KSD);

%szimg = size(IMGDAT);

for N = 1:size(IMGDAT,1),
  for S = 1:size(IMGDAT,4),
    IMGDAT(N,:,:,S) = filter2(h,squeeze(IMGDAT(N,:,:,S)));
  end
end



return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function IMGDAT = subDoTFilter(IMGDAT,FBAND)


f1 = FBAND(1);
f2 = FBAND(2);


szimg = size(IMGDAT);
IMGDAT = reshape(IMGDAT,[szimg(1) prod(szimg(2:end))]);  % (t,x,y,z) --> (t,xyz)


if f1 > 0 && f2 > 0,
  DC_OFFS = nanmean(IMGDAT,1);
  [b,a] = butter(4,[f1 f2],'bandpass');
  IMGDAT = filtfilt(b,a,IMGDAT);
  for N = 1:size(IMGDAT,2),
    IMGDAT(:,N) = IMGDAT(:,N) + DC_OFFS(N);
  end
elseif f1 > 0,
  DC_OFFS = nanmean(IMGDAT,1);
  [b,a] = butter(4,f1,'high');
  IMGDAT = filtfilt(b,a,IMGDAT);  
  for N = 1:size(IMGDAT,2),
    IMGDAT(:,N) = IMGDAT(:,N) + DC_OFFS(N);
  end
elseif f2 > 0,
  [b,a] = butter(4,f2,'low');
  IMGDAT = filtfilt(b,a,IMGDAT);
end


IMGDAT = reshape(IMGDAT,szimg);

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function IMGDAT = subDoTcNormalize(IMGDAT,STIM,METHOD)

if nargin < 3,  METHOD = 'none';  end

szimg = size(IMGDAT);
IMGDAT = reshape(IMGDAT,[szimg(1) prod(szimg(2:end))]);  % (t,x,y,z) --> (t,xyz)


%MODEL = STIM.mdl{1};
MODEL = STIM.boxcar;
nrep = ceil(szimg(1)/length(MODEL));
if nrep > 1,
  MODEL = repmat(MODEL(:)',[1 nrep]);
end
%tsel1 = find(MODEL > 0.4);
%tsel2 = find(abs(MODEL) < 0.1);
% use 3 volumes before stimulus
ton = find(diff(MODEL) > 0.5);
if isempty(ton),
  tsel2 = 1:length(MODEL);
else
  tsel2 = zeros(1,length(MODEL));
  for N = 1:length(ton),
    ts = max(1,ton(N)-2);
    te = ton(N);
    tsel2(ts:te) = 1;
  end
  tsel2 = find(tsel2 > 0);
end

switch lower(METHOD),
 case {'sdu','tosdu'}
  tmpm = nanmean(IMGDAT(tsel2,:),1);
  tmps = nanstd(IMGDAT(tsel2,:),[],1);
  % to avoid divided-by-zero
  idx = find(tmps(:) < eps);
  tmps(idx) = 1;
  tmpm(idx) = 0;
  IMGDAT(:,idx) = 0;
  for N=1:size(IMGDAT,2),
    IMGDAT(:,N) = (IMGDAT(:,N)-tmpm(N)) / tmps(N);
  end
  
 case {'percent','percentage','%'}
  tmpm = nanmean(IMGDAT(tsel2,:),1);
  % to avoid divided-by-zero
  idx = find(abs(tmpm(:)) < eps);
  tmpm(idx) = 1;
  IMGDAT(:,idx) = 1;  % should become 0 after (IMGDAT/m - 1)*100
  for N=1:size(IMGDAT,2),
    IMGDAT(:,N) = IMGDAT(:,N) / tmpm(N);
  end
  IMGDAT = (IMGDAT - 1) * 100;
  
 otherwise
end

IMGDAT = reshape(IMGDAT,szimg);


return
