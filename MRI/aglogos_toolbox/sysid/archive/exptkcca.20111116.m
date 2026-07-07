function RES = exptkcca(Ses,ExpNo,varargin)
%EXPTKCCA - Applies tkCCA between neural and BOLD singals.
%  RES = EXPTKCCA(SESSION,EXPNO,...) applies tkCCA between neural and 
%  BOLD signals.
%
%  Supported options are :
%    'maxlag'     : max. lag in seconds
%    'RoiName'    : Roi name(s)
%    'AddSdf'     : includes SDF or not.
%    'ResampleHz' : resampling Hz, can be as 'bold' or any numeric
%
%  EXAMPLE :
%    res = exptkcca('b06sc1',1);
%    plot_tkcca(res)
% 
%  VERSION : 
%    0.90 08.09.09 YM
% 
%  See also tkcca plot_tkcca exptcor exptkcca_cv


if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end


% SET OPTIONS
RoiName         = 'all';
MriSig          = 'roiTs';
NeuSig          = 'blp';
NeuChans           = [];
NeuBands           = [];

VERBOSE         = 1;
ResampleHz      = 'bold';
MAX_LAGS_SEC    = 20;
ADD_SDF         = 0;

grp = getgrp(Ses, ExpNo);

ANAP = grp.anap;
if isfield(ANAP,'tkcca'),
  RoiName = ANAP.tkcca.rois;
  NeuSig = ANAP.tkcca.neusig;
  MriSig = ANAP.tkcca.mrisig;
  NeuChans = ANAP.tkcca.chans;
  NeuBands = ANAP.tkcca.bands;
  MAX_LAGS_SEC = ANAP.tkcca.maxlagsec;
  ADD_SDF = ANAP.tkcca.addsdf;
  ResampleHz = ANAP.tkcca.resamplehz;
end;

for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'verbose'}
    VERBOSE = varargin{N+1};
   case {'roi','roiname','roinames'}
    RoiName = varargin{N+1};
   case {'sdf','addsdf','add_sdf'}
    ADD_SDF = varargin{N+1};
   case {'resample','resamplehz'}
    ResampleHz = varargin{N+1};
   case {'neusig','neu'},
    NeuSig = varargin{N+1};
   case {'mrisig','mri'},
    MriSig = varargin{N+1};
   case {'ele','elename','elenames','chans','chan'}
    NeuChans = varargin{N+1};
    if ischar(NeuChans),
      NeuChans = find(strcmp(grp.ele.site,NeuChans));
    end;
   case {'band','bands','bandname','bandnames'}
    NeuBands = varargin{N+1};
  end
end

if isempty(ResampleHz),  ResampleHz = 'bold';  end

Ses = goto(Ses);
grp = getgrp(Ses,ExpNo);

if VERBOSE,
  fprintf('**** %s(ExpNo=%d) ', upper(mfilename), ExpNo);
end

RES = {};
if ~isrecording(Ses,grp),
  return
end

[roits blp] = mrineu_load(Ses,ExpNo,...
                          'MriSig',MriSig,'RoiName',RoiName,...
                          'NeuSig',NeuSig,'EleName',NeuChans,'bands',NeuBands,'AddSpike',ADD_SDF,...
                          'ResampleHz',ResampleHz);

if isempty(roits) || isempty(roits.dat),
  fprintf(' no roits for ''%s'', skipping.\n',RoiName);
  return
end
blp.dimname = {'time' 'chan' 'band'};  % this may updated by ccapreproc().


[roits, blp] = ccapreproc(roits, blp);
roits.dat = roits.dat';   % make (time,vox) as (vox,time)

% NEURAL data
NChan = size(blp.dat,2);
NBANDS = size(blp.dat,3);

if ndims(blp.dat) > 2,
  fprintf('%s(%d,%d,%d) ', upper(blp.dir.dname), size(blp.dat));
else
  fprintf('%s(%d,%d) ', upper(blp.dir.dname), size(blp.dat));
end;

neusz = size(blp.dat);
blp.dat = reshape(blp.dat,[neusz(1) prod(neusz(2:end))]);
blp.dat = blp.dat';   % make (time,chan/band) as (chan/band,time)

if roits.dx < 1,
  XLAGS = round(MAX_LAGS_SEC/roits.dx);
  XLAGS = -XLAGS:XLAGS;
else
  XLAGS = round([-MAX_LAGS_SEC:roits.dx:MAX_LAGS_SEC]/roits.dx);
end

% calculate cca
if VERBOSE,
  fprintf('tkcca(X=%dx%d,Y=%dx%d,LAGS=%d(%gs))\n',...
          size(blp.dat,1),size(blp.dat,2),size(roits.dat,1),size(roits.dat,2),...
          XLAGS(end),XLAGS(end)*roits.dx);
end

[c U V] = tkcca(blp.dat,roits.dat, XLAGS);

NLAGS = length(XLAGS);

if VERBOSE,  fprintf(' results...');  end

RES.session                 = Ses.name;
RES.grpname                 = grp.name;
RES.exps                    = ExpNo;
RES.canonical_correlogram   = c;
RES.dx                      = roits.dx;
RES.lags                    = XLAGS;

RES.opts.algorithm          = 'tkcca';
RES.opts.maxlags            = XLAGS(end)*roits.dx;
RES.opts.roiname            = RoiName;
RES.opts.sigs               = {NeuSig, MriSig};
RES.opts.chans              = NeuChans;
RES.opts.bands              = NeuBands;
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

[X, timeidx, tauidx] = embed(blp.dat,XLAGS);
if 0,
  tmpx = U(:)'*X;
  tmpv = corrcoef(tmpx(:),RES.fmri.projected(timeidx));
  if tmpv(1,2) < 0,
    U = -U;
  end
end

tpos = find(XLAGS*roits.dx > 0 & XLAGS*roits.dx <= 10);
U = reshape(U,[NChan NBANDS NLAGS]);
Yp = RES.fmri.projected(timeidx);
Yp = Yp(:);
for iCh = 1:NChan,
  chanoffs = (iCh-1)*NBANDS*NLAGS;
  weights = squeeze(U(iCh,:,:));
  projected = [];
  tmpidx = 1:NLAGS:NBANDS*NLAGS;
  neudat = [];
  for K = 1:NLAGS,
    projected = cat(1,projected,weights(:,K)'*X(tmpidx+K-1+chanoffs,:));
    if XLAGS(K) == 0,
      neudat = X(tmpidx+K-1+chanoffs,:);
    end
  end

  tmpxc = corr([Yp, projected']);
  tmpxc = tmpxc(2:end,1);
  
  RES.ephys(iCh).weights = weights;
  RES.ephys(iCh).projected = projected;
  RES.ephys(iCh).xcorr   = tmpxc;
  RES.ephys(iCh).lags    = XLAGS;
  RES.ephys(iCh).band    = blp.info.band;
  RES.ephys(iCh).dx      = blp.dx;
  RES.ephys(iCh).dimname = blp.dimname;
  
  % convolve neural bands with univarHRF
  tmplag = find(XLAGS == 0);
  tmpsel = [1:size(neudat,2)] + tmplag;
  for K = 1:size(neudat,1),
    tmpdat = conv(neudat(K,:),fliplr(weights(K,:))); % flip to match with HRF
    neudat(K,:) = tmpdat(tmpsel);
  end
  neudat = nanmean(neudat,1);  % average across bands
  [tmpr tmpp] = corrcoef(Yp,neudat);
  %RES.ephys(iCh).neuconv  = neudat(:);
  RES.ephys(iCh).ccr_conv = tmpr(1,2);
  RES.ephys(iCh).ccp_conv = tmpp(1,2);
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
