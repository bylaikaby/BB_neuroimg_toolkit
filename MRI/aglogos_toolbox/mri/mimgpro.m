function OtcImg = mimgpro(tcImg,ARGS)
%MIMGPRO - Preprocess tcImg before applying correlation analysis
% OtcImg = MIMGPRO(tcImg,ARGS) preprocess the tcImg structure to optimize it for correlation
% analysis. The filters and other operations can be defined through ARGS.
%
% Valid arguments are (defaults):
% ------------------------------------------
% DEF.IFILTER                 = 0;		Filter w/ a small kernel
% DEF.IFILTER_KSIZE           = 3;		Kernel size
% DEF.IFILTER_SD              = 1.5;	SD (if half about 90% of flt in kernel)
% DEF.IDETREND                = 1;		Linear detrending
% DEF.ITMPFILTER              = 0;		Temporal filtering
% DEF.ITMPFLT_LOW             = 0.05;	Remove high frequency noise
% DEF.ITMPFLT_HIGH            = 0.005;  Remove slow oscillations
% DEF.ITOSDU                  = 0;		Convert to SD Units
%
% NKL, 18.07.04
  
DEF.ISUBSTITUDE             = 0;		% Get rid of magnetization-transients
DEF.IFILTER                 = 0;		% Filter w/ a small kernel
DEF.IFILTER_KSIZE           = 3;		% Kernel size
DEF.IFILTER_SD              = 1.5;		% SD (if half about 90% of flt in kernel)

DEF.IFILTER3D               = 0;
DEF.IFILTER3D_KSIZE_mm      = 3;        % Kernel size in mm
DEF.IFILTER3D_FWHM_mm       = 1.0;      % FWHM of Gaussian in mm

DEF.IDETREND                = 1;		% Linear detrending
DEF.ITMPFILTER              = 0;		% Temporal filtering
DEF.ITMPFLT_LOW             = 0.05;		% Remove high frequency noise
DEF.ITMPFLT_HIGH            = 0.005;  	% Remove slow oscillations
DEF.ITOSDU                  = 1;		% Convert to SD Units
DEF.VERBOSE                 = 1;

if nargin < 1,
  help mimgpro;
  return
end;
if exist('ARGS','var'),
  ARGS = sctcat(ARGS,DEF);
else
  ARGS = DEF;
end;
pareval(ARGS);

% no need to run temporal filtering
if ITMPFLT_LOW <= 0 && ITMPFLT_HIGH <= 0,  ITMPFILTER = 0;  end


if VERBOSE,
  fprintf('.[mimgpro-> ');
end;


if ISUBSTITUDE,
  MagnTrans = 6;    % Six seconds is approx. the duration of magnetization
                    % tansient. Usually, we have the dummies to take care of this. Some of
                    % the Glass pattern scans, however, do not have dummies :-(

  NIMG = round(MagnTrans/tcImg.dx);
  if NIMG < 1,
    NIMG = 1;
  end;
  tcImg.dat(:,:,:,1:NIMG) = tcImg.dat(:,:,:,NIMG+1:2*NIMG);
end;
  
if IFILTER,
  if VERBOSE,
    fprintf('.XY-filtering (S=%g, SD=%g).', IFILTER_KSIZE,IFILTER_SD);
  end;

  tcImg.dat = mconv(tcImg.dat,IFILTER_KSIZE,IFILTER_SD);
%   for NS=1:size(tcImg.dat,3),
%     tcImg.dat(:,:,NS,:) = mconv(squeeze(tcImg.dat(:,:,NS,:)),IFILTER_KSIZE,IFILTER_SD);
%   end;
end

if IFILTER3D,
  if VERBOSE,
    fprintf('.3D-smooth (S=%smm, FWHM=%smm).',...
            deblank(sprintf('%d ',IFILTER3D_KSIZE_mm)),...
            deblank(sprintf('%g ',IFILTER3D_FWHM_mm)));
  end;
  tcImg.dat = mconv3(tcImg.dat,tcImg.ds,IFILTER3D_KSIZE_mm,IFILTER3D_FWHM_mm);
end

tcols = rmfield(tcImg,'dat');
tcols.dir.dname = 'roiTs';


if IDETREND > 0 || ITOSDU > 0 || ITMPFILTER > 0,

  if VERBOSE && IDETREND,   fprintf('.detrend'); end;
  if VERBOSE && ITMPFILTER,
    if ITMPFLT_LOW > 0 && ITMPFLT_HIGH > 0,
      fprintf('.bandpass[%g-%g]',ITMPFLT_HIGH,ITMPFLT_LOW);
    elseif ITMPFLT_LOW > 0,
      fprintf('.lowhpass[%g]',ITMPFLT_LOW);
    elseif ITMPFLT_HIGH > 0,
      fprintf('.highpass[%g]',ITMPFLT_HIGH);
    end
  end;
  if VERBOSE && ITOSDU,     fprintf('.tosdu');   end;
  
  if VERBOSE,  fprintf(' processing');  end
  for S = 1:size(tcImg.dat,3),
    if VERBOSE,  fprintf('.');  end;
    
    tmp = tcImg.dat(:,:,S,:);
    dims = size(tmp);
    tcols.dat = mreshape(squeeze(tmp));
  
    if IDETREND,
      tcols.dat = detrend(tcols.dat);
    end;
  
    if ITMPFILTER,
      nyqf = (1/tcImg.dx)/2;
      if ITMPFLT_HIGH > 0 && ITMPFLT_LOW > 0,
        [b,a] = butter(4,[ITMPFLT_HIGH ITMPFLT_LOW]/nyqf);
      elseif ITMPFLT_HIGH > 0,
        [b,a] = butter(4,ITMPFLT_HIGH/nyqf,'high');
      elseif ITMPFLT_LOW > 0,
        [b,a] = butter(4,ITMPFLT_LOW/nyqf,'low');
      end
      tcols.dat = filtfilt(b,a,tcols.dat);
    end;

    if ITOSDU,
      if strcmp(tcols.grpname,'AuxFiles');
        tcols = tosduAux(tcols,'dat');
      else
        tcols = tosdu(tcols);
      end;
    end;
    
    
    tcImg.dat(:,:,S,:) = mreshape(tcols.dat,dims,'m2i');

  end;
end

if VERBOSE, fprintf('].'); end;
OtcImg = tcImg;
return;

  



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sig = tosduAux(Sig,datname)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DIM = 1;							% All arrays have time as dim=1
if	strcmp(Sig.dir.dname,'tcImg'),
  DIM = 4;							% Except tcImg and Xcor (dim=4)
end;
stat = getbaselineAux(Sig,DIM);
eval(sprintf('dims = size(Sig.%s);',datname));
dims(:) = 1;
eval(sprintf('dims(%d) = size(Sig.%s,%d);',DIM,datname,DIM));
mdat = repmat(stat.m, dims);
sdat = repmat(stat.s, dims);
eval(sprintf('Sig.%s = (Sig.%s - mdat) ./ sdat;',datname,datname));
stat.func{1} = sprintf('dims(%d) = size(Sig.%s,%d);',DIM,datname,DIM);
stat.func{2} = 'repmat(stat.m, dims)';
stat.func{3} = 'repmat(stat.s, dims)';
stat.func{4} = sprintf('Sig.%s = (Sig.%s - mdat) ./ sdat;',datname,datname);
Sig.tosdu = stat;
return;
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stat = getbaselineAux(Sig,DIM)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
x = stimidx(Sig,'blank',2);
dims = size(Sig.dat);
dims(DIM) = 1;
if DIM == 1,	% NEURAL SIGNAL
  stat.m = hnanmean(Sig.dat(x,:),DIM);
  stat.m = reshape(stat.m,dims);
  stat.s = std(Sig.dat(x,:),1,DIM);
  stat.s = reshape(stat.s,dims);
else
  stat.m = hnanmean(Sig.dat(:,:,:,x,:),DIM);
  stat.m = reshape(stat.m,dims);
  stat.s = std(Sig.dat(:,:,:,x,:),1,DIM);
  stat.s = reshape(stat.s,dims);
end;
stat.ix = x(:);
stat.dx = Sig.dx(1);
stat.y  = stat.m + 5 * stat.s;
return;
  
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Idx = stimidx(Sig,ObjType,HemoDelay)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
StimV       = Sig.stm.v{1};
StimT       = Sig.stm.time{1};
Idx         = [];
StimTypes   = {};

switch ObjType
 case { 'prestim','prestm' }
  % assumes blank - stimulus ....
  ts = round((StimT(1)   + HemoDelay)/Sig.dx(1));
  te = round((StimT(1+1) + HemoDelay)/Sig.dx(1))-1;
  Idx = ts:te;
 case { 'blank','nostim'}
  for N=1:length(StimV),
    if ~StimV(N),
      ts = round((StimT(N)   + HemoDelay)/Sig.dx(1));
      te = round((StimT(N+1) + HemoDelay)/Sig.dx(1))-1;
      tmpdur = ts:te;
      Idx = [Idx, tmpdur];
    end
  end
 otherwise
end

if isempty(Idx),
  if VERBOSE, fprintf('\n ERROR stimidx: ''%s'' not found.',ObjType); end;
  Idx = [];
  return;
end

% select indices within data length.
if strcmpi(Sig.dir.dname,'tcImg'),
  % Sig.dat = (x,y,slice,t,...)
  dlen = size(Sig.dat,4);
else
  % Sig.dat = (time,chan,...)
  dlen = size(Sig.dat,1);
end
Idx = Idx(Idx > 0 & Idx <= dlen);

% make sure no overlapped regions
Idx = unique(Idx);
return
  