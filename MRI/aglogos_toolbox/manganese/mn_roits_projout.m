function varargout = mn_roits_projout(roiTs,BASEDAT)
%MN_ROITS_PROJOUT - project a given component from roiTs.
%  ROITS = MN_ROITS_PROJOUT(ROITS,BASEDAT) projects BASEDAT out from roiTs.
%  [ROITS UVEC] = MN_ROITS_PROJOUT(ROITS,BASEDAT) does the same things but
%  returns BASEDAT as a unit vector.  BASEDAT must be (T,N) matrix.
%
%  VERSION :
%    0.90 09.06.05 YM  pre-release
%    0.91 15.06.05 YM  supports BASEDAT as a matrix.
%
%  See also MN_ROI_GET, MN_ROI_CAT

if nargin < 2,  help mn_roits_projout; return;  end

% must be (t,n)
if isvector(BASEDAT),  BASEDAT = BASEDAT(:);  end
% make sure BASEDAT as unit vectors
BASEDAT = subUnitVector(BASEDAT);
% decorrelate components
BASEDAT = subDecorrData(BASEDAT);


% project "BASEDAT" out from roiTs.
if iscell(roiTs),
  for N = 1:length(roiTs),
    NEWROITS{N} = subProjectOut(roiTs{N},BASEDAT);
  end
else
  NEWROITS = subProjectOut(roiTs,BASEDAT);
end

% set output
if nargout,
  varargout{1} = NEWROITS;
  if nargout > 1,
    varargout{2} = BASEDAT;
  end
end

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to make BASEDAT as unit vectors
function BASEDAT = subUnitVector(BASEDAT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for N = 1:size(BASEDAT,2),
  tmpvec = BASEDAT(:,N);
  tmpvec = tmpvec - mean(tmpvec(:));
  v = sqrt(sum(tmpvec(:).*tmpvec(:)));
  if v == 0,
    tmpvec(:) = 0;
  else
    tmpvec = tmpvec / v;
  end
  BASEDAT(:,N) = tmpvec;
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to decorrelate BASEDAT
function BASEDAT = subDecorrData(BASEDAT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for iX = 1:size(BASEDAT,2),
  tmpx = BASEDAT(:,iX);
  for iY = iX+1:size(BASEDAT,2),
    tmpy = BASEDAT(:,iY);
    BASEDAT(:,iY) = tmpy - sum(tmpx(:).*tmpy(:))*tmpx;
  end
end

% make sure unit vectors
%BASEDAT = subUnitVector(BASEDAT);

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to project "BASEDAT" out from roiTs.
function newTs = subProjectOut(roiTs,BASEDAT)

newTs = roiTs;

for N = 1:size(roiTs.dat,2),
  tmpdat = double(roiTs.dat(:,N));
  offs   = mean(tmpdat(:));
  tmpdat = tmpdat - offs;
  for K = 1:size(BASEDAT,2),
    tmpdat = tmpdat - sum(tmpdat(:).*BASEDAT(:,K)) * BASEDAT(:,K);
  end
  tmpdat = tmpdat + offs;

  newTs.dat(:,N) = tmpdat;
end



return;
