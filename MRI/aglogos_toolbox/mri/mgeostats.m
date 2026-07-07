function stat = mgeostats(SESSION, ExpNo)
%MGEOSTATS - Compute geometrical statistics by using imfeature
%	sts = MGEOSTATS(SESSION, ExpNo), computes center of mass
%	(centroid), area and other statistics by using sesroi.mat and the
%	imfeature of the Image Processing Toolbox.
%
%	If MEASUREMENTS is the string 'all', then all of the above
%   measurements are computed. If MEASUREMENTS is not specified
%   or if it is the string 'basic', then these measurements are 
%   computed: 'Area', 'Centroid', and 'BoundingBox'.
%	NKL, 27.10.02
%
%	See also IMFEATURE, SESROI

Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);

% LOAD SESROI WITH THE NOISE, BRAIN, AND ELECTRODE ROIS
load('sesroi.mat');
eval(sprintf('roigrp = %s;', grp.name));
mask = double(roigrp.noise);

% LOAD DATA FILE WITH tcImg
load(catfilename(Ses,ExpNo,'tcimg'),'tcImg');

% COMPUTE NOISE MEAN/STD AND SET THRESHOLD
tmp = tcImg.dat .* repmat(mask, [1 1 size(tcImg.dat,3)]);
NoiseMean = nanmean(tmp(:));
NoiseStd = nanstd(tmp(:));
Thr = NoiseMean + 3 * NoiseStd;

% BINARIZE IMAGE
tcImg.dat(find(tcImg.dat<Thr)) = 0;
tcImg.dat(find(tcImg.dat)) = 1;

% COMPUTE CENTROID FOR EACH SLICE
for N=1:size(tcImg.dat,3),
	L = bwlabel(tcImg.dat(:,:,N));
	c = imfeature(L,'centroid');
	centroid.x(N) = c(1).Centroid(1);
	centroid.y(N) = c(1).Centroid(2);
end;
cenx = centroid.x(:);
ceny = centroid.y(:);

mx = nanmean(cenx);
my = nanmean(ceny);
sx = nanstd(cenx);
sy = nanstd(ceny);

thrx = 3*sx;
thry = 3*sy;

ix = find(abs(cenx-mx)>thrx);
iy = find(abs(ceny-my)>thry);

dx = zeros(length(cenx),1);
dy = zeros(length(ceny),1);
dx(ix) = cenx(ix) - mx;
dy(iy) = cenx(iy) - my;

if nargout,
	stat.cenx = cenx;
	stat.ceny = ceny;
	stat.ix	  = ix;
	stat.iy	  = iy;
	stat.dx	  = dx;
	stat.dy	  = dy;
end;


