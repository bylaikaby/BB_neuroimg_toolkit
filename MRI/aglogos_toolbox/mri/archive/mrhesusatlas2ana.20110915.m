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
%    0.91 13.05.11 YM  use morphed Bezgin/Paxinos atlas and Frey MRI template.
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
  USE_EPI = 0;
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
fprintf('ACCEPT LICENCE AGREEMENT OF RHESUS-ATLAS(Bezgin(atlas), Frey(MRI-template)) AND SPM.\n');
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
    hFig = subPlotAna([],INFO,expfile);
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
    subPlotAtlas(hFig,INFO,ATLAS);
  end
  
  % create ROI structure
  if DO_MAKE_ROI && exist('Ses','var'),
    fprintf(' %s: making ROIs(minvoxels=%d)...',mfilename,INFO.minvoxels);
    RoiAtlas = subGetROI(Ses,GrpName{N},INFO,ATLAS);
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



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to create a window for SPM progress
function [Finter Fgraphics] = subCreateSPMWindow()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-Close any existing 'Interactive' 'Tag'ged windows
delete(spm_figure('FindWin','Interactive'))
delete(spm_figure('FindWin','Graphics'))

FS   = spm('FontSizes');				%-Scaled font sizes
PF   = spm_platform('fonts');			%-Font names (for this platform)
Rect = spm('WinSize','Interactive');	%-Interactive window rectangle

%-Create SPM Interactive window
Finter = figure('IntegerHandle','off',...
	'Tag','Interactive',...
	'Name',sprintf('%s: SPM progress',mfilename),...
	'NumberTitle','off',...
	'Position',Rect,...
	'Resize','on',...
	'Color',[1 1 1]*.7,...
	'MenuBar','none',...
	'DefaultTextFontName',PF.helvetica,...
	'DefaultTextFontSize',FS(10),...
	'DefaultAxesFontName',PF.helvetica,...
	'DefaultUicontrolBackgroundColor',[1 1 1]*.7,...
	'DefaultUicontrolFontName',PF.helvetica,...
	'DefaultUicontrolFontSize',FS(10),...
	'DefaultUicontrolInterruptible','on',...
	'Renderer', 'zbuffer',...
	'Visible','on');

Fgraphics = spm_figure('GetWin','Graphics');

return;


  

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



% read the reference and exported volume
VG = spm_vol(reffile);
VF = spm_vol(expfile);

% set optional flags for spm_coreg
flags = INFO.defflags;

[hWin hResult] = subCreateSPMWindow();
set(hResult,'visible','off');

if any(DO_TWOSTEPS) && ~strcmpi(flags.cost_fun,'ncc'),
  %          cost_fun - cost function string:
  %                      'mi'  - Mutual Information
  %                      'nmi' - Normalised Mutual Information
  %                      'ecc' - Entropy Correlation Coefficient
  %                      'ncc' - Normalised Cross Correlation
  flags.cost_fun = 'ncc';
  
  fprintf('%s: running spm_coreg()...',mfilename);
  fprintf(' sep=[%s], cost_fun=''%s'', fwhm=[%g %g]\n',...
          deblank(sprintf('%d ',flags.sep)),flags.cost_fun,flags.fwhm(1),flags.fwhm(2));
  x = spm_coreg(VG, VF, flags);
  set(hResult,'visible','on');

  % RESET optional flags for NEXT spm_coreg
  flags = INFO.defflags;
  % set the better seed
  if ~any(flags.params),
    flags.params = x(:)';
  end
end



% run coregistration
fprintf(' %s: running spm_coreg()...',mfilename);
fprintf(' sep=[%g %g], cost_fun=''%s'', fwhm=[%g %g]\n',...
        flags.sep(1),flags.sep(2),flags.cost_fun,flags.fwhm(1),flags.fwhm(2));

x = spm_coreg(VG, VF, flags);
set(hResult,'visible','on');
if ishandle(hWin),  close(hWin);  end

Q = inv(VF.mat\spm_matrix(x(:)')*VG.mat);
fprintf(' X1 = %0.3f*X %+0.3f*Y %+0.3f*Z %+0.3f\n',Q(1,:));
fprintf(' Y1 = %0.3f*X %+0.3f*Y %+0.3f*Z %+0.3f\n',Q(2,:));
fprintf(' Z1 = %0.3f*X %+0.3f*Y %+0.3f*Z %+0.3f\n',Q(3,:));

M = [];
M.mat      = inv(spm_matrix(x));  % matrix to convert inplane to reference
M.x        = x;
M.Q        = Q;
M.vgmat    = VG.mat;
try
M.vgpixdim = VG.private.hdr.dime.pixdim(2:4);  % pixdim of reference
catch
M.vgpixdim = abs(VG.private.mat0([1 6 11]));
end
M.vfmat    = VF.mat;
try
M.vfpixdim = VF.private.hdr.dime.pixdim(2:4);  % pixdim of inplane
catch
M.vfpixdim = abs(VF.private.mat0([1 6 11]));
end
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get Roi structure
function ROI = subGetROI(Ses,GrpName,INFO,ATLAS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% GET BASIC INFO
Ses = goto(Ses);
grp = getgrp(Ses,GrpName);
anap = getanap(Ses,grp);


% select corresponding slices
if isfield(anap,'ImgDistort') && anap.ImgDistort == 0,
  % match image size
  tcImg = sigload(Ses,grp.exps(1),'tcImg');
  if size(ATLAS.dat,3) ~= size(tcImg.dat,3),
    % slice selection
    ATLAS.dat = ATLAS.dat(:,:,grp.ana{3});
  end
  if size(ATLAS.dat,1) ~= size(tcImg.dat,1) || size(ATLAS.dat,2) ~= size(tcImg.dat,2),
    fnx = size(tcImg.dat,1);
    fny = size(tcImg.dat,2);
    fnz = size(tcImg.dat,3);
    NEWATLAS = zeros(fnx,fny,fnz);
    for N = 1:fnz,
      NEWATLAS(:,:,N) = imresize(ATLAS.dat(:,:,N),[fnx fny],'nearest');
    end
    ATLAS.dat = NEWATLAS;
    clear NEWATLAS;
  end
  clear tcImg;
end



% create rois
nx = size(ATLAS.dat,1);  ny = size(ATLAS.dat,2);  nz = size(ATLAS.dat,3);

uniqroi = sort(unique(ATLAS.dat(:)));
ROIroi = {};
ROInames = {};
maskimg = zeros(nx,ny);
for N=1:length(uniqroi),
  roinum  = uniqroi(N);
  tmpname = '';
  for K=1:length(ATLAS.roitable),
    if ATLAS.roitable{K}{1} == roinum,
      tmpname = ATLAS.roitable{K}{3};
      break;
    end
  end
  if isempty(tmpname),  continue;  end
  if roinum < 0,
    tmpname = fprintf('%s OH',tmpname);
  end
  
  idx = find(ATLAS.dat(:) == roinum);
  if length(idx) < INFO.minvoxels,  continue;  end
  %if length(idx) < 300,  continue;  end

  [tmpx tmpy tmpz] = ind2sub([nx ny nz],idx);
  uslice = sort(unique(tmpz(:)));
  for S=1:length(uslice),
    maskimg(:) = 0;
    slice = uslice(S);
    selvox = find(tmpz == slice);
    tmpidx = sub2ind([nx ny],tmpx(selvox),tmpy(selvox));
    maskimg(tmpidx) = 1;

    tmproiroi.name  = tmpname;
    tmproiroi.slice = slice;
    tmproiroi.px    = [];
    tmproiroi.py    = [];
    tmproiroi.mask  = logical(maskimg);

    ROIroi{end+1} = tmproiroi;
  end
  ROInames{end+1} = tmpname;
end

% now add the entire brain
tmpname = 'brain';

idx = find(abs(ATLAS.dat(:)) > 0);
[tmpx tmpy tmpz] = ind2sub([nx ny nz],idx);
if length(idx) >= INFO.minvoxels,
  uslice = sort(unique(tmpz(:)));
  for S=1:length(uslice),
    maskimg(:) = 0;
    slice = uslice(S);
    selvox = find(tmpz == slice);
    tmpidx = sub2ind([nx ny],tmpx(selvox),tmpy(selvox));
    maskimg(tmpidx) = 1;

    tmproiroi.name  = tmpname;
    tmproiroi.slice = slice;
    tmproiroi.px    = [];
    tmproiroi.py    = [];
    tmproiroi.mask  = logical(maskimg);

    ROIroi{end+1} = tmproiroi;
  end
  ROInames{end+1} = tmpname;
end


% finalize "Roi" structure
tcAvgImg = sigload(Ses,grp.exps(1),'tcImg');
anaImg = anaload(Ses,grp);
GAMMA = 1.8;
ROI = mroisct(Ses,grp,tcAvgImg,anaImg,GAMMA);
ROI.roinames = ROInames;
ROI.roi = ROIroi;

return




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function hFig = subPlotAna(hFig,INFO,expfile)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

reffile = fullfile(INFO.atlas_dir,INFO.reffile);
[fp fref] = fileparts(reffile);
if isempty(hFig),
  [fp fexp] = fileparts(expfile);
  hFig = figure;
else
  figure(hFig);
end
set(hFig,'Name',sprintf('%s %s: %s',datestr(now,'HH:MM:SS'),mfilename,fexp));

[fp2 fr2 fe2] = fileparts(reffile);
if strcmpi(fe2,'.nii'),
  Hr = spm_vol(reffile);
  Vr = spm_read_vols(Hr);
  Hr.dime.pixdim = [3 Hr.mat(1,1) Hr.mat(2,2) Hr.mat(3,3)];
else
  [Vr Hr] = anz_read(reffile);
end


[Ve He] = anz_read(expfile);

axs = [1 4 7  2 5 8];
for N = 1:3,
  for K = 1:2,
    if K == 1,
      vol = Vr;  hdr = Hr;
    else
      vol = Ve;  hdr = He;
    end
    if N == 1,
      idx = round(size(vol,2)/2);
      tmpimg = squeeze(vol(:,idx,:));
      xres = hdr.dime.pixdim(2);
      yres = hdr.dime.pixdim(4);
      tmptitleX = 'X';
      tmptitleY = 'Z';
    elseif N == 2,
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
   subplot(3,3,axs(N +(K-1)*3));
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
   if N == 1,
     if K == 1,
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



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function hFig = subPlotAtlas(hFig,INFO,ATLAS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(hFig);

axs = [3 6 9];

vol = abs(single(ATLAS.dat));
hdr.dime.pixdim = [1 ATLAS.ds(:)'];

cmap = jet(256);
minv = 0;
maxv = max(vol(:));
vol  = (vol - minv)/(maxv - minv);
vol  = round(vol*255) + 1;

if any(INFO.permute),
  vol = permute(vol,INFO.permute);
  hdr.dime.pixdim(2:4) = hdr.dime.pixdim(INFO.permute);
end
if any(INFO.flipdim),
  for N = 1:length(INFO.flipdim),
    vol = flipdim(vol,INFO.flipdim(N));
  end
end


for N = 1:3,
  if N == 1,
    idx = round(size(vol,2)/2);
    tmpimg = squeeze(vol(:,idx,:));
    xres = hdr.dime.pixdim(2);
    yres = hdr.dime.pixdim(4);
    tmptitleX = 'X';
    tmptitleY = 'Z';
  elseif N == 2,
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
  subplot(3,3,axs(N));
  tmpx = (1:size(tmpimg,1))*xres;
  tmpy = (1:size(tmpimg,2))*yres;
  %imagesc(tmpx-xres/2,tmpy-yres/2,tmpimg');
  image(tmpx-xres/2,tmpy-yres/2,ind2rgb(tmpimg',cmap));
  set(gca,'xlim',[0 max(tmpx)],'ylim',[0 max(tmpy)]);
  set(gca,'ydir','normal');
  hx = size(tmpimg,1)/2 *xres;
  hy = size(tmpimg,2)/2 *yres;
  hold on;
  line([0 max(tmpx)], [hy hy]-yres/2, 'color','y');
  line([hx hx]-xres/2, [0 max(tmpy)], 'color','y');
  xlabel(tmptitleX);  ylabel(tmptitleY);
  %daspect(gca,[2 2 1]);
  if N == 1,
    tmptitle = sprintf('ATLAS');
    title(strrep(tmptitle,'_','\_'),'horizontalalignment','center');
  end
end



return
