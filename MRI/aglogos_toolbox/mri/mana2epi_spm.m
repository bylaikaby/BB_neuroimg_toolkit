function varargout = mana2epi_spm(Ses,GrpExp,varargin)
%MANA2EPI_SPM - Coregister the given anatomy image to the EPI scan.
%  MANA2EPI_SPM(SESSION,GRPNAME,...) coregisters the given anatomy to the EPI scan.
%
%  In any case, results (conversion matrix) will be saved into *_coreg_ana2epi.mat.
%
%  Supported options are
%    'raw'        :  0|1, use photoshop-raw as anatomy
%    'export'     :  0|1, do export data as .hdr/img.
%    'coregister' :  0|1, do coregistration
%    'plot'       :  0|1, to plot a figure or not.
%    'twosteps'   : (default 0),  run spm_coreg() two times, first with 'ncc' cost-function.
%
%  Parameters can be controlled by the description file.
%    GRP.xxx.anap.mana2epi_spm.twosteps  = 0;
%    GRP.xxx.anap.mana2epi_spm.spm_coreg.cost_fun  = 'nmi';
%          cost_fun - cost function string:
%                      'mi'  - Mutual Information
%                      'nmi' - Normalised Mutual Information
%                      'ecc' - Entropy Correlation Coefficient
%                      'ncc' - Normalised Cross Correlation
%
%  EXAMPLE :
%    % coregister the atlas to the given session/group.
%    mana2epi_spm('e10aw1','spont');
%
%
%  VERSION :
%    0.90 27.02.12 YM  pre-release, modified from mana2brain.m
%    0.91 05.06.13 YM  save -v7.3.
%
%  See also anz_read anz_write spm_coreg

if nargin < 2,  eval(sprintf('help %s;',mfilename)); return;  end

if iscell(GrpExp),
  for N = 1:length(GrpExp),
    mana2epi_spm(Ses,GrpExp{N},varargin{:});
  end
  return
end


Ses = goto(Ses);
grp = getgrp(Ses,GrpExp);

if ismanganese(Ses,GrpExp),
  keyboard
  return
end

GrpName = grp.name;


% optional settings
USE_RAW       = 0;
DO_EXPORT     = 1;
DO_COREGISTER = 1;
DO_TWOSTEPS   = 0;
DO_PLOT       = 1;
DO_UPDATE_ANA = 1;

FLAGS_SPM_COREG = [];
anap = getanap(Ses,GrpName);
if isfield(anap,'mana2epi_spm'),
  x = anap.mana2epi_spm;
  if isfield(x,'use_raw'),
    USE_RAW = x.use_raw;
  end
  if isfield(x,'twosteps'),
    DO_TWOSTEPS = x.twosteps;
  end
  if isfield(x,'spm_coreg'),
    FLAGS_SPM_COREG = x.spm_coreg;
  end
  clear x;
end

for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'useraw' 'use_raw' 'raw' 'photoshop'}
    USE_RAW = varargin{N+1};
   case {'export'}
    DO_EXPORT     = varargin{N+1};
   case {'coregister','coreg'}
    DO_COREGISTER = varargin{N+1};
   case {'updateana' 'update'}
    DO_UPDATE_ANA = varargin{N+1};
   case {'twostep','twosteps'}
    DO_TWOSTEPS = varargin{N+1};
   case {'plot'}
    DO_PLOT       = varargin{N+1};
  end
end


% if needed, export the anatomy as ANALYZE format.
[ANAFILES EPIFILES GrpNames] = subImgExport(Ses,GrpExp,USE_RAW,DO_EXPORT,'ana2epi');

% flags for spm_coreg()
%          cost_fun - cost function string:
%                      'mi'  - Mutual Information
%                      'nmi' - Normalised Mutual Information
%                      'ecc' - Entropy Correlation Coefficient
%                      'ncc' - Normalised Cross Correlation
INFO.defflags.sep      = [2 1];
INFO.defflags.params   = [0 0 0  0 0 0];
%INFO.defflags.params   = [0 0 0  0 0 0  1 1 1];
INFO.defflags.cost_fun = 'nmi';
INFO.defflags.fwhm     = [2 2];
if ~isempty(FLAGS_SPM_COREG),
  fnames = {'sep' 'params' 'cost_fun' 'fwhm'};
  for N = 1:length(fnames),
    if isfield(FLAGS_SPM_COREG,fnames{N}),
      INFO.defflags.(fnames{N}) = FLAGS_SPM_COREG.(fnames{N});
    end
  end
end



if ischar(ANAFILES),  ANAFILES = { ANAFILES };  end
if ischar(EPIFILES),  EPIFILES = { EPIFILES };  end
for N = 1:length(ANAFILES),
  anafile = ANAFILES{N};
  epifile = EPIFILES{N};
  fprintf('%s %s %2d/%d: %s\n',datestr(now,'HH:MM:SS'),mfilename,...
          N,length(ANAFILES),anafile);
  
  if any(USE_RAW)
    [fp fr fe] = fileparts(anafile);
    rawfile = fullfile(fp,sprintf('%s.raw',fr));
    dstfile = fullfile(fp,sprintf('%s.img',fr));
    if exist(rawfile,'file')
      fprintf(' PHOTOSHOP %s.raw-->img.',fr);
      copyfile(rawfile,dstfile,'f');
      fprintf('\n');
    end
    
    [fp fr fe] = fileparts(epifile);
    rawfile = fullfile(fp,sprintf('%s.raw',fr));
    dstfile = fullfile(fp,sprintf('%s.img',fr));
    if exist(rawfile,'file')
      fprintf(' PHOTOSHOP %s.raw-->img.',fr);
      copyfile(rawfile,dstfile,'f');
      fprintf('\n');
    end
  end

  [fp fr] = fileparts(anafile);
  % coregister inplane anatomy to the reference
  matfile = fullfile(fp,sprintf('%s_coreg_ana2epi.mat',fr));
  if DO_COREGISTER,
    % do coregistration
    M = subDoCoregister(anafile,epifile,INFO,DO_TWOSTEPS);
    fprintf(' %s: saving conversion matrix ''M'' to ''%s''...',mfilename,matfile);
    save(matfile,'M');
    fprintf(' done.\n');
  elseif exist(matfile,'file'),
    load(matfile,'M');
  else
    M = [];
  end

  % note that this index is for the original anatomy (no permutete/flipdim).
  M.ind_in_ana = subGetCoordsInANA(anafile,epifile,INFO,M);
  M.pixdim_ana = M.vfpixdim;
  M.ind_in_ref = subGetCoordsInREF(anafile,epifile,INFO,M);
  M.pixdim_ref = M.vgpixdim;
  fprintf(' %s: saving coodinates ''M.ind_in_ana'' to ''%s''...',mfilename,matfile);
  save(matfile,'M');
  fprintf(' done.\n');
  
  
  if DO_UPDATE_ANA
    fprintf(' %s: updating anatomy...',mfilename,matfile);
    tmpgrp = getgrp(Ses,GrpNames{N});
    ananame = tmpgrp.ana{1};
    anaindx = tmpgrp.ana{2};

    if sesversion(Ses) >= 2,
      ANA = load(sigfilename(Ses,anaindx,ananame),ananame);
      ANA = ANA.(anafile{N});
    else
      ANA = load(sprintf('%s.mat',ananame),ananame);
      ANA = ANA.(ananame){anaindx};
    end
    
    ANA = sub_convert(ANA,M,0);
    
    Ses.ascan.(ananame){end+1} = {};
    newindx = length(Ses.ascan.(ananame));
    if sesversion(Ses) >= 2,
      sigsave(Ses,newindx,ananame,ANA);
    else
      ANA2 = load(sprintf('%s.mat',ananame),ananame);
      ANA2 = ANA2.(ananame);
      ANA2{newindx} = ANA;
      eval([ananame ' = ANA2;']);
      save(sprintf('%s.mat',ananame),ananame,'-append','-v7.3');
    end
    
    fprintf('\n');
    fprintf(' EDIT %s.m ===============================\n',Ses.name);
    fprintf('   GRP.(%s).ana = { ''%s'' %d [] };\n',tmpgrp.name,ananame,newindx);
  end    

  fprintf('%s %s: DONE.\n',datestr(now,'HH:MM:SS'),mfilename);
end




return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function v = subIsAnzfile(x)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if iscell(x),  x = x{1};  end
v = 0;
if ~ischar(x),  return;  end
[fp fr fe] = fileparts(x);
if any(strcmpi(fe,{'.hdr','.img'})),  v = 1;  end

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ANAFILES EPIFILES GrpNames] = subImgExport(Ses,Grp,USE_RAW,DO_EXPORT,DIR_NAME)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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


fprintf('%s %s: exporting ana/epi (%d)...\n',...
        datestr(now,'HH:MM:SS'),mfilename,length(Grp));
for N = 1:length(Grp),
  tmpgrp = getgrp(Ses,Grp{N});
  GrpNames{end+1} = tmpgrp.name;
  
  ananame{end+1} = sprintf('%s{%d}',tmpgrp.ana{1},tmpgrp.ana{2});
  anafile{end+1} = tmpgrp.ana{1};
  anaindx(end+1) = tmpgrp.ana{2};
  
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
  
  anzfile = fullfile(pwd,DIR_NAME,sprintf('%s_%s_%03d.img',Ses.name,anafile{N},anaindx(N)));
  imgdim = [4 size(ANA.dat,1) size(ANA.dat,2) size(ANA.dat,3) 1];
  pixdim = [3 ANA.ds(1) ANA.ds(2) ANA.ds(3)];
  fprintf('[%s]', deblank(sprintf('%g ',pixdim(2:4))));
  
  if any(DO_EXPORT),
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
  fprintf(' done.\n');
  ANAFILES{end+1} = anzfile;
  
  
  % EPI ==========================================================
  if isnumeric(Grp{N})
    ExpNo = Grp{N}(1);
  else
    tmpgrp = getgrp(Ses,Grp{N});
    ExpNo = tmpgrp.exps(1);
  end
  fprintf(' epi: read exp=%d...',ExpNo);
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
  %EPI.dat = EPI.dat * single(intmax('int16'));
  EPI.dat = EPI.dat * 32000;
  

  anzfile = fullfile(pwd,DIR_NAME,sprintf('%s_epi_%03d.img',Ses.name,ExpNo));
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

  if any(DO_EXPORT),
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
  fprintf(' done.\n');
  EPIFILES{end+1} = anzfile;
end


return


% ============================================================================
% Do coregistration
function M = subDoCoregister(anafile,reffile,INFO,DO_TWOSTEPS)
% ============================================================================

% checks required files
if ~exist(reffile,'file'),
  error('\nERROR %s: reference EPI not found, ''%s''\n',mfilename,reffile);
end
if ~exist(anafile,'file'),
  error('\nERROR %s: exp-anatomy not found, ''%s''\n',mfilename,anafile);
end

% if spm_coreg_ui() called, it creates conversion matrix automatically.
% as result, cause the trouble when calling spm_vol()
[fp fr] = fileparts(anafile);
matfile = fullfile(fp,sprintf('%s.mat',fr));
if exist(matfile,'file'),  delete(matfile); end
clear fp fr fe matfile;

fprintf(' ref: %s\n',reffile);
fprintf(' exp: %s\n',anafile);

M = mcoreg_spm_coreg(reffile,anafile,INFO.defflags,'twosteps',DO_TWOSTEPS);


return



% ============================================================================
% get coordinates: from anatomy to reference
function IND_to_VG = subGetCoordsInANA(anafile,reffile,INFO,M)
% ============================================================================
% initialize spm package, before any use of spm_xxx functions
if any(strcmpi(spm('ver'),{'SPM2','SPM5'})),
  spm_defaults;
else
  spm_get_defaults;
end


hdr = hdr_read(anafile);

% get coords of EXP-ANATOMY
xyzres = hdr.dime.pixdim(2:4);
x = 1:hdr.dime.dim(2);
y = 1:hdr.dime.dim(3);
z = 1:hdr.dime.dim(4);

% get EXP-coords in voxel
[R C P] = ndgrid(x,y,z);
RCP = zeros(4,length(R(:)));  % allocate memory first to avoid memory problem
RCP(1,:) = R(:);  clear R;
RCP(2,:) = C(:);  clear C;
RCP(3,:) = P(:);  clear P;
RCP(4,:) = 1;

% convert EXP-coords as mm
XYZ = M.vfmat*RCP;       % in mm
clear RCP;

% convert the coords into REFERENCE space
XYZ(4,:) = 1;
XYZ = M.mat*XYZ;         % in mm

% convert the coords into  space
VG = spm_vol(reffile);
XYZ(4,:) = 1;
RCP = inv(VG.mat)*XYZ;   % in voxel
RCP = round(RCP(1:3,:));

% mark outside as NaN
RCP(RCP(:) < 1) = NaN;
RCP(1,RCP(1,:) > VG.dim(1)) = NaN;
RCP(2,RCP(2,:) > VG.dim(2)) = NaN;
RCP(3,RCP(3,:) > VG.dim(3)) = NaN;
tmpidx = isnan(RCP(1,:).*RCP(2,:).*RCP(3,:));
RCP(:,tmpidx) = NaN;

tmpidx = ~tmpidx;
IND_to_VG = NaN(1,size(RCP,2));
IND_to_VG(tmpidx) = sub2ind(VG.dim,RCP(1,tmpidx),RCP(2,tmpidx),RCP(3,tmpidx));


IND_to_VG = reshape(IND_to_VG,hdr.dime.dim(2:4));


return


% ============================================================================
% get coordinates : from reference to anatomy
function IND_to_VF = subGetCoordsInREF(anafile,reffile,INFO,M)
% ============================================================================
% initialize spm package, before any use of spm_xxx functions
if any(strcmpi(spm('ver'),{'SPM2','SPM5'})),
  spm_defaults;
else
  spm_get_defaults;
end


% get coords of REF-ANATOMY
x = 1:M.vgdim(1);
y = 1:M.vgdim(2);
z = 1:M.vgdim(3);

% get REF-coords in voxel
[R C P] = ndgrid(x,y,z);
RCP = zeros(4,length(R(:)));  % allocate memory first to avoid memory problem
RCP(1,:) = R(:);  clear R;
RCP(2,:) = C(:);  clear C;
RCP(3,:) = P(:);  clear P;
RCP(4,:) = 1;

% convert REF-coords into EXP-coords
X = M.vfmat\spm_matrix(M.x(:)')*M.vgmat;
RCP = X*RCP;
RCP = round(RCP(1:3,:));

% mark outside as NaN
RCP(RCP(:) < 1) = NaN;
RCP(1,RCP(1,:) > M.vfdim(1)) = NaN;
RCP(2,RCP(2,:) > M.vfdim(2)) = NaN;
RCP(3,RCP(3,:) > M.vfdim(3)) = NaN;
tmpidx = isnan(RCP(1,:).*RCP(2,:).*RCP(3,:));
RCP(:,tmpidx) = NaN;

tmpidx = ~tmpidx;
IND_to_VF = NaN(1,size(RCP,2));
IND_to_VF(tmpidx) = sub2ind(M.vfdim,RCP(1,tmpidx),RCP(2,tmpidx),RCP(3,tmpidx));

IND_to_VF = reshape(IND_to_VF,M.vgdim);

return




% ==================================================================================
function ANA = sub_convert(ANA,M,VERBOSE)


newdat = zeros(size(ANA.dat),class(ANA.dat));

tmpidx = find(~isnan(M.ind_in_ref(:)));
newdat(tmpidx) = ANA.dat(M.ind_in_ref(tmpidx));
%newdat(M.ind_in_ref(tmpidx)) = ANA.dat(tmpidx);

ANA.dat = newdat;

return



% ==================================================================================



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
