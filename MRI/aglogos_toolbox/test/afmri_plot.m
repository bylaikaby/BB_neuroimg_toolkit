function afmri_plot(ses,ExpNo)

ses = goto(ses);
grp = getgrp(ses,ExpNo);
anap = getanap(ses,ExpNo);
par   = expgetpar(ses,ExpNo);

if 0
tcimg = sigload(ses,ExpNo,'tcImg');
else
pvpar = par.pvpar;
tcimg.session = ses.name;
tcimg.grpname = grp.name;
tcimg.ExpNo   = ExpNo;
tcimg.dir.dname = 'tcImg';
tcimg.usr     = [];
tcimg.dat     = pvread_2dseq(catfilename(ses,ExpNo,'2dseq'));
tcimg.ds      = [pvpar.res pvpar.slithk];
tcimg.dx      = pvpar.imgtr;
tcimg.centroid = mcentroid(tcimg.dat,tcimg.ds)';
end



spar  = getsortpars(ses,ExpNo);
stimT = spar.stim.tonset{1};
Pre_sec  = anap.gettrial.PreT;
Post_sec = anap.gettrial.PostT;
Pre_sec  = 0;
Post_sec = spar.stim.tlen{1}(1);


jawpo = par.evt.obs{1}.jawpo;
cent.dx   = tcimg.dx(1);
cent.dat  = tcimg.centroid';
cent.dat  = mcentroid(tcimg.dat(:,:,7,:),tcimg.ds)';



cent.dat(:,1) = cent.dat(:,1) - cent.dat(1,1);
cent.dat(:,2) = cent.dat(:,2) - cent.dat(1,2);
cent.dat(:,3) = cent.dat(:,3) - cent.dat(1,3);
cent.dat(:,4) = sqrt(sum(cent.dat.^2,2));

scanreco = ses.expp(ExpNo).scanreco;


figure;
subplot(2,1,1);
sub_plot(jawpo);
legend('jaw','po');
title(sprintf('JAWPO: %s exp%d scanreco=[%d %d]',ses.name,ExpNo,scanreco(1),scanreco(2)));
sub_plottrial(stimT,Pre_sec,Post_sec);
set(gca,'xlim',[0 size(tcimg.dat,4)*tcimg.dx(1)]);


subplot(2,1,2);
sub_plot(cent);
legend('x','y','z','dist');  ylabel('XYZ in mm');
minv = min(tcimg.ds);
line(get(gca,'xlim'), [minv minv],'color','k');
line(get(gca,'xlim'),-[minv minv],'color','k');
title(sprintf('CENTROID: %s exp%d scanreco=[%d %d]',ses.name,ExpNo,scanreco(1),scanreco(2)));
sub_plottrial(stimT,Pre_sec,Post_sec);
set(gca,'xlim',[0 size(tcimg.dat,4)*tcimg.dx(1)]);



return



function sub_plot(sig)
tmpt = [0:size(sig.dat,1)-1]*sig.dx;
plot(tmpt,sig.dat);
set(gca,'xlim',[tmpt(1) tmpt(end)]);
xlabel('Time in second');  ylabel('ADC');
grid on;
return


function sub_plottrial(stimT,Pre_sec,Post_sec)
hold on;
ylm = get(gca,'ylim');
hr = [];
for N = 1:length(stimT),
  ts = stimT{N}(1)-Pre_sec;
  te = stimT{N}(1)+Post_sec;
  tmppos = [ts ylm(1) te-ts ylm(2)-ylm(1)];
  hr(end+1) = rectangle('pos',tmppos,'facecolor',[0.9 0.8 0.8],'linestyle','none');
end
setback(hr);
set(gca,'layer','top');

return
