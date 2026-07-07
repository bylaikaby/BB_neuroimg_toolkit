function mratatlas2mng(Ses,GrpName,varargin)
%MRATATLAS2MNG - Extracts ROIs from the rat atlas (only for manganese exeperiment).
%  MRATATLAS2MNG(SES)
%  MRATATLAS2MNG(SES,GRPNAME) extracts ROIs from the rat atlas then saves ROIs into "Roi.mat".
%  
%  !! IMPORTANT !!!
%  Inplane anatomy and functional images must be CORONAL section to match with ATLAS.
%  +X=left, +Y=posterior, +Z=ventral.
%  Correct ASCAN.xxx.permute, GRPP.permute, GRP.xxx.permute if needed.
%
%  !! NOTE THAT THIS PROGRAM IS WRITTEN FOR MANGANESE EXPERIMENTS.
%  !! FOR THE CASE OF FUNCTIONAL IMAGING, USE mratatlas2ana.m.
%
%  Supported options are :
%    'export'     : (default 0),  call mratInplane2analyze() or not.
%    'raw2img'    : (default 0),  call mraw2img() or not.
%    'coregister' : (default 1),  call spm_coreg() or not, otherwise use previous registration.
%    'twosteps'   : (default 0),  run spm_coreg() two times, first with 'ncc' cost-function.
%
%  EXAMPLE :
%    sesascan('rat7tHA1');
%    anaview('rat7tHA1',1);
%    % make sure CORONAL, otherwise edit "permute" then re-run sesascan()/mnimgload()
%    mratInplane2analyze('rat7tHA1','mdeftinj');
%    % do some photoshop work here, if needed
%    % mratraw2img('rat7tHA1','mdeftinj');  % run this if needed.
%    mratatlas2mng('rat7tHA1','mdeftinj')
%    % modify the description file here.
%    mroi('rat7tHA1','mdeftinj');            % check ROIs
%
%  NOTE :
%   Inplane anatomy/functional images must be 'coronal' section,  +X=left,+Y=post., +Z=vent.
%   Atlas directory can be set in getdirs() as .rat_atlas.
%
%   Parameters can be controlled by the description file.
%     GRP.xxx.anap.mratatlas2mng.atlas     = 'GSKrat97';
%     GRP.xxx.anap.mratatlas2mng.use_raw   = 0;
%     GRP.xxx.anap.mratatlas2mng.flipdim   = [2 3];
%     GRP.xxx.anap.mratatlas2mng.minvoxels = 10;
%     GRP.xxx.anap.mratatlas2mng.twosteps  = 0;
%
%   Optional flags for spm_coreg() can be set as following, see spm_coreg() for detail.
%     GRP.xxx.anap.mratatlas2mng.spm_coreg.sep      = [4 2];          % optimisation sampling steps (mm)
%     GRP.xxx.anap.mratatlas2mng.spm_coreg.params   = [0 0 0  0 0 0]; % starting estimates (6 elements)
%     GRP.xxx.anap.mratatlas2mng.spm_coreg.cost_fun = 'nmi';          % cost function string
%     GRP.xxx.anap.mratatlas2mng.spm_coreg.fwhm     = [7 7];          % smoothing to apply to 256x256 joint histogram
%   For detail, see spm_coreg.m
%
%          cost_fun - cost function string:
%                      'mi'  - Mutual Information
%                      'nmi' - Normalised Mutual Information
%                      'ecc' - Entropy Correlation Coefficient
%                      'ncc' - Normalised Cross Correlation
%                      default: 'nmi'
%
%  REQUITEMENT :
%    SPM, http://www.fil.ion.ucl.ac.uk/spm
%    ATLAS database by AJ Schwarz et. al
%    MUST ACCEPT LICENCE AGREEMENT IN ratBrain_copyright_licence_2007-02-13.doc and README.v5.
%
%  VERSION :
%    0.90 06.08.07 YM  pre-release
%    0.91 08.08.07 YM  bug fix.
%    0.92 09.08.07 YM  supports INFO.minvoxels to ignore very small structure.
%    0.93 20.08.07 YM  also adds the entire brain as ROI.
%    0.94 07.02.09 YM  bug fix for spm5...
%    0.95 17.11.10 YM  two-step estimation, 1st by 'ncc' cost-function.
%    0.96 09.03.11 YM  renamed as mratatlas2mng() from mratatlas2roi().
%    0.97 03.02.12 YM  use mroi_save().
%    0.98 04.07.13 YM  use matlas_defs(), clean-up.
%
%  See also anz_read anz_write spm_coreg matlas_defs mratInplane2analyze mratraw2img
%           matlas2roi mratatlas2ana mrhesusatlas2ana
%           mroi2roi_coreg mroi2roi_shift mana2brain mana2epi


if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end

% GET BASIC INFO
Ses = goto(Ses);
if ~exist('GrpName','var'),  GrpName = {};  end
if isempty(GrpName),  GrpName = subGetUniqGroups(Ses);  end
if iscell(GrpName)
  for N = 1:length(GrpName),
    mratatlas2mng(Ses,GrpName{N},varargin{:});
  end
  return
end
grp = getgrp(Ses,GrpName);


ATLAS_SET     = 'GSKrat97';
DO_EXPORT     = 0;
DO_RAW2IMG    = 0;
DO_COREGISTER = 1;
DO_TWOSTEPS   = 0;
UNDO_CROPPING = 0;      % must be 0
DO_FLIPDIM    = [2 3];  % must be [2 3]
MIN_NUM_VOXELS = 10;
FLAGS_SPM_COREG = [];

anap = getanap(Ses,GrpName);
if isfield(anap,'spm_coreg')
  % backward compatibility...
  FLAGS_SPM_COREG = anap.spm_coreg;
end
if isfield(anap,'mratatlas2mng'),
  x = anap.mratatlas2mng;
  if isfield(x,'atlas')
    ATLAS_SET = x.atlas;
  end
  if isfield(x,'flipdim'),
    DO_FLIPDIM = x.flipdim;
  end
  if isfield(x,'minvoxels'),
    MIN_NUM_VOXELS = x.minvoxels;
  end
  if isfield(x,'twosteps'),
    DO_TWOSTEPS = x.twosteps;
  end
  if isfield(x,'spm_coreg'),
    FLAGS_SPM_COREG = x.spm_coreg;
  end
  clear x;
end

for N=1:2:length(varargin),
  switch lower(varargin{N}),
   case {'atlas'}
    ATLAS_SET = varargin{N+1};
   case {'doexport','export','inplane2anatomy'}
    DO_EXPORT = varargin{N+1};
   case {'doraw2img','raw2img' 'raw'}
    DO_RAW2IMG = varargin{N+1};
   case {'docoregister','coregister','coreg'}
    DO_COREGISTER = varargin{N+1};
   case {'twostep','twosteps'}
    DO_TWOSTEPS = varargin{N+1};
   case {'flipdim'}
    DO_FLIPDIM = varargin{N+1};
   case {'minvoxel','minvoxels','min_num_voxels'}
    MIN_NUM_VOXELS = varargin{N+1};
    
  end
end

if any(DO_TWOSTEPS),  DO_COREGISTER = 1;  end

% initialize spm package, bofore any use of spm_xxx functions
if any(strcmpi(spm('ver'),{'SPM2','SPM5'})),
  spm_defaults;
else
  spm_get_defaults;
end


INFO = matlas_defs(ATLAS_SET);
INFO.flipdim = DO_FLIPDIM;
INFO.undoCropping = UNDO_CROPPING;
INFO.minvoxels = MIN_NUM_VOXELS;

% flags for spm_coreg()
INFO.defflags.sep      = [4 2];
INFO.defflags.params   = [0 0 0  0 0 0];
INFO.defflags.cost_fun = 'nmi';
INFO.defflags.fwhm     = [7 7];
if ~isempty(FLAGS_SPM_COREG),
  fnames = {'sep' 'params' 'cost_fun' 'fwhm'};
  for N = 1:length(fnames),
    if isfield(FLAGS_SPM_COREG,fnames{N}),
      INFO.defflags.(fnames{N}) = FLAGS_SPM_COREG.(fnames{N});
    end
  end
end


fprintf('\nATLAS : %s', INFO.type);
switch lower(INFO.type)
 case {'gskrat97'}
  fprintf('\n');
  fprintf('ACCEPT LICENCE AGREEMENT OF RAT-ATLAS(AJ Schwartz,GlaxoSmithKline).\n');
  fprintf('For detail, see ratBrain_copyright_licence_*.doc.\n');
 case {'rat16t'}
  fprintf('\n');
  fprintf('ACCEPT LICENCE AGREEMENT OF RAT-ATLAS(AGLOGO/YMurayama/GSKrat97).\n');
  fprintf('For detail, see *.doc.\n');
 case {'rat2013'}
  fprintf('\n');
  fprintf('ACCEPT LICENCE AGREEMENT OF RAT-ATLAS(AGLOGO/HEvrard).\n');
  fprintf('For detail, see *.doc.\n');
 otherwise
  [fp fe fe] = fileparts(INFO.atlas_file);
  if strcmpi(fe,'.mat'),
    error('\n ERROR %s: not supported yet, atlas=%s.\n',mfilename,INFO.type);
  end
end
fprintf('\n');
fprintf('ACCEPT LICENCE AGREEMENT OF %s.\n',spm('ver'));
fprintf('For detail, see http://www.fil.ion.ucl.ac.uk/spm\n');
fprintf('\n');
pause(3);  % 3sec pause
  

% Run coregistration and extract ROIs from atlas
fprintf('%s: %s %s Atlas=%s----------------------------------\n',mfilename,Ses.name,grp.name,INFO.type);

% export inplane anatomy
if DO_EXPORT,
  mratInplane2analyze(Ses,GrpName,'info',INFO);
end
if DO_RAW2IMG,
  fprintf(' mratraw2img().');
  mratraw2img(Ses,GrpName,'info',INFO);
end

% coregister inplane anatomy to the reference
matfile = sprintf('coreg_%s.mat',GrpName);
if DO_COREGISTER,
  % do coregistration
  M = subDoCoregister(Ses,GrpName,INFO,DO_TWOSTEPS);
  fprintf('%s: saving conversion matrix ''M'' to ''%s''...',mfilename,matfile);
  save(matfile,'M');
  fprintf(' done.\n');
else
  load(matfile,'M');
end

% assign structure number to voxels
fprintf('%s: making aligned atlas...',mfilename);
ATLAS = subGetAtlas(Ses,GrpName,INFO,M);
fprintf(' saving ''ATLAS'' to ''%s''...',matfile);
save(matfile,'ATLAS','-append');
fprintf(' done.\n');
  
% create ROI structure
fprintf('%s: making ROIs(minvoxels=%d)...',mfilename,INFO.minvoxels);
fprintf('%s: making ROIs...',mfilename);
RoiAtlas = subGetROI(Ses,GrpName,INFO,ATLAS);
fprintf('n=%d',length(RoiAtlas.roinames));
datname = sprintf('Atlas_%s',GrpName);
mroi_save(Ses,datname,RoiAtlas,'verbose',1,'backup',1);

fprintf('\nEDIT ''%s.m''\n',Ses.name);
fprintf('ROI.names = {');
for K=1:length(RoiAtlas.roinames),  fprintf(' ''%s''',RoiAtlas.roinames{K});  end
fprintf(' };\n');
fprintf('GRPP.grproi or GRP.%s.grproi as ''%s''.\n',GrpName,datname);
eval(sprintf('clear %s RoiAtlas;',datname));


return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Looks at grp.ana and returns group names those are unique.
function GrpNames = subGetUniqGroups(Ses)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(Ses);
grps = getgroups(Ses);
IsUniq = ones(1,length(grps));
GrpNames = {};
for N = 1:length(grps),
  if IsUniq(N) == 0,  continue;  end
  ana1 = grps{N}.ana;
  for K = N+1:length(grps),
    ana2 = grps{K}.ana;
    if strcmpi(ana1{1},ana2{1}) && ana1{2} == ana2{2} && length(ana1{3}) == length(ana2{3}),
      if all(ana1{3} == ana2{3}),
        IsUniq(K) = 0;
      end
    end
  end
  GrpNames{end+1} = grps{N}.name;
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
function M = subDoCoregister(Ses,GrpName,INFO,DO_TWOSTEPS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize spm package, bofore any use of spm_xxx functions
if any(strcmpi(spm('ver'),{'SPM2','SPM5'})),
  spm_defaults;
else
  spm_get_defaults;
end


% GET BASIC INFO
Ses = goto(Ses);
grp = getgrp(Ses,GrpName);

% checks required files
reffile = fullfile(INFO.template_dir,INFO.template_file);
if ~exist(reffile,'file'),
  error('\nERROR %s: reference anatomy not found, ''%s''\n',mfilename,reffile);
end
atlasfile = fullfile(INFO.template_dir,INFO.atlas_file);
if ~exist(atlasfile,'file'),
  error('\nERROR %s: atlas not found, ''%s''\n',mfilename,atlasfile);
end
expfile = fullfile(pwd,sprintf('anat_%s.img',grp.name));
if ~exist(expfile,'file'),
  error('\nERROR %s: inplane-anatomy not found, ''%s''\n',mfilename,expfile);
end
% if spm_coreg_ui() called, it creates conversion matrix automatically.
% as result, cause the trouble when calling spm_vol()
[fp fr] = fileparts(expfile);
matfile = fullfile(fp,sprintf('%s.mat',fr));
if exist(matfile,'file'),  delete(matfile); end
clear fp fr fe matfile;



% read the reference and exported volume
VG = spm_vol(reffile);
VF = spm_vol(expfile);



[hWin hResult] = subCreateSPMWindow();
set(hResult,'visible','off');


% set optional flags for spm_coreg
flags = INFO.defflags;


% run coregistration
if any(DO_TWOSTEPS),
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
fprintf('%s: running spm_coreg()...',mfilename);
fprintf(' sep=[%s], cost_fun=''%s'', fwhm=[%g %g]\n',...
        deblank(sprintf('%d ',flags.sep)),flags.cost_fun,flags.fwhm(1),flags.fwhm(2));
x = spm_coreg(VG, VF, flags);
set(hResult,'visible','on');


if ishandle(hWin),  close(hWin);  end


Q = inv(VF.mat\spm_matrix(x(:)')*VG.mat);
fprintf('X1 = %0.3f*X %+0.3f*Y %+0.3f*Z %+0.3f\n',Q(1,:));
fprintf('Y1 = %0.3f*X %+0.3f*Y %+0.3f*Z %+0.3f\n',Q(2,:));
fprintf('Z1 = %0.3f*X %+0.3f*Y %+0.3f*Z %+0.3f\n',Q(3,:));

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
function ATLAS = subGetAtlas(Ses,GrpName,INFO,M)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize spm package, bofore any use of spm_xxx functions
if any(strcmpi(spm('ver'),{'SPM2','SPM5'})),
  spm_defaults;
else
  spm_get_defaults;
end


% GET BASIC INFO
Ses = goto(Ses);
grp = getgrp(Ses,GrpName);
anap = getanap(Ses,grp);
ExpNo = grp.exps(1);
par = expgetpar(Ses,ExpNo);
atlasfile = fullfile(INFO.template_dir,INFO.atlas_file);
if ~exist(atlasfile,'file'),
  error('\nERROR %s: atlas not found, ''%s''\n',mfilename,atlasfile);
end

% get coords of fMRI
xyzres = par.pvpar.res;
if length(par.pvpar.reco.RECO_fov) > 2,
  xyzres(3) = par.pvpar.reco.RECO_fov(3)*10/par.pvpar.nsli;
else
  %xyzres(3) = mean(par.pvpar.acqp.ACQ_slice_sepn);
  xyzres(3) = par.pvpar.slithk;
end
xyzres = xyzres * 10;  % need to multiply 10 for the atlas
if isfield(Ses.expp(ExpNo),'imgcrop') && ~isempty(Ses.expp(ExpNo).imgcrop),
  IMGCROP = Ses.expp(ExpNo).imgcrop;
elseif isfield(grp,'imgcrop'),
  IMGCROP = grp.imgcrop;
else
  IMGCROP = [];
end
clear tcImg;
if ~isempty(IMGCROP),
  x = (0:IMGCROP(3)-1) + IMGCROP(1);
  y = (0:IMGCROP(4)-1) + IMGCROP(2);
else
  x = 1:par.pvpar.nx;
  y = 1:par.pvpar.ny;
end
if isfield(Ses.expp(ExpNo),'slicrop') && ~isempty(Ses.expp(ExpNo).slicrop),
  SLICROP = Ses.expp(ExpNo).slicrop;
else
  if isfield(grp,'slicrop'),
    SLICROP = grp.slicrop;
  else
    SLICROP = [];
  end
end
if ~isempty(SLICROP),
  z = 1:SLICROP(2);
else
  z = 1:par.pvpar.nsli;
end

if isfield(grp,'permute') && ~isempty(grp.permute),
  tmpx = x;  tmpy = y;  tmpz = z;
  if all(grp.permute == [1 2 3]),
    % do nothing
  elseif all(grp.permute == [1 3 2]),
    tmpy = z;  tmpz = y;
  elseif all(grp.permute == [2 1 3]),
    tmpx = y;  tmpy = x;
  elseif all(grp.permute == [2 3 1]),
    tmpx = y;  tmpy = z;  tmpz = x;
  elseif all(grp.permute == [3 1 2]),
    tmpx = z;  tmpy = x;  tmpz = y;
  elseif all(grp.permute == [3 2 1]),
    tmpx = z;  tmpz = x;
  else
    keyboard
  end
  x = tmpx;  y = tmpy;  z = tmpz;
  clear tmpx tmpy tmpz;
  xyzres = xyzres(grp.permute);
end

if INFO.undoCropping == 0,
  x = 1:length(x);
  y = 1:length(y);
  z = 1:length(z);
end


% get fMRI-coords in voxel
[R C P] = ndgrid(x,y,z);
RCP = zeros(4,length(R(:)));  % allocate memory first to avoid memory problem
RCP(1,:) = R(:);  clear R;
RCP(2,:) = C(:);  clear C;
RCP(3,:) = P(:);  clear P;
RCP(4,:) = 1;

% convert fMRI-coords into inplane-anatomy, -/+1 for matlab indexing
xyzscale = xyzres ./ M.vfpixdim;
RCP(1,:) = (RCP(1,:)-1) * xyzscale(1) + 1;
RCP(2,:) = (RCP(2,:)-1) * xyzscale(2) + 1;
RCP(3,:) = (RCP(3,:)-1) * xyzscale(3) + 1;
XYZ = M.vfmat*RCP;       % in mm
clear RCP;

% convert the coords into REFERENCE space
XYZ(4,:) = 1;
XYZ = M.mat*XYZ;         % in mm

% convert the coords into ATLAS space
VA = spm_vol(atlasfile);
XYZ(4,:) = 1;
RCP = inv(VA.mat)*XYZ;   % in voxel
RCP = round(RCP(1:3,:));

% mark outside as NaN
RCP(RCP(:) < 1) = NaN;
RCP(1, RCP(1,:) > VA.dim(1)) = NaN;
RCP(2, RCP(2,:) > VA.dim(2)) = NaN;
RCP(3, RCP(3,:) > VA.dim(3)) = NaN;
% for N = 1:3,
%   idx = find(RCP(N,:) < 1 | RCP(N,:) > VA.dim(N));
%   if isempty(idx),  continue;  end
%   RCP(N,idx) = NaN;
% end
atlas = spm_read_vols(VA);
atlas = abs(atlas);

% assign structure number to voxels
nvox = size(RCP,2);
strnum = zeros(1,nvox);
for N = 1:nvox,
  if any(isnan(RCP(:,N))),  continue;  end
  strnum(N) = atlas(RCP(1,N),RCP(2,N),RCP(3,N));
end
clear RCP atlas;

strnum = reshape(strnum,[length(x) length(y) length(z)]);
% recover flipped direction
for N = 1:length(INFO.flipdim),
  strnum = flipdim(strnum,INFO.flipdim(N));
end
strnum = int16(strnum);


ATLAS.dat      = strnum;
ATLAS.ds       = xyzres;
ATLAS.roitable = matlas_roitable(fullfile(INFO.template_dir,INFO.table_file));
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
