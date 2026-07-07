function showstat(SesName, ExpNo, Overwrite)
%SHOWSTAT - Shows displays the results of EXPGETSTAT for SesName & ExpNo
% SHOWSTAT Reads the results of EXPGETSTAT from file or creates them
% in flight to display the general statistics of an experiment.
% NKL, 28.06.04

if nargin < 3,
  Overwrite = 0;
end;

if nargin < 2,
  help showstat;
  return;
end;

Ses = goto(SesName);
filename = catfilename(Ses,ExpNo);
if Overwrite==0 & isinfile(Ses,ExpNo,'sts'),
  fprintf('SHOWSTAT: Loading sts from %s\n', filename);
  sts = matsigload(filename,'sts');
else
  fprintf('SHOWSTAT: Structure "sts" does not exist in %s\n', filename);
  fprintf('SHOWSTAT: Creating sts...\n');
  expgetstat(Ses,ExpNo);
  sts = matsigload(filename,'sts');
end;

dspstat(sts);
