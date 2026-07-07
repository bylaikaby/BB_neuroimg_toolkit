function [ANAP, ROI, GRPP, CTG] = esfmri(SesName)
%ESFMRI - Defines common parameters for es-phys-fMRI
% [ANAP, ROI, GRPP] = esfmri(SesName)
% NKL 16.05.10
%  

% ----------------------------------------------------------------------------------------
% GLOBAL DEFINITIONS FOR ALL SESSIONS, E.G. DIRECTORIES, MODELS, ETC.
% ----------------------------------------------------------------------------------------
ANAP.ClusterMode = 0;          % When using the office-cluster
DIRS = getdirs;  % Our directory structure
switch lower(DIRS.HOSTNAME)
 case {'nb-nikos' 'nb-nikos-travel' 'workbook-nikos' 'ultrabook-nikos'}
  ANAP.ClusterMode = 0;
 case {'win447' 'node4' 'node5' 'node6'}
  ANAP.ClusterMode = 0;
end

if ANAP.ClusterMode,
  DRV = '\\nkldata\YDISK';                  % All data are on the cluster disk
% elseif exist('y:/','dir'),
%   DRV = 'Y:/';
elseif strcmpi(DIRS.HOSTNAME,'ultrabook-nikos') | strcmpi(DIRS.HOSTNAME,'nb-nikos'),
  DRV = 'F:/';
else
  DRV = 'D:/BrainMaps';
end;

ANAP.project.GlobalDir      = fullfile(DRV,'Global/Ripples');
ANAP.project.imagefile      = fullfile(DRV,'Global/Anatomy/rathead16T.img');
ANAP.project.atlasfile      = fullfile(DRV,'GlobalAnatomy/rathead16T_AtlasROIs.mat');
ANAP.project.elesite        = fullfile(DRV,'Projects/Anatomy/RatEleSites');
ANAP.project.flicker_dir    = fullfile(DRV,'Global/Flicker');
ANAP.project.estim_dir      = fullfile(DRV,'Global/DES');
ANAP.project.datadir        = fullfile(DRV,'DataMatlab/');
ANAP.project.atlas.ds       = [0.1 0.1 0.1];
ANAP.project.atlas.bregma   = [147 134 36]; % AP, ML, DV coordinates of Bregma
ANAP.project.ExpList        = 'selected';   % Option(1) = 'original'; used by description files

% FOR TESTING CLUSTER MACHINES...
%ANAP.project.datadir        = fullfile(DRV,'DataTestCluster/');

% Directory of Raw Data for "Cluster" machines.
if any(ANAP.ClusterMode),
  ANAP.project.DataMri =   '//nkldata/DataRawHipp/';
  ANAP.project.DataNeuro = '//nkldata/DataRawHipp/';
end


  
SesName = lower(SesName);

%=========================================================================================
% ROI for MRI experiments, if exist or needed, then put here
%=========================================================================================
ROI.groups	= {'all'};                          % SuperAvg (see HROI)
ROI.names	= {'brain';'V1';'V2';'inj';'ipz'};
ROI.model	= 'brain';                          % Group to use as model

% more ROIs
tmproi      = {'Brain','LEFT','RIGHT','inj','ipz'};
ROI.groups  = {'All'};                      % SuperAvg (see HROI)
ROI.model   = 'brain';                       % Group to use as model
ROI.names   = {};
ROI.names   = paxroigroups('ROI','monkey');  
ROI.names   = cat(2,tmproi, ROI.names);


%=========================================================================================
% CATEGORIES (CTG) OF  EXPS/GROUPS/SIGS, if exist or needed
%=========================================================================================
CTG.GrpPhySigs      = {};                       % Group these physiology signals
CTG.TrialSigs       = {'roiTs'};                % Signals to be sorted by trial (sesgettrial)

ANAP.AlertMonkeyExp =  1;
ANAP.essite         = 'LGN';

% Averages of BLPs that we use for models
% v1 = nanmean(squeeze(nanmean(tblp.dat(:,[1 2],:),2)),2);
% v2 = nanmean(squeeze(nanmean(tblp.dat(:,[3:5],:),2)),2);
% v3 = nanmean(squeeze(nanmean(tblp.dat(:,[6],:),2)),2);
ANAP.LFP = {[1 2], [3:5], [6]};
ANAP.CH  = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stimulation parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CLN & BLP
ANAP.clnpar.REMOVE_ES       = 1;           % try to remove microstimulation artifact
ANAP.siggetblp.conv2sdu     = 'none';
ANAP.siggetblp.conv2sdu     = 3;            % Select "zerobase" mode
ANAP.siggetblp.conv2sdu     = {'sdu','blank'};            % Select "zerobase" mode



% SPIKE EXTRACTION
ANAP.siggetspk.conv2sdu     = 0;            % No normalization - direct spike-count
ANAP.siggetspk.binwidth     = 0.001;        % 10ms binwidth for peristimulus histograms
ANAP.siggetspk.sdfrate      = 500;          % 500Hz resampling rate for SDF
ANAP.siggetspk.sdfkernel    = 0.005;        % 5ms X 3 (SD) X 2 = kernel size
ANAP.siggetspk.threshold    = 3.5;
ANAP.siggetspk.base_period  = 'blank';

% ES-Triggered Averaging to see post-pulse responses
GRPP.esch       = 3;                    % electric stimulation recorded channel
GRPP.espdur     = [0.2 0.0 0.2];        % first pulse, interpulse, second pulse durations
GRPP.espcur     = [-400 0 400];         % electric stimulation current for the three durations
GRPP.esspkwin   = [0.5 1];              % spike removal window in msec [start end]
GRPP.essigs     = {'blp','Cln','Sdf','Spkt'};
GRPP.burst      = 0.3;

ANAP.sesesmean.window       = [-1000 8000];    % To see responses for ISI intervals


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extraction of time series from ROIs (in the Roi.mat)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ANAP.imgload.INORMALIZE = 1;
ANAP.imgload.IDETREND   = 0;

ANAP.mareats.IEXCLUDE       = {'brain'};    % Exclude in MAREATS
ANAP.mareats.ICONCAT        = 1;            % 1= concatanate ROIs before creating roiTs
ANAP.mareats.IFFTFLT        = 0;            % Respiratory artifact removal I
ANAP.mareats.IARTHURFLT     = 1;            % IT ONLY MAKES SENSE for TR <= 500
ANAP.mareats.IGAMMA         = 0;            % NO need for gamma-correction in these sessions
ANAP.mareats.IDETREND       = 0;
ANAP.mareats.ICUTOFF        = 0.750;        % DX = 0.250
ANAP.mareats.ICUTOFFHIGH    = 0.030;
ANAP.mareats.ITOSDU         = 0;            % Express data in SD Units
ANAP.mareats.IHEMODELAY     = 0;
ANAP.mareats.IHEMOTAIL      = 0;
ANAP.mareats.IMIMGPRO       = 1;            % Do image processsing
ANAP.mareats.IFILTER        = 1;            % 1=to spatially filter; 0=no filter at all
ANAP.mareats.IFILTER_KSIZE  = 5;            % Kernel size
ANAP.mareats.IFILTER_SD     = 2;            % SD (if half about 90% of flt in kernel)
ANAP.mareats.ISUBSTITUDE    = 0;            % DO not use this if you have dummy scans
ANAP.mareats.USE_REALIGNED  = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VIEWER parameters and defaults
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ANAP.mview.viewmode         = 'lightbox-trans';
ANAP.mview.viewpage         = 1;
ANAP.mview.nrowncol_trans   = [3 3];
ANAP.mview.roi              = 'all';
ANAP.mview.alpha            = 0.05;
ANAP.mview.datname          = 'statv';
ANAP.mview.statistics       = 'glm';
ANAP.mview.glmana.model     = 'fVal';
ANAP.mview.glmana.trial     = 1;
ANAP.mview.cluster          = 1;
ANAP.mview.negcorr          = 0;
ANAP.mview.mcluster3.B      = 3;
ANAP.mview.mcluster3.cutoff = round((2*(ANAP.mview.mcluster3.B-1)+1)^3*0.3);
ANAP.mview.bwlabeln.conn    = 26;	% must be 6(surface), 18(edges) or 26(corners)
ANAP.mview.bwlabeln.minvoxels = ANAP.mview.bwlabeln.conn * 0.4;
ANAP.mview.slices           = [];

GRPP.anap.HemoDelay     = 0;  % 2->worse
GRPP.anap.HemoTail      = 2;  % 6->worse

DO_BY_TRIAL = 1;
if DO_BY_TRIAL,
  GRPP.grpsigs   = {'troiTs','tblp','esblp','esCln','esSdf','esSpkt','es0Cln'};
else
  GRPP.grpsigs    = {'roiTs'};         % Overwrites GrpPhySigs and GrpImgSigs on a GROUP-basis!!!
end

% Definitions regarding sorting by trial
GRPP.anap.gettrial.status       = DO_BY_TRIAL;        % IsTrial
GRPP.anap.gettrial.Xmethod      = 'tosdu';
GRPP.anap.gettrial.Xepoch       = 'prestim';% Argument (Epoch) to xfrom in gettrial
GRPP.anap.gettrial.Average      = 1;        % Do not average tblp, but concat
GRPP.anap.gettrial.RefChan      = 2;        % Reference channel (for DIFF)
GRPP.anap.gettrial.sort         = 'trial';  % sorting with SIGSORT, can be 'none|stimulus|trial
GRPP.anap.gettrial.trial2obsp   = 0;
GRPP.anap.gettrial.HemoDelay    = GRPP.anap.HemoDelay;
GRPP.anap.gettrial.HemoTail     = GRPP.anap.HemoTail;
GRPP.anap.gettrial.PreT         =  6;
GRPP.anap.gettrial.PostT        =  6+10;
GRPP.anap.gettrial.PreT         =  0;
GRPP.anap.gettrial.PostT        =  0;
GRPP.anap.gettrial.CheckCentroid   = 0;

GRPP.anap.gettrial.blp.Xmethod = 'none';
GRPP.anap.gettrial.ClnSpc.Xmethod = 'none';
GRPP.anap.gettrial.Spkt.Xmethod = 'none';
GRPP.anap.gettrial.Sdf.Xmethod = 'none';


% Definitions related to correlation or GLM analysis
ANAP.aval               = 0.50;         % p-value for selecting time series
ANAP.rval               = 0.05;         % r (Pearson) coeff. for selecting time series
ANAP.shift              = 1;            % nlags for xcor in seconds
ANAP.clustering         = 1;            % apply clustering after voxel-selection
ANAP.bonferroni         = 0;            % Correction for multiple comparisons

% CORR analysis
GRPP.groupcor           = 'before cor';
GRPP.corana{1}.mdlsct   = 'fhemo';           % Model for correlation analysis (see expgetstm)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Control flags for GLM analysis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
GRPP.groupglm                = 'before glm';
GRPP.anap.glm.IARESTIMATION  = 0;            % AR estimation
GRPP.anap.glm.ISATTERWAITH   = 0;            % Satterwaith
GRPP.anap.glm.ICONVWITHGAMMA = 0;

MDL = 2;
if MDL==1,
  % Number of GLM regressors + constant function
  GRPP.glmconts = [];
  GRPP.glmana{1}.mdlsct = {'fhemo','dtfhemo'};
  NoReg = length(GRPP.glmana{1}.mdlsct) + 1;
  GRPP.glmconts{end+1} = setglmconts('f','fVal',NoReg,'pVal',0.1);
  GRPP.glmconts{end+1} = setglmconts('t','pbr',  [ 1  0  0],'pVal',1);
  GRPP.glmconts{end+1} = setglmconts('t','pbr2', [ 0  1  0],'pVal',1);
  GRPP.glmconts{end+1} = setglmconts('t','nbr',  [-1  0  0],'pVal',1);
  GRPP.glmconts{end+1} = setglmconts('t','nbr2', [ 0 -1  0],'pVal',1);
elseif MDL==2,
  GRPP.glmconts = [];
  GRPP.glmana{1}.mdlsct = {'MDL_esburst.mat[2]','MDL_esburst.mat[3]'};
  NoReg = length(GRPP.glmana{1}.mdlsct) + 1;
  GRPP.glmconts{end+1} = setglmconts('f','fVal',NoReg,'pVal',0.1);
  GRPP.glmconts{end+1} = setglmconts('t','nm',     [ 1  0  0],'pVal',1);
  GRPP.glmconts{end+1} = setglmconts('t','gamma',  [ 0  1  0],'pVal',1);
  GRPP.glmconts{end+1} = setglmconts('t','-nm',    [-1  0  0],'pVal',1);
  GRPP.glmconts{end+1} = setglmconts('t','-gamma', [ 0 -1  0],'pVal',1);
else
  GRPP.glmconts = [];
  GRPP.glmana{1}.mdlsct = {'MDL_esburst.mat[1]','MDL_esburst.mat[2]',...
                      'MDL_esburst.mat[3]','MDL_esburst.mat[4]'};
  NoReg = length(GRPP.glmana{1}.mdlsct) + 1;
  GRPP.glmconts{end+1} = setglmconts('f','fVal',NoReg,'pVal',0.1);
  GRPP.glmconts{end+1} = setglmconts('t','pes',   [ 1  0  0  0  0],'pVal',1);
  GRPP.glmconts{end+1} = setglmconts('t','nes',   [ 0  1  0  0  0],'pVal',1);
  GRPP.glmconts{end+1} = setglmconts('t','dpes',  [ 0  0  1  0  0],'pVal',1);
  GRPP.glmconts{end+1} = setglmconts('t','dnes',  [ 0  0  0  1  0],'pVal',1);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  IC ANALYSIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
GRPP.anap.ica.evar_keep         = 10;           % Numbers of PCs to keep
GRPP.anap.ica.SIGNAME           = 'roiTs';
GRPP.anap.ica.TFILTER           = [0 0.02];     % mareats(0.033)
GRPP.anap.ica.mdlname           = {};           % Name of model (ICs or their average)
GRPP.anap.ica.ic2mdl            = [];           % e.g. {[1 7],[2]};

GRPP.anap.ica.roinames          = {'v1'};       % Analyzie only TS in these ROIs
GRPP.anap.ica.dim               = 'spatial';    % Temporal does not really work...
GRPP.anap.ica.type              = 'bell';       % The Tony Bell algorithm
GRPP.anap.ica.normalize         = 'none';       % No normalization (e.g. to SD etc.)
GRPP.anap.ica.period            = 'all';        % Blank, stim, all...
GRPP.anap.ica.icomp             = [1:10];       % Show this components only
GRPP.anap.ica.slices            = [];           % Slices to show

C={[1 0 0],[0 1 1],[0 0 1],[1 0 1],[0 .7 .7],[.7 0 .7],[0 0 .4],[.4 .4 0],[.3 .3 .3],[1 .6 .3]};
GRPP.anap.ica.COLORS = cat(2,C,C,C);   

% TO USE SOME ICs or THEIR MEAN AS MODELS DEFINE THE FOLLOWING FIELDS:
GRPP.anap.ica.mdlname           = {};               % e.g. {'V1','V2','MT','XC'};
GRPP.anap.ica.ic2mdl            = [];               % e.g. {[1 7],[2]};
GRPP.anap.ica.DISP_THRESHOLD    = 2.3;              % For SHOWICA only (ca. 2 SDs)

GRPP.anap.ica.mdlidx            = [];           % Use the first 2 models for selecting ICs
GRPP.anap.ica.pVal              = 0.001;        % pVal for corr(mixica,IComponent)
GRPP.anap.ica.rVal              = 0.3;          % rVal-thr for corr(mixica,IComponent)

ANAP.selroits.GRPNAME   = {'lgnv', 'es300'};
ANAP.selroits.ROINAME   = {{'V1',  'V2'}, {'V1', 'V2'}};
ANAP.selroits.CONTRAST  = {{'pbr', 'pbr'}, {'pbr', 'nbr'}};
ANAP.selroits.PVAL      = {[.001 .01], [.001 .01]};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Control flags for the SHOWMAP program
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ANAP.showmap.STDERROR   = 0;             % If set uses errorbar otherwise CI
ANAP.showmap.CIVAL      = [1 99];        % low and high confidence interval
ANAP.showmap.BSTRP      = 200;
ANAP.showmap.TRIAL      = [];
ANAP.showmap.FUNCSCALE  = [0 10 1.5];
ANAP.showmap.ANASCALE   = [0 10000 1.2];
ANAP.showmap.DRAW_ROI   = {};
ANAP.showmap.FMTTYPE    = 'paper';       % Default is paper

ANAP.showmap.COL_FACE   = [];            % shading color for CI plots
ANAP.showmap.COL_LINE   = 'rbgck';
ANAP.showmap.CMAP       = {'r','b','g','c','k'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fine-tuning of GLM/SHOWMAP parameters (per session)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ANAP.ImgDistort = 0;
ANAP.Quality    = 90;       % 90/100
ANAP.REFGROUP   = [];

switch(SesName),
 % ------------------------------------------------------------------------------------
 % Sessions for getting a global average of PBR/NBR in different areas
 % ------------------------------------------------------------------------------------
 case 'h05271',
  ANAP.mview.anascale       = [0 12000 1.3];
  ANAP.mview.funscale       = [0 8 1.4];
  ANAP.mview.roi            = 'V1';
  ANAP.mview.alpha          = 0.0000001;
  ANAP.showessigs.RoiName   = 'V1';
  ANAP.showessigs.ModelName = 'nm';
  ANAP.showessigs.pVal      = 1e-9;
 case 'h05272',
  ANAP.mview.anascale       = [0 8000 1.2];
  ANAP.mview.funscale       = [0 8 2.3];
  ANAP.mview.roi            = 'V2';
  ANAP.mview.alpha          = 0.001;
  ANAP.showessigs.RoiName   = 'IPZ';
  ANAP.showessigs.ModelName = 'fVal';
  ANAP.showessigs.pVal      = 1e-7;
 case 'g032m1'
  ANAP.mview.anascale       = [0 8000 1.2];
  ANAP.mview.funscale       = [0 8 2.3];
 case 'd04nm6'
  ANAP.mview.anascale       = [0 8000 1.2];
  ANAP.mview.funscale       = [0 8 2.3];
 case 'rat2c1'
  ANAP.mview.anascale       = [0 8000 1.2];
  ANAP.mview.funscale       = [0 8 2.3];
  
 case {'b06nm6'}
  
 otherwise,
  fprintf('Unknown session %s; edit esfmri.m and define new "case"\n', SesName);
  keyboard;
end;

if isfield(ANAP.mview,'funscale'),
ANAP.showmap.FUNCSCALE  = ANAP.mview.funscale;
ANAP.showmap.ANASCALE   = ANAP.mview.anascale;
end

return;

