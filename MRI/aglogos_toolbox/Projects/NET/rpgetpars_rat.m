function [ANAP, ROI, GRPP, FLICK, ESTIM, POLAR] = rpgetpars_rat(SesName, ANAP, ARGS)
%RPGETPARS_RAT - Global structures and parameters of the rat NET-fMRI experiments
%
% NKL 25.01.2014
%
% HIGHPASS is only for the cleaning process; It is recovered after the signal is denoised.
% To ensure recovery we have to set LOWRECOVER = 1;
% Checking rathm1, ratjp1, etc. shows that HIGHPASS=4; LOWRECOVER=1 in the standard
% remifentanil sessions in the magnet (NET-fMRI).
% NOTE No highpass filtering is done with SPIKE2 sessions, that are free of interference!
%=========================================================================================
ANAP.Animal = 'rat';
ANAP.clnpar.HIGHPASS   = 4;  % Cutoff freq for high pass (in Hz)
ANAP.clnpar.LOWRECOVER = 1;  % Recover low-freq componet(s) removed by any highpass.
ANAP.clnpar.OUTLIERS   = 0;  % Set if check for outliers is desired
ANAP.clnpar.REMOVE_ECG = 0;  % try to remove hear-beat artifact
ANAP.clnpar.PLOT       = 0;  % Plot data before/after cleaning

%=========================================================================================
% BLP( EXTRACTION IN RATS )
%=========================================================================================
% UDS(Up-Down States) [0.5- 1.0Hz]
% KCOMPLEX(  2-6Hz  ) - periodic occurrence 0.5 to 0.7 Hz (0.5 seconds duration). 
% THETA(     4-10Hz )
% SPINDLES( 11-16Hz )
% UPDATED( NKL, 27-Apr-2019)
%
ANAP.siggetblp.NewFs    = 660;
ANAP.siggetblp.lcutoff  = 660;
ANAP.siggetblp.mcutoff  = 100;
ANAP.siggetblp.conv2sdu = 0;        % DO NOT SET THIS (problems with state-detection)
ANAP.siggetblp.detrend  = 1;

% ==========================================================================================
% UPDATED(NKL/YM 09.07.2019)
% ==========================================================================================
% CLN       [   0.0   325.0] 'cln'     'LFP',   0.0};
% PGO       [   1.0    15.0] 'pgo'     'LFP',   6.5};
% DELTA     [   0.3     3.8] 'delta'   'LFP',   1.5};
% THETA     [   4.0    10.5] 'theta'   'LFP',   3.0};
% SIGMA     [  11.0    20.0] 'sigma'   'LFP',  10.5};
% GAMMA     [  25.0    88.0] 'gamma'   'LFP',  30.0};
% HGAMMA    [  90.0   135.0] 'hgamma'  'LFP',  30.0};
% RIPPLE    [ 140.0   250.0] 'ripple'  'LFP',  60.0};
% MEFP      [ 250.0   600.0] 'mefp'    'MUA', 100.0};
% MUA       [ 650.0  1800.0] 'mua'     'MUA', 200.0};
% ==========================================================================================
ANAP.siggetblp.band{ 1} = {[   0.0   325.0] 'cln'     'LFP',   0.0};
ANAP.siggetblp.band{ 2} = {[   1.0    15.0] 'pgo'     'LFP',   6.5};
ANAP.siggetblp.band{ 3} = {[   0.3     3.8] 'delta'   'LFP',   1.5};
ANAP.siggetblp.band{ 4} = {[   4.0    10.5] 'theta'   'LFP',   3,0};
ANAP.siggetblp.band{ 5} = {[  11.0    20.0] 'sigma'   'LFP',  10.0};
ANAP.siggetblp.band{ 6} = {[  25.0    88.0] 'gamma'   'LFP',  30.0};
ANAP.siggetblp.band{ 7} = {[  90.00  135.0] 'hgamma'  'LFP',  30};
ANAP.siggetblp.band{ 8} = {[ 140.00  250.0] 'ripple'  'LFP',  60};
ANAP.siggetblp.band{ 9} = {[ 250.0   600.0] 'mefp'    'MUA', 100.0};
ANAP.siggetblp.band{10} = {[ 650.0  2000.0] 'mua'     'MUA', 200.0};
ANAP.siggetblp.lBands   = [1:8];          % Bands in the LFP range
ANAP.siggetblp.mBands   = [9 10];         % mEFP and MUA Bands
ANAP.siggetblp.despike  = 0;              % 0|1 to despike or not

for N=1:length(ANAP.siggetblp.band),
  range = sprintf('%.0f %.0f', ANAP.siggetblp.band{N}{1});
  txt = sprintf('%s(%s)/%d', ANAP.siggetblp.band{N}{2},range,ANAP.siggetblp.band{N}{4});
  ANAP.siggetblp.blpinfo{N} = txt;
end;
  
ANAP.eeg.siggetblp.conv2sdu = 0;
ANAP.eeg.siggetblp.NewFs    = 660;
ANAP.eeg.siggetblp.lcutoff  = 660;
ANAP.eeg.siggetblp.band{ 1} = {[   0    300] 'cln'    'LFP',  0};
ANAP.eeg.siggetblp.band{ 2} = {[   0.2    4] 'delta'  'LFP',  2};
ANAP.eeg.siggetblp.band{ 3} = {[   5     10] 'theta'  'LFP',  2};
ANAP.eeg.siggetblp.band{ 4} = {[  11     22] 'sigma'  'LFP',  2};
ANAP.eeg.siggetblp.band{ 5} = {[  25     75] 'gamma'  'LFP', 20};
ANAP.eeg.siggetblp.band{ 6} = {[  80    160] 'ripple' 'LFP', 20};
ANAP.eeg.siggetblp.band{ 7} = {[ 800   1200] 'mefp'   'MUA', 50};
ANAP.eeg.siggetblp.decimate = 4;
ANAP.eeg.siggetblp.despike  = 0;                % 0|1 to despike or not

ANAP.viewbands.band = {};
ANAP.viewbands.band{end+1}  = {'ripple',   8, [140 190], 'zscore', 1,1,[0 0 0],[1 0 0],[1 .93 .93]};
ANAP.viewbands.band{end+1}  = {'hgamma',   8, [90  130], 'zscore', 1,1,[0 0 0],[1 0 0],[1 .93 .93]};
ANAP.viewbands.band{end+1}  = {'gamma',    8, [30   55], 'zscore', 1,1,[0 0 0],[1 0 0],[1 .93 .93]};
ANAP.viewbands.band{end+1}  = {'sigma',   12, [16   30], 'zscore', 1,1,[0 0 0],[0.4 0 1],[1 .93  1 ]};
ANAP.viewbands.band{end+1}  = {'theta',   12, [ 4   10], 'zscore', 1,1,[0 0 0],[.4 0 .4],[1 .93  1 ]};

% The CHAN selects the "channels" to display (each will have ripple-spindle)
ANAP.viewbands.chan         = {'PFC','pl','pl','LC'};
ANAP.viewbands.site_average = 0;  % SETTING THIS=1, WILL SHOW THE AVERAGE OF EACH CHAN
ANAP.viewbands.tepoch       = 10;
ANAP.viewbands.site_band    = {};       % Selects between "ripple" and "spindle" (in this case)
ANAP.viewbands.site_band{1} = {'PFC'  {'hfo'   }};
ANAP.viewbands.site_band{2} = {'pl'   {'ripple'}};
ANAP.viewbands.site_band{3} = {'pl'   {'hfo'}};
ANAP.viewbands.site_band{4} = {'LC'   {'cln'}};

%=========================================================================================
% SPIKE EXTRACTION -----------------------------------------------------------------------
%=========================================================================================
ANAP.siggetspk.highpassHz   = 1000;         % DO NOT USE lower cutoff; it picks mEFP
ANAP.siggetspk.conv2sdu     = 0;            % No normalization - direct spike-count
ANAP.siggetspk.binwidth     = 0.025;        % 20ms binwidth for peristimulus histograms
ANAP.siggetspk.sdfrate      = ANAP.siggetblp.NewFs;
ANAP.siggetspk.sdfkernel    = 0.010;        % 5ms X 3 (SD) X 2 = kernel size
ANAP.siggetspk.threshold    = 3.0;          % Threshold for spike selection
ANAP.siggetspk.base_period  = 'blank';      
ANAP.siggetspk.spkselect    = 0;            % runs spike selection.

%=========================================================================================
% GENERAL PHYSIOLOGY/FMRI PARAMETES ------------------------------------------------------
%=========================================================================================
ANAP.aval       = 0.5;      % p-value for selecting time series
ANAP.rval       = 0.05;     % r (Pearson) coeff. for selecting time series
ANAP.shift      = 0;        % nlags for xcor in seconds
ANAP.clustering = 1;        % apply clustering after voxel-selection
ANAP.bonferroni = 0;        % Correction for multiple comparisons

GRPP.expinfo    = {'imaging','recording'};
GRPP.daqver     = 2.00;		% DAQ program version: 2=nl+ym; 1=nl;
GRPP.hwinfo     = '';		% hardware info
GRPP.hardch     = [1];	    % electrode numbers for ADF_CHANNELs ch1 = visual
GRPP.softch     = [];		% invalidated channels for analysis
GRPP.neusig     = 'blp';
GRPP.mrisig     = 'froiTs';

GRPP.ele.name   =  '';
GRPP.ele.roi    =  {'hele', 'hele'};
GRPP.ele.ap     = [];
GRPP.ele.ml     = [];
GRPP.ele.depth  = [];
GRPP.ele.site   = [];
GRPP.ele.color  = {[1 0 0],[0 0 0],[0 0 1],[0 1 1],[0 .5 0],[.7 .7 .6],[0 1 0],[1 0 1],[1 1 0]};

%=========================================================================================
ROI.groups      = {'All'};
ROI.model       = {'hp'};
ROI.names       = {'Brain'};
%
%=========================================================================================
% RATROIS(H.E, 29.04.2013 - 1.Rhomb,2.Mete,3.Mese,4.Diencephalon,5.Limbic,6.Neocortex)
%=========================================================================================
% ANAP.SELROI = {'Brainstem',...
%                'Vermis','IntHemCb','alCb','LatHemCb','pflCb','DCbN','PontReg','Raphe','LCreg'...
%                'MesE','SC','InfCol','PAG','SN','VTA', ...
%                'aTha','mTha','lTha','dlStriatum','vmStriatum','GP','Acc','HTh','DBMS','BNST','ZoIns',...
%                'Amy','PirFo','dHP','iHP','vHP','Sub','Ent','Olf','aIns','apIns','dgIns','Cing','RetSplen',...
%                'V1','V2','A1','A2','S1','S2','M1','M2', 'Temp','Par','OFC','FrA','mPFC'};
% ZI (Zona Incerta): An architectonically and functionally heterogeneous region that "forms a
% primal center of the diencephalon for generating direct responses (visceral, arousal,
% attention and/or posture-locomotion) to a given sensory (somatic and/or visceral) stimulus."
% Since about 10 years, it is also a target for DBS for Parkinson's disease and tremor. The
% most comprehensive review is by John Mitrofanis (Neuroscience. 2005;130(1):1-15).
%   BnST (bed nucleus of the stria terminalis): Limbic nucleus (with many subnuclei)
% interconnected with the amygdala, accumbens and hypothalamus. It is involved in behavioral
% stress response, appetitive sexual behavior and many other 'autonomic'/'homeostatic'
% behaviors and physiological activities through the regulation of the
% Hypothalamic-Pituitary-Adrenal Axis Activity.
%   WE MAY RESTORE THIS... Right now many sessions do not have the Brainstem definition!
% ANAP.SELROI = {'Vermis','IntHemCb','alCb','LatHemCb','pflCb','DCbN','PontReg','Raphe','LCreg',...
%                'MesE','SC','InfCol','PAG','HTh','SN','VTA', ...
%                'GP','Acc','vmStriatum','dlStriatum','DBMS','BNST','ZoIns','aTha','mTha','lTha',...
%                'Amy','dHP','iHP','vHP','Sub','Ent','PirFo','Olf','aIns','apIns','dgIns','Cing','RetSplen',...
%                'V1','V2','A1','A2','S1','S2','M1','M2', 'Temp','Par','OFC','FrA','mPFC'};
%   I HAVE LEFT OUT DBMS which is absent in most sessions
% ANAP.SELROI = {'Vermis' 'IntHemCb' 'LatHemCb' 'pflCb' 'DCbN' 'alCb' ...
%                'PontReg' 'ParabrachialN' 'Raphe' 'LC_CGn' 'PAG' 'SN' 'VTA' ...
%                'InfCol' 'SC' 'Tha' 'LGN' 'Pul' 'HTh' ...
% MONKEY         'BNST' 'MSDB' 'NBM' 'DS' 'VS' 'GP'  ...
%                'Amy' 'HP' 'Ent' 'PirFo' 'Ins' 'aIns' 'dACC' 'ACC' 'PCC' ...
%                'fV1' 'pfV1' 'pV1' 'V2V3' 'V4' 'V5' 'TmpVis' 'TmpAu' ...
%                'S1' 'S2' 'Motor' 'Premotor' 'RetroSp' ...
%                'TmpPol','TmpSTS' 'ParLat' 'ParIntra' ...
%                'ParPrec' 'orbPFC' 'medPFC' 'dlPFC'};
%
% METENCEPHALON (PONS + CEREBELLUM)++++++++++++++++++++++++++++++++++++++++
% 'Vermis',     'Vermis'
% 'alCb',       'Anterior cerebellar lobe'
% 'IntHemCb',   'Intermediate cerebellar hemisphere'
% 'LatHemCb',   'Lateral cerebellar hemisphere'
% 'pflCb',      'Parafloculonodular'
% 'DCbN',       'Deep cerebellar nuclei'
%
ANAP.SELROI = {'Vermis','IntHemCb','LatHemCb','pflCb','DCbN','alCb',...
               'PontReg','Raphe','LCreg','PAG','SN','VTA'...
               'InfCol','MesE','SC','HTh','mTha','lTha',...
               'GP','Acc','vmStriatum','dlStriatum','BNST','ZoIns',...
               'Amy','dHP','iHP','vHP','Sub','Ent','PirFo','Olf',...
               'aIns','apIns','dgIns','Cing','RetSplen',...
               'V1','V2','A1','A2','S1','S2','M1','M2',...
               'Temp','Par','OFC','FrA','mPFC'};

% ================================================================================================
% AM_RATS = 0; % (A. Marreiros Experiments, with incomplete ROI definitions)
% ================================================================================================
%if AM_RATS,
%  ANAP.SELROI = {'Vermis','IntHemCb','alCb','LatHemCb','pflCb','DCbN','Raphe','LCreg',...
%    'MesE','SC','InfCol','PAG','HTh','SN','VTA', ...
%    'GP','Acc','BNST','ZoIns','mTha','lTha',...
%    'Amy','dHP','iHP','vHP','Sub','Ent','PirFo','Olf','aIns','apIns','dgIns','Cing','RetSplen',...
%    'V1','V2','A1','A2','S1','S2','M1','M2', 'Temp','Par','OFC','FrA','mPFC'};
% end;
% ================================================================================================

% ROIS for checking PBR/NBR and fractions in session-functions, e.g. SESHRF, NETBLP,etc.
% ROI(Cerebellum, Pons, Basal Ganglia, Thalamus, Hipp-Formation, Sensory Cortices PFC )
% THE FOLLOWING CELL ARRAY WAS INITIALLY USED (memory/speed issuess...)

USE_INITIAL_ARRAY = 0;
if USE_INITIAL_ARRAY,
  ANAP.NETBLP.SELROI = {'DCbN','pflCb','LatHemCb','alCb','IntHemCb','Vermis',...
                      'PontReg',...
                      'dlStriatum','vmStriatum','GP','Acc',...
                      'BNST','DBMS',...
                      'aTha','mTha','lTha',...
                      'dHP','iHP','vHP','Sub','Ent',...
                      'S1','S2','A1','A2','V1','V2','M1','M2'...
                      'OFC','Fra','mPFC'};
else
  ANAP.NETBLP.SELROI = {'Brainstem','Vermis','IntHemCb','alCb','LatHemCb','pflCb','DCbN',...
                    'PontReg','Raphe','LCreg',...
                    'MesE','SC','InfCol','PAG','HTh','SN','VTA',...
                    'dlStriatum','vmStriatum','GP','Acc','BNST',...
                    'ZoIns','aTha','mTha','lTha','Amy','dHP','iHP','vHP','Sub','Ent',...
                    'PirFo','Olf','apIns','aIns','dgIns','Cing','RetSplen',...
                    'V1','V2','A1','A2','S1','S2','M1','M2'...
                    'Temp','Par','OFC','Fra','mPFC'};
end;

tmprois = {'Brain',...
           'ele_HPCa1','ele_HPCa3','ele_HPDent',...
           'ele_aTha','ele_mTha','ele_lTha',...
           'ele_S1','ele_Par'};

GRPP.grproi ='RoiGrp';
ROI.names   = paxroigroups('ROI','rat');
ROI.names   = cat(2, tmprois, ROI.names);

%=========================================================================================
% IMAGE LOADING AND ROI DEFINITION -------------------------------------------------------
%=========================================================================================
ANAP.imgload.ICROP                  = 1;		% Crop images
ANAP.imgload.INORMALIZE             = 0;
ANAP.imgload.INORMALIZE_THR         = 10;
ANAP.imgload.ISUBSTITUTE            = 0;		% Substitute initial images if no DUMMIES exist
ANAP.imgload.IDETREND               = 0;		% Detrend images
ANAP.imgload.IDETREND_AND_DENOISE   = 0;
ANAP.imgload.ITMPFLT_LOW            = 0;
ANAP.imgload.ITMPFLT_HIGH           = 0;
ANAP.imgload.IDENOISE               = 0;
ANAP.imgload.IFILTER                = 0;

%=========================================================================================
% EXTRACTION of time series from ROIs (in the Roi.mat)
%=========================================================================================
ANAP.mareats.IEXCLUDE               = {'Brain','LEFT','RIGHT'};
ANAP.mareats.ICONCAT                = 1;    % 1= concatanate ROIs before creating roiTs
ANAP.mareats.SMART_UPDATE           = 1;    % smart update checks parameters
ANAP.mareats.ISUBSTITUTE            = 0;    % DO not use this if you have dummy scans
ANAP.mareats.IHEMODELAY             = 0;    % usually 2 sec, but here is shorter
ANAP.mareats.IHEMOTAIL              = 0;    % usually 6 sec, but here also shorter
ANAP.mareats.IFFTFLT                = 0;    % Respiratory artifact removal I
ANAP.mareats.IROIFILTER             = 0;    % spatial filter with ROI masking
ANAP.mareats.IROIFILTER_KSIZE       = 0;    % Filter within ROI-boundaries
ANAP.mareats.IROIFILTER_SD          = 0;    % Size and SD.. of filters
ANAP.mareats.IFILTER3D              = 0;    % Voxel Size:  [0.75 0.75 2];
ANAP.mareats.IFILTER3D_KSIZE_mm     = [];   % [2 2 3] e.g. Kernel size in mm
ANAP.mareats.IFILTER3D_FWHM_mm      = [];   % [1 1 1.5] e.g. FWHM of Gaussian in mm
ANAP.mareats.IARTHURFLT             = [];   % = [0.11 0.13]; % UNFORTUNATELY VERY SLOW
ANAP.mareats.IGAMMA                 = 0;    % NO gamma-correction in these sessions
ANAP.mareats.IRADIUS                = 0;    % Radius (mm) for dispersion-derivative
ANAP.mareats.INOTCH                 = 0;    % Def: 4; Threshold for resp-art removal
ANAP.mareats.IRESPTHR               = 0;    % Threshold for resp-art removal
ANAP.mareats.IRESPBAND              = [];   % Resp artifact frequency range
ANAP.mareats.IDETREND               = 0;    % Remove linear trends
ANAP.mareats.ICUTOFF                = 0.0;  % No smoothing at all
ANAP.mareats.ICUTOFFHIGH            = 0.01; % Highpass filtering
ANAP.mareats.IREMBRAINMEAN          = 1;    % Remove brain's average (phys-artifacts)
ANAP.mareats.IDETREND               = 0;    % Remove linear trends
ANAP.mareats.ITOSDU                 = {'zerobase','blank'};             % Normalization
ANAP.mareats.IRESAMPLE              = 0;    % Resample scans with DX = 1sec
%================================================================================================
ANAP.mareats.IMIMGPRO               = 1;    % Minimal Image processing
ANAP.mareats.IFILTER                = 1;    % 1=to spatially filter; 0=no filter at all
ANAP.mareats.IFILTER_KSIZE          = 3;    % Kernel size (previously 3)
ANAP.mareats.IFILTER_SD             = 1.25; % Kernel SD (90% of flt in kernel) (previously 1.5)
%================================================================================================
ANAP.froiTs.mareats               = ANAP.mareats;
ANAP.froiTs.mareats.IRESAMPLE     = 1;      % Resample scans with DX = 1sec
ANAP.froiTs.mareats.IREMBRAINMEAN = 1;      % Remove brain's average (phys artifacts)
ANAP.froiTs.mareats.IFILTER       = 1;      % 1=to spatially filter; 0=no filter at all
ANAP.froiTs.mareats.IFILTER_KSIZE = 3;      % Default: 5, Kernel size (previously 3)
ANAP.froiTs.mareats.IFILTER_SD    = 1.5;    % Default: 2, Kernel SD (90% of flt in kernel)
ANAP.froiTs.mareats.ICUTOFFHIGH   = 0.010;  % remove very slow oscillations
ANAP.froiTs.mareats.ICUTOFF       = 0.450;  % 0.5 is Nyquist..
ANAP.froiTs.mareats.ITOSDU        = {'zerobase','blank'};   % Normalization
ANAP.froiTs.mareats.IRESPTHR      = 0;      % THESE TWO should be defined in the session-file
ANAP.froiTs.mareats.IRESPBAND     = [];     % Respiration-Frequency-Range for art-removal
%=========================================================================================
% GETTRIAL - PRE-PROCESSING
%=========================================================================================
ANAP.gettrial.status        =   1;              % IsTrial
ANAP.gettrial.Average       =   1;              % Do not average tblp, but concat
ANAP.gettrial.trial2obsp    =   0;              % Obsp with multiple ripple-events
ANAP.gettrial.Xmethod       =   'none';         % No transformation to SD units
ANAP.gettrial.Xepoch        =   'prestim';      % Argument (Epoch) to xfrom in gettrial
ANAP.gettrial.sort          =   'trial';        % sorting with SIGSORT, can be 'none|stimulus|trial
ANAP.gettrial.HemoDelay     =   1;              % Irrelevant for "spont" groups
ANAP.gettrial.HemoTail      =   4;              % Irrelevant for "spont" groups
ANAP.gettrial.RefChan       =   2;              % Reference channel (for DIFF/not used here)
ANAP.gettrial.PreT          = -20;              % Beginning of trial window w/ respect to event 
ANAP.gettrial.PostT         = +20;              % End of trial window w/ respect to event
ANAP.gettrial.IBRAINMEAN    =   0;              % [1 2] Remove evt-uncorr noise; 3 PCA..
ANAP.gettrial.ICUTOFF       =   0.0;            % Smoothing
ANAP.gettrial.ICUTOFFHIGH   =   0.0;            % Removing lowfreq fluctuations

% ------------------------------------------------------------------------------------------
% FILTERING(ATTENTION TO ANAP.GETTRIAL.ICUTOFF & ANAP.GETTRIAL.ICUTOFFHIGH)
% Filtering is applied on the entire time series, before conversion to perievent trials. It
% therefore appears to be "redundant" to the mareats.ICUTOFF... but the reasons for having this
% step is: (a) Trying filters is easier if we do not extract the entire roiTs again and
% again...(b) roiTs can be used for other analyses (connectivity) that require different
% temporal filtering profiles...
% ATTENTION HemoDelay/HemoTail is irrelevant for spont activity data!!!
% ------------------------------------------------------------------------------------------
GRPP.anap.gettrial = ANAP.gettrial;    % Generalize..
if ANAP.gettrial.status,
  GRPP.grpsigs={'plblp','plroiTs','plfroiTs'};
else
  GRPP.grpsigs={'blp','roiTs','froiTs'};
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EVENT( DETECTION & IDENTIFICATION)
% ==========================================================================================
%
% CLUSTERING Cln (N=3): PEAKS 35, 65, 145, 275 
ANAP.getevent.common.frange = [ 5 320];       % Frequency range used for spec/TF displays
ANAP.getevent.common.pxxwin = [-0.05  0.05];  % Window used to compute power spectra
ANAP.getevent.common.tfwin  = [-0.50  0.50];  % Window used to compute wavelets
ANAP.getevent.common.muawin = [-2.00  2.00];  % Window used to see perievent raw responses
ANAP.getevent.common.clnwin = [-3.00  3.00];  % Window used to see perievent raw responses
ANAP.getevent.common.evtwin = [-4.00  4.00];  % Default NET-BLP window
ANAP.getevent.common.dspwin = [-5.00  5.00];  % Display-window for neural signals
ANAP.getevent.common.netwin = [-15.0 15.00];  % Display-window for neural signals
ANAP.getevent.common.mriwin = [-20.0 20.0];   % Display-window for fMRI signals

% ------------------------------------------------------------------------------------------
% HIPPOCAMPUS(Events detected & identified in the Pontine Regions, e.g. parabrachial nucleus)
% ------------------------------------------------------------------------------------------
% UPDATED(NKL/YM 09.07.2019)
% ==========================================================================================
% CLN       [   0.0   325.0] 'cln'     'LFP',   0.0};
% PGO       [   1.0    15.0] 'pgo'     'LFP',   6.5};
% DELTA     [   0.3     3.8] 'delta'   'LFP',   1.5};
% THETA     [   4.0    10.5] 'theta'   'LFP',   3.0};
% SIGMA     [  11.0    20.0] 'sigma'   'LFP',  10.5};
% GAMMA     [  25.0    88.0] 'gamma'   'LFP',  30.0};
% HGAMMA    [  90.0   135.0] 'hgamma'  'LFP',  30.0};
% RIPPLE    [ 140.0   250.0] 'ripple'  'LFP',  60.0};
% MEFP      [ 250.0   600.0] 'mefp'    'MUA', 100.0};
% MUA       [ 650.0  1800.0] 'mua'     'MUA', 200.0};
% ==========================================================================================
ANAP.getevent.pl.maxpeak    = 8;        % Peaks greater than maxpeak are noise
ANAP.getevent.pl.nnmfthr    = 3.0;      % Event-Contrast used by evtcontrast()
ANAP.getevent.pl.bname      = {'pgo','gamma','ripple'};
ANAP.getevent.pl.brange     = {};

ANAP.getevent.pl.pgo.brange    = [];        % Get range from BLP
ANAP.getevent.pl.pgo.dtlow     = 0;         % lowpass cutoff for envelop
ANAP.getevent.pl.pgo.dtthr     = 3.5;       % Peak-threshold
ANAP.getevent.pl.pgo.gap       = 0.100;     % Gap between this type of events

ANAP.getevent.pl.gamma.brange  = [];
ANAP.getevent.pl.gamma.dtlow   = 0;         % lowpass cutoff for envelop
ANAP.getevent.pl.gamma.dtthr   = 3.5;       % Peak-threshold
ANAP.getevent.pl.gamma.gap     = 0.075;     % Gap between this type of events

ANAP.getevent.pl.hgamma.brange = [];
ANAP.getevent.pl.hgamma.dtlow  = 0;         % lowpass cutoff for envelop
ANAP.getevent.pl.hgamma.dtthr  = 3.5;       % Peak-threshold
ANAP.getevent.pl.hgamma.gap    = 0.075;     % Gap between this type of events

ANAP.getevent.pl.ripple.brange = [];        % Get range from BLP
ANAP.getevent.pl.ripple.dtlow  = 0;         % lowpass cutoff for envelop
ANAP.getevent.pl.ripple.dtthr  = 3.5;       % Peak-threshold
ANAP.getevent.pl.ripple.gap    = 0.050;     % Gap between this type of events

ANAP.getevent.hp = ANAP.getevent.pl;

% ------------------------------------------------------------------------------------------
% LC(Events detected & identified in the Locus Coeruleus nucleus)
% ------------------------------------------------------------------------------------------
ANAP.getevent.lc.maxpeak       = 8;
ANAP.getevent.lc.nnmfthr       = 3;
ANAP.getevent.lc.bname         = {'F20Hz','F50Hz','F100Hz'};
ANAP.getevent.lc.brange        = {};

ANAP.getevent.lc.F20Hz.brange  = [10 30];
ANAP.getevent.lc.F20Hz.dtlow   = 2;        % lowpass cutoff for envelop
ANAP.getevent.lc.F20Hz.dtthr   = 2.5;       % Peaktothreshold
ANAP.getevent.lc.F20Hz.dtbase  = 1.0;       % Peaktothreshold
ANAP.getevent.lc.F20Hz.gap     = 0;       % Gap between this type of events

ANAP.getevent.lc.F50Hz.brange  = [40 60];
ANAP.getevent.lc.F50Hz.dtlow   = 2;        % lowpass cutoff for envelop
ANAP.getevent.lc.F50Hz.dtthr   = 2.5;       % Peaktothreshold
ANAP.getevent.lc.F50Hz.dtbase  = 1.0;       % Peaktothreshold
ANAP.getevent.lc.F50Hz.gap     = 0;       % Gap between this type of events

ANAP.getevent.lc.F100Hz.brange = [90 110];
ANAP.getevent.lc.F100Hz.dtlow  = 2;        % lowpass cutoff for envelop
ANAP.getevent.lc.F100Hz.dtthr  = 2.5;       % Peaktothreshold
ANAP.getevent.lc.F100Hz.dtbase = 1.0;       % Peaktothreshold
ANAP.getevent.lc.F100Hz.gap    = 0;       % Gap between this type of events

% ------------------------------------------------------------------------------------------
% PONS(Events detected & identified in the Pontine Regions, e.g. parabrachial nucleus)
% ------------------------------------------------------------------------------------------
ANAP.getevent.pbn.maxpeak       = 8;
ANAP.getevent.pbn.nnmfthr       = 3.5;
ANAP.getevent.pbn.bname         = {'swr','pgo','swrpgo'};

ANAP.getevent.pbn.swr.brange    = [];       % Get range from BLP
ANAP.getevent.pbn.swr.dtlow     = 0;        % lowpass cutoff for envelop
ANAP.getevent.pbn.swr.dtthr     = 4.5;      % Peak-threshold
ANAP.getevent.pbn.swr.dtbase    = 1.0;      % Peak-threshold
ANAP.getevent.pbn.swr.gap       = 0.1;      % Gap between this type of events

ANAP.getevent.pbn.pgo.brange    = [2 15];
ANAP.getevent.pbn.pgo.dtlow     = 0;        % lowpass cutoff for envelop
ANAP.getevent.pbn.pgo.dtthr     = 4.0;      % Detection threshold
ANAP.getevent.pbn.pgo.dtbase    = 1.0;      % Below this activity is considered random
ANAP.getevent.pbn.pgo.gap       = 0.2;      % Minimum Interevent time 

ANAP.getevent.pbn.swrpgo.brange = [];       % Get range from BLP
ANAP.getevent.pbn.swrpgo.dtlow  = 0;        % lowpass cutoff for envelop
ANAP.getevent.pbn.swrpgo.dtthr  = 4.0;      % Peak-threshold
ANAP.getevent.pbn.swrpgo.dtbase = 1.0;      % Below this activity is considered random
ANAP.getevent.pbn.swrpgo.gap    = 0.2;      % Gap between this type of events

% ------------------------------------------------------------------------------------------
% LGN(Events detected & identified in the Lateral Geniculate Nucleus [LGN])
% ------------------------------------------------------------------------------------------
ANAP.getevent.lgn.maxpeak = 8;
ANAP.getevent.lgn.nnmfthr = 3.5;       
ANAP.getevent.lgn.bname   = {'theta', 'spindle', 'gamma', 'hfo', 'mua'};

ANAP.getevent.lgn.theta.brange   = [];          % THETA-RANGE
ANAP.getevent.lgn.theta.dtlow    = 0;           % No lowpass filtering
ANAP.getevent.lgn.theta.dtthr    = 3.5;         % Detection threshold
ANAP.getevent.lgn.theta.dtbase   = 1;           % Below this activity is random
ANAP.getevent.lgn.theta.gap      = 0.10;        % Min Inter-Event time

ANAP.getevent.lgn.spindle.brange = [];          % SPINDLE-range
ANAP.getevent.lgn.spindle.dtlow  = 0;           % No lowpass filtering
ANAP.getevent.lgn.spindle.dtthr  = 3.5;         % Detection threshold
ANAP.getevent.lgn.spindle.dtbase = 1;           % Below this activity is random
ANAP.getevent.lgn.spindle.gap    = 0.10;        % Min Inter-Event time

ANAP.getevent.lgn.gamma.brange   = [];          % GAMMA-range
ANAP.getevent.lgn.gamma.dtlow    = 0;           % No lowpass filtering
ANAP.getevent.lgn.gamma.dtthr    = 4;           % GAMMA-detection threshold
ANAP.getevent.lgn.gamma.dtbase   = 1;           % Below this activity is random
ANAP.getevent.lgn.gamma.gap      = 0.10;        % Min Inter-Event time

ANAP.getevent.lgn.hfo.brange     = [];          % HFO-range
ANAP.getevent.lgn.hfo.dtlow      = 0;           % No lowpass filtering
ANAP.getevent.lgn.hfo.dtthr      = 3.5;         % HFO-detection threshold
ANAP.getevent.lgn.hfo.dtbase     = 1;           % Below this activity is random
ANAP.getevent.lgn.hfo.gap        = 0.10;        % Min Inter-Event time

ANAP.getevent.lgn.mua.brange     = [];          % MUA-range
ANAP.getevent.lgn.mua.dtlow      = 0;           % No lowpass filtering
ANAP.getevent.lgn.mua.dtthr      = 3.5;         % HFO-detection threshold
ANAP.getevent.lgn.mua.dtbase     = 1;           % Below this activity is random
ANAP.getevent.lgn.mua.gap        = 0.10;        % Min Inter-Event time

% ------------------------------------------------------------------------------------------
% UPDATE(Set parameters for all electrodes sites belonging to the same structure)
% ------------------------------------------------------------------------------------------
ANAP.getevent.hp    = ANAP.getevent.pl;
ANAP.getevent.cx    = ANAP.getevent.lgn;
ANAP.getevent.st    = ANAP.getevent.lgn;
ANAP.getevent.at    = ANAP.getevent.lgn;
ANAP.getevent.pul   = ANAP.getevent.lgn;
ANAP.getevent.eeg   = ANAP.getevent.lgn;
ANAP.getevent.NOS   = ANAP.getevent.lgn;
ANAP.getevent.cer   = ANAP.getevent.lgn;
ANAP.getevent.po    = ANAP.getevent.pbn;

% ==========================================================================================
% SEVT for getevent_sevt
% ==========================================================================================
ANAP.sevt.sigtype     = 'blp';
ANAP.sevt.evtsites    = {'pl'};
ANAP.sevt.frange      = [1 300];      % Frequency range used for spec/TF displays
ANAP.sevt.tfwin       = [-1.5 1.5];   % Start-window for TF-plot
ANAP.sevt.evtwin      = [-10 10];     % Used by getevent/dspevent
ANAP.sevt.pxxwin      = [-0.1 0.1];   % Window used to compute pmtm
ANAP.sevt.dspwin      = [-0.5 0.5];   % Final display window for TF reps
ANAP.sevt.mriwin      = [ANAP.gettrial.PreT ANAP.gettrial.PostT];
ANAP.sevt.ele.events  = {'spindle' 'gamma' 'ripple'};
ANAP.sevt.pl          = ANAP.sevt.ele;
ANAP.sevt.pl.events   = {'spindle', 'sigma', 'gamma', 'hgamma', 'ripple'};
ANAP.sevt.hp          = ANAP.sevt.pl;
ANAP.sevt.sr          = ANAP.sevt.pl;

% ==========================================================================================
% USEVT for getevent_usevt
% ==========================================================================================
ANAP.usevt.sigtype          = 'blp';
ANAP.usevt.evtsites         = {'pl'};
ANAP.usevt.frange           = [1 300];      % Frequency range used for spec/TF displays
ANAP.usevt.tfwin            = [-1.5 1.5];   % Start-window for TF-plot
ANAP.usevt.evtwin           = [-10 10];     % Used by getevent/dspevent
ANAP.usevt.pxxwin           = [-0.1 0.1];   % Window used to compute pmtm
ANAP.usevt.dspwin           = [-0.5 0.5];   % Final display window for TF reps
ANAP.usevt.mriwin           = [ANAP.gettrial.PreT ANAP.gettrial.PostT];
% NOT USED..
ANAP.usevt.ele.clust_type   = 'peak';       % method: peak|fcgng|gng|nnmf
ANAP.usevt.ele.peak_clusters = {[0 20],[25 60], [65 140], [145 240]};
% INSTEAD WE USE...
ANAP.usevt.ele.clust_type   = 'tfnnmf';       % method: peak|fcgng|gng|nnmf
ANAP.usevt.ele.peak_clusters = {};

ANAP.usevt.ele.nc           = 4.5;
ANAP.usevt.ele.dtfilter     = {[5 300] 'bandpass'};
ANAP.usevt.ele.dtthr        = 4;
ANAP.usevt.ele.gap          = 0.05;
ANAP.usevt.ele.minevtnum    = 5;
ANAP.usevt.ele.evtpeak      = 15;
ANAP.usevt.ele.nnmfthr      = 2;
ANAP.usevt.pl               = ANAP.usevt.ele;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MRIEVENT( DETECTION & IDENTIFICATION )
% ==========================================================================================
% Calculating contrasts (not used here...)
% con = {};
% for N=1:NREG,
%   con{end+1} = zeros(1,NREG+1); con{end}(N) = 1;
%   con{end+1} = zeros(1,NREG+1); con{end}(N) = -1;
% end;
% ==========================================================================================
% PCA(the following definitions should be tried in Ruhe.. after the Tokyo trip)
% ==========================================================================================
% ANAP.mrigetevent.pl.pcawins      = {[-18 -12], [-1 3], [4 8], [12 18]};
% ANAP.mrigetevent.pl.contname     = {'PC1','PC2','PC3','PC4','PC5'};
% ANAP.mrigetevent.pl.nclust       = length(ANAP.mrigetevent.pl.contname);
% ANAP.mrigetevent.pl.conts        = {};
% ANAP.mrigetevent.pl.conts{end+1} = [ 1  0  0  0  0  0]; 
% ANAP.mrigetevent.pl.conts{end+1} = [ 0  1  0  0  0  0]; 
% ANAP.mrigetevent.pl.conts{end+1} = [ 0  0  1  0  0  0];
% ANAP.mrigetevent.pl.conts{end+1} = [ 0  0  0  1  0  0];
% ANAP.mrigetevent.pl.conts{end+1} = [ 0  0  0  0  1  0];

ANAP.mrigetevent.pl.seslist      = {'rat','hp','st1'};
ANAP.mrigetevent.pl.sites        = {'pl','st'};
ANAP.mrigetevent.pl.bands        = {'spindle', 'sigma',  'gamma',  'hgamma', 'ripple','mua'};
ANAP.mrigetevent.pl.msaevt       = {'mean','pc1'};
ANAP.mrigetevent.pl.bname        = {'spindle', 'sigma',  'gamma',  'hgamma', 'ripple'};

% NOTE Spatial PCA is computed in multiple windows, which are then concatenated to have a
% better representation of the peri-event MSA
ANAP.mrigetevent.pl.mriwin       = [-20 20];
ANAP.mrigetevent.pl.xcorwin      = [-10 10];
ANAP.mrigetevent.pl.xcorbinw     = 0.5;
ANAP.mrigetevent.pl.thr          = 5;
ANAP.mrigetevent.pl.gap          = 0.1;

ANAP.mrigetevent.pl.pcawins      = {[-20 -12], [-2 5], [12 20]};
ANAP.mrigetevent.pl.pcawins      = {[1:25],[26:50],[56:80]};


ANAP.mrigetevent.pl.contname     = {'ripMSA','pgoMSA','PBR','NBR'};
ANAP.mrigetevent.pl.nclust       = length(ANAP.mrigetevent.pl.contname);
ANAP.mrigetevent.pl.conts        = {};
ANAP.mrigetevent.pl.conts{end+1} = [ 1  0  0]; 
ANAP.mrigetevent.pl.conts{end+1} = [-1  0  0]; 
ANAP.mrigetevent.pl.conts{end+1} = [ 0  1  0]; 
ANAP.mrigetevent.pl.conts{end+1} = [ 0 -1  0]; 
% ANAP.mrigetevent.pl.conts{end+1} = [ 0  0  1  0];
% ANAP.mrigetevent.pl.conts{end+1} = [ 0  0 -1  0];

ANAP.mrigetevent.st             = ANAP.mrigetevent.pl;
ANAP.mrigetevent.vcx             = ANAP.mrigetevent.st;
ANAP.mrigetevent.vcx.seslist     = {'monkey','spont','cx1'};
ANAP.mrigetevent.vcx.sites       = {'hp','st','vcx'};

% ANAP.SELROI = {'Vermis','IntHemCb','alCb','LatHemCb','pflCb','DCbN','PontReg','Raphe','LCreg',...
%                'MesE','SC','InfCol','PAG','HTh','SN','VTA', ...
%                'GP','Acc','vmStriatum','dlStriatum','DBMS','BNST','ZoIns','aTha','mTha','lTha',...
%                'Amy','dHP','iHP','vHP','Sub','Ent','PirFo','Olf','aIns','apIns','dgIns','Cing','RetSplen',...
%                'V1','V2','A1','A2','S1','S2','M1','M2', 'Temp','Par','OFC','FrA','mPFC'};

% ==========================================================================================
% STRUCTURES(Groups of Used Electrodes-Sites each belonging to a Brain Structure)
% ==========================================================================================
ANAP.structure.sCx    = {'vcx','v1','s1','m1','a1'};
ANAP.structure.aCx    = {'cx','ax','v2','s2','m2','a2'};
ANAP.structure.PFC    = {'OFC','Fra','pfc','pfc0','mPFC'};
ANAP.structure.Cx     = cat(2, ANAP.structure.sCx, ANAP.structure.aCx,ANAP.structure.PFC);

ANAP.structure.sTha   = {'lgn','st','lt','th','lTha'};
ANAP.structure.aTha   = {'mt','at','aTha','mTha'};
ANAP.structure.Tha    = cat(2, ANAP.structure.sTha, ANAP.structure.aTha);

ANAP.structure.WM     = {'wm','eeg'};
ANAP.structure.Hipp   = {'pl','hp','sr','dg','ca1','ca3','dHP','iHP','vHP','Sub','Ent'};
ANAP.structure.BG     = {'dlStriatum','vmStriatum','GP','Acc'};
ANAP.structure.StMsDb = {'BNST','DBMS'};
ANAP.structure.Cer    = {'cer','Vermis','alCb','IntHemCb','LatHemCb','pflCb','DCbN'};
ANAP.structure.LC     = {'lc','LCreg'};
ANAP.structure.Pons   = {'PontReg','PBn','po'};

ANAP.structure.Brain  = cat(2,ANAP.structure.Cx,ANAP.structure.Tha,ANAP.structure.Hipp);
ANAP.structure.Brain  = cat(2,ANAP.structure.Brain, ANAP.structure.WM, ANAP.structure.Hipp,...
                            ANAP.structure.BG, ANAP.structure.StMsDb,ANAP.structure.Cer,...
                            ANAP.structure.LC, ANAP.structure.Pons);

ANAP.recsites = {'pl', 'sr', 'hp',...
                 'th','st', 'at','mt',...
                 'cx','s1','m1','v1','a1',...
                 'ax','v2','a2','s2','m2','pfc','pfc0',...
                 'lc','cer','wm','eeg'};

ANAP.roisites  = {'dHP', 'dHP', 'dHP',...
                 'lTha','lTha','lTha','lTha',...
                 'S1','S1','M1','V1','A1',...
                 'S2','S2','M2','V2','A2','mPFC','Par',...
                 'LCreg','Vermis','S1','S1'};

ANAP.elerois  = {'dHP', 'ele_HPDent', 'ele_HPCa3',...
                 'ele_aTha','ele_mTha','ele_lTha','ele_lTha',...
                 'S1','ele_S1','M1','V1','A1',...
                 'S2','S2','M2','V2','A2','mPFC','ele_Par',...
                 'LCreg','Vermis','S1','S1'};

ANAP.excludesites = {'NOS','NaN','NA','eeg','cc','nolc','wm'};

% NKL 15.04.2019
% These are the valid structures that we recorded from in the NET-fMRI project
ANAP.CurSites.struct  = {'Hipp', 'Thal', 'LGN', 'Cx', 'Cer', 'LC', 'VLC'};
ANAP.CurSites.elesite = {'pl',   'th',   'lgn', 'cx', 'cer', 'lc', 'vlc'};

% These are used by many functions for population-analysis and display
% Alert animal, LGN-CX & FAST PROCESSING were not included at this time
% NKL 15.04.2019
% RAT{end+1} = {'ratqn1'   'chlor' 'sli9' 'hp' 'th' 'cxt' 'lc1net1' 'des1' 'Q11'};
% RAT{end+1} = {'ratrx1'   'chlor' 'sli9' 'hp' 'th' 'cxt' 'lc1net1' 'des1' 'Q11'};
% RAT{end+1} = {'rattq1'   'remif' 'sli9' 'hp' 'th' 'cxt' 'lc1net1' 'des1' 'Q11'};
% RAT{end+1} = {'ratoo2'   'remif' 'sli9' 'hp' 'th' 'cxt' 'lc1net0' 'des1' 'Q11'};
% RAT{end+1} = {'ratto1'   'remif' 'sli9' 'hp' 'th' 'cxt' 'lc1net0' 'des1' 'Q11'};
% RAT{end+1} = {'ratub1'   'remif' 'sli9' 'hp' 'th' 'cxt' 'lc1net0' 'des1' 'Q11'};
% RAT{end+1} = {'rattb1'   'remif' 'sli9' 'hp' 'th' 'cxt' 'lc1net1' 'des1' 'Q11'};
% RAT{end+1} = {'ratrn1'   'chlor' 'sli9' 'hp' 'th' 'cxt' 'lc1net1' 'des1' 'Q11'};
% RAT{end+1} = {'ratrt1'   'chlor' 'sli9' 'hp' 'th' 'cxt' 'lc1net1' 'des1' 'Q11'};
% RAT{end+1} = {'ratsp1'   'chlor' 'sli9' 'hp' 'th' 'cxt' 'lc1net1' 'des1' 'Q11'};

% -------------------------------------------------------------------------------------------
% RAN on 07.08.2019 - Huge difference between Chloralose & Remifentanyl
% The second yields definitely robust and consistent results!
% -------------------------------------------------------------------------------------------
% getmevent('lcremi','spo','dspall','str','lc');
% getmevent('lchlor','spo','dspall','str','lc');
% -------------------------------------------------------------------------------------------
ANAP.SesGroups.netfmri = {'rat', 'evt',  'remif'};  % All sessions in the project of NET-fMRI
ANAP.SesGroups.debug   = {'rat', 'err',  'remif'};    % Sessions with Pons & LGN Recordings
ANAP.SesGroups.lcnet   = {'rat', 'sli9',  'lc1net1'};  % All sessions in the project of NET-fMRI
ANAP.SesGroups.lcremi  = {'rat', 'lc1net1', 'remif'};  % All sessions in the project of NET-fMRI
ANAP.SesGroups.lchlor  = {'rat', 'lc1net1', 'chlor'};  % All sessions in the project of NET-fMRI


%=========================================================================================
% GLM ANALYSIS
%=========================================================================================
GRPP.anap.HemoDelay = 1;                % Note used here...
GRPP.anap.HemoTail =  3;                % Note used here...

GRPP.anap.glm.IARESTIMATION  = 0;       % AR estimation
GRPP.anap.glm.ISATTERWAITH   = 0;       % Satterwaith
GRPP.anap.glm.ICONVWITHGAMMA = 0;       % No convolution is need (done by mkmodel)

GRPP.anap.glm.glmpreproc = '';          % GRPP.anap.glm.glmpreproc = 'usrtransforms';
GRPP.anap.glm.doplot     = 0;

GRPP.glmgrppval     = 0.05;                 % for SESGLMANA
GRPP.glmgrpmode     = 'mean';               % for SESGLMANA (and, or, bin...)
GRPP.glmana         = [];                   % GLM analysis details
GRPP.glmsigs        = '';                   % Standard input arg for all functions
GRPP.glmseeds       = {'hp','at','pfc'};    % Used in PRMKMODEL
GRPP.glmele         = {'elepl','eleth'};    % Used in PRMKMODEL

%if nargin>0,
if 0,
  GRPP.glmdesign  = ARGS.glmdesign;   % Default in rpgetpars.m and ses-def in descr. file

  tmp = fieldnames(ANAP.getevent);
  for K=1:length(tmp)
    GRPP.glmstruct{K}{1} = tmp{K};
    GRPP.glmstruct{K}{2} = {sprintf('%sroiTs',tmp{K}),sprintf('%sfroiTs',tmp{K})};
  end;
  
  GLM_MODELS = {};
  for K=1:length(GRPP.glmstruct),
    V = GRPP.glmstruct{K}{1};
    ANAP.getevent.(V).contrasts = {'fVal'};    % First item... continues below..
    for N=1:length(ANAP.getevent.(V).bname),
      ANAP.getevent.(V).contrasts{end+1} = ANAP.getevent.(V).bname{N};
      ANAP.getevent.(V).contrasts{end+1} = strcat(ANAP.getevent.(V).bname{N},'-');
      GLM_MODELS{K}{N} = sprintf('%s/%s_%s.mat[%d]', 'spont', GRPP.glmdesign, V, N);
    end;
  end;
  
  %=========================================================================================
  % GLM ANALYSIS
  %=========================================================================================
  GROUPGLM = 'before glm';
  %  GROUPGLM = 'after glm';
  switch lower(GRPP.glmdesign),
   case 'siggamrip',
    DNO = 1;
    for K=1:length(GRPP.glmstruct),
      SigName = GRPP.glmstruct{K}{2};
      for S=1:length(SigName),
        GRPP.glm.(SigName{S}).groupglm  = GROUPGLM;
        GRPP.glm.(SigName{S}).glmana = {};
        evt = ANAP.getevent.(GRPP.glmstruct{K}{1});
        GRPP.glm.(SigName{S}).glmana{DNO}.mdlsct = GLM_MODELS{K};
        
        clear con tst; con{1} = []; tst{1}='f';
        for N=1:length(evt.bname),
          tst{end+1} = 't'; tst{end+1} = 't';
          con{end+1}=zeros(1,length(evt.bname)+1); con{end}(N) = 1;
          con{end+1}=zeros(1,length(evt.bname)+1); con{end}(N) = -1;
        end;
        GRPP.glm.(SigName{S}).glmconts = {};
        for N=1:length(con),
          GRPP.glm.(SigName{S}).glmconts{end+1}=...
              setglmconts(tst{N}, evt.contrasts{N},con{N},'pVal',1.0,'WhichDesign',DNO);
        end;
      end;
    end;
    
   case 'seed',
    DNO = 1;
    GRPP.glm.glmana = {};
    GRPP.glm.groupglm = 'after glm';
    GRPP.glm.glmana{DNO}.mdlsct = {'wmal','wmar','wmpl','wmpr'};
    GRPP.glm.glmconts = {};
    GRPP.glm.glmconts{end+1}=setglmconts('f','fSeed',  [], 'pVal',0.1,'WhichDesign',DNO);
    GRPP.glm.glmconts{end+1}=setglmconts('t','wmal', [ 1  0  0  0  0],'pVal',1.0,'WhichDesign',DNO);
    GRPP.glm.glmconts{end+1}=setglmconts('t','wmar', [ 0  1  0  0  0],'pVal',1.0,'WhichDesign',DNO);
    GRPP.glm.glmconts{end+1}=setglmconts('t','wmpl', [ 0  0  1  0  0],'pVal',1.0,'WhichDesign',DNO);
    GRPP.glm.glmconts{end+1}=setglmconts('t','wmpr', [ 0  0  0  1  0],'pVal',1.0,'WhichDesign',DNO);
    GRPP.glm.froiTs = GRPP.glm;
    GRPP.glmana     = GRPP.glm.glmana;
    GRPP.glmconts   = GRPP.glm.glmconts;
    
   otherwise,
    fprintf('rpgetpars_monkey: unknown GLMDESIGN\n'); keyboard
  end;
end;

%=========================================================================================
% Rat-Data-Atlas Registration (see also paxgetrois.m)
%=========================================================================================
%ANAP.tkcca.AllRois      = {'HF','HippMonSynP', 'HippMonSynN', 'HippPolSyn'};
%ANAP.tkcca.AllSelect    = {'all','ripple','gamma'};
ANAP.tkcca.mrisig       = 'froiTs';         % And roiTs/froiTs for fMRI signal
ANAP.tkcca.neusig       = 'blp';            % Use BLP for neural signal
ANAP.tkcca.rois         = 'HF';             % Compute maps for entire brain
ANAP.tkcca.chans        = [];               % Group each type, e.g. pl, sr, cx...
ANAP.tkcca.bands        = [2:6];            % Relevenat BLP-Bands: Delta,Spindle,Gamma,Ripple
ANAP.tkcca.maxlagsec    = 20;               % Lags
ANAP.tkcca.resamplehz   = 1;                % Resample at the freq of fMRI signal
ANAP.tkcca.thr          = 1;                % Threshold for RES.fmri
ANAP.tkcca.addsdf       = 0;                % No need to use SDF        

ANAP.tkcca.ppMode       = 'chan';           % BLPs for each Ch. "blp" Chans for each BLP
ANAP.tkcca.ppNorm       = 'zscore';         % tosdu, zscore, dispderiv
ANAP.tkcca.ppRoiLimit   = 0;                % Use limited portion of ROI
ANAP.tkcca.ppDspDeriv   = 0;                % Dispersion derivative w/ radius=5
ANAP.tkcca.ppFilt       = [0 0];            % [0 0.3] is used for rpgettrial...
ANAP.tkcca.ppSigSelect  = 'all';            % ALL, NOISE, RIPPLE, GAMMA, SPINDLE
ANAP.tkcca.ppTrialWin   = [-5 10];          % Window around ONSET to consider for tkCCA

%=========================================================================================
% Rat-Data-Atlas Registration (see also paxgetrois.m)
%=========================================================================================
GRPP.anap.mratatlas2ana.atlas                   = 'gskrat97';  % Paxinos
GRPP.anap.mratatlas2ana.atlas                   = 'rat2013';   % Henry 2013
GRPP.anap.mratatlas2ana.permute                 = [1 3 2];
GRPP.anap.mratatlas2ana.flipdim                 = [3];
GRPP.anap.mratatlas2ana.spm_coreg.cost_fun      = 'ecc';

GRPP.anap.mana2brain.permute                    = [1 3 2];
GRPP.anap.mana2brain.flipdim                    = [3];
GRPP.anap.mana2brain.brain                      = '16t';
GRPP.anap.mana2brain.resolution                 = 'high';  % high(0.1mm),0.2mm,0.25mm,low(0.5mm)
GRPP.anap.mana2brain.use_epi                    = 1;

%=========================================================================================
% Parameters used by MVIEW
%=========================================================================================
ANAP.mview.viewmode         = 'lightbox-trans';
ANAP.mview.viewpage         = 1;
ANAP.mview.anascale         = [0  5000  1.3];
ANAP.mview.roi              = 'All';
ANAP.mview.datname          = 'response';
ANAP.mview.alpha            = 0.0001;
ANAP.mview.statistics       = 'glm';
ANAP.mview.glmana.model     = 1;
ANAP.mview.glmana.minmax    = [-3 3];
ANAP.mview.glmana.trial     = 1;
ANAP.mview.cluster          = 0;
ANAP.mview.clusterfunc      = 'mcluster';
ANAP.mview.negcorr          = 1;
ANAP.mview.mcluster3.B      = 3;
ANAP.mview.mcluster3.cutoff =  round((2*(ANAP.mview.mcluster3.B-1)+1)^3*0.3);
ANAP.mview.slices           = [];

%=========================================================================================
% Parameters used by SHOWSPONT
%=========================================================================================
ANAP.showmap.STDERROR   = 1;             % If set uses errorbar otherwise CI
ANAP.showmap.CIVAL      = [1 99];        % low and high confidence interval
ANAP.showmap.BSTRP      = 200;
ANAP.showmap.TRIAL      = [];
ANAP.showmap.FUNCSCALE  = [0 10 1.5];
ANAP.showmap.ANASCALE   = [0 10000 1.2];
ANAP.showmap.DRAW_ROI   = {};
ANAP.showmap.COL_FACE   = [];            % shading color for CI plots
ANAP.showmap.COL_LINE   = 'rgbmckyrgbmck';
ANAP.showmap.MASKNAME   = {'fVal', 'fVal', 'fVal','fVal'};
ANAP.showmap.MODELNAME  = {'fVal', 'fVal', 'fVal','fVal'};
ANAP.showmap.MSKP       = [1  1  1  1];
ANAP.showmap.MDLP       = [1e-4 1e-4 1e-4 1e-4];

if nargin > 0,
  % -------------------------------------------------------------------------------------------------------
  % FLICKER GROUPS - CONTROL FOR BOLD QUALITY AND AREA REGISTRATION
  % -------------------------------------------------------------------------------------------------------
  FLICK.grproi            = GRPP.grproi;
  FLICK.anap.globaldir    = ANAP.project.flicker_dir;
  FLICK.anap.allsesmodel  = sprintf('%s/allsesmodel.mat',FLICK.anap.globaldir);
  % -------------------------------------------------------------------------------------------------------
  % MAREATS - PARAMETERS: DO NOT Change! IFILTER, CUTOFFs etc are the best selection
  % -------------------------------------------------------------------------------------------------------
  FLICK.anap.mareats        = ANAP.mareats;
  FLICK.anap.froiTs.mareats = ANAP.froiTs.mareats;
  % -------------------------------------------------------------------------------------------------------
  % SESGETTRIAL CONVERSION TO TRIALS
  % -------------------------------------------------------------------------------------------------------
  FLICK.anap.gettrial.status      = 1;            % We convert to trials
  FLICK.anap.gettrial.Average     = 1;            % And average them
  FLICK.anap.gettrial.trial2obsp  = 1;            % And the concatenate in a single obsp
  FLICK.anap.gettrial.PreT        = 0;            % No PreT (stimulus rather than trial type)
  FLICK.anap.gettrial.PostT       = 0;            % No PostT
  FLICK.anap.gettrial.IBRAINMEAN  = 0;            % 1=removes mean,2=zscore(dat,[],2)
  FLICK.anap.gettrial.Xmethod     = 'none';       % set to zero if IBREANMEAN > 0...
  FLICK.anap.gettrial.Xepoch      = 'prestim';    % Normlization-base
  FLICK.anap.gettrial.HemoDelay   = 1.0;          % XFORM: Here much shorter than usually!
  FLICK.anap.gettrial.HemoTail    = 6;            % XFORM: Same for tail
                                                  % -----------------------------------------------------------------------------------------------------
                                                  % SESGROUPGLM GLM-ANALYSIS
                                                  % -----------------------------------------------------------------------------------------------------
  FLICK.anap.glm.IARESTIMATION    = 0;            % AR estimation
  FLICK.anap.glm.ISATTERWAITH     = 0;            % Satterwaith
  FLICK.anap.glm.ICONVWITHGAMMA   = 0;
  FLICK.groupglm                  = 'before glm';
  FLICK.anap.glm.glmpreproc       = '';
  FLICK.glmsigs                   = {'troiTs'};
  
  % NOTE In contrast to monkey-coronal!!!
  % Left part of the image is left side of the BRAIN
  ACTIVATION_SPECIFICITY_TEST=1;
  if ACTIVATION_SPECIFICITY_TEST,
    if ACTIVATION_SPECIFICITY_TEST==1,
      FLICK.glmconts                  = {};
      J=1; FLICK.glmana{J}.mdlsct     = {'trialhipp[0]','trialhipp[1]'};
      FLICK.glmconts{end+1} = setglmconts('f','fHipp',  [],'pVal',  0.1, 'WhichDesign',J);
      FLICK.glmconts{end+1} = setglmconts('t','pbr1', [  1   0   0], 'pVal',1,'WhichDesign',J);
      FLICK.glmconts{end+1} = setglmconts('t','pbr2', [  0   1   0], 'pVal',1,'WhichDesign',J);
      FLICK.glmconts{end+1} = setglmconts('t','nbr1', [ -1   0   0], 'pVal',1,'WhichDesign',J);
      FLICK.glmconts{end+1} = setglmconts('t','nbr2', [  0  -1   0], 'pVal',1,'WhichDesign',J);
      FLICK.glmconts{end+1} = setglmconts('t','L>R',  [  1  -1   0], 'pVal',1,'WhichDesign',J);
      FLICK.glmconts{end+1} = setglmconts('t','R>L',  [ -1   1   0], 'pVal',1,'WhichDesign',J);
      FLICK.glmconts{end+1} = setglmconts('t','RL+',  [ .5  .5  -1], 'pVal',1,'WhichDesign',J);
      FLICK.glmconts{end+1} = setglmconts('t','RL-',  [-.5 -.5   1], 'pVal',1,'WhichDesign',J);
      J=2; FLICK.glmana{J}.mdlsct     = {'trialcohen[0]','trialcohen[1]'};
      FLICK.glmconts{end+1} = setglmconts('f','fCohen',  [],'pVal',  0.1, 'WhichDesign',J);
      FLICK.glmconts{end+1} = setglmconts('t','pbr1', [ 1  0  0], 'pVal',1,'WhichDesign',J);
      FLICK.glmconts{end+1} = setglmconts('t','pbr2', [ 0  1  0], 'pVal',1,'WhichDesign',J);
      FLICK.glmconts{end+1} = setglmconts('t','nbr1', [-1  0  0], 'pVal',1,'WhichDesign',J);
      FLICK.glmconts{end+1} = setglmconts('t','nbr2', [ 0 -1  0], 'pVal',1,'WhichDesign',J);
      FLICK.glmconts{end+1} = setglmconts('t','L>R',  [ 1 -1  0],'pVal',1,'WhichDesign',J);
      FLICK.glmconts{end+1} = setglmconts('t','R>L',  [-1  1  0],'pVal',1,'WhichDesign',J);
    else
      % ACTIVATION_SPECIFICITY_TEST==2, means it's a single stimulus... (CHANGE..)
      FLICK.glmconts                  = {};
      J=1; FLICK.glmana{J}.mdlsct     = {'hipp'};
      FLICK.glmconts{end+1} = setglmconts('f','fV1',  [],'pVal',  0.1, 'WhichDesign',J);
      FLICK.glmconts{end+1} = setglmconts('t','pbr',  [ 1 0],'pVal',1,'WhichDesign',J);
      FLICK.glmconts{end+1} = setglmconts('t','nbr',  [-1 0],'pVal',1,'WhichDesign',J);
    end;  
  else
    FLICK.glmconts                  = {};
    J=1; FLICK.glmana{J}.mdlsct     = {'fhemo'};
    FLICK.glmconts{end+1} = setglmconts('f','fV1',  [],'pVal',  0.1, 'WhichDesign',J);
    FLICK.glmconts{end+1} = setglmconts('t','pbr',  [ 1 0],'pVal',1,'WhichDesign',J);
    FLICK.glmconts{end+1} = setglmconts('t','nbr',  [-1 0],'pVal',1,'WhichDesign',J);
    J=2; FLICK.glmana{J}.mdlsct     = {'hipp','dtfhemo'};
    FLICK.glmconts{end+1} = setglmconts('f','fV2',  [],'pVal',  0.1, 'WhichDesign',J);
    FLICK.glmconts{end+1} = setglmconts('t','hipp',   [ 1  0  0],'pVal',1,'WhichDesign',J);
    FLICK.glmconts{end+1} = setglmconts('t','hipp-',  [-1  0  0],'pVal',1,'WhichDesign',J);
    FLICK.glmconts{end+1} = setglmconts('t','dthemo', [ 0  1  0],'pVal',1,'WhichDesign',J);
    FLICK.glmconts{end+1} = setglmconts('t','dthemo-',[ 0 -1  0],'pVal',1,'WhichDesign',J);
  end;
  % -------------------------------------------------------------------------------------------------------
  % MVIEW DISPLAY PARAMETERS
  % -------------------------------------------------------------------------------------------------------
  FLICK.anap.mview.alpha          = 0.001;
  FLICK.anap.mview.glmana.model   = 1;
  FLICK.anap.mview.cluster        = 0;
  FLICK.anap.mview.clusterfunc    = 'mcluster';
  
  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % ELECTRICAL STIMULAION/FOOTSHOCK GROUPS - CONTROL FOR BOLD QUALITY AND AREA REGISTRATION
  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % NOTE(TO CHECK STIMULATION PARAMETERS)
  % p = expgetpar('e10aw1',26)
  % p.stm
  %    v: {[1x270 double]}        % Stimulus ID (e.g. 0=red-stimulus, 1=green..)
  %  val: {[1x270 double]}        % Value 0=blank, 1, stimulus is on
  %   dt: {[1x270 double]}        % duration of each epoch, blank=2s, Stim=4s...
  %    t: {[1x271 double]}        % The exact onset-time (increasing function)
  % tvol: {[1x271 double]}        % Onset time in volumes
  % time: {[1x270 double]}        % Onset time in seconds with msec-resolution
  % MODEL(To see the model, one can type):
  % EXPMKMODEL('e10aw1',26,'fhemo')
  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  ESTIM.anap.mareats                      = ANAP.mareats;
  ESTIM.anap.froiTs.mareats               = ANAP.froiTs.mareats;
  ESTIM.anap.froiTs.mareats.IRESAMPLE     = 0.5;
  ESTIM.anap.froiTs.mareats.IREMBRAINMEAN = 1;      % Remove brain's average (phys artifacts)
  ESTIM.anap.froiTs.mareats.IFILTER       = 1;      % 1=to spatially filter; 0=no filter at all
  ESTIM.anap.froiTs.mareats.IFILTER_KSIZE = 5;      % Kernel size (previously 3)
  ESTIM.anap.froiTs.mareats.IFILTER_SD    = 2.0;    % Kernel SD (90% of flt in kernel) (previously 1.5)
  ESTIM.anap.froiTs.mareats.ICUTOFFHIGH   = 0.020;  % remove very slow oscillations
  ESTIM.anap.froiTs.mareats.ICUTOFF       = 0.200;  % 0.5 is Nyquist..
  
  ESTIM.anap.globaldir           = ANAP.project.estim_dir;
  ESTIM.anap.allsesmodel         = sprintf('%s/allsesmodel.mat',ESTIM.anap.globaldir);
  
  ESTIM.anap.mview.alpha         = 0.001;         % MVIEW for visualization of results
  ESTIM.anap.mview.datname       = 'beta';
  ESTIM.anap.mview.cluster       = 1;
  ESTIM.anap.mview.clusterfunc   = 'mcluster';
  ESTIM.anap.mview.glmana.model  = 2;
  
  % CRITICALLY PROJECT-DEPENDENT!!
  ESTIM.anap.gettrial.status     = 1;             % We convert to trials
  ESTIM.anap.gettrial.Average    = 0;             % And average them
  ESTIM.anap.gettrial.trial2obsp = 0;             % And the concatenate in a single obsp
  ESTIM.anap.gettrial.sort       = 'trial';
  ESTIM.anap.gettrial.PreT       = 0;             % No PreT (stimulus rather than trial type)
  ESTIM.anap.gettrial.PostT      = 0;             % No PostT
  ESTIM.anap.gettrial.IBRAINMEAN = 4;             % 1=removes mean,2=zscore(dat,[],2)
  ESTIM.anap.gettrial.Xmethod    = 'none';        % set to zero if IBREANMEAN > 0...
  ESTIM.anap.gettrial.Xepoch     = 'prestim';     % Normlization-base
  ESTIM.anap.gettrial.HemoDelay  = 2;             % XFORM: Here much shorter than usually!
  ESTIM.anap.gettrial.HemoTail   = 4;             % XFORM: Same for tail
  
  ESTIM.anap.glm.IARESTIMATION   = 0;             % AR estimation
  ESTIM.anap.glm.ISATTERWAITH    = 0;             % Satterwaith
  ESTIM.anap.glm.ICONVWITHGAMMA  = 0;
  
  ESTIM.grpsigs                  = {'tblp','tfroiTs'};
  ESTIM.glmseeds                 = {'hp'};        % Used in PRMKMODEL
  ESTIM.glmele                   = {'hp'};        % Used in PRMKMODEL
  ESTIM.groupglm                 = 'before glm';  % average experiments before running GLM
  ESTIM.glmsigs                  = {'tfroiTs'};   % will be overwritten by 'sigs','tfroiTs'...
  ESTIM.glmdesign                = 'estim';       % Regressors: BLP sigs or Seed Regions
  ESTIM.glmstruct                = {};
  ESTIM.glmconts                 = {};
  ESTIM.glmana                   = {};

  DNO = 1;
  if ischar(ESTIM.glmdesign),
    % TO LOAD AN ALREADY GENERATED MODEL:
    % ESTIM.glmana{DNO}.mdlsct = {sprintf('mdl%s.mat[1]', ESTIM.glmdesign)};
    ESTIM.glmana{DNO}.mdlsct = {'fhemo'};
  else
    for N=1:length(ESTIM.glmdesign),
      ESTIM.glmana{N}.mdlsct = ESTIM.glmdesign;
    end;
  end;
  
  if iscell(ESTIM.glmdesign),
    ESTIM.anap.glm.modnum = length(ESTIM.glmana{DNO}.mdlsct);
    ESTIM.glmconts{end+1} = setglmconts('f','fVal',  [],        'pVal', 0.1, 'WhichDesign',DNO);
    ESTIM.glmconts{end+1} = setglmconts('t','PBR',   [ 1  1  0],'pVal', 1.0, 'WhichDesign',DNO);
    ESTIM.glmconts{end+1} = setglmconts('t','NBR',   [-1 -1  0],'pVal', 1.0, 'WhichDesign',DNO);
    ESTIM.glmconts{end+1} = setglmconts('t','hipp',  [ 1  0  0],'pVal', 1.0, 'WhichDesign',DNO);
    ESTIM.glmconts{end+1} = setglmconts('t','hipp-', [-1  0  0],'pVal', 1.0, 'WhichDesign',DNO);
    ESTIM.glmconts{end+1} = setglmconts('t','cohen', [ 0  1  0],'pVal', 1.0, 'WhichDesign',DNO);
    ESTIM.glmconts{end+1} = setglmconts('t','cohen-',[ 0 -1  0],'pVal', 1.0, 'WhichDesign',DNO);
  else
    ESTIM.anap.glm.modnum = length(ESTIM.glmana{DNO}.mdlsct);
    ESTIM.glmconts{end+1} = setglmconts('f','fVal',  [],    'pVal', 0.1, 'WhichDesign',DNO);
    ESTIM.glmconts{end+1} = setglmconts('t','PBR',   [ 1 0],'pVal', 1.0, 'WhichDesign',DNO);
    ESTIM.glmconts{end+1} = setglmconts('t','NBR',   [-1 0],'pVal', 1.0, 'WhichDesign',DNO);
  end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout > 5,
  POLAR = ESTIM;
  % Classic EEG classification (See http://en.wikipedia.org/wiki/Electroencephalography)
  POLAR.anap.siggetblp.conv2sdu = 0;
  POLAR.anap.siggetblp.NewFs    = 500;
  POLAR.anap.siggetblp.lcutoff  = 500;
  POLAR.anap.siggetblp.band{ 1} = {[   0.5    4] 'delta'  'LFP',  2};
  POLAR.anap.siggetblp.band{ 2} = {[   4      8] 'theta'  'LFP',  2};
  POLAR.anap.siggetblp.band{ 3} = {[   8     13] 'alpha'  'LFP',  2};
  POLAR.anap.siggetblp.band{ 4} = {[  13     30] 'beta'   'LFP',  8};
  POLAR.anap.siggetblp.band{ 5} = {[  30    100] 'gamma'  'LFP', 15}; %  it was 180
  POLAR.anap.siggetblp.band{ 6} = {[   1    150] 'lfp'    'LFP', 15}; %  it was 180
  POLAR.anap.siggetblp.band{ 7} = {[ 500   3400] 'mua'    'MUA', 15};
  POLAR.anap.siggetblp.lBands   = [1:6];        % Bands in the LFP range
  POLAR.anap.siggetblp.mBands   = [7];          % Bands in the MUA range
  
  POLAR.anap.mareats        = ANAP.mareats;
  POLAR.anap.froiTs.mareats = ANAP.froiTs.mareats;

  POLAR.anap.mview.datname                  = 'response';
  POLAR.anap.mview.alpha                    = 0.05;
  POLAR.anap.mview.statistics               = 'glm';
  POLAR.anap.mview.anascale                 = [500  15000  2];
  POLAR.anap.mview.glmana.model             = 1;
  POLAR.anap.mview.glmana.minmax            = [-2.5 2.5];
  
  POLAR.anap.gettrial.IBRAINMEAN  = 1;                  % 1=removes entire-brain mean,2=zscore(dat,[],2)
  POLAR.anap.gettrial.sort        = 'trial';
  POLAR.anap.gettrial.PreT        = [];
  POLAR.anap.gettrial.PostT       = [];
  POLAR.anap.gettrial.blp.Xmethod = 'sdu';
  POLAR.anap.gettrial.blp.Xepoch  = 'prestim';
  POLAR.anap.gettrial.Xmethod     = 'zerobase';      
  POLAR.anap.gettrial.Xepoch      = 'prestim';  
  POLAR.anap.gettrial.HemoDelay   = 2;                  % Tested! DO NOT CHANGE
  POLAR.anap.gettrial.HemoTail    = 7;          

  POLAR.anap.froiTs.gettrial  = POLAR.anap.gettrial;
  POLAR.anap.glm.glmpreproc = '';
  POLAR.groupglm            = 'before glm'; 
  POLAR.glmsigs             = {'troiTs', 'tfroiTs'};
  POLAR.glmana              = {};
  POLAR.glmana{1}.mdlsct    = {'mdlpolar.mat[1]','mdlpolar.mat[2]'};
  POLAR.glmconts            = {};
  POLAR.glmconts{end+1} = setglmconts('f','fVal',  [], 'pVal', 0.1);
  POLAR.glmconts{end+1} = setglmconts('t','pbr',  [ 1  1  0],'pVal', 1.0);
  POLAR.glmconts{end+1} = setglmconts('t','nbr',  [-1 -1  0],'pVal', 1.0);
  POLAR.glmconts{end+1} = setglmconts('t','lgn',  [ 1  0  0],'pVal', 1.0);
  POLAR.glmconts{end+1} = setglmconts('t','hip',  [ 0  1  0],'pVal', 1.0);
end;
return;


