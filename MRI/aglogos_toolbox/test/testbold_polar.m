SES = {};
SES{end+1} = {'B06.RF1', {'polar'} };
SES{end+1} = {'B06.SC1', {'polar'} };
SES{end+1} = {'B06.Sg1', {'polar'} };
SES{end+1} = {'D04.QK1', {'polar'} };
SES{end+1} = {'D04.Ru1', {'polar'} };
SES{end+1} = {'D04.S01', {'polar'} };
SES{end+1} = {'D04.Sk1', {'polar'} };
SES{end+1} = {'D04.TB1', {'polar','polar2'} };
SES{end+1} = {'H05.TI1', {'polar'} };
SES{end+1} = {'I02.301', {'polar'} };
SES{end+1} = {'J04.TU1', {'polar'} };



% for S = 1:length(SES),
%   tmpses = SES{S}{1};
%   tmpgrp = SES{S}{2}{1};
%   %sesareats(tmpses,tmpgrp);
%   sesgettrial(tmpses,tmpgrp,'roiTs');
%   sesgrpmake(tmpses,tmpgrp,'troiTs');
%   sesgroupglm(tmpses,tmpgrp);
% end
  
% return



NUM_VOXELS = [];


BASE_MEAN = [];
BASE_STD  = [];
RESP_MEAN = [];
RESP_STD  = [];



for S = 1:length(SES),
  tmpses = SES{S}{1};
  tmpgrp = SES{S}{2}{1};
  fprintf('%s (%s) :...',tmpses,tmpgrp);
  sig = mvoxselect(tmpses,tmpgrp,'v1','glm[pbr]',[],0.01,'verbose',0);
  if ~isempty(sig.dat),
    bidx = getStimIndices(sig,'prestim',0,0);
    sidx = getStimIndices(sig,'anystim',0,8);
    
    NVox = size(sig.dat,2);
    mdat = nanmean(sig.dat,2);
    AMP_BASE(S) = nanmean(mdat(bidx));
    [tmpv tmpi] = max(mdat(sidx));
    sidx = [-1 0 1] + sidx(tmpi);
    AMP_RESP(S) = nanmean(mdat(sidx));
    
    tmpbase = nanmean(sig.dat(bidx,:),1);
    tmpresp = nanmean(sig.dat(sidx,:),1);
    
    BASE_MEAN(S) = nanmean(tmpbase);
    BASE_STD(S)  = nanstd(tmpbase);
    RESP_MEAN(S) = nanmean(tmpresp);
    RESP_STD(S)  = nanstd(tmpresp);
    
    fprintf('norm=%s  base=%g  resp=%g\n',sig.xform.method,BASE_MEAN(S),RESP_MEAN(S));
  else
    NUM_VOXELS(S) = 0;
    AMP_BASE(S) = NaN;
    AMP_RESP(S) = NaN;
    fprintf(' no data (NaN)\n');
  end
end
