function mrhesusatlas2ana(varargin)
%MRHESUSATLAS2ANA - Coregister atlas to the given anatomy image or session/group.
%  MRHESUSATLAS2ANA(ANZFILE,...) coregisters the atlas to the given ANALIZE file.
%  MRHESUSATLAS2ANA(SESSION,GRPNAME,...) coregisters the atlas to the given
%  session/group.  After the coregistration, ROI set will be generated.
%  In this case, functional images can be a subset of slices in
%  the brain, but the anatomical scan must be an whole head anatomy.
%
%  In any case, results (atlas, conversion matrix) will be saved into *_coreg_atlas.mat.
%
%  Supported options are
%    'coregister' :  0|1, do coregistration
%    'permute'    :  permutation vector for the input image
%    'flipdim'    :  flipping dimension for the input image
%    'plot'       :  0|1, to plot a figure or not.
%    'makeroi'    :  0|1, make ROIs for session/group.
%    'twosteps'   : (default 0),  run spm_coreg() two times, first with 'ncc' cost-function.
%
%  Parameters can be controlled by the description file.
%    GRP.xxx.anap.mrhesusatlas2ana.permute   = [1 3 2];
%    GRP.xxx.anap.mrhesusatlas2ana.flipdim   = [3];
%    GRP.xxx.anap.mrhesusatlas2ana.minvoxels = 10;
%    GRP.xxx.anap.mrhesusatlas2ana.twosteps  = 0;
%    GRP.xxx.anap.mrhesusatlas2ana.spm_coreg.cost_fun  = 'nmi';
%          cost_fun - cost function string:
%                      'mi'  - Mutual Information
%                      'nmi' - Normalised Mutual Information
%                      'ecc' - Entropy Correlation Coefficient
%                      'ncc' - Normalised Cross Correlation
%
%  TIPS:
%   - To get better results, the input image should be in the similar
%     orientation like the atlas-image.  Options (permute/flipdim) will does
%     dimensional manipulation to the input image.
%   - For horizontal slices, use permute:[1 3 2], flipdim:[3]
%   - For coronal slice,     use permute:[],      flipdim:[2]
%
%  EXAMPLE :
%    % coregister the atlas to the given ANALIZE file.
%    mrhesusatlas2ana('Y:\DataMatlab\Anatomy\XXX.img');
%    % coregister the atlas to the given session/group.
%    mrhesusatlas2ana('i077k1','Spont');
%    mrhesusatlas2ana('i077k1','Spont','UseEPI',1);  % use EPI as anatomy
%
%  NOTE :
%
%  VERSION :
%    0.90 27.04.11 YM  modified from mratatlas2ana().
%    0.91 13.05.11 YM  use morphed CoCoMac/Paxinos atlas and Frey MRI template.
%    0.92 16.05.11 YM  bug fix, support EPI
%
%  See also anz_write spm_coreg

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end

if subIsAnzfile(varargin{1}),
  % called like mrhesusatlas2ana(anzfile,...)
  IMGFILES = varargin{1};
  iOPT = 2;
else
  if nargin < 2,
    fprintf('usage:  %s(Session,GrpName,...)\n',mfilename);
    return;
  end
  if iscell(varargin{2}),
    for N = 1:length(varargin{2}),
      mrhesusatlas2ana(varargin{1},varargin{2}{N},varargin{2:end});
    end
    return
  end
  % if ismanganese(varargin{1},varargin{2}),
  %   mratatlas2mng(varargin{1},varargin{2});
  %   return
  % end
  % called like mrhesusatlas2ana(Ses,Grp,...)
  anap = getanap(varargin{1},varargin{2});
  USE_EPI = 0;
  if isfield(anap,'mrhesusatlas2ana'),
    if isfield(anap.mrhesusatlas2ana,'use_epi'),
      USE_EPI = anap.mrhesusatlas2ana.use_epi;
    end
  end
  for N = 3:2:length(varargin),
    switch lower(varargin{N}),
     case {'epi','useepi','use_epi'}
      USE_EPI = varargin{N+1};
    end
  end
  [IMGFILES Ses GrpName] = subAnaExport(varargin{1},varargin{2},USE_EPI);
  iOPT = 3;
end
if ischar(IMGFILES),  IMGFILES = { IMGFILES };  end

% optional settings
DO_PERMUTE    = [];
DO_FLIPDIM    = [];
DO_COREGISTER = 1;
DO_TWOSTEPS   = 0;
DO_PLOT       = 1;
DO_MAKE_ROI   = 1;
MIN_NUM_VOXELS = [];

FLAGS_SPM_COREG = [];

if exist('Ses','var') && exist('GrpName','var'),
  anap = getanap(Ses,GrpName{1});
  if isfield(anap,'mrhesusatlas2ana'),
    if isfield(anap.mrhesusatlas2ana,'permute'),
      DO_PERMUTE = anap.mrhesusatlas2ana.permute;
    end
    if isfield(anap.mrhesusatlas2ana,'flipdim'),
      DO_FLIPDIM = anap.mrhesusatlas2ana.flipdim;
    end
    if isfield(anap.mrhesusatlas2ana,'minvoxels'),
      MIN_NUM_VOXELS = anap.mrhesusatlas2ana.minvoxels;
    end
    if isfield(anap.mrhesusatlas2ana,'twosteps'),
      DO_TWOSTEPS = anap.mrhesusatlas2ana.twosteps;
    end
    if isfield(anap.mrhesusatlas2ana,'spm_coreg'),
      FLAGS_SPM_COREG = anap.mrhesusatlas2ana.spm_coreg;
    end
  end
end

for N = iOPT:2:nargin,
  switch lower(varargin{N}),
   case {'coregister','coreg'}
    DO_COREGISTER = varargin{N+1};
   case {'twostep','twosteps'}
    DO_TWOSTEPS = varargin{N+1};
   case {'permute'}
    DO_PERMUTE    = varargin{N+1};
   case {'flipdim'}
    DO_FLIPDIM    = varargin{N+1};
   case {'plot'}
    DO_PLOT       = varargin{N+1};
   case {'make roi','makeroi','roi'}
    DO_MAKE_ROI   = varargin{N+1};
   case {'minvoxel','minvoxels','min_num_voxels'}
    MIN_NUM_VOXELS = varargin{N+1};
  end
end
DO_PERMUTE = DO_PERMUTE(:)';
DO_FLIPDIM = DO_FLIPDIM(:)';


% initialize spm package, bofore any use of spm_xxx functions
if any(strcmpi(spm('ver'),{'SPM2','SPM5'})),
  spm_defaults;
else
  spm_get_defaults;
end


INFO = mrhesusatlas_defs;
INFO.permute = DO_PERMUTE;
INFO.flipdim = DO_FLIPDIM;
if any(MIN_NUM_VOXELS),
  INFO.minvoxels = MIN_NUM_VOXELS;
end

% flags for spm_coreg()
%          cost_fun - cost function string:
%                      'mi'  - Mutual Information
%                      'nmi' - Normalised Mutual Information
%                      'ecc' - Entropy Correlation Coefficient
%                      'ncc' - Normalised Cross Correlation
% INFO.defflags.sep      = [4 2];
% INFO.defflags.params   = [0 0 0  0 0 0];
% INFO.defflags.cost_fun = 'nmi';
% INFO.defflags.fwhm     = [7 7];


INFO.defflags.sep      = [2 1];
INFO.defflags.params   = [0 0 0  0 0 0];
INFO.defflags.cost_fun = 'nmi';
INFO.defflags.fwhm     = [3 3];



if ~isempty(FLAGS_SPM_COREG),
  fnames = {'sep' 'params' 'cost_fun' 'fwhm'};
  for N = 1:length(fnames),
    if isfield(FLAGS_SPM_COREG,fnames{N}),
      INFO.defflags.(fnames{N}) = FLAGS_SPM_COREG.(fnames{N});
    end
  end
end

fprintf('\n');
fprintf('ACCEPT LICENCE AGREEMENT OF RHESUS-ATLAS(CoCoMac/Paxinos(atlas), Frey(MRI-template)) AND SPM.\n');
fprintf('For detail, see http://cocomac.org/,\n');
fprintf('                http://www.bic.mni.mcgill.ca/ServicesAtlases/Rhesus,\n');
fprintf('                http://www.fil.ion.ucl.ac.uk/spm\n');
fprintf('\n');
pause(3);  % 3sec pause

for N = 1:length(IMGFILES),
  expfile= IMGFILES{N};
  fprintf('%s %s %2d/%d: %s\n',datestr(now,'HH:MM:SS'),mfilename,...
          N,length(IMGFILES),expfile);
  
  if any(DO_PERMUTE) || any(DO_FLIPDIM),
    [img hdr] = anz_read(expfile);
    if any(DO_PERMUTE),
      fprintf(' permute[%s].',deblank(sprintf('%d ',DO_PERMUTE)));
      img = permute(img,DO_PERMUTE);
      hdr.dime.dim(2:4)    = hdr.dime.dim(DO_PERMUTE+1);
      hdr.dime.pixdim(2:4) = hdr.dime.pixdim(DO_PERMUTE+1);
    end
    if any(DO_FLIPDIM),
      fprintf(' flipdim[%s].',deblank(sprintf('%d ',DO_FLIPDIM)));
      for K=1:length(DO_FLIPDIM),
        img = flipdim(img,DO_FLIPDIM(K));
      end
    end
    [fp fr fe] = fileparts(expfile);
    expfile = fullfile(fp,sprintf('%s_mod%s',fr,fe));
    fprintf(' writing ''%s''...',expfile);
    anz_write(expfile,hdr,img);
    fprintf(' done.\n');
  end
  
  if DO_PLOT,
    hFig = matlas2roi_plot('ana',[],INFO,expfile);
  end
  
  [fp fr] = fileparts(expfile);
  % coregister inplane anatomy to the reference
  matfile = fullfile(fp,sprintf('%s_coreg_atlas.mat',fr));
  if DO_COREGISTER,
    % do coregistration
    M = subDoCoregister(expfile,INFO,DO_TWOSTEPS);
    fprintf(' %s: saving conversion matrix ''M'' to ''%s''...',mfilename,matfile);
    save(matfile,'M');
    fprintf(' done.\n');
  else
    load(matfile,'M');
  end

  % assign structure number to voxels
  fprintf(' %s: making aligned atlas...',mfilename);
  ATLAS = subGetAtlas(expfile,INFO,M);
  fprintf(' saving ''ATLAS'' to ''%s''...',matfile);
  save(matfile,'ATLAS','-append');
  fprintf(' done.\n');

  if DO_PLOT,
    matlas2roi_plot('atlas',hFig,INFO,ATLAS);
  end
  
  % create ROI structure
  if DO_MAKE_ROI && exist('Ses','var'),
    fprintf(' %s: making ROIs(minvoxels=%d)...',mfilename,INFO.minvoxels);
    RoiAtlas = mcoreg_make_roi(Ses,GrpName{N},INFO,ATLAS);
    fprintf('n=%d',length(RoiAtlas.roinames));
    datname = sprintf('Atlas_%s',GrpName{N});
    eval(sprintf('%s = RoiAtlas;',datname));
    fprintf(' saving ''%s'' to ''Roi.mat''...',datname);
    if exist('Roi.mat','file'),
      save('Roi.mat',datname,'-append');
    else
      save('Roi.mat',datname);
    end
    fprintf(' done.\n');

    fprintf('\nEDIT ''%s.m''\n',Ses.name);
    fprintf('ROI.names = {');
    for K=1:length(RoiAtlas.roinames),  fprintf(' ''%s''',RoiAtlas.roinames{K});  end
    fprintf(' };\n');
    fprintf('GRPP.grproi or GRP.%s.grproi as ''%s''.\n',GrpName{N},datname);
    eval(sprintf('clear %s RoiAtlas;',datname));
  end

  clear ATLAS;
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
function [IMGFILES Ses GrpName] = subAnaExport(Ses,Grp,USE_EPI)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(Ses);
if ~exist('Grp','var'),
  Grp = getgrp(Ses);
end
if ~iscell(Grp),  Grp = { Grp };  end

ananame = {};
anafile = {};
anaindx = [];
GrpName = {};
for N = 1:length(Grp),
  tmpgrp = getgrp(Ses,Grp{N});
  anap = getanap(Ses,Grp{N});
  if ~isimaging(tmpgrp),  continue;  end
  if isempty(tmpgrp.ana), continue;  end
  if any(USE_EPI) || (isfield(anap,'ImgDistort') && any(anap.ImgDistort)),
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
[ananame idx] = unique(ananame);
anafile = anafile(idx);
anaindx = anaindx(idx);
GrpName = GrpName(idx);

DIR_NAME = 'atlas';

if ~exist(fullfile(pwd, DIR_NAME),'dir'),
  mkdir(pwd, DIR_NAME);
end

IMGFILES = {};

fprintf('%s %s: exporting anatomies (%d)...\n',...
        datestr(now,'HH:MM:SS'),mfilename,length(ananame));
for N = 1:length(ananame),
  fprintf(' %s: read...',ananame{N});
  if strcmpi(anafile{N},'epi'),
    ANA = load(catfilename(Ses,anaindx(N),'tcImg'),'tcImg');
    ANA = ANA.tcImg;
    ANA.dat = nanmean(ANA.dat,4);
  else
    ANA = load(sprintf('%s.mat',anafile{N}),anafile{N});
    ANA = ANA.(anafile{N}){anaindx(N)};
  end
  
  % scale to 0-32767 (int16+)
  fprintf(' scaling(int16+)...');
  ANA.dat = single(ANA.dat);
  ANA.dat(isnan(ANA.dat)) = 0;
  minv = min(ANA.dat(:));
  maxv = max(ANA.dat(:));
  ANA.dat = (ANA.dat - minv) / (maxv - minv);
  ANA.dat = ANA.dat * single(intmax('int16'));
  
  % testing half-zero
  %ANA.dat(1:round(size(ANA.dat,1)/2),:,:) = 0;
  % testing left-shift
  %ANA.dat(1:160,:,:) = ANA.dat((1:160)+20,:,:);
  %ANA.dat(161:end,:,:) = 0;
  
  
  anzfile = fullfile(pwd,DIR_NAME,sprintf('%s_%s_%03d.hdr',Ses.name,anafile{N},anaindx(N)));
  imgdim = [4 size(ANA.dat,1) size(ANA.dat,2) size(ANA.dat,3) 1];
  pixdim = [3 ANA.ds(1) ANA.ds(2) ANA.ds(3)];
  fprintf('[%s]', deblank(sprintf('%g ',pixdim(2:4))));

  % only for rat-atlas...
  %pixdim(2:4) = pixdim(2:4)*10;  % multiply 10 for rat-atlas

  
  fprintf('-->[%s]', deblank(sprintf('%g ',pixdim(2:4))));
  fprintf(' saving to ''%s''...',anzfile);
  hdr = hdr_init('dim',imgdim,'pixdim',pixdim,...
                 'datatype','int16','glmax',intmax('int16'),...
                 'descrip',sprintf('%s %s',Ses.name,ananame{N}));
  anz_write(anzfile,hdr,int16(round(ANA.dat)));

  clear ANA;
  fprintf(' done.\n');
  IMGFILES{end+1} = anzfile;
end

return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do coregistration
function M = subDoCoregister(expfile,INFO,DO_TWOSTEPS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize spm package, bofore any use of spm_xxx functions
if any(strcmpi(spm('ver'),{'SPM2','SPM5'})),
  spm_defaults;
else
  spm_get_defaults;
end


% checks required files
reffile = fullfile(INFO.atlas_dir,INFO.reffile);
if ~exist(reffile,'file'),
  error('\nERROR %s: reference anatomy not found, ''%s''\n',mfilename,reffile);
end
atlasfile = fullfile(INFO.atlas_dir,INFO.atlasfile);
if ~exist(atlasfile,'file'),
  error('\nERROR %s: atlas not found, ''%s''\n',mfilename,atlasfile);
end
if ~exist(expfile,'file'),
  error('\nERROR %s: exp-anatomy not found, ''%s''\n',mfilename,expfile);
end
% if spm_coreg_ui() called, it creates conversion matrix automatically.
% as result, cause the trouble when calling spm_vol()
[fp fr] = fileparts(expfile);
matfile = fullfile(fp,sprintf('%s.mat',fr));
if exist(matfile,'file'),  delete(matfile); end
clear fp fr fe matfile;

fprintf(' ref: %s\n',reffile);
fprintf(' exp: %s\n',expfile);

M = mcoreg_spm_coreg(reffile,expfile,INFO.defflags,'twosteps',DO_TWOSTEPS);


return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create corresponding atlas
function ATLAS = subGetAtlas(expfile,INFO,M)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize spm package, before any use of spm_xxx functions
if any(strcmpi(spm('ver'),{'SPM2','SPM5'})),
  spm_defaults;
else
  spm_get_defaults;
end


atlasfile = fullfile(INFO.atlas_dir,INFO.atlasfile);
if ~exist(atlasfile,'file'),
  error('\nERROR %s: atlas not found, ''%s''\n',mfilename,atlasfile);
end

hdr = hdr_read(expfile);

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

% convert the coords into ATLAS space
% 16.05.11. NOTE THAT ATLAS HAS THE SAME DIMENSION AS REF-TEMPLATE.
VA = spm_vol(fullfile(INFO.atlas_dir,INFO.reffile));
%VA = spm_vol(atlasfile);

XYZ(4,:) = 1;
RCP = inv(VA.mat)*XYZ;   % in voxel
RCP = round(RCP(1:3,:));

% mark outside as NaN
RCP(RCP(:) < 1) = NaN;
RCP(1,RCP(1,:) > VA.dim(1)) = NaN;
RCP(2,RCP(2,:) > VA.dim(2)) = NaN;
RCP(3,RCP(3,:) > VA.dim(3)) = NaN;


ROITABLE = mratatlas_roitable(fullfile(INFO.atlas_dir,INFO.tablefile));
if 1,
  atlas = load(fullfile(INFO.atlas_dir,INFO.atlasfile),'ATLAS');
  atlas = atlas.ATLAS;
  atlas.dat = double(atlas.dat);

  % make RGB to a single unique number
  atlas.dat = atlas.dat(:,:,:,1)*256*256 + atlas.dat(:,:,:,2)*256 + atlas.dat(:,:,:,3);
  % make white as black
  atlas.dat(atlas.dat(:) == 255*256*256 + 255*256 + 255) = 0;
  
  for N = 1:length(ROITABLE),
    tmpv = ROITABLE{N}{1};
    ROITABLE{N}{1} = tmpv(1)*256*256 + tmpv(2)*256 + tmpv(3);
  end
end
  
  
  
% assign structure number to voxels
nvox = size(RCP,2);
strnum = zeros(1,nvox);
for N = 1:nvox,
  if any(isnan(RCP(:,N))),  continue;  end
  strnum(N) = atlas.dat(RCP(1,N),RCP(2,N),RCP(3,N));
end
clear RCP atlas;

strnum = reshape(strnum,[length(x) length(y) length(z)]);
% recover flipped direction
for N = 1:length(INFO.flipdim),
  strnum = flipdim(strnum,INFO.flipdim(N));
end
% undo permutation
if any(INFO.permute),
  strnum = ipermute(strnum,INFO.permute);
  xyzres = ipermute(xyzres,INFO.permute);
end
strnum = int32(strnum);
  

ATLAS.dat      = strnum;
ATLAS.ds       = xyzres;
ATLAS.roitable = ROITABLE;

if isempty(ATLAS.roitable),
  error('\nERROR %s:  invalid roi-table.\n',mfilename);
end


return

