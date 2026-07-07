function im = read2dseq(fname,nx,nx1,nx2,ny,ny1,ny2,ns,ns1,ns2,nt1,nt2,byteorder,wordtype,datclass)
%READ2DSEQ - Read Paravision Data
%  im=READ2DSEQ(fname,nx,nx1,nx2,ny,ny1,ny2,ns,ns1,ns2,nt1,nt2,byteorder,wordtype)
%	nx,ny,ns		: x- and y- dimensions of image, and # of slices
%	nx1,nx2,ny1,ny2	: crop dimensions
%	ns1,ns2			: slice range
%	nt1,nt2			: time point range
%	byteorder		: (s) swap, (n) non-swap is required
%	wordtype		: _8BIT_UNSGN_INT, _16BIT_SGN_INT or _32BIT_SGN_INT
%
%	NOTE: This function should now read any data... (old mread2dseq not needed)
%
%	NKL, 09.06.02
%   YM,  03.03.04 supports 'wordtype'.
%   YM,  17.11.04 improved speed upto x2.3 (30.1sec --> 13.1sec/84M).
%   YM,  26.01.06 supports 'datclass' as data type of output image.
%   YM,  29.05.08 if byteorder=='', then assume 'bigEndian'.
%
% See also IMGLOAD, GETPVPARS, SESASCAN, SESCSCAN, TDSEQ_READ

if nargin == 0,  help read2dseq;  return;  end

if ~exist(fname,'file'),
  error(' ERROR %s: ''%s'' not found.\n Check filename or network connection.'...
        ,mfilename,fname);
end


if ~exist('wordtype','var'),  wordtype = '_16BIT_SGN_INT';  end		% file data type
if ~exist('datclass','var'),   datclass = 'double';  end              % output data type

if nargin == 1, 
  % tdseq_read() will get imaging parameters from acqp/reco.
  im = tdseq_read(fname);
  im = double(im);
  return;
else
  if isempty(byteorder),
    byteorder = 'bigEndian';
    fprintf(' WARNING %s: assuming as ''%s''...',mfilename,byteorder);
  end
  if isempty(wordtype),   wordtype  = '_16BIT_SGN_INT';  end
  
  im = subRead2dseq(fname,nx,nx1,nx2,ny,ny1,ny2,ns,ns1,ns2,nt1,nt2,...
                    byteorder,wordtype,datclass);
end


switch lower(datclass),
 case {'double'}
  im = double(im);
 case {'single'}
  im = single(im);
 case {'_8bit_unsgn_int', 'uint8', 'char' }
  im = uint8(im);
 case {'_16bit_unsgn_int', 'uint16' }
  im = uint16(im);
 case {'_32bit_unsgn_int', 'uint32' }
  im = uint32(im);
 case {'_64bit_unsgn_int', 'uint64' }
  im = uint64(im);
 case {'_16bit_sgn_int', 'int16', 'short' }
  im = int16(im);
 case {'_32bit_sgn_int', 'int32', 'long' }
  im = int32(im);
 case {'_64bit_sgn_int', 'int64', 'longlong' }
  im = int64(im);
 otherwise
  error(' ERROR %s: unsupported data class, ''%s''.',mfilename,datclass);
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to read 2dseq
function im = subRead2dseq(fname,nx,nx1,nx2,ny,ny1,ny2,ns,ns1,ns2,nt1,nt2,byteorder,wordtype,dattyp)


% set byte order
switch lower(byteorder),
 case {'s','swap','b','big','bigendian','big-endian','ieee-be','be'}
  byteorder = 'ieee-be';
 case {'n','noswap','non-swap','l','little','littleendian','little-endian','ieee-le','le'}
  byteorder = 'ieee-le';
end

% 17.11.04 YM, no precision conversion for faster reading.
% This will be 2.4 times farster than with conversion.
switch wordtype,
 case {'_8BIT_UNSGN_INT', 'uint8', 'char' }
  wordtype = 'uint8=>unit8';
  nbytes = 1;
 case {'_16BIT_SGN_INT', 'int16', 'short' }
  wordtype = 'int16=>int16';
  nbytes = 2;
 case {'_32BIT_SGN_INT', 'int32', 'long' }
  wordtype = 'int32=>int32';
  nbytes = 4;
end


ds = ns2 - ns1 + 1;		% Number of Slices
nt = nt2 - nt1 + 1;		% Number of Time Points
dx = nx2 - nx1 + 1;
dy = ny2 - ny1 + 1;


%wordtype = 'int16';
wtype = wordtype(1:findstr(wordtype,'=>')-1);
im = zeros(dx,dy,ds,nt, wtype);
nVoxVol = nx*ny*ns;
ix = nx1:nx2;
iy = ny1:ny2;
is = ns1:ns2;

h = waitbar(0,strrep(strrep(sprintf('read2dseq: Loading images...\n %s',fname),'\','/'),'_','\_'));

fid = fopen(fname,'rb',byteorder);
try,
  if nt1 > 1,
    fseek(fid, neleVol*(nt1-1)*nbytes, 'bof');
  end

  for TPNT = 1:nt,
    waitbar(TPNT/nt, h);
    im0 = fread(fid, nVoxVol, wordtype);
    im0 = reshape(im0, nx, ny, ns);
    %im(:,:,:,TPNT) = double(im0(nx1:nx2,ny1:ny2,ns1:ns2));
    im(:,:,:,TPNT) = im0(ix, iy, is);
  end
catch,
  fclose(fid);	% close the file handle first for safety.
  disp(lasterr);
  fprintf('2dseq: %s\n',fname);
  fprintf('CROP DIMENSIONS (DESCR. FILE): dx,dy,ds,nt = %d %d %d %d\n',dx,dy,ds,nt);
  fprintf('PARAVISION DIMENSIONS: nx,ny,ns    = %d %d %d\n', nx,ny,ns);
  fprintf('Check ''crop'', ''imgcrop'' or ''scanreco'' in the session file.\n');
  keyboard;
end;

fclose(fid);
  
if ishandle(h),  close(h);  drawnow;  end



return;
