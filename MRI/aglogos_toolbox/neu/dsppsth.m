function dsppsth(Sig)
%DSPPSTH - Display histogram data from single units
%	NKL, 27.10.02

if nargin < 1,
	error('usage: dsppsth(Sig);');
end;

t = [0:size(Sig.dat,1)-1]*Sig.dx(1);
t=t(:);

fs = get(gcf,'DefaultAxesfontsize');
fw = get(gcf,'DefaultAxesfontweight');
set(gcf,'DefaultAxesfontsize', 8);
set(gcf,'DefaultAxesfontweight','normal');

NoChan = size(Sig.dat,2);
NoObsp = size(Sig.dat,3);

if exist('DispPars','var'),
  DispPars.sumactivity=0;
  if DispPars.sumactivity,
    for ObspNo = 1:NoObsp,
      times{ObspNo} = [];
      for ChanNo = 1:NoChan,
        times{ObspNo} = cat(1,times{ObspNo},Sig.times{ChanNo,ObspNo});
      end;
    end;
  end;
end;

for ObspNo = 1:NoObsp,
  len(ObspNo) = length(Sig.times{1,ObspNo});
end;

% It's too slow to display all spikes
NoDots = 100;
SKIP = round(max(len)/NoDots);		% many dots can't be seen....!!
SKIP=10;

if nargin > 1,
  Sig.dat = mean(Sig.dat(:,1,:),3);
end;

MAX=max(Sig.dat(:));
DY = [MAX*1.25:0.75*MAX/NoObsp:2*MAX];

for ChanNo = 1:NoChan,
  p = bar(t,Sig.dat,1);
  drawstmlines(Sig,'linewidth',1,'linestyle','--','color','r');
  for ObspNo = 1:NoObsp,
	set(gca,'xlim',[t(1) t(end)]);
	set(gca,'xlim',[t(1) 60]);
	set(gca,'ylim',[0 2*MAX]);
	xlabel('Time in sec');
	ylabel('Spike Count');
	hold on
	plot(Sig.dt*Sig.times{ChanNo,ObspNo}(1:SKIP:end),...
		 DY(ObspNo),'k.','MarkerSize',2);
  end;
end;



