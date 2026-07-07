function pars = mroitsgetpars(roiTs)
%MROITSGETPARS - Get number of slices, of areas and of subROIs
% oRoi = MROITSGETPARS(roiTs) returns the number of valid areas, ROIs and slices for the
% structure roiTs.
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
%           r: {[708x1 double]}
%       tosdu: [1x1 struct]
%
% NKL 04.07.04
  
if nargin < 1,
  help mroitsgetpars;
  return;
end;

if ~iscell(roiTs),
  fprintf('mroitsgetpars: expects a CELL ARRAY input\n');
  return;
end;

K = 1;
for N=1:length(roiTs),
  names{N} = roiTs{N}.name;
  slices(N) = roiTs{N}.slice;
end;

pars.nareas = 0;
pars.areas = {};
pars.nslices = 0;
pars.nrois = {};

pars.nslices = length(unique(slices));
pars.areas = unique(names);
pars.nareas = length(pars.areas);

for S=1:pars.nslices,
  for N=1:pars.nareas,
    nRoi{S}(N) = 0;
    for K=1:length(roiTs),
      if strcmp(roiTs{K}.name,pars.areas{N}) & roiTs{K}.slice==S,
        nRoi{S}(N) = nRoi{S}(N) + 1;
      end;
    end;
  end;
end;

pars.nrois = nRoi;  




