function dspglm(roiTs,varargin)
%DSPGLM - Display the GLM results.

if nargin < 1,                  % roiTs must be defined as input
    help dsproits;
    return;
end;

VALIDARGS = {'RoiName';'rThr';'Mode';'Err';'FigFlag';'TrialNo'};

[SesName, ExpNo] = mgetroitsinfo(roiTs);
anap = getanap(SesName, ExpNo);
grp  = getgrp(SesName, ExpNo);

if ~(isfield(anap,'gettrial') & isfield(anap.gettrial,'status')),
    fprintf('DSPROITS: no "status"; ANAP structure is not completely defined!\n');
    keyboard;
end;

if ~isfield(grp,'refgrp') | ~isfield(grp.refgrp,'reftrial'),
    fprintf('DSPROITS: no "reftrial"; GRP.refgrp structure is not completely defined!\n');
    grp.refgrp.reftrial = 0;
end;

if ~isfield(anap,'rval'),
    fprintf('DSPROITS: no "rval"; ANAP structure is not completely defined!\n');
    keyboard;
end;
%%% Returns the GLM Cont field after which there is no sweat.
if isfield(grp,'refgrp') & ~isempty(grp.refgrp),
    roiTs = mroitsmask(roiTs);
end

for nroi = 1:length(roiTs)
    if iscell(roiTs{nroi})
        for ntrial =1:length(roiTs{nroi})
            if isfield(roiTs{nroi}{ntrial},'glmcont') | isfield(roiTs{nroi}{ntrial},'glmcontref')
                if isfield(roiTs{nroi}{ntrial},'glmcont')
                    temp = {roiTs{nroi}{ntrial}};
                    displaymaphot(temp);
                end
            end
        end
    else
        displaymaphot(roiTs);
    end
end

if iscell(roiTs{1})
    figurehandle = mfigure([1 29 1280 956]);
    set(gcf,'color','k');
    for nroi = 1:length(roiTs)
        for k=1:length(roiTs{nroi})
            reftrial = roiTs{nroi}{k}.glmcont(1).selvoxels;
            data = roiTs{nroi}{k}.dat(:,reftrial);
            y = nanmean(data,2);
            try
                yerr = nanstd(data,[],2)/sqrt(size(data,2));
            catch
                yerr = nanstd(data,2)/sqrt(size(data,2));
            end
            h(k) = errorbar([1:size(data,1)]*roiTs{nroi}{1}.dx,y,yerr,'r-');
            hold on;
        end
        set(h,'linewidth',2);
        drawstmlines(roiTs{1}{1},'linewidth',2,'color','b','linestyle',':');
        set(gca,'xcolor','w','ycolor','w','color',[.7 .7 .7]);
    end
end