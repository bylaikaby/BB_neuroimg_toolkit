function dspepoch(Sig)
%DSPEPOCH - Displays an epoch-sorted signal
% DSPEPOCH can be used to plot the output of the
% getepoch(sorttrials(Sig)) function.
% LfpM.dat:						[60x10x30 double]
% sorttrials(LfpM):				12    10    30     4     2
% getepoch(sorttrials(LfpM)):	12    10     2   120

NoChan = size(Sig.dat,2);
NoEpoch= size(Sig.dat,3);

Sig.dat = mean(Sig.dat,4);
Sig.dat = permute(Sig.dat,[1 3 2]);

s = size(Sig.dat);
Sig.dat = reshape(Sig.dat,[s(1)*s(2) s(3)]);
t = gettimebase(Sig);

fs = get(gcf,'DefaultAxesfontsize');
fw = get(gcf,'DefaultAxesfontweight');
set(gcf,'DefaultAxesfontsize',	8);
set(gcf,'DefaultAxesfontweight','normal');

if NoChan == 2,
  NoRow=1;  NoCol=2;
elseif NoChan > 2 & NoChan <= 8,
  NoRow=2;  NoCol=4;
else
  NoRow=4;  NoCol=4;
end;

for ChanNo = 1:NoChan,
  if ~any(Sig.chan == ChanNo),
	subplot(NoRow,NoCol,ChanNo);
	set(gca,'color',[.3 .3 .3]);
	text(0.25,0.5,'No Response','color','y');
	set(gca,'box','on');
  end;
end;

for ChanNo = 1:NoChan,
  subplot(NoRow,NoCol,Sig.chan(ChanNo));
  plot(t,Sig.dat(:,ChanNo),Sig.dsp.args{:});
  set(gca,'xlim',[t(1) t(end)]);
  title(sprintf('N=%d, Ch=%d',ChanNo, Sig.chan(ChanNo)),'color','r');
  drawstmlines(Sig);
  hold on
end;

xlabel(Sig.dsp.label{1});
ylabel(Sig.dsp.label{2});
set(gcf,'DefaultAxesfontsize',	fs);
set(gcf,'DefaultAxesfontweight',fw);
