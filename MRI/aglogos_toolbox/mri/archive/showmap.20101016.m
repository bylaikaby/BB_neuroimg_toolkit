function showmap(SesName,GrpName,varargin)
%SHOWMAP - Uses MaskCombine to show PES/NES maps/TCs for a given mask (e.g. PVS)
% showmap(SesName,GrpName,varargin)
% showmap('b06fu1','visesmix','roiname','mt');
% showmap('b06fu1','visesmix','roiname','lgn','mask','fVal','slice',[4:8]);    
% showmap('b06fu1','visesmix','brain',[],{'pvs','nvs'},{'pes','nes'});
%
% ATTENTION
% =====================
% showmap('h05tm1','visesmix','mask',{'IC-fVal','IC-fVal','IC-fVal'},'model',{'IC1','IC6', ...
%                     'IC9'},'roiname',{'sc','lgn','v1','v2','mt'});
%
% showmap('b06td1','visescomb','mskp',0.1,'mdlp',0.05,'roiname',{'sc','v1','v2'},'model',{'pes','nes'});
%
% The previous will work with a refgrp = 'visesmix' etc...
% WE MUST define explicitly the "model" otherwise default is incr/decr!!
% NKL 18.04.2007

if nargin < 1, help showmap;  return; end;
if nargin < 2, GrpName = 'visesmix'; end;

Ses = goto(SesName);
grp = getgrpbyname(Ses,GrpName);
anap = getanap(Ses,GrpName);
refgrp = grp.refgrp;

if ~isfield(anap,'showmap'),
  fprintf(['SHOWMAP requires the definition of defaults in grp.anap.showmap\n']);
  fprintf('Define "showmap" in ESGETPARS, VISESMIXGETPARS, VISESCOMBGETPARS or Descr File\n');
  return;
end;

GABA_SESSION    = 0;
if isempty(findstr(lower(SesName),'h0527')) && ~isempty(findstr(lower(GrpName),'inj')),
  GABA_SESSION = 1;
end;

STDERROR    = anap.showmap.STDERROR;
CIVAL       = anap.showmap.CIVAL; 
BSTRP       = anap.showmap.BSTRP;    
TRIAL       = anap.showmap.TRIAL;    
SLICES      = anap.mview.slices;
FUNCSCALE   = anap.showmap.FUNCSCALE;
ANASCALE    = anap.showmap.ANASCALE;

MaskName    = anap.showmap.MASKNAME;
ModelName   = anap.showmap.MODELNAME; 
MDLP        = anap.showmap.MDLP; 
MSKP        = anap.showmap.MSKP;     
DRAW_ROI    = anap.showmap.DRAW_ROI;
ROINAME     = anap.showmap.ROINAME; 
FMTTYPE     = anap.showmap.FMTTYPE;  
COL_LINE    = anap.showmap.COL_LINE;  
COL_FACE    = anap.showmap.COL_FACE; 

if isfield(anap.showmap,'LINESTYLE'),
  LineStyle   = anap.showmap.LINESTYLE; 
end;
if isfield(anap.showmap,'MULTI_TRIAL'),
  MULTI_TRIAL = anap.showmap.MULTI_TRIAL;
else
  MULTI_TRIAL = [];
end;

if isfield(anap.showmap,'CMAP'),
  CMAP = anap.showmap.CMAP;
else
  CMAP = {'r','b','c','m','g','y','c','k'};
end;

DRAWSTM     = 1;
YGRID       = 0;

% ---------------------------------------------------
% PARSE INPUT
% ---------------------------------------------------
for N=1:2:length(varargin),
  switch lower(varargin{N}),
   case {'ygrid'},
    YGRID = varargin{N+1};
   case {'drawstm','drawstmlines'}
    DRAWSTM = varargin{N+1};
   case {'color'}
    COL_LINE = varargin{N+1};
   case {'cmap'}
    CMAP = varargin{N+1};
   case {'slices'}
    SLICES = varargin{N+1};
   case {'fmt'}
    FMTTYPE = varargin{N+1};
   case {'drawroi'}
    DRAW_ROI = varargin{N+1};
   case {'roiname'}
    ROINAME = varargin{N+1};
   case {'mask'}
    MaskName = varargin{N+1};
   case {'linestyle'}
    LineStyle = varargin{N+1};
   case {'model'}
    ModelName = varargin{N+1};
   case {'mskp'}
    MSKP = varargin{N+1};
   case {'cival'}
    CIVAL = varargin{N+1};
   case {'bstrp'}
    BSTRP = varargin{N+1};
   case {'mdlp'}
    MDLP = varargin{N+1};
   otherwise
    fprintf('unknown command option\n');
    return;
  end
end

[roiTs, roiTXT] = esgetroits(SesName, GrpName, varargin{:});

LEGEND={};
for M=1:length(MaskName),
  for N=1:length(ModelName),
    LEGEND{end+1} = upper(strcat(MaskName{M},'-',ModelName{N}));
  end;
end;

msk = sprintf('%s,',char(MaskName{1}));
if length(MaskName)>1,
  for N=2:length(MaskName),
    msk = strcat(msk, sprintf('%s,',char(MaskName{N})));
  end;
end;
msk=msk(1:end-1);

mdl = sprintf('%s,',char(ModelName{1}));
if length(ModelName)>1,
  for N=2:length(ModelName),
    mdl = strcat(mdl, sprintf('%s,',char(ModelName{N})));
  end;
end;
mdl=mdl(1:end-1);

if ~isempty(DRAW_ROI),
  ROINAME = DRAW_ROI;
end;

if exist('MULTI_TRIAL','var') && ~isempty(MULTI_TRIAL),
  M = MULTI_TRIAL;
  for N=1:length(roiTs),
    nvox(N) = size(roiTs{N}.dat,2);
  end;
  
  comTs{1} = roiTs{M(1)};
  for N=M(1)+1:M(2),
    comTs{1} = mvoxlogical(comTs{1},'and',roiTs{N});
  end

  comTs{2} = roiTs{M(3)};
  for N=M(3)+1:M(4),
    comTs{2} = mvoxlogical(comTs{2},'and',roiTs{N});
  end
  
  if 1,
    save('MeanEsvar.mat','comTs','nvox');
  end;
  
  if 0,
  model = comTs{1};
  model.dat = hnanmean(model.dat,2);
  tmp = hnanmean(comTs{2}.dat,2);
  model.dat = cat(2,model.dat,tmp(:));
  save('MDL_comTs.mat','model');
  fprintf('SHOWMAP: Saved "model" in MDL_comTs.mat\n');
  end;
  
  roiTs = comTs;  clear comTs;
  %   ROINAME   = {{'LGN','V1'},{'V2'}};
  %   CMAP      = {'r','b'};
  %   COL_LINE  = 'rb';
  roiTXT    = {'pbr','nbr'};

  mfigure([50 100 400 600]);
  subplot(2,1,1);
  bar(nvox(M(1):M(2)));
  title('PBR Voxels');
  subplot(2,1,2);
  bar(nvox(M(3):M(4)));
  title('NBR Voxels');
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DISPLAY FOR GABA-INJECTION SESSIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if GABA_SESSION,
  mfigure([50 200 800 800]);
  set(gcf,'color',[1 1 1]);
  map = subplot(1,2,1);
  dspmaps(roiTs,'axes',map,'slice',SLICES,'clip',FUNCSCALE(1:2),'gamma',FUNCSCALE(3),...
          'drawroi',DRAW_ROI,'cmap',CMAP);
  title(sprintf('showmap(%s,%s)', upper(SesName), upper(GrpName)));
  axis off;
  
  TRIAL_POS = {[0.55   0.77    0.2940    0.2], [0.55    0.52    0.2940    0.2],...
              [0.55    0.29    0.2940    0.2], [0.55    0.05    0.2940    0.2]};
  
  for N=1:length(roiTs),
    subplot('position',TRIAL_POS{N});
    troiTs = getTrialMeans(SesName, GrpName, roiTs{N});
    subPlotTrials(troiTs,COL_LINE(N));
    if N<length(roiTs), set(gca,'xticklabel',[]); end;
    drawstmlines(troiTs,'linestyle','none');
    title(sprintf('ROI = %s', LEGEND{N}),'fontsize',8,'VerticalAlignment','middle');
  end;
  
  xlabel('Time in seconds');
  ylabel('SD Units');
  set(gca,'ygrid','on');
%  return;
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DISPLAY FOR ALL OTHER SESSIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mfigure([50 100 1550 1000]);
set(gcf,'color',[1 1 1]);

% FUNCTIONAL MAPS ON ANATOMY
map = subplot('position', [0.05    0.08    0.41    0.8]);
dspmaps(roiTs,'axes',map,'slice',SLICES,'clip',FUNCSCALE(1:2),'gamma',FUNCSCALE(3),...
        'drawroi',DRAW_ROI,'cmap',CMAP);
title(sprintf('showmap(%s,%s)', upper(SesName), upper(GrpName)));
axis off;

DRAW_TEXT=0;
if DRAW_TEXT,
  % DISPLAY TEXT INFORMATION 
  POS = [0.55  0.68  0.40  0.29];
  subplot('position',POS);
  set(gca,'xlim',[0 200], 'ylim',[ 0 100], 'ydir','reverse');
  axis off;
  txt = [];
  txt{end+1}  = sprintf('Anatomy/Functional Scale: [%g %g %g], [%g %g %g]', ANASCALE, FUNCSCALE);
  txt{end+1}  = sprintf('Bootstrap: [%g %g], N=%d', CIVAL, BSTRP);
  MSKPtxt = sprintf('%g ', MSKP);
  txt{end+1}  = sprintf('Mask=[%s]', msk);
  txt{end+1}  = sprintf('p(msk)<=%s', MSKPtxt);
  MDLPtxt = sprintf('%g ', MDLP(:));
  txt{end+1}  = sprintf('Model=[%s]', mdl);
  txt{end+1}  = sprintf('p(mdl)<=%s', MDLPtxt);
  txt{end+1}  = sprintf('GLM: Reference Group: [%s]', upper(refgrp.grpexp));
  if isfield(grp,'design'),
    txt{end+1}  = sprintf('Stimulus Design: [%s]', grp.design);
  end;
  if isfield(grp,'label'),
    tmp = '';
    for N=1:length(grp.label),
      tmp = strcat(tmp,'-',grp.label{N});
    end;
    
    txt{end+1}  = sprintf('ES-PAR: [%s]', tmp);
  else
    txt{end+1} = 'Field grp.label not defined';
  end;
  
  for N=1:length(txt),
    K = 10 * N; text(10,K,txt{N});
  end;
end;

% POS = [0.55 0.1 0.40 0.55];
% subplot('position',POS);
POS=[2 4 6 8];
for N=1:length(roiTs),
  subplot(length(roiTs),2,POS(N)); 
  if all(isnan(roiTs{N}.dat)), continue; end;
  if isfield(anap,'inj'),
    m = hnanmean(roiTs{N}.dat(1:anap.inj.PRE_VOL,:),1);
    roiTs{N}.dat = roiTs{N}.dat - repmat(m,[size(roiTs{N}.dat,1) 1]);
  end;
  roiTs{N} = xform(roiTs{N},'zerobase','blank');
  if exist('LineStyle','var') && ~isempty(LineStyle),
    if LineStyle(N)
      hd(N) = dsproits(roiTs{N},'color',COL_LINE(N),'bstrp',BSTRP,'cival',...
                       CIVAL,'linewidth',1.5,'stderror',STDERROR);
    else
      hd(N) = dsproits(roiTs{N},'color',COL_LINE(N),'bstrp',0,'cival',CIVAL,'linewidth',2,'linestyle',':');
    end;
  else
    hd(N) = dsproits(roiTs{N},'color',COL_LINE(N),'bstrp',BSTRP,'cival',...
                     CIVAL,'linewidth',1.5,'stderror',STDERROR);
  end;
  
  if DRAWSTM,
    drawstmlines(roiTs{1},'linestyle','none');
  end;
  if N==length(roiTs), xlabel('Time in seconds'); end;
  
  ylabel('SD Units');
  if YGRID,
    set(gca,'ygrid','on');
  end;
  box on;
  title(roiTXT{N});
end;

% [h, h1] = legend(hd,roiTXT,'location','northwest');
% set(h,'FontWeight','normal','FontSize',8,'color',[1 1 1]);
% set(h,'xcolor','k','ycolor','k');
% set(h1,'linewidth',3);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function troiTs = getTrialMeans(SesName, GrpName, roiTs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses         = goto(SesName);
grp         = getgrpbyname(Ses,GrpName);
anap        = getanap(Ses,GrpName);
inj         = anap.inj;

PRE_TRIALS      = inj.PRE_TRIALS;
TRANS_TRIALS    = inj.TRANS_TRIALS;
POST_TRIALS     = inj.POST_TRIALS;

% ------------------------------------------------------------------------------------------
% WARNING: This is temporary for the A. Rauch 17.08.10 session CHANGE!!!!!!!!!!!!!!!!!
% ------------------------------------------------------------------------------------------
PRE_TRIALS      = [1:5];
TRANS_TRIALS    = [6:7];
POST_TRIALS     = [8:12];
% ------------------------------------------------------------------------------------------

% GET PRE-INJECTION AND POST-INJECTION TRIALS
PRESTIM = 5;               % We choose 3 volumes as prestim
PreT    = PRESTIM * roiTs.dx;
PostT   = inj.TRIAL_DUR * roiTs.dx;

% SPLIT IN TRIALS AND NORMALIZE
spar    = getsortpars(Ses,grp.exps(1));

savTs = roiTs;
for N=1:size(roiTs.dat,3),
  roiTs.dat = savTs.dat(:,:,N); % For each experiment
  troiTs = sigsort(roiTs,spar.trial,PreT,PostT);
  % Because the very first does not have a "PreT" it returns NaN
  % We replace the NaN with the values of the second troiTs
  troiTs.dat(1:PRESTIM,:,1) = hnanmean(troiTs.dat(1:PRESTIM,:,2),3);
  dat(:,:,:,N) = troiTs.dat;
end;
troiTs.dat = dat;

% NOTE: Initially the .dat field is Time X Model X Trial X ExpNo
% with this one here: troiTs_pre.dat  = troiTs_pre.dat(:,:,:), we have Time X Model X Trial*ExpNo
% For each Pre/Post the trial average is thus average of all trials and all exps
troiTs.pre      = troiTs;
troiTs.pre.dat  = troiTs.dat(:,:,PRE_TRIALS,:);
troiTs.post     = troiTs;
troiTs.post.dat = troiTs.dat(:,:,POST_TRIALS,:);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subPlotTrials(troiTs, COLOR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sig = troiTs;
sig.dat = troiTs.pre.dat;
sig = xform(sig,'zerobase','blank');
troiTs.pre.dat = sig.dat;
sig.dat = troiTs.post.dat;
sig = xform(sig,'zerobase','blank');
troiTs.post.dat = sig.dat;

prem    = squeeze(nanmean(troiTs.pre.dat(:,:,:),2));
postm   = squeeze(nanmean(troiTs.post.dat(:,:,:),2));

presd = hnanstd(prem,2)/sqrt(size(prem,2));
postsd = hnanstd(postm,2)/sqrt(size(postm,2));
prem = nanmean(prem,2);
postm = nanmean(postm,2);
t = [0:length(prem)-1] * troiTs.dx;

hd = errorbar(t, prem, presd);
eb = findall(hd);
set(eb(1),'LineWidth',0.5,'Color', COLOR);
set(eb(2),'LineWidth',1.0,'Color', COLOR);
hold on;
hd = errorbar(t, postm, postsd);
eb = findall(hd);
set(eb(1),'LineWidth',0.5,'Color', COLOR);
set(eb(2),'LineWidth',3.0,'Color', COLOR);
set(gca,'xlim',[t(1) t(end)],'ygrid','on');
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ix = GetMdlIdx(anap, MdlName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ix = 0;
for N=1:length(anap.showmap.MODELNAME),
  if strcmp(anap.showmap.MODELNAME{N},MdlName),
    ix = N;
    return;
  end;
end;
return;




  