function showch(SESSION,arg2,SigName,PRNOUT)
%SHOWCH - Group all contrast of a group by calling catconfunc
% SHOWCH invokes catconfunc(SESSION, GrpName, SigName) and
% concatanates all computed contrast functions.
% SHOWCH ('c98nm1','movie1') all signals in group movie1 (chLfp, ..)
% SHOWCH ('c98nm1',1) all signals in experiment 1
% SHOWCH ('m02lx1','movie1','mrich') BOLD-coherence in group movie1
%
% CF-Related variables
% ses.confunc.algs		= {'kc'};
% ses.confunc.maxchan	= 16;
% ses.confunc.idist		= 1;	% 1mm
% ses.confunc.eleconfig	= [ 01 02 03 04; ...
% 							05 06 07 08; ...
% 						    09 10 11 12; ...
% 							13 14 15 16];
NORMALIZE=1;
if nargin < 4,
  PRNOUT=0;
end;

Ses = goto(SESSION);

if nargin < 2,
  arg2 = [];
end;

if exist('arg2','var') & isa(arg2,'char'),
  GrpName = arg2;
  gnames = fieldnames(Ses.grp);
  if any(strcmp(gnames,GrpName))
	grp = getgrpbyname(Ses,GrpName);
  end;
  filename = strcat(GrpName,'.mat');
else
  ExpNo = arg2;
  filename = catfilename(Ses,ExpNo);
  grp=getgrp(Ses,ExpNo);
  GrpName = grp.name;
end;

if nargin < 3 | (nargin>=3 & isempty(SigName)),
  sigs = Ses.GrpCHSigs;
else
  sigs{1} = SigName;
end;

load(filename,sigs{:});
eval(sprintf('Sig = %s;',sigs{1}));

if length(Sig)>1,
  clear sigs;
  for N=1:length(Sig),
    sigs{N} = sprintf('Sig%d',N);
    eval(sprintf('%s=Sig{%d};',sigs{N},N));
  end;
end;
  
TITLE = sprintf('showch: SESSION: %s, GrpName: %s\n',...
				  Ses.name, GrpName);

if 1,		% Coherence against distance
  mfigure([100 50 1100 850],TITLE,'r',11);
  for N=1:length(sigs),
    eval(sprintf('Sig = %s;', sigs{N}));
    for NP=1:length(Sig.npairs),
      dist{N}(NP) = Sig.npairs{NP}.dist;
    end;
    F1 = 0;
    F2 = 2000;
    IDX = find(Sig.f>F1 & Sig.f < F2);
    Sig.dat = hnanmean(Sig.dat,3);
    Sig.bdat = hnanmean(Sig.bdat,3);
    Sig.std = hnanmean(Sig.std,3);
    c = mean(Sig.dat(IDX,:),1);
    csd = mean(Sig.std(IDX,:),1);
    bc = mean(Sig.bdat(IDX,:),1);
    
    hd(N) = subplot(2,2,N);
    plot(dist{N}, c, 'rs-','markerfacecolor','k');
    hold on;
    %  plot(dist, bc, 'ks-','markerfacecolor','k');
    ed = errorbar(dist{N}, c, csd);
    set(ed(1),'color','k','linewidth',2);
    set(ed(2),'color','b','linewidth',1);
    
    tmpylim=get(gca,'ylim');
    ylim(N) = max(tmpylim);
  end;

  ylim = max(ylim);
  for N=1:length(sigs),
    dist{N} = round(dist{N}*100)/100;
    axes(hd(N));
    set(hd(N),'ylim',[0 ylim]);
    set(hd(N),'xtick',dist{N});
    set(hd(N),'xlim',[dist{N}(1)-0.2 dist{N}(end)+0.2]);
    plot_title = sprintf('Signal Type: %s', sigs{N});
    title(plot_title);
    xlabel('Distance in mm');
    ylabel('Coherence');
    grid on;
  end;
end;
DoPrint(PRNOUT);

if 1,		% PLOT SPECTRA
  mfigure([100 50 1100 850],TITLE,'r',11);
  for N=1:length(sigs),
    eval(sprintf('Sig = %s;', sigs{N}));
    Sig.dat = hnanmean(Sig.dat,3);
    Sig.dat = hnanmean(Sig.dat,2);
    
    hd(N) = subplot(2,2,N);
    plot(Sig.f, Sig.dat);
    plot_title = sprintf('Signal Type: %s (Fs=%5.3f)', sigs{N},1/Sig.dx);
    title(plot_title);
    xlabel('Frequency in Hz');
    ylabel('Coherence');
    set(gca,'yscale','log');
  end;
end;

if 1,		% SINGLE VALUE FOR ALL FREQ & MIN DISTANCE
  for N=1:length(sigs),
    [D,ID]=min(dist{N});
    eval(sprintf('Sig = %s;', sigs{N}));
    Sig.dat = hnanmean(Sig.dat,3);
    Sig.dat = hnanmean(Sig.dat,1);
    Sig.std = hnanmean(Sig.std,3);
    Sig.std = hnanmean(Sig.std,1);
    meanCH(N) = Sig.dat(ID);
    stdCH(N) = Sig.std(ID);
  end;
  mfigure([100 50 400 400],TITLE,'r',11);
  hd = bar(meanCH);
  set(hd,'edgecolor','b','facecolor','k');
  set(gca,'xticklabel',{'Lfp';'Gamma';'MUA';'Sdf'});
  % set(gca,'ylim',[0 0.3],'ygrid','on');
  hold on;
  eb=errorbar([1:length(sigs)],meanCH,stdCH);
  set(eb(1),'linewidth',2,'color','k');
  set(eb(2),'linestyle','none');
  xlabel('Signal Type');
  ylabel('Coherence');
end;
DoPrint(PRNOUT);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoPrint(prnout)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if prnout,
  print;
  close gcf;
end;

