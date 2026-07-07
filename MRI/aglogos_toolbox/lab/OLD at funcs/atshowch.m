function atshowch(SESSION, GrpName)
%ATSHOWCH - Group all contrast of a group by calling catconfunc
% ATSHOWCH invokes catconfunc(SESSION, GrpName, SigName) and
% concatanates all computed contrast functions.
%
% TODO
% 1. GET ALL AVERAGE AND PLOT EACH SIGNAL FOR ONE!! DISTANCE
%   

  
  
NORMALIZE=1;

Ses = goto(SESSION);
grp = getgrpbyname(Ses,GrpName);
sigs = Ses.GrpCHSigs;
filename = strcat(GrpName,'.mat');
  
load(filename,sigs{:});

TITLE = sprintf('atshowch: SESSION: %s, GrpName: %s\n',...
				  Ses.name, GrpName);

mfigure([100 50 1100 850],TITLE,'r',11);
for N=1:length(sigs),

  eval(sprintf('Sig = %s;',sigs{N}));
  for NN=1:length(Sig.npairs),
	dist{N}(NN) = Sig.npairs{NN}.dist;
  end;
  
  eval(sprintf('Sig = %s;', sigs{N}));
  Sig.dat = hnanmean(Sig.dat,3);
  Sig.bdat = hnanmean(Sig.bdat,3);
  Sig.std = hnanmean(Sig.std,3);
  c = mean(Sig.dat,1);
  csd = mean(Sig.std,1);
  bc = mean(Sig.bdat,1);

  hd(N) = subplot(3,3,N);
  plot(dist{N}, c, 'rs-','markerfacecolor','r');
  hold on;
  ed = errorbar(dist{N}, c, csd);
  set(ed(1),'color','k','linewidth',2);
  set(ed(2),'color','b','linewidth',1);
  
  tmpylim=get(gca,'ylim');
  ylim(N) = max(tmpylim);
end;

ylim = max(ylim);
for N=1:length(sigs),
  dist{N} = round(dist{N}*1000)/1000;
  lim = max(abs(dist{N}));
  lim = 0.1 * lim;
  axes(hd(N));
  set(hd(N),'ylim',[0 ylim]);
  set(hd(N),'xtick',dist{N});
  set(hd(N),'xlim',[dist{N}(1)-lim dist{N}(end)+lim]);
  plot_title = sprintf('Signal Type: %s', sigs{N});
  title(plot_title);
  xlabel('Distance in mm');
  ylabel('Coherence');
  grid on;
end;
return;

