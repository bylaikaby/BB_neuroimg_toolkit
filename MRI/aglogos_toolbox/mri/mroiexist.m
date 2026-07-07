function ROI_EXISTS = mroiexist(Roi,RoiName)
%MROIEXIST - Check if the roi with "RoiName" exists
% oRoi = MROIEXIST (Roi,Slice) is used to check whether a particular ROI was already defined.
%
% See also MROIGET
%
% NKL 20.11.04
  
if nargin < 2,
  help mroiexist;
  return;
end;

ROI_EXISTS=0;
for N=1:length(Roi.roi),
  if strcmp(lower(Roi.roi{N}.name),lower(RoiName)),
    ROI_EXISTS=1;
    break;
  end;
end;
