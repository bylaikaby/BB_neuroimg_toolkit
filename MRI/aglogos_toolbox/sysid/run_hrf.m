function [RES V1 V2] = run_hrf(TYPE)
%RUN_HRF - Compute/Plot HRF
%  EXAMPLE :
%    [ALL V1 V2] = run_hrf('spont')
%
  
SES = flsesgrp(TYPE);

RoiName = 'all'; EleName = 'all';

RoiName = 'eleV1';  EleName = 'V1';
%RoiName = 'eleV2';  EleName = 'V2';

%RoiName = 'V1';  EleName = 'V2';
%RoiName = 'V2';  EleName = 'V1';


%SES = SES(1:4);

RES = {};
for N = 1:length(SES),
  tmpres = sesbandhrf(SES{N}{1},SES{N}{2}{1},'plot',1,...
                   'RoiName',RoiName,'EleName',EleName,...
                   'AddSdf',1,'StimGroup','none','Method','cra');
  if isempty(tmpres),  continue;  end
  RES{end+1} = tmpres;
  clear tmpres;
end


% average all

V1 = [];
V2 = [];

for N = 1:length(RES),
  hrf = RES{N};
  grp = getgrp(RES{N}.session,RES{N}.grpname);
  for K = 1:length(hrf),
    if strcmpi(hrf(K).elename,'v1'),
      V1 = sub_cathrf(V1,hrf(K));
    elseif strcmpi(hrf(K).elename,'v2'),
      V2 = sub_cathrf(V2,hrf(K));
    end
    %if strcmpi(grp.namech{K},'v1'),
    %  V1 = sub_cathrf(V1,hrf(K));
    %elseif strcmpi(grp.namech{K},'v2'),
    %  V2 = sub_cathrf(V2,hrf(K));
    %end
  end
end

if ~isempty(V1),
  figure; set(gcf,'Name',sprintf('HRF V1 (%s)',TYPE));
  sub_plothrf(V1);
end
if ~isempty(V2),
  figure; set(gcf,'Name',sprintf('HRF V2 (%s)',TYPE));
  sub_plothrf(V2);
end

return


function RES = sub_cathrf(RES,newres)

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

RES.dat = cat(2,RES.dat,newres.dat);

  
return


function RES = sub_lowpass(RES)

tmpsz = size(RES.dat);
RES.dat = reshape(RES.dat,[tmpsz(1) prod(tmpsz(2:end))]);

[b a] = butter(8,0.5,'low');
nt = tmpsz(1);
nm = round(nt/2);
tmpidx = [nm+1:-1:2 1:nt nt-1:-1:(nt-nm)];
tmpsel = [1:nt] + nm;
for N = 1:size(RES.dat,2),
  tmpdat = RES.dat(:,N);
  tmpdat = tmpdat(tmpidx);
  tmpdat = filtfilt(b,a,tmpdat);
  RES.dat(:,N) = tmpdat(tmpsel);
end

RES.dat = reshape(RES.dat,tmpsz);



return


function sub_plothrf(RES)


RES = sub_lowpass(RES);


% normalize to max of 'gamma'
for iCh = 1:size(RES.dat,2),
  tmpv = max(RES.dat(:,iCh,6));
  RES.dat(:,iCh,:) = RES.dat(:,iCh,:) / tmpv;
end


tmpt = RES.lags*RES.dx;

  
% get time2peak
time2peak = [];
tmpsel = find(tmpt < 12);
for iCh = 1:size(RES.dat,2),
  for iBand = 1:size(RES.dat,3),
    [tmpv tmpi] = max(RES.dat(tmpsel,iCh,iBand));
    time2peak(iCh,iBand) = tmpt(tmpi(1));
  end
end


subplot(2,1,1);
tmpavr = squeeze(nanmean(RES.dat,2));
tmpstd = squeeze(nanstd(RES.dat,[],2));
tmpsem = tmpstd / sqrt(size(RES.dat,2));
imagesc(tmpt,1:size(RES.dat,3),tmpavr');
if 1,
  hold on;
  % plot timings of the peak
  for iBand = 1:size(tmpavr,2),
    %[tmpv tmpi] = max(tmpavr(:,iBand));
    %plot(tmpt(tmpi(1)),iBand,'+','linestyle','none');
    tmpm = nanmean(time2peak(:,iBand));
    tmps = nanstd(time2peak(:,iBand));
    plot(tmpm,iBand','o','linestyle','none');
    line([tmpm-tmps tmpm+tmps],[iBand iBand],'linewidth',2);
  end
end

%set(gca,'clim',[-35 35]);
set(gca,'clim',[-0.08 0.08],'xlim',[0 30]);
set(gca,'clim',[-1 1],'xlim',[0 30]);
set(gca,'ydir','normal')
for K=1:length(RES.band),
  yticklabel{K}=sprintf('%s [%d-%d]',RES.band{K}{2},RES.band{K}{1}(1),RES.band{K}{1}(2));
end
set(gca,'ytick',1:length(yticklabel),'yticklabel',yticklabel)
title(sprintf('Averaged HRF (NCh=%d)',size(RES.dat,2)));
xlabel('lags in sec');
colorbar;


subplot(2,1,2);
tmpidx = [3 6 8 9];  % nm1 gamma mua spk
col = lines(length(tmpidx)).^0.01;
for K=1:length(tmpidx),
  tmpm = tmpavr(:,tmpidx(K));
  tmps = tmpsem(:,tmpidx(K));
  %ciplot(tmpm-tmps,tmpm+tmps,tmpt,col(K,:));
  %errorbar(tmpt,tmpm,tmps,'color',col(K,:));
  plot(tmpt,tmpm,'color',col(K,:),'linewidth',2);
  hold on;
end
legend(yticklabel(tmpidx));
set(gca,'xlim',[0 30],'layer','top');
ylabel('Normalized Amplitude');
xlabel('lags in sec');
grid on;




  
return
