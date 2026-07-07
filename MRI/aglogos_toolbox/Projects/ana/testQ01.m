%testQ01 - MRI-PHYS (4.7T)  laminar electrode test
% SESSION : test.Q01 -- laminar electrode test at 4.7T
% EXPDATE : 23.10.08
% GROUPS  :
% EXPERIMENTS :
% ROIS :
%
% DATE/AUTHOR
%  23.10.08 YM

%=======================================================================
% basic information : data directories, session quality
%=======================================================================
SYSP.DataNeuro	= '//win49/Data/DataNeuro/';     % dir. for adf/adfw/dgz
SYSP.DataMri	= '//Wks19/guest/';     % dir. for 2dseq
SYSP.dirname	= 'test.Q01';           % <--- Session Name
SYSP.date       = '23.Oct 08';         % <--- Session Date

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

ANAP.ImgDistort         = 1;

ANAP.clnpar.DEBUG       = 1;
ANAP.clnpar.SAVEGRA     = 1;

% Extraction of time series from ROIs (in the Roi.mat)
ANAP.mareats.IEXCLUDE       = {};
ANAP.mareats.ICONCAT        = 1;     % 1= concatanate ROIs before creating roiTs
ANAP.mareats.IFFTFLT        = 0;     % Respiratory artifact removal I
ANAP.mareats.IARTHURFLT     = 0;     % IT ONLY MAKES SENSE for TR <= 500
ANAP.mareats.IGAMMA         = 0;     % NO need for gamma-correction in these sessions
ANAP.mareats.IDETREND       = 0;
ANAP.mareats.ITOSDU         = {'percent','blank'};     % Express data in SD Units
ANAP.mareats.IHEMODELAY     = 2;     % For computing baseline in XFORM
ANAP.mareats.IHEMOTAIL      = 6;     % Same.. but only for non-prestim cases
ANAP.mareats.IMIMGPRO       = 1;     % Do image processsing
ANAP.mareats.IFILTER        = 1;	 % 1=to spatially filter; 0=no filter at all
ANAP.mareats.IFILTER_KSIZE  = 3;	 % Kernel size
ANAP.mareats.IFILTER_SD     = 1.5;   % SD (if half about 90% of flt in kernel)
ANAP.mareats.ISUBSTITUDE    = 0;     % DO not use this if you have dummy scans
ANAP.mareats.ICUTOFF        = 0;   % Most spontaneous activity stuff is at 0.1Hz
ANAP.mareats.ICUTOFFHIGH    = 0;;

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
ROI.names	= {'brain'; 'brain2'; 'ele'; 'v1'; 'v2'; 'test'};	% Define desired ROIs
ROI.model	= 'ele';                                % Group to use as model


%=======================================================================
% ANATOMY scans (if exist gefi/mdeft/ir/msme)
% PLEASE MAKE SURE THE ELECTRODE POSITION AND SLICE IS 100% CORRECT
%=======================================================================
% ASCAN.flash{1}.info		= 'Anatomy flash';
% ASCAN.flash{1}.scanreco	= [71 1];
% ASCAN.flash{1}.imgcrop	= [28 16 62 40]*4;



%=======================================================================
% default group parameters
% this must be overwritten in each group, if different.
%=======================================================================
GRPP.daqver		= 2.00;		% DAQ program version: 2=nl+ym; 1=nl;
GRPP.imgcrop	= [28 16 62 40];	% x, y, width, height
GRPP.ana        = {'flash',1,[1:3]};
GRPP.hwinfo		= '';		% hardware info
GRPP.hardch		= [1 2 3 4];	% electrode numbers for ADF_CHANNELs
GEPP.gradch     = 5;
GRPP.softch		= [];		% invalidated channels for analysis
GRPP.findch		= [];		% Bad Channels spotted w/ findchan(Ses,GrpName);
GRPP.grproi		= 'RoiDef';	% the name of a Group's ROI, RoiDef as default
GRPP.expinfo    = {'imaging','recording'};
GRPP.stminfo = 'polar';

% Definitions regarding sorting by trial
GRPP.anap.gettrial.status       = 0;
GRPP.anap.gettrial.trial2obsp   = 0;
GRPP.anap.gettrial.Xmethod      = 'percent';  % tosdu-prestim doesn't show anything,
GRPP.anap.gettrial.Xepoch       = 'blank';  % Argument (Epoch) to xfrom in gettrial
GRPP.anap.gettrial.sort         = 'trial';  % sorting with SIGSORT, can be 'none|stimulus|trial
GRPP.anap.gettrial.RefChan      = 2;        % Reference channel (for DIFF)
GRPP.anap.gettrial.Average      = 1;        % Concat/Average; It is also used from trial2obsp

GRPP.grpsigs    = {'roiTs'};         % Overwrites GrpPhySigs and GrpImgSigs on a GROUP-basis!!!


% GRPP.grpsigs = {'blp';'roiTs'};           % Overwrites GrpPhySigs and GrpImgSigs

%=========================================================================================
% Control flags for COR analysis
%=========================================================================================
ANAP.shift                = 10;
GRPP.groupcor             = 'after cor';
GRPP.corana{1}            = 'hemo';

%=========================================================================================
GRPP.groupglm                = 'after glm';
GRPP.glmana{1}.mdlsct{1} = 'henmo';
GRPP.glmconts{1}=setglmconts('t','hemo+',[1 0],'pVal',1,'WhichDesign',1);


%=======================================================================
% Chan: 1 2 3  4
% Ele:
%--------------------------------
% Scan  Config    Monkey        NIComp    EPI
% 27:   MultiEle     -            -       fastEPI (imgtr=500ms)
% 28:             100nF/100Ohm    -
% 29:                -            +
% 30:                +            +
%
% 31:   MultiEle     -            -       EPI17 (imgtr=6000ms)
% 32:                +            -
% 33:                +            +
% 34:                -            +
%
% 35:   SingleEle    -            +       EPI17 (imgtr=6000ms)
% 36:                +            +
% 37:                +            -
% 38:                -            -
%
% 
%=======================================================================

% 
GRP.scan7.exps  = [1];
GRP.scan8.exps  = [2];
GRP.scan8.validobsp = [1];
GRP.scan9.exps  = [3];
GRP.scan10.exps = [4];
GRP.scan10.validobsp = [1];
GRP.scan11.exps = [5];
GRP.scan12.exps = [6];

GRP.scan13.exps = [7];

GRP.noscan.exps = [8];
GRP.noscan.expinfo    = {'recording'};


% Ch03 short-curcuit, DIFF
GRP.noscan2.exps = [9];
GRP.noscan2.expinfo    = {'recording'};

% Ch03 short-curcuit, NRSE
GRP.noscan3.exps = [10];
GRP.noscan3.expinfo    = {'recording'};

% Ch03 short-curcuit, RSE
GRP.noscan4.exps = [11];
GRP.noscan4.expinfo    = {'recording'};



%=======================================================================
% individual files (must cover all 'exps'.)
%=======================================================================
% scan 7-13
for N = 1:7,
  EXPP(N).physfile  = sprintf('testQ01_%03d.adfw',N); % <---------- adfw name
  EXPP(N).scanreco  = [N+6, 1];           % <---------- ScanNumber, RecoNumber
end

for N = 8:11,
  EXPP(N).physfile  = sprintf('testQ01_%03d.adfw',N); % <---------- adfw name
  EXPP(N).scanreco  = [];           % <---------- ScanNumber, RecoNumber
end