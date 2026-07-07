function RES = exptcor(Ses,ExpNo,varargin)
%EXPTCOR - Computes temporal correlation between neural and BOLD signals
%  RES = EXPTCOR(SESSION,EXPNO,...) computes temporal correlation between
%  neural and BOLD signals.
%
%  Supported options are :
%    'maxlag'     : max. lag in seconds
%    'RoiName'    : Roi name(s)
%    'MriSig'     : MRI signal
%    'NeuSig'     : NEU signal
%    'chans'      : Electrode indices/names (may require grp.namech)
%    'bands'      : Band indices/names for the neural signal
%    'AddSdf'     : includes SDF or not.
%    'ResampleHz' : resampling Hz, can be as 'bold' or any numeric
%    'Plot'       : plot results or not
%
%  NOTE :
%    -lags mean NeuSig preceeds MriSig.
%    +lags mean NeuSig follows  MriSig.
%    For easy comparison with HRF, flip the lags (lags=-lags) so that
%    +lags mean MriSig follows NeuSig.  See plot_tkcca() for detail.
%
%  EXAMPLE :
%    res = exptcor('b06sc1',1);
%    plot_tkcca(res)
% 
%  VERSION : 
%    0.90 31.07.09 YM  modified from do_cca_ym.m
%    0.91 12.02.12 YM  updated to make similar as exptkcca().
% 
%  See also sestcor exptkcca plot_tkcca


if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end


% opts = {
%     'lambda'    10.^[-[1:3]]'
%     'lag'		20 % in secs
%     }';
% opts = resolveopts(varargin, opts);

% SET OPTIONS
ALGORITHM    = 'corrcoef';  % corrcoef | cov
MAX_LAGS_SEC = 20;
EACH_VOXEL   =  0;  % must be always ZERO.
VERBOSE      =  1;
% preprocess
RoiName      = 'all';
MriSig       = 'roiTs';
NeuSig       = 'blp';
NeuChans     = [];
NeuBands     = [];
ResampleHz   = 'bold';
ADD_SDF      = 0;
SIG_SELECT   = 'all';
AverageBLPChannels = 0;


for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'maxlags','maxlag'}
    MAX_LAGS_SEC = varargin{N+1};
   case {'algorithm','method'}
    ALGORITHM = varargin{N+1};
   case {'each' 'eachvoxel' 'eachvox'}
    EACH_VOXEL = varargin{N+1};
   case {'verbose'}
    VERBOSE = varargin{N+1};
   case {'roi','roiname','roinames'}
    RoiName = varargin{N+1};
   case {'neusig','neu'},
    NeuSig = varargin{N+1};
   case {'mrisig','mri'},
    MriSig = varargin{N+1};
   case {'ele','elename','elenames','chans','chan'}
    NeuChans = varargin{N+1};
   case {'band','bands','bandname','bandnames'}
    NeuBands = varargin{N+1};
   case {'sdf','addsdf','add_sdf','add_spike','addspike'}
    ADD_SDF = varargin{N+1};
   case {'resample','resamplehz'}
    ResampleHz = varargin{N+1};
   case {'sigsel','sel'},
    SIG_SELECT = varargin{N+1};    
  case {'average'}
    AverageBLPChannels = varargin{N+1};
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

[roits blp] = mrineu_load(Ses,ExpNo,...
                          'MriSig',MriSig,'RoiName',RoiName,...
                          'NeuSig',NeuSig,'EleName',NeuChans,'bands',NeuBands,'AddSpike',ADD_SDF,...
                          'ResampleHz',ResampleHz);

if isempty(roits) || isempty(roits.dat),
  fprintf(' no roits for ''%s'', skipping.\n',sub_text(RoiName));
  return
end
if isempty(blp) || isempty(blp.dat),
  fprintf(' no blp for ''%s'', skipping.\n',sub_text(NeuChans));
  return
end

if AverageBLPChannels,
  % THIS IS COMPLETE GARGABE... WE SHOULD FIND A WAY TO DO THIS RIGHT OR JUST FORGET ABOUT
  % IT. HERE IT'S DONE TO QUICKLY CHECK DIFFERENCES IN COV BETWEEN DIFFERENT ROIS... (RIPPLE STUFF)
  blp.dat = nanmean(nanmean(blp.dat,2),4);
  blp.dat = nanmean(blp.dat(:,:,[7 8]),3);
  blp.info.band = blp.info.band(7);
  blp.elename   = { 'average' };
end;


blp.dimname = {'time' 'chan' 'band'};  % this may updated by ccapreproc().

[roits, blp] = ccapreproc(roits, blp, SIG_SELECT);


d = {};
% BOLD data 
roits.dat = zscore(roits.dat);
roits.dat = roits.dat';   % make (time,vox) as (vox,time)
d{1} = roits.dat;
roits.dat = [];  % no need for later


if roits.dx < 1,
  XLAGS = round(MAX_LAGS_SEC/roits.dx);
  XLAGS = -XLAGS:XLAGS;
  
  % 1sec bin
  %XLAGS = round([-MAX_LAGS_SEC:MAX_LAGS_SEC]/roits.dx);
else
  XLAGS = round([-MAX_LAGS_SEC:roits.dx:MAX_LAGS_SEC]/roits.dx);
end

if VERBOSE,
  fprintf(' maxlag=%gs:',XLAGS(end)*roits.dx);
end



sz_blp = size(blp.dat);   % blp.dat as (time,chan,band)
NChan  = size(blp.dat,2);
NBANDS = size(blp.dat,3);
NLAGS  = length(XLAGS);

tmpall  = zeros(NBANDS*NLAGS*NChan,size(blp.dat,1));
tmpoffs = 0;
for iCh = 1:NChan,
  tmpdat = squeeze(blp.dat(:,iCh,:));
  tmpdat = zscore(tmpdat);
  tmpdat = tmpdat';  % tmpdat as (bands,time)
  for K = 1:NLAGS,
    % negative lag means shifting to right
    tmpall([1:NBANDS]+tmpoffs,:) = circshift(tmpdat,[0,-XLAGS(K)]);
    tmpoffs = tmpoffs + NBANDS;
    %tmpall = cat(1,tmpall,circshift(tmpdat,[0,XLAGS(K)]));
  end
end
d{2} = tmpall;

blp.dat = [];  % no need for later


%bands = [1 20;
%		 60 120;
%		 100 3000];



if size(d{1},2) > 2000,
  fprintf(' tlen%d->2000.',size(d{1},2));
  d{1} = d{1}(:,1:2000);
  d{2} = d{2}(:,1:2000);
end



if 1,
  SP_WEIGHT = [];
else
  tmpres = exptkcca(Ses,ExpNo,'verbose',1,...
                    'MriSig',MriSig,'RoiName',RoiName,...
                    'NeuSig',NeuSig,'chans',NeuChans,'bands',NeuBands,'AddSdf',ADD_SDF,...
                    'ResampleHz',ResampleHz);
  SP_WEIGHT = tmpres.fmri.weights;
end


% calculate cor
if VERBOSE,
  fprintf(' cor(%s,D{1}=%dx%d,D{2}=%dx%d)...',...
          ALGORITHM,size(d{1},1),size(d{1},2),size(d{2},1),size(d{2},2));
end

if EACH_VOXEL,
  U = sub_tcor_vox(d,'algorithm',ALGORITHM);
else
  U = sub_tcor(d,'algorithm',ALGORITHM,'spw',SP_WEIGHT);
end

if VERBOSE,  fprintf(' results...');  end


RES.session = Ses.name;
RES.grpname = grp.name;
RES.exps    = ExpNo;

RES.opts.algorithm = ALGORITHM;
RES.opts.maxlags   = MAX_LAGS_SEC;
RES.opts.roiname   = RoiName;
RES.opts.sigs      = {NeuSig, MriSig};
RES.opts.elename   = blp.elename;
RES.opts.chans     = NeuChans;
RES.opts.bands     = NeuBands;


RES.fmri.x = d{1};
RES.fmri.weights   = U{1,1};
RES.fmri.projected = U{1,2}';
RES.fmri.coords  = roits.coords;
RES.fmri.ana     = roits.ana;
RES.fmri.dx      = roits.dx;
RES.fmri.ds      = roits.ds;

tpre = find(XLAGS*roits.dx >= -10 & XLAGS*roits.dx < 0);
tpos = find(XLAGS*roits.dx > 0 & XLAGS*roits.dx <= 10);
for iCh = 1:NChan,
  chanoffs = (iCh-1)*NBANDS*NLAGS;
  if EACH_VOXEL,
    weights = reshape(nanmean(U{2,1}([1:NBANDS*NLAGS]+chanoffs,:),2),[NBANDS NLAGS]);
  else
    weights = reshape(U{2,1}([1:NBANDS*NLAGS]+chanoffs,:),[NBANDS NLAGS]);
  end
  projected = [];
  
  if 1,
    tmpxc = nanmean(weights,1);
    tmpxc = tmpxc(:);
  else
    for K = 1:NLAGS,
      tmpidx = [1:NBANDS] + (K-1)*NBANDS;
      %projected = cat(1,projected,weights(:,K)'*d{2}(tmpidx+chanoffs,:));
      % may better use abs(weights) otherwise, xcor become always positive...
      projected = cat(1,projected,abs(weights(:,K))'*d{2}(tmpidx+chanoffs,:));
    end
    tmpxc = corr([U{1,2}, projected']);
    tmpxc = tmpxc(2:end,1);
  end
  
  RES.ephys(iCh).weights = weights;
  RES.ephys(iCh).projected = projected;
  RES.ephys(iCh).xcorr   = tmpxc;
  RES.ephys(iCh).lags    = XLAGS;
  RES.ephys(iCh).band    = blp.info.band;
  RES.ephys(iCh).dx      = blp.dx;
  RES.ephys(iCh).elename = blp.elename{iCh};
  RES.ephys(iCh).dimname = blp.dimname;
  if EACH_VOXEL,
    nvox = size(U{2,1},2);
    tmpr = reshape(U{2,1}([1:NBANDS*NLAGS]+chanoffs,:),[NBANDS NLAGS nvox]);
    tmpp = reshape(U{2,3}([1:NBANDS*NLAGS]+chanoffs,:),[NBANDS NLAGS nvox]);
    RES.ephys(iCh).vox_r = tmpr;
    RES.ephys(iCh).vox_p = tmpp;
  end
  
  % convolve neural bands with univarHRF
  tmplag = find(XLAGS == 0);
  tmpidx = [1:NBANDS] + (tmplag-1)*NBANDS;
  neudat = d{2}(tmpidx+chanoffs,:);
  if 1,
    tmpk = mhemokernel('cohen',blp.dx,30);
    tmpsel = [1:size(neudat,2)];
    for K = 1:size(neudat,1),
      tmpdat = conv(neudat(K,:),tmpk.dat(:));
      neudat(K,:) = tmpdat(tmpsel);
    end
    neudat = nanmean(neudat,1);
  else
    tmpsel = [1:size(neudat,2)] + tmplag;
    for K = 1:size(neudat,1),
      tmpdat = conv(neudat(K,:),fliplr(weights(K,:))); % flip to match with HRF
      neudat(K,:) = tmpdat(tmpsel);
    end
    neudat = nanmean(neudat,1);  % average across bands
  end
  if EACH_VOXEL,
    RES.ephys(iCh).ccr_conv = NaN;
    RES.ephys(iCh).ccp_conv = NaN;
  else
    [tmpr tmpp] = corrcoef(U{1,2},neudat);
    %RES.ephys(iCh).neuconv  = neudat(:);
    RES.ephys(iCh).ccr_conv = tmpr(1,2);
    RES.ephys(iCh).ccp_conv = tmpp(1,2);
  end
end


RES.U = U;

if VERBOSE,  fprintf(' done.\n');  end


return




function U = sub_tcor(d,varargin)
% d{1} as (voxel,time), d{2} as (band/chan,time)

% U{1,1} as
% U{1,2} as
% U{2,1} as
% U{2,2} as

ALGORITHM  = 'corrcoef';
SP_WEIGHT  = [];
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'algorithm','method'}
    ALGORITHM = varargin{N+1};
   case {'spw','sp_weight'}
    SP_WEIGHT = varargin{N+1};
  end
end

if isempty(SP_WEIGHT),
  SP_WEIGHT = ones(size(d{1},1),1) / size(d{1},1);
end
SP_WEIGHT = SP_WEIGHT(:);


%mvox = nanmean(d{1},1);
mvox = SP_WEIGHT'*d{1};
cor_r = zeros(size(d{2},1),1);
cor_p = zeros(size(cor_r));


switch lower(ALGORITHM),
 case {'corrcoef','corr'}
  for N = 1:size(d{2},1),
    [tmpr tmpp] = corrcoef(mvox,d{2}(N,:));
    cor_r(N) = tmpr(1,2);
    cor_p(N) = tmpp(1,2);
  end
 case {'cov'}
  for N = 1:size(d{2},1),
    [tmpr tmpp] = cov(mvox,d{2}(N,:));
    cor_r(N) = tmpr(1,2);
    cor_p(N) = tmpp(1,2);
  end
 otherwise
  error('%s: unknown method ''%s''\n',mfilename,ALGORITHM);
end


pneu = d{2} .* repmat(cor_r,[1,size(d{2},2)]);
pneu = nanmean(d{2},1);

U{1,1} = SP_WEIGHT;
U{1,2} = mvox(:);
U{2,1} = cor_r(:);
U{2,2} = pneu(:);


return


function U = sub_tcor_vox(d,varargin)
% d{1} as (voxel,time), d{2} as (band/chan,time)

% U{1,1} as
% U{1,2} as
% U{2,1} as
% U{2,2} as

ALGORITHM  = 'corrcoef';
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'algorithm','method'}
    ALGORITHM = varargin{N+1};
  end
end

cor_r = zeros(size(d{2},1),size(d{1},1));  % (band/chan,vox)
cor_p = zeros(size(cor_r));


switch lower(ALGORITHM),
 case {'corrcoef','corr'}
  for V = 1:size(d{1},1),
    for N = 1:size(d{2},1),
      [tmpr tmpp] = corrcoef(d{1}(V,:),d{2}(N,:));
      cor_r(N,V) = tmpr(1,2);
      cor_p(N,V) = tmpp(1,2);
    end
  end
 case {'cov'} 
  for V = 1:size(d{1},1),
    for N = 1:size(d{2},1),
      [tmpr tmpp] = cov(d{1}(V,:),d{2}(N,:));
      cor_r(N,V) = tmpr(1,2);
      cor_p(N,V) = tmpp(1,2);
    end
  end
 otherwise
  error('%s: unknown method ''%s''\n',mfilename,ALGORITHM);
end

tmpr = nanmean(cor_r,2);  % mean along voxels

pneu = d{2} .* repmat(tmpr,[1,size(d{2},2)]);
pneu = nanmean(d{2},1);

U{1,1} = [];
U{1,2} = [];
U{2,1} = cor_r;
U{2,2} = pneu;
U{2,3} = cor_p;

return



% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function txt = sub_text(Vars)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isempty(Vars),
  txt = 'all';
elseif isnumeric(Vars),
  txt = deblank(sprintf('%g ',Vars));
elseif iscell(Vars),
  txt = '';
  for N = 1:length(Vars),
    txt = strcat(txt,sprintf(' %s',Vars{N}));
  end
  txt = strtrim(txt);
elseif ischar(Vars),
  txt = Vars;
else
  txt = '';
end

return
