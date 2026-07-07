function varargout = mn_spm2mat(SESSION,GRPNAME,SPMFLAGS,REALIGNED)
%MN_SPM2MAT - Converts SPM data into our data structre.
%  MN_SPM2MAT(SESSION,GRPNAME) concatinates .img files, creating time course,
%  then dumps it slice by slice and also updates anatomy file.
%  We need to do this "slice-by-slice" to avoid memory problem.
%  File names will be like, m02th1_mdeftinj_sl001.mat, ...m02th1_mdeftinj_slxxx.mat.
%  REALIGNED data will be stored in subdirectory of TC_SLICE_REALIGNED.
%  RAW data will be stored in subdirecroty of TC_SLICE_RAW.
%
%  MN_SPM2MAT(SESSION,GRPNAME,SPMFLAGS,REALIGNED)
%
%  EXAMPLE :
%    mn_spm2mat('m02th1','mdeftinj');  % interactive mode
%    mn_spm2mat('m02th1','mdeftinj',SPMFLAGS,1);   % non-interactive mode
%
%  NOTE :
%    THIS PROGRAM ASSUMES DATATYPE AS INT16.
%
%  VERSION :
%    0.90 02.06.2005 YM  pre-release.
%    0.91 03.06.2005 YM  also updates anatomy data.
%    0.92 08.06.2005 YM  creates subdirecoty for data, updates "tcimg.mat" too.
%    0.93 13.06.2005 YM  bug fix for d03se1.
%    0.94 15.06.2005 YM  adds the interactive mode.
%    0.95 20.06.2005 YM  sets "tcImg.dir.tcimgfile" correctly.
%    0.96 10.07.2005 YM  supports o02wu1/wx1.
%
%  See also HDR_READ, MNREALIGN, MN_TCSLICE_LOAD

if nargin < 2,  help mn_spm2mat; return;  end

if nargin < 3,  SPMFLAGS = [];  end
if nargin < 4,  REALIGNED = 1;  end

DIR_SPM = 'spm';

% CONTROL FLAGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DO_EXPORT_TCIMG    = 1;
DO_EXPORT_GRPTCIMG = 1;
DO_EXPORT_ANATOMY  = 1;
USE_SPM_RESLICE    = 0;


% ENTER THE INTERACTIVE MODE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 3,
  % use realigned data or not.
  c = input('Q: Export realigned data? Y/N[Y]: ','s');
  if isempty(c), c = 'Y'; end
  if c == 'y' | c == 'Y',
    REALIGNED = 1;
  else
    REALIGNED = 0;
  end
  % export grouped tcimg or not
  c = input('Q: Update grouped tcImg? Y/N[Y]: ','s');
  if isempty(c), c = 'Y'; end
  if c == 'y' | c == 'Y',
    DO_EXPORT_GRPTCIMG = 1;
  else
    DO_EXPORT_GRPTCIMG = 0;
  end
  % export anatomy
  c = input('Q: Update anatomy? Y/N[Y]: ','s');
  if isempty(c), c = 'Y'; end
  if c == 'y' | c == 'Y',
    DO_EXPORT_ANATOMY = 1;
  else
    DO_EXPORT_ANATOMY = 0;
  end
end
  
  
if REALIGNED > 0,
  DIR_TCSLICE = 'TC_SLICE_REALIGNED';
else
  DIR_TCSLICE = 'TC_SLICE_RAW';
end


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses  = goto(SESSION);
grp  = getgrp(SESSION,GRPNAME);
EXPS = grp.exps;

% Note that REALIGNED/RESLICED has a filename with 'r' prefix.
if REALIGNED,
  for iExp = length(EXPS):-1:1,
    ExpNo = EXPS(iExp);
    IMGFILES{iExp} = sprintf('%s/r%s_%03d.img',DIR_SPM,Ses.name,ExpNo);
  end
else
  for iExp = length(EXPS):-1:1,
    ExpNo = EXPS(iExp);
    IMGFILES{iExp} = sprintf('%s/%s_%03d.img',DIR_SPM,Ses.name,ExpNo);
  end
end

% DO AFFINE TRANSFORMATON IF REQUIRED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
afp = zeros(1,12);
% get control flags from Ses.anap.mnrealign
if isfield(Ses.anap,'mnrealign'),
  if isfield(Ses.anap.mnrealign,'xyztrans') & length(Ses.anap.mnrealign.xyztrans)==3,
    afp(1:3) = Ses.anap.mnrealign.xyztrans(:);
  end
  if isfield(Ses.anap.mnrealign,'xyzrotate') & length(Ses.anap.mnrealign.xyzrotate)==3,
    afp(4:6) = Ses.anap.mnrealign.xyzrotate(:)/360*2*pi;  % in radian
  end
end
if any(afp) & USE_SPM_RESLICE,
  if ~exist('defaults','var'), spm_defaults;  end
  fprintf(' %s: rotate/trans (n=%d)...',mfilename,length(IMGFILES));
  afp(7:9) = 1;    % scaling
  M = spm_matrix(afp);
  % flags for spm_reslice
  flags.mask       = 1;		% 1    as SPM-GUI default.
  flags.mean       = 0;		% 1    as SPM-GUI default.
  flags.interp     = 4;		% 4    as SPM-GUI default.  'inf' crashed,02.06.05YM.
  flags.which      = 2;		% 2    as SPM-GUI default.

  AFTFILES = {};
  % create mat files for affine transformation.
  % NOTE THAT spm_reslice make affine transf. relative to the first volume,
  % so adds a dummy file to perform rotation/translation by spm_reslice.
  for N = 1:length(IMGFILES),
    [fp,fr,fe] = fileparts(IMGFILES{N});
    imgfile = fullfile(fp,sprintf('AFT_%s.img',fr));
    hdrfile = fullfile(fp,sprintf('AFT_%s.hdr',fr));
    matfile = fullfile(fp,sprintf('AFT_%s.mat',fr));
    copyfile(fullfile(fp,sprintf('%s.img',fr)),imgfile);
    copyfile(fullfile(fp,sprintf('%s.hdr',fr)),hdrfile);
    save(matfile,'M');  % must be named as 'M', see spm_vol_ana.m for detail.
    AFTFILES{N+1} = imgfile;
  end
  copyfile(hdrfile,fullfile(fp,'AFT_dummy.hdr'));
  copyfile(imgfile,fullfile(fp,'AFT_dummy.img'));
  AFTFILES{1} = fullfile(fp,'AFT_dummy.img');
  afp(:) = 0;  afp(7:9) = 1;
  M = spm_matrix(afp);
  save(fullfile(fp,'AFT_dummy.mat'),'M');
  
  hWin = subCreateSPMWindow();
  drawnow; refresh;
  % do reslice
  spm_reslice(char(AFTFILES),flags);
  if ishandle(hWin),  close(hWin);  end
  % update filenames
  for N = 1:length(IMGFILES),
    [fp,fr,fe] = fileparts(AFTFILES{N+1});
    IMGFILES{N} = fullfile(fp,sprintf('r%s%s',fr,fe));
  end
  
  fprintf(' done.\n');
end




% Get dimension of .img file %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[fp,fr,fe] = fileparts(IMGFILES{1});
hdrfile = fullfile(fp,sprintf('%s.hdr',fr));	% like spm/m02th1_001.hdr
HDR  = hdr_read(hdrfile);
nx   = HDR.dime.dim(2);
ny   = HDR.dime.dim(3);
nz   = HDR.dime.dim(4);
nt   = length(EXPS);
xres = double(HDR.dime.pixdim(2));
yres = double(HDR.dime.pixdim(3));
zres = double(HDR.dime.pixdim(4));


% READING IMAGES, SUPPORTS ONLY INT16 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if REALIGNED,
  fprintf(' %s: reading REALIGNED images (n=%d)...',mfilename,length(IMGFILES));
else
  fprintf(' %s: reading ORIGINAL images (n=%d)...',mfilename,length(IMGFILES));
end
DAT = zeros(nx,ny,nz,nt,'int16');
for N = 1:length(IMGFILES),
  fid = fopen(IMGFILES{N},'rb');
  if fid < 0,
    fprintf(' %s ERROR: failed to open ''%s''.\n',mfilename,IMGFILES{N});
    keyboard
  end
  tmpimg = fread(fid,inf,'int16=>int16');
  fclose(fid);
  tmpimg = reshape(tmpimg,nx,ny,nz);
  if any(afp) & USE_SPM_RESLICE == 0,
    % -1 to match rot.diretion with that of spm_reslice.
    tmpimg = subImgRotate(tmpimg,afp(4:6)/pi*180*-1);
  end
  DAT(:,:,:,N) = tmpimg;
end
fprintf(' done.\n');



% CREATE 'tcImg' like structure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tcImg.session		= Ses.name;
tcImg.grpname		= grp.name;
tcImg.ExpNo			= grp.exps;
tcImg.slice         = 0;		% will be updated later

tcImg.dir.dname		= 'tcImg';
tcImg.dir.scantype	= 'MDEFT';
tcImg.dir.scanreco	= [];
tcImg.dir.imgfile	= [];
tcImg.dir.evtfile	= 'none';
tcImg.dir.matfile	= '';
tcImg.dir.tcimgfile	= '';


% DISPLAY
tcImg.dsp.func		= 'dspimg';
tcImg.dsp.args		= {};
tcImg.dsp.label		= {'Readout'; 'Phase Encode'; 'Slice'; 'Time Points'};
if isfield(grp,'imgcrop'),
  tcImg.usr.imgcrop   = grp.imgcrop;
else
  tcImg.usr.imgcrop   = [];	% useless
end
tcImg.dat           = [];
tcImg.ds			= [xres yres zres];
if isfield(grp,'imgtr'),
  tcImg.dx            = grp.imgtr;
else
  tcImg.dx           = 1;
end

% keep flags for spm functions, if given
tcImg.spm           = SPMFLAGS;


% DUMP TIME-COURSE IN EVERY SLICE. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if DO_EXPORT_TCIMG,
  if exist(DIR_TCSLICE,'dir') == 0,
    mkdir(DIR_TCSLICE);
  end
  fprintf(' %s: dumping to ''%s/%s_%s_slxxx.mat'' (xxx=001-%03d)...',...
          mfilename,DIR_TCSLICE,Ses.name,grp.name,nz);
  for iSlice = 1:nz,
    matfile = sprintf('%s/%s_%s_sl%03d.mat',DIR_TCSLICE,Ses.name,grp.name,iSlice);
    %fprintf(' %s: slice[%3d] --> %s...',mfilename, iSlice, matfile);
    tcImg.dir.tcimgfile = matfile;
    tcImg.slice = iSlice;
    tcImg.dat   = DAT(:,:,iSlice,:);
    save(matfile,'tcImg');
    %fprintf(' done.\n');
  end
  fprintf(' done.\n');
end



% NOW UPDATES MEAN IMAGE DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MDAT = [];
if DO_EXPORT_GRPTCIMG & ~strcmpi(grp.name,'mdeftinjir'),
  SigName = grp.name;
  fprintf(' %s: updating %s in tcimg.mat... ',mfilename,SigName);
  MDAT = squeeze(mean(DAT,4));
  if exist('tcimg.mat') ~= 0 & any(strcmpi(who('-file','tcimg.mat'),SigName)),
    tcImg = load('tcimg.mat',SigName);
    tcImg = tcImg.(SigName);
    tcImg.ds = [xres yres zres];
  end
  tcImg.ExpNo = grp.exps;
  tcImg.dir.tcimgfile = 'tcimg.mat';
  tcImg.dat   = MDAT;
  eval(sprintf('%s = tcImg;',SigName));
  if exist('tcimg.mat','file') ~= 0,
    save('tcimg.mat',SigName,'-append');
  else
    save('tcimg.mat',SigName);
  end
  fprintf(' done.\n');
end


% NOW UPDATES ANATOMY DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if DO_EXPORT_ANATOMY,
  %ADAT = squeeze(DAT(:,:,:,1));		% needs only the first one.
  if isempty(MDAT),
    MDAT = squeeze(mean(DAT,4));
    MDAT = int16(round(MDAT));
  end
  ADAT = MDAT;
  ananame = grp.ana{1};
  anascan = grp.ana{2};
  anafile = sprintf('%s.mat',ananame);

  fprintf(' %s: updating anatomy ''%s{%d}''...',mfilename,ananame,anascan);
  ANA = load(anafile,ananame);
  ANA = ANA.(ananame);
  ANA{anascan}.dat = ADAT;
  ANA{anascan}.ds  = [xres yres zres];
  eval(sprintf('%s = ANA;',ananame));
  save(anafile,ananame,'-append');
  fprintf(' done.\n');
end




return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to rotate image volume
function IMGVOL = subImgRotate(IMGVOL,XYZ_DEG)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if XYZ_DEG(1) ~= 0,
  for N = 1:size(IMGVOL,1),
    IMGVOL(N,:,:) = imrotate(IMGVOL(N,:,:),XYZ_DEG(1),'bicubic','crop');
  end
end
if XYZ_DEG(2) ~= 0,
  for N = 1:size(IMGVOL,2),
    IMGVOL(:,N,:) = imrotate(IMGVOL(:,N,:),XYZ_DEG(2),'bicubic','crop');
  end
end
if XYZ_DEG(3) ~= 0,
  for N = 1:size(IMGVOL,3),
    IMGVOL(:,:,N) = imrotate(IMGVOL(:,:,N),XYZ_DEG(3),'bicubic','crop');
  end
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


