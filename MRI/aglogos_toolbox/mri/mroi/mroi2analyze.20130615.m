function mroi2analyze(session,grpName,roiName,varargin)
%MROI2ANALYZE - saves the roi definition in anz-file
% MROI2ANALYZE(SESSION,GROUP,ROI) loads the roi definition from Roi.mat
% and saves it to roianz.img and roianz.hdr

grp = getgrp(session,grpName) ;
if ischar(session),
  session = getses(session) ;
end

roifile = mroi_file(session,grpName)
%roifile = fullfile(session.sysp.DataMatlab,session.sysp.dirname,'Roi.mat') ;
if exist(roifile,'file'),
  Roi = load(roifile,grp.grproi) ;
else
  error('The file %s does not exist.',roifile) ;
end
Roi = Roi.(grp.grproi) ;

imagedata = zeros([size(Roi.img) 3]) ;
for N = 1:length(Roi.roi),
  if any(strcmpi(Roi.roi{N}.name,roiName)),
    slino = Roi.roi{N}.slice ;
    tmpcolormap = [0:1.0/256:1.0]' ;
    tmpcolormap = repmat(tmpcolormap,1,3) ;
    imagedata(:,:,slino,:) = subFuseImage(squeeze(imagedata(:,:,slino,:)),...
              Roi.img(:,:,slino),min(Roi.img(:)),max(Roi.img(:)),...
              ~(Roi.roi{N}.mask),0.5,tmpcolormap) ;
  end
end

imagedata = mean(imagedata,4) ;

imagedim = int16([4,size(imagedata,1),size(imagedata,2),size(imagedata,3)]);
if length(imagedim) < 5,
  imagedim(length(imagedim)+1:5) = int16(1) ;
end
header = hdr_init('dim',imagedim, ...
                  'datatype','double', ...
                  'pixdim',single([Roi.ds(1:3),Roi.ds(4)*Roi.dx]), ...
                  'vox_offset',10, ...
                  'cal_max',0, ...
                  'cal_min',0, ...
                  'glmax',max(imagedata(:)), ...
                  'glmin',min(imagedata(:)), ...
                  'orient',0 ...
                  ) ;

anzfile = fullfile(session.sysp.matdir,session.sysp.dirname,'roianz') ;
anz_write(anzfile,header,imagedata) ;

%anz_view(sprintf('%s.img',anzfile));

return ;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to fuse anatomy and functional images
function IMG = subFuseImage(ANARGB,STATV,MINV,MAXV,PVAL,ALPHA,CMAP)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ndims(ANARGB) == 2,
  % image is just a vector, squeezed, so make it 2D image with RGB
  ANARGB = permute(ANARGB,[1 3 2]);
end

IMG = ANARGB;
if isempty(STATV) || isempty(PVAL) || isempty(ALPHA),  return;  end

PVAL(isnan(PVAL(:))) = 1;  % to avoid error;

imsz = [size(ANARGB,1) size(ANARGB,2)];
if any(imsz ~= size(STATV)),
  if datenum(version('-date')) >= datenum('January 29, 2007'),
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
if ~isempty(idx),
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
