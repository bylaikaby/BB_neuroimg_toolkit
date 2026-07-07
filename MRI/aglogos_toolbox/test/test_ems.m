


%dgzfile = '//Win49/N/DataNeuro/B03.DP1/b03dp1_001.dgz';
%adffile = '//Win49/N/DataNeuro/B03.DP1/b03dp1_001.adfw';

dgzfile = '//wks6/guest/D02.HO1/D02HO1_04062007_s14.dgz';
adffile = '//wks6/guest/D02.HO1/D02HO1_04062007_s14.adfw';



DG = dg_read(dgzfile);


% EYE MOVEMENT
em.dx = DG.ems{1}{1}(1)/1000;  % in sec
em.dat = [];
em.dat(:,1) = DG.ems{1}{2}(:);  % horizontal
em.dat(:,2) = DG.ems{1}{3}(:);  % vertial


% JAWPO by dgz
jawpo.dx = DG.ems{1}{4}(1)/1000;  % in sec
jawpo.dat = [];
jawpo.dat(:,1) = DG.ems{1}{5}(:);  % jaw
jawpo.dat(:,2) = DG.ems{1}{8}(:);  % po

if 1,
  em.dx = em.dx*2;
  em.dat = em.dat(1:round(size(em.dat,1)/2),:);
  jawpo.dx = jawpo.dx*2;
  jawpo.dat = jawpo.dat(1:round(size(jawpo.dat,1)/2),:);
  
end



% JAWPO by adf
[tmpwv1 npts sampt] = adf_read(adffile,0,4-1);
[tmpwv2 npts sampt] = adf_read(adffile,0,5-1);

jawpo2.dx = 0.05;  % in sec
jawpo2.dat = [];
jawpo2.dat(:,1) = tmpwv1(:);  % jaw
jawpo2.dat(:,2) = tmpwv2(:);  % po
% downsample
[p,q] = rat(sampt/1000/jawpo2.dx,0.0001);  % sampt as msec
jawpo2.dat = resample(jawpo2.dat,p,q);




figure;
h1 = subplot(3,1,1);
t = [0:size(em.dat,1)-1]*em.dx;
plot(t,em.dat);
title('EYE');  legend('horizontal','vertical'); grid on;
set(gca,'ylim',[-2500 2500]);
xlabel('Time in seconds');  ylabel('ADC Units');
hold on;
line([0 max(t)],[-2048 -2048],'color','r');
line([0 max(t)],[2048 2048],'color','r');
text(0.01,0.1,strrep(dgzfile,'_','\_'),'units','normalized','fontweight','bold');


h2 = subplot(3,1,2);
t = [0:size(jawpo.dat,1)-1]*jawpo.dx;
plot(t,jawpo.dat);
title('JAW-PO DGZ');  legend('jaw','po');  grid on;
set(gca,'ylim',[-2500 2500]);
xlabel('Time in seconds');  ylabel('ADC Units');
line([0 max(t)],[-2048 -2048],'color','r');
line([0 max(t)],[2048 2048],'color','r');
text(0.01,0.1,strrep(dgzfile,'_','\_'),'units','normalized','fontweight','bold');


h3 = subplot(3,1,3);
t = [0:size(jawpo2.dat,1)-1]*jawpo2.dx;
plot(t,jawpo2.dat);
title('JAW-PO ADFW');  legend('jaw','po');  grid on;
set(gca,'ylim',[-35000 35000]);
xlabel('Time in seconds');  ylabel('ADC Units');
line([0 max(t)],[-32768 -32768],'color','r');
line([0 max(t)],[32768 32768],'color','r');
text(0.01,0.1,strrep(adffile,'_','\_'),'units','normalized','fontweight','bold');


%set([h1 h2 h3],'xlim',[0 size(jawpo2.dat,1)*jawpo2.dx]);





figure;
plot([0:size(jawpo2.dat,1)-1]*jawpo2.dx,jawpo2.dat(:,1));
hold on;

plot([0:size(jawpo.dat,1)-1]*jawpo.dx,jawpo.dat(:,1)*1000,'r');
