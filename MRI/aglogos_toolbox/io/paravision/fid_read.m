function [KDATA,acqp] = fid_read(fidfile,varargin)
% FID_READ - Read ParaVision K-space data, usually named 'fid'
%  [KDATA,ACQP] = FID_READ(FILENAME)
%  KDATA = FID_READ(FILENAME,ACQP)
%  KDATA = FID_READ(FILENAME,BYTEORDER,WORDTYPE)
%    acqp       : a acqp sturcture returned by jpcode/PVrdPar.m
%    byteorder  : (s) swap, (n) non-swap is required
%	 wordtype   : _16BIT_SGN_INT or _32BIT_SGN_INT
%
%  Returned KDATA is just a vector, use FID_RESHAPE to reconstruct
%  K-space dimension, like KRESHAPED = FID_RESHAPE(KDATA,ACQP).
%
% VERSION : 0.90 12.11.04 YM  pre-release
%           0.91 18.11.04 YM  supports restored data from tape
%
% See also PVRDFID, PVRDPAR, FID_RESHAPE, FID_RESHAPE, FID_RECO

if nargin < 1,  help fid_read;  return;  end

% check the file.
if ~exist(fidfile,'file'),
  % checks as "fid.orig" that is usually backuped from a tape.
  [fp,fr,fe] = fileparts(fidfile);
  if exist(sprintf('%s/%s.orig',fp,fr),'file'),
    fidfile = sprintf('%s/%s.orig',fp,fr);
  else
    error(sprintf(' fid_read error: ''%s (or fid.orig)'' not found.',fidfile));
  end
end

if nargin == 1,
  % called as FID_READ(FILENAME)
  global STDPATH
  [tmpdir,filenum] = fileparts(fileparts(fidfile));
  [STDPATH.pv,tmpdir,tmpext] = fileparts(tmpdir);
  STDPATH.pv(end+1) = '/';
  filedir = strcat(tmpdir,tmpext);
  acqp = PVrdPar(filedir, filenum, opt('GEO',0,'VERBOSE',0));
  byteorder = acqp.BYTORDA;
  wordtype  = acqp.ACQ_word_size;
elseif nargin == 2 & isstruct(varargin{1}),
  % called as FID_READ(FILENAME,ACQP)
  acqp = varargin{1};
  byteorder = acqp.BYTORDA;
  wordtype  = acqp.ACQ_word_size;
elseif nargin == 3
  % called as FID_READ(FILENAME,BYTEORDER,WORDTYPE)
  byteorder = varargin{1};
  wordtype  = varargin{2};
else
  fprintf(' fid_read error: wrong input argument(s).\n');
  return;
end


% set byte order
switch lower(byteorder),
 case {'s','swap','b','bigendian','big-endian'}
  byteorder = 'ieee-be';
 case {'n','noswap','non-swap','l','little','littleendian','little-endian'}
  byteorder = 'ieee-le';
end

% set data type
switch wordtype,
 case {'_16_BIT','_16BIT_SGN_INT','int16'}
  wordtype = 'int16=>int16';
 case {'_32_BIT','_32BIT_SGN_INT','int32'}
  wordtype = 'int32=>int32';
 otherwise
  error('');
end


fid = fopen(fidfile,'rb',byteorder);
KDATA = fread(fid,inf,wordtype);
fclose(fid);

%KDATA = reshape(KDATA,2,length(KDATA));
%KDATA = complex(KDATA(1,:),KDATA(2,:));


return;

