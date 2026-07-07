function X = check_roi(Ses,GrpName,varargin)
%
%
%


if nargin < 2,  GrpName = 'spont';  end



Ses = goto(Ses);
grp = getgrp(Ses,GrpName);


RoiFile = fullfile(pwd,'Roi.mat');

VarName = 'RoiGrp';
ROI = load(RoiFile,VarName);
ROI = ROI.(VarName);


DRAWN_ROI = {};
ATLAS_ROI = {};
for N = 1:length(ROI.roi),
  if ~isempty(ROI.roi{N}.px),
    DRAWN_ROI{end+1} = ROI.roi{N}.name;
  else
    ATLAS_ROI{end+1} = ROI.roi{N}.name;
  end
end

DRAWN_ROI = unique(DRAWN_ROI);
ATLAS_ROI = unique(ATLAS_ROI);

COMMON_ROI = intersect(DRAWN_ROI,ATLAS_ROI);

X.session = Ses.name;
X.drawn = DRAWN_ROI;
X.atlas = ATLAS_ROI;
if isempty(COMMON_ROI),
  X.common = {};
else
  X.common = COMMON_ROI;
end

return
