%COROSION - Compute charge-density for different impedance/current combinations
%
% Q = Charge in uC (micro-coulombs)
% C = Charge Density (uC/cm^2)
% A = Electrodetip Area (cm^2)
% t = pulse duration (Sec)
% I = current (A)

clear all; close all;

% CURRENTS AND IMPEDANCES USED
% microA and KOhms
eledat = [1600	100;...
          1600	100;...
          1400	33;...
          1400	60;...
          1400	30;...
          1800	40;...
          800     50;...
          800     50;...
          800     40;...
          1700	450;...
          1700	125;...
          1700	65;...
          1000	80;...
          1000	200;...
          500     80;...
          1000	25;...
          1000	50;...
          500     45;...
          1000	40;...
          750     140;...
          1000	150;...
          750     70;...
          750     50;...
          750     160;...
          1000	67;...
          1000	105;...
          1000	80;...
          1000	80;...
          1000	100;...
          1000	80;...
          1000	90;...
          1000	50;...
          1000	40;...
          1000	80;...
          1000	240;...
          1000	190;...
          1000	140;...
          1000	120;...
          1000	140;...
          750     200;...
          1000	280;...
          1000	130;...
          1000	140;...
          1000	140;...
          1000	120;...
          1000	170;...
          1000	140;...
          1000	140];

dat(:,1) = eledat(:,2);
dat(:,2) = eledat(:,1);

t=200*10^-6;
I=[1:1:2000]*10^-6;  % In Amperes
E=[0.001:0.001:1];   % MegaOhms

clear C
% to spead up things...
f = t/0.0003 * E.^1.4;
for N = length(I):-1:1,
  C(N,:) = I(N) * f;
end

% Amps * Ohms  (Amps * MOhms)
% to go from C to mC we multiply w/ 1000 and to go to uC we multiply 10^6
% to go from 1/mm^2 to 1/cm^2 w/ multiply with 100
CC=log10(C*10^6*100);  % 1000*100 is Andreas' correction (last 1000 for uC)

if 0,
mfigure([10 100 600 500]);
set(gcf,'color',[0 0 .2]);
set(gcf,'DefaultAxesfontsize', 11);
set(gcf,'DefaultAxesfontweight','normal');
drawnow;

surf(CC);
shading interp;
set(gca,'xscale','log')
set(gca,'yscale','log')
view(0, -90);
drawnow;
set(gca,'xcolor','w','ycolor','w');
yticks=get(gca,'ytick');
xticks=get(gca,'xtick');
set(gca,'FontSize',11);
set(gca,'xticklabel',[xticks]);
set(gca,'yticklabel',[yticks]);
%xlabel('Impedance in kOhms');
%ylabel('Current in microA');
axis off
view(0, -90);
savgca = gca;
end;

if 0,
% nh = axes('position',get(savegca,'position'));
axis([1 1000 1 2000]);
hold on;
[N K]=find(CC>log10(290)&CC<log10(310));			% ca 300 uC/cm2
plot3(K,N,ones(length(N),1)*5,'k','linewidth',2);
[N K]=find(CC>log10(3900)&CC<log10(4100));			% ca 4000 uC/cm2
plot3(K,N,ones(length(N),1)*5,'k','linewidth',2);
set(savgca,'xcolor','y','ycolor','y');
set(savgca,'xscale','log')
set(savgca,'yscale','log')

clear C E I CC
t=200*10^-6;
% I=[1:1:2000]*10^-6;  % In Amperes
% E=[0.001:0.001:1];   % MegaOhms

E=dat(:,1)*10^-3;  % In MOhms from KOhms
I=dat(:,2)*10^-6;  % In Amperes from MicroA

% to spead up things...
f = t/0.0003 * E.^1.4;
C = I .* f *10^6*100;
CC=log10(C); % To MicroC and 1/cm2
CRIT = log10(4100);

for N=1:length(CC),
  if CC(N) <= CRIT,
    plot(dat(N,1),dat(N,2),'marker','s','markerfacecolor','k',...
         'markeredgecolor','g','linestyle','none','markersize',12);
  else
    plot(dat(N,1),dat(N,2),'marker','s','markerfacecolor','k',...
         'markeredgecolor','r','linestyle','none','markersize',6);
  end;    
end;

h = colorbar;
axes(h);
set(h,'xcolor','w','ycolor','w');
set(h,'FontSize',11);
yticks = get(h,'ytick');
set(h,'yticklabel',[10.^yticks]);
%ylabel('Charge Density in microCoulomb','color','w','FontSize',11);
end;


if 1,
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %    dat = [100 1600 KOhm uA
  %           150 1600 KOhm uA
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  t=200*10^-6;          % In seconds
  E=dat(:,1)*10^-3;     % In MOhms from KOhms
  I=dat(:,2)*10^-6;     % In Amperes from MicroA
  
  C = I .* (t/0.0003 * E.^1.4);
  C = C * 10^6 * 100;
  C = C(find(C<4100));
  
  [n,x] = hist(C(:),15);
  
  mfigure([20 200 600 550]);
  set(gcf,'color',[0 0 .2]);
  set(gcf,'DefaultAxesfontsize', 11);
  set(gcf,'DefaultAxesfontweight','normal');

  stem(x,n,'linewidth',2.5,'color','c','markerfacecolor','c','markersize',10);
  set(gca,'xlim',[0 4200]);
  set(gca,'ylim',[0 10]);
  set(gca,'color',[0 0 .2],'xcolor','w','ycolor','w');
  xlabel('Charge Density','FontSize',14);
  ylabel('Scores','FontSize',14);
end;


