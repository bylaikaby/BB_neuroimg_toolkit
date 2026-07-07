function varargout = hneu(varargin)
%HNEU - General neural-signal processing functions used by all projects
%
% See also
%   HHELP                   -- Guide for the documentation of all Phys+fMRI Software
%   /MATLAB/NEU/CONTENTS    -- Project Specific Functions
%   
% Preprocessing ofr Neurophysiology Data
%   SESDUMPPAR      -- Read all parameters and dump them in SesPar
%   SESGETCLN       -- Clean/Decimate the physiology signals
%   SESGETBLP       -- Split the Cln structure into different frequency bands
%   SESGETSPK       -- Extract spike times and create Spike Density Functions
%   FINDCHAN        -- Find bad channels and exclude by setting the findch field
%
% Visualization of Neurophysiology Data
%   SHOWCH          - - Group all contrast of a group by calling catconfunc
%   SHOWCHAN        - - Display the signal of each channel separately
%   SHOWCLN         - - Cln Display (Time, spectra, amplitude-distribution & RMS)
%   DSPSIG          - - Display a signal 
%   DSPPSTH         - - Display histogram data from single units
%
% ------------------------------------------------------------------------------------------
%
% Old Analysis Steps (Currently we use the BLP-Extraction Method)
%   SESGETSIGS - This function cleans or decimates (or both) the raw neurophysiological
%       signal, and then extracts the basic bands that we use for our analysis; It invokes the
%       following matlab functions, each of which can be called directly when the data are
%       already partly processed;
%	SESDUMPPAR - Read all parameters and dump them in SesPar
%	SESGETCLN - Clean/Decimate the physiology signals
%	SESCLNSPC - Generate spectrograms for denoised signal Cln
%	SESGETLFPMUAFLT - Filter, rectify and decimate
%	SESGETLFPMUA - Average spectrogram bands
%	SESGETSPK - Extract spike times and create Spike Density Functions
%	FINDCHAN - Find bad channels and exclude by setting the findch field
%
% Detailed Explanation of Individual Steps
% SESDUMPPAR - Read all parameters and dump them in SesPar
% SESGETCLN - Clean/Decimate the physiology signals
% "Cln" functions
%   CLNHELP
%   SESCLNADJEVT - Creates the "ClnAdjEvt" file with corrected MRI events
%      CLNADJEVT
%   SESGETCLN - Read ADF files, eliminate Gradient Noise and/or Decimate
%      GETCLN
%      CLNMAIN, VCLNMAIN
%      DECMAIN, VDECMAIN
%
% SESCLNSPC - Generate spectrograms for denoised signal Cln
% "ClnSpc" functions
%   SESCLNSPC - Make spectrograms for the Cln signal of each experiment
%      SIGSPC
%
% SESGETLFPMUA - "pLfpL", "pLfpM", "pLfpH", pMua ClnSpc-averages
% "Lfp/Mua/Spkt" functions
%   SESGETLFPMUAFLT - Get Lfp/Mua/Gamma etc
%      GETBANDSFLT
%   SESGETLFPMUA - Get spectral powers with the Lfp and Mua ranges
%      GETLFPMUA
%
% We use two types of band-passed signals: (a) Signals that are filtered and resampled with
% 250Hz, and (b) Signals that are created by averaging between certain frequency bands of the
% spectrogram, which has a temporal resolution of TR; The following lines illustrate the
% frequency ranges used for filtering (dots are replace by dashes because they confuse the
% Matlab parser, which stops treating the capital names as links):
%
% anap-bands-Lfp		= [1 90];		% entire "lfp" range (unrectified)
% anap-bands-Gamma		= [24 90];		% gamm "lfp" range (unrectified)
% anap-bands-LfpL		= [1 12];		% delta-theta (rectified)
% anap-bands-LfpM		= [12 24];		% alpha-beta (rectified)
% anap-bands-LfpH		= [24 90];		% gamma (rectified)
% anap-bands-Mua		= [500 2500];	% spiking (rectified)
%  
% anap-bands-lfpcutoff	= 10;			% Low pass filter after rectification
% anap-bands-muacutoff	= 100;			% Low pass filter after rectification
% anap-bands-samprate	= 250;			% Resample at 250Hz
%
% In addition, we have the pLfpL, pLfpM, pLfpH, and pMua that are
% averages of the spectrogram within the ranges:
%
% anap-bands-LfpL		= [1 12];		% delta-theta (rectified)
% anap-bands-LfpM		= [12 24];		% alpha-beta (rectified)
% anap-bands-LfpH		= [24 90];		% gamma (rectified)
% anap-bands-Mua		= [500 2500];	% spiking (rectified)
%
% SESGETSPK - Extracts spikes and SDFs from "Cln" data
%      GETSPK
%
% FINDCHAN - Find channels driven by the stimulus (for exclusion) Before continuing with
% analysis and in particular before applying statistical test the user *must* check of the
% quality of individual channels; You can visualize the channels by loading a signal and
% invoking the function showchan(Sig); To ensure bias-free decision is better to use the
% FINDCHAN utility;
%
% varargout = FINDCHAN (SesName,GrpName,SigName) loads the desired signal (SigName) from a
% control group during which stimulation is expected to cause changes in neural activity and
% examines whether stimulus-induced modulation is significant; It returns all channels driven
% by the stimulus;
%
% H = FINDCHAN (SesName,GrpName,SigName) returns a string of zeros and ones; Zero means the
% default assumption (H0) cannot be rejected, and in this case means bad channel (default is
% that background and stimulus activity are coming from the same population); One means they
% are different;
%
% [H,p] = FINDCHAN (SesName,GrpName,SigName) the probability of 0/1 over all experiments of the
% group;
%
% Important Note:
%
% To select channels according to whether or not they show changes in neural activity elicited
% by the stimulus one cannot simply apply a t-test between the values of the signal during
% stimulation and during blank; For all unretified signal the mean of stimulus-induced activity
% will be the same with that observed in the resting state; We have to compare rectified
% signals or variances; The onset of the stimulus causes increase of variance; Alternatively we
% can compare rms values;
%  
% "VLfp/VMua/VSpk" functions
%   SESGETRF - Compute receptive fields of cells by reverse correlation
%      GETRF
%
% I/O Functions
% -----------------------------
% SIGLOAD - Loads the signal for Ses, ExpNo/GrpName
% STMLOAD - generate stimulus data for plotting
% ADFINFO - read adf file information
% ADFREAD - read adf file
%
% Analysis Utilities
% -----------------------------
% EXPGETPAR - return experiment parameters, evt, pvpar and stm
% GETSTIMINFO - print information regarding individual stimuli
% GETTRIALINFO - print information regarding individual trials
% GETSORTPARS - Get parameters to reshape/sort signals with SIGSORT
% SIGSORT - Sort out signals by given parameter
% SIGSELEPOCH - select the signal during "EPOCH"
% XFORM - converts Sig's unit accoring to 'Method' and 'Epoch'
% GOTO - Read session file and go to the corresponding directory
% GETGRP - Returns the group-structure by experiment number or group name
% EXPGETRMS - Get RMS for signal SigName read from file
% RMS - Compute RMS of signal passed as argument
% SIGHIST - Makes histogram of signal-values
% DSPHIST - Displays histogram
% EXPGETHIST - Runs SIGHIST for all signals in HISTSIGS
% SESGETHIST - Runs EXPGETHIST for entire session
%
% Display Functions
% -----------------------------
% HSHOW
% SHOW - display signals of mat and group files
%

%helpwin hneu
web(sprintf('file://%s',which('hneu.html')),'-browser');
