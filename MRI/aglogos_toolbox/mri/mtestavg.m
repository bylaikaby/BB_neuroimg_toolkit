function [eleTs, testTs] = mtestavg(roiTs, Thr, pThr, roiname)
%MTESTAVG - Test different types of averaging (common mask, selection/trial etc.)  

if nargin < 3,
  pThr = 0.1;
end;

if nargin < 2,
  Thr = 0.1;
end;

if nargin < 4,
  roiname = 'ele';
end;

DEBUG=0;  
eleTs = mroitsget(roiTs,[],roiname);
% try
% 	testTs = mroitsget(roiTs,[],'test');
% catch
% 	warning('mtestavg: test roi was not passed in')
% end

for S=1:length(eleTs),
  clear idx dat;
  idx = [];
  for ExpNo = size(eleTs{S}.dat,3):-1:1,
    tmp = (eleTs{S}.r{1}(:,ExpNo)>Thr);
    idx(:,ExpNo) = tmp(:);
	%idx = cat(1,idx(:),find(eleTs{S}.r{1}(:,ExpNo) > Thr));
  end;
  %uidx = sort(unique(idx));
  %prob{S} = zeros(1,size(eleTs{S}.dat,2));
  %for iVox = 1:length(uidx),
%	vox = uidx(iVox);
%	prob{S}(vox) = length(find(idx == vox));
  %end
  %prob{S} = prob{S} / size(eleTs{S}.dat,3);
  %comidx = find(prob{S} > pThr);

  prob{S} = sum(idx,2)/size(idx,2);
  comidx = (prob{S}>pThr);

  % update, 'r', 'dat','coords' based on  comidx
  %eleTs{S}.dat  = eleTs{S}.dat(:,comidx,:);
  %eleTs{S}.r{1} = eleTs{S}.r{1}(comidx,:);
  %eleTs{S}.coords = eleTs{S}.coords(comidx);
  
  % keep 'comidx' for info.
  eleTs{S}.comidx = comidx;
  eleTs{S}.idx    = idx;

  
%  for ExpNo = size(eleTs{S}.dat,3):-1:1,
%    dat(:,:,ExpNo) = eleTs{S}.dat(:,eleTs{S}.comidx,ExpNo);
%  end;  eleTs{S}.idx = idx;

%  eleTs{S}.dat = dat;

end;


if DEBUG,
  subplot(2,1,1);
  dspsig(eleTs{1},'color','k');
  hold on;
  dspsig(eleTs{2},'color','r');
  
  subplot(2,1,2);
  stem(prob{1});
  hold on;
  stem(prob{2},'r');
end;

  
  


 
  
  