
NT = 300;
NV = 200;

DAT = zeros(NT,NV);

c1  = zeros(NT,1);  c1(1:round(NT/2)) = 0.5;  c1(round(NT/2):end) = -0.5;
c2  = [0:NT-1]'/(NT-1);
c3  = sin(c2*2*pi*2);
for N =   1:round(NV/3),  DAT(:,N) = c1;  end
for N = round(NV/3)+1:2*round(NV/3),  DAT(:,N) = c2;  end
for N = 2*round(NV/3)+1:NV,  DAT(:,N) = c3;  end

%DAT = permute(DAT,[2 1]);  % (t,chan) --> (chan,t)

DAT = DAT + rand(size(DAT))*2;

% normalization, mean=0,std=1
m = mean(DAT,1);
s = std(DAT,[],1);
for N = 1:size(DAT,2),
  if s(N) ~= 0,
    DAT(:,N) = (DAT(:,N) - m(N)) / s(N);
  else
    DAT(:,N) = 0;
  end
end

figure;
subplot(311);
plot(DAT(:,[1:10 round(NV/3)+1:round(NV/3)+10 2*round(NV/3)+1:2*round(NV/3)+10]));  grid on;
title('DATA');

doJade = 0;
useJadeAsGuess = 0; %if this is 1, we use Jade to initialise the KGV and KMI
                    %exception: for n=16, use fast ICA by default (see below)

numSources = size(DAT,1);
etaLapl = 0.01;   %UPDATE OPTIONS.tol IN CONTRAST_PLS2 FOR 16 SIGNAL CASE
kernelSizeKMILapl = 3; %3 in KMI tech report

%Generate random matrix with small condition number, by randomly perturbing
%an orthogonal matrix
mixMat = rand(numSources,numSources);
while ~((1 <=cond(mixMat)) & (cond(mixMat) <= 2)),
  mixMat = rand_orth(numSources)+1/numSources*rand(numSources,numSources);
end

%x = mixMat*srcArray;     %generate mixtures of data
invTrueW = inv(mixMat); %

if doJade > 0,
  [WJade] = jadeR(DAT,numSources);
else
  WJade = rand_orth(numSources);
end

%using fica result to initialise KMI and KGV
if useJadeAsGuess > 0,
  Wguess = WJade;  %used to initialise KMI and KGV
else
  Wguess = rand_orth(numSources);
end

[W,Score] = kernel_ica(DAT,'ncomp',numSources,'contrast','kcTrace','eta',etaLapl, ...
                       'sig',kernelSizeKMILapl,'kernel','laplace','polish',0,...
                       'restarts',0,'disp',0,'invTrueW',invTrueW,'W0',Wguess);    

IC = W*DAT;


subplot(312);
plot(IC');  grid on;
title('ICA');




% PCA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DAT = permute(DAT,[2 1]);  % (t,chan) --> (chan,t)

SigMean = mean(DAT,1);

% covmatrix
Ndata = size(DAT,1);
Ndims = size(DAT,2);
CV    = zeros(Ndims,Ndims);
if flag == 0,  Ndata = Ndata - 1;  end
for iX = 1:Ndims,
  x = double(DAT(:,iX)) - SigMean(iX);
  CV(iX,iX) = sum(x .* x) / Ndata;
  for iY = iX+1:Ndims,
    y = double(DAT(:,iY)) - SigMean(iY);
    CV(iX,iY) = sum(x .* y) / Ndata;
    CV(iY,iX) = CV(iX,iY);
  end
end

[U,eVar,PC] = svds(CV,Ndims);
eVar = diag(eVar);

subplot(313);
plot(PC(:,[1:3]));  grid on;
title('PCA');

