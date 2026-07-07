THIS HERE MUST BE FIXED; it can be useful...
    the idea is to select a smaller area after we run general corana with brain..

function oroiTs = msubroisel(roiTs,RoiName1,RoiName2)
%MSUBROISEL - Select sub-ROIs from a large ROI's roiTs (e.g. V1 from roiTs{Brain}
% oRoi = MSUBROISEL(roiTs,Slice,RoiName1,RoiName2) selects "roiTs" based on "Slice" and
% "RoiName". "Slice" can be a numeric vector.  "RoiName" can be a cell array of strings.

if nargin < 3,
  RoiName2 = 'Brain';
end;

if nargin < 2,
  help msubroisel;
  return;
end;

if ~iscell(roiTs),
  roiTs={roiTs};
end;

Ses = goto(roiTs{1}.session);
grp = getgrpbyname(Ses,roiTs{1}.grpname);
Roi = matsigload('roi.mat',grp.grproi); % Load the ROI of that group

oRoi = mroicat(Roi);
oRoi = mroiget(oRoi,[],RoiName1);
if isempty(oRoi.roi),
  fprintf('MSUBROISEL: No Roi was found\n');
  return;
end;

nslices = roiTs{1}.roiSlices;
for N=1:nslices,
  tmpTs = mroitsget(roiTs,Slice,RoiName2);
  map = matsmap(tmpTs,-0.001); % abs(dat)>0.001...
  for K=1:length(tmpTs.dat
keyboard




% SELECT "roiTs" based on "RoiName".
if ~isempty(RoiName),
  K = 1;
  for N=1:length(roiTs),
    if ~any(strcmpi(roiTs{N}.name,RoiName)),
      continue;
    end;
    oroiTs{K} = roiTs{N};
    K = K + 1;
  end;
else
  oroiTs = roiTs;
end
if ~exist('oroiTs','var'),
  fprintf('MROITSGET: Incorrect "RoiName" definition\n');
  keyboard;
end


if isempty(Slice),  return;  end;
if ischar(Slice) & strcmpi(Slice,'all'),  return;  end


% SELECT "roiTs" based on "Slice".
roiTs = oroiTs;
clear oroiTs;
K = 1;
for N=1:length(roiTs),
  if ~any(roiTs{N}.slice == Slice),
    continue;
  end;
  oroiTs{K} = roiTs{N};
  K = K + 1;
end;

  