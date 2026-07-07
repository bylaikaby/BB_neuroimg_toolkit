function showcodeco
%SHOWCODECO - Demonstrate LTI-systems analysis
% SHOWCODECO - Computes and demonstrate LTI-systems analysis
% NKL 20.07.03
  
SESSION = 'n03qv1'
hrfGrpName = 'spont';
tstGrpName = 'polarflash';

Ses = goto(SESSION);
load(strcat(tstGrpName,'.mat'),'pLfpH','pMua','xcor');
pNeu = pLfpH;
pNeu.dir.dname = 'pNeu';
pNeu.dat = 0.5 * (pLfpH.dat+pMua.dat);

load(strcat(hrfGrpName,'.mat'),'hrf');
grp = getgrpbyname(Ses,tstGrpName);
filename = catfilename(Ses,grp.exps(1));

sig1 = msigdeconv(xcor{1},hrf);      % optimal filtering
sig2 = msigdeconv(xcor{2},hrf);      % optimal filtering

L=size(xcor{1}.dat,1);
t = [0:L-1]*xcor{1}.dx;
pNeu.dat = pNeu.dat(1:L,:);
sig1.dat = sig1.dat(1:L,:);
sig1 = tosdu(sig1);

mfigure([100 80 600 800]);
subplot(3,1,1);
dsphrf(hrf);
set(gca,'xlim',[0 100]);

subplot(3,1,2);
hd(1)=plot(t,mean(pNeu.dat,2),'k','linewidth',2);
hold on;
hd(2)=plot(t,sig1.dat,'color',[.6 .6 .6]);
legend(hd,'Neural','Deconvolved MRI');
title('Deconvolution following optimal Wiener filtering');
xlabel('Number of Images');
ylabel('Arbitrary Units');

subplot(3,1,3);
[ax,f1,f2]=plotyy(t,mean(pNeu.dat,2),t,mean(xcor{1}.dat,2));
set(f1,'color','k');
set(f2,'color','r','linewidth',1);


%%% CONVOLUTION
mfigure([100 80 600 800]);
subplot(3,1,1);
dsphrf(hrf);
set(gca,'xlim',[0 100]);

subplot(3,1,2);
hd(1)=plot(t,mean(pNeu.dat,2),'r','linewidth',2);

hrfdat = hnanmean(hrf.dat,2);
for N=1:length(xcor),
  Sig = xcor{N};
  val = hnanmean(Sig.dat,2);
  val = conv(val,hrfdat);
  val = val(1:size(Sig.dat,1));
end;
convNeu=pNeu;
convNeu.dat = val;
convNeu = tosdu(convNeu);

hold on;
hd(2)=plot(t,val,'k');
legend(hd,'Neural','Deconvolved MRI');
title('Deconvolution following optimal Wiener filtering');
xlabel('Number of Images');
ylabel('Arbitrary Units');

subplot(3,1,3);
% [ax,f1,f2]=plotyy(t,mean(pNeu.dat,2),t,mean(xcor{1}.dat,2));
[ax,f1,f2]=plotyy(t,mean(pNeu.dat,2),t,convNeu.dat);
axes(ax(2));
if 0,
hold on;
plot(t,mean(convNeu.dat,2),'linewidth',2);
end;
set(f1,'color','k');
set(f2,'color','r','linewidth',1);
