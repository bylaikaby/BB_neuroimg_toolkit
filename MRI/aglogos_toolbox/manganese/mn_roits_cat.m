function varargout = mn_roits_cat(roiTs)
%MN_ROITS_CAT - concatinates given roiTs.
%  ROITS = MN_ROITS_CAT(ROITS) returns roiTs structre for ROINAME.
%
%  VERSION :
%    0.90 09.06.05 YM  pre-release
%    0.91 24.06.05 YM  supports ".ttest.pca_p".
%
%  See also MN_ROITS_GET

if nargin == 0,  help mn_roits_cat; return;  end

if isempty(roiTs),
  if nargout,
    varargout{1} = {};
  end
  return;
end

if ~iscell(roiTs),
  varargout{1} = roiTs;
  %roiTs = { roiTs };
  return;
end

% CONCATINATE TIMME COURSE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NumVoxels = 0;  NumTime = 0;
for N = 1:length(roiTs),
  if ~isempty(roiTs{N}.dat),
    NumTime   = size(roiTs{N}.dat,1);
    NumVoxels = NumVoxels + size(roiTs{N}.dat,2);
  end
end

TC_DAT = zeros(NumTime,NumVoxels, class(roiTs{1}.dat));
COORDS = zeros(NumVoxels,3, 'int16');
SLICE  = zeros(1,length(roiTs), 'int16');
if isfield(roiTs{1},'ttest'),
  TTEST_P = ones(1,NumVoxels);
  if isfield(roiTs{1}.ttest,'pca_p'),
    TTEST_P2 = ones(1,NumVoxels);
  end
end

ROINAME = {};  EXPNO = [];
OFFS = 0;
for N = 1:length(roiTs),
  idx = [1:size(roiTs{N}.dat,2)] + OFFS;
  TC_DAT(:,idx) = roiTs{N}.dat;
  SL_DAT(idx)   = int16(roiTs{N}.slice);
  COORDS(idx,:) = int16(roiTs{N}.coords);
  SLICE(N)      = int16(roiTs{N}.slice);
  if isfield(roiTs{N},'ttest'),
    TTEST_P(idx) = roiTs{N}.ttest.p(:);
    if isfield(roiTs{N}.ttest,'pca_p'),
      TTEST_P2(idx) = roiTs{N}.ttest.pca_p(:);
    end
  end

  ROINAME{N}    = roiTs{N}.name;
  EXPNO         = cat(2,EXPNO,roiTs{N}.ExpNo(:)');
  
  OFFS = OFFS + size(roiTs{N}.dat,2);
end

ROINAME = unique(ROINAME);
RoiName = ROINAME{1};
for N = 2:length(ROINAME),
  RoiName = sprintf('%s+%s',RoiName,ROINAME{N});
end


NEWROITS = roiTs{1};
NEWROITS.ExpNo   = sort(unique(EXPNO));
NEWROITS.name    = RoiName;
NEWROITS.dat     = TC_DAT;
NEWROITS.slice   = sort(unique(SLICE));
NEWROITS.coords  = COORDS;
if isfield(roiTs{1},'ttest'),
  NEWROITS.ttest.p = TTEST_P;
  if isfield(roiTs{1}.ttest,'pca_p'),
    NEWROITS.ttest.pca_p = TTEST_P2;
  end
end

if nargout,
  varargout{1} = NEWROITS;
end


return;
