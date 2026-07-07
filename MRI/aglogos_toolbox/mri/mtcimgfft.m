function tcImg = mtcimgfft(tcImg, cutoff, mask)
%MTCIMGFFT - Filters respiratory artifacts
% MVITFFT(tcImg, cutoff, mask) filters respiratory artifacts by
% examining the power spectrum of the signal and scaling all
% frequencies accordingly. In specific, the 1 - abs(spectrum) is used
% as scaling function for the spectrum of the MRI signal. The signal
% is then reconstructed. This function works directly on the tcImg
% signal, while MATSFFT on the roiTs. A "cutoff" can be defined by
% the user for temporal smoothing, and a mask to avoid processing
% of voxels outside the brain area.
%
% See also MATSFFT
%
% NKL, 10.02.01

DEBUG       = 0;
MYSLICE     = 0;
DOFLT       = 1;
DOPLOT      = 0;
DODETREND   = 1;

if nargin < 3,
  mask = {};
  MaskName = 'none';
else
  MaskName = 'brain';
  if isstruct(mask),        % Roi structure
    Roi = mask; clear mask;
    Roi = mroiget(Roi,[],MaskName);
    for N=1:size(tcImg.dat,3),
      mask(:,:,N) = Roi.roi{N}.mask;
    end
  end;
end;

if nargin < 2,
  cutoff = 0;
end;

if ~nargin,
  help mtcimgfft;
  return;
end;

if DEBUG & MYSLICE,
  tcImg.dat = tcImg.dat(:,:,MYSLICE,:);
end;

Fs = 1/tcImg.dx;
nyq = Fs/2;
LEN = size(tcImg.dat,4);
PADLEN = getpow2(LEN,'ceiling');

DIMS = size(squeeze(tcImg.dat(:,:,1,:)));
SliceNo = size(tcImg.dat,3);

if DODETREND,
  % Save the mean here to obtain anatomical info after denoising
  img = mean(tcImg.dat,4);
  NPOINTS = size(tcImg.dat,4);
end;

for SliceNo = 1:size(tcImg.dat,3),
  if DODETREND,
    tcols{SliceNo} = detrend(mreshape(squeeze(tcImg.dat(:,:,SliceNo,:))));
  else
    tcols{SliceNo} = mreshape(squeeze(tcImg.dat(:,:,SliceNo,:)));
  end;
end;
tcImg.dat = [];

% GET RID OF ALL VOXELS OUTSIDE THE BRAIN MASK
if ~isempty(mask),
  for SliceNo = 1:length(tcols),
    slice_mask = mask(:,:,SliceNo);
    tmp{SliceNo} = tcols{SliceNo}(:,find(slice_mask(:)));
  end;
  tcols = tmp; clear tmp;
end;
  
if DEBUG,
  savtcols = tcols;
end;

for SliceNo = 1:length(tcols),
  NCOL = size(tcols{SliceNo},2);
  fdat = fftshift(fft(tcols{SliceNo},PADLEN,1));
  
  if DOFLT,
    len = size(fdat,1)/2;
    fabs = abs(fdat);
    lfr  = [0:Fs/(LEN-1):Fs] - Fs/2;
    fabs = mean(fabs,2);
    me = median(fabs);
    iq = iqr(fabs);
    ix = find(lfr>-0.37 & lfr<0.37);
    fabs(ix) = me+iq;
    fabs = fabs - me;
    fabs = 1 - fabs/max(fabs);
    fabs = fabs - min(fabs);
    fabs = fabs/max(fabs);
    fdat = fdat .* repmat(fabs,[1 NCOL]);
  end;
  
  tmp = real(ifft(fftshift(fdat)));
  tcols{SliceNo} = tmp(1:LEN,:,:);
  clear tmp;
end;

if cutoff,
  [b,a] = butter(6,cutoff/nyq,'low');
  for SliceNo = 1:length(tcols),
    tcolsDIMS = size(tcols{SliceNo});
    tcols{SliceNo} = filtfilt(b,a,tcols{SliceNo}(:));
    tcols{SliceNo} = reshape(tcols{SliceNo},tcolsDIMS);
  end;
end;

% NOW PUT BACK ALL BRAIN VOXELS IN THE ACTUAL RECT-IMAGE
if ~isempty(mask),
  for SliceNo = 1:length(tcols),
    slice_mask = mask(:,:,SliceNo);
    tmp{SliceNo} = zeros(size(tcols{SliceNo},1),length(slice_mask(:)));
    tmp{SliceNo}(:,find(slice_mask(:))) = tcols{SliceNo};
  end;
  tcols = tmp; clear tmp;
end;

for SliceNo = 1:length(tcols),
  tcImg.dat(:,:,SliceNo,:) = reshape(tcols{SliceNo}', DIMS);
end;

if DODETREND,
  tcImg.dat = tcImg.dat + repmat(img,[1 1 1 NPOINTS]);
end;

if DOPLOT,
  SINGLE_SLICES=0;
  t = [0:size(tcols{1},1)-1]' * tcImg.dx;
  if SINGLE_SLICES,
    mfigure([10 200 900 600]);
    for SliceNo=1:SliceNo,
      hold on;
      plot(t, mean(savtcols{SliceNo},2),'k');
      plot(t, mean(tcols{SliceNo},2),'r:');
    end;
  else
    for N=2:length(savtcols),
      savtcols{1} = cat(2,savtcols{1},savtcols{N});
      tcols{1} = cat(2,tcols{1},tcols{N});
    end;
    savtcols = mean(savtcols{1},2);
    tcols = mean(tcols{1},2);
    mfigure([10 100 1000 750]);
    msubplot(2,2,1);
    collage(tcImg);
    subplot(2,2,2);
    plot(t, mean(savtcols,2),'k','linewidth',2);
    hold on;
    plot(t, mean(tcols,2),'r','linewidth',3);
    set(gca,'xlim',[t(1) t(end)]);
    grid on;
    xlabel('Time in seconds');
    subplot(2,2,4);
    ARGS.SRATE = Fs;
    ARGS.COLOR = 'k';
    msigfft(savtcols,ARGS);
    hold on;
    ARGS.COLOR = 'r';
    ARGS.STYLE = '-';
    msigfft(tcols,ARGS);
    xlabel('Frequency in Hz');
    grid on;
    txt = sprintf('mtcimgfft(Session: %s, Cutoff: %.2f, [Roi="%s"])',...
                  tcImg.session,cutoff,MaskName);
    suptitle(txt,'r',12);
  end;
end;
