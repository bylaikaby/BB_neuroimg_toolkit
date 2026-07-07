function varargout = mana2epi(Ses,GrpExp,CmdStr,varargin)
%MANA2EPI - Register anatomy to the EPI volume.
%  MANA2EPI(Ses,GrpName,CmdStr,...) registers anatomy to the EPI volume.
%
%  EXAMPLE (spm) :
%    mana2epi('E10aW1','spont','SPM','raw',1)
%
%  EXAMPLE (manual reg) :
%    mana2epi('E10aW1','spont','Export')    % export mat-data as analyze format
%    mana2epi('E10aW1','spont','GUI')       % GUI for registration
%    mana2epi('E10aW1','spont','Update')    % Update the anatomy with the registered one.
%
%  NOTE :
%    'Update' will add new anatomy volume to the existing anatomy data.
%    GRP.ana should be the original one in the beginning and modify it after 'Update' done.
%    To run 'Update' again, get GRP.ana back to the original value.
%
%  VERSION :
%    0.90 29.02.12 YM  pre-release
%    0.91 02.10.12 YM  accepts slice difference when 'update'.
%    0.92 06.11.13 YM  asks for the command if not given.
%    0.93 26.08.14 YM  supports 'NEW_ANA_INDEX'.
%    0.94 14.07.16 YM  checks GRPP.ana for editting.
%
%  See also mana2epi_spm mreg2d_gui mana2brain matlas2roi mroi2roi_coreg mroi2roi_shift

if nargin < 2,  eval(['help ' mfilename]); return;  end

if ~isimaging(Ses,GrpExp),
  fprintf('%s: not imaging exp/grp.\n',mfilename);
  return;
end

if nargin > 2 && strcmpi(CmdStr,'spm')
  mana2epi_spm(Ses,GrpExp,varargin{:});
  return
end

if nargin < 3,
  c = input('mana2epi Q: Which command?  [eXport|Gui|Update]: ','s');
  switch lower(c)
   case {'export' 'x'}
    CmdStr = 'export';
   case {'gui' 'g'}
    CmdStr = 'gui';
   case {'update' 'u'}
    CmdStr = 'update';
   otherwise
    return
  end
end



USE_RAW = 0;
SUB_DIR = 'ana2epi';
NEW_ANA_INDEX = [];
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'raw' 'useraw' 'use_raw'}
    USE_RAW = varargin{N+1};
   case {'dir' 'subdir' 'sub_dir'}
    SUB_DIR = varargin{N+1};
   case {'newanaindex' 'new_ana_index'}
    NEW_ANA_INDEX = varargin{N+1};
  end
end


Ses = goto(Ses);
grp = getgrp(Ses,GrpExp);

switch lower(CmdStr),
 case {'export'}
  % export mat-data as analyze format.
  DO_EXPORT = 1;
  [ANAFILES EPIFILES GrpNames] = subImgExport(Ses,GrpExp,USE_RAW,DO_EXPORT,SUB_DIR);
  
 case {'gui' 'coreg' 'coregister' 'register'}
  % invoke GUI for registration.
  DO_EXPORT = 0;
  [ANAFILES EPIFILES GrpNames] = subImgExport(Ses,GrpExp,USE_RAW,DO_EXPORT,SUB_DIR);
  fprintf(' ref: %s\n',EPIFILES{1});
  fprintf(' src: %s\n',ANAFILES{1});
  mreg2d_gui(EPIFILES{1},ANAFILES{1});
  
 case {'update' 'updateana' 'update_ana'}
  % update the anatomy with the registered one.
  sub_update_anatomy(Ses,GrpExp,SUB_DIR,NEW_ANA_INDEX);
  
end


return






% ============================================================================
function [ANAFILES EPIFILES GrpNames] = subImgExport(Ses,Grp,USE_RAW,DO_EXPORT,DIR_NAME)
% ============================================================================
Ses = goto(Ses);
if ~exist('Grp','var'),
  Grp = getgrp(Ses);
end
if ~iscell(Grp),  Grp = { Grp };  end

if isempty(DIR_NAME),  DIR_NAME = 'ana2epi';  end

if ~exist(fullfile(pwd, DIR_NAME),'dir'),
  mkdir(pwd, DIR_NAME);
end

ANAFILES = {};
EPIFILES = {};
GrpNames = {};

ananame = {};
anafile = {};
anaindx = [];

EPI_UPSAMPLE = 1;

if any(DO_EXPORT)
  fprintf('%s %s: exporting ana/epi (%d)...\n',...
          datestr(now,'HH:MM:SS'),mfilename,length(Grp));
end
for N = 1:length(Grp),
  tmpgrp = getgrp(Ses,Grp{N});
  GrpNames{end+1} = tmpgrp.name;
  
  ananame{N} = sprintf('%s{%d}',tmpgrp.ana{1},tmpgrp.ana{2});
  anafile{N} = tmpgrp.ana{1};
  anaindx(N) = tmpgrp.ana{2};
  if anaindx(N) > length(Ses.ascan.(anafile{N})),
    if length(Ses.ascan.(anafile{N})) == 1,
      anaindx(N) = 1;
    end
  end
  
  
  anzfile = fullfile(pwd,DIR_NAME,sprintf('%s_%s_%03d.img',Ses.name,anafile{N},anaindx(N)));
  if any(DO_EXPORT),
    fprintf(' %s: read ana...',ananame{N});
    if sesversion(Ses) >= 2,
      ANA = load(sigfilename(Ses,anaindx(N),anafile{N}),anafile{N});
      ANA = ANA.(anafile{N});
    else
      ANA = load(sprintf('%s.mat',anafile{N}),anafile{N});
      ANA = ANA.(anafile{N}){anaindx(N)};
    end
  
    % scale to 0-32767 (int16+)
    fprintf(' scaling(int16+)...');
    ANA.dat = double(ANA.dat);
    ANA.dat(isnan(ANA.dat)) = 0;
    minv = min(ANA.dat(:));
    maxv = max(ANA.dat(:));
    ANA.dat = (ANA.dat - minv) / (maxv - minv);
    %ANA.dat = ANA.dat * double(intmax('int16'));
    ANA.dat = ANA.dat * 32000;
  
    imgdim = [4 size(ANA.dat,1) size(ANA.dat,2) size(ANA.dat,3) 1];
    pixdim = [3 ANA.ds(1) ANA.ds(2) ANA.ds(3)];
    fprintf('[%s]', deblank(sprintf('%g ',pixdim(2:4))));
  
    %fprintf('-->[%s]', deblank(sprintf('%g ',pixdim(2:4))));
    fprintf(' saving to ''%s''...',anzfile);
    hdr = hdr_init('dim',imgdim,'pixdim',pixdim,...
                   'datatype','int16','glmax',intmax('int16'),...
                   'descrip',sprintf('%s %s',Ses.name,ananame{N}));
    anz_write(anzfile,hdr,int16(round(ANA.dat)));
    subWriteInfo(anzfile,hdr,ANA.dat);
  end
  %clear ANA;
  if any(USE_RAW)
    [fp fr fe] = fileparts(anzfile);
    rawfile = fullfile(fp,sprintf('%s.raw',fr));
    dstfile = fullfile(fp,sprintf('%s.img',fr));
    if exist(rawfile,'file')
      fprintf(' PHOTOSHOP %s.raw-->img.',fr);
      copyfile(rawfile,dstfile,'f');
    end
  end
  if any(DO_EXPORT)
    fprintf(' done.\n');
  end
  ANAFILES{end+1} = anzfile;
  
  
  % EPI ==========================================================
  if isnumeric(Grp{N})
    ExpNo = Grp{N}(1);
  else
    tmpgrp = getgrp(Ses,Grp{N});
    ExpNo = tmpgrp.exps(1);
  end

  anzfile = fullfile(pwd,DIR_NAME,sprintf('%s_epi_%03d.img',Ses.name,ExpNo));
  if any(DO_EXPORT),
    fprintf(' epi: read tcImg(exp=%d)...',ExpNo);
    EPI = load(sigfilename(Ses,ExpNo,'tcImg'),'tcImg');
    EPI = EPI.tcImg;
    EPI.dat = nanmean(EPI.dat,4);

    % scale to 0-32767 (int16+)
    fprintf(' scaling(int16+)...');
    EPI.dat = double(EPI.dat);
    EPI.dat(isnan(EPI.dat)) = 0;
    minv = min(EPI.dat(:));
    maxv = max(EPI.dat(:));
    EPI.dat = (EPI.dat - minv) / (maxv - minv);
    %EPI.dat = EPI.dat * double(intmax('int16'));
    EPI.dat = EPI.dat * 32000;

    imgdim = [4 size(EPI.dat,1) size(EPI.dat,2) size(EPI.dat,3) 1];
    pixdim = [3 EPI.ds(1) EPI.ds(2) EPI.ds(3)];
    fprintf('[%s]', deblank(sprintf('%g ',pixdim(2:4))));

    if any(EPI_UPSAMPLE),
      anasz  = size(ANA.dat);
      newdat = zeros(anasz(1),anasz(2),size(EPI.dat,3));
      for S = 1:size(EPI.dat,3),
        newdat(:,:,S) = imresize(EPI.dat(:,:,S),[anasz(1) anasz(2)]);
      end
      EPI.dat = newdat;
      EPI.ds(1:2) = ANA.ds(1:2);
      imgdim = [4 size(EPI.dat,1) size(EPI.dat,2) size(EPI.dat,3) 1];
      pixdim = [3 EPI.ds(1) EPI.ds(2) EPI.ds(3)];
      clear newdat;
      fprintf('-->[%s]', deblank(sprintf('%g ',pixdim(2:4))));
    end
    
    fprintf(' saving to ''%s''...',anzfile);
    hdr = hdr_init('dim',imgdim,'pixdim',pixdim,...
                   'datatype','int16','glmax',intmax('int16'),...
                   'descrip',sprintf('%s %s',Ses.name,ananame{N}));
    anz_write(anzfile,hdr,int16(round(EPI.dat)));
    subWriteInfo(anzfile,hdr,EPI.dat);
  end
  clear ANA;
  if any(USE_RAW)
    [fp fr fe] = fileparts(anzfile);
    rawfile = fullfile(fp,sprintf('%s.raw',fr));
    dstfile = fullfile(fp,sprintf('%s.img',fr));
    if exist(rawfile,'file')
      fprintf(' PHOTOSHOP %s.raw-->img.',fr);
      copyfile(rawfile,dstfile,'f');
    end
  end
  
  if any(DO_EXPORT),
    fprintf(' done.\n');
  end
  EPIFILES{end+1} = anzfile;
end


return

% ==================================================================================
function subWriteInfo(ANZFILE,HDR,IMG)
% ==================================================================================

[fp froot] = fileparts(ANZFILE);


TXTFILE = fullfile(fp,sprintf('%s.txt',froot));
fid = fopen(TXTFILE,'wt');
fprintf(fid,'date:     %s\n',datestr(now));
fprintf(fid,'program:  %s\n',mfilename);

fprintf(fid,'[output]\n');
fprintf(fid,'dim:      [');  fprintf(fid,' %d',HDR.dime.dim(2:4));  fprintf(fid,' ]\n');
fprintf(fid,'pixdim:   [');  fprintf(fid,' %g',HDR.dime.pixdim(2:4));  fprintf(fid,' ] in mm\n');
fprintf(fid,'datatype: %d',HDR.dime.datatype);
switch HDR.dime.datatype
 case 1
  dtype =  'binary';
 case 2
  dtype =  'char';
 case 4
  dtype =  'int16';
 case 8
  dtype =  'int32';
 case 16
  dtype =  'float';
 case 32
  dtype =  'complex';
 case 64
  dtype =  'double';
 case 128
  dtype =  'rgb';
 otherwise
  dtype =  'unknown';
end
fprintf(fid,'(%s)\n',dtype);


fprintf(fid,'[photoshop raw]\n');
[str,maxsize,endian] = computer;
fprintf(fid,'width:  %d\n',HDR.dime.dim(2));
fprintf(fid,'height: %d\n',HDR.dime.dim(3)*HDR.dime.dim(4));
fprintf(fid,'depth:  %s\n',dtype);
if strcmpi(endian,'B'),
fprintf(fid,'byte-order: Mac\n');
else
fprintf(fid,'byte-order: IBM\n');
end
fprintf(fid,'header: 0\n');


fclose(fid);

return



% ============================================================================
function sub_update_anatomy(Ses,GrpExp,SUB_DIR,NEW_ANA_INDEX)
% ============================================================================

Ses = goto(Ses);
grp = getgrp(Ses,GrpExp);

if isnumeric(GrpExp),
  ExpNo = GrpExp(1);
else
  ExpNo = grp.exps(1);
end

anaindx = grp.ana{2};
if anaindx > length(Ses.ascan.(grp.ana{1})),
  if length(Ses.ascan.(grp.ana{1})) == 1,
    anaindx = 1;
  end
end


fref = sprintf('%s_epi_%03d',Ses.name,ExpNo);
freg = sprintf('%s_%s_%03d',Ses.name,grp.ana{1},anaindx);

matfile = fullfile(SUB_DIR,sprintf('%s_ref(%s)_mreg2d_volume.mat',freg,fref));

TVOL = load(matfile,'TVOL');
TVOL = TVOL.TVOL;


fprintf(' reg: %s\n',matfile);

ananame = grp.ana{1};
anaindx = grp.ana{2};

fprintf(' ana: %s{%d} loading...',ananame,anaindx);
if sesversion(Ses) >= 2,
  ANA = load(sigfilename(Ses,anaindx,ananame),ananame);
  ANA = ANA.(ananame);
else
  ANA = load(sprintf('%s.mat',ananame),ananame);
  ANA = ANA.(ananame){anaindx};
end

if numel(ANA.dat) ~= numel(TVOL.dat),
  epifile = fullfile(SUB_DIR,sprintf('%s_epi_%03d.img',Ses.name,ExpNo));
  hdr = hdr_read(epifile);
  if size(TVOL.dat,3) == hdr.dime.dim(4),
    % selected slices, just update the slice thickness.
    ANA.ds(3) = hdr.dime.pixdim(4);
  else
    error('\n ERROR %s:  not the same size,  ANA.dat=[%s] TVOL.dat=[%s]',...
          deblank(sprintf('%d ',size(ANA.dat))),...
          deblank(sprintf('%d ',size(TVOL.dat))));
  end
end

    
ANA.dat = TVOL.dat;

fprintf(' saving...');
if any(NEW_ANA_INDEX) && NEW_ANA_INDEX > length(Ses.ascan.(ananame)),
  newindx = NEW_ANA_INDEX;
  Ses.ascan.(ananame){newindx} = {};
else
  Ses.ascan.(ananame){end+1} = {};
  newindx = length(Ses.ascan.(ananame));
end


if sesversion(Ses) >= 2,
  sigsave(Ses,newindx,ananame,ANA);
else
  ANA2 = load(sprintf('%s.mat',ananame),ananame);
  ANA2 = ANA2.(ananame);
  ANA2{newindx} = ANA;
  eval([ananame ' = ANA2;']);
  save(sprintf('%s.mat',ananame),ananame,'-append');
end
fprintf(' done.\n');

fprintf('\n');
fprintf(' EDIT %s.m ===============================\n',Ses.name);
if any(IS_GRPP_ANA(Ses,grp)),
  fprintf('   GRPP.ana = { ''%s'' %d [] };\n',ananame,newindx);
else
  fprintf('   GRP.%s.ana = { ''%s'' %d [] };\n',grp.name,ananame,newindx);
end

return



function iGRPP = IS_GRPP_ANA(Ses,grp)
iGRPP = 0;
SessionFile = which(Ses.name);
[pathstr,SessionName] = fileparts(SessionFile);
eval(SessionName);
if isfield(GRPP,'ana') && isequal(GRPP.ana, grp.ana),
  iGRPP = 1;
end
return

