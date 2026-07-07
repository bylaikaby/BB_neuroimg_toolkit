function [SesName, ExpNo] = getblpinfo(blp)
%GETBLPINFO - Returns the session name and experiment number of blp.
% [SesName, ExpNo] = GETBLPINFO(blp) checks if it's a structure of nested cell array
% and finds the name and expno of the time series.
% NKL 31.12.2005
  

if nargin < 1,
  help getblpinfo;
  return;
end;

if isstruct(blp),
  SesName = blp.session;
  ExpNo = blp.ExpNo(1);
  return;
end;

if iscell(blp),
  if isstruct(blp{1}),
    SesName = blp{1}.session;
    ExpNo = blp{1}.ExpNo(1);
  else
    SesName = blp{1}{1}.session;
    ExpNo = blp{1}{1}.ExpNo(1);
  end;
end;

  
    
