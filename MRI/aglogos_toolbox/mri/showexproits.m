function showexproits(SesName, GrpName, RoiName, Thr, Mode)
%SHOWEXPROITS - Display ROI time series of each experiment in the same plot
%
% SHOWEXPROITS (SesName, ExpNo, RoiName, Thr, Mode) makes a figure with two subplots. The
% uppers shows the correlation map, and the lower the time course of ROI voxels. If Mode is
% zero the average time course is displayed; otherwise the function makes a surface plot
% with all voxels of the ROI.
%
% Defaults:
%   RoiName = 'v1';
%   Thr = 0.01;
%   Mode = 0;
%
% Usage:
%   SHOWEXPROITS ('k005x1', 3, 'v1', 0.3, 0);
%
% NKL, 11.04.04

if nargin < 5,
  Mode = 1;     % plots the average roiTs
                % Mode=1 will generate a surface plot
end;

if nargin < 4,
  Thr = 0.1;
end;

if nargin < 3,
  RoiName = 'v1';
end;

if nargin < 2,
  help showexproits;
  return;
end;


Ses = goto(SesName);
grp = getgrpbyname(Ses,GrpName);

for N=1:length(grp.exps),
  ExpNo = grp.exps(N);
  roiTs = sigload(Ses,ExpNo,'roiTs');
  roiTs = mroitsget(roiTs,[],RoiName);
  roiTs = mroitssel(roiTs,Thr);
  roiTs{1}.dat = mean(roiTs{1}.dat,2);

  if N==1,
    oroiTs = roiTs;
  else
    oroiTs{1}.dat = cat(2,oroiTs{1}.dat,roiTs{1}.dat);
  end;

end;

mfigure([10 30 1200 1000]);

MODE=2;
if MODE==0,
  for N=1:size(oroiTs{1}.dat,2),
    subplot(4,5,N);
    plot(oroiTs{1}.dat(:,N),'color','k','linewidth',2);
    title(sprintf('%d',N));
  end;
elseif MODE==1,
  surf([0:size(oroiTs{1}.dat,1)-1], [0:size(oroiTs{1}.dat,2)-1],  oroiTs{1}.dat');
  view(0,90);
elseif MODE==2,
  surf([0:size(oroiTs{1}.dat,1)-1], [0:size(oroiTs{1}.dat,2)-1],  oroiTs{1}.dat');
  view(0,90);
  shading interp;
elseif MODE==3,
  [x,y] = meshgrid([0:size(oroiTs{1}.dat,1)-1], [0:size(oroiTs{1}.dat,2)-1]);
  plot3(y,x,oroiTs{1}.dat');
end;



