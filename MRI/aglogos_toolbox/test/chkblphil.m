
fprintf('loading blp...');
blp = sigload('s02nm1',1,'blp');


Fs   = 1/blp.dx;
NFFT = 2^nextpow2(1.0/blp.dx);


% compute spectrum of RAW, blp.dat
fprintf(' specgram of raw...');
clear Braw DAT;
DAT = blp.dat;
for iCh = size(DAT,2):-1:1,
  for iBand = size(DAT,3):-1:1,
    [tmpB,F,T] = specgram(DAT(:,iCh,iBand),NFFT,Fs);
    Braw(:,iCh,iBand) = mean(abs(tmpB),2);
  end
end





% compute envelops by Hilbert Transform
fprintf(' hilbert...');
DO_HIL = zeros(1,size(blp.dat,2));
if blp.info.lenvelop == 0,
  DO_HIL(blp.info.lBands) = 1;
end
if blp.info.menvelop == 0,
  DO_HIL(blp.info.mBands) = 1;
end

clear DAT;
for iCh = size(blp.dat,2):-1:1,
  for iBand = size(blp.dat,3):-1:1,
    if DO_HIL(iBand) == 1,
      DAT(:,iCh,iBand) = abs(hilbert(blp.dat(:,iCh,iBand)));
    else
      DAT(:,iCh,iBand) = blp.dat(:,iCh,iBand);
    end
  end
end

% compute spectrum of HIL
fprintf(' specgram of hil...');
clear Bhil;
for iCh = size(DAT,2):-1:1,
  for iBand = size(DAT,3):-1:1,
    [tmpB,F,T] = specgram(DAT(:,iCh,iBand),NFFT,1/blp.dx);
    Bhil(:,iCh,iBand) = mean(abs(tmpB),2);
  end
end





% plot RAW
figure('Name',sprintf('%s ExpNo=%d(%s):  blpRAW',blp.session,blp.ExpNo,blp.grpname));
mB = squeeze(mean(Braw,2));  % mean along channels
for iBand = 1:size(mB,2),
  info = blp.info.band{iBand};
  subplot(5,2,iBand);
  plot(F,mean(mB(:,iBand),2)); grid on; hold on;
  set(gca,'xlim',[0 140]);
  line([info{1}(1),info{1}(1)],get(gca,'ylim'),'color','r');
  line([info{1}(2),info{1}(2)],get(gca,'ylim'),'color','r');
  title(sprintf('[%d %d] %s-%s',info{1}(1),info{1}(2),info{2},info{3}));
  xlabel('Frequency in Hz'); ylabel('Amplitude');
  if DO_HIL(iBand) == 0,
    text(0.01,0.9,'HIL','units','normalized');
  else 
    text(0.01,0.9,'RAW','units','normalized');
  end
  line([Fs/2,Fs/2],get(gca,'ylim'),'color','g');
end



% plot HIL
figure('Name',sprintf('%s ExpNo=%d(%s):  blpHIL',blp.session,blp.ExpNo,blp.grpname));
mB = squeeze(mean(Bhil,2));  % mean along channels
for iBand = 1:size(mB,2),
  info = blp.info.band{iBand};
  subplot(5,2,iBand);
  plot(F,mean(mB(:,iBand),2)); grid on; hold on;
  set(gca,'xlim',[0 140]);
  line([info{1}(1),info{1}(1)],get(gca,'ylim'),'color','r');
  line([info{1}(2),info{1}(2)],get(gca,'ylim'),'color','r');
  title(sprintf('[%d %d] %s-%s',info{1}(1),info{1}(2),info{2},info{3}));
  xlabel('Frequency in Hz'); ylabel('Amplitude');
  text(0.01,0.9,'HIL','units','normalized');
  line([Fs/2,Fs/2],get(gca,'ylim'),'color','g');
end

fpritnf(' done.\n');