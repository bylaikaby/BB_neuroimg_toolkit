function [imgs,sampt,dx,dy,thick] = img_read(imgfile,obs,imgcrop,startvol,widthvol)
%IMG_READ - Reads 'IMG' formatted file.
% PURPOSE : To read 'IMG' formatted data.
% USAGE :   [imgs,sampt,dx,dy,thick] = img_read(imgfile,[obs],[imgcrop],[startvol],[widthvol])
% NOTE :   'obs','imgcrop','startvol' SHOULD start from 0, not 1.
% VERSION : 0.90 02.02.2004 YM   first release
%
% See also IMG_INFO IMG_WRITE IMGLOAD SESIMGLOAD


if nargin < 1
  fprintf('usage: img = img_read(imgfile,obs,imgcrop,startvol,widthvol)\n');
  fprintf('args:  obs,imgcrop>= 0, startvol>=0,withs>=1.\n');
  return;
end

if ~exist('obs','var'),      obs = 0;        end
if ~exist('imgcrop','var'),  imgcrop  = [];  end
if ~exist('startvol','var'), startvol = -1;  end
if ~exist('widthvol','var'), widthvol = -1;  end

imgs = [];
% Opens a file
fid = fopen(imgfile,'rb');
if fid == -1
  error(sprintf('img_read : faild to open %s\n',imgfile));
end

% read header
HEADSIZE = 256;
h_magic         = fread(fid,4,'int8')';
h_version       = fread(fid,1,'float32');
if length(find(h_magic == [22 71 9 10])) == 4,
  % IMG format
  h_nx            = fread(fid,1,'int32');
  h_ny            = fread(fid,1,'int32');
  h_nslice        = fread(fid,1,'int32');
  h_sec_per_sample = fread(fid,1,'float32');
  h_nobs          = fread(fid,1,'int32');
  h_dx            = fread(fid,1,'float32');
  h_dy            = fread(fid,1,'float32');
  h_thick         = fread(fid,1,'float32');
  h_datatype      = fread(fid,1,'int8');
else
  fprintf('\n %s is not IMG format.\n',fname);
  keyboard
end

nvox_per_vol = h_nx * h_ny * h_nslice;

fseek(fid,HEADSIZE,'bof');
% read directory
obscounts   = fread(fid,h_nobs,'int32')';
offsets     = fread(fid,h_nobs,'int32')';
switch h_datatype
 case 10
  typestr = 'uint8';    typelen = 1;
 case 11
  typestr = 'int8';     typelen = 1;
 case 12
  typestr = 'uint16';   typelen = 2;
 case 13
  typestr = 'int16';    typelen = 2;
 case 14
  typestr = 'uint32';   typelen = 4;
 case 15
  typestr = 'int32';    typelen = 4;
 case 20
  typestr = 'float32';  typelen = 4;
 case 21
  typestr = 'double';   typelen = 8;
 otherwise
  error(sprintf('img_read : unknown datatype %d\n',h_datatype));
end

% move pointer and modify obscounts(obs+1) for partial reading
if startvol >= 0,
  startvol = startvol * nvox_per_vol;
  widthvol = widthvol * nvox_per_vol;
  fseek(fid,startvol*typelen,'cof');
  obscounts(obs+1) = obscounts(obs+1) - startvol;
  if widthvol > 0 & widthvol < obscounts(obs+1),
    obscounts(obs+1) = widthvol;
  end
end

% read data
offsets(obs+1), obscounts(obs+1)
fseek(fid,offsets(obs+1),'bof');
imgs = fread(fid,obscounts(obs+1),typestr);
% close the file
fclose(fid);

% reshape the matrix to (x,y,slice,t)
imgs = reshape(imgs,h_nx,h_ny,h_nslice,numel(imgs)/nvox_per_vol);

% image cropping, imgcrop = [x,y,w,h],  x,y must be >= 0.
if ~isempty(imgcrop),
  xi = [1:imgcrop(3)] + imgcrop(1);   % imgcrop(1) >= 0
  yi = [1:imgcrop(4)] + imgcrop(2);   % imgcrop(2) >= 0
  imgs = imgs(xi,yi,:,:);
end


% more outputs
if nargout > 1,
  sampt = h_sec_per_sample;  % in seconds
  dx    = h_dx;
  dy    = h_dy;
  thick = h_thick;
end
