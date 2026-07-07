function hfunctions
%HFUNCTIONS - Functions used for the analysis of fMRI/Physiology data
% HFUNCTIONS lists the functions used in the analysis of fMRI and
% Physiology data together with a brief description. Details on the
% functionality of each routines can be obtained by clicking on the
% function name. Only a small selection of functions is explicitly
% included in the documentation. For detailed information, click on
% the appropriate directory.
%
% See also HHELP
%
% ---------------------------------------------------------------------------
% Getting started
% ---------------------------------------------------------------------------
% HGETSTARTED - Very brief description of basics steps
% HSESLOG - Log of what "was done" for each session
% HSESSION - Description of a typical session file
% ANA  - Dir with all description files
% ARCHIVE - Dir with older versions and temporary backups
%
% ---------------------------------------------------------------------------
% Batch Processing at the Session-Level, GUIs & Demos of Procedures
% ---------------------------------------------------------------------------
% HPROJECTS - Display list of current projects
% PROJECTS - Dir with all projects; read by mgui
% PROCS - Dir with all routines that run a process for all experiments
% DEMO - Dir with all Demos illustrating the usage of functions
% DOCS - All our documentation (m, html, doc etc)
% GUI - All our GUI stuff
%
% ---------------------------------------------------------------------------
% Functions & Directories for Physiology Analysis
% ---------------------------------------------------------------------------
% HNEUPRO - Documenation of physiology analysis
% HPLOTRF - Functions used to plot receptive fields
% CLN - Dir with generating the Cln structure and interference removal
% NEU - Dir with processing of neural signals  
% LFPMUA - Dir with band-passed signals, envelopes and conversions
% CFUNC - Dir with all contrast functions
% RFPLOT - Dir of functions for receptive field plotting
%
% ---------------------------------------------------------------------------
% Functions & Directories for Imaging Analysis
% ---------------------------------------------------------------------------
% HIMGPRO - Documentation of imaging analysis
% HROI - Description of "ROI" selection performed by "MROI"
% HROIFUNC - All functions using "ROI"s
% MRI - Image analysis
% JPCODE - Code written by Josef Pfeuffer (Paravision conversions)
%
% ---------------------------------------------------------------------------
% Functions & Directories for Statistical Analysis
% ---------------------------------------------------------------------------
% HSTAT - Functions used for statistical analysis of the data
% HDEPA - Documentation of dependence analysis
% CFUNC - Dir with contrast functions used in dependence analysis
%
% ---------------------------------------------------------------------------
% Directories with General Utilities
% ---------------------------------------------------------------------------
% PLT - Dir with Plotting/Display routines
% EVT - Dir for reading, sorting of events (dgz/evt file handling)
% EXPORT - Dir for exporting data and generating movies
% FIXFUNC - Dir for fixing/updating old data-structures
% IO - Dir with input/output functions (imgload, adfread etc)
% JPCODE - Dir with Paravision conversions
% LAB - Dir with contributions of various lab members
% STMIMAGES - Dir with images or place-holders for display purposes
% UTILS - Dir with miscellenous utilities
%
% ---------------------------------------------------------------------------
% Some Important Small Utilities
% ---------------------------------------------------------------------------
% INFOWHO - List the variables in each mat-file of a session
% INFO1WHO - List the variables in the 1st file of each group
% INFOGRPWHO - Displays information for all experiments of group GrpName
% INFOEVT - Display Stimulus Information from Event-File
% INFOEXP - Displays information regarding an experiments of "SESSION"
% INFOGRP - Display the fields of all groups of a session
% INFOSUPGRP - Lists & returns all super groups from description files
% INFOROITS - List roiTs structure-information
% INFOFILES - List of files updated in the last X days (Default X=1)
%
% EXPGETPAR - return experiment parameters, evt, pvpar and stm
% GETSTIMINFO - print information regarding individual stimuli
% GETTRIALINFO - print information regarding individual trials
% GETSORTPARS - Get parameters to reshape/sort signals with SIGSORT
% SIGSELEPOCH - select the signal during "EPOCH"
% SIGSORT - Sort out signals by given parameter
% XFORM - converts Sig's unit accoring to 'Method' and 'Epoch'
% GETSTIMINDICES - Gets time indices of specified object/period
% GETBASELINE - get baseline activity of signal "Sig"
% FINDCHAN - Find channels driven by the stimulus (for exclusion)
%
% Some Demos - They Included Brief Documentation Of All Steps
% ======================================================================
% SESVITAL - Get respiration and plethysmogram signals and save in vitals
% EXPGETVITEVT - Read vital signs, ie plethysmogram and respiration
% EXPGETEVT - Uses adf_info/dg_read to get all events of experiment ExpNo
% DEMORESPARTIFACTS - show the spectral power of all voxels of "ROI" Roiname
% DEMOGETPLETH - Loads the plethysmogram of the experiment ExpNo and
% MVITICA - Removal of resp artifacts by detecting independent sources
% PLETHLOAD - Loads the "MAT-file" with the recorded vital signs
% SHOWVITAL - Display the plethysmogram signal
% 
helpwin hfunctions


