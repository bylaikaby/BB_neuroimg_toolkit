function simg = mconv(img, ksize, sd)
%MCONV - 2D convolution w/ a gaussian kernel
%	simg = MCONV(img, ksize, sd), function to low pass filter images.
%	img: input image
%	ksize: kernel size (default = 3)
%	sd: standard deviation (default = 1) in pixels
%	NKL, 03.09.00
%   YM,  22.03.12  use reshape, supporting multidimensional data.
%
%	See also MEDFILT2, CONV2

if nargin < 3 | nargout ~= 1,
	error('usage: simg = mconv(img, ksize, sd);');
	return;
end


if ndims(img) >= 4,
  imgsz = size(img);
  img = reshape(img,[imgsz(1) imgsz(2) prod(imgsz(3:end))]);
else
  imgsz = [];
end
  


h = fspecial('gaussian',ksize,sd);


simg = zeros(size(img));
for N = 1:size(img,3)
  simg(:,:,N) = filter2(h, img(:,:,N));
end



if any(imgsz)
  img  = reshape(img,imgsz);
  simg = reshape(simg,imgsz);
end



return
