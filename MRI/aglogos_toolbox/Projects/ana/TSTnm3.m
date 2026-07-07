%TSTnm3 - Neurophys QNX test
% SESSION : TST.nm3 -- QNX test in neurophys room
% EXPDATE : 25.08.10
% GROUPS  : 
% EXPERIMENTS : 
% ROIS :
%
% NOTES :
%  For Exp=1:12
%    Ch1: tactile
%    Ch2: obsp
%    Ch3: stim. onset pulse
%    Ch4: OpenGL swap
%    Ch5: photodiode
%  For Exp=13:15
%    Ch1: attenuated obsp
%
% RESULTS :
%  Exp=13:22
%    Estimated delay in points
%      2023  1396  1380  1307  1301  1298  1296  1299  1293  1290
%    Delay = 66.6384+-10.8588 ms (mean+-sd, dt=0.048 ms)
%
% CODES :
%    for N = 13:22, tmpwv = adfread('tstnm3',N,1,1); DAT(:,N-12) = tmpwv(1:20000); end
%    for N=1:10, ts(N) = min(find(DAT(:,N) > 8000)); end;  % 8000 as threshold (16000/2)
%    mean(ts)*0.048 = 66.6384
%    std(ts)*0.048  = 10.8588
%
% DATE/AUTHOR
%  25.08.10 YM

%=======================================================================
% basic information : data directories, session quality
%=======================================================================
SYSP.DataNeuro	= '//wks6/guest/';     % dir. for adf/adfw/dgz
SYSP.DataNeuro	= 'D:/DataNeuro/';     % dir. for adf/adfw/dgz
SYSP.DataMri	= '//Wks6/guest/';     % dir. for 2dseq
SYSP.dirname	= 'TST.nm3';           % <--- Session Name
SYSP.date       = '25.Aug 10';         % <--- Session Date

%=======================================================================
% default analysis parameters : see also getses.m/getanap.m
% this must be overwritten in each group, if different.
%=======================================================================
% Definitions related to correlation or GLM analysis
ANAP.Quality	= -1;	% Percent (all exps good activation)
ANAP.aval               = 0.05;         % p-value for selecting time series
ANAP.rval               = 0.15;         % r (Pearson) coeff. for selecting time series
ANAP.shift              = 0;            % nlags for xcor in seconds
ANAP.clustering         = 1;            % apply clustering after voxel-selection
ANAP.bonferroni         = 0;            % Correction for multiple comparisons
ANAP.ImgDistort         = 0;

ANAP.clnpar.DEBUG       = 0;
ANAP.clnpar.DECFRAC     = 1;
ANAP.clnpar.SAVEGRA     = 0;

ANAP.imgload.ISUBSTITUTE = 0;
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
ANAP.mareats.ICUTOFF        = 0.8;   % Most spontaneous activity stuff is at 0.1Hz
ANAP.mareats.ICUTOFFHIGH    = 0.01;;

ANAP.siggetspk.binwidth     = 0.001;   % 1ms bin for Sdf

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
ROI.names	= {'brain' 'ele' 'v1' 'v2' 'MT' 'ele' 'elev1' 'test'};	% Define desired ROIs
ROI.model	= 'ele';                                % Group to use as model

%=======================================================================
% ANATOMY scans (if exist gefi/mdeft/ir/msme)
% PLEASE MAKE SURE THE ELECTRODE POSITION AND SLICE IS 100% CORRECT
%=======================================================================
ASCAN.flash{1}.info		= 'Anatomy FLASH';
ASCAN.flash{1}.scanreco	= [60 1];
ASCAN.flash{1}.imgcrop	= [26 22 56 36]*2 - [0 7 0 0];

%=======================================================================
% default group parameters
% this must be overwritten in each group, if different.
%=======================================================================
GRPP.daqver		= 2.00;		% DAQ program version: 2=nl+ym; 1=nl;
GRPP.imgcrop	= [];	% x, y, width, height
GRPP.ana        = {'flash',1,[1:5]};
GRPP.hwinfo		= '';		% hardware info
GRPP.hardch		= [1:5];	% electrode numbers for ADF_CHANNELs
GRPP.namech     = repmat({'V1'},size(GRPP.hardch));
GRPP.gradch     = [];
GRPP.softch		= [];		% invalidated channels for analysis
GRPP.findch		= [];		% Bad Channels spotted w/ findchan(Ses,GrpName);
GRPP.grproi		= 'RoiDef';	% the name of a Group's ROI, RoiDef as default
GRPP.condition  = {'normal'};
GRPP.recgain    = 15120*ones(size(GRPP.hardch));

% Definitions regarding sorting by trial
GRPP.anap.gettrial.status       = 1;
GRPP.anap.gettrial.trial2obsp   = 0;
GRPP.anap.gettrial.Xmethod      = 'none';  % tosdu-prestim doesn't show anything,
GRPP.anap.gettrial.Xepoch       = 'prestim';  % Argument (Epoch) to xfrom in gettrial
GRPP.anap.gettrial.sort         = 'trial';  % sorting with SIGSORT, can be 'none|stimulus|trial
GRPP.anap.gettrial.RefChan      = 2;        % Reference channel (for DIFF)
GRPP.anap.gettrial.Average      = 1;        % Concat/Average; It is also used from trial2obsp
GRPP.anap.gettrial.blp.Xmethod = 'sdu';
GRPP.anap.gettrial.ClnSpc.Xmethod = 'sdu';
GRPP.anap.gettrial.Spkt.Xmethod = 'none';


% 5/5/5s of blank/polar/blank by manual open/close
GRP.polar1.exps = [1 2];
GRP.polar1.design = '5/5/5sec  blank/polar/blank x 5 trials';
GRP.polar1.stminfo = 'full-field polar';
GRP.polar1.label = {'full-field polar'};
GRP.polar1.expinfo = {'recording'};
GRP.polar1.grpsigs = {'tCln'};


% 5/5/5s of blank/polar/blank by auto. open/close
GRP.polar2 = GRP.polar1;
GRP.polar2.exps   = [3 4];
GRP.polar2.design = '5/5/5sec  blank/polar/blank x 5 trials';
GRP.polar2.stminfo = 'full-field polar';

% 10/10/10s of blank/polar/blank by manual open/close
GRP.polar3 = GRP.polar1;
GRP.polar3.exps   = [5 6];
GRP.polar3.design = '10/10/10sec  blank/polar/blank x 5 trials';
GRP.polar3.stminfo = 'full-field polar';

% 10/10/10s of blank/polar/blank by auto. open/close
GRP.polar4 = GRP.polar1;
GRP.polar4.exps   = [7 8];
GRP.polar4.design = '10/10/10sec  blank/polar/blank x 5 trials';
GRP.polar4.stminfo = 'full-field polar';


% 5/5/5s of blank/polar/blank by manual open/close
GRP.polar5 = GRP.polar1;
GRP.polar5.exps   = [9];
GRP.polar5.design = '5/5/5sec  blank/polar/blank x 3 trials';
GRP.polar5.stminfo = 'full-field polar';
GRP.polar5.validobsp = 1;

% 5/5/5s of blank/polar/blank by manual open/close
GRP.polar6 = GRP.polar1;
GRP.polar6.exps   = [10];
GRP.polar6.design = '5/5/5sec  blank/polar/blank x 10 trials';
GRP.polar6.stminfo = 'full-field polar';

% 5/5/5s of blank/polar/blank by manual open/close
GRP.polar7 = GRP.polar1;
GRP.polar7.exps   = [11];
GRP.polar7.design = '5/5/5sec  blank/polar/blank x 1 trials';
GRP.polar7.stminfo = 'full-field polar';
GRP.polar7.validobsp = 1;


% NEW CABLE CONNECTION OF OBSP TRIGGER
% 5/5/5s of blank/polar/blank by manual open/close
GRP.polar8 = GRP.polar1;
GRP.polar8.exps   = [12];
GRP.polar8.design = '5/5/5sec  blank/polar/blank x 1 trials';
GRP.polar8.stminfo = 'full-field polar';



% NEW CABLE CONNECTION OF OBSP TRIGGER
% 5/5/5s of blank/polar/blank by manual open/close
GRP.polar9 = GRP.polar1;
GRP.polar9.exps   = [13:22];
GRP.polar9.design = '5/5/5sec  blank/polar/blank x 1 trials';
GRP.polar9.stminfo = 'full-field polar';
GRP.polar9.hardch= [1];	% electrode numbers for ADF_CHANNELs




%=======================================================================
% individual files (must cover all 'exps'.)
%=======================================================================
for N = 1:35,
  EXPP(N).physfile  = sprintf('TSTnm3_%03d.adfw',N); % <---------- adfw name
  EXPP(N).scanreco  = [];           % <---------- ScanNumber, RecoNumber
end

