function roiTs=mselcor(roiTs,Thr,pThr)
%MSELCOR - selects r and p values from roiTs of a grouped file
% MSELCOR(roiTs,Thr,pThr) - returns roiTs with comidx, idx
% AB 07.09.04
  
if nargin < 3,
  pThr = 0.1;
end;

if nargin < 2,
  Thr = 0.1;
end;

for S=1:length(roiTs),
  idx = [];
  for ExpNo = size(roiTs{S}.dat,3):-1:1,
    tmp = (roiTs{S}.r{1}(:,ExpNo)>Thr);
    idx(:,ExpNo) = tmp(:);
  end;
  prob{S} = sum(idx,2)/size(idx,2);
  comidx = (prob{S}>pThr);
  % keep 'comidx' for info.
  roiTs{S}.comidx = comidx;
  roiTs{S}.idx    = idx;
 
end;

