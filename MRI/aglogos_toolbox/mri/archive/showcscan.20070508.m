function showcscan(SESSION,ScanType,ScanNo,varargin)
%SHOWCSCAN - Show control scans (e.g. epi13, tcImg, etc.)
% SHOWCSCAN (SESSION, ScanType, ScanNo, varargin) - Shows all cscan fields
% If the cScan matfile does not exist the function will load and analyze
% all standard scans that may not even have event files etc. The
% scans will be all saved under the cScan.mat file, with each scan
% represented by one variable (epi13, tcImg, etc.).
%
%  NOTE :
%    SHOWCSCAN() calls DSPCORIMG() and DSPFUSED().  Optional arguments for those functions
%    can be passed as a pair of optional name and value.
%    DSPFUSED() uses 
%      DEF.SWCLIP     = [0.1 0.9];
%      DEF.SWCOLORBAR = 0;
%      DEF.SWGAMMA    = 0.7;
%      DEF.SWLUTSIZE  = 64;
%      DEF.SWLUTSCALE = 1.1;
%    To change those values, call SHOWSCAN() like
%      showscan(SESSION,ScanType,ScanNo,'SWCLIP',[0.1 0.3],'SWGAMMA',1.2).
%    Those values also can be set in the description file like
%      CSCAN.epi13{2}.showcscan.SWCLIP = [0.1 0.3];
%
% Examples:
% showcscan('n03ow1') -- will show Epi13 scans
% showcscan('e04pb1') -- will show tcImg scans
%
%  EXAMPLE :
%    >> showcscan('d02hm1','epi13',2);  % will show CSCAN.epi13{2}
%    >> showcscan('d02hm1','epi13',2,'SWCLIP',[0.1 0.9]);
%
% NKL, 13.12.01
% YM,  08.05.07   supports ARGS for dspcorimg()/dspfused().
%
%  See also dspcorimg dspfused


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

if nargin < 3,
  ScanNo = [];
end

% optional arguments for dspcorimg()/dspfused()
if nargin < 4,
  ARGS = [];
else
  ARGS = [];
  % 'ARGS' for dspfused()
  %DEF.SWCLIP     = [0.1 0.9];
  %DEF.SWCOLORBAR = 0;
  %DEF.SWGAMMA    = 0.7;
  %DEF.SWLUTSIZE  = 64;
  %DEF.SWLUTSCALE = 1.1;
  for N = 1:2:length(varargin),
    switch lower(varargin{N}),
     case {'swclip'}
      ARGS.SWCLIP = varargin{N+1};
     case {'swcolorbar'}
      ARGS.SWCOLORBAR =  varargin{N+1};
     case {'SWGAMMA'}
      ARGS.SWGAMMA    =  varargin{N+1};
     case {'swlutsize'}
      ARGS.SWLUTSIZE  =  varargin{N+1};
     case {'swlutscale'}
      ARGS.SWLUTSCALE =  varargin{N+1};
    end
  end
end


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
  scandat = s.(scans{S});
  scanpar = Ses.cscan.(scans{S});
  if nargin > 2,
    scandat = scandat(ScanNo);
    scanpar = scanpar(ScanNo);
  end
  for N=1:length(scandat),
    if isfield(scanpar{N},mfilename) & ~isempty(scanpar{N}.(mfilename)),
      tmpargs = sctmerge(scanpar{N}.(mfilename),ARGS);
    else
      tmpargs = ARGS;
    end
    dspcorimg(scandat{N},[],tmpargs);
  end;
end;



