function coords=crophelp(img,map)
% crophelp helps the user of mroi to crop the atlas picture for the right
% region
%
% it is called by mroi
%27.10.10 BS
mh=figure;
imshow(img,map);
[x,y]=ginput(2);
if x(2)<x(1)
    x=[x(2) x(1)];
end
if y(2)<y(1)
     y=[y(2) y(1)];
end
coords=[x(1) y(1) x(2)-x(1) y(2)-y(1)];
coords=uint16(coords);
close(mh)

% function [slice coords]=crophelp(atlas)
% % crophelp helps the user of mroi to crop the atlas picture for the right
% % region
% mh=figure;
% persistent mh
% 
% 
% function Main_Callback(hObject,eventdata,handles)
% switch lower(eventdata)
%     case 'draw_img'    
%         switch atlas.atlas
%             case {1,2}
%                 atlasorient='atlas.hor';
%                 %hindx=(1:47)*2+103;
%                 hindx=(1:47)-6;
%                 slice=num2str(find(hindx==str2num(atlas.slice)));
%             case {3,4}
%                 atlasorient='atlas.cor';
%                 %cindx=(76:-1:1)*2+31;%33-183
%                 cindx=(76:-1:1)-26;
%                 slice=num2str(find(cindx==str2num(atlas.slice))); %calculate the image number from the index of the atlas
%         end
% 
%         scale=eval([atlasorient '(' slice ').res']);
%         atlimg=eval([atlasorient '(' slice ').img' ]);
%         mapatlas=eval([atlasorient '(' slice ').map' ]);
%         imshow(atlimg,mapatlas);
% 
% 
%     case 'selector'
%         [x,y]=ginput(2);
%         if x(2)<x(1)
%             x=[x(2) x(1)];
%         end
%         if y(2)<y(1)
%              y=[y(2) y(1)];
%         end
%         coords=[x(1) y(1) x(2)-x(1) y(2)-y(1)];
%         coords=uint16(coords);
%         close(mh)
% end