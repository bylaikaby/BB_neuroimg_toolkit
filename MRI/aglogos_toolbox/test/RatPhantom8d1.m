%RatPhantom.6z2 - Debug-Session(1): fMRI+Neurophys in 4.7T; OE 11.Feb.11
% SESSION: RatPhantom.6z2
% EXPDATE: 11.Feb.11 
% PROJECT: Test Neuro Nexus Electrod
%
% NOTE 
%   2 x Neuro Nexus Electrod (16 Channel) testing with Axel
%
% AUTHOR:
% TS 11.Feb.11
%

%==========================================================================
% basic information : data directories, session quality
%==========================================================================
% SYSP.DataNeuro          = '//Win49/Data/DataNeuro/';    % KEEP THIS dir structure ALWAYS
SYSP.DataNeuro          = '//wks19/guest/';    % KEEP THIS dir structure ALWAYS
SYSP.DataMri            = '//wks19/guest/';
%SYSP.DataMatlab            = 'y:/DataRatHipp/';
SYSP.dirname            = 'RatPhantom.8d1';
SYSP.date               = '11.Feb.11';

ANAP.Quality            = -1;	% Percent (all exps good activation)
ANAP.ImgDistort         =  1;	% EPI-Anatomy can't be registered due2distortions

%=========================================================================================
% ANATOMY scans (if exist gefi/mdeft/ir/msme)
%=========================================================================================
% ASCAN.rare{1}.info      = 'Anatomy';
% ASCAN.rare{1}.scanreco  = [65 1];
% ASCAN.rare{1}.imgcrop   = [];


ANAP.clnpar.DEBUG   = 1;
ANAP.clnpar.DECFRAC = 1;
ANAP.clnpar.SAVEGRA = 1;





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFAULT GROUP INFORMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
GRPP.daqver             = 2.00;		% DAQ program version: 2=nl+ym; 1=nl;
GRPP.hardch             = [1:5 7:16];   % electrode numbers for ADF_CHANNELs ch1 = visual
GRPP.gradch             = 6;
GRPP.namech             = repmat({'ele'},[1 length(GRPP.hardch)]);
GRPP.ana                = [];
GRPP.imgcrop            = [];
GRPP.expinfo       = {'imaging','recording'};
GRPP.condition     = {'normal'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EACH GROUP INFORMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

GRP.test2.exps          = [1 2];
GRP.test2.design        = 'No stim';
GRP.test2.stminfo       = 'spontaneous 1min 48s';
GRP.test2.label         = {'spont'};
GRP.test2.expinfo       = {'imaging','recording'};


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXPERIMENT INFORMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% recording without Magnet
EXPP(1).physfile = 'RatPhantom8d1_001.adfw';
EXPP(1).scanreco = [4 1];

% recording with Magnet
EXPP(2).physfile = 'RatPhantom8d1_002.adfw';
EXPP(2).scanreco = [5 1];




