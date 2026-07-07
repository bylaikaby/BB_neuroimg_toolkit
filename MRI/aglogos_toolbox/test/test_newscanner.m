DGZFILE = 'd:/temp/ggg.dgz';
DGZFILE = '\\win49\Data\DataNeuro\db110216.6E1\db1102166E1_001.dgz';
[fp fr] = fileparts(DGZFILE);
ADFFILE = fullfile(fp,sprintf('%s.adfw',fr));

evt = expgetevt(DGZFILE);
switch lower(fr)
 case {'ggg'}
  [wv npts sampt] = adf_read(ADFFILE,0,5);
 otherwise
  [wv npts sampt] = adf_read(ADFFILE,0,1);
end
wv = int16(wv);

DGZLEN = evt.obs{1}.origtimes.end;  % in msec
ADFLEN = length(wv)*sampt;          % in msec

TFACTOR = DGZLEN / ADFLEN;


MRIEVT = evt.obs{1}.origtimes.mri;
MRIEVT = MRIEVT(:)';

tmpwv  = double(wv);
tmpwv(tmpwv <  15000) = 0;
tmpwv(tmpwv >= 15000) = 1;
tmpt   = (0:length(tmpwv)-1)*sampt;
ADFEVT = tmpt(diff(tmpwv) > 0);
ADFEVT = ADFEVT(:)';


figure('Name',sprintf('%s.dgz/adfw',fr));
subplot(2,1,1);
tmpt = [0:length(wv)-1]*sampt;
%plot(tmpt,wv,'b');
plot(tmpt(1:2:end),wv(1:2:end),'b');
hold on;
ylm = get(gca,'ylim');
for N = 1:length(MRIEVT),
  line([MRIEVT(N) MRIEVT(N)],ylm,'color','r');
end
text(0.01,0.92,sprintf('DGZLEN/ADFLEN=%g/%gmsec',DGZLEN,ADFLEN),'units','normalized');
xlabel('Time in msec');
ylabel('ADC Unit');
set(gca,'xlim',[tmpt(1) tmpt(end)]);
set(gca,'xlim',[0 1000]);
grid on;
title(strrep(sprintf('%s.dgz/adfw',fr),'_','\_'));


subplot(2,1,2);
plot(MRIEVT);
text(0.01,0.92,sprintf('NumMRITriggers=%d',length(MRIEVT)),'units','normalized');
xlabel('MRI Trigger Events');
ylabel('Time in msec');
grid on;
set(gca,'xlim',[1 length(MRIEVT)]);




figure('Name',sprintf('%s.dgz/adfw',fr));

subplot(2,1,1);
tmpd1 = diff(MRIEVT);
tmpd2 = diff(ADFEVT);
plot(tmpd1,'r');
hold on;
plot(tmpd2,'b');
xlabel('MRI Trigger Events');
ylabel('Interval in msec');
legend('MRI(dgz)','MRI(adf)');
grid on;
title(strrep(sprintf('%s.dgz/adfw',fr),'_','\_'));
ylm = get(gca,'ylim');
tmpm = round(nanmean(tmpd1));
tmph = ceil(diff(ylm)/2) + 1;
set(gca,'ylim',[tmpm-tmph tmpm+tmph]);
set(gca,'xlim',[1 max(length(MRIEVT),length(ADFEVT))]);
text(0.01,0.92,sprintf('MeanInt=%g/%g',nanmean(tmpd1),nanmean(tmpd2)),'units','normalized');


subplot(2,1,2);
if length(ADFEVT) > length(MRIEVT),
  MRIEVT(end+1:length(ADFEVT)) = NaN;
elseif length(ADFEVT) < length(MRIEVT)
  ADFEVT(end+1:length(MRIEVT)) = NaN;
end
tmpd  = ADFEVT - MRIEVT;
tmpd2 = ADFEVT*TFACTOR - MRIEVT;
plot(tmpd);
hold on;
plot(tmpd2,'r');
xlabel('MRI Trigger Events');
ylabel('Diff(ADF-DGZ) in msec');
grid on;
legend('raw','clock corrected');
ylm = get(gca,'ylim');
tmpm = round(nanmean(tmpd));
tmph = ceil(diff(ylm)/2) + 1;
set(gca,'ylim',[tmpm-tmph tmpm+tmph]);
set(gca,'xlim',[1 length(MRIEVT)]);
text(0.01,0.92,sprintf('MeanDiff=%g/%g',nanmean(tmpd),nanmean(tmpd2)),'units','normalized');
