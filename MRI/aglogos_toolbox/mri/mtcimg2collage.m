function tcImg = mtcimg2collage(tcImg)
%MTCIMG2COLLAGE - Collage all slices into a single image.
% tcImg = MTCIMG2COLLAGE(tcImg) collages all slices into a single image.
% NKL, 30.04.04
% See also MGETCOLLAGE, XFORM

img1 = mgetcollage(squeeze(tcImg.dat(:,:,:,1)));
tmp = zeros([size(img1) 1 size(tcImg.dat,4)]);
for N=1:size(tcImg.dat,4),
  tmp(:,:,1,N) = mgetcollage(squeeze(tcImg.dat(:,:,:,N)));
end;
tcImg.dat = tmp;
  