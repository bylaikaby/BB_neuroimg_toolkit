function im = read2dseq(fname,nx,nx1,nx2,ny,ny1,ny2,ns,ns1,ns2,nt1,nt2,byteorder,wordtype)
%READ2DSEQ - Read Paravision Data
%	im=READ2DSEQ(fname,nx,nx1,nx2,ny,ny1,ny2,ns,ns1,ns2,nt1,nt2,byteorder,wordtype)
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
%
% See also IMGLOAD, GETPVPARS, SESASCAN, SESCSCAN

if nargin == 0,  help read2dseq;  return;  end

if byteorder == 's',
  fid = fopen(fname,'r','ieee-be');
else
  fid = fopen(fname,'r');
end

if ~exist('wordtype','var'),  wordtype = '_16BIT_SGN_INT';  end

switch wordtype,
 case {'_8BIT_UNSGN_INT', 'uint8', 'char' }
  imgfmt = 'uint8';
  nbytes = 1;
 case {'_16BIT_SGN_INT', 'int16', 'short' }
  imgfmt = 'int16';
  nbytes = 2;
 case {'_32BIT_SGN_INT', 'int32', 'long' }
  imgfmt = 'int32';
  nbytes = 4;
end

try,	
  ds = ns2 - ns1 + 1;		% Number of Slices
  nt = nt2 - nt1 + 1;		% Number of Time Points
  dx = nx2 - nx1 + 1;
  dy = ny2 - ny1 + 1;

  im = zeros(dx,dy,ds,nt);
  h = waitbar(0,'Loading images');

  if nt1 > 1,
    fseek(fid,nx*ny*ns*(nt1-1)*nbytes,'bof');	
  end

  for TPNT = 1:nt,
    waitbar(TPNT/nt,h)
    %im0=fread(fid,nx*ny*ns,'uint16');
    %im0 = fread(fid,nx*ny*ns,'int16');
    im0 = fread(fid,nx*ny*ns,imgfmt);
    im0 = reshape(im0,nx,ny,ns);
    im(:,:,:,TPNT) = im0(nx1:nx2,ny1:ny2,ns1:ns2);
  end
catch,
  fclose(fid);	% close the file handle first for safety.
  disp(lasterr);
  fprintf('2dseq: %s\n',fname);
  fprintf('READ: dx,dy,ds,nt = %d %d %d %d\n',dx,dy,ds,nt);
  fprintf('FILE: nx,ny,ns    = %d %d %d\n', nx,ny,ns);
  fprintf('Check ''crop'', ''imgcrop'' or ''scanreco'' in the session file.\n');
  keyboard;
end;

fclose(fid);
close(h);

return;
