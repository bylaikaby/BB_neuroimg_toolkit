function hmri
%HMRI - Invokes Help browser for all MRI functions
%
% fname = which('hmri.htm');
% cmd = sprintf('file://%s', fname);
% web(cmd, '-browser');
%
  
% DISCLAIMER: Most of the functions in our package were written by myself (NKL) and Yusuke
% Murayama (YM). They are neither optimized or necessarily convenient for general
% usage. Often they are changed (by NKL or YM) to accomodate new projects but unforutantely
% not always changed enough to be backwards compatible. In other words (and unfortunately),
% time considerations keep the few good things in here at subotpimal level. Still the
% package is useful and works very well for individual projects, taking into account the
% complexity of our data (combination with physiology or other techniques). So, until we
% find some one to do systematic work on this package, please do not change things without
% notifying Yusuke or myself. Thanks!
%
% Experiments & Signals
%  
% Note: Paravision saves the data in the so-called FID (free induction decay) files as
% sequential echoes. Following reconstruction, which includes resorting and assembling
% different segments, the generated images are saved as 2dseq files. Each session
% (e.g. M02.lx1) includes a number of directories (1, 2...)  named after the scan number. Each
% scan directory has the following (relevant) entries:
%       pdata       is the data directory 
%       acqp        is the acquisition parameter file
% The pdata directory contains the actual data
%       2dseq       is the data file
%       reco        includes the reconstruction parameters
% In the beginning of the analysis, and following the generation of SesPar.mat (by invoking the
% function SESDUMPPAR), the following steps must be taken:
%
% See also
%   /MATLAB/MRI/CONTENTS            -- General "MRI-Related" Utilities
%   /MATLAB/EVT/CONTENTS            -- Event handling and observation-period/trial routines
% 
% Preprocessing of MRI Data
%   SESASCAN        - - Load all anatomy files
%   SESCSCAN        - - Load and analyzed control scans
%   SESVITAL        - - Get respiration and plethysmogram signals and save in vitals
%   SESIMGLOAD      - - Append all Paravision 2dseq imagefiles of a Session
%   SESROI          - - Generate the regions of interest (ROIs) used for analysis
% 
% Other Help Sources
%   HROI            - - Description of ROI selection performed by MROI
%   INFOROITS       - - Display names and slice-number of roiTs structure
%
% Detailed Description
%   SESLOAD invokes the following functions:
%   SESDUMPPAR - Load all experiment parameters
%   SESASCAN - Load all anatomy scans
%   SESCSCAN - Analyze all control scans (eg Epi13)
%   SESVITAL - Get respiration and plethysmogram signals and save in Vital
%   SESIMGLOAD - Convert 2dseq files into matlab files
%   SESTCIMG  - Generate mean(tcImg,dat,4) for each group
%
% New sessions invoke SESLOAD(SesName) with no other arguments; Sessions that have been partly
% processed, may require editing of the SESLOAD swithes to determine which steps need to be
% run; Obviously, any of the above SESXXXX functions can be invoked manually by the user;
%
% SESTCIMG - Can be invoked from within SESLOAD; The mean imaging data are used during the
% definition of regions of interest; They have auxilliary function only; By getting the overall
% mean response we can better defined the regions showing activation, obtain better CNR for
% drawing the boundaries of anatomically-defined cortical areas etc; The mean responses do not
% accurately represent the time course of the BOLD signal, as they often average voxels not
% showing signficant activation; The time course and the details of the signal can be only
% studied after running the cross-correlation analysis on data of individual experiments; The
% average of such (seleceted) data is the one we use to compare imaging and neural signals;
%
% The following steps are interactive:
%
% SESROI (SesName) - Defines Regions of Interest Important note - You can run SESTCIMG to get
% the average responses and subsequently rung SESROI to define ROIs on the basis of anatomical
% detail and of a rough idea of the extent of activation; However, this has an obvious
% disadvantage: it's very slow, because preprocessing is done on the entire image, including
% regions outside the brain;
%
% It is recommended that you use: SESROI first (it won't display data from tcImg matfile, but
% from one experiment only); to define the brain-ROI; Then run SESTCIMG, and then run SESROI
% again
%
% SESROI (SesName, 'update') - Finds all activated areas in the group-scans of tcImg mat-file,
% and applies a logical-"AND" operation between the activation maps and the area ROIs specified
% in the previous step; SESROI (SesName, 'reset') Restores the ROI file as it was in the first
% step
%
% SESAREATS - Use roi information and create area-time-series; SESAREATS is the function
% applied different filters to the original data; check the documentation-header of the
% function for details on filters;
%
% SESAREATS - also applies correlation analysis to the data; The created roiTs has both the
% time series of each area defined in Roi-names, and the r-values for each time series;
%
% SESGRPMAKE - fix this one
%
% SESGETHRF - Get Hemodynamic responses
%
% MAREATS - See detailed description in mareats
%
% Small utilites for signal selection and processing
% ----------------------------------------------------------------
% EXPGETSTM - Provide stimulus-related information
% GETCOND - Split the file data into trial and observation periods
% GETEPOCH - Reshapes and permutes the output of the sorttrials
% GETEXPINFO - get information about sesname, expno, group
% GETTRIALINFO - get trial information, including tiral IDs
% GETGRPROI - Returns all references groups of a session
% GETTRIAL - Return single trial from observation period
% SIGSELEPOCH - select the signal during EPOCH
% SIGSORT - Sort out signals by given parameter
% SORTTRIALS - sort randomly presented trials
% GETCOND - Split the file data into trial and observation periods
% XFORM - converts Sig's unit accoring to 'Method' and 'Epoch'
% FINDTRIALPAR (pars,TrialID) - returns trial index
%
% Example:
% ----------------------------------------------------------------
% To see the quality of signals after group averaging you can do
% the following (example with session f01pr1):
% oSig = catsig('f01pr1','polarflash','roiTs');
% oSigTrial = gettrial(oSig,5); 
% gettrialinfo('f01pr1','polarflash');
% Returns among others:
%       id: 5
%       label: 'trial5' etc
% oSigTrial = gettrial(oSig,5); - get the trial ID=5
% dsproits(mroitssel(oSigTrial,0_4));
% The last call will display the time courses of the trial 5;
%
% goto('e04pl1');
% load polarflash;
% dsproits(mroitssel(gettrial(roiTs,X),0.65))
% The above 3 lines will show the time course of an individual
% trial, with ID=X (in the example-session X is in [0-5]);
%
% SESIMGVIEW - Includes all display functions for imaging data
% ----------------------------------------------------------------
%       SHOWASCAN (SesName) - See anatomy (dump if pptout is set)
%       SHOWCSCAN (SesName) - See control scans (dump if pptout is set)
%       SHOWIMG (SesName,ExpNo) - See functional data
%       SHOWVITAL (SesName,ExpNo) - Shows the plethysmogram and its spectra
%       SHOWVITAL (SesName) - Like showvital(SesName,ExpNo) but for all experiments
%       DSPROITS (roiTs) - Shows the time series of each area/ROI
%       DSPCORIMG (xcor) - Shows the xcor maps (xcor{}_dat)
%       DSPIMG - Check function's header
%       QVIEW  - Check function's header
%
%
% ----------------------------------------------------------------
% Old analysis (to be eliminated)
% ----------------------------------------------------------------
% The field grp_ana must include Scan, Scan_number, [Subset of ana sli
% matching tcimg] and [the electrode slices];
% For example: ses-grp-estm1-ana = {'gefi';1;[13 17 21];[17]};
% means that the first "gefi" scan is used for anatomical
% information; The scan usually 20-40 slices, and here the slices
% 13, 17 and 21 are matching the ones collected with EPI; Finally,
% one electrode was used which was placed in the slice 17;
%
% SHOWMODEL (SesName,GrpName) Shows the model of a group; It is a good
% idea to check the models before going to the next step (running
% correlation analysis); For example, showmodel('f01kz1','estm1')
% will show one model; showmodel('f01kz1','estm3') will show 4
% models for each stimulation intensity; Calculating models for
% experiment with event-related design is not a "safe bet"; The
% well known strong nonlinearities of bold for short presentations
% often require the usage of data-derived models, or models
% generated by convolving the local neural response with a hrf
% function; It's important to check, because i have found it
% difficult to have a "generic" model-maker;
% SESXCOR (SesName) applies correlation analysis within the Brain
% roi; The process will append the xcor structure to each file,
% including	the r-value maps and the time courses of the
% significant voxels;
% SHOWXCOR (SesName,arg2) can be used to see the results of xcor by
% defining the session and ExpNo or GrpName; Examples:
%		SHOWXCOR('f01kz1',21);
%		SHOWXCOR('f01kz1','estm1');
% SHOWXCORPLOT (SesName,GrpName) can be used to see the results of group
% xcor data; Activated voxels are "plotted" on anatomical scans
% rather than superimposed as zscore-maps;
% SESGRPMAKE ('f01kz1','estm1','xcor');
% You can use this one to average all xcors and see better the
% quality of the signal; Normally the grouping is done at the end
% of the analysis, by calling sesgrpmake(SesName), which groups
% all variables listed in GrpSigs.
%
% (a) Ring/Bar Stimuli with Dynamic Suppression
% (b) Brief stimuli to study temporal integration.
%
% Version : 1.0 NKL  01.04.04
  
%%%% helpwin hmri
%%%% web hmri.htm;

fname = which('hmri.htm');
cmd = sprintf('file://%s', fname);
web(cmd, '-browser');





