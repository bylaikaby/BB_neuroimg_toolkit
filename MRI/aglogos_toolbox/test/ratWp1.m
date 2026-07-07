%RAT.Wp1 - Spontaneous Recording (2 electrodes)
% SESSION   : rat.Wp1
% EXPDATE   : 24.Nov.09
%       
% EXPERIMENTS : 2
%
% NOTES     : done on 4.7T. 
%             2 electrodes (both are 4mm lateral to bregma)
%
% GROUPS    	
% spont: spontaneous activites (10min x2)
% 
% ANESTHESIA: Urethane anaesthesia
%
% AUTHOR
%   YM 24.11.09
%

%=========================================================================================
% basic information : data directories, session quality
%=========================================================================================
SYSP.DataNeuro	= '//Win49/Data/DataNeuro/';
SYSP.DataMri	= '//wks8/guest/';
SYSP.dirname	= 'rat.Wp1';
SYSP.date		= '24.Nov.09';

%=========================================================================================
% CATEGORIES (CTG) OF  EXPS/GROUPS/SIGS, if exist or needed
%=========================================================================================
CTG.GrpPhySigs  = {'blp'};              % Group these physiology signals

% Session-specific quality/registration testing flags
ANAP.Quality            = -1;	% Percent (all exps good activation)
ANAP.ImgDistort         =  0;	% EPI-Anatomy can't be registered due2distortions


ANAP.siggetspk.binwidth     = 0.1;   % 100ms bin for Sdf

%ANAP.sesclnspc.twin         = 1.0;
%ANAP.sesclnspc.nfft_sec     = 1.0;
%ANAP.sesclnspc.dt           = 0.5;   % this doesn't work..., sigspc() will ignore...

ANAP.sesclnspc.twin         = 1.0;
ANAP.sesclnspc.nfft_sec     = 1.0;
ANAP.sesclnspc.dt           = 0.5;   % this doesn't work..., sigspc() will ignore...


%=========================================================================================
% GROUP DEFINITIONS (DEFAULTS)
%=========================================================================================
GRPP.ana        = {};
GRPP.imgcrop    = [];
GRPP.daqver		= 2.00;		% DAQ program version: 2=nl+ym; 1=nl;
GRPP.expinfo    ={'recording'};
GRPP.hwinfo		= '';		% hardware info
GRPP.hardch		= [1 2];    % electrode numbers for ADF_CHANNELs ch1 = visual
GRPP.softch		= [];		% invalidated channels for analysis
GRPP.namech     = {'SMr','SMl'};  % right/left somatosensory cortex, 4mm lateral to blegma
GRPP.grproi		= 'RoiDef';	% the name of a Group's ROI (RoiDef is the default)

GRPP.grpsigs    = {};         % Overwrites GrpPhySigs and GrpImgSigs on a GROUP-basis!!!


%==========================================================================
% INDIVIDUAL GROUPS: 
%==========================================================================
GRP.spont.exps              = [1:2];
GRP.spont.stminfo           = '10min spont';
GRP.spont.condition         = {'normal'};
GRP.spont.label             = {'10min spont'};

%==========================================================================
% INDIVIDUAL EXPERIMENTS
%==========================================================================
for N = 1:2,
  EXPP(N).physfile = sprintf('ratWp1_%03d.adfw',N);
  EXPP(N).scanreco = [];
end
