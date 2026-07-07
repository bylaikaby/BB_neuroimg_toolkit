function RES = fidtkcca(Ses,ExpNo,varargin)
%FIDTKCCA - Run tkCCA for FID and neural signals.
%  RES = FIDTKCCA(Ses,ExpNo,...) runs tkCCA for FID and neural signals.
%
%  Supported options are :
%    'MriSig'     : MRI signal
%    'MriNrom'    : normalization for MriSig
%    'NeuSig'     : NEU signal
%    'chans'      : Electrode indices/names (may require grp.namech)
%    'bands'      : Band indices/names for the neural signal
%    'AddSdf'     : includes SDF or not.
%    'NeuNorm'    : normalization for NeuSig
%    'ResampleHz' : resampling Hz, can be as 'bold' or any numeric
%
%  Parameters can be set as ANAP.fidtkcca or GRP.().anap.fidtkcca
%    ANAP.fidtkcca.neusig        = 'blp';
%    ANAP.fidtkcca.neu_chans     = {'pl.avr' 'cx.avr'};  % ".avr" does mean().
%    ANAP.fidtkcca.neu_bands     = {'theta' 'spindle' 'sigma' 'gamma' 'ripple' 'mua'};
%    ANAP.fidtkcca.neu_addsdf    = 0;
%    ANAP.fidtkcca.neu_norm      = 'sdu';
%    ANAP.fidtkcca.mrisig        = 'tcMrs';
%    ANAP.fidtkcca.fid_effwin    = [70:230];
%    ANAP.fidtkcca.fid_apodize   = 'hanning';
%    ANAP.fidtkcca.fid_bellwidth = 0.75;
%    ANAP.fidtkcca.fid_norm      = 'sdu';
%    ANAP.fidtkcca.resamplehz    = 'mrs'; % takes forever...
%    ANAP.fidtkcca.resamplehz    = 2;
%    ANAP.fidtkcca.maxlagsec     = 8.0;
%
%  EXAMPLE :
%
%  VERSION :
%    0.90 18.05.14 YM  pre-release
%
%  See also tkcca plot_fidtkcca

if nargin < 2,  eval(['help ' mfilename]); return;  end


% SET OPTIONS
VERBOSE         = 1;
MriSig          = 'tcMrs';
NeuSig          = 'blp';
NeuChans        = [];
NeuBands        = [];
NeuAddSdf       = 0;
NeuNorm         = 'sdu';
FidEffWin       = [];
FidApodize      = 'hanning';
FidBellWidth    = 0.75;
FidNorm         = 'sdu';

ResampleHz      = 'mrs';
MaxLagsSec      = 20;


ANAP = getanap(Ses,ExpNo);
if isfield(ANAP,'fidtkcca'),
  NeuSig        = ANAP.fidtkcca.neusig;
  MriSig        = ANAP.fidtkcca.mrisig;

  NeuChans      = ANAP.fidtkcca.neu_chans;
  NeuBands      = ANAP.fidtkcca.neu_bands;
  NeuAddSdf       = ANAP.fidtkcca.neu_addsdf;
  NeuNorm       = ANAP.fidtkcca.neu_norm;
  
  FidEffWin     = ANAP.fidtkcca.fid_effwin;
  FidApodize    = ANAP.fidtkcca.fid_apodize;
  FidBellWidth  = ANAP.fidtkcca.fid_bellwidth;
  FidNorm       = ANAP.fidtkcca.fid_norm;

  ResampleHz    = ANAP.fidtkcca.resamplehz;
  MaxLagsSec  = ANAP.fidtkcca.maxlagsec;
end;

for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'verbose'}
    VERBOSE = varargin{N+1};
   case {'neusig','neu'},
    NeuSig = varargin{N+1};
   case {'ele','elename','elenames','chans','chan','neuchans' 'neu_chans'}
    NeuChans = varargin{N+1};
   case {'band','bands','bandname','bandnames','neubands','neu_bands'}
    NeuBands = varargin{N+1};
   case {'sdf','addsdf','add_sdf','add_spike','addspike','neu_addsdf' ,'neuaddsdf'}
    NeuAddSdf = varargin{N+1};
   case {'neunorm','neu_norm'}
    NeuNorm = varargin{N+1};
   
   case {'mrisig','mri','fidsig','fid'},
    MriSig = varargin{N+1};
   case {'fideffwin','fid_effwin'}
    FidEffWin = varargin{N+1};
   case {'fidapod' 'fid_apod' 'fidapodize' 'fid_apodize' 'apodize'}
    FidApodize = varargin{N+1};
   case {'fidbellwidth' 'fid_bellwidth'}
    FidBellWidth = varargin{N+1};
   case {'fidnorm','fid_norm' 'mrinorm' 'mri_norm'}
    FidNorm = varargin{N+1};
  
   case {'resample','resamplehz'}
    ResampleHz = varargin{N+1};
   case {'maxlag','maxlagsec'}
    MaxLagsSec = varargin{N+1};
  end
end

if isempty(ResampleHz),  ResampleHz = 'mrs';  end

Ses = goto(Ses);
grp = getgrp(Ses,ExpNo);

if VERBOSE,
  %fprintf(' %s',datestr(now,'HH:MM:SS'));
end


if VERBOSE,  fprintf(' load(%s).',MriSig);  end
mrs = sigload(Ses,ExpNo,MriSig);
% do some processing for the mrs signal =========================
% mrs.dat must be (time,vox,...)
if strcmpi(MriSig,'tcMrs')
  if any(FidEffWin)
    if VERBOSE,  fprintf(' effwin.');  end
    mrs.dat = mrs.dat(FidEffWin,:,:);
  end
  
  if VERBOSE,  fprintf(' amp/phs.');  end
  clear tmpdat;
  tmpdat(:,:,:,1) = abs(mrs.dat);
  tmpdat(:,:,:,2) = unwrap(angle(mrs.dat),[],1);
  mrs.dat = tmpdat;
  
  if strcmpi(FidApodize,'hanning')
    if VERBOSE,  fprintf(' apod(hanning).');  end
    L = size(mrs.dat,1);
    csbf = hanning(round(2*L*FidBellWidth));
    csbf = csbf(round(length(csbf)/2):end);
    if length(csbf) > L,
      csbf = csbf(1:L);
    else
      csbf(end+1:L) = 0;
    end
    mrs.dat = bsxfun(@times,mrs.dat,csbf);
  end
  
  
  if VERBOSE,  fprintf(' cv.');  end
  s = nanstd(mrs.dat,[],1);   % (sp,vox,time,amp/phs)
  m = nanmean(mrs.dat,1);     % (sp,vox,time,amp/phs)
  mrs.dat = bsxfun(@rdivide,s,m);       % (sp,vox,time,amp/phs)
  tmpsz = size(mrs.dat);
  mrs.dat = reshape(mrs.dat,tmpsz(2:end));  % (vox,time,amp/phs)
  mrs.dat = permute(mrs.dat,[2 1 3]);  % (time,vox,amp/phs)
  if VERBOSE,  fprintf(' detrend.');  end
  mrs = sigdetrend(mrs);
end

switch lower(FidNorm)
 case {'sd' 'sdu' 'zscore'}
  if VERBOSE,  fprintf(' %s.',FidNorm);  end
  mrs.dat = zscore(mrs.dat,[],1);
end


% ===============================================================

if VERBOSE,
  fprintf('\n load(%s,sdf=%d).',NeuSig,NeuAddSdf);
end
[blp, spk] = sub_neuload(Ses,ExpNo,NeuSig,NeuChans,NeuBands,NeuAddSdf);
if VERBOSE,
  tmptxt = '';
  for N = 1:length(blp.elename)
    tmptxt = [tmptxt ' ' blp.elename{N}];
  end
  fprintf(' ch[%s].',strtrim(tmptxt));
  tmptxt = '';
  for N = 1:length(blp.info.band)
    tmptxt = [tmptxt ' ' blp.info.band{N}{2}];
  end
  fprintf(' band[%s].',strtrim(tmptxt));
  clear tmptxt;
end

switch lower(NeuNorm)
 case {'sd' 'sdu' 'zscore'}
  if VERBOSE,  fprintf(' %s.',NeuNorm);  end
  blp.dat = zscore(blp.dat,[],1);
  if NeuAddSdf && ~isempty(spk)
    spk.dat = zscore(spk.dat,[],1);
  end
end


if ischar(ResampleHz),
  switch lower(ResampleHz),
   case {'mri','bold','roits','mrs'}
    if ~isempty(blp),
      if VERBOSE,  fprintf(' resampling(%gHz).',1/mrs.dx);  end
      blp   = sigresample(blp,mrs.dx);
    end
   case {'neu','blp','neural'}
    if ~isempty(mrs),
      if VERBOSE,  fprintf(' resampling(%gHz).',1/blp.dx);    end
      mrs = sigresample(mrs,blp.dx);
    end
   otherwise
    ResampleHz = [];
  end
elseif isnumeric(ResampleHz) && any(ResampleHz),
  if VERBOSE,
    fprintf(' resampling(%gHz).',ResampleHz);
  end
  if ~isempty(blp),
    %blp = sigresample(blp,1/ResampleHz);
    blp = siginterp1(blp,1/ResampleHz);
  end
  if ~isempty(mrs),
    %mrs = sigresample(mrs,1/ResampleHz);
    mrs = siginterp1(mrs,1/ResampleHz);
  end
end




% Add Sdf if needed
if NeuAddSdf && ~isempty(spk) && ~isempty(blp),
  %spk = sigresample(spk,blp.dx);
  spk = siginterp1(spk,blp.dx);  % since spk.dat is in Hz, better to use interp1.
  npts = min([size(blp.dat,1) size(spk.dat,1)]);
  blp.dat = blp.dat(1:npts,:,:);
  spk.dat = spk.dat(1:npts,:);
  blp.dat = cat(3,blp.dat,spk.dat);
  blp.info.band{end+1} = {[500 round(1/spk.dt/2)]    'spk'    'SPK'    [1/spk.dx]};
end

% check time length
if any(ResampleHz) && ~isempty(mrs) && ~isempty(blp),
  npts = min([size(blp.dat,1) size(mrs.dat,1)]);
  blp.dat   = blp.dat(1:npts,:,:);
  mrs.dat = mrs.dat(1:npts,:,:);
  clear npts;
end





% MRI data
mrssz = size(mrs.dat);
mrs.dat = reshape(mrs.dat,[mrssz(1) prod(mrssz(2:end))]);
mrs.dat = mrs.dat';   % make (time,vox,amp/phs) as (vox*amp/phs,time)

% NEURAL data
NChan = size(blp.dat,2);
NBANDS = size(blp.dat,3);

neusz = size(blp.dat);
blp.dat = reshape(blp.dat,[neusz(1) prod(neusz(2:end))]);
blp.dat = blp.dat';   % make (time,chan/band) as (chan/band,time)

XLAGS = -round(MaxLagsSec/mrs.dx):round(MaxLagsSec/mrs.dx);
% if mrs.dx < 1,
%   XLAGS = round(MaxLagsSec/mrs.dx);
%   XLAGS = -XLAGS:XLAGS;
% else
%   XLAGS = round([-MaxLagsSec:mrs.dx:MaxLagsSec]/mrs.dx);
% end


% calculate cca
if VERBOSE,
  fprintf(' tkcca(X=%dx%d,Y=%dx%d,LAGS=%d(%gs))\n',...
          size(blp.dat,1),size(blp.dat,2),size(mrs.dat,1),size(mrs.dat,2),...
          XLAGS(end),XLAGS(end)*mrs.dx);
end

% NOTE :
%   tkcca(X=24x663, Y=2x663, LAGS=4(4s))   takes  83sec.
%   tkcca(X=16x1325,Y=2x1325,LAGS=20(10s)) takes 445sec
t0 = tic;
[c U V] = tkcca(blp.dat,mrs.dat, XLAGS);
if VERBOSE
  fprintf('   tkcca-%gs. ',toc(t0));
end

if VERBOSE,  fprintf(' results...');  end

NLAGS = length(XLAGS);

RES.session                 = Ses.name;
RES.grpname                 = grp.name;
RES.exps                    = ExpNo;
RES.canonical_correlogram   = c;
RES.dx                      = mrs.dx;
RES.lags                    = XLAGS;

RES.opts.algorithm          = 'tkcca';
RES.opts.maxlags            = XLAGS(end)*mrs.dx;
RES.opts.sigs               = {NeuSig, MriSig};
RES.opts.elename            = blp.elename;
RES.opts.neu_chans          = NeuChans;
RES.opts.neu_bands          = NeuBands;
RES.opts.neu_norm           = NeuNorm;
RES.opts.fid_effwin         = FidEffWin;
RES.opts.fid_apodize        = FidApodize;
RES.opts.fid_bellwidth      = FidBellWidth;
RES.opts.fid_norm           = FidNorm;

RES.fmri.x                  = mrs.dat;
RES.fmri.weights            = reshape(V,mrssz(2:end));
RES.fmri.projected          = V'*mrs.dat;
RES.fmri.dx                 = mrs.dx;
RES.fmri.ds                 = mrs.ds;

% if nanmean(RES.fmri.weights(:)) < 0,
%   RES.fmri.weights   = -RES.fmri.weights;
%   RES.fmri.projected = -RES.fmri.projected;
%   U = -U;
% end

[X, timeidx, tauidx] = embed(blp.dat,XLAGS);
if 0,
  tmpx = U(:)'*X;
  tmpv = corrcoef(tmpx(:),RES.fmri.projected(timeidx));
  if tmpv(1,2) < 0,
    U = -U;
  end
end

tpos = find(XLAGS*mrs.dx > 0 & XLAGS*mrs.dx <= 10);
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
  RES.ephys(iCh).ele     = blp.elename{iCh};
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


% check correlogram
if VERBOSE,  fprintf(' done.\n');  end

return




% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [blp spk] = sub_neuload(Ses,GrpExp,SigName,EleName,BandName,AddSpike)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
blp = [];
spk = [];
  
grp = getgrp(Ses,GrpExp);

blp = sigload(Ses,GrpExp,SigName);
if any(strcmpi(SigName,{'ClnSpc','tClnSpc'})),
  blp = sub_spc2blp(blp);
end

% overwrite grp.namech with grp.ele.site....
if isfield(grp,'ele') && isfield(grp.ele,'site') && ~isempty(grp.ele.site),
  grp.namech = grp.ele.site;
end
if ~isfield(grp,'namech'),
  for N = 1:size(blp.dat,2), grp.namech{N} = sprintf('ch%d',N);  end
end

if any(strcmpi(EleName,'all')) || isempty(EleName),
  EleName = 'all';
  SELCH   = { 1:size(blp.dat,2) };
  EleLabel = grp.namech;
elseif any(strcmpi(EleName,'sitegrouped')) || any(strcmpi(EleName,'site.avr')),
  tmpele = unique(grp.ele.site);
  EleLabel = cell(1,length(tmpele));
  clear tmp;
  for K=1:length(tmpele),
    SELCH{K} = find(strcmp(grp.ele.site,tmpele{K}));
    EleLabel{K} = sprintf('%s.avr',tmpele{K});
  end
elseif any(strcmpi(EleName,'hipgrouped')),
  tmpele = {'pl' 'sr'};
  SELCH = {};
  EleLabel = {};
  for K = 1:length(tmpele)
    tmpidx = find(strcmp(grp.ele.site,tmpele{K}));
    if isempty(tmpidx),  continue;  end
    SELCH{end+1} = tmpidx;
    EleLabel{end+1} = sprintf('%s.avr',tmpele{K});
  end
elseif strcmp(EleName,'cxgrouped'),
  tmpele = {'cx'};
  SELCH = {};
  EleLabel = {};
  for K = 1:length(tmpele)
    tmpidx = find(strcmp(grp.ele.site,tmpele{K}));
    if isempty(tmpidx),  continue;  end
    SELCH{end+1} = tmpidx;
    EleLabel{end+1} = sprintf('%s.avr',tmpele{K});
  end
elseif isnumeric(EleName),
  SELCH    = { EleName };
  EleLabel = grp.namech(SELCH);
else
  %if ~isfield(grp,'namech'),
  %  error('%s(%s) doesn''t have grp.namech.\n',Ses.name,grp.name);
  %end
  if ischar(EleName),  EleName = { EleName };  end
  SELCH    = {};
  EleLabel = [];
  for K = 1:length(EleName)
    tmpidx = sub_find_elechan(grp.ele.site,EleName{K});
    if any(tmpidx)
      SELCH{end+1} = tmpidx;
      if any(strfind(EleName{K},'.avr')) || any(strfind(EleName{K},'.med'))
        % averaged
        EleLabel{end+1} = EleName{K};
      else
        % no average
        for E = 1:length(tmpidx)
          EleLabel{end+1} = EleName{K};
        end
      end
    end
  end
  
  if isempty(SELCH),
    error('\n ERROR %s: no channel found for ''%s''.\n',mfilename,sub_text(EleName));
    %return;
  end
end

% channel selection
tmpsz = size(blp.dat);
blp.dat = reshape(blp.dat,[tmpsz(1) tmpsz(2) prod(tmpsz(3:end))]);
newdat = [];
for N = 1:length(SELCH),
  tmpdat = blp.dat(:,SELCH{N},:);
  if any(strfind(EleLabel{N},'.avr')),
    tmpdat = nanmean(tmpdat,2);
  elseif any(strfind(EleLabel{N},'.med'))
    tmpdat = nanmedian(tmpdat,2);
  end
  newdat = cat(2,newdat,tmpdat);
end
tmpsz(2) = size(newdat,2);
newdat = reshape(newdat,tmpsz);
blp.dat = newdat;
clear newdat;

blp.elename = EleLabel;


% band selection
if any(strcmpi(BandName,'all')) || isempty(BandName),
  bandidx = 1:size(blp.dat,3);
elseif isnumeric(BandName),
  bandidx = BandName;
else
  bandidx = [];
  for K = 1:length(blp.info.band),
    %if any(strcmpi(blp.info.band{K}{2},{'dethe','alpha','nm1','nm2','gamma','mua'})),
    if any(strcmpi(blp.info.band{K}{2},BandName)),
      bandidx(end+1) = K;
    end
  end
end
  
blp.dat = blp.dat(:,:,bandidx);
blp.info.band = blp.info.band(bandidx);
clear bandidx;

if AddSpike
  spk = sigload(Ses,GrpExp,'Spkt');
  spk.times = {};
  
  % channel selection
  tmpsz = size(spk.dat);
  spk.dat = reshape(spk.dat,[tmpsz(1) tmpsz(2) prod(tmpsz(3:end))]);
  newdat = [];
  for N = 1:length(SELCH),
    tmpdat = spk.dat(:,SELCH{N});
    if any(strfind(EleLabel{N},'.avr')),
      tmpdat = nanmean(tmpdat,2);
    elseif any(strfind(EleLabel{N},'.med'))
      tmpdat = nanmedian(tmpdat,2);
    end
    newdat = cat(2,newdat,tmpdat);
  end
  tmpsz(2) = size(newdat,2);
  newdat = reshape(newdat,tmpsz);
  spk.dat = newdat;
  clear newdat;
  
  spk.elename = EleLabel;
  
  spk.dat = spk.dat/spk.dx;  % convert into in Hz
end
return


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function blp = sub_spc2blp(ClnSpc)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
band = { { [   1    4] 'delta'  },...
         { [   4    8] 'theta'  },...
         { [   8   12] 'alpha'  },...
         { [  12   24] 'nm1'    },...
         { [  24   40] 'nm2'    },...
         { [   1   50] 'swave'  },...
         { [  40   60] 'gamma1' },...
         { [  60   80] 'gamma2' },...
         { [  60   80] 'gamma3' },...
         { [ 100  120] 'gamma4' },...
         { [ 120  250] 'ripple' },...
         { [ 250  800] 'ripple' },...
         { [1000 3000] 'mua'    }  };

% ClnSpc.dat as (t,f,chan)
% blp.dat as (t,chan,band)
blp.session = ClnSpc.session;
blp.grpname = ClnSpc.grpname;
blp.ExpNo   = ClnSpc.ExpNo;
blp.dat     = zeros(size(ClnSpc.dat,1),size(ClnSpc.dat,3),length(band));
blp.dx      = ClnSpc.dx(1)';
blp.dxorg   = ClnSpc.dxorg;
blp.stm     = ClnSpc.stm;
blp.info.band = band;

freq = [0:size(ClnSpc.dat,2)-1]*ClnSpc.dx(2);
for N = 1:length(band),
  tmpf = band{N}{1};
  tmpi = find(freq >= tmpf(1) & freq <= tmpf(2));
  tmpdat = squeeze(nanmean(ClnSpc.dat(:,tmpi,:),2));
  blp.dat(:,:,N) = tmpdat;
end
return



% =============================================================================================
function selch = sub_find_elechan(EleSites,EleName)
% =============================================================================================

selch = [];

EleName = strrep(EleName,'.avr','');

% supports '*' and '?'
if any(strfind(EleName,'*')) || any(strfind(EleName,'?')),
  tmpEleName = EleName;
  EleName = strrep(EleName,'*','.*');
  EleName = strrep(EleName,'?','.');
  for N = 1:length(EleSites),
    if isequal(regexpi(EleSites,EleName),1),
      selch(end+1) = N;
    end
  end
  EleName = tmpEleName;  clear tmpEleName;
else
  for N = 1:length(EleSites),
    if any(strcmpi(EleSites{N},EleName)),
      selch(end+1) = N;
    end
  end
end

return


% =============================================================================================
function [eX, timeidx, tauidx] = embed(X,tau)
% =============================================================================================
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
