% STAT
% This directory includes all functions used to estimate various statistics
% of a signal.
%
% Help and Documentation
%   hstat        - - Documentation of our statistics package
%
% Incomplete Functions !!! (ToDo's)
%   sesgrpstat   - - Group all statistical values and functions
%   spcsts       - - Get statistics of signal Spc.
%   sigsigsts    - - Computes cross-correlation and cross-covarinace
%   siganova1    - - Compute One-Way Anova between blank and stim conditions  
%
% Channel Selection (Reports channels not driven by the stimulus)
%   findchan     - - Find channels driven by the stimulus (for exclusion)
%
% Entropy Estimation and Signal RMS Value
%   showentropy  - - Show entropy distributions for different groups
%   ssigentropy  - - Computes the entropy of all channels of a signal Sig
%   sentropy     - - Computes the entropy of a vector x
%
% Autocorrelation and Coherence Functions
%   sigcor       - - Get autocorrelation function from signal Sig
%   expcor       - - Display autocorrelation function of Signals SigNames
%   dspsigacr    - - Display signal and its statistics
%
% Amplitude Distributions
%   sighist      - - Make a histogram-signal from the dat file of Sig
%   dsphist      - - Display histogram as bar or stem plot
%   exphist      - - Display amplitude-distributions for signals with SigNames
%   showhist     - - Show the amplitude-distribution of a signal SigName
%
% Statistics of Individual Signals
%   sigsts       - - Get descriptive statistics of signal Sig.
%   dspsigsts    - - Display signal statistics
%   sigrms       - - Computes the RMS values for each window with size Sig.stm.voldt
%   dsprms       - - Display the RMS values as bar graphs
%   exprms       - - Compute the RMS value of a signals windows or epochs
%   sigttest     - - Performs a t-test between signals
%
% Statistics of All Signals of an Experiment
%   getstimstat  - - returns time-statistics for SESSION,GRP/EXPNO.
%   expgetstat   - - Statistical Analysis for ExpNo of SesName
%   dspstat      - - Displays experiment statistics
%   showstat     - - Shows displays the results of EXPGETSTAT for SesName & ExpNo
%   sesgetstat   - - Invokes EXPGETSTAT for each experiment of session "SesName"
%
% Statistics Utilities
%   pca          - - Applies Principal Component Analysi on the data
%   linreg       - - performs linear regression between vectors x and y
%   mtspec       - - Multitaper Time-Frequency Spectrum
%   multreg      - - Multiple regression analysis
%   nonlinfit    - - Nonlinear fits using the L-M method
%   ExpWith3Pars - - Compute exponential with (P,x)
%
% Test/Debug Functions
%   tststat      - - Test functions for statistical analysis
%
% NKL, 19.07.04
%   anovan       - Please edit session/group list in this script as your demand.
%   cat1blp      - - Concatanate along the first dimension all experiments to compute r for the channel
%   depanovan    - DEPANOVA - N-way ANOVA for dependency analysis
%   depstat      - : 1way ANOVA for dependency signals
%   dspsigpca    - - plots data computed by SIGPCA.
%   mycov        - Covariance matrix.
%   sesstat      - - Compute miscelleneous session-statistics
%   sigpca       - - Computes PCA of SIG.dat
