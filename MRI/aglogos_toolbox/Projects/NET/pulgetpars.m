function [ANAP, ROI, GRPP] = pulgetpars(SesName, ARGS)
%PULGETPARS - Defines Common Parameters for the Pulvinar NET-fMRI Project
% [ANAP, ROI, GRPP] = pulgetpars(SesName) is called from within each description file to set
% the basic parameters that are used by all sessions. For a detailed description of the
% analysis procedure see RPANA.M
%
% NKL 30.07.2013
%  
% See also RPANA, RPGETPARS, RPSESSIONS


% get basic/common parameters.
[ANAP, ROI, GRPP, FLICK, ESTIM, POLAR] = rpgetpars(SesName, ARGS);
% ok here modify parameters for Pulvinar project.
ANAP.clnpar.HIGHPASS   = 4;  % Cutoff freq for high pass (in Hz)
ANAP.clnpar.LOWRECOVER = 1;  % Recover low-freq componet(s) removed by any highpass.
ANAP.clnpar.OUTLIERS   = 0;  % Set if check for outliers is desired
ANAP.clnpar.REMOVE_ECG = 0;  % try to remove hear-beat artifact

%=========================================================================================
% BLP EXTRACTION
%=========================================================================================
ANAP.siggetblp.NewFs    = 660;
ANAP.siggetblp.lcutoff  = 660;
ANAP.siggetblp.conv2sdu = 1;        % Before 13.03.2014 ANAP.siggetblp.conv2sdu = 0;
ANAP.siggetblp.detrend  = 1;

AbsLowCut = 30;
ANAP.siggetblp.band     = {};
ANAP.siggetblp.band{ 1} = {[   0    325] 'cln'     'LFP', 0};           % Cln (low res)
ANAP.siggetblp.band{ 2} = {[   0.03 3.0] 'delta'   'LFP', 0};           % Standard EEG...
ANAP.siggetblp.band{ 3} = {[   3.5   12] 'theta'   'LFP', 3};           % Alpha 8-13Hz !!
ANAP.siggetblp.band{ 4} = {[  13     16] 'spindle' 'LFP', 4};           % Spindles.. 10-18Hz!!
ANAP.siggetblp.band{ 5} = {[  17     28] 'sigma'   'LFP', 5};           % Also Beta 13-30Hz!!
ANAP.siggetblp.band{ 6} = {[  30     80] 'gamma'   'LFP', AbsLowCut};
ANAP.siggetblp.band{ 7} = {[  81    190] 'ripple'  'LFP', AbsLowCut};
ANAP.siggetblp.band{ 8} = {[ 255    750] 'hfo'     'MUA', AbsLowCut};
ANAP.siggetblp.band{ 9} = {[ 755   3000] 'mua'     'MUA', 200};         % MB 06.05.2014 for SpkCoh
ANAP.siggetblp.lBands   = [1:7];         % Bands in the LFP range
ANAP.siggetblp.mBands   = [8 9];         % mEFP and MUA Bands
ANAP.siggetblp.despike  = 0;             % 0|1 to despike or not
for N=1:length(ANAP.siggetblp.band),
  range = sprintf('%.0f %.0f', ANAP.siggetblp.band{N}{1});
  txt = sprintf('%s(%s)/%d', ANAP.siggetblp.band{N}{2},range,ANAP.siggetblp.band{N}{4});
  ANAP.siggetblp.blpinfo{N} = txt;
end;


%=========================================================================================
% VIEWBANDS parameters for viewband-display
%=========================================================================================
ANAP.viewbands.band = {};   % {Name,   Dec, FilterHz, normalize, envelope, yscale, rgb, rgb, rgb)}
ANAP.viewbands.band{end+1}  = {'ripple',  8, [ 81 190], 'zscore', 1, 1, [0 0 0],[1  0   0],[1    .93  .93]};
ANAP.viewbands.band{end+1}  = {'gamma',   8, [ 30  80], 'zscore', 1, 1, [0 0 0],[0  .8  0],[.93  1    .93]};
ANAP.viewbands.band{end+1}  = {'sigma',   8, [ 17  28], 'zscore', 1, 1, [0 0 0],[0  0   1],[.93  .93  1  ]};
ANAP.viewbands.band{end+1}  = {'spindle', 8, [ 13  16], 'zscore', 1, 1, [0 0 0],[1  0   1],[1    .93  1  ]};
ANAP.viewbands.band{end+1}  = {'theta',   8, [ 3.5 12], 'zscore', 1, 1, [0 0 0],[.8 .8  0],[1    1    .93]};
ANAP.viewbands.band{end+1}  = {'delta',   8, [ .2   4], 'zscore', 1, 1, [0 0 0],[0 .8  .8],[.93  1    1  ]};

ANAP.viewbands.chan         = {'lgn' 'pl'};
ANAP.viewbands.site_average = 1;
ANAP.viewbands.tepoch       = 2;
ANAP.viewbands.site_band    = {};
ANAP.viewbands.site_band{1} = {'lgn' {'ripple' 'gamma'} };
ANAP.viewbands.site_band{2} = {'pl'  {'ripple' 'gamma' 'spindle'} };



%=========================================================================================
% SPIKE EXTRACTION -----------------------------------------------------------------------
%=========================================================================================
% YM USE a spike threshold of 3.0
% If .spkselect is set, then ...  sesgetspk() will do spike selection by the Michel-Method
%     Spkt.times is updated while keeping the original as Spkt.times_spkcdt.
% If .despike is set as 'selected' then sesgetblp() removes only selected spikes
% If .despike is 1, removes all spikes (without selection).
ANAP.siggetspk.highpassHz   = 1000;         % DO NOT USE lower cutoff; it peaks mEFP
ANAP.siggetspk.conv2sdu     = 0;            % No normalization - direct spike-count
ANAP.siggetspk.binwidth     = 0.025;        % 10ms binwidth for peristimulus histograms
ANAP.siggetspk.sdfrate      = ANAP.siggetblp.NewFs;  % Resampling rate for SDF
ANAP.siggetspk.sdfkernel    = 0.010;        % 5ms X 3 (SD) X 2 = kernel size
ANAP.siggetspk.threshold    = 3.0;          % Threshold for spike selection
ANAP.siggetspk.base_period  = 'blank';      
ANAP.siggetspk.spkselect    = 0;            % runs spike selection.

