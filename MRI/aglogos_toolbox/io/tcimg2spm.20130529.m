function varargout = tcimg2spm(varargin)
%TCIMG2SPM - dumps tcImg structure into ANALIZE-7 format for SPM.
%  [IMGFILES,HDRFILES] = TCIMG2SPM(TCIMG,...)
%  [IMGFILES,HDRFILES] = TCIMG2SPM(SESSION,EXPNO,...) dumps the given tcImg structure to 
%  spm/.img,.hdr for analysis with SPM and returns output file as IMGFILES for binary
%  images, HDRFILES for header files.
%  Supported options are...
%    SaveDir    : directory to save, default as 'spm'.
%    ExportAs3D : flag to export as 3D, default as 1.
%    DataType   : data type, default as class(tcImg.dat).
%    Use2dseq   : export directrly from 2dseq.
%
%  EXAMPLE :
%    % exporting "tcImg" structure, each time point as a separated file.
%    tcimg2spm(Ses,ExpNo,'ExportAs3D',1)
%    % exporting from "2dseq", ecah time point as a separated file.
%    tcimg2spm(Ses,ExpNo,'ExportAs3D',1,'use2dseq',1,'')
%
%  VERSION :
%    0.90 06.06.05 YM  pre-release
%    0.91 13.03.07 YM  supports 'ExportAs3D','SaveDir' and 'DataType' as option.
%    0.92 10.02.11 YM  potential bug fix for mkdir().
%    0.93 25.07.12 YM  use expfilename()/sigfilename().
%    0.94 29.05.14 YM  bug fix when size(tcImg.dat,4)==1.
%
%  See also SPM2TCIMG HDR_INIT HDR_WRITE EXPREALIGN IMGLOAD

if nargin == 0,  eval(sprintf('help %s',mfilename)); return;  end

% CONTROL FLAGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SAVE_DIR     = 'spm';
EXPORT_AS_3D = 1;
DATTYPE      = '';
USE_2DSEQ    = 0;


% CHECK INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isstruct(varargin{1}) && isfield(varargin{1},'dat') && isfield(varargin{1},'ds'),
  % Called like tcimg2spm(tcImg,...)
  tcImg = varargin{1};
  idxopt = 2;
  USE_2DSEQ = 0;
  Ses = goto(tcImg.session);
  %grp = getgrp(Ses,tcImg.ExpNo(1));
else
  % Called like tcimg2spm(session,expno,...)
  if nargin < 2,
    fprintf(' %s ERROR: ExpNo is missing.',mfilename);
    return;
  end
  Ses = goto(varargin{1});
  %grp = getgrp(Ses,varargin{2});
  tcImg = [];
  idxopt = 3;
end

for N = idxopt:2:length(varargin),
  switch lower(varargin{N}),
   case {'exportas3d','export3d','3d'}
    EXPORT_AS_3D = varargin{N+1};
   case {'savedir','dir'}
    SAVE_DIR = varargin{N+1};
   case {'datatype','dattype','dataclass','datclass'}
    DATTYPE = varargin{N+1};
   case {'use2dseq','use 2dseq','2dseq'}
    USE_2DSEQ = varargin{N+1};
  end
end

% PREPARE DATA
if USE_2DSEQ,
  ARGS.ISAVE = 0;
  tcImg = imgload(Ses,varargin{2},ARGS);
elseif isempty(tcImg),
  tcImg = sigload(Ses,varargin{2},'tcImg');
end



if ~isempty(DATTYPE),
  tcImg.dat = eval(sprintf('%s(tcImg.dat);',DATTYPE));
end



if length(tcImg.ExpNo) == 1,
  froot = sprintf('%s_%03d',tcImg.session, tcImg.ExpNo);  % DO THIS FOR spm2tcimg
else
  froot = sprintf('%s_%s',tcImg.session, tcImg.grpname);
end

% create "spm" dirctory
if ~exist(fullfile(pwd,SAVE_DIR),'dir'),  mkdir(SAVE_DIR);  end


dtype  = class(tcImg.dat);


if EXPORT_AS_3D && size(tcImg.dat,4) > 1,
  % SAVE EACH TIME POINT AS DIFFERENT IMG/HDR.
  pixdim = [3 tcImg.ds(1) tcImg.ds(2) tcImg.ds(3)];
  dim    = [4 size(tcImg.dat,1) size(tcImg.dat,2) size(tcImg.dat,3) 1];
  IMGFILES = cell(1,size(tcImg.dat,4));
  HDRFILES = cell(1,size(tcImg.dat,4));
  for N = 1:size(tcImg.dat,4),
    % set filenames
    OUT_IMGFILE = fullfile(SAVE_DIR,sprintf('%s_%05d.img',froot,N));
    OUT_HDRFILE = fullfile(SAVE_DIR,sprintf('%s_%05d.hdr',froot,N));
    % write out .img
    fid = fopen(OUT_IMGFILE,'wb');
    fwrite(fid, tcImg.dat(:,:,:,N), dtype);
    fclose(fid);
    % write out .hdr
    hdr = hdr_init('dim',dim,'datatype',dtype,'pixdim',pixdim,'glmax',intmax('int16'));
    hdr_write(OUT_HDRFILE,hdr);
    % keep output files for varargout
    IMGFILES{N} = OUT_IMGFILE;
    HDRFILES{N} = OUT_HDRFILE;
  end
else
  % SAVE ALL TIME POINTS AS A SINGLE IMG/HDR.
  pixdim = [3 tcImg.ds(1) tcImg.ds(2) tcImg.ds(3)];
  dim    = [4 size(tcImg.dat,1) size(tcImg.dat,2) size(tcImg.dat,3) size(tcImg.dat,4)];
  OUT_IMGFILE = fullfile(SAVE_DIR,sprintf('%s.img',froot));
  OUT_HDRFILE = fullfile(SAVE_DIR,sprintf('%s.hdr',froot));
  % write out .img
  fid = fopen(OUT_IMGFILE,'wb');
  fwrite(fid, tcImg.dat, dtype);
  fclose(fid);
  % write out .hdr
  hdr = hdr_init('dim',dim,'datatype',dtype,'pixdim',pixdim,'glmax',intmax('int16'));
  hdr_write(OUT_HDRFILE,hdr);
  % keep output files for varargout
  IMGFILES{1} = OUT_IMGFILE;
  HDRFILES{1} = OUT_HDRFILE;
end


% return output filenames, if required.
if nargout,
  varargout{1} = IMGFILES;
  if nargout > 1
    varargout{2} = HDRFILES;
  end
end



return;
