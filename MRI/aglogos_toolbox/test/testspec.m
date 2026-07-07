function [SPblank SPmovie SPf] = testspec(SESSION,EXPS)
%
%  SPblank,SPmovie: (freq,chan,exp)  
%

Ses = goto(SESSION);
if ischar(EXPS),  EXPS = getexps(SESSION,EXPS);  end

grp = getgrp(Ses,EXPS(1));
fprintf('%s %s: %s %s nexps=%d\n',gettimestring,mfilename,...
        Ses.name,grp.name,length(EXPS));
SPblank = [];  SPmovie = [];
for iExp = length(EXPS):-1:1,
  ExpNo = EXPS(iExp);
  fprintf(' %s [%3d/%d] Exp=%d:\n',mfilename,...
          length(EXPS)-iExp+1,length(EXPS),ExpNo);
  [spblank,spmovie,f] = spc_blankstim(Ses.name,ExpNo);
  SPblank(:,:,iExp) = spblank;
  SPmovie(:,:,iExp) = spmovie;
end
SPf = f;
fprintf('%s %s: done.\n',gettimestring,mfilename);


if nargout > 0, return;  end






spratio = squeeze(mean(SPmovie./SPblank,2));  % mean across channels

m = squeeze(mean(spratio,2));
s = squeeze(std(spratio,[],2));

if length(EXPS) == 1,
  tmptitle = sprintf('%s Exp=%d(%s) PSD ratio of movie/blank',...
                     Ses.name,EXPS(1),grp.name);
else
  tmptitle = sprintf('%s grp=%s PSD ratio of movie/blank',...
                     Ses.name,grp.name);
end
figure('Name',tmptitle);
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName',  'Comic Sans MS');
set(gcf,'PaperType',			'A4');


%F_list = [13 43 73 158],
F_list = [5 13 33 57 99 158];

subplot(2,1,1);
plot(SPf,m,'color','b','linewidth',2);
hold on; grid on;
%plot(SPf,m+s,'color','r');
plot(SPf,m+s,'color',[0.9 0.5 0.5]); 
%plot(SPf,m-s,'color','g');
plot(SPf,m-s,'color',[0.5 0.9 0.5]);
h = legend(sprintf('mean (N=%d)',length(EXPS)),'mean+sd','mean-sd');
legend(h,'location','NorthWest');
set(gca,'xlim',[0.5 500],'ylim',[0.4 7],...
        'xscale','log','yscale','log');
for F = F_list,
  line([F F],get(gca,'ylim'),'color','r');
  text(F,max(get(gca,'ylim')),num2str(F),'fontweight','bold');
end
title(tmptitle);
xlabel('Frequency in Hz');
ylabel('PSD ratio of movie/blank');

text(0.02,0.02,sprintf('nexps=%d nchans=%d',length(EXPS),size(SPmovie,2)),...
     'units','normalized','fontweight','bold');


mb = squeeze(mean(SPblank,2));
mm = squeeze(mean(SPmovie,2));

subplot(2,1,2);
plot(SPf,mean(mb,2),'color','b','linewidth',2);
hold on; grid on;
plot(SPf,mean(mm,2),'color','r','linewidth',2);
h = legend('blank','movie');
legend(h,'location','NorthWest');
set(gca,'xlim',[0.5 500],...
        'xscale','log','yscale','log');

for F = F_list,
  line([F F],get(gca,'ylim'),'color','r');
  text(F,max(get(gca,'ylim')),num2str(F),'fontweight','bold');
end
title('Mean PSD during blank and movie');
xlabel('Frequency in Hz');
ylabel('Power Spectral Density in dB/Hz');

text(0.02,0.02,sprintf('nexps=%d nchans=%d',length(EXPS),size(SPmovie,2)),...
     'units','normalized','fontweight','bold');




if length(EXPS) == 1,
  figfile = sprintf('%s_%03d_psd_ratio.fig',Ses.name,EXPS(1));
else
  figfile = sprintf('%s_%s_psd_ratio.fig',Ses.name,grp.name);
end

saveas(gcf,figfile);
