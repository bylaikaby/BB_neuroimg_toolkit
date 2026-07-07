function mana2analyze(varargin)
%MANA2ANALYZE - exports anatomical images as ANALYZE format
%  MANA2ANALYZE(SESSION,GRPNAME,...)
%  MANA2ANALYZE(SESSION,EXPNO,...)
%  MANA2ANALYZE(SESSION,ANANAME,INDEX,...) exports anatomical images as ANALYZE format.
%
%  Supported options are :
%    'use_epi'  : 0|1, export averaged EPI data as anatomical images.
%    'x10'      : make volxel size 10 times for rat-atlas.
%    'dir'      : directory to save
%    'filename  : filename to save
%    'datatype' : uint8 | int16
%    'permute'  : a vector for permute()
%    'flipdim'  : a vector for flipdim()
%    'NII'      : 0/1 to export as .nii (NIfTI-1) format.
%    'NIIcompatible' : 'spm' (default), 'amira', 'slicer' or 'qform=2,d=1'
%
%  EXAMPLE :
%    >> mana2analyze('e10ha1','rare',1);
%    >> mana2analyze('e10ha1',6,'use_epi',1);
%
%  VERSION :
%    0.90 13.12.12 YM  pre-release
%    0.91 05.07.13 YM  supports 'datatype', 'permute' and 'flipdim'.
%    0.92 06.06.20 YM  supports .nii (NIfTI-1).
%
%  See also hdr_init nii_init anz_write mstat2analyze tcimg2spm

if nargin < 2,  eval(['help ' mfilename]); return;  end

ANA = {};

% called like mana2analyze(ANA,...)
if isstruct(varargin{1}) && isfield(varargin{1},'dat')
  ANA = varargin{1};
  VargiStart = 2;
  if iscell(ANA),  ANA = ANA{1};  end
  if isfield(ANA,'session')
    SAVE_FILE = sprintf('%s_%s_%03d.img',ANA.session,ANA.grpname,ANA.ExpNo);
  else
    SAVE_FILE = sprintf('%s_anatomy.img',datestr(now,'yyyymmdd_HHMMSS'));
  end
  fprintf('%s %s: exporting anatomy...\n',...
          datestr(now,'HH:MM:SS'),mfilename);
end


if isempty(ANA)
  Ses = goto(varargin{1});
  if ischar(varargin{2}) && isfield(Ses.ascan,varargin{2})
    % called like mana2analyze(Ses,ANAname,ANAindex,...)
    VargiStart = 4;
    SAVE_FILE  = sprintf('%s_%s_%03d.img',Ses.name,varargin{2},varargin{3});
    if sesversion(Ses) < 2
      ANA = load(sprintf('%s.mat',varargin{2}),varargin{2});
      ANA = ANA.(varargin{2});
      if nargin > 2
        ANA = ANA{varargin{3}};
      else
        ANA = ANA{1};
      end
    else
      if nargin > 2
        anafile = sigfilename(Ses,varargin{3},varargin{2});
      else
        anafile = sigfilename(Ses,1,varargin{2});
      end
      ANA = load(anafile,varargin{2});
      ANA = ANA.(varargin{2});
    end
    fprintf('%s %s: exporting anatomy (%s,%d)...\n',...
            datestr(now,'HH:MM:SS'),mfilename,varargin{2},varargin{3});
  else
    % called like mana2analyze(Ses,grp/exp,...)
    GrpExp = varargin{2};
    grp = getgrp(Ses,GrpExp);
    ANA = anaload(Ses,GrpExp);
    VargiStart = 3;
    if isnumeric(GrpExp)
      SAVE_FILE  = sprintf('%s_%03d_anatomy.img',Ses.name,GrpExp);
      fprintf('%s %s: exporting anatomy (%s,Exp=%d)...\n',...
              datestr(now,'HH:MM:SS'),mfilename,Ses.name,GrpExp);
    else
      SAVE_FILE  = sprintf('%s_%s_anatomy.img',Ses.name,grp.name);
      fprintf('%s %s: exporting anatomy (%s,%s)...\n',...
              datestr(now,'HH:MM:SS'),mfilename,Ses.name,grp.name);
    end
  end
end


DIR_NAME  = '';
DO_X10    = 0;
DO_SCALE  = 1;
V_PERMUTE = [];
V_FLIPDIM = [];
DATA_TYPE = 'int16';
EXPORT_AS_NII  = 0;
NII_COMPATIBLE = 'spm';  % spm|amira|slicer|qform=2,d=1

for N = VargiStart:2:nargin
  switch lower(varargin{N})
   case {'epi' 'use_epi'}
    if any(varargin{N+1})
      fprintf(' epi...');
      if isnumeric(GrpExp)
        ExpNo = GrpExp;
      else
        ExpNo =grp.exps(1);
      end
      ANA = sigload(Ses,ExpNo,'tcImg');
      SAVE_FILE  = sprintf('%s_%03d_epi.img',Ses.name,ExpNo);
      if ~isfield(ANA,'ana')
        ANA.ana = nanmean(ANA.dat,4);
      end
      ANA.dat = ANA.ana;
    end
 
   case {'x10' 'rat'}
    DO_X10 = any(varargin{N+1});

   case {'dir' 'save_dir' 'savedir'}
    DIR_NAME = varargin{N+1};
    
   case {'file' 'filename'}
    SAVE_FILE = varargin{N+1};

   case {'datatype' 'dtype'}
    DATA_TYPE = varargin{N+1};
   case {'permute'}
    V_PERMUTE = varargin{N+1};
   case {'flipdim'}
    V_FLIPDIM = varargin{N+1};
   case {'scale'}
    DO_SCALE  = varargin{N+1};
  
   case {'nii','nifti-1','nifti1','nifti'}
    EXPORT_AS_NII = varargin{N+1};
   case {'niicompatible','nii_compatible'}
    NII_COMPATIBLE = varargin{N+1};
  end
end

if isempty(DIR_NAME),  DIR_NAME = 'anz';  end


if any(V_PERMUTE)
  fprintf(' permute[%s].',deblank(sprintf('%d ',V_PERMUTE)));
  ANA.dat = permute(ANA.dat,V_PERMUTE);
  ANA.ds  = ANA.ds(V_PERMUTE);
end
if any(V_FLIPDIM)
  fprintf(' flipdim[%s].',deblank(sprintf('%d ',V_FLIPDIM)));
  for N = 1:length(V_FLIPDIM)
    ANA.dat = flipdim(ANA.dat,V_FLIPDIM(N));
  end
end

ANA.dat(isnan(ANA.dat)) = 0;
if any(DO_SCALE)
  % scale to 0-1
  fprintf(' scaling(%s+)...',DATA_TYPE);
  ANA.dat = double(ANA.dat);
  minv = min(ANA.dat(:));
  maxv = max(ANA.dat(:));
  ANA.dat = (ANA.dat - minv) / (maxv - minv);
end

switch lower(DATA_TYPE)
 case {'uint8' 'uchar'}
  DATA_TYPE = 'uint8';
  if any(DO_SCALE),  ANA.dat = ANA.dat*255;  end
  ANA.dat = uint8(round(ANA.dat));
 otherwise
  DATA_TYPE = 'int16';
  if any(DO_SCALE),  ANA.dat = ANA.dat*32000;  end
  %if any(DO_SCALE),  ANA.dat = ANA.dat*double(intmax('int16'));  end
  ANA.dat = int16(round(ANA.dat));
end


imgfile = fullfile(DIR_NAME,SAVE_FILE);

if any(EXPORT_AS_NII)
  [fp,fr] = fileparts(imgfile);
  imgfile = fullfile(fp,sprintf('%s.nii',fr));
end


fp = fileparts(imgfile);
if ~isempty(fp)
  if ~exist(fp,'dir'),  mkdir(fp);  end
end

imgdim = [4 size(ANA.dat,1) size(ANA.dat,2) size(ANA.dat,3) 1];
pixdim = [3 ANA.ds(1) ANA.ds(2) ANA.ds(3)];
fprintf('pixdim[%s]', deblank(sprintf('%g ',pixdim(2:4))));

if any(DO_X10)
  ANA.ds = ANA.ds * 10;
  fprintf('-->[%s]', deblank(sprintf('%g ',pixdim(2:4))));
end
fprintf(' saving to ''%s''...',imgfile);
if any(EXPORT_AS_NII)
  hdr = nii_init('dim',imgdim,'pixdim',pixdim,...
                 'datatype',DATA_TYPE,'glmax',intmax(DATA_TYPE),...
                 'niicompatible',NII_COMPATIBLE);
else
  hdr = hdr_init('dim',imgdim,'pixdim',pixdim,...
                 'datatype',DATA_TYPE,'glmax',intmax(DATA_TYPE));
end
anz_write(imgfile,hdr,ANA.dat);

subWriteInfo(imgfile,hdr,V_PERMUTE,V_FLIPDIM,EXPORT_AS_NII,NII_COMPATIBLE);
fprintf(' done.\n');



return




% ==================================================================================
function subWriteInfo(IMGFILE,HDR,V_PERMUTE,V_FLIPDIM,EXPORT_AS_NII,NII_COMPATIBLE)
% ==================================================================================

[fp, froot] = fileparts(IMGFILE);


TXTFILE = fullfile(fp,sprintf('%s.txt',froot));
fid = fopen(TXTFILE,'wt');
fprintf(fid,'date:     %s\n',datestr(now));
fprintf(fid,'program:  %s\n',mfilename);
fprintf(fid,'platform: MATLAB %s\n',version());
fprintf(fid,'permute:  [%s]\n',deblank(sprintf('%d ',V_PERMUTE)));
fprintf(fid,'flipdim:  [%s]\n',deblank(sprintf('%d ',V_FLIPDIM)));

fprintf(fid,'\n[output]\n');
fprintf(fid,'dim:      [%s]\n',deblank(sprintf('%d ',HDR.dime.dim(2:4))));
fprintf(fid,'pixdim:   [%s] in mm\n',deblank(sprintf('%g ',HDR.dime.pixdim(2:4))));
fprintf(fid,'datatype: %d',HDR.dime.datatype);
switch HDR.dime.datatype
 case 1
  dtype =  'binary';
 case 2
  dtype =  'uchar';
 case 4
  dtype =  'int16';
 case 8
  dtype =  'int32';
 case 16
  dtype =  'float';
 case 32
  dtype =  'complex';
 case 64
  dtype =  'double';
 case 128
  dtype =  'rgb';
 otherwise
  dtype =  'unknown';
end
fprintf(fid,'(%s)\n',dtype);
if EXPORT_AS_NII
fprintf(fid,'format:   NIfTI-1 (.nii:%s)\n',NII_COMPATIBLE);
else
fprintf(fid,'format:   ANALYZE-7.5 (.hdr/img)\n');
end


fprintf(fid,'\n[photoshop raw]\n');
[str,maxsize,endian] = computer;
fprintf(fid,'width:  %d\n',HDR.dime.dim(2));
fprintf(fid,'height: %d\n',HDR.dime.dim(3)*HDR.dime.dim(4));
fprintf(fid,'depth:  %s\n',dtype);
if strcmpi(endian,'B')
fprintf(fid,'byte-order: Mac\n');
else
fprintf(fid,'byte-order: IBM\n');
end
if EXPORT_AS_NII
fprintf(fid,'header: %d\n',HDR.dime.vox_offset);
else
fprintf(fid,'header: 0\n');
end

fclose(fid);

return
