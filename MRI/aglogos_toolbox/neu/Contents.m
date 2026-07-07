% NEU -- General neural-signal processing functions
%
% Help
%   hneu            - - General neural-signal processing functions used by all projects
%
% Batch Files
%   sesneuana       - - Batch file to run all preprocessing and correlation/GLM analysis for fMRI data
%
% Display Functions
%   showcln         - - Show the cleaned signal, Cln, and its spectral power
%   showclnspc      - - Plot spectrograms as surface plots (3D or Flat)
%   showblp         - - Show BLP Signals of ExpNo/Group
%   showelegrid     - - shows the grid of electrodes or voxels
%   showchan        - - Display the signal of each channel separately
%   showcra         - - Apply Wiener analysis to group data
%   showch          - - Group all contrast of a group by calling catconfunc
%   showsigcf       - - Display the signals resulting from depend-analysis
%   showicadenoise  - - show ICA results (DEMO)
%   showsta         - - displays 'spkBlp' signal.
%   showsigfft      - - show the spectra of all signals we use
%   showtblp        - - Display signals "SigName" of different trials 
%   showtrial       - - Display signals "SigName" of different trials 
%
%   dspsig          - - Display a neural signal
%   dspsig2         - - Display two signals by using plotyy
%   dspclnspc       - - shows the spectrograms of the Cln signal (e.g. ClnSpc)
%   dspblp          - - Plot a single BLP signal or all BLPs in form of a spectrogram
%   dspfftblp       - - Show fourier spectrum of BLP signals
%   dsppsth         - - Display histogram data from single units
%   dsprf           - - Plot RF structure of a single experiment
%   dspgrprf        - - Plot RF structure of a single experiment
%   dspspktrigavr   - - displays 'spkBlp' signal.
%   dspbands        - - Display the power spectrum of individual bands
%   dspclncor       - - Plot the LFP-MUA correlations computed by getlfpmua4cor (ClnCor)
%   dsptblp         - - Display signals "SigName" of different trials 
%
% Signal Processing
%   showadf         - - Show raw ADF data
%   sigxform        - - Transform signal according to the second input argument "xform"
%   sigabs          - - Full-Rectify signal abs(Sig)
%   sigdetrend      - - Detrend data fields of signal Sig (e.g. Cln, Lfp)
%   sigfilt         - - Filters the signal within limits 'lims' and type 'ftype'
%   sighilbert      - - Compute Hilbert Transform of the Signal
%   sigdiff         - - Computes derivative of order "Order"
%   sigmult         - - Multiplies signals "by element"
%   sigcumsum       - - Returns the cummulative sum of the Sig.dat field
%   sigtosdu        - - Convert Signal to baseline-SD Units
%   sigpsd          - - Compute PSD of the signal
%   sigdecimate     - - Decimate Sig by a factor of "Fac"
%   sigreshape      - - Reshape sig(Nx1) to osig(KxM), M=NoTrig,K=diff(trig+lims)
%   sigsctcat       - - Concatenate structures and some of their fields.
%   sigmean         - - Compute the mean of a signal along dimension DIM (default=1)
%   sigmedian       - - Compute Median of a signal along dimension DIM (default=1)
%   sigresample     - - Resample signal Sig at sampling rate of NewFs
%   siginfo         - - Display signal information
%   gethlm          - - Returns the mean of Hilbert Trans of LFP(gamma) & MUA of all channels
%   sesgethlm       - - Computes the mean of Hilbert Trans of LFP(gamma) & MUA of all channels
%   sesrmsts        - - Generates RMS of the Cln signal.
%   sigrmsts        - - Generates time-window RMS of the given signal.
%   sesall2blp      - - Replace all signals (barring Spkt/Sdf) with BLPs
%   getblpinfo      - - Returns the session name and experiment number of blp.
%   blpfreqz        - - plots fiter responses used for "blp" extraction.
%
% Band Separation
%   sesgetsigs      - - Get all signals (Cln/Dec, Lfp, Mua, Sdf, etc.)
%   siggetblp       - - Separate the Cln signal into freqeuncy bands (10 Bands including the EEG standards)
%   expgetblp       - - Separate the Cln signal into freqeuncy bands for SesName/ExpNo
%   sesgetblp       - - Separate the Cln signal into freqeuncy bands for entire session
%   blp2sig         - - Averages bands into traditional signal (Lfp, Mua, etc.)
%   sigselblp       - - Select BLPs by examining their correlation to the stimulus
%   expselblp       - - Select frequency bands by correlating the neural signal w/ a model
%   sesselblp       - - Selects stimulus/mri-correlated frequency bands based on r-value
%   getbandsflt     - - Extract Gamma/Lfp/Mua/LfpLHM by bandpass filtering
%   sesgetlfpmuaflt - - Get Lfp/Mua/LfpH etc.
%
% Spectrograms, Bandgrams and Coherograms
%   sigspc          - - Make spectrogram from signal iSig
%   grpclnspc       - - Make spectrograms for the Cln signal of each group
%   sesclnspc       - - Make spectrograms for the Cln signal of each experiment
%   cohgram         - - time dependent coherence analysis
%
% Compute BLPs by Selective Averaging of ClnSpc
%   getgrplfpmua    - - Extract power signals from the ClnSpc of a group-file
%   sesgetlfpmua    - - Get pLFP/pMUA etc by calling the function GETLFPMUA
%   getlfpmua       - - Extract power signals from ClnSpc (LfpPow,MuaPow)
%
% Compute Correlations/IRs for LFP-band Input and MUA-Output
%   seslfpmua4corr  - - Get pLFP/pMUA etc by calling the function GetLfpMua4Corr
%   getlfpmua4corr  - - Returns TS of the average MUA and all frequencies in LFP range
%   lfpmuairf       - - Compute the Impuse Response of the LFP-MUA system
%   sigwhiten       - - Whiten signal (remove stimulus-related modulations)
%   sigwhitendemo   - - Show effects of prewhitening on signal Sig.
%
% Spike Detection and Spike Density Functions
%   nview           - - Displays neural signals
%   siggetspk       - - Extract spikes from the raw signal (Cln)
%   sesgetspk       - - Extracts spikes and SDFs from Cln.dat
%   getspk          - - Extracts spikes and SDFs from Cln.dat
%   spksdf_deci     - - Make spike density functions
%   getspkform      - - Extract spikes forms from the raw signal (Sig)
%   spkfind         - - Extract single spikes by detecting zero crossings
%   spksdf          - - Make spike density functions
%   tstwin          - - Test the effects of window (PSTH bin width) on independence
%   vtestshow       - - Demo of dynamics of site-RF "TO BE REPLACED!!"
%   sigspkform      - - Extract spikes forms from the raw signal (Sig)
%   sesspktrigpca   - - computes spike triggered PCA of signal
%   sigspktrigcov   - - Computes spike-triggered average of SIG.
%   spkview         - - Displays neural signals of spikes (Spkt)
%   getspkhist      - - Get the histograpm of the Spkt.times
%   dsptimes        - DSPSPKT - Display Spike data as raster
%
% Spike Trigger Averages and Variance
%   sesspkana       - - Spike-triggered analysis (spkana)
%   spkana          - - Analyzes spike waveforms, spectra, and clustering.
%   sigspktrigavr   - - Computes spike-triggered average of SIG.
%   siggetburst     - - Extract bursts from Spkt signal
%   sesspktrigavr   - - computes spike triggered averages of signal
%   sesbrsttrigavr  - - computes spike triggered averages of Blp
%   atsesspktrigavr - - computes spike triggered averages of Blp
%
% Receptive Field Estimation via Reverse Correlation
%   getrfdyn        - - Compute RF of the recording sites by means of reverse correlation.
%   siggetrf        - - Compute site-RF structure by means of reverse correlation.
%   siggetrfdyn     - - Compute site-RF structure by means of reverse correlation.
%   spkgetrf        - - Compute site-RF structure by means of reverse correlation.
%   sesgetrf        - - Compute RF of the cells by means of reverse correlation.
%   getelepos       - - returns correct electrode position and distances
%   getrfsigs       - - Get RF signals that are grouped by catsig/catgrpmovie etc
%   grprfdyn        - - Group all coherence data of a group
%   getrf           - - Compute RF of the recording sites by means of reverse correlation.
%   grprf           - - Group all coherence data of a group
%   sesautoplot     - - evaluate autoplot data
%
% Movies
%   movmean         - - Load a movie file defined in the Sig.movie structure
%   catgrpmovie     - - Concatanates all movie-groups into one large group.
%   catmovie        - - concatanate signals from mat files into a group file
%
% Fixup routines
%   sigfixblp       - - Add/Modify a band in BLP
%   sesfixblp       - - Separate the Cln signal into freqeuncy bands for entire session
%   expfixblp       - - Separate the Cln signal into freqeuncy bands for SesName/ExpNo
%
% Information on Files and Structures (Files in ./Matlab/Utils)
%   whoupdated         % Lists all recently updated Matlab scripts.
%   whofile            % List file variables by calling who(filename,'-file',...)
%   infowho            % Searches for variable "VarName" in all files of a session
%   info1who           % List the variables in the 1st file of each group
%   infogrpwho         % List the variables of each MAT file that belongs to the group GrpName
%   infoevt            % Display Event/Stim Information (Requires dgz and acqp/reco files)
%   infoexp            % Displays information regarding the experiment ExpNo of SESSION
%   infogrp            % Display the fields of all groups of a session
%   infomissing        % Display missing mat files from a session
%   infosupgrp         % Lists & returns all super groups from description files
%   infoses            % Display information for each group of a session using raw data
%
% Other Utilities
%   spc2blp         - - Average the time courses of ClnSpc for given frequency ranges varargout =
%   spc2model       - - Generates regressors from frequency ranges of SPC
