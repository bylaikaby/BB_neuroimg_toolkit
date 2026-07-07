%CM033zJ1 - description of your poject/session
% SESSION : CM033.zJ1  - type of experiment (if exists) -
% EXPDATE : 20.01.16
% GROUPS  :
% EXPERIMENTS :
% ROIS :
%
% RECGAIN : x5000
% ELECTRODES : 1 2
% ADFCHANNEL : 1 2
% DEPTH(um) : 358 419
% NOTES : ......
%
% DATE/AUTHOR
%
% See also sesdumppar sesclnadjevt sesgetcln monline hgetstarted


%=======================================================================
% basic information : data directories, session quality
%=======================================================================
SYSP.DataNeuro	= 'RawDirForDGZ-ADF';  % dir. for adf/adfw/dgz
% SYSP.DataMri	= 'RawDirForMRData';     % dir. for 2dseq
SYSP.DataMri	= SYSP.DataNeruo;     % dir. for 2dseq
SYSP.dirname	= 'CM033.zJ1';
ANAP.Quality	= -1;	% Percent (all exps good activation)


%=======================================================================
% CATEGORIES (CTG) OF  EXPS/GROUPS/SIGS, if exist or needed
%=======================================================================
% CTG.exclGrps = ...
% CTG.inclGrps = ...
% CTG.rfGrps{X} = ...
% CTG.chcfGrps{X} = ...
% CTG.winGrps{X} = ...
% CTG.ImgGrps{X} = ...
% CTG.ImgSpoGrps = ...

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



% ANALYSIS PARAMETERS For Cleaning
% faster singular values decomposition for pca
ANAP.clnpar.METHOD      = 'pca';
% ANAP.clnpar.AVR_NOISE   = 'mean';
% ANAP.clnpar.NOPCS       = 8;
% ANAP.clnpar.PCACOEF     = 0.10;
% ANAP.clnpar.PCA_HIGHPASS= 1;
ANAP.clnpar.HIGHPASS    = 1;         % Cutoff freq for high pass (in Hz)
ANAP.clnpar.USE_LANSVD  = 1;
ANAP.clnpar.PLOT        = 0;  % save spectrum figures before/after cleaning



%=======================================================================
% ROI for MRI experiments, if exist or needed, then put here
% brain-ROI must be defined
% test-ROI should be defined, because if exists it's used to test
% scan-stability
% All roi should be with lower case
% model roi is the one we may use for xcor analysis
%=======================================================================
ROI.groups	= {'all'};                              % SuperAvg (see HROI)
ROI.names	= {'brain'; 'ele'; 'v1'; 'v2'; 'test'};	% Define desired ROIs
ROI.model	= 'ele';                                % Group to use as model



%=======================================================================
% ANATOMY scans (if exist gefi/mdeft/ir/msme)
% PLEASE MAKE SURE THE ELECTRODE POSITION AND SLICE IS 100% CORRECT
%=======================================================================
ASCAN.gefi{1}.info		= 'Electrode localization scan';
ASCAN.gefi{1}.scanreco	= [1 1];
ASCAN.gefi{1}.imgcrop	= [];

ASCAN.mdeft{1}.info		= 'Anatomy mdeft';
ASCAN.mdeft{1}.scanreco	= [2 1];
ASCAN.mdeft{1}.imgcrop	= [128 80 136 88];

ASCAN.mdeft{2}.info		= 'Anatomy mdeft';
ASCAN.mdeft{2}.scanreco	= [12 1];
ASCAN.mdeft{2}.imgcrop	= [128 80 136 88];

ASCAN.ir{1}.info		= 'Anatomy ir';
ASCAN.ir{1}.scanreco	= [5 1];
ASCAN.ir{1}.imgcrop		= [128 80 136 88];

%=======================================================================
% default group parameters
% this must be overwritten in each group, if different.
%=======================================================================
GRPP.daqver		= 2.00;		% DAQ program version: 2=nl+ym; 1=nl;
GRPP.hwinfo		= '';		% hardware info


% important (MRI)
GRPP.imgcrop	= [56 10 56 36];	% x, y, width, height
GRPP.ana		= {'gefi'; 1; [11 14]; [14 14]};

% important (NEU)
GRPP.gradch     = 5;        % Chan# of grad. in the ADF files
GRPP.hardch		= [1 2];	% Chan# of elec. in the ADF files

GRPP.softch		= [];		% invalidated channels for analysis
GRPP.findch		= [];		% Bad Channels spotted w/ findchan(Ses,GrpName);
GRPP.grproi		= 'RoiDef';	% the name of a Group's ROI, RoiDef as default


%=======================================================================
% experiment groups
%=======================================================================
% test1 : test scan with 'polar'
GRP.test1.exps		= [1:10];  % experiment numbers
GRP.test1.expinfo	= {'imaging','recording'};
GRP.test1.stminfo	= 'polar test';


GRP.test2.exps		= [11:20];  % experiment numbers
GRP.test2.expinfo	= {'imaging','recording'};
GRP.test2.stminfo	= 'polar test';


%=======================================================================
% individual files (must cover all 'exps'.)
%=======================================================================
for N = 1:15,
  EXPP(N).physfile  = sprintf('abcdef_%03d.adfx',N);
  EXPP(N).scanreco  = [N+8, 1];
end


EXPP(16).physfile  = 'abcdef_020.adfx';
EXPP(16).scanreco  = [25, 1];
