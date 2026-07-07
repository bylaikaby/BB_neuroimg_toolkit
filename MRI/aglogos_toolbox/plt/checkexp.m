function checkexp(SesName, ExpNo)
%CHECKEXP - Check the quality of signals in experiment ExpNo (used during data collection)
% CHECKEXP (SesName, ExpNo) assumes online updating of the session description file. It also
% expects that the "to be tested" scan was reconstracted and that adfw and dgz files were
% converted. In addition, the disk of DataMatlab must be also defined. So, in short, to get
% online feedback by using this function do the following:
%
% 1. Run your scan and collect MRI/Phys data
% 2. Reco Scan
% 3. Convert adfw/dgz
% 4. Enter the experiment entry into your description file (check directories)
% 5. Define output directory (e.g. //wks20/DataMatlab or ./DataMatlab
% 6. Call: checkexp(SesName, ExpNo);
%
% NKL, 09.02.06

if nargin < 2,
  help checkexp;
  return;
end;

Ses = goto(SesName, ExpNo);

sesdumppar(Ses, ExpNo);
sesgetcln(Ses, ExpNo);
if 0,
sesgetblp(Ses, ExpNo);
end;
sesrmsts(Ses,ExpNo);
sesgettrial(Ses,ExpNo,'rmsCln');

sesascan(Ses);
sesimgload(Ses,ExpNo);
if ~exist('Roi.mat','file'),
  sesroi(Ses);
end;
sesareats(Ses,ExpNo);
sescorana(Ses,ExpNo);
showneumri(Ses,ExpNo);
