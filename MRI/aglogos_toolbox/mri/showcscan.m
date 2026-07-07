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
% YM,  05.10.07   rewrite to supports GLM stuff, not compatible to old data.
%
%  See also sescscan dspcorimg dspglmimg dspfused


if nargin < 1,
  help showcscan;
  return;
end;

Ses = goto(SESSION);

if ~isfield(Ses,'cscan'),
  fprintf('sescscan: Session %s does not have control scans\n',Ses.name);
  return;
end;

if nargin < 2,  ScanType = [];  end
if nargin < 3,  ScanNo   = [];  end

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

if sesversion(Ses) < 2,
  MATFILE_V1 = 'cScan.mat';
  if ~exist(MATFILE_V1,'file'),
    answ = yesorno('cScan File does not exist. Process now?');
    if answ,
      sescscan(Ses);
    else
      exit;
    end;
  end;
end


if isempty(ScanType),
  % No scan-selection, get all fields
  ScanType = fieldnames(Ses.cscan);
end;
if ischar(ScanType),  ScanType = { ScanType };  end



for T = 1:length(ScanType),
  if ~any(strcmpi(ScanType{T},fieldnames(Ses.cscan))),
    error('%s ERROR: invalid ScanType=%s.',mfilename,ScanType{T});
  end
    
  ScanIdx = [];
  if isempty(ScanNo),
    scans = Ses.cscan.(ScanType{T});
    for N = 1:length(scans),
      if ~isempty(scans{N}),
        ScanIdx(end+1) = N;
      end
    end
  else
    ScanIdx = ScanNo;
  end
  for N = ScanIdx,
    if N <= 0 | N > length(Ses.cscan.(ScanType{T})),
      error('%s ERROR: invalid ScanNo=%d for %s.',mfilename,N,ScanType{T});
    end
    if isempty(Ses.cscan.(ScanType{T}){N}),
      fprintf('%s WARNING: invalid scan, skipping %s[%d].\n',mfilename,ScanType{T},N);
      continue;
    end
    
    if sesversion(Ses) >= 2,
      tcImg = sigload(Ses,N,ScanType{T});
    else
      SigName = sprintf('%s_%d',ScanType{T},N);
      if isempty(who('-file',MATFILE_V1,SigName)),
        tmptxt = sprintf('%s[%d] not found, run sescscan()? Y/N[Y]: ',ScanType{T},N);
        c = input(tmptxt,'s');
        if isempty(c), c = 'Y';  end
        switch lower(c),
         case {'y'}
          sescscan(Ses);
         otherwise
          return
        end
      end
      tcImg = load(MATFILE_V1,SigName);
      tcImg = tcImg.(SigName);
    end

    scanpar = Ses.cscan.(ScanType{T}){N};
    if isfield(scanpar,mfilename) & ~isempty(scanpar.(mfilename)),
      tmpargs = sctmerge(scanpar.(mfilename),ARGS);
    else
      tmpargs = ARGS;
    end
    if isfield(tmpargs,'ana') & ~isempty(tmpargs.ana),
      ANA = load(sprintf('%s.mat',tmpargs.ana{1}));
      ANA = ANA.(tmpargs.ana{1}){tmpargs.ana{2}};
      if length(tmpargs.ana) >= 3 & ~isempty(tmpargs.ana{3}),
        ANA.dat = ANA.dat(:,:,tmpargs.ana{3});
      end
    else
      ANA.dat = tcImg.ana;
      ANA.ds  = tcImg.ds;
    end

    tmpargs.info     = scanpar.info;
    tmpargs.scanname = upper(sprintf('%s[%d]',ScanType{T},N));
    tmpargs.figtitle = sprintf('%s %s[%d]',Ses.name,ScanType{T},N);
    
    XCOR     = tcImg.xcor;
    XCOR.ana = ANA.dat;
    dspcorimg(XCOR,[],tmpargs);
    
    tmpsz = size(tcImg.dat);
    GLM       = tcImg.glm;
    GLM.ana   = ANA.dat;
    GLM.tcdat = reshape(tcImg.dat,[prod(tmpsz(1:3)) tmpsz(4)])';
    dspglmimg(GLM, [],tmpargs);
  end
end


return


