function mratatlas2ana(varargin)
%MRATATLAS2ANA - Coregister atlas to the given anatomy image or session/group.
%  MRATATLAS2ANA(ANZFILE,...) coregisters the atlas to the given ANALIZE file.
%  Note that voxel resolution of the atlas is x10 bigger than the real and make
%  sure that the given ANALIZE file has also x10 voxel size.
%  MRATATLAS2ANA(SESSION,GRPNAME,...) coregisters the atlas to the given
%  session/group.  After the coregistration, ROI set will be generated.
%  In this case, functional images can be a subset of slices in
%  the brain, but the anatomical scan must be an whole head anatomy.
%
%  In any case, results (atlas, conversion matrix) will be saved into *_coreg_atlas.mat.
%
%  Supported options are
%    'permute' :  permutation vector for the input image
%    'flipdim' :  flipping dimension for the input image
%    'plot'    :  0|1, to plot a figure or not.
%    'makeroi' :  0|1, make ROIs for session/group.
%
%  TIPS:
%    To get better results, the input image should be in the similar
%    orientation like the atlas-image.  Options (permute/flipdim) will does
%    dimensional manipulation to the input image.
%
%  EXAMPLE :
%    % coregister the atlas to the given ANALIZE file.
%    mratatlas2ana('Y:\DataMatlab\Anatomy\rathead16T.img');
%    % coregister the atlas to the given session/group.
%    mratatlas2ana('ratRI1','es50a','permute',[1 3 2],'flipdim',[3]);
%
%  NOTE :
%    Voxel size of rat-atlas is 10 time of the real size.
%
%  VERSION :
%    0.90 07.02.09 YM  pre-release
%    0.91 09.02.09 YM  suppors (ses,grp,..) input.
%    0.92 10.02.09 YM  bug fix.
%
%  See also anz_read anz_write spm_coreg rat16T_coreg rat16T_roi

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end

if subIsAnzfile(varargin{1}),
  % called like mratatlas2ana(anzfile,...)
  IMGFILES = varargin{1};
  iOPT = 2;
else
  % called like mratatlas2ana(Ses,Grp,...)
  [IMGFILES Ses GrpName] = subAnaExport(varargin{1},varargin{2});
  iOPT = 3;
end
if ischar(IMGFILES),  IMGFILES = { IMGFILES };  end

% optional settings
DO_PERMUTE    = [];
DO_FLIPDIM    = [];
DO_COREGISTER = 1;
DO_PLOT       = 1;
DO_MAKE_ROI   = 1;
for N = iOPT:2:nargin,
  switch lower(varargin{N}),
   case {'coregister'}
    DO_COREGISTER = varargin{N+1};
   case {'permute'}
    DO_PERMUTE    = varargin{N+1};
   case {'flipdim'}
    DO_FLIPDIM    = varargin{N+1};
   case {'plot'}
    DO_PLOT       = varargin{N+1};
   case {'make roi','makeroi','roi'}
    DO_MAKE_ROI   = varargin{N+1};
  end
end
DO_PERMUTE = DO_PERMUTE(:)';
DO_FLIPDIM = DO_FLIPDIM(:)';


% initialize spm package, bofore any use of spm_xxx functions
spm_defaults;

INFO = mratatlas_defs;
INFO.permute = DO_PERMUTE;
INFO.flipdim = DO_FLIPDIM;
% flags for spm_coreg()
INFO.defflags.sep      = [4 2];
INFO.defflags.params   = [0 0 0  0 0 0];
INFO.defflags.cost_fun = 'nmi';
INFO.defflags.fwhm     = [7 7];


fprintf('\n');
fprintf('ACCEPT LICENCE AGREEMENT OF RAT-ATLAS(AJ Schwartz,GlaxoSmithKline) AND SPM5.\n');
fprintf('For detail, see ratBrain_copyright_licence_*.doc, http://www.fil.ion.ucl.ac.uk/spm\n');
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
      fprintf(' flipdim[%s].',deblank(sprintf('%d ',DO_PERMUTE)));
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
  
  
  [fp fr fe] = fileparts(expfile);
  % coregister inplane anatomy to the reference
  matfile = fullfile(fp,sprintf('%s_coreg_atlas.mat',fr));
  if DO_COREGISTER,
    % do coregistration
    M = subDoCoregister(expfile,INFO);
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
    fprintf(' %s: making ROIs...',mfilename);
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
function [IMGFILES Ses GrpName] = subAnaExport(Ses,Grp)
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
  if ~isimaging(tmpgrp),  continue;  end
  if isempty(tmpgrp.ana), continue;  end
  ananame{end+1} = sprintf('%s{%d}',tmpgrp.ana{1},tmpgrp.ana{2});
  anafile{end+1} = tmpgrp.ana{1};
  anaindx(end+1) = tmpgrp.ana{2};
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
  ANA = load(sprintf('%s.mat',anafile{N}),anafile{N});
  ANA = ANA.(anafile{N}){anaindx(N)};

  % scale to 0-32767 (int16+)
  fprintf(' scaling(int16+)...');
  ANA.dat = single(ANA.dat);
  ANA.dat(isnan(ANA.dat)) = 0;
  minv = min(ANA.dat(:));
  maxv = max(ANA.dat(:));
  ANA.dat = (ANA.dat - minv) / (maxv - minv);
  ANA.dat = ANA.dat * single(intmax('int16'));
  
  anzfile = fullfile(pwd,DIR_NAME,sprintf('%s_%s_%03d.hdr',Ses.name,anafile{N},anaindx(N)));
  imgdim = [4 size(ANA.dat,1) size(ANA.dat,2) size(ANA.dat,3) 1];
  pixdim = [3 ANA.ds(1) ANA.ds(2) ANA.ds(3)];
  fprintf('[%s]', deblank(sprintf('%g ',pixdim(2:4))));
  pixdim(2:4) = pixdim(2:4)*10;  % multiply 10 for rat-atlas
  fprintf('-->[%s]', deblank(sprintf('%g ',pixdim(2:4))));
  fprintf(' saving to ''%s''...',anzfile);
  hdr = hdr_init('dim',imgdim,'pixdim',pixdim,...
                 'datatype','int16','glmax',intmax('int16'),...
                 'descrip',sprintf('%s %s',Ses.name,ananame{N}));
  anz_write(anzfile,hdr,ANA.dat);

  clear ANA;
  fprintf(' done.\n');
  IMGFILES{end+1} = anzfile;
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
function M = subDoCoregister(expfile,INFO)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize spm package, bofore any use of spm_xxx functions
spm_defaults;

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
[fp fr fe] = fileparts(expfile);
matfile = fullfile(fp,sprintf('%s.mat',fr));
if exist(matfile,'file'),  delete(matfile); end
clear fp fr fe matfile;



% read the reference and exported volume
VG = spm_vol(reffile);
VF = spm_vol(expfile);

% set optional flags for spm_coreg
flags = INFO.defflags;


% run coregistration
fprintf(' %s: running spm_coreg()...',mfilename);
fprintf(' sep=[%g %g], cost_fun=''%s'', fwhm=[%g %g]\n',...
        flags.sep(1),flags.sep(2),flags.cost_fun,flags.fwhm(1),flags.fwhm(2));

hWin = subCreateSPMWindow();
x = spm_coreg(VG, VF, flags);
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
function ATLAS = subGetAtlas(expfile,INFO,M);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize spm package, bofore any use of spm_xxx functions
spm_defaults;

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
%xyzres = xyzres * 10;  % need to multiply 10 for the atlas


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
% undo permutation
if any(INFO.permute),
  strnum = ipermute(strnum,INFO.permute);
  xyzres = ipermute(xyzres,INFO.permute);
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

% select corresponding slices
if ~isempty(grp.ana),
  ATLAS.dat = ATLAS.dat(:,:,grp.ana{3});
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
[fp fref fe] = fileparts(reffile);
if isempty(hFig),
  [fp fexp fe] = fileparts(expfile);
  hFig = figure;
else
  figure(hFig);
end
set(hFig,'Name',sprintf('%s %s: %s',datestr(now,'HH:MM:SS'),mfilename,fexp));


[Vr Hr] = anz_read(reffile);
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
   tmpx = [1:size(tmpimg,1)]*xres;
   tmpy = [1:size(tmpimg,2)]*yres;
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
  tmpx = [1:size(tmpimg,1)]*xres;
  tmpy = [1:size(tmpimg,2)]*yres;
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
