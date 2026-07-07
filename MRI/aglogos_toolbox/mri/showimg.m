function showimg(varargin)
%SHOWIMG - GUI interface to browse images
% SHOWIMG (varargin) is used to browse images and debug scans. It
% will display one slice at a time and permit the definition of
% ROIs. If the Time Display is set the time series for the selected
% ROI will be displayed in the preferred units (SD, Percent, Raw,
% etc). Arguments to SHOWIMG can be:
%  
% SHOWIMG (SESSION,ExpNo)
% SHOWIMG (SESSION,ScanName,ScanNo)
% SHOWIMG (SesDir,pvScanNo,pvRecoNo)
%
% EXAMPLES:
% ================================
% 1. SHOWIMG ('m02lx1',1);         % With description file
% 2. SHOWIMG ('n03.ow1',25);       % Without description file; directly 2dseq
% 3. SHOWIMG ('e04pb1',1);         % With description file; CHECK Variability
% 
% DISPLAYING A CONTROL SCAN 
% ================================
% Ses = goto('n03ow1');
% load('cScan.mat');
% dspimg(tcImg);
%
% NOTE: The example (2.) will not work if the computer is
% not on the network (laptop during trips..) because it directly
% accesses data on Wks8-like data-servers.
%
% NKL, 10.04.04
  
if nargin < 2,
  help showimg;
  return;
end;

DescriptionFile = 1;
if isa(varargin{1},'char'),
  if findstr(varargin{1},'.'),  % It's directory name
    SesDir = varargin{1};
    DescriptionFile = 0;
  else
    SESSION = varargin{1};
  end;
else
  Ses = varargin{1};
end;

if DescriptionFile,
  if isa(varargin{2},'char'),	% Either ascan/cscan or Group File
	if ~exist('Ses'),
	  Ses = goto(SESSION);
      if isempty(Ses),
        fprintf('SHOWIMG: Non existing session: %s\n',SESSION);
        return;
      end;
	end;
	if isgrpname(Ses,varargin{2}),
	  GrpName = varargin{2};
	else
      fprintf('SHOWIMG: Group %s does not exist in Session: %s\n',...
              varargin{2}, Ses.name);
      fprintf('SHOWIMG: Check your spelling or the description file\n');
      return;
	end;
  else
    ExpNo = varargin{2};
  end;
  if ~exist('Ses','var'),
    Ses = goto(SESSION);
    if isempty(Ses),
      fprintf('SHOWIMG: Non existing session: %s\n',SESSION);
      return;
    end;
  end;
else
  pvScanNo = varargin{2};
  if nargin == 3,
    pvRecoNo = varargin{3};
  else
    pvRecoNo = 1;
  end;
end;

if DescriptionFile,
  if exist('GrpName'),
    fprintf('SHOWIMG: Reading %s from tcImg.mat\n',GrpName);
	tcImg = matsigload('tcImg.mat',GrpName);
  else
    fprintf('SHOWIMG: Reading tcImg from Experiment %d\n',ExpNo);
    tcImg = sigload(Ses,ExpNo,'tcImg');
  end
  dspimg(tcImg);
else
  fprintf('SHOWIMG: Paravision 2dseq scan was requested\n');
  fprintf('SHOWIMG: Reading File ...');
  tcImg = scanload(SesDir,pvScanNo,pvRecoNo);
  fprintf('Done!\n');
  fprintf('SHOWIMG: Does not handle 2dseq files; Invoking qview(tcImg)\n');
  qview(tcImg);
end;



