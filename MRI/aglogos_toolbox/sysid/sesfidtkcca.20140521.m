function RES = sesfidtkcca(SES,GRPEXP,varargin)
%SESFIDTKCCA - Apply tkCCA between neural and MRS signals.
%  RES = SESFIDTKCCA(SESSION,GRPEXP,...) applies tkCCA between neural and 
%  MRS signals.
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
%    res = sesfidtkcca('ratpe2','spont');
%    plot_fidtkcca(res)
%
%  VERSION :
%    0.90 21.05.14 YM  pre-release modified from sestkcca.
%
%  See also fidtkcca plot_fidtkcca

if nargin < 2,  GRPEXP = '';  end

DO_PLOT         = 1;
MriSig          = 'tcMrs';
NeuSig          = 'blp';
NeuChans        = [];
NeuBands        = [];
NeuAddSdf       = 0;
NeuNorm         = 'sdu';
MriNorm         = 'zscore';

FidEffWin       = [];
FidApodize      = 'hanning';
FidBellWidth    = 0.75;
FidNorm         = 'sdu';

ResampleHz      = [];
MaxLagsSec      = 20;


SES = goto(SES);
if isnumeric(GRPEXP) && ~isempty(GRPEXP),
  EXPS = GRPEXP;
else
  EXPS = getexps(SES,GRPEXP);
end

grp = getgrp(SES, EXPS(1));

ANAP = getanap(SES, EXPS(1));
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
  MaxLagsSec    = ANAP.fidtkcca.maxlagsec;
end;

% overwrite with command-line options
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'plot'},
    DO_PLOT = varargin{N+1};
   
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

fprintf('%s %s: %s',...
        datestr(now,'HH:MM:SS'),upper(mfilename), upper(SES.name));
if ischar(GRPEXP) && ~isempty(GRPEXP),
  fprintf('(%s,nexp=%d): ',GRPEXP,length(EXPS));
else
  fprintf('(nexp=%d): ',length(EXPS));
end
fprintf('ELE=[%s], BLP=[%s], SIGS(%s,%s)\n',...
        sub_text(NeuChans), sub_text(NeuBands),...
        NeuSig, MriSig);


if ~nargout,
  SaveFilename = tkcca_filename(SES,GRPEXP,MriSig,[],NeuSig,NeuChans);
  fprintf(' SaveFilename : ''%s''\n',SaveFilename);
end

RES = [];
for iExp = 1:length(EXPS),
  fprintf('%s %3d/%d:',datestr(now,'HH:MM:SS'),iExp,length(EXPS));
  if ~isspectroscopy(SES,EXPS(iExp)),
    fprintf(' not fMRS, skipping.\n');
    continue;
  end
  fprintf(' fidtkcca(%s,ExpNo=%d).\n',SES.name,EXPS(iExp));
  tmpres = fidtkcca(SES,EXPS(iExp),...
                    'neusig',NeuSig, 'mrisig',MriSig,...
                    'chans',NeuChans, 'bands',NeuBands, 'addsdf',NeuAddSdf,...
                    'FidEffWin',FidEffWin, 'FidApodize',FidApodize, 'FidBellWidth',FidBellWidth,...
                    'NeuNorm',NeuNorm, 'FidNorm',FidNorm, 'ResampleHz',ResampleHz, 'MaxLagsSec',MaxLagsSec);
  
  if isempty(tmpres), fprintf(' no Ele, skipping\n'); return; end
  RES = sub_catcca(RES,tmpres);
end

if DO_PLOT,
  fprintf(' plotting...');
  plot_fidtkcca(RES);
end

if ~nargout,
  [fp fr] = fileparts(SaveFilename);
  if ~exist(fp,'dir'),  mkdir(fp);  end
  
  fprintf(' saving ''RES'' to ''%s''...', SaveFilename);
  if exist(SaveFilename,'file'),
    save(SaveFilename, '-append','RES');
  else
    save(SaveFilename, 'RES');
  end;
  fprintf(' done.\n');
end;
return


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function RES = sub_catcca(RES,newres)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(RES),  
  RES = newres;
  if isfield(RES,'U'),
    RES      = rmfield(RES,'U');
  end
  RES.fmri = rmfield(RES.fmri,{'x','projected'});
  RES.ephys = rmfield(RES.ephys,'projected');
  return
end
if isfield(RES,'exps'),
  RES.exps = cat(2,RES.exps,newres.exps);
end


if isfield(RES,'canonical_correlogram'),
  RES.canonical_correlogram = cat(3,RES.canonical_correlogram,newres.canonical_correlogram);
end


RES.fmri.weights = cat(3,RES.fmri.weights,newres.fmri.weights);
for N = 1:length(RES.ephys),
  RES.ephys(N).weights = cat(3,RES.ephys(N).weights,newres.ephys(N).weights);
  RES.ephys(N).projected = [];  % too large to keep...
  %RES.ephys(N).projected = cat(3,RES.ephys(N).projected, newres.ephys(N).projected);
  
  RES.ephys(N).xcorr   = cat(2,RES.ephys(N).xcorr,  newres.ephys(N).xcorr);
  RES.ephys(N).ccr_conv = cat(2,RES.ephys(N).ccr_conv, newres.ephys(N).ccr_conv);
  RES.ephys(N).ccp_conv = cat(2,RES.ephys(N).ccp_conv, newres.ephys(N).ccp_conv);
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function txt = sub_text(Vars)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
