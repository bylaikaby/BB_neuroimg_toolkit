function varargout = dspmvox(ROITS,varargin)
%DSPMVOX - displays ROITS structure by mvoxselect
%  DSPMVOX(ROITS,...) displays ROITS structure of that voxsels are 
%  selected by mvoxselect based on the certain statistics/alpha.
%  [hMap hTimeCourse] = DSPMVOX(ROITS,...) does the same things,
%  returning axes handles of the images and time courses.
%
%  Supported options are :
%    DatName  : data name to plot, 'statv','resp'
%    Colormap : a color map for activated voxsels
%    Clip     : clipping range as [min max]
%    DrawROI  : a flag to draw ROIs, 0 or 1
%    legend   : text string(s) for legend
%
%  EXAMPLE :
%    >> sig = mvoxselect('e04ds1','visesmix','all','glm[2]',[],0.01);
%    >> dspmvox(sig,'clip',[0 20],'colormap',hot(256))
%  EXAMPLE 2:
%    >> sig1 = mvoxselect('e04ds1','visesmix','v1','glm[1]',[],0.01);
%    >> sig2 = mvoxselect('e04ds1','visesmix','v2','glm[1]',[],0.01);
%    >> dspmvox({sig1 sig2},'color',{'r','g'},'legend',{'v1','v2'})
%    >> dspmvox(roiTs,'legend',{'pos','neg'},'Clip',[0 20],'gamma',1.8);
%
%  VERSION :
%    0.90 12.03.07 YM  pre-release
%    0.91 15.03.07 YM  supports a cell array of ROITS
%
%  See also mvoxselect mvoxselectmask dspmvoxmap dspmvoxtc

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end

if isstruct(ROITS),  ROITS = { ROITS };  end

if iscell(ROITS) & iscell(ROITS{1}),
  for N = 1:length(ROITS),
    [hMap(N) hTC(N)] = dspmvox(ROITS{N},varargin{:});
  end
  if nargout,
    varargout{1} = hMap;
    if nargout > 1,
      varargout{2} = hTC;
    end
  end
  return;
end

if nargin < 2,
  DefArgs = {'legend',{'PES','NES'},'Clip',[0 20],'gamma',2};
else
  DefArgs = varargin;
end;


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(ROITS{1}.session);
grp = getgrp(Ses,ROITS{1}.grpname);
ANAP = getanap(Ses,grp);


% PLOT DATA
tmptitle = sprintf('%s(%s) ROI:%s model:%s P<%g',Ses.name,grp.name,...
                   ROITS{1}.name,ROITS{1}.stat.model,ROITS{1}.stat.alpha);
figure('Name',sprintf('%s: %s',mfilename,tmptitle),'position',[100 200 1000 700]);
set(gcf,'DefaultAxesfontsize',	10);
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName', 'Comic Sans MS');

% check the position of the figure, due to Matlab's bug,
% sometimes the figure appears outside the monitor....
pos = get(gcf,'pos');
if abs(pos(1)) > 5000 | abs(pos(2)) > 5000,
  set(gcf,'pos',[100 100 pos(3) pos(4)]);
end

% PLOT MAPS
%% hMap = axes('pos',[0.1300    0.30    0.7750    0.620]);
hMap = axes('pos',[ 0.05  0.1  0.4 0.75]);
dspmvoxmap(ROITS,'axes',hMap,DefArgs{:});
% PLOT TIME COURSE
%% hTC = axes('pos',[0.1300    0.100    0.7750    0.17]);
hTC = axes('pos',[ 0.6  0.1  0.36 0.75]);
dspmvoxtc(ROITS,'axes',hTC,DefArgs{:});


if nargout,
  varargout{1} = hMap;
  if nargout > 1,
    varargout{2} = hTC;
  end
end

return
