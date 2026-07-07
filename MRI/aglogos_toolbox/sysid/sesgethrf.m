function sesgethrf(SesName,GrpNames,LOG)
%SESGETHRF - Estimate HRF for all relevant (no stimulus) groups of the session
%
% SESGETHRF (SesName,Grpnames,LOG) estimates the Hemodynamic Response Function (HRF) of the
% neurovascular system in combined physiology and fMRI experiments. Reliable estimates are
% obtained from data collected without visual stimulation. Relevant groups are named
% "spont", "baseline", "p0c0" etc. The list of sessions including spontaneous activity data
% are is given below.
%
% To obtain the HRF estimate the following steps must be performed:
%
%   ** Edit the description file and ensure correct definition of the grp.actmap field. The
%   actmap is a cell array with two elements. The first is the group from which reliable
%   activity is expected (usually stimulation with rotating polars). The second indicates
%   the trial from which the activity could be computed (for multiple-trial
%   experiments). This second entry is irrelevant for SESGETHRF because we compute the
%   activation for each existing trial and obtain a common map (the median of the
%   correlation map of each trial).
%
%   ** Run all preprocessing (i.e. sesloadimg(SesName), sesgetcln(SesName)) to generate the
%   tcImg and Cln structures and save them in the corresponding files in the ./home/SIGS
%   directory.
%
%   ** Run SESROI(SesName) to define the ROI regions (usually V1, V2,.. brain, ele), whereby
%   the ele ROI is the one used by SESGETHRF to select voxels (and time series).
%
%   ** Run FLSESAREATS (SesName) to select the voxels. Note that for the HRF estimation we
%   do not use SESAREATS but rather the FLSESAREATS. It is so, because we have
%   project-specific requirements in the preprocessing of the time series. See FLSESAREATS
%   for details. FLSESAREATS will select all voxels defined in each ROI; no further
%   selection on the basis of "activation" is done by this function (though it's possible if
%   the appropriate parameters are set!).
%
%   ** Run BPROITSMEAN or BPROITSMEDIAN to generate mean or median roiTs. For the estimation
%   of HRF the function BPROITSMEDIAN gives better (more robust) results.
%
%   ** Run BPCORANA with a threshold that depends on the data-quality. No magic recipies
%   here. Try different values and see the effects. A threshold of 0.15-0.25 works well. Do not
%   forget to set the last input argument (SameMap) to 1, indicating that we shall be using the
%   common median correlation map as mask for further selection of time series while performing
%   the CRA.
%  
%   ** Now you can run the SESGETHRF. The function will call GRPGETHRF, EXPGETHRF and SIGHRF to
%   do the actual job. GRPGETHRF will do the following (no need to repeat for each experiment)
%   troiTs = sigload(Ses,grp.actmap{1},'troiTs');
%   tmp = EXPGETHRF(Ses,ExpNo,SigName,RoiName,troiTs.origIdx);
%   roiTs.origIdx is the tsIndex used as shown next
%   roiTs.dat = hnanmean(roiTs.dat(:,tsIndex),2);
%  
%   ** Run SHOWHRF(SesName,GrpName) to see the results.
%  
% See also
%   FLLOG           -- Analysis steps performed for each session
%   FLDOC           -- Detailed documentation, including references etc
%   FLTODO          -- Problems, Reports and ToDo list for the glass pattern project
%   FLSESAREATS     - - Generate Time-Series for each area defined in ROI.names
%   BPCORANA        - - Correlation analysis on averaged data (avgTs in file GrpName)
%   BPROITSMEAN     - - Compute the mean of each ROI Time Series (for correlation analysis)
%   MAREATS         - - Select and process the time series of selected ROIs or Areas
%
%   /MATLAB/FLASH/CONTENTS -- Project Specific Functions
%   /MATLAB/SYSID/CONTENTS -- System Identification Methods Applied in Neuro-MRI
%  
% NKL, 01.04.04

Ses = goto(SesName);

if nargin < 3,
  LOG = 0;
end;

if ~isfield(Ses.ctg,'imgSpoGrps'),
  fprintf('SESGETHRF: Ses.ctg.imgSpoGrps not found\n');
  keyboard;
end;

if nargin < 2,
  GrpNames = Ses.ctg.imgSpoGrps;
else
  if isa(GrpNames,'char'),
    GrpNames = {GrpNames};
  end;
end;

if LOG,
  LogFile=strcat('SESGETHRF_',Ses.name,'.log');	% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end;

for GrpNo = 1:length(GrpNames),
  grpgethrf(Ses,GrpNames{GrpNo});
end;

if LOG,
  diary off;
end;

