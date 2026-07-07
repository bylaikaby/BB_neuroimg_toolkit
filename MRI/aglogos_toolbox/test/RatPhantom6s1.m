%RatPhantom.6s1 - Debug-Session(1): fMRI+Neurophys in 4.7T; OE 04.Feb.11
% SESSION: RatPhantom.6s1
% EXPDATE: 04.Feb.11 
% PROJECT: Test Neuro Nexus Electrod
%
% NOTE 
%   Neuro Nexus Electrod (16 Channel) testing with Axel
%
% AUTHOR:
% TS 04.Feb.11
%

%==========================================================================
% basic information : data directories, session quality
%==========================================================================
%SYSP.DataNeuro          = '//Win49/Data/DataNeuro/';    % KEEP THIS dir structure ALWAYS
SYSP.DataNeuro          = '//wks8/guest/';    % KEEP THIS dir structure ALWAYS
SYSP.DataMri            = '//wks8/guest/';
%SYSP.matdir             = 'y:/DataRatHipp/';
SYSP.dirname            = 'RatPhantom.6s1';
SYSP.date               = '04.Feb.11';


ANAP.Quality            = -1;	% Percent (all exps good activation)
ANAP.ImgDistort         =  1;	% EPI-Anatomy can't be registered due2distortions

%=========================================================================================
% ANATOMY scans (if exist gefi/mdeft/ir/msme)
%=========================================================================================
% ASCAN.rare{1}.info      = 'Anatomy';
% ASCAN.rare{1}.scanreco  = [65 1];
%ASCAN.rare{1}.imgcrop   = [];



ANAP.clnpar.DEBUG   = 1;
ANAP.clnpar.DECFRAC = 3;
ANAP.clnpar.SAVEGRA = 1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFAULT GROUP INFORMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
GRPP.daqver             = 2.00;		% DAQ program version: 2=nl+ym; 1=nl;
GRPP.hardch             = [1:4];   % electrode numbers for ADF_CHANNELs ch1 = visual
GRPP.gradch             = 5;
GRPP.namech             = {'ele1','ele4','ele7','ele13'};
GRPP.ana                = [];
GRPP.imgcrop            = [];
GRPP.condition     = {'normal'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EACH GROUP INFORMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

GRP.spont1.exps          = [1];
GRP.spont1.design        = 'No stim';
GRP.spont1.stminfo       = 'spontaneous 4min 30s';
GRP.spont1.label         = {'spont'};
GRP.spont1.expinfo       = {'recording'};


GRP.spont2.exps          = [2];
GRP.spont2.design        = 'No stim';
GRP.spont2.stminfo       = 'spontaneous 4min 30s';
GRP.spont2.label         = {'spont'};
GRP.spont2.expinfo       = {'recording' 'imaging'};




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXPERIMENT INFORMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% recording without Magnet
EXPP(1).physfile = 'RatPhantom6s1_001.adfw';
EXPP(1).scanreco = [];

% recording with Magnet
EXPP(2).physfile = 'RatPhantom6s1_002.adfw';
EXPP(2).scanreco = [7 1];




