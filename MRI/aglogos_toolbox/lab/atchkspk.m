
if 1,

  Cln = atgetcln('d98at2',1);
  atSpkt = atgetspk('d98at2',1);


  [b,a] = butter(4,500/(1/Cln.dx/2),'high');
  Cln.dat = filtfilt(b,a,Cln.dat);


  T_LIM = 10;

  CLNT = [1:size(Cln.dat,1)]*Cln.dx;

  Tsel = find(CLNT <= T_LIM);

  for N = 1:length(atSpkt.times),
    figure('Name',sprintf('N:%d, Ch=%d',N,atSpkt.chan(N)));
    spkt = atSpkt.times{N} * atSpkt.dt;
    spkt = spkt(find(spkt < T_LIM));
    plot(CLNT(Tsel),Cln.dat(Tsel,:));
    hold on; grid on;
    for K = 1:length(spkt),
      line([spkt(K),spkt(K)],[0 1000],'color','k');
    end
  end


else
  fname = 'E:\DataNeuro\D98.AT2\2002-9-5_13-45-30\CSC13.Ncs';
  tst = 8194340;
  ted = tst + 20*1000;

  % waveform
  [wvdata,cr] = read_cr(fname,'tstart',tst,'tend',ted,'verbose');

  [b,a] = butter(4,500/(wvdata.sample_freq/2),'high');
  wvdata.v = filtfilt(b,a,wvdata.v);

  % spikes as res(X)
  load('E:\DataNeuro\D98.AT2\2002-9-5_13-45-30\spikes.mat');

  %for N = 1:length(res),
  for N =16:20,
    figure('Name',sprintf('res=%d, tst=%d, ted=%d',N,tst,ted));
    plot(wvdata.t, wvdata.v);
    hold on; grid on;
    tmpspk = res(N).spikes;
    tmpspk = tmpspk(find(tmpspk > tst & tmpspk < ted));
    for T = 1:length(tmpspk),
      line([tmpspk(T),tmpspk(T)],[0 1000],'color','r');
    end
    set(gca,'xlim',[min(wvdata.t(:)),max(wvdata.t(:))]);
  end
  
end
