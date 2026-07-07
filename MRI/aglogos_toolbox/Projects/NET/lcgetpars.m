function [ANAP, ROI, GRPP, LCSTIM, FSHOCK, FLICK] = lcgetpars(SesName, ARGS)
%LCGETPARS - Defines common parameters for LC stimulation
% [ANAP, ROI, GRPP] = lcgetpars(SesName) is called from within each description file to set
% the basic parameters that are used by all sessions. For a detailed description of the
% analysis procedure see RPANA.M
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXTRACTION/EDITING OF ROIS
% MATLAS2ROI Register the Atlas into the current EPI-space 
% MROI Run once and make electrode ROI (in this project THELE)
% PAXRENAMEROI(Ses,'roi_set','Atlas_spont') Rename the generated ROIs
% MANA2EPI(To make morphed anatomy onto EPI, do following)
% >> MANA2EPI(Ses,Grp,'export')
% >> MANA2EPI(Ses,Grp,'gui')
% >> MANA2EPI(Ses,Grp,'update')
% >> edit the session file based on messages (for example, GRP.spont.ana = { 'rare' 3 [] };)
% MROI to correct atlas-related ROIs.
% For details relatd to the definitions of atlas/morphing variables, check alwyas the
% individual sessions, as the quality of registration is utterly depending on the collected
% data, e.g. whether you may use anatomical scans or EPI for mapping the ROIs.
% Example session: S11kz1
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% NKL 06.01.2011
% NKL 06.08.2013 (Together with Andre)
%  
% See also LCANA


% get basic/common parameters.
[ANAP, ROI, GRPP, FLICK, ESTIM, POLAR] = rpgetpars(SesName, ARGS);


% NOTE: as of 12.07.19, all sessions are in DataRatHipp
% % force to look at "DataPul" directory
% if isfield(ANAP.project,'datadir') && any(strfind(ANAP.project.datadir,'DataRatHipp'))
%   ANAP.project.datadir = strrep(ANAP.project.datadir,'DataRatHipp','DataRatLC');
% end


% 2019.07.16
% new LC sessions have DX=1sec
ANAP.mareats.IRESAMPLE = 0;
ANAP.froiTs.mareats.IRESAMPLE = 0;          % "0.5" gives lots of significant voxels..., use very low p-value for statistics
ANAP.froiTs.mareats.IFILTER_KSIZE = 3;      % Default: 5, Kernel size (previously 3)
ANAP.froiTs.mareats.IFILTER_SD    = 1.5;    % Default: 2, Kernel SD (90% of flt in kernel)
ANAP.froiTs.mareats.ICUTOFFHIGH   = 0.010;  % remove very slow oscillations
ANAP.froiTs.mareats.ICUTOFF       = 0.450;  % 0.5 is Nyquist..

% ------------------------------------------------------------------------------------------------
% GLOBAL DEFINITIONS FOR ALL SESSIONS, E.G. DIRECTORIES, MODELS, ETC.
% ------------------------------------------------------------------------------------------------
SesName = lower(SesName);


%=========================================================================================
% Neural Event (e.g. Ripple) Extraction NKL_ATN: Old versions in the end of the file!!
%=========================================================================================
% NKL 16.03.2012
GRPP.labels = {'0.2mA, 50Hz','0.4mA, 50Hz'};

%=========================================================================================

tmproi = {'Brain','LEFT','RIGHT','lc','cele','thele'};

ROI.groups      = {'All'};                          % SuperAvg (see HROI)
ROI.model       = {'lc'};
GRPP.grproi ='RoiGrp';
ROI.names   = paxroigroups('ROI','rat');
ROI.names   = cat(2, tmproi, ROI.names);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LCSTIM GROUPS - CONTROL FOR BOLD QUALITY AND AREA REGISTRATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% blank-microstim-blank: 6-1-18 or 6-1-20
% ratqn1 lcstim:  blank microstim+microstim blank /6 1 20
% ratrx1 lcstim:  blank microstim+microstim blank /6 1 20
% rattq1 lcstim:  blank microstim+microstim blank /6 1 20
% rattq1 lcstim1: blank microstim+microstim blank /6 1 20
% rattq1 lcstim2: blank microstim+microstim blank /6 1 20
% ratoo2 lcstim:  blank microstim+microstim blank /6 4 20
% ratoo2 lcstim1: blank microstim+microstim blank /6 1 18
% ratto1 lcstim:  blank microstim+microstim blank /6 1 20
% ratto1 lcstim1: blank microstim+microstim blank /6 1 20
% ratto1 lcstim2: blank microstim+microstim blank /6 1 20
% ratub1 lcstim:  blank microstim+microstim blank /6 1 20
% rattb1 lcstim:  blank microstim+microstim blank /6 1 20
%
%LCSTIM = ESTIM;

LCSTIM.anap.gettrial.status = 1;
LCSTIM.anap.gettrial.status      =  1;           % We convert to trials
LCSTIM.anap.gettrial.Average     =  1;           % And average them
LCSTIM.anap.gettrial.trial2obsp  =  1;           % And the concatenate in a single obsp
LCSTIM.anap.gettrial.sort        = 'stimulus';
LCSTIM.anap.gettrial.PreT        = -6;           % No PreT (stimulus rather than trial type)
LCSTIM.anap.gettrial.PostT       =  18;          % No PostT
% LCSTIM.anap.gettrial.sort        = 'trial';
% LCSTIM.anap.gettrial.PreT        =  0;           % No PreT (stimulus rather than trial type)
% LCSTIM.anap.gettrial.PostT       =  0;          % No PostT
LCSTIM.anap.gettrial.Xmethod     = 'tosdu';      % set to zero if IBREANMEAN > 0...
LCSTIM.anap.gettrial.Xepoch      = 'prestim';    % Normlization-base
LCSTIM.anap.gettrial.HemoDelay   = 2.0;          % XFORM: Here much shorter than usually!
LCSTIM.anap.gettrial.HemoTail    = 6.0;          % XFORM: Same for tail
LCSTIM.anap.gettrial.IBRAINMEAN  =  0;           % 1=removes mean,2=zscore(dat,[],2)
LCSTIM.anap.gettrial.ICUTOFF     =  0;
LCSTIM.anap.gettrial.ICUTOFFHIGH =  0;

% -----------------------------------------------------------------------------------------------------
% SESGROUPGLM GLM-ANALYSIS
% -----------------------------------------------------------------------------------------------------
LCSTIM.anap.glm.IARESTIMATION    = 0;            % AR estimation
LCSTIM.anap.glm.ISATTERWAITH     = 0;            % Satterwaith
LCSTIM.anap.glm.ICONVWITHGAMMA   = 0;

LCSTIM.groupglm                  = 'before glm';
LCSTIM.anap.glm.glmpreproc       = '';
LCSTIM.glmsigs                   = {'tfroiTs'};
LCSTIM.glmana   = {};
LCSTIM.glmconts = {};

DNO=1;
LCSTIM.glmana{DNO}.mdlsct = {'fhemo'};
NoReg = length(LCSTIM.glmana{DNO}.mdlsct);
LCSTIM.glmconts{end+1} = setglmconts('f','fVal', NoReg+1,'pVal',  0.1, 'WhichDesign',DNO);
LCSTIM.glmconts{end+1} = setglmconts('t','pbr',  [ 1 0],'pVal',1,'WhichDesign',DNO);
LCSTIM.glmconts{end+1} = setglmconts('t','nbr',  [-1 0],'pVal',1,'WhichDesign',DNO);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FSHOCK GROUPS - CONTROL FOR BOLD QUALITY AND AREA REGISTRATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%FSHOCK = ESTIM;
FSHOCK = LCSTIM;
% -------------------------------------------------------------------------------------------------------
% SESGETTRIAL CONVERSION TO TRIALS
% -------------------------------------------------------------------------------------------------------
% ratqn1 fshock:  blank microstim+microstim /4 1
% ratqn1 fshock1: blank microstim+microstim /4 1
% ratqn1 fshock2: blank microstim+microstim blank /6 4 20
% ratrx1 fshock:  blank microstim+microstim /4 1
% ratrx1 fshock1: blank microstim+microstim /4 1
% ratrx1 fshock2: blank microstim+microstim blank /6 4 20
% rattq1 fshock:  blank microstim+microstim /4 1
% ratto1 fshock:  blank microstim+microstim /4 1
% ratto1 fshock1: blank microstim+microstim blank /6 4 20
% ratub1 fshock:  blank microstim+microstim /4 1
FSHOCK.anap.gettrial.status      = 1;            % We convert to trials
FSHOCK.anap.gettrial.Average     = 1;            % And average them
FSHOCK.anap.gettrial.trial2obsp  = 1;            % And the concatenate in a single obsp
FSHOCK.anap.gettrial.sort        = 'trial';
FSHOCK.anap.gettrial.PreT        = 0;            % No PreT (stimulus rather than trial type)
FSHOCK.anap.gettrial.PostT       = 0;            % No PostT
FSHOCK.anap.gettrial.Xmethod     = 'tosdu';      % set to zero if IBREANMEAN > 0...
FSHOCK.anap.gettrial.Xepoch      = 'prestim';    % Normlization-base
FSHOCK.anap.gettrial.HemoDelay   = 2.0;          % XFORM: Here much shorter than usually!
FSHOCK.anap.gettrial.HemoTail    = 6.0;          % XFORM: Same for tail
FSHOCK.anap.gettrial.IBRAINMEAN  = 0;            % 1=removes mean,2=zscore(dat,[],2)
FSHOCK.anap.gettrial.ICUTOFF     =  0;
FSHOCK.anap.gettrial.ICUTOFFHIGH =  0;

% -----------------------------------------------------------------------------------------------------
% SESGROUPGLM GLM-ANALYSIS
% -----------------------------------------------------------------------------------------------------
FSHOCK.anap.glm.IARESTIMATION    = 0;            % AR estimation
FSHOCK.anap.glm.ISATTERWAITH     = 0;            % Satterwaith
FSHOCK.anap.glm.ICONVWITHGAMMA   = 0;

FSHOCK.groupglm                  = 'before glm';
FSHOCK.anap.glm.glmpreproc       = '';
FSHOCK.glmsigs                   = {'tfroiTs'};
FSHOCK.glmana   = {};
FSHOCK.glmconts = {};

DNO=1;
FSHOCK.glmana{DNO}.mdlsct = {'fhemo'};
NoReg = length(FSHOCK.glmana{DNO}.mdlsct);
FSHOCK.glmconts{end+1} = setglmconts('f','fVal', NoReg+1,'pVal',  0.1, 'WhichDesign',DNO);
FSHOCK.glmconts{end+1} = setglmconts('t','pbr',  [ 1 0],'pVal',1,'WhichDesign',DNO);
FSHOCK.glmconts{end+1} = setglmconts('t','nbr',  [-1 0],'pVal',1,'WhichDesign',DNO);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ELECTRICAL STIMULAION/FOOTSHOCK GROUPS - CONTROL FOR BOLD QUALITY AND AREA REGISTRATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
FLICK = FSHOCK;  % For now we keep the paramters identical (for LC experiments)
% ratoo2 flicker: blank fgenerator blank /6 4 20
% ratoo2 flicker1: blank fgenerator blank /6 1 18




return
