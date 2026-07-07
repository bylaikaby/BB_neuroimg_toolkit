function GRP = visesmixgetpars(GRP)
%VISESMIXGETPARS - Get common parameters for the VISESMIX group (for global stats)
% pars = visesmixgetpars(GRP)
%
% b06fu1: 06.Feb.07 - [LGN]: Outstanding; Visesmix/Visescomb Examples for Averages
% b06gh1: 27.Mar.07 - [LGN]: Outstanding; Visesmix/Visescomb Examples for Averages
% b06gi1: 02.Mar.07 - [LGN]: Outstanding; Visesmix/Visescomb Examples for Averages
% d04g11: 13.Feb.07 - [LGN]: Outstanding; Visesmix,8/Visescomb,8 Examples for Averages
% b06h21: 17.Apr.07 - [LGN]: Excellent Visesmix for averages
% h05hq1: 11.Mai.07 - [LGN]: Outstanding; Freqtest/Visesmix for Averages
% B06TD1: 05.Jun.09 - [LGN]: Outstanding; Strong Freq Effects in visesmix,6,12; visescomb)
% e04ds1: 04.Oct.06 - [LGN]: Outstanding; Visesmix/Visescomb Examples for Averages
% h05gb1: 21.Mar.07 - [LGN]: Good visesmix (pes/nes) - no Lido effects
% H05Tm1: 19.May.09 - [LGN]: Outstanding; Strong Freq Effects (visesmix is like freqtest)
% d02hm1: 07.Mai.07 - [LGN]: Good visesmix - needs ROI redefinition
% d04jq1: 08.Oct.07 - [LGN]: Good visesmix (avg); no injection effects
% b06lp1: 07.Jan.08 - [LGN]: AR-Inj; Outstanding Reversal in IPZ (V2 close to ele tip)
% l02fj1: 26.Jan.07 - [LGN]: Excellent cat(visesmix,visesmix8)/cat(visescomb,visescomb8) - V1-Lesion
% f05gp1: 09.Mar.07 - [LGN]: 09.03.07 Analysis Completed; Excellent
% b06nr1: 12.Jun.08 - [LGN]: Lidocaine, V2 recording 12.06.08
% d04m11: 19.Feb.08 - [LGN]: AR-Inj; no effect??
% f05i31: 19.Jun.07 - [LGN]: ES/Flicker(8/15/30Hz & CGP-46381 Inj) 19.06.07 (systemic)
% f05ih1: 03.Jul.07 - [LGN]: Good visesmix/L some GABA-block effects
% f05il1: 02.Aug.07 - [LGN]: GABA-a/b block 02.08.07 (systemic)
% f05iy1: 15.Aug.07 - [LGN]: GABA-a block 15.08.07 (systemic)
% h05ip1: 11.Jul.07 - [LGN]: Good visesmix (pes/nes) - very small GABA-effects
%
% h05jo1: 17.Aug.07 - [LGN]: GABA-a/b blocker -> 17.08.07 (local)
% h05jx1: 15.Oct.07 - [LGN]: GABA-a/b blocker -> 15.10.07 (local)
% h05n21: 22.Apr.08 - [LGN]: GABA-a block, V2 recording 22.04.08
% h05ni1: 03.Jun.08 - [LGN]: GABA-a block, V2 recording -> 03.06.08
% h05np1: 15.May.08 - [LGN]: GABA-a block, V2 recording: Very good session w/ EleTip on IPZ
% h05o51: 26.Jun.08 - [LGN]: lidocaine, V2 recording 26.06.08
% h05oy1: 25.Jul.08 - [LGN]: lidocaine, V2 recording 25.07.08
% l02gg1: 28.Feb.07 - [LGN]: Multiple Visesmix in animal w/ V1 lesion
% h05jd1: 30.Aug.07 - [LGN]: Good Viesesmix - high temporal resolution
%
% h03fi1: 25.Jan.07 - [PUL]: Good Visesmix,8/Visescomb,8 - V1-inhibition at 8Hz
% j02fg1: 23.Jan.07 - [OT]: Excellent responses showing V1/V2 activation; example for OT-stim
% j02fp1: 01.Feb.07 - [OT]: Outstanding; visescombL is excellent mask for all groups
% l02dq1: 02.Oct.06 - [PUL]: Good visesmixL/combL in lesioned monkey; typical Pul results
%
% NKL 17.03.2007

TEST_RUN = 0;

GRP.visesmix.exps                       = [];
GRP.visesmix.design                     = '';
GRP.visesmix.stminfo                    = '';

GRP.visesmix.expinfo                    = {'imaging';'microstimulation'};
GRP.visesmix.label                      = {'VS';'ES'};
GRP.visesmix.condition                  = {'normal'};
GRP.visesmix.refgrp.grpexp              = 'visesmix';
GRP.visesmix.refgrp.reftrial            = [];               % Use the .reftrial for analysis
GRP.visesmix.HemoDelay                  = 2;
GRP.visesmix.HemoTail                   = 2;

% ------------------------------------------------------------------------
% Variables evaluated by MAREATS
% ------------------------------------------------------------------------
GRP.visesmix.anap.mareats.ICONCAT        = 1;       % 1= concatanate ROIs before creating roiTs
GRP.visesmix.anap.mareats.IFFTFLT        = 0;       % Respiratory artifact removal I
GRP.visesmix.anap.mareats.IARTHURFLT     = 0;       % IT ONLY MAKES SENSE for TR <= 500
GRP.visesmix.anap.mareats.IGAMMA         = 0;       % NO need for gamma-correction in these sessions
GRP.visesmix.anap.mareats.IDETREND       = 0;
GRP.visesmix.anap.mareats.ITOSDU         = 0;       % Express data in SD Units
GRP.visesmix.anap.mareats.IHEMODELAY     = 2;       % For computing baseline in XFORM
GRP.visesmix.anap.mareats.IHEMOTAIL      = 2;       % Same.. but only for non-prestim cases
GRP.visesmix.anap.mareats.IMIMGPRO       = 1;       % Do image processsing
GRP.visesmix.anap.mareats.IFILTER        = 1;       % 1=to spatially filter; 0=no filter at all
GRP.visesmix.anap.mareats.ISUBSTITUDE    = 0;       % DO not use this if you have dummy scans
GRP.visesmix.anap.mareats.IPCA           = 0;       % Reconstruct all TS from the first 8 components

if GRP.visesmix.anap.mareats.IFILTER  == 1,
  GRP.visesmix.anap.mareats.IFILTER_KSIZE  = 5;     % Kernel size
  GRP.visesmix.anap.mareats.IFILTER_SD     = 2;     % SD (if half about 90% of flt in kernel)
  GRP.visesmix.anap.mareats.ICUTOFF        = 0.211;
  GRP.visesmix.anap.mareats.ICUTOFFHIGH    = 0.010;
elseif GRP.visesmix.anap.mareats.IFILTER  == 2,
  GRP.visesmix.anap.mareats.IFILTER_KSIZE  = 3;     % Kernel size
  GRP.visesmix.anap.mareats.IFILTER_SD     = 1.25;  % SD (if half about 90% of flt in kernel)
  GRP.visesmix.anap.mareats.ICUTOFF        = 0.210;
  GRP.visesmix.anap.mareats.ICUTOFFHIGH    = 0.016;
elseif GRP.visesmix.anap.mareats.IFILTER  == 3,
  GRP.visesmix.anap.mareats.IFILTER_KSIZE  = 5;     % Kernel size
  GRP.visesmix.anap.mareats.IFILTER_SD     = 2;     % SD (if 1.5 ca. 90% of flt in kernel)
  GRP.visesmix.anap.mareats.ICUTOFF        = 0.180;
  GRP.visesmix.anap.mareats.ICUTOFFHIGH    = 0.010;
else
end;

if TEST_RUN,
  GRP.visesmix.anap.mareats.IEXCLUDE       = {'LGN','SC','Pul','V1','V2','MT','XC','inj','ipz'};
else
  GRP.visesmix.anap.mareats.IEXCLUDE       = {};
end;

% ------------------------------------------------------------------------
% USE THE FOLLOWING MODELS (CREATED WITH ESMODELS) TO SELECT ICs
% Variables evaluated by GETICA, SHOWICARES and SHOWICA
% ------------------------------------------------------------------------
GRPP.anap.ica.ClnSpc.evar_keep  = 20;
GRPP.anap.ica.ClnSpc.dim        = 'spatial';
GRPP.anap.ica.ClnSpc.type       = 'bell';
GRPP.anap.ica.ClnSpc.normalize  = 'none';

% FOR ROITS ETC.
GRPP.anap.ica.evar_keep         = 20;               % Numbers of PCs to keep
GRPP.anap.ica.roinames          = {'SC','LGN','V1','V2','MT','XC'};
GRPP.anap.ica.dim               = 'spatial';        % Temporal does not really work...
GRPP.anap.ica.type              = 'bell';           % The Tony Bell algorithm
GRPP.anap.ica.normalize         = 'none';           % No normalization (e.g. to SD etc.)
GRPP.anap.ica.period            = 'all';            % blank, stim, all...
GRPP.anap.ica.icomp             = [1:GRPP.anap.ica.evar_keep];
GRPP.anap.ica.mdlname           = {'pbr','nbr'};    % Name of model (ICs or their average)
GRPP.anap.ica.ic2mdl            = {[1],[2]};        % Use the following ICs as models for GLM
GRPP.anap.ica.DISP_THRESHOLD    = 2;                % For SHOWICA only (ca. 2 SDs)
GRPP.anap.ica.SIGNAME           = 'troiTs';

% The following defitions refer to the selection of ICs on the basis of their similarity to
% standard models, e.g. AvgResp.dat containing the average of all sessions for visesmix
% experiments. Different vectors represent responses in different areas, e.g. model.dat(:,1)
% is usually the V1 response, model.dat(:,2) the V2 response, and so on.
% The pVal and rVal fields are used by ICASELECT(SesName, GrpName).
% To run this function, you must (a) run GETICA, (b) esmodels(Ses,Grp,'avgresp') or any
% other model, and then [idx, r] = icaselect(Ses,Grp).
% To see the selected IC run ICASELECT without output arguments
GRPP.anap.ica.mdlidx            = [];           % Use the first 2 models for selecting ICs
GRPP.anap.ica.pVal              = 0.01;         % pVal for corr(mixica,IComponent)
GRPP.anap.ica.rVal              = 0.25;          % rVal-thr for corr(mixica,IComponent)

% PARAMETERS FOR GENERATING ACTIVATION MAPS THAT ARE SUPERIMPOSED ON ROIS BY MROI
GRP.visesmix.anap.mroiesstat.mask       = {'fVal','fVal','fVal','fVal'};
GRP.visesmix.anap.mroiesstat.models     = {'pvs', 'nvs', 'pes', 'nes'};
GRP.visesmix.anap.mroiesstat.mskpval    = 0.1;
GRP.visesmix.anap.mroiesstat.mdlpval    = 0.1;
GRP.visesmix.anap.mroiesstat.roinames   = {'brain'};

% THE FOLLOWING PARAMETERS ARE FOR GENERATING NEW (ACTIVATION-BASED) ROIS IN MROI
GRP.visesmix.anap.mkroi.roi             = 'brain';
GRP.visesmix.anap.mkroi.newroi          = 'pbr';
GRP.visesmix.anap.mkroi.contrast        = 'pbr';
GRP.visesmix.anap.mkroi.pval            = 0.01;

GRP.visesmix.anap.threshold             = 1;            % SHOWMAPS activity above 3SD
GRP.visesmix.anap.bonferoni             = 0;            % SHOWMAPS apply Bonferoni correction

% Definitions regarding sorting by trial
GRP.visesmix.anap.gettrial.status       = 1;
GRP.visesmix.anap.gettrial.trial2obsp   = 1;
GRP.visesmix.anap.gettrial.Xmethod      = 'percent';  % tosdu-prestim doesn't show anything,
GRP.visesmix.anap.gettrial.Xepoch       = 'blank';  % Argument (Epoch) to xfrom in gettrial
GRP.visesmix.anap.gettrial.sort         = 'trial';  % sorting with SIGSORT, can be 'none|stimulus|trial
GRP.visesmix.anap.gettrial.RefChan      = 2;        % Reference channel (for DIFF)
GRP.visesmix.anap.gettrial.Average      = 1;        % Concat/Average; It is also used from trial2obsp

if GRP.visesmix.anap.gettrial.status,
  GRP.visesmix.grpsigs = {'troiTs'};
else
  GRP.visesmix.grpsigs = {'roiTs'};
end;

GRP.visesmix.anap.showmap.STDERROR      = 0;             % If set uses errorbar otherwise CI
GRP.visesmix.anap.showmap.CIVAL         = [1 99];        % low and high confidence interval
GRP.visesmix.anap.showmap.BSTRP         = 200;
GRP.visesmix.anap.showmap.TRIAL         = [];
GRP.visesmix.anap.showmap.DRAW_ROI      = {};
GRP.visesmix.anap.showmap.FMTTYPE       = 'paper';       % Default is paper
GRP.visesmix.anap.showmap.COL_FACE      = [];            % shading color for CI plots
GRP.visesmix.anap.showmap.FUNCSCALE     = [0 10 1.5];
GRP.visesmix.anap.showmap.ANASCALE      = [0 10000 1.2];

% IMPORTANT FOR BATCH PROCESSING!!
% NKL: 22 Aug 2009
GRP.visesmix.anap.showmap.ROINAME   = {{'LGN'},{'SC'},{'PUL'},{'V1'},{'V2'},{'XC'},{'MT'}};
GRP.visesmix.anap.showmap.CMAP      = {[.4 0 0],'y','c','r','b','m','g','k','r','y','c','r','b','m','g','k'};
GRP.visesmix.anap.showmap.COL_LINE  = 'xycrbmgkrycrbmgk';
GRP.visesmix.anap.showmap.MASKNAME  = {'fVal','fVal','fVal','pvs','pvs','pvs','pvs'};
GRP.visesmix.anap.showmap.MODELNAME = {'pes','pes','pes',{'pes','nes'},{'pes','nes'},{'pes','nes'},{'pes','nes'}};
GRP.visesmix.anap.showmap.MSKP      = [0.05 0.05 0.05 0.05 0.05 0.05 0.05];
GRP.visesmix.anap.showmap.MDLP      = [0.05 0.05 0.05 0.05 0.05 0.05 0.05];

% IMPORTANT FOR STATS
GRP.visesmix.anap.mview.statistics           = 'glm';
GRP.visesmix.anap.mview.datname              = 'statv';
GRP.visesmix.anap.mview.glmana.model         = 4;
GRP.visesmix.anap.mview.glmana.trial         = 1;
GRP.visesmix.anap.mview.cluster              = 0;
GRP.visesmix.anap.mview.clusterfunc          = 'mcluster3';
GRP.visesmix.anap.mview.clusterfunc          = 'mcluster';
GRP.visesmix.anap.mview.mcluster3.B          = 3;
GRP.visesmix.anap.mview.mcluster3.cutoff     =  round((2*(GRP.visesmix.anap.mview.mcluster3.B-1)+1)^3*0.3);
GRP.visesmix.anap.mview.slices               = [];

GRP.visesmix.anap.voxselect.dx          = 1;    % Sampling time before averaging
GRP.visesmix.anap.voxselect.roinames    = {'LGN','SC','Pul','V1','V2','MT','XC'};
GRP.visesmix.anap.voxselect.masks       = {'visesmix', {'pvs','pvs'}, [0.10 0.10]};
GRP.visesmix.anap.voxselect.models      = {'visesmix', {'pes','nes'}, [0.05 0.05]};


% ====================================================================================================
% ATTENTION:
% IF THE FIELD IC2MDL IS NOT EMPTY, THEN WE USE THE ESGETPARS.M GLM-DEFINITIONS AND OUR
% REGRESSORS ARE IC COMPONENTS
% ====================================================================================================
GRP.visesmix.glmana = {};
GRP.visesmix.glmconts = {};
GRP.visesmix.model{1}.name  = 'vs';             % model-name, must be unique
GRP.visesmix.model{1}.type  = 'trialfhemo[0]';  % kernel type, can be boxcar,hemo etc.
GRP.visesmix.model{2}.name  = 'es';             % model-name, must be unique
GRP.visesmix.model{2}.type  = 'trialfhemo[1]';  % kernel type, can be boxcar,hemo etc.

DNO = 1;
if GRP.visesmix.anap.gettrial.status & GRP.visesmix.anap.gettrial.trial2obsp,
  % **** THIS HERE GAVE BY FAR THE CLEAREST RESULTS ****
  % Any of the composit or trial-based regressors, when tested unconditionally, they
  % select voxels in a manner that maps generated with uncorrelated regressors appear to
  % have small overlap. That is, the PVS-PES regressor will often pick actual PVS-NES type
  % of responses, and so will the PVS-NES regressor.
  % The only way around this - as far as I know at this point - is to generate conditional
  % maps.
  % Use MASKCOMBINE(SesName,GrpName,'brain') to see the maps
  GRP.visesmix.glmana{DNO}.mdlsct = {'vs','es'};
  NoReg = length(GRP.visesmix.glmana{DNO}.mdlsct) + 1;
  GRP.visesmix.glmconts{end+1} = setglmconts('f','fVal',NoReg,'pVal',0.1,'WhichDesign',DNO);
  GRP.visesmix.glmconts{end+1} = setglmconts('t','pvs', [ 1  0  0],'pVal',1, 'WhichDesign',DNO);
  GRP.visesmix.glmconts{end+1} = setglmconts('t','nvs', [-1  0  0],'pVal',1, 'WhichDesign',DNO);
  GRP.visesmix.glmconts{end+1} = setglmconts('t','pes', [ 0  1  0],'pVal',1, 'WhichDesign',DNO);
  GRP.visesmix.glmconts{end+1} = setglmconts('t','nes', [ 0 -1  0],'pVal',1, 'WhichDesign',DNO);
else
  GRP.visesmix.glmana{DNO}.mdlsct = {'fhemo'};
  NoReg = length(GRP.visesmix.glmana{DNO}.mdlsct) + 1;
  GRP.visesmix.glmconts{end+1} = setglmconts('f','fVal',NoReg,  'pVal',0.1, 'WhichDesign',DNO);
  GRP.visesmix.glmconts{end+1} = setglmconts('t','pbr', [ 1 0], 'pVal',1,'WhichDesign',DNO);
  GRP.visesmix.glmconts{end+1} = setglmconts('t','nbr', [-1 0], 'pVal',1, 'WhichDesign',DNO);
end;

if 0,       % THIS GOES TO THE DESCRIPTION FILE...
  DNO=2;
  GRP.visesmix.anap.ica = GRPP.anap.ica;
  if ~isempty(GRP.visesmix.anap.ica.ic2mdl),
    for N=1:length(GRP.visesmix.anap.ica.ic2mdl),
      GRP.visesmix.glmana{DNO}.mdlsct{N} = sprintf('ICAMDL_visesmix.mat[%d]', N);
    end;
    NoReg2 = length(GRP.visesmix.glmana{DNO}.mdlsct) + 1;
    
    txt = GRP.visesmix.anap.ica.mdlname;
    ConMat = zeros(NoReg2, NoReg2-1);
    for N=1:length(GRP.visesmix.anap.ica.ic2mdl), ConMat(N,N) = 1;  end;  ConMat = ConMat';
    GRP.visesmix.glmconts{end+1} = setglmconts('f','IC-fVal',NoReg2,'pVal',0.1,'WhichDesign',DNO);
    for N=1:size(ConMat,1),
      GRP.visesmix.glmconts{end+1} = setglmconts('t',txt{N},ConMat(N,:),'pVal',1,'WhichDesign',DNO);
    end;
    GRP.visesmix.glmconts{end+1} = setglmconts('t','V1>V2', [ 1 -1  0],'pVal',1,'WhichDesign',DNO);
    GRP.visesmix.glmconts{end+1} = setglmconts('t','V2>V1', [-1  1  0],'pVal',1,'WhichDesign',DNO);
  end;
end;

