function dspimgsurf(img,mode)
%DSPIMGSURF - Display an image as surface-plot
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
end;

  
