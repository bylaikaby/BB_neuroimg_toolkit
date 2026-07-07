function sesroitsmedian(SesName, grpnames, Thr)
%SESROITSMEDIAN - Compute the median of each ROI Time Series (for correlation analysis)
% SESROITSMEDIAN Computes the average response of each voxel of each ROI. The function can be
% used to increase the signal to noise ration in the roiTs data before applying the
% correlation analysis. This is useful when we want to have always the same mask for the
% study of responses to different trials/stimuli.
%
% NOTE: In continuous observation periods this is not needed! In those experiments
% (e.g. M02lx1, or all the old Nature sessions) the correlation analysis is performed
% immediately after the creating of roiTs in the MAREATS functions, which calls MATSCOR. The
% present function is good for experiments in which an observation period has several
% trials. In the latter case roiTs selection on the basis of Roi.mat DOES NOT invoke
% MATSCOR. Instead the SESAREATS if followed by the call of SESGETTRIAL which splits the
% observation periods in trials. NO AVERAGING can be possible done before this step; due to
% the clock-jitter. The present function is called immediately after the SESGETTRIAL to
% generate group-averages of the troiTs structure.
%  
% It is THIS AVERAGES that are used by SESATSCOR to create r-value maps!!!
%  
% See also GETTRIAL SESGETTRIAL
%
% NKL 23.07.04

if nargin < 3,
  Thr = 0.1;
end;

Ses = goto(SesName);

if nargin < 2,
  grpnames = Ses.ctg.imgActGrps{2};
end;

if nargin < 1,
  help sesroitsmedian;
  return;
end;


for GrpNo = 1:length(grpnames),
  grp = getgrpbyname(Ses,grpnames{GrpNo});
  fprintf('SESROITSMEDIAN: Session %s, Group %s', Ses.name,grpnames{GrpNo});

  for iExp = 1:length(grp.exps),
    ExpNo = grp.exps(iExp);
    Sig = sigload(Ses,ExpNo,'roiTs');

    if iExp == 1,
      roiTs = Sig;
      DIM = ndims(Sig{1}.dat)+1;
    else
      for A = 1:length(roiTs),
        roiTs{A}.dat = cat(DIM,roiTs{A}.dat,Sig{A}.dat);
        roiTs{A}.r{1} = cat(2,roiTs{A}.r{1},Sig{A}.r{1});
      end;
    end;
    fprintf('.');
  end;
  fprintf(' Done!\n');

  name = strcat(grpnames{GrpNo},'.mat');
  if exist(name,'file'),
    save(name,'roiTs','-append');
    fprintf('sesroitsmedian: roiTs was appended into file %s\n', name);
  else
    save(name,'roiTs');
    fprintf('sesroitsmedian: roiTs was saved into file %s\n', name);
  end;
end;
return;


