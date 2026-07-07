if ~exist('SESSION','var'),
  %SESSION = 's02nm1';
  SESSION = 'c98nm1';
  %SESSION = 'g97nm1';
end
if ~exist('ExpNo','var'),
  %ExpNo   = 38;
  %ExpNo   =  3;
  ExpNo   = 36;
  %ExpNo   = 31;
end

grp = getgrp(SESSION,ExpNo);

fprintf(' %s: %s ExpNo=%d(%s)\n',mfilename,SESSION,ExpNo,grp.name);
sigload(SESSION,ExpNo,'blp');


nyqf = (1.0/blp.dx)/2;


LFP_ENVELOPE        = 1;	% convert LFP to its envelope
FIT_MUA_TO_LFP_BAND = 1;	% fit MUA to LFP band frequency
SIG_LOWPASS         = 0;


for N = 1:length(blp.info.band),
  fprintf('%2d: [%4d %4d]: %6s %s\n',...
          N,blp.info.band{N}{1}(1),blp.info.band{N}{1}(2),...
          blp.info.band{N}{2},blp.info.band{N}{3});
end

if LFP_ENVELOPE > 0,
  fprintf(' %s: envelop',mfilename);
  nyqf = (1/blp.dx)/2;
  if blp.info.lenvelop == 0,
    for iBand = blp.info.lBands,
      fprintf('.');
      lim = blp.info.band{iBand}{1};
      [b,a] = butter(4,lim(2)/nyqf/2,'low');
      tmpdat = squeeze(abs(blp.dat(:,:,iBand)));
      blp.dat(:,:,iBand) = filtfilt(b,a,tmpdat);
    end
  end
  if blp.info.menvelop == 0,
    for iBand = blp.info.mBands,
      fprintf('.');
      lim = blp.info.band{iBand}{1};
      [b,a] = butter(4,lim(2)/nyqf/2,'low');
      tmpdat = squeeze(abs(blp.dat(:,:,iBand)));
      blp.dat(:,:,iBand) = filtfilt(b,a,tmpdat);
    end
  end
  fprintf(' done.\n');
end



if SIG_LOWPASS > 0,
  fprintf(' %s: lowpass(%.2fHz)',mfilename,SIG_LOWPASS);
  nyqf = (1/blp.dx)/2;
  [b,a] = butter(4,SIG_LOWPASS/nyqf,'low');
  for iBand = 1:size(blp.dat,3),
    blp.dat(:,:,iBand) = filtfilt(b,a,blp.dat(:,:,iBand));
  end
  fprintf(' done.\n');
end




Ses = goto(SESSION);
ELEINF = Ses.anap.confunc;
ELEINF.chan = blp.chan;

fprintf(' %s: corr',mfilename);
CORR = zeros(size(blp.dat,3),size(blp.dat,2),size(blp.dat,2));
DIST = zeros(size(blp.dat,2),size(blp.dat,2));
DIST(:) = -1;
for iCh = 1:size(blp.dat,2),
  fprintf('.');
  [ix,iy] = ind2sub(size(ELEINF.eleconfig),ELEINF.chan(iCh));
  for jCh = iCh:size(blp.dat,2),
    [jx,jy] = ind2sub(size(ELEINF.eleconfig),ELEINF.chan(jCh));
    dx = (jx - ix) * ELEINF.eledist;
    dy = (jy - iy) * ELEINF.eledist;
    DIST(iCh,jCh) = sqrt(dx^2 + dy^2);
    for iBand = 1:size(CORR,1),
      CORR(iBand,iCh,jCh) = corr(blp.dat(:,iCh,iBand),blp.dat(:,jCh,iBand));
    end
  end
end
fprintf(' done.\n');

bandLabel = {};
for iBand = 1:size(CORR,1),
  band = blp.info.band{iBand};
  bandLabel{iBand} = sprintf('%s [%d-%d]',band{2},band{1}(1),band{1}(2));
end

tmpcorr = reshape(CORR,[size(CORR,1),size(CORR,2)*size(CORR,3)]);
tmpdist = reshape(DIST,[1,size(DIST,1)*size(DIST,2)]);

udist = sort(unique(tmpdist));
udist = udist(find(udist >= 0));

tmptitle = sprintf('%s ExpNo=%d(%s) blp-corr',SESSION,ExpNo,blp.grp.name);

COL = 'rgbcmykrgbcmyk';
figure('Name',tmptitle);
for iBand = 1:size(tmpcorr,1),
  tmpdat = tmpcorr(iBand,:);
  for iDist = 1:length(udist),
    tmp = tmpdat(find(tmpdist == udist(iDist)));
    tmpzm(iDist) = mean(tmp);
    tmpzs(iDist) = std(tmp);
  end
  if iBand <= 3,
    plot3(udist,ones(1,length(udist))*iBand,tmpzm,'color',COL(iBand),'linewidth',2,...
          'marker','o','markerfacecolor',COL(iBand));
  else
    plot3(udist,ones(1,length(udist))*iBand,tmpzm,'color',COL(iBand),'linewidth',2);
  end
  hold on;
end
title(tmptitle);
xlabel('Distance in mm');
set(gca,'zlim',[0 1]);
set(gca,'ytick',1:size(tmpcorr,1),'yticklabel',bandLabel);
grid on;



return;
figure;
for iBand = 1:size(tmpcorr,1),
end



