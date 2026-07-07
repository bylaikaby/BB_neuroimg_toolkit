function mnrealign(SESSION,GRPNAME,SPMFLAGS)
%MNREALIGN - aligns image and save as time-course of each slices.
%  MNREALIGN(SESSION,GRPNAME) creates .hdr/.img files that SPM can handle,
%  then runs SPM_REALIGN and SPM_RESLICE.  SPM_RESLICE creates realigned and
%  resliced data with 'r' prefix.  Finally, those r-xxxx.img files will be
%  concatinated and the program saves data as time-couse of each slices.
%  For example, spm/m02th1_xxx.img/hdr will be created, then spm/rm02th1_x.img
%  as SPM generated files, then m02th1_slxxx.mat as time-course of slice xxx.
%
%  INFO :
%    SPM_REALIGN will take 15-30min for m02th1 (nexps=104).
%    SPM_RESLICE will take 15-20min for m025h1 (nexps=104).
%    Of course, time is dependent on "flags" for spm_xxx function...
%
%    !!! IMPORTANT  !!!!!!
%    In some cases (j008v2 for example), very bright regions outside brain cause
%    unexpected realignment. If images contain a water ball for normalization,
%    set masking threshold in the session file like...
%      ANAP.mnrealign.mask_thr = xxxxxx;
%    This value will be used as masking to peripheral regions.
%    !!!!!!!!!!!!!!!!!!!!!!
%
%  NOTE :
%    !!!! Several slices at begging and end may appear as uniform or nonsense
%    after processing by spm_reslice() due to outside of interpolation.
%    If you don't like, maybe flags.mask = 0 for spm_reslice() may be fine, 
%    although I never did it.
%
%  NOTE 2:
%    Control flags parameters can be set in the description file like...
%     ANAP.mnrealign.datname   = '2dseq';   % '2dseq' or 'tcImg'
%     ANAP.mnrealign.export    = 1;
%     ANAP.mnrealign.use_edges = 1;
%     ANAP.mnrealign.realign   = 1;
%     ANAP.mnrealign.reslice   = 1;
%     ANAP.mnrealign.confirm   = 1;
%     ANAP.mnrealign.spm_realign.quality = 0.75;
%
%  10.07.05 YM :
%    spm_reslice() may change image dimension and due to bug, its size is different
%    from .hdr file.... If the case, play arround imgcrop/slicrop until solved.
%
%  REQUIREMENT :
%    SPM2 package
%
%  VERSION :
%    0.90 02.06.05 YM  pre-release
%    0.91 02.06.05 YM  saves figures of the result.
%    0.92 03.06.05 YM  playing around with "flags" for spm functions.
%    0.93 03.06.05 YM  uses SPM's interactive window for progress watch.
%    0.94 08.06.05 YM  saves flags as text files.
%    0.95 13.06.05 YM  bug fix for d03se1.
%    0.96 10.07.05 YM  use Ses.anap.mrealign for function control.
%    0.97 08.09.05 YM  supports masking. (obsolete, use flags.pw of spm_realign).
%    0.98 13.09.05 YM  tests edge detection.
%    0.99 18.11.10 YM  supports SPM2/SPM5/SPM8.
%    1.00 20.02.11 YM  delete .mat to avoid conflict with mnimgloadavr().
%
%  See also MN_DAT2SPM, MN_SPM2MAT, SPM_REALIGN, SPM_RESLICE, MK_SPMMASK


if nargin < 2,  help mnrealign; return;  end
if nargin < 3,  SPMFLAGS = [];  end

% CONTROL FLAGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DO_EXPORT  = 1;    % create .hdr/.img file from 2dseq/tcImg.
USE_EDGES  = 0;    % use edges intead of images.
DO_REALIGN = 1;    % call spm_realign() to obtain alignment info as .mat file.
DO_TRANSONLY = 0;  % use internal routine (translation only)
DO_RESLICE = 1;    % call spm_reslice() to do image alignment.
DO_CONFIRM = 1;    % confirm the alignment, applying spm_realign to processed ones.
                   % so it take 2 times long.

% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);
EXPS = grp.exps;
ANAP = getanap(Ses,GRPNAME);

DIR_SPM = 'spm';


% get control flags from ANAP.mnrealign
if isfield(ANAP,'mnrealign'),
  if isfield(ANAP.mnrealign,'export') && ~isempty(ANAP.mnrealign.export),
    DO_EXPORT = ANAP.mnrealign.export;
  end
  if isfield(ANAP.mnrealign,'use_edges') && ~isempty(ANAP.mnrealign.use_edges),
    USE_EDGES = ANAP.mnrealign.use_edges;
  end
  if isfield(ANAP.mnrealign,'realign') && ~isempty(ANAP.mnrealign.realign),
    DO_REALIGN = ANAP.mnrealign.realign;
  end
  if isfield(ANAP.mnrealign,'reslice') && ~isempty(ANAP.mnrealign.reslice),
    DO_RESLICE = ANAP.mnrealign.reslice;
  end
  if isfield(ANAP.mnrealign,'confirm') && ~isempty(ANAP.mnrealign.confirm),
    DO_CONFIRM = ANAP.mnrealign.confirm;
  end
end


fprintf('%s %s BEGIN...SESSION=''%s'' GRPNAME=''%s''\n',...
        gettimestring,mfilename,Ses.name,grp.name);


% EXPORT "tcImg.dat" as .hdr/.img %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if DO_EXPORT,
  if isfield(grp,'mnimgloadavr') && ~isempty(grp.mnimgloadavr),
    datname = 'tcImg';
  elseif isfield(ANAP,'mnrealign') && isfield(ANAP.mnrealign,'datname') && ...
        ~isempty(ANAP.mnrealign.datname),
    datname = ANAP.mnrealign.datname;
  else
    datname = 'tcImg';
    %datname = '2dseq';
  end
  fprintf(' %s: mn_dat2spm() exporting %s for SPM...\n',gettimestring,datname);
  IMGFILES = mn_dat2spm(Ses,grp.name,datname,'verbose',0);
else
  fprintf(' %s: checking img/hdr...',gettimestring);
  for iExp = length(EXPS):-1:1,
    ExpNo = EXPS(iExp);
    IMGFILES{iExp} = sprintf('%s/%s_%03d.img',DIR_SPM,Ses.name,ExpNo);
    % ENSURE THAT .img is not "edged" one.
    % if .img is alredy 'edges' then copy back the original.
    bakfile = sprintf('%s.bak',IMGFILES{iExp});
    if exist(bakfile,'file'),
      fid = fopen(IMGFILES{iExp},'rb');
      tmpimg = fread(fid,inf,'int16=>int16');
      fclose(fid);
      if max(tmpimg(:)) == 1,
        copyfile(bakfile,IMGFILES{iExp},'f');
      end
    end
  end
  fprintf('done.\n');
end




% REPLACE IMAGE WITH THAT OF EDGES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if USE_EDGES > 0
  fprintf(' %s: detecting edges...',mfilename);
  for N = 1:length(IMGFILES),
    bakfile = sprintf('%s.bak',IMGFILES{N});
    copyfile(IMGFILES{N},bakfile,'f');
    hdr = hdr_read(sprintf('%s.hdr',IMGFILES{N}(1:end-4)));
    nx   = double(hdr.dime.dim(2));
    ny   = double(hdr.dime.dim(3));
    nz   = double(hdr.dime.dim(4));
    fid = fopen(IMGFILES{N},'rb');
    if fid < 0,
      fprintf(' %s ERROR: failed to open ''%s''.\n',mfilename,IMGFILES{N});
      keyboard
    end
    tmpimg = fread(fid,inf,'int16');
    fclose(fid);
    tmpimg = reshape(tmpimg,[nx ny nz]);
    for iZ = 1:nz,
      tmpimg(:,:,iZ) = edge(tmpimg(:,:,iZ),'canny');
    end
    fid = fopen(IMGFILES{N},'wb');
    fwrite(fid,tmpimg,'int16');
    fclose(fid);
  end
  fprintf(' done.\n');
end




% convert to a cell array to a string matrix for spm_xxxx functions
P = char(IMGFILES);



% CALL spm_defaults to avoid warning by spm_flip_analyze_images().
hWin = [];
if any(strcmpi(spm('ver'),{'SPM2','SPM5'})),
  spm_defaults;
else
  spm_get_defaults;
end


% CREATES spm-interactive window
if DO_REALIGN + DO_RESLICE + DO_CONFIRM > 0,
  hWin = subCreateSPMWindow();
  drawnow; refresh;
end

% read header to get spatial resolution
[fp,fr] = fileparts(IMGFILES{1});
HDR = hdr_read(fullfile(fp,sprintf('%s.hdr',fr)));
xres = double(HDR.dime.pixdim(2));
% yres = double(HDR.dime.pixdim(3));
% zres = double(HDR.dime.pixdim(4));

% SET FLAGS FOR SPM FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE:  fwhm: VoxelSize*2.5, sep: VoxelSize*2  gives reasonable alignment.
FLAGS.spm_realign.quality    = 0.75;	% 0.75 as SPM-GUI default.
%FLAGS.spm_realign.fwhm       = 2;		% 5    as SPM-GUI default.
%FLAGS.spm_realign.sep        = 1.6;		% 4    as SPM-GUI default.
FLAGS.spm_realign.fwhm       = xres*2.5;
FLAGS.spm_realign.sep        = xres*2;
FLAGS.spm_realign.rtm        = 0;		% 0    as SPM-GUI default.
FLAGS.spm_realign.PW         = '';	% ''   as SPM-GUI default.
FLAGS.spm_realign.interp     = 2;		% 2    as SPM-GUI default.
FLAGS.spm_reslice.mask       = 1;		% 1    as SPM-GUI default.
FLAGS.spm_reslice.mean       = 1;		% 1    as SPM-GUI default.
FLAGS.spm_reslice.interp     = 4;		% 4    as SPM-GUI default.  'inf' crashed,02.06.05YM.
FLAGS.spm_reslice.which      = 2;		% 2    as SPM-GUI default.
% UPDATE "FLAGS" WITH GIVEN INPUT "SPMFLAGS"
FLAGS = subUpdateFlags(Ses,ANAP,FLAGS,SPMFLAGS);


% CALL spm_realign %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if DO_REALIGN,

  % 10.02.11 YM:  now mnimgloadavr() use the different directory.
  % % first delete alignment data, if exist, to avoid conflict with mnimgloadavr().
  % for N = 1:size(P,1),
  %   [fp fr] = fileparts(deblank(P(N,:)));
  %   matfile = fullfile(fp,sprintf('%s.mat',fr));
  %   if exist(matfile,'file'),  delete(matfile);  end
  % end
  
  flags = FLAGS.spm_realign;
  fprintf(' %s: spm_realign() making alignment data (quality=%.2f,fwhm=%.2f,sep=%.2f)...',...
          gettimestring,flags.quality,flags.fwhm,flags.sep);
  spm_realign(P,flags);
  h = subPlotRealign(Ses,grp,IMGFILES,flags);
  figfile = sprintf('%s_%s_%s.fig',Ses.name,grp.name,mfilename);
  saveas(h,figfile);
  subSaveFlags(IMGFILES{1},'spm_realign',flags);
  fprintf(' done.\n');
elseif DO_TRANSONLY,
  fprintf(' %s: corr. data', gettimestring);
  subPosCorr(P);
end


% COPY-BACK ORIGINALS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if USE_EDGES,
  for N = 1:size(P,1),
    imgfile = deblank(P(N,:));
    bakfile = sprintf('%s.bak',imgfile);
    copyfile(bakfile,imgfile,'f');
  end
end


% CALL spm_reslice %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if DO_RESLICE,
  flags = FLAGS.spm_reslice;
  fprintf(' %s: spm_reslice() reslicing data...',gettimestring);
  spm_reslice(P,flags);
  subSaveFlags(IMGFILES{1},'spm_reslice',flags);
  fprintf(' done.\n');
end


% CALL spm_realign again to check %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if DO_CONFIRM,
  IMGFILES2 = {};
  for iExp = length(IMGFILES):-1:1,
    [fp,fr,fe] = fileparts(IMGFILES{iExp});
    IMGFILES2{iExp} = fullfile(fp,sprintf('r%s%s',fr,fe));
    % make a backup of .hdr since new spm_realign updates .hdr instead of .mat
    hdrfile = fullfile(fp,sprintf('r%s.hdr',fr));
    bakfile = fullfile(fp,sprintf('r%s.hdr.bak',fr));
    copyfile(hdrfile,bakfile,'f');
  end
  P2 = char(IMGFILES2);  % convert cell -> matrix
  flags = FLAGS.spm_realign;
  fprintf(' %s: spm_realign() confirming alignment (quality=%.2f,fwhm=%.2f,sep=%.2f)...',...
          gettimestring,flags.quality,flags.fwhm,flags.sep);
  spm_realign(P2,flags);
  h = subPlotRealign(Ses,grp,IMGFILES2,flags);
  set(h,'Name',sprintf('%s REALIGNED', get(h,'Name')));
  figfile = sprintf('%s_%s_%s_realigned.fig',Ses.name,grp.name,mfilename);
  saveas(h,figfile);
  fprintf(' done.\n');
  % delete SPM created .mat
  [fp,fr] = fileparts(IMGFILES2{1});
  tmppat = fullfile(fp,sprintf('%s*.mat',fr(1:3)));
  delete(tmppat);
  % get the original .hdr from .bak
  for iExp = 1:length(IMGFILES2),
    [fp fr] = fileparts(IMGFILES2{iExp});
    hdrfile = fullfile(fp,sprintf('%s.hdr',fr));
    bakfile = fullfile(fp,sprintf('%s.hdr.bak',fr));
    copyfile(bakfile,hdrfile,'f');
  end
  % clear variables
  clear P2 IMGFILES2;
end


if ishandle(hWin),  close(hWin);  end


% CONCATINATE PROCESSED IMAGES AND DUMP SLICE BY SLICE. %%%%%%%%%%%%%%%%%%%%%%%
fprintf(' %s: mn_spm2mat() importing raw *.img to matfile...\n',gettimestring);
mn_spm2mat(Ses,grp.name,FLAGS,0);
fprintf(' %s: mn_spm2mat() importing resliced r*.img to matfile...\n',gettimestring);
mn_spm2mat(Ses,grp.name,FLAGS,1);



fprintf('%s %s END.\n',gettimestring,mfilename);

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to update flags
function flags = subUpdateFlags(Ses,ANAP,flags,SPMFLAGS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isfield(SPMFLAGS,'spm_realign'),
  fnames = fieldnames(SPMFLAGS.spm_realign);
  for N = 1:length(fnames),
    flags.spm_realign.(fnames{N}) = SPMFLAGS.spm_realign.(fnames{N});
  end
end
if isfield(SPMFLAGS,'spm_reslice'),
  fnames = fieldnames(SPMFLAGS.spm_reslice);
  for N = 1:length(fnames),
    flags.spm_reslice.(fnames{N}) = SPMFLAGS.spm_reslice.(fnames{N});
  end
end
if isfield(ANAP,'mnrealign'),
  if isfield(ANAP.mnrealign,'spm_realign'),
    fnames = fieldnames(ANAP.mnrealign.spm_realign);
    for N = 1:length(fnames),
      flags.spm_realign.(fnames{N}) = ANAP.mnrealign.spm_realign.(fnames{N});
    end
  end
  if isfield(ANAP.mnrealign,'spm_reslice'),
    fnames = fieldnames(ANAP.mnrealign.spm_reslice);
    for N = 1:length(fnames),
      flags.spm_reslice.(fnames{N}) = ANAP.mnrealign.spm_reslice.(fnames{N});
    end
  end
end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to save flags
function subSaveFlags(IMGFILE,FUNCNAME,FLAGS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fields = fieldnames(FLAGS);
[fp,fr,fe] = fileparts(IMGFILE);
txtfile = fullfile(fp,sprintf('%s_%s.txt',mfilename,FUNCNAME));
fid = fopen(txtfile,'wt');
fprintf(fid,'%% %s() flags\n',FUNCNAME);
for N = 1:length(fields),
  f = fields{N};
  v = FLAGS.(f);
  fprintf(fid,'flags.%s =',f);
  if ischar(v),
    fprintf(fid,' ''%s''',v);
  elseif isinteger(v),
    if length(v) > 1,  fprintf(' [');  end
    for K = 1:length(v),
      fprintf(fid,' %d',v(K));
    end
    if length(v) > 1,  fprintf(' ]');  end
  elseif isfloat(v),
    if length(v) > 1,  fprintf(' [');  end
    for K = 1:length(v),
      fprintf(fid,' %f',v(K));
    end
    if length(v) > 1,  fprintf(' ]');  end
  end
  fprintf(fid,';\n');
end
fclose(fid);

  
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot results of spm_realign().
function H = subPlotRealign(Ses,grp,IMGFILES,flags)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[fd,fr] = fileparts(IMGFILES{1});
txtfile = fullfile(fd,sprintf('rp_%s.txt',fr));
fid = fopen(txtfile,'rt');
ALIGN = fscanf(fid,'%g',[6 length(IMGFILES)]);
fclose(fid);

% get experiment numbers from IMGFILES, because the order is not correct in time.
%T = [1:size(ALIGN,2)];
T = zeros(1,length(IMGFILES));
for N = 1:length(IMGFILES),
  [fp,fr] = fileparts(IMGFILES{N});
  ExpNo = str2double(fr(strfind(fr,'_')+1:end));
  %T(N) = find(grp.exps == ExpNo);
  T(N) = ExpNo;
end


tmptitle = sprintf('%s: %s %s',mfilename,Ses.name,grp.name);
H = figure('Name',tmptitle);
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName',  'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');


inftxt = sprintf('quality=%.2f fwhm=%.1f sep=%.1f rtm=%d PW=''%s'' interp=%d',...
                 flags.quality,flags.fwhm,flags.sep,flags.rtm,flags.PW,flags.interp);

subplot(2,1,1);
plot(T,ALIGN(1,:),'color','b');  grid on; hold on;
plot(T,ALIGN(2,:),'color','k');
plot(T,ALIGN(3,:),'color','r');
legend('x','y','z');
set(gca,'xlim',[min(T) max(T)]);
xlabel('Experiment Number');
ylabel('mm');
title(sprintf('%s %s: Translation',Ses.name,grp.name));
text(0.02,0.07,strrep(inftxt,'_','\_'),'units','normalized','fontname','Comic Sans MS')

subplot(2,1,2)
plot(T,ALIGN(4,:)*180/pi,'color','b');  grid on; hold on;
plot(T,ALIGN(5,:)*180/pi,'color','k');
plot(T,ALIGN(6,:)*180/pi,'color','r');
legend('pitch','roll','yaw');
set(gca,'xlim',[min(T) max(T)]);
xlabel('Experiment Number');
ylabel('degrees');
title(sprintf('%s %s: Rotation',Ses.name,grp.name));
text(0.02,0.07,strrep(inftxt,'_','\_'),'units','normalized','fontname','Comic Sans MS')


return;




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





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
% apply corr analysis to detect translational movement
function subPosCorr(P)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55

imgfile = deblank(P(1,:));
hdr = hdr_read(sprintf('%s.hdr',imgfile(1:end-4)));
nx = double(hdr.dime.dim(2));
ny = double(hdr.dime.dim(3));
nz = double(hdr.dime.dim(4));
xres = double(hdr.dime.pixdim(2));
yres = double(hdr.dime.pixdim(3));
zres = double(hdr.dime.pixdim(4));
fid = fopen(imgfile,'rb');
refvol = reshape(fread(fid,inf,'int16'),[nx ny nz]);
fclose(fid);

xsli = 1:round(nx/10):nx;  xsli = unique(xsli(2:end-1));
ysli = 1:round(ny/10):ny;  ysli = unique(ysli(2:end-1));
zsli = 1:round(nz/10):nz;  zsli = unique(zsli(2:end-1));

xyzpry = zeros(size(P,1),6);
M = zeros(4,4);
M(1,1) = xres;
M(2,2) = yres;
M(3,3) = zres;
M(4,4) = 1;


for N = 2:size(P,1),
  imgfile = deblank(P(N,:));
  fid = fopen(imgfile,'rb');
  curvol = reshape(fread(fid,inf,'int16'),[nx ny nz]);
  fclose(fid);

  % along X
  csli = subSliCorr(xsli,refvol,curvol,1);
  xyzpry(N,1) = mean(csli-xsli)*xres;
  M(1,4) = -xyzpry(N,1);

  % along Y
  csli = subSliCorr(ysli,refvol,curvol,2);
  xyzpry(N,2) = mean(csli-ysli)*yres;
  M(2,4) = -xyzpry(N,2);

  % along Z
  csli = subSliCorr(zsli,refvol,curvol,3);
  xyzpry(N,3) = mean(csli-zsli)*zres;
  M(3,4) = -xyzpry(N,3);

  mat = -M;  mat(4,4) = 1;
  matfile = sprintf('%s.mat',imgfile(1:end-4));
  save(matfile,'M','mat');
end


xyzpry

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function csli = subSliCorr(SLI,refvol,curvol,DIM)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

csli = [];
for iSli = 1:length(SLI),
  if DIM == 1,
    dat0 = refvol(SLI(iSli),:,:);
  elseif DIM == 2,
    dat0 = refvol(:,SLI(iSli),:);
  else
    dat0 = refvol(:,:,SLI(iSli));
  end
  tmpcorr = zeros(1,size(curvol,DIM));
  range = (-10:10) + SLI(iSli);
  for K = 1:length(range),
    x = range(K);
    if x > 0 && x <= length(tmpcorr),
      if DIM == 1,
        dat1 = curvol(x,:,:);
      elseif DIM == 2,
        dat1 = curvol(:,x,:);
      else
        dat1 = curvol(:,:,x);
      end
      tmpcorr(x) = corr(dat0(:),dat1(:));
    end
  end
  [maxv maxi] = max(tmpcorr);
  csli(iSli) = maxi;
end
