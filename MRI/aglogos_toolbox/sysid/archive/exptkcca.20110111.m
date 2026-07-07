function RES = exptkcca(Ses,ExpNo,varargin)
%EXPTKCCA - Applies tkCCA between neural and BOLD singals.
%  RES = EXPTKCCA(SESSION,EXPNO,...) applies tkCCA between neural and 
%  BOLD signals.
%
%  Supported options are :
%    'maxlag'     : max. lag in seconds
%    'RoiName'    : Roi name(s)
%    'EleName'    : Electrode name(s), requires grp.namech
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
%  See also tkcca plot_tkcca exptcor


if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end


% SET OPTIONS
MAX_LAGS_SEC = 20;
VERBOSE      =  1;

% preprocess
RoiName     = 'all';
EleName     = 'all';
ADD_SDF     = 0;
ResampleHz  = 'bold';
MriSig      = 'roiTs';
NeuSig      = 'blp';


for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'maxlags','maxlag'}
    MAX_LAGS_SEC = varargin{N+1};
   case {'verbose'}
    VERBOSE = varargin{N+1};
   case {'roi','roiname','roinames'}
    RoiName = varargin{N+1};
   case {'ele','elename','elenames'}
    EleName = varargin{N+1};
   case {'sdf','addsdf','add_sdf'}
    ADD_SDF = varargin{N+1};
   case {'resample','resamplehz'}
    ResampleHz = varargin{N+1};
   case {'neusig'},
    NeuSig = varargin{N+1};
   case {'mrisig'},
    MriSig = varargin{N+1};
  end
end
if isempty(ResampleHz),  ResampleHz = 'bold';  end


Ses = goto(Ses);
grp = getgrp(Ses,ExpNo);

if VERBOSE,
  fprintf('%s %s: %s ExpNo=%d',datestr(now,'HH:MM:SS'),mfilename,...
          Ses.name,ExpNo);
end

RES = {};
if ~isrecording(Ses,grp),
  return
end

[roits blp] = mrineu_load(Ses,ExpNo,'RoiName',RoiName,'EleName',EleName,'AddSpike',ADD_SDF,...
                          'ResampleHz',ResampleHz,'neusig',NeuSig,'mrisig',MriSig);

if isempty(roits) || isempty(roits.dat),
  fprintf(' no roits for ''%s'', skipping.\n',RoiName);
  return
end
if isempty(blp) || isempty(blp.dat),
  fprintf(' no blp for ''%s'', skipping.\n',EleName);
  return
end

% BOLD data 
roits.dat = zscore(roits.dat);
roits.dat = roits.dat';   % make (time,vox) as (vox,time)

% NEURAL data
NChan = size(blp.dat,2);
NBANDS = size(blp.dat,3);
for iCh = 1:NChan,
  for K = 1:NBANDS,
    blp.dat(:,iCh,K) = zscore(blp.dat(:,iCh,K));
  end
end

if 0,
  % just for test..
  %pre-whitening with lowe-frequecies
  roits.dat = roits.dat';
  for iCh = 1:NChan,
    for K = 1:3,
      a = th2poly(ar(blp.dat(:,iCh,K),5,'fb0'));
      blp.dat(:,iCh,K) = filter(a,1,blp.dat(:,iCh,K));
      roits.dat        = filter(a,1,roits.dat);
    end
  end
  roits.dat = roits.dat';
end
neusz = size(blp.dat);
blp.dat = reshape(blp.dat,[neusz(1) prod(neusz(2:end))]);
blp.dat = blp.dat';   % make (time,chan/band) as (chan/band,time)

if roits.dx < 1,
  % 1sec bin
  XLAGS = round([-MAX_LAGS_SEC:MAX_LAGS_SEC]/roits.dx);
else
  XLAGS = round([-MAX_LAGS_SEC:roits.dx:MAX_LAGS_SEC]/roits.dx);
end

if VERBOSE,
  fprintf(' maxlag=%gs:',XLAGS(end)*roits.dx);
end

% calculate cca
if VERBOSE,
  fprintf(' tkcca(X=%dx%d,Y=%dx%d)...',...
          size(blp.dat,1),size(blp.dat,2),size(roits.dat,1),size(roits.dat,2));
end

[c U V kappaOpt] = tkcca(blp.dat,roits.dat, XLAGS);

NLAGS = length(XLAGS);

if VERBOSE,  fprintf(' results...');  end

RES.session = Ses.name;
RES.grpname = grp.name;
RES.exps    = ExpNo;
RES.canonical_correlogram = c;
RES.dx      = roits.dx;
RES.lags    = XLAGS;

RES.opts.algorithm = 'tkcca';
RES.opts.maxlags   = XLAGS(end)*roits.dx;
RES.opts.roiname   = RoiName;
RES.opts.elename   = EleName;

RES.fmri.x = roits.dat;
RES.fmri.weights   = V;
RES.fmri.projected = V'*roits.dat;
RES.fmri.coords  = roits.coords;
RES.fmri.ana     = roits.ana;
RES.fmri.dx      = roits.dx;
RES.fmri.ds      = roits.ds;

if nanmean(RES.fmri.weights(:)) < 0,
  RES.fmri.weights = -RES.fmri.weights;
  RES.fmri.projected = -RES.fmri.projected;
  U = -U;
end

[X, timeidx, tauidx] = embed(blp.dat,XLAGS);
%tmpx = U(:)'*X;
%tmpv = corrcoef(tmpx(:),RES.fmri.projected(timeidx));
%if tmpv(1,2) < 0,
%  U = -U;
%end

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
  RES.ephys(iCh).elename = blp.elename{iCh};
  
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
