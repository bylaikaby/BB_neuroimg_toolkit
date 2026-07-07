function RES = sestkcca(SES,GRPEXP,varargin)
%SESTKCCA - Apply tkCCA between neural and BOLD signals.
%  RES = SESTKCCA(SESSION,GRPEXP,...) applies tkCCA between neural and 
%  BOLD signals.
%
%  Supported options are :
%    'RoiName'    : Roi name(s)
%    'MriSig'     : MRI signal
%    'MriNrom'    : normalization for MriSig
%    'NeuSig'     : NEU signal
%    'chans'      : Electrode indices/names (may require grp.namech)
%    'bands'      : Band indices/names for the neural signal
%    'AddSdf'     : includes SDF or not.
%    'ResampleHz' : resampling Hz, can be as 'bold' or any numeric
%    'CV'         : cross-validation 0|1
%
%  EXAMPLE :
%    res = sestkcca('b06sc1','spont');
%
%  VERSION :
%    0.90 31.07.09 YM  pre-release
%    0.91 28.04.11 YM  cat 'canonical_correlogram' also.
%    0.92 29.04.11 YM  clean-up, adapt for 'cross-validation'.
%    0.93 28.11.11 YM  use tkcca_filename() for saving.
%
%  See also exptkcca exptkcca_cv grptkcca plot_tkcca sestcor tkcca_filename

if nargin < 2,  GRPEXP = '';  end

DO_PLOT         = 0;
MriSig          = 'roiTs';
NeuSig          = 'blp';
RoiName         = 'all';
NeuChans        = [];
NeuBands        = [];
ResampleHz      = '';
ADD_SDF         = 0;
CrossValidation = 0;
MaxLags         = 15;
SIG_SELECT      = 'all';
MriNorm         = 'zscore';

SES = goto(SES);
if isnumeric(GRPEXP) && ~isempty(GRPEXP),
  EXPS = GRPEXP;
else
  EXPS = getexps(SES,GRPEXP);
end

grp = getgrp(SES, EXPS(1));

ANAP = getanap(SES, EXPS(1));
if isfield(ANAP,'tkcca'),
  RoiName       = ANAP.tkcca.rois;
  NeuSig        = ANAP.tkcca.neusig;
  MriSig        = ANAP.tkcca.mrisig;
  NeuChans      = ANAP.tkcca.chans;
  NeuBands      = ANAP.tkcca.bands;
  ADD_SDF       = ANAP.tkcca.addsdf;
  ResampleHz    = ANAP.tkcca.resamplehz;
  MAX_LAGS_SEC  = ANAP.tkcca.maxlagsec;
  SIG_SELECT    = ANAP.tkcca.ppSigSelect;
end;

% overwrite with command-line options
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'roi','rois','roiname','roinames'}
    RoiName = varargin{N+1};
   case {'neusig','neu'},
    NeuSig = varargin{N+1};
   case {'mrisig','mri'},
    MriSig = varargin{N+1};
   case {'resample','resamplehz'}
    ResampleHz = varargin{N+1};
   case {'sdf','addsdf','add_sdf'}
    ADD_SDF = varargin{N+1};
   case {'ele','elename','elenames','chans','chan'}
    NeuChans = varargin{N+1};
   case {'band','bands','bandname','bandnames'}
    NeuBands = varargin{N+1};
   case {'mrinorm'},
    MriNorm = varargin{N+1};
   case {'cv','crossvalidation'}
    CrossValidation = varargin{N+1};    
   case {'sigsel','sel'},
    SIG_SELECT = varargin{N+1};    
   case {'plot'},
    DO_PLOT = varargin{N+1};
  end
end

fprintf('%s %s: %s',...
        datestr(now,'HH:MM:SS'),upper(mfilename), upper(SES.name));
if ischar(GRPEXP) && ~isempty(GRPEXP),
  fprintf('(%s,nexp=%d): ',GRPEXP,length(EXPS));
else
  fprintf('(nexp=%d): ',length(EXPS));
end
fprintf('ROI=[%s], ELE=[%s], BLP=[%s], SIGS(%s,%s) CV=%d\n',...
        sub_text(RoiName), sub_text(NeuChans), sub_text(NeuBands),...
        NeuSig, MriSig, CrossValidation);



if ~nargout,
  % EXAMPLE:
  if any(SIG_SELECT),
    SaveFilename = tkcca_filename(SES,GRPEXP,MriSig,RoiName,NeuSig,NeuChans,...
                                  ANAP.tkcca.ppDspDeriv,SIG_SELECT);
  else
    SaveFilename = tkcca_filename(SES,GRPEXP,MriSig,RoiName,NeuSig,NeuChans);
  end
  fprintf(' SaveFilename : ''%s''\n',SaveFilename);
end

RES = [];
if any(CrossValidation),
  % use 'cross-validated' version
  RES = exptkcca_cv(SES,EXPS,...
                        'mrisig',MriSig,'RoiName',RoiName,'mrinorm',MriNorm,'sigsel',SIG_SELECT,...
                        'neusig',NeuSig,'chans',NeuChans,'bands',NeuBands,'ResampleHz',ResampleHz);
else
  if strcmp(NeuSig,'cblp'),
    RES = grptkcca(SES, GRPEXP,...
                   'neusig','cblp','mrisig','croiTs','RoiName',RoiName,...
                   'mrinorm',MriNorm,'chans',NeuChans,'bands',NeuBbands,'ResampleHz',ResampleHz);
  else
    for iExp = 1:length(EXPS),
      tmpres = exptkcca(SES,EXPS(iExp),...
                        'neusig',NeuSig,'mrisig',MriSig,'RoiName',RoiName,'sigsel',SIG_SELECT,...
                        'mrinorm',MriNorm,'chans',NeuChans,'bands',NeuBands,'ResampleHz',ResampleHz);
      
      if isempty(tmpres), fprintf(' no Roi/Ele, skipping\n'); return; end
      RES = sub_catcca(RES,tmpres);
    end
  end;
end

if isfield(RES,'opts'),  RES.opts.cv = CrossValidation;         end;
if isfield(ANAP,'siggetblp'),  RES.siggetblp = ANAP.siggetblp;  end;
if isfield(ANAP,'gettrial'),  RES.gettrial = ANAP.gettrial;     end;
if isfield(ANAP,'mareats'),  RES.mareats = ANAP.mareats;        end;

if ~nargout,
  if DO_PLOT,
    fprintf(' plotting...');
    tmpres = RES;
    tmpres.fmri.weights = nanmean(tmpres.fmri.weights,2);
    for N = 1:length(tmpres.ephys),
      tmpres.ephys(N).weights = nanmean(tmpres.ephys(N).weights,3);
      tmpres.ephys(N).xcorr   = nanmean(tmpres.ephys(N).xcorr,  2);
    end
    plot_tkcca(tmpres);
  end

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


RES.fmri.weights = cat(2,RES.fmri.weights,newres.fmri.weights);
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
