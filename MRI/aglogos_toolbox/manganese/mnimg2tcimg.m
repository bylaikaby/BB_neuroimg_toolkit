function tcImg = mnimg2tcimg(Ses,GrpExp,varargin)
%MNIMG2TCIMG - Get Manganese images as a tcImg structure.
%  tcImg = MNIMG2TCIMG(Ses,GrpName,...)
%  tcImg = MNIMG2TCIMG(Ses,Exps,...) returns manganese images as a tcImg structure.
%
%  Supported options are :
%    'permute' : permute
%    'flipdim' : flipdim
%    'slicrop' : slice cropping
%
%  NOTE :
%    This funciton will work only when manganese data are reasonably small.
%
%  VERSION :
%    0.90 27.12.11 YM  pre-release
%    0.91 29.12.11 YM  supports EXPS as input, permute/flipdim/slicrop.
%
%  See also mncatexps mn_tcslice_load

if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end


USE_REALIGNED = 1;
VERBOSE       = 1;
V_PERMUTE     = [];
V_FLIPDIM     = [];
SLICE_CROP    = [];


Ses = goto(Ses);
if ischar(GrpExp),
  % GrpExp as a group name
  GrpName = GrpExp;
  grp = getgrp(Ses,GrpName);
  EXPS = grp.exps;
else
  % GrpExp as exp. numbers.
  EXPS = GrpExp;
  grp = getgrp(Ses,EXPS(1));
  GrpName = grp.name;
end
anap = getanap(Ses,grp);


for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'realign' 'use_realigned' 'userealigned'}
    USE_REALIGNED = varargin{N+1};
   case {'raw' 'use_raw' 'useraw'}
    USE_REALIGNED = ~any(varargin{N+1});
   case {'permute'}
    V_PERMUTE = varargin{N+1};
   case {'flipdim'}
    V_FLIPDIM = varargin{N+1};
   case {'slicrop' 'slicecrop'}
    SLICE_CROP = varargin{N+1};
   case {'verbose'}
    VERBOSE = varargin{N+1};
  end
end


% get the dimension from the anatomy.
if VERBOSE,
  fprintf(' %s: ana.size',mfilename);
end
anaImg = anaload(Ses,grp);
nX = size(anaImg.dat,1);  nY = size(anaImg.dat,2);  nS = size(anaImg.dat,3);
nT = length(EXPS);
tsel = zeros(1,length(EXPS));
for N = 1:length(EXPS),
  tmpidx = min(find(grp.exps == EXPS(N)));
  if isempty(tmpidx),
    error(' ERROR %s: Exp=%d not found in %s(%s).\n',mfilename,EXPS(N),Ses.name,grp.name);
  end
  tsel(N) = tmpidx;
end

clear anaImg;
if VERBOSE,
  fprintf('[%dx%dx%d nT=%d/%d]',nX,nY,nS,nT,length(grp.exps));
end


if USE_REALIGNED > 0,
  DIR_TCSLICE = 'TC_SLICE_REALIGNED';
else
  DIR_TCSLICE = 'TC_SLICE_RAW';
end


if VERBOSE,
  fprintf(' loading(%s)...',DIR_TCSLICE);
end


TCDAT = [];
for iSlice = 1:nS,
  matfile = sprintf('%s_%s_sl%03d.mat',Ses.name,grp.name,iSlice);
  matfile = fullfile(pwd,DIR_TCSLICE,matfile);
  tmpimg = load(matfile,'tcImg');
  tmpimg = tmpimg.tcImg;
  tmpimg.dat = tmpimg.dat(:,:,:,tsel);
  if isempty(TCDAT)
    TCDAT = zeros(nX,nY,nS,nT,class(tmpimg.dat));
  end
  TCDAT(:,:,iSlice,:) = tmpimg.dat;
end


tcImg = tmpimg;
tcImg.ExpNo = EXPS;
if isfield(tcImg,'slice')
  tcImg = rmfield(tcImg,'slice');
end
if isfield(tcImg,'pca_denoised')
  tcImg = rmfield(tcImg,'pca_denoised');
end
if isfield(tcImg,'pca')
  tcImg = rmfield(tcImg,'pca');
end

tcImg.dat = TCDAT;
tcImg.dir.tcimgfile = '';




if any(V_PERMUTE),
  if VERBOSE,  fprintf('permute[%s].',deblank(sprintf('%d ',V_PERMUTE)));  end
  tcImg.dat = permute(tcImg.dat,[V_PERMUTE 4]);
  tcImg.ds  = tcImg.ds(V_PERMUTE);
end
if any(V_FLIPDIM),
  if VERBOSE,  fprintf('flipdim[%s].',deblank(sprintf('%d ',V_FLIPDIM)));  end
  for N = 1:length(V_FLIPDIM),
    tcImg.dat = flipdim(tcImg.dat,V_FLIPDIM(N));
  end
end
if any(SLICE_CROP),
  if VERBOSE,  fprintf('slicrop[%d/%d].',length(SLICE_CROP),size(tcImg.dat,3));  end
  tcImg.dat = tcImg.dat(:,:,SLICE_CROP,:);
end



fprintf(' done.\n');


return

