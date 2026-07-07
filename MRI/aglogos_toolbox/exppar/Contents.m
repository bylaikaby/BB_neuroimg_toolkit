% EVT -- Event Reading, Handling and Viewing
% The directory contains all initial QNX event stuff and the functions, which based on these
% events can reorganize the data. Particularly important are the utilities that can be used
% to convert long observation periods into trial sorted according to the task or stimulus.
%
% Experiment Parameters (e.g. for updating stm in Signals)J
%   expgetpar      - - Returns experiment parameters, evt, pvpar and stm (See sesdumppar)
%   expgetstm      - - Provide stimulus-related information (stm, epoch, boxcar, hemo)
%   sesdumppar     - - Get/Load all experimental parameteters of the session.
%
% Information Needed Before Sorting Signals According to Trial or Stimulus
%   getstiminfo    - - Returns information regarding individual stimuli
%   gettrialinfo   - - Returns information regarding individual trials
%   getexpinfo     - - Get information about SesName, ExpNo and Group
%   findstimpar    - - Get index and parameters of stimID (SortPar is returned from getsortpar)
%   findtrialpar   - - Get index and parameters of trialID (SortPar is returned from getsortpar)
%
% Sorting Data According to Trial or Stimulus (e.g. stimXX or tiralXX, XX = 01,02,...)
%   sesgettrial    - - Split observation periods into trials
%   gettrial       - - Split observation period in trials and return average response per trial.
%   sesgetsortpars - - Get parameters for re-sorting signal in trials
%   getsortpars    - - Get parameters required to reshape/sort signals with the sigsort function
%   sessigsort     - - Sort out signals by given parameter
%   sigsort        - - Sort out signals by given parameter
%   sigselepoch    - - Select Epoch of Signal (blank, nonblank, stimXX, triaXX)
%   getstim        - - Return trial from observation period
%
% Vital Signs and Eye Movements
%   expgeteyemov   - - Read eye movement traces
%   sesgeteyemov   - - Read eye position data and save in MAT file
%   expgetvitevt   - - Read vital signs, i.e. plethysmogram and respiration
%   sesgetvitevt   - - Read ecg/resp signals of entire session and save the in MAT files
%
% Loading and Saving of Event Files
%   dumpdgz        - - print event information in given trials of DGZ.
%   expgetevt      - - Uses adf_info/dg_read to get all events of experiment ExpNo
%
% Small Utilities
%   selectevt      - - Select an event with certain type/subtype
%   selectprm      - - Returns event parameters of certain type/subtype
%   getevtcodes    - - Get event codes used by the QNX programs (E_MAGIC, E_NAME,...)
%   expgettfactor  - - returns timing factor for adf/evt/img.
%   hevt           - - Invokes Help browser for "evt" functions
%   trial2obsp     - - Convert trial-based time series into continuous obserpvation periods
