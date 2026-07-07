function [r,wx,wy]=tkcca_cv(X,Y,tau,kappas)
% [r,wx,wy]=tkcca_cv(X,Y,tau,kappas,varargin)
%
%
% INPUT:
%     X		Cell array of multivariate time series, each cell entry is an
%           experimental session
%     Y       corresponding timeseries Y
%     tau     time lags
%     kappas  regularisers
%
%
% OUTPUT:
% %     r     canonical correlogram
%       wx    time resolved canonical variate
%       wy    the other canonical variate
%


if numel(tau)==1,tau = -tau:tau;end

% for each data set in the session
for ifold = 1:numel(X)
	% for each regulariser
	for ir=1:size(kappas,1)
		[rr,wxn{ifold,ir},wyn{ifold,ir}] = tkcca(X{ifold},Y{ifold},tau,kappas(ir,:));
%		[rr,wxn{ifold,ir},wyn{ifold,ir}] = ccca(X{ifold},Y{ifold},tau,kappas(ir,:));
		% match the sign of the variates to the sign of the first one
		if ifold==1,s = 1;
	    else, s = sign(sum(wxn{ifold,ir}(:).*wxn{1,ir}(:)));
	    end
	    wxn{ifold,ir} = wxn{ifold,ir}*s./sqrt(sum(wxn{ifold,ir}(:).^2));
	    wyn{ifold,ir} = wyn{ifold,ir}*s./sqrt(sum(wyn{ifold,ir}(:).^2));
	end	    
end

% compute the correlation on the test data set
for ifold = 1:numel(X)
	for ir=1:size(kappas,1)
		% the canonical variates can be averaged to obtain the out-of-sample
		% error for this holdout set as none of the variates was estimated
	    % using data from ifold
		r_cv(ifold,ir) = evaluate_model(median(cat(3,wxn{setdiff(1:numel(X),ifold),ir}),3),...
	        	X{ifold},median(cat(2,wyn{setdiff(1:numel(X),ifold),ir}),2),Y{ifold},tau); 		
	end	    
end

% the regulariser that maximises the correlation on the test data
[r,rmax_ind] = max(median(abs(r_cv)));
fprintf('Picked [%f \t %f\t]: %0.2f\n',kappas(rmax_ind,1),kappas(rmax_ind,2),r);
% average over all variates
wx = median(cat(3,wxn{:,rmax_ind}),3);
wy = median(cat(2,wyn{:,rmax_ind}),2);
% average over all canonical correlograms
for ifold = 1:numel(X)
	[c(ifold,:)] = canonical_correlogram(wx,X{ifold},wy,Y{ifold},tau); 
	if 1 
	figure(22),clf
	subplot(2,2,1),imagesc(fliplr(wxn{ifold,rmax_ind})),
	colorbar('location','northoutside'),title('wx(\tau)')
	set(gca,'xticklabel',(max(tau)-get(gca,'xticklabel'))./2,'ytick',[1:9],...
		'yticklabel',{
		'mua','ripple','gamma','nmod','beta','sigma','alpha','theta','delta'
		})
	subplot(2,2,3),
	plot(fliplr(tau./2),fliplr(c(ifold,:).*sign(sum(c(ifold,:))))),hold all
	plot(fliplr(tau./2),fliplr(xcorr(mean(X{ifold}),mean(Y{ifold}),max(tau),'coeff')))
	legend('tkcca','xcorr')
	subplot(2,2,2)
	imagesc(X{ifold}),colorbar('location','northoutside'),xlabel('time [seconds]'),ylabel('frequency band')
		set(gca,'ytick',[1:9],'xticklabel',get(gca,'xtick')./2,...
		'yticklabel',{
		'mua','ripple','gamma','nmod','beta','sigma','alpha','theta','delta'
		})
	subplot(2,2,4)
	imagesc(Y{ifold}),colorbar('location','northoutside'),xlabel('time [seconds]'),ylabel('voxels')
	set(gca,'xticklabel',get(gca,'xtick')./2)
	pause
	end
end
r = median(c);

function [prediction,xhat,yhat] = evaluate_model(wx,x,wy,y,lags)
[r,xhat,yhat] = canonical_correlogram(wx,x,wy,y,lags);
prediction = corr(median(xhat,2),yhat);

function [c xhat yhat]= canonical_correlogram(wx,x,wy,y,tau)
%
startInd 	= -tau(1) + 1;
stopInd		= size(x,2) - tau(end);

idx = startInd:stopInd;

yhat = (wy'*y(:,idx))';
warning off
for itau=1:length(tau)
	xhat(:,itau) = (wx(:,itau)'*x(:,idx + tau(itau)))';
	c(itau) = corr(xhat(:,itau),yhat);
end
warning on
