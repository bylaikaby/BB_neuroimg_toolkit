function showfratio(Arg1, Arg2)
%SHOWFRATIO - Show the F-Ratio of reduced-to-full design matrix for each frequency band
% showfratio(SesName, GrpName) shows for one or more sessions the fratio results
%
% EXAMPLES:
%       showfratio('alert','kf');           The 5 best sessions
%       showfratio('alert','kfall');        All OK sessions
%       showfratio('alfratio','kf');        The 5 best sessions (from ..fratio.mat)
%       showfratio('alfratio','kfall');     All OK sessions
%
%       showfratio('n02gu1');           (Default group = 'fix')
%       showfratio('n02gu1','fix');
%       showfratio('alert','
%
% NKL 23.01.2008

if nargin < 1,  help showfratio; return;    end;

if (strcmp(Arg1,'alert') | strcmp(Arg1,'anest')),
  if nargin < 2,
    Arg2 = 'all';
  end;
  ses = seslist(Arg1,Arg2);
  SINGLE_SESSION=0;
else
  ses{1}{1} = Arg1;
  SINGLE_SESSION=1;
end;

if SINGLE_SESSION,
  Ses = goto(ses{1}{1});
  grpnames = getgrpnames(Ses);
  for N=1:length(grpnames),
    fname = catfilename(Ses.name,grpnames{N});
    load(fname, 'fratio');
    %              x: [3x1 double]
    %              y: [3x8 double]
    %              p: [3x8 double]
    %          betas: [3x1 double]
    %         serror: [3x1 double]
    %        pvalues: [1x8794 single]
    if N==1,
      tmpfratio = fratio;
    else
      tmpfratio.y = cat(2,tmpfratio.y,fratio.y);
      tmpfratio.p = cat(2,tmpfratio.p,fratio.p);
    end;
  end;
  fratio = tmpfratio; clear tmpfratio;
  dspfratio(fratio);
  return;
end;


for N=1:length(ses),
  tmpses = ses{N}{1};
  PrepType = getpreptype(tmpses);
  if strcmp(PrepType,'alert'),
    GrpName = 'fix';
  else
    GrpName = 'zstim';
  end;

  fprintf('%s.', tmpses);
  goto(tmpses);
  fname = strcat(GrpName,'.mat');
  tmpfratio = matsigload(fname,'fratio');
  
  if N==1,
    fratio = tmpfratio;
  else
    fratio.y = cat(2,fratio.y,tmpfratio.y);
    fratio.p = cat(2,fratio.p,tmpfratio.p);
  end;
end;
fprintf('...Done!\n');
fratio.arg1 = Arg1;
if exist('Arg2','var'),
  fratio.arg2 = Arg2;
else
  fratio.arg2 = 'none';
end;

if size(fratio.y,2) == 1,
  subPlotSingleSession(fratio);
else
  subPlotMultipleSessions(fratio);
end;
return;

  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Single Session results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subPlotSingleSession(fratio)
mfigure([100 300 900 800]);
bar(fratio.x, fratio.y);
set(gca,'xlim',fratio.xlim);
set(gca,'xticklabel',fratio.xticklabel);
xlabel(fratio.xlabel);ylabel(fratio.ylabel);
hold on;
s = fratio.y+1;
p = fratio.p;
s01 = find(p<0.01);
s001 = find(p<0.001);
plot(fratio.x(s01), s(s01),'linestyle','none','marker','*','markerfacecolor','g','markeredgecolor','g');
plot(fratio.x(s001), s(s001),'linestyle','none','marker','*','markerfacecolor','r','markeredgecolor','r');
grid on;
suptitle(sprintf('Session: %s, Group: %s',fratio.sesname, fratio.grpname));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Multiple Sessions results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subPlotMultipleSessions(fratio)
%mfigure([100 300 900 800]);
mfigure([100 200 700 600]);
m = hnanmean(fratio.y,2);
m = median(fratio.y,2);
s = std(fratio.y,1,2)/sqrt(size(fratio.y,2));
hd2 = errorbar(fratio.x, m, s);
eb = findall(hd2);
set(eb(1),'LineWidth',0.5,'Color','k','linestyle','none','linewidth',2);
set(eb(2),'LineWidth',2,'Color','b','marker','none','linestyle','none',...
          'markeredgecolor','k','markerfacecolor','b','markersize',12);
hold on;
bar(fratio.x, m);
hold on;
st = m+s+1;
p = median(fratio.p,2);
s01 = find(p<0.01);
s001 = find(p<0.001);

if 0,
  plot(fratio.x(s01), st(s01),'linestyle','none','marker','*','markersize',10,...
       'markerfacecolor','g','markeredgecolor','g');
  plot(fratio.x(s001), st(s001),'linestyle','none','marker','*','markersize',10,...
       'markerfacecolor','r','markeredgecolor','r');
else
  for N=1:length(st),
    text(fratio.x(N), 2, sprintf('%.6f', p(N)),'fontsize',10,...
         'rotation',90,'color','w','fontweight','bold');
  end;
end;

set(gca,'xlim',fratio.xlim);
set(gca,'xtick',[1:length(fratio.xticklabel)]);
set(gca,'xticklabel',fratio.xticklabel);
xlabel(fratio.xlabel);
ylabel(fratio.ylabel);
grid on;
s1 = 'F-Ratio for 15 LFP bands (W=10Hz) & MUA';
s2 = sprintf('getfratio(%s,%s)/showfratio(fratio,kf)', fratio.arg1, fratio.arg2);
s3 = 'p <= 0.01 (Green Asterisk), p <= 0.001 (Red Asterisk)';
title({s1;s2;s3});
set(gca,'layer','top');
grid off
return;


