function cormap = matsmap(roiTs, rthr, STATNAME, COL)
%MATSMAP - Creates activation maps on anatomy using any of the roiTs statistics 
% MATSMAP(roiTs) assumes some kind of selection of time series,
% i.e. usually with mroitssel(roiTs); otherwise it will assign each
% value of the .r field on the anatomical scan.
%
% NKL, 29.04.04
% YM,  01.08.04 supports also '.p' field, use like matsmap(roiTs,thr,'p').

if ~nargin,
  help matsmap;
  return;
end;

if nargin < 2,  rthr = 0;        end;
if nargin < 3,  STATNAME = 'r';  end
if nargin < 4, COL='rgbcywm'; end;


if ~iscell(roiTs),
  roiTs = {roiTs};
end;

NoModel = length(roiTs{1}.(STATNAME));
EPIDIMS = [roiTs{1}.grp.imgcrop(3:4) size(roiTs{1}.ana,3)];

for N=1:length(roiTs{1}.(STATNAME)),
  if NoModel>1,
    cormap{N} = zeros(EPIDIMS);
  else
    cormap{N} = NaN*ones(EPIDIMS);
  end;
end;

for M = 1:NoModel,
  for A = 1:length(roiTs),
    if iscell(roiTs{A}.coords),
      xyz = roiTs{A}.coords{M};
    else
      xyz = roiTs{A}.coords;
    end;
    for N=1:length(roiTs{A}.(STATNAME){M}),
      cormap{M}(xyz(N,1),xyz(N,2),xyz(N,3)) = roiTs{A}.(STATNAME){M}(N);
    end;
  end;
end;

for M = 1:NoModel,
  if rthr,
    nanidx = find(cormap{M}(:) < rthr);

    if NoModel>1,
      if ~isempty(nanidx),  cormap{M}(nanidx) = 0;  end
    else
      if ~isempty(nanidx),  cormap{M}(nanidx) = NaN;  end
    end;
  end

  if size(cormap{M},1) ~= size(roiTs{1}.ana,1) | ...
        size(cormap{M},2) ~= size(roiTs{1}.ana,2),
    DIMS = squeeze(size(roiTs{1}.ana(:,:,1)));
    for N=size(cormap{M},3):-1:1,
      tmp(:,:,N) = imresize(cormap{M}(:,:,N),DIMS);
    end;
    cormap{M} = tmp; clear tmp;
  end;
end;

if ~nargout,
  if NoModel <= 1,
    ascan = mgetcollage(roiTs{1}.ana);
    fscan = mgetcollage(cormap{M});
    dspfused(ascan,fscan);
  else
    ascan = mgetcollage(roiTs{1}.ana);
    for M=1:NoModel,
      fscan{M} = mgetcollage(cormap{M});
    end;
    plotfused(ascan,fscan,rthr,COL);
  end;
  daspect([1 1 1]);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plotfused(ai,fi,thr,COL)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SWCLIP		= [0.1 0.9];
SWGAMMA     = 0.7;

if nargin < 3,
  thr = 0.15;
end;

if ~iscell(fi),
  fprintf('PLOTFUSED: Expects a cell array as second argument\n');
  return;
end;

if size(ai,1)~=size(fi{1},1) | size(ai,2)~=size(fi{1},2),
  for N=1:length(fi),
    fi{N} = imresize(fi{N},size(ai),'nearest');
  end;
end

ai = imadjust(ai./max(ai(:)),SWCLIP, [0 1], SWGAMMA);	% clip/gamma-correct
imagesc(ai');
colormap(gray);
axis off;
hold on;

for M=1:length(fi),
  [x,y] = find(fi{M}>thr);
  for N=1:length(x),
    % JITTER TO SEE OVERLAPPING VOXELS
    plot(x(N)+(M-1)/4,y(N)+(M-1)/4,'marker','s','markersize',5,...
         'markerfacecolor',COL(M),'markeredgecolor',COL(M));
  end;
end;






    
