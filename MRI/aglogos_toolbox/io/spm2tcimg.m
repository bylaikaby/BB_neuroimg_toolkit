function varargout = spm2tcimg(varargin)
%SPM2TCIMG - creates tcImg from ANALIZE-7 format of SPM.
%  TCIMG = SPM2TCIMG(IMGFILES)
%  TCIMG = SPM2TCIMG(SESSION,EXPNO) creates tcImg structure from .img/hdr files.
%
%  VERSION :
%    0.90 06.06.05 YM  pre-release
%
%  See also TCIMG2SPM, HDR_READ EXPREALIGN

if nargin == 0,  help spm2tcimg; return;  end

DIR_SPM = 'spm';

if nargin == 1,
  if ischar(varargin{1}),
    IMGFILES = { varargin{1} };
  else
    IMGFILES = varargin{1};
  end
  % called like spm2tcimg(IMGFILES)
  % extract session, expno from "session_expno_xxxxx.img".  
  [fp,fr] = fileparts(IMGFILES{1});
  idx = findstr(fr,'_');
  %SESSION = fr(1:idx(1)-1);
  SESSION = fr((-6:-1)+idx(1));  % do like this to support files with 'r' prefix.
  if length(idx) == 1,  idx(end+1) = length(fr)+1;  end
  %EXPGRP   = fr(8:idx(end)-1);
  EXPGRP   = fr((1:3)+idx(1)); % do like this to support files with 'r' prefix.
  Ses      = goto(SESSION);
  if isempty(str2num(EXPGRP)),
    % EXPGRP as group name
    grp   = getgrp(Ses,EXPGRP);
    ExpNo = grp.exps;
  else
    % EXPGRP as ExpNo
    ExpNo = str2num(EXPGRP);
    grp   = getgrp(Ses,ExpNo);
  end
  % CREATE 'tcImg' like structure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  tcImg.session		= Ses.name;
  tcImg.grpname		= grp.name;
  tcImg.ExpNo			= ExpNo;
  tcImg.dir.dname		= 'tcImg';
  tcImg.dir.scantype	= '';
  tcImg.dir.scanreco	= [];
  tcImg.dir.imgfile	= [];
  tcImg.dir.evtfile	= '';
  tcImg.dir.matfile	= '';
  tcImg.dir.tcimgfile	= '';
  % DISPLAY
  tcImg.dsp.func		= 'dspimg';
  tcImg.dsp.args		= {};
  tcImg.dsp.label		= {'Readout'; 'Phase Encode'; 'Slice'; 'Time Points'};
  tcImg.usr.imgcrop   = [];
  tcImg.dat           = [];
  tcImg.ds            = [];
  tcImg.dx            = grp.imgtr;
else
  % called like spm2tcimg(SESION,EXPNO/GRPNAME)
  Ses     = goto(varargin{1});
  if ischar(varargin{2}),
    tmpf  = dir(fullfile(DIR_SPM,sprintf('r%s_%s*.img',Ses.name,varargin{2})));
    grp   = getgrp(Ses,varargin{2});
    ExpNo = grp.exps;
    tcImg = mgettcimg(Ses,ExpNo(1));
    tcImg.ExpNo = grp.exps;
  else
    tmpf  = dir(fullfile(DIR_SPM,sprintf('r%s_%03d*.img',Ses.name,varargin{2})));
    ExpNo = varargin{2};
    grp   = getgrp(Ses,ExpNo);
    tcImg = mgettcimg(Ses,ExpNo);
  end
  for N = length(tmpf):-1:1,
    IMGFILES{N} = fullfile(DIR_SPM,tmpf(N).name);
  end
  IMGFILES = sort(IMGFILES);
end
  



% GET DATATYPE/SIZE from header info. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[fp,fr] = fileparts(IMGFILES{1});
hdrfile = fullfile(fp,sprintf('%s.hdr',fr));	% like spm/m02th1_001_xx.hdr
HDR  = hdr_read(hdrfile);
nx   = HDR.dime.dim(2);
ny   = HDR.dime.dim(3);
nz   = HDR.dime.dim(4);
xres = HDR.dime.pixdim(2);
yres = HDR.dime.pixdim(3);
zres = HDR.dime.pixdim(4);

if HDR.dime.datatype == 2,
  DATATYPE = 'int8';
elseif HDR.dime.datatype == 4,
  DATATYPE = 'int16';
elseif HDR.dime.datatype == 8,
  DATATYPE = 'int32';
elseif HDR.dime.datatype == 16,
  DATATYPE = 'single';
elseif HDR.dime.datatype == 64,
  DATATYPE = 'double';
end

if isempty(tcImg.ds),
  tcImg.ds = [xres yres zres];
end


DAT = zeros(nx,ny,nz,length(IMGFILES),DATATYPE);
for N = 1:length(IMGFILES),
  fid = fopen(IMGFILES{N},'rb');
  tmpdat = fread(fid,inf,DATATYPE);
  fclose(fid);
  DAT(:,:,:,N) = reshape(tmpdat,nx,ny,nz);
end

tmpidx = find(isnan(DAT(:)));
if ~isempty(tmpidx),  DAT(tmpidx) = 0;  end
clear tmpidx;


tcImg.dat = DAT;
if ~isfield(tcImg,'centroid') || isempty(tcImg.centroid),
  tcImg.centroid = mcentroid(tcImg.dat,tcImg.ds);
end

if nargout,
  varargout{1} = tcImg;
end


return;
