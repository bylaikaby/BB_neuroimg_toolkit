function [CTG, ANAP, ROI, GRPP] = esalertgetpars
%ESALERTGETPARS - Get common parameters for all injection/microstimulation experiments
% [ANAP, ROI, GRPP] = esalertgetpars
%
% NKL 17.03.2007
% =========================================================================================

%=========================================================================================
% CATEGORIES (CTG) OF  EXPS/GROUPS/SIGS, if exist or needed
%=========================================================================================
CTG.GrpPhySigs  = {};                       % Group these physiology signals
CTG.TrialSigs   = {'roiTs'};                % Signals to be sorted by trial (sesgettrial)

%=========================================================================================
% ROI for MRI experiments, if exist or needed, then put here
%=========================================================================================
ROI.groups	= {'all'};                          % SuperAvg (see HROI)
ROI.names	= {'brain';'LGN';'V1';'V2';'XC';'MT';'lgnV1';'lgnV2'};
ROI.model	= 'brain';                          % Group to use as model

ANAP.AlertMonkeyExp     =  1;   % For SESCATEXPS....

ANAP.imgload.INORMALIZE = 1;
ANAP.imgload.IDETREND   = 0;

% Extraction of time series from ROIs (in the Roi.mat)
ANAP.mareats.IEXCLUDE       = {'brain'};    % Exclude in MAREATS
ANAP.mareats.ICONCAT        = 1;            % 1= concatanate ROIs before creating roiTs
ANAP.mareats.IFFTFLT        = 0;            % Respiratory artifact removal I
ANAP.mareats.IARTHURFLT     = 0;            % IT ONLY MAKES SENSE for TR <= 500
ANAP.mareats.IGAMMA         = 0;            % NO need for gamma-correction in these sessions
ANAP.mareats.IDETREND       = 1;
ANAP.mareats.ITOSDU         = {'tosdu','prestim'};
ANAP.mareats.IHEMODELAY     = 2;
ANAP.mareats.IHEMOTAIL      = 2;
ANAP.mareats.ISUBSTITUDE    = 0;        % DO not use this if you have dummy scans
ANAP.mareats.USE_REALIGNED  = 1;

ANAP.mareats.IMIMGPRO       = 1;        % Do image processsing
ANAP.mareats.IFILTER        = 1;		% 1=to spatially filter; 0=no filter at all
ANAP.mareats.IFILTER_KSIZE  = 5;		% Kernel size
ANAP.mareats.IFILTER_SD     = 2.5;      % SD (if half about 90% of flt in kernel)
ANAP.mareats.ICUTOFF        = 0.15;
ANAP.mareats.ICUTOFFHIGH    = 0;
ANAP.mareats.IPCA           = 4;

% Definitions related to correlation or GLM analysis
ANAP.aval               = 0.50;         % p-value for selecting time series
ANAP.rval               = 0.05;         % r (Pearson) coeff. for selecting time series
ANAP.shift              = 1;            % nlags for xcor in seconds
ANAP.clustering         = 1;            % apply clustering after voxel-selection
ANAP.bonferroni         = 0;            % Correction for multiple comparisons

ANAP.mview.viewmode     = 'lightbox-trans';
ANAP.mview.viewpage     = 1;
ANAP.mview.nrowncol_trans = [3 3];

ANAP.mview.roi          = 'all';
ANAP.mview.alpha        = 0.05;
ANAP.mview.statistics   = 'glm';
ANAP.mview.glmana.model = 1;
ANAP.mview.glmana.trial = 1;
ANAP.mview.cluster      = 0;
ANAP.mview.negcorr      = 0;

ANAP.mview.mcluster3.B  = 3;
ANAP.mview.mcluster3.cutoff     = round((2*(ANAP.mview.mcluster3.B-1)+1)^3*0.3);
ANAP.mview.bwlabeln.conn        = 26;	% must be 6(surface), 18(edges) or 26(corners)
ANAP.mview.bwlabeln.minvoxels   = ANAP.mview.bwlabeln.conn * 0.4;

DO_BY_TRIAL = 1;

if DO_BY_TRIAL,
GRPP.grpsigs    = {'troiTs'};         % Overwrites GrpPhySigs and GrpImgSigs on a GROUP-basis!!!
else
GRPP.grpsigs    = {'roiTs'};         % Overwrites GrpPhySigs and GrpImgSigs on a GROUP-basis!!!
end

GRPP.anap.HemoDelay     = 0;  % 2->worse
GRPP.anap.HemoTail      = 2;  % 6->worse

% Definitions regarding sorting by trial
GRPP.anap.gettrial.status       = DO_BY_TRIAL;        % IsTrial
GRPP.anap.gettrial.Xmethod      = 'percent';
GRPP.anap.gettrial.Xepoch       = 'prestim';% Argument (Epoch) to xfrom in gettrial
GRPP.anap.gettrial.Average      = 1;        % Do not average tblp, but concat
GRPP.anap.gettrial.RefChan      = 2;        % Reference channel (for DIFF)
GRPP.anap.gettrial.sort         = 'trial';  % sorting with SIGSORT, can be 'none|stimulus|trial
GRPP.anap.gettrial.trial2obsp   = 0;
GRPP.anap.gettrial.HemoDelay    = GRPP.anap.HemoDelay;
GRPP.anap.gettrial.HemoTail     = GRPP.anap.HemoTail;
GRPP.anap.gettrial.PreT         = 6;
GRPP.anap.gettrial.PostT        = 6+10;

%GRPP.anap.gettrial.CheckJawPo   = 1;
GRPP.anap.gettrial.CheckCentroid   = 0;

% Control flags for GLM analysis
GRPP.groupglm                = 'before glm';
GRPP.anap.glm.IARESTIMATION  = 0;            % AR estimation
GRPP.anap.glm.ISATTERWAITH   = 0;            % Satterwaith
GRPP.anap.glm.ICONVWITHGAMMA = 0;

% Number of GLM regressors + constant function
% NOTE THAT GLM performs one-tailed t-test for t-contrast.
GRPP.glmana{1}.mdlsct = {'fhemo','hemo'};
NoReg = length(GRPP.glmana{1}.mdlsct) + 1;
GRPP.glmconts{01} = setglmconts('f','fVal',NoReg,'pVal',0.1);
GRPP.glmconts{02} = setglmconts('t','pes',   [ 1  1  0],'pVal',1);
GRPP.glmconts{03} = setglmconts('t','nes',   [-1 -1  0],'pVal',1);

ANAP.showmap.STDERROR      = 0;        % If set uses errorbar otherwise CI
ANAP.showmap.CIVAL         = [1 99];   % low and high confidence interval
ANAP.showmap.BSTRP         = 100;
ANAP.showmap.TRIAL         = [];
ANAP.showmap.FUNCSCALE     = [0 10 1.5];
ANAP.showmap.ANASCALE      = [0 10000 1.2];
ANAP.showmap.DRAW_ROI      = {};

ANAP.mview.slices          = [7 8];

ANAP.showmap.ROINAME       = {{'lgnv1'},{'lgnv2'}};
ANAP.showmap.MASKNAME      = {'IC-fVal','IC-fVal'};
ANAP.showmap.MODELNAME     = {'v1','v2'};
ANAP.showmap.MSKP          = [0.1 0.1];
ANAP.showmap.MDLP          = [1e-5 1e-10];
ANAP.showmap.FMTTYPE       = 'paper';       % Default is paper
ANAP.showmap.COL_LINE      = 'rbcmgyck';
ANAP.showmap.COL_FACE      = [];            % shading color for CI plots
ANAP.showmap.CMAP          = {'r','b','c','m','g','y','c','k'};

