function sesdeconvolve(SESSION,EXPS)
%SESDECONVOLVE - Perform deconvolution using MDECCONVOLVE
% SESDECONVOLVE - is to model the neural data from the measure BOLD
% data.
%
Ses = goto(SESSION);

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

for N = 1:length(EXPS),
  mdeconvolve(Ses,EXPS(N));
end;
