function varargout = mana2brain(varargin)
%MANA2BRAIN - Coregister the given anatomy image to the template brain.
%  MANA2BRAIN(ANZFILE,...) coregisters ANZFILE to the template brain.
%  Note that voxel resolution of rat-template is x10 bigger than the real and make
%  sure that the given ANALIZE file has also x10 voxel size.
%
%  MANA2BRAIN(SESSION,GRPNAME,...) coregisters the given anatomy to the template brain.
%
%  In any case, results (conversion matrix) will be saved into *_coreg_brain.mat.
%
%  Supported options are
%    'brain'      :  template brain, see mbrain_defs().
%    'epi'        :  0|1, use EPI data as anatomy
%    'raw'        :  0|1, use photoshop-raw as anatomy
%    'export'     :  0|1, do export data as .hdr/img.
%    'coregister' :  0|1, do coregistration
%    'permute'    :  permutation vector for the input image
%    'flipdim'    :  flipping dimension for the input image
%    'plot'       :  0|1, to plot a figure or not.
%    'twosteps'   : (default 0),  run spm_coreg() two times, first with 'ncc' cost-function.
%
%  Parameters can be controlled by the description file.
%    GRP.xxx.anap.mana2brain.brain     = 'CoCoMac';
%    GRP.xxx.anap.mana2brain.use_epi   = 0;
%    GRP.xxx.anap.mana2brain.permute   = [1 3 2];
%    GRP.xxx.anap.mana2brain.flipdim   = [3];
%    GRP.xxx.anap.mana2brain.minvoxels = 10;
%    GRP.xxx.anap.mana2brain.twosteps  = 0;
%    GRP.xxx.anap.mana2brain.spm_coreg.cost_fun  = 'nmi';
%          cost_fun - cost function string:
%                      'mi'  - Mutual Information
%                      'nmi' - Normalised Mutual Information
%                      'ecc' - Entropy Correlation Coefficient
%                      'ncc' - Normalised Cross Correlation
%
%  TIPS:
%   - To get better results, the input image should be in the similar
%     orientation like the reference-brain.  Options (permute/flipdim) will does
%     dimensional manipulation to the input image.
%   - For horizontal slices, use permute:[1 3 2], flipdim:[3]
%   - For coronal slice,     use permute:[],      flipdim:[2]
%
%  EXAMPLE :
%    % coregister the atlas to the given session/group.
%    mana2brain('rat5n1','pinch1','flipdim',[2]);
%
%  NOTE :
%    Voxel size of rat-template is 10 time of the real size.
%
%  VERSION :
%    0.90 03.10.11 YM  pre-release, modified from mratatlas2ana.m
%    0.91 10.10.11 YM  bug fix, improved speed.
%    0.92 12.01.12 YM  supports 'epi' as option.
%    0.93 15.01.12 YM  supports 'use_raw' for photoshop raw.
%    0.94 17.04.13 YM  supports 'resolution' of the reference brain.
%    0.95 05.07.13 YM  supports 'mana2brain.brain'.
%    0.96 11.10.19 YM  clean up.
%
%  See also mbrain_defs anz_read anz_write spm_coreg mcoreg_spm_coreg
%           mroits2brain mana2brain_roi

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end

if subIsAnzfile(varargin{1})
  % called like mana2brain(anzfile,...)
  IMGFILES = varargin{1};
  iOPT = 2;
  IS_RAT = 0;
else
  % called like mana2brain(Ses,Grp,...)
  if nargin < 2
    fprintf('usage:  %s(Session,GrpName,...)\n',mfilename);
    return;
  end
  if iscell(varargin{2})
    for N = 1:length(varargin{2})
      mana2brain(varargin{1},varargin{2}{N},varargin{3:end});
    end
    return
  end
  if ismanganese(varargin{1},varargin{2})
    keyboard
    return
  end
  iOPT = 3;
  Ses = goto(varargin{1});
  grp = getgrp(Ses,varargin{2});
  GrpName = grp.name;
  IS_RAT = 0;
  if strncmpi(Ses.name,'rat',3),  IS_RAT = 1;  end
end

% optional settings
USE_EPI       = 0;
USE_RAW       = 0;
DO_EXPORT     = 1;
DO_PERMUTE    = [];
DO_FLIPDIM    = [];
DO_COREGISTER = 1;
DO_TWOSTEPS   = 0;
DO_PLOT       = 1;
BRAIN_RES     = 'low';


FLAGS_SPM_COREG = [];
BRAIN_TYPE      = '';
if exist('Ses','var') && exist('GrpName','var')
  anap = getanap(Ses,GrpName);
  if isfield(anap,'mana2brain')
    x = anap.mana2brain;
    if isfield(x,'use_epi')
      USE_EPI = x.use_epi;
    end
    if isfield(x,'use_raw')
      USE_RAW = x.use_raw;
    end
    if isfield(x,'permute')
      DO_PERMUTE = x.permute;
    end
    if isfield(x,'flipdim')
      DO_FLIPDIM = x.flipdim;
    end
    if isfield(x,'twosteps')
      DO_TWOSTEPS = x.twosteps;
    end
    if isfield(x,'spm_coreg')
      FLAGS_SPM_COREG = x.spm_coreg;
    end
    if isfield(x,'brain')
      BRAIN_TYPE = x.brain;
    end
    if isfield(x,'resolution')
      BRAIN_RES = x.resolution;
    end
    clear x;
  end
end

for N = iOPT:2:length(varargin)
  switch lower(varargin{N})
   case {'epi', 'use_epi', 'useepi'}
    USE_EPI = varargin{N+1};
   case {'useraw' 'use_raw' 'raw' 'photoshop'}
    USE_RAW = varargin{N+1};
   case {'export'}
    DO_EXPORT     = varargin{N+1};
   case {'coregister','coreg'}
    DO_COREGISTER = varargin{N+1};
   case {'twostep','twosteps'}
    DO_TWOSTEPS = varargin{N+1};
   case {'permute'}
    DO_PERMUTE    = varargin{N+1};
   case {'flipdim'}
    DO_FLIPDIM    = varargin{N+1};
   case {'brain'}
    BRAIN_TYPE    = varargin{N+1};
   case {'plot'}
    DO_PLOT       = varargin{N+1};
   case {'rat'}
    IS_RAT        = any(varargin{N+1});
   case {'res' 'resolution'}
    BRAIN_RES     = varargin{N+1};
  end
end
DO_PERMUTE = DO_PERMUTE(:)';
DO_FLIPDIM = DO_FLIPDIM(:)';


% if needed, export the anatomy as ANALYZE format.
if exist('Ses','var') && exist('GrpName','var')
  IMGFILES = subAnaExport(Ses,GrpName,USE_EPI,USE_RAW,DO_EXPORT,'brain',IS_RAT);
end

if ~any(BRAIN_TYPE)
  if any(IS_RAT)
    BRAIN_TYPE = 'rat';
  else
    BRAIN_TYPE = 'rhesus';
  end
end
INFO = mbrain_defs(BRAIN_TYPE,'resolution',BRAIN_RES);
INFO.permute = DO_PERMUTE;
INFO.flipdim = DO_FLIPDIM;


% flags for spm_coreg()
%          cost_fun - cost function string:
%                      'mi'  - Mutual Information
%                      'nmi' - Normalised Mutual Information
%                      'ecc' - Entropy Correlation Coefficient
%                      'ncc' - Normalised Cross Correlation
INFO.defflags.sep      = [4 2];
INFO.defflags.params   = [0 0 0  0 0 0];
INFO.defflags.cost_fun = 'nmi';
INFO.defflags.fwhm     = [7 7];
if ~isempty(FLAGS_SPM_COREG)
  fnames = {'sep' 'params' 'cost_fun' 'fwhm'};
  for N = 1:length(fnames)
    if isfield(FLAGS_SPM_COREG,fnames{N})
      INFO.defflags.(fnames{N}) = FLAGS_SPM_COREG.(fnames{N});
    end
  end
end



fprintf('\nATLAS : %s', INFO.type);
switch lower(INFO.type)
 case {'gskrat97'}
  fprintf('\n');
  fprintf('ACCEPT LICENCE AGREEMENT OF RAT-ATLAS(AJSchwartz,GlaxoSmithKline).\n');
  fprintf('For detail, see ratBrain_copyright_licence_*.doc.\n');
 case {'rat16t'}
  fprintf('\n');
  fprintf('ACCEPT LICENCE AGREEMENT OF RAT-ATLAS(AGLOGO/YMurayama/GSKrat97).\n');
  fprintf('For detail, see *.doc.\n');
 case {'rataf1' 'rataa1'}
  fprintf('\n');
 case {'rat2013'}
  fprintf('\n');
  fprintf('ACCEPT LICENCE AGREEMENT OF RAT-ATLAS(AGLOGO/HEvrard).\n');
  fprintf('For detail, see *.doc.\n');
 case {'cocomac'}
  fprintf('\n');
  fprintf('ACCEPT LICENCE AGREEMENT OF RHESUS-ATLAS(CoCoMac/Paxinos(atlas), Frey(MRI-template)).\n');
  fprintf('For detail, see http://cocomac.org/,\n');
  fprintf('                http://www.bic.mni.mcgill.ca/ServicesAtlases/Rhesus,\n');
  fprintf('SIGNIFICANT MODIFICATION AND COMPILATION BY AGLOGO: YMurayama, MBesserve, HEvrard.\n');
 case {'henry3d'}
  fprintf('\n');
  fprintf('ACCEPT LICENCE AGREEMENT OF RHESUS-ATLAS(Henry Evrard, MPI/CIN).\n');
  fprintf('For detail, see xxxx/,\n');
  fprintf('SIGNIFICANT MODIFICATION AND COMPILATION BY AGLOGO/CIN: HEvrard.\n');
 otherwise
  error('\n ERROR %s:  not supported yet, atlas=%s\n',mfilename,INFO.type);
end
fprintf('\n');
fprintf('ACCEPT LICENCE AGREEMENT OF %s.\n',spm('ver'));
fprintf('For detail, see http://www.fil.ion.ucl.ac.uk/spm\n');
fprintf('\n');
pause(3);  % 3sec pause



if ischar(IMGFILES),  IMGFILES = { IMGFILES };  end
for N = 1:length(IMGFILES)
  expfile= IMGFILES{N};
  fprintf('%s %s %2d/%d: %s\n',datestr(now,'HH:MM:SS'),mfilename,...
          N,length(IMGFILES),expfile);
  
  if any(DO_PERMUTE) || any(DO_FLIPDIM)
    [img, hdr] = anz_read(expfile);
    if any(DO_PERMUTE)
      fprintf(' permute[%s].',deblank(sprintf('%d ',DO_PERMUTE)));
      img = permute(img,DO_PERMUTE);
      hdr.dime.dim(2:4)    = hdr.dime.dim(DO_PERMUTE+1);
      hdr.dime.pixdim(2:4) = hdr.dime.pixdim(DO_PERMUTE+1);
    end
    if any(DO_FLIPDIM)
      fprintf(' flipdim[%s].',deblank(sprintf('%d ',DO_FLIPDIM)));
      for K=1:length(DO_FLIPDIM)
        img = flipdim(img,DO_FLIPDIM(K));
      end
    end
    [fp, fr, fe] = fileparts(expfile);
    expfile = fullfile(fp,sprintf('%s_mod%s',fr,fe));
    if any(DO_EXPORT)
      fprintf(' writing ''%s''...',expfile);
      anz_write(expfile,hdr,img);
      subWriteInfo(expfile,hdr,img);
    end
    fprintf(' done.\n');
  end
  
  if any(USE_RAW)
    [fp, fr, fe] = fileparts(expfile);
    rawfile = fullfile(fp,sprintf('%s.raw',fr));
    dstfile = fullfile(fp,sprintf('%s.img',fr));
    if exist(rawfile,'file')
      fprintf(' PHOTOSHOP %s.raw-->img.',fr);
      copyfile(rawfile,dstfile,'f');
      fprintf('\n');
    end
  end

  if DO_PLOT
    hFig = subPlotAna([],INFO,expfile);
  end
  
  [fp, fr] = fileparts(expfile);
  % coregister inplane anatomy to the reference
  matfile = fullfile(fp,sprintf('%s_coreg_brain.mat',fr));
  if DO_COREGISTER
    % do coregistration
    M = subDoCoregister(expfile,INFO,DO_TWOSTEPS);
    if any(BRAIN_TYPE)
      M.brain = BRAIN_TYPE;
    end
    fprintf(' %s: saving conversion matrix ''M'' to ''%s''...',mfilename,matfile);
    save(matfile,'M');
    fprintf(' done.\n');
  elseif exist(matfile,'file')
    load(matfile,'M');
  else
    M = [];
  end

  % note that this index is for the original anatomy (no permutete/flipdim).
  M.ind_in_ana = subGetCoordsInANA(expfile,INFO,M);
  M.pixdim_ana = M.vfpixdim;
  if any(DO_PERMUTE)
    tmpi = [];
    tmpi(DO_PERMUTE) = 1:numel(DO_PERMUTE);
    M.pixdim_ana = M.pixdim_ana(tmpi);
  end
  M.ind_in_ref = subGetCoordsInREF(expfile,INFO,M);
  M.pixdim_ref = M.vgpixdim;
  fprintf(' %s: saving coodinates ''M.ind_in_ana'' to ''%s''...',mfilename,matfile);
  save(matfile,'M');
  fprintf(' done.\n');


  fprintf('%s %s: DONE.\n',datestr(now,'HH:MM:SS'),mfilename);
end




return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function v = subIsAnzfile(x)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if iscell(x),  x = x{1};  end
v = 0;
if ~ischar(x),  return;  end
[fp, fr, fe] = fileparts(x);
if any(strcmpi(fe,{'.hdr','.img'})),  v = 1;  end

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [IMGFILES, Ses, GrpName] = subAnaExport(Ses,Grp,USE_EPI,USE_RAW,DO_EXPORT,DIR_NAME,IS_RAT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(Ses);
if ~exist('Grp','var')
  Grp = getgrp(Ses);
end
if ~iscell(Grp),  Grp = { Grp };  end

ananame = {};
anafile = {};
anaindx = [];
GrpName = {};
for N = 1:length(Grp)
  tmpgrp = getgrp(Ses,Grp{N});
  anap = getanap(Ses,Grp{N});
  if ~isimaging(tmpgrp),  continue;  end
  if isempty(tmpgrp.ana), continue;  end
  if any(USE_EPI) || (isfield(anap,'ImgDistort') && any(anap.ImgDistort))
    ananame{end+1} = sprintf('epi{%d}',tmpgrp.exps(1));
    anafile{end+1} = 'epi';
    anaindx(end+1) = tmpgrp.exps(1);
  else
    ananame{end+1} = sprintf('%s{%d}',tmpgrp.ana{1},tmpgrp.ana{2});
    anafile{end+1} = tmpgrp.ana{1};
    anaindx(end+1) = tmpgrp.ana{2};
  end
  GrpName{end+1} = tmpgrp.name;
end
[ananame, idx] = unique(ananame);
anafile = anafile(idx);
anaindx = anaindx(idx);
GrpName = GrpName(idx);

if isempty(DIR_NAME),  DIR_NAME = 'brain';  end

if ~exist(fullfile(pwd, DIR_NAME),'dir')
  mkdir(pwd, DIR_NAME);
end

IMGFILES = {};

fprintf('%s %s: exporting anatomies (%d)...\n',...
        datestr(now,'HH:MM:SS'),mfilename,length(ananame));
for N = 1:length(ananame)
  fprintf(' %s: read...',ananame{N});
  if strcmpi(anafile{N},'epi')
    ANA = load(sigfilename(Ses,anaindx(N),'tcImg'),'tcImg');
    ANA = ANA.tcImg;
    ANA.dat = nanmean(ANA.dat,4);
  else
    if sesversion(Ses) >= 2
      ANA = load(sigfilename(Ses,anaindx(N),anafile{N}),anafile{N});
      ANA = ANA.(anafile{N});
    else
      ANA = load(sprintf('%s.mat',anafile{N}),anafile{N});
      ANA = ANA.(anafile{N}){anaindx(N)};
    end
  end

  % scale to 0-32767 (int16+)
  fprintf(' scaling(int16+)...');
  ANA.dat = double(ANA.dat);
  ANA.dat(isnan(ANA.dat)) = 0;
  minv = min(ANA.dat(:));
  maxv = max(ANA.dat(:));
  ANA.dat = (ANA.dat - minv) / (maxv - minv);
  %ANA.dat = ANA.dat * single(intmax('int16'));
  ANA.dat = ANA.dat * 32000;
  
  anzfile = fullfile(pwd,DIR_NAME,sprintf('%s_%s_%03d.img',Ses.name,anafile{N},anaindx(N)));
  imgdim = [4 size(ANA.dat,1) size(ANA.dat,2) size(ANA.dat,3) 1];
  pixdim = [3 ANA.ds(1) ANA.ds(2) ANA.ds(3)];
  fprintf('[%s]', deblank(sprintf('%g ',pixdim(2:4))));
  
  if any(IS_RAT)
    pixdim(2:4) = pixdim(2:4)*10;  % multiply 10 for rat-template
  end

  fprintf('-->[%s]', deblank(sprintf('%g ',pixdim(2:4))));
  if any(DO_EXPORT)
    fprintf(' saving to ''%s''...',anzfile);
    hdr = hdr_init('dim',imgdim,'pixdim',pixdim,...
                   'datatype','int16','glmax',intmax('int16'),...
                   'descrip',sprintf('%s %s',Ses.name,ananame{N}));
    anz_write(anzfile,hdr,int16(round(ANA.dat)));
    subWriteInfo(anzfile,hdr,ANA.dat);
  end
  clear ANA;
  if any(USE_RAW)
    [fp, fr, fe] = fileparts(anzfile);
    rawfile = fullfile(fp,sprintf('%s.raw',fr));
    dstfile = fullfile(fp,sprintf('%s.img',fr));
    if exist(rawfile,'file')
      fprintf(' PHOTOSHOP %s.raw-->img.',fr);
      copyfile(rawfile,dstfile,'f');
    end
  end
  fprintf(' done.\n');
  IMGFILES{end+1} = anzfile;
end

return


% ============================================================================
% Do coregistration
function M = subDoCoregister(expfile,INFO,DO_TWOSTEPS)
% ============================================================================

% checks required files
reffile = fullfile(INFO.template_dir,INFO.template_file);
if ~exist(reffile,'file')
  error('\nERROR %s: reference anatomy not found, ''%s''\n',mfilename,reffile);
end
if ~exist(expfile,'file')
  error('\nERROR %s: exp-anatomy not found, ''%s''\n',mfilename,expfile);
end

% if spm_coreg_ui() called, it creates conversion matrix automatically.
% as result, cause the trouble when calling spm_vol()
[fp, fr] = fileparts(expfile);
matfile = fullfile(fp,sprintf('%s.mat',fr));
if exist(matfile,'file'),  delete(matfile); end
clear fp fr fe matfile;

fprintf(' ref: %s\n',reffile);
fprintf(' exp: %s\n',expfile);

M = mcoreg_spm_coreg(reffile,expfile,INFO.defflags,'twosteps',DO_TWOSTEPS);


return



% ============================================================================
% get coordinates: from anatomy to reference
function IND_to_VG = subGetCoordsInANA(expfile,INFO,M)
% ============================================================================
% initialize spm package, before any use of spm_xxx functions
if any(strcmpi(spm('ver'),{'SPM2','SPM5'}))
  spm_defaults;
else
  spm_get_defaults;
end


hdr = hdr_read(expfile);

% get coords of EXP-ANATOMY
xyzres = hdr.dime.pixdim(2:4);
x = 1:hdr.dime.dim(2);
y = 1:hdr.dime.dim(3);
z = 1:hdr.dime.dim(4);

% get EXP-coords in voxel
[R, C, P] = ndgrid(x,y,z);
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
reffile = fullfile(INFO.template_dir,INFO.template_file);
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
% recover flipped direction
for N = 1:length(INFO.flipdim)
  IND_to_VG = flipdim(IND_to_VG,INFO.flipdim(N));
end
% undo permutation
if any(INFO.permute)
  IND_to_VG = ipermute(IND_to_VG,INFO.permute);
end


return


% ============================================================================
% get coordinates : from reference to anatomy
function IND_to_VF = subGetCoordsInREF(expfile,INFO,M)
% ============================================================================
% initialize spm package, before any use of spm_xxx functions
if any(strcmpi(spm('ver'),{'SPM2','SPM5'}))
  spm_defaults;
else
  spm_get_defaults;
end


% get coords of REF-ANATOMY
reffile = fullfile(INFO.template_dir,INFO.template_file);
x = 1:M.vgdim(1);
y = 1:M.vgdim(2);
z = 1:M.vgdim(3);

% get REF-coords in voxel
[R, C, P] = ndgrid(x,y,z);
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

if any(INFO.flipdim) || any(INFO.permute)
  IND2 = 1:prod(M.vfdim);
  % get the original dimension
  if any(INFO.permute)
    tmpi = [];
    tmpi(INFO.permute) = 1:numel(INFO.permute);
    tmpdim = M.vfdim(tmpi);
  else
    tmpdim = M.vfdim;
  end
  IND2 = reshape(IND2,tmpdim);
  % permute
  if any(INFO.permute)
    IND2 = permute(IND2,INFO.permute);
  end
  % flipdim
  for N = 1:length(INFO.flipdim)
    IND2 = flipdim(IND2,INFO.flipdim(N));
  end
  IND2 = reshape(IND2,[1 numel(IND2)]);
  % update indices
  tmpidx = ~isnan(IND_to_VF(:));
  IND_to_VF(tmpidx) = IND2(IND_to_VF(tmpidx));
end


IND_to_VF = reshape(IND_to_VF,M.vgdim);

return




% ===============================================================
function hFig = subPlotAna(hFig,INFO,expfile)
% ===============================================================
reffile = fullfile(INFO.template_dir,INFO.template_file);
[fp, fref] = fileparts(reffile);
if isempty(hFig)
  [fp, fexp] = fileparts(expfile);
  hFig = figure;
else
  figure(hFig);
end
set(hFig,'Name',sprintf('%s %s: %s',datestr(now,'HH:MM:SS'),mfilename,fexp));

[fp2, fr2, fe2] = fileparts(reffile);
if strcmpi(fe2,'.nii')
  Hr = spm_vol(reffile);
  Vr = spm_read_vols(Hr);
  Hr.dime.pixdim = [3 Hr.mat(1,1) Hr.mat(2,2) Hr.mat(3,3)];
else
  [Vr, Hr] = anz_read(reffile);
end


[Ve, He] = anz_read(expfile);

%axs = [1 4 7  2 5 8]; % 3x3
axs = [1 3 5  2 4 6];  % 3x2
for N = 1:3
  for K = 1:2
    if K == 1
      vol = Vr;  hdr = Hr;
    else
      vol = Ve;  hdr = He;
    end
    if N == 1
      idx = round(size(vol,2)/2);
      tmpimg = squeeze(vol(:,idx,:));
      xres = hdr.dime.pixdim(2);
      yres = hdr.dime.pixdim(4);
      tmptitleX = 'X';
      tmptitleY = 'Z';
    elseif N == 2
      idx = round(size(vol,1)/2);
      tmpimg = squeeze(vol(idx,:,:));
      xres = hdr.dime.pixdim(3);
      yres = hdr.dime.pixdim(4);
      tmptitleX = 'Y';
      tmptitleY = 'Z';
    else 
      idx = round(size(vol,3)/2);
      tmpimg = squeeze(vol(:,:,idx));
      xres = hdr.dime.pixdim(2);
      yres = hdr.dime.pixdim(3);
      tmptitleX = 'X';
      tmptitleY = 'Y';
   end
   %subplot(3,3,axs(N +(K-1)*3));
   subplot(3,2,axs(N +(K-1)*3));
   tmpx = (1:size(tmpimg,1))*xres;
   tmpy = (1:size(tmpimg,2))*yres;
   imagesc(tmpx-xres/2,tmpy-yres/2,tmpimg');
   set(gca,'xlim',[0 max(tmpx)],'ylim',[0 max(tmpy)]);
   set(gca,'ydir','normal');
   hx = size(tmpimg,1)/2 *xres;
   hy = size(tmpimg,2)/2 *yres;
   hold on;
   line([0 max(tmpx)], [hy hy]-yres/2, 'color','y');
   line([hx hx]-xres/2, [0 max(tmpy)], 'color','y');
   xlabel(tmptitleX);  ylabel(tmptitleY);
   %daspect(gca,[2 2 1]);
   if N == 1
     if K == 1
       tmptitle = sprintf('REF: %s',fref);
     else
       tmptitle = sprintf('Inplane: %s',fexp);
     end
     title(strrep(tmptitle,'_','\_'),'horizontalalignment','center');
   end
  end
end
colormap('gray');


return



% ==================================================================================
function subWriteInfo(ANZFILE,HDR,IMG)
% ==================================================================================

[fp, froot] = fileparts(ANZFILE);


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
  dtype =  'uchar';
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
if strcmpi(endian,'B')
fprintf(fid,'byte-order: Mac\n');
else
fprintf(fid,'byte-order: IBM\n');
end
fprintf(fid,'header: 0\n');


fclose(fid);

return
