function RES = exptkcca_cv(Ses,EXPS,varargin)
%EXPTKCCA_CV - Applies tkCCA between neural and BOLD singals (CrossValidated version).
%  RES = EXPTKCCA_CV(SESSION,EXPS,...) applies tkCCA between neural and 
%  BOLD signals (cross-validated version).
%
%  Supported options are :
%    'maxlag'     : max. lag in seconds
%    'RoiName'    : Roi name(s)
%    'AddSdf'     : includes SDF or not.
%    'ResampleHz' : resampling Hz, can be as 'bold' or any numeric
%
%  EXAMPLE :
%    res = exptkcca_cv('b06sc1',1);
%    plot_tkcca(res)
% 
%  VERSION : 
%    0.90 29.04.11 YM  modified from exptkcca.m
% 
%  See also tkcca_cv plot_tkcca exptkcca


if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end


% SET OPTIONS
RoiName         = 'all';
MriSig          = 'roiTs';
NeuSig          = 'blp';
NeuChans        = [];
NeuBands        = [];
MriNorm         = 'zscore';

VERBOSE         = 1;
ResampleHz      = 'bold';
MAX_LAGS_SEC    = 15;
ADD_SDF         = 0;

ANAP = getanap(Ses);
if isfield(ANAP,'tkcca'),
  RoiName = ANAP.tkcca.rois;
  NeuSig = ANAP.tkcca.neusig;
  MriSig = ANAP.tkcca.mrisig;
  MriNorm = ANAP.tkcca.mrinorm;
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
   case {'mrinorm'}
    MriNorm = varargin{N+1};
   case {'roi','roiname','roinames'}
    RoiName = varargin{N+1};
   case {'sdf','addsdf','add_sdf'}
    ADD_SDF = varargin{N+1};
   case {'resample','resamplehz'}
    ResampleHz = varargin{N+1};
   case {'neusig'},
    NeuSig = varargin{N+1};
   case {'mrisig'},
    MriSig = varargin{N+1};
   
   case {'ele','elename','elenames','chans','chan'}
    NeuChans = varargin{N+1};
   case {'band','bands','bandname','bandnames'}
    NeuBands = varargin{N+1};
  end
end

if isempty(ResampleHz),  ResampleHz = 'bold';  end

Ses = goto(Ses);
if ~isnumeric(EXPS),
  % EXPS as grpname...
  EXPS = getexps(Ses,EXPS);
end
grp = getgrp(Ses,EXPS(1));


if VERBOSE,
  fprintf('**** %s(NExp=%d) ', upper(mfilename), length(EXPS));
end

RES = {};
if ~isrecording(Ses,grp),
  return
end


NEU = {};  BLD = {};
for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  fprintf('\n  %2d/%d loading exp(%d)...',N,length(EXPS),ExpNo);
  
  [roits blp] = mrineu_load(Ses,ExpNo,...
                            'MriSig',MriSig,'RoiName',RoiName,...
                            'NeuSig',NeuSig,'EleName',NeuChans,'bands',NeuBands,'AddSpike',ADD_SDF,...
                            'ResampleHz',ResampleHz);
  
  if isempty(roits) || isempty(roits.dat),
    fprintf(' no roits for ''%s'', skipping.\n',RoiName);
    return
  end

% %%%%%%%%%%%%%%%%%%%5
%roits = sigfiltfilt(roits, 0.25, 'low');
%blp   = sigfiltfilt(blp,   0.25, 'low');
% %%%%%%%%%%%%%%%%%%%5

  % ======================================================================================================
  %                                           START PROCESSING....
  % ======================================================================================================
  try,
    % BOLD data
    switch lower(MriNorm),
     case 'tosdu',
      roits = xform(roits,'tosdu','blank');
     case 'tosdu-bandpass',
      roits = xform(roits,'tosdu','blank');
      roits = sigfilt(roits,[0.01 0.3], 'bandpass');
     case 'tosdu-meanOfROI',
      roits = xform(roits,'tosdu','blank');
      roits = sigfilt(roits,[0.01 0.3], 'bandpass');
      m = nanmean(roits.dat,2);
      roits.dat = roits.dat - repmat(m, [1 size(roits.dat,2)]);
     case 'zscore',
      roits.dat = zscore(roits.dat);
     case 'bandpass',
      roits.dat = zscore(roits.dat);
      roits = sigfilt(roits,[0.008 0.6], 'bandpass');
     case 'diffroimean',
      m = nanmean(roits.dat,2);
      roits.dat = roits.dat - repmat(m, [1 size(roits.dat,2)]);
     case 'zscore_diffroimean',
      roits.dat = zscore(roits.dat);
      m = nanmean(roits.dat,2);
      roits.dat =roits.dat - repmat(m, [1 size(roits.dat,2)]);
     case 'dispderiv',
      roits = dispderiv(roits,5);
    end;
    fprintf(' MriNorm(%s)...', MriNorm);

  catch,
    disp(lasterr);
    keyboard
  end;

  roits.dat = roits.dat';   % make (time,vox) as (vox,time)
  
  % NEURAL data
  NChan = size(blp.dat,2);
  NBANDS = size(blp.dat,3);
  
  fprintf(' %s[%s] ',blp.dir.dname, deblank(sprintf('%d ',size(blp.dat))));
  
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
  
  
  % make a cell array data
  NEU = cat(2,NEU,{ blp.dat });
  BLD = cat(2,BLD,{ roits.dat });

end
fprintf('\n');


if roits.dx < 1,
  XLAGS = round(MAX_LAGS_SEC/roits.dx);
  XLAGS = -XLAGS:XLAGS;
  
  % 1sec bin
  %XLAGS = round([-MAX_LAGS_SEC:MAX_LAGS_SEC]/roits.dx);
else
  XLAGS = round([-MAX_LAGS_SEC:roits.dx:MAX_LAGS_SEC]/roits.dx);
end

% calculate tkcca(cv)
if VERBOSE,
  fprintf('tkcca_cv(X=%dx%d,Y=%dx%d,LAGS=%d(%gs),N=%d)\n',...
          size(blp.dat,1),size(blp.dat,2),size(roits.dat,1),size(roits.dat,2),...
          XLAGS(end),XLAGS(end)*roits.dx,length(NEU));
end


kappas = kfromn(10.^[-3:0],2);
[r,Wx,Wy] = tkcca_cv(NEU,BLD,XLAGS,kappas);


NLAGS = length(XLAGS);

if VERBOSE,  fprintf(' results(mri)...');  end

RES.session                 = Ses.name;
RES.grpname                 = grp.name;
RES.exps                    = EXPS;
RES.canonical_correlogram   = r;
RES.dx                      = roits.dx;
RES.lags                    = XLAGS;

RES.opts.algorithm          = 'tkcca';
RES.opts.mrinorm            = MriNorm;
RES.opts.maxlags            = XLAGS(end)*roits.dx;
RES.opts.roiname            = RoiName;
RES.opts.sigs               = {NeuSig, MriSig};
RES.opts.chans              = NeuChans;
RES.opts.bands              = NeuBands;
RES.opts.anap               = ANAP;

RES.fmri.x                  = [];   % too big to keep all roits.dat...
RES.fmri.weights            = Wy;
RES.fmri.projected          = [];   % too big to keep all roits.dat (projected)...
RES.fmri.coords             = roits.coords;
RES.fmri.ana                = roits.ana;
RES.fmri.dx                 = roits.dx;
RES.fmri.ds                 = roits.ds;

if nanmean(RES.fmri.weights(:)) < 0,
  RES.fmri.weights   = -RES.fmri.weights;
  RES.fmri.projected = -RES.fmri.projected;
  Wx = -Wx;
  Wy = -Wy;
end


%[X, timeidx, tauidx] = embed(blp.dat,XLAGS);
%tmpx = Wx(:)'*X;
%tmpv = corrcoef(tmpx(:),RES.fmri.projected(timeidx));
%if tmpv(1,2) < 0,
%  Wx = -Wx;
%end



if VERBOSE,  fprintf(' results(neu)...');  end
% now compute xcorr for each exps with the same Wx/Wy
for iExp = 1:length(NEU),
  blp.dat   = NEU{iExp};   % note (chan/band,time)
  roits.dat = BLD{iExp};   % note (vox,time)
  newres = sub_ephys(blp,roits,Wx,Wy,XLAGS,NChan,NBANDS);

  if iExp == 1 || ~isfield(RES,'ephys'),
    RES.ephys = newres.ephys;
  else
    for N = 1:length(RES.ephys),
      RES.ephys(N).weights = cat(3,RES.ephys(N).weights,newres.ephys(N).weights);
      %RES.ephys(N).projected = cat(3,RES.ephys(N).projected, newres.ephys(N).projected);
      RES.ephys(N).projected = [];  % too big to keep...
      RES.ephys(N).xcorr   = cat(2,RES.ephys(N).xcorr,  newres.ephys(N).xcorr);
      RES.ephys(N).ccr_conv = cat(2,RES.ephys(N).ccr_conv, newres.ephys(N).ccr_conv);
      RES.ephys(N).ccp_conv = cat(2,RES.ephys(N).ccp_conv, newres.ephys(N).ccp_conv);
    end
  end
end

% check correlogram
if VERBOSE,  fprintf(' done.\n');  end
return




% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function RES = sub_ephys(blp,roits,Wx,Wy,XLAGS,NChan,NBANDS)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

NLAGS = length(XLAGS);


[X, timeidx, tauidx] = embed(blp.dat,XLAGS);
%tmpx = U(:)'*X;
%tmpv = corrcoef(tmpx(:),RES.fmri.projected(timeidx));
%if tmpv(1,2) < 0,
%  U = -U;
%end

tpos = find(XLAGS*roits.dx > 0 & XLAGS*roits.dx <= 10);
U = reshape(Wx,[NChan NBANDS NLAGS]);

%RES.fmri.projected = V'*roits.dat
%Yp = RES.fmri.projected(timeidx);
Yp = Wy' * roits.dat;
Yp = Yp(timeidx);
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



return



% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [eX, timeidx, tauidx] = embed(X,tau)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
