function [roiTs IsChanged] = mareats(Ses,ExpNo,SigName,ARGS)
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
% NOTES :
%   Analysis parameter can be controled by ...
%     ANAP.mareats          or ANAP.(signame).mareats
%     GRP.xxx.anap.mareats  or GRP.xxx.anap.(signame).mareats
%
%     ANAP.mareats.IEXCLUDE        = {'brain'};
%     ANAP.mareats.ICONCAT         = 0;     % Concatante regions & slices
%     ANAP.mareats.ISUBSTITUDE     = 0;
%     ANAP.mareats.IRESAMPLE       = 0;
%     ANAP.mareats.IDETREND        = 1;
%
%     ANAP.mareats.IMIMGPRO        = 0;     % Preprocessing by mimgpro.m
%     ANAP.mareats.IFILTER         = 0;		% Filter w/ a small kernel
%     ANAP.mareats.IFILTER_KSIZE   = 3;		% Kernel size
%     ANAP.mareats.IFILTER_SD      = 1.5;	% SD (if half about 90% of flt in kernel)
%     ANAP.mareats.IFILTER3D               = 0;        % 3D smoothing
%     ANAP.mareats.IFILTER3D_KSIZE_mm      = 3;        % Kernel size in mm
%     ANAP.mareats.IFILTER3D_FWHM_mm       = 1.0;      % FWHM of Gaussian in mm
%
%     ANAP.mareats.IROIFILTER       = 0;    % spatial filter with ROI masking
%     ANAP.mareats.IROIFILTER_KSIZE = ANAP.mareats.IFILTER_KSIZE;
%     ANAP.mareats.IROIFILTER_SD    = ANAP.mareats.IFILTER_SD;
%
%     ANAP.mareats.IFFTFLT         = 0;     % FFT filtering
%     ANAP.mareats.IARTHURFLT      = 1;     % The breath-remove of A. Gretton
%     ANAP.mareats.ICUTOFF         = 0.750; % Lowpass temporal filtering
%     ANAP.mareats.ICUTOFFHIGH     = 0.055; % Highpass temporal filtering
%     ANAP.mareats.ICORWIN         = 0;
%     ANAP.mareats.ITOSDU          = 2;     % can bel like {'sdu','prestim'}
%     ANAP.mareats.IHEMODELAY      = 2;
%     ANAP.mareats.IHEMOTAIL       = 5;
%     ANAP.mareats.IPLOT           = 0;
%
%     ANAP.mareats.COMPUTE_SNR     = 1;     % Compute SNR or not
%     ANAP.mareats.USE_REALIGNED   = 0;     % Use realigned tcImg or not
%     ANAP.mareats.SMART_UPDATE    = 1;     % checks existing roiTs or not
%  
%  VERSION :
%    1.00 12.03.04 NKL
%    1.01 03.11.05 Chand
%    1.02 16.04.07 YM  if no ROI, then select all voxels for quick analysis.
%    1.03 15.11.07 YM  ITOSDU can be a cell array of {'method','epoch'}
%    1.04 25.11.10 YM  computes SNR as .snr
%    1.05 30.03.11 YM  supports IROIFILTER
%    1.06 17.01.12 YM  supports IFILTER3D, SigName.
%    1.07 29.01.12 YM  .ana/.snr as 'single' for less memory.
%    1.08 03.02.12 YM  .ana as int16() for less memory.
%    1.10 06.02.12 YM  removed codes for corana, use sescorana().
%
%  See also sesareats mimgpro sigdetrend matsfft matsrmresp dispderiv roifilt2 xform

if nargin < 2,  eval(sprintf('help %s;',mfilename)); return;  end


DEF.IEXCLUDE        = {'brain'};
DEF.ICONCAT         = 0;        % Concatante regions & slices
DEF.ISUBSTITUDE     = 0;
DEF.IRESAMPLE       = 0;
DEF.IDETREND        = 1;
DEF.IMIMGPRO        = 0;        % Preprocessing by mimgpro.m
DEF.IFILTER         = 0;		% Filter w/ a small kernel
DEF.IFILTER_KSIZE   = 3;		% Kernel size
DEF.IFILTER_SD      = 1.5;	% SD (if half about 90% of flt in kernel)
DEF.IFILTER3D               = 0;        % 3D smoothing
DEF.IFILTER3D_KSIZE_mm      = 3;        % Kernel size in mm
DEF.IFILTER3D_FWHM_mm       = 1.0;      % FWHM of Gaussian in mm


% Spatial filter with ROI masking, see roifilt2()
DEF.IROIFILTER       = 0;
DEF.IROIFILTER_KSIZE = DEF.IFILTER_KSIZE;
DEF.IROIFILTER_SD    = DEF.IFILTER_SD;


DEF.IPCA            = 0;
DEF.IFFTFLT         = 0;        % FFT filtering
DEF.IARTHURFLT      = 1;        % The breath-remove of A. Gretton
DEF.IRADIUS         = 0;        % Radius in mm to compute dispersion derivative!
DEF.ICUTOFF         = 0.750;    % Lowpass temporal filtering
DEF.ICUTOFFHIGH     = 0.055;    % Highpass temporal filtering
DEF.ICORWIN         = 0;
DEF.ITOSDU          = 2;
DEF.IHEMODELAY      = 2;
DEF.IHEMOTAIL       = 5;
DEF.ISHIFT          = 0;        % Shift left (<0) or right (>0) for slow scans
DEF.IRESAMPLE       = 0;        % Shift left (<0) or right (>0) for slow scans
DEF.IPLOT           = 0;


DEF.COMPUTE_SNR     = 1;        % Compute SNR
DEF.USE_REALIGNED   = 0;        % Use realigned tcImg or not
DEF.SMART_UPDATE    = 1;        % checks existing roiTs or not

if ~exist('SigName','var'),  SigName = 'roiTs';  end

if exist('ARGS','var'),
  if isempty(ARGS),     % Do nothing; only select time series
    fprintf('mareats: All ARGS are set to zero\n');
    ARGS.IEXCLUDE        = {'brain';'ele';'test'};
    ARGS.ICONCAT         = 0;
    ARGS.IMIMGPRO        = 0;
    ARGS.IFFTFLT         = 0;
    ARGS.IARTHURFLT      = 0;
    ARGS.IRADIUS         = 0;        % Radius in mm to compute dispersion derivative!
    ARGS.ICUTOFF         = 0;
    ARGS.ICUTOFFHIGH     = 0;
    ARGS.IDETREND        = 0;
    ARGS.ITOSDU          = 2;
    ARGS.IHEMODELAY      = 2;
    ARGS.IHEMOTAIL       = 5;
    ARGS.ISHIFT          = 0;
    ARGS.IRESAMPLE       = 0;
    ARGS.IPLOT           = 0;
    ARGS.IRESAMPLE       = 0;
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
Ses = goto(Ses);                    % Read session info
grp = getgrp(Ses,ExpNo);
anap = getanap(Ses,grp);

fprintf(' %s %s: ',datestr(now,'HH:MM:SS'),mfilename);

if isfield(anap,'mareats') && ~isempty(anap.mareats),
  fprintf('anap(%d).',length(fieldnames(anap.mareats)));
  ARGS = sctmerge(ARGS,anap.mareats);
end
if isfield(anap,SigName) && isfield(anap.(SigName),'mareats'),
  fprintf('%s.anap(%d).',SigName,length(fieldnames(anap.(SigName).mareats)));
  ARGS = sctmerge(ARGS,anap.(SigName).mareats);
end

pareval(ARGS);  % evaluate ARGS.xxxx as XXXX.
if isfield(ARGS,'SMART_UPDATE'),
  % remove this 'SMART_UPDATE' to make subIsSameARGS() to work correctly.
  ARGS = rmfield(ARGS,'SMART_UPDATE');
end


fprintf('loading(tcImg).');

% LOAD THE ACTUAL DATA
if exist('GrpName','var'),
  % tcImg.mat contains the average tcImg data of each group!
  % These data can be used to extract roiTs and apply correlation analysis
  filename = 'tcImg.mat';
  tcImg = matsigload(filename,GrpName);
  if isempty(tcImg),
    fprintf('structure tcImg was not found in tcImg.mat\n');
    keyboard;
  end;
else
  if USE_REALIGNED == 0 && exist(sigfilename(Ses,ExpNo,'tcImg.bak'),'file'),
    fprintf('[tcImg.bak]');
    tcImg = sigload(Ses,ExpNo,'tcImg.bak');
  else
    tcImg = sigload(Ses,ExpNo,'tcImg');
  end
end;

if isempty(tcImg),
  fprintf('mareats: No data in tcImg of file %s\n',...
          sigfilename(Ses,ExpNo,'tcImg'));
  return;
end;

% LOAD Roi
RoiFile = mroi_file(Ses,grp.grproi);
if any(strcmpi(whofile(RoiFile),grp.grproi)),
  Roi = load(RoiFile,grp.grproi);
  Roi = Roi.(grp.grproi);
else
  fprintf('mareats: ''%s'' not in %s, all voxels are included.\n',grp.grproi,RoiFile);
  % cleate Roi structure
  Roi.session = tcImg.session;
  Roi.grpname = tcImg.grpname;
  Roi.roinames = {'all'};
  Roi.dir = tcImg.dir;
  Roi.dsp.func = 'dsproi';
  Roi.dsp.args = {};
  Roi.dsp.label = {};
  Roi.ana = nanmean(tcImg.dat,4);
  Roi.img = Roi.ana;
  Roi.ds  = tcImg.ds;
  for N = 1:size(tcImg.dat,3),
    Roi.roi{N}.name = 'all';
    Roi.roi{N}.slice = N;
    Roi.roi{N}.px    = [];
    Roi.roi{N}.py    = [];
    Roi.roi{N}.mask  = logical(ones(size(tcImg.dat,1),size(tcImg.dat,2)));
  end
  Roi.ele = {};
  
  % update Ses.roi.names also.
  Ses.roi.names = {'all'};
end;


% =========================================================================================
%     CHECKS EXISTING roiTs
% =========================================================================================
if sesversion(Ses) >= 2,
  matfile = sigfilename(Ses,ExpNo,SigName);
else
  matfile = sigfilename(Ses,ExpNo,'mat');
end
IsChanged = 1;
if SMART_UPDATE && exist(matfile,'file') && any(strcmpi(who('-file',matfile),SigName)),
  roiTs = sigload(Ses,ExpNo,SigName);
  if ~isempty(roiTs),
    if ICONCAT,
      PROC_ROI = ones(1,length(Ses.roi.names));
      KEEP_SIG = zeros(1,length(roiTs));
      for RoiNo = 1:length(Ses.roi.names),
        if any(strcmpi(IEXCLUDE,Ses.roi.names{RoiNo})),
          PROC_ROI(RoiNo) = 0;
          continue;
        end;
        tmp = mtimeseries(tcImg,Roi,Ses.roi.names{RoiNo});
        if isempty(tmp),
          PROC_ROI(RoiNo) = 0;
          continue;
        end
        for N = 1:length(roiTs),
          if size(roiTs{N}.dat,1) == size(tcImg.dat,4),
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
        end
        clear tmp;
      end
      Ses.roi.names = Ses.roi.names(PROC_ROI > 0);
      roiTs         = roiTs(KEEP_SIG > 0);
      if isempty(Ses.roi.names),
        % no need to process
        IsChanged = 0;
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
  if length(tcImg.ds) < 3,
    tmppar = expgetpar(Ses,grp.name);
    tcImg.ds(3) = tmppar.pvpar.slithk;
    clear tmppar;
  end
  tcImg.centroid = mcentroid(tcImg.dat,tcImg.ds);
end
% compute mean images along time for roiTs{X}.ana before applying IMGPRO
tcImg.mdat = nanmean(tcImg.dat,4);
maxv = max(tcImg.mdat(:));
minv = min(tcImg.mdat(:));
tcImg.mdat = (tcImg.mdat - minv)/(maxv-minv) * 30000;
tcImg.mdat = int16(round(tcImg.mdat));
clear maxv minv;


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
if any(IMIMGPRO),
  IARG.ISUBSTITUDE             = 0;		% Filter w/ a small kernel
  IARG.IFILTER                 = IFILTER;
  IARG.IFILTER_KSIZE           = IFILTER_KSIZE;
  IARG.IFILTER_SD              = IFILTER_SD;
  IARG.IFILTER3D               = IFILTER3D;
  IARG.IFILTER3D_KSIZE_mm      = IFILTER3D_KSIZE_mm;
  IARG.IFILTER3D_FWHM_mm       = IFILTER3D_FWHM_mm;
  IARG.IDETREND                = 0;		% Linear detrending
  IARG.ITOSDU                  = 0;		% Convert to SD Units
  IARG.ITMPFILTER              = 0;		% Reduce samp. rate by this factor
  IARG.ITMPFLT_LOW             = 0;
  IARG.ITMPFLT_HIGH            = 0;
  fprintf(' mimgpro.');
  tcImg = mimgpro(tcImg,IARG);
end;


TrialID = -1;
if isfield(grp,'actmap') && length(grp.actmap) > 1,
  TrialID = grp.actmap{2};
end;


% ======================================================================
% NOW BUILD THE ROITS STRUCTURE
% ======================================================================
rts.session   = Roi.session;
rts.grpname   = tcImg.grpname;
rts.ExpNo     = tcImg.ExpNo;
%rts.dir       = Roi.dir;
rts.dir.dname = SigName;
%rts.dsp       = Roi.dsp;
%rts.dsp.func  = 'dsproits';
rts.stm       = tcImg.stm;
rts.ele       = Roi.ele;
rts.ana       = tcImg.mdat;
rts.snr       = [];
rts.ds        = tcImg.ds;
rts.dx        = tcImg.dx;
rts.dat       = [];
rts.centroid  = single(tcImg.centroid);
if isfield(tcImg,'stimch'),
  rts.stimch = tcImg.stimch;
end
% now computes SNR
tmpm = nanmean(tcImg.dat,4);
tmps = nanstd(tcImg.dat,[],4);
tmpi = tmps(:) < eps;
tmpm(tmpi) = 0;
tmps(tmpi) = 1;
rts.snr       = tmpm ./ tmps;
rts.snr       = single(rts.snr);
clear tmpm tmps tmpi;


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
    if isempty(tmp),  continue;  end;

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
    if max(x(:))>size(tcImg.dat,1) || max(y(:))>size(tcImg.dat,2),
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
clear Roi;
TCIMG_SIZE = size(tcImg.dat);
tcImg.dat = [];

if length(roiTs) == 0,
  error('\n ERROR %s:  no ROI to process, check anap.mareats.IEXCLUDE or grp.grproi.\n',mfilename);
end



% REMOVE RESPIRATION ARTIFACTS AND LOWPASS FITLER BY USING INVERTING THE FFT-SPECTRUM
if ISUBSTITUDE,
  fprintf(' substitude[%d].',ISUBSTITUDE);
  for AreaNo = 1:length(roiTs),
    idx = getStimIndices(roiTs{AreaNo},'prestim',IHEMODELAY);
    m = hnanmean(roiTs{AreaNo}.dat(idx(ISUBSTITUDE:end),:),1);
    roiTs{AreaNo}.dat(1:ISUBSTITUDE,:) = repmat(m,[ISUBSTITUDE 1]);
  end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DC_removed = 0;  % flag must set as 1 if the processing removes DC offsets
for AreaNo = 1:length(roiTs),
  DATOFFS{AreaNo} = nanmean(roiTs{AreaNo}.dat,1);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% DETREND DATA
if IDETREND,
  fprintf(' detrend.');
  roiTs = sigdetrend(roiTs);
  DC_removed = 1;
end;

if IRESAMPLE,
  fprintf(' resample(%2.2f).',IRESAMPLE);
  roiTs = sigresample(roiTs,IRESAMPLE);
  rts.dx = roiTs{1}.dx;
end

% REMOVE RESPIRATION ARTIFACTS AND LOWPASS FITLER BY USING INVERTING THE FFT-SPECTRUM
if IFFTFLT,
  fprintf(' matsfft.');
  FFTARGS.DOPLOT = IPLOT;
  roiTs = matsfft(roiTs,0,FFTARGS); % Cutoff is set to zero; we do the filtering here
end;

% REMOVE RESPIRATORY ARTIFACTS BY PROJECTING OUT SINUSOIDS
if IARTHURFLT,
  fprintf(' matsrmresp.');
  roiTs = matsrmresp(roiTs);
end;

% check values by roiTs.dx.
nyq = (1/roiTs{1}.dx)/2;
if ICUTOFFHIGH > nyq
  fprintf('\n mareats: ICUTOFFHIGH=%g is out of nyq frequency.',ICUTOFFHIGH);
  fprintf(' %s{1}.dx=%g, nyqf=%g\n',SigName,roiTs{1}.dx,nyq);
  ICUTOFFHIGH = 0;
  fprintf('%s mareats[WARNING]: Skipping highpass temporal filtering\n',gettimestring);
end
if ICUTOFF > nyq
  fprintf('\n mareats: ICUTOFF=%g is out of nyq frequency.',ICUTOFF);
  fprintf(' %s{1}.dx=%g, nyqf=%g\n',SigName,roiTs{1}.dx,nyq);
  ICUTOFF = 0;
  fprintf('%s mareats[WARNING]: Skipping lowpass temporal filtering\n',gettimestring);
end

if ICUTOFF && ICUTOFFHIGH,
  fprintf(' bandpass[%g-%g].',ICUTOFFHIGH,ICUTOFF);
  [b,a] = butter(4,[ICUTOFFHIGH ICUTOFF]/nyq,'bandpass');
  DC_removed = 1;
elseif ICUTOFF,
  fprintf(' lowpass[%g].',ICUTOFF);
  [b,a] = butter(4,ICUTOFF/nyq,'low');
elseif ICUTOFFHIGH,
  fprintf(' highpass[%g].',ICUTOFFHIGH);
  [b,a] = butter(4,ICUTOFFHIGH/nyq,'high');
  DC_removed = 1;
end;

% NOTE THAT 'DATOFFS' is computed for normalization below.
if ICUTOFF || ICUTOFFHIGH,
  % prepare index for mirroring
  dlen   = size(roiTs{1}.dat,1);
  flen   = max([length(b),length(a)]);
  idxfil = [flen+1:-1:2 1:dlen dlen-1:-1:dlen-flen-1];
  idxsel = (1:dlen) + flen;
  
  for AreaNo = 1:length(roiTs),
    for N=1:size(roiTs{AreaNo}.dat,2),
      tmp = roiTs{AreaNo}.dat(idxfil,N);
      tmp = filtfilt(b,a,tmp);
      roiTs{AreaNo}.dat(:,N) = tmp(idxsel);
    end;
  end;
end;

if IPCA,
  fprintf(' PCA[%d].',IPCA);
  for AreaNo = 1:length(roiTs),
    [u, s, v] = svds(roiTs{AreaNo}.dat,IPCA);
    roiTs{AreaNo}.dat = u * s * v';
    % test....
    %tmpm = zeros(100,1); tmpm(25:75) = 0.5;
    %roiTs{AreaNo}.dat = (2*rand(100,50)-1)*0.2 + repmat(tmpm,[1 50]) + 0.5;
    %figure;
    %subplot(2,1,1); plot(roiTs{AreaNo}.dat);  title('original');
    %[u, s, v] = svds(roiTs{AreaNo}.dat,IPCA);
    %subplot(2,1,2); plot(u*s*v');  title('after PCA');
  end;
end;


% NOTE THAT 'DATOFFS' is computed for normalization below.
if ISHIFT,
  fprintf(' shift[%g].',ISHIFT);
  tmpofs = round(ISHIFT/roiTs{1}.dx);
  for AreaNo = 1:length(roiTs),
    if tmpofs < 0,
      ofs = abs(tmpofs);
      roiTs{AreaNo}.dat = cat(1,roiTs{AreaNo}.dat(ofs+1:end,:),roiTs{AreaNo}.dat(1:ofs,:));
    else
      roiTs{AreaNo}.dat = cat(1,roiTs{AreaNo}.dat(1:ofs,:),roiTs{AreaNo}.dat(ofs+1:end-ofs,:));
    end;
  end;
end;

if IRADIUS,
  fprintf(' Dispersion-Derivative[%g].',IRADIUS);
  for AreaNo = 1:length(roiTs),
    roiTs{AreaNo} = dispderiv(roiTs{AreaNo}, IRADIUS);
  end;
end

if any(IROIFILTER),
  fprintf(' roifilt2(sz=%g,sd=%g).',IROIFILTER_KSIZE,IROIFILTER_SD);
  for AreaNo = 1:length(roiTs),
    roiTs{AreaNo} = sub_roifilt2(roiTs{AreaNo},tcImg,IROIFILTER_KSIZE,IROIFILTER_SD,TCIMG_SIZE);
  end
end



% CONVERT DATA IN UNITS OF STANDARD DEVIATION
method = 'none';
if ~isempty(ITOSDU) && iscell(ITOSDU),
  % ITOSDU as like { 'percent', 'blank' }
  method = ITOSDU{1};
  epoch  = ITOSDU{2};
elseif ischar(ITOSDU) && ~isempty(ITOSDU),
  % ITOSDU as like 'tosdu'
  method = ITOSDU;  epoch = 'blank';
elseif any(ITOSDU),
  epoch = 'blank';
  if ITOSDU == 1,
    method = 'tosdu';     epoch = 'prestim';
  elseif ITOSDU == 2,
    method = 'tosdu';     epoch = 'blank';
  else
    method = 'zerobase';  epoch = 'blank';
  end;
end
if isempty(method),  method = 'none';  end
switch lower(method),
 case {'none'}
  % No normalization, but need to recover DC offsets removed by temporal filtering
  if DC_removed,
    fprintf(' DC-recover.');
    for AreaNo = 1:length(DATOFFS),
      for N = 1:size(roiTs{AreaNo}.dat,2),
        roiTs{AreaNo}.dat(:,N) = roiTs{AreaNo}.dat(:,N) + DATOFFS{AreaNo}(N);
      end
    end
  end
 otherwise
  % do some normalization
  if any(strcmpi(method, {'percent' 'percentage' 'frac' 'fraction'})) && DC_removed > 0,
    % need to recover DC offsets
    fprintf(' DC-recover.');
    for AreaNo = 1:length(DATOFFS),
      for N = 1:size(roiTs{AreaNo}.dat,2),
        roiTs{AreaNo}.dat(:,N) = roiTs{AreaNo}.dat(:,N) + DATOFFS{AreaNo}(N);
      end
    end
  end
  fprintf(' %s[%s].',method, epoch);
  for AreaNo = 1:length(roiTs),
    roiTs{AreaNo} = xform(roiTs{AreaNo},method,epoch,IHEMODELAY,IHEMOTAIL);
  end;
end;
fprintf('\n');


if sesversion(Ses) < 2,
  for N=1:length(roiTs),
    roiTs{N}.r{1} = ones(size(roiTs{N}.dat,2),1,'single');
    roiTs{N}.p{1} = zeros(size(roiTs{N}.dat,2),1,'single');
    % OLD CODE
    %roiTs{N}.r{1} = ones(1,size(roiTs{N}.dat,2));
    %roiTs{N}.p{1} = zeros(1,size(roiTs{N}.dat,2));
  end;
end;


% PLOT RESULTS
if IPLOT,
  dsproits(roiTs);
end;

for AreaNo = 1:length(roiTs),
  roiTs{AreaNo}.info = ARGS;
  roiTs{AreaNo}.info.date = date;
  roiTs{AreaNo}.info.time = gettimestring;
end;


if exist('roiTsKEEP','var') && ~isempty(roiTsKEEP),
  for AreaNo = 1:length(roiTs),
    roiTsKEEP{end+1} = roiTs{AreaNo};
  end
  roiTs = roiTsKEEP;
  clear roiTsKEEP;
end


return







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



% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function rts = sub_roifilt2(rts,tcImg,KSIZE,KSD,TCIMG_SIZE)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SLICES = unique(rts.coords(:,3));

% tmpmsk = zeros(size(tcImg.dat,1),size(tcImg.dat,2));
tmpmsk = zeros(TCIMG_SIZE(1:2));

h = fspecial('gaussian',KSIZE,KSD);

tmpimg = tmpmsk;
for K = 1:length(SLICES),
  % indices for rts.dat
  tmpidx  = find(rts.coords(:,3) == SLICES(K));
  % indices for the given 2D image
  tmpidx2 = sub2ind(size(tmpmsk),rts.coords(tmpidx,1),rts.coords(tmpidx,2));
  for T = 1:size(rts.dat,1),
    % image data
    %    tmpimg = tcImg.dat(:,:,SLICES(K),T);
    tmpimg(:) = 0;    
    tmpimg(tmpidx2) = rts.dat(T,tmpidx);  % may be redundant...
    % set mask
    tmpmsk(:) = 0;
    tmpmsk(tmpidx2) = 1;
    % apply 2D filtering
    tmpimg = roifilt2(h,tmpimg,tmpmsk);
    % give the result
    rts.dat(T,tmpidx) = tmpimg(tmpidx2);
  end
end


return

