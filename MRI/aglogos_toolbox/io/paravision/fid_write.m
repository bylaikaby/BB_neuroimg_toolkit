function fid_write(FIDFILE,KDATA,varargin)
% FID_WRITE - write K-space data as fid
%  FID_WRITE(FIDFILE,KDATA,ACQP)
%  FID_WRITE(FIDFILE,KDATA,BYTEORDER,WORDTYPE)
%
%  KDATA should be reshaped into 'fid' file dimension.
%
%
% VERSION : 0.90 16.11.04 YM  pre-release
%
% See also FID_READ, FID_RESHAPE, PVRDFID

if nargin < 3,  help fid_write; return;  end


if ~isreal(KDATA),
  error(' fid_write error: reshape the data first by fid_reshape().\n');
end


% back up the original "fid" file.
srcfile = sprintf('%s/fid',fileparts(FIDFILE));
dstfile = sprintf('%s/fid.pv',fileparts(FIDFILE));
if ~exist(dstfile,'file') && exist(srcfile,'file'),
  status = copyfile(srcfile,dstfile,'f');
  if status == 0,
    error(' fid_write error: cannot backup the original fid.\n');
  end
end


if nargin == 3 && isstruct(varargin{1}),
  % called as FID_WRITE(FILENAME,KDATA,ACQP)
  acqp = varargin{1};
  byteorder = acqp.BYTORDA;
  wordtype  = acqp.ACQ_word_size;
elseif nargin == 4
  % called as FID_WRITE(FILENAME,BYTEORDER,WORDTYPE)
  byteorder = varargin{1};
  wordtype  = varargin{2};
else
  fprintf(' fid_write error: wrong input argument(s).\n');
  return;
end


% set byte order
switch lower(byteorder),
 case {'s','swap','b','big','bigendian','big-endian'}
  byteorder = 'ieee-be';
 case {'n','noswap','non-swap','l','little','little-endian','littleendian'}
  byteorder = 'ieee-le';
end

% set data type
switch wordtype,
 case {'_16_BIT','_16BIT_SGN_INT','int16'}
  wordtype = 'int16';
 case {'_32_BIT','_32BIT_SGN_INT','int32'}
  wordtype = 'int32';
 otherwise
  error(' fid_write error: unknown wordtype.\n');
end


fid = fopen(FIDFILE,'wb',byteorder);
try
  fwrite(fid,KDATA,wordtype);
catch
  fclose(fid);
  error(' fid_write error: faild to write data.\n');
end
fclose(fid);


return;

