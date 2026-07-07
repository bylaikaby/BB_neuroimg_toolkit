function dspimgdata(imgdata)
%DSPIMGDATA - Display multislice image data (dat-fields)
% DSPIMGDATA is used to quickly visualize the contents of 3D arrays
%
% NKL, 09.08.02

if ~nargin,
  help dspimgdata;
  return;
end;

if ~iscell(imgdata),
  imgdata = {imgdata};
end;

for N=1:length(imgdata),
  mfigure([20 100 800 800]);
  img = mgetcollage(imgdata{N});
  imagesc(img');
  colormap(hot);
end;
