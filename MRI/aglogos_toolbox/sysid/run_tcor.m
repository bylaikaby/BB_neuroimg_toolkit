function [RES V1 V2] = run_tcor(TYPE)
%RUN_TCOR - Run/Plot TCOR
%  EXAMPLE :
%    [ALL V1 V2] = run_tcor('polar')
%    [ALL V1 V2] = run_tcor('spont')
%
  
SES = flsesgrp(TYPE);

RoiName = 'all'; EleName = 'all';

RoiName = 'eleV1';  EleName = 'V1';
RoiName = 'V1';  EleName = 'V1';
%RoiName = 'V2';  EleName = 'V2';

%RoiName = 'V1';  EleName = 'V2';
%RoiName = 'V2';  EleName = 'V1';


%RoiName = 'eleV1';  EleName = 'V1';



ResampleHz = 'bold';

%ResampleHz = 0.1;

%SES = SES(1:4);
%SES = SES(1:2);

RES = {};
for N = 1:length(SES),
  tmpres = sestcor(SES{N}{1},SES{N}{2}{1},'plot',1,...
                   'RoiName',RoiName,'EleName',EleName,...
                   'ResampleHz',ResampleHz,'AddSdf',1);
  if isempty(tmpres),  continue;  end
  RES{end+1} = tmpres;
  clear tmpres;
end


% average all

V1 = [];
V2 = [];

for N = 1:length(RES),
  neu = RES{N}.ephys;
  grp = getgrp(RES{N}.session,RES{N}.grpname);
  for K = 1:length(neu),
    if strcmpi(neu(K).elename,'v1'),
      V1 = sub_catneu(V1,neu(K));
    elseif strcmpi(neu(K).elename,'v2'),
      V2 = sub_catneu(V2,neu(K));
    end
    %if strcmpi(grp.namech{K},'v1'),
    %  V1 = sub_catneu(V1,neu(K));
    %elseif strcmpi(grp.namech{K},'v2'),
    %  V2 = sub_catneu(V2,neu(K));
    %end
  end
end

if ~isempty(V1),
  figure; set(gcf,'Name',sprintf('COR-neu V1 (%s)',TYPE));
  sub_plotneu(V1);
end
if ~isempty(V2),
  figure; set(gcf,'Name',sprintf('COR-neu V2 (%s)',TYPE));
  sub_plotneu(V2);
end

return


function RES = sub_resample(RES,NEWDX)

if length(RES) > 1,
  for N = 1:length(RES),
    RES(N) = sub_resample(RES(N),NEWDX);
  end
  return
end

if size(RES.xcorr,2) > 1,
  RES.weights = nanmean(RES.weights,ndims(RES.weights));
  RES.xcorr   = nanmean(RES.xcorr,2);
  if isfield(RES,'ccr_conv'),
    RES.ccr_conv = nanmean(RES.ccr_conv,2);
    RES.ccp_conv = nanmean(RES.ccp_conv,2);
  end
end


x = RES.lags*RES.dx;
xi = -20:NEWDX:20;

if length(x) == length(xi) && all(x == xi),  return;  end

try,
  for N = 1:size(RES.weights,1),
    neww(N,:) = interp1(x,RES.weights(N,:),xi,'linear');
  end
catch,
  keyboard
end
RES.weights = neww;
RES.xcorr = interp1(x,RES.xcorr,xi,'linear');
RES.lags = xi/NEWDX;  % lags in points
RES.dx   = NEWDX;

return


function RES = sub_catneu(RES,newres)

newres = sub_resample(newres,0.5);

% for "xcorr", no need to normalize
%for N = 1:size(newres.weights,3),
%  tmpv = newres.weights(:,:,N);
%  newres.weights(:,:,N) = newres.weights(:,:,N) / max(tmpv(:));
%end


if isempty(RES),
  RES = newres;
  if isfield(RES,'session'),
    RES.session = { RES.session };
    RES.grpname = { RES.grpname };
    RES.exps    = { RES.exps    };
  end
  return
end

if isfield(RES,'session'),
  RES.session = cat(2,RES.session,newres.session);
  RES.grpname = cat(2,RES.grpname,newres.grpname);
  RES.exps    = cat(2,RES.exps,   newres.exps);
end

RES.weights = cat(3,RES.weights,newres.weights);
RES.xcorr   = cat(3,RES.xcorr,  newres.xcorr);

if isfield(RES,'ccr_conv'),
  RES.ccr_conv = cat(2,RES.ccr_conv,newres.ccr_conv);
  RES.ccp_conv = cat(2,RES.ccp_conv,newres.ccp_conv);
end
  
return



function sub_plotneu(RES)

subplot(2,1,1);
tmpt = RES.lags*RES.dx;
tmpt = -tmpt;  % flip to match with HRF
imagesc(tmpt,1:size(RES.weights,1),nanmean(RES.weights,3));
%set(gca,'clim',[-35 35]);
set(gca,'clim',[0 1]);
set(gca,'ydir','normal')
for K=1:length(RES.band),
  yticklabel{K}=sprintf('%s [%d-%d]',RES.band{K}{2},RES.band{K}{1}(1),RES.band{K}{1}(2));
end
set(gca,'ytick',1:length(yticklabel),'yticklabel',yticklabel)
title(sprintf('averaged xcorr (n=%d)',size(RES.weights,3)));
xlabel('lags in sec (neuro to BOLD)');
colorbar;

subplot(2,1,2);
tmpm = nanmean(RES.xcorr,3);
%tmps = nanstd(RES.xcorr,[],3) / sqrt(size(RES.xcorr,3));
tmps = nanstd(RES.xcorr,[],3);
tmpt = RES.lags*RES.dx;
tmpt = -tmpt;  % flip to match with HRF
ciplot(tmpm-tmps,tmpm+tmps,tmpt,[0.95 0.75 0.75]);
hold on;
plot(tmpt,tmpm,'color','k','linewidth',2);
grid on;
text(0.05,0.05,'mean+-sd','units','normalized')
set(gca,'xlim',[-20 20],'ylim',[-0.3 0.6],'layer','top');
title(sprintf('averaged xcorr (n=%d)',size(RES.xcorr,3)));
xlabel('lags in sec (neuro to BOLD)');
ylabel('corr. coef.');

return
