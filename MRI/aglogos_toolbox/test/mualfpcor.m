function testmualfpcor(TWINDOW_SEC)

% analysis options
%TWINDOW_SEC = 0.4;			% time window in seconds
%TSHIFT_SEC  = 0.1;			% shit of window in seconds

%TWINDOW_SEC = 10.0;			% time window in seconds
%TSHIFT_SEC  = 2.0;			% shit of window in seconds
TSHIFT_SEC  = TWINDOW_SEC * 0.2;

LFP_ENVELOPE        = 1;	% convert LFP to its envelope
FIT_MUA_TO_LFP_BAND = 1;	% fit MUA to LFP band frequency



blp = sigload('s02nm1',9,'blp');
%blp = sigload('s02nm1',38,'blp');


% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% I DON'T NEED ALL TIME POINTS FOR TESTING
%blp.dat = blp.dat(1:round(60/blp.dx),:,:);
% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!



for N = 1:length(blp.info.band),
  fprintf('%2d: [%4d %4d]: %6s %s\n',...
          N,blp.info.band{N}{1}(1),blp.info.band{N}{1}(2),...
          blp.info.band{N}{2},blp.info.band{N}{3});
end

BLPDAT = blp.dat;


if LFP_ENVELOPE > 0,
  fprintf(' %s: envelop',mfilename);
  nyqf = (1/blp.dx)/2;
  if blp.info.lenvelop == 0,
    for iBand = blp.info.lBands,
      fprintf('.');
      lim = blp.info.band{iBand}{1};
      [b,a] = butter(4,lim(2)/nyqf,'low');
      tmpdat = squeeze(abs(blp.dat(:,:,iBand)));
      BLPDAT(:,:,iBand) = filtfilt(b,a,tmpdat);
    end
  end
  if blp.info.menvelop == 0,
    for iBand = blp.info.mBands,
      fprintf('.');
      lim = blp.info.band{iBand}{1};
      [b,a] = butter(4,lim(2)/nyqf,'low');
      tmpdat = squeeze(abs(blp.dat(:,:,iBand)));
      BLPDAT(:,:,iBand) = filtfilt(b,a,tmpdat);
    end
  end
  fprintf(' done.\n');
end


TINDEX = 1:round(TWINDOW_SEC/blp.dx);
TSHIFT = round(TSHIFT_SEC/blp.dx);
NT     = floor((size(BLPDAT,1)-length(TINDEX))/TSHIFT)+1;


CORMUA = zeros(NT,size(BLPDAT,2),size(BLPDAT,3)-1);
CORMUA2 = zeros(size(BLPDAT,2),size(BLPDAT,3)-1);
BLPMUA = zeros(size(BLPDAT,1),size(BLPDAT,2),size(BLPDAT,3)-1);


if FIT_MUA_TO_LFP_BAND,
  fprintf(' %s: fit-band',mfilename);
  nyqf = (1/blp.dx)/2;
  for iBand = 1:size(CORMUA,3),
    fprintf('.');
    lim = blp.info.band{iBand}{1};
    if lim(2) < nyqf,
      [b,a] = butter(4,lim(2)/nyqf,'low');
      tmpmua = squeeze(blp.dat(:,:,end));
      BLPMUA(:,:,iBand) = filtfilt(b,a,tmpmua);
    else
      BLPMUA(:,:,iBand) = blp.dat(:,:,end);
    end
  end
  fprintf(' done.\n');
else
  for iBand = 1:size(CORMUA,3),
    BLPMUA(:,:,iBand) = blp.dat(:,:,end);
  end
end


fprintf(' %s: norm',mfilename);
for iCh = 1:size(BLPDAT,2),
  fprintf('.');
  for iBand = 1:size(BLPDAT,3),
    m = mean(BLPDAT(:,iCh,iBand),1);
    s = std(BLPDAT(:,iCh,iBand),[],1);
    BLPDAT(:,iCh,iBand) = (BLPDAT(:,iCh,iBand) - m) / s;
  end
  for iBand = 1:size(BLPMUA,3),
    m = mean(BLPMUA(:,iCh,iBand),1);
    s = std(BLPMUA(:,iCh,iBand),[],1);
    BLPMUA(:,iCh,iBand) = (BLPMUA(:,iCh,iBand) - m) / s;
  end
end
fprintf(' done.\n');




fprintf(' %s: corr',mfilename);
for iCh = 1:size(CORMUA,2),
  fprintf('.'); 
  for iBand = 1:size(CORMUA,3),
    tmpmua = squeeze(BLPMUA(:,iCh,iBand));
    tmplfp = squeeze(BLPDAT(:,iCh,iBand));
    for iT = 1:NT,
      tmpt = TINDEX + TSHIFT*(iT-1);
      CORMUA(iT,iCh,iBand) = corr(tmpmua(tmpt),tmplfp(tmpt));
    end
    CORMUA2(iCh,iBand) = corr(tmpmua,tmplfp);
  end
end

fprintf(' done.\n');





matfile = sprintf('%s_%s_%03d_%03d.mat',mfilename,blp.session,blp.ExpNo,TWINDOW_SEC*1000);
save(matfile,'BLPDAT','BLPMUA','CORMUA','CORMUA2','TWINDOW_SEC','TSHIFT_SEC');



return;




iCh = 1;


%for iCh = 1:size(BLPMUA,2),
for iCh = [1 8],
  tmptxt = sprintf('%s exp=%d(%s) twin=%.2f tshift=%.2f',...
                   blp.session,blp.ExpNo(1),blp.grpname,...
                   TWINDOW_SEC, TSHIFT_SEC);
  figure('Name',tmptxt);
  tmua = [0:size(BLPDAT,1)-1]*blp.dx;
  %tcor = [0:size(CORMUA,1)-1]*blp.dx*TSHIFT + blp.dx*length(TINDEX)/2;
  tcor = [0:size(CORMUA,1)-1]*blp.dx*TSHIFT + blp.dx*length(TINDEX);
  %tcor = [0:size(CORMUA,1)-1]*blp.dx*TSHIFT;
  for N=1:9,
    band = blp.info.band{N};
  
    tmpmua = BLPMUA(:,iCh,N);
    tmpmua = tmpmua / max(tmpmua(1:100)) * 0.2;
  
    tmplfp = BLPDAT(:,iCh,N);
    tmplfp = tmplfp / max(tmplfp(1:100)) * 0.2;
  
    subplot(9,1,N);
    plot(tmua,tmplfp,'b');
    hold on; grid on;
    plot(tmua,tmpmua,'r');
    plot(tcor,CORMUA(:,iCh,N),'k','linewidth',2);
    set(gca,'xlim',[0 max(tmua)],'ylim',[-.8 .8]);
    tmptxt = sprintf('[%d %d] %s R=%.3f/%.3f',band{1}(1),band{1}(2),band{2},...
                     mean(CORMUA(:,iCh,N),1),CORMUA2(iCh,N));
    text(0,0.1,tmptxt,'units','normalized');
    set(gca,'xlim',[20 60]);
  end

  h = findobj(gcf,'type','axes');
end
