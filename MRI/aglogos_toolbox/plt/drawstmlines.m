function drawstmlines(sig,varargin)
%DRAWSTMLINES - draw dashed line at the stimulus on/off times
%	DRAWSTMLINES(sig,obsp,lwidth,lstyle,col)
%	draws onset/offset of stimulus with color "col"
%	NKL 11.05.02
if ~isfield(sig,'stm') | ~isfield(sig.stm,'time') | isempty(sig.stm.time),
  return;
end;

HIGHT       = 0;
FACECOLOR   = [0.9 1 0.9];
EDGECOLOR   = [.5 .4 .4];
LINESTYLE   = ':';
LINEWIDTH   = 1;

for N=1:2:length(varargin),
  switch lower(varargin{N}),
   case {'linestyle'}
    LINESTYLE = varargin{N+1};
   case {'linewidth'}
    LINEWIDTH = varargin{N+1};
   case {'facecolor'}
    FACECOLOR = varargin{N+1};
   case {'edgecolor'}
    EDGECOLOR = varargin{N+1};
   case {'hight'}
    HIGHT = varargin{N+1};
   otherwise
    fprintf('unknown command option\n');
    return;
  end
end

stm = sig.stm.time{1};
if isfield(sig.stm,'stmtypes'),
  stimuli = sig.stm.stmtypes(sig.stm.v{1}+1);
  if any(strcmpi(stimuli,'blank')),
    idxon = find(~strcmpi(stimuli,'blank'));
    idxoff = idxon + 1;
    stm(end+1) = max([stm(end) sum(sig.stm.dt{1})]);
    %stm = unique(stm([idxon(:)' idxoff(:)']));
    tmpstm(1,:) = stm(idxon);
    tmpstm(2,:) = stm(idxoff);
    stm = tmpstm(:)';
  else
    % no blank in the stimulus sequence, maybe awake stuff
    stm = zeros(1,2*length(sig.stm.time{1}));
    stm(1:2:end) = sig.stm.time{1};
    stm(2:2:end) = sig.stm.time{1} + sig.stm.dt{1};
  end
end

tmp = get(gca,'ylim'); tmpy = tmp(1);
if HIGHT,
  tmph = HIGHT;
else
  tmph = tmp(2)-tmp(1);
end;
hd = [];

if ~strcmp(FACECOLOR,'none'),
  for N=1:2:length(stm),
    tmpx = stm(N);
    tmpw = stm(N+1)-stm(N);
    hd(end+1) = rectangle('Position',[tmpx tmpy tmpw tmph],...
                          'edgecolor','k','facecolor',FACECOLOR,...
                          'linestyle','none','Tag','ScaleBar');
  end
  setback(hd);
end;

YLIM = get(gca,'ylim');
for N=1:length(stm),
  line([stm(N) stm(N)],[YLIM(1) YLIM(1)+tmph],'color',EDGECOLOR,...
       'linestyle',LINESTYLE,'linewidth',LINEWIDTH);
end

% 21.07.04 YM: draw a line at the end of the stimulus.
%              this will be useful for signals sorted by the stimulus.
if length(stm) == 1,
  dt = sig.stm.dt{1};
  line([stm(1)+dt(1) stm(1)+dt(1)],YLIM(1)+tmph,'color',EDGECOLOR,...
       'linestyle',LINESTYLE,'linewidth',LINEWIDTH);
end
set(gca,'layer','top');
