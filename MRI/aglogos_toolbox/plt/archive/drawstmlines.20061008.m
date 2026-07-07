function drawstmlines(sig,varargin)
%DRAWSTMLINES - draw dashed line at the stimulus on/off times
%	DRAWSTMLINES(sig,obsp,lwidth,lstyle,col)
%	draws onset/offset of stimulus with color "col"
%	NKL 11.05.02
if ~isfield(sig,'stm') | ~isfield(sig.stm,'time') | isempty(sig.stm.time),
  return;
end;

if isempty(varargin),
	varargin{1}='color';
	varargin{2}=[.7 .7 .7];
	varargin{3}='linestyle';
	varargin{4}=':';
end;

stm = sig.stm.time{1};
if isfield(sig.stm,'stmtypes'),
  stimuli = sig.stm.stmtypes(sig.stm.v{1}+1);
  idxon = find(~strcmpi(stimuli,'blank'));
  idxoff = idxon + 1;
  stm(end+1) = max([stm(end) sum(sig.stm.dt{1})]);
  stm = unique(stm([idxon(:)' idxoff(:)']));
end

for N=1:2:length(stm),
  tmpx = stm(N);
  tmp = get(gca,'ylim'); tmpy = tmp(1);
  tmpw = stm(N+1)-stm(N);
  tmph = tmp(2)-tmp(1);
  hd=rectangle('Position',[tmpx tmpy tmpw tmph],...
            'edgecolor','k','facecolor',[1 .9 .9],'linestyle','none','Tag','ScaleBar');
  setback(hd);
end

for N=1:length(stm),
  line([stm(N) stm(N)],get(gca,'ylim'),varargin{:});
end

% 21.07.04 YM: draw a line at the end of the stimulus.
%              this will be useful for signals sorted by the stimulus.
if length(stm) == 1,
  dt = sig.stm.dt{1};
  line([stm(1)+dt(1) stm(1)+dt(1)],get(gca,'ylim'),varargin{:});
end

