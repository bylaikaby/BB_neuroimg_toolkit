function VOL = mconv3(VOL,VOXDIM_mm,KSIZE_mm,FWHM_mm)
%MCONV3 - 3D Smoothing.
%  VOL = MCONV3(VOL,VOXDIM_mm,KSIZE_mm,FWHM_mm) applies 3D smoothing.
%
%  NOTE :
%    * VOL can be N dimensional array like (x,y,z,....)
%    * When KSIZE_mm is empty, the function use optimum size for the given FWHM_mm.
%    * Gaussian SD is FWHM/(2*sqrt(2*log(2))).
%
%  EXAMPLE :
%    tcImg.dat = mconv3(tcImg.dat, tcImg.ds, 3,  1);
%    tcImg.dat = mconv3(tcImg.dat, tcImg.ds, [], 1);
%    tcImg     = mconv3(tcImg,     tcImg.ds, 3,  1);
%    VOL       = mconv3(rand(100,100,20), [1 1 1], 5, 1.5);
%
%  VERSION :
%    0.90 17.01.12 YM  pre-release
%
%  See also mareats mimgpro spm_smoothkern spm_conv_vol spm_smooth

if nargin < 4,  eval(sprintf('help %s',mfilename));  return;  end

if isstruct(VOL) && isfield(VOL,'dat') && isfield(VOL,'ds'),
  % called like mconv3(tcImg,...)
  if isempty(VOXDIM_mm),  VOXDIM_mm = VOL.ds;  end
  VOL.dat = mconv3(VOL.dat,VOXDIM_mm,KSIZE_mm,FWHM_mm);
  return
end


if isempty(VOXDIM_mm),  VOXDIM_mm = [1 1 1];  end

if length(FWHM_mm) < 3,
  FWHM_mm(end+1:3) = FWHM_mm(1);
end

% Full Width at Half Maximum
%FWHM_mm = 2 * sqrt(2*log(2)) * KSD_mm;


s  = FWHM_mm ./ VOXDIM_mm;   % voxel anisotropy
s1 = s / sqrt(8*log(2));     % FWHM -> Gaussian parameter

x  = round(6*s1(1));
y  = round(6*s1(2));
z  = round(6*s1(3));


if any(KSIZE_mm),
  if length(KSIZE_mm) < 3
    KSIZE_mm(end+1:3) = KSIZE_mm(1);
  end
  r = round(KSIZE_mm/2 ./ VOXDIM_mm);  % radius
  %r(r < 1) = 1;
  x = min(r(1),x);
  y = min(r(2),y);
  z = min(r(3),z);
end

x = -x:x; x = spm_smoothkern(s(1),x,1); x  = x/sum(x);
y = -y:y; y = spm_smoothkern(s(2),y,1); y  = y/sum(y);
z = -z:z; z = spm_smoothkern(s(3),z,1); z  = z/sum(z);

i  = (length(x) - 1)/2;
j  = (length(y) - 1)/2;
k  = (length(z) - 1)/2;


volsz = size(VOL);
if length(volsz) > 4,
  DO_RESHAPE = 1;
  VOL = reshape(VOL,[volsz(1:3) prod(volsz(4:end))]);
else
  DO_RESHAPE = 0;
end



% % spm_conv_vol() doesn't support more than 3D...
% Q = zeros(volsz,class(VOL));  % temp buffer for SPM
% spm_conv_vol(VOL,Q,x,y,z,-[i j k]);
% VOL = Q;

Q = zeros(volsz(1:3),class(VOL));  % temp buffer for SPM
offsets = -[i j k];
for N = 1:size(VOL,4),
  V = VOL(:,:,:,N);
  spm_conv_vol(V,Q,x,y,z,offsets);
  VOL(:,:,:,N) = Q;
end


if DO_RESHAPE,
  VOL = reshape(VOL,volsz);
end


return
