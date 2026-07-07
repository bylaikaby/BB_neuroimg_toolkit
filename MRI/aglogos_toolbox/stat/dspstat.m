function dspstat(sts)
%DSPSTAT - Displays experiment statistics
% DSPSTAT(sts) displays the results of EXPGETSTAT. A number of
% statistics and statistical functions are computed; Their usage
% depends on the experimet. Usually the sts structure (see below)
% is saved into the mat file together with all other
% signals. Grouping by using SESGRPSTAT is used to analyze the
% properties of each signal. 
% 
% Structure of the statistical results
%    ----------------------------------
%    General Experiment Information
%    ----------------------------------
%     session: 'c98nm1'
%     grpname: 'movie1'
%       ExpNo: 1
%         dir: [1x1 struct]
%         dsp: [1x1 struct]
%        chan: [1 2 3 4 5 6 7 8 9 10 11 16 13 14 15]
%          dx: 0.0040
%         grp: [1x1 struct]
%         evt: [1x1 struct]
%         stm: [1x1 struct]
%    ----------------------------------
%    Signal Statistics  
%    ----------------------------------
%         sts: [1x1 struct]
%         ent: [1x1 struct]
%         pdf: [1x1 struct]
%         cor: [1x1 struct]
%         rms: [1x1 struct]
%
% NKL 28.06.04

if nargin < 1,
  help dspstat;
  return;
end;

names = fieldnames(sts);
K = 1;
for N=1:length(names),
  if ~isempty(strfind(lower(names{N}),'lfp')), continue; end;
  if ~isempty(strfind(lower(names{N}),'gamma')), continue; end;
  if ~isempty(strfind(lower(names{N}),'sdf')), continue; end;
  if ~isempty(strfind(lower(names{N}),'mua')), continue; end;
  idx(K) = N;
  K = K + 1;
end;

for N=1:length(names),
  if exist('idx') & any(idx==N), continue; end;
  DOdspstat(eval(sprintf('sts.%s', names{N})));
end;
  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DOdspstat(sts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mfigure([1 55 1278 935]);
set(gcf,'DefaultAxesfontsize',	8);
set(gcf, 'DefaultAxesFontName', 'Arial');
set(gcf,'color',[.8 .92 .9]);

COL=8; ROW=4;
tmp = mean(sts.cor.dat,4);
sacr = tmp(:,:,2);
bacr = tmp(:,:,1);
t = [0:size(bacr,1)-1]*sts.cor.dx;
t = t(:) - sts.cor.nlags * sts.cor.dx;
for ChanNo = 1:size(bacr,2),
  subplot(ROW,COL,sts.chan(ChanNo));
  plot(t,bacr(:,ChanNo),'color','k');
  hold on;
  plot(t,sacr(:,ChanNo),'color','r');
  set(gca,'xlim',[t(1) t(end)]);
  title(sprintf('In:%d-Ch=%d',ChanNo,sts.chan(ChanNo)));
end;

subplot(2,4,5);
hd = bar(sts.ent.dat);
ylabel('Entropy');
xlabel('Channel Number');
set(hd(1),'facecolor','k','edgecolor','k');
set(hd(2),'facecolor','r','edgecolor','r');
title('Signal Entropy');
legend('Blank','Stim',3);
set(gca,'xlim',[0 16],'xtick',[0:2:16]);

subplot(2,4,6);
hd = bar(sts.rms.dat);
ylabel('RMS');
xlabel('Channel Number');
set(hd(1),'facecolor','k','edgecolor','k');
set(hd(2),'facecolor','r','edgecolor','r');
title('Signal RMS Value');
set(gca,'xlim',[0 16],'xtick',[0:2:16]);

subplot(2,4,7);
hd = bar(sts.pdf.x, sts.pdf.dat);
ylabel('Scores');
xlabel('Channel Number');
set(hd(1),'facecolor','k','edgecolor','k');
set(hd(2),'facecolor','r','edgecolor','r');
set(gca,'xlim',[-3 3]);
title('Amplitude Distribution');

% STS
%       mean: [2x15 double]
%     median: [2x15 double]
%        std: [2x15 double]
%        iqr: [2x15 double]
subplot(4,4,12);
z = (sts.sts.mean(2,:)-sts.sts.mean(1,:))./...
    sqrt(sts.sts.std(1,:).*sts.sts.std(2,:));
hd = bar(z);
ylabel('Z-Score');
xlabel('Channel Number');
set(hd(1),'facecolor','k','edgecolor','k');
title('(m1-m2)/sqrt(s1*s2)');
set(gca,'xlim',[0 16],'xtick',[0:2:16]);

subplot(4,4,12);
hd = bar(sts.sts.median(2,:)-sts.sts.median(1,:));
ylabel('Median');
xlabel('Channel Number');
set(hd(1),'facecolor','b','edgecolor','k');
title('Difference of Medians');
set(gca,'xlim',[0 16],'xtick',[0:2:16]);

subplot(4,4,16);
hd = bar(sts.sts.iqr');
ylabel('IQR');
xlabel('Channel Number');
set(hd(1),'facecolor','g','edgecolor','k');
title('Interquartile Intervals');
set(gca,'xlim',[0 16],'xtick',[0:2:16]);

% TITLE etc.
stit = sprintf('Session: %s, Group: %s, ExpNo: %d, Sig: %s',...
               sts.session, sts.grpname, sts.ExpNo, sts.dir.dname);
suptitle(stit,'r');
