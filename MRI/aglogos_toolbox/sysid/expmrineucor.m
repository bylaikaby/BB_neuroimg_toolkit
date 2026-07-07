function RES = expmrineucor(Ses,GrpExp,varargin)
%EXPMRINEUCOR - Computes temporal correlation between neural and BOLD signals (each vox)
%  RES = EXPMRINEUCOR(SESSION,EXPNO,...) computes temporal correlation between
%  neural and BOLD signals (each vox).
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
%    'ConvHRF'    : convolve HRF
%
%    RES = 
%      session: 'rat7e1'
%      grpname: 'spont'
%         exps: [3]
%         opts: [1x1 struct]
%          ana: [36x42x4 double]
%       coords: [193x3 double]
%     lags_pts: [1x41 double]
%           dx: 1
%          dat: [41x1x8x193 double]   <---- corr data as (lag,chan,band,voxel)
%      dimname: {'lag'  'chan'  'band'  'voxel'}
%
%  NOTE :
%     -lags mean MriSig preceeds NeuSig.
%     +lags mean MriSig follows  NeuSig.
%
%
%  EXAMPLE :
%     res = sesmrineucor('rat7e1','spont','mrisig','rproiTs','roi','HP','neusig','rpblp','ele','hipgrouped','convhrf','cohen')
%     plot_mrineucor(res);
% 
%  VERSION : 
%    0.90 14.02.12 YM  modified from exptcor().
%    0.91 15.02.12 YM  set lags to match with HRF.
% 
%  See also sesmrineucor plot_mrineucor


if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end


% opts = {
%     'lambda'    10.^[-[1:3]]'
%     'lag'		20 % in secs
%     }';
% opts = resolveopts(varargin, opts);

% SET OPTIONS
ALGORITHM    = 'corrcoef';  % corrcoef | cov
COEF_WITH_P  = 0;
MAX_LAGS_SEC = 20;
VERBOSE      =  1;
% preprocess
RoiName      = 'all';
MriSig       = 'roiTs';
NeuSig       = 'blp';
NeuChans     = [];
NeuBands     = [];
ResampleHz   = 'bold';
ADD_SDF      = 0;
ConvHRF      = '';
SIG_SELECT   = 'all';



for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'maxlags','maxlag'}
    MAX_LAGS_SEC = varargin{N+1};
   case {'algorithm','method'}
    ALGORITHM = varargin{N+1};
   case {'coef_with_p'}
    COEF_WITH_P = varargin{N+1};
    
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
   case {'convhrf','hrf','convolve'}
    ConvHRF = varargin{N+1};
   case {'sigsel','sel'},
    SIG_SELECT = varargin{N+1};
   case {'average'}
    AverageBLPChannels = varargin{N+1};
  end
end
if isempty(ResampleHz),  ResampleHz = 'bold';  end


Ses = goto(Ses);
grp = getgrp(Ses,GrpExp);

if VERBOSE,
  if isnumeric(GrpExp),
    fprintf('%s %s: %s ExpNo=%d',datestr(now,'HH:MM:SS'),mfilename,...
            Ses.name,GrpExp);
  else
    fprintf('%s %s: %s %s',datestr(now,'HH:MM:SS'),mfilename,...
            Ses.name,grp.name);
  end
end


RES = {};
if ~isrecording(Ses,grp),
  return
end

if VERBOSE,
  fprintf(' loading...');
end

[roits blp] = mrineu_load(Ses,GrpExp,...
                          'MriSig',MriSig,'RoiName',RoiName,...
                          'NeuSig',NeuSig,'EleName',NeuChans,'bands',NeuBands,'AddSpike',ADD_SDF,...
                          'ResampleHz',ResampleHz,'ConvHRF',ConvHRF);


if isempty(roits) || isempty(roits.dat),
  fprintf(' no roits for ''%s'', skipping.\n',sub_text(RoiName));
  return
end
if isempty(blp) || isempty(blp.dat),
  fprintf(' no blp for ''%s'', skipping.\n',sub_text(NeuChans));
  return
end

blp.dimname = {'time' 'chan' 'band'};  % this may updated by ccapreproc().
%[roits, blp] = ccapreproc(roits, blp, SIG_SELECT);



if roits.dx < 1,
  XLAGS = round(MAX_LAGS_SEC/roits.dx);
  XLAGS = -XLAGS:XLAGS;
  
  % 1sec bin
  %XLAGS = round([-MAX_LAGS_SEC:MAX_LAGS_SEC]/roits.dx);
else
  XLAGS = round([-MAX_LAGS_SEC:roits.dx:MAX_LAGS_SEC]/roits.dx);
end
NLAGS  = length(XLAGS);

if VERBOSE,
  fprintf(' maxlag=%gs:',XLAGS(end)*roits.dx);
end



NVox   = size(roits.dat,2);
NChan  = size(blp.dat,2);
NBANDS = size(blp.dat,3);

if COEF_WITH_P,
  d = {};
  % BOLD data 
  %roits.dat = nanmean(roits.dat,2);  % for testing
  roits.dat = zscore(roits.dat);
  roits.dat = roits.dat';   % make (time,vox) as (vox,time)
  d{1} = roits.dat;
  roits.dat = [];  % no need for later


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

  % calculate cor
  if VERBOSE,
    fprintf(' cor(%s,D{1}=%dx%d,D{2}=%dx%d)...',...
            ALGORITHM,size(d{1},1),size(d{1},2),size(d{2},1),size(d{2},2));
  end

  U = sub_tcor_vox_tkcca(d,'algorithm',ALGORITHM);
else
  % calculate cor
  if VERBOSE,
    fprintf(' cor(%s,mri=[%s],neu=[%s])...',ALGORITHM,...
            deblank(sprintf('%d ',size(roits.dat))),...
            deblank(sprintf('%d ',size(blp.dat))));
  end
  U = sub_tcor_vox(roits,blp,(NLAGS-1)/2,'algorithm',ALGORITHM);
end
  

if VERBOSE,  fprintf(' results...');  end


RES.session = Ses.name;
RES.grpname = grp.name;
if isnumeric(GrpExp),
RES.exps    = GrpExp;
else
RES.exps    = grp.exps;
end

RES.opts.algorithm = ALGORITHM;
RES.opts.maxlags   = MAX_LAGS_SEC;
RES.opts.roiname   = RoiName;
RES.opts.sigs      = {NeuSig, MriSig};
RES.opts.elename   = blp.elename;
RES.opts.band      = blp.info.band;
RES.opts.neuchans  = NeuChans;
RES.opts.neubands  = NeuBands;


RES.ana      = roits.ana;
RES.coords   = roits.coords;
RES.lags_pts = XLAGS;
RES.dx       = roits.dx;
RES.dat      = [];

if COEF_WITH_P,
  RES.dat  = zeros(NBANDS,NLAGS,NVox,NChan); % permute later.
  RES.p    = ones(size(RES.dat));            % permute later.
  for iCh = 1:NChan,
    chanoffs = (iCh-1)*NBANDS*NLAGS;
    
    tmpr = U{2,1}([1:NBANDS*NLAGS]+chanoffs,:);
    tmpp = U{2,3}([1:NBANDS*NLAGS]+chanoffs,:);
    
    tmpr = reshape(tmpr,[NBANDS NLAGS NVox]);
    tmpp = reshape(tmpp,[NBANDS NLAGS NVox]);
    
    RES.dat(:,:,:,iCh) = tmpr;
    RES.p(:,:,:,iCh)   = tmpp;
  end
  
  % (band,lag,vox,chan) --> (lag,chan,band,vox)
  RES.dat = permute(RES.dat,[2 4 1 3]);
  RES.p   = permute(RES.p,  [2 4 1 3]);
else
  RES.dat = U{2,1};
end
RES.dimname = { 'lag' 'chan' 'band' 'voxel' };


% to match with HRF, flip the lag-direction.
RES.dat = flipdim(RES.dat,1);
if isfield(RES,'p'),
  RES.p = flipdim(RES.p,1);
end



if VERBOSE,  fprintf(' done.\n');  end


return


% ===========================================================
function U = sub_tcor_vox(roits,blp,maxlags,varargin)
% ===========================================================

ALGORITHM  = 'xcov';
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'algorithm','method'}
    ALGORITHM = varargin{N+1};
  end
end

% x = zeros(100,1);  x(20:40) = 1;
% x = x + (2*rand(100,1)-1)*0.25;
% y = circshift(x,5);
% figure;
% subplot(2,1,1);
% plot([x y]); legend('x','y');
% subplot(2,2,3);
% plot(-10:10,xcorr(x,y,10,'coef'));
% subplot(2,2,4);
% plot(-10:10,xcorr(y,x,10,'coef'));


NVox  = size(roits.dat,2);
NChan = size(blp.dat,2);
NBand = size(blp.dat,3);

cor_r = zeros(maxlags*2+1,NChan,NBand,NVox);
switch lower(ALGORITHM),
 case {'xcorr' 'cor' 'corr'}
  for V = 1:NVox,
    for C = 1:NChan
      for B = 1:NBand
        cor_r(:,C,B,V) = xcorr(blp.dat(:,C,B),roits.dat(:,V),maxlags,'coeff');
      end
    end
  end
 case {'xcov' 'cov' 'corrcoef'} 
  for V = 1:NVox,
    for C = 1:NChan
      for B = 1:NBand
        cor_r(:,C,B,V) = xcov(blp.dat(:,C,B),roits.dat(:,V),maxlags,'coeff');
      end
    end
  end
 otherwise
  error('%s: unknown method ''%s''\n',mfilename,ALGORITHM);
end

U{1,1} = [];
U{1,2} = [];
U{2,1} = cor_r;
U{2,2} = [];
U{2,3} = [];

return



% ===========================================================
function U = sub_tcor_vox_tkcca(d,varargin)
% ===========================================================
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
