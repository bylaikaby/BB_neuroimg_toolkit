function sesstat(SesName,EXPS,DOPLOT)
%SESSTAT - Compute miscelleneous session-statistics
% SESSTAT (SesName,EXPS,DOPLOT) computes a number of statistics characterizing the entire
% session. In specific:
% 
%   1. BLPSTAT - Estimation of significantly modulating frequency channels
%  
% NKL, 04.08.04

if nargin < 3,
  DOPLOT=0;
end;

Ses = goto(SesName);

if nargin < 3,
  LOG = 0;
end;

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;

% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

if ~DOPLOT,
  % 1. ESTIMATION OF SIGNIF. MODULATION PER FREQUENCY CHANNEL
  blpstat{1}.r = []; blpstat{1}.p = []; blpstat{1}.lag = [];
  blpstat{2} = blpstat{1};
  names = {'model';'roiTs'};
  for ExpNo = EXPS,
    grp=getgrp(Ses,ExpNo);
    fprintf('Processing %s,%s(%d) ... ',Ses.name,grp.name,ExpNo);
    blp = sigload(Ses,ExpNo,'blp');
    for N=1:length(blpstat),
      eval(sprintf('stat = blp.%s;',names{N}));
      blpstat{N}.name = names{N};
      blpstat{N}.r = cat(2,blpstat{N}.r,stat.r);
      blpstat{N}.p = cat(2,blpstat{N}.p,stat.p);
      blpstat{N}.lag = cat(2,blpstat{N}.lag,stat.lag);
      blpstat{N}.info = blp.info;
    end;
    fprintf('Done!\n');
  end;
else
  % OVER MULTIPLE SESSIONS
  sessions = {'n03qv1';'n03qr1';'m02lx1'};
  for SesNo=1:length(sessions),
    goto(sessions{SesNo});
    stat = matsigload('stat.mat','blpstat');
    if SesNo==1,
      blpstat = stat;
    else
      for N=1:length(stat),
        blpstat{N}.r = cat(2,blpstat{N}.r,stat{N}.r);
        blpstat{N}.p = cat(2,blpstat{N}.p,stat{N}.p);
        blpstat{N}.lag = cat(2,blpstat{N}.lag,stat{N}.lag);
      end;
    end;
    SesName='Multiple';
  end;
end;

for N=1:length(blpstat),
  NoExp = size(blpstat{N}.r,2);
  cval = 0.01;
  rval = 0.40;

  p = median(blpstat{N}.p,2);
  r = median(blpstat{N}.r,2);
  idx0 = find(abs(p)>cval);
  idx1 = find(abs(p)<=cval);
  p(idx0)=0;
  p(idx1)=1;

  blpstat{N}.idx = p .* r;
  blpstat{N}.idx(find(blpstat{N}.idx<=rval)) = 0;
end;

if DOPLOT,
  for N=1:length(blpstat{1}.info.band),
    bands{N} = sprintf('%d-%d',blpstat{1}.info.band{N}{1});
  end;
  figure(1);
  set(gcf,'DefaultAxesfontsize',8);
  hd(1) = stem(blpstat{1}.idx);
  hold on;
  hd(2) = stem(blpstat{2}.idx,'color','r','linestyle',':');
  dspyval(gca, bands);
  set(gca,'ylim',[0 1.1],'xlim',[0 length(bands)+1]);
  xlabel('Frequency Band');
  ylabel('Corr Coeff');
  legend(hd,blpstat{1}.name,blpstat{2}.name);
  title(sprintf('Statistics for %s',SesName));
  hold off;
  return;
end;

if exist('stat.mat'),
  save('stat.mat','-append','blpstat');
else
  save('stat.mat','blpstat');
end;    

if LOG,
  LogFile=strcat('SESSTAT_',Ses.name,'.log');	% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end;

if LOG,
  diary off;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dspyval(gca,label)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(gca,'xtick',[1:length(label)]);
tmp = get(gca,'children');
K=1;
for N=1:length(tmp),
  typ = get(tmp(N),'type');
  if strcmp(typ,'hggroup'),
    ydata{K}=get(tmp(N),'ydata');
    xdata{K}=get(tmp(N),'xdata');
    K=K+1;
  end;
end;
for N=1:K-1,
  mx(N,:)=ydata{N};
end;
xdata=xdata{1};
ydata=max(mx);
ytick = get(gca,'ytick');
dy=mean(diff(ytick))/2;
for N=1:length(label),
  text(xdata(N),ydata(N)+dy,label{N},...
       'fontsize',9,'color','k','fontweight','bold','rotation',90);
end;

  
