function variations=kfromn(n,k)
% variations=kfromn(n,k)
% returns all variations of n, i.e. it picks k elements from n and 
% allows picking the same element multiple times
%
%	CAUTION: since kfromn uses recursion, be careful not to take 
%		 too high values or matlab gets stuck
%
% INPUT
% 	n	vector of elements
%	k	number of elements to pick
%
% OUPUT
%	variations	the variations, a n^k-by-k matrix

variations = zeros(length(n)^k,k);
if k==1,
   variations = n;
elseif k==2, 
   for ik=1:length(n):length(n)^k
   	inds = ik:ik+length(n)-1;
   	variations(inds,1) = n(ceil(ik/length(n)));
	variations(inds,2) = n(:);
   end
else
   row = 1;
   for ik=1:length(n)
	tmp = kfromn(n,k-1);
	variations(row:row+size(tmp,1)-1,end-k+1:end) = ...
		[repmat(n(ik),size(tmp,1),1) tmp];
	row = row+size(tmp,1);
   end
end
       
