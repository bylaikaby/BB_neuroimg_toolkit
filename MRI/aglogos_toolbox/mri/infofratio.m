function infofratio(SesName)
%INFOFRATIO - Display all information related to F-Statistics in a roiTs
% blp = infofratio(SesName) computes the F Ratio for different
% regressors (ClnSpc or BLP).
%
% roiTs{1}.glmcont(1)
%      selvoxels: [1x137 single]
%          statv: [1x137 single]
%        pvalues: [1x137 single]
%      allvalues: [1x238 single]
%           cont: [1x1 struct]
%        BetaMag: []
%     allbetamag: []
%
% NKL 26.01.2008

if nargin < 1, help infofratio; return;     end;

FFull = 4;
Ses = goto(SesName);
grpnames = supgrpmembers(SesName);

for N=1:length(grpnames),
  roiTs = sigload(Ses,grpnames{N},'roiTs');
  roiTs = roiTs{1};
  glm = roiTs.glmcont(FFull);

  subplot(2,1,1);
  hist(glm.statv(:),30);
  Num=length(glm.statv);
  M = mean(glm.statv);
  s = sprintf('F-stat: %s, N=%d, F=%.3f',grpnames{N}, Num, M);
  title(s);
  
  subplot(2,1,2);
  hist(glm.pvalues(:),30);
  pmin = min(glm.pvalues(:));
  pmax = max(glm.pvalues(:));
  pM = mean(glm.pvalues(:));
  s = sprintf('P-val: %s, p-min=%.3f, p-max=%.3f, p-mean=%.3f', grpnames{N}, pmin,pmax,pM);
  title(s);
  pause;
end;

