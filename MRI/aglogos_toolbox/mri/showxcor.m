function showxcor(SesName, ExpNo)
%SHOWXCOR - Display the correlation results (xcor) for SesName/ExpNo
% SHOWXCOR(SESSION,ExpNo) - shows correlation maps superimposed on
% anatomical scans, and if exists also the activated voxels in different
% regions of interest, such as different visual areas etc. The
% function calls the dspxcor which does the actual job.
%
% NKL, 25.10.02

xcor = matsigload(catfilename(SesName,ExpNo),'xcor');
dspxcor(xcor);


