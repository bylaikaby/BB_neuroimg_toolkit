function mrender(img, ARGS)
%MRENDER - rendering monkey anatomy data
%	1. Make entire-head rendering
%	2. Make partial removal of skull to see structures
%	nkl, 10.12.00
%
%	SUBVOLUME  Extract subset of volume dataset.
%    [NX, NY, NZ, NV] = SUBVOLUME(X,Y,Z,V,LIMITS) extracts a subset of
%    volume dataset V using specified axis-aligned LIMITS. LIMITS = 
%    [xmin xmax ymin ymax zmin zmax] (Any nans in the limits indicate 
%    that the volume should not be cropped along that axis.) Arrays X, 
%    Y and Z specify the points at which the data V is given. The 
%    subvolume is returned in NV and the coordinates of the subvolume 
%    are given in NX, NY and NZ.
% 
%    [NX, NY, NZ, NV] = SUBVOLUME(V,LIMITS) assumes  
%                [X Y Z] = meshgrid(1:N, 1:M, 1:P) where [M,N,P]=SIZE(V).
%    
%    NV = SUBVOLUME(...) returns the subvolume only.
% 
%    Example:
%       load mri
%       D = squeeze(D);
%       [x y z D] = subvolume(D, [60 80 nan 80 nan nan]);
%       p = patch(isosurface(x,y,z,D, 5), 'FaceColor', 'red', 'EdgeColor', 'none');
%       p2 = patch(isocaps(x,y,z,D, 5), 'FaceColor', 'interp', 'EdgeColor', 'none');
%       view(3); axis tight;  daspect([1 1 .4])
%       colormap(gray(100))
%       camlight; lighting gouraud
%       isonormals(x,y,z,D,p);


if nargin < 1,
	error('usage: mrender(img)');
	return;
end;

XRANGE		= [nan nan];
YRANGE		= [nan nan];
ZRANGE		= [nan nan];
PLOT_TYPE	= 1;

if (nargin == 2),				% Eval parameters in struct etc.
   tmp = fieldnames(ARGS);		% cell array of strings.
   for i = 1:length(tmp),
      eval(sprintf('%s = %s;',tmp{i},strcat('ARGS.',tmp{i})),'');
   end;
end;

LIMITS = [XRANGE YRANGE ZRANGE];
LIMITS = LIMITS(:);

if length(size(img)) == 4,
	warning('Ignoring 4th dimension: uses img(:,:,:,1)');
	img = squeeze(img(:,:,:,1));
end;

width	= size(img,1);
height	= size(img,2);
nslices = size(img,3);

if (width > 128 | height > 128),
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
figure('Position',[10, 450, 512, 512]);

if PLOT_TYPE == 0,
   fprintf('Creating isosurface\n');
   hiso = patch(isosurface(imgs,5),'FaceColor',[1,.75,.65], 'EdgeColor','none');

   lightangle(45,30);
   view(135,40);
   axis tight
   daspect([1,1,1]);
   colormap('default');

   fprintf('Creating isocups\n');
   hcap = patch(isocaps(img,5),'FaceColor','interp', 'EdgeColor','none');

   fprintf(1,'Creating isonormals');
   isonormals(imgs,hiso);
   set(hcap,'AmbientStrength',.6);
   set(hiso,'SpecularColorReflectance',0,'SpecularExponent',50);

else
   [x,y,z,imgpart]  = subvolume(img,LIMITS);

   fprintf('Smoothing surface data ...\n');
   imgparts = smooth3(imgpart,'gaussian',3);

   fprintf('Creating partial isosurface and isonormals\n');
   p1 = patch(isosurface(x,y,z,imgparts),'FaceColor',[.95 .85 .8],'EdgeColor','none');
   isonormals(x,y,z,imgparts,p1);

   fprintf('Creating partial isocaps\n');
   % THIS ONE HERE, FILLS IN THE 'HOLES' !! KEEP IT AROUND 
   imgpart = (4 * imgpart + smooth3(imgpart,'box',[9 9 3]))/5;
   p2 = patch(isocaps(x,y,z,imgpart),'FaceColor','interp','EdgeColor','none');

   lightangle(130,55);
   view(130,55);
   axis tight
   daspect([1,1,1]);
   colormap(gray);

   camlight right;
   camlight left;
   lighting gouraud;

   set(p1,'AmbientStrength',.25);
   set(p1,'DiffuseStrength',.55);
   set(p1,'SpecularColorReflectance',0);
   set(p1,'SpecularExponent',60);

   set(p2,'AmbientStrength',0.9);
   set(p2,'DiffuseStrength',0.2);
   set(p2,'SpecularExponent',120);
   set(p2,'SpecularColorReflectance',0);
end;


