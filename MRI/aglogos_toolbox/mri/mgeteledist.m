function dist = mgeteledist(coords,elepos,ds)
%MGETELEDIST - returns distance from the electrode.
%  DIST = MGETELEDIST(COORDS,ELEPOS,DS)  returns distance from the electrode.
%
%    COORDS : (voxels,3) in voxels
%    ELEPOS : (x,y,z)    in voxels
%    DS     : (x,y,z)    in mm
%
%  EXAMPLE :
%    >> elepos = mgetelepos(Session,ExpNo);
%    >> roiTs  = sigload(Session,ExpNo);
%    >> dist   = mgeteledist(roiTs{1}.coords,elepos(1,:),roiTs{1}.ds)
%
%  VERSION :
%    0.90 12.03.06 YM  pre-release
%
%  See also MGETELEPOS

if nargin < 3,  eval(sprintf('help %s;',mfilename)); return;  end

% make sure elepos/ds as a row vector
elepos = elepos(:)';
ds = ds(:)';

% compute distance from the electrode by for-loop, to avoid memory problem.
dist   = zeros(1,size(coords,1));
for N = 1:size(coords,1),
  tmpd = coords(N,:) - elepos;
  tmpd = tmpd .* ds;
  tmpd = sqrt(sum(tmpd.*tmpd));
  dist(N) = tmpd;
end


return;
