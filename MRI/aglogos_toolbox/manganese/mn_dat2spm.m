function varargout = mn_dat2spm(SESSION,GRPEXP,WHICH_DATA,varargin)
%MN_DAT2SPM - exports imaging data for SPM.
%  MN_DAT2SPM(SESSION,GRPNAME)
%  MN_DAT2SPM(SESSION,EXPS) will create .hdr/.img files, that SPM
%  can handle, from 2dseq or tcImg.dat data.
%  FILES = MN_DAT2SPM(...) will return exported .img files.
%
%  Supported options are :
%    SAVE_DIR : directory to export
%    DATATYPE : data type, 'int16' or 'uint8'
%    PREFIX   : prefix for the exported filename
%    POSTFIX  : postfix for the exported filename
%
%  EXAMPLE :
%    mn_dat2spm('m02th1','mdeftinj');           % from 2dseq to .img/.hdr
%    mn_dat2spm('m02th1','mdeftinj','tcImg');	% from tcImg to .img/.hdr
%
%  NOTE :
%    THIS PROGRAM ASSUMES DATATYPE OF TCIMG.DAT/2DSEQ AS INT16.
%
%  VERSION :
%    0.90 01.06.2005 YM  pre-release.
%    0.91 02.06.2005 YM  checks pv.nx/ny/nsli.
%    0.92 03.06.2005 YM  supports PERMUTE/FLIPDIM for 2dseq.
%    0.93 10.07.2005 YM  supports o02wu1/wx1, using Ses.expp(N).imgcrop/slicrop
%    0.94 08.08.2005 YM  checks RECO_byte_order for 2dseq's machine format.
%    0.95 31.07.2006 YM  bug fix on reco.RECO_transposition.
%    0.96 10.02.2011 YM  supports 'SAVE_DIR'.
%    0.97 22.02.2011 YM  supports 'PREFIX', 'POSTFIX', 'DATATYPE'.
%    0.98 23.02.2011 YM  supports 'SAVE_TEXT' for info.
%    0.99 06.02.2012 YM  use expfilename() instead of catfilename();
%
%  See also MNREALIGN, HDR_INIT, HDR_WRITE


if nargin < 2;  mn_dat2spm; return;  end

if nargin < 3,  WHICH_DATA = '';   end

if isempty(WHICH_DATA),  WHICH_DATA = '2dseq';  end
if ~any(strcmpi(WHICH_DATA,{'2dseq' 'tcImg'})),
  fprintf('%s ERROR: unknown data to export, should be 2dseq or tcImg.\n',mfilename);
  return;
end

% OPTIONAL SETTINGS
SAVE_DIR  = 'spm';
PREFIX    = '';
POSTFIX   = '';
DATA_TYPE = 'int16';
SAVE_TEXT = 0;
VERBOSE   = 1;
for N = 1:2:length(varargin),
  switch lower(varargin{N})
   case {'dir','savedir','save_dir'}
    SAVE_DIR = varargin{N+1};
   case {'prefix','pre_fix'}
    PREFIX   = varargin{N+1};
   case {'postfix','post_fix'}
    POSTFIX  = varargin{N+1};
   case {'datatype','data_type'}
    DATA_TYPE = varargin{N+1};
   case {'savetext','save_text','savetxt','save_txt', 'text', 'txt'}
    SAVE_TEXT = varargin{N+1};
   case {'verbose'}
    VERBOSE  = varargin{N+1};
  end
end


if ~any(strcmpi(DATA_TYPE,{'int16','uint8'})),
  error('\n ERROR %s: DATA_TYPE must be ''int16'' or ''uint8''\n',mfilename);
end



DO_IMGCROP = 1;   % 2dseq image cropping
DO_SLICROP = 1;   % 2dseq slice cropping
DO_PERMUTE = 1;   % 2dseq permuation
DO_FLIPDIM = 1;   % 2dseq flip dimension


% BASIC INFORMATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses  = goto(SESSION);
if isnumeric(GRPEXP),
  grp  = getgrp(Ses,GRPEXP(1));
  EXPS = GRPEXP;  % GRPEXP as EXPS
else
  grp  = getgrp(Ses,GRPEXP);
  EXPS = grp.exps;
end
par  = expgetpar(Ses,EXPS(1));
pv   = par.pvpar;

if exist(fullfile(pwd,SAVE_DIR),'dir') == 0,
  mkdir(SAVE_DIR);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TESTGIN...
%EXPS = EXPS(1:10);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

xres = pv.reco.RECO_fov(1)/pv.reco.RECO_size(1) * 10;	% in mm
yres = pv.reco.RECO_fov(2)/pv.reco.RECO_size(2) * 10;	% in mm
zres = pv.reco.RECO_fov(3)/pv.reco.RECO_size(3) * 10;	% in mm

% RECOVER THE ORIGINAL RECO SIZE. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% who change pvpar.nx/ny/nsli?????
if pv.reco.RECO_transposition(1) > 0,
  tmpv = xres;
  xres = yres;
  yres = tmpv;
else
  if any([pv.nx pv.ny pv.nsli] ~= pv.reco.RECO_size(1:3)'),
    fprintf(' wrong dim? [%d %d %d] ~= RECO_size[%d %d %d]\n',...
          pv.nx,pv.ny,pv.nsli,...
        pv.reco.RECO_size(1),pv.reco.RECO_size(2),pv.reco.RECO_size(3));
  end
  if pv.nx ~= pv.reco.RECO_size(1),
    pv.nx = pv.reco.RECO_size(1);
  end
  if pv.ny ~= pv.reco.RECO_size(2),
    pv.ny = pv.reco.RECO_size(2);
  end
  if pv.nsli ~= pv.reco.RECO_size(3),
    pv.nsli = pv.reco.RECO_size(3);
  end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


IMGFILES = cell(1,length(EXPS));
HDRFILES = cell(1,length(EXPS));

if VERBOSE,  fprintf('%s %s BEGIN...\n',gettimestring,mfilename);  end
try,
for iExp = 1:length(EXPS),

  ExpNo = EXPS(iExp);
  %fprintf('Current Group/Experiment %s (%d)\n', grp.name,ExpNo);

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
    pixdim = [3 xres yres zres 0 0 0 0];	% must be 8 elements

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
    if DO_PERMUTE && isfield(grp,'permute') && ~isempty(grp.permute),
      tmpimg = permute(tmpimg,grp.permute);
      pixdim(2:4) = permute([xres yres zres],grp.permute);
    end
    % FLIPING DIMENSION =========================================
    if DO_FLIPDIM && isfield(grp,'flipdim') && ~isempty(grp.flipdim),
      for iDim = 1:length(grp.flipdim),
        tmpimg = flipdim(tmpimg,grp.flipdim(iDim));
      end
    end
  else
    if VERBOSE, fprintf(' tcImg...');  end
    tcImg = sigload(Ses,ExpNo,'tcImg');
    tmpimg = tcImg.dat;
    pixdim = [3 tcImg.ds(1) tcImg.ds(2) tcImg.ds(3) 0 0 0 0];	% must be 8 elements
  end
  dim = [3 size(tmpimg,1) size(tmpimg,2) size(tmpimg,3) 0 0 0 0];	% must be 8 elements

  if strcmpi(DATA_TYPE,'uint8'),
    tmpimg = double(tmpimg)
    tmpimg = tmpimg / 32767 * 255;
    tmpimg = uint8(round(tmpimg));
  end
  
  
  % write .img/.hdr files.
  OUT_IMGFILE = fullfile(SAVE_DIR,sprintf('%s%s_%03d%s.img',PREFIX, Ses.name, ExpNo, POSTFIX));
  OUT_HDRFILE = fullfile(SAVE_DIR,sprintf('%s%s_%03d%s.hdr',PREFIX, Ses.name, ExpNo, POSTFIX));
  if VERBOSE, fprintf(' writing to %s/hdr...',OUT_IMGFILE);  end
  fid = fopen(OUT_IMGFILE,'wb');
  fwrite(fid, tmpimg, DATA_TYPE);
  fclose(fid);
  hdr = hdr_init('dim',dim,'datatype',DATA_TYPE,'pixdim',pixdim,'glmax',intmax(DATA_TYPE));
  hdr_write(OUT_HDRFILE,hdr);

  if SAVE_TEXT,
    sub_save_text(OUT_IMGFILE,WHICH_DATA,hdr);
  end
  
  if VERBOSE, fprintf(' done.\n');  end
  
  IMGFILES{iExp} = OUT_IMGFILE;	% keep for varargout.
  HDRFILES{iExp} = OUT_HDRFILE;	% keep for varargout.
end

catch,
  fprintf('%s: %s',mfilename,lasterr);
  try, fclose(fid); end
  keyboard
end
if VERBOSE, fprintf('%s %s END.\n',gettimestring,mfilename);  end

if nargout,
  varargout{1} = IMGFILES;
  if nargout > 1,
    varargout{2} = HDRFILES;
  end
end


return;



% ---------------------------------------------------------------
function sub_save_text(OUT_IMGFILE,WHICH_DATA,HDR)
% ---------------------------------------------------------------
[fp fr] = fileparts(OUT_IMGFILE);
txtfile = fullfile(fp,sprintf('%s.txt',fr));

fid = fopen(txtfile,'wt');

fprintf(fid,'date:     %s\n',datestr(now));
fprintf(fid,'program:  %s\n',mfilename);
fprintf(fid,'[input]\n');
fprintf(fid,'source:   %s\n',WHICH_DATA);
fprintf(fid,'[output]\n');
fprintf(fid,'dim:      [ %s ]\n',deblank(sprintf('%d ',HDR.dime.dim(2:4))));
fprintf(fid,'pixdim:   [ %s ] in mm\n',deblank(sprintf('%g ',HDR.dime.pixdim(2:4))));
fprintf(fid,'datatype: %d',HDR.dime.datatype);
switch HDR.dime.datatype
 case 2
  dtype =  'uint8';
 case 4
  dtype =  'int16';
 otherwise
  dtype =  'unknown';
end
fprintf(fid,'(%s)\n',dtype);
fprintf(fid,'[photoshop raw]\n');
fprintf(fid,'width:    %d\n',HDR.dime.dim(2));
fprintf(fid,'height:   %d(=%dx%d)\n',prod(HDR.dime.dim(3:4)),HDR.dime.dim(3),HDR.dime.dim(4));
fprintf(fid,'channels: 1\n');
fprintf(fid,'depth:    %s\n',dtype);
[str,maxsize,endian] = computer;
fprintf(fid,'endian:   %s\n',endian);
fprintf(fid,'header:   0\n');

fclose(fid);

return
