if ~exist('SESSION','var'),
  %SESSION = 's02nm1';
  %SESSION = 'c98nm1';
  SESSION = 'g97nm1';
end
if ~exist('ExpNo','var'),
  ExpNo   = 1;
  %ExpNo   = 36;
  ExpNo   = 31;
end


sigload(SESSION,ExpNo,'Cln');


nyqf = (1.0/Cln.dx)/2;
[b,a] = butter(4,400/nyqf,'high');

Cln.dat = filtfilt(b,a,Cln.dat);


iCh = 15;
base = mean(Cln.dat(:,iCh));
sd = std(Cln.dat(:,iCh));

THRSD = 3.5;
THRSD = 8.0;
thr = base + THRSD * sd;

tmpwv = abs(Cln.dat(:,iCh));
tmpwv(tmpwv < thr) = 0;

MIN_INTERVAL = round(0.001/Cln.dx);  % min interval as 1ms
tmpwv = diff(tmpwv);
tmpwv = hzerox(tmpwv);
tmpspk = find(tmpwv);
IDX = zeros(size(tmpspk));
IDX(1) = 1;
spkpre = 1;  spknow = 2;
while spknow <= length(tmpspk),
  if tmpspk(spknow) - tmpspk(spkpre) > MIN_INTERVAL,
    spkpre = spknow;
    IDX(spknow) = 1;
  end
  spknow = spknow + 1;
end
SPK{iCh} = tmpspk(find(IDX))+1;
SPKAMP = zeros(length(SPK{iCh}),size(Cln.dat,2));
SPKAMP(:,iCh) = Cln.dat(SPK{iCh},iCh);

ELE = Cln.chan;
ELECFG = [ [1 2 3 4];
           [5 6 7 8];
           [9 10 11 12];
           [13 14 15 16] ];
ELEDIST = 1;

[ix,iy] = ind2sub([4 4],iCh);
DIST = [];
for jCh = 1:size(Cln.dat,2),
  [jx,jy]   = ind2sub([4 4],ELE(jCh));
  DIST(jCh) = sqrt((jx-ix)^2 + (jy-iy)^2);
  SPKAMP(:,jCh) = Cln.dat(SPK{iCh},jCh);
end




