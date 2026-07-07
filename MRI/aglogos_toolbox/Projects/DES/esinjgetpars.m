function [ANAP, ROI, GRPP] = esinjgetpars(SesName)
%ESINJGETPARS - Defines the common parameters for injection/microstimulation experiments
% [ANAP, ROI, GRPP] = esinjgetpars
%
% NOTES:
% This function is substantially different from visesmixgetpars, esgetpars etc. The idea here
% is to have a module through which we can control all sessions that can be used for
% averages. To accomodate for differences between sessions the function is called with an
% argument that indicateds the session from within which esinjgetpars was invoked.
%
% WARNING:
% Do NOT change anything here!! You will effect many different functions and the display
% of the results used for the paper won't be reproducible!
%
% The following functions/scripts should be checked if changes are necessary:
% 1. INJMKMODEL - makes the models by using the average responses of all good sessions
% 2. SHOWINJROITS - creates averages or displays the results of individual or all functions
% 3. ES_DACAPO - Repeats the analysis (check flags!! within that function)
% 4. ES_DOC - has all the documentation of our anlaysis
% 5. ES_LIST to see the status of the used sessions
%
% See also INJMKMODEL SHOWINJROITS ES_DACAPO ES_DOC ES_LIST
%
% NKL 17.03.2007
% =========================================================================================

BSTRP_DEBUG = 0;    % SET TO BSTRP NUMBER... when done!


% ----------------------------------------------------------------------------------------
% GLOBAL DEFINITIONS FOR ALL SESSIONS, E.G. DIRECTORIES, MODELS, ETC.
% ----------------------------------------------------------------------------------------
ANAP.ClusterMode = 0;          % When using the office-cluster
DIRS = getdirs;  % Our directory structure
switch lower(DIRS.HOSTNAME)
 case {'nb-nikos' 'nb-nikos-travel' 'workbook-nikos' 'ultrabook-nikos'}
  ANAP.ClusterMode = 0;
 case {'win447' 'node4' 'node5' 'node6'}
  ANAP.ClusterMode = 1;
end

if ANAP.ClusterMode,
  DRV = '\\nkldata\YDISK';                  % All data are on the cluster disk
% elseif exist('y:/','dir'),
%   DRV = 'Y:/';
elseif strcmpi(DIRS.HOSTNAME,'ultrabook-nikos') | strcmpi(DIRS.HOSTNAME,'nb-nikos'),
  DRV = 'D:/BrainMaps/';
else
  DRV = 'D:/';
end;

ANAP.project.GlobalDir      = fullfile(DRV,'Global/Ripples');
ANAP.project.imagefile      = fullfile(DRV,'Global/Anatomy/rathead16T.img');
ANAP.project.atlasfile      = fullfile(DRV,'GlobalAnatomy/rathead16T_AtlasROIs.mat');
ANAP.project.elesite        = fullfile(DRV,'Projects/Anatomy/RatEleSites');
ANAP.project.flicker_dir    = fullfile(DRV,'Global/Flicker');
ANAP.project.estim_dir      = fullfile(DRV,'Global/DES');
ANAP.project.datadir        = fullfile(DRV,'BrainMaps/DataMatlab/');
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




% =========================================================================================
% SESSIONS USED FOR THE ESFMRI PAPER (2 monkeys, 7 good sessions)
% =========================================================================================
% The following sessions were not used (NKL 30.07.09)
%   SES{end+1} = 'b06n51';      % Completed   Bad session/not usable
%   SES{end+1} = 'b06kl1';      % Completed   Bad session/not usable
%   SES{end+1} = 'd04m11';      % Completed   Bad session/not usable
%   SES{end+1} = 'd04k41';      % Completed   Only polarinj but no effects of injection?
%   SES{end+1} = 'h05n21';      % Completed   Only 361 volumes (instead of 592)
% =========================================================================================
% 'b06lv1' 'b06lp1' 'h05km1' 'h05l21' 'h05ni1' 'h05n21', 'h05lr1' 'h05np1'
% 'd04m11', 'b06l11'
ANAP.SES = {};
ANAP.SES{end+1} = 'b06lv1';  % OUTSTANDING -- Excellent Demo for INJc, INJp, IPZ, etc.
ANAP.SES{end+1} = 'b06lp1';  % EXCELLENT
ANAP.SES{end+1} = 'h05km1';  % VERY GOOD
ANAP.SES{end+1} = 'h05l21';  % VERY GOOD
ANAP.SES{end+1} = 'h05ni1';  % EXCELLENT
ANAP.SES{end+1} = 'h05lr1';  % VERY GOOD
ANAP.SES{end+1} = 'h05np1';  % OUTSTANDING -- Demo! EleTip in IPZ!
ANAP.SES{end+1} = 'b06l11';  % GOOD but INJ cannot be defined in the proper location
% ANAP.SES{end+1} = 'h05n21';  % SHORTER OBSP
%ANAP.SES{end+1} = 'd04m11';  % GOOD but INJ cannot be defined in the proper location

if ~exist('SesName','var'),
  fprintf('OLD DESCRIPTION FILE; edit and add argument to the esinjgetpars function\n');
  keyboard;
end;

% =========================================================================================
% ROI for MRI experiments
% =========================================================================================
ROI.groups	= {'all'};                            
%%  ROI.names	= {'brain';'V1';'V2';'inj';'ipz';'mt'};      
% v1- and v2- are V1-INJ and V2-IPZ!!
ROI.names	= {'LGN';'SC';'Pul';'V1';'V2';'XC';'MT';'Brain';'inj';'v1-';'v2-';'ipz'};
ROI.model	= 'inj';                              

% more ROIs
tmproi      = {'Brain','LEFT','RIGHT','inj','ipz','v1-','v2-'};
ROI.groups  = {'All'};                      % SuperAvg (see HROI)
ROI.model   = 'inj';                       % Group to use as model
ROI.names   = {};
ROI.names   = paxroigroups('ROI','monkey');  
ROI.names   = cat(2,tmproi, ROI.names);



% TO BE FILLED UP IN INDIVIDUAL DESCRIPTION FILES
ANAP.essite         = 'LGN';
ANAP.comments       = 'GABA Inj, Comments: ';

ANAP.mroi.gamma     = 1.6;
ANAP.mroi.colors    = 'wcyrgbmwcyrgbm';         % Colors for drawing activations on MROI anatomy/rois
ANAP.mroi.mapcolors = 'kgkrbwcymrbgcwk';        % Colors for drawing activations on MROI anatomy/rois

% GRPP.anap.inj.PRE_TRIALS    = [1:8];        % Pre-Injection Trials
% GRPP.anap.inj.POST_TRIALS   = [27:37];      % Post-Injection Trials
TWO_ENDS = 0;
if TWO_ENDS,
  GRPP.anap.inj.PRE_TRIALS    = [1:8];        % Pre-Injection Trials
  GRPP.anap.inj.TRANS_TRIALS  = [15:22];      % Transition zone
  GRPP.anap.inj.POST_TRIALS   = [29:37];      % Post-Injection Trials
else
  GRPP.anap.inj.PRE_TRIALS    = [1:13];        % Pre-Injection Trials
  GRPP.anap.inj.TRANS_TRIALS  = [14:23];        % Pre-Injection Trials
  GRPP.anap.inj.POST_TRIALS   = [24:37];      % Post-Injection Trials
  GRPP.anap.inj.POST_TRIALS   = [13:35];      % Post-Injection Trials
end;

GRPP.anap.inj.PRE_VOL       = 128;          % Pre-Injection Volumes
GRPP.anap.inj.PRE_TIME      = 500;          % Pre-Injection Time in Seconds
GRPP.anap.inj.POST_VOL      = 464;          % Post-Injection Volumes
GRPP.anap.inj.POST_TIME     = 2240;         % Post-Injection Time in Seconds
GRPP.anap.inj.TRIAL_DUR     = 16;           % Trial Duration in VOLUMES
GRPP.anap.inj.STMFR         = 0.0156;       % Stimulus frequency in Hz
GRPP.anap.inj.DX            = 4;            % Volume TR
GRPP.anap.inj.OBSP_VOL      = 592;
GRPP.anap.inj.OBSP_Time     = 592*GRPP.anap.inj.DX;

% Definitions regarding sorting by trial
GRPP.anap.gettrial.status       = 0;
GRPP.anap.gettrial.trial2obsp   = 1;
GRPP.anap.gettrial.Xmethod      = 'percent';  % tosdu-prestim doesn't show anything,
GRPP.anap.gettrial.Xepoch       = 'blank';  % Argument (Epoch) to xfrom in gettrial
GRPP.anap.gettrial.sort         = 'trial';  % sorting with SIGSORT, can be 'none|stimulus|trial
GRPP.anap.gettrial.RefChan      = 2;        % Reference channel (for DIFF)
GRPP.anap.gettrial.Average      = 1;        % Concat/Average; It is also used from trial2obsp

% =========================================================================================
% Definitions related to correlation or GLM analysis
% =========================================================================================
ANAP.aval               = 0.50;         % p-value for selecting time series
ANAP.rval               = 0.05;         % r (Pearson) coeff. for selecting time series
ANAP.shift              = 1;            % nlags for xcor in seconds
ANAP.clustering         = 1;            % apply clustering after voxel-selection
ANAP.bonferroni         = 0;            % Correction for multiple comparisons

DO_BY_TRIAL = 0;
if DO_BY_TRIAL,
  GRPP.grpsigs    = {'troiTs'};         % Overwrites GrpPhySigs and GrpImgSigs on a GROUP-basis!!!
else
  GRPP.grpsigs    = {'roiTs'};         % Overwrites GrpPhySigs and GrpImgSigs on a GROUP-basis!!!
end

% =========================================================================================
% MVIEW - INTERACTIVE DATA VISUALIZATION
% =========================================================================================
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
ANAP.mview.mcluster3.B          = 3;
ANAP.mview.mcluster3.cutoff     =  round((2*(ANAP.mview.mcluster3.B-1)+1)^3*0.3);
ANAP.mview.bwlabeln.conn        = 26;	% must be 6(surface), 18(edges) or 26(corners)
ANAP.mview.bwlabeln.minvoxels   = ANAP.mview.bwlabeln.conn * 0.8;
ANAP.mview.slices               = [];
ANAP.mview.glmana.minmax        = [0 120];
ANAP.mview.glmana.model         = 1;
ANAP.mview.clusterfunc          = 'bwlabeln';

% The field "voxselect" is used by the function SHOWMAP/MASKCOMBINE for selecting positive
% or negative ES-induced responses from within a visual map (mask) that is only positive or
% only negative.roiTs. Extraction of time series from ROIs (in the Roi.mat)
GRPP.anap.voxselect.dx          = 1;            % Sampling time before averaging
GRPP.anap.voxselect.roinames    = {'V1','V2'};
GRPP.anap.voxselect.masks       = {'esinj', {'fVal','fVal'},    [0.100 0.100]};
GRPP.anap.voxselect.models      = {'esinj', {'INJ', 'IPZ' },    [0.000000001 0.000000001] };

% =========================================================================================
% SIGNAL CONDITIONING AND PREPROCESSING
% =========================================================================================
DEBUG = 0;
if DEBUG,
  GRPP.anap.mareats.IEXCLUDE       = {'V1';'V2';'inj';'ipz';'mt'};      
else
  GRPP.anap.mareats.IEXCLUDE       = {'Brain'};
end;

GRPP.anap.mareats.ICONCAT        = 1;     % 1= concatanate ROIs before creating roiTs
GRPP.anap.mareats.IFFTFLT        = 0;     % Respiratory artifact removal I
GRPP.anap.mareats.IARTHURFLT     = 0;     % IT ONLY MAKES SENSE for TR <= 500
GRPP.anap.mareats.IGAMMA         = 0;     % NO need for gamma-correction in these sessions
GRPP.anap.mareats.IDETREND       = 1;
GRPP.anap.mareats.ITOSDU         = {'percent','blank'};
GRPP.anap.mareats.IHEMODELAY     = 4;     % For computing baseline in XFORM
GRPP.anap.mareats.IHEMOTAIL      = 4;     % Same.. but only for non-prestim cases
GRPP.anap.mareats.IMIMGPRO       = 1;     % Do image processsing
GRPP.anap.mareats.IFILTER        = 4;     % 1=to spatially filter; 0=no filter at all
GRPP.anap.mareats.ISUBSTITUDE    = 0;     % DO not use this if you have dummy scans
GRPP.anap.mareats.IPCA           = 0;    % Reconstruct all TS from the first 8 components

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
elseif  GRPP.anap.mareats.IFILTER  == 4,
  GRPP.anap.mareats.IFILTER_KSIZE  = 5.0;   % Kernel size
  GRPP.anap.mareats.IFILTER_SD     = 2.0;
  GRPP.anap.mareats.ICUTOFF        = 0.033;
  GRPP.anap.mareats.ICUTOFFHIGH    = 0;
end;

% =========================================================================================
% ICA (INDEPENDENT COMPONENT ANALYSIS)
% =========================================================================================
GRPP.anap.ica.evar_keep         = 10;               % Numbers of PCs to keep
GRPP.anap.ica.roinames          = {'V1','V2'};      % Analyzie only TS in these ROIs
GRPP.anap.ica.dim               = 'spatial';        % Temporal does not really work...
GRPP.anap.ica.type              = 'bell';           % The Tony Bell algorithm
GRPP.anap.ica.normalize         = 'none';           % No normalization (e.g. to SD etc.)
GRPP.anap.ica.period            = 'all';            % Blank, stim, all...
GRPP.anap.ica.icomp             = [1:10];           % Show this components only
GRPP.anap.ica.slices            = [];               % Slices to show
GRPP.anap.ica.SIGNAME           = 'roiTs';          % Signals to analyzie (e.g. roiTs, blp, troiTs)

% ANAP.showmap.COL_LINE     = 'rcbm';
% C={[1 0 0],[0 1 0],[0 0 1],[0 0 0],[0 .7 .7],[.7 0 .7],[0 0 .4],[.4 .4 0],[.3 .3 .3],[1 .6 .3]};
C={[1 0 0],[0 1 1],[0 0 1],[1 0 1],[0 .7 .7],[.7 0 .7],[0 0 .4],[.4 .4 0],[.3 .3 .3],[1 .6 .3]};
GRPP.anap.ica.COLORS = cat(2,C,C,C);   

% TO USE SOME ICs or THEIR MEAN AS MODELS DEFINE THE FOLLOWING FIELDS:
GRPP.anap.ica.mdlname           = {};               % e.g. {'V1','V2','MT','XC'};
GRPP.anap.ica.ic2mdl            = [];               % e.g. {[1 7],[2]};
GRPP.anap.ica.DISP_THRESHOLD    = 3.3;              % For SHOWICA only (ca. 2 SDs)

% USE THE FOLLOWING MODELS (CREATED WITH ESMODELS) TO SELECT ICs
% Variables evaluated by GETICA, SHOWICARES and SHOWICA
GRPP.anap.ica.ClnSpc.evar_keep  = 20;
GRPP.anap.ica.ClnSpc.dim        = 'spatial';
GRPP.anap.ica.ClnSpc.type       = 'bell';
GRPP.anap.ica.ClnSpc.normalize  = 'none';

% The following defitions refer to the selection of ICs on the basis of their similarity to
% standard models, e.g. AvgResp.dat containing the average of all sessions for visesmix
% experiments. Different vectors represent responses in different areas, e.g. model.dat(:,1)
% is usually the V1 response, model.dat(:,2) the V2 response, and so on.
% The pVal and rVal fields are used by ICASELECT(SesName, GrpName).
% To run this function, you must (a) run GETICA, (b) esmodels(Ses,Grp,'avgresp') or any
% other model, and then [idx, r] = icaselect(Ses,Grp).
% To see the selected IC run ICASELECT without output arguments
GRPP.anap.ica.mdlidx            = [];           % Use the first 2 models for selecting ICs
GRPP.anap.ica.pVal              = 0.001;        % pVal for corr(mixica,IComponent)
GRPP.anap.ica.rVal              = 0.3;          % rVal-thr for corr(mixica,IComponent)

% =========================================================================================
% HELP FOR SELECTING ROIs
% =========================================================================================
GRP.visesmix.anap.mroiesstat.mask      = {'fVal','fVal','fVal','fVal'};
GRP.visesmix.anap.mroiesstat.models    = {'pvs','nvs','pes','nes'};
GRP.visesmix.anap.mroiesstat.mskpval   = 0.10;
GRP.visesmix.anap.mroiesstat.mdlpval   = 1e-9;
GRP.visesmix.anap.mroiesstat.roinames  = {'Brain'};

% =========================================================================================
% CORRELATION AND GLM (GENERAL LINEAR MODEL) ANALYSIS
% =========================================================================================
GRPP.groupcor           = 'before cor';
GRPP.corana{1}.mdlsct   = 'boxcar';           % Model for correlation analysis (see expgetstm)

% Control flags for GLM analysis
GRPP.groupglm                = 'before glm';
GRPP.anap.glm.IARESTIMATION  = 0;            % AR estimation
GRPP.anap.glm.ISATTERWAITH   = 0;            % Satterwaith
GRPP.anap.glm.ICONVWITHGAMMA = 0;

ANAP.showmap.MSKP          = 0.1;
ANAP.showmap.STDERROR      = 0;             % If set uses errorbar otherwise CI
ANAP.showmap.CIVAL         = [1 99];        % low and high confidence interval
ANAP.showmap.BSTRP         = BSTRP_DEBUG;
ANAP.showmap.TRIAL         = [];
ANAP.showmap.FUNCSCALE     = [0 10 1.5];
ANAP.showmap.ANASCALE      = [0 10000 1.2];
ANAP.showmap.DRAW_ROI      = {};
ANAP.showmap.FMTTYPE       = 'paper';       % Default is paper
ANAP.showmap.COL_FACE      = [];            % shading color for CI plots
ANAP.showmap.MASKNAME      = {'fMdl', 'fMdl', 'fMdl', 'fMdl', 'fMdl'};

GRPP.glmana = {};
GRPP.glmconts = {};

if DEBUG,
  DNO = 1;
  GRPP.glmana{DNO}.mdlsct = {'Mdl_esinj.mat[1]'};
  NoReg = length(GRPP.glmana{DNO}.mdlsct);
  GRPP.glmconts{end+1} = setglmconts('f','fVal', NoReg+1,'pVal', 0.1, 'WhichDesign',DNO);
  GRPP.glmconts{end+1} = setglmconts('t','PBR',  [ 1  0],'pVal', 1, 'WhichDesign',DNO);
  GRPP.glmconts{end+1} = setglmconts('t','NBR',  [-1  0],'pVal', 1, 'WhichDesign',DNO);
else
  % Mdl_esinj.mat[1] = pre-trial average of V1-V2 responses (like the fhemo/boxcar but from data)
  % Mdl_esinj.mat[2] = end-of-post-trial average of V1-V2 responses
  % Mdl_esinj.mat[3] = low-pass filtered INJ response
  % Mdl_esinj.mat[4] = low-pass filtered IPZ response
  % Mdl_esinj.mat[5] = low-pass filtered V1 response
  % Mdl_esinj.mat[6] = low-pass filtered V2 response
  DNO = 1;
  GRPP.glmana{DNO}.sfilter = [];        % It's already filtered with [5 2] in mareats
  GRPP.glmana{DNO}.tfilter = [];        % It's already filtered with [0 0.025] in mareats
  
  % MODELS: INJ V1/V2 IPZ PRE POST
  GRPP.glmana{DNO}.mdlsct = {'Mdl_esinj.mat[1]','Mdl_esinj.mat[2]',...
                      'Mdl_esinj.mat[3]','Mdl_esinj.mat[4]','Mdl_esinj.mat[5]'};
  NoReg = length(GRPP.glmana{DNO}.mdlsct);
  GRPP.glmconts{end+1} = setglmconts('f','fMdl', NoReg+1,'pVal',  0.1, 'WhichDesign',DNO);
  GRPP.glmconts{end+1} = setglmconts('t','INJ',  [ 4 -1 -1 -1 -1  0]/4, 'pVal', 1, 'WhichDesign',DNO);
  GRPP.glmconts{end+1} = setglmconts('t','V1',   [ 0  1  0  0  0  0], 'pVal', 1, 'WhichDesign',DNO);
  GRPP.glmconts{end+1} = setglmconts('t','V2',   [ 0 -1  0  0  0  0], 'pVal', 1, 'WhichDesign',DNO);
  GRPP.glmconts{end+1} = setglmconts('t','IPZ',  [ 0  0  2 -1  1  0]/2, 'pVal', 1, 'WhichDesign',DNO);
  GRPP.glmconts{end+1} = setglmconts('t','pre-inj',[ 1 0 0 1 0 0], 'pVal', 1, 'WhichDesign',DNO);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Excellent session capitalized
% 'B06LV1' 'B06LP1' 'H05KM1' 'h05l21' 'H05NI1' 'h05lr1' 'H05NP1' 'b06l11'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ANAP.showmap.MODELNAME  = {'INJc','V1', 'V2', 'IPZ'}; - old regressors

ANAP.showmap.MSKP         = [.1 .1 .1 .1];
ANAP.showmap.MASKNAME     = {'fMdl', 'fMdl', 'fMdl', 'fMdl'};
ANAP.showmap.MODELNAME    = {'INJ','V1', 'V2', 'IPZ'};
ANAP.showmap.COL_LINE     = 'rcbm';
ANAP.showmap.CMAP         = {'r','c','b','m'};

% OLD SELIDX      = [1 1 1 1 1 0 1 0];

ESFMRI = 1;
switch(SesName),
 case 'b06lv1', % **** (1) SHOWINJROITS ****  Completed! % OUTSTANDING -- Excellent Demo for INJ, INJp, IPZ, etc.
  ANAP.showmap.ROINAME      = {{'INJ'}, {'V1'}, {'V2'}, {'IPZ'}};
  ANAP.showmap.MDLP         = [1e-15  1e-35 1e-5 1e-35];
  ANAP.mview.slices         = [2 3 4 5 6];
 case 'b06lp1', % **** (2) SHOWINJROITS ****  Completed! % EXCELLENT -- Good figure
  ANAP.showmap.ROINAME      = {{'INJ'}, {'V1'}, {'V2'}, {'IPZ'}};
  ANAP.showmap.MODELNAME    = {'pre-inj','V1', 'V2', 'IPZ'};
  ANAP.showmap.MDLP         = [1e-1  1e-10 1e-8 1e-3];
  ANAP.mview.slices         = [5 6 7 8 9];
 case 'h05km1', % **** (3) SHOWINJROITS ****  Completed! % VERY GOOD -- Good figure
  ANAP.showmap.ROINAME      = {{'INJ'}, {'V1'}, {'V2'}, {'IPZ'}};
  ANAP.showmap.MDLP         = [1e-5  1e-5 1e-6 1e-2];
  ANAP.mview.slices         = [1:5];
 case 'h05l21', % **** (4) SHOWINJROITS ****  Completed! % VERY GOOD -- Bad poor INJc
  ANAP.mview.slices         = [2:6];
  ANAP.showmap.ROINAME      = {{'INJ'}, {'V1'}, {'V2'}, {'IPZ'}};
  ANAP.showmap.MDLP         = [1e-8  1e-30 1e-30 1e-5];
 case 'h05ni1', % **** (5) SHOWINJROITS ****  Completed! EXCELLENT
  ANAP.mview.slices         = [6:10];
  ANAP.showmap.ROINAME      = {{'INJ'}, {'V1'}, {'V2'}, {'IPZ'}};
  ANAP.showmap.MODELNAME    = {'pre-inj','V1', 'V2', 'IPZ'};
  ANAP.showmap.MDLP         = [1e-5  1e-15 1e-10 1e-10];
 case 'h05lr1', % **** (7) SHOWINJROITS ****  Completed! % VERY GOOD -- INJ gives good response w/out model-no reversal
  ANAP.mview.slices         = [1:5];
  ANAP.showmap.ROINAME      = {{'INJ'}, {'V1'}, {'V2'}, {'IPZ'}};
  ANAP.showmap.MODELNAME    = {'pre-inj','V1', 'V2', 'IPZ'};
  ANAP.showmap.MDLP         = [1e-5  1e-25 1e-15 1e-10];
 
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % GOOD V2 PHYSIOLOGY!!!!!!!!!!!!!!
 case 'h05np1', % **** (8) SHOWINJROITS ****  Completed!
  ANAP.mview.slices         = [6:10];
  ANAP.showmap.ROINAME      = {{'INJ'}, {'V1'}, {'All'}, {'IPZ'}};
  ANAP.showmap.MASKNAME     = {'fMdl', 'fMdl', 'fMdl', 'fMdl'};
  ANAP.showmap.MODELNAME    = {'pre-inj','V1', 'V2', 'IPZ'};
  ANAP.showmap.MDLP         = [1e-25  1e-35 1e-10 1e-6];
  GRPP.anap.inj.POST_TRIALS = [22:37];                          % Post-Injection Trials
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
 case 'b06l11', % **** (10) SHOWINJROITS ****  Completed! % NOT VERY GOOD
  ANAP.mview.slices         = [2:6];
  ANAP.showmap.ROINAME      = {{'INJ'}, {'V1'}, {'V2'}, {'IPZ'}};
  ANAP.showmap.MDLP         = [1e-15  1e-35 1e-8 1e-2];

%  case 'h05n21', % **** (6) SHOWINJROITS ****  Completed! 361 points instead of 592 (can't be used)
%   ANAP.showmap.ROINAME      = {{'All'}, {'All'}, {'All'}, {'V2'}};
%   ANAP.showmap.MDLP         = [1e-20  1e-40 1e-10 1e-80];
%
%   DESIGN = 'fVal';
%   if ~strcmp(DESIGN,'fneu'),
%     % VERY GOOD -- IPZ is exactly at the electrode position!!
%     ANAP.showmap.ROINAME      = {{'All'}, {'All'}, {'All'}, {'All'}, {'INJ'}};
%     ANAP.showmap.MODELNAME    = {'INJc',   'IPZ',   'V1',    'V2',    'INJp'};
%     ANAP.showmap.MSKP         = [.1 .1 .1 .1 .1];
%     ANAP.showmap.MDLP         = [1e-28 1e-10  1e-10  1e-10 0.4];    
%   else
%     ANAP.showmap.ROINAME      = {{'All'}, {'All'}, {'All'}, {'All'}};
%     ANAP.showmap.MODELNAME    = { 'neuINJ', 'neuIPZ'  'neuV1', 'neuV2'};
%     ANAP.showmap.MSKP         = [.1 .1 .1 .1 .1];
%     ANAP.showmap.MDLP         = [1e-14 1e-12  1e-10  1e-10  1e-04];    
%     DNO = 3;
%     GRPP.glmana{DNO}.mdlsct = {'Mdl_esinj.mat[1]','Mdl_esinj.mat[2]','MdlCln_esinj.mat[1]'};
%     GRPP.glmana{DNO}.tfilter = [0 0.02];
%     NoReg = length(GRPP.glmana{DNO}.mdlsct);
%     GRPP.glmconts{end+1} = setglmconts('f','fNeu', NoReg+1,'pVal',  0.1, 'WhichDesign',DNO);
%     GRPP.glmconts{end+1} = setglmconts('t','neuINJ', [ 1 -1  0  0],'pVal', 1, 'WhichDesign',DNO);
%     GRPP.glmconts{end+1} = setglmconts('t','neuIPZ', [-1  1  1  0],'pVal', 1, 'WhichDesign',DNO);
%     GRPP.glmconts{end+1} = setglmconts('t','neuV1',  [ 1  0  0  0],'pVal', 1, 'WhichDesign',DNO);
%     GRPP.glmconts{end+1} = setglmconts('t','neuV2',  [-1  0  0  0],'pVal', 1, 'WhichDesign',DNO);
%   end;
 
 case 'd04m11', % **** (9) SHOWINJROITS ****  Completed! % NOT GOOD
  ANAP.showmap.ROINAME      = {{'All'}, {'V1'}, {'All'}, {'V2'}};
  ANAP.showmap.MDLP         = [1e-2  1e-5 1e-1 1e-2];
 otherwise,
  % fprintf('Unknown session in ESINJGETPARS\n');
end;



%%%%%%%%%%%%%%%%%%%%5 OLD CODE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   DNO = 1;
%   GRPP.glmana{DNO}.mdlsct = {'Mdl_esinj.mat[1]','Mdl_esinj.mat[2]','Mdl_esinj.mat[3]',...
%                       'Mdl_esinj.mat[4]','Mdl_esinj.mat[5]','Mdl_esinj.mat[6]'};
%   GRPP.glmana{DNO}.tfilter = [0 0.018];
%   NoReg = length(GRPP.glmana{DNO}.mdlsct);
%   GRPP.glmconts{end+1} = setglmconts('f','fMdl', NoReg+1,'pVal',  0.1, 'WhichDesign',DNO);
%   GRPP.glmconts{end+1} = setglmconts('t','INJc', [ 1 -1  0  0  0  0  0],'pVal', 1, 'WhichDesign',DNO);
%   GRPP.glmconts{end+1} = setglmconts('t','INJp', [ 0  0  1  0 -1 -1  0],'pVal', 1, 'WhichDesign',DNO);
%   GRPP.glmconts{end+1} = setglmconts('t','IPZ',  [-1  1  0  0  0  0  0],'pVal', 1, 'WhichDesign',DNO);
%   GRPP.glmconts{end+1} = setglmconts('t','V1',   [ 1  1 -1 -1  0  0  0],'pVal', 1, 'WhichDesign',DNO);
%   GRPP.glmconts{end+1} = setglmconts('t','V2',   [-1 -1  0  0  0  0  0],'pVal', 1, 'WhichDesign',DNO);
%   GRPP.glmconts{end+1} = setglmconts('t','V1F',  [ 1  1  0  0  0  0  0],'pVal', 1, 'WhichDesign',DNO);
  
%   DNO = 2;
%   GRPP.glmana{DNO}.mdlsct = {'Mdl_esinj.mat[1]','Mdl_esinj.mat[2]','Mdl_esinj.mat[3]','Mdl_esinj.mat[4]'};
%   GRPP.glmana{DNO}.tfilter = [0 0.018];
%   NoReg = length(GRPP.glmana{DNO}.mdlsct);
%   GRPP.glmconts{end+1} = setglmconts('f','fVis', NoReg+1,'pVal',  0.1, 'WhichDesign',DNO);
%   GRPP.glmconts{end+1} = setglmconts('t','vINJ',  [ 1 -1  1 -1  0],'pVal', 1, 'WhichDesign',DNO);
%   GRPP.glmconts{end+1} = setglmconts('t','vIPZ',  [ 1  1 -1  1  0],'pVal', 1, 'WhichDesign',DNO);
%   GRPP.glmconts{end+1} = setglmconts('t','vV1',   [ 1  1  1  0  0],'pVal', 1, 'WhichDesign',DNO);
%   GRPP.glmconts{end+1} = setglmconts('t','vV2',   [ 1  1  0  0  0],'pVal', 1, 'WhichDesign',DNO);

%   DNO = 2;
%   GRPP.glmana{DNO}.mdlsct = {'Mdl_inj.mat[1]','Mdl_inj.mat[2]','Mdl_inj.mat[3]',...
%                       'Mdl_inj.mat[4]','Mdl_inj.mat[5]'};
%   GRPP.glmana{DNO}.tfilter = [0 0.018];
%   NoReg = length(GRPP.glmana{DNO}.mdlsct);
%   GRPP.glmconts{end+1} = setglmconts('f','fInj', NoReg+1,'pVal',  0.1, 'WhichDesign',DNO);
%   GRPP.glmconts{end+1} = setglmconts('t','iINJc', [ 4 -1 -1 -1 -1  0]/4,'pVal', 1, 'WhichDesign',DNO);
%   GRPP.glmconts{end+1} = setglmconts('t','iIPZ',  [-1  4 -1 -1 -1  0]/4,'pVal', 1, 'WhichDesign',DNO);
%   GRPP.glmconts{end+1} = setglmconts('t','iV1',   [ 1 -1  4 -1 -1  0]/4,'pVal', 1, 'WhichDesign',DNO);
%   GRPP.glmconts{end+1} = setglmconts('t','iV2',   [-1 -1 -1  4 -1  0]/4,'pVal', 1, 'WhichDesign',DNO);
%   GRPP.glmconts{end+1} = setglmconts('t','iINJp', [-1 -1 -1 -1  4  0]/4,'pVal', 1, 'WhichDesign',DNO);



