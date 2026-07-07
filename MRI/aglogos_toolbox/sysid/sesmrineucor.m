function RES = sesmrineucor(SES,GRPEXP,varargin)
%SESMRINEUCOR - Apply temporal correlation analysis between neural and BOLD signals (each voxel).
%  RES = SESMRINEUCOR(SESSION,GRPEXP,...) applies temporal correlation analysis between
%  neural and BOLD signals (each voxel).
%
%  Supported options are :
%    'RoiName'    : Roi name(s)
%    'MriSig'     : MRI signal
%    'NeuSig'     : NEU signal
%    'chans'      : Electrode indices/names (may require grp.namech)
%    'bands'      : Band indices/names for the neural signal
%    'AddSdf'     : includes SDF or not.
%    'ResampleHz' : resampling Hz, can be as 'bold' or any numeric
%    'ConvHRF'    : convolve HRF
%    'Plot'       : plot results or not
%
%  EXAMPLE :
%     res = sesmrineucor('rat7e1','spont','mrisig','rproiTs','roi','HP','neusig','rpblp','ele','hipgrouped','convhrf','cohen')
%     plot_mrineucor(res);
%
%  VERSION :
%    0.90 14.02.12 YM  modified from sestcor.m.
%
%  See also exptcor plot_tkcca sestkcca

if nargin < 2,  GRPEXP = '';  end

DO_PLOT      = 0;
MriSig       = 'roiTs';
NeuSig       = 'blp';
RoiName      = 'all';
NeuChans     = [];
NeuBands     = [];
ADD_SDF      = 0;
ResampleHz   = 'bold';
ConvHRF      = '';
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
   
   case {'convhrf','hrf','convolve'}
    ConvHRF = varargin{N+1};
   
   case {'sigsel','sel'},
    SIG_SELECT = varargin{N+1};    
    
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
  fprintf('%2d/%d ',iExp,length(EXPS));
  
  tmpres = expmrineucor(SES,EXPS(iExp),'verbose',1,...
                        'mrisig',MriSig,'RoiName',RoiName,'sigsel',SIG_SELECT,...
                        'neusig',NeuSig,'chans',NeuChans,'bands',NeuBands,...
                        'ResampleHz',ResampleHz,'AddSdf',ADD_SDF,'ConvHRF',ConvHRF);
  if isempty(tmpres),
    fprintf(' no Roi/Ele, skipping\n');
    return;
  end
  
  RES = sub_catcor(RES,tmpres);
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
  RES.dimname{end+1} = 'exp';
  return
end

if isfield(RES,'exps'),
  RES.exps = cat(2,RES.exps,newres.exps);
end


% RES.dat as (lag,chan,band,vox)
RES.dat = cat(5,RES.dat,newres.dat);
if isfield(RES,'p')
RES.p   = cat(5,RES.p,  newres.p);
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
