function Brst = siggetburst(Spkt,NSPIKES,DURATION_MSEC,MIN_INTERVAL_MSEC)
%SIGGETBURST - Extract bursts from Spkt signal
%   BRST = SIGGETBURST(SPKT,NSPIKES,DURATION_MSEC,MIN_INTERVAL_MSEC)
%
%   Bursts are defined by 
%     1. Duration between spike and spike+NSPIKES must be less than DURATION_MSEC.
%              t(spk+NSPIKES) - t(spk) < DURATION_MSEC
%     2. Burst interval must be greater than MIN_INTERVAL_MSEC.
%              t(burst+1) - t(burst) > MIN_INTERVAL_MSEC
%
%  VERSION : 0.90 18.01.05 YM  first release
%            0.91 20.01.05 YM  changed algorythm
%            0.92 25.01.05 YM  avoid error for D98.at1/at2
%
%  See also SIGGETSPK


% OLD ALGORYTHM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % min. number of spikes within a burst
% if ~exist('MIN_NSPIKES','var'),  MIN_NSPIKES = 4;  end
% % min. spiking activity within a burst
% if ~exist('MIN_FREQ_HZ','var'),  MIN_FREQ_HZ = 20;  end
% % min. interval between bursts.
% if ~exist('MIN_INTERVAL_SEC','var'),  MIN_INTERVAL_SEC = 0.01;  end


% BRST = cell(size(Spkt.times));
% for iSpk = 1:length(Spkt.times),
%   spkt = Spkt.times{iSpk} * Spkt.dt;   % use Spkt.dt, not Spkt.dx !!!!!!
%   BRST{iSpk} = round(subGetBurstOLD(spkt,MIN_NSPIKES,MIN_FREQ_HZ,MIN_INTERVAL_SEC) / Spkt.dt);
% end


  
% NEW ALGORYTHM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% number of spikes within a burst-duration
if ~exist('NSPIKES','var'),  NSPIKES = 3;  end
% burst duration
if ~exist('DURATION_MSEC','var'),  DURATION_MSEC = 20;  end
% min. interval between bursts.
if ~exist('MIN_INTERVAL_MSEC','var'),  MIN_INTERVAL_MSEC = 10;  end
BRST = cell(size(Spkt.times));
for iSpk = 1:length(Spkt.times),
  spkt = Spkt.times{iSpk} * Spkt.dt;    % use Spkt.dt, not Spkt.dx !!!!!!
  brst = subGetBurst(spkt, NSPIKES,DURATION_MSEC/1000, MIN_INTERVAL_MSEC/1000);
  BRST{iSpk} = round(brst/Spkt.dt);
end



Brst = Spkt;
Brst.times = BRST;
Brst.dir.dname = strrep(Spkt.dir.dname,'Spk','Brst');
% Brst.(mfilename).min_nspikes = MIN_NSPIKES;
% Brst.(mfilename).min_freq_hz = MIN_FREQ_HZ;
% Brst.(mfilename).min_interval_sec = MIN_INTERVAL_SEC;
Brst.(mfilename).nspikes = NSPIKES;
Brst.(mfilename).duration_msec = DURATION_MSEC;
Brst.(mfilename).min_interval_msec = MIN_INTERVAL_MSEC;


return;





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function BRST = subGetBurst(SPKT,NSPIKES,DURATION_SEC,MIN_INTERVAL_SEC)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DEBUG = 0;
BRST = [];
if isempty(SPKT),  return;   end

% NOTE "SPKT" in sec.
burst_end = SPKT;
burst_end(1:end-NSPIKES+1) = SPKT(NSPIKES:end);

% duration between spike and spike+NSPIKES must be less than DURATION_MSEC.
BRST = SPKT(find((burst_end - SPKT) < DURATION_SEC));
% burst interval must be greater than MIN_INTERVAL_MSEC
BRST = BRST(find(diff([0;BRST(:)]) > MIN_INTERVAL_SEC));


if DEBUG == 0,  return;  end

figure;
tmpspk = zeros(1,round(max(SPKT)*1000));
tmpspk(round(SPKT*1000)) = 1;
t = [1:length(tmpspk)]/1000;  % in msec
plot(t,tmpspk,'blue');  hold on;

tmpburst = zeros(1,round(max(SPKT)*1000));
tmpburst(round(BRST*1000)) = 0.5;
plot(t,tmpburst,'red');
grid on;

keyboard

return;






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function BRST = subGetBurstOLD(SPKT,MIN_NSPIKES,MIN_FREQ_HZ,MIN_INTERVAL_SEC)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DEBUG = 0;
BRST = [];
if isempty(SPKT),  return;   end

REFRACTORY = 0.002;  % refractory period as 2ms

% remove spikes with interval less than refractory period
IDX = zeros(size(SPKT));
IDX(1) = 1;
spkpre = 1;  spknow = 2;
while spknow <= length(SPKT),
  if SPKT(spknow) - SPKT(spkpre) > REFRACTORY,
    spkpre = spknow;
    IDX(spknow) = 1;
  end
  spknow = spknow + 1;
end
if DEBUG,  fprintf('%d --> %d\n',length(SPKT),length(find(IDX)));  end
SPKT = SPKT(find(IDX == 1));


% bursts which are shorter than this period must be caused by archfact.
MIN_DURATION = REFRACTORY * (MIN_NSPIKES - 1);

% get spiking activity in Hz
spkHz = 1.0./diff(SPKT);
tmpspk = zeros(size(spkHz));
tmpspk(find(spkHz >= MIN_FREQ_HZ)) = 1;

% detects onset time of bursts
burstOn = SPKT(find(diff(tmpspk) > 0));

% detects offset time of bursts
burstOff = SPKT(find(diff(tmpspk) < 0));
% to 'off' must be greater than 'on'
if burstOff(1) < burstOn(1),
  burstOff = burstOff(2:end);
end
if length(burstOn) > length(burstOff),
  burstOff(end:length(burstOn)) = burstOff(end);
end

% compute duration of bursts
try,
  burstDur = burstOff - burstOn;
catch,
  keyboard
end

% compute intervals of bursts
burstInt = burstOn(2:end) - burstOff(1:end-1);
burstInt(2:end+1) = burstInt(:);  % shift by one
%burstInt = [burstOn(1),burstInt(:)];
burstInt(1) = burstOn(1);

nspikes = zeros(size(burstDur));
for N = 1:length(burstOn)-1,
  nspikes(N) = length(find(SPKT >= burstOn(N) & SPKT <= burstOff(N)));
end

BRST = find( burstDur >= MIN_DURATION & ...
             burstInt >= MIN_INTERVAL_SEC & ...
             nspikes  >= MIN_NSPIKES );
BRST = burstOn(BRST);


 
if DEBUG == 0,  return;  end

figure;
plot(SPKT(1:end-1),spkHz,'blue');  hold on;
scaleV = max(spkHz(:))/2;
tmpburst = zeros(1,round(max(SPKT)*1000));
t = [1:length(tmpburst)]/1000;  % in msec
tmpburst(round(burstOn*1000)) = scaleV;
plot(t,tmpburst,'green');
tmpburst(:) = 0;
tmpburst(round(burstOff*1000)) = scaleV;
plot(t,tmpburst,'yellow');
tmpburst(:) = 0;
tmpburst(round(BRST*1000)) = scaleV;
plot(t,tmpburst,'red');
grid on;

keyboard

return;
