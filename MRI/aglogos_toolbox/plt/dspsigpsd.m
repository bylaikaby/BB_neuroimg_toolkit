function dspsigpsd(Sig)
%DSPSIGPSD - displays the PSD of a Cln signal
% DSPSIGPSD is used to estimate the regions of high power
% changes that can be used to determing the LFP/MUA ranges.
% NKL 11.05.03
		
global DispPars;

if nargin < 1,
	error('usage: dspsigpsd(Sig);');
end;

f = [0:size(Sig.dat,1)-1]*Sig.dx(1);
f=f(:);

fs = get(gcf,'DefaultAxesfontsize');
fw = get(gcf,'DefaultAxesfontweight');
set(gcf,'DefaultAxesfontsize',	8);
set(gcf,'DefaultAxesfontweight','normal');
set(gcf,'color', DispPars.figcolor);

plot(f,Sig.dat);
set(gca,'xscale','log');

pnts = find(f>=20&f<300);
for N=1:size(Sig.dat,2),
  [m,ix(N)] = max(Sig.dat(pnts,N));
end;
ix = ix + pnts(1) - 1;
ix = round(mean(ix));

hold on;
line([f(ix) f(ix)],get(gca,'ylim'),'color','r');

set(gca,'xlim',[f(1) f(end)]);
set(gca,'xcolor', DispPars.xcolor);
set(gca,'ycolor', DispPars.ycolor);
set(gca,'color', DispPars.color);

xlabel(Sig.dsp.label{1});
ylabel(Sig.dsp.label{2});
set(gcf,'DefaultAxesfontsize',	fs);
set(gcf,'DefaultAxesfontweight',fw);







