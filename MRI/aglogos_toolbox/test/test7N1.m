%TEST7N1 - fMRI 7T Rat; Axel 28.Apr.11
% SESSION:  test.7N1
% EXPDATE:  28.Apr.11 
% PROJECT:  Spontaneous BOLD
% NOTE:  Test Phys on 7T Rat   
%
% AUTHOR:
% TS 28.Apr.11

%==========================================================================
% basic information : data directories, session quality
%==========================================================================
SYSP.DataMri             = '//wks21/data/';
SYSP.DataNeuro           = '//Win49/Data/DataNeuro/';
SYSP.matdir              = 'y:/DataRatHipp/';
SYSP.dirname             = 'test.7N1';
SYSP.date                = '28.Apr.11';

%[ANAP, ROI, GRPP, FLICK] = rpgetpars('test7N1');  % Get common parameters

%=========================================================================================
% Parameters used by MVIEW
%=========================================================================================
ANAP.mview.anascale      = [0 5000 1.3];
ANAP.mview.funscale      = [-5 30];
ANAP.mview.alpha         = 0.01;
ANAP.mview.slices        = [];
ANAP.Quality             = -1;	% Percent (all exps good activation)
ANAP.ImgDistort          =  0;	% EPI-Anatomy can't be registered due2distortions

% EPICROP                  = [14 23 34 51];    % cropping as [x y width height]
% EPI2ANA                  = [10 5];

ANAP.clnpar.DEBUG       = 1;
ANAP.clnpar.DECFRAC	 = 1;			% Decimation factor
ANAP.clnpar.SAVEGRA     = 1;			% Save gradient noise



%=========================================================================================
% Anatomy scans (if exist gefi/mdeft/ir/msme)
%=========================================================================================
% ASCAN.rare{1}.info      = 'In-plane Anatomy';
% ASCAN.rare{1}.scanreco  = [51 1];
% ASCAN.rare{1}.imgcrop   = [(EPICROP(1)-1)*EPI2ANA(1)+1 (EPICROP(2)-1)*EPI2ANA(1)+1 EPICROP(3:4)*EPI2ANA(1)];
% 
% ASCAN.flash{1}.info      = 'In-plane Anatomy';
% ASCAN.flash{1}.scanreco  = [49 1];
% ASCAN.flash{1}.imgcrop   = [(EPICROP(1)-1)*EPI2ANA(2)+1 (EPICROP(2)-1)*EPI2ANA(2)+1 EPICROP(3:4)*EPI2ANA(2)];

%=========================================================================================
% DEFAULT GROUP INFORMATION
%=========================================================================================
GRPP.daqver        = 2.00;		% DAQ program version: 2=nl+ym; 1=nl;
GRPP.hardch        = [1:4];     % electrode numbers for ADF_CHANNELs ch1 = visual
GRPP.gradch        = [5];
GRPP.namech        = [];
GRPP.ana           = []; %{'rare'; 1; [1:8]};  % inplane anatomie
GRPP.imgcrop       = [];       % cropping as [x y width height]
GRPP.expinfo       = {'imaging','recording'};
GRPP.condition     = {'normal'};

%=======================================================================================================
% Number of acquired channels, names, markers and positions
%=======================================================================================================
% GRPP.ele.stim    = [];                       % electric stimulation recorded channel
% GRPP.ele.chan	 = [1:5];                    % electrode numbers for ADF_CHANNELs ch1 = visual
% GRPP.ele.grad    = [6];                      % Channels in which Grad-Interference is acq.
% GRPP.ele.name    = GRPP.namech;              % Channel-names (OXANA- CHECK IF CORRECT)
% 
% GRPP.ele.sidx    = {'pl','sr','cx'};         % pl=Pyramidal cell; sr=Stratum radiatum; cx=Cortex
% GRPP.ele.site    = {'pl','pl','cx','cx','pl'};
% 
% GRPP.ele.ap      = -[ 5000   5000   5000   5000  5000];
% GRPP.ele.ml      =  [-2500  -2500  -2500  -2500  2500];
% GRPP.ele.depth   = -[ 2400   2300   1500   1400  2400];
% 
% % for functional Image - Electrod-Position
% GRPP.mele.x      = [37 37 37 37  26]; % X-Direction
% GRPP.mele.y      = [47.5 47.5 47.5 47.5 47]; % Y-Direction
% GRPP.mele.slice  = [3 3 4 4 3]; % Slice
% 
% GRPP.ele.mcoords(1,:) = [38-EPICROP(1)+1  46.0-EPICROP(2)+1  3];
% GRPP.ele.mcoords(2,:) = [38-EPICROP(1)+1  46.0-EPICROP(2)+1  3];
% GRPP.ele.mcoords(3,:) = [38-EPICROP(1)+1  46.0-EPICROP(2)+1  3];
% GRPP.ele.mcoords(4,:) = [38-EPICROP(1)+1  46.0-EPICROP(2)+1  4];
% GRPP.ele.mcoords(5,:) = [28.5-EPICROP(1)+1  45-EPICROP(2)+1  4];

%=========================================================================================
% EACH GROUP INFORMATION
%=========================================================================================

GRP.spont.exps                 = [1 2 3];
GRP.spont.design               = 'No stim';
GRP.spont.stminfo              = 'spontaneous 1min';
GRP.spont.label                = {'spont'};
GRP.spont.refgrp.grpexp        = 'spont';
GRP.spont.expinfo              = {'imaging','recording'};


%=========================================================================================
% EXPERIMENT INFORMATION
%=========================================================================================

% Standard EPI coronal without Saturation slices
EXPP(1).physfile = sprintf('test7N1_012.adfw');
EXPP(1).scanreco = [12 1];

% Standard EPI axial, without Saturation slices
EXPP(2).physfile = sprintf('test7N1_013.adfw');
EXPP(2).scanreco = [13 1];

% Standard EPI coronal, without Saturation slices, Testgenerator off
EXPP(3).physfile = sprintf('test7N1_014.adfw');
EXPP(3).scanreco = [14 1];






