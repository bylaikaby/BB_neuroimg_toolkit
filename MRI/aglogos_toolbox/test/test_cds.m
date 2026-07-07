%Ses = goto('h05nm7');
%Ses = goto('f10nm1');
%Ses = goto('h05nm8');
%Ses = goto('h05nm9');



function test_cds(Ses)

Ses = goto(Ses);



grp = getgrp(Ses,'flash');
EXPS = grp.exps;

TCSD = [];  TCLN = [];

fprintf('%s %s: %s(%s,n=%d) : ',...
        datestr(now,'HH:MM:SS'),mfilename,Ses.name,grp.name,length(EXPS));

dz = 0.15;  % mm
for N = 1:length(EXPS),
%for N = 1:3,

  fprintf('.');
  ExpNo = EXPS(N);
  
  
  cln = sigload(Ses,ExpNo,'Cln');
  cln = xform(cln,'zerobase','blank');

  cln = sigfiltfilt(cln,100,'lowpass');
  
  if isfield(grp,'recgain'),
    adc2mV = 20*1000/65536;  % +-10V as 16bit
    for K = 1:size(cln.dat,2),
      cln.dat(:,K) = cln.dat(:,K) * adc2mV / grp.recgain(K);
    end
  end
  
  % acending order...
  ELE_POS = (1:size(cln.dat,2))*dz;  % 0.15mm spacing
  cln.dat = flipdim(cln.dat,2);
  
  %[CSDDAT CSD_POS] = csd_standard(cln.dat,ELE_POS,'spf',1);
  %[CSDDAT CSD_POS] = icsd_delta(cln.dat,ELE_POS,'spf',1);

  %[CSDDAT CSD_POS] = ncsdz(cln.dat,ELE_POS,'standard','spf',1);
  [CSDDAT CSD_POS] = ncsdz(cln.dat,ELE_POS,'delta-icsd','spf',1);
  
  
  % CSDDAT = nan(size(cln.dat));
  % for K = 2:size(cln.dat,2)-1,
  %  CSDDAT(:,K) = cln.dat(:,K-1) - 2*cln.dat(:,K) + cln.dat(:,K+1);
  % end
  % CSD_POS = ELE_POS;
  % CSDDAT = -CSDDAT / dz^2;

  
  csdcln = cln;
  csdcln.dat = CSDDAT;

  p = getsortpars(Ses,ExpNo);
  if isfield(cln,'stimch'),
    tmpt = [0:size(cln.stimch.dat,1)-1]*cln.stimch.dx;
    tmps = cln.stimch.dat(:,1);
    tmps = tmps - nanmean(tmps(1:20));
    tmpx = find(diff(tmps) > 100);
    dt1  = p.trial.dtvol{1}(1);
    dt2  = p.trial.dtvol{1}(2);
    ilen = round((dt1+dt2)/cln.stimch.dx);
    for K = 1:length(p.trial.tonset{1}),
      is = round(p.trial.tonset{1}{K}(1)/cln.stimch.dx);
      ie = is + ilen;
      ix = min(tmpx(tmpx >= is & tmpx < ie));
      tx = tmpt(ix);
      p.trial.tonset{1}{K} = [tx-dt1 tx tx+dt2]; 
    end
  end
  
  tcln = sigsort(cln,p.trial);
  tcln = xform(tcln,'zerobase','prestim');
  tcln.dat = nanmean(tcln.dat,3);
  
  
  tclncsd = sigsort(csdcln,p.trial);
  tclncsd = xform(tclncsd,'zerobase','prestim');
  tclncsd.dat = nanmean(tclncsd.dat,3);
  
  % figure;
  % tmpt = [0:size(tclncsd.dat,1)-1]*tclncsd.dx - tclncsd.stm.time{1}(2);
  % tmpdat = tclncsd.dat;
  % tmpdat(isnan(tmpdat(:))) = 0;
  % imagesc(tmpt,CSD_POS,tmpdat');
  % colormap(flipud(jet(256)));
  % ylm = get(gca,'ylim');
  % line([0 0],ylm,'color','k');
  % line([0.1 0.1],ylm,'color','k');
  % set(gca,'ydir','reverse');
  % clm = get(gca,'clim');
  % set(gca,'clim',[-clm(2) clm(2)]);
  % set(gca,'xlim',[-0.1 0.5]);
  % drawnow;

  if isempty(TCSD),
    TCSD = tclncsd.dat;
  else
    if size(tclncsd.dat,1) > size(TCSD,1),
      tclncsd.dat = tclncsd.dat(1:size(TCSD,1),:);
    elseif size(tclncsd.dat,1) < size(TCSD,1),
      tclncsd.dat(end:size(TCSD,1),:) = NaN;
    end
    TCSD = cat(3,TCSD,tclncsd.dat);
  end
  
  if isempty(TCLN),
    TCLN = tcln.dat;
  else
    if size(tcln.dat,1) > size(TCLN,1),
      tcln.dat = tcln.dat(1:size(TCLN,1),:);
    elseif size(tcln.dat,1) < size(TCLN,1),
      tcln.dat(end:size(TCLN,1),:) = NaN;
    end
    TCLN = cat(3,TCLN,tcln.dat);
  end
  
  
  
end
fprintf(' done.\n');


tmpdat = nanmean(TCSD,3);
tmpdat(isnan(tmpdat(:))) = 0;
figure;
tmpt = [0:size(TCSD,1)-1]*tclncsd.dx - tclncsd.stm.time{1}(2);
imagesc(tmpt,CSD_POS,tmpdat');
colormap(flipud(jet(256)));


ylm = get(gca,'ylim');
line([0 0],ylm,'color','k');
line([0.1 0.1],ylm,'color','k');
set(gca,'ydir','reverse');
clm = get(gca,'clim');
set(gca,'clim',[-clm(2) clm(2)]);
set(gca,'xlim',[-0.1 0.5]);
title(Ses.name);
