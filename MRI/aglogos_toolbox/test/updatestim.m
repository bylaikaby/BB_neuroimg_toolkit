function updatestim(haxs)

if nargin < 1,  haxs = [];  end

if isempty(haxs),  haxs = gca;  end

if length(haxs) > 1,
  for N = 1:length(haxs),  updatestim(haxs(N));  end
  return
end


set(allchild(haxs),'HandleVisibility','on');

ylm = get(haxs,'ylim');


h = findobj(haxs,'tag','stim-rect');
tmph = ylm(2)-ylm(1);
for N = 1:length(h),
  tmppos = get(h(N),'pos');
  tmppos(2) = ylm(1);  tmppos(4) = tmph;
  set(h(N),'pos',tmppos);
end
setback(h);
set(h,'HandleVisibility','off');


h = findobj(haxs,'tag','stim-line');
set(h,'ydata',ylm);
set(h,'HandleVisibility','off');
