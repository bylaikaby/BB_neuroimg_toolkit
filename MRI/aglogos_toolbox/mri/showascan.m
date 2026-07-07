function showascan(SESSION,ScanType,ScanNo,PPTOUT, NScale)
%SHOWASCAN - show any of the anatomical scans (e.g. gefi, mdeft, ir)
% SHOWASCAN(SESSION,ScanType,ScanNo,PPTOUT, NScale) loads one of the files created by
% sesloadana.m and displays the contents of the ScanNo scan of scantype
% ScanType.
%	
% See also DSPANAIMG DSPIMG SHOWIMG
% NKL, 26..12.02

if nargin < 5,
  NScale = 0;
end;

if nargin < 4,
  PPTOUT = 0;
end;

if nargin < 3,
	ScanNo = 1;
end;

if nargin < 1,
  help showascan;
  return;
end;

Ses = goto(SESSION);
ananames = fieldnames(Ses.ascan);

if exist('ScanType'),
  eval(sprintf('ascan = Ses.ascan.%s;', ScanType));
  ascan = ascan{ScanNo};
else  
  if isempty(ananames),
    fprintf('showascan: no anatomy files were found in %s\n', ...
            Ses.name);
    return;
  end;
  eval(sprintf('ascan = Ses.ascan.%s;', ananames{1}));
  ascan = ascan{ScanNo};
  ScanType = ananames{1};
end;

fprintf('SHOWASCAN: Loading ScanType %s, ScanNo %d\n', ScanType, ScanNo);
load(strcat(ScanType,'.mat'));
eval(sprintf('ana = %s{%d};',ScanType, ScanNo));
dspanaimg(ana, NScale);

if PPTOUT,
    set(gcf,'InvertHardCopy', 'off');
    imgfile = sprintf('ANA_%s_%s_%d',ana.session,ana.dir.dname,ana.dir.scanreco(1));
    imgfile = hstrfext(imgfile,'');
    print('-dmeta',imgfile);
    close all
end;




