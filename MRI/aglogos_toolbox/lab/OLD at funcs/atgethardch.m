function grp = atgethardch(SESSION,GrpName)
%ATGETHARDCH - get recording grid information

if ~nargin,
  SESSION='d98at1';
  GrpName = 'spont1';
end;

Ses = goto(SESSION);
if isa(GrpName,'char'),
  grp = getgrpbyname(Ses,GrpName);
else
  grp = GrpName;
end;

Ses.rsi.CELLGRID	= reshape([1:16],4,4);
Ses.rsi.TETGRID		= reshape([1:12],4,3);
Ses.rsi.CELLS		= Ses.confunc.cells;
Ses.rsi.TETRODES	= Ses.confunc.tetrodes;

K=1;
for N=1:length(Ses.rsi.TETRODES),
  [tx,ty] = find(Ses.rsi.TETGRID==Ses.rsi.TETRODES(N));
  tx = (tx-1) * size(Ses.rsi.CELLGRID,1);
  ty = (ty-1) * size(Ses.rsi.CELLGRID,2);

  for M=1:Ses.rsi.CELLS(N),
	[x,y] = find(Ses.rsi.CELLGRID==M);
	x = x + tx;
	y = y + ty;
	grp.hardch(K) = (y-1)*size(Ses.confunc.eleconfig,1)+x;
	K=K+1;
  end;
end;

if ~nargout,
  d = Ses.confunc.idist;
  mfigure([100 100 700 700]);
  for C=1:size(Ses.confunc.eleconfig,1),
	plot(d*repmat([C],[size(Ses.confunc.eleconfig,2) 1]),...
		 d*[1:size(Ses.confunc.eleconfig,2)],'sk',...
		 'linestyle','none','markersize',2,'markerfacecolor','k');
	hold on;
  end;
  tmp = (1+size(Ses.confunc.eleconfig)) * Ses.confunc.idist;
  limx = [0 tmp(1)]; limy = [0 tmp(2)];
  set(gca,'ydir','reverse');
  set(gca,'xlim',limx,'ylim',limy);
  for N=1:length(grp.hardch),
	[x,y] = find(Ses.confunc.eleconfig==grp.hardch(N));
	plot(d*x,d*y,'sr','linestyle','none','markersize',6);
  end;
  for N=0:size(Ses.rsi.TETGRID,2)+1,
	x = N * size(Ses.rsi.CELLGRID,1) * d + d/2;
	tmp = get(gca,'ylim');
	tmp(1)=tmp(1)+d/2;
	tmp(2)=tmp(2)-d/2;
	line([x x],tmp,'color','g');
  end;
  for N=0:size(Ses.rsi.TETGRID,1)+1,
	y = N * size(Ses.rsi.CELLGRID,1) * d + d/2;
	tmp = get(gca,'xlim');
	tmp(1)=tmp(1)+d/2;
	tmp(2)=tmp(2)-d/2;
	line(tmp,[y y],'color','g');
  end;
  TIT=sprintf('Session: %s, Group: %s, SigType: %s',...
			  Ses.name, grp.name, Ses.confunc.curtype);
  suptitle(TIT,'r',11);
end;

