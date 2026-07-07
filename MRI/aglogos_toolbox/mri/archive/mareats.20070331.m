function roiTs = mareats(SESSION,ExpNo,ARGS)
%MAREATS - Select and process the time series of selected ROIs or Areas
% MAREATS (SESSION, ExpNo, ARGS) extracts the time series for each of the permissible ROIs
% defined with the sesroi(SesName) utility.  The areas noted as "excluded"
% (e.g. IEXCLUDE={'brain';'ele'}) are not taken into account.
%
% The selection of time series depends on individual projects. There are two general
% categories: (a) Projects in which the voxel identity is important; representative example is
% the "dynamic connectivity" project, in which dependence measures are determining the strength
% of connectivity between brain sites, and (b) Projects in which the exact voxel identity is
% irrelevant; an example, here, is the study of BOLD nonlinearities during brief-pulse
% stimulation. In this project the response of a region or area (e.g. V1, ele) is averaged
% across all voxels in the area, and this average response is compared with neural activity and
% so on and so forth.
%
% Both the IEXCLUDE and the ICONCAT fields will be different in the two types of project. To
% avoid editing this function or passing long lists of arguments, the IEXCLUDE, ICONCAT,
% etc. may be defined in the description file, as follows:
%
% DYNAMIC CONNECTIVITY
%       ANAP.mareats.IEXCLUDE = {'brain';'ele';};
%       ANAP.mareats.ICONCAT  = 0;
% BRIEF PULSES
%       ANAP.mareats.IEXCLUDE = {'brain';'ele';'test'};
%       ANAP.mareats.ICONCAT  = 1;
%
% The 'test' ROI is not needed for the second type of projects. It is used in the dependence
% studies to denote an area that is certainly not modulated by the stimulus.
%
% The ROIs are assumed to be already determined in the Ses.roi structure, including the
% following fields:
%       ROI.groups = {'all'};
%       ROI.names	= {'brain';'v1';'v2';'test'};
%       ROI.model	= 'v1';
% For details regarding these definitions type "hroi" To define the actual ROIs type
% "sesroi(SesName)".
%
% In the first category of projects, MAREATS returns a cell array which has the time series of
% each permissible (not excluded) ROI as defined by sesroi. This means, that multiple ROIs in a
% single cortical area will appear as different members of the cell array. This arrangments
% ensure the preservation of the convexity-constraint for ROI definition, which in turn
% warrants a Euclidean distance definition that corresponds as closely as possible to axonal
% distance (geodesic).
% A sample output of the function is seen here for the first value
%       session: 'j02x31'   Refers to the session name
%       grpname: 'gpatrc2'  Refers to the group name
%         ExpNo: 80         Experiment number
%           dir: [1x1 struct]   Some directories
%           dsp: [1x1 struct]
%           grp: [1x1 struct]
%           evt: [1x1 struct]
%           stm: [1x1 struct]
%           ele: {}
%            ds: [0.7500 0.7500 2]
%            dx: 1
%           ana: [90x64x5 double]
%          name: 'Brain'          Refers to the ROI selected
%         slice: -1
%        coords: [20842x3 double]   Tal Coords
%     roiSlices: [1 2 3 4 5]        The number of slices to display
%           dat: [128x20842 double]  IMPORTANT THIS IS THE
%           ACTUAL DATA FROM EACH VOXEL
%           mdl: {[128x1 double]  [128x1 double]  [128x1 double]  [128x1
%           double]  [128x1 double]}  The model you would use for the
%           General Linear Model
%             r: {[20842x1 double]}
%             p: {[20842x1 double]}
%          info: [1x1 struct]
%
% In the second category MAREATS returns a cell array, each member of which is a cortical area
% as defined in the Ses.roi.names, barring the exclude areas.
%
% Note that the output of the MAREATS in the first project-category can be still concatanated
% by using the MROITSCAT (see below);
%
% See also SESROI SESTCIMG MROI MROIGET MTCFROMCOORDS MROICAT MROITSCAT
%
% MTIMESERIES - Function to obtain the time series of voxels of a ROI Usage: MTIMESERIES
% (tcImg, Roi, RoiName) uses the ROI information in the structure Roi and select time series
% for each defined area or subregion in the structure;
%
% MROICAT - Concatanate all rois of the same area in a slice Usage: MyRoi = MROICAT (MyRoi);
% If, for example, we have right/left "V1", this operation will make the separate "V1" (left)
% and "V1" (right) one single area by or-ing the masks and concatanating the coordinates Called
% by: MTIMESERIES
%
% MROIGET - Select one area with one or multiple concatanated rois Usage: oRoi =
% mroiget(oRoi,[],RoiName); Called by: MTIMESERIES
%
% MTCFROMCOORDS - Get the time course of the signals for each voxel Usage:
% tc=mtcfromcoords(tcImg,coords); The function returns the time series of the voxels having
% coordinates "coords"; The coordinates are defined in the "save" case of the Main_Callback of
% the MROIGUI script; The tc (time courses) are processed according to the switches defined in
% "ARGS" Called by: MTIMESERIES
%
% MROITSCAT - Concatanates the ROI-based roiTs cell array members Usage: roiTs = MROITSCAT
% (roiTs);
%
% MATSCOR - Compute correlation coefficients for model mdlsct roiTs = matscor(roiTs,mdlsct) can
% be called with model(s) if not, then expgetstm(ses,expno,'hemo') is used Called by: MAREATS
%
% CORMAP = MATSMAP(roiTs,0_6); can be called to obtain cor maps matsmap without arguments will
% display the maps Called by: DSPROITS
%
% DSPROITS (roiTs) displays the cor maps and time courses; The display-format of the function
% depends on the roiTs type; Conctacatanated roiTs structures will display one time course per
% area, while roiTs of the first project-category will display the time courese of each
% independent ROI
%
% MROITSSEL - Further selects roiTs on the basis of the r-value
% Usage: roiTs = MROITSSEL (roiTs).
%
% EXAMPLES:
% ====================================================================================
% roiTs = mareats('f01pr1',1);  Based on Ses.anap.mareats will
% extract the area time series (individual time series are unimportant).
% tmp = mroitssel(roiTs,0.5); or dsproits(mroitssel(roiTs,0.4))
%
% roiTs = mareats('m02lx1',1);
% ICONCAT = 0; matsfft. matscor. tosdu.dsproits(mroitssel(roiTs,0.25));
% ICONCAT = 1; croiTs = mareats('m02lx1',1); dsproits(mroitssel(mroitscat(croiTs),0.25));
% The result of the above actions should be equivalent..
%
% NKL 12.03.04
% Chand 03 Nov 2005
  
if nargin < 2,  eval(sprintf('help %s;',mfilename)); return;  end


DEF.IEXCLUDE        = {'brain'};
DEF.ICONCAT         = 0;        % Concatante regions & slices
DEF.ISUBSTITUDE     = 0;
DEF.IDETREND        = 1;
DEF.IMIMGPRO        = 0;        % Preprocessing by mimgpro.m
DEF.IFILTER         = 0;		% Filter w/ a small kernel
DEF.IFILTER_KSIZE   = 3;		% Kernel size
DEF.IFILTER_SD      = 1.5;	% SD (if half about 90% of flt in kernel)

DEF.IFFTFLT         = 0;        % FFT filtering
DEF.IARTHURFLT      = 1;        % The breath-remove of A. Gretton
DEF.ICUTOFF         = 0.750;    % Lowpass temporal filtering
DEF.ICUTOFFHIGH     = 0.055;    % Highpass temporal filtering
DEF.ICORWIN         = 0;
DEF.ITOSDU          = 2;
DEF.IHEMODELAY      = 2;
DEF.IHEMOTAIL       = 5;
DEF.IPLOT           = 0;

if exist('ARGS','var'),
  if isempty(ARGS),     % Do nothing; only select time series
    fprintf('mareats: All ARGS are set to zero\n');
    ARGS.IEXCLUDE        = {'brain';'ele';'test'};
    ARGS.ICONCAT         = 0;
    ARGS.IMIMGPRO        = 0;
    ARGS.IFFTFLT         = 0;
    ARGS.IARTHURFLT      = 0;
    ARGS.ICUTOFF         = 0;
    ARGS.ICUTOFFHIGH     = 0;
    ARGS.IDETREND        = 0;
    ARGS.ITOSDU          = 2;
    ARGS.IHEMODELAY      = 2;
    ARGS.IHEMOTAIL       = 5;
    ARGS.IPLOT           = 0;
  end;
  ARGS = sctcat(ARGS,DEF);
else
  ARGS = DEF;
end;

% =========================================================================================
% READ DATA AND CHECK FLAGS THAT ARE SESSION-SPECIFIC
% NOTE: mareats will accept flags as arguments. Session-specific requirements, however, can
% be placed into the Ses.anap.mareats field. These definition will overwrite any other
% definition through the ARGS input variable or the default values defined in DEF.
% =========================================================================================
Ses = goto(SESSION);                    % Read session info
grp = getgrp(Ses,ExpNo);
anap = getanap(Ses,grp);


fprintf(' %s %s: ',datestr(now,'HH:MM:SS'),mfilename);

if isfield(anap,'mareats') & ~isempty(anap.mareats),
  fprintf('anap(%d).',length(fieldnames(anap.mareats)));
  ARGS = sctmerge(ARGS,anap.mareats);
end
pareval(ARGS);  % evaluate ARGS.xxxx as XXXX.


fprintf('loading.');



% LOAD Roi
if ~exist('roi.mat','file'),
  fprintf('mareats: Roi.mat does not exist; Run mroigui\n');
  return;
end;
Roi = matsigload('roi.mat',grp.grproi); % Load the ROI of that group

% LOAD THE ACTUAL DATA
if exist('GrpName','var'),
  % tcImg.mat contains the average tcImg data of each group!
  % These data can be used to extract roiTs and apply correlation analysis
  filename = 'tcImg.mat';
  tcImg = matsigload(filename,GrpName);
  if isempty(tcImg),
    fprintf('structure %s was not found in tcImg.mat\n');
    keyboard;
  end;
else
  tcImg = sigload(Ses,ExpNo,'tcImg');
end;

if isempty(tcImg),
  fprintf('mareats: No data in tcImg of file %s\n',...
          catfilename(Ses,ExpNo,'tcImg'));
  return;
end;

% =========================================================================================
%     CHECKS EXISTING roiTs
% =========================================================================================
matfile = catfilename(Ses,ExpNo,'mat');
if exist(matfile,'file') & any(strcmpi(who('-file',matfile),'roiTs')),
  roiTs = sigload(Ses,ExpNo,'roiTs');
  if ~isempty(roiTs),
    if ICONCAT,
      PROC_ROI = ones(1,length(Ses.roi.names));
      KEEP_SIG = zeros(1,length(roiTs));
      for RoiNo = 1:length(Ses.roi.names),
        if any(strcmpi(IEXCLUDE,Ses.roi.names{RoiNo})),
          continue;
        end;
        tmp = mtimeseries(tcImg,Roi,Ses.roi.names{RoiNo});
        if isempty(tmp),
          PROC_ROI(RoiNo) = 0;
          continue;
        end
        for N = 1:length(roiTs),
          if strcmpi(roiTs{N}.name,Ses.roi.names{RoiNo}),
            if isequal(tmp.coords(:),roiTs{N}.coords(:)),
              if subIsSameARGS(ARGS,roiTs{N}.info),
                KEEP_SIG(N) = 1;
                PROC_ROI(RoiNo) = 0;
                break;
              end
            end
          end
        end
        clear tmp;
      end
      Ses.roi.names = Ses.roi.names(find(PROC_ROI));
      roiTs         = roiTs(find(KEEP_SIG));
      if isempty(Ses.roi.names),
        return
      end
      fprintf('update[%s',Ses.roi.names{1});
      for RoiNo = 2:length(Ses.roi.names),  fprintf(' %s',Ses.roi.names{RoiNo});  end
      fprintf(']');
      roiTsKEEP = roiTs;  % will be used later to cat roiTs
    else
      fprintf(' too complicated, write code here.\n');
      keyboard
    end
  end
  clear roiTs;
end
clear matfile;



% compute a time course of centroid, for sorting of awake data
if ~isfield(tcImg,'centroid'),
  tcImg.centroid = mcentroid(tcImg.dat,tcImg.ds);
end




% =========================================================================================
%                       PROCESSING OF DATA & CORRELATION ANALYSIS
% =========================================================================================
%
% PROCESS VOLUMES
% OtcImg = MIMGPRO(tcImg,ARGS) preprocess the tcImg structure to optimize it for correlation
% analysis. The filters and other operations can be defined through ARGS. Defaults are:
%
% DEF.IFILTER                 = 0;		Filter w/ a small kernel
% DEF.IFILTER_KSIZE           = 3;		Kernel size
% DEF.IFILTER_SD              = 1.5;	SD (if half about 90% of flt in kernel)
% DEF.IDETREND                = 1;		Linear detrending
% DEF.ITOSDU                  = 0;		Convert to SD Units
% DEF.ITMPFILTER              = 0;		Reduce samp. rate by this factor
% DEF.ITMPFLT_LOW             = 0.05;	Reduce samp. rate by this factor
% DEF.ITMPFLT_HIGH            = 0.005;  Remove slow oscillations
%
% NOTE: This function is not used much because it processes the entire images and it is time
% consuming. If however spatial filtering is required, one has to do it before splitting the
% data into regions of interest; then IMIMGPRO should be used. Sessions requiring this usage
% can set the Ses.anap.mareats.IMIMGPRO flag.
%
% The function is also recommended when analyzing old data or data from other projects
% (e.g. Glass patterns) which do not have an updated stm field or they have magnetization
% transients as a result of not having dummy scans. One has to pay attention to not
% duplicate operations, such as detrending, tosdu etc.
%
if IMIMGPRO,
  IARG.ISUBSTITUDE             = 0;		% Filter w/ a small kernel
  IARG.IFILTER                 = IFILTER;
  IARG.IFILTER_KSIZE           = IFILTER_KSIZE;
  IARG.IFILTER_SD              = IFILTER_SD;
  IARG.IDETREND                = 0;		% Linear detrending
  IARG.ITOSDU                  = 0;		% Convert to SD Units
  IARG.ITMPFILTER              = 0;		% Reduce samp. rate by this factor
  IARG.ITMPFLT_LOW             = 0;
  IARG.ITMPFLT_HIGH            = 0;
  fprintf(' mimgpro.');
  tcImg = mimgpro(tcImg,IARG);
end;

TrialID = -1;
if isfield(grp,'actmap') & length(grp.actmap) > 1,
  TrialID = grp.actmap{2};
end;


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
rts.ana       = mean(tcImg.dat,4);
rts.centroid  = tcImg.centroid;

roiTs = {};
% ===================================================================
% SELECT TIME SERIES ON THE BASIS OF GROUP-ROIS
% ===================================================================
ValidRoiNo = 1;
if ICONCAT,
  for RoiNo=1:length(Ses.roi.names),
    if any(strcmpi(IEXCLUDE,Ses.roi.names{RoiNo})),
      continue;
    end;

    % The function mtimeseries(tcImg,Roi,Name) returns:
    %     name: 'v1'
    %      mask: [84x84x2 double]
    %       ntc: {[1 969]  [970 2011]}
    %        ix: [2011x1 double]
    %    coords: [2011x3 double]
    % roiSlices: [double]
    %       dat: [256x2011 double]
    % We use only the name, coords, and dat fields  !!!

    tmp = mtimeseries(tcImg,Roi,Ses.roi.names{RoiNo});
    if isempty(tmp),
      continue;
    end;

    roiTs{ValidRoiNo}           = rts;
    roiTs{ValidRoiNo}.name      = tmp.name;

    % roiTs{ValidRoiNo}.mask    = tmp.mask; Beg/End of slices
    % roiTs{ValidRoiNo}.ntc     = tmp.ntc;  Beg/End of slices
    % roiTs{ValidRoiNo}.ix      = tmp.ix;   Find(mask(:))

    roiTs{ValidRoiNo}.slice     = -1;       % All slices concat-ed
    roiTs{ValidRoiNo}.coords    = tmp.coords;
    roiTs{ValidRoiNo}.roiSlices = tmp.roiSlices;
    roiTs{ValidRoiNo}.dat       = tmp.dat;
    ValidRoiNo = ValidRoiNo + 1;
  end;
else
  for RoiNo=1:length(Roi.roi),
    if any(strcmpi(IEXCLUDE,Roi.roi{RoiNo}.name)),
      continue;
    end;
    roiTs{ValidRoiNo} = rts;
    roiTs{ValidRoiNo}.name = Roi.roi{RoiNo}.name;
    roiTs{ValidRoiNo}.slice = Roi.roi{RoiNo}.slice;

    [x,y] = find(Roi.roi{RoiNo}.mask);
    if max(x(:))>size(tcImg.dat,1) | max(y(:))>size(tcImg.dat,2),
      fprintf('MAREATS: Mask is greater than the actual image\n');
      size(tcImg.dat)
      size(Roi.roi{RoiNo}.mask)
      keyboard;
    end;
    roiTs{ValidRoiNo}.coords = [x y ones(length(x),1)*roiTs{ValidRoiNo}.slice];
    roiTs{ValidRoiNo}.dat = mtcfromcoords(tcImg,roiTs{ValidRoiNo}.coords);

    ValidRoiNo = ValidRoiNo + 1;
  end;
end;

% NO NEED of tcImg.dat...
tcImg.dat = [];
% NO NEED of Roi...
clear Roi;

% REMOVE RESPIRATION ARTIFACTS AND LOWPASS FITLER BY USING INVERTING THE FFT-SPECTRUM
if ISUBSTITUDE,
  fprintf(' substitude[%d].',ISUBSTITUDE);
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
    tmp = mean(roiTs{AreaNo}.dat,1);
    roiTs{AreaNo}.dat = detrend(roiTs{AreaNo}.dat);
    roiTs{AreaNo}.dat = roiTs{AreaNo}.dat + repmat(tmp,[size(roiTs{AreaNo}.dat,1) 1]);
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
if ICUTOFFHIGH > nyq
  fprintf('\n mareats: ICUTOFFHIGH=%g is out of nyq frequency.',ICUTOFFHIGH);
  fprintf(' roiTs{1}.dx=%g, nyqf=%g\n',roiTs{1}.dx,nyq);
  ICUTOFFHIGH = 0;
  keyboard
end
if ICUTOFF > nyq
  fprintf('\n mareats: ICUTOFF=%g is out of nyq frequency.',ICUTOFF);
  fprintf(' roiTs{1}.dx=%g, nyqf=%g\n',roiTs{1}.dx,nyq);
  ICUTOFF = 0;
  keyboard
end

if ICUTOFF & ICUTOFFHIGH,
  fprintf(' bandpass[%g-%g].',ICUTOFFHIGH,ICUTOFF);
  [b,a] = butter(4,[ICUTOFFHIGH ICUTOFF]/nyq,'bandpass');
elseif ICUTOFF,
  fprintf(' lowpass[%g].',ICUTOFF);
  [b,a] = butter(4,ICUTOFF/nyq,'low');
elseif ICUTOFFHIGH,
  fprintf(' highpass[%g].',ICUTOFFHIGH);
  [b,a] = butter(4,ICUTOFFHIGH/nyq,'high');
end;

% NOTE THAT 'DATOFFS' is computed for normalization below.
if ICUTOFF | ICUTOFFHIGH,
  % prepare index for mirroring
  dlen   = size(roiTs{1}.dat,1);
  flen   = max([length(b),length(a)]);
  idxfil = [flen+1:-1:2 1:dlen dlen-1:-1:dlen-flen-1];
  idxsel = [1:dlen] + flen;
  
  for AreaNo = 1:length(roiTs),
    DATOFFS{AreaNo} = hnanmean(roiTs{AreaNo}.dat,1);
    for N=1:size(roiTs{AreaNo}.dat,2),
      tmp = roiTs{AreaNo}.dat(idxfil,N);
      tmp = filtfilt(b,a,tmp);
      roiTs{AreaNo}.dat(:,N) = tmp(idxsel);
    end;
  end;
else
  DATOFFS = {};
end;


% ===================================================================
% THIS STEP WILL ADD AN .r FIELD TO THE roiTs STRUCTURE
% roiTs = matscor(roiTs,mdlsct) CAN BE CALLED WITH MODEL(S)
% IF NOT, THEN EXPGETSTM(SES,EXPNO,'HEMO') IS USED
% CORMAP = MATSMAP(roiTs,0.6); CAN BE CALLED TO OBTAIN COR MAPS
% MATSMAP WITHOUT ARGUMENTS WILL DISPLAY THE MAPS
% ===================================================================
%%% HACKED IN BY CHAND TO GET THE MODEL INCORPORATED INTO THE SYSTEM
%%% WITHOUT DOING COREELATION ANALYSIS.
%%% 3 Nov 2005

ICORANA=0;
if ICORANA,
  fprintf(' matscor.');
  grp = getgrp(Ses,ExpNo);
  if strncmp(grp.name,'spon',4) | strncmp(grp.name,'base',4),
    for N=1:length(roiTs),
      roiTs{N}.r{1} = ones(size(roiTs{N}.dat,2),1);
      roiTs{N}.p{1} = zeros(size(roiTs{N}.dat,2),1);
      % OLD CODE
      %roiTs{N}.r{1} = ones(1,size(roiTs{N}.dat,2));
      %roiTs{N}.p{1} = zeros(1,size(roiTs{N}.dat,2));
    end;
  else

    % CHECK WHETHER WE USE THE NEURAL SIGNAL AS MODEL
    if isfield(grp,'model'),
      mdlsct = mkmultreggeneral(Ses,ExpNo);
    else
      mdlsct{1} = expgetstm(Ses,ExpNo,'hemo');
    end;

    % TRIAL BASED
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

      % OBSERVATION PERIOD BASED
      if ~ICORWIN,       % Apply cor analysis for the entire obsp
        roiTs = matscor(roiTs,mdlsct);
      else
        ICORWIN = round(ICORWIN./roiTs{1}.dx)+1;
        if ICORWIN(4)>size(roiTs{1}.dat,1),
          ICORWIN(4) = size(roiTs{1}.dat,1);
        end;
        for K=1:length(roiTs),
          tmpTs{K} = rmfield(roiTs{K},'dat');
          tmpTs{K}.dat = roiTs{K}.dat([ICORWIN(1):ICORWIN(2) ICORWIN(3):ICORWIN(4)],:,:);
        end;
        tmpsct = mdlsct;
        tmpsct{1}.dat = tmpsct{1}.dat([ICORWIN(1):ICORWIN(2) ICORWIN(3):ICORWIN(4)]);
        tmpTs = matscor(tmpTs,tmpsct);
        for K=1:length(roiTs),
          roiTs{K}.r = tmpTs{K}.r;
          roiTs{K}.p = tmpTs{K}.p;
          roiTs{K}.coords = tmpTs{K}.coords;
        end;
        clear tmpTs;
      end;
    end;
  end;
else
  for N=1:length(roiTs),
    roiTs{N}.r{1} = ones(size(roiTs{N}.dat,2),1);
    roiTs{N}.p{1} = zeros(size(roiTs{N}.dat,2),1);
    % OLD CODE
    %roiTs{N}.r{1} = ones(1,size(roiTs{N}.dat,2));
    %roiTs{N}.p{1} = zeros(1,size(roiTs{N}.dat,2));
  end;
end;

% CONVERT DATA IN UNITS OF STANDARD DEVIATION

if ITOSDU,
  method = 'tosdu';
  if ITOSDU == 1,
    epoch = 'prestim';
  elseif ITOSDU == 2,
    epoch = 'blank';
  else
    epoch = 'blank';
    method = 'zerobase';
  end;
  fprintf(' %s[%s].',method, epoch);
  for AreaNo = 1:length(roiTs),
    roiTs{AreaNo} = xform(roiTs{AreaNo},method,epoch,IHEMODELAY,IHEMOTAIL);
  end;
else
  % No normalization, but need to recover DC offsets removed by temporal filtering
  for AreaNo = 1:length(DATOFFS),
    for N = 1:size(roiTs{AreaNo}.dat,2),
      roiTs{AreaNo}.dat(:,N) = roiTs{AreaNo}.dat(:,N) + DATOFFS{AreaNo}(N);
    end
  end
end;
fprintf('\n');

% THE GLM ANALYSIS RUNS INDEPENDENT OF THIS MODULE
% RUN MAREATS AND THEN SESGLMANA
% if IGLM
%     MatFileName = catfilename(SESSION,ExpNo,'glm');
%     %     if exist(MatFileName)
%     %         disp('Using Existing Mat Files for the GLM Output');
%     %         temp = load(MatFileName);
%     %         for nroi = 1:length(roiTs)
%     %             roiTs{nroi}.glmoutput = temp.dataglm{nroi}.glmoutput;
%     %         end
%     %     else
%    
%     disp('Computing the General Linear Model');
%     roiTs = runreducedglm(roiTs);
%    
%     % end
% end


% PLOT RESULTS
if IPLOT,
  dsproits(roiTs);
end;

for AreaNo = 1:length(roiTs),
  roiTs{AreaNo}.info = ARGS;
  roiTs{AreaNo}.info.date = date;
  roiTs{AreaNo}.info.time = gettimestring;
end;


if exist('roiTsKEEP','var') & ~isempty(roiTsKEEP),
  for AreaNo = 1:length(roiTs),
    roiTsKEEP{end+1} = roiTs{AreaNo};
  end
  roiTs = roiTsKEEP;
  clear roiTsKEEP;
end


if ~nargout,
  if isfield(Ses.roi,'append') & Ses.roi.append,
    tmp = roiTs;
    roiTs = sigload(SESSION,ExpNo,'roiTs')';
    len = length(roiTs);
    for N=1:length(tmp),
      roiTs{len+N} = tmp{N};
    end;
  end;
  filename = catfilename(Ses,ExpNo,'mat');
  if exist(filename,'file'),
    save(filename,'-append','roiTs');
  else
    save(filename,'roiTs');
  end;
end;




function V = subIsSameARGS(ARGS,info)
V = 1;
fnames = fieldnames(ARGS);
for N = 1:length(fnames),
  if ~isfield(info,(fnames{N})),
    V = 0;  break;
  end
  if ~isequal(ARGS.(fnames{N}),info.(fnames{N})),
    V = 0;  break;
  end
end

%ARGS.(fnames{N})
%info.(fnames{N})


return
