function GRP = visescombgetpars(GRP)
%VISESCOMBGETPARS - Get common parameters for the VISESCOMB group (for global stats)
% pars = visescombgetpars(GRP)
% NKL 17.03.2007
  
GRP.visescomb.exps                       = [];
GRP.visescomb.design                     = '';
GRP.visescomb.stminfo                    = '';

GRP.visescomb.expinfo                    = {'imaging';'microstimulation'};
GRP.visescomb.label                      = {'VS+ES combined'};
GRP.visescomb.condition                  = {'normal'};
GRP.visescomb.refgrp.grpexp              = 'visescomb';
GRP.visescomb.refgrp.reftrial            = [];               % Use the .reftrial for analysis
GRP.visescomb.HemoDelay                  = 2;
GRP.visescomb.HemoTail                   = 2;

% ITOSDU == 1, epoch = 'prestim'; method = 'tosdu';
% ITOSDU == 2, epoch = 'blank'; method = 'tosdu';
% ITOSDU == 3, epoch = 'blank'; method = 'zerobase';
GRP.visescomb.anap.mareats.IEXCLUDE       = {'Brain'};
GRP.visescomb.anap.mareats.ICONCAT        = 1;     % 1= concatanate ROIs before creating roiTs
GRP.visescomb.anap.mareats.IFFTFLT        = 0;     % Respiratory artifact removal I
GRP.visescomb.anap.mareats.IARTHURFLT     = 0;     % IT ONLY MAKES SENSE for TR <= 500
GRP.visescomb.anap.mareats.IGAMMA         = 0;     % NO need for gamma-correction in these sessions
GRP.visescomb.anap.mareats.IDETREND       = 0;
GRP.visescomb.anap.mareats.ITOSDU         = 0;     % Express data in SD Units
GRP.visescomb.anap.mareats.IHEMODELAY     = 2;     % For computing baseline in XFORM
GRP.visescomb.anap.mareats.IHEMOTAIL      = 2;     % Same.. but only for non-prestim cases
GRP.visescomb.anap.mareats.IMIMGPRO       = 1;     % Do image processsing
GRP.visescomb.anap.mareats.ISUBSTITUDE    = 0;     % DO not use this if you have dummy scans
GRP.visescomb.anap.mareats.IFILTER        = 1;	 % 1=to spatially filter; 0=no filter at all

if      GRP.visescomb.anap.mareats.IFILTER  == 1,
  GRP.visescomb.anap.mareats.IFILTER_KSIZE  = 3;     % Kernel size
  GRP.visescomb.anap.mareats.IFILTER_SD     = 0.75;  % SD (if half about 90% of flt in kernel)
  GRP.visescomb.anap.mareats.ICUTOFF        = 0.2125;
  GRP.visescomb.anap.mareats.ICUTOFFHIGH    = 0.0097;   % original 0.0097;
elseif  GRP.visescomb.anap.mareats.IFILTER  == 2,
  GRP.visescomb.anap.mareats.IFILTER_KSIZE  = 3;     % Kernel size
  GRP.visescomb.anap.mareats.IFILTER_SD     = 1.25;  % SD (if half about 90% of flt in kernel)
  GRP.visescomb.anap.mareats.ICUTOFF        = 0.210;
  GRP.visescomb.anap.mareats.ICUTOFFHIGH    = 0.016;
elseif  GRP.visescomb.anap.mareats.IFILTER  == 3,
  GRP.visescomb.anap.mareats.IFILTER_KSIZE  = 5;     % Kernel size
  GRP.visescomb.anap.mareats.IFILTER_SD     = 2;     % SD (if 1.5 ca. 90% of flt in kernel)
  GRP.visescomb.anap.mareats.ICUTOFF        = 0.180;
  GRP.visescomb.anap.mareats.ICUTOFFHIGH    = 0.010;
else
end;

% Definitions regarding sorting by trial
GRP.visescomb.anap.gettrial.status       = 1;
GRP.visescomb.anap.gettrial.trial2obsp   = 1;
GRP.visescomb.anap.gettrial.Xmethod      = 'percent';  % tosdu-prestim doesn't show anything,
GRP.visescomb.anap.gettrial.Xepoch       = 'blank';  % Argument (Epoch) to xfrom in gettrial
GRP.visescomb.anap.gettrial.sort         = 'trial';  % sorting with SIGSORT, can be 'none|stimulus|trial
GRP.visescomb.anap.gettrial.RefChan      = 2;        % Reference channel (for DIFF)
GRP.visescomb.anap.gettrial.Average      = 1;        % Concat/Average; It is also used from trial2obsp

% The field "voxselect" is used by the function MASKCOMBINE for selecting positive or
% negative ES-induced responses from within a visual map (mask) that is only positive or
% only negative.
% voxselect.masks are usually the visual maps
% voxselect.models are the regressors for selecting ES response
% Extraction of time series from ROIs (in the Roi.mat)
GRP.visescomb.anap.voxselect.dx          = 1;    % Sampling time before averaging
GRP.visescomb.anap.voxselect.masks       = {'visescomb', {'pvs','nvs'}, 0.05};

REFGROUP = 'visesmix';
REFGROUP = 'visescomb';
if strcmp(REFGROUP,'visesmix'),
  GRP.visescomb.anap.voxselect.models      = {'visescomb', {'pes','nes'}, 0.05};
else
  GRP.visescomb.anap.voxselect.models      = {'visescomb', {'incr','decr'}, 0.05};
end;

% GRP.visescomb.anap.voxselect.masks       = {'visesmix', {'pvs','nvs'}, 0.05};
% GRP.visescomb.anap.voxselect.models      = {'visesmix', {'pes','nes'}, 0.05};

% PARAMETERS FOR GENERATING ACTIVATION MAPS THAT ARE SUPERIMPOSED ON ROIS BY MROI
GRP.visescomb.anap.mroiesstat.models     = {'pes','nes','incr','decr'};
GRP.visescomb.anap.mroiesstat.pval       = 0.05;
GRP.visescomb.anap.mroiesstat.roinames   = {};

% USE THE FOLLOWING MODELS (CREATED WITH ESMODELS) TO SELECT ICs
GRP.visescomb.anap.ica.MdlName               = 'combica';

GRP.visescomb.anap.threshold                 = 1;            % SHOWMAPS activity above 3SD
GRP.visescomb.anap.bonferoni                 = 0;            % SHOWMAPS apply Bonferoni correction

if GRP.visescomb.anap.gettrial.status,
  GRP.visescomb.grpsigs = {'troiTs'};
else
  GRP.visescomb.grpsigs = {'roiTs'};
end;

GRP.visescomb.glmana{1}.mdlsct = {'MDL_visescomb_mixcomb.mat[1]',...
                    'MDL_visescomb_mixcomb.mat[2]','MDL_visescomb_mixcomb.mat[3]'};
NoReg = length(GRP.visescomb.glmana{1}.mdlsct) + 1;
GRP.visescomb.glmconts = {};
GRP.visescomb.glmconts{end+1} = setglmconts('f','fVal', NoReg,  'pVal',0.1, 'WhichDesign',1);
GRP.visescomb.glmconts{end+1} = setglmconts('t','pvs',  [ 1  0  1  0]/2, 'pVal',1,'WhichDesign',1);
GRP.visescomb.glmconts{end+1} = setglmconts('t','nvs',  [-1  0 -1  0]/2, 'pVal',1,'WhichDesign',1);
GRP.visescomb.glmconts{end+1} = setglmconts('t','incr', [-0.5  1 -0.5  0], 'pVal',1,'WhichDesign',1);
GRP.visescomb.glmconts{end+1} = setglmconts('t','decr', [ 0.5 -1  0.5  0], 'pVal',1,'WhichDesign',1);

