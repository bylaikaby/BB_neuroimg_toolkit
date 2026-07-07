function GRP = estimgetpars(GRP)
%ESTIMGETPARS - Get common parameters for the VISESMIX group (for global stats)
% pars = estimgetpars(GRP)
% NKL 17.03.2007
  
GRP.estim.exps               = [];
GRP.estim.design             = '';
GRP.estim.stminfo            = '';

GRP.estim.roinames                   = {'LGN','SC','Pul','V1','V2','MT','XC'};
GRP.estim.expinfo                    = {'imaging';'microstimulation'};
GRP.estim.condition                  = {'normal'};
GRP.estim.refgrp.grpexp              = 'estim';
GRP.estim.refgrp.reftrial            = [];               % Use the .reftrial for analysis
GRP.estim.HemoDelay                  = 2;
GRP.estim.HemoTail                   = 2;

% USED BY SESGROUPSTAT/SHOWGROUPSTAT TO AVERAGE RESPONSES AND DISPLAY THEM
GRP.estim.anap.voxselect.dx          = 0.5;    % Sampling time before averaging
GRP.estim.anap.voxselect.masks       = {'estim', {'fVal'}, 0.1};
GRP.estim.anap.voxselect.models      = {'estim', {'pbr','nbr'}, 0.05};

% ITOSDU == 1, epoch = 'prestim'; method = 'tosdu';
% ITOSDU == 2, epoch = 'blank'; method = 'tosdu';
% ITOSDU == 3, epoch = 'blank'; method = 'zerobase';
GRP.estim.anap.mareats.IEXCLUDE       = {};
GRP.estim.anap.mareats.ICONCAT        = 1;     % 1= concatanate ROIs before creating roiTs
GRP.estim.anap.mareats.IFFTFLT        = 0;     % Respiratory artifact removal I
GRP.estim.anap.mareats.IARTHURFLT     = 0;     % IT ONLY MAKES SENSE for TR <= 500
GRP.estim.anap.mareats.IGAMMA         = 0;     % NO need for gamma-correction in these sessions
GRP.estim.anap.mareats.IDETREND       = 0;
GRP.estim.anap.mareats.ITOSDU         = 0;     % Express data in SD Units
GRP.estim.anap.mareats.IHEMODELAY     = 2;     % For computing baseline in XFORM
GRP.estim.anap.mareats.IHEMOTAIL      = 2;     % Same.. but only for non-prestim cases
GRP.estim.anap.mareats.IMIMGPRO       = 1;     % Do image processsing
GRP.estim.anap.mareats.IFILTER        = 1;	   % 1=to spatially filter; 0=no filter at all
GRP.estim.anap.mareats.IFILTER_KSIZE  = 3;	   % Kernel size
GRP.estim.anap.mareats.IFILTER_SD     = 0.75;  % SD (if half about 90% of flt in kernel)
GRP.estim.anap.mareats.ISUBSTITUDE    = 0;     % DO not use this if you have dummy scans
GRP.estim.anap.mareats.ICUTOFF        = 0.20;  % For all 4/4/12 second trials
GRP.estim.anap.mareats.ICUTOFFHIGH    = 0.02;

% Definitions regarding sorting by trial
GRP.estim.anap.gettrial.status       = 1;
GRP.estim.anap.gettrial.trial2obsp   = 1;
GRP.estim.anap.gettrial.Xmethod      = 'percent';  % tosdu-prestim doesn't show anything,
GRP.estim.anap.gettrial.Xepoch       = 'blank';  % Argument (Epoch) to xfrom in gettrial
GRP.estim.anap.gettrial.sort         = 'trial';  % sorting with SIGSORT, can be 'none|stimulus|trial
GRP.estim.anap.gettrial.RefChan      = 2;        % Reference channel (for DIFF)
GRP.estim.anap.gettrial.Average      = 1;        % Concat/Average; It is also used from trial2obsp

% THE FOLLOWING PARAMETERS ARE FOR GENERATING NEW (ACTIVATION-BASED) ROIS IN MROI
GRP.estim.anap.mkroi.roi             = 'brain';
GRP.estim.anap.mkroi.newroi          = 'pbr';
GRP.estim.anap.mkroi.contrast        = 'pbr';
GRP.estim.anap.mkroi.pval            = 0.01;

% PARAMETERS FOR GENERATING ACTIVATION MAPS THAT ARE SUPERIMPOSED ON ROIS BY MROI
GRP.estim.anap.mroiesstat.models     = {'pbr','nbr'};
GRP.estim.anap.mroiesstat.pval       = 0.01;
GRP.estim.anap.mroiesstat.roinames   = {};

% USE THE FOLLOWING MODELS (CREATED WITH ESMODELS) TO SELECT ICs
GRP.estim.anap.ica.type            = 'bell';
GRP.estim.anap.ica.dim             = 'spatial';
GRP.estim.anap.ica.evar_keep       = 20;
GRP.estim.anap.ica.NoComponents    = -1;             % In case of no model-selection
GRP.estim.anap.ica.icomp           = {'1+' '1-' '3+' '3-' '4+' '4-'};
GRP.estim.anap.ica.DISP_THRESHOLD  = 2;
GRP.estim.anap.ica.MdlName         = 'estim';
GRP.estim.anap.ica.pVal            = 0.05;
GRP.estim.anap.ica.rVal            = 0.6;
GRP.estim.anap.ica.ic2mdl          = {'1+' '4+' '4-'};
GRP.estim.anap.ica.ic2roi          = {'1+' '4+' '4-'};

GRP.estim.anap.threshold                 = 0;    % SHOWMAPS activity above 3SD
GRP.estim.anap.bonferoni                 = 0;    % SHOWMAPS apply Bonferoni correction

if GRP.estim.anap.gettrial.status,
  GRP.estim.grpsigs = {'troiTs'};
else
  GRP.estim.grpsigs = {'roiTs'};
end;

GRP.estim.corana{1}.mdlsct   =  'hemo';

GRP.estim.glmana{1}.mdlsct   = {'hemo','fhemo'};

NoReg = length(GRP.estim.glmana{1}.mdlsct) + 1;

GRP.estim.glmconts = {};
GRP.estim.glmconts{end+1} = setglmconts('f','fVal',NoReg,'pVal',0.1);
GRP.estim.glmconts{end+1} = setglmconts('t','pbr',  [ 1  1 0],'pVal',1);
GRP.estim.glmconts{end+1} = setglmconts('t','nbr',  [-1 -1 0],'pVal',1);


