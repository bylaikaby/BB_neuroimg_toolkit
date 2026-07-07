function varargout = mnupdate_ana(SESSION,GRPNAME,AVERAGE_IDX,REALIGNED)
%MNUPDATE_ANA - Updates anatomy data.
%
%  EXAMPLE :
%    mnupdate_ana('ratci1','mdeftinj',1:2);  % average 1:2 volumes 
%
%  NOTE :
%    THIS PROGRAM ASSUMES DATATYPE AS INT16.
%
%  VERSION :
%    0.90 07.07.2006 YM  pre-release.
%
%  See also HDR_READ, MNREALIGN, MN_TCSLICE_LOAD, MN_SPM2MAT

if nargin < 2,  help mnupdate_ana; return;  end

if nargin < 3,  AVERAGE_IDX = [];  end
if nargin < 4,  REALIGNED = 1;  end

DIR_SPM = 'spm';

% CONTROL FLAGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DO_EXPORT_ANATOMY  = 1;


% ENTER THE INTERACTIVE MODE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 4,
  % use realigned data or not.
  c = input('Q: Export realigned data? Y/N[Y]: ','s');
  if isempty(c), c = 'Y'; end
  if c == 'y' | c == 'Y',
    REALIGNED = 1;
  else
    REALIGNED = 0;
  end
end
  
  
if REALIGNED > 0,
  DIR_TCSLICE = 'TC_SLICE_REALIGNED';
else
  DIR_TCSLICE = 'TC_SLICE_RAW';
end


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses  = goto(SESSION);
grp  = getgrp(SESSION,GRPNAME);
EXPS = grp.exps;

% Note that REALIGNED/RESLICED has a filename with 'r' prefix.
if REALIGNED,
  for iExp = length(EXPS):-1:1,
    ExpNo = EXPS(iExp);
    IMGFILES{iExp} = sprintf('%s/r%s_%03d.img',DIR_SPM,Ses.name,ExpNo);
  end
else
  for iExp = length(EXPS):-1:1,
    ExpNo = EXPS(iExp);
    IMGFILES{iExp} = sprintf('%s/%s_%03d.img',DIR_SPM,Ses.name,ExpNo);
  end
end


% Get dimension of .img file %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[fp,fr,fe] = fileparts(IMGFILES{1});
hdrfile = fullfile(fp,sprintf('%s.hdr',fr));	% like spm/m02th1_001.hdr
HDR  = hdr_read(hdrfile);
nx   = HDR.dime.dim(2);
ny   = HDR.dime.dim(3);
nz   = HDR.dime.dim(4);
nt   = length(EXPS);
xres = double(HDR.dime.pixdim(2));
yres = double(HDR.dime.pixdim(3));
zres = double(HDR.dime.pixdim(4));


% READING IMAGES, SUPPORTS ONLY INT16 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if REALIGNED,
  fprintf(' %s: reading REALIGNED images (n=%d)...',mfilename,length(IMGFILES));
else
  fprintf(' %s: reading ORIGINAL images (n=%d)...',mfilename,length(IMGFILES));
end
DAT = zeros(nx,ny,nz,nt,'int16');
for N = 1:length(IMGFILES),
  fid = fopen(IMGFILES{N},'rb');
  if fid < 0,
    fprintf(' %s ERROR: failed to open ''%s''.\n',mfilename,IMGFILES{N});
    keyboard
  end
  tmpimg = fread(fid,inf,'int16=>int16');
  fclose(fid);
  tmpimg = reshape(tmpimg,nx,ny,nz);
  DAT(:,:,:,N) = tmpimg;
end
fprintf(' done.\n');



% NOW UPDATES ANATOMY DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if DO_EXPORT_ANATOMY,
  if isempty(AVERAGE_IDX),  AVERAGE_IDX = 1:size(DAT,4);  end
  MDAT = squeeze(mean(DAT(:,:,:,AVERAGE_IDX),4));
  MDAT = int16(round(MDAT));
  ADAT = MDAT;
  ananame = grp.ana{1};
  anascan = grp.ana{2};
  anafile = sprintf('%s.mat',ananame);

  fprintf(' %s: updating anatomy ''%s{%d}''...',mfilename,ananame,anascan);
  ANA = load(anafile,ananame);
  ANA = ANA.(ananame);
  ANA{anascan}.dat = ADAT;
  ANA{anascan}.ds  = [xres yres zres];
  eval(sprintf('%s = ANA;',ananame));
  save(anafile,ananame,'-append');
  fprintf(' done.\n');
end




return;
