Ses   = goto('D04Mf1');
ExpNo = 1;


spar = getsortpars(Ses,ExpNo);

Cln = sigload(Ses,ExpNo,'Cln');
tCln = sigsort(Cln,spar.trial);

figure(10);




blp = expgetblp(Ses,ExpNo);
tblp = sigsort(blp,spar.trial);

figure(10);
tmpdat = squeeze(tblp{2}.dat(:,1,end,:));
t = [0:size(tmpdat,1)-1]*tblp{1}.dx;
tmpcln = squeeze(tCln{2}.dat);
tcln = [0:size(tmpcln,1)-1]*tCln{1}.dx;
for N=1:5,
  subplot(5,1,N);
  cla;
  plot(tcln,tmpcln(:,N));
  line([10 10],get(gca,'ylim'),'color','k');
  set(gca,'xlim',[8 12]);
  grid on;
end
for N=1:5,
  subplot(5,1,N);
  hold on;
  plot(t,tmpdat(:,N)*400,'r');
  %line([10 10],get(gca,'ylim'),'color','r');
  set(gca,'xlim',[8 12]);
  grid on;
end



figure;
t = [0:size(Cln.dat,1)-1]*Cln.dx;
plot(t,Cln.dat(:,1));
hold on;
t = [0:size(blp.dat,1)-1]*blp.dx;
plot(t,blp.dat(:,1,end)*400,'r');
grid on;
