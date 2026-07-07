function RES = sestcor(SES,GRPEXP,varargin)
%SESTCOR - Apply temporal correlation analysis between neural and BOLD signals.
%  RES = SESTCOR(SESSION,GRPEXP,...) applies temporal correlation analysis between
%  neural and BOLD signals.
%
%  Supported options are :
%    'RoiName'    : Roi name(s)
%    'MriSig'     : MRI signal
%    'NeuSig'     : NEU signal
%    'chans'      : Electrode indices/names (may require grp.namech)
%    'bands'      : Band indices/names for the neural signal
%    'AddSdf'     : includes SDF or not.
%    'ResampleHz' : resampling Hz, can be as 'bold' or any numeric
%    'Plot'       : plot results or not
%
%  EXAMPLE :
%    res = sestcor('b06sc1','spont');
%
%  VERSION :
%    0.90 07.08.09 YM  pre-release
%    0.91 13.02.11 YM  use tcorr_filename() for saving.
%
%  See also exptcor plot_tkcca sestkcca

if nargin < 2,  GRPEXP = '';  end

DO_PLOT      = 0;
EachVoxel    = 0;   % must be always ZERO
MriSig       = 'roiTs';
NeuSig       = 'blp';
RoiName      = 'all';
NeuChans     = [];
NeuBands     = [];
ADD_SDF      = 0;
ResampleHz   = 'bold';
SaveFilename = '';
SIG_SELECT   = 'all';

for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'roi','roiname','roinames'}
    RoiName = varargin{N+1};
   case {'neusig','neu'},
    NeuSig = varargin{N+1};
   case {'mrisig','mri'},
    MriSig = varargin{N+1};
   case {'resample','resamplehz'}
    ResampleHz = varargin{N+1};
   case {'sdf','addsdf','add_sdf'}
    ADD_SDF = varargin{N+1};
   case {'ele','elename','elenames','chan','chans'}
    NeuChans = varargin{N+1};
   case {'band','bands','bandname','bandnames'}
    NeuBands = varargin{N+1};
   case {'sigsel','sel'},
    SIG_SELECT = varargin{N+1};    
   case {'each' 'eachvox' 'eachvoxe'}
    EachVoxel = varargin{N+1};
   case {'plot'}
    DO_PLOT = varargin{N+1};
  end
end

SES = goto(SES);

if isnumeric(GRPEXP) && ~isempty(GRPEXP),
  EXPS = GRPEXP;
else
  EXPS = getexps(SES,GRPEXP);
end

%EXPS = EXPS(1:2);
anap = getanap(SES,EXPS(1));



fprintf('%s %s: %s',...
        datestr(now,'HH:MM:SS'),upper(mfilename), upper(SES.name));
if ischar(GRPEXP) && ~isempty(GRPEXP),
  fprintf('(%s,nexp=%d): ',GRPEXP,length(EXPS));
else
  fprintf('(nexp=%d): ',length(EXPS));
end
fprintf('ROI=[%s], ELE=[%s], BLP=[%s], SIGS(%s,%s)\n',...
        sub_text(RoiName), sub_text(NeuChans), sub_text(NeuBands),...
        NeuSig, MriSig);



if ~nargout,
  % EXAMPLE:
  % monkey_tkcca_spont_rproiTs(Ent)_rpblp(allgrouped)_pp(zs2(1)-all)
  if any(SIG_SELECT),
    SaveFilename = tcorr_filename(SES,GRPEXP,MriSig,RoiName,NeuSig,NeuChans,...
                                  anap.tkcca.ppDspDeriv,SIG_SELECT);
  else
    SaveFilename = tcorr_filename(SES,GRPEXP,MriSig,RoiName,NeuSig,NeuChans);
  end
  fprintf(' SaveFilename : ''%s''\n',SaveFilename);
end

RES = [];
for iExp = 1:length(EXPS),
  if mod(iExp,10) == 0,
    fprintf('%d',iExp);
  else
    fprintf('.');
  end
  
  tmpres = exptcor(SES,EXPS(iExp),'verbose',1,...
                   'mrisig',MriSig,'RoiName',RoiName,'sigsel',SIG_SELECT,...
                   'neusig',NeuSig,'chans',NeuChans,'bands',NeuBands,...
                   'ResampleHz',ResampleHz,'AddSdf',ADD_SDF,...
                   'EachVoxel',EachVoxel);
  if isempty(tmpres),
    fprintf(' no Roi/Ele, skipping\n');
    return;
  end
  
  RES = sub_catcor(RES,tmpres);
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


if any(SaveFilename),
  [fp fr] = fileparts(SaveFilename);
  if ~exist(fp,'dir'),  mkdir(fp);  end
  
  fprintf(' saving ''RES'' to ''%s''...', SaveFilename);
  if exist(SaveFilename,'file'),
    save(SaveFilename, '-append','RES');
  else
    save(SaveFilename, 'RES');
  end;
end


fprintf(' done.\n');


return




function RES = sub_catcor(RES,newres)

if isempty(RES),  
  RES = newres;
  RES      = rmfield(RES,'U');
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
  
  %RES.ephys(N).neuconv  = cat(2,RES.ephys(N).neudat, newres.ephys(N).neudat);
  RES.ephys(N).ccr_conv = cat(2,RES.ephys(N).ccr_conv, newres.ephys(N).ccr_conv);
  RES.ephys(N).ccp_conv = cat(2,RES.ephys(N).ccp_conv, newres.ephys(N).ccp_conv);
  
  if isfield(RES.ephys(N),'vox_r'),
    RES.ephys(N).vox_r = cat(4,RES.ephys(N).vox_r, newres.ephys(N).vox_r);
    RES.ephys(N).vox_p = cat(4,RES.ephys(N).vox_p, newres.ephys(N).vox_p);
  end  
end
  

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
