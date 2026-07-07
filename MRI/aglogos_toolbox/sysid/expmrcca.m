function RES = expmrcca(Ses,ExpNo,varargin)
%EXPMRCCA - Applies tkCCA to BOLD singals with the given ROIs.
%  RES = EXPMRCCA(SESSION,EXPNO,...) applies tkCCA to BOLD signals with the given ROIs.
%
%  Supported options are :
%    'maxlag'     : max. lag in seconds
%    'RoiName'    : Roi name(s)
%    'ResampleHz' : resampling Hz, can be as 'bold' or any numeric
%
%  NOTE :
%    -lags mean ModelSig preceeds MriSig.
%    +lags mean ModelSig follows  MriSig.
%    For easy comparison with HRF, flip the lags (lags=-lags) so that
%    +lags mean MriSig follows ModelSig.  See plot_mrcca() for detail.
%
%  EXAMPLE :
%    res = expmrcca('e10ha1',6,'mrisig','roiTs','roi',{'HP' 'hele'});
%    plot_mrcca(res)
% 
%  VERSION : 
%    0.90 08.01.13 YM
% 
%  See also tkcca plot_mrcca exptcor expmrcca_cv

if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end

% SET OPTIONS
MAX_LAGS_SEC    = 20;
VERBOSE         = 1;
RoiName         = 'all';
MriSig          = 'roiTs';
ResampleHz      = 'bold';
MriNorm         = 'none';
RegType         = 'pca';

ANAP = getanap(Ses,ExpNo);
if isfield(ANAP,'mrcca'),
  RoiName       = ANAP.mrcca.rois;
  MriSig        = ANAP.mrcca.mrisig;
  ResampleHz    = ANAP.mrcca.resamplehz;
  MriNorm       = ANAP.mrcca.mrinorm;
  MAX_LAGS_SEC  = ANAP.mrcca.maxlagsec;
end;

for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'verbose'}
    VERBOSE = varargin{N+1};
   case {'roi','roiname','roinames'}
    RoiName = varargin{N+1};
   case {'mrisig','mri'},
    MriSig = varargin{N+1};
   case {'regtype','reg'},
    RegType = varargin{N+1};
   case {'resample','resamplehz'}
    ResampleHz = varargin{N+1};
   case {'mrinorm'}
    MriNorm = varargin{N+1};
  end
end

if isempty(ResampleHz),  ResampleHz = 'bold';  end
if ischar(RoiName),      RoiName = { RoiName };  end


Ses = goto(Ses);
grp = getgrp(Ses,ExpNo);

if VERBOSE,
  fprintf('**** %s(ExpNo=%d) ', upper(mfilename), ExpNo);
end


RES = {};

[roits mdlts] = mrcca_sigload(Ses,ExpNo,'mrisig',MriSig,'roi',RoiName,...
                              'mrinorm',MriNorm,'ResampleHz',ResampleHz, 'reg',RegType);


if isempty(roits) || isempty(roits.dat) || isempty(mdlts) || isempty(mdlts.dat),
  fprintf(' no roits/mdlts, skipping.\n');
  return
end
mdlts.dimname = {'time' 'roi' };  % this may updated by ccapreproc().


%[roits, mdlts] = ccapreproc(roits, mdlts, SIG_SELECT);

roits.dat = roits.dat';   % make (time,vox) as (vox,time)

% MODEL data
NModel = size(mdlts.dat,2);

if ndims(mdlts.dat) > 2,
  fprintf('%s(%d,%d,%d) ', upper(mdlts.dir.dname), size(mdlts.dat));
else
  fprintf('%s(%d,%d) ', upper(mdlts.dir.dname), size(mdlts.dat));
end;

mdlsz = size(mdlts.dat);
mdlts.dat = reshape(mdlts.dat,[mdlsz(1) prod(mdlsz(2:end))]);
mdlts.dat = mdlts.dat';   % make (time,roi/xxx) as (roi/xxx,time)

if roits.dx < 1,
  XLAGS = round(MAX_LAGS_SEC/roits.dx);
  XLAGS = -XLAGS:XLAGS;
else
  XLAGS = round([-MAX_LAGS_SEC:roits.dx:MAX_LAGS_SEC]/roits.dx);
end

% calculate cca
if VERBOSE,
  fprintf('tkcca(X=%dx%d,Y=%dx%d,LAGS=%d(%gs))\n',...
          size(mdlts.dat,1),size(mdlts.dat,2),size(roits.dat,1),size(roits.dat,2),...
          XLAGS(end),XLAGS(end)*roits.dx);
end

[c U V] = tkcca(mdlts.dat,roits.dat, XLAGS);

NLAGS = length(XLAGS);

if VERBOSE,  fprintf(' results...');  end

RES.session                 = Ses.name;
RES.grpname                 = grp.name;
RES.exps                    = ExpNo;
RES.canonical_correlogram   = c;
RES.dx                      = roits.dx;
RES.lags                    = XLAGS;

RES.opts.algorithm          = 'tkcca';
RES.opts.mrinorm            = MriNorm;
RES.opts.maxlags            = XLAGS(end)*roits.dx;
RES.opts.roiname            = RoiName;
RES.opts.sigs               = {MriSig, MriSig};
RES.opts.mdlname            = mdlts.name;
RES.opts.anap               = ANAP;

RES.fmri.x                  = roits.dat;
RES.fmri.weights            = V;
RES.fmri.projected          = V'*roits.dat;
RES.fmri.coords             = roits.coords;
RES.fmri.ana                = roits.ana;
RES.fmri.dx                 = roits.dx;
RES.fmri.ds                 = roits.ds;

if nanmean(RES.fmri.weights(:)) < 0,
  RES.fmri.weights   = -RES.fmri.weights;
  RES.fmri.projected = -RES.fmri.projected;
  U = -U;
end

[X, timeidx, tauidx] = embed(mdlts.dat,XLAGS);
if 0,
  tmpx = U(:)'*X;
  tmpv = corrcoef(tmpx(:),RES.fmri.projected(timeidx));
  if tmpv(1,2) < 0,
    U = -U;
  end
end

tpos = find(XLAGS*roits.dx > 0 & XLAGS*roits.dx <= 10);
U = reshape(U,[NModel NLAGS]);
Yp = RES.fmri.projected(timeidx);
Yp = Yp(:);
for iCh = 1:NModel,
  chanoffs = (iCh-1)*NLAGS;
  weights = squeeze(U(iCh,:,:));
  projected = [];
  tmpidx = 1:NLAGS:NLAGS;
  mdldat = [];
  for K = 1:NLAGS,
    projected = cat(1,projected,weights(:,K)'*X(tmpidx+K-1+chanoffs,:));
    if XLAGS(K) == 0,
      mdldat = X(tmpidx+K-1+chanoffs,:);
    end
  end

  tmpxc = corr([Yp, projected']);
  tmpxc = tmpxc(2:end,1);
  
  RES.model(iCh).weights = weights;
  RES.model(iCh).projected = projected;
  RES.model(iCh).xcorr   = tmpxc;
  RES.model(iCh).lags    = XLAGS;
  RES.model(iCh).dx      = mdlts.dx;
  RES.model(iCh).name    = mdlts.name{iCh};
  RES.model(iCh).dimname = mdlts.dimname;
  
  % convolve neural bands with univarHRF
  tmplag = find(XLAGS == 0);
  tmpsel = [1:size(mdldat,2)] + tmplag;
  for K = 1:size(mdldat,1),
    tmpdat = conv(mdldat(K,:),fliplr(weights(K,:))); % flip to match with HRF
    mdldat(K,:) = tmpdat(tmpsel);
  end
  mdldat = nanmean(mdldat,1);  % average across bands
  [tmpr tmpp] = corrcoef(Yp,mdldat);
  %RES.model(iCh).neuconv  = mdldat(:);
  RES.model(iCh).ccr_conv = tmpr(1,2);
  RES.model(iCh).ccp_conv = tmpp(1,2);
end


% check correlogram
if VERBOSE,  fprintf(' done.\n');  end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [eX, timeidx, tauidx] = embed(X,tau)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% embed the first signal in its temporal context
opt.detrend = 0;%1
opt.window	= '';%'hamming';
[D T] = size(X);
% in case tau is a scalar, make it a vector from -tau to tau
if prod(size(tau))==1,tau = -tau:tau;end
startInd 	= tau(end) + 1;
stopInd		= T + tau(1);
len			= stopInd - startInd + 1;

% create a column vector that contains the indices of the first segment
idx = repmat((startInd:stopInd)', 1, length(tau)) + repmat(tau, len, 1); 	
% create (linear) indices for the different dimensions
dim_offset = repmat( (0:D-1)*T, length(tau)*len, 1);
idx = repmat(idx(:), 1, D) + dim_offset;

% for the linear indices we need column-signals
X = X';

% get the data (D channels, segments are concatenated)
eX = X(idx);
switch opt.window
 case 'hanning'
  wind = repmat(hanning(len), 1, length(tau)*D);
 otherwise
  wind = ones(len, length(tau)*D);
end
eX = reshape(eX, len, length(tau)*D);
if opt.detrend, 
  eX = (detrend(eX).*wind)';
else
  eX = (eX.*wind)';
end
tauidx = repmat(tau',D,1); 
timeidx = startInd:stopInd;
return;
