function rts = mtimeseries(tcImg, Roi, RoiName, Slice)
%MTIMESERIES - Function to obtain the time series of voxels of a ROI.
% MTIMESERIES (tcImg, Roi, RoiName) uses the ROI information in the
% structure Roi and select time series for each defined area or
% subregion in the structure.
%
%  VERSION :
%    0.90 xxxx
%    0.91 02.12.10  YM  use subNewCode() for faster operation.
%    0.92 23.01.12  YM  bug fix when imgcrop was changes after mroi().
%
% See also MROIGUI, MROIGET, MROICOORD, MAREATS

if nargin < 2,
  help mtimeseries;
  return;
end;

if ~exist('Slice','var'),  Slice = [];  end



if isempty(Slice) || isequal(Slice,-1),
  %rts = subOldCode(tcImg,Roi,RoiName);
  rts = subNewCode(tcImg,Roi,RoiName,Slice); 
else
  rts = subNewCode(tcImg,Roi,RoiName,Slice); 
end


return



function rts = subNewCode(tcImg,Roi,RoiName,Slice)

if isempty(RoiName),  RoiName = 'all';  end
if isequal(Slice,-1) || isempty(Slice),  Slice = 1:size(tcImg.dat,3);  end

%Roi = mroiget(Roi,Slice,RoiName);
rts = {};

coords = [];
for N = 1:length(Roi.roi),
  roiroi = Roi.roi{N};
  % check RoiName
  if ~strcmpi(RoiName,'all') && ~any(strcmpi(RoiName,roiroi.name)), continue;  end
  % check Slice
  if ~any(Slice == roiroi.slice),  continue;  end
  % now selected by RoiName AND Slice
  if size(Roi.roi{N}.mask,1) ~= size(tcImg.dat,1) || size(Roi.roi{N}.mask,2) ~= size(tcImg.dat,2)
    % imgcrop may be changed after mroi().
    if any(Roi.roi{N}.px),
      tmpbw = poly2mask(Roi.roi{N}.px,Roi.roi{N}.py,size(tcImg.dat,2),size(tcImg.dat,1));
      Roi.roi{N}.mask = tmpbw'; % (y,x) --> (x,y)
    end
  end
  [x y] = find(Roi.roi{N}.mask);
  z = zeros(size(x));  z(:) = roiroi.slice;
  coords = cat(1,coords,[x(:),y(:),z(:)]);
end

if isempty(coords),  return;  end


szimg = size(tcImg.dat);

% check duplicated voxels
tmpidx = sub2ind(szimg(1:3),coords(:,1),coords(:,2),coords(:,3));
tmpidx = sort(unique(tmpidx));
[x y z] = ind2sub(szimg(1:3),tmpidx);
coords = [x(:),y(:),z(:)];
clear tmpidx;

% set coords and time courses
rts.name   = RoiName;
rts.coords = coords;
rts.dat    = mtcfromcoords(tcImg,coords);
rts.slice  = Slice;
rts.roiSlices = Slice;

  


return





function rts = subOldCode(tcImg,Roi,RoiName)
% ======================================================================
% FIRST CONCATANATE ALL ROIS OF THE SAME AREA IN A SLICE
% IF FOR EXAMPLE WE HAVE RIGHT/LEFT V1, THIS OPERATION WILL MAKE
% THE SEPARATE V1 (LEFT) AND V1 (RIGHT) ONE AREA OR-ING THE MASKS
% AND CONCATANATING THE COORDINATES
% ======================================================================

oRoi = mroicat(Roi);

% ======================================================================
% NOW SELECT ONE AREA WITH ONE OR MULTIPLE CONCATANATED ROIs
% ======================================================================
oRoi = mroiget(oRoi,[],RoiName);
if isempty(oRoi.roi),
  rts = {};
  return;
end;
rts.name = RoiName;

% ======================================================================
% HERE THE MASK WILL TURN INTO A 3D ARRAY!
% ======================================================================

try
for N=1:length(oRoi.roi),
  rts.mask(:,:,N) = oRoi.roi{N}.mask;
  rts.roiSlices(N) = oRoi.roi{N}.slice;
end;
catch
  keyboard
end

% ======================================================================
% NOW GET THE TIME COURSES OF THE SIGNLAS FOR EACH VOXEL
% ======================================================================
ofs = 1;

try
  if 0,
    % 2007.11.22 YM:  THIS IS OLD CODE, CAUSING MEMORY-PROBLEM in cat() for 162x82x13x256
    for N=1:length(rts.roiSlices),
      mask = rts.mask(:,:,N);
      [x,y] = find(mask);
      
      %%% BUG: coords = [x y ones(length(x),1)*N];
      coords = [x y ones(length(x),1)*rts.roiSlices(N)];

      rts.ntc{N} = [ofs ofs+length(x)-1];
      ofs = ofs + length(x);
      tc = mtcfromcoords(tcImg,coords);
      ix = find(mask(:));
      if N==1,
        rts.ix = ix;
        rts.coords = coords;
        rts.dat = tc;
      else
        rts.ix = cat(1,rts.ix,ix);
        rts.coords = cat(1,rts.coords,coords);
        rts.dat = cat(2,rts.dat,tc);
      end;
    end;
  else
    % 2007.11.22 YM: minimize memory-problem with this code.
    nvox = length(find(rts.mask(:)));
    rts.coords = zeros(nvox,3);
    rts.dat    = [];
    ivox       = 0;
    for N=1:length(rts.roiSlices),
      mask = rts.mask(:,:,N);
      [x,y] = find(mask);
      if isempty(x), continue;  end
      
      %%% BUG: coords = [x y ones(length(x),1)*N];
      coords = [x y ones(length(x),1)*rts.roiSlices(N)];
      
      tmpsel = (1:length(x)) + ivox;
      rts.coords(tmpsel,:) = coords;
      ivox = ivox + length(x);
    end
    clear coords tmpsel mask x y;
    rts.dat = mtcfromcoords(tcImg,rts.coords);
  end
catch
  disp(lasterr);
  keyboard;
end;
  

return
