function dspsigpow(Sig)
%DSPSIGPOW - plot a neural raw signal
%	dspsigpow(Sig) - plot a neural raw signal
%	NKL, 13.12.01

global DispPars;

if ~exist('DispPars') | ~isfield(DispPars,'sumactivity'),
  initdisppars;
end;

if nargin < 1,
	error('usage: dspsigpow(Sig);');
end;

if ~isfield(Sig,'chan'),
  Sig.chan = [1];
  fprintf('WARNING: Old file with no channel information!\n');
end;
	

NoObsp = size(Sig.dat,3);

t = [0:size(Sig.dat,1)-1]*Sig.dx(1);
t=t(:);

NoChan = size(Sig.dat,3);

if DispPars.sumactivity,
  NoRow=1;  NoCol=1;
  Sig.dat = reshape(Sig.dat,[size(Sig.dat,1) size(Sig.dat,2)*size(Sig.dat,3)]);
  err = std(Sig.dat,1,2);
  m = mean(Sig.dat,2);
  if 0,
	h = errorbar(t,m,err);
	if strcmp(Sig.dir.dname,'LfpM'),
	  set(h(1),Sig.dsp.args{:},'color',[1 .7 .7],'linestyle',':');
	else
	  set(h(1),Sig.dsp.args{:},'color',[.7 .7 1],'linestyle',':');
	end;
	set(h(2),Sig.dsp.args{:},'linewidth',1.5);
  else
	h = plot(t,m);
	set(gca,Sig.dsp.args{:},'linewidth',1.5);
  end;
  
  set(gca,'xlim',[t(1) t(end)]);
  set(gca,'xcolor', DispPars.xcolor);
  set(gca,'ycolor', DispPars.ycolor);
  set(gca,'color', DispPars.color);
  xlabel(Sig.dsp.label{1});
  ylabel(Sig.dsp.label{2});
  grid on;
%  drawstmlines(Sig,DispPars.stimlines{:},'linewidth',2,'color','r');
else
  if size(Sig.dat,2) == 2,
	NoRow=1;  NoCol=2;
  elseif size(Sig.dat,2) > 2 & size(Sig.dat,2) <= 8,
	NoRow=2;  NoCol=4;
  else
	NoRow=4;  NoCol=4;
  end;
  
  fs = get(gcf,'DefaultAxesfontsize');
  fw = get(gcf,'DefaultAxesfontweight');
  set(gcf,'DefaultAxesfontsize',	8);
  set(gcf,'DefaultAxesfontweight','normal');
  set(gcf,'color', DispPars.figcolor);
  set(gcf,'DefaultAxesfontsize',8);
  LABEL=0;
  for ChanNo = 1:size(Sig.dat,2),
	if ~any(Sig.chan == ChanNo),
	  subplot(NoRow,NoCol,ChanNo);
	  set(gca,'color',[.3 .3 .3]);
	  text(0.25,0.5,'No Response','color','y');
	  set(gca,'box','on');
	end;
  end;

  for ChanNo = 1:size(Sig.dat,2),
	subplot(NoRow,NoCol,Sig.chan(ChanNo));
	set(gca,'color','w');
	err = hnanstd(Sig.dat(:,ChanNo,:),3);
	m = hnanmean(Sig.dat(:,ChanNo,:),3);

	if 0 & NoObsp>1,
	  h = errorbar(t,m,err);
	  if strcmp(Sig.dir.dname,'LfpM'),
		set(h(1),Sig.dsp.args{:},'color',[1 .7 .7],'linestyle',':');
	  else
		set(h(1),Sig.dsp.args{:},'color',[.7 .7 1],'linestyle',':');
	  end;
	  set(h(2),Sig.dsp.args{:},'linewidth',1.5);
	else
	  plot(t,m,Sig.dsp.args{:});
	end;

	title(sprintf('Chan: %d',ChanNo));
	set(gca,'xlim',[t(1) t(end)]);
	set(gca,'xcolor', DispPars.xcolor);
	set(gca,'ycolor', DispPars.ycolor);
	set(gca,'color', DispPars.color);
	xlabel(Sig.dsp.label{1});
	ylabel(Sig.dsp.label{2});

	drawstmlines(Sig,DispPars.stimlines{:},'linewidth',2,'color','b');
	hold on;
  end;
  if ChanNo==size(Sig.dat,3),
	LABEL=1;
  end;
  set(gcf,'DefaultAxesfontsize', fs);
  set(gcf,'DefaultAxesfontweight',fw);
end;








