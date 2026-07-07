function drawline(NoLines)
%DRAWLINE - Draw line at the location of ginput
% DRAWLINE(NoLines)

c = ginput(NoLines);

for N=1:NoLines,
  line([c(1,N) c(1,N)],get(gca,'ylim'),'linewidth',2,'color','r');
end;

hold on;
% text(0,c(1,N)*1.1,sprintf('%4.3f/%4.3f',c(1,1),c(1,2)));

