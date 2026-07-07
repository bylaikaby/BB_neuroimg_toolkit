
%X = [randn(30,2)*.4;randn(40,2)*.5+ones(40,1)*[4 4];randn(10,2)*0.4+ones(10,1)*[-0.7 2.5]];
X = [randn(60,2)*.4;randn(80,2)*.5+ones(80,1)*[4 4];randn(90,2)*0.4+ones(90,1)*[-0.7 2.4]];

MaxK = round(1+log2(size(X,1)));

[NumK p idx, C, sumd, D] = jd_kmeans(X, MaxK, 'replicates',25);
%[NumK p distort idx, C, sumd, D] = jump_kmeans(X, MaxK, 'replicates',25);

%[idx C sumd D] = kmeans(X,3);  NumK = 3;

[clust type] = dbscan(X,5);
fprintf('dbscan=%d\n',length(find(unique(clust)>0)));



figure(1);
subplot(1,2,1);  cla;
plot(X(:,1),X(:,2),'linestyle','none','color','k','marker','.');
hold on;
%colors = 'rgbcmyk';
colors = lines(NumK);
for N = 1:NumK,
  tmpidx = (idx == N);
  if isempty(tmpidx),  continue;  end
  tmpc = colors(N,:);
  plot(X(tmpidx,1),X(tmpidx,2),'linestyle','none',...
       'color',tmpc,'marker','o','markeredgecolor',tmpc);
end
grid on;


subplot(1,2,2);  cla;
plot(p,'marker','o');
xlabel('# of clusters');
ylabel('cost value');
grid on;


for N = 1:20,
  [idx C sumd D] = kmeans(X,N);
  s = silhouette(X,idx);
  cf(N) = nanmean(s);
end
