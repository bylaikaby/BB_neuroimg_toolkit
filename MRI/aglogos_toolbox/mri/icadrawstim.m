function icadrawstim(haxs,Sig,FILL)
%ICADRAWSTIM - Draw stimulus intevals as rectangles of different colors
%
% NKL 11.06.09

stimv = Sig.stm.v{1};
if FILL,
  for N = 1:length(stimv),
    FACECOLORS{N} = [0.98 0.92 0.92];
  end;
  if ~isempty(findstr('comb',Sig.grpname)),
    FACECOLORS{3} = [0.98 0.68 0.68];
  end;
else
  for N = 1:length(stimv),
    FACECOLORS{N} = 'none';
  end;
end;

ylm   = get(haxs,'ylim');  tmph = ylm(2)-ylm(1);
drawL = [];  drawR = [];
if isfield(Sig,'stm') & ~isempty(Sig.stm),
  stimv = Sig.stm.v{1};
  stimt = Sig.stm.time{1};  stimt(end+1) = sum(Sig.stm.dt{1});
  stimdt = Sig.stm.dt{1};
  for N = 1:length(stimv),
    if any(strcmpi(Sig.stm.stmpars.StimTypes{stimv(N)+1},{'blank','none','nostim'})),
      continue;
    end
    if stimt(N) == stimt(N+1),
      tmpw = stimdt(N);
    else
      tmpw = stimt(N+1) - stimt(N);
    end
    if ~any(drawL == stimt(N)),
      if FILL,
        line([stimt(N), stimt(N)],ylm,'color','k','tag','stim-line');
      else
        line([stimt(N), stimt(N)],ylm,'color','k','tag','stim-line','linestyle','--');
      end;
      drawL(end+1) = stimt(N);
    end
    if isempty(drawR) | ~any(drawR(:,1) == stimt(N) & drawR(:,2) == tmpw),
      rectangle('Position',[stimt(N) ylm(1) tmpw tmph],...
                'facecolor',FACECOLORS{N},'linestyle','none',...
                'tag','stim-rect');
      drawR(end+1,1) = stimt(N);
      drawR(end  ,2) = tmpw;
    end
    if ~any(drawL == stimt(N)+tmpw),
      if FILL,
        line([stimt(N),stimt(N)]+tmpw,ylm,'color','k','tag','stim-line');
      else
        line([stimt(N),stimt(N)]+tmpw,ylm,'color','k','tag','stim-line','linestyle','--');
      end;
      drawL(end+1) = stimt(N)+tmpw;
    end
  end
end

% adjust stimulus indicator size
set(allchild(haxs),'HandleVisibility','on');
ylm = get(haxs,'ylim');  tmph = ylm(2)-ylm(1);
h = findobj(haxs,'tag','stim-line');
set(h,'ydata',ylm);
h = findobj(haxs,'tag','stim-rect');
for N = 1:length(h),
  tmppos = get(h(N),'pos');
  tmppos(2) = ylm(1);  tmppos(4) = tmph;
  set(h(N),'pos',tmppos);
end

setfront(findobj(haxs,'tag','stim-line'));
setback(findobj(haxs,'tag','stim-rect'));
% set indicators' handles invisible to use legend() funciton.
set(findobj(haxs,'tag','stim-line'),'handlevisibility','off');
set(findobj(haxs,'tag','stim-rect'),'handlevisibility','off');
return;
