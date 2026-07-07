function [c,U,V,kappaOpt] = tkcca(X,Y,tau,kappas)
%TKCCA - Temporal kernel CCA - time resolved filters are computed for X
% [c,U,V] = tkcca(X,Y,tau,kappas)
%
% 	temporal kernel CCA - time resolved filters are computed for X
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
%
% for an example just type 
%
%>> tkcca
%
% without input arguments
%
%
%
if nargin==0,example,return,
elseif nargin<4,
  %kappas = 10.^-[0:4];
  kappas = kfromn(10.^[-3:0],2);
  if nargin<3, tau = 10;end
end

% 02.05.11 YM:  make sure it's a column vector
if isvector(kappas),  kappas = kappas(:);  end


% embed one signal in time shifted copies of itself
[X, timeidx, tauidx] = embed(X,tau);
% compute the linear kernels
kY = Y(:,timeidx)' * Y(:,timeidx);
kX = X' * X;
% find the right regularizer
kappaOpt	= optimize_kappa({kX,kY},kappas);
% compute kcca using the right regularizer
[r, a, b]	= kcca({kX,kY},kappaOpt);
% reconstruct the canonical variates and compute canonical correlogram
[U, V, c]	= reconstruct(X,Y(:,timeidx),a,b,tauidx);

function [eX, timeidx, tauidx] = embed(X,tau)
	% embed the first signal in its temporal context
	opt.detrend = 0;%1
	opt.window	= '';%'hamming';
	[D T] = size(X);
	% in case tau is a scalar, make it a vector from -tau to tau
	if prod(size(tau))==1,tau = -tau:tau;end
	startInd 	= tau(end) + 1;
	stopInd		= T + tau(1);
	len			= stopInd - startInd + 1;
	% create a column vector that contains the indices of the first segment
	idx = repmat((startInd:stopInd)', 1, length(tau)) + repmat(tau, len, 1); 	
	% create (linear) indices for the different dimensions
	dim_offset = repmat( (0:D-1)*T, length(tau)*len, 1);
	idx = repmat(idx(:), 1, D) + dim_offset;
	% for the linear indices we need column-signals
	X = X';
	% get the data (D channels, segments are concatenated)
	eX = X(idx);
	switch opt.window
	  case 'hanning'
	    wind = repmat(hanning(len), 1, length(tau)*D);
	  otherwise
	    wind = ones(len, length(tau)*D);
	end
	eX = reshape(eX, len, length(tau)*D);
	if opt.detrend, 
		eX = (detrend(eX).*wind)';
	else
	  eX = (eX.*wind)';
	end
	tauidx = repmat(tau',D,1); 
	timeidx = startInd:stopInd;

function [r,a,b] = kcca(Ks,kappas)
	% compute the dual coefficients (implementation inspired by Tijl De Bie, 
	% taken from www.kernel-methods.net)
	n = size(Ks{1},1);
	m = length(Ks);
	ncomp = 1;
	% Generate LH
	VK=zeros(n*m,n);
	for i=1:m
		[u,v] = eig(Ks{i});
    	Ks{i} = Ks{i}./sqrt(sum(diag(v).^2));
	    VK((i-1)*n+1:i*n,:)=Ks{i};
	end
	LH=VK*VK';
	for i=1:m
	    LH((i-1)*n+1:i*n,(i-1)*n+1:i*n)=0;
	end
	% Generate RH
	RH=zeros(n*m,n*m);
	for i=1:m
	    RH((i-1)*n+1:i*n,(i-1)*n+1:i*n)=(Ks{i}*Ks{i}')+(Ks{i}*kappas(i)) + 1e-5*eye(n);
	end
	RH=(RH+RH')/2;
	LH=(LH+LH')/2;
	options.disp = 0;
    
    % Compute the generalized eigenvectors
    if 1,
      [Vs,cors]=eigs(LH,RH,ncomp,'LA',options);
      cors=diag(cors);
    else
      ncomp = n;
      [Vs,cors]=eigs(LH,RH,ncomp,'LA',options);
      cors=diag(cors);
      
      icomp = 5;
      Vs   = Vs(:,icomp);
      cors = cors(icomp);
    end
      
    for i=1:m
      vs{i}=Vs((i-1)*n+1:i*n,:);
    end
	a = vs{1};
	b = vs{2};
	r = cors(1);
    
    
function kappa = optimize_kappa(Ks,kappas,iterations)
	fprintf(' %s %s: Optimizing Regularizers...', datestr(now,'HH:MM:SS'), mfilename);
	if nargin<3, iterations=10; end
	if size(kappas,2) ~= length(Ks), 
		kappas = repmat(kappas,1,length(Ks));
	end
	shcors = zeros(size(kappas,1),iterations);
	shk = Ks;
	% try each regularizer
	for iR = 1:size(kappas,1)
		r(iR,1) = kcca(Ks,kappas(iR,:));
		% for all iterations of the reshuffling procedure
		for iS = 1:iterations
			idx = randperm(size(Ks{1},1));
			shk{1} = Ks{1}(idx,idx);		
		    % do cca on shuffled data
     		shcors(iR,iS) = kcca(shk,kappas(iR,:));
		end
	end
  	% pick that regularizer that maximizes the distance between 
  	% true correlations and shuffled data correlations
  	[val,pick]  = max(mean((repmat(r,1,(iterations))-shcors).^2,2));
  	fprintf('\n   Correlations(true/shuffled)= %0.2f/%0.2f   Picked kappa=[%s]\n',...
  			r(pick),mean(shcors(pick,:)),deblank(sprintf('%g ',kappas(pick,:))))
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
	pX = squeeze(mean(reshape(pX(sortInds,:), [D,nTau, size(eX,2)] )))';
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
	kappa =  [10.^-[3:6]]'; % regularizer
	len = 400;	% length of the time series
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
	y = mixing1 *sig(1:end-delay) + noise *randn(length(mixing1),len);
	x = mixing2 *sig(delay+1:end) + noise *randn(length(mixing2),len);

	[c,U,V] = tkcca(x,y,lag,kappa);
	
	% plot results
	figure(42)
	subplot(2,3,1:3), 
	ts = [sig(delay+1:end)' x' y']+repmat(0:sum([size(x,1),size(y,1)]),size(x,2),1);
	plot(ts(1:100,:))
	set(gca,'ytick',[0:sum([size(x,1),size(y,1)])],...
			'yticklabel',{'Signal','X_1','X_2','Y_1','Y_2'})
	subplot(2,3,4), 
	imagesc(U),colorbar,
	set(gca,'xtick',1:5:2*lag+1,'xticklabel',-lag:5:lag,'ytick',[1 2])
	title('Variate of X')
	subplot(2,3,5), 
	imagesc(V),colorbar
	title('Variate of Y')
	set(gca,'xtick',[],'ytick',[1 2])
	subplot(2,3,6), 
	plot(-lag:lag,c)
	title('canonical correlogram')
