function OtcImg = imgload(SESSION,ExpNo,ARGS)
%IMGLOAD - Load Paravision 2dseq files
%	OtcImg = IMGLOAD(SesName,ExpNo,ARGS) uses read2dseq to read the
%	reconstructed MR images and preprocess them according to the flags set
%	in the structure ARGS. The file name is determined by ExpNo, which
%	indexes the expp(ExpNo).scanreco in the description file.
%
% NOTE :
%  Setting parameters can be controlled by ANAP.imgload.xxx or GRP.xxx.anap.imgload.
%    ANAP.imgload.ICROP                = 0;         % Crop images
%    ANAP.imgload.ISLICROP             = 0;         % Crop slice
%    ANAP.imgload.IDATCLASS            = 'double';  % data type for tcImg.dat
%  --------------------------------------------------------------------
%    ANAP.imgload.ISUBSTITUTE          = 0;		    % Substitute initial images to avoid transient
% --------------------------------------------------------------------
%    ANAP.imgload.INORMALIZE           = 0;	        % Ratio normalization
%    ANAP.imgload.INORMALIZE_THR       = 10;        % Percent of max to include in normaliz.
% --------------------------------------------------------------------
%    ANAP.imgload.IDETREND             = 0;         % Linear detrending
% --------------------------------------------------------------------
%    ANAP.imgload.IFILTER              = 0;	        % Filter w/ a small kernel
%    ANAP.imgload.IFILTER_KSIZE        = 3;	        % Kernel size
%    ANAP.imgload.IFILTER_SD           = 1.5;       % SD (if half about 90% of flt in kernel)
% --------------------------------------------------------------------
%    ANAP.imgload.IDENOISE             = 0;         % Remove respiratory art. (not used)
%    ANAP.imgload.IRESP_FREQ           = 0.4;       % (Hz) 25 strokes / min
% --------------------------------------------------------------------
%    ANAP.imgload.ITMPFLT_LOW          = 0;         % Reduce samp. rate by this factor
%    ANAP.imgload.ITMPFLT_HIGH         = 0;         % Remove slow oscillations
% --------------------------------------------------------------------
%    ANAP.imgload.IDC_RECOVER          = 0;         % Recover removed DC offsets
% --------------------------------------------------------------------
%    ANAP.imgload.IDETREND_AND_DENOISE = 0;         % Detrend and remove resp artifacts
%
%
% EXTENSION : if DEF.SAVEAS_IMG == 1, 'tcImg.dat' will be saved as a
%           separate file.  06.02.04 YM
%
% VERSION :
%   1.00 24.02.01 NKL
%   1.01 09.02.04 YM   bug fix on empty frange{3} (when imgtr>0.36s).
%   1.02 23.04.04 YM   remove unused fields.
%   1.03 26.01.06 YM   normalize time by time if large data like d04zn1.
%   1.04 07.04.06 YM   bug fix on Ses.expp(ExpNo).slice.
%   1.05 08.10.06 YM   computes a time course of centroid for awake MRI.
%   1.06 13.03.07 YM   bug fix when grp.imgcrop is empty.
%   1.07 31.08.07 YM   support ISUBSTITUTE_RAND.
%   1.08 20.10.07 YM   checks initial transients.
%   1.09 15.11.07 YM   supports IDC_RECOVER
%   1.10 26.11.07 YM   supports ISLICROP
%   1.11 03.12.07 YM   supports EXPP(X).DataMri/dirname.
%   1.12 11.01.08 YM   supports ANAP.imgload.RECO_byte_order/RECO_wordtype.
%   1.13 30.01.12 YM   supports csession/cgroup, use sigsave().
%
% See also MGETTCIMG, SESIMGLOAD, READ2DSEQ, SESASCAN, SESCSCAN,
%          IMRESIZE, IMFEATURE, EPI13, MSIGFFT,
%          IMG_WRITE, IMG_READ, IMG_INFO SIGSAVE

if nargin < 2,  eval(sprintf('help %s;',mfilename)); return;  end

  
% ======================================================================
% DEFAULT SETTINGS & OPERATIONS
% ======================================================================
% --------------------------------------------------------------------
DEF.ICROP                   = 0;		% Crop images
DEF.ISLICROP                = 0;        % Crop slice
DEF.IDATCLASS               = 'double'; % data type for tcImg.dat
% --------------------------------------------------------------------
DEF.ISUBSTITUTE             = 0;		% Substitute initial images to avoid trans
DEF.ISUBSTITUTE_RAND        = 1;
% --------------------------------------------------------------------
DEF.INORMALIZE              = 1;		% Ratio normalization
DEF.INORMALIZE_THR          = 10;		% Percent of max to include in normaliz.
% --------------------------------------------------------------------
DEF.IDETREND                = 0;		% Linear detrending
% --------------------------------------------------------------------
DEF.IFILTER                 = 0;		% Filter w/ a small kernel
DEF.IFILTER_KSIZE           = 3;		% Kernel size
DEF.IFILTER_SD              = 1.5;		% SD (if half about 90% of flt in kernel)
% --------------------------------------------------------------------
DEF.IDENOISE                = 0;		% Remove respiratory art. (not used)
DEF.IRESP_FREQ              = 0.4;		% (Hz) 25 strokes / min
% --------------------------------------------------------------------
DEF.ITMPFLT_LOW             = 0;		% Reduce samp. rate by this factor
DEF.ITMPFLT_HIGH            = 0;		% Remove slow oscillations
% --------------------------------------------------------------------
DEF.IDC_RECOVER             = 0;        % Recover removed DC offsets
% --------------------------------------------------------------------
DEF.IADJUST                 = 0;		% Permit gamma/clip
DEF.ICLIP                   = [0.1 0.9];% Clipping
DEF.IGAMMA                  = 0.8;		% Gamma value
% --------------------------------------------------------------------
DEF.IDETREND_AND_DENOISE    = 0;        % Detrend and remove resp artifacts
% --------------------------------------------------------------------
DEF.ISAVE                   = 0;        % Save in mat-file
DEF.SAVEAS_IMG              = 0;        % tcImg.dat will be saved separately.



% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);				% Get Session Information
grp = getgrp(Ses,ExpNo);
anap = getanap(Ses,ExpNo);
%par = expgetpar(Ses,ExpNo);
%pvpar = par.pvpar;
if isa(grp,'cgroup'),
  grp = grp.oldstruct();
end


if isa(Ses,'csession'),
  DIRS = Ses.getdirs();
  EXPP = Ses.m_expp(ExpNo);
else
  DIRS = Ses.sysp;
  EXPP = Ses.expp(ExpNo);
end
if ~isfield(EXPP,'dirname') || isempty(EXPP.dirname),
  EXPP.dirname = DIRS.dirname;
end
if ~isfield(EXPP,'DataNeuro') || isempty(EXPP.DataNeuro)
  EXPP.DataNeuro = DIRS.DataNeuro;
end
if ~isfield(EXPP,'DataMri') || isempty(EXPP.DataMri)
  EXPP.DataMri = DIRS.DataMri;
end
if ~isfield(EXPP,'imgcrop') || isempty(EXPP.imgcrop),
  EXPP.imgcrop = grp.imgcrop;
end
if ~isfield(EXPP,'imgcrop') || isempty(EXPP.imgcrop),
  if isfield(grp,'imgcrop'),
    EXPP.imgcrop = grp.imgcrop;
  else
    EXPP.imgcrop = [];
  end
end
if ~isfield(EXPP,'slicrop') || isempty(EXPP.slicrop),
  if isfield(grp,'slicrop'),
    EXPP.slicrop = grp.slicrop;
  else
    EXPP.slicrop = [];
  end
end
clear DIRS;



pvpar = getpvpars(fullfile(EXPP.DataMri,EXPP.dirname),...
                  EXPP.scanreco(1),EXPP.scanreco(2));

if isfield(anap,'imgload') && ~isempty(anap.imgload),
  if isfield(anap.imgload,'RECO_byte_order'),
    pvpar.reco.RECO_byte_order = anap.imgload.RECO_byte_order;
  end
  if isfield(anap.imgload,'RECO_wordtype'),
    pvpar.reco.RECO_wordtype = anap.imgload.RECO_wordtype;
  end
end


tcImg = mgettcimg(Ses,ExpNo);


%%% ------------------------------------------
%%% IF ARGS EXIST..
%%% APPEND DEFAULTS ON THEM AND EVALUATE ALL
%%% ------------------------------------------
if isfield(anap,'imgload') && ~isempty(anap.imgload),
  DEF = sctmerge(DEF,anap.imgload);
end
if exist('ARGS','var') && ~isempty(ARGS),
  ARGS = sctcat(ARGS,DEF);
else
  ARGS = DEF;
end;

% fix typo (substituDe/substituTe) but keep compatibility for old stuff....
if isfield(ARGS,'ISUBSTITUDE'),
  ARGS.ISUBSTITUTE = ARGS.ISUBSTITUDE;
end
if isfield(ARGS,'ISUBSTITUDE_RAND'),
  ARGS.ISUBSTITUTE_RAND = ARGS.ISUBSTITUDE_RAND;
end

pareval(ARGS);

%%% ------------------------------------------
%%% READ IMAGE AND PHYSIOLOGY PARAMETERS
%%% ------------------------------------------
nx		= pvpar.nx;
ny		= pvpar.ny;
nt		= pvpar.nt;
ns		= pvpar.nsli;
imgtr	= pvpar.imgtr;

fprintf(' imgload: ');

% IF CROPPING REQUIRED GET DIMENSIONS FROM PAR-FILE
% THEY ORIGINALLY DEFINED IN Ses.grp.name.crop
if ICROP && ~isempty(EXPP.imgcrop),
  x1 = EXPP.imgcrop(1);
  y1 = EXPP.imgcrop(2);
  x2 = x1 + EXPP.imgcrop(3) - 1;
  y2 = y1 + EXPP.imgcrop(4) - 1;
  fprintf('imgcrop[%dx%d->%dx%d].',nx,ny,EXPP.imgcrop(3),EXPP.imgcrop(4));
else
  x1 = 1;	y1 = 1;
  x2 = nx;	y2 = ny;
end;
%t1	= tcImg.usr.imgofs;
%t2	= tcImg.usr.imgofs + tcImg.usr.imglen - 1;
t1 = 1;
t2 = nt;

% ns1 = 1;
% ns2 = ns;
% if isfield(EXPP,'slice'),
%   ns1 = EXPP.slice(1);
%   ns2 = EXPP.slice(2);
% end;
% NS1=ns1;
% NS2=ns2-ns1+1;

ns1 = 1;
ns2 = ns;
if ISLICROP > 0,
  slicrop = [];
  if isfield(EXPP,'slice') && ~isempty(EXPP.slice),
    % given as [start end] like [16 30], 15 slices of 16:30
    slicrop = [EXPP.slice(1) EXPP.slice(2)-EXPP.slice(1)+1];
  elseif isfield(EXPP,'slicrop') && ~isempty(EXPP.slicrop),
    % given as [start num_slices] like [2 11], 11 slices from 2
    slicrop = EXPP.slicrop;
  end;
  % update ns1/ns2 for slice selection
  if ~isempty(slicrop),
    % given as [start num_slices] like [2 11], 11 slices from 2
    ns1 = slicrop(1);
    ns2 = slicrop(2)+slicrop(1)-1;
    fprintf('slicrop[%d->%d].',ns,slicrop(2));
  end
  clear slicrop
end



if ~exist(tcImg.dir.imgfile,'file'),
  fprintf('File %s does not exist!\n',tcImg.dir.imgfile);
  keyboard;
end;


% ------------------------------------------------------------------------
% READ DATA
% im=read2dseq(fname,nx,nx1,nx2,ny,ny1,ny2,ns,ns1,ns2,nt1,nt2,byteorder,wordtype,dattype)
% nx,ny,ns			: x- and y- dimensions of image, and # of slices
% nx1,nx2,ny1,ny2	: crop dimensions
% ns1,ns2			: slice range
% nt1,nt2			: time point range
% byteorder			: (s) swap, (n) non-swap is required
% wordtype          : '_16BIT_SGN_INT' or something else, see ParaVision manual.
% dattype           : 'double' or 'single' of tcImg.dat, see DEF.IDATCLASS
% ------------------------------------------------------------------------
% 06.11.03 YM, use pvpar for byte swapping.
fprintf(' 2dseq(%s/%s->%s).',pvpar.reco.RECO_byte_order,pvpar.reco.RECO_wordtype,IDATCLASS);

% Defaults:
% byteorder: littleEndian
% Wordtype: _16BIT_SGN_INT
% Example of reading raw files (from Analyzie directly):

% img =
% read2dseq('rathead16T.raw',256,1,256,140,1,140,256,1,256,1,1,'littleEndian','_16BIT_SGN_INT','double');
fprintf(' read.');
img = read2dseq(tcImg.dir.imgfile,nx,x1,x2,ny,y1,y2,ns,ns1,ns2,t1,t2,...
                pvpar.reco.RECO_byte_order,pvpar.reco.RECO_wordtype,IDATCLASS,0);



% Used only w/ EPI13 data to get rid of transients
% All our new data have dummies; so substitute should be zero
if ISUBSTITUTE,
  fprintf(' substituting(%d,rand=%d).',ISUBSTITUTE,ISUBSTITUTE_RAND);
  for NS=1:size(img,3),
    img(:,:,NS,1:ISUBSTITUTE) = img(:,:,NS,ISUBSTITUTE+1:2*ISUBSTITUTE);
    if ISUBSTITUTE_RAND, 
      idx = 1:ISUBSTITUTE;
      for x = 1:size(img,1),
        for y = 1:size(img,2),
          img(x,y,NS,idx) = img(x,y,NS,idx(randperm(ISUBSTITUTE)));
        end
      end
    end
  end;
  %fprintf('imgload: Transients Eliminated\n');
else
  tmpsz = size(img);
  tmpdat = reshape(img,[size(img,1)*size(img,2)*size(img,3), size(img,4)]);
  tmpdat = mean(tmpdat,1);
  thalf  = round(length(tmpdat)/2)+1;
  tmpm   = mean(tmpdat(thalf:end));
  tmps   = std(tmpdat(thalf:end));
  if tmpdat(1)-tmpm > tmps*10,
    figure('Name',sprintf('%s(%s,%d)',mfilename,Ses.name,ExpNo));
    plot(tmpdat);
    set(gca,'xlim',[0 length(tmpdat)]);
    hold on; grid on;
    xlabel('Time in volumes');  ylabel('Mean Voxel Value');
    line(get(gca,'xlim'),[tmpm tmpm],'color',[0 0 0]);
    line(get(gca,'xlim'),[tmpm tmpm]+1*tmps,'color','r');
    line(get(gca,'xlim'),[tmpm tmpm]-1*tmps,'color','r');
    title(strrep(sprintf('%s: ExpNo=%d(%s)',Ses.name,ExpNo,grp.name),'_','\_'));
    fprintf('\n WARNING %s: %s Exp=%d(%s) initial transients detected, not enough dummies...',mfilename,Ses.name,ExpNo,grp.name);
    fprintf('\n Please set ANAP.imgload.ISUBSTITUTE (for all) or GRP.%s.anap.ISUBSTITUTE (for the group) in volumes.\n',grp.name);
    %keyboard
  end
  clear tmpsz tmpdat thalf tmpm tmps;
end;

if INORMALIZE,
  fprintf(' normalizing.');

  thr = INORMALIZE_THR;
  slice_mean = mean(img,4);			% Avg. over time.
  
  % Find the avg. activation of those pix that are above threshold.
  % This excludes areas outside of the brain from the average.
  included_voxels  = max(slice_mean(:)) * thr / 100.0;
  volume_mean = mean( mean( slice_mean( slice_mean(:) > included_voxels)));
  % Normalize images to avg activation of brain (activated) pixles.
  if numel(img)*8 > 800e+6,
    % If 'img' is larger than 800M, then do time by time to avoid memory problem.
    for N = 1:size(img,4),
      img(:,:,:,N) = 1000/volume_mean * img(:,:,:,N);
    end
  else
    img = 1000/volume_mean * img;
  end
  %fprintf('imgload: Image normalized\n');
end;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DC_removed = 0;  % flag must set as 1 if the processing removes DC offsets
dcoffs = nanmean(img,4);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if IDETREND && size(img,4) > 1,
  fprintf(' detrending.');
  for NS=1:size(img,3),
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
  DC_removed = 1;
end;

if IFILTER,
  fprintf(' XY-filtering.');
  for NS=1:size(img,3),	
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
  for NS=1:size(img,3),	
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
  for NS=1:size(img,3),
	tmp = squeeze(img(:,:,NS,:));
	mtmp = mean(tmp,3);
	[b,a] = butter(4,ITMPFLT_HIGH/((1/imgtr)/2),'high');
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
  DC_removed = 1;
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
  for NS=1:size(img,3),
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


if IDC_RECOVER && DC_removed && size(img,4) > 1,
  fprintf(' DC-recover.');
  for x = 1:size(img,1),
    for y = 1:size(img,2),
      for z = 1:size(img,3)
        img(x,y,z,:) = img(x,y,z,:) + dcoffs(x,y,z);
      end
    end
  end
end



if IADJUST,
  fprintf(' adjusting intensities.');
  %fprintf('imgload: Adjusting intensities (Top/Gamma)\n');
  thr = mean(img(:)) * 0.05;
  img(img(:)<thr) = NaN;
  m = nanmean(img(:));
  s = nanstd(img(:));
  c = m+3*s;
  img(img(:)>c)=c;
  img = img ./ c;
  for NS=1:size(img,3),
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

tcImg.centroid = mcentroid(tcImg.dat,tcImg.ds);

fprintf(' done.\n');

if ISAVE,
  try
    fname = sigsave(Ses,ExpNo,'tcImg',tcImg);
    bakfile = sprintf('%s.bak',fname);
    if exist(bakfile,'file'),
      fprintf(' deleting .bak file...');
      delete(bakfile);
      fprintf(' done.\n');
    end
  catch
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
