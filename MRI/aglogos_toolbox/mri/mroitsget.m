function oroiTs = mroitsget(roiTs,Slice,RoiName)
%MROITSGET - Get time series of ROI in slice "Slice" with name "RoiName" 
% oRoi = MROITSGET(roiTs,Slice,RoiName) selects "roiTs" based on "Slice" and "RoiName".
%    "Slice" can be a numeric vector.  "RoiName" can be a cell array of strings.
%
% EXAMPLE:  selRoi = mroitsget(roiTs,1,'v1');
%           selRoi = mroitsget(roiTs,[1 2],{'v1','v2'});
%
% See also MROI, MAREATS, SIGLOAD
%
% ROITS - Structure
%    session: 'n03qv1'
%     grpname: 'rivalryleft'
%       ExpNo: 1
%         dir: [1x1 struct]
%         dsp: [1x1 struct]
%         grp: [1x1 struct]
%         evt: [1x1 struct]
%         stm: [1x1 struct]
%         ele: {[1x1 struct]  [1x1 struct]}
%          ds: [0.3750 0.3750 2]
%          dx: 0.2500
%         ana: [76x56x2 double]
%        name: 'v2'
%       slice: 1
%      coords: [708x3 double]
%         dat: [700x708 double]
%           r: {[1x708 double]}
%       tosdu: [1x1 struct]
%
% NKL 04.07.04
% YM  06.04.06  supports troiTs.

if nargin < 3,
  help mroitsget;
  return;
end;

if ~iscell(roiTs),
  roiTs={roiTs};
end;

% if strmatch('ele',RoiName,'exact'),
%   idx=strcmp('ele',RoiName);
%   RoiName(idx)=[];
%   RoiName=cat(2,RoiName,{'ele1','ele2'});
% end;

if iscell(roiTs{1}),
  % roiTs as troiTs
  oroiTs = {};
  for N = 1:length(roiTs),
    tmp = mroitsget(roiTs{N},Slice,RoiName);
    if ~isempty(tmp),
      oroiTs{end+1} = tmp;
    end
  end
  return;
end


% SELECT "roiTs" based on "RoiName".
if ~isempty(RoiName),
  oroiTs = {};
  K = 1;
  for N=1:length(roiTs),
    if ~any(strcmpi(roiTs{N}.name,RoiName)),
      continue;
    end;
    oroiTs{K} = roiTs{N};
    K = K + 1;
  end;
  if isempty(oroiTs),
    fprintf(' WARNING %s:',mfilename);
    if ischar(RoiName),
      fprintf(' ''%s''',RoiName);
    else
      for K = 1:length(RoiName),
        fprintf(' ''%s''',RoiName{K});
      end
    end
    fprintf(' not found.\n');
  end
else
  oroiTs = roiTs;
end

if isempty(oroiTs),
  oroiTs = roiTs;
end;

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


if ~exist('oroiTs','var'),
  fprintf('MROITSGET: Incorrect "Slice" definition\n');
  keyboard;
end;
