function [ANAP, ROI, GRPP] = esgetpars
%ESGETPARS - Get common parameters for all microstimulation experiments
% pars = esgetpars(GRP)
% NKL 17.03.2007


% ----------------------------------------------------------------------------------------
% GLOBAL DEFINITIONS FOR ALL SESSIONS, E.G. DIRECTORIES, MODELS, ETC.
% ----------------------------------------------------------------------------------------
ANAP.ClusterMode = 1;          % When using the office-cluster
DIRS = getdirs;  % Our directory structure
switch lower(DIRS.HOSTNAME)
 case {'nb-nikos' 'nb-nikos-travel' 'workbook-nikos' 'ultrabook-nikos'}
  ANAP.ClusterMode = 0;
 case {'win447' 'node4' 'node5' 'node6'}
  ANAP.ClusterMode = 1;
end

if ANAP.ClusterMode,
  DRV = '\\nkldata\YDISK';                  % All data are on the cluster disk
elseif exist('y:/','dir'),
  DRV = 'Y:/';
elseif strcmpi(DIRS.HOSTNAME,'ultrabook-nikos') | strcmpi(DIRS.HOSTNAME,'nb-nikos'),
  DRV = 'F:/';
else
  DRV = 'D:/';
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


%=========================================================================================
% ROI for MRI experiments, if exist or needed, then put here
%=========================================================================================
ROI.groups	= {'all'};                            % SuperAvg (see HROI)
ROI.names	= {'LGN';'SC';'Pul';'V1';'V2';'XC';'MT';'Brain';'inj';'ipz';'ica'};
ROI.model	= 'LGN';                              % Group to use as model

% ------------------------------------------------------------------------
% Variables evaluated by MAREATS
% ------------------------------------------------------------------------
GRPP.anap.mareats.IEXCLUDE       = {'brain'};
GRPP.anap.mareats.ICONCAT        = 1;     % 1= concatanate ROIs before creating roiTs
GRPP.anap.mareats.IFFTFLT        = 0;     % Respiratory artifact removal I
GRPP.anap.mareats.IARTHURFLT     = 0;     % IT ONLY MAKES SENSE for TR <= 500
GRPP.anap.mareats.IGAMMA         = 0;     % NO need for gamma-correction in these sessions
GRPP.anap.mareats.IDETREND       = 0;
GRPP.anap.mareats.ITOSDU         = 0;     % Express data in SD Units
GRPP.anap.mareats.IHEMODELAY     = 2;     % For computing baseline in XFORM
GRPP.anap.mareats.IHEMOTAIL      = 2;     % Same.. but only for non-prestim cases
GRPP.anap.mareats.IMIMGPRO       = 1;     % Do image processsing
GRPP.anap.mareats.IFILTER        = 1;     % 1=to spatially filter; 0=no filter at all
GRPP.anap.mareats.ISUBSTITUDE    = 0;     % DO not use this if you have dummy scans
GRPP.anap.mareats.IPCA           = 0;     % Reconstruct all TS from the first 8 components

if      GRPP.anap.mareats.IFILTER  == 1,
  GRPP.anap.mareats.IFILTER_KSIZE  = 3;     % Kernel size
  GRPP.anap.mareats.IFILTER_SD     = 0.75;  % SD (if half about 90% of flt in kernel)
  GRPP.anap.mareats.ICUTOFF        = 0.211;
  GRPP.anap.mareats.ICUTOFFHIGH    = 0.010;
elseif  GRPP.anap.mareats.IFILTER  == 2,
  GRPP.anap.mareats.IFILTER_KSIZE  = 3;     % Kernel size
  GRPP.anap.mareats.IFILTER_SD     = 1.25;  % SD (if half about 90% of flt in kernel)
  GRPP.anap.mareats.ICUTOFF        = 0.210;
  GRPP.anap.mareats.ICUTOFFHIGH    = 0.016;
elseif  GRPP.anap.mareats.IFILTER  == 3,
  GRPP.anap.mareats.IFILTER_KSIZE  = 5;     % Kernel size
  GRPP.anap.mareats.IFILTER_SD     = 2;     % SD (if 1.5 ca. 90% of flt in kernel)
  GRPP.anap.mareats.ICUTOFF        = 0.180;
  GRPP.anap.mareats.ICUTOFFHIGH    = 0.010;
else
end;

% Definitions regarding sorting by trial
GRPP.anap.gettrial.status       = 1;
GRPP.anap.gettrial.trial2obsp   = 1;
GRPP.anap.gettrial.Xmethod      = 'percent';  % tosdu-prestim doesn't show anything,
GRPP.anap.gettrial.Xepoch       = 'blank';  % Argument (Epoch) to xfrom in gettrial
GRPP.anap.gettrial.sort         = 'trial';  % sorting with SIGSORT, can be 'none|stimulus|trial
GRPP.anap.gettrial.RefChan      = 2;        % Reference channel (for DIFF)
GRPP.anap.gettrial.Average      = 1;        % Concat/Average; It is also used from trial2obsp

% The field "voxselect" is used by the function MASKCOMBINE for selecting positive or
% negative ES-induced responses from within a visual map (mask) that is only positive or
% only negative.roiTs
% voxselect.masks are usually the visual maps
% voxselect.models are the regressors for selecting ES response
% Extraction of time series from ROIs (in the Roi.mat)
GRPP.anap.voxselect.dx          = 1;    % Sampling time before averaging
GRPP.anap.voxselect.roinames    = ROI.names;
GRPP.anap.voxselect.masks       = {'visesmix', {'fVal', 'fVal'},  0.05};
GRPP.anap.voxselect.models      = {'visesmix', {'pes', 'nes' },   0.05};

ANAP.mroi.gamma     = 1.6;
ANAP.mroi.colors    = 'wcyrgbmwcyrgbm';        % Colors for drawing activations on MROI anatomy/rois
ANAP.mroi.mapcolors = 'kgkrbwcymrbgcwk';       % Colors for drawing activations on MROI anatomy/rois

% Definitions related to correlation or GLM analysis
ANAP.aval               = 0.50;         % p-value for selecting time series
ANAP.rval               = 0.05;         % r (Pearson) coeff. for selecting time series
ANAP.shift              = 1;            % nlags for xcor in seconds
ANAP.clustering         = 1;            % apply clustering after voxel-selection
ANAP.bonferroni         = 0;            % Correction for multiple comparisons

DO_BY_TRIAL = 1;
if DO_BY_TRIAL,
GRPP.grpsigs    = {'troiTs'};         % Overwrites GrpPhySigs and GrpImgSigs on a GROUP-basis!!!
else
GRPP.grpsigs    = {'roiTs'};         % Overwrites GrpPhySigs and GrpImgSigs on a GROUP-basis!!!
end

ANAP.mview.viewmode             = 'lightbox-trans';
ANAP.mview.anascale             = [0  20000  1];
ANAP.mview.roi                  = 'ALL';
ANAP.mview.alpha                = 0.01;
ANAP.mview.statistics           = 'glm';
ANAP.mview.datname              = 'statv';
ANAP.mview.glmana.model         = 1;
ANAP.mview.glmana.trial         = 1;
ANAP.mview.cluster              = 1;
ANAP.mview.negcorr              = 1;

ANAP.mview.bwlabeln.conn        = 26;	% must be 6(surface), 18(edges) or 26(corners)
ANAP.mview.bwlabeln.minvoxels   = ANAP.mview.bwlabeln.conn * 0.8;

% The selection of clustering method and "size" is critical to get most of the ROIs without
% getting the garbage...
ANAP.mview.mcluster3.B          = 3;
ANAP.mview.mcluster3.cutoff     =  round((2*(ANAP.mview.mcluster3.B-1)+1)^3*0.3);

% CHECK THIS ONE HERE.......
ANAP.mview.clusterfunc          = 'mcluster3';
ANAP.mview.clusterfunc          = 'bwlabeln';

ANAP.mview.slices               = [];
ANAP.mview.glmana.minmax        = [0 120];
ANAP.mview.glmana.model         = 1;

% ------------------------------------------------------------------------
% USE THE FOLLOWING MODELS (CREATED WITH ESMODELS) TO SELECT ICs
% Variables evaluated by GETICA, SHOWICARES and SHOWICA
% ------------------------------------------------------------------------
GRPP.anap.ica.ClnSpc.evar_keep  = 20;
GRPP.anap.ica.ClnSpc.dim        = 'spatial';
GRPP.anap.ica.ClnSpc.type       = 'bell';
GRPP.anap.ica.ClnSpc.normalize  = 'none';

% FOR ROITS ETC.
GRPP.anap.ica.evar_keep         = 20;               % Numbers of PCs to keep
GRPP.anap.ica.roinames          = {'SC','LGN','V1','V2','MT','XC'};
GRPP.anap.ica.dim               = 'spatial';        % Temporal does not really work...
GRPP.anap.ica.type              = 'bell';           % The Tony Bell algorithm
GRPP.anap.ica.normalize         = 'none';           % No normalization (e.g. to SD etc.)
GRPP.anap.ica.period            = 'all';            % blank, stim, all...
GRPP.anap.ica.icomp             = [1:GRPP.anap.ica.evar_keep];
GRPP.anap.ica.mdlname           = {'pbr','nbr'};    % Name of model (ICs or their average)
GRPP.anap.ica.ic2mdl            = [];               % Use the following ICs as models for GLM
GRPP.anap.ica.DISP_THRESHOLD    = 2;                % For SHOWICA only (ca. 2 SDs)
GRPP.anap.ica.SIGNAME           = 'troiTs';

% The following defitions refer to the selection of ICs on the basis of their similarity to
% standard models, e.g. AvgResp.dat containing the average of all sessions for visesmix
% experiments. Different vectors represent responses in different areas, e.g. model.dat(:,1)
% is usually the V1 response, model.dat(:,2) the V2 response, and so on.
% The pVal and rVal fields are used by ICASELECT(SesName, GrpName).
% To run this function, you must (a) run GETICA, (b) esmodels(Ses,Grp,'avgresp') or any
% other model, and then [idx, r] = icaselect(Ses,Grp).
% To see the selected IC run ICASELECT without output arguments
GRPP.anap.ica.mdlidx            = [];           % Use the first 2 models for selecting ICs
GRPP.anap.ica.pVal              = 0.01;         % pVal for corr(mixica,IComponent)
GRPP.anap.ica.rVal              = 0.25;          % rVal-thr for corr(mixica,IComponent)

C={[1 0 0],[0 1 0],[0 0 1],[0 0 0],[0 .7 .7],[.7 0 .7],[0 0 .4],[.4 .4 0],[.3 .3 .3],[1 .6 .3]};
GRPP.anap.ica.COLORS = cat(2,C,C,C);   

% ====================================================================================================
% SHOWMAP (SesName, GrpName)
% All the definitions below will be overwritten by the command-line arguments
% ====================================================================================================
ANAP.showmap.STDERROR      = 0;        % If set uses errorbar otherwise CI
ANAP.showmap.CIVAL         = [1 99];   % low and high confidence interval
ANAP.showmap.BSTRP         = 100;
ANAP.showmap.TRIAL         = [];
ANAP.showmap.FUNCSCALE     = [0 10 1.5];
ANAP.showmap.ANASCALE      = [0 10000 1.2];
ANAP.showmap.DRAW_ROI      = {};
ANAP.showmap.MASKNAME      = {'fVal','fVal'};
ANAP.showmap.MODELNAME     = {'IC1','IC2'};
ANAP.showmap.MDLP          = [0.001 0.001];
ANAP.showmap.MSKP          = [0.1 0.1];
ANAP.showmap.ROINAME       = {{'V1','V2'},{'V1','V2'}};
ANAP.showmap.FMTTYPE       = 'paper';       % Default is paper
ANAP.showmap.COL_LINE      = 'rbcmgyck';
ANAP.showmap.COL_FACE      = [];            % shading color for CI plots
ANAP.showmap.CMAP          = {'r','b','c','m','g','y','c','k'};

% CORR analysis
GRPP.groupcor           = 'before cor';
GRPP.corana{1}.mdlsct   = 'boxcar';           % Model for correlation analysis (see expgetstm)

% Control flags for GLM analysis
GRPP.groupglm                = 'before glm';
GRPP.anap.glm.IARESTIMATION  = 0;            % AR estimation
GRPP.anap.glm.ISATTERWAITH   = 0;            % Satterwaith
GRPP.anap.glm.ICONVWITHGAMMA = 0;

GRPP.glmana{1}.mdlsct = {'hemo'};
NoReg = length(GRPP.glmana{1}.mdlsct) + 1;
GRPP.glmconts = {};
GRPP.glmconts{end+1} = setglmconts('f','fVal',NoReg,'pVal',0.1);
GRPP.glmconts{end+1} = setglmconts('t','pbr',   [ 1 0],'pVal',1);
GRPP.glmconts{end+1} = setglmconts('t','nbr',   [-1 0],'pVal',1);

if 0,       % EXAMPLE of ROI-model (FIRST run esmodels('h03de1','freqtest1','pul'))
  DNO=1;
  GRP.freqtest1.glmana{DNO}.mdlsct = {'MDL_freqtest1_pul.mat[1]'};
  NoReg = length(GRP.freqtest1.glmana{DNO}.mdlsct) + 1;
  GRP.freqtest1.glmconts{end+1} = setglmconts('f','fVal', NoReg,'pVal',0.1);
  GRP.freqtest1.glmconts{end+1} = setglmconts('t','pbr',   [ 1 0],'pVal',DNO);
  GRP.freqtest1.glmconts{end+1} = setglmconts('t','nbr',   [-1 0],'pVal',DNO);
  
  DNO=2;
  if ~isempty(GRP.freqtest1.anap.ica.ic2mdl),
    for N=1:length(GRP.freqtest1.anap.ica.ic2mdl),
      GRP.freqtest1.glmana{DNO}.mdlsct{N} = sprintf('ICAMDL_freqtest1.mat[%d]', N);
    end;
    NoReg2 = length(GRP.freqtest1.glmana{DNO}.mdlsct) + 1;
    
    txt = GRP.freqtest1.anap.ica.mdlname;
    ConMat = zeros(NoReg2, NoReg2-1);
    for N=1:length(GRP.freqtest1.anap.ica.ic2mdl), ConMat(N,N) = 1;  end;  ConMat = ConMat';
    GRP.freqtest1.glmconts{end+1} = setglmconts('f','IC-fVal',NoReg2,'pVal',0.1,'WhichDesign',DNO);
    for N=1:size(ConMat,1),
      GRP.freqtest1.glmconts{end+1} = setglmconts('t',txt{N},ConMat(N,:),'pVal',1,'WhichDesign',DNO);
    end;
    GRP.freqtest1.glmconts{end+1} = setglmconts('t','V1>V2', [ 1 -1  0],'pVal',1,'WhichDesign',DNO);
    GRP.freqtest1.glmconts{end+1} = setglmconts('t','V2>V1', [-1  1  0],'pVal',1,'WhichDesign',DNO);
  end;
end;

ANAP.essite     = '????? Define stimulation site';
ANAP.comments   = '????? Add comments';
