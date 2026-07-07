function dspimginfo(s)
%DSPIMGINFO - Display Image info
%	DSPIMGINFO(s) displays image info and
%	stores it into a meta file that can be imported in PPT etc.
%	NKL, 30.11.02

y  = 92;
dy = 6.5;
props={'color';'y';'fontsize';9;'fontweight';'bold';...
       'fontname';'New Times Roman'};

set(gca,'color','k');
set(gca,'xlim',[0 100]);
set(gca,'ylim',[0 100]);
set(gca,'ytick',[],'xtick',[]);
set(gca,'box','on','xcolor','w','ycolor','w')

[lab,txt] = mgetimginfo(s);
for N=1:length(txt),
	text(48,y,lab{N},props{:},'horizontalAlignment','right','color','r');
	text(52,y,txt{N},props{:},'horizontalAlignment','left');
	y = y - dy;
end;

