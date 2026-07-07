function ax = get2axis(CurAxis)
%GET2AXIS - Get second axis (right) on existing axes
  
ax = axes('Units',get(CurAxis,'Units'), ...
    'Position',get(CurAxis,'Position'),'Parent',gcf);
set(ax,'YAxisLocation','right','Color','none','XGrid','off','YGrid','off','Box','off');

  