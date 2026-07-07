function img = mgetcollage(img)
%MGETCOLLAGE - shows a tcImg structure in mgetcollage-mode
% MGETCOLLAGE (tcImg) averages all time points and concatanates all
% slices to generate a single "image" for all slices.
% NKL, 27.04.04

if ~nargin,
  help mgetcollage;
  return;
end;

if isstruct(img),
  a = mean(img.dat,4);
else
  a = img;
end;

a = reshape(a,[size(a,1) size(a,2) 1 size(a,3)]);

siz = [size(a,1) size(a,2) size(a,4)];
nn = sqrt(prod(siz))/siz(2);
mm = siz(3)/nn;
if (ceil(nn)-nn) < (ceil(mm)-mm),
  nn = ceil(nn); mm = ceil(siz(3)/nn);
else
  mm = ceil(mm); nn = ceil(siz(3)/mm);
end

b = a(1,1); % to inherit type 
b(1,1) = 0; % from a
b = repmat(b, [mm*siz(1), nn*siz(2), size(a,3), 1]);

rows = 1:siz(1); cols = 1:siz(2);
for i=0:mm-1,
  for j=0:nn-1,
    k = j+i*nn+1;
    if k<=siz(3),
      b(rows+i*siz(1),cols+j*siz(2),:) = a(:,:,:,k);
    end
  end
end
img = b;

