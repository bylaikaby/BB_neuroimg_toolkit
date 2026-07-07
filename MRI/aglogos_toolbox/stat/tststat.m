%TSTSTAT - Test functions for statistical analysis
% NKL 27.06.04

SesName = 'c98nm1';
ExpNo = 1;

Ses = goto(SesName);
LfpH = sigload(Ses,ExpNo,'LfpH');

stat = sigsts(LfpH);
