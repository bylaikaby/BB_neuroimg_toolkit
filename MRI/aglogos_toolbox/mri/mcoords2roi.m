function ROINAMES = mcoords2roi(varargin)
%MCOORDS2ROI - returns roinames from given coordinates.
%  ROINAMES = MCOORDS2ROI(SESSION,GRPEXP,COORDS)
%  ROINAMES = MCOORDS2ROI(SIG) returns roinames from given coordinates.
%  The inputs 'COORDS' must be a matrix of (vox,3=xyz).
%
%  EXAMPLE :
%    >> sig = mvoxselect('e04ds1','visesmix','all','glm[2]',[],0.01);
%    >> roinames = mcoords2roi('e04ds1','visesmix',sig.coords)
%    >> roinames = mcoords2roi(sig)
%
%  VERSION :
%    0.90 22.02.07 YM  pre-release
%
%  See also

if nargin < 1,  eval(sprintf('help %s;',mfilename)); return;  end

EXCLUDE_ROI = {'brain'};

if issig(varargin{1}),
  SIG = varargin{1};
  if iscell(SIG),
    for N = 1:length(SIG),
      ROINAMES{N} = mcoords2roi(SIG{N});
    end
    return
  end
  COORDS = SIG.coords;
  Ses = goto(SIG.session);
  grp = getgrp(Ses,SIG.grpname);
else
  % called like mcoords2roi(Session,GrpExp,Coords)
  Ses = goto(varargin{1});
  grp = getgrp(Ses,varargin{2});
  COORDS = varargin{3};
end


% LOAD ROI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ROI = load('Roi.mat',grp.grproi);
ROI = ROI.(grp.grproi);

% search for possible roi-names
tmproi = {};
for N = 1:length(ROI.roi),
  if ~any(strcmpi(EXCLUDE_ROI,ROI.roi{N}.name)),
    tmproi{end+1} = ROI.roi{N}.name;
  end
end
tmproi = unique(tmproi);
unames = {'unknown',tmproi{:}};

% assign indices for ROIs
VOLIDX = ones(size(ROI.img));
for N = 1:length(ROI.roi),
  if ~any(strcmpi(EXCLUDE_ROI,ROI.roi{N}.name)),
    roiidx = find(strcmpi(unames,ROI.roi{N}.name));
    tmpimg = VOLIDX(:,:,ROI.roi{N}.slice);
    [maskx,masky] = find(ROI.roi{N}.mask);
    tmpidx = sub2ind(size(tmpimg),maskx,masky);
    tmpimg(tmpidx) = roiidx;
    VOLIDX(:,:,ROI.roi{N}.slice) = tmpimg;
  end
end


% get corresponding ROI indices and names
tmpidx = sub2ind(size(ROI.img),COORDS(:,1),COORDS(:,2),COORDS(:,3));
roiidx = VOLIDX(tmpidx);

ROINAMES = unames(roiidx);

return
