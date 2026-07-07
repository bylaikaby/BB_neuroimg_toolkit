function mratatlas2roi(Ses,GrpNames,varargin)
%MRATATLAS2ROI -- extracts ROIs from the rat atlas.
%  MRATATLAS2ROI(SES)
%  MROIATLAS2ROI(SES,GRPNAME) extracts ROIs from the rat atlas then saves ROIs into "Roi.mat".
%  
%  !! IMPORTANT !!!
%  Inplane anatomy and functional images must be CORONAL section to match with ATLAS.
%  +X=left, +Y=posterior, +Z=ventral.
%  Correct ASCAN.xxx.permute, GRPP.permute, GRP.xxx.permute if needed.
%
%
%  EXAMPLE :
%    >> sesascan('rat7tHA1');
%    >> anaview('rat7tHA1',1);
%    >> % make sure CORONAL, otherwise edit "permute" then re-run sesascan()/mnimgload()
%    >> mratInplane2analyze('rat7tHA1','mdeftinj');
%    >> % do some photoshop work here, if needed
%    >> % mratraw2img('rat7tHA1','mdeftinj');  % run this if needed.
%    >> mratatlas2roi('rat7tHA1','mdeftinj')
%    >> % modify the description file here.
%    >> mroi('rat7tHA1','mdeftinj');            % check ROIs
%
%  NOTE :
%   Inplane anatomy/functional images must be 'coronal' section,  +X=left,+Y=post., +Z=vent.
%   Atlas directory can be set in getdirs() as .rat_atlas.
%   Optional flags for spm_coreg() can be set as following, see spm_coreg() for detail.
%     GRP.xxx.anap.spm_coreg.sep      = [4 2];          % optimisation sampling steps (mm)
%     GRP.xxx.anap.spm_coreg.params   = [0 0 0  0 0 0]; % starting estimates (6 elements)
%     GRP.xxx.anap.spm_coreg.cost_fun = 'nmi';          % cost function string
%     GRP.xxx.anap.spm_coreg.fwhm     = [7 7];          % smoothing to apply to 256x256 joint histogram
%
%  REQUITEMENT :
%    SPM2, http://www.fil.ion.ucl.ac.uk/spm
%    ATLAS database by AJ Schwarz et. al
%    MUST ACCEPT LICENCE AGREEMENT IN ratBrain_copyright_licence_2007-02-13.doc and README.v5.
%
%  VERSION :
%    0.90 06.08.07 YM  pre-release
%    0.91 08.08.07 YM  bug fix.
%    0.92 09.08.07 YM  supports INFO.minvoxels to ignore very small structure.
%    0.93 20.08.07 YM  also adds the entire brain as ROI.
%    0.94 07.02.09 YM  bug fix for spm5...
%
%  See also mratatlas_defs mratatlas_roitable mratInplane2analyze spm_coreg mroi

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end

if ~exist('GrpNames','var'),  GrpNames = {};  end
DO_EXPORT     = 0;
DO_RAW2IMG    = 0;
DO_COREGISTER = 1;
for N=1:2:length(varargin),
  switch lower(varargin{N}),
   case {'doexport','export','inplane2anatomy'}
    DO_EXPORT = varargin{N+1};
   case {'doraw2img','raw2img'}
    DO_RAW2IMG = varargin{N+1};
   case {'docoregister','coregister','coreg'}
    DO_COREGISTER = varargin{N+1};
  end
end




% initialize spm package, bofore any use of spm_xxx functions
spm_defaults;

INFO = mratatlas_defs;
% flags for spm_coreg()
INFO.defflags.sep      = [4 2];
INFO.defflags.params   = [0 0 0  0 0 0];
INFO.defflags.cost_fun = 'nmi';
INFO.defflags.fwhm     = [7 7];


fprintf('\n');
fprintf('ACCEPT LICENCE AGREEMENT OF RAT-ATLAS(AJ Schwartz,GlaxoSmithKline) AND SPM2.\n');
fprintf('For detail, see ratBrain_copyright_licence_*.doc, http://www.fil.ion.ucl.ac.uk/spm\n');
fprintf('\n');
pause(3);  % 3sec pause


% GET BASIC INFO
Ses = goto(Ses);
if isempty(GrpNames),  GrpNames = subGetUniqGroups(Ses);  end
if ischar(GrpNames),  GrpNames = { GrpNames };  end

% Run coregistration and extract ROIs from atlas
for N=1:length(GrpNames),
  fprintf('%s: %s %s ----------------------------------\n',mfilename,Ses.name,GrpNames{N});

  % export inplane anatomy
  if DO_EXPORT,
    mratInplane2analyze(Ses,GrpNames{N},INFO);
  end
  if DO_RAW2IMG,
    mratraw2img(Ses,GrpNames{N});
  end

  % coregister inplane anatomy to the reference
  matfile = sprintf('coreg_%s.mat',GrpNames{N});
  if DO_COREGISTER,
    % do coregistration
    M = subDoCoregister(Ses,GrpNames{N},INFO);
    fprintf('%s: saving conversion matrix ''M'' to ''%s''...',mfilename,matfile);
    save(matfile,'M');
    fprintf(' done.\n');
  else
    load(matfile,'M');
  end

  % assign structure number to voxels
  fprintf('%s: making aligned atlas...',mfilename);
  ATLAS = subGetAtlas(Ses,GrpNames{N},INFO,M);
  fprintf(' saving ''ATLAS'' to ''%s''...',matfile);
  save(matfile,'ATLAS','-append');
  fprintf(' done.\n');
  
  % create ROI structure
  fprintf('%s: making ROIs...',mfilename);
  RoiAtlas = subGetROI(Ses,GrpNames{N},INFO,ATLAS);
  fprintf('n=%d',length(RoiAtlas.roinames));
  datname = sprintf('Atlas_%s',GrpNames{N});
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
  fprintf('GRPP.grproi or GRP.%s.grproi as ''%s''.\n',GrpNames{N},datname);
  eval(sprintf('clear %s RoiAtlas;',datname));
end


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
    if strcmpi(ana1{1},ana2{1}) & ana1{2} == ana2{2} & length(ana1{3}) == length(ana2{3}),
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
function Finter = subCreateSPMWindow()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-Close any existing 'Interactive' 'Tag'ged windows
delete(spm_figure('FindWin','Interactive'))

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


return;


  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do coregistration
function M = subDoCoregister(Ses,GrpName,INFO)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize spm package, bofore any use of spm_xxx functions
spm_defaults;

% GET BASIC INFO
Ses = goto(Ses);
grp = getgrp(Ses,GrpName);
anap = getanap(Ses,grp);

% checks required files
reffile = fullfile(INFO.atlas_dir,INFO.reffile);
if ~exist(reffile,'file'),
  error('\nERROR %s: reference anatomy not found, ''%s''\n',mfilename,reffile);
end
atlasfile = fullfile(INFO.atlas_dir,INFO.atlasfile);
if ~exist(atlasfile,'file'),
  error('\nERROR %s: atlas not found, ''%s''\n',mfilename,atlasfile);
end
expfile = fullfile(pwd,sprintf('anat_%s.img',grp.name));
if ~exist(expfile,'file'),
  error('\nERROR %s: inplane-anatomy not found, ''%s''\n',mfilename,expfile);
end
% if spm_coreg_ui() called, it creates conversion matrix automatically.
% as result, cause the trouble when calling spm_vol()
[fp fr fe] = fileparts(expfile);
matfile = fullfile(fp,sprintf('%s.mat',fr));
if exist(matfile,'file'),  delete(matfile); end
clear fp fr fe matfile;



% read the reference and exported volume
VG = spm_vol(reffile);
VF = spm_vol(expfile);

% set optional flags for spm_coreg
flags = INFO.defflags;
if isfield(anap,'spm_coreg'),
  fnames = fieldnames(anap.spm_coreg);
  for N = 1:length(fnames),
    flags.(fnames{N}) = anap.spm_coreg.(fnames{N});
  end
  clear fnames;
end

% run coregistration
fprintf('%s: running spm_coreg()...',mfilename);
fprintf(' sep=[%g %g], cost_fun=''%s'', fwhm=[%g %g]\n',...
        flags.sep(1),flags.sep(2),flags.cost_fun,flags.fwhm(1),flags.fwhm(2));

hWin = subCreateSPMWindow();
x = spm_coreg(VG, VF, flags);
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
function ATLAS = subGetAtlas(Ses,GrpName,INFO,M);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize spm package, bofore any use of spm_xxx functions
spm_defaults;

% GET BASIC INFO
Ses = goto(Ses);
grp = getgrp(Ses,GrpName);
anap = getanap(Ses,grp);
ExpNo = grp.exps(1);
par = expgetpar(Ses,ExpNo);
atlasfile = fullfile(INFO.atlas_dir,INFO.atlasfile);
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
if isfield(Ses.expp(ExpNo),'imgcrop') & ~isempty(Ses.expp(ExpNo).imgcrop),
  IMGCROP = Ses.expp(ExpNo).imgcrop;
elseif isfield(grp,'imgcrop'),
  IMGCROP = grp.imgcrop;
else
  IMGCROP = [];
end
clear tcImg;
if ~isempty(IMGCROP),
  x = [0:IMGCROP(3)-1] + IMGCROP(1);
  y = [0:IMGCROP(4)-1] + IMGCROP(2);
else
  x = 1:par.pvpar.nx;
  y = 1:par.pvpar.ny;
end
if isfield(Ses.expp(ExpNo),'slicrop') & ~isempty(Ses.expp(ExpNo).slicrop),
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

if isfield(grp,'permute') & ~isempty(grp.permute),
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
for N = 1:3,
  idx = find(RCP(N,:) < 1 | RCP(N,:) > VA.dim(N));
  if isempty(idx),  continue;  end
  RCP(N,idx) = NaN;
end
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
ATLAS.roitable = mratatlas_roitable(fullfile(INFO.atlas_dir,INFO.tablefile));
if isempty(ATLAS.roitable),
  error('\nERROR %s:  invalid roi-table.\n',mfilename);
end


return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get Roi structure
function ROI = subGetROI(Ses,GrpName,INFO,ATLAS);
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
