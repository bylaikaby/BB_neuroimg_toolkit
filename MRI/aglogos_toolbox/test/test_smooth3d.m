

tcImg = sigload('Q11bX1',1,'tcImg');


sd = [1 1 1];  % in mm

s = 2 * sqrt(2*log(2)) * sd;  % FWHM in mm


VOX = tcImg.ds;
V = squeeze(tcImg.dat(:,:,:,1));
Q = zeros(size(V),class(V));




s  = s./VOX;                        % voxel anisotropy
s1 = s/sqrt(8*log(2));              % FWHM -> Gaussian parameter

sd = (s/2)/sqrt(2*log(2));


x  = round(6*s1(1)); x = -x:x; x = spm_smoothkern(s(1),x,1); x  = x/sum(x);
y  = round(6*s1(2)); y = -y:y; y = spm_smoothkern(s(2),y,1); y  = y/sum(y);
z  = round(6*s1(3));
z = 0;
z = -z:z; z = spm_smoothkern(s(3),z,1); z  = z/sum(z);

i  = (length(x) - 1)/2;
j  = (length(y) - 1)/2;
k  = (length(z) - 1)/2;


spm_conv_vol(V,Q,x,y,z,-[i j k]);
