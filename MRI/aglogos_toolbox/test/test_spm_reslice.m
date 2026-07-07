Sxyz = [ 1 1 1];
Txyz = [0 0 0];
Rxyz = [20 0 0]/180*pi;
T = eye(4);  T(1:3,4) = Txyz(:);
S = eye(4);  S([1 6 11]) = Sxyz;
Rx = eye(4); A = Rxyz(1); Rx([6 7 10 11]) = [cos(A)  sin(A) -sin(A) cos(A)];
Ry = eye(4); A = Rxyz(2); Ry([1 3  9 11]) = [cos(A) -sin(A)  sin(A) cos(A)];
Rz = eye(4); A = Rxyz(3); Rz([1 2  5  6]) = [cos(A)  sin(A) -sin(A) cos(A)];
M = Rz*Ry*Rx*T*S;  % scale, translate then rotate around xyz

M

V0 = spm_vol('D:\DataMatlab\Anatomy\Rhesus_Atlas_Bezgin\D99-test.img');
VX = spm_vol('D:\DataMatlab\Anatomy\Rhesus_Atlas_Bezgin\D99-test.img');

VX.mat = M*VX.mat;

spm_reslice([V0 VX],struct('which',1,'mean',0));


VR = spm_vol('D:\DataMatlab\Anatomy\Rhesus_Atlas_Bezgin\rD99-test.img');


IMG0 = spm_read_vols(V0);
IMGR = spm_read_vols(VR);


figure(100);
subplot(1,2,1); imagesc(squeeze(IMG0(120,:,:))');  set(gca,'ydir','normal');
subplot(1,2,2); imagesc(squeeze(IMGR(120,:,:))');  set(gca,'ydir','normal');
