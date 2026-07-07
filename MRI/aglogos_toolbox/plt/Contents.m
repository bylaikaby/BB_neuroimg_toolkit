% PLT -- General display functions
% This directory contains all general display functions. Our convention is: Functions that
% start with "dsp" handle signals. Functions that start with show handle experiments. Functions
% that start with br browse through an entire session to display different experiments or
% groups. All other functions are small utilities.
%
% For example:
%
%   SIGLOAD('c98nm1',1,'LfpH'); will load the LfpH signal from the
%           first experiment of session c98.nm1, and dspsig(LfpH) will
%
%           display it. Alternatively you can type
%   SHOWSIG('c98nm1',1,'LfpH'), which will have the same effect.
%
% General Signal Display Functions
%   show           - - Display signals using the "Sig.dsp.func" Function
%
% Signal Quality and Variability
%
% Receptive Field Plotting
%   showautoplot   - - shows autoplot data
%
% Dependence Analysis
%   dspchcfdist    - - plot coherence against distance for entire session
%   showrmsmri     - - Displays the RMS of the Neural Signal superimposed on the BOLD response.
%
% System Identification
%   showavghrf     - - Show typical HRF as average from different animals
%
% Filtering and Denoising
%
% Correlation, Regression and ANOVA Analysis
%   showmoviettest - - show sesroi results (ROIs xcor data etc.) for group
%   showtc         - - Get time series of a roipoly-defined region of interest
%
% Neural Signal Display Functions
%   dspautoplot    - - Display histogram of autoplot data
%   dspaplimg      - - display one of the stimuli presented during the experiment
%   dspem          - - display eye movements in an x-y plot
%   dspepoch       - - Displays an epoch-sorted signal
%   dspfft         - - plot a neural raw signal
%   dspflashspec   - - Show spectral power distribution of a signal
%   dspgrid        - - display grid w/ vertical lines over cortex
%   dsphold        - - applies hold on/off to all subplots
%   dspimpedance   - - displays the impedance spectrum of a cortical region.
%   dsppfl         - - display image and intensity profiles
%   dsppfl3        - - display image and intensity profiles
%   dsppsd         - - plot a neural raw signal
%   dspsigpow      - - plot a neural raw signal
%   dspsigpsd      - - displays the PSD of a Cln signal
%   dspspikeform   - - show spike wave forms
%   dspvit         - - display eye movsigents in an x-y plot
%
% Imaging Signal Display Functions
%   dspanaimg      - - Display multi-slice anatomical scans
%   dspimgsurf     - - Display an image as surface-plot
%   dspsesroi      - - show sesroi results (ROIs xcor data etc.) for group
%   dspcormrineu   - - show sesroi results (ROIs xcor data etc.) for group
%   dsptc          - - plot a neural raw signal
%   dspmoviettest  - - show sesroi results (ROIs xcor data etc.) for group
%   dspprofile     - - display intenstity profile of cortex
%   mimage         - - show a two-dimensional image at its real dimensions
%
% Combined Neural & Imaging Signal Display Functions
%
% Demo Functions
%   showres        - - Show all data for the SFN03 analysis
%
% Browser Functions
%   brspc          - - Invokes SHOWTRSPC for all alert-monkeys session of 2002
%   brwact         - - Browse the t-test maps and time series to check quality
%   brwch          - - Browse single channels
%   brwir          - - Browse/print Impulse Responses and their best fit
%   brwraw         - - Show Cln.dat of the Nature 2001 Sessions
%   brwrois        - - Show all ROIs for all Nature 2001 sessions
%   brwxcors       - - Browse all Xcor Structures for all sessions
%
% General Utilties
%   zoomin         - - plots the selected axes to the new window.
%   checkexp       - - Check the quality of signals in experiment ExpNo (used during data collection)
%   suptitle       - - puts a title above all subplots.
%   colorcode      - - To change the colormap and its num of levels of the figure
%   drawstmlines   - - draw dashed line at the stimulus on/off times
%   getdispmode    - - it returns whether or not PPT output is required
%   getpptstate    - - it returns whether or not PPT output is required
%   initdisppars   - - Initializes all global display parameters
%   mfigure        - - modified figure() command w/ other defaults...
%   mlegend        - - Displays a ledend on an axis
%   mstem          - - Discrete sequence or "mstem" plot.
%   msubplot       - - create axes in tiled positions.
%   msubplotcoord  - - create axes in tiled positions.
%   mvitshow       - - show ECG and PLETH traces
%   pptout         - - dump the plot as image of format fmt
%   pranshow       - - display data for the anesthesia project
%   prgpshow       - - display data for Glass-Pattern experiments
%   setdispmode    - - it returns whether or not PPT output is required
%   setpptstate    - - It returns whether or not PPT output is required
%   drawline           - - Draw line at the location of ginput
%   label              - - Stick a label anywhere on a figure in normalized coordinates.
%   get2axis       - - Get second axis (right) on existing axes
%   figtitle       - - puts a titile to the current figure window
%   figlabel       - - puts a text string in the figure window
%   setfront       - - sets graphic object(s) in front of others
%   setback        - - sets graphic object(s) at back of others
%
% NKL, 28.06.04
