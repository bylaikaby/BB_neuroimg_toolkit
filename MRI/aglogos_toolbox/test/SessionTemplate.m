%SBJUID - MRI-PHYS (4.7T)  V1/V2 MRI+Neurophys (laminar ele)
% SESSION : SBJ.UID -- anest. mri-phys at 4.7T
% EXPDATE : DD.MM.YY
% GROUPS  :
% EXPERIMENTS : 
% ROIS :
%
% NOTES :
%  Laminar electrode at 25(****) of V1 chamber (Left),
%  ELE #  1  2  3  4
%  ADF #  1  2  3  4
%  Area  v2 v2 v2 v2
%  Good recoring and BOLD.
%
% RESULTS :
%
% DATE/AUTHOR
%  DD.MM.YY WHO

%=======================================================================
% basic information : data directories, session quality
%=======================================================================
SYSP.DataNeuro	= '//winXX/Data/';     % dir. for adf/adfw/dgz
SYSP.DataMri	= '//winXX/Data/';     % dir. for 2dseq
SYSP.dirname	= 'SBJ.UID';           % <--- Session Name
SYSP.date       = 'DD.MM YY';          % <--- Session Date

ANAP.Quality	= -1;	% Percent (all exps good activation)

%=======================================================================
% default analysis parameters : see also getses.m/getanap.m
% this must be overwritten in each group, if different.
%=======================================================================
% ANAP.xxxx = ...

% Definitions related to correlation or GLM analysis
ANAP.aval               = 0.05;         % p-value for selecting time series
ANAP.rval               = 0.15;         % r (Pearson) coeff. for selecting time series
ANAP.shift              = 0;            % nlags for xcor in seconds
ANAP.clustering         = 1;            % apply clustering after voxel-selection
ANAP.bonferroni         = 0;            % Correction for multiple comparisons

ANAP.ImgDistort         = 0;


ANAP.clnpar.DEBUG       = 0;
ANAP.clnpar.SAVEGRA     = 0;

ANAP.imgload.IDETREND   = 0;

% Extraction of time series from ROIs (in the Roi.mat)
ANAP.mareats.IEXCLUDE       = {};
ANAP.mareats.ICONCAT        = 1;     % 1= concatanate ROIs before creating roiTs
ANAP.mareats.IFFTFLT        = 0;     % Respiratory artifact removal I
ANAP.mareats.IARTHURFLT     = 0;     % IT ONLY MAKES SENSE for TR <= 500
ANAP.mareats.IGAMMA         = 0;     % NO need for gamma-correction in these sessions
ANAP.mareats.IDETREND       = 1;
ANAP.mareats.ITOSDU         = {'none','blank'};     % Express data in SD Units
ANAP.mareats.IHEMODELAY     = 2;     % For computing baseline in XFORM
ANAP.mareats.IHEMOTAIL      = 6;     % Same.. but only for non-prestim cases
ANAP.mareats.IMIMGPRO       = 1;     % Do image processsing
ANAP.mareats.IFILTER        = 1;	 % 1=to spatially filter; 0=no filter at all
ANAP.mareats.IFILTER_KSIZE  = 3;	 % Kernel size
ANAP.mareats.IFILTER_SD     = 1.5;   % SD (if half about 90% of flt in kernel)
ANAP.mareats.ISUBSTITUDE    = 0;     % DO not use this if you have dummy scans
ANAP.mareats.ICUTOFF        = 0.2;   % Most spontaneous activity stuff is at 0.1Hz
ANAP.mareats.ICUTOFFHIGH    = 0.017;;


%=========================================================================================
% CATEGORIES (CTG) OF  EXPS/GROUPS/SIGS, if exist or needed
%=========================================================================================
CTG.GrpPhySigs  = {};               % Group these physiology signals
CTG.TrialSigs   = {'roiTs','blp'};        % Signals to be sorted by trial (sesgettrial)


%=========================================================================================
% Defaults for MVIEW(Ses,Grp)
%=========================================================================================
ANAP.mview.viewmode     = 'lightbox-trans';
ANAP.mview.roi          = 'all';
ANAP.mview.alpha        = 0.05;

%=======================================================================
% ROI for MRI experiments, if exist or needed, then put here
% brain-ROI must be defined
% test-ROI should be defined, because if exists it's used to test
% scan-stability
% All roi should be with lower case
% model roi is the one we may use for xcor analysis
%=======================================================================
ROI.groups	= {'all'};                              % SuperAvg (see HROI)
ROI.names	= {'brain' 'ele' 'v1' 'v2' 'MT' 'ele' 'elev1' 'elev2' 'test'};	% Define desired ROIs
ROI.model	= 'ele';                                % Group to use as model


%=======================================================================
% ANATOMY scans (if exist rare/mdeft/ir/msme)
% PLEASE MAKE SURE THE ELECTRODE POSITION AND SLICE IS 100% CORRECT
%=======================================================================
ASCAN.flash{1}.info		= 'Anatomy FLASH';
ASCAN.flash{1}.scanreco	= [6 1];
ASCAN.flash{1}.imgcrop	= [50 50 60 60]*2;



%=======================================================================
% default group parameters
% this must be overwritten in each group, if different.
%=======================================================================
GRPP.daqver		= 2.00;		% DAQ program version: 2=nl+ym; 1=nl;
GRPP.imgcrop	= [50 50 60 60];	% x, y, width, height
GRPP.ana        = {'flash',1,[4:15]};
GRPP.hwinfo		= '';		% hardware info
GRPP.hardch		= [1 2 3 4];	% electrode numbers for ADF_CHANNELs
GRPP.namech     = {'V2','V2','V2','V2'};
GRPP.gradch     = 5;
GRPP.softch		= [];		% invalidated channels for analysis
GRPP.findch		= [];		% Bad Channels spotted w/ findchan(Ses,GrpName);
GRPP.grproi		= 'RoiDef';	% the name of a Group's ROI, RoiDef as default
GRPP.condition  = {'normal'};
GRPP.expinfo    = {'imaging','recording'};


% Definitions regarding sorting by trial
GRPP.anap.gettrial.status       = 1;
GRPP.anap.gettrial.trial2obsp   = 0;
GRPP.anap.gettrial.Xmethod      = 'percent';  % tosdu-prestim doesn't show anything,
GRPP.anap.gettrial.Xepoch       = 'prestim';  % Argument (Epoch) to xfrom in gettrial
GRPP.anap.gettrial.sort         = 'trial';  % sorting with SIGSORT, can be 'none|stimulus|trial
GRPP.anap.gettrial.RefChan      = 2;        % Reference channel (for DIFF)
GRPP.anap.gettrial.Average      = 1;        % Concat/Average; It is also used from trial2obsp
GRPP.anap.gettrial.blp.Xmethod = 'sdu';


GRPP.grpsigs    = {'troiTs','tblp'};         % Overwrites GrpPhySigs and GrpImgSigs on a GROUP-basis!!!
GRPP.grpsigs    = {'troiTs','tblp','tSdf','tSpkt'};         % Overwrites GrpPhySigs and GrpImgSigs on a GROUP-basis!!!


% GRPP.grpsigs = {'blp';'roiTs'};           % Overwrites GrpPhySigs and GrpImgSigs

%=========================================================================================
% Control flags for COR analysis
%=========================================================================================
ANAP.shift                = 10;
GRPP.groupcor             = 'before cor';
GRPP.corana{1}.mdlsct     = 'fhemo';
GRPP.corana{2}.mdlsct     = 'hemo';

%=========================================================================================
GRPP.groupglm                = 'before glm';
GRPP.glmana{1}.mdlsct{1} = 'fhemo';
GRPP.glmconts{1}=setglmconts('t','fhemo+',[ 1 0],'pVal',1,'WhichDesign',1);
GRPP.glmconts{2}=setglmconts('t','fhemo-',[-1 0],'pVal',1,'WhichDesign',1);


%=======================================================================
% Chan:  1  2  3  4
% Ele:   1  2  3  4
% Area: V2 V2 V2 V2  good responses from all.
% gain x30
%=======================================================================

% polar
GRP.polar.exps = [1:5];
GRP.polar.design = '10/6/14sec  blank/polar/blank x 10 trials';
GRP.polar.stminfo = 'ff polar';
GRP.polar.label = {'ff polar'};

% flicker
GRP.flicker8.exps = [14 15 26 27 30 31];
GRP.flicker8.design = '10/6/14sec  blank/flicker/blank x 10 trials';
GRP.flicker8.stminfo = '8Hz flicker';
GRP.flicker8.label = {'flicker'};

% spontaneous
GRP.spont.exps = [32:36];
GRP.spont.design = 'spont 5min';
GRP.spont.stminfo = 'avotec off';
GRP.spont.label = {'spont'};
GRP.spont.anap.gettrial.status = 0;
GRP.spont.refgrp.grpexp = 'polar';



%=======================================================================
% individual files (must cover all 'exps'.)
%=======================================================================
for N = 1:36,
  EXPP(N).physfile  = sprintf('SBJUID_%03d.adfw',N); % <---------- adfw name
  EXPP(N).scanreco  = [N+7, 1];           % <---------- ScanNumber, RecoNumber
end

