function hstat
%HSTAT - Documentation of our statistics package
% HSTAT describes some of the statistical procedures and offers
% examples of how to use the function of our statistics
% package. The R17 of Matlab has a number of userful features for
% generating contents and documentation. In the "stat" directory
% there is a contents.m file now that is updated regularly and
% reflects the latest changes we make. This module is only for
% additional information on how to use sequences of functions in
% the "stat" directory.
%
% All functions relay on the STATISTICAL, CONTROL, and OPTIMIZATION
% toolboxes of Matlab. The historgram functions are used to examine
% the distribution of signal-amplitudes. Note, that all rectified
% signals have large deviations from the normality. They vary from
% gamma to Poisson functions; Hypothesis testing must take into
% account this variability. In addition, MRI data are
% heteroschedastic, which means comparison of blank with stimulus
% periods cannot simply correct p values by Bonferroni correction.
%
% See also CFUNC HFUNCTIONS HHELP
%
% Example of procedure to estimate Type I errors
% 1 - Get group information with INFOGRP('c98nm1');
%       Exps(movie1): 1 4 7 10 13 16 19 22 26 30 41 45 
%       ........
%       Exps(spont1): 36 37 38 39 40 
% 2 - Experiments 36:40 are without stimulus (spont1)
% 3 - Make sure the .epoch field is set in the description file. It
% points to the experiments whose stimulus protocol will be used to
% fake non-blank epochs.
% 4 - SHOWHIST('c98nm1',36); will display to almost identical
% normal distributions from the blank and non-blank (faked) periods.
% 5 -   [H, p] = findchan('c98nm1','movie1','Lfp'); (uses RMS(Lfp))
%       The default assumpation, H, is that the distribution of the
%       signal values during blank and non-blank are coming from
%       the same population, that is, that stimulus is causing no
%       changes in the neural activity. Both H and p are vectors,
%       whose elements are the recording channels (or the voxels in
%       MRI); The value p is the expectation of "rejection" over
%       the repetition of the experiments (in movie1 12
%       repetitions, etc.). H = 1, of the p value is above 0.85;
%       otherwise is zero (no activation).
%       The above examples yield the following results:
%
%       0.3333 0.3333 0.1667 0.2500 0.0833 0.3333 0.4167 0.4167 0.4167
%       0.4167 0.3333 0.5000 0.4167 0.5000 0.7500
%       H is zero for all channels!
%       This is so, because we used an unrectified signal
%       (Lfp). Stimulus, in this case increase the SD of the normal
%       distribution, with no changes in the mean (it increase the
%       gamma oscillations around the same mean!
%       Using on the other hand:
%       [H, p] = findchan('c98nm1','movie1','LfpH'); (uses LfpH)
%       yields,
%       1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 0.5833 1.0 1.0  0.8333
%       which shows that 2 channels (12, 15) do not have a good signal.
%
%       Using a group with no stimulus, shows
%       [H, p] = findchan('c98nm1','spont1','LfpH'); (uses LfpH)
%       0  0  0  0  0  0  0  0  0  0  1  0  0  1  0
%       Assuming no interaction between channels (true for our
%       case), the above result suggests that with the 0.85
%       threshold we have a 0.13 probability of false-alarms.
    
helpwin hstat;
