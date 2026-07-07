function roiTs = grpareats(SESSION,GrpName)
%GRPAREATS - Select and process TS of selected ROIs or Areas from group files
% GRPAREATS (SESSION, GrpName) extracts the time series for each of the permissible ROIs
% defined with the sesroi(SesName) utility.  The areas noted as "excluded"
% (e.g. IEXCLUDE={'brain';'ele'}) are not taken into account. For documentation see function
% mareats.m
%
% NKL 22.01.05

ARGS.IEXCLUDE        = {'brain'};
ARGS.ICONCAT         = 1;        % Concatante regions & slices
ARGS.ISUBSTITUDE     = 2;
ARGS.IDETREND        = 1;
ARGS.IFFTFLT         = 0;        % FFT filtering
ARGS.IARTHURFLT      = 0;        % The breath-remove of A. Gretton
ARGS.ICUTOFF         = 0.2;      % Lowpass temporal filtering
ARGS.ICUTOFFHIGH     = 0;        % Highpass temporal filtering
ARGS.ICORANA         = 1;
ARGS.ITOSDU          = 2;
ARGS.IHEMODELAY      = 2;
ARGS.IHEMOTAIL       = 5;
ARGS.IPLOT           = 0;

pareval(ARGS);

if nargin < 2,
  helpwin grpareats;
  return;
end;
  
Ses = goto(SESSION);                    % Read session info

if isfield(Ses.anap,'grpareats'),
  names = fieldnames(Ses.anap.grpareats);
  for N=1:length(names),
    eval(sprintf('%s = Ses.anap.grpareats.%s;', names{N}, names{N}));
  end;
end;

grp = getgrpbyname(Ses,GrpName);
ExpNo = grp.exps(1);

if ~exist('roi.mat','file'),
  fprintf('grpareats: Roi.mat does not exist; Run mroigui\n');
  return;
end;
Roi = matsigload('roi.mat',grp.grproi); % Load the ROI of that group

filename = 'tcImg.mat';
tcImg = matsigload(filename,GrpName);
if isempty(tcImg),
  fprintf('structure %s was not found in tcImg.mat\n');
  keyboard;
end;

if isempty(tcImg),
  fprintf('grpareats: No data in tcImg of file %s\n',...
          catfilename(Ses,ExpNo,'tcImg'));
  return;
end;

TrialID = -1;
if isfield(grp,'actmap') & length(grp.actmap) > 1,
  TrialID = grp.actmap{2};
end;

fprintf('%s: ',gettimestring);

% ======================================================================
% NOW BUILD THE ROITS STRUCTURE
% ======================================================================
rts.session   = Roi.session;
rts.grpname   = tcImg.grpname;
rts.ExpNo     = tcImg.ExpNo;
rts.dir       = Roi.dir;
rts.dir.dname = 'roiTs';
rts.dsp       = Roi.dsp;
rts.dsp.func  = 'dsproits';
rts.grp       = tcImg.grp;
rts.evt       = tcImg.evt;
rts.stm       = tcImg.stm;
rts.ele       = Roi.ele;
rts.ds        = tcImg.ds;
rts.dx        = tcImg.dx;

if ~isempty(grp.ana),
  AnaFile = sprintf('%s.mat',grp.ana{1});
  if exist(AnaFile,'file') & ~isempty(who('-file',AnaFile,grp.ana{1})),
    tmp = load(AnaFile,grp.ana{1});
    eval(sprintf('anaImg = tmp.%s;',grp.ana{1}));
    rts.ana = anaImg{grp.ana{2}}.dat;
    rts.ana = squeeze(rts.ana(:,:,grp.ana{3}));
else
  rts.ana = mean(tcImg.dat,4);
  end;
end;  

% ===================================================================
% SELECT TIME SERIES ON THE BASIS OF GROUP-ROIS
% ===================================================================
ValidRoiNo = 1;
if ICONCAT,
  for RoiNo=1:length(Ses.roi.names),
    if any(strcmp(lower(IEXCLUDE),lower(Ses.roi.names{RoiNo}))),
      continue;
    end;
    roiTs{ValidRoiNo} = rts;
    tmp = mtimeseries(tcImg,Roi,Ses.roi.names{RoiNo});
    if isempty(tmp),
      continue;
    end;

    roiTs{ValidRoiNo}           = rts;
    roiTs{ValidRoiNo}.name      = tmp.name;
    roiTs{ValidRoiNo}.slice     = -1;       % All slices concat-ed
    roiTs{ValidRoiNo}.coords    = tmp.coords;
    roiTs{ValidRoiNo}.roiSlices = tmp.roiSlices;
    roiTs{ValidRoiNo}.dat       = tmp.dat;
    ValidRoiNo = ValidRoiNo + 1;
  end;
else
  for RoiNo=1:length(Roi.roi),
    if any(strcmp(lower(IEXCLUDE),lower(Roi.roi{RoiNo}.name))),
      continue;
    end;
    roiTs{ValidRoiNo} = rts;
    roiTs{ValidRoiNo}.name = Roi.roi{RoiNo}.name;
    roiTs{ValidRoiNo}.slice = Roi.roi{RoiNo}.slice;
    
    [x,y] = find(Roi.roi{RoiNo}.mask);
    if max(x(:))>size(tcImg.dat,1) | max(y(:))>size(tcImg.dat,2),
      fprintf('GRPAREATS: Mask is greater than the actual image\n');
      size(tcImg.dat)
      size(Roi.roi{RoiNo}.mask)
      keyboard;
    end;
    roiTs{ValidRoiNo}.coords = [x y ones(length(x),1)*roiTs{ValidRoiNo}.slice];
    roiTs{ValidRoiNo}.dat = mtcfromcoords(tcImg,roiTs{ValidRoiNo}.coords);
    
    ValidRoiNo = ValidRoiNo + 1;
  end;
end;

% REMOVE RESPIRATION ARTIFACTS AND LOWPASS FITLER BY USING INVERTING THE FFT-SPECTRUM
if ISUBSTITUDE,
  fprintf(' substitude.');
  for AreaNo = 1:length(roiTs),
    idx = getStimIndices(roiTs{AreaNo},'prestim',IHEMODELAY);
    m = hnanmean(roiTs{AreaNo}.dat(idx(ISUBSTITUDE:end),:),1);
    roiTs{AreaNo}.dat(1:ISUBSTITUDE,:) = repmat(m,[ISUBSTITUDE 1]);
  end;
end;

% DETREND DATA
if IDETREND,
  fprintf(' detrend.');
  for AreaNo = 1:length(roiTs),
    roiTs{AreaNo}.dat = detrend(roiTs{AreaNo}.dat);
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

% check values by roiTs.dx.
nyq = (1/roiTs{1}.dx)/2;
ilen = size(roiTs{1}.dat,1);
len = round(ilen/4);
if ICUTOFFHIGH > nyq
  fprintf(' grpareats: ICUTOFFHIGH is out of nyq frequency.');
  fprintf(' roiTs{1}.dx=%.2f\n',roiTs{1}.dx);
  ICUTOFFHIGH = 0;
  keyboard
end
if ICUTOFF > nyq
  fprintf(' grpareats: ICUTOFF is out of nyq frequency.');
  fprintf(' roiTs{1}.dx=%.2f\n',roiTs{1}.dx);
  ICUTOFF = 0;
  keyboard
end

if ICUTOFF & ICUTOFFHIGH,
  fprintf(' bandpass[%.3f-%.3f].',ICUTOFFHIGH,ICUTOFF);
  [b,a] = butter(3,[ICUTOFFHIGH ICUTOFF]/nyq,'bandpass');
elseif ICUTOFF,
  fprintf(' lowpass[%.3f].',ICUTOFF);
  [b,a] = butter(4,ICUTOFF/nyq,'low');
elseif ICUTOFFHIGH,
  fprintf(' highpass[%.3f].',ICUTOFFHIGH);
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

% ===================================================================
% THIS STEP WILL ADD AN .r FIELD TO THE roiTs STRUCTURE
% roiTs = matscor(roiTs,mdlsct) CAN BE CALLED WITH MODEL(S)
% IF NOT, THEN EXPGETSTM(SES,EXPNO,'HEMO') IS USED
% CORMAP = MATSMAP(roiTs,0.6); CAN BE CALLED TO OBTAIN COR MAPS
% MATSMAP WITHOUT ARGUMENTS WILL DISPLAY THE MAPS
% ===================================================================
if ICORANA,
  fprintf(' matscor.');
  grp = getgrp(Ses,ExpNo);
  if strncmp(grp.name,'spon',4) | strncmp(grp.name,'base',4),
    for N=1:length(roiTs),
      roiTs{N}.r{1} = ones(1,size(roiTs{N}.dat,2));
      roiTs{N}.p{1} = zeros(1,size(roiTs{N}.dat,2));
    end;
  else
    mdlsct{1} = expgetstm(Ses,ExpNo,'hemo');
    if TrialID >= 0,
      pars = getsortpars(Ses,ExpNo);
      TrialIndex = findtrialpar(pars,TrialID);
      for N=1:length(roiTs),
        tmproiTs{N} = sigsort(roiTs{N},pars.trial);
        tmproiTs{N} = tmproiTs{N}{TrialIndex};
      end;
      mdlsct{1} = sigsort(mdlsct{1},pars.trial);
      mdlsct{1} = mdlsct{1}{TrialIndex};
      tmproiTs = matscor(tmproiTs,mdlsct);
      for N=1:length(roiTs),
        roiTs{N}.r = tmproiTs{N}.r;
        roiTs{N}.p = tmproiTs{N}.p;
      end;
    else
      roiTs = matscor(roiTs,mdlsct);
    end;
  end;
else
  for N=1:length(roiTs),
    roiTs{N}.r{1} = ones(1,size(roiTs{N}.dat,2));
    roiTs{N}.p{1} = zeros(1,size(roiTs{N}.dat,2));
  end;
end;

% CONVERT DATA IN UNITS OF STANDARD DEVIATION
if ITOSDU,
  if ITOSDU == 1,
    epoch = 'prestim';
  else
    epoch = 'blank';
  end;
  fprintf(' tosdu[%s].',epoch);
  for AreaNo = 1:length(roiTs),
    roiTs{AreaNo} = xform(roiTs{AreaNo},'tosdu',epoch,IHEMODELAY,IHEMOTAIL);
  end;
end;
fprintf('\n');

% PLOT RESULTS
if IPLOT,
  dsproits(roiTs);
end;

for AreaNo = 1:length(roiTs),
  roiTs{AreaNo}.info = ARGS;
  roiTs{AreaNo}.info.date = date;
  roiTs{AreaNo}.info.time = gettimestring;
end;

if ~nargout,
  filename = strcat(GrpName,'.mat');
  if exist(filename,'file'),
    save(filename,'-append','roiTs');
  else
    save(filename,'roiTs');
  end;
end;


