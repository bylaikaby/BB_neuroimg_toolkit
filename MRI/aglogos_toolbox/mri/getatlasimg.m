function [img map]=getatlasimg(atlas)
% getatlasimg gives back the scaled selected image from the atlas and the
% corresponding colormap. 
% As input it needs a struct which contains the atlas itself (s.cor/s.hor) and the scaling (s.scale). 
%
% 27.10.10 BS
% 17.11.10 BS added mirror and rotate
 
    
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
    atlimg=eval([atlasorient '(' slice ').img' ]);
    mapatlas=eval([atlasorient '(' slice ').map' ]);
    [ximg yimg]=size(atlimg);
    [img map]=imresize(atlimg,mapatlas,[round(scale(1)/atlas.ds(1)*ximg) round(scale(2)/atlas.ds(2)*yimg)]);  

    %if the brain has a different angle
    if atlas.rotate~=0
         img=imrotate(img,str2num(atlas.rotate),'crop');        
%         img=uint16(img);
%         preserve=find(img==0);% find all black pixels
%         img(preserve)=300;
%         img=imrotate(img,str2num(atlas.rotate));
%         newblk=find(img==0); %find the new black pixels and make the bright
%         img(newblk)=254;
%         preserve=find(img==300); %restore black pixel before rotation
%         img(preserve)=0;
%         img=uint8(img);
    end
    crop=str2num(atlas.crop);
    if any(crop<0)
        if crop(1)<0
            img=enlarge_image(img,crop(1),0);
        end
        if crop(2)<0
            img=enlarge_image(img,0,crop(2));
        end
    end
end

function nimg=enlarge_image(img,y,x)
%enlarge_image creates a bigger matrix for the atlas image and is called
%when crop is negative
    szimg=size(img);
    if x<0
        szimg(1)=szimg(1)+abs(x);
    end
    if y<0
        szimg(2)=szimg(2)+abs(y);
    end

    nimg=uint8(zeros(szimg));
    nimg(:,:)=254;
    nimg(abs(x)+1:size(nimg,1),abs(y)+1:size(nimg,2))=img;
end