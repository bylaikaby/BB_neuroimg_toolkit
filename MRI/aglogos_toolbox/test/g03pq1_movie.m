
SESSION = 'g03pq1';
ExpNo   = 1;

ses = goto(SESSION);
grp = getgrp(ses,ExpNo);

pvpar = getpvpars(SESSION,ExpNo);


tcImg.session = ses.name;
tcImg.grpname = grp.name;
tcImg.ExpNo   = ExpNo;
tcImg.dir.dname = 'tcImg';
tcImg.usr     = [];
tcImg.dat     = pvread_2dseq(catfilename(ses,ExpNo,'2dseq'));
tcImg.ds      = [pvpar.ds pvpar.slithk];
tcImg.dx      = pvpar.imgtr;


spar = getsortpars(ses,ExpNo);


Pre_sec  = 4;
Post_sec = 14;

selpts = -round(Pre_sec/tcImg.dx):round(Post_sec/tcImg.dx);

stimT = spar.stim.tonset{1};
nomove = zeros(1,size(tcImg.dat,4));
for N = 1:length(stimT),
  tmpidx = selpts + round(stimT{N}(1)/tcImg.dx);
  tmpidx = tmpidx(find(tmpidx > 0 & tmpidx < length(nomove)));
  nomove(tmpidx) = 1;
end

moved = find(nomove == 0);

tcImg.dat(:,:,:,moved) = 0;


par = expgetpar(ses,ExpNo);
jawpo = par.evt.obs{1}.jawpo;
figure;
tmpt = [0:size(jawpo.dat,1)-1]*jawpo.dx;
plot(tmpt,jawpo.dat);
legend('jaw','po');
set(gca,'xlim',[tmpt(1) tmpt(end)]);
xlabel('Time in second');  ylabel('ADC');
scanreco = ses.expp(ExpNo).scanreco;
title(sprintf('%s exp%d scanreco=[%d %d]',ses.name,ExpNo,scanreco(1),scanreco(2)));
grid on;  hold on;
hr = [];  ylm = get(gca,'ylim');
for N = 1:length(stimT),
  tmpidx = selpts + round(stimT{N}(1)/tcImg.dx);
  tmpidx = tmpidx(find(tmpidx > 0 & tmpidx < length(nomove)));
  tmpidx = tmpidx * tcImg.dx;
  tmppos = [tmpidx(1) ylm(1)  tmpidx(end)-tmpidx(1)  ylm(2)-ylm(1)];
  hr(end+1) = rectangle('pos',tmppos,'facecolor',[0.9 0.8 0.8],'linestyle','none');
end
setback(hr);
set(gca,'layer','top');

fname = sprintf('%s_%03d_jawpo.fig',ses.name,ExpNo);
saveas(gcf,fullfile('y:/temp',fname));

tcimgmovie(tcImg);
fname = sprintf('%s_%03d_2dseq.fig',ses.name,ExpNo);
saveas(gcf,fullfile('y:/temp',fname));
