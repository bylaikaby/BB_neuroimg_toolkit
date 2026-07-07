function [nx,ny,nslice,nobs,samptime,obslens,dx,dy,thick,datatype] =  img_info(imgfile)
%IMG_INFO - Get information of 'IMG' formatted file.
% PURPOSE : To read information about 'IMG' formatted data.
% USAGE   : [nx,ny,nslice,nobs,samptime,obslens,dx,dy,thick,datatype] = img_info(imgfile)
% ARGOUTS : 'samptime' in seconds.   'obslens' as in volumes
% VERSION : 0.90 02.02.2004 YM   first release
%
% See also IMG_READ IMG_WRITE IMGLOAD
  

if nargin < 1
  fprintf('usage: [nx,ny,nslice,nobs,samptime,obslens,dx,dy,thick,datatype] = img_info(imgfile)\n');
  return;
end

% Opens a file
fid = fopen(imgfile,'rb');
if fid == -1
  error(sprintf('img_info : faild to open %s\n',imgfile));
end

IMG_HEADER_SIZE = 256;             % IMG header size, must be 256

% read header
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
  fpritntf('\n %s is not IMG format.\n',fname);
  keyboard
end
fseek(fid,IMG_HEADER_SIZE,'bof');
% read directory
obscounts   = fread(fid,h_nobs,'int32');
offsets     = fread(fid,h_nobs,'int32');

% close it
fclose(fid);

% prepare outputs
nvox_per_vol = h_nx * h_ny * h_nslice;
switch h_datatype
 case 10
  datatype = 'uint8';
 case 11
  datatype = 'int8';
 case 12
  datatype = 'uint16';
 case 13
  datatype = 'int16';
 case 14
  datatype = 'uint32';
 case 15
  datatype = 'uint32';
 case 20
  datatype = 'float32';
 case 21
  datatype = 'double';
 otherwise
  error(sprintf('img_info : unknown datatype %d\n',h_datatype));
end

if nargout == 0,
  if length(find(h_magic == [22 71 9 10])) == 4,
    ftype = 'img';
  else
    ftype = 'unknown';
  end
  fprintf('img_info: %s\n',imgfile);
  fprintf(' type:  %s,    version:  %.3f\n',ftype, h_version);
  fprintf(' nx:    %3d,    dx:       %.4fmm\n',h_nx,h_dx);
  fprintf(' ny:    %3d,    dy:       %.4f\n',h_ny,h_dy);
  fprintf(' nslice:%3d,    thick:    %.4f\n',h_nslice,h_thick);
  fprintf(' nobs:    %d\n',h_nobs);
  if h_nobs == 1,
    fprintf(' obslen:  %d volumes\n',obscounts/nvox_per_vol);
  end
  fprintf(' sampt:   %.4f sec\n',h_sec_per_sample);
  fprintf(' data:    %s\n',datatype);
  return;
else
  nx        = h_nx;
  ny        = h_ny;
  nslice    = h_nslice;
  nobs      = h_nobs;
  samptime  = h_sec_per_sample;
  obslens   = obscounts/nvox_per_vol;
  dx        = h_dx;
  dy        = h_dy;
  thick     = h_thick;
end
