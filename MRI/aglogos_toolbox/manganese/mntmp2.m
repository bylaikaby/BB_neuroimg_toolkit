
SESSION = 'm02th1';
GRPNAME = 'mdeftinj';

Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);
EXPS = grp.exps;

fprintf('%s reading data',mfilename);
MSLICE = [];
for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  fprintf('.');
  imgfile = sprintf('spm/rm02th1_%03d.img',ExpNo);
  tcImg = spm2tcimg(imgfile);
  tmpdat = reshape(tcImg.dat,[166*124 205]);
  m = mean(tmpdat,1);
  if isempty(MSLICE),
    MSLICE = zeros(length(m),length(EXPS));
  end
  MSLICE(:,N) = m(:);
end
fprintf(' done.\n');


% normalization
NSLICE = MSLICE;
for N = 1:size(MSLICE,2),
  NSLICE(:,N) = MSLICE(:,N) ./ MSLICE(:,1);
end


figure;
set(gcf,'Name','m02th1 mdeftinj: Mean Voxel Value in Slice');
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName',  'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');

cmap = jet(size(MSLICE,2));
subplot(2,2,1);
for N = 1:size(MSLICE,2),
  plot(MSLICE(:,N),'color',cmap(N,:));  hold on; grid on;
end
set(gca,'clim',[0 size(MSLICE,2)]);
colorbar('location','south','fontsize',8);
text(0.5,0.25,'Time-Color Code','units','normalized',...
     'horizontalalignment','center','fontname','Comic Sans MS','fontweight','bold');
xlabel('Slice Number');
ylabel('Mean Voxel Value');
set(gca,'xlim',[0 size(MSLICE,1)]);
title(sprintf('%s %s:  Mean Voxel Value in Slice',Ses.name,grp.name))

subplot(2,2,2);
for N = 1:size(MSLICE,2),
  plot(NSLICE(:,N),'color',cmap(N,:));  hold on; grid on;
end
set(gca,'clim',[0 size(MSLICE,2)]);
colorbar('location','south','fontsize',8);
text(0.5,0.25,'Time-Color Code','units','normalized',...
     'horizontalalignment','center','fontname','Comic Sans MS','fontweight','bold');
xlabel('Slice Number');
ylabel('Normalied Voxel Value');
set(gca,'xlim',[0 size(MSLICE,1)]);
title(sprintf('%s %s:  Normalized Voxel Value in Slice',Ses.name,grp.name))




subplot(2,2,3);
surf(MSLICE);
set(gca,'xlim',[0 104]); set(gca,'ylim',[0 205]);
xlabel('Experiment Number (Time)');  ylabel('Slice Number');
title(sprintf('%s %s:  Time Course of Mean Voxel Value in Slice',Ses.name,grp.name))



subplot(2,2,4);
surf(NSLICE);
set(gca,'xlim',[0 104]); set(gca,'ylim',[0 205]);
xlabel('Experiment Number (Time)');  ylabel('Slice Number');
title(sprintf('%s %s:  Time Course of Normalized Voxel Value in Slice',Ses.name,grp.name))






% make movie
figure;
set(gcf,'Name','m02th1 mdeftinj: Mean Voxel Value in Slice');
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName',  'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');

pos = get(gcf,'pos');
%pos(3) = pos(3)*1.9;  pos(4) = pos(4)*1.2;
set(gcf,'pos',[20 100 pos(3)*2 pos(4)*1.2]);


a1 = subplot(1,2,1);
pos1 = get(gca,'pos');
h1 = plot(MSLICE(:,1),'color',cmap(1,:));
grid on;
set(gca,'clim',[0 size(MSLICE,2)]);
colorbar('location','south','fontsize',8);
text(0.5,0.25,'Time-Color Code','units','normalized',...
     'horizontalalignment','center','fontname','Comic Sans MS','fontweight','bold');
xlabel('Slice Number');
ylabel('Mean Voxel Value');
set(gca,'xlim',[0 size(MSLICE,1)]);
set(gca,'ylim',[0 4000]);
title(sprintf('%s %s:  Mean Voxel Value in Slice',Ses.name,grp.name))

a2 = subplot(1,2,2);
pos2 = get(gca,'pos');
h2 = plot(NSLICE(:,1),'color',cmap(1,:));
grid on;
set(gca,'clim',[0 size(MSLICE,2)]);
colorbar('location','north','fontsize',8);
text(0.5,0.8,'Time-Color Code','units','normalized',...
     'horizontalalignment','center','fontname','Comic Sans MS','fontweight','bold');
xlabel('Slice Number');
ylabel('Normalied Voxel Value');
set(gca,'xlim',[0 size(MSLICE,1)]);
set(gca,'ylim',[0.7 1.5]);
title(sprintf('%s %s:  Normalized Voxel Value in Slice',Ses.name,grp.name))

clear F;
for N = 1:size(MSLICE,2),
  set(h1,'ydata',MSLICE(:,N),'color',cmap(N,:));
  set(h2,'ydata',NSLICE(:,N),'color',cmap(N,:));
  % WHY THIS STUPID THING HAPPENS,
  set(a1,'pos',pos1);
  set(a2,'pos',pos2);
  drawnow;
  F(N) = getframe;
end


movie(F,10);



