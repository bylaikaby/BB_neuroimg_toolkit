function oRoi = mroicat(Roi)
%MROICAT - Concatanate ROIs with same name in the same slice
% oRoi = MROICAT (Roi) concatanates all ROIs into one mask by using
% an OR logical operation.
%       name: 'V1'
%      slice: 1
%       mask: [34x22 double]
%         px: [26x1 double]
%         py: [26x1 double]
%    anamask: [136x88 logical]		% OBSOLETE
%     coords: [15x3 double]			% OBSOLETE
%
%  See also MROI, MROIGET

if nargin < 1,
  help mroicat;
  return;
end;

oRoi = Roi;
oRoi.roi = {};
NoSlice = size(Roi.img,3);
NoRoi = length(Roi.roinames);
K = 1;
for SliceNo = 1:NoSlice,
  for RoiNo = 1:NoRoi,
    [tmp,Roi] = roicat(Roi,SliceNo,Roi.roinames{RoiNo});
    if ~isempty(tmp),
      oRoi.roi{K} = tmp;
      K = K + 1;
    end;
  end;
end;

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [roi,Roi] = roicat(Roi,Slice,RoiName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 29.11.04 YM improved speed.
% HERE IS NEW CODE, x2.53 faster.
SELIDX = [];
for N=1:length(Roi.roi),
  if strcmpi(Roi.roi{N}.name,RoiName) & Roi.roi{N}.slice == Slice,
    SELIDX(end+1) = N;
  end;
end;
if isempty(SELIDX),
  roi = {};
  return;
end
tmpRoi = Roi.roi(SELIDX);
Roi.roi(SELIDX) = [];
% HERE IS OLD CODE
% K = 1;
% for N=1:length(Roi.roi),
%   if strcmpi(Roi.roi{N}.name,RoiName) & Roi.roi{N}.slice == Slice,
%     tmpRoi{K} = Roi.roi{N};
%     K = K + 1;
%   end;
% end;
% if ~exist('tmpRoi') | isempty(tmpRoi),
%   roi = {};
%   return;
% end;



roi = tmpRoi{1};
% NOTE: The actmap-ROIs will have all px, py empty, because no
% polygon is definable with the non-convex and spread out
% activation. So, all px py field will be ignored.
try,
  for N=2:length(tmpRoi),
    if ~isempty(roi.px),
      roi.px = cat(1,roi.px,[NaN]);
      roi.py = cat(1,roi.py,[NaN]);
      roi.px = cat(1,roi.px,tmpRoi{N}.px);
      roi.py = cat(1,roi.py,tmpRoi{N}.py);
    end;
    
    roi.mask = roi.mask | tmpRoi{N}.mask;
    if isfield(roi,'anamask'),
      roi.anamask = roi.anamask | tmpRoi{N}.anamask;
    end;
    % 16.05.04 The following statement is commented, because the
    % new version of MROI does not bother to determine
    % coordinates. The coords are only needed when we extract the
    % time series; they have been eliminated from the ROI structure
    % (altough some old ROIs may still have it) and won't be
    % handled by MROICAT and MROIGET.
    % roi.coords = cat(1,roi.coords,tmpRoi{N}.coords);
  end;
catch,
  disp(lasterr);
  keyboard;
end;




