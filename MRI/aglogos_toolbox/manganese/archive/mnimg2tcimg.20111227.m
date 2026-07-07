function tcImg = mnimg2tcimg(Ses,GrpExp,varargin)
%MNIMG2TCIMG - Get Manganese images as a tcImg structure.
%  tcImg = MNIMG2TCIMG(Ses,GrpExp,...) returns manganese images as a tcImg structure.
%
%  NOTE :
%    This funciton will work only when manganese data are reasonably small.
%
%  VERSION :
%    0.90 27.12.11 YM  pre-release
%
%  See also mncatexps mn_tcslice_load

if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end


USE_REALIGNED = 1;
VERBOSE       = 1;


Ses = goto(Ses);
grp = getgrp(Ses,GrpExp);
anap = getanap(Ses,grp);


for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'realign' 'use_realigned' 'userealigned'}
    USE_REALIGNED = varargin{N+1};
   case {'raw' 'use_raw' 'useraw'}
    USE_REALIGNED = ~any(varargin{N+1});
   case {'verbose'}
    VERBOSE = varargin{N+1};
  end
end


% get the dimension from the anatomy.
if VERBOSE,
  fprintf(' %s: getting dimension from ana.',mfilename);
end
anaImg = anaload(Ses,grp);
nX = size(anaImg.dat,1);  nY = size(anaImg.dat,2);  nS = size(anaImg.dat,3);
nT = length(grp.exps);
clear anaImg;
if VERBOSE,
  fprintf('[%dx%dx%d nT=%d]',nX,nY,nS,nT);
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
  if isempty(TCDAT)
    TCDAT = zeros(nX,nY,nS,nT,class(tmpimg.dat));
  end
  TCDAT(:,:,iSlice,:) = tmpimg.dat;
end


tcImg = tmpimg;
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

fprintf(' done.\n');


return

