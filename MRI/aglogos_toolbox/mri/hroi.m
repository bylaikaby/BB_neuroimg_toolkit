function hroi
%HROI - Description of ROI selection performed by MROI
% MROI - Is the ROI-Selection tool, used to define regions of interest.
%
% * MROI expects that all paravision, 2dseq, files were loaded and
% saved as mat-files. They include all anatomy scans (e.g. gefi,
% mdeft, etc), the control scans (e.g. Epi13), and the actual data,
% which are saved in the directory DataMatlab/SesDir/SIGS. The
% conversion can be done by invoking individual processes, such as
% sesascan(SesName), sescscan(SesName), sesimgload(SesName) etc.,
% or by running the sesload function which creates the SesPar.mat
% file and loads all existing physiology and imaging data.
%
% * MROI also expects the existence of averaged imaging data. That is,
% it assumes that you have already run the sestcimg(SesName)
% function. The latter saves the average imaging data of each group as
% structures having the group's name in the tcImg.mat file.
% sestcimg(SesName) applies certain basic signal processing steps
% before averaging the experiments of the group. They usually include,
% removal of respiratory artifacts, detrending and temporal low-pass
% filtering. If you want to change the defaults you will have to
% edit the mgrptcimg.m function, or use the ARGS input argument to
% define new preprocessing steps.
%
% * In addition, proper function of MROI depends on the following
% definitions in the session's description file:
%
% ROI.groups - Experiment-Groups that can be averaged to obtain the
%                   best possible anatomical detail (Default: 'all')
% ROI.names  - Names of the desired ROIs/Areas (e.g. {'brain'; 'V1'; 'V2'})
% ROI.model  - Group to use as model (e.g. V1)
%
% GRP.grpname.actmap - The reference group whose average-tcImg is
%               used to compute activation maps. For example, if
%               actmap == 'movie1', then tcImg =
%               matsigload('tcImg.mat','movie1'); loads the data, from
%               which correlation maps are computed.
%
%               The definition of the reference group is important and
%               must be done immediately after the generation of the
%               description file. Eeach group may have the same or
%               different reference group. The rationale of the
%               reference group can be explained as follows:
%
%               Let's assume that a session has 3 groups each with
%               different stimulus duration and contrast. For
%               instance, the first stimulus is a polar stimulus of
%               100% contrast and of 12s duration (p12c100). The
%               second is p8c50, and the 3rd is p2c80. To examine the
%               effects of stimulus parameters on activation, the user
%               may prefer to compare the time series of the same
%               voxels in all three conditions. The description file,
%               in this case, should be prepared as follows:
%
%               GRP.p12c100.actmap = {'p12c100'};
%               GRP.p8c50.actmap = {'p12c100'};
%               GRP.p2c80.actmap = {'p12c100'};
%
%               whereby, p12c100 is taken as *reference-group* because
%               it is expected to have the most robust activation.
%  
% Note that the reference group name is an item of a cell array rather
% than a string. Definition of a single group name implies that each
% experimental run contains a single continuous observation
% period. Definition of a second string, indicates the existence of
% trials within the observation period. In this case, the string
% (e.g. {'GrpName','trial8'}) is the trial-ID, and it points to the
% trial whose analysis will provide the activity maps used as
% reference. An example can be found in the session C01.ph1, the
% second group of which contains observation periods with mutliple
% trials (N=9). The groups in this session have the following
% definitions:
%
% GRP.p125c100.exps           = [1:10];
% GRP.p125c100.actmap         = {'p125c100'};
% .............................................
% GRP.polarflash.exps         = [11:71 73:130];
% GRP.polarflash.actmap       = {'polarflash'; 'trial8'};
%
% To find out the trial ID (if you do not remember the trial types
% in your last experiment..) type gettrialinfo(SesName,GrpName) or
% gettrialinfor(SesName,ExpNo); To findout about the stimulus type
% getstiminfo(SesName,GrpName) etc.
%
% GETTRIALINFO will return:
%            TRIAL-RELATED PARAMETERS
%            PAR1----------------------------------
%             id: 0
%             label: 'trial0'
%             nrep: 1
%             imgtr: 0.250 (sec)
%             tlen:  14.032 (sec)
%             stmv:  0 1 2
%             stmt:  0 8 16 (volumes)
%             stmdt: 8 8 40 (volumes)
%             prm'nframes' = 2
%            PAR2----------------------------------
%             id: 1
%             label: 'trial1'  
%            . . . . . . . . . . . . . . . .
%            PAR9----------------------------------
%             id: 8
%             label: 'trial8'
%             nrep: 1
%             imgtr: 0.250 (sec)
%             tlen:  16.562 (sec)
%             stmv:  0 1 2
%             stmt:  0 8 16 (volumes)
%             stmdt: 8 8 40 (volumes)
%             prm'nframes' = 60
%
% Let's id=8, be the selection, then we use the function
% findtrialpar to obtain the actual cell-array index for trial 8,
% as follows:
%       ID = 8;
%       grp = getgrpbyname(Ses,GrpName);
%       ExpNo = grp.exps(1);
%       [IDX,PAR] = findtrialpar(getsortpars(Ses,ExpNo),ID);
%       IDX will be "9"
% 
% An additional important reason for using different refences groups
% to compute the activation maps is that many sessions may examine
% activity of more than one areas. In this case different
% stimulation conditions may be optimal for different groups, and
% thus each group may have a distinct reference-map.
%
% In contrast to the cases above, experiments in which exactly the
% same voxels must be analyzed for every group condition
% (e.g. Dependence analysis) must always have the same reference
% group. In this case, the only reason for computing an activation map
% is to exclude accidental inclusion of white-matter during the
% definition of the ROIs by the user. For dependence analysis the best
% strategy is to (a) define the ROIs based on anatomical information,
% (b) Compute the correllation or z-score map for the entire brain,
% and (c) Compute the "AND" between the brain-activation map and the
% individual ROIs. The process should be applied to the group expected
% to have the most robust activation, and the name of this group
% should go to the actmap field of all the other groups.
%  
% In summary, the process of ROI definition goes as follows:
%
% *** UPDATE all description-file definitions
%
% *** RUN sesload(SesName) to load all paravision files
%
% *** RUN sestcimg(SesName) to generate the averaged imaging data 
%
% *** RUN sesroi(SesName) to draw all ROIs specified in ses.roi.names
%       by using sesroi
%
% *** RUN mcorana(SesName,GrpName) for all critical groups. mcorana
%       without an output argument will automatically display the data
%       for visual inspection. This stage *must* be done interactively
%       to make sure the activation maps are usable. The model for the
%       cross-correlation analysis is always obtained from the stm
%       field by invoking the EXPGETSTIM(SesName,grp.exps(1),'hemo'),
%       which returns a boxcar function with the on/off periods
%       defined in the stm field, convolved with a gamma-function
%       kernel to mimic the hemodynamic response profile. If you are
%       not satisfied with the result of mcorana, check the quality
%       of individual experiments and the time course of
%       the average file by using "dspimg". You may change
%       thresholds or the clustering parameters to see if the maps
%       improve. Remember, that there definitely are "bad-session",
%       the data of whih are simply not "usable". If you manage to
%       get decent maps, then
%
% *** RUN sesroi(SesName,'update'). This will generate new ROIs in
%       the Roi.mat file, each having the name of a reference
%       group. The new ROIs are simply the original ROIs "AND" the
%       brain activity map (e.g. BrainAct.grpname). To remove the
%       newly created ROIs run sesroi(SesName,'reset'). Further
%       analysis of the data will access either the original ROI
%       groups or those containing the activation reference maps.
%
% When MROI is invoked, it searches for all groups that may have
% other ROI-definition sets than the default one (e.g. RoiDef). The
% detected ROIs are placed into the "Group" menu-box. To complete
% the ROI-definition step, each ROI-set found in the menu-box must
% be defined by the user. All defined ROIs will be save in Roi.mat,
% each with the name defined in the ses.grp.grproi.
% 
% *****************************************************************
% THE ROI STRUCTURE
% *****************************************************************
%	ROi.session		= tcImg.session;
%	ROi.grpname		= tcImg.grpname;
%	ROi.exps		= grp.exps;
%	ROi.anainfo     = grp.ana;
%	ROi.roinames	= Ses.roinames;
%
%	ROi.dir			= tcImg.dir;
%	ROi.dir.dname	= 'Roi';
%	ROi.dsp.func	= 'dsproi';
%	ROi.dsp.args	= {};
%	ROi.dsp.label	= {};
%
%	ROi.grp			= tcImg.grp;
%	ROi.usr			= tcImg.usr;
%	ROi.ana			= anaImg.dat(:,:,grp.ana{3});
%	ROi.img			= mean(tcImg.dat,4);
%	ROi.ds			= [tcImg.ds tcImg.usr.pvpar.slithk];
%	ROi.dx			= tcImg.dx;
%	ROi.roi			= {};
%	ROi.ele			= {};
%
%  "Roi.roi" will be like...
%   Roi.roi{1}.name: 'brain'
%   Roi.roi{1}.slice: 1
%   Roi.roi{1}.mask: [34x22 logical]
%   Roi.roi{1}.px: [28x1 double]
%   Roi.roi{1}.py: [28x1 double]
%
%  "Roi.ele" will be like...
%   Roi.ele{1}.ele: 1
%   Roi.ele{1}.slice: 1
%   Roi.ele{1}.anax: 91.6161
%   Roi.ele{1}.anay: 68.5793
%   Roi.ele{1}.x: 23
%   Roi.ele{1}.y: 17
%
% *****************************************************************
% FUNCTIONS USED FOR ROI AND ROI-TIME-SERIES DEFINITIONS
% *****************************************************************
% See also
%
% ROI generation procedure
% ================================================
% MROI (Session) - Draw ROIs and Electrode positions and
%	save them in the matfile Roi
% MAREATS (Session,ExpNo) - Selects Area-TS (eg all V1 ROIs, all V2 ROIs etc) and
%	saves them into the matfile "catfilename(Ses,ExpNo,'mat');
%
% Utilities Used to Create Area-Time-Series
% ================================================
% MROISCT Returns a structure of roi, mainly called by mroigui
% MROIDSP - Display image in gcf to obtain rois
% MSIGROITC - Select time series based on predefined rois
% MROIGET - Get Roi of name RoiName for slice 'Slice'
% MGETELEDIST - Get distance between electrode tips (to be done!)
% MTCFROMCOORDS - Get time series  based on coords (called by mtimeseries)
% MTIMESERIES - Function to obtain time series form voxels of coords
% MAREATS - Selects Time Series of Each Area (eg all V1 ROIs etc)
% MLOADROITS - Load ROI Time Series for ExpNo
% MGETROIIDX - Select roiTs indices corresponding to a desired area
%
% Auxilliary functions used by MROI/MAREATS
% ================================================
% [pleth,resp] = EXPGETVITEVT (Session, ExpNo) - Returns the pleth
% signal, which can be used to estimate the model or filter for
% removing respiratory artifacts
% EXPGETVITEVT (SESSION, ExpNo) - w/ nargout=0, will show the signals
% MROIGUI - gui interface to define rois.
%
% *****************************************************************
% EXAMPLES DEMONSTRATING ROI-USAGE
% *****************************************************************
%
% Example 1: Compute Kernel Covariance for Roi 'V1'
% ================================================================
% roiTs = MLOADROITS (Ses,ExpNo);
% roiIdx = MGETROIIDX (roiTs, 'V1');
%	The function uses roiTs_roiname to obtain the index
% CONFUNC (roiTs{roiIdx});  
%
% Example 2: Display mean/err of time series of an experiment
% ================================================================
% roiTs = mtimeseries ('m02lx1',1,'V1');
%   The input arguments are:
%       SESSION = 'm02lx1';
%       ExpNo = 1;
%       RoiName = 'V1';
%
%   Ses = goto(SESSION);
%   grp = getgrp(Ses,ExpNo);
%   Roi = matsigload('roi.mat',grp.grproi);
%   filename = catfilename(Ses,ExpNo,'tcimg');
%   load(filename,'tcImg');
%   oRoi = mroiget(Roi,[],RoiName);
%   [coords(1),coords(2),coords(3)] = find(?????????)
%   tc=mtcfromcoords(tcImg,coords);
%
%   The output structure is:
%   roiTs = 
%       session: 'm02lx1'
%       grpname: 'movie1'
%       roiname: 'V1'
%          exps: [1 16]
%           dir: [1x1 struct]
%           dsp: [1x1 struct]
%           grp: [1x1 struct]
%           usr: [1x1 struct]
%            ds: [0.7500 0.7500 2]
%            dx: 0.2500
%           ele: {[1x1 struct]  [1x1 struct]}
%          mask: [34x22x2 double]
%        coords: [153x3 double]         -- THEY GO TO CFUNC
%           dat: [1560x153 double]      -- THESE ARE THE TIME SERIES
%
%   The function mareats will convert the .dat field in SD units
%   and add the following fields:
%   roiTs = 
%       .......: ...............
%         tosdu: [1x1 struct]
%           avg: [1560x1 double]
%           err: [1560x1 double]
%
% *****************************************************************
% TO-DO's
% *****************************************************************
% * MCGRPCOR - Make activation maps for ses.roi.cgrp
% * MROIUPDATE - "AND" maps of ROI with activation  
% * MROIRESET - Delete updated maps and use the original ORIs again
%
helpwin hroi






