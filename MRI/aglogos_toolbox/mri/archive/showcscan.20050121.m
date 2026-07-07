function showcscan(SESSION,ScanType)
%SHOWCSCAN - Show control scans (e.g. epi13, tcImg, etc.)
% SHOWCSCAN (SESSION, ScanType) - Shows all cscan fields
% If the cScan matfile does not exist the function will load and analyze
% all standard scans that may not even have event files etc. The
% scans will be all saved under the cScan.mat file, with each scan
% represented by one variable (epi13, tcImg, etc.).
%
% Examples:
% showcscan('n03ow1') -- will show Epi13 scans
% showcscan('e04pb1') -- will show tcImg scans
% NKL, 13.12.01

if nargin < 1,
  help showcscan;
  return;
end;

Ses = goto(SESSION);

if ~isfield(Ses,'cscan'),
  fprintf('sescscan: Session %s does not have control scans\n',Ses.name);
  return;
end;

if nargin < 2,                  % No scan-selection, get all fields
  scans = fieldnames(Ses.cscan);
else
  if isa(ScanType,'char');      % User entered one scan-name
    scans{1} = ScanType;
  else
    scans = ScanType;           % User entered cell array of names
  end;
end;

filename = 'cScan.mat';
if ~exist(filename,'file'),
  answ = yesorno('cScan File does not exist. Process now?');
  if answ,
    sescscan(Ses);
  else
    exit;
  end;
end;
s = load(filename,scans{:});
scans = fieldnames(s);

for S=1:length(scans),
  eval(sprintf('myscan = s.%s;',scans{S}));
  for N=1:length(myscan),
    dspcorimg(myscan{N});
  end;
end;



