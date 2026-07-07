function varargout = mgetelepos(varargin)
%MGETELEPOS - returns electrode(s) position in voxels
%  ELEPOS = MGETELEPOS(SESSION,EXPNO/GRPNAME)
%  ELEPOS = MGETELEPOS(ROITS)  returns electrode(s) position in voxels.
%
%  ELEPOS(ele#,xyz)
%
%  EXAMPLE :
%   >> [epipos anapos] = mgetelepos('m02lx1','movie1');
%   >> mgetelepos('m02lx1','movie1');   % plots electrode(s) position
%
%
%  See also MGETELEDIST

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end


if nargin == 1,
  % called like mgetelepos(roiTs)
  Ses = goto(varargin{1}{1}.session);
  grp = getgrp(Ses,varargin{1}{1}.ExpNo(1));
elseif nargin == 2,
  % called like mgetelepos(Ses,ExpNo/GrpName)
  Ses = goto(varargin{1});
  grp = getgrp(Ses,varargin{2});
end


% Load ROI
ROI = load('Roi.mat',grp.grproi);
ROI = ROI.(grp.grproi);


% Prepare electrode(s) coordinates
ELEPOS = [];  ANAPOS = [];
for N = length(ROI.ele):-1:1,
  ELEPOS(N,:) = [ROI.ele{N}.x, ROI.ele{N}.y, ROI.ele{N}.slice];  % in functional image
  ANAPOS(N,:) = [ROI.ele{N}.anax, ROI.ele{N}.anay, ROI.ele{N}.slice]; % in anatomy
end


if nargout > 0,
  varargout{1} = ELEPOS;
  if nargout > 1,
    varargout{2} = ANAPOS;
  end
else
  if isempty(ANAPOS),
    fprintf('WARNING %s: electrode(s) position is not defined yet.\n',mfilename);
    return;
  end
  figure('Name',sprintf('%s(''%s'',''%s'')',mfilename,Ses.name,grp.name));
  for N = 1:size(ANAPOS,1),
    subplot(size(ANAPOS,1),1,N);
    x = ANAPOS(N,1);  y = ANAPOS(N,2);  z = ANAPOS(N,3);
    imagesc(ROI.ana(:,:,z)');
    colormap('gray');
    set(gca, 'FontName', 'Comic Sans MS');
    hold on;
    plot(x,y,'y+','markersize',12);
    tmptxt = sprintf('ele%d: ana=(%.2f %.2f), epi=(%d,%d)', N,x,y,ELEPOS(N,1),ELEPOS(N,2));
    text(x-8,y-7,tmptxt,'color','y','fontsize',8);
    xlabel('X in voxels');  ylabel('Y in voxels');
    tmptxt = sprintf('Slice=%d',z);
    text(0.01,0.9,tmptxt,'color','y','fontsize',10,'units','normalized');
    title(sprintf('%s %s: ANATOMY slice=%d ele=%d',Ses.name,grp.name,z,N));
  end
end

return;

