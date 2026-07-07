function varargout = pvread_fid(varargin)
%PVREAD_FID - Read ParaVision fid data.
%  [IDATA,IMGP] = PVREAD_FID(FILENAME,...)
%  IDATA = PVREAD_FID(FILENAME,...)
%  IDATA = PVREAD_FID(SESSION,EXPNO,...) read ParaVision fid data.
%
%  Supported options are...
%    'ByteOrder' : 'littleEndian' or 'bigEndian'
%    'WordType'  : '_16BIT_SGN_INT' or '_32BIT_SGN_INT'
%    'ImgSize'   : image size as [nx, ny, nslices, ntime], must not be empty.
%    'acqp'      : acqp structure returned by pvread_acqp().
%    'method'    : method structure returned by pvread_method().
%
%  Returned IDATA is NOT 'double', but 'WordType'.
%
%  NOTE:
%    When method.PVM_SpatDimEnum is '3D', reading may fail due to size mismatch.
%
%  VERSION :
%    0.90 14.05.14 YM  pre-release
%    0.91 03.06.14 YM  supports "ser".
%
%  See also pvread_2dseq pv_imgpar pvread_acqp pvread_method pvread_imnd

if nargin < 1,  eval(sprintf('help %s;',mfilename));  return;  end


if ischar(varargin{1}) && ~isempty(strfind(varargin{1},'fid')),
  % Called like pvread_fid(FIDFILE)
  imgfile = varargin{1};
  ivar = 2;
elseif ischar(varargin{1}) && ~isempty(strfind(varargin{1},'ser')),
  % Called like pvread_fid(SERFILE)
  imgfile = varargin{1};
  ivar = 2;
elseif ischar(varargin{1}) && ~isempty(strfind(varargin{1},'2dseq')),
  % Called like pvread_fid(2DSEQFILE)
  imgfile = fullfile(fileparts(fileparts(fileparts(varargin{1}))),'fid');
  ivar = 2;
else
  % Called like pvread_fid(SESSION,ExpNo)
  if nargin < 2,
    error(' ERROR %s: missing 2nd arg. as ExpNo.\n',mfilename);
    return;
  end
  ses = getses(varargin{1});
  imgfile = expfilename(ses,varargin{2},'fid');
  ivar = 3;
end


% check the file.
if ~exist(imgfile,'file'),
  error(' ERROR %s: ''%s'' not found.',mfilename,imgfile);
end

% SET OPTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ImgSize   = [];
ByteOrder = '';
WordType  = '';
acqp      = [];
method    = [];
imnd      = [];
for N = ivar:2:length(varargin),
  switch lower(varargin{N}),
   case {'imgsize','imagesize'}
    ImgSize = varargin{N+1};
   case {'byteorder','endian','byte_order'}
    ByteOrder = varargin{N+1};
   case {'wordtype','datatype','data type','word type'}
    WordType = varargin{N+1};
   case {'acqp'}
    acqp = varargin{N+1};
   case {'method'}
    method = varargin{N+1};
   case {'imnd'}
    imnd = varargin{N+1};
  end
end


% set byte order %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(ByteOrder),
  if isempty(acqp),  acqp = pvread_acqp(imgfile);  end
  ByteOrder = acqp.BYTORDA;
end
switch lower(ByteOrder),
 case {'s','swap','b','big','bigendian','big-endian'}
  ByteOrder = 'ieee-be';
 case {'n','noswap','non-swap','l','little','littleendian','little-endian'}
  ByteOrder = 'ieee-le';
end


% set data type %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(WordType),
  if isempty(acqp),  acqp = pvread_acqp(imgfile);  end
  if isfield(acqp,'GO_raw_data_format')
    WordType = acqp.GO_raw_data_format;
  else
    WordType = acqp.ACQ_word_size;
  end
end
switch WordType,
 case {'_16_BIT','GO_16BIT_SGN_INT','int16'}
  NBytes   = 2;
  WordType = 'int16=>int16';
 case {'_32_BIT','GO_32BIT_SGN_INT','int32'}
  NBytes   = 4;
  WordType = 'int32=>int32';
 otherwise
  error(' %s error: unknown data type, ''%s''.',WordType,mfilename);
end


imgp = [];
if nargout > 1
  if isempty(acqp),  acqp = pvread_acqp(imgfile);  end
  if isempty(method), method = pvread_method(imgfile,'verbose',0);  end
  
  imgp = pv_imgpar(imgfile,'acqp',acqp,'method',method);
end

% set image size if needed %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(ImgSize),
  if isempty(imgp),
    if isempty(acqp),  acqp = pvread_acqp(imgfile);  end
    if isempty(method), method = pvread_method(imgfile,'verbose',0);  end
    imgp = pv_imgpar(imgfile,'acqp',acqp,'method',method);
  end
  ImgSize = imgp.imgsize;
end




% READ DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fid = fopen(imgfile,'rb',ByteOrder);
IDATA = fread(fid,inf,WordType);
fclose(fid);

IDATA = reshape(IDATA,[2 numel(IDATA)/2]);
IDATA = complex(IDATA(1,:),IDATA(2,:));

try
  IDATA = reshape(IDATA,ImgSize);
catch
  fprintf('\n Num.elements=%d,',numel(IDATA));
  fprintf('\n expected ImgSize=[%s]\n',deblank(sprintf('%d ',ImgSize)));
  error(' ERROR %s : size mismatch.',mfilename);
end


% RETURN VALUES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout,
  varargout{1} = IDATA;
  if nargout > 1,
    varargout{2} = imgp;
  end
end


return;
