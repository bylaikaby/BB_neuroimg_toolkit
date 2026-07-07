function RES = expmrcca_cv(Ses,GrpExp,varargin)
%EXPMRCCA_CV - Applies tkCCA to BOLD signals with the given ROIs.
%  RES = EXPMRCCA_CV(SESSION,Grp/EXPS,...) applies tkCCA to BOLD signals
%  with the given ROIs (cross-validated version).
%
%  Supported options are :
%    'maxlag'     : max. lag in seconds
%    'RoiName'    : Roi name(s)
%    'MriSig'     : MRI signal
%    'MriNorm'    : MRI signal normalization
%    'ResampleHz' : resampling Hz, can be as 'bold' or any numeric
%
%  EXAMPLE :
%    res = expmrcca_cv('e10ha1','spont','mrisig','roiTs','roi',{'HP' 'hele'});
%    plot_mrcca(res)
% 
%  VERSION : 
%    0.90 08.01.13 YM  modified from exptkcca_cv.m
% 
%  See also tkcca_cv plot_mrcca expmrcca


if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end


% SET OPTIONS
RoiName         = 'all';
MriSig          = 'roiTs';
MriNorm         = 'zscore';

VERBOSE         = 1;
ResampleHz      = 'bold';
MAX_LAGS_SEC    = 15;

if isnumeric(GrpExp),
  ANAP = getanap(Ses,GrpExp(1));
else
  ANAP = getanap(Ses,GrpExp);
end
if isfield(ANAP,'mrcca'),
  RoiName = ANAP.mrcca.rois;
  MriSig  = ANAP.mrcca.mrisig;
  MriNorm = ANAP.mrcca.mrinorm;
  MAX_LAGS_SEC = ANAP.mrcca.maxlagsec;
  ResampleHz = ANAP.mrcca.resamplehz;
end;

for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'verbose'}
    VERBOSE = varargin{N+1};
   case {'mrinorm'}
    MriNorm = varargin{N+1};
   case {'roi','roiname','roinames'}
    RoiName = varargin{N+1};
   case {'resample','resamplehz'}
    ResampleHz = varargin{N+1};
   case {'mrisig'},
    MriSig = varargin{N+1};
  end
end

if isempty(ResampleHz),  ResampleHz = 'bold';  end
if ischar(RoiName),      RoiName = { RoiName };  end
if length(RoiName) == 1,
  error('\n ERROR %s: length(RoiName) must be > 1.\n',mfilename);
end


Ses = goto(Ses);
if ~isnumeric(GrpExp),
  % GrpExp as grpname...
  EXPS = getexps(Ses,GrpExp);
else
  % GrpExp as EXPS
  EXPS = GrpExp;
end
grp = getgrp(Ses,EXPS(1));


if VERBOSE,
  fprintf('**** %s(NExp=%d) ', upper(mfilename), length(EXPS));
end

RES = {};

MDL = {};  BLD = {};
for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  fprintf('\n  %2d/%d loading exp(%d)...',N,length(EXPS),ExpNo);
  
  
  [roits mdlts] = mrcca_sigload(Ses,ExpNo,'mrisig',MriSig,'roi',RoiName,...
                                'mrinorm',MriNorm,'ResampleHz',ResampleHz);
  
  if isempty(roits) || isempty(roits.dat),
    fprintf(' no roits for ''%s'', skipping.\n',RoiName);
    return
  end
  
  if 1,
    %[roits, mdlts] = ccapreproc(roits, mdlts, SIG_SELECT);
  end;

% %%%%%%%%%%%%%%%%%%%5
%roits = sigfiltfilt(roits, 0.25, 'low');
%mdlts   = sigfiltfilt(mdlts,   0.25, 'low');
% %%%%%%%%%%%%%%%%%%%5

  % ======================================================================================================
  %                                           START PROCESSING....
  % ======================================================================================================

  roits.dat = roits.dat';   % make (time,vox) as (vox,time)
  
  % Model data
  NModel = size(mdlts.dat,2);
  
  fprintf(' %s[%s] ',mdlts.dir.dname, deblank(sprintf('%d ',size(mdlts.dat))));
  
  for iCh = 1:NModel,
    mdlts.dat(:,iCh) = zscore(mdlts.dat(:,iCh));
  end

  if 0,
    % just for test..
    %pre-whitening with lowe-frequecies
    roits.dat = roits.dat';
    for iCh = 1:NModel,
      for K = 1:3,
        a = th2poly(ar(mdlts.dat(:,iCh,K),5,'fb0'));
        mdlts.dat(:,iCh,K) = filter(a,1,mdlts.dat(:,iCh,K));
        roits.dat        = filter(a,1,roits.dat);
      end
    end
    roits.dat = roits.dat';
  end

  mdlsz = size(mdlts.dat);
  mdlts.dat = reshape(mdlts.dat,[mdlsz(1) prod(mdlsz(2:end))]);
  mdlts.dat = mdlts.dat';   % make (time,chan/band) as (chan/band,time)
  
  
  % make a cell array data
  MDL = cat(2,MDL,{ mdlts.dat });
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
          size(mdlts.dat,1),size(mdlts.dat,2),size(roits.dat,1),size(roits.dat,2),...
          XLAGS(end),XLAGS(end)*roits.dx,length(MDL));
end


kappas = kfromn(10.^[-3:0],2);
ff = parzenwin(5);
for i=1:numel(MDL)
%	MDL{i} = mean(cat(3,MDL{i}(1:10,:),MDL{i}(11:20,:),MDL{i}(21:30,:)),3);
%	MDL{i}([1 10],:) = [];
	MDL{i} = MDL{i} - repmat(mean(MDL{i}),size(MDL{i},1),1);
%	MDL{i} = filtfilt(ff,1,MDL{i}')';
	BLD{i} = BLD{i} - repmat(mean(BLD{i}),size(BLD{i},1),1);
%	BLD{i} = filtfilt(ff,1,BLD{i}')';
end

[r,Wx,Wy] = tkcca_cv(MDL,BLD,XLAGS,kappas);


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
RES.opts.sigs               = {MriSig, MriSig};
RES.opts.mdlname            = mdlts.name;
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


%[X, timeidx, tauidx] = embed(mdlts.dat,XLAGS);
%tmpx = Wx(:)'*X;
%tmpv = corrcoef(tmpx(:),RES.fmri.projected(timeidx));
%if tmpv(1,2) < 0,
%  Wx = -Wx;
%end



if VERBOSE,  fprintf(' results(mdl)...');  end
% now compute xcorr for each exps with the same Wx/Wy
for iExp = 1:length(MDL),
  mdlts.dat = MDL{iExp};   % note (roi,time)
  roits.dat = BLD{iExp};   % note (vox,time)
  newres = sub_model(mdlts,roits,Wx,Wy,XLAGS,NModel);

  if iExp == 1 || ~isfield(RES,'model'),
    RES.model = newres.model;
  else
    for N = 1:length(RES.model),
      RES.model(N).weights = cat(3,RES.model(N).weights,newres.model(N).weights);
      %RES.model(N).projected = cat(3,RES.model(N).projected, newres.model(N).projected);
      RES.model(N).projected = [];  % too big to keep...
      RES.model(N).xcorr   = cat(2,RES.model(N).xcorr,  newres.model(N).xcorr);
      RES.model(N).ccr_conv = cat(2,RES.model(N).ccr_conv, newres.model(N).ccr_conv);
      RES.model(N).ccp_conv = cat(2,RES.model(N).ccp_conv, newres.model(N).ccp_conv);
    end
  end
end

% check correlogram
if VERBOSE,  fprintf(' done.\n');  end
return




% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function RES = sub_model(mdlts,roits,Wx,Wy,XLAGS,NModel)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

NLAGS = length(XLAGS);


[X, timeidx, tauidx] = embed(mdlts.dat,XLAGS);
%tmpx = U(:)'*X;
%tmpv = corrcoef(tmpx(:),RES.fmri.projected(timeidx));
%if tmpv(1,2) < 0,
%  U = -U;
%end

tpos = find(XLAGS*roits.dx > 0 & XLAGS*roits.dx <= 10);
U = reshape(Wx,[NModel NLAGS]);

%RES.fmri.projected = V'*roits.dat
%Yp = RES.fmri.projected(timeidx);
Yp = Wy' * roits.dat;
Yp = Yp(timeidx);
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
  RES.model(iCh).name    = mdlts.name{iCh};
  RES.model(iCh).dx      = mdlts.dx;
  
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
