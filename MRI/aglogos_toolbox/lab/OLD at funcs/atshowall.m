function atshowall(SESSION, GrpName)
%ATSHOWALL - Group all contrast of a group by calling catconfunc
% ATSHOWALL invokes catconfunc(SESSION, GrpName, SigName) and
% concatanates all computed contrast functions.
%
% TO RUN THIS YOU MUST FIRST:
% atana(SesName)
% atsesgrpmake(SesName);
% atsupergrp('d98at2');

if ~nargin,
  SESSION='d98at1';
end;

NORMALIZE=1;
ANATYPE = 1;

Ses = goto(SESSION);
if nargin < 2,
  GrpName = strcat('sg',Ses.name,'.mat');
else
  GrpName = strcat(GrpName,'.mat');
end;
  
load(GrpName);

chsig = {'chLfp','chGamma','chatLfp','chMua','chmuaSdf',...
	  'chSdf','chatSdf'};

cfsig = {'cfLfp','cfGamma','cfatLfp','cfMua','cfmuaSdf',...
	  'cfSdf','cfatSdf'};

TITLE = sprintf('atshowall: SESSION: %s, GrpName: %s\n',...
				  Ses.name, GrpName);

eval(sprintf('cfSig = %s;',cfsig{1}));
base = getSigConAvg(cfSdf, 'kc');
minval = min(base.dmean);
cContrast = cfSig.cnames{1};		% Redefine for KMI etc.
for N=1:length(cfsig),
  eval(sprintf('cfSig = %s;', cfsig{N}));
  eval(sprintf('cf = cfSig.%s;', cContrast));
  top = max(cf.selfconts);
  cfavg = getSigConAvg( cfSig, cContrast);
  if NORMALIZE,
	cfavg.dmean = (cfavg.dmean-minval)/top;
	cfavg.dstd = (cfavg.dstd/top);
  end;
  cfmean(N)=nanmean(cfavg.dmean(:));
  cfstd(N)=nanmean(cfavg.dstd(:));
end;


%%%%%
%%%%% Sig.dat = [freq X NoDist X NoMatFiles];
%%%%%
for N=1:length(chsig),
  eval(sprintf('Sig = %s;',chsig{N}));
  for NN=1:length(Sig.npairs),
	dist{N}(NN) = Sig.npairs{NN}.dist;
  end;

  eval(sprintf('Sig = %s;',chsig{N}));

  name{N}=Sig.dir.dname;
  d(N) = nanmean(dist{N});
  label{N} = sprintf('%4.3f--%4.3f',min(dist{N}), max(dist{N}));
  
  eval(sprintf('Sig = %s;', chsig{N}));

  Sig.dat = hnanmean(Sig.dat,3);		% Over repetition (MAT files)
  Sig.std = hnanmean(Sig.std,3);
  c(N)	  = nanmean(Sig.dat(:));
  csd(N)  = nanmean(Sig.std(:));

end;

[d,idx] = sort(d);
mfigure([100 100 500 800],TITLE,'r',11);
subplot(2,1,1);
hd = bar(c(idx));
for N=1:length(label),
  slabel{N} = label{idx(N)};
  sname{N} = name{idx(N)};
  text(N*0.9,0.05+c(idx(N)),char(slabel{N}),...
	   'fontweight','bold','fontsize',8,'color','b','rotation',90);
end;
set(gca,'ylim',[0 1]);
set(gca,'xticklabel',char(sname{:}));
set(gca,'ygrid', 'on');
ylabel('Average Coherence Value in [1 90Hz]');
title('Coherence Analysis');

subplot(2,1,2);
hd = bar(cfmean(idx));
for N=1:length(label),
  slabel{N} = label{idx(N)};
  sname{N} = name{idx(N)};
  text(N*0.9,0.05+cfmean(idx(N)),char(slabel{N}),...
	   'fontweight','bold','fontsize',8,'color','b','rotation',90);
end;
set(gca,'ylim',[0 1]);
set(gca,'xticklabel',char(sname{:}));
set(gca,'ygrid', 'on');
ylabel('Contrast in [1 90Hz]');
title('Mutual Information Analysis');

if 0,
mfigure([100 100 800 850],TITLE,'r',11);
for N=1:length(chsig),

  eval(sprintf('Sig = %s;',chsig{N}));
  for NN=1:length(Sig.npairs),
	dist{N}(NN) = Sig.npairs{NN}.dist;
  end;
  
  eval(sprintf('Sig = %s;', chsig{N}));
  Sig.dat = hnanmean(Sig.dat,3);
  Sig.bdat = hnanmean(Sig.bdat,3);
  Sig.std = hnanmean(Sig.std,3);
  c = mean(Sig.dat,1);
  csd = mean(Sig.std,1);
  bc = mean(Sig.bdat,1);

  hd(N) = subplot(4,2,N);
  plot(dist{N}, c, 'rs-','markerfacecolor','r');
  hold on;
  ed = errorbar(dist{N}, c, csd);
  set(ed(1),'color','k','linewidth',2);
  set(ed(2),'color','b','linewidth',1);
  
  tmpylim=get(gca,'ylim');
  ylim(N) = max(tmpylim);
end;

ylim = max(ylim);
for N=1:length(chsig),
  dist{N} = round(dist{N}*1000)/1000;
  lim = max(abs(dist{N}));
  lim = 0.1 * lim;
  axes(hd(N));
  set(hd(N),'ylim',[0 ylim]);
  set(hd(N),'xtick',dist{N});
  set(hd(N),'xlim',[dist{N}(1)-lim dist{N}(end)+lim]);
  plot_title = sprintf('Signal Type: %s', chsig{N});
  title(plot_title);
  xlabel('Distance in mm');
  ylabel('Coherence');
  grid on;
end;
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cfavg = getSigConAvg(Sig,cContrast)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
eval(sprintf('cf = Sig.%s;',cContrast));
for N=1:length(cf.dat),
  cfavg.dmean(N) = nanmean(cf.dat{N}(:));
  cfavg.dstd(N) = nanstd(cf.dat{N}(:))/sqrt(length(cf.dat{N}(:)));
end;
return;
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mkrfgrid(movpos)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
w = movpos(3);
h = movpos(4);
x = movpos(1)-w/2;
y = movpos(2)-h/2;
rectangle('Position', [x y w h],'linewidth',3,'edgecolor','r');
