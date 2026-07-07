
%SESSION = 's02nm1';
%EXPS    = getexps(SESSION);

SESSION = 'c98nm1';
EXPS    = getexps(SESSION,'movie1');


TWINVAR = [0.1 0.2 0.5 1.0 2.0 5.0 10.0 20.0 50.0];

% compute t-window corr.
if 1,
  for iExp = 1:length(EXPS),
    ExpNo = EXPS(iExp);
    fprintf('%s %s: %s ExpNo=%d =====================================================\n',...
            gettimestring,mfilename,SESSION,ExpNo);
    for N = 1:length(TWINVAR),
      testmualfpcor(SESSION,ExpNo,TWINVAR(N));
    end
  end
end



return


% plot results.

MATFILES = {};
for N = 1:length(TWINVAR),
  MATFILES{N} = sprintf('testmualfpcor_%s_%03d_%07d.mat',...
                        lower(SESSION),ExpNo,TWINVAR(N)*1000);
end


CORVAL = [];
TWIN   = [];
for N = 1:length(MATFILES),
  load(MATFILES{N});
  CORMUA = mean(CORMUA,1);
  CORVAL(:,:,N) = CORMUA;
  TWIN(N) = TWINDOW_SEC;
end

CORVAL = CORVAL(:,1:7,:);

NORMALIZE_CORR = 0;


%  1: [   0    4]:  Delta LFP
%  2: [   4    8]:  Theta LFP
%  3: [   8   14]:  Alpha LFP
%  4: [  14   24]:   Beta LFP
%  5: [  24   35]: GammaL LFP
%  6: [  35   80]: GammaM LFP
%  7: [  80  100]: GammaH LFP

bandLabel = {};
for iBand = 1:size(CORVAL,2),
  band = INFO.band{iBand};
  bandLabel{iBand} = sprintf('%s [%d-%d]',band{2},band{1}(1),band{1}(2));
end



COL = 'rgbcmykrgbcmyk';
%for iCh = 1:size(CORVAL,1);
%  tmpcor = squeeze(CORVAL(iCh,:,:));
  tmpcor = squeeze(mean(CORVAL,1));
  if NORMALIZE_CORR,
    for iBand = 1:size(tmpcor,1),
      tmpcor(iBand,:) = tmpcor(iBand,:) / CORMUA2(iCh,iBand);
    end
  end  
  %figure('Name',sprintf('iCh = %d',iCh));
  figure;
  subplot(1,2,1);
  surf(TWIN,1:size(CORVAL,2),tmpcor);
  shading interp;
  xlabel('Size of Time Window (sec)');
  ylabel('LFP Bands');
  set(gca,'xscale','log');
  if NORMALIZE_CORR,
    zlabel('Normalized Corr. between env-bpLFP and lp-envMUA');
    set(gca,'clim',[-1 1]);
    set(gca,'zlim',[-1 1]);
  else
    zlabel('Corr. between env-bpLFP and lp-envMUA');
  end
  set(gca,'ytick',1:size(CORVAL,2),'yticklabel',bandLabel);
  set(gca,'zlim',[-0.1 0.25]);
  
  subplot(1,2,2);
  x = zeros(1,size(tmpcor,2));  x = TWIN;
  y = zeros(1,size(tmpcor,2));
  for iBand = 1:size(tmpcor,1),
    y(:) = iBand;
    plot3(x,y,tmpcor(iBand,:),'color',COL(iBand),'linewidth',2);
    hold on;
  end
  x = zeros(1,size(tmpcor,1));
  y = 1:size(CORVAL,2);
  x(:) = max(TWIN);
  %plot3(x,y,squeeze(CORMUA2(iCh,1:size(CORVAL,2))),'color','k','linewidth',4);
  plot3(x,y,squeeze(mean(CORMUA2(:,1:size(CORVAL,2)),1)),'color','k','linewidth',4);
  
  grid on;
  xlabel('Size of Time Window (sec)');
  ylabel('LFP Bands');
  set(gca,'xscale','log');
  if NORMALIZE_CORR,
    zlabel('Normalized Corr. between env-bpLFP and lp-envMUA');
    set(gca,'clim',[-1 1]);
    set(gca,'zlim',[-1 1]);
  else
    zlabel('Corr. between env-bpLFP and lp-envMUA');
  end
  set(gca,'ytick',1:size(CORVAL,2),'yticklabel',bandLabel);
  set(gca,'zlim',[-0.1 0.25]);
  
%end

