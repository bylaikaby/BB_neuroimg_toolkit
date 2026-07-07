function dspavgroits(roiTs,varargin)
%DSPAVGROITS - Display roiTs
% dspavgroits(roiTs,varargin)
%
% Possible arguments (DEFAULT):
%   BSTRP (1000)
%   AVERAGE (1)
%   ERROR (ci,eb,none)
% 
% See also DSPMVOXTC DSPMVOXMAP DSPMVOX ESCAT
%
% NKL, 13.06.07

if nargin < 1, help dspavgroits;  return; end;

% ---------------------------------------------------
%%%%% DEFAULTS
% ---------------------------------------------------
BSTRP       = 1000;     % Itterations for Bootstraping
AVGRESPONSE = 1;        % Average all model types
COL_LINE    = [];
COL_FACE    = [];
ERROR       = 'ci';     % confidence intervlas
CIVAL       = [1 99];   % low and high confidence interval
DX          = 0;
YLIM        = [];

% ---------------------------------------------------
%%%%% PARSE INPUT
% ---------------------------------------------------
for N=1:2:length(varargin),
  switch lower(varargin{N}),
   case {'dx'}
    DX = varargin{N+1};
   case {'bstrp'}
    BSTRP = varargin{N+1};
   case {'average'}
    AVGRESPONSE = varargin{N+1};
   case {'error'}
    ERROR = varargin{N+1};
   case {'cival'}
    CIVAL = varargin{N+1};
   case {'linecolor'}
    COL_LINE = varargin{N+1};
   case {'facecolor'}
    COL_FACE = varargin{N+1};
   case {'ylim'}
    YLIM = varargin{N+1};
   case {'legend'}
    LEGTXT = varargin{N+1};
  end
end

if isstruct(roiTs),
  roiTs = {roiTs};
end;

if DX,
  for N=1:length(roiTs),
    if iscell(roiTs{N}),
      for M=1:length(roiTs{N}),
        roiTs{N}{M} = mroitsinterp(roiTs{N}{M},DX);
      end;
    else
      roiTs{N} = mroitsinterp(roiTs{N},DX);
    end;
  end;
end;

if AVGRESPONSE,
  for N=1:length(roiTs),
    if iscell(roiTs{N}),
      ts = [];
      for M=1:length(roiTs{N}),
        ts = cat(2,ts,roiTs{N}{M}.dat);
      end;
      roiTs{N} = roiTs{N}{1};
      roiTs{N}.dat = ts;
    end;
  end;
end;

% If AVGRESPONSE==0, then we have PBR and NBR; hence the loop!
for N=1:length(roiTs),
  subPlotTC(roiTs{N},ERROR,BSTRP,COL_LINE,COL_FACE,CIVAL,DX);
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subPlotTC(roiTs,ERROR,BSTRP,COL_LINE,COL_FACE,CIVAL,DX)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for N=1:length(roiTs),
  t = [1:size(roiTs.dat,1)]'*roiTs.dx;
  y = hnanmean(roiTs.dat,2);
  yerr = hnanstd(roiTs.dat,2)/sqrt(size(roiTs.dat,2));

  m = round(length(y)/2);
  [maxy, maxt]  = max(abs(y(m+1:end)));

  if isempty(COL_LINE),
    if y(m+1+maxt) >= 0,
      COL_LINE = 'r';
    else
      COL_LINE = 'b';
    end;
  end;

  if isempty(COL_FACE),
    if y(m+1+maxt) >= 0,
      COL_FACE = [.9 .6 .6];
    else
      COL_FACE = [.6 .6 .9];
    end;
  end;
  
  if strcmp(ERROR,'ci'),
    [maxy, maxt]  = max(abs(y));
    Boot = bootstrp(BSTRP,@hnanmean,roiTs.dat');
    Cinter = prctile(Boot,CIVAL); % the 1 and 99% intervals
    ciplot(Cinter(1,:),Cinter(2,:),t,COL_FACE);
    hold on
    hd = plot(t, y,'linewidth',1,'color',COL_LINE);
  elseif strcmp(ERROR,'eb'),
    hd = errorbar(t, y, yerr);
    eb = findall(hd);
    set(eb(1),'LineWidth',1,'Color',COL_FACE);
    set(eb(2),'LineWidth',2,'Color',COL_LINE);
  else
    hd = plot(t, y,'linewidth',1,'color',COL_LINE);
  end;
  
  title(roiTs.name);
  set(gca,'xlim',[t(1) t(end)]);
  if ~isempty(YLIM),
    set(gca,'ylim',YLIM);
  end;
  subDrawStm(roiTs);
  hold off;
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subDrawStm(sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
stm = sig.stm.time{1};
if isfield(sig.stm,'stmtypes'),
  stimuli = sig.stm.stmtypes(sig.stm.v{1}+1);
  if any(strcmpi(stimuli,'blank')),
    idxon = find(~strcmpi(stimuli,'blank'));
    idxoff = idxon + 1;
    stm(end+1) = max([stm(end) sum(sig.stm.dt{1})]);
    stm = unique(stm([idxon(:)' idxoff(:)']));
  else
    stm = zeros(1,2*length(sig.stm.time{1}));
    stm(1:2:end) = sig.stm.time{1};
    stm(2:2:end) = sig.stm.time{1} + sig.stm.dt{1};
  end
end
tmp = get(gca,'ylim'); tmpy = tmp(1);
tmph = tmp(2)-tmp(1);
hd = [];

for N=1:2:length(stm),
  tmpx = stm(N);
  tmpw = stm(N+1)-stm(N);
  hd(end+1) = rectangle('Position',[tmpx tmpy tmpw tmph],...
                        'facecolor',[.85 .85 .85],'linestyle','none','Tag','ScaleBar');
end
setback(hd);
set(gca,'layer','top');
return;



