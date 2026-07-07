function [IDATA,acqp,reco] = tdseq_read(imgfile,imgcrop,timecrop,varargin)
% TDSEQ_READ - Read ParaVision 2dseq data
%  [IDATA,ACQP,RECO] = TDSEQ_READ(FILENAME)
%  [IDATA,ACQP,RECO] = TDSEQ_READ(FILENAME,IMGCROP,TIMECROP)
%  IDATA = TDSEQ_READ(FILENAME,IMGCROP,TIMECROP,ACQP,RECO)
%  IDATA = TDSEQ_READ(FILENAME,IMGCROP,TIMECROP,IMGSIZE,BYTEORDER,WORDTYPE)
%    imgcrop    : cropping as [x,y,width,height], can be empty. x,y>=1.
%    reco/acqp  : a reco sturcture returned by jpcode/PVrdPar.m
%    timecrop   : cropping as [t,nt], can be empty.  t>=1.
%    imgsize    : image size as [nx, ny, nslices, ntime], must not be empty.
%    byteorder  : (s) swap, (n) non-swap is required
%	 wordtype   : _16BIT_SGN_INT or _32BIT_SGN_INT
%
%  Returned IDATA is NOT 'double', but 'wordtype'.
%
% VERSION :
%   0.90 18.11.04 YM  pre-release
%   0.91 07.03.07 YM  bug fix on reading mdeft.
%
% See also PVRDPAR, PVRDPARRECO, pvread_2dseq

if nargin < 1,  help tdseq_read;  return;  end

% check the file.
if ~exist(imgfile,'file'),
  error(' tdseq_read error: ''%s'' not found.',imgfile);
end

if nargin < 4,
  % called as TDSEQ_READ(FILENAME) or TDSEQ_READ(FILENAME,IMGCROP)
  global STDPATH
  [tmpdir,reconum] = fileparts(fileparts(imgfile));
  [tmpdir,filenum] = fileparts(fileparts(tmpdir));
  [STDPATH.pv,tmpdir,tmpext] = fileparts(tmpdir);
  STDPATH.pv(end+1) = '/';
  filedir = strcat(tmpdir,tmpext);
  reconum = str2num(reconum);
  acqp = PVrdPar(filedir, filenum, opt('GEO',0,'VERBOSE',0));
  reco = PVrdParReco(filedir, filenum, opt('RECO',reconum,'VERBOSE',0) );
  byteorder = reco.RECO_byte_order;
  wordtype  = reco.RECO_wordtype;
  if nargin < 2,  imgcrop = [];   end
  if nargin < 3,  timecrop = [];  end
elseif nargin == 5 & isstruct(varargin{1}) & isstruct(varargin{2}),
  % called as TDSEQ_READ(FILENAME,IMGCROP,TIMECROP,ACQP,RECO)
  acqp = varargin{1};
  reco = varargin{2};
  byteorder = reco.RECO_byte_order;
  wordtype  = reco.RECO_wordtype;
elseif nargin == 6,
  % called as TDSEQ_READ(FILENAME,IMGCROP,TIMECROP,IMGSIZE,BYTEORDER,WORDTYPE)
  NX        = varargin{1}(1);
  NY        = varargin{1}(2);
  NS        = varargin{1}(3);
  NT        = varargin{1}(4);
  byteorder = varargin{2};
  wordtype  = varargin{3};
  % just to avoid error.
  reco = [];
else
  fprintf(' tdseq_read error: wrong input argument(s).\n');
  return;
end

if ~exist('NX','var'),
  NX = reco.RECO_size(1);
  if length(reco.RECO_size) < 2,  %% 1D case
    NY = 1;
  else
    NY = reco.RECO_size(2);
  end
  NS = acqp.NSLICES;
  NT = acqp.NR;
  if strncmp(acqp.PULPROG,'<mdeft',5),
    if length(reco.RECO_size) > 2,
      NS = reco.RECO_size(3);
    end
    NT = acqp.NI;
  end
end


% set byte order
switch lower(byteorder),
 case {'s','swap','b','big','bigendian','big-endian'}
  byteorder = 'ieee-be';
 case {'n','noswap','non-swap','l','little','littleendian','little-endian'}
  byteorder = 'ieee-le';
end


% set data type
switch wordtype,
 case {'_16_BIT','_16BIT_SGN_INT','int16'}
  wordtype = 'int16=>int16';
  nbytes   = 2;
 case {'_32_BIT','_32BIT_SGN_INT','int32'}
  wordtype = 'int32=>int32';
  nbytes   = 4;
 otherwise
  error(' tdseq_read error: unknown data type, ''%s''.',wordtype);
end


fid = fopen(imgfile,'rb',byteorder);
if isempty(timecrop),
  IDATA = fread(fid, inf, wordtype);
else
  T  = timecrop(1);
  NT = timecrop(2);
  try,
    if T > 1,
      fseek(fid, NX*NY*NS*(T-1)*nbytes, 'bof');
    end
    IDATA = fread(fid, NX*NY*NS*NT, wordtype);
  catch
    fclose(fid);
    fprintf(' expected [NX,NY,NSLICES,NT] = [%d,%d,%d,%d]\n',NX,NY,NS,NT);
    error(' tdseq_read error: imgsize is out of range.');
  end
end
fclose(fid);


if isfield(reco,'RECO_image_type') & strcmp(reco.RECO_image_type, 'COMPLEX_IMAGE'),
  % According to ParaVision manual,
  % first all real data is written to 2dseq, then imaginary data is appended to it.
  IDATA = reshape(IDATA,length(IDATA)/2,2);
  IDATA = complex(IDATA(:,1),IDATA(:,2));
end

try,
  IDATA = reshape(IDATA,NX,NY,NS,NT);
catch
  fprintf(' Num.elements=%d,',numel(IDATA));
  fprintf(' expected [NX,NY,NSLICES,NT] = [%d,%d,%d,%d]\n',NX,NY,NS,NT);
  error(' tdseq_read error: imgsize is out of range.');
end


if ~isempty(imgcrop),
  % imgcrop as [x,y,width,height]
  try,
    ix = [1:imgcrop(3)] + imgcrop(1)-1;
    iy = [1:imgcrop(4)] + imgcrop(2)-1;
    IDATA = IDATA(ix,iy,:,:);
  catch
    size(IDATA)
    imgcrop
    error(' tdseq_read error: imgcrop is out of range.\n');
  end
end

return;

