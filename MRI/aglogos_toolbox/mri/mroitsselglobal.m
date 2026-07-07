function roiTs = mroitsselglobal(roiTs, roiname, Thr)
%MROITSSELGLOBAL - Selects a common map for all trials of an observation period
% MROITSSELGLOBAL (roiTs) will take the median of all r-values (for roiTs structures that
% have more than one experiment) and then compute the median r value map across all trials.
%  
% NKL 08.08.04

if nargin < 3,
  Thr = 0.10;
end;

if nargin < 2,
  roiname = 'ele';
end;

if nargin < 1,
  help mroitsselglobal;
  return;
end;

for N=1:length(roiTs),
  roiTs{N}.r{1} = median(roiTs{N}.r{1},2);
  idx = find(roiTs{N}.r{1}>=Thr);
  roiTs{N}.origIdx = idx;
  roiTs{N}.r{1} = roiTs{N}.r{1}(idx);
  roiTs{N}.dat = roiTs{N}.dat(:,idx);
  roiTs{N}.coords = roiTs{N}.coords(idx,:);
end;

roiTs = mroitsget(roiTs,[],roiname);




    
    