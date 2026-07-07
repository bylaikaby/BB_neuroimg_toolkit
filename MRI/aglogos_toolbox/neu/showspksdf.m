function showspksdf(SesName, ExpNo, Chan, XLIM)
%SHOWSPKSDF - Show the Sdf of an experiment and the time of spikes
% NKL 21.10.2007
 
if nargin < 1,
  SesName = 'g02mn1';
  ExpNo = 18;
  Chan = 1;
  XLIM = [];
end;

MUAIDX = 6;

if nargin & nargin < 3,
  Chan = 1;
end;

if nargin & nargin < 4,
  XLIM = [0 10000];
end;

Cln = sigload(SesName,ExpNo,'Cln');
Cln = xform(Cln,'tosdu','prestim');
[Sdf, Spkt, blp] = sigload(SesName,ExpNo,'Sdf','Spkt','blp');

if isempty(XLIM),
  dt = Cln.stm.dt{1};
  XLIM = [dt(1)-5 dt(1)+5] * 1000;
end;

clnt = [0:size(Cln.dat,1)-1] * Cln.dx * 1000;
clny = Cln.dat(:,Chan);

blpy = blp.dat(:,Chan,MUAIDX);
blpt = [0:size(blpy,1)-1]*blp.dx*1000;
idx  = find(blpt>=XLIM(1) & blpt<=XLIM(2));
blp.dat = blp.dat(idx,:,:);
blpt = blpt(idx);
blpy = blpy(idx);
blpy = blpy - min(blpy);

sdfy = Sdf.dat(:,Chan);
sdfy = sdfy - min(sdfy);
sdft = [0:size(Sdf.dat,1)-1] * Sdf.dx * 1000;

stimes = Spkt.times{Chan} * Spkt.dt * 1000;
idx = find(stimes>=XLIM(1) & stimes<=XLIM(2));
stimes = stimes(idx);

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOT NOW
%%%%%%%%%%%%%%%%%%%%%%%%%%%
mfigure([50 120 1400 1000]);

% SPIKES AND CLN
subplot(3,1,1);
sd = (2 * std(abs(clny))) * 6;
ylim = [-sd sd];
for N=1:length(stimes),
  line([stimes(N) stimes(N)],ylim,'color','k','linewidth',0.1);
end;
hold on;
plot(clnt,clny,'r');
set(gca,'xlim',XLIM,'ylim',ylim);
xlabel('Time in milliseconds');
title(sprintf('Session: %s, ExpNo: %d <Cln,Spkt: 500Hz BP cutoff>',SesName,ExpNo));

% MUA AND SDF
subplot(3,1,2);
area(blpt, blpy,'facecolor',[.7 .7 .7]);
hold on;
plot(sdft, sdfy,'color','c','linewidth',2);
set(gca,'xlim',XLIM);
ylim = get(gca,'ylim');

subplot(3,1,2);
for N=1:length(stimes),
  line([stimes(N) stimes(N)],ylim,'color','y','linewidth',0.1);
end;
hold on;
area(blpt, blpy,'facecolor',[.7 .7 .7]);
hold on;
plot(sdft, sdfy,'color','c','linewidth',2);
ylabel('SD Units');
title('Spkt (yellow), BLP (area)  and  Sdf (cyan)');

% ALL OTHER BLPs
subplot(3,1,3);
COL = 'krgbcmy';
for N=1:size(blp.dat,3)-1,
  h(N) = plot(blpt, blp.dat(:,Chan,N),COL(N));
  hold on;
end;
set(gca,'xlim',XLIM);
xlabel('Time in milliseconds');

suptitle(sprintf('Session: %s, ExpNo: %d, Chan: %d, Range: [%d-%d]',SesName,ExpNo,Chan,XLIM));
