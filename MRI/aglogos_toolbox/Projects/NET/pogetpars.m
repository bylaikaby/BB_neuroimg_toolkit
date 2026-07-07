function [ANAP, ROI, GRPP, FLICK, ESTIM, POLAR] = pogetpars(SesName, ARGS)
%POGETPARS - Defines Common Parameters for the NET-fMRI Project (PONS)
%
%  See also rpgetpars rpgetpars_monkey rpgetpars_rat

[ANAP, ROI, GRPP, FLICK, ESTIM, POLAR] = rpgetpars(SesName, ARGS);

% Update parameters specific to the PONS sessions
ANAP.project.datadir        = strrep(ANAP.project.datadir,'DataHipp','DataPons');
