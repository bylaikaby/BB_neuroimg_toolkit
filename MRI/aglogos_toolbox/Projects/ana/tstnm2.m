%TSTNM2 - test with saline-bath
%         4x4 array with 1.5mm spacing, neurophys room
%
% EXPDATE : 27.06.06 Tue.
% GROUPS :  sound
% EXPERIMENTS : 110
%
% STIMULUS : sound
% INTER-ELECTRODE DISTANCE = 1.5mm
% REC GAIN :  x19920
% REC FILTER: 1-8kHz
% ELECTRODES :   1 2 3 4 6 8 9 10 16
% ADF_CHANNEL :	 1 2 3 4 5 6 7  8  9
%
% IMPEDANCE(Mohm,1kHz): 0.73 0.31 0.41 0.32 0.30 0.26 0.53 0.62 0.09  (D04nm1)
% IMPEDANCE(Mohm,1kHz): 0.24 0.41 0.43 0.15 0.39 0.25 0.64 0.44 0.67 0.27 (
%                       0.15 0.15 0.16 0.19 0.25 0.09 0.32 0.40 0.02  (today)
%
% !!!!!!!!!!!!!!!!!!!!!!!
% I used the same electrodes as G05nm1(22.06.06) experiment, no replacement.
% !!!!!!!!!!!!!!!!!!!!!!!
%
% SHEILDED SPEAKERS WERE USED,  no sign of artifacts so far.
%
% 27.06.06  YM

%=======================================================================
% basic information : data directories, session quality
%=======================================================================
SYSP.DataNeuro	= '//Win49/N/DataNeuro/';
SYSP.DataNeuro	= '//Win47/F/DataNeuro/';
SYSP.DataMri	= '//Wks8/guest/nmr/';
SYSP.dirname	= 'TST.nm2';
SYSP.date		= '27.Jun.06.Tue.';
ANAP.Quality	= -1;	% Percent (activation OK, consistent throughout session)

%=======================================================================
% CATEGORIES (CTG) OF EXPS/GROUPS/SIGS, if exist or needed, then put here
%=======================================================================
% CTG.inclGrps      = ...
% CTG.exclGrps		= {};
% CTG.rfGrps        = {};
% CTG.chcfGrps{1}	= {{};{}};
% CTG.chcfGrps{2}	= {{};{;;}};
% CTG.chcfGrps{3}	= {{};{}};
% CTG.winGrps{1}	= {'rivalryleft'};
% CTG.winGrps{2}	= {'rivalryright'};
% CTG.winGrps{3}	= {'polarflash'};
% CTG.imgGrps{X}    = ...
% CTG.imgSpoGrps    = ...

CTG.GrpPhySigs      = {'blp','ClnSpc'};


%=======================================================================
% COHERENCE / CONTRAST analysis (if exist)
%=======================================================================
ANAP.confunc.eledist		= 1.5;	% 1mm
ANAP.confunc.maxchan		= 16;
ANAP.confunc.eleconfig		= [ [01 02 03 04];
                                [05 06 07 08];
                                [09 10 11 12];
                                [13 14 15 16] ];

%=======================================================================
% bands extraction
%=======================================================================
ANAP.bands.conv2sdu         = 1;



%=======================================================================
% default group parameters
% this must be overwritten in each group, if different.
%=======================================================================
GRPP.daqver		= 2.00;		% DAQ program version: 2=nl+ym; 1=nl;
GRPP.hwinfo		= '';		% hardware info
GRPP.hardch		= [1 2 3 4 6 8 9 10 16]; % electrode numbers for ADF_CHANNELs
GRPP.softch		= [];		% invalidated channels for analysis
GRPP.lgnele     = [];  % electrode number in LGN


% ===========================================================================
% GROUPS:
% ===========================================================================

% white noise, 15-5-10sec of blank-sound-blank, 0.5min/file
% sound: 15-20kHz flat noise recorded as chan10 (the last).
GRP.sound.exps		= [1:50];
GRP.sound.expinfo	= {'recording'};
GRP.sound.stminfo	= 'white noise (flat)';


%=======================================================================
% SINGLE EXPERIMENTS: individual files (must cover all 'exps'.)
%=======================================================================
for N = 1:50,
  EXPP(N).physfile		= sprintf('tstnm2_%03d.adfw',N);
end
