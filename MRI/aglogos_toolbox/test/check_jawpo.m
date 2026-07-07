
p = expgetpar('b04bx1',22);
jawpo = p.evt.obs{1}.jawpo;

jawpo.dat = double(jawpo.dat);

%jawpo = sigfiltfilt(jawpo,[0.02 25],'bandpass');

%spc = sigspc(jawpo,1,0.5);


jawpo.dat = zscore(jawpo.dat,[],1);
figure;
plot(abs(jawpo.dat));


