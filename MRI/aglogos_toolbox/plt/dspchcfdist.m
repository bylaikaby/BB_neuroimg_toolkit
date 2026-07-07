function dspchcfdist(Sig)
%DSPCHCFDIST - plot coherence against distance for entire session
% DSPCHCFDIST (Sig) plots the concatanated data resulting from
% sessupimggrp(SesName).

plot(Sig.dist,Sig.dat,'ks:','markerfacecolor','k');
grid on;
