function OtcImg = imgload(SESSION,ExpNo,ARGS)
%IMGLOAD - Load Paravision 2dseq files
%	OtcImg = IMGLOAD(SesName,ExpNo,ARGS) uses read2dseq to read the
%	reconstructed MR images and preprocess them according to the flags set
%	in the structure ARGS. The file name is determined by ExpNo, which
%	indexes the expp(ExpNo).scanreco in the description file.
%
%	NKL, 24.02.01
%	CORRECT DESCRIPTION!!!!!!!!!!!!!!
%	otcImg = IMGLOAD(...) returns the structure:
%
% EXTENSION : if DEF.SAVEAS_IMG == 1, 'tcImg.dat' will be saved as a
%           separate file.  06.02.04 YM
%
% VERSION : 1.00 24.02.01 NKL
%           1.01 09.02.04 YM   bug fix on empty frange{3} (when imgtr>0.36s).
% See also MGETTCIMG SESIMGLOAD READ2DSEQ IMRESIZE IMFEATURE EPI13 MSIGFFT
%          IMG_WRITE IMG_READ IMG_INFO
  
  
% ======================================================================
% DEFAULT SETTINGS & OPERATIONS
% ======================================================================
DEF.ISCANTYPE               = 'EPI';	% All MRI+Phis is EPI (one/multi shot)
DEF.IDATATYPE               = 'tcImg';	% Usually the name of the structure
DEF.ICLIP                   = [0.1 0.9];% Clipping
DEF.IGAMMA                  = 0.8;		% Gamma value
DEF.IRESP_FREQ              = 0.4;		% (Hz) 25 strokes / min
DEF.ISUBSTITUDE             = 0;		% Substitude initial images to avoid trans
DEF.ICROP                   = 0;		% Crop images
DEF.IADJUST                 = 0;		% Permit gamma/clip
DEF.INORMALIZE              = 0;		% Ratio normalization
DEF.INORMALIZE_THR          = 10;		% Percent of max to include in normaliz.
DEF.IDETREND                = 0;		% Linear detrending
DEF.IDETREND_AND_DENOISE    = 0;        % Detrend and remove resp artifacts
DEF.ITMPFLT_LOW             = 0;		% Reduce samp. rate by this factor
DEF.ITMPFLT_HIGH            = 0;		% Remove slow oscillations
DEF.IDENOISE                = 0;		% Remove respiratory art. (not used)
DEF.IFILTER                 = 0;		% Filter w/ a small kernel
DEF.IFILTER_KSIZE           = 3;		% Kernel size
DEF.IFILTER_SD              = 1.5;		% SD (if half about 90% of flt in kernel)
DEF.ISAVE                   = 0;        % Save in mat-file
DEF.SAVEAS_IMG              = 0;        % tcImg.dat will be saved separately.

if nargin < 2,
  error('usage: tcImg = imgload(Ses,ExpNo,ARGS);');
end;

Ses = goto(SESSION);				% Get Session Information
tcImg = mgettcimg(Ses,ExpNo);

%%% ------------------------------------------
%%% IF ARGS EXIST..
%%% APPEND DEFAULTS ON THEM AND EVALUATE ALL
%%% ------------------------------------------
if exist('ARGS','var'),
  ARGS = sctcat(ARGS,DEF);
else
  ARGS = DEF;
end;
pareval(ARGS);

%%% ------------------------------------------
%%% READ IMAGE AND PHYSIOLOGY PARAMETERS
%%% ------------------------------------------
nx		= tcImg.usr.pvpar.nx;
ny		= tcImg.usr.pvpar.ny;
nt		= tcImg.usr.pvpar.nt;
ns		= tcImg.usr.pvpar.nsli;
imgtr	= tcImg.usr.pvpar.imgtr;

% IF CROPPING REQUIRED GET DIMENSIONS FROM PAR-FILE
% THEY ORIGINALLY DEFINED IN Ses.grp.name.crop
if ICROP,
  x1 = tcImg.grp.imgcrop(1);
  y1 = tcImg.grp.imgcrop(2);
  x2 = x1 + tcImg.grp.imgcrop(3) - 1;
  y2 = y1 + tcImg.grp.imgcrop(4) - 1;
else
  x1 = 1;	y1 = 1;
  x2 = nx;	y2 = ny;
end;
t1	= tcImg.usr.imgofs;
t2	= tcImg.usr.imgofs + tcImg.usr.imglen - 1;

ns1 = 1;
ns2 = ns;
if isfield(Ses.expp(ExpNo),'slice'),
  ns1 = Ses.expp(ExpNo).slice(1);
  ns2 = Ses.expp(ExpNo).slice(2);
end;
NS1=1;
NS2=ns2-ns1+1;

if ~exist(tcImg.dir.imgfile,'file'),
  fprintf('File %s does not exist!\n',tcImg.dir.imgfile);
  keyboard;
end;

fprintf(' imgload:');
% ------------------------------------------------------------------------
% READ DATA
% im=read2dseq(fname,nx,nx1,nx2,ny,ny1,ny2,ns,ns1,ns2,nt1,nt2,byteorder)
% nx,ny,ns			: x- and y- dimensions of image, and # of slices
% nx1,nx2,ny1,ny2	: crop dimensions
% ns1,ns2			: slice range
% nt1,nt2			: time point range
% byteorder			: (s) swap, (n) non-swap is required
% ------------------------------------------------------------------------
% 06.11.03 YM, use pvpar for byte swapping.
fprintf(' 2dseq.');
if strcmpi(tcImg.usr.pvpar.reco.RECO_byte_order,'bigEndian'),
  % byte swap for IRIX etc.
  img=read2dseq(tcImg.dir.imgfile,nx,x1,x2,ny,y1,y2,ns,ns1,ns2,t1,t2,'s');
else
  % no swap for INTEL
  img=read2dseq(tcImg.dir.imgfile,nx,x1,x2,ny,y1,y2,ns,ns1,ns2,t1,t2,'n');
end

if ns1 == ns2,
  ns = 1;
end;

% Used only w/ EPI13 data to get rid of transients
% All our new data have dummies; so substitude should be zero
if ISUBSTITUDE,
  fprintf(' substituting.');
  for NS=NS1:NS2,
    img(:,:,NS,1:ISUBSTITUDE) = img(:,:,NS,ISUBSTITUDE+1:2*ISUBSTITUDE);
  end;
  %fprintf('imgload: Transients Eliminated\n');
end;

if INORMALIZE,
  fprintf(' normalizing.');

  thr = INORMALIZE_THR;
  slice_mean = mean(img,4);			% Avg. over time.
  
  % Find the avg. activation of those pix that are above threshold.
  % This excludes areas outside of the brain from the average.
  included_voxels  = max(slice_mean(:)) * thr / 100.0;
  volume_mean = mean( mean( slice_mean( find( slice_mean > included_voxels))));
  % Normalize images to avg activation of brain (activated) pixles.
  img = 1000/volume_mean * img;
  %fprintf('imgload: Image normalized\n');
end;

if IDETREND,
  fprintf(' detrending.');
  for NS=NS1:NS2,
    tmp = squeeze(img(:,:,NS,:));
    dims = size(tmp);
    mtmp = mean(tmp,3);
    tcols = mreshape(tmp);
    tcols = detrend(tcols);
    tmp = mreshape(tcols,dims,'m2i') + repmat(mtmp,[1 1 dims(3)]);
    img(:,:,NS,:) = tmp;
  end;
  clear tmp mtmp;
  %fprintf('imgload: TimeCourse Detrended\n');
end;

if IFILTER,
  fprintf(' XY-filtering.');
  for NS=NS1:NS2,	
    img(:,:,NS,:) = mconv(squeeze(img(:,:,NS,:)),IFILTER_KSIZE,IFILTER_SD);
  end;
  %fprintf('imgload: spatially filtered\n');
end

if IDENOISE,
  fprintf(' denoising(Resp).');
  l = IRESP_FREQ - 0.02;
  r = IRESP_FREQ + 0.02;
  nyq = (1/imgtr) / 2;
  nl = l / nyq;		% normalized left boundary
  nr = r / nyq;		% normalized right boundary
  [b,a]	= butter(4,[nl nr],'stop');
  [b1,a1] = butter(4,2*[nl nr],'stop');
  for NS=NS1:NS2,	
    for N=1:size(img,1),
      for M=1:size(img,2),
        if any(img(N,M,NS,:)),
          img(N,M,NS,:) = filtfilt(b,a,img(N,M,NS,:));
          img(N,M,NS,:) = filtfilt(b1,a1,img(N,M,NS,:));
        end;
      end;
    end;
  end;
  %fprintf('imgload: TimeCourse Denoised (Resp Artifact Removal)\n');
end;

if ITMPFLT_HIGH,
  fprintf(' T-filtering(HP).');
  for NS=NS1:NS2,
	tmp = squeeze(img(:,:,NS,:));
	mtmp = mean(tmp,3);
	[b,a] = butter(4,ITMPFLT_HIGH/((1/imgtr)/2),'higimgtr');
	for C=1:size(tmp,1),
	  for R=1:size(tmp,2),
		tmp(C,R,:) = filtfilt(b,a,tmp(C,R,:));
	  end;
	end;
	tmp = tmp + repmat(mtmp,[1 1 size(tmp,3)]);
	img(:,:,NS,:) = tmp;
  end;
  clear tmp mtmp;
  %fprintf('imgload: High Pass Temporal Filtering\n');
end;

if ITMPFLT_LOW,
  fprintf(' T-filtering(LP).');
  if ITMPFLT_LOW <= 2,
    ITMPFLT_LOW = 2.5;
    fprintf('imgload[WARNING]: lowpass filter cuttof set to %3.2f\n',...
			ITMPFLT_LOW);
  end;
  newrate = (1/imgtr)/ITMPFLT_LOW;
  nyq = (1/imgtr)/2;
  [b,a] = butter(4,newrate/nyq,'low');
  for NS=NS1:NS2,
    tmp = squeeze(img(:,:,NS,:));
    for C=1:size(tmp,1),
      for R=1:size(tmp,2),
        tmp(C,R,:) = filtfilt(b,a,tmp(C,R,:));
      end;
    end;
    img(:,:,NS,:) = tmp;
  end;
  clear tmp;
  %fprintf('imgload: Low Pass Temporal Filtering\n');
end;

if IADJUST,
  fprintf(' adjusting intencities.');
  %fprintf('imgload: Adjusting intensities (Top/Gamma)\n');
  thr = mean(img(:)) * 0.05;
  img(find(img<thr)) = NaN;
  m = nanmean(img(:));
  s = nanstd(img(:));
  c = m+3*s;
  img(find(img>c))=c;
  img = img ./ c;
  for NS=NS1:NS2,
    for N=1:size(img,4),
      img(:,:,NS,N)=imadjust(img(:,:,NS,N),ICLIP,[0 1],IGAMMA);
    end;
  end;
  img = img * c;
end;

tcImg.dat = img;
clear img tmp;

if IDETREND_AND_DENOISE,
  fprintf(' detrend_and_denoise.');
  DOPLOT = 0;
  tcImg = DetrendAndDenoiseImg(tcImg,DOPLOT);
end;

fprintf(' done.\n');

if ISAVE,
  try,
    if SAVEAS_IMG,
      tcImg.dir.datfile = catfilename(Ses,ExpNo,'tcimgdat');
      if ~exist(fileparts(tcImg.dir.datfile)),
        [fp,fr,fe] = fileparts(fileparts(tcImg.dir.datfile));
        mkdir(fp,strcat(fr,fe));
      end
      fprintf(' imgload: tcImg.dat    -->''%s''...',tcImg.dir.datfile);
      imgdat = tcImg.dat;
      tcImg.dat = [];
      dx = tcImg.ds(1);
      dy = tcImg.ds(2);
      thick = tcImg.usr.pvpar.slithk;
      img_write(tcImg.dir.datfile,...
                imgdat,imgtr,dx,dy,thick,'datatype','double');
      fprintf(' done.\n');
    end
    fprintf(' imgload: tcImg        -->''%s''...',tcImg.dir.tcimgfile);
    if ~exist(fileparts(tcImg.dir.tcimgfile)),
      [fp,fr,fe] = fileparts(fileparts(tcImg.dir.tcimgfile));
      mkdir(fp,strcat(fr,fe));
    end
    if ~exist(tcImg.dir.tcimgfile,'file'),
      save(tcImg.dir.tcimgfile,'tcImg');
    else
      save(tcImg.dir.tcimgfile,'tcImg','-append');
    end
    fprintf(' done.\n');
  catch,
    disp(lasterr);
    keyboard;
  end;
end;

if nargout == 1,
  OtcImg = tcImg;
else
  if ~ISAVE,
    tcImg
    keyboard;
  end;
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sig = DetrendAndDenoiseImg(Sig,DOPLOT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
frange = GetRespRate(Sig,DOPLOT);
nyq = (1/Sig.dx) / 2;
for N=1:length(frange),
  frange{N}=frange{N}/nyq;
end;

if ~isempty(frange{1}),
  [b,a] = butter(1,frange{1},'stop');
else
  fprintf('\n imgload: all freq ranges are empty.  applying detrend() only...');
end
if ~isempty(frange{2}),
  [b1,a1] = butter(1,frange{2},'stop');
end
if ~isempty(frange{3}),
  [b2,a2] = butter(1,frange{3},'stop');
end

mimg = mean(Sig.dat,4);
SIZE = squeeze(size(Sig.dat(:,:,1,:)));
for SliceNo=1:size(Sig.dat,3),
  tmpimg = squeeze(Sig.dat(:,:,SliceNo,:));
  tmpimg = mreshape(tmpimg);
  for N=1:size(tmpimg,2),
	tmpimg(:,N) = detrend(tmpimg(:,N));
    if ~isempty(frange{1}),
      tmpimg(:,N) = filtfilt(b,a,tmpimg(:,N));
    end
    if ~isempty(frange{2}),
      tmpimg(:,N) = filtfilt(b1,a1,tmpimg(:,N));
    end
    if ~isempty(frange{3}),
      tmpimg(:,N) = filtfilt(b2,a2,tmpimg(:,N));
    end
  end;
  Sig.dat(:,:,SliceNo,:) = mreshape(tmpimg,SIZE,'m2i');
end;
Sig.dat = Sig.dat + repmat(mimg,[1 1 1 size(Sig.dat,4)]);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function frange = GetRespRate(tcImg,DOPLOT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tcImg.dat = tcImg.dat(:,:,1,:);
[famp,fang,freq] = msigfft(tcImg);
famp = mean(famp,2);

idx1 = find(freq>0.35 & freq < 0.46);
idx2 = find(freq>0.70 & freq < 0.92);
idx3 = find(freq>1.40 & freq < 1.80);

[m, f1] = max(famp(idx1));
[m, f2] = max(famp(idx2));
[m, f3] = max(famp(idx3));

if ~isempty(idx1),
  f1 = f1 + idx1(1) - 1;
  frange{1} = [freq(f1)-0.015 freq(f1)+0.015];
else
  f1 = [];  frange{1} = [];
end
if ~isempty(idx2),
  f2 = f2 + idx2(1) - 1;
  frange{2} = [freq(f2)-0.015 freq(f2)+0.015];
else
  f2 = [];  frange{2} = [];
end
if ~isempty(idx3),
  f3 = f3 + idx3(1) - 1;
  frange{3} = [freq(f3)-0.015 freq(f3)+0.015];
else
  f3 = [];  frange{3} = [];
end


if DOPLOT,
  plot(freq, famp,'color','k','linewidth',1);
  grid on;
  hold on;

  if ~isempty(f1),
    line([freq(f1) freq(f1)],get(gca,'ylim'),'color','g','linewidth',1);
  end
  if ~isempty(f2),
    line([freq(f2) freq(f2)],get(gca,'ylim'),'color','g','linewidth',1);
  end
  if ~isempty(f3),
    line([freq(f3) freq(f3)],get(gca,'ylim'),'color','g','linewidth',1);
  end
  
  if ~isempty(frange{1}),
    line([frange{1}(1) frange{1}(1)],get(gca,'ylim'),'color','r');
    line([frange{1}(2) frange{1}(2)],get(gca,'ylim'),'color','r');
  end
  if ~isempty(frange{2}),
    line([frange{2}(1) frange{2}(1)],get(gca,'ylim'),'color','r');
    line([frange{2}(2) frange{2}(2)],get(gca,'ylim'),'color','r');
  end
  if ~isempty(frange{3}),
    line([frange{3}(1) frange{3}(1)],get(gca,'ylim'),'color','r');
    line([frange{3}(2) frange{3}(2)],get(gca,'ylim'),'color','r');
  end
end;
