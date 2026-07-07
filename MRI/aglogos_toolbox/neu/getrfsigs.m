function gSigs = getrfsigs(SESSION)
%GETRFSIGS - Get RF signals that are grouped by catsig/catgrpmovie etc
% GETRFSIGS selects of the movie-relevant signals VLfp... VMua etc.
%
%
% NKL 29.09.03

Ses = goto(SESSION);
gSigs = Ses.ctg.GrpRFSigs;
  




