SESSION = 'j02kh1';

GROUPS = {};
GROUPS{end+1} = 'j02kh1_6';
GROUPS{end+1} = 'j02kh1_11';
GROUPS{end+1} = 'j02kh1_21';
GROUPS{end+1} = 'j02kh1_37';
GROUPS{end+1} = 'j02kh1_51';
%GROUPS{end+1} = 'j02qx1_4';  % bad activation...
GROUPS{end+1} = 'j02x31_3';
GROUPS{end+1} = 'j02yu1_4';
GROUPS{end+1} = 'j02yu1_5';
GROUPS{end+1} = 'j02hx1_10';


ALPHA = 0.05;


fprintf('%s: loading data N=%d (alpha=%g)...',mfilename,length(GROUPS),ALPHA);
NumVoxels = NaN(length(GROUPS),2);
RespR     = NaN(length(GROUPS),2);
RespMean  = NaN(length(GROUPS),2);
RespStd   = NaN(length(GROUPS),2);
SIG.dat   = NaN(16,length(GROUPS),2);
SIG.std   = NaN(16,length(GROUPS),2);
for N = 1:length(GROUPS),
  tmpsig = mvoxselect(SESSION,GROUPS{N},'all','corr[hemo]',[],ALPHA,'base','blank','selectR','both');
  RESP_R{N}   = tmpsig.stat.dat;
  RESP_VAL{N} = tmpsig.resp.mean - tmpsig.resp.base;
  pidx = find(RESP_R{N} > 0);
  nidx = find(RESP_R{N} < 0);
  NumVoxels(N,1) = length(pidx);
  NumVoxels(N,2) = length(nidx);
  RespR(N,1)     = nanmean(RESP_R{N}(pidx));
  RespR(N,2)     = nanmean(RESP_R{N}(nidx));
  RespMean(N,1)  = nanmean(RESP_VAL{N}(pidx));
  RespMean(N,2)  = nanmean(RESP_VAL{N}(nidx));
  RespStd(N,1)   = nanstd(RESP_VAL{N}(pidx));
  RespStd(N,2)   = nanstd(RESP_VAL{N}(nidx));
  SIG.dat(:,N,1) = nanmean(tmpsig.dat(:,pidx),2);
  SIG.dat(:,N,2) = nanmean(tmpsig.dat(:,nidx),2);
  SIG.std(:,N,1) = nanstd(tmpsig.dat(:,pidx),[],2);
  SIG.std(:,N,2) = nanstd(tmpsig.dat(:,nidx),[],2);
  SIG.dx = tmpsig.dx;
end

SIG.sem = NaN(size(SIG.std));
for N = 1:length(GROUPS),
  if NumVoxels(N,1) > 0,
    SIG.sem(:,N,1) = SIG.std(:,N,1)/sqrt(NumVoxels(N,1));
  end
  if NumVoxels(N,2) > 0,
    SIG.sem(:,N,2) = SIG.std(:,N,2)/sqrt(NumVoxels(N,2));
  end
end

idx_7T = [];
idx_47T = [];
xticklabel = {};
for N = 1:length(GROUPS),
  if any(strfind(GROUPS{N},'j02kh1')),
    % 7T test scan
    idx_7T(end+1) = N;
    xticklabel{N} = sprintf('7T: %s',GROUPS{N});
  else
    % 4.7T test scan
    idx_47T(end+1) = N;
    xticklabel{N} = sprintf('4.7T: %s',GROUPS{N});
  end
end



% plot data

% Num Voxels
figure('Name',sprintf('%s: Num Voxels (P<%g)',mfilename,ALPHA),'defaultaxesfontweight','bold');
pos = get(gcf,'pos');  pos(3) = pos(3)*1.5;  set(gcf,'pos',pos);
subplot(1,2,1);
% insert NaN to split 7T and 4.7T data
tmpx = [idx_7T max(idx_7T)+0.5 idx_47T];
tmpdat = NumVoxels(idx_7T,:);
tmpdat(end+1,:) = NaN;
tmpdat = cat(1,tmpdat,NumVoxels(idx_47T,:));
h = plot(tmpx,tmpdat,'marker','o','markersize',8,'linewidth',2);
set(h(1),'color',[0.9 0.5 0.1]);  set(h(2),'color',[0.2 0.2 0.8]);
legend('CorrR>0','CorrR<0','location','northwest');
% stupid but need to do...
set(gca,'xticklabel',[],'xlim',[0 length(GROUPS)+1]);
for N = 1:length(GROUPS),
  text(N,-100,strrep(xticklabel{N},'_','\_'),...
       'rotation',-90,'fontsize',8,'fontweight','bold');
end
ylabel('# of Activated Voxels');
grid on;
title(sprintf('Num. Activated Voxels (P<%g)',ALPHA));
pos = get(gca,'pos');  pos(2) = 0.22;  pos(4) = 0.70;  set(gca,'pos',pos);

subplot(1,2,2);
tmpm = []; tmps = [];
tmpm(1,:) = nanmean(NumVoxels(idx_7T,:),1);
tmpm(2,:) = nanmean(NumVoxels(idx_47T,:),1);
tmps(1,:) = nanstd(NumVoxels(idx_7T,:),[],1)/sqrt(length(idx_7T));
tmps(2,:) = nanstd(NumVoxels(idx_47T,:),[],1)/sqrt(length(idx_47T));
[h,signifP,ci,] = ttest2(NumVoxels(idx_7T,1),NumVoxels(idx_47T,1),ALPHA,'both');
[h,signifN,ci,] = ttest2(NumVoxels(idx_7T,2),NumVoxels(idx_47T,2),ALPHA,'both');
h = errorbar(tmpm,tmps,'linewidth',2,'marker','o','markersize',8);
set(h(1),'color',[0.9 0.5 0.1]);  set(h(2),'color',[0.2 0.2 0.8]);
legend(sprintf('CorrR>0 P=%.3f(t-test)',signifP),...
       sprintf('CorrR<0 P=%.3f(t-test)',signifN),'location','northwest');
ylabel('# of Activated Voxels');
set(gca,'xlim',[0.5 2.5],'xtick',[1 2],'xticklabel',[]);
text(1,-100,'7T','rotation',-90,'fontsize',8,'fontweight','bold');
text(2,-100,'4.7T','rotation',-90,'fontsize',8,'fontweight','bold');
grid on;
title(sprintf('Mean/SEM of Num Voxels (P<%g)',ALPHA));
pos = get(gca,'pos');  pos(2) = 0.22;  pos(4) = 0.70;  set(gca,'pos',pos);



% Mean Response
figure('Name',sprintf('%s: Mean Response (P<%g)',mfilename,ALPHA),'defaultaxesfontweight','bold');
pos = get(gcf,'pos');  pos(3) = pos(3)*1.5;  set(gcf,'pos',pos);
subplot(1,2,1);
% insert NaN to split 7T and 4.7T data
tmpx = [idx_7T max(idx_7T)+0.5 idx_47T];
tmpdat = RespMean(idx_7T,:);
tmpdat(end+1,:) = NaN;
tmpdat = cat(1,tmpdat,RespMean(idx_47T,:));
h = plot(tmpx,abs(tmpdat),'marker','o','markersize',8,'linewidth',2);
set(h(1),'color',[0.9 0.5 0.1]);  set(h(2),'color',[0.2 0.2 0.8]);
legend('CorrR>0','CorrR<0','location','southeast');
set(gca,'ylim',[0 max(get(gca,'ylim'))]);
% stupid but need to do...
set(gca,'xticklabel',[],'xlim',[0 length(GROUPS)+1]);
for N = 1:length(GROUPS),
  text(N,-0.1,strrep(xticklabel{N},'_','\_'),...
       'rotation',-90,'fontsize',8,'fontweight','bold');
end
ylabel('BOLD Amplitude (%)');
grid on;
title(sprintf('Mean Response (P<%g)',ALPHA));
pos = get(gca,'pos');  pos(2) = 0.22;  pos(4) = 0.70;  set(gca,'pos',pos);
subplot(1,2,2);
tmpm = []; tmps = [];
tmpm(1,:) = nanmean(RespMean(idx_7T,:),1);
tmpm(2,:) = nanmean(RespMean(idx_47T,:),1);
tmps(1,:) = nanstd(RespMean(idx_7T,:),[],1)/sqrt(length(idx_7T));
tmps(2,:) = nanstd(RespMean(idx_47T,:),[],1)/sqrt(length(idx_47T));
[h,signifP,ci,] = ttest2(RespMean(idx_7T,1),RespMean(idx_47T,1),ALPHA,'both');
[h,signifN,ci,] = ttest2(RespMean(idx_7T,2),RespMean(idx_47T,2),ALPHA,'both');
h = errorbar(abs(tmpm),tmps,'linewidth',2,'marker','o','markersize',8);
set(h(1),'color',[0.9 0.5 0.1]);  set(h(2),'color',[0.2 0.2 0.8]);
legend(sprintf('CorrR>0 P=%.3f(t-test)',signifP),...
       sprintf('CorrR<0 P=%.3f(t-test)',signifN),'location','southeast');
ylabel('BOLD Amplitude (%)');
set(gca,'ylim',[0 max(get(gca,'ylim'))]);
set(gca,'xlim',[0.5 2.5],'xtick',[1 2],'xticklabel',[]);
text(1,-0.2,'7T','rotation',-90,'fontsize',8,'fontweight','bold');
text(2,-0.2,'4.7T','rotation',-90,'fontsize',8,'fontweight','bold');
grid on;
title(sprintf('Mean/SEM of Mean Response (P<%g)',ALPHA));
pos = get(gca,'pos');  pos(2) = 0.22;  pos(4) = 0.70;  set(gca,'pos',pos);


% STD Response
figure('Name',sprintf('%s: Response STD (P<%g)',mfilename,ALPHA),'defaultaxesfontweight','bold');
pos = get(gcf,'pos');  pos(3) = pos(3)*1.5;  set(gcf,'pos',pos);
subplot(1,2,1);
% insert NaN to split 7T and 4.7T data
tmpx = [idx_7T max(idx_7T)+0.5 idx_47T];
tmpdat = RespStd(idx_7T,:);
tmpdat(end+1,:) = NaN;
tmpdat = cat(1,tmpdat,RespStd(idx_47T,:));
h = plot(tmpx,tmpdat,'marker','o','markersize',8,'linewidth',2);
set(h(1),'color',[0.9 0.5 0.1]);  set(h(2),'color',[0.2 0.2 0.8]);
legend('CorrR>0','CorrR<0','location','southeast');
set(gca,'ylim',[0 max(get(gca,'ylim'))]);
% stupid but need to do...
set(gca,'xticklabel',[],'xlim',[0 length(GROUPS)+1]);
for N = 1:length(GROUPS),
  text(N,-0.1,strrep(xticklabel{N},'_','\_'),...
       'rotation',-90,'fontsize',8,'fontweight','bold');
end
ylabel('STD of BOLD Amplitude (%)');
grid on;
title(sprintf('Response STD (P<%g)',ALPHA));
pos = get(gca,'pos');  pos(2) = 0.22;  pos(4) = 0.70;  set(gca,'pos',pos);
subplot(1,2,2);
tmpm = []; tmps = [];
tmpm(1,:) = nanmean(RespStd(idx_7T,:),1);
tmpm(2,:) = nanmean(RespStd(idx_47T,:),1);
tmps(1,:) = nanstd(RespStd(idx_7T,:),[],1)/sqrt(length(idx_7T));
tmps(2,:) = nanstd(RespStd(idx_47T,:),[],1)/sqrt(length(idx_47T));
[h,signifP,ci,] = ttest2(RespStd(idx_7T,1),RespStd(idx_47T,1),ALPHA,'both');
[h,signifN,ci,] = ttest2(RespStd(idx_7T,2),RespStd(idx_47T,2),ALPHA,'both');
h = errorbar(abs(tmpm),tmps,'linewidth',2,'marker','o','markersize',8);
set(h(1),'color',[0.9 0.5 0.1]);  set(h(2),'color',[0.2 0.2 0.8]);
legend(sprintf('CorrR>0 P=%.3f(t-test)',signifP),...
       sprintf('CorrR<0 P=%.3f(t-test)',signifN),'location','southeast');
ylabel('STD of BOLD Amplitude (%)');
set(gca,'ylim',[0 max(get(gca,'ylim'))]);
set(gca,'xlim',[0.5 2.5],'xtick',[1 2],'xticklabel',[]);
text(1,-0.2,'7T','rotation',-90,'fontsize',8,'fontweight','bold');
text(2,-0.2,'4.7T','rotation',-90,'fontsize',8,'fontweight','bold');
grid on;
title(sprintf('Mean/SEM of Response STD (P<%g)',ALPHA));
pos = get(gca,'pos');  pos(2) = 0.22;  pos(4) = 0.70;  set(gca,'pos',pos);




% Plot Time course
figure('Name',sprintf('%s: Time Course (P<%g)',mfilename,ALPHA),'defaultaxesfontweight','bold');
pos = get(gcf,'pos');  pos(3) = pos(3)*1.5;  set(gcf,'pos',pos);
subplot(1,2,1);
tmpt = [0:size(SIG.dat,1)-1]*SIG.dx;
for N = 1:size(SIG.dat,2),
  if any(idx_7T == N),
    tmpcolor = [0.0 0.0 1.0];
  else
    tmpcolor = [0.0 0.5 0.0];
  end
  tmpm = squeeze(SIG.dat(:,N,:));
  tmps = squeeze(SIG.sem(:,N,:));
  h = errorbar([tmpt(:) tmpt(:)],tmpm,tmps,'color',tmpcolor);
  hold on;
  set(h(2),'HandleVisibility','off');
  set(h(2),'LineStyle','--');
end
h = legend(strrep(xticklabel,'_','\_'));
set(h,'FontSize',6);
set(gca,'xlim',[-5 tmpt(end)]);
xlabel('Time in seconds');  ylabel('BOLD Amplitude (%)');
title(sprintf('Mean Time Course (P<%g)',ALPHA));
text(0.99,0.01,'mean+-sem','units','normalized',...
     'HorizontalAlignment','right','VerticalAlignment','bottom');
grid on;
ylm = get(gca,'ylim');  ylm = [-max(abs(ylm)) max(abs(ylm))];
set(gca,'ylim',ylm);
h = rectangle('pos',[0 min(ylm) 48 ylm(2)-ylm(1)],...
              'linestyle','none','facecolor',[1.0 0.9 0.9]);
setback(h);
set(gca,'layer','top');

subplot(1,2,2);
tmpm = squeeze(nanmean(SIG.dat(:,idx_7T,:),2));
tmps = squeeze(nanstd(SIG.dat(:,idx_7T,:),[],2)) / sqrt(length(idx_7T));
h = errorbar([tmpt(:) tmpt(:)],tmpm,tmps,'linewidth',2);
set(h,'color',[0.0 0.0 1.0]);
set(h(2),'HandleVisibility','off','linestyle','--');
hold on;
tmpm = squeeze(nanmean(SIG.dat(:,idx_47T,:),2));
tmps = squeeze(nanstd(SIG.dat(:,idx_47T,:),[],2)) / sqrt(length(idx_7T));
h = errorbar([tmpt(:) tmpt(:)],tmpm,tmps,'linewidth',2);
set(h,'color',[0.0 0.5 0.0]);
set(h(2),'HandleVisibility','off','linestyle','--');
grid on;
legend('7T','4.7T');
set(gca,'xlim',[-5 tmpt(end)]);
xlabel('Time in seconds');  ylabel('BOLD Amplitude (%)');
title(sprintf('Mean/SEM of Mean Time Course (P<%g)',ALPHA));
text(0.99,0.01,'mean+-sem','units','normalized',...
     'HorizontalAlignment','right','VerticalAlignment','bottom');
grid on;
set(gca,'ylim',ylm);
h = rectangle('pos',[0 min(ylm) 48 ylm(2)-ylm(1)],...
              'linestyle','none','facecolor',[1.0 0.9 0.9]);
setback(h);
set(gca,'layer','top');
