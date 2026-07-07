function varargout = mroidsp(img,cbar,gamma,mytitle,cormap,thr,COLORS,atlas,atlascolor)
%MROIDSP - Display image in GCF to obtain ROIs
% MROIDSP (img) displays the image img in the right orientation to
% calculate regions of interest.
% H = MROIDSP(img) returns a handle to the plotted image.
%
%
% See also MROI, DSPIMG


if nargin < 2,  cbar=0;        end;

% windows computers has gamma of 2.2
if nargin < 3,  gamma = 2.1;   end;

if nargin < 4,  mytitle = '';  end;

if nargin < 5, cormap = [];    end
if nargin < 6, thr  = 0;       end
if nargin < 7, COLORS = [];    end
if nargin < 8, atlas = [];     end
if nargin < 9, atlascolor = [];  end

%settings for atlas
fuse_atlas=1; % switch for atlas, 1= fuse image, 0=overlay image
thres=35; %threshold for color which will be included

if ~isa(img,'double'), img = double(img);  end

img = mean(img,4);

if gamma,
  maximg = max(img(:));
  minimg = min(img(:));
  if maximg ~= minimg,
    img = (img - minimg) ./ (maximg - minimg);
  else
    img(:) = 0.5;
  end
  img = imadjust(img,[0.015 0.95],[0 1],1/gamma);
end

if isempty(cormap),
    if ~isempty(atlas)%add only atlas-overlay exists
      if isempty(atlascolor),  atlascolor = 'yellow';  end
      if ischar(atlascolor),
        switch lower(atlascolor)
         case {'r','red'}
          atlascolor = gray(256);
          atlascolor(:,2) = 0;
          atlascolor(:,3) = 0;
         case {'g','green'}
          atlascolor = gray(256);
          atlascolor(:,1) = 0;
          atlascolor(:,3) = 0;
         case {'b','blue'}
          atlascolor = gray(256);
          atlascolor(:,1) = 0;
          atlascolor(:,2) = 0;
         case {'y','yellow'}
          atlascolor = gray(256);
          atlascolor(:,3) = 0;
         case {'gray'}
          atlascolor = gray(256);
         otherwise
        end
      end
      
      img = round(img*256);
      img(img(:) > 256) = 256;
      img(img(:) <   1) =   1;
      img = ind2rgb(img,gray(256));
      img=permute(img,[2 1 3]); 
      atlas = 256 - atlas;        % make black as white
      if fuse_atlas% fusion version          atlind=find(atlas(:)>thres); %find all pixel over threshold
          atlind=find(atlas(:)>thres); %find all pixel over threshold
          atlas = ind2rgb(atlas,atlascolor); %change colormap to rgb 
            [x(:,1) x(:,2)]=ind2sub([size(img,1) size(img,2)],atlind); %convert to coordinates
            for kk=1:length(x)
                img(x(kk,1),x(kk,2),:)=atlas(x(kk,1),x(kk,2),:);   %overwirte pixel
            end
          hImage = imshow(img);
      else %overlay-version
          hImage = imshow(img);
          hold on
          atlas = ind2rgb(atlas,atlascolor);
          %atlas = permute(atlas,[2 1 3]);
          k=imshow(atlas);
          set(k,'AlphaData',0.5)
          hold off
      end
    else % do as before
         hImage = imagesc(img');
         colormap(gray(256)); 
    end
 
else
  % superimpose the corr.map
  if size(img,1)~=size(cormap,1) | size(img,2)~=size(cormap,2),
    cormap = imresize(cormap,[size(img,1),size(img,2)]);
  end

  % scale 'img' to [0 1] if not scaled by 'gamma', see above.
  if gamma <= 0,
    maximg = max(img(:));
    minimg = min(img(:));
    if maximg ~= minimg,
      img = (img - minimg) ./ (maximg - minimg);
    else
      img(:) = 0.5;
    end
  end
  % now scale 'img' to [0 255]
  img = round(img*255);
  
  % index to rgb
  img(find(isnan(img(:)) == 1)) = 1; % to avoid error in ind2rgb
  img = ind2rgb(img+1,colormap(gray(256)));

  % fuse corr.map into 'img'
  if size(cormap,3) == 1,
    img = subFuseImages(img,cormap,thr,'mri');
  else
    if isempty(COLORS),
      cormap = max(cormap,[],3);
      img = subFuseImages(img,cormap,thr,'mri');
    else
      for N = 1:size(cormap,3),
        img = subFuseImages(img,squeeze(cormap(:,:,N)),thr,COLORS(N));
      end
    end
  end
  hImage = imshow(permute(img,[2 1 3]));
end

daspect([1 1 1]);
axis off;



if cbar,
  cb = colorbar;
  set(cb,'xcolor','y','ycolor','y');
  set(cb,'fontsize',8);
end;
if ~isempty(mytitle),
  title(mytitle,'color','r','fontsize',14);
end;


% return image's handle, if needed.
if nargout > 0,
  varargout{1} = hImage;
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subfunction to fuse images
function img = subFuseImages(img,cormap,thr,colorname)
    
% get activated pixels
actidx = repmat(cormap,[1,1,3]);  % repmat for r,g,b
actidx = find(abs(actidx(:)) > thr);   % select by threshold
if ~isempty(actidx),
  % scale 'cormap' [-1 1] to [0 255]
  cormap =  round((cormap + 1)/2*255);
  cormap(find(isnan(cormap(:)) == 1)) = 1; % to avoid error in ind2rgb
  cormap = ind2rgb(cormap,subColorCode(colorname,256));
  % fuse images
  img(actidx) = cormap(actidx);
end



return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subfunction to get a color-code
function c = subColorCode(colorname,nlevels)

switch lower(colorname)
 case {'default','defalt','defult'}
  % Matlab does change colormap size to 64x3, so get original size.
  norig = size(colormap,1);
  c = colormap(colorname);
  n = size(c,1);
 
 case { 'mri' }
  h = round(nlevels/2);
  c = hot(h);
  c1 = zeros(h,3);
  c1(:,3) = [0:h-1]'./h;
  c = cat(1,flipud(c1),c);
  n = size(c,1);
  
 case { 'autumn','bone','colorcube','cool','copper',...
	'flag','gray','hot','hsv','jet','lines','pink','prism',...
	'spring','summer','white','winer' }
  % Matlab doen't change colormap size.
  c = eval(sprintf('colormap(%s(%d))',colorname,nlevels));
  n = size(c,1);
 % change number of levels for image
if nlevels ~= n,
  c = interp1(1:n,c,1:(n - 1)/(nlevels - 1):n,'linear');
end

 case { 'r' }
  x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  c(:,[2 3]) = 0;
 case { 'g' }
  x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  c(:,[1 3]) = 0;
 case { 'b' }
  x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  c(:,[1 2]) = 0;
 case { 'c' }
  x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  c(:,1) = 0;
 case { 'm' }
  x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  c(:,2) = 0;
 case { 'y' }
  x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  c(:,3) = 0;
 case { 'k' }
  %x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  % black is meaning less, so use 'yellow'
  x = [0:nlevels-1] / (nlevels-1);  c = [x',x',x'];
  c(:,3) = 0;
  
 otherwise
  fprintf(' not supported ''%s''\n',colorname);
  return;
end


