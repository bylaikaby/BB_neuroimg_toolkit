
  
  
  
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function NEWVOL = subAlignSliceCorr(IMGVOL,REFVOL)

nx = size(IMGVOL,1);
ny = size(IMGVOL,2);

xsli = 1:round(nx/10):nx;  xsli = unique(xsli(2:end-1));
ysli = 1:round(ny/10):ny;  ysli = unique(ysli(2:end-1));

NEWVOL = zeros(size(IMGVOL),class(IMGVOL));

for Z = 1:size(IMGVOL,3),
  refimg = REFVOL(:,:,Z);
  curimg = IMGVOL(:,:,Z);
  
  %C = xcorr2(curimg,refimg);
  C = normxcorr2(curimg,refimg);
  [maxv maxi] = max(C(:));
  [ix iy] = ind2sub(size(C),maxi);
  ix = ix - size(curimg,1);
  iy = iy - size(curimg,2);
  
  if ix == 0 && iy == 0,
    NEWVOL(:,:,Z) = IMGVOL(:,:,Z);
    continue;
  end
  
  tmpx1 = [1:size(IMGVOL,1)];
  tmpx2 = [1:size(IMGVOL,1)] + ix;
  tmpidx = find(tmpx2 > 0 & tmpx2 < size(IMGVOL,1));
  tmpx1 = tmpx1(tmpidx);
  tmpx2 = tmpx2(tmpidx);
  
  tmpy1 = [1:size(IMGVOL,2)];
  tmpy2 = [1:size(IMGVOL,2)] + iy;
  tmpidx = find(tmpy2 > 0 & tmpy2 < size(IMGVOL,2));
  tmpy1 = tmpy1(tmpidx);
  tmpy2 = tmpy2(tmpidx);
  
  NEWVOL(tmpx1,tmpy1,Z) = IMGVOL(tmpx2,tmpy2,Z);
  
  
  figure;
  subplot(1,3,1); imagesc(refimg');
  subplot(1,3,2); imagesc(curimg');
  subplot(1,3,3); imagesc(NEWVOL(:,:,Z)');
  keyboard
  
end

  
return
 