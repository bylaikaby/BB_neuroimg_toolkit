function oroiTs = mroitsfilt(roiTs,ARGS)
%MROITSFILT - Generate Time-Series for each area defined in ROI (like mareats)
% MROITSFILT (SESSION,EXPS,LOG) uses the information in roi.mat and generate area-time-series
% by concatanating the rois of each area in each slice. The function is identical to the
% portion of mareats dealing with signal processing. WE MUST DECIDE whether to keep this and
% call it from mareats or get rid of it altogether?????!
%
% See also MAREATS MROIGUI MROISCT
% NKL, 01.04.04

DEF.IFFTFLT         = 0;
DEF.IARTHURFLT      = 0;
DEF.ICUTOFF         = 0.750;            % Lowpass temporal filtering
DEF.ICUTOFFHIGH     = 0.055;            % Highpass temporal filtering
DEF.ISUBSTITUDE     = 2;

if exist('ARGS','var'),
  ARGS = sctcat(ARGS,DEF);
else
  ARGS = DEF;
end;
pareval(ARGS);

% REMOVE RESPIRATION ARTIFACTS AND LOWPASS FITLER BY USING INVERTING THE FFT-SPECTRUM
if ISUBSTITUDE,
  fprintf(' substitude.');
  for AreaNo = 1:length(roiTs),
    idx = getStimIndices(roiTs{AreaNo},'prestim');
    m = hnanmean(roiTs{AreaNo}.dat(idx(ISUBSTITUDE:end),:),1);
    roiTs{AreaNo}.dat(1:ISUBSTITUDE,:) = repmat(m,[ISUBSTITUDE 1]);
  end;
end;

% REMOVE RESPIRATION ARTIFACTS AND LOWPASS FITLER BY USING INVERTING THE FFT-SPECTRUM
if IFFTFLT,
  fprintf(' matsfft.');
  FFTARGS.DOPLOT = IPLOT;
  roiTs = matsfft(roiTs,0,FFTARGS); % Cutoff is set to zero; we do the filtering here
end;

% REMOVE RESPIRATORY ARTIFACTS BY PROJECTING OUT SINUSOIDS
if IARTHURFLT,
  fprintf(' matsrmresp.');
  for AreaNo = 1:length(roiTs),
    roiTs{AreaNo} = matsrmresp(roiTs{AreaNo});
  end;
end;

if ICUTOFF & ICUTOFFHIGH,
  ilen = size(roiTs{1}.dat,1);
  len = round(ilen/4);
  fprintf(' bandpass.');
  nyq = (1/roiTs{1}.dx)/2;
  [b,a] = butter(3,[ICUTOFFHIGH ICUTOFF]/nyq,'bandpass');
elseif ICUTOFF,
  fprintf(' lowpass.');
  nyq = (1/roiTs{1}.dx)/2;
  [b,a] = butter(4,ICUTOFF/nyq,'low');
elseif ICUTOFFHIGH,
  fprintf(' highpass.');
  nyq = (1/roiTs{1}.dx)/2;
  [b,a] = butter(4,ICUTOFFHIGH/nyq,'high');
end;

if ICUTOFF | ICUTOFFHIGH,
  for AreaNo = 1:length(roiTs),
    for N=1:size(roiTs{AreaNo}.dat,2),
      pre = roiTs{AreaNo}.dat(1:len,N);
      pst = roiTs{AreaNo}.dat(end-len+1:end,N);
      tmp = cat(1,flipud(pre),roiTs{AreaNo}.dat(:,N),flipud(pst));
      tmp = filtfilt(b,a,tmp);
      roiTs{AreaNo}.dat(:,N) = tmp(len+1:len+ilen);
    end;
  end;
end;

fprintf('\n');

if nargout,
  oroiTs = roiTs;
end;
