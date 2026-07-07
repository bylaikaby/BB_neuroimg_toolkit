function RES = sesmrcca(SES,GRPEXP,varargin)
%SESMRCCA - Apply tkCCA to BOLD signals with the given ROIs.
%  RES = SESMRCCA(SESSION,GRPEXP,...) applies tkCCA to BOLD signals with the given ROIs.
%
%  Supported options are :
%    'RoiName'    : Roi name(s)
%    'MriSig'     : MRI signal
%    'MriNorm'    : normalization for MriSig
%    'ResampleHz' : resampling Hz, can be as 'bold' or any numeric
%    'CV'         : cross-validation 0|1
%
%  EXAMPLE :
%    res = sesmrcca('e10ha1','spont','mrisig','roiTs','roi',{'HP' 'hele'});
%    plot_mrcca(res);
%
%  VERSION :
%    0.90 08.01.13 YM  pre-release
%
%  See also expmrcca expmrcca_cv grpmrcca plot_mrcca sestcor mrcca_filename

if nargin < 2,  GRPEXP = '';  end

DO_PLOT         = 0;
MriSig          = 'roiTs';
RoiName         = 'all';
ResampleHz      = '';
CrossValidation = 0;
MaxLags         = 15;
MriNorm         = 'zscore';
RegType         = 'pca';

SES = goto(SES);
if isnumeric(GRPEXP) && ~isempty(GRPEXP),
  EXPS = GRPEXP;
else
  EXPS = getexps(SES,GRPEXP);
end

grp = getgrp(SES, EXPS(1));

ANAP = getanap(SES, EXPS(1));
if isfield(ANAP,'mrcca'),
  RoiName       = ANAP.mrcca.rois;
  MriSig        = ANAP.mrcca.mrisig;
  ResampleHz    = ANAP.mrcca.resamplehz;
  MAX_LAGS_SEC  = ANAP.mrcca.maxlagsec;
end;

% overwrite with command-line options
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'roi','rois','roiname','roinames'}
    RoiName = varargin{N+1};
   case {'mrisig','mri'},
    MriSig = varargin{N+1};
   case {'resample','resamplehz'}
    ResampleHz = varargin{N+1};
   case {'mrinorm'},
    MriNorm = varargin{N+1};
   case {'regtype','reg'},
    RegType = varargin{N+1};
   case {'cv','crossvalidation'}
    CrossValidation = varargin{N+1};    
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
fprintf('ROI=[%s], SIG(%s) CV=%d\n',...
        sub_text(RoiName), MriSig, CrossValidation);


if ~nargout,
  % EXAMPLE:
  SaveFilename = mrcca_filename(SES,GRPEXP,MriSig,RoiName);
  fprintf(' SaveFilename : ''%s''\n',SaveFilename);
end

RES = [];
if any(CrossValidation),
  % use 'cross-validated' version
  RES = expmrcca_cv(SES,EXPS,...
                    'mrisig',MriSig,'RoiName',RoiName,'mrinorm',MriNorm,...
                    'ResampleHz',ResampleHz, 'reg', RegType);
else
  for iExp = 1:length(EXPS),
      tmpres = expmrcca(SES,EXPS(iExp),...
                        'mrisig',MriSig,'RoiName',RoiName,'mrinorm',MriNorm,...
                        'ResampleHz',ResampleHz, 'reg', RegType);
      
      if isempty(tmpres), fprintf(' no Roi, skipping\n'); return; end
      RES = sub_catcca(RES,tmpres);
  end
end

if isfield(RES,'opts'),  RES.opts.cv = CrossValidation;         end;
if isfield(ANAP,'gettrial'),  RES.gettrial = ANAP.gettrial;     end;
if isfield(ANAP,'mareats'),  RES.mareats = ANAP.mareats;        end;

if ~nargout,
  if DO_PLOT,
    fprintf(' plotting...');
    tmpres = RES;
    tmpres.fmri.weights = nanmean(tmpres.fmri.weights,2);
    for N = 1:length(tmpres.model),
      tmpres.model(N).weights = nanmean(tmpres.model(N).weights,3);
      tmpres.model(N).xcorr   = nanmean(tmpres.model(N).xcorr,  2);
    end
    plot_mrcca(tmpres);
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
  RES.fmri  = rmfield(RES.fmri,{'x','projected'});
  RES.model = rmfield(RES.model,'projected');
  return
end
if isfield(RES,'exps'),
  RES.exps = cat(2,RES.exps,newres.exps);
end


if isfield(RES,'canonical_correlogram'),
  RES.canonical_correlogram = cat(3,RES.canonical_correlogram,newres.canonical_correlogram);
end


RES.fmri.weights = cat(2,RES.fmri.weights,newres.fmri.weights);
for N = 1:length(RES.model),
  RES.model(N).weights = cat(3,RES.model(N).weights,newres.model(N).weights);
  RES.model(N).projected = [];  % too large to keep...
  %RES.model(N).projected = cat(3,RES.model(N).projected, newres.model(N).projected);
  
  RES.model(N).xcorr   = cat(2,RES.model(N).xcorr,  newres.model(N).xcorr);
  RES.model(N).ccr_conv = cat(2,RES.model(N).ccr_conv, newres.model(N).ccr_conv);
  RES.model(N).ccp_conv = cat(2,RES.model(N).ccp_conv, newres.model(N).ccp_conv);
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
