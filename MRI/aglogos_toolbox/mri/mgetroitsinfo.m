function [SesName, ExpNo] = mgetroitsinfo(roiTs)
%MGETROITSINFO - Returns the session name and experiment number of roiTs.
% [SesName, ExpNo] = MGETROITSINFO(roiTs) checks if it's a structure of nested cell array
% and finds the name and expno of the time series.
% NKL 31.12.2005
  

if nargin < 1,
  help mgetroitsinfo;
  return;
end;

if isstruct(roiTs),
  SesName = roiTs.session;
  ExpNo = roiTs.ExpNo(1);
  return;
end;

if iscell(roiTs),
  if isstruct(roiTs{1}),
    SesName = roiTs{1}.session;
    ExpNo = roiTs{1}.ExpNo(1);
  else
    SesName = roiTs{1}{1}.session;
    ExpNo = roiTs{1}{1}.ExpNo(1);
  end;
end;

  
    
