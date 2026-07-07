function varargout = tcimg2spm(varargin)
%TCIMG2SPM - dumps tcImg structure into ANALIZE-7 or NIfTI format for SPM.
%  [IMGFILES,HDRFILES] = TCIMG2SPM(TCIMG,...)
%  [IMGFILES,HDRFILES] = TCIMG2SPM(SESSION,EXPNO,...) dumps the given tcImg structure to 
%  spm/.img,.hdr for analysis with SPM and returns output file as IMGFILES for binary
%  images, HDRFILES for header files.
%  Supported options are...
%    SaveDir    : directory to save, default as 'spm'.
%    ExportAs3D : flag to export as 3D, default as 1.
%    DataType   : data type, default as class(tcImg.dat).
%    Use2dseq   : export directrly from 2dseq.
%    NII        : 0/1 to export as .nii (NIfTI-1) format.
%    NIIcompatible : 'spm' (default), 'amira', 'slicer' or 'qform=2,d=1'
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
%    0.94 29.05.13 YM  bug fix when size(tcImg.dat,4)==1.
%    0.95 06.03.20 YM  support .nii (NIfTI-1).
%
%  See also spm2tcimg hdr_init hdr_write nii_init imgload exprealign mana2analyze

if nargin == 0,  eval(sprintf('help %s',mfilename)); return;  end

% CONTROL FLAGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SAVE_DIR       = 'spm';
EXPORT_AS_3D   = 1;
DATTYPE        = '';
USE_2DSEQ      = 0;
EXPORT_AS_NII  = 0;
NII_COMPATIBLE = 'spm';  % spm|amira|slicer|qform=2,d=1


% CHECK INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isstruct(varargin{1}) && isfield(varargin{1},'dat') && isfield(varargin{1},'ds')
  % Called like tcimg2spm(tcImg,...)
  tcImg = varargin{1};
  idxopt = 2;
  USE_2DSEQ = 0;
  Ses = goto(tcImg.session);
  %grp = getgrp(Ses,tcImg.ExpNo(1));
else
  % Called like tcimg2spm(session,expno,...)
  if nargin < 2
    fprintf(' %s ERROR: ExpNo is missing.',mfilename);
    return;
  end
  Ses = goto(varargin{1});
  %grp = getgrp(Ses,varargin{2});
  tcImg = [];
  idxopt = 3;
end

for N = idxopt:2:length(varargin)
  switch lower(varargin{N})
   case {'exportas3d','export3d','3d'}
    EXPORT_AS_3D = varargin{N+1};
   case {'savedir','dir'}
    SAVE_DIR = varargin{N+1};
   case {'datatype','dattype','dataclass','datclass'}
    DATTYPE = varargin{N+1};
   case {'use2dseq','use 2dseq','2dseq'}
    USE_2DSEQ = varargin{N+1};
   case {'nii','nifti-1','nifti1','nifti'}
    EXPORT_AS_NII = varargin{N+1};
   case {'niicompatible','nii_compatible'}
    NII_COMPATIBLE = varargin{N+1};
  end
end

% PREPARE DATA
if USE_2DSEQ
  ARGS.ISAVE = 0;
  tcImg = imgload(Ses,varargin{2},ARGS);
elseif isempty(tcImg)
  tcImg = sigload(Ses,varargin{2},'tcImg');
end



if ~isempty(DATTYPE)
  tcImg.dat = eval(sprintf('%s(tcImg.dat);',DATTYPE));
end



if length(tcImg.ExpNo) == 1
  froot = sprintf('%s_%03d',tcImg.session, tcImg.ExpNo);  % DO THIS FOR spm2tcimg
else
  froot = sprintf('%s_%s',tcImg.session, tcImg.grpname);
end

% create "spm" dirctory
if ~exist(fullfile(pwd,SAVE_DIR),'dir'),  mkdir(SAVE_DIR);  end


dtype  = class(tcImg.dat);


if EXPORT_AS_3D && size(tcImg.dat,4) > 1
  % SAVE EACH TIME POINT AS DIFFERENT IMG/HDR.
  pixdim = [3 tcImg.ds(1) tcImg.ds(2) tcImg.ds(3)];
  dim    = [4 size(tcImg.dat,1) size(tcImg.dat,2) size(tcImg.dat,3) 1];
  IMGFILES = cell(1,size(tcImg.dat,4));
  HDRFILES = cell(1,size(tcImg.dat,4));
  for N = 1:size(tcImg.dat,4)
    if any(EXPORT_AS_NII)
      % set filenames/header
      OUT_HDRFILE = fullfile(SAVE_DIR,sprintf('%s_%05d.nii',froot,N));
      OUT_IMGFILE = OUT_HDRFILE;
      hdr = nii_init('dim',dim,'datatype',dtype,'pixdim',pixdim,'glmax',intmax('int16'),...
                     'niicompatible',NII_COMPATIBLE);
      wmode = 'ab';
    else
      % set filenames/header
      OUT_IMGFILE = fullfile(SAVE_DIR,sprintf('%s_%05d.img',froot,N));
      OUT_HDRFILE = fullfile(SAVE_DIR,sprintf('%s_%05d.hdr',froot,N));
      hdr = hdr_init('dim',dim,'datatype',dtype,'pixdim',pixdim,'glmax',intmax('int16'));
      wmode = 'wb';
    end
    % write out .hdr
    hdr_write(OUT_HDRFILE,hdr);
    % write out .img
    fid = fopen(OUT_IMGFILE,wmode);
    fwrite(fid, tcImg.dat(:,:,:,N), dtype);
    fclose(fid);
    % keep output files for varargout
    IMGFILES{N} = OUT_IMGFILE;
    HDRFILES{N} = OUT_HDRFILE;
  end
else
  % SAVE ALL TIME POINTS AS A SINGLE IMG/HDR.
  pixdim = [3 tcImg.ds(1) tcImg.ds(2) tcImg.ds(3)];
  dim    = [4 size(tcImg.dat,1) size(tcImg.dat,2) size(tcImg.dat,3) size(tcImg.dat,4)];
  if any(EXPORT_AS_NII)
    hdr = nii_init('dim',dim,'datatype',dtype,'pixdim',pixdim,'glmax',intmax('int16'),...
                   'niicompatible',NII_COMPATIBLE);
    wmode = 'ab';
  else
    OUT_IMGFILE = fullfile(SAVE_DIR,sprintf('%s.img',froot));
    OUT_HDRFILE = fullfile(SAVE_DIR,sprintf('%s.hdr',froot));
    hdr = hdr_init('dim',dim,'datatype',dtype,'pixdim',pixdim,'glmax',intmax('int16'));
    wmode = 'wb';
  end
  % write out .hdr
  hdr_write(OUT_HDRFILE,hdr);
  % write out .img
  fid = fopen(OUT_IMGFILE,wmode);
  fwrite(fid, tcImg.dat, dtype);
  fclose(fid);
  % keep output files for varargout
  IMGFILES{1} = OUT_IMGFILE;
  HDRFILES{1} = OUT_HDRFILE;
end


% return output filenames, if required.
if nargout
  varargout{1} = IMGFILES;
  if nargout > 1
    varargout{2} = HDRFILES;
  end
end



return
