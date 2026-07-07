function roiTs = icagetroits(Roi)
%ICAGETROITS - Get time series of selected ROIS
% roi = icagetroits(Roi) the function is usually called in conjuction with:
% Roi = icagetroi(Ses,Grp);
% roiTs = icagetroits(Roi);
% 
% NKL 21.05.07
%

if nargin < 1,
  help icagetroits;
  return;
end;


tcImg = sigload(Roi.session,Roi.ExpNo,'tcImg');
rts1 = getTC(tcImg,Roi,Roi.roinames{1});
rts2 = getTC(tcImg,Roi,Roi.roinames{2});
roiTs = rmfield(rts1,'dat');
roiTs.NumW = [size(rts1.dat,2) size(rts2.dat,2)];
roiTs.dat(:,1) = hnanmean(rts1.dat,2);
roiTs.dat(:,2) = hnanmean(rts2.dat,2);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function rts = getTC(tcImg, Roi, RoiName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
oRoi = mroicat(Roi);
oRoi = mroiget(oRoi,[],RoiName);
if isempty(oRoi.roi),
  rts = {};
  return;
end;
rts.name = RoiName;

for N=1:length(oRoi.roi),
  rts.mask(:,:,N) = oRoi.roi{N}.mask;
  rts.roiSlices(N) = oRoi.roi{N}.slice;
end;

ofs = 1;
for N=1:length(rts.roiSlices),
  mask = rts.mask(:,:,N);
  [x,y] = find(mask);
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
rts.dx = tcImg.dx;

