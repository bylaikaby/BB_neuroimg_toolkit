function montageImage = mmontage(iVOL,varargin)
%MMONTAGE Generate a rectangular image (montage) from a volume-data.
%   montageImage = MMONTAGE(iVOL,...) generages a rectangular image (montage) from a volume-data.
%
%   NOTE :
%     iVOL should have "Y" as the first dimension!!
%     iVOL should be 4D data: [Y X 1 Z] for gray-scale or [Y X rgb Z] for rgb
%
%   Supported options:
%     'ClipRange'   : clipping values [min max]
%     'RowsCols'    : # of rows/colums (in unit of image)
%     'AspectRatio' : aspect ratio
%
%   EXAMPLE :
%     ivolume = rand(10,20,1,5);       % [Y X 1 slice]
%     bigImage = mmontage(ivolume);    % [Y X]
%     imagesc(bigImage)
%
%   VERSION :
%     0.90 18.04.2019 YM  pre-release
%
%   See also MONTAGE.

if nargin < 1
  eval(['help ' mfilename]);
  return;
end

% options
CLIP_RANGE = [NaN NaN];
MON_RAWCOL = [NaN NaN];
AXES_ASPECT = 1;

% parse "varargin" inputs
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'cliprange' 'clip' 'range'}
    CLIP_RANGE = varargin{N+1};
    if numel(CLIP_RANGE) ~= 2
      error('%s: ''clip'' should be [min-value max-value].\n',mfilename);
    end
   case {'size' 'msize' 'mrowcol' 'rowcol' 'rowscols' 'montagesize' 'montagerowscols'}
    MON_RAWCOL = varargin{N+1};
    if numel(MON_RAWCOL) ~= 2
      error('%s: ''rowcol'' should be [nrows ncols].\n',mfilename);
    end
   case {'row' 'rows' 'nrows' 'nrow'}
    MON_RAWCOL(1) = varargin{N+1};
   case {'col' 'cols' 'ncols' 'ncol'}
    MON_RAWCOL(2) = varargin{N+1};
   case {'aspect' 'aspectratio'}
    AXES_ASPECT = varargin{N+1};
  end
end

if ndims(iVOL) < 4
  if size(iVOL,3) == 3
    % rgb
  else
    % iVOL looks like [X Y slice]... make it [Y X 1 slice].
    iVOL = permute(iVOL,[2 1 4 3]);
  end
end


% Function Scope
nZ = size(iVOL,4);
nY = size(iVOL,1);
nX = size(iVOL,2);
[mRows, mCols] = sub_GetMontageSize(MON_RAWCOL, nX, nY, nZ, AXES_ASPECT);


montImageSz = [mRows*nY mCols*nX size(iVOL,3) 1];
if islogical(iVOL)
  montageImage = false(montImageSz);
else
  montageImage = zeros(montImageSz,class(iVOL));
end

rows = 1:nY;
cols = 1:nX;
z = 1;
for r = 0:mRows-1
  for c = 0:mCols-1,
    if z <= nZ
      montageImage(rows + r * nY, cols + c * nX, :) = iVOL(:,:,:,z);
    else
      break;
    end
    z = z + 1;
  end
end

% clipping
if size(iVOL,3) ~= 3
  if any(CLIP_RANGE(1))
    montageImage(montageImage(:) < CLIP_RANGE(1)) = CLIP_RANGE(1);
  end
  if any(CLIP_RANGE(2))
    montageImage(montageImage(:) > CLIP_RANGE(2)) = CLIP_RANGE(2);
  end
end


return


% ==============================================================
function [mRows, mCols] = sub_GetMontageSize(montageRowCol,nX,nY,nZ, AspectR)
% ==============================================================
if isempty(montageRowCol) || all(isnan(montageRowCol))
  mCols = ceil(sqrt(AspectR*nY*nZ/nX));
  mRows = ceil(nZ/mCols);
elseif isnan(montageRowCol(1))
  mRows = ceil(nZ/montageRowCol(2));
  mCols = montageRowCol(2);
elseif isnan(montageRowCol(2))
  mRows = montageRowCol(1);
  mCols = ceil(nZ/montageRowCol(1));
else
  mRows = montageRowCol(1);
  mCols = montageRowCol(2);
  if mRows*mCols < nz
    error('%s:  ''montageRowCol'' is too small (nZ=%d).\n',mfilename,nZ);
  end
end

return;
