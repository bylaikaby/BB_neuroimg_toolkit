function varargout = densplot(DAT,varargin)
%DENSPLOT - Density plot.
%  DENSPLOT(DAT,...) does density plot.
%    DAT must be (samples,2), the 1st/2nd column as X/Y.
%
%  Supported options are :
%    'axes'        : a handle for the plotting axes
%    'xedges'      : xedges for 2D histogram (hist3)
%    'yedges'      : yedges for 2D histogram (hist3)
%    'smooth'      : 0|1, smooth the 2D histogram
%    'normalize'   : 0|1, normalize the 2D histogram
%    '3d'          : 0|1, 3D surface plotting
%    'colorbar'    :
%    'colormap'    : colormap
%    'xlabel'      :
%    'ylabel'      :
%    'zlabel'      :
%    'contour'     : 0|1, whether to draw contours, if >1, then # of levels.
%    'scatter'     : 0|1, whether to plot scatter
%    'marker'      : marker type for scater plot
%    'markersize'  : marker size
%    'markercolor' : marker color
%
%  EXAMPLE :
%    DAT = rand(1000,2);
%    densplot(DAT);
%
%  VERSION :
%    0.90 16.02.12 YM  pre-release
%
%  See also hist3 pcolor contour surf plot


if nargin < 1,  eval(['help ' mfilename]); return;  end

if isempty(DAT),  return;  end

% PRE-PROCESSING
XEDGES = [];
YEDGES = [];
DO_SMOOTH = 0;
DO_NORMALIZE = 1;

H_AXES  = [];
CMAP    = [];
PLOT_3D = 0;

% SCATTER PLOT
PLOT_SCATTER  = 1;
MARKER_TYPE   = 'o';
MARKER_SIZE   = 1.5;
MARKER_COLOR  = [0 0 0];

% SURFACE PLOT
PLOT_SURFACE  = 1;

% CONTOUR PLOT
PLOT_CONTOUR  = 1;

% LABELS, ETC
PLOT_XLABEL   = 'X';
PLOT_YLABEL   = 'Y';
if any(DO_NORMALIZE),
  PLOT_ZLABEL = '# of counts';
else
  PLOT_ZLABEL = 'Prob.';
end
PLOT_COLORBAR = 1;


for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'xedge' 'xedges'}
    XEDGES = varargin{N+1};
   case {'yedge' 'yedges'}
    YEDGES = varargin{N+1};
   case {'smooth'}
    DO_SMOOTH = varargin{N+1};
   case {'norm' 'normalize'}
    DO_NORMALIZE = varargin{N+1};
   
   case {'axes'}
    H_AXES = varargin{N+1};
   case {'3d'}
    PLOT_3D = varargin{N+1};
   case {'cmap'}
    CMAP = varargin{N+1};
   case {'colorbar'}
    PLOT_COLORBAR = varargin{N+1};
   case {'xlabel'}
    PLOT_XLABEL = varargin{N+1};
   case {'ylabel'}
    PLOT_YLABEL = varargin{N+1};
   case {'zlabel'}
    PLOT_ZLABEL = varargin{N+1};
   
   case {'scatter'}
    PLOT_SCATTER = varargin{N+1};
   case {'marker'}
    MARKER_TYPE = varargin{N+1};
   case {'markersize'}
    MARKER_SIZE = varargin{N+1};
   case {'markercolor' 'markerfacecolor'}
    MARKER_COLOR = varargin{N+1};

   case {'contour'}
    PLOT_CONTOUR = varargin{N+1};

   case {'surface'}
    PLOT_SURFACE = varargin{N+1};
    
   otherwise
    fprintf(' %s : unknown option %s.\n',mfilename,varargin{N});
  end
end

if strcmpi(PLOT_ZLABEL,'# of counts'),
  PLOT_ZLABEL = 'Prob. Density';
end


if ~any(XEDGES),
  maxv = max(DAT(:,1)) * 1.1;
  minv = min(DAT(:,1)) * 1.1;
  step = (maxv - minv)/256;
  XEDGES = minv:step:maxv;
end
if ~any(YEDGES),
  maxv = max(DAT(:,2)) * 1.1;
  minv = min(DAT(:,2)) * 1.1;
  step = (maxv - minv)/128;
  YEDGES = minv:step:maxv;
end
clear maxv minv step;

if isempty(CMAP),  CMAP = jet(256);  end



[ncount c] = hist3(DAT,'edges',{XEDGES YEDGES});

ncount = ncount';  % annoying matlab.... (y,x) --> (x,y)
X = c{1};
Y = c{2};
clear c;


if any(DO_SMOOTH),
  if DO_SMOOTH > 1,
    k = fspecial('gaussian',round(DO_SMOOTH),DO_SMOOTH*0.2);
  else
    k = fspecial('gaussian',5,1);
  end
  ncount = filter2(k,ncount);
end
if any(DO_NORMALIZE) && ~isempty(DAT),
  ncount = ncount / sum(ncount(:));
end


if ishandle(H_AXES),
  axes(H_AXES);
end

cla;
colormap(CMAP);

%ncount(5,5) = max(ncount(:));  % testing..


FIX_MATLAB = 1;

if any(PLOT_3D),
  if any(PLOT_SCATTER),
    Z = zeros(size(DAT,1),1);
    hs = stem3(DAT(:,1),DAT(:,2),Z,'linestyle','none',...
               'marker',MARKER_TYPE,'markersize',MARKER_SIZE,...
               'color',MARKER_COLOR,'markerfacecolor',MARKER_COLOR);
    hold on;
  end
  hf = surf(XEDGES,YEDGES,ncount);
  shading interp; % why shading shift the image...
  alpha(hf,'color'); % why alpha shift the image...
  if FIX_MATLAB,
    tmpa = get(hf,'AlphaData');
    tmpa = circshift(tmpa,[-1 -1]);
    set(hf,'AlphaData',tmpa);
    clear tmpa;
  end
  if any(PLOT_CONTOUR),
    hold on;
    if PLOT_CONTOUR > 1,
      hc = contour(X,Y,ncount,PLOT_CONTOUR);
    else
      hc = contour(X,Y,ncount,20);
    end
  end
else
  if any(PLOT_SCATTER),
    hs = plot(DAT(:,1),DAT(:,2),'linestyle','none',...
              'marker',MARKER_TYPE,'markersize',MARKER_SIZE,...
              'color',MARKER_COLOR,'markerfacecolor',MARKER_COLOR);
    hold on;
  end
  if any(PLOT_SURFACE),
    hf = pcolor(XEDGES,YEDGES,ncount);
    shading interp; % why shading shift the image...
    alpha(hf,'color'); % why alpha shift the image...
    if FIX_MATLAB,
      tmpa = get(hf,'AlphaData');
      tmpa = circshift(tmpa,[-1 -1]);
      set(hf,'AlphaData',tmpa);
      clear tmpa;
    end
    set(hf,'linestyle','none');
    %hf = imagesc(X,Y,ncount);  set(gca,'ydir','normal');
    %set(hf,'AlphaData',ncount);
    hold on;
  end
  if any(PLOT_CONTOUR),
    if PLOT_CONTOUR > 1,
      hc = contour(X,Y,ncount,PLOT_CONTOUR);
    else
      hc = contour(X,Y,ncount,20);
    end
  end
end
text(0.01,0.005,sprintf('N=%d',size(DAT,1)),...
     'units','normalized','verticalalignment','bottom');


set(gca,'xlim',[X(1) X(end)],'ylim',[Y(1) Y(end)]);
set(gca,'layer','top');
grid on;


if any(PLOT_XLABEL),  xlabel(PLOT_XLABEL);  end
if any(PLOT_YLABEL),  ylabel(PLOT_YLABEL);  end
if any(PLOT_ZLABEL),  zlabel(PLOT_ZLABEL);  end


if any(PLOT_COLORBAR),
  h = colorbar;
  if any(PLOT_ZLABEL),
    set(get(h,'ylabel'),'String',PLOT_ZLABEL);
  end
else
  h = findobj(gcf,'tag','Colorbar');
  if ishandle(h),
    colorbar(h,'off');
  end
end


if nargout,
  varargout{1} = gca;
  if nargout > 1
    RES.x = X;
    RES.y = Y;
    RES.hist = ncount;
    varargout{2} = RES;
  end
  
end


return
