function tc = mtcfromcoords(tcImg,coords)
%MTCFROMCOORDS - Get time series of a ROI on the basis "coords"
% oRoi = MTCFROMCOORDS (tcImg, coords) returns the time series of the
% voxels having coordinates "coords". The coordinates are defined
% in the "save" case of the Main_Callback of the MROIGUI
% script.
%  
% They are calculated as follows:
% for RoiNo = 1:length(Roi.roi),
%   if isfield(Roi.roi{RoiNo},'anamask'),
%     Roi.roi{RoiNo}.mask=imresize(double(Roi.roi{RoiNo}.anamask),DIMS);
%   end
%   [x,y] = find(Roi.roi{RoiNo}.mask);
%   Roi.roi{RoiNo}.coords = [x y ones(length(x),1)*Roi.roi{RoiNo}.slice];
% end;
% and stored in the field Roi.roi.coords. Scaling because of
% differences in the size of tha anatomy and EPI images is taken
% into account.
% NKL 03.04.04  

if nargin < 2,
  help mtcfromcoords;
  return;
end;


if 1,
  szimg = size(tcImg.dat);
  idx = sub2ind(szimg(1:3), coords(:,1),coords(:,2),coords(:,3));
  tcImg.dat = reshape(tcImg.dat, [prod(szimg(1:3)), szimg(4)]);
  if length(idx)*size(tcImg.dat,2)*8 > 300e-6,
    % likely to cause memory problem when transposing at a time
    tc = zeros(size(tcImg.dat,2),length(idx),class(tcImg.dat));
    for N=1:length(idx),
      tc(:,N) = tcImg.dat(idx(N),:)';
    end
  else
    tc = tcImg.dat(idx,:)';
  end
else
  % OLD CODE
  tc = zeros(size(tcImg.dat,4),size(coords,1),class(tcImg.dat));
  for N=1:size(coords,1),
    tmp = tcImg.dat(coords(N,1),coords(N,2),coords(N,3),:);
    tc(:,N) = tmp(:);
  end;
end

