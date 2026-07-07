function IDATA = fid_reco(KDATA,method)
% FID_RECO - reconstruct image from K-space data
%  IDATA = FID_RECO(KDATA,METHOD)
%
% VERSION : 0.90 17.11.04 YM  pre-release
%
% See also FID_READ, FID_RESHAPE, FID_WRITE

if nargin == 0,  help fid_reco;  return;  end

if nargin < 2,  method = 'ifft';  end


switch lower(method),
 case {'fft'}
  fhandle = @fft2;
 case {'ifft'}
  fhandle = @ifft2;
 otherwise
  fhandle = str2func(method);
end


IDATA = zeros(size(KDATA));

for iSlice = 1:size(KDATA,3),
  for iTime = 1:size(KDATA,4),
    tmpimg = double(KDATA(:,:,iSlice,iTime));
    % apply fft2, ifft2 or user function.
    tmpimg = fhandle(tmpimg);
    % substitute Zero-frequency component to the neighborhood.
    tmpimg(1,1) = (tmpimg(1,2)+tmpimg(2,2)+tmpimg(2,1))/3;
    tmpimg(1,end) = (tmpimg(1,end-1)+tmpimg(2,end-1)+tmpimg(2,end))/3;
    % shift data
    tmpimg = fftshift(tmpimg);
    IDATA(:,:,iSlice,iTime) = abs(tmpimg);
  end
end
