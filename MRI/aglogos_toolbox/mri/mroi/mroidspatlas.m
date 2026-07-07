function varargout = mroidspatlas(img,atlas,cbar,gamma,mytitle,cormap,thr,COLORS)
%MROIDSPATLAS - Display image in GCF to obtain ROIs and overlay it with the
%atlas 
% MROIDSPATLAS (img) displays the image img in the right orientation to
% calculate regions of interest.
% H = MROIDSPATLAS(img) returns a handle to the plotted image.
%
%
% See also MROI, DSPIMG, MROIDSPATLAS
%
% 27.10.10 BS
% 17.11.10 BS adjustments/bugfixing
% 30.11.10 BS added usability for transformed atlas
% 11.04.11 YM use .map for color, rgb before imresize


    if nargin < 3,  cbar=0;        end;

    % windows computers has gamma of 2.2
    if nargin < 4,  gamma = 2.1;   end;

    if nargin < 5,  mytitle = '';  end;

    if nargin < 6, cormap = [];    end
    if nargin < 7, thr  = 0;       end
    if nargin < 8, COLORS = [];    end


    if isstruct(atlas)
        %check here for crop
        if isfield(atlas,'Roidef_atlas') && atlas.atlas==5
            %for roidef_atlas
            if length(atlas.Roidef_atlas.atlas) < atlas.slicetrans,
              hImage=mroidsp(img,cbar,gamma,mytitle,cormap,thr,COLORS);
            else
              atlimg = atlas.Roidef_atlas.atlas(atlas.slicetrans).img;
              atlimg = ind2rgb(atlimg,atlas.Roidef_atlas.atlas(atlas.slicetrans).map);
              % note that atlas(slice).img as (y,x)
              atlimg = imresize(atlimg,size(img'));
              hImage=mroidsp(img,cbar,gamma,mytitle,cormap,thr,COLORS,...
                             atlimg,'none');
            end
        else 
            switch atlas.atlas
                case {1,2}
                    atlasorient='atlas.hor';
                    %hindx=(1:47)*2+103;
                    hindx=(1:47)-6;
                    slice=num2str(find(hindx==str2num(atlas.slice)));
                case {3,4}
                    atlasorient='atlas.cor';
                    %cindx=(76:-1:1)*2+31;%33-183
                    cindx=(76:-1:1)-26;
                    slice=num2str(find(cindx==str2num(atlas.slice))); %calculate the image number from the index of the atlas
            end

            scale=eval([atlasorient '(' slice ').res']);
            crop=round(str2num(atlas.crop)./scale(1)./10);
            atlas.crop=num2str(crop);
            %load and scale image
            [atlimg mapatlas]=getatlasimg(atlas);
            %sanity check: image size versus crop
            [ximg yimg]=size(atlimg);
            crop=check_limits(crop,ximg,yimg);
            %atlimg=ind2gray(atlimg(crop(1):crop(2),crop(3):crop(4)),mapatlas);
            atlimg=ind2rgb(atlimg(crop(1):crop(2),crop(3):crop(4)),mapatlas);
            % note that atlimg as (y,x)
            atlimg=imresize(atlimg,size(img'));
            %overlay the anatomical scan
            hImage=mroidsp(img,cbar,gamma,mytitle,cormap,thr,COLORS,atlimg);
        end
    else
        disp('atlas is missing in getdirs!')
    end

    if nargout > 0,
      varargout{1} = hImage;
    end
end

function newcrop=check_limits(crop,ximg,yimg)
% check_limits checks the limits of the to be cropped image and 
% gives back the coordinates for the image in the format [x1,x2,y1,y2].
% Input format is [x,y,w,h] and the limits of the image ximg und yimg.

xcoord=crop(2);
ycoord=crop(1);
width=crop(4);
height=crop(3);

% if the crop is larger as the new image
height= min(height,yimg-1);
width = min(width,ximg-1);

%if the width from xcoord is larger as the image
xcoord = max(1,min(xcoord,ximg-width));

%if the height from ycoord is larger as the image
ycoord = max(1,min(ycoord,yimg-height));


newcrop=[xcoord xcoord+width ycoord ycoord+height]; % now its [x1,x2,y1,y2]
end