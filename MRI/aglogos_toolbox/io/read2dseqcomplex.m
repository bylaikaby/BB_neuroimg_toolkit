function im = read2dseqcomplex(SesDir, ScanNo, RecoNo)
%READ2DSEQCOMPLEX - Read Paravision Data reconstructed as complex numbers
%  im=READ2DSEQCOMPLEX(SesDir, ScanNo, RecoNo)
%
%	NKL, 21.03.06
%
% See also GETPVPARS

% global STDPATH
% global acqp reco
  
if nargin < 3,
  RecoNo = 1;
end;

if nargin & nargin < 2,
  help read2dseqcomplex;
  return;
end;

if nargin == 0,
  fprintf('DUBUG MODE: Testing rat.AD1, Scan=21, Reco=1\n');
  SesDir = 'rat.AD1';
  ScanNo = 21;
  RecoNo = 1;
end;

pv = getpvpars(SesDir, ScanNo, RecoNo);
DIRS = getdirs;
fname = sprintf('%s%s/%d/pdata/%d/2dseq',DIRS.mridir,SesDir,ScanNo,RecoNo);

im = rd2dseq(fname);



% im = subRead2dseqcomplex(fname,pv.nx,1,pv.nx,pv.ny,1,pv.ny,pv.nsli,1,pv.nsli,1,pv.nt,...
%                          'n',pv.reco.RECO_wordtype,'double');




keyboard



return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to read 2dseq
function im = subRead2dseqcomplex(fname,nx,nx1,nx2,ny,ny1,ny2,ns,ns1,ns2,nt1,nt2,byteorder,wordtype,dattyp)

% set byte order
switch lower(byteorder),
 case {'s','swap','b','big','bigendian','big-endian'}
  byteorder = 'ieee-be';
 case {'n','noswap','non-swap','l','little','littleendian','little-endian'}
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

h = waitbar(0,sprintf('read2dseqcomplex: Loading images...\n %s',fname));

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
