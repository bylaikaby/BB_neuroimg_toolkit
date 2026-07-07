%@SESSIONTEMPLATE - description of your poject/session
% SESSION : abcdef  - type of experiment (if exists) -
% EXPDATE : 15.03.04
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
% See also HPROJECTS


%=======================================================================
% basic information : data directories, session quality
%=======================================================================
SYSP.DataNeuro	= '//Win49/E/DataNeuro/';  % dir. for adf/adfw/dgz
SYSP.DataMri	= '//Wks8/guest/nmr/';     % dir. for 2dseq
SYSP.dirname	= 'ABC.def';
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

% Extraction of time series from ROIs (in the Roi.mat)
% ANAP.mareats.IEXCLUDE   = {'brain'};    % Exclude in MAREATS
% ANAP.mareats.ICONCAT    = 1;            % 1= concatanate ROIs before creating roiTs
% ANAP.mareats.IFFTFLT    = 0;            % Respiratory artifact removal I
% ANAP.mareats.IARTHURFLT = 1;            % Respiratory artifact removal II (Default)
% ANAP.mareats.ICUTOFF    = 1;            % 1Hz low pass cutoff
% ANAP.mareats.ICUTOFFHIGH= 0;            % No highpass
% ANAP.mareats.ITOSDU     = 0;            % Express data in SD Units

% Definitions for BLP extraction and trial splitting
% info.NewFs      = 250;     % All signals will be resampled at 250Hz
% COL-4 is the lowpass cuttof for filtering the envelope
% ANAP.siggetblp.band{ 1}     = {[   0     4] 'Delta'   'LFP', 0};
% ANAP.siggetblp.band{ 2}     = {[   4     8] 'Theta'   'LFP', 0};
% ANAP.siggetblp.band{ 3}     = {[   4     8] 'ThetaR'  'LFP', 2};
% ANAP.siggetblp.band{ 4}     = {[   8    14] 'Alpha'   'LFP', 3};
% ANAP.siggetblp.band{ 5}     = {[  14    24] 'Beta'    'LFP', 4};
% ANAP.siggetblp.band{ 6}     = {[  24    90] 'Gamma'   'LFP', 30};
% ANAP.siggetblp.band{ 7}     = {[   0    90] 'LFP'     'LFP', 0};
% ANAP.siggetblp.band{ 8}     = {[   0    90] 'LFPR'    'LFP', 30};
% ANAP.siggetblp.band{ 9}     = {[  40   130] 'LFPN'    'LFP', 30};
% ANAP.siggetblp.band{10}     = {[ 400  3000] 'MUA'     'MUA', 30};
% ANAP.siggetblp.lBands       = [1:9];    % Bands in the LFP range
% ANAP.siggetblp.mBands       = [10];      % Bands in the MUA range
% ANAP.siggetblp.conv2sdu     = 1;                % no conversion to SDU


%=======================================================================
% MOVIE analysis (if exist) : THIS MUST BE SET CAREFULLY.
%=======================================================================
ANAP.revcor.Frame		= 1;		% For display purposes
ANAP.revcor.TOFFSET		= [0];
ANAP.revcor.LFP_THR		= [3];
ANAP.revcor.MUA_THR		= [3];
ANAP.revcor.BadRFChan	= [];		% For display purposes
ANAP.revcor.MovPos		= [-2.2 -3.6 20 15];  % [centx centy width height]
%ANAP.revcor.NO_AVG		= 2000;		% see also getrf.m


%=======================================================================
% COHERENCE / CONTRAST analysis (if exist) : THIS MUST BE SET CAREFULLY.
%=======================================================================
ANAP.confunc.maxchan	= 16;
ANAP.confunc.eledist	= 2;	% 2mm
ANAP.confunc.eleconfig	= [ 01 02 03 04; ...
							05 06 07 08; ...
						    09 10 11 12; ...
							13 14 15 16];

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
ASCAN.gefi{1}.imgcrop	= [128 80 136 88];

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
% EPI13 : basic functional scans (if exist)
%=======================================================================
CSCAN.epi13{1}.info		= 'Polars Stim';
CSCAN.epi13{1}.ana		= {};
CSCAN.epi13{1}.scanreco	= [7 1];
CSCAN.epi13{1}.imgcrop	= [32 20 34 22];
CSCAN.epi13{1}.v		= {[1 0 1 0 1 0 1 0]};
CSCAN.epi13{1}.t		= {[8 8 8 8 8 8 8 8]};


%=======================================================================
% default group parameters
% this must be overwritten in each group, if different.
%=======================================================================
GRPP.daqver		= 2.00;		% DAQ program version: 2=nl+ym; 1=nl;
GRPP.imgcrop	= [56 10 56 36];	% x, y, width, height
GRPP.ana		= {'gefi'; 1; [11 14]; [14 14]};
GRPP.hwinfo		= '';		% hardware info
GRPP.hardch		= [1 2];	% electrode numbers for ADF_CHANNELs
GRPP.softch		= [];		% invalidated channels for analysis
GRPP.findch		= [];		% Bad Channels spotted w/ findchan(Ses,GrpName);
GRPP.grproi		= 'RoiDef';	% the name of a Group's ROI, RoiDef as default

% GRPP.grpsigs = {'blp';'roiTs'};           % Overwrites GrpPhySigs and GrpImgSigs

% % correlation analysis for MRI
% GRPP.corana{1}.mdlsct = 'hemo';           % Model for correlation analysis
% GRPP.corana{2}.mdlsct = 'lfpr';           % Model for correlation analysis


% % glm analysis for MRI
% GRPP.groupglm                = 'before glm';
% GRPP.anap.glm.IARESTIMATION  = 0;            % AR estimation
% GRPP.anap.glm.ISATTERWAITH   = 0;            % Satterwaith
% GLM regressors
% GRPP.glmana{1}.mdlsct = {'hemo','lfpr','gamma','mua'};   % Model for GLM analysis 
% % GLM contrasts
% NoReg = length(GRPP.glmana{1}.mdlsct) + 1;
% GRPP.glmconts{1} = setglmconts('f','General Effects',NoReg,'pVal',ANAP.aval);
% GRPP.glmconts{2} = setglmconts('t','Hemo Effect',[1 0 0 0 0]);

% % Definitions regarding sorting by trial
% GRPP.anap.gettrial.status       = 0;        % IsTrial
% GRPP.anap.gettrial.Xmethod      = 'tosdu';  % Argument (Method)to xfrom in gettrial
% GRPP.anap.gettrial.Xepoch       = 'prestim';% Argument (Epoch) to xfrom in gettrial
% GRPP.anap.gettrial.Average      = 1;        % Do not average tblp, but concat
% GRPP.anap.gettrial.RefChan      = 2;        % Reference channel (for DIFF)
% GRPP.anap.gettrial.sort         = 'trial';  % sorting with SIGSORT, can be 'none|stimulus|trial

% % Definitions for correlation or GLM analysis
% % The grpexp is group or exp-data that are analyzed to generate maks for all other exps
% % The reftrial shows which of the trials should be used as regressor
% GRPP.refgrp.grpexp          = 'normostim';      % Default reference group
% GRPP.refgrp.reftrial        = 5;            % Use the .reftrial for analysis


%=======================================================================
% experiment groups
%=======================================================================
% test1 : test scan with 'polar'
GRP.test1.exps		= [1];  % experiment numbers
GRP.test1.expinfo	= {'imaging','recording'};
GRP.test1.stminfo	= 'polar test';

% test2 : test scan with 'polar', no event data (no-dgz)
GRP.test2.exps		= [10];  % experiment numbers
GRP.test2.expinfo	= {'imaging','alert'};
GRP.test2.stminfo	= 'Polar Test';
% if no-dgz or to ignore dgz,
% then should have these v/t/stmtypes values.
GRP.test2.v			= {[1 0 1 0 1 0 1 0]};  % stimulus, 0 as blank
GRP.test2.t			= {[8 8 8 8 8 8 8 8]};  % duration in volumes
GRP.test2.stmtypes	= {'blank','polar'};    % 0=blank, 1=polar

% movie1 : 5 min movie of xxxx.avi
GRP.movie1.exps		= [2:9 11];  % experiment numbers
GRP.movie1.expinfo	= {'imaging','recording'};
GRP.movie1.stminfo	= 'movie1';

% movie2 : 5 min movie of yyyy.avi
GRP.movie2.exps		= [12 15];  % experiment numbers
GRP.movie2.expinfo	= {'imaging','recording'};
GRP.movie2.stminfo	= 'movie2';

% spont1 : 5 min spontaneous activities
GRP.spont1.exps		= [13:14];  % experiment numbers
GRP.spont1.expinfo	= {'imaging','recording'};
GRP.spont1.stminfo	= '';
% parameters different from default values.
GRP.spont1.imgcrop	= [60 12 56 36];  % x, y, width, height
GRP.spont1.ana		= {'mdeft'; 2; [11 14]; [14 14]};
GRP.spont1.anap.bands.Lfp	= [1 50];
GRP.spont1.anap.bans.lfpcutoff = 5;
%GRP.spont1.epoch	= 1;  % If exist/set to not pay attention to Sig.stm
%GRP.spont1.refgrp	= 'movie1'; % Use the zmap of exp to sel TC

% flash1 : flash suppression
GRP.flash1.exps		= [16:18];  % experiment numbers
GRP.flash1.expinfo	= {'imaging','recording','alert'};
GRP.flash1.stminfo	= 'Flash Suppression';
% additional parameters for this group
GRP.flash1.labels	= {'P|B--P|N'; 'N|B--P|N'; 'B|P--N|P'; ...
                    'B|N--P|N'; 'P|P--N|N'; 'N|N--P|P'; };


%=======================================================================
% individual files (must cover all 'exps'.)
%=======================================================================
for N = 1:15,
  EXPP(N).physfile  = sprintf('abcdef_%03d.adfw',N);
  EXPP(N).videofile = sprintf('abcdef_%03d_2.adfw',N);
  EXPP(N).scanreco  = [N+8, 1];
end

EXPP(16).physfile  = 'abcdef_020.adfw';
EXPP(16).scanreco  = [25, 1];

EXPP(17).physfile  = 'abcdef_021.adfw';
EXPP(17).scanreco  = [27, 2];

EXPP(18).physfile  = 'abcdef_025.adfw';
EXPP(18).scanreco  = [28, 2];
