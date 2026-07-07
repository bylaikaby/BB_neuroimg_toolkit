function exprealign(SESSION,ExpNo,SPMFLAGS)
%EXPREALIGN - aligns image and save as time-course of each slices.
%  EXPREALIGN(SESSION,ExpNo) creates .hdr/.img files that SPM can handle,
%  then runs SPM_REALIGN and SPM_RESLICE.  SPM_RESLICE creates realigned and
%  resliced data with 'r' prefix.  Finally, those r-xxxx.img files will be
%  concatinated and the program saves data as time-couse of each slices.
%  For example, spm/m02th1_xxx.img/hdr will be created, then spm/rm02th1_x.img
%  as SPM generated files, then m02th1_slxxx.mat as time-course of slice xxx.
%
%  NOTE :
%    !!!! Several slices at edges may appear as uniform or nonsense
%    after processing by spm_reslice() due to outside of interpolation.
%    If you don't like, maybe flags.mask = 0 for spm_reslice() may be fine, 
%    although I never did it.
%
%  NOTE 2:
%    Control flags parameters can be set in the description file like...
%     %ANAP.exprealign.datname   = 'tcImg';   % '2dseq' or 'tcImg'
%     ANAP.exprealign.preproc   = 1;  % takes alignment of each slices
%     ANAP.exprealign.export    = 1;
%     ANAP.exprealign.use_edges = 0;
%     ANAP.exprealign.realign   = 1;
%     ANAP.exprealign.reslice   = 1;
%     ANAP.exprealign.confirm   = 1;
%     ANAP.exprealign.spm_realign.quality = 0.75;
%
%  10.07.05 YM :
%    spm_reslice() may change image dimension and due to bug, its size is different
%    from .hdr file.... If the case, play arround imgcrop/slicrop until solved.
%
%  17.04.07 YM :
%    SPM5 now saves realignment into '.hdr', not '.mat'....
%
%
%  REQUIREMENT :
%    SPM2 package
%
%  VERSION :
%    0.90 13.03.07 YM  pre-release, modified from mnrealign.
%    0.91 19.04.07 YM  supports 'reference-volume' by correct trials.
%
%  See also SESREALIGN SESSPMMASK TCIMG2SPM SPM2TCIMG SPM_REALIGN SPM_RESLICE ANZ_READ


if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end
if nargin < 3,  SPMFLAGS = [];  end

% CONTROL FLAGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DO_PREPROC = 0;    % does some preprocessing to improve motion correction
DO_EXPORT  = 1;    % create .hdr/.img file from 2dseq/tcImg.
USE_EDGES  = 0;    % use edges intead of images.
DO_REALIGN = 1;    % call spm_realign() to obtain alignment info as .mat file.
DO_TRANSONLY = 0;  % use internal routine (translation only)
DO_RESLICE = 1;    % call spm_reslice() to do image alignment.
DO_CONFIRM = 1;    % confirm the alignment, applying spm_realign to processed ones.
                   % so it take 2 times long.

% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);
anap = getanap(Ses,ExpNo);
par = expgetpar(Ses,ExpNo);
DIR_SPM = 'spm';


% get control flags from anap.exprealign
if isfield(anap,'exprealign'),
  if isfield(anap.exprealign,'preproc') & ~isempty(anap.exprealign.preproc),
    DO_PREPROC = anap.exprealign.preproc;
  end
  if isfield(anap.exprealign,'export') & ~isempty(anap.exprealign.export),
    DO_EXPORT = anap.exprealign.export;
  end
  if isfield(anap.exprealign,'use_edges') & ~isempty(anap.exprealign.use_edges),
    USE_EDGES = anap.exprealign.use_edges;
  end
  if isfield(anap.exprealign,'realign') & ~isempty(anap.exprealign.realign),
    DO_REALIGN = anap.exprealign.realign;
  end
  if isfield(anap.exprealign,'transonly') & ~isempty(anap.exprealign.transonly),
    DO_TRANSONLY = anap.exprealign.transonly;
  end
  if isfield(anap.exprealign,'reslice') & ~isempty(anap.exprealign.reslice),
    DO_RESLICE = anap.exprealign.reslice;
  end
  if isfield(anap.exprealign,'confirm') & ~isempty(anap.exprealign.confirm),
    DO_CONFIRM = anap.exprealign.confirm;
  end
end

if DO_TRANSONLY,   DO_REALIGN = 0;  end



fprintf('%s %s BEGIN...SESSION=''%s'' ExpNo=%d\n',...
        gettimestring,mfilename,Ses.name,ExpNo);


% EXPORT "tcImg.dat" as .hdr/.img %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if DO_EXPORT,
  if isfield(anap,'exprealign') & isfield(anap.exprealign,'datname') & ...
        ~isempty(anap.exprealign.datname),
    datname = anap.exprealign.datname;
  else
    datname = 'tcImg';
    %datname = '2dseq';
  end
  fprintf(' %s: tcimg2spm() exporting %s for SPM...\n',gettimestring,datname);
  matfile = catfilename(Ses,ExpNo,'tcImg');
  bakfile = sprintf('%s.bak',matfile);
  if ~exist(bakfile,'file'),
    copyfile(matfile,bakfile,'f');  % copy as backup
  else
    copyfile(bakfile,matfile,'f');  % recover from backup
  end
  IMGFILES = tcimg2spm(Ses,ExpNo,'ExportAs3D',1,'SaveDir',DIR_SPM);
  % IF 'awake' stuff, then set the reference volume as a correct trial
  if isawake(Ses,ExpNo),
    srcfile = fullfile(DIR_SPM,sprintf('%s_%s_refvolume.img',Ses.name,grp.name));
    if ~exist(srcfile,'file') | ExpNo == grp.exps(1),
      fprintf(' exporting ''reference volume'' from corrct trials...');
      subExportRefVolume(Ses,grp.exps(1),srcfile);
    end
    copyfile(srcfile,IMGFILES{1},'f');
  else
    % SHOULD BE ALIGNED TO THE FIRST VOLUME OF THE FIRST EXP.
    if ExpNo ~= grp.exps(1),
      srcfile = fullfile(DIR_SPM,sprintf('%s_%03d_00001.img',Ses.name,grp.exps(1)));
      copyfile(srcfile,IMGFILES{1},'f');
    end
  end
else
  fprintf(' %s: checking img/hdr...',gettimestring);
  [fp,fr,fe] = catfilename(Ses,ExpNo,'mat');
  for N = 1:par.pvpar.nt,
    IMGFILES{N} = fullfile(DIR_SPM,sprintf('%s_%05d.img',fr,N));
    % ENSURE THAT .img is not "edged" one.
    % if .img is alredy 'edges' then copy back the original.
    bakfile = sprintf('%s.bak',IMGFILES{N});
    if exist(bakfile,'file'),
      %fid = fopen(IMGFILES{N},'rb');
      %tmpimg = fread(fid,inf,'int16=>int16');
      %fclose(fid);
      tmpimg = anz_read(IMGFILES{N});
      if max(tmpimg(:)) == 1,
        copyfile(bakfile,IMGFILES{N},'f');
      end
    end
  end
  fprintf('done.\n');
end



if DO_PREPROC > 0,
  fprintf(' %s: preproc...',mfilename);
% 30.10.07 YM: alignment by centroid is not good at all, if I use image itself.
%   refimg  = anz_read(IMGFILES{1});
%   refmass = subGetSliceCentroid(refimg);
%   for N = 2:length(IMGFILES),
%     [tmpimg tmphdr]  = anz_read(IMGFILES{N});
%     [tmpimg tmpmass] = subAlignSliceCentroid(tmpimg,refmass);
%     if any(round(tmpmass-refmass)),
%       keyboard
%     end
%     anz_write(IMGFILES{N},tmphdr,tmpimg);
%   end
%   clear refimg tmpimg refmass tmpmass;

  refimg = anz_read(IMGFILES{1});
  for N = 2:length(IMGFILES),
    [tmpimg tmphdr] = anz_read(IMGFILES{N});
    tmpimg = subAlignSliceCorr(tmpimg,refimg);
    anz_write(IMGFILES{N},tmphdr,tmpimg);
  end
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
    %fid = fopen(IMGFILES{N},'rb');
    %if fid < 0,
    %  fprintf(' %s ERROR: failed to open ''%s''.\n',mfilename,IMGFILES{N});
    %  keyboard
    %end
    %tmpimg = fread(fid,inf,'int16');
    %fclose(fid);
    %tmpimg = reshape(tmpimg,[nx ny nz]);
    tmpimg = reshape(anz_read(IMGFILES{N}),[nx ny nz]);
    for iZ = 1:nz,
      tmpimg(:,:,iZ) = edge(tmpimg(:,:,iZ),'canny');
    end
    fid = fopen(IMGFILES{N},'wb');
    %fwrite(fid,tmpimg,'int16');
    fwrite(fid,tmpimg,class(tmpimg));
    fclose(fid);
  end
  fprintf(' done.\n');
end




% convert to a cell array to a string matrix for spm_xxxx functions
P = char(IMGFILES);



% CALL spm_defaults to avoid warning by spm_flip_analyze_images().
hWin = [];
spm_defaults;

% CREATES spm-interactive window
if DO_REALIGN + DO_RESLICE + DO_CONFIRM > 0,
  hWin = subCreateSPMWindow();
  drawnow; refresh;
end

% read header to get spatial resolution
[fp,fr,fe] = fileparts(IMGFILES{1});
HDR = hdr_read(fullfile(fp,sprintf('%s.hdr',fr)));
xres = double(HDR.dime.pixdim(2));
% yres = double(HDR.dime.pixdim(3));
% zres = double(HDR.dime.pixdim(4));

% SET FLAGS FOR SPM FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE:  fwhm: VoxelSize*2.5, sep: VoxelSize*2  gives reasonable alignment.
FLAGS.spm_realign.quality    = 0.75;	% 0.75 as SPM-GUI default.
%FLAGS.spm_realign.fwhm       = 2;		% 5    as SPM-GUI default.
%FLAGS.spm_realign.sep        = 1.6;	% 4    as SPM-GUI default.
FLAGS.spm_realign.fwhm       = xres*2.5;
FLAGS.spm_realign.sep        = xres*2;
FLAGS.spm_realign.rtm        = 0;		% 0    as SPM-GUI default.
FLAGS.spm_realign.PW         = '';	    % ''   as SPM-GUI default.
FLAGS.spm_realign.interp     = 2;		% 2    as SPM-GUI default.
FLAGS.spm_reslice.mask       = 1;		% 1    as SPM-GUI default.
FLAGS.spm_reslice.mean       = 1;		% 1    as SPM-GUI default.
FLAGS.spm_reslice.interp     = 4;		% 4    as SPM-GUI default.  'inf' crashed,02.06.05YM.
FLAGS.spm_reslice.which      = 2;		% 2    as SPM-GUI default.
% UPDATE "FLAGS" WITH GIVEN INPUT "SPMFLAGS"
FLAGS = subUpdateFlags(anap,FLAGS,SPMFLAGS);


% CALL spm_realign %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if DO_REALIGN,
  flags = FLAGS.spm_realign;
  fprintf(' %s: spm_realign() making alignment data (quality=%.2f,fwhm=%.2f,sep=%.2f)...',...
          gettimestring,flags.quality,flags.fwhm,flags.sep);
  spm_realign(P,flags);
  h = subPlotRealign(Ses,ExpNo,IMGFILES,flags);
  figfile = fullfile(DIR_SPM,sprintf('%s_exp%03d_%s.fig',Ses.name,ExpNo,mfilename));
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
  for N = length(IMGFILES):-1:1,
    [fp,fr,fe] = fileparts(IMGFILES{N});
    IMGFILES2{N} = fullfile(fp,sprintf('r%s%s',fr,fe));
  end
  P2 = char(IMGFILES2);  % convert cell -> matrix
  flags = FLAGS.spm_realign;
  fprintf(' %s: spm_realign() confirming alignment (quality=%.2f,fwhm=%.2f,sep=%.2f)...',...
          gettimestring,flags.quality,flags.fwhm,flags.sep);
  spm_realign(P2,flags);
  h = subPlotRealign(Ses,ExpNo,IMGFILES2,flags);
  set(h,'Name',sprintf('%s REALIGNED', get(h,'Name')));
  figfile = fullfile(DIR_SPM,sprintf('%s_exp%03d_%s_realigned.fig',Ses.name,ExpNo,mfilename));
  saveas(h,figfile);
  fprintf(' done.\n');
  % delete un-used files
  [fp,fr,fe] = fileparts(IMGFILES2{1});
  tmppat = fullfile(fp,sprintf('%s*.mat',fr(1:3)));
  delete(tmppat);
  % clear variables
  clear P2 IMGFILES2;
end


if ishandle(hWin),  close(hWin);  end
drawnow;


% CONCATINATE PROCESSED IMAGES AND DUMP SLICE BY SLICE. %%%%%%%%%%%%%%%%%%%%%%%
fprintf(' %s: spm2tcimg() importing r*.img to matfile...\n',gettimestring);
tcImg = spm2tcimg(Ses,ExpNo);
if ~isfield(tcImg,'centroid') | isempty(tcImg.centroid),
  tcImg.centroid = mcentroid(tcImg.dat,tcImg.ds);
end
tcImg.spm = FLAGS;
save(catfilename(Ses,ExpNo,'tcImg'),'tcImg');
clear tcImg;



fprintf('%s %s END.\n',gettimestring,mfilename);

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to update flags
function flags = subUpdateFlags(anap,flags,SPMFLAGS)
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
if isfield(anap,'exprealign'),
  if isfield(anap.exprealign,'spm_realign'),
    fnames = fieldnames(anap.exprealign.spm_realign);
    for N = 1:length(fnames),
      flags.spm_realign.(fnames{N}) = anap.exprealign.spm_realign.(fnames{N});
    end
  end
  if isfield(anap.exprealign,'spm_reslice'),
    fnames = fieldnames(anap.exprealign.spm_reslice);
    for N = 1:length(fnames),
      flags.spm_reslice.(fnames{N}) = anap.exprealign.spm_reslice.(fnames{N});
    end
  end
end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to save flags
function flags = subSaveFlags(IMGFILE,FUNCNAME,FLAGS)
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
% SUBFUNCTION to export the reference volume
function subExportRefVolume(Ses,ExpNo,reffile)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% sort by 'trial'
tcImg = sigload(Ses,ExpNo,'tcImg.bak');  % sure to load un-realigned data
grp = getgrp(Ses,ExpNo);
if isfield(grp,'daqver') & grp.daqver >= 2,
  spar  = getsortpars(Ses,ExpNo);
  tcImg = sigsort(tcImg,spar.trial,[],[],0,0);
  if iscell(tcImg),  tcImg = tcImg{1};  end
end

% set NaN as 0
tmpidx = find(isnan(tcImg.dat(:)));
tcImg.dat(tmpidx) = 0;
% average the first 2 volumes of each trials
tmpimg = mean(tcImg.dat(:,:,:,1:min(2,size(tcImg.dat,4)),:),4);
szimg  = size(tmpimg);
if length(szimg) == 5,
  tmpimg = reshape(tmpimg,[prod(szimg(1:3)) szimg(5)]);
else
  tmpimg = reshape(tmpimg,[prod(szimg(1:3)) 1]);
end
mimg   = mean(tmpimg,2);

% pick up the best one
rval = [];
for N = 1:size(tmpimg,2),
  tmpr = corrcoef(tmpimg(:,N),mimg(:));
  rval(N) = tmpr(1,2);
end
[tmpv tmpi] = max(rval);
refvol = reshape(tmpimg(:,tmpi(1)),szimg(1:3));


dtype  = class(refvol);
pixdim = [3 tcImg.ds(1) tcImg.ds(2) tcImg.ds(3)];
dim    = [4 szimg(1) szimg(2) szimg(3) 1];

[fp,fr,fe] = fileparts(reffile);
imgfile = fullfile(fp,sprintf('%s.img',fr));
hdrfile = fullfile(fp,sprintf('%s.hdr',fr));
% write out .img
fid = fopen(imgfile,'wb');
fwrite(fid,refvol,dtype);
fclose(fid);
% write out .hdr
hdr = hdr_init('dim',dim,'datatype',dtype,'pixdim',pixdim,'glmax',intmax('int16'));
hdr_write(hdrfile,hdr);

  
return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot results of spm_realign().
function H = subPlotRealign(Ses,ExpNo,IMGFILES,flags)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[fd,fr,fe] = fileparts(IMGFILES{1});
txtfile = fullfile(fd,sprintf('rp_%s.txt',fr));
fid = fopen(txtfile,'rt');
ALIGN = fscanf(fid,'%g',[6 length(IMGFILES)]);
fclose(fid);

% get experiment numbers from IMGFILES, because the order is not correct in time.
%T = [1:size(ALIGN,2)];
T = [1:length(IMGFILES)];


tmptitle = sprintf('%s: %s ExpNo=%d',mfilename,Ses.name,ExpNo);
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
set(gca,'xlim',[0 max(T)]);
xlabel('Volume Number');
ylabel('mm');
title(sprintf('%s ExpNo=%d: Translation',Ses.name,ExpNo));
text(0.02,0.07,strrep(inftxt,'_','\_'),'units','normalized','fontname','Comic Sans MS')

subplot(2,1,2)
plot(T,ALIGN(4,:)*180/pi,'color','b');  grid on; hold on;
plot(T,ALIGN(5,:)*180/pi,'color','k');
plot(T,ALIGN(6,:)*180/pi,'color','r');
legend('pitch','roll','yaw');
set(gca,'xlim',[0 max(T)]);
xlabel('Volume Number');
ylabel('degrees');
title(sprintf('%s ExpNo=%d: Rotation',Ses.name,ExpNo));
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
%fid = fopen(imgfile,'rb');
%refvol = reshape(fread(fid,inf,'int16'),[nx ny nz]);
%fclose(fid);
refvol = anz_read(imgfile);

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
  %fid = fopen(imgfile,'rb');
  %curvol = reshape(fread(fid,inf,'int16'),[nx ny nz]);
  %fclose(fid);
  curvol = reshape(anz_read(imgfile),[nx ny nz]);

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
  range = [-10:10] + SLI(iSli);
  for K = 1:length(range),
    x = range(K);
    if x > 0 & x <= length(tmpcorr),
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function centroids = subGetSliceCentroid(IMGVOL)

NX = size(IMGVOL,1);
NY = size(IMGVOL,2);
  
tmpX = reshape([1:NX],[NX,1,1]);
tmpX = repmat(tmpX,[1,NY]);

tmpY = reshape([1:NY],[1,NY,1]);
tmpY = repmat(tmpY,[NX,1]);

for Z=1:size(IMGVOL,3),
  tmpdat = IMGVOL(:,:,Z);
  sumXY  = sum(tmpdat(:));
  x = sum(tmpdat(:).*tmpX(:)) / sumXY;
  y = sum(tmpdat(:).*tmpY(:)) / sumXY;
  centroids(Z,:) = [x y];
end

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [NEWVOL imgmass] = subAlignSliceCentroid(IMGVOL,REFMASS)

imgmass = subGetSliceCentroid(IMGVOL);
movmass = round(REFMASS - imgmass);

NEWVOL = zeros(size(IMGVOL),class(IMGVOL));

for Z=1:size(IMGVOL,3),
  if movmass(Z,1) == 0 && movmass(Z,2) == 0,
    NEWVOL(:,:,Z) = IMGVOL(:,:,Z);
    continue;
  end
  tmpx1 = [1:size(IMGVOL,1)];
  tmpx2 = [1:size(IMGVOL,1)] + movmass(Z,1);
  tmpidx = find(tmpx2 > 0 & tmpx2 < size(IMGVOL,1));
  tmpx1 = tmpx1(tmpidx);
  tmpx2 = tmpx2(tmpidx);
  
  tmpy1 = [1:size(IMGVOL,2)];
  tmpy2 = [1:size(IMGVOL,2)] + movmass(Z,2);
  tmpidx = find(tmpy2 > 0 & tmpy2 < size(IMGVOL,2));
  tmpy1 = tmpy1(tmpidx);
  tmpy2 = tmpy2(tmpidx);
  
  NEWVOL(tmpx1,tmpy1,Z) = IMGVOL(tmpx2,tmpy2,Z);
end
  
  
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function NEWVOL = subAlignSliceCorr(IMGVOL,REFVOL)

nx = size(IMGVOL,1);
ny = size(IMGVOL,2);

xsli = 1:round(nx/10):nx;  xsli = unique(xsli(2:end-1));
ysli = 1:round(ny/10):ny;  ysli = unique(ysli(2:end-1));

NEWVOL = zeros(size(IMGVOL),class(IMGVOL));

for Z = 1:size(IMGVOL,3),
  refimg = REFVOL(:,:,Z);
  curimg = IMGVOL(:,:,Z);
  
  %C = xcorr2(curimg,refimg);
  C = normxcorr2(curimg,refimg);
  [maxv maxi] = max(C(:));
  [ix iy] = ind2sub(size(C),maxi);
  ix = ix - size(curimg,1);
  iy = iy - size(curimg,2);
  
  if ix == 0 && iy == 0,
    NEWVOL(:,:,Z) = IMGVOL(:,:,Z);
    continue;
  end
  
  tmpx1 = [1:size(IMGVOL,1)];
  tmpx2 = [1:size(IMGVOL,1)] + ix;
  tmpidx = find(tmpx2 > 0 & tmpx2 < size(IMGVOL,1));
  tmpx1 = tmpx1(tmpidx);
  tmpx2 = tmpx2(tmpidx);
  
  tmpy1 = [1:size(IMGVOL,2)];
  tmpy2 = [1:size(IMGVOL,2)] + iy;
  tmpidx = find(tmpy2 > 0 & tmpy2 < size(IMGVOL,2));
  tmpy1 = tmpy1(tmpidx);
  tmpy2 = tmpy2(tmpidx);
  
  NEWVOL(tmpx1,tmpy1,Z) = IMGVOL(tmpx2,tmpy2,Z);
  
  
  figure;
  subplot(1,3,1); imagesc(refimg');
  subplot(1,3,2); imagesc(curimg');
  subplot(1,3,3); imagesc(NEWVOL(:,:,Z)');
  keyboard
  
end

  
return
