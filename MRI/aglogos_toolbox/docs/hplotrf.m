function hplotrf
%HPLOTRF - Functions used to plot receptive fields
% See also
% SESGETRF (Ses,EXPS) LfpPow, MuaPow, etc
% SHOWGRPRF ('c98nm1','zmovie01') shows RF computed from a group
% SHOWSUPRF ('c98nm1') shows RF from supergroups
% SHOWRF ('g02nm1',17) shows RF of computed from an experiment
% DSPGRPRF (VLfp,VMua,2,FileName)
% DSPRF (VLfp,VMua,2,FileName);
% MKRFGRID Draws a generic grid for positioning the RF/Movies
% PLOTRF (Ask for directory/file interactively)
%       if the movies used in the session were never used before, then
%       an average and std of the several samples of approximately
%       2500 frames must be computed to be used for statistical
%       evaluation of the site-RF; To do this we use movmean, or for
%       the entire session (if all movies are new - we can check with
%       exist(moviename,'file')) sesmovmean
% MOVIEMEAN (Ses,GrpName) load a movie file defined in the Sig_movie structure
% SESMOVMEAN (Ses) will do all new movies of the session
%
helpwin hplotrf

