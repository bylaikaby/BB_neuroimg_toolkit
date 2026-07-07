function varargout = getica(SESSION,GRPEXPS,SIGNAME)
%GETICA - ICA to examine different (unpredictable) time courses
% SIG = getica(SESSION,GRPEXP,SIGNAME) runs ICA and returns the results
%
%  EXAMPLE MRI:
%
%  NOTE
%   To obtain consistent results use "compressed".
%   For an example, if 'nLatent' is excanged with 'runica' for the same data set, the
%   'activations' (ICs) may be different, when PCA limits the number of ICs.
%   So,  1) do PCA and compress data matching the numbers of computing ICA components.
%        2) run ICA with compressed data
%
%   =======================================================
%   ICA structure
%   =======================================================
%                        ncomp: 15
%                        icomp: [15x9288 double]    - need to be converted to "image"
%                       coords: [9288x3 double]     - coordinates of each point in icomp
%                         mask: [4-D logical]       - not sure why we need this?
%                          dat: [150x15 double]     - the ICs
%                           ds: [0.7500 0.7500 2]
%                           dx: 2
%     LatentDimensionReduction: 1
%                    evar_keep: 15
%                      ica_dim: 'spatial'
%                     ica_type: 'bell'
%                    normalize: 'none'
%                   clusterica: [1x1 struct]
%
% NOTE
%   *** NKL 18.Aug.09 I changed GETICA for selecting ICs on the basis of PRESTIM activity. I
%       also added TFILTER/SFILTER and a pre-selection of data within the "ica" ROI (see
%       ROIs in B06lv1. This is still poor. Some ICs are intercorrelated (more than one can
%       "ignore"); clustering of responses is need to get unequivocal clusters. The only
%       good news is that the main result (e.g. b06lv1) is clear, with a good INJc, INJp and
%       IPZ zones. NEEDS REALLY!!! WORK this; otherwise is not usable no matter what bs
%       people explain ....
%   *** Attention to TFILTER/SFILTER before GLM (to preserve resolution...)
%   *** All major results are in PPT files (V:\LogothetisEtAl esfMRI Nature 2009\Archive)
%
%  VERSION :
%    0.90 05.02.07 YM  pre-release
%    0.91 13.04.07 YM  can be controlled by ANAP.ica
%    0.92 22.05.07 YM  use eigs() for less memory if needed.
%    0.93 28.05.07 YM  bug fix, missing .ana/.coords for tcImg.
%    0.94 07.11.07 YM  adapting for ClnSpc/Cln.
%    0.95 25.03.08 YM  supports 'period'.
%    1.01 17.06.09 NKL
%    1.02 14.07.09 YM  supports 'sobi'.
%
%  See also PERFORM_ICA SHOWMODEL_ICA CLUSTERICA SIGGETICA SHOWICARES

DEBUG = 1;
if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end

if ~exist('SIGNAME','var'),  SIGNAME = '';  end


% CONTROL FLAGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
LatentDimensionReduction = 1;

ICA_TYPE    = 'bell';                       % 'bell': infomax / Bell&Sejnowski 'fastica' : Hyvarinen
ICA_DIM     = 'spatial';                    % temporal ICA or spatial ICA
EVAR_KEEP   = 50;                           % If > 1 then, represents numb. of PCs
                                            % If < 1 then, threshold for cum. sum of eVar.(e.g. 0.8)
NORMALIZE   = 'none';
PERIOD      = 'all';
TFILTER     = [];
SFILTER     = [];

% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
if isnumeric(GRPEXPS),
  EXPS = GRPEXPS;
  grp  = getgrp(Ses,EXPS(1));
else
  grp = getgrp(Ses,GRPEXPS);
  EXPS = grp.exps;
end

% overwrite settings by ANAP.ica
anap = getanap(Ses,grp);

% GET PARAMETERS FROM THE ANAP.ICA STRUCTURE (E.G. SEE ESGETPARS.M)
ROINAME = 'all';

if isfield(anap,'ica'),
  if isfield(anap.ica,'roinames'),
    ROINAME = anap.ica.roinames;
  end;
  if isfield(anap.ica,'evar_keep') & ~isempty(anap.ica.evar_keep),
    EVAR_KEEP = anap.ica.evar_keep;
  end
  if isfield(anap.ica,'dim') & ~isempty(anap.ica.dim),
    ICA_DIM = anap.ica.dim;
  end
  if isfield(anap.ica,'type') & ~isempty(anap.ica.type),
    ICA_TYPE = anap.ica.type;
  end
  if isfield(anap.ica,'LatentDimensionReduction') & ~isempty(anap.ica.LatentDimensionReduction),
    LatentDimensionReduction = anap.ica.LatentDimensionReduction;
  end
  if isfield(anap.ica,'normalize') & ~isempty(anap.ica.normalize),
    NORMALIZE = anap.ica.normalize;
  end
  if isfield(anap.ica,'period') & ~isempty(anap.ica.period),
    PERIOD = anap.ica.period;
  end
  if isfield(anap.ica,'TFILTER') & ~isempty(anap.ica.TFILTER),
    TFILTER = anap.ica.TFILTER;
  end
  if isfield(anap.ica,'SFILTER') & ~isempty(anap.ica.SFILTER),
    SFILTER = anap.ica.SFILTER;
  end
  
  % if signal specific parameters, then overwrite settings
  % See for example anap.ica.ClnSpc.... in ESGETPARS.m
  if isfield(anap.ica,SIGNAME),
    if isfield(anap.ica.(SIGNAME),'evar_keep') & ~isempty(anap.ica.(SIGNAME).evar_keep),
      EVAR_KEEP = anap.ica.(SIGNAME).evar_keep;
    end
    if isfield(anap.ica.(SIGNAME),'dim') & ~isempty(anap.ica.(SIGNAME).dim),
      ICA_DIM = anap.ica.(SIGNAME).dim;
    end
    if isfield(anap.ica.(SIGNAME),'type') & ~isempty(anap.ica.(SIGNAME).type),
      ICA_TYPE = anap.ica.(SIGNAME).type;
    end
    if isfield(anap.ica.(SIGNAME),'LatentDimensionReduction') & ~isempty(anap.ica.(SIGNAME).LatentDimensionReduction),
      LatentDimensionReduction = anap.ica.(SIGNAME).LatentDimensionReduction;
    end
    if isfield(anap.ica.(SIGNAME),'normalize') & ~isempty(anap.ica.(SIGNAME).normalize),
      NORMALIZE = anap.ica.(SIGNAME).normalize;
    end
    if isfield(anap.ica.(SIGNAME),'period') & ~isempty(anap.ica.(SIGNAME).period),
      PERIOD = anap.ica.(SIGNAME).period;
    end
  end
end

if isempty(SIGNAME),
  if isfield(anap,'gettrial') & anap.gettrial.status > 0,
    SIGNAME = 'troiTs';
  else
    SIGNAME = 'roiTs';
  end
end
if isfield(anap.ica,'SIGNAME'),
  SIGNAME = anap.ica.SIGNAME;       % to use roiTs while anap.gettrial.status = 1...
end;


if strcmpi(ICA_DIM,'spatial') | strcmpi(ICA_DIM,'temporal'),
  N_AVERAGE = length(EXPS);
else
  N_AVERAGE = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% CAUTION!!!!!!!!!!!!! - CHECKING... things out; change later
% N_AVERAGE=0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmpi(ICA_TYPE,'sobi'),
  ICA_DIM = 'temporal';
  N_AVERAGE = length(EXPS);
end

if DEBUG,
  fprintf('GETICA: Included ROIs: ');
  for N=1:length(ROINAME), fprintf('%s ', ROINAME{N}); end;
  fprintf('\n');
  fprintf('GETICA: %s %s: %s(%s) ',datestr(now,'HH:MM:SS'),mfilename,Ses.name,grp.name);
  fprintf('loading(%s,nexp=%d,period=%s)',SIGNAME,length(EXPS),PERIOD);
end;

oSig = [];
% PREPARE DATA FOR ICA STUFF
for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  SIG = sigload(Ses,ExpNo,SIGNAME);
  stmidx = [];
  switch lower(PERIOD),
   case {'stim'}
    stmidx = getStimIndices(SIG,'stim',0,0);
   case {'all','none',''}
    stmidx = [];
   otherwise
    stmidx = getStimIndices(SIG,PERIOD,0,0);
  end
  if ~isempty(stmidx),
    if strcmpi(SIGNAME,'tcImg'),
      SIG.dat = SIG.dat(:,:,:,stmidx);
    else
      if iscell(SIG),
        for N = 1:length(SIG),
          if iscell(SIG{N}),
            for K = 1:length(SIG{N}),
              SIG{N}{K}.dat = SIG{N}{K}.dat(stmidx,:,:);
            end
          else
            SIG{N}.dat = SIG{N}.dat(stmidx,:,:);
          end
        end
      else
        SIG.dat = SIG.dat(stmidx,:,:);
      end
    end
  end    
  switch SIGNAME,
   case {'tcImg'}
    oSig = subTCIMG(oSig,SIG,N_AVERAGE);
   case {'roiTs'}
    if ~strcmp(ROINAME,'all'),
      SIG = mroitsget(SIG,[],ROINAME);
    end;
    oSig = subROITS(oSig,SIG,N_AVERAGE);
   case {'troiTs'}
    if ~strcmp(ROINAME,'all'),
      SIG = mroitsget(SIG,[],ROINAME);
    end;
    oSig = subTROITS(oSig,SIG,N_AVERAGE);
   case {'ClnSpc'}
    oSig = subNeuSig(oSig,SIG,N_AVERAGE);
   case {'Cln'}
    oSig = subClnExp(oSig,SIG);
    
   otherwise
    error('\n ERROR %s: unsupported signal ''%s''\n',SIGNAME);
  end
  if ~nargout,
    fprintf('.');
  end;
  clear SIG;
end
if ~nargout,
  fprintf(' done.\n');
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SELECT Time Courses on the basis of PRESTIM activity
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NKL AUG2009 - CHECK THIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% oSig = subSigPreProcess(oSig,0.15,TFILTER,SFILTER);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RUN ICA ------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DOPLOT = 0;     % Only for debugging
switch SIGNAME,
 case {'ClnSpc','Cln'}
  % oSig.dat as (time,freq,chan) for ClnSpc
  % oSig.dat as (time,rep,chan) for Cln
  Sig = [];
  tmpsig = oSig;
  for N = 1:size(oSig.dat,3),
    tmpsig.dat = oSig.dat(:,:,N);
    if isfield(oSig,'chan'),
      tmpsig.chan = oSig.chan(N);
    end
    tmpsig = siggetica(tmpsig,'dim',ICA_DIM,'type',ICA_TYPE,...
                       'LatentDimensionReduction',LatentDimensionReduction,...
                       'evarkeep',EVAR_KEEP,'normalize',NORMALIZE,'plot',DOPLOT);
    Sig = cat(2,Sig,tmpsig);
  end
  oSig = Sig;
  clear Sig tmpsig;
 otherwise
  % NOTE THAT oSig.dat is (time,vox)
  oSig = siggetica(oSig,'dim',ICA_DIM,'type',ICA_TYPE,...
                   'LatentDimensionReduction',LatentDimensionReduction,...
                   'evarkeep',EVAR_KEEP,'normalize',NORMALIZE,'plot',DOPLOT);
end


% clusetr analysis, if imaging data
if any(strcmpi({'tcImg','roiTs','troiTs'},SIGNAME)),
  oSig = clusterica(oSig);
end
oSig.roinames = ROINAME;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NKL AUG2009 - CHECK THIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~N_AVERAGE,
  TLEN = round(size(oSig.dat,1)/2);
  tmp = cat(3,oSig.dat(1:TLEN,:),oSig.dat(TLEN+1:end,:));
  oSig.dat = mean(tmp,3);
  tmp = cat(3,oSig.ica.dat(1:TLEN,:),oSig.ica.dat(TLEN+1:end,:));
  oSig.ica.dat = mean(tmp,3);
  tmp = oSig;
  tmp.dat = oSig.ica.dat;
  if 0,
    % SELECT ICs BY CORRELATING THE PRESTIM TRIALS
    tmp = subSigPreProcess(tmp,0.4);
    oSig.idx = tmp.idx;
    oSig.ica.dat = tmp.dat;
    oSig.ica.icomp = oSig.ica.icomp(tmp.idx,:);
    oSig.ica.evar_keep = length(tmp.idx);
    oSig.ica.ncomp = length(tmp.idx);
    oSig.ica.mask = oSig.ica.mask(:,:,:,tmp.idx);
  end;
end;

if nargout,
  varargout{1} = oSig;
else
  matfile = sprintf('ICA_%s_%s_%s.mat',grp.name,SIGNAME,ICA_DIM);
  fprintf('%s: Saving ''oSig'' to %s...',mfilename,matfile);
  save(matfile,'oSig');
  fprintf(' done.\n');
  if DOPLOT,
    showicares(oSig);
  end;
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Select time courses on the basis of models for the prestim period
%         name: 'V1+V2'
%         slice: -1
%        coords: [7939x3 double]
%           dat: [592x7939 double]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sig = subSigPreProcess(Sig,RVAL,TFILTER,SFILTER)
if nargin < 4,
  SFILTER = [];
end;
if nargin < 3,
  TFILTER = [];
end;
Ses = getses(Sig.session);
grp = getgrpbyname(Sig.session,Sig.grpname);
anap = getanap(Sig.session, Sig.grpname);
if isfield(anap,'inj'),
  inj = anap.inj;
end;

MDL_LEN = 128;
mdl = expmkmodel(Ses,Sig.grpname,'hemo');
mdl = mdl.dat(1:MDL_LEN,1);   % V1 model

if ~isempty(TFILTER),
  fprintf('GETICA: Temporal Filtering with [%g %g]...', TFILTER);
  Sig = sigfilt(Sig,TFILTER,'bandpass');
  fprintf('Done!\n');
end;

if ~isempty(SFILTER),
  fprintf('GETICA: Spatial Filtering with [%g %g]...', TFILTER);
  Sig = sigspatfilt(Sig,SFILTER);
  fprintf('Done!\n');
end;

for N=1:size(Sig.dat,2),
  tmpr = corrcoef(Sig.dat(1:MDL_LEN,N),mdl);
  r(N) = tmpr(1,2);
end;
idx = find(abs(r)>RVAL);
Sig.dat = Sig.dat(:,idx);
Sig.coords = Sig.coords(idx,:);
Sig.idx = idx;
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREPARE DATA FOR tcImg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = subTCIMG(oSig,tcImg,N_AVERAGE)

% reshape and permute, [x,y,z,t] --> [t, xyz]
szdat = size(tcImg.dat);
tcImg.dat = reshape(tcImg.dat,[prod(szdat(1:3)), szdat(4)]);
tcImg.dat = permute(tcImg.dat,[2 1]);
if isempty(oSig),
  oSig = tcImg;
  if N_AVERAGE,
    oSig.dat = oSig.dat / N_AVERAGE;
  end
  if ~isfield(oSig,'ana'),
    oSig.ana = mean(tcImg.dat,1);
    oSig.ana = reshape(oSig.ana,[szdat(1:3)]);
    [ix iy iz] = ind2sub(szdat(1:3),[1:prod(szdat(1:3))]);
    oSig.coords = [ix(:) iy(:) iz(:)];
  end
else
  oSig.ExpNo(end+1) = tcImg.ExpNo(1);
  if N_AVERAGE,
    oSig.dat = oSig.dat + tcImg.dat / N_AVERAGE;
  else
    oSig.dat = cat(1,oSig.dat,tcImg.dat);
  end
end
return

% PREPARE DATA FOR roiTs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = subROITS(oSig,roiTs,N_AVERAGE)
% concatenate all ROIs  
TMPDAT = roiTs{1}.dat;
TMPCOORDS = roiTs{1}.coords;
TMPNAME = roiTs{1}.name;
for iRoi = 2:length(roiTs),
  TMPDAT = cat(2,TMPDAT,roiTs{iRoi}.dat);
  TMPCOORDS = cat(1,TMPCOORDS,roiTs{iRoi}.coords);
  TMPNAME = sprintf('%s+%s',TMPNAME,roiTs{iRoi}.name);
end

% remove duplicated voxels
tmpidx = sub2ind(size(roiTs{1}.ana),TMPCOORDS(:,1),TMPCOORDS(:,2),TMPCOORDS(:,3));
[tmpidx tmpsafe] = unique(tmpidx);
TMPDAT = TMPDAT(:,tmpsafe);
TMPCOORDS = TMPCOORDS(tmpsafe,:);

% concatenate/average data
if isempty(oSig),
  oSig = roiTs{1};
  oSig.name = TMPNAME;
  oSig.dat = TMPDAT;
  oSig.coords = TMPCOORDS;
  if N_AVERAGE,
    oSig.dat = oSig.dat / N_AVERAGE;
  end
else
  oSig.ExpNo(end+1) = roiTs{1}.ExpNo(1);
  if N_AVERAGE>1,
    oSig.dat = oSig.dat + TMPDAT / N_AVERAGE;
  else
    %oSig.dat = cat(3,oSig.dat,TMPDAT);  % 14.07.09 YM: why '3', originally it was '1'.
    oSig.dat = cat(1,oSig.dat,TMPDAT);
  end
end
return


% PREPARE DATA FOR troiTs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = subTROITS(oSig,troiTs,N_AVERAGE)
if isstruct(troiTs{1}),
  % this happens when trial2obsp == 1
  oSig = subROITS(oSig,troiTs,N_AVERAGE);
  return
end

TMPDAT = [];
TMPCOORDS = [];
TMPNAME = '';
TLEN = [];
% concatenate all ROIs and trials
for R = 1:length(troiTs),
  TMPCOORDS = cat(1,TMPCOORDS,troiTs{R}{1}.coords);
  TMPNAME = sprintf('%s+%s',TMPNAME,troiTs{R}{1}.name);
  tdat = troiTs{R}{1}.dat;
  TLEN(1) = size(troiTs{R}{1},1);
  for T = 2:length(troiTs{R}),
    tdat = cat(1,tdat,troiTs{R}{T}.dat);
    TLEN(T) = size(troiTs{R}{T},1);
  end
  TMPDAT = cat(2,TMPDAT,tdat);
end


% remove duplicated voxels
tmpidx = sub2ind(size(troiTs{1}{1}.ana),TMPCOORDS(:,1),TMPCOORDS(:,2),TMPCOORDS(:,3));
[tmpidx tmpsafe] = unique(tmpidx);
TMPDAT = TMPDAT(:,tmpsafe);
TMPCOORDS = TMPCOORDS(tmpsafe,:);


% concatenate/average data
if isempty(oSig),
  oSig = troiTs{1}{1};
  oSig.name = TMPNAME;
  oSig.dat = TMPDAT;
  oSig.coords = TMPCOORDS;
  oSig.triallen = TLEN;
  if N_AVERAGE,
    oSig.dat = oSig.dat / N_AVERAGE;
  end
else
  oSig.ExpNo(end+1) = troiTs{1}{1}.ExpNo(1);
  if N_AVERAGE,
    oSig.dat = oSig.dat + TMPDAT / N_AVERAGE;
  else
    oSig.dat = cat(1,oSig.dat,TMPDAT);
  end
end
return


% PREPARE DATA FOR Neural Signals %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = subNeuSig(oSig,iSig,N_AVERAGE)

% note iSig.dat = (t,...)
if isempty(oSig),
  oSig = iSig;
  if N_AVERAGE,
    oSig.dat = oSig.dat / N_AVERAGE;
  end
else
  oSig.ExpNo(end+1) = iSig.ExpNo(1);
  if N_AVERAGE,
    if size(oSig.dat,1) > size(iSig.dat,1),
      oSig.dat = oSig.dat(1:size(iSig.dat,1),:,:,:,:);
    elseif size(oSig.dat,1) < size(iSig.dat,1),
      iSig.dat = iSig.dat(1:size(oSig.dat,1),:,:,:,:);
    end
    
    oSig.dat = oSig.dat + iSig.dat / N_AVERAGE;
  else
    oSig.dat = cat(1,oSig.dat,iSig.dat);
  end
end

return


% PREPARE DATA FOR Cln %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = subClnExp(oSig,iSig)

% note iSig.dat = (t,chan) --> oSig.dat(t,exps,chan)
tmpsz = size(iSig.dat);
iSig.dat = reshape(iSig.dat,[tmpsz(1) 1 tmpsz(2:end)]);
if isempty(oSig),
  oSig = iSig;
else
  oSig.ExpNo(end+1) = iSig.ExpNo(1);
  if size(oSig.dat,1) > size(iSig.dat,1),
    oSig.dat = oSig.dat(1:size(iSig.dat,1),:,:);
  elseif size(oSig.dat,1) < size(iSig.dat,1),
    iSig.dat = iSig.dat(1:size(oSig.dat,1),:,:);
  end
  oSig.dat = cat(2,oSig.dat,iSig.dat);  % concat to 2nd dim. (exp)
end

return
