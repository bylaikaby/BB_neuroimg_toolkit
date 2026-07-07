% CLN -- Cleaning functions for neural signals recorded in fMRI/Physiology Experiments
%
%   clnhelp         - - Denoising process for fMRI/Physiology Experiments
%   hcln            - - Invokes Help browser for "cln" functions
%
% Display Functions
%   showcln         - - Cln Display (Time, spectra, amplitude-distribution & RMS)
%
% Files
%   adx2cln         - - Remove electromagnetic interference patterns from physiology signal.
%   clnadf          - - Denoise adf data
%   clnadjevt       - - detects MRI events for cleaning interference noises.
%   clnmain         - - Remove electromagnetic interference patterns from physiology signal.
%   clnupdate       - - Updating the old "nature" sessions
%   decadf          - - Decimate original data
%   decmain         - - Decimate signal collected with video stimuli.
%   getcln          - - create the Cln structure used by our analysis programs
%   getclockerror   - - Compute difference between the QNX and Paravision clocks
%   getgrapat       - - Get gradient pattern vectors
%   getmpxdata      - - Get multiplexed data
%   sesclnadjevt    - - Creates the ClnAdjEvt.mat file with corrected MRI events
%   sesconvadf      - - converts ADF/ADFW files
%   sesgetcln       - - Read ADF files, eliminate Grad.Noise and/or Decimate
%   vclnmain        - - Remove electromagnetic interference patterns from physiology signal.
%   vdecmain        - - Decimate signal collected with video stimuli.
%   vgetframedata   - - Get frame timing of movie experiments.
%
% CHECK THIS...
%   clnadf_pvavr    - - Denoise adf files
%   clnadjevt_pvavr - - Adjust the MRI events correcting the QNX/Paravision clockDiff
%   clnmain_pvavr   - - Remove electromagnetic interference patterns from physiology signal.
%
% SPECIAL SESSIONS
%   decmain_b01nm3  - - Decimate signal collected with video stimuli.
%   getcln_b01nm3   - - THE FOLLOWING CODE LINES ARE SPECIFIC TO THIS SESSION THAT HAS
%   getcln_c01jw1   - - microstimulation experiments were done by old program.
%   getcln_n97fs    - - THE FOLLOWING CODE LINES ARE SPECIFIC TO THIS SESSION THAT HAS
%   getcln_npbugfix - - THE FOLLOWING CODE LINES ARE SPECIFIC TO THIS SESSION THAT HAS
%   getcln_ymfs     - - THE FOLLOWING CODE LINES ARE SPECIFIC TO THIS SESSION THAT HAS
%   clncheck        - - Check the spectra of the Cln and the Gradient Channel
