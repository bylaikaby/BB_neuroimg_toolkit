function varargout = mn_dat2medx(SESSION,GRPNAME,WHICH_DATA,VERBOSE)
%MN_DAT2MEDX - exports imaging data for MEDX.
%  MN_DAT2MEDX(SESSION,GRPNAME) will create .hdr/.img files, that MEDX
%  can handle, from 2dseq or tcImg.dat data.
%  FILES = MN_DAT2MEDX(...) will return exported .img files.
%
%  EXAMPLE :
%    mn_dat2medx('m02th1','mdeftinj');          % from 2dseq to .img/.hdr
%    mn_dat2medx('m02th1','mdeftinj','tcImg');	% from tcImg to .img/.hdr
%
%  NOTE :
%    THIS PROGRAM ASSUMES DATATYPE OF TCIMG.DAT/2DSEQ AS INT16.
%
%  VERSION :
%    0.90 21.09.2005 YM  pre-release.
%    0.91 06.02.2012 YM  use expfilename() instead of catfilename().
%
%  See also MN_DAT2SPM


if nargin < 2;  mn_dat2medx; return;  end

if nargin < 3,  WHICH_DATA = '';   end
if nargin < 4,  VERBOSE    = 1;    end

if isempty(WHICH_DATA),  WHICH_DATA = '2dseq';  end
if ~strcmpi(WHICH_DATA,'2dseq') & ~strcmpi(WHICH_DATA,'tcImg'),
  fprintf('%s ERROR: unknown data to export, should be 2dseq or tcImg.\n',mfilename);
  return;
end


DO_IMGCROP = 1;   % 2dseq image cropping
DO_SLICROP = 1;   % 2dseq slice cropping
DO_PERMUTE = 1;   % 2dseq permuation
DO_FLIPDIM = 1;   % 2dseq flip dimension


% BASIC INFORMATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses  = goto(SESSION);
grp  = getgrp(Ses,GRPNAME);
EXPS = grp.exps;
par  = expgetpar(Ses,EXPS(1));
pv   = par.pvpar;

if exist('medx','dir') == 0,
  mkdir('medx');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TESTGIN...
%EXPS = EXPS(1:10);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% RECOVER THE ORIGINAL RECO SIZE. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% who change pvpar.nx/ny/nsli?????
if pv.nx ~= pv.reco.RECO_size(1),
  pv.nx = pv.reco.RECO_size(1);
end
if pv.ny ~= pv.reco.RECO_size(2),
  pv.ny = pv.reco.RECO_size(2);
end
if pv.nsli ~= pv.reco.RECO_size(3),
  pv.nsli = pv.reco.RECO_size(3);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


xres = pv.reco.RECO_fov(1)/pv.reco.RECO_size(1) * 10;	% in mm
yres = pv.reco.RECO_fov(2)/pv.reco.RECO_size(2) * 10;	% in mm
zres = pv.reco.RECO_fov(3)/pv.reco.RECO_size(3) * 10;	% in mm


IMGFILES = cell(1,length(EXPS));
HDRFILES = cell(1,length(EXPS));

if VERBOSE,  fprintf('%s %s BEGIN...\n',gettimestring,mfilename);  end
try,
  VOL_TC = [];
for iExp = 1:length(EXPS),

  ExpNo = EXPS(iExp);

  if VERBOSE, fprintf(' [%3d/%d] Exp=%3d:',iExp,length(EXPS),ExpNo);  end

  if VERBOSE, fprintf(' reading');  end
  if strcmpi(WHICH_DATA,'2dseq'),
    if VERBOSE, fprintf(' 2dseq...');  end
    IN_IMGFILE = expfilename(Ses,ExpNo,'2dseq');
    if strcmpi(par.pvpar.reco.RECO_byte_order,'bigEndian'),
      fid = fopen(IN_IMGFILE,'rb','ieee-be');
    else
      fid = fopen(IN_IMGFILE,'rb');
    end
    tmpimg = fread(fid,inf,'int16=>int16');
    fclose(fid);
    tmpimg = reshape(tmpimg,pv.nx,pv.ny,pv.nsli);
    pixdim = [xres yres zres];

    % IMAGE CROPPING ============================================
    if DO_IMGCROP > 0,
      if isfield(Ses.expp(ExpNo),'imgcrop') & ~isempty(Ses.expp(ExpNo).imgcrop),
        nx = Ses.expp(ExpNo).imgcrop(3);
        ny = Ses.expp(ExpNo).imgcrop(4);
        XSEL = [1:nx] + Ses.expp(ExpNo).imgcrop(1) - 1;
        YSEL = [1:ny] + Ses.expp(ExpNo).imgcrop(2) - 1;
      elseif isfield(grp,'imgcrop') & ~isempty(grp.imgcrop),
        nx = grp.imgcrop(3);
        ny = grp.imgcrop(4);
        XSEL = [1:nx] + grp.imgcrop(1) - 1;
        YSEL = [1:ny] + grp.imgcrop(2) - 1;
      else
        XSEL = 1:pv.nx;
        YSEL = 1:pv.ny;
      end
      tmpimg = tmpimg(XSEL,:,:);
      tmpimg = tmpimg(:,YSEL,:);
    end
    % SLICE CROPPING ============================================
    if DO_SLICROP > 0,
      if isfield(Ses.expp(ExpNo),'slicrop') & ~isempty(Ses.expp(ExpNo).slicrop),
        nsli = Ses.expp(ExpNo).slicrop(2);
        SSEL = [1:nsli] + Ses.expp(ExpNo).slicrop(1) - 1;
      elseif isfield(grp,'ns1'),
        nsli = grp.ns2 - grp.ns1 + 1;
        SSEL = grp.ns1:grp.ns2;
      elseif isfield(grp,'slicrop'),
        nsli = grp.slicrop(2);
        SSEL = [1:nsli] + grp.slicrop(1) - 1;
      else
        SSEL = 1:pv.nsli;
      end
      tmpimg = tmpimg(:,:,SSEL);
    end
    % IMAGE PERMUTATION =========================================
    if DO_PERMUTE & isfield(grp,'permute') & ~isempty(grp.permute),
      tmpimg = permute(tmpimg,grp.permute);
      pixdim(1:3) = permute([xres yres zres],grp.permute);
    end
    % FLIPING DIMENSION =========================================
    if DO_FLIPDIM & isfield(grp,'flipdim') & ~isempty(grp.flipdim),
      for iDim = 1:length(grp.flipdim),
        tmpimg = flipdim(tmpimg,grp.flipdim(iDim));
      end
    end
  else
    if VERBOSE, fprintf(' tcImg...');  end
    tcImg = sigload(Ses,ExpNo,'tcImg');
    tmpimg = tcImg.dat;
    pixdim = [tcImg.ds(1) tcImg.ds(2) tcImg.ds(3)];
  end
  dim = [size(tmpimg,1) size(tmpimg,2) size(tmpimg,3) length(EXPS)];

  if isempty(VOL_TC),
    VOL_TC = zeros(size(tmpimg,1),size(tmpimg,2),size(tmpimg,3),length(EXPS),'int16');
  end

  VOL_TC(:,:,:,iExp) = tmpimg;
  if VERBOSE, fprintf(' done.\n');  end
  
end


% write .img/.hdr files.
IMGFILE = sprintf('medx/%s_%s.raw',Ses.name, grp.name);
TXTFILE = sprintf('medx/%s_%s.txt',Ses.name, grp.name);
if VERBOSE, fprintf(' writing to %s/txt...',IMGFILE);  end
fid = fopen(IMGFILE,'wb','ieee-le');
fwrite(fid, VOL_TC, 'int16');
fclose(fid);
fid = fopen(TXTFILE,'wt');
fprintf(fid,'session= %s\n',Ses.name);
fprintf(fid,'grpname= %s\n',grp.name);
fprintf(fid,'exps=['); fprintf(fid,' %d',grp.exps); fprintf(fid,' ]\n');
fprintf(fid,'byte_order= littleEndian\n');
fprintf(fid,'wordtype= _16BIT_SGN_INT\n');
fprintf(fid,'rawdim= [');  fprintf(fid,' %d',dim); fprintf(fid,' ]\n');
fprintf(fid,'pixdim= [');  fprintf(fid,' %.2f',pixdim); fprintf(fid,' ]\n');
fclose(fid);

if VERBOSE, fprintf(' done.\n');  end


catch,
  fprintf('%s: %s',mfilename,lasterr);
  try, fclose(fid); end
  keyboard
end
if VERBOSE, fprintf('%s %s END.\n',gettimestring,mfilename);  end

if nargout,
  varargout{1} = IMGFILE;
  if nargout > 1,
    varargout{2} = TXTFILE;
  end
end


return;
