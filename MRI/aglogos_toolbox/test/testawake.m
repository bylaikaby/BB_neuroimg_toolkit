

% GOOD SESSION
SES = 'D02HQ1';  EXP = 1;
% BAD SESSION
SES = 'D02JU1';  EXP = 1;


SIG = sigload(SES,EXP,'tcImg');
SIG.dir.dname = 'roiTs';
SIG.ana = squeeze(mean(SIG.dat(:,:,:,1:20),4));
SIG.dat = permute(SIG.dat,[4 1 2 3]);
tmpsz = size(SIG.dat);
SIG.dat = reshape(SIG.dat,[tmpsz(1) prod(tmpsz(2:end))]);
[ix iy iz] = ind2sub(tmpsz(2:end), 1:size(SIG.dat,2));
SIG.coords = [ix(:) iy(:) iz(:)];
clear tmpsz ix iy iz;

ANAP = getanap(SES,EXP);
ANAP.gettrial.Xmethod = 'percent';
ANAP.gettrial.Average = 0;
ANAP.gettrial.CheckCentroid = 0;

noavg = gettrial(SIG,ANAP);
if iscell(noavg),  noavg = noavg{1};  end
if iscell(noavg),  noavg = noavg{1};  end

IMGSZ = size(noavg.ana);


maxv = max(abs(noavg.dat(:)));
maxv = 5;
idx = sub2ind(IMGSZ,noavg.coords(:,1),noavg.coords(:,2),noavg.coords(:,3));
figure; showfig;
tmpx = [1:IMGSZ(1)*IMGSZ(3)];
tmpy = [1:IMGSZ(2)];
for N=1:size(noavg.dat,3),
  tmpdat = mean(noavg.dat(:,:,N),1);
  %tmpdat = std(noavg.dat(:,:,N),[],1);
  tmpimg = zeros(IMGSZ);
  tmpimg(idx) = tmpdat(:);
  tmpimg = permute(tmpimg,[2 1 3]);
  tmpsz  = size(tmpimg);
  tmpimg = reshape(tmpimg,[tmpsz(1) prod(tmpsz(2:end))]);
  subplot(size(noavg.dat,3),1,N);
  imagesc(tmpx,tmpy,tmpimg);
  tmpmax = max(abs(tmpimg(:)));
  %set(gca,'clim',[-tmpmax tmpmax]*0.5);
  
  %set(gca,'clim',[-maxv maxv]);
  set(gca,'clim',[-30 30]);
  set(gca,'xlim',[0.5 IMGSZ(1)*IMGSZ(3)+0.5]);
  set(gca,'xticklabel',[],'yticklabel',[]);
  %title(sprintf('Trial %d',N));
  ylabel(sprintf('T %d',N),'fontsize',6);
end


figure; showfig;
COLORS = lines(size(noavg.dat,3));
tmplabel = {};
for N=1:size(noavg.dat,3),
  tmpdat = mean(noavg.dat(:,:,N),2);
  %subplot(size(noavg.dat,3),1,N);
  plot(tmpdat,'color',COLORS(N,:));
  hold on;  grid on;
  %ylabel(sprintf('T %d',N),'fontsize',6);
  tmplabel{N} = sprintf('T %d',N);
end
legend(tmplabel,'location','EastOutside');


tmpdat = squeeze(mean(noavg.dat,1));
ccR = zeros(size(noavg.dat,3));
ccP = ones(size(noavg.dat,3));
for N = 1:size(noavg.dat,3)
  for K = N:size(noavg.dat,3),
    [tmpr tmpp] = corrcoef(tmpdat(:,N),tmpdat(:,K));
    ccR(N,K) = tmpr(1,2);
    ccR(K,N) = ccR(N,K);
    ccP(N,K) = tmpp(1,2);
    ccP(K,N) = ccP(N,K);
  end
end
figure; showfig; imagesc(ccR); set(gca,'clim',[-1 1]); colorbar;


ccRavg = zeros(1,size(ccR,1));
for N = 1:size(ccR,1),
  tmpdat = ccR(:,N);
  tmpdat(N) = NaN;
  ccRavg(N) = nanmean(tmpdat);
end



model = expmkmodel(SES,EXP,'fhemo');
model = model{1};
for N=1:size(noavg.dat,3),
  [tmpr tmpp] = mcor(model.dat(:),noavg.dat(:,:,N));
  imgR{N} = zeros(IMGSZ);
  imgP{N} = ones(IMGSZ);
  imgR{N}(idx) = tmpr(:);
  imgP{N}(idx) = tmpp(:);
end


figure; showfig;
tmpx = [1:IMGSZ(1)*IMGSZ(3)];
tmpy = [1:IMGSZ(2)];
for N=1:size(noavg.dat,3),
  tmpimg = imgR{N};
  tmpimg = permute(tmpimg,[2 1 3]);
  tmpsz  = size(tmpimg);
  tmpimg = reshape(tmpimg,[tmpsz(1) prod(tmpsz(2:end))]);
  subplot(size(noavg.dat,3),1,N);
  imagesc(tmpx,tmpy,tmpimg);
  set(gca,'clim',[-1 1]);
  set(gca,'xlim',[0.5 IMGSZ(1)*IMGSZ(3)+0.5]);
  set(gca,'xticklabel',[],'yticklabel',[]);
  %title(sprintf('Trial %d',N));
  ylabel(sprintf('T %d',N),'fontsize',6);
end


ccRR = zeros(size(noavg.dat,3));
for N=1:size(noavg.dat,3),
  for K=N:size(noavg.dat,3),
    [tmpr tmpp] = corrcoef(imgR{N}(:),imgR{K}(:));
    ccRR(N,K) = tmpr(1,2);
    ccRR(K,N) = ccRR(N,K);
  end
end
figure; showfig; imagesc(ccRR); set(gca,'clim',[-1 1]); colorbar;

ccRRavg = zeros(1,size(ccRR,1));
for N = 1:size(ccRR,1),
  tmpdat = ccRR(:,N);
  tmpdat(N) = NaN;
  ccRRavg(N) = nanmean(tmpdat);
end
