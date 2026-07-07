function roiTs = matscor(roiTs,mdlsct,SHIFT)
%MATSCOR - Apply correlation analysis to the roiTs time series Xcor =
% MATSCOR (roiTs) uses the model "mdlsct" to search for time series in
% roiTs that correlate with stimulus changes.
%
% [R,P]=corrcoef(...) returns P, a matrix of p-values for testing the
% hypothesis of no correlation. Each p-value is the probability of
% getting a correlation as large as the observed value by random
% chance, when the true correlation is zero. If P(i,j) is small, say
% less than 0.05, then the correlation R(i,j) is significant.
%
% See also MCORIMG MCOR MKMODEL
%
% NKL, 11.04.04

if nargin < 3,
  SHIFT = 0;                % No xcor/lags are computed
end;

if nargin < 2,
  help matscor;
  return;
end;

NLAGS = round(SHIFT/roiTs{1}.dx);
NoRoi = length(roiTs);
NoModel = length(mdlsct);

for A = 1:NoRoi,
  % clear existing .r/.p
  roiTs{A}.r = {};
  roiTs{A}.p = {};
  roiTs{A}.mdl = {};
  
  tmpdat = roiTs{A}.dat;
  idx = find(isnan(tmpdat(:)));
  tmpdat(idx) = 0;
  
  for M = NoModel:-1:1,
    % mdlsct{M} is a cell array containing models for each of roiTs
    if iscell(mdlsct{M}),
      %[roiTs{A}.r{M}, roiTs{A}.p{M}] = mcor(mdlsct{M}{A}.dat,roiTs{A}.dat,NLAGS);
      [roiTs{A}.r{M}, roiTs{A}.p{M}] = mcor(mdlsct{M}{A}.dat,tmpdat,NLAGS);
      roiTs{A}.r{M} = roiTs{A}.r{M}(:);
      roiTs{A}.p{M} = roiTs{A}.p{M}(:);
      roiTs{A}.mdl{M} = squeeze(mdlsct{M}{A}.dat(:,1,1));
    else
      %[roiTs{A}.r{M}, roiTs{A}.p{M}] = mcor(mdlsct{M}.dat,roiTs{A}.dat,NLAGS);
      [roiTs{A}.r{M}, roiTs{A}.p{M}] = mcor(mdlsct{M}.dat,tmpdat,NLAGS);
      roiTs{A}.r{M} = roiTs{A}.r{M}(:);
      roiTs{A}.p{M} = roiTs{A}.p{M}(:);
      roiTs{A}.mdl{M} = squeeze(mdlsct{M}.dat(:,1,1));
    end;
  end
end;
