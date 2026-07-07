function Spf = sigspkform(Sig)
%SIGSPKFORM - Extract spikes forms from the raw signal (Sig)
% Spf = SIGSPKFORM(Sig) detect spikes and subsequently creates a
% two dimensional array with columns the waveforms of individual
% spikes. The number of columns corresponds to the number of
% isolated spikes. The function is used to examine the spetra of
% spikes and multiunit activity as well as to examine the EPSP
% activation in temporally resolved spike averages.
% NKL, 10.11.02
%
% See also SESGETSPK GETSPK

times = GetSpikeTimes(Sig);
NoChan = size(Sig.dat,2);
NoObsp = size(Sig.dat,3);
for ObspNo=1:NoObsp,
  for ChanNo=1:NoChan,
	Spf{ChanNo,ObspNo} = getspikeforms(Sig,times{ChanNo,ObspNo});
  end;
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Spkt = GetSpikeTimes(Sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
THRSD = 3.5;
HighPassCutoff = 500;
[b,a] = butter(4,HighPassCutoff/((1/Sig.dx)/2),'high');

NoChan = size(Sig.dat,2);
NoObsp = size(Sig.dat,3);
for ObspNo=1:NoObsp,
  for ChanNo=1:NoChan,
	if ~isempty(Sig.dat),
	  tmpwv = squeeze(Sig.dat(:,ChanNo,ObspNo));
	else
	  tmpwv = adx_read(adxfile,ObspNo-1,ChanNo-1);
	end
	tmpwv = filtfilt(b,a,tmpwv);		% high-pass filtered signal
	base = mean(tmpwv(:));
	sd   = std(tmpwv(:));
	thr  = base + THRSD * sd;
	tmpwv(tmpwv < thr) = 0;			% take pos threshold only
	tmpwv = diff(tmpwv);				% differentiate
	tmpwv = hzerox(tmpwv);			% find zero x-ings
	Spkt{ChanNo,ObspNo} = find(tmpwv) * Sig.dx;
  end;
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Spf = getspikeforms(sig,spkt)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SpikeLags	  = 0.0010;	% Possible jitter in finding the spikes
SpikePreTime  = 0.0015;	% start before trigger seconds
SpikeDuration = 0.0035;	% duration in seconds (includes afterspike activity)
SpikeWindow = SpikePreTime + SpikeDuration;

spkt = spkt - SpikePreTime;
pnts = round(spkt/sig.dx);
pSpikeWindow = round(SpikeWindow/sig.dx);
pLags = round(SpikeLags/sig.dx);

dat = zeros(pSpikeWindow,length(spkt)-1);
for N=1:length(spkt) - 1;
	dat(:,N)=sig.dat(pnts(N)+1:pnts(N)+pSpikeWindow);
end;
pat = hnanmean(dat,2);

for N=1:length(spkt) - 1;
  [C,lags] = xcorr(pat,dat(:,N),pLags);
  [mx,mxi] = max(C);						% optimal lag
  newpnts(N) = pnts(N)-(mxi-pLags);			% difference 
end;

for N=1:length(spkt) - 1;
	dat(:,N)=sig.dat(newpnts(N)+1:newpnts(N)+pSpikeWindow);
end;

Spf.session = sig.session;
Spf.grpname = sig.grpname;
Spf.ExpNo = sig.ExpNo;
Spf.dir = sig.dir;
Spf.dir.dname = 'Spf';
Spf.dx = sig.dx;
Spf.dat = dat;
Spf.times = (newpnts(:) * sig.dx) + SpikePreTime;
Spf.SpikeLags = SpikeLags;
Spf.SpikePreTime = SpikePreTime;
Spf.SpikeDuration = SpikeDuration;
Spf.SpikeWindow = SpikeWindow;
Spf.stm.v = {[0 1 0]};
Spf.stm.t = {[0 SpikePreTime SpikeWindow]};
Spf.stm.dt = {diff([0 SpikePreTime SpikeWindow])};
Spf.dsp.func = 'dspspikeform';
Spf.dsp.args = {'color';'k';'linestyle';'-';'linewidth';1.5};
Spf.dsp.label = {'Time in sec'; 'ADC Units'};






