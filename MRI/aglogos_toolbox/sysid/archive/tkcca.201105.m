function [c,U,V,c_perc,U_perc,V_perc] = tkcca(X,Y,tau,kappas)
% [c, U, V, c_bstrp, U_bstrp, V_bstrp] = tkcca(X,Y,tau,kappas)
%
% 	temporal kernel CCA
%
% INPUT
%	X	a nDimensions-by-Samples data matrix
%	Y	a mDimensions-by-Samples data matrix
%	tau	the maximal time lag by which X is shifted with respect to Y
%	kappas	the regularizers
%
% OUTPUT
%	c	the canonical correlogram, from -tau to tau
%	U	the time resolved canonical variate for X
%	V	the canonical variate for Y
%
%	if additional output args are specified, tkcca will return
%	bootstrapped MEDIANS in the first three output args
%	and the respective 25th and 75th PERCENTILES in the last three output args
%
%
% If you use this software for your research, please cite the article
% Biessmann et al., "Temporal Kernel CCA and its Application in Multimodal
% Neuronal Data Analysis", 2009, Machine Learning Journal,
% doi=10.1007/s10994-009-5153-3, http://www.springerlink.com/content/e1425487365v2227
%
% EXAMPLES
%
%>> tkcca
%
% 	without input arguments will produce figure one of above mentioned reference
%
%>> [c,U,V] = tkcca(X,Y,10,10.^[-4:0])
%
%	computes canonical correlogram and time resolved variates from -10 to 10
%	and choose the best regularization parameter from 10.^[-4:0]
%
%>> [c, U, V, c_bstrp, U_bstrp, V_bstrp] = tkcca(X,Y,5)
%
%	computes 100 boostrap iterations and returns the median
%	canonical correlogram and time resolved variates for time lags -5 to 5
%	respective 25th/75th percentiles are returned in c_bstrp, U_bstrp, V_bstrp

if nargin==0,example,return,end

if nargin<4, kappas = [10.^-[0:7]]'; end

% 02.05.2011 YM:  kappa > 0.0001 has a problem of eigensolver..
if nargin<4, kappas = [10.^-[0:4]]'; end



% center data
X = X - repmat(mean(X,2),1,size(X,2));
Y = Y - repmat(mean(Y,2),1,size(Y,2));
% embed one signal in time shifted copies of itself
[X, timeidx, tauidx] = embed(X,tau);
% compute the linear kernels
kY = Y(:,timeidx)' * Y(:,timeidx);
kX = X' * X;
%
if size(kappas,1)==1
    kappaOpt = kappas;
else
    % find the right regularizer
    kappaOpt	= optimize_kappa(kX,kY,kappas);
end

% compute kcca using the right regularizer
[r, a, b]	= kcca(kX,kY,kappaOpt);
% reconstruct the canonical variates and compute canonical correlogram
[U, V, c]	= reconstruct(X,Y(:,timeidx),a,b,tauidx);

if nargout>3
    % estimate bootstrapped 25/75 percentiles
    nIt = 100;
    for it=1:nIt
        idx = ceil(size(kX,1)*rand(size(kX,1),1));
        % compute kcca using the right regularizer
        [r, a, b]	= kcca(kX(idx,idx),kY(idx,idx),kappaOpt);
        % reconstruct the canonical variates and compute canonical correlogram
        [allU(:,:,it), allV(:,it), allC(it,:)]	= reconstruct(X(:,idx),Y(:,timeidx(idx)),a,b,tauidx);
    end
    c_perc = [quantile(allC,.95);quantile(allC,.05)];
    U_perc = cat(3,quantile(allU,.95,3),quantile(allU,.05,3));
    V_perc = cat(3,quantile(allV,.95,2),quantile(allV,.05,2));
end

function [eX, timeidx, tauidx] = embed(X,tau)
% embed the first signal in its temporal context
[D T] = size(X);
% in case tau is a scalar, make it a vector from -tau to tau
if length(tau)==1,tau = -tau:tau;end
startInd 	= abs(tau(1)) + 1;
stopInd		= T - abs(tau(end));
len			= stopInd - startInd + 1;
% create a column vector that contains the indices of the first segment
idx = repmat((startInd:stopInd)', 1, length(tau)) + repmat(tau, len, 1);
% create (linear) indices for the different dimensions
dim_offset = repmat( (0:D-1)*T, length(tau)*len, 1);
idx = repmat(idx(:), 1, D) + dim_offset;
% for the linear indices we need column-signals
X = X';
% get the data (D channels, segments are concatenated) and reshape it
eX = reshape(X(idx), len, length(tau)*D)';
tauidx = repmat(tau',D,1);
timeidx = startInd:stopInd;

function [r,a,b] = kcca(kX,kY,kappas)
% compute the dual coefficients
n = size(kX,1);
options.disp = 0;
options.MAXITERATION = 500;
% normalise the spectral norm of the matrices
kX = kX./max(eig(kX));
kY = kY./max(eig(kY));
% Generate LH
LH = -[zeros(n) kX*kY';kY*kX' zeros(n)];
RH = [kX*kX'+eye(n)*kappas(1) zeros(n);zeros(n) kY*kY'+eye(n)*kappas(2)];
% Compute the generalized eigenvectors
warning off
% force symmetry
LH = (LH+LH')./2;
RH = (RH+RH')./2;
[Vs,r]=eigs(inv(RH+1e-5)*LH,[],1,'LR',options);
warning on
a = Vs(1:n);
b = Vs(n+1:end);


function kappa = optimize_kappa(kX,kY,kappas,iterations)
fprintf('Optimizing regularizers\n')
if nargin<4, iterations=10; end
if size(kappas,2) ~= 2, kappas = repmat(kappas,1,2);end
shcors = zeros(length(kappas),iterations);
skX = kX; skY = kY;
% try each regularizer
for iR = 1:length(kappas)
    fprintf('Kappa = [%f %f]\t',kappas(iR,1),kappas(iR,2))
    r(iR,1) = kcca(kX,kY,kappas(iR,:));
    % for all iterations of the reshuffling procedure
    for iS = 1:iterations
        idx = randperm(size(kX,1));
        skX = kX(idx,idx);
        % do cca on shuffled data
        shcors(iR,iS) = kcca(skX,skY,kappas(iR,:));
    end
    fprintf('%0.2f (True) - %0.2f (Shuffled) = %0.2f\n',...
        r(iR,1),mean(shcors(iR,:),2),r(iR,1)-mean(shcors(iR,:),2))
end
% pick that regularizer that maximizes the distance between
% true correlations and shuffled data correlations
[val,pick]  = max(mean((repmat(r,1,(iterations))-shcors),2));
fprintf('Picked kappa=[ %f %f ]\ncorrelations  %0.2f (true) vs. %0.2f (shuffled)\n',...
    kappas(pick,1),kappas(pick,2),r(pick),mean(shcors(pick,:)))
kappa = kappas(pick,:);

function [U,V,c] = reconstruct(eX,Y,a,b,tidx)
% the number of time lags
nTau = length(unique(tidx));
% the number of dimensions
D = size(eX,1)/nTau;
% the time-lag sorted indices
[sorted, sortInds] = sort(tidx);
% the zero lag canonical component
pY = ((Y * b)' * Y)';
% the time shifted canonical components
pX = repmat(eX * a, 1, size(eX, 2) ) .* eX;
if D>1
    pX = squeeze(mean(reshape(pX(sortInds,:), [D,nTau, size(eX,2)] )));
end
if nTau>1
    pX = pX';
end

% the correlations between the zero lag component of Y and the
% time shifted components of X (i.e. the canonical correlogram)
c = corr(pY,pX);
% the time resolved variate
U = reshape(eX * a, nTau, D)';
% the other variate
V = Y * b;

function example
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Example with toy data		%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rand('seed',1)
lag = 10;    % max time lag
delay = 6;   % coupling delay between the two variables
kappa =  [10.^-[4:7]]'; % regularizer
len = 200;	% length of the time series
spike_noise = .1;
noise = 0.15;
% mixing coefficients for x and y
mixing1 = [.1 .9]';
mixing2 = [.9 .1]';
%% make a noisy spike train
spikeinds = randperm(len);
spikeinds = spikeinds(1:(len/20));
inds = 1:len;
sig = zeros(1,len+delay);
sig(spikeinds) = 1;
sig = sig + randn(1,len+delay)*spike_noise;
%% mix the spike train into x and y, normalize
x = mixing1 *sig(1:end-delay) + noise *randn(length(mixing1),len);
y = mixing2 *sig(delay+1:end) + noise *randn(length(mixing2),len);
x = x./repmat(std(x')',1,len);
y = y./repmat(std(y')',1,len);

[c,U,V,c_perc] = tkcca(x,y,lag,kappa);

yc = V'*y;
xc = mean(filter2(U,x,'same'));

% plot results
figsiz = [16 7];
figure(42),clf
fnt = 8;
subplot(1,7,1:2),
p = get(gca,'position');
set(gca,'position',p.*[1 1 1 .8] + [-.08 0.09 0 0])
annotation(gcf,'textbox','String',{'A'},'Fontweight','bold','LineStyle','none',...
    'Position',[.01 .92 .16 .08],'fontsize',fnt+2);
offs = 7;
ts = [zscore(xc') zscore(yc') x' y' zscore(sig(delay+1:end)')]+repmat(1:offs:offs*7,size(x,2),1);
t = [1:80]';
hold on
plot(t,ts(t,1),'color',[1 0 0]*.8)
plot(t,ts(t,2),'color',[0 1 0].*.8)
plot(t,ts(t,end),'color',[0 0 1]),
plot([t t],ts(t,3:4),'color',[1 0 0]*.6)
plot([t t],ts(t,5:6),'color',[0 1 0]*.6)
xlabel('Time [samples]','fontsize',fnt)
ylim([-2 offs*sum(7)+3])
set(gca,'ytick',[1:offs:offs*7],...
    'yticklabel',{'CV_x','CV_y','X_1','X_2','Y_1','Y_2','Signal'},'fontsize',fnt)

h=subplot(1,7,3),
imagesc(V),colorbar
title('w_y','fontsize',fnt)
set(h,'xtick',[],'ytick',[1 2],'yticklabel',{'wy_1','wy_2'},...
    'fontsize',fnt,'position',get(h,'position').*[1 1 .2 .8]+[-.02 .08 0 0])
p = get(gca,'position');
annotation(gcf,'textbox','String',{'B'},'Fontweight','bold','LineStyle','none',...
    'Position',[p(1)-.05 .92 .16 .08],'fontsize',fnt+2);

h=subplot(1,7,4:5),
imagesc(U),
title('w_x(\tau)','fontsize',fnt)
xlabel('\tau','fontsize',fnt)
p = get(gca,'position');
set(gca,'xtick',1:5:2*lag+1,'xticklabel',-lag:5:lag,...
    'ytick',[1 2],'yticklabel',{'wx_1','wx_2'},'fontsize',fnt,...
    'position',p.*[1 1 .8 .8]+[.04 .08 0 0])
p = get(gca,'position');
annotation(gcf,'textbox','String',{'C'},'Fontweight','bold','LineStyle','none',...
    'Position',[p(1)-.05 .92 .16 .08],'fontsize',fnt+2);

h = subplot(1,7,6:7),
% median
plot(-lag:lag,c,'r')
hold on
% percentiles
plot(-lag:lag,c_perc,'k--')
xlabel('\tau','fontsize',fnt)
p = get(gca,'position');
set(gca,'fontsize',fnt,'position',p.*[1 1 .8 .8]+[.05 .08 0 0])
p = get(gca,'position');
annotation(gcf,'textbox','String',{'D'},'Fontweight','bold','LineStyle','none',...
    'Position',[p(1)-.05 .92 .16 .08],'fontsize',fnt+2);
title('Canonical Correlogram','fontsize',fnt)
