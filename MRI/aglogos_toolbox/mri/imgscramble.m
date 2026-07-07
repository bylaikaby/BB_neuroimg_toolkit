function oImg = imgscramble(img)
%IMGSCRAMBLE - Scramble RGB images w/ quasi-similar PowSpec
% oImg IMGSCRAMBLE (img) returns the phase-scramble version of the
% input image img
% NKL 09.10.98
%  

if nargin < 1,
  fprintf('imgscramble: DEMO-MODE\n');
  fprintf('imgscramble: reading file ScrambleExample.jpg\n');
  DIRS = getdirs;
  if strcmp(DIRS.HOSTNAME,'win58'),
    cddemo;
  end;

  FileName = 'ScrambleExample.jpg';
  img = imread(FileName,'JPEG');
  f2 = fftshift(fft2(img));
  f2abs = log(abs(f2));
  figure('position',[10 60 800 800]);
  set(gcf,'DefaultAxesBox',		'on');
  set(gcf,'DefaultAxesfontsize',	10);
  set(gcf,'DefaultAxesFontName', 'Comic Sans MS');
  set(gcf,'DefaultAxesfontweight','bold');

  msubplot(2,2,1);
  subimage(img);

  msubplot(2,2,2);
  dspimgsurf(f2abs);
  set(gca,'zlim',[4 12],'clim',[4 12]);
  view(-40,65);
  colormap(gray);

  msubplot(2,2,3);
  simg = DoScrambling(img);
  subimage(simg);

  msubplot(2,2,4);  
  f2 = fftshift(fft2(simg));
  f2abs = log(abs(f2));
  dspimgsurf(f2abs);
  set(gca,'zlim',[4 12],'clim',[4 12]);
  view(-40,65);
  colormap(gray);

  suptitle('IMGSCRAMBLE-DEMO: FileName = ScrambleExample.jpg');
  return;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function simg = DoScrambling (img)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Shuffle phases.. dirty but ok for now
% NKL, 01.02.99
width	= size(img,1);
height	= size(img,2);
fimg  = fft2(img);
absft = abs(fimg);
phft  = angle(fimg);
idx  = rand(width*height,1);
[dum idx] = sort(idx);
idx = repmat(reshape(idx,width,height),[1 1 size(img,3)]);
simg = real(fft2(absft.*exp(i*idx)));
simg = simg - min(simg(:));
simg = uint8(255 * simg/max(simg(:)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dspimgsurf(img,mode)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DSPIMGSURF - Display an image as surface-plot
% NKL, 01.02.99
if nargin < 2,
  mode = 1;
end;
if size(img,3) > 1,
  img = mean(img,3);
end;

if mode == 1,
  img = double(img);
  [x,y]=meshgrid([1:size(img,1)],[1:size(img,2)]);
  bot = mesh(x,y,img,img);
  set(bot,'FaceColor','texturemap');
  set(bot,'CData',img);
  set(gca,'xlim',[1 size(img,1)], 'ylim',[1 size(img,2)]);
  view(-42,75);
else
  surf([1:size(img,1)],[1:size(img,2)],double(img));
  colormap(jet);
end;
  





