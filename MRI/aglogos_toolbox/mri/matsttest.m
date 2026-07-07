function [roiTs,Hval,Pval] = matsttest(roiTs,epochX,epochY,alpha,tail,bonferroni)
%MATSTTEST - Apply unpaired T-Test analysis to the roiTs time series
%  [roiTs,hval,pval] = matsttest(roiTs,epochX,epochY) apply unpaired T-test between
%  "epochX" and "epochY".
%  [roiTs,hval,pval] = matsttest(roiTs,epochX,epochY,alpha,tail,bonferroni) uses
%  "alpha" as alpha-value, "tail" for three alternative hypotheses and 
%  "bonferroni" as a flag to alpha-value correction.
%
%   As default, alpah=0.05, tail = 'both' and bonferroni = 1.
%
%   "epochX/Y" can be either numeric indices for compariing periods or a string 
%   specifying the stmulus like 'blank'.  "epochY" can be a cell array of strings/indices.
%
%   tail = 'both'  : mean(epoch1) ~= mean(epoch2)
%   tail = 'right' : mean(epoch1) >  mean(epoch2)
%   tail = 'left'  : mean(epoch1) <  mean(epoch2)
%
% APPENDED STRUCTURE :
%   roiTs{1} = ....
%     ttest: [1x1 struct]
%              ttest.epoch: {{1x2 cell}}      <--- indices for each epoch
%                  ttest.h: {[1x2520 double]} <-- h values
%         p: {[1x2520 double]}                <-- p values
%
%
% EXAMPLE :
%   [roiTs, h, p] = matsttest(roiTs,'blank','polar', 0.05, 0, 1);
%
%   idxX = getStimIndices(roiTs{1},'blank',HemoDelay,HemoTail);
%   idxY = getStimIndices(roiTs{1},'movie',HemoDelay,HemoTail);
%   [roiTs, h, p] = matsttest(roiTs,idxX,idxY, 0.05, 0, 1);
%
% VERSION : 01.08.04 YM   pre-release
%
% See also GETSTIMINDICES, TTEST2, MATSCOR

if nargin < 3,  help matsttest; return;  end


if nargin < 4,  alpha = 0.05;    end
if nargin < 5,  tail  = 'both';  end
if nargin < 6,  bonferroni = 1;  end


if ischar(epochX),
  idxX = getStimIndices(roiTs{1},epochX);
else
  idxX = epochX;
end

% "epochY" can be multiple epoch.
if ~iscell(epochY),  epochY = {epochY};  end
for iEpoch = 1:length(epochY),
  if ischar(epochY{iEpoch}),
    idxY{iEpoch} = getStimIndices(roiTs{1},epochY{iEpoch});
  else
    idxY{iEpoch} = epochY{iEpoch};
  end
end

for iArea = 1:length(roiTs),
  if bonferroni,
    tmpA = alpha / size(roiTs{iArea}.dat,2);
  else
    tmpA = alpha;
  end
  tmpX = roiTs{iArea}.dat(idxX,:);
  roiTs{iArea}.p = {};
  roiTs{iArea}.ttest = {};
  for iEpoch = 1:length(idxY),
    tmpY = roiTs{iArea}.dat(idxY{iEpoch},:);
    h = zeros(1,size(tmpX,2));
    p = ones(1,size(tmpY,2));
    for iVox = 1:size(tmpX,2),
      [h(iVox),p(iVox)] = ttest2(tmpX(:,iVox),tmpY(:,iVox),tmpA,tail);
    end
    roiTs{iArea}.ttest.epoch{iEpoch} = {idxX,idxY{iEpoch}};;
    roiTs{iArea}.ttest.h{iEpoch} = h;
    roiTs{iArea}.p{iEpoch} = p;
  end
end


if nargout > 1,
  Hval = {};  Pval = {};
  for iArea = 1:length(roiTs),
    Hval{iArea} = roiTs{iArea}.ttest.h;
    Pval{iArea} = roiTs{iArea}.p;
  end
end


return;
