function dsppsd(Sig)
%DSPPSD - plot a neural raw signal
%	dsppsd(Sig) - plot a neural raw signal
%	NKL, 13.12.01

global DispPars;
if nargin < 1,
	error('usage: dsppsd(Sig);');
end;

Sig.dat = hnanmean(Sig.dat,3);	% AVERAGE ALL OBSERVATION PERIODS

f = [0:size(Sig.dat,1)-1]*Sig.dx(2);
f=f(:);

fs = get(gcf,'DefaultAxesfontsize');
fw = get(gcf,'DefaultAxesfontweight');
set(gcf,'DefaultAxesfontsize', 8);
set(gcf,'DefaultAxesfontweight','normal');
set(gcf,'color', DispPars.figcolor);

COL=4; ROW=4;
if DispPars.sumactivity,
  Sig.dat = hnanmean(Sig.dat,2);
  COL = 1; ROW = 1;
end;
  
for ChanNo = 1:size(Sig.dat,2),
  if COL>1,
	subplot(ROW,COL,ChanNo);
  end;
  
  plot(f,Sig.dat(:,ChanNo),Sig.dsp.args{:});
  set(gca,'xscale','log');
  set(gca,'yscale','log');

  set(gca,'xcolor', DispPars.xcolor);
  set(gca,'ycolor', DispPars.ycolor);
  set(gca,'color', DispPars.color);
  line([50 50],get(gca,'ylim'),'linewidth',1,'linestyle',':','color','r');
  grid on;
  
if DispPars.sumactivity,
  title(sprintf('Channels=[%d:%d]',Sig.chan(1),Sig.chan(end)),'color','r');
else
  title(sprintf('Ch=%d',ChanNo),'color','r');
end;
end;

xlabel(Sig.dsp.label{1});
ylabel(Sig.dsp.label{2});
set(gcf,'DefaultAxesfontsize',	fs);
set(gcf,'DefaultAxesfontweight',fw);



