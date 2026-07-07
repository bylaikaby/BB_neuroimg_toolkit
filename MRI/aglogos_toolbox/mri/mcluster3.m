function [ocoords, idx] = mcluster3(coords,B,cutoff)
%MCLUSTER3 - Cluster analysis on "coords" to discard single voxels of activation 
% MCLUSTER3 is a variation of the mcluster routine, modified to work with the coords field of
% roiTs structure; the latter include 3D coordinates.
%  
% [occords, idx] = MCLUSTER3(coord,B,cutoff)
%
% px, py are indices of correlated voxels, i.e. [px,py] = find(corrmap>threshold) pxnewm pynew
% are indices of correlated voxels with at least "cutoff" voxels within +/i border size B.
% Old Defaults (cutoff =  8, B = 5);
% New Defaults (cutoff = 12, B = 5);
%
% NKL, 10.11.01
% YM,  14.07.05 supports 3D
% YM,  17.07.05 improved 3D speed.
  
if nargin == 0,  help mcluster3; return;  end

if nargin < 3,	cutoff = 12; end;
if nargin < 2,	B = 5;		end;


% CONTROL FLAGS/SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DEBUG = 0;
if size(coords,1) > 10000,
  SHOW_WAITBAR = 1;
else
  SHOW_WAITBAR = 0;
end


if size(coords,2) > 2,
  % This code takes 6.5min for 267006 voxels, ~40000voxels/min.
  vol = zeros(max(coords(:,1))+2*B,max(coords(:,2))+2*B,max(coords(:,3))+2*B,'int8');
  szvol = size(vol);
  idx = sub2ind(szvol,coords(:,1)+B,coords(:,2)+B,coords(:,3)+B);
  vol(idx) = 1;
  N = zeros(1,size(coords,1));
  %isel = 0:2*B;	% -B <= xyz <= +B
  isel = 1:(2*B-1);	% -B <  xyz <  +B
  if SHOW_WAITBAR > 0,
    h = waitbar(0,'Please wait...(40000voxels/min)');
    set(h,'Name',sprintf('%s %s : %dvoxels',datestr(now,'HH:MM:SS'),mfilename,size(coords,1)));
    for K = 1:size(coords,1),
      waitbar(K/size(coords,1));
      tmpvol = vol(isel+coords(K,1), isel+coords(K,2), isel+coords(K,3));
      N(K) = sum(tmpvol(:)) - 1;
    end
    close(h);
  else
    for K = 1:size(coords,1),
      tmpvol = vol(isel+coords(K,1), isel+coords(K,2), isel+coords(K,3));
      N(K) = sum(tmpvol(:)) - 1;
    end
  end

  % This code takes 4 hours for 267006 voxels.
%   coordsMin = coords - B;
%   coordsMax = coords + B;
%   N = zeros(1,size(coords,1));
%   fprintf('%s: n=%d',mfilename,size(coords,1));
%   h = waitbar(0,sprintf('%s: voxels=%d',mfilename,size(coords,1)));
%   for K = 1:size(coords,1),
%     waitbar(K/size(coords,1));
%     tx = (coordsMin(K,1) < coords(:,1)) & (coords(:,1) < coordsMax(K,1));
%     ty = (coordsMin(K,2) < coords(:,2)) & (coords(:,2) < coordsMax(K,2));
%     tz = (coordsMin(K,3) < coords(:,3)) & (coords(:,3) < coordsMax(K,3));
%     %t1=((px>(px(K)-B))&(px<(px(K)+B)));
%     %t2=((py>(py(K)-B))&(py<(py(K)+B)));
%     %t3=((pz>(pz(K)-B))&(pz<(pz(K)+B)));
%     %N(K) = sum(t1&t2&t3)-1;  % -1 as its own
%     N(K) = sum(tx&ty&tz)-1;
%   end
%   close(h);
else
  px = coords(:,1);
  py = coords(:,2);
  for K = 1:length(px),
    t1=((px>(px(K)-B))&(px<(px(K)+B)));
    t2=((py>(py(K)-B))&(py<(py(K)+B)));
    N(K) = sum(t1&t2)-1;
  end
  N
end

idx = find(N >= cutoff);
ocoords = coords(idx,:);


if DEBUG > 0 | nargout == 0,
  figure('name',mfilename);
  plot(N); grid on;
  line(get(gca,'xlim'),[cutoff, cutoff],'color','r');
  xlabel('Voxel Index');
  ylabel('Number of voxels within B');
  set(gca,'xlim',[0 length(N)]);
end

return;
