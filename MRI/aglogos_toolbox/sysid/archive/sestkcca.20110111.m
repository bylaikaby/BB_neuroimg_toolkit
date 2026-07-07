function RES = sestkcca(SES,GRPEXP,varargin)
%SESTKCCA - Apply tkCCA between neural and BOLD signals.
%  RES = SESTKCCA(SESSION,GRPEXP,...) applies tkCCA between neural and 
%  BOLD signals.
%
%  Supported options are :
%    'maxlag'     : max. lag in seconds
%    'RoiName'    : Roi name(s)
%    'EleName'    : Electrode name(s), requires grp.namech
%    'AddSdf'     : includes SDF or not.
%    'ResampleHz' : resampling Hz, can be as 'bold' or any numeric
%    'Plot'       : plot results or not
%
%  EXAMPLE :
%    res = sestkcca('b06sc1','spont');
%
%  VERSION :
%    0.90 31.07.09 YM  pre-release
%
%  See also exptkcca plot_tkcca sestcor

if nargin < 2,  GRPEXP = '';  end

RoiName     = 'all';
EleName     = 'all';

NeuSig      = 'blp';
MriSig      = 'roiTs';
ResampleHz  = 'bold';

ADD_SDF    = 0;
DO_PLOT = 1;
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'roi','roiname','roinames'}
    RoiName = varargin{N+1};
   case {'ele','elename','elenames'}
    EleName = varargin{N+1};
   case {'resample','resamplehz'}
    ResampleHz = varargin{N+1};
   case {'sdf','addsdf','add_sdf'}
    ADD_SDF = varargin{N+1};
   case {'plot'}
    DO_PLOT = varargin{N+1};
   case {'neusig'},
    NeuSig = varargin{N+1};
   case {'mrisig'},
    MriSig = varargin{N+1};
  end
end

SES = goto(SES);
if isnumeric(GRPEXP) && ~isempty(GRPEXP),
  EXPS = GRPEXP;
else
  EXPS = getexps(SES,GRPEXP);
end

fprintf('%s %s: %s %s-%s: ',datestr(now,'HH:MM:SS'),mfilename,...
        SES.name,RoiName,EleName);
if ischar(GRPEXP) && ~isempty(GRPEXP),
  fprintf('(%s,nexp=%d): ',GRPEXP,length(EXPS));
else
  fprintf('(nexp=%d): ',length(EXPS));
end
fprintf('\n');
RES = [];
for iExp = 1:length(EXPS),
  if mod(iExp,10) == 0,
    fprintf('%d',iExp);
  else
    fprintf('.');
  end
  tmpres = exptkcca(SES,EXPS(iExp),'verbose',1,'neusig',NeuSig,'mrisig',MriSig,...
                     'RoiName',RoiName,'EleName',EleName,...
                     'ResampleHz',ResampleHz,'AddSdf',ADD_SDF);
  if isempty(tmpres),
    fprintf(' no Roi/Ele, skipping\n');
    return;
  end
  RES = sub_catcca(RES,tmpres);
end

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
fprintf(' done.\n');
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function RES = sub_catcca(RES,newres)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

RES.fmri.weights = cat(2,RES.fmri.weights,newres.fmri.weights);
for N = 1:length(RES.ephys),

  RES.ephys(N).weights = cat(3,RES.ephys(N).weights,newres.ephys(N).weights);
  RES.ephys(N).xcorr   = cat(2,RES.ephys(N).xcorr,  newres.ephys(N).xcorr);
  RES.ephys(N).ccr_conv = cat(2,RES.ephys(N).ccr_conv, newres.ephys(N).ccr_conv);
  RES.ephys(N).ccp_conv = cat(2,RES.ephys(N).ccp_conv, newres.ephys(N).ccp_conv);
end
return
