function PVPAR = pv_getpvpars(varargin)
%PV_GETPVPARS - Get ParaVision imaging parameters, compatible with GETPVPARS().
%  PVPAR = PV_GETPVPARS(IMGFILE,...)
%  PVPAR = PV_GETPVPARS(SESSION,EXPNO,...) gets ParaVision's imaging parameters compatible
%  with GETPVPARS().
%
%  EXAMPLE :
%    pvpar = pv_getpvpars('\\wks8\mridata\B07.371\46\pdata\1\2dseq');  % EPI
%
%  VERSION :
%    0.90 12.05.14 YM  pre-release
%    0.91 26.05.14 YM  use method.PreScanDelay for spectroscopy.
%    0.92 03.02.14 YM  supports "ser".
%    0.93 22.10.14 YM  fix a problem of PULPROG: '<rp_dualsliceEPI.ppg>' where reco=x2slices.
%    0.94 27.03.15 YM  bug fix for sesascan().
%    0.95 05.11.15 YM  bug fix for RECO-transposition.
%
%  See also pv_imgpar getpvpars

if nargin < 1,  eval(sprintf('help %s;',mfilename));  return;  end

if ischar(varargin{1}) && ~isempty(strfind(varargin{1},'2dseq')),
  % Called like pv_imgpar(2DSEQFILE)
  imgfile = varargin{1};
  ivar = 2;
elseif ischar(varargin{1}) && ~isempty(strfind(varargin{1},'fid')),
  % Called like pv_imgpar(FIDFILE)
  imgfile = varargin{1};
  ivar = 2;
elseif ischar(varargin{1}) && ~isempty(strfind(varargin{1},'ser')),
  % Called like pv_imgpar(SERFILE)
  imgfile = varargin{1};
  ivar = 2;
else
  % Called like pv_imgpar(SESSION,ExpNo)
  if nargin < 2,
    if strcmpi(varargin{1},'test'),
      sub_do_test();
    else
      error(' ERROR %s: missing 2nd arg. as ExpNo.\n',mfilename);
    end
    return;
  end
  ses = getses(varargin{1});
  if any(ses.expp(varargin{2}).scanreco(2)),
    imgfile = expfilename(ses,varargin{2},'2dseq');
  else
    imgifle = expfilename(ses,varargin{2},'fid');
  end
  ivar = 3;
end

% check the file.
if ~exist(imgfile,'file'),
  error(' ERROR %s: ''%s'' not found.',mfilename,imgfile);
end


% SET OPTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
reco      = [];
acqp      = [];
imnd      = [];
method    = [];
for N = ivar:2:length(varargin),
  switch lower(varargin{N}),
   case {'reco'}
    reco = varargin{N+1};
   case {'acqp'}
    acqp = varargin{N+1};
   case {'imnd'}
    imnd = varargin{N+1};
   case {'method'}
    method = varargin{N+1};
  end
end


if isempty(acqp),   acqp   = pvread_acqp(imgfile);    end
if isempty(method), method = pvread_method(imgfile,'verbose',0);  end

if any(strfind(imgfile,'2dseq')),
  if isempty(reco),   reco   = pvread_reco(imgfile);    end
end
imgp = pv_imgpar(imgfile,'acqp',acqp,'reco',reco,'method',method);

PVPAR.imgfile = imgp.filename;
if isfield(method,'PVM_VoxArrSize') && any(method.PVM_VoxArrSize)
PVPAR.nx      = imgp.imgsize(1);
PVPAR.ny      = imgp.imgsize(2);
PVPAR.nt      = imgp.imgsize(end);
PVPAR.nsli    = 1;
PVPAR.nspect  = imgp.imgsize(1);
PVPAR.tspect  = imgp.dimsize(1);
PVPAR.nvox    = imgp.imgsize(2);
PVPAR.voxsize = imgp.voxsize;
  if isfield(method,'PreScanDelay') && any(method.PreScanDelay)
  PVPAR.prescan = method.PreScanDelay / 1000;  % [s]
  end
else
PVPAR.nx      = imgp.imgsize(1);
PVPAR.ny      = imgp.imgsize(2);
if length(imgp.imgsize) > 3
PVPAR.nt      = imgp.imgsize(4);
else
PVPAR.nt      = 1;
end
PVPAR.nsli    = imgp.imgsize(3);
end
PVPAR.fa      = imgp.flip_angle;
PVPAR.nseg    = imgp.nseg;
PVPAR.imgtr   = imgp.imgtr;
PVPAR.slitr   = imgp.slitr;
PVPAR.segtr   = imgp.segtr;
PVPAR.effte   = imgp.effte;
PVPAR.recovtr = imgp.recovtr;
PVPAR.gradtype = [];


if any(strfind(lower(acqp.PULPROG),'dualslice')),
  for N = 1:PVPAR.nseg,
    PVPAR.gradtype = cat(2,PVPAR.gradtype,ones(1,PVPAR.nsli/2)*N);
  end
else
  for N = 1:PVPAR.nseg,
    PVPAR.gradtype = cat(2,PVPAR.gradtype,ones(1,PVPAR.nsli)*N);
  end
end
PVPAR.graddur  = -1;
% PVPAR.fov      = imgp.fov;
% PVPAR.res      = imgp.res;
% bug fix to avoid RECO_transposition
PVPAR.fov      = imgp.imgsize(1:2).*imgp.dimsize(1:2);
PVPAR.res      = imgp.dimsize(1:2);

PVPAR.slithk   = imgp.slithk;
PVPAR.isodist  = acqp.ACQ_slice_offset;
PVPAR.sligap   = acqp.ACQ_slice_sepn - acqp.ACQ_slice_thick;
PVPAR.dstime   = [];
PVPAR.ds       = [];
if isfield(method,'NDummyScans'),
  PVPAR.ds = method.NDummyScans;
elseif isfield(acqp,'DS'),
  PVPAR.ds = acqp.DS;
end
if isfield(acqp,'MP_DummyScanTime'),
  PVPAR.dstime = acqp.MP_DummyScanTime;
else
  PVPAR.dstime = PVPAR.ds * PVPAR.segtr;
end
PVPAR.acqp     = acqp;
PVPAR.method   = method;
PVPAR.reco     = reco;

    
return;
