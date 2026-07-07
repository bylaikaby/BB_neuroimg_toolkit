function GRP = zappgetpars(GRP)
%ZAPPGETPARS - Get common parameters for the VISESMIX group (for global stats)
% pars = zappgetpars(GRP)
% NKL 17.03.2007
  
GRP.zapp.exps               = [];
GRP.zapp.design             = '';
GRP.zapp.stminfo            = 'zapping microstim';

GRP.zapp.roinames                   = {'Brain','LGN','SC','Pul','V1','V2','MT','XC'};
GRP.zapp.expinfo                    = {'imaging';'microstimulation'};
GRP.zapp.condition                  = {'normal'};
GRP.zapp.refgrp.grpexp              = 'zapp';
GRP.zapp.refgrp.reftrial            = [];               % Use the .reftrial for analysis
GRP.zapp.HemoDelay                  = 2;
GRP.zapp.HemoTail                   = 2;

GRP.zapp.anap.voxselect.dx          = 1;
GRP.zapp.anap.voxselect.masks       = {'zapp', {'fVal'}, 0.1};
GRP.zapp.anap.voxselect.models      = {'zapp', {'pbr','nbr'}, 0.01};

% ITOSDU == 1, epoch = 'prestim'; method = 'tosdu';
% ITOSDU == 2, epoch = 'blank'; method = 'tosdu';
% ITOSDU == 3, epoch = 'blank'; method = 'zerobase';
GRP.zapp.anap.mareats.IEXCLUDE       = {};
GRP.zapp.anap.mareats.ICONCAT        = 1;     % 1= concatanate ROIs before creating roiTs
GRP.zapp.anap.mareats.IFFTFLT        = 0;     % Respiratory artifact removal I
GRP.zapp.anap.mareats.IARTHURFLT     = 0;     % IT ONLY MAKES SENSE for TR <= 500
GRP.zapp.anap.mareats.IGAMMA         = 0;     % NO need for gamma-correction in these sessions
GRP.zapp.anap.mareats.IDETREND       = 1;
GRP.zapp.anap.mareats.ITOSDU         = 0;     % Express data in SD Units
GRP.zapp.anap.mareats.IHEMODELAY     = 2;     % For computing baseline in XFORM
GRP.zapp.anap.mareats.IHEMOTAIL      = 2;     % Same.. but only for non-prestim cases
GRP.zapp.anap.mareats.IMIMGPRO       = 1;     % Do image processsing
GRP.zapp.anap.mareats.IFILTER        = 1;	 % 1=to spatially filter; 0=no filter at all
GRP.zapp.anap.mareats.IFILTER_KSIZE  = 3;	 % Kernel size
GRP.zapp.anap.mareats.IFILTER_SD     = 1.25;  % SD (if half about 90% of flt in kernel)
GRP.zapp.anap.mareats.ISUBSTITUDE    = 0;     % DO not use this if you have dummy scans
GRP.zapp.anap.mareats.ICUTOFF        = 0;
GRP.zapp.anap.mareats.ICUTOFFHIGH    = 0;

% Definitions regarding sorting by trial
GRP.zapp.anap.gettrial.status       = 1;
GRP.zapp.anap.gettrial.trial2obsp   = 1;
GRP.zapp.anap.gettrial.Xmethod      = 'percent';  % tosdu-prestim doesn't show anything,
GRP.zapp.anap.gettrial.Xepoch       = 'blank';  % Argument (Epoch) to xfrom in gettrial
GRP.zapp.anap.gettrial.sort         = 'trial';  % sorting with SIGSORT, can be 'none|stimulus|trial
GRP.zapp.anap.gettrial.RefChan      = 2;        % Reference channel (for DIFF)
GRP.zapp.anap.gettrial.Average      = 1;        % Concat/Average; It is also used from trial2obsp

% THE FOLLOWING PARAMETERS ARE FOR GENERATING NEW (ACTIVATION-BASED) ROIS IN MROI
GRP.zapp.anap.mkroi.roi             = 'brain';
GRP.zapp.anap.mkroi.newroi          = 'pbr';
GRP.zapp.anap.mkroi.contrast        = 'pbr';
GRP.zapp.anap.mkroi.pval            = 0.01;

% PARAMETERS FOR GENERATING ACTIVATION MAPS THAT ARE SUPERIMPOSED ON ROIS BY MROI
GRP.zapp.anap.mroiesstat.models     = {'pbr','nbr'};
GRP.zapp.anap.mroiesstat.pval       = 0.01;
GRP.zapp.anap.mroiesstat.roinames   = {};

if GRP.zapp.anap.gettrial.status,
  GRP.zapp.grpsigs = {'troiTs'};
else
  GRP.zapp.grpsigs = {'roiTs'};
end;

GRP.zapp.corana{1}.mdlsct   =  'hemo';
GRP.zapp.glmana{1}.mdlsct   = {'hemo'};
NoReg = length(GRP.zapp.glmana{1}.mdlsct) + 1;
GRP.zapp.glmconts = {};
GRP.zapp.glmconts{end+1} = setglmconts('f','fVal',NoReg,'pVal',0.1);
GRP.zapp.glmconts{end+1} = setglmconts('t','pbr',  [ 1 0],'pVal',1);
GRP.zapp.glmconts{end+1} = setglmconts('t','nbr',  [-1 0],'pVal',1);


