function hshow
%HSHOW - Help for all dispaly functions
% HSHOW lists all display functions used by our analysis
% package. Only functions starting with show are displayed; that is
% only functions that operated on file-level. Functions starting
% with dsp operate on signals directly and are usually invoked by
% the corresponding show... function or the show.m which calls the
% display function, whose name appears in the Sig.dsp.func field.
%
% See also PLT
%
% Cortical Impedance Measurements
% ====================================================================  
% AXELCONVERT (PlotID) - shows cortical impedance results
%
% General Utilities
% ====================================================================  
% SHOW - display signals of mat and group files
% SHOWCHAN - display all channels separately
% SHOWRES - Show all data for the SFN03 analysis
% SHOWSUPRES - Show all data for the SFN03 analysis
% SHOWSFN - Summary of plots and images from the SFN2003 Data
%       ***EXAMPLES***  
%       SHOWSFN ('zmov','chcfGrps');
%       SHOWSFN ('zpol','chcfGrps');
%       SHOWSFN ('zspo','chcfGrps');
%
% Display individual signals
% ====================================================================  
% SHOWCLN - Show Cln signal
% SHOWSPC3 - shows the spectrogram of Cln
% SHOWSIGFFT - show the spectra of all signals we use (needs work!)
% SHOWICADENOISE - show "ICA" results (DEMO)
% SHOWVITAL (SesName,ExpNo) - Shows the plethysmogram and its spectra
% SHOWVITAL (SesName) - Like showvital(SesName,ExpNo) but for all experiments
%
% Neural and "BOLD" responses to brief pulses
% ====================================================================  
% SHOWPULSE - Shows the data collected with short pulse-stimuli
% SHOWBPULSE - Shows "BOLD" responses to very short pulse-stimuli
% SHOWCRA - Apply Wiener analysis to group data
% SHOWMODEL - Show model for SesName and group GrpName
% SHOWCODECO - Demonstrate LTI-systems analysis
%
% Reverse Corr and "RF" Fields computed via different signals
% ====================================================================  
% SHOWAUTOPLOT - shows autoplot data to select signals (eg Flash Sup)
% SHOWELEGRID - shows the grid of electrodes or voxels
% SHOWRF - Show site-"RF" structure for different frequency bands
% SHOWGRPRF - Show site-"RF" structure for different frequency bands
% SHOWSUPRF - Show site-"RF" structure for different frequency bands
% SHOWAVGHRF - Show typical "HRF" as average from different animals
%       ***EXAMPLES***  
%       SESSUPGRP ('c98nm1','movie1','cf') - kernel-covariance for group movie1
%       SESSUPGRP ('c98nm1','movie1','ch') - coherence for group movie1
%       SESSUPGRP ('c98nm1','movie1','rf') - receptive field analysis
%       SESSUPGRP ('c98nm1',[],'cf') - for all groups
%       SESSUPGRP ('c98nm1',[],'ch') - coherence for all groups
%
% Dependence Analysis (Correlation, Coherence, Information Theor)
% ====================================================================  
% SHOWCH - Group all contrast of a group by calling catconfunc
% SHOWCHCF - plot coherence against distance for entire session
% SHOWHRF - show sesroi results ("ROI"s xcor data etc) for group
% SHOWSFNMRI - plot "MRI" coherence against distance for entire session
% SHOWSFNMRINEU - plot "MRI"/Neu coherence against distance for entire session
%       ***EXAMPLES***  
%       SHOWCHCF (session,SuperGroup) - "MRI" confunc/coherence
%       SHOWCHCF ('m02lx1','zmov01');
%       SHOWCHCF ('n02m21','zmov01');
%       SHOWCHCF ('b01mz1','zmov01');
%       SHOWCHCF ('b01mz1','zspo01');
%
% Statistical Analysis
% ====================================================================  
% SHOWMOVIETTEST - show sesroi results ("ROI"s xcor data etc) for group
% SHOWPTS - show sesroi results ("ROI"s xcor data etc) for group
% SHOWSPF - show spike forms and statistics
% SHOWSTAT - shows the mean/std of different epochs to assess selectivity
%  
% Display Images, "ROI"s, and Voxel Time Series
% ====================================================================  
% SHOWIMG - "GUI" interface to browse images
% SHOWASCAN - show any of the anatomical scans (eg gefi, mdeft, ir)
% SHOWCSCAN - Show control scans (eg "EPI13", tcImg, etc)
% SHOWIMGINFO - display Image info and store in meta file
% SHOWROITS - Display "ROI" time series for SesName and experiment ExpNo
% SHOWTC - Get time series of a roipoly-defined region of interest
% SHOWVITAL - Display the plethysmogram signal
% SHOWXCOR - show sesroi results ("ROI"s xcor data etc) for group
% DSPCORIMG (xcor) - Shows the xcor maps (xcor{}_dat)
% SHOWXCORPLOT - show sesroi results ("ROI"s xcor data etc) for group
% SUPTITLE - puts a title above all subplots
%
% Binocular Rivalry
% ====================================================================  
% SHOWRVWAVE - Displays the Wilson-Blake Rivalry Waves
%
% Chemistry Stuff
% ====================================================================  
% SHOWPHDEPEND - plots the 1/"T1"-conc dependency at several ph Valuse
% SHOWPHFRAMES - show "T1" Signal as function of ph
%
% Main Analysis "GUI" and its display subroutines
% ====================================================================  
% MGUI - Sorts out projects and runs procs interactively or in batch
% IMGVIEWER - Browse 2dseq or tcImg Image-Data
% SESROI (SesName, [getroi|update|reset]) "ROI" definitions
% DSPROITS (roiTs) - Shows the time series of each area/"ROI"
% DSPIMG - Check function's header
% QVIEW  - Check function's header
%  
  
helpwin hshow


