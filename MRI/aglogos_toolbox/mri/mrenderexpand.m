function mrenderexpand(img, ARGS)
%MRENDEREXPAND - rendering monkey anatomy data
%	1. Make entire-head rendering
%	2. Make partial removal of skull to see structures
%	nkl, 10.12.00

if nargin < 1,
	error('usage: mrender(img)');
	return;
end;

% DEFAULT PARAMETERS
XRANGE	= {[nan nan]; [nan nan]; [nan nan]};
YRANGE	= {[nan nan]; [nan nan]; [nan nan]};
ZRANGE	= {[nan 37]; [38 41]; [42 nan]};
XOFFSET = [0 45 0];
YOFFSET = [0 25 0];
ZOFFSET = [-25 0 20];
AmbStr  = [.2 .15 .10];
DifStr  = [.3 .25 .20];
cAmbStr  = [.8 .7 .6];
cDifStr  = [.2 .1 .1];
FIG_POSITION = [10, 300, 640, 600];

if (nargin == 2),				% Eval parameters in struct etc.
   tmp = fieldnames(ARGS);		% cell array of strings.
   for i = 1:length(tmp),
      eval(sprintf('%s = %s;',tmp{i},strcat('ARGS.',tmp{i})),'');
   end;
end;

NPARTS = length(XRANGE);
for N=1:NPARTS,
	LIMITS{N} = [XRANGE{N} YRANGE{N} ZRANGE{N}];
	LIMITS{N} = LIMITS{N}(:);
end;

if length(size(img)) == 4,
	warning('Ignoring 4th dimension: uses img(:,:,:,1)');
	img = squeeze(img(:,:,:,1));
end;

width	= size(img,1);
height	= size(img,2);
nslices = size(img,3);

if (width > 128 | heigth > 128),
	width = 128;
	height = 128;
	tmp = zeros(width,height,nslices);
	for N=1:nslices,
		tmp(:,:,N) = imresize(img(:,:,N), [width height],'nearest');
	end;
	img = tmp;
	clear tmp;
end;

img = img(:);
if max(img) <= 1,
	img = img * 255;
end;
img = reshape(img,[width height nslices]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DO RENDERING ...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure('Position', FIG_POSITION);

fprintf('Smoothing surface data ...\n');
imgs = smooth3(img,'gaussian',[5 5 3]);

for N=1:NPARTS,
   [x,y,z,pimg]   = subvolume(img, LIMITS{N});
   [x,y,z,pimgs]  = subvolume(imgs,LIMITS{N});
   x = x + XOFFSET(N);
   y = y + YOFFSET(N);
   z = z + ZOFFSET(N);

   fprintf('(%d): Creating partial isosurface and isonormals\n',N);
   p = patch(isosurface(x,y,z,pimgs),...
		'FaceColor',[.95 .85 .8],'EdgeColor','none');
   isonormals(x,y,z,pimgs,p);

   fprintf('(%d): Creating partial isocaps\n',N);
   cp = patch(isocaps(x,y,z,pimg),...
		'FaceColor','interp','EdgeColor','none');

   lightangle(130,55);
   view(130,55);
   axis tight
   daspect([1,1,1]);
   colormap(gray);
   camlight right;
   camlight left;
   lighting gouraud;

   set(p,'AmbientStrength',   AmbStr(N));
   set(p,'DiffuseStrength',   DifStr(N));
   set(cp,'AmbientStrength', cAmbStr(N));
   set(cp,'DiffuseStrength', cDifStr(N));

   set(p, 'SpecularColorReflectance',0);
   set(p, 'SpecularExponent',		 120);
   set(cp,'SpecularColorReflectance',0);
   set(cp,'SpecularExponent',		 120);
end;




