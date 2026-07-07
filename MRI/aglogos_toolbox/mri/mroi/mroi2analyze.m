function mroi2analyze(SesName,GrpName,RoiName,varargin)
%MROI2ANALYZE - saves the roi definition in anz-file
% MROI2ANALYZE(SESSION,GROUP,ROINAME,...) loads the roi definition from Roi.mat
% and saves as ANALYZE-7.5 or NIfTI-1 format.
%
%  Supported options are:
%    'undocrop' : 0/1 undo cropping or not.
%    'NII'      : 0/1 to export as .nii (NIfTI-1) format.
%    'NIIcompatible' : 'spm' (default), 'amira', 'slicer' or 'qform=2,d=1'
%    'FlipDim'      : [1,2...] dimension(s) to flip, 1/2/3 as X/Y/Z
%
%  Obsolete:
%    'mode' : 'mask' or 'old'.
%
%  EXAMPLE :
%    >> mroi2analyze(SesName,grpname,RoiName,...)
%    >> mroi2analyze(SesName,grpname,'','nii',1)   % export all ROIs as NIfTI-1 format.
%
%  VERSION :
%    0.90 2013.06.xx    : orignal
%    0.91 2018.03.01 YM : modified to export ROIs as masks.
%    0.92 2019.11.21 YM : clean-up.
%    0.93 2020.03.26 YM : supports .nii (NIfTI-1) and UNDO_CROP.
%    0.94 2020.04.08 YM : supports 'FlipDim'.
%
%  See also mroi_file hdr_init nii_init anz_write anz_view


if nargin < 1,  eval(['help ' mfilename]); return;  end

if nargin < 3
  RoiName = '';
end

MODE_STR = 'mask';
UNDO_CROP = 0;
V_FLIPDIM = [];

EXPORT_AS_NII = 0;
NII_COMPATIBLE = 'spm';  % spm|amira|slicer|qform=2,d=1

for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'mode'}
    MODE_STR = varargin{N+1};
   
   case {'undocrop' 'undo_cropping'}
    UNDO_CROP = varargin{N+1};
   case {'flipdim' 'flip'}
    V_FLIPDIM = varargin{N+1};
    
   case {'nii','nifti-1','nifti1','nifti'}
    EXPORT_AS_NII = varargin{N+1};
   case {'niicompatible','nii_compatible'}
    NII_COMPATIBLE = varargin{N+1};
  end
end
if ~isempty(V_FLIPDIM) && ischar(V_FLIPDIM)
  % 'V_FLIPDIM' is given as a string like, 'Y' or 'XZ'
  tmpdim = [];
  for N=1:length(V_FLIPDIM)
    tmpidx = strfind('xyz',lower(V_FLIPDIM(N)));
    if ~isempty(tmpidx),  tmpdim(end+1) = tmpidx;  end
  end
  V_FLIPDIM = tmpdim;
  clear tmpdim tmpidx;
end



ses = goto(SesName);
grp = getgrp(SesName,GrpName) ;

roifile = mroi_file(ses,GrpName);
%roifile = fullfile(ses.sysp.DataMatlab,ses.sysp.dirname,'Roi.mat') ;
if exist(roifile,'file')
  ROI = load(roifile,grp.grproi) ;
  ROI = ROI.(grp.grproi);
else
  error('%s: The file %s does not exist.',mfilename,roifile) ;
end



switch lower(MODE_STR)
 case {'original' 'old'}
  sub_original_old_proc(ses,grp,RoiName,ROI);
 case {'mask'}
  sub_export_mask(ses,grp,RoiName,ROI,UNDO_CROP,V_FLIPDIM,EXPORT_AS_NII,NII_COMPATIBLE);
end


% =============================================================
function sub_export_mask(ses,grp,RoiNames,ROI,UNDO_CROP,V_FLIPDIM,EXPORT_AS_NII,NII_COMPATIBLE)
% =============================================================
if isempty(RoiNames) || any(strcmpi(RoiNames,'all'))
  RoiNames = ses.roi.names;
end

roidata = zeros(size(ROI.img));
if any(UNDO_CROP)
  p = expgetpar(ses,grp.exps(1));
  voldata = zeros([p.pvpar.nx,p.pvpar.ny,p.pvpar.nsli]);
  if isequal(size(roidata),size(voldata))
    % to avoid error...
    ix = 1:size(voldata,1);
    iy = 1:size(voldata,2);
  else
    IMGCROP = grp.imgcrop;
    ix = (0:IMGCROP(3)-1) + IMGCROP(1);
    iy = (0:IMGCROP(4)-1) + IMGCROP(2);
  end
else
  voldata = roidata;
end


imgdim  = [4 size(voldata,1) size(voldata,2) size(voldata,3), 1];
pixdim  = [3 ROI.ds(1) ROI.ds(2) ROI.ds(3)];
sesdir  = fullfile(ses.sysp.DataMatlab,ses.sysp.dirname);
subdir  = 'mroi2analyze';
imgroot = sprintf('%s_%s',ses.name,grp.grproi);




hdr = [];
for R = 1:length(RoiNames)
  IS_FOUND = 0;
  roidata(:) = 0;
  fprintf('%3d %15s: ',R, RoiNames{R});
  for N = 1:length(ROI.roi)
    if any(strcmpi(RoiNames{R},ROI.roi{N}.name))
      if any(ROI.roi{N}.mask(:) > 0)
        IS_FOUND = 1;
        roidata(:,:,ROI.roi{N}.slice) = roidata(:,:,ROI.roi{N}.slice) + double(ROI.roi{N}.mask);
      end
    end
  end
  if any(IS_FOUND)
    roidata(roidata(:) > 0) = 255;
    
    if any(UNDO_CROP)
      voldata(:) = 0;
      for S = 1:size(roidata,3)
        voldata(ix,iy,S) = roidata(:,:,S);
      end
    else
      voldata = roidata;
    end
    
    if any(V_FLIPDIM)
      for K = 1:length(V_FLIPDIM)
        voldata = flipdim(voldata,V_FLIPDIM(K));
      end
    end
    
    if any(EXPORT_AS_NII)
      hdr = nii_init('dim',imgdim, 'pixdim',pixdim,...
                     'datatype','uchar', 'glmax',255,...
                     'niicompatible',NII_COMPATIBLE);
      imgfile = fullfile(subdir,sprintf('%s_%s.nii',imgroot,RoiNames{R}));
    else
      hdr = hdr_init('dim',imgdim, 'pixdim',pixdim,...
                     'datatype','uchar', 'glmax',255);
      imgfile = fullfile(subdir,sprintf('%s_%s.hdr',imgroot,RoiNames{R}));
    end
    fprintf(' %s...',imgfile);
    if ~exist(fullfile(sesdir,subdir),'dir'),  mkdir(fullfile(sesdir,subdir)); end
    anz_write(fullfile(sesdir,imgfile),hdr,voldata);
    fprintf('done (nvox=%d).\n', length(find(voldata(:) > 0)));
  else
    fprintf(' not found or empty, skipped.\n');
  end
end

if ~isempty(hdr)
  txtfile = fullfile(subdir,sprintf('%s.txt',imgroot));
  sub_write_infotxt(txtfile,hdr,UNDO_CROP,V_FLIPDIM,EXPORT_AS_NII,NII_COMPATIBLE);
end

return

% =============================================================
function sub_write_infotxt(TXTFILE,HDR,UNDO_CROP,V_FLIPDIM,EXPORT_AS_NII,NII_COMPATIBLE)
% =============================================================
  
fid = fopen(TXTFILE,'wt');
fprintf(fid,'date:     %s\n',datestr(now));
fprintf(fid,'program:  %s\n',mfilename);
fprintf(fid,'platform: MATLAB %s\n',version());
%fprintf(fid,'permute:  [%s]\n',deblank(sprintf('%d ',V_PERMUTE)));
fprintf(fid,'flipdim:  [%s]\n',deblank(sprintf('%d ',V_FLIPDIM)));
fprintf(fid,'undocrop: %d\n',UNDO_CROP);


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


fclose(fid);


return




% =============================================================
function sub_original_old_proc(ses,grp,RoiName,ROI)
% =============================================================

imagedata = zeros([size(ROI.img) 3]);
minv = min(ROI.img(:));
maxv = max(ROI.img(:));

for N = 1:length(ROI.roi)
  if any(strcmpi(RoiName,ROI.roi{N}.name)) || any(strcmpi(RoiName,'all')) || isempty(RoiName),
    slino = ROI.roi{N}.slice ;
    tmpcolormap = [0:1.0/256:1.0]' ;
    tmpcolormap = repmat(tmpcolormap,1,3) ;
    imagedata(:,:,slino,:) = subFuseImage(squeeze(imagedata(:,:,slino,:)),...
              ROI.img(:,:,slino),minv,maxv,...
              ~(ROI.roi{N}.mask),0.5,tmpcolormap) ;
  end
end

imagedata = mean(imagedata,4) ;

imagedim = int16([4,size(imagedata,1),size(imagedata,2),size(imagedata,3)]);
if length(imagedim) < 5
  imagedim(length(imagedim)+1:5) = int16(1) ;
end
header = hdr_init('dim',imagedim, ...
                  'datatype','double', ...
                  'pixdim',single([4 ROI.ds(1:3),ROI.ds(4)*ROI.dx]), ...
                  'vox_offset',10, ...
                  'cal_max',0, ...
                  'cal_min',0, ...
                  'glmax',max(imagedata(:)), ...
                  'glmin',min(imagedata(:)), ...
                  'orient',0 ...
                  ) ;

anzfile = fullfile(ses.sysp.matdir,ses.sysp.dirname,'roianz') ;
anz_write(anzfile,header,imagedata) ;

%anz_view(sprintf('%s.img',anzfile));

return ;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to fuse anatomy and functional images
function IMG = subFuseImage(ANARGB,STATV,MINV,MAXV,PVAL,ALPHA,CMAP)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ndims(ANARGB) == 2
  % image is just a vector, squeezed, so make it 2D image with RGB
  ANARGB = permute(ANARGB,[1 3 2]);
end

IMG = ANARGB;
if isempty(STATV) || isempty(PVAL) || isempty(ALPHA),  return;  end

PVAL(isnan(PVAL(:))) = 1;  % to avoid error;

imsz = [size(ANARGB,1) size(ANARGB,2)];
if any(imsz ~= size(STATV))
  if datenum(version('-date')) >= datenum('January 29, 2007')
    STATV = imresize_old(STATV,imsz,'nearest',0);
    PVAL  = imresize_old(PVAL, imsz,'nearest',0);
    %STATV = imresize_old(STATV,imsz,'bilinear',0);
    %PVAL  = imresize_old(PVAL, imsz,'bilinear',0);
  else
    STATV = imresize(STATV,imsz,'nearest',0);
    PVAL  = imresize(PVAL, imsz,'nearest',0);
    %STATV = imresize(STATV,imsz,'bilinear',0);
    %PVAL  = imresize(PVAL, imsz,'bilinear',0);
  end
end


tmpdat = repmat(PVAL,[1 1 3]);   % for rgb
idx = find(tmpdat(:) < ALPHA);
if ~isempty(idx)
  % scale STATV from MINV to MAXV as 0 to 1
  STATV = (STATV - MINV)/(MAXV - MINV);
  STATV = round(STATV*255) + 1;  % +1 for matlab indexing
  STATV(STATV(:) <   0) =   1;
  STATV(STATV(:) > 256) = 256;
  % map 0-256 as RGB
  STATV = ind2rgb(STATV,CMAP);
  % replace pixels
  %fprintf('\nsize(IMG)=  '); fprintf('%d ',size(IMG));
  %fprintf('\nsize(STATV)='); fprintf('%d ',size(STATV));
  IMG(idx) = STATV(idx);
end

return;
