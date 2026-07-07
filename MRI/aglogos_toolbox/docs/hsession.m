function hsession
%HSESSION - Help for session file.
% Session files are suppposed to have direcory settings, analysis
% parameters, data filenames and so on.
% "SYSP" sets data direcories for adf/adfw and 2dseq.
% "ANAP" sets analysis parameters for the session.
% "ASCAN" sets information about anatomical scans.
% "CSCAN" sets information about basic epi13 scans.
% "GRPP"  sets default parameters for all groups.  If each group
% 	has the same parameter(s), then programs will ignore values by
%	"GRPP" and use values by group's own.
% "GRP.xxx" sets experimet information for each group (repetition
% 	of the same data collection, experiment).
% "EXPP" provides filename, scan/reco number for each data collection.
%
% See also HPROJECTS, HSESLOG,
% See also SESCHECK, SESCHECKLV2
% See also GETDIRS, GOTO, GETSES, CATFILENAME
%
%
%
% %=======================================================================
% % basic information : data directories, session quality
% %=======================================================================
% SYSP.DataNeuro	= '//Win49/M/DataNeuro/';  % dir. for adf/adfw/dgz
% SYSP.DataMri	= '//Wks8/guest/nmr/';     % dir. for 2dseq
% SYSP.dirname	= 'ABC.def';
% ANAP.Quality	= -1;	% Percent (all exps good activation)
%
% %=======================================================================
% % CATEGORIES (CTG) OF  EXPS/GROUPS/SIGS, if exist or needed
% %=======================================================================
% % CTG.exclGrps = ...
% % CTG.inclGrps = ...
% % CTG.rfGrps{X} = ...
% % CTG.chcfGrps{X} = ...
% % CTG.winGrps{X} = ...
% % CTG.ImgGrps{X} = ...
% % CTG.ImgSpoGrps = ...
%
% %=======================================================================
% % default analysis parameters : see also getses.m/getanap.m
% % this must be overwritten in each group, if different.
% %=======================================================================
% % ANAP.xxxx = ...
%
% %=======================================================================
% % MOVIE analysis (if exist) : THIS MUST BE SET CAREFULLY.
% %=======================================================================
% ANAP.revcor.Frame		= 1;		% For display purposes
% ANAP.revcor.TOFFSET		= [0];
% ANAP.revcor.LFP_THR		= [3];
% ANAP.revcor.MUA_THR		= [3];
% ANAP.revcor.BadRFChan	= [];		% For display purposes
% ANAP.revcor.MovPos		= [-2.2 -3.6 20 15];  % [centx centy width height]
% %ANAP.revcor.NO_AVG		= 2000;		% see also getrf.m
%
%
% %=======================================================================
% % COHERENCE / CONTRAST analysis (if exist) : THIS MUST BE SET CAREFULLY.
% %=======================================================================
% ANAP.confunc.maxchan	= 16;
% ANAP.confunc.eledist	= 2;	% 2mm
% ANAP.confunc.eleconfig	= [ 01 02 03 04; ...
% 							05 06 07 08; ...
% 						    09 10 11 12; ...
% 							13 14 15 16];
%
% %=======================================================================
% % ROI for MRI experiments, if exist or needed, then put here
% % brain-ROI must be defined
% % test-ROI should be defined, because if exists it's used to test
% % scan-stability
% % All roi should be with lower case
% % model roi is the one we may use for xcor analysis
% %=======================================================================
% ROI.groups	= {'all'};                              % SuperAvg (see HROI)
% ROI.names	= {'brain'; 'ele'; 'v1'; 'v2'; 'test'};	% Define desired ROIs
% ROI.model	= 'ele';                                % Group to use as model
%
%
%
% %=======================================================================
% % ANATOMY scans (if exist gefi/mdeft/ir/msme)
% % PLEASE MAKE SURE THE ELECTRODE POSITION AND SLICE IS 100% CORRECT
% %=======================================================================
% ASCAN.gefi{1}.info		= 'Electrode localization scan';
% ASCAN.gefi{1}.scanreco	= [1 1];
% ASCAN.gefi{1}.imgcrop	= [128 80 136 88];
%
% ASCAN.mdeft{1}.info		= 'Anatomy mdeft';
% ASCAN.mdeft{1}.scanreco	= [2 1];
% ASCAN.mdeft{1}.imgcrop	= [128 80 136 88];
%
% ASCAN.mdeft{2}.info		= 'Anatomy mdeft';
% ASCAN.mdeft{2}.scanreco	= [12 1];
% ASCAN.mdeft{2}.imgcrop	= [128 80 136 88];
%
% ASCAN.ir{1}.info		= 'Anatomy ir';
% ASCAN.ir{1}.scanreco	= [5 1];
% ASCAN.ir{1}.imgcrop		= [128 80 136 88];
%
% %=======================================================================
% % EPI13 : basic functional scans (if exist)
% %=======================================================================
% CSCAN.epi13{1}.info		= 'Polars Stim';
% CSCAN.epi13{1}.ana		= {};
% CSCAN.epi13{1}.scanreco	= [7 1];
% CSCAN.epi13{1}.imgcrop	= [32 20 34 22];
% CSCAN.epi13{1}.v		= {[1 0 1 0 1 0 1 0]};
% CSCAN.epi13{1}.t		= {[8 8 8 8 8 8 8 8]};
%
%
% %=======================================================================
% % default group parameters
% % this must be overwritten in each group, if different.
% %=======================================================================
% GRPP.daqver		= 2.00;		% DAQ program version: 2=nl+ym; 1=nl;
% GRPP.imgcrop	= [56 10 56 36];	% x, y, width, height
% GRPP.ana		= {'gefi'; 1; [11 14]; [14 14]};
% GRPP.hwinfo		= '';		% hardware info
% GRPP.hardch		= [1 2];	% electrode numbers for ADF_CHANNELs
% GRPP.softch		= [];		% invalidated channels for analysis
% GRPP.grproi		= 'RoiDef';	% the name of a Group's ROI, RoiDef as default
%
% %=======================================================================
% % experiment groups
% %=======================================================================
% % test1 : test scan with 'polar'
% GRP.test1.exps		= [1];  % experiment numbers
% GRP.test1.expinfo	= {'imaging','recording'};
% GRP.test1.stminfo	= 'polar test';
%
% % test2 : test scan with 'polar', no event data (no-dgz)
% GRP.test2.exps		= [10];  % experiment numbers
% GRP.test2.expinfo	= {'imaging','alert'};
% GRP.test2.stminfo	= 'Polar Test';
% % if no-dgz or to ignore dgz,
% % then should have these v/t/stmtypes values.
% GRP.test2.v			= {[1 0 1 0 1 0 1 0]};  % stimulus, 0 as blank
% GRP.test2.t			= {[8 8 8 8 8 8 8 8]};  % duration in volumes
% GRP.test2.stmtypes	= {'blank','polar'};    % 0=blank, 1=polar
%
% % movie1 : 5 min movie of xxxx.avi
% GRP.movie1.exps		= [2:9 11];  % experiment numbers
% GRP.movie1.expinfo	= {'imaging','recording'};
% GRP.movie1.stminfo	= 'movie1';
%
% % movie2 : 5 min movie of yyyy.avi
% GRP.movie2.exps		= [12 15];  % experiment numbers
% GRP.movie2.expinfo	= {'imaging','recording'};
% GRP.movie2.stminfo	= 'movie2';
%
%
% %=======================================================================
% % individual files (must cover all 'exps'.)
% %=======================================================================
% for N = 1:15,
%   EXPP(N).physfile  = sprintf('abcdef_%03d.adfw',N);    % adf/adfw
%   EXPP(N).videofile = sprintf('abcdef_%03d_2.adfw',N);  % for movie
%   EXPP(N).scanreco  = [N+8, 1];                         % 2dseq
% end
%
helpwin hsession
