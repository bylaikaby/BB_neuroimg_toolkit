goto('d03se1');
load mdeft;
mdeft = mdeft{1};

v = double(mdeft.dat);  v = permute(v,[1 3 2]);

nX = size(v,1);  nY = size(v,2);  nZ = size(v,3);

iX = 25,  iY = 100;  iZ = 50;



figure;
tmpv = squeeze(v(iX,:,:));
[xi,yi,zi] = meshgrid(iX,1:nY,1:nZ);
hSag = surface(...
    'xdata',reshape(xi,[nY,nZ]),'ydata',reshape(yi,[nY,nZ]),'zdata',reshape(zi,[nY,nZ]),...
    'cdata',tmpv,...
    'facecolor','texturemap','edgecolor','none',...
    'CDataMapping','scaled','linestyle','none');
tmpv = squeeze(v(:,iY,:));
[xi,yi,zi] = meshgrid(1:nX,iY,1:nZ);
hCor = surface(...
    'xdata',reshape(xi,[nX,nZ]),'ydata',reshape(yi,[nX,nZ]),'zdata',reshape(zi,[nX,nZ]),...
    'cdata',tmpv,...
    'facecolor','texturemap','edgecolor','none',...
    'CDataMapping','scaled','linestyle','none');
tmpv = squeeze(v(:,:,iZ));
[xi,yi,zi] = meshgrid(1:nX,1:nY,iZ);
hTra = surface(...
    'xdata',1:nX,'ydata',1:nY,'zdata',reshape(zi,[nY,nX]),...
    'cdata',tmpv',...
    'facecolor','texturemap','edgecolor','none',...
    'CDataMapping','scaled','linestyle','none');

view(53,36);  grid on;
set(gca,'zdir','reverse');
xlabel('X'); ylabel('Y');  zlabel('X');


% tmpv = squeeze(v(:,:,iZ));
% hZ = surface('xdata',1:nX,'ydata',1:nY,'zdata',ones(nX,nY)'*iZ,'cdata',tmpv',...
%             'facecolor','texturemap','edgecolor','none',...
%             'CDataMapping','scaled','linestyle','none');

% hold on;



%figure;
%h = slice(v,iX,iY,iZ);
%set(h,'facecolor','texturemap','edgecolor','none','CDataMapping','scaled','linestyle','none');
