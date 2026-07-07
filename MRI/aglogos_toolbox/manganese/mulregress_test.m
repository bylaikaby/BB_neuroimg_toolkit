
Ntime  = 80;
Ndata  = 1000;
Nmodel = 5;
NOISE  = 0.2;

% make models
X = zeros(Ntime,Nmodel);
X(21:60,1) = 1;             % _|--|_
X(:,2) = sin([0:79]/79*2*pi*2);
X(21:40,3) = [19:-1:0]'/19; % _|\|\_
X(41:60,3) = [19:-1:0]'/19;
X([21:40 61:80],4) = 1;       % _|-|_|-
X(:,5) = 1;                 % ------


% make data
Y = zeros(Ntime,Ndata);
for N=1:100,
  Y(:,N) = X(:,1) + (2*rand(Ntime,1)-1)*NOISE;
end
for N=101:200,
  Y(:,N) = X(:,2) + (2*rand(Ntime,1)-1)*NOISE;
end
for N=201:300,
  Y(:,N) = X(:,3) + (2*rand(Ntime,1)-1)*NOISE;
end
for N=301:400,
  Y(:,N) = X(:,4) + (2*rand(Ntime,1)-1)*NOISE;
end
%for N=401:500,
%  Y(:,N) = (2*rand(Ntime,1)-1)*NOISE;
%end
for N=401:500,
  Y(:,N) = X(:,1)*0.3 + X(:,2)*0.7 + (2*rand(Ntime,1)-1)*NOISE;
end


for N=501:600,
  Y(:,N) = X(:,1)*0.7 + X(:,2)*0.3 + (2*rand(Ntime,1)-1)*NOISE;
end
for N=601:700,
  Y(:,N) = X(:,1)*0.7 + X(:,3)*0.3 + (2*rand(Ntime,1)-1)*NOISE;
end
for N=701:800,
  Y(:,N) = X(:,1)*0.7 + X(:,4)*0.3 + (2*rand(Ntime,1)-1)*NOISE;
end
for N=801:900,
  Y(:,N) = X(:,2)*0.7 + X(:,3)*0.3 + (2*rand(Ntime,1)-1)*NOISE;
end
for N=901:1000,
  Y(:,N) = X(:,2)*0.7 + X(:,4)*0.3 + (2*rand(Ntime,1)-1)*NOISE;
end







stats = mulregress(Y,X);

figure('Name',sprintf('%s: mulregress result',mfilename));
COL = 'rgbcmyk';
for N=1:Nmodel,
  subplot(Nmodel,2,2*N-1);
  plot(X(:,N),'color',COL(N));
  grid on;  set(gca,'ylim',[-1.2 1.2]);
  title(sprintf('MODEL=%d',N));
  subplot(Nmodel,2,2*N);
  % pick up positive correlation only
  idx = find(stats.tstat.pval(N,:) < 0.01);
  plot(mean(Y(:,idx),2),'color',COL(N));
  grid on;  set(gca,'ylim',[-1.2 1.2]);
  title(sprintf('Mean of significant data for MODEL%d (N=%d,both-side)',N,length(idx)));
end


cont = mulregress_contrast(stats.beta,stats.covb,[1 -1 0 0 0],stats.dfe);
figure('Name',sprintf('%s: mulregress_contrast result',mfilename));
subplot(4,1,1);
plot(stats.beta(1,:),'g');  hold on;
plot(stats.beta(2,:),'m');
grid on;  legend('1','2');
title('beta 1,2');  xlabel('Voxel Number');
set(gca,'xlim',[1 Ndata],'layer','top');
subplot(4,1,2);
tmpfill = cont.beta;  tmpfill(find(tmpfill < 0)) = 0;
fill([0 1:Ndata Ndata+1],[0 tmpfill 0],[1.0 0.8 0.8],'edgecolor',[1.0 0.8 0.8]);
hold on;
plot(cont.beta);  grid on;
title('new beta 1-2, shaded area should have low p-value');  xlabel('Voxel Number');
set(gca,'xlim',[1 Ndata],'layer','top');
subplot(4,1,3);
plot(cont.tstat.pval); grid on;
title('p value for new beta');  xlabel('Voxel Number');
set(gca,'xlim',[1 Ndata],'layer','top');
subplot(4,1,4);
idx = find(cont.tstat.pval < 0.01);
plot(mean(Y(:,idx),2),'linewidth',2);  grid on;  hold on;
plot(X(:,1),'color','g');
plot(X(:,2),'color','m');
legend('mean voxel','model1 as +1','model2 as -1');
title(sprintf('Mean of significant voxels (N=%d)',length(idx)));  xlabel('Time in points');
set(gca,'ylim',[-1.2 1.2],'layer','top');
