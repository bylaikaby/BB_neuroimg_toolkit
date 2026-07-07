function Spf = spkana(SESSION,ExpNo)
%SPKANA - Analyzes spike waveforms, spectra, and clustering.
% Spf = SPKANA(SESSION,ExpNo) invokes getspkform to obtain the
% individual spike forms. It then computes PC components to check
% the most likely number of different spikes detected and
% calculates their spectra.
% NKL, 10.11.02
%
%         session: 'dalsp1'
%          grpname: 'riv'
%            ExpNo: 1
%              dir: [1x1 struct]
%               dx: 4.4800e-005
%              dat: [268x470 double]
%            times: [1x470 double]
%        SpikeLags: 0.0030
%     SpikePreTime: 0.0040
%    SpikeDuration: 0.0080
%      SpikeWindow: 0.0120
%              stm: [1x1 struct]
%              dsp: [1x1 struct]
%              amp: [2048x470 double]
%               fr: [2048x1 double]
% See also SESGETSPK GETSPK
SWPCA = 0;
SWPAR = 0;
SWAVG = 0;
SWMUA = 0;

if ~nargin,
  SESSION='dalsp1';
  ExpNo=1;
end;

Ses = goto(SESSION);
Grp = getgrp(Ses,ExpNo);
clnfile = catfilename(Ses,ExpNo,'cln');
matfile = catfilename(Ses,ExpNo,'mat');
load(clnfile,'Cln');
load(matfile,'LfpFlt');

keyboard
% **** GET ALL SPIKE FORMS OF AN EXPERIMENT
Spf = sigspkform(Cln);

if SWPCA,
  % COMPUTE PCA COMPONENTS OF THE FORMS (NOT EFFECTIVE)
  Spf = getpca(Spf);
end;

if SWPAR,
  % COMPUTE SPIKE SIZE AND DURATION AS CLUSTER PARAMETERS (NOT EFFECTIVE)
  Spf = getspkpar(Spf);
end;

% **** COMPUTE SPIKE SPECTRA
Spf = getspkspc(Spf);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This here needs really work. I must check bibliography to see how
% they do it. We don't seem to be getting anything reasonable by
% doing this although visual inspection shows that the spikes were
% perfecly well detected etc....
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if SWAVG,
  % COMPUTE SPIKE-TRIGGERED AVERAGES OF LFPs
  Spf = spktrgavg(Spf,LfpFlt);
end;

if SWMUA,
  Mua = mkspktrain(Spf);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DUMPING AND PLOTTING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~nargout,
  SAVE=0;
  if SAVE,
	save(matfile,'-append','Spf');
	fprintf('Structure Spf was appended into %s\n', matfile);
  end;
  
  if 1,
	% PLOT SPIKE FORM (UP) AND SPECTRA (DOWN)
	mfigure([100 100 650 800]);
	subplot(2,1,1);
	t = [0:size(Spf{1}.dat,1)-1]*Spf{1}.dx*1000-Spf{1}.SpikePreTime*1000;
	eb = errorbar(t,mean(Spf{1}.dat,2),std(Spf{1}.dat,1,2));
	hold on;
	plot(t,mean(Spf{1}.dat,2),'linewidth',2,'color','r');
	set(gca,'xlim',[t(1) t(end)]);
	line([0 0],get(gca,'ylim'),...
	   'linewidth',1,'color','r','linestyle',':');
	grid on

	subplot(2,1,2);
	plot(Spf{1}.fr,mean(Spf{1}.amp,2),'color','k','linewidth',2);
	set(gca,'xscale','log');
	grid on;
	line([10 10],get(gca,'ylim'),'linewidth',3,'color','r');
	line([150 150],get(gca,'ylim'),'linewidth',3,'color','r');
	line([300 300],get(gca,'ylim'),'linewidth',1,'color','b');
	line([3000 3000],get(gca,'ylim'),'linewidth',1,'color','b');
	xlabel('Frequency in Hz');
	ylabel('Power');
	T=sprintf('SPKANA - Ses: %s, Grp: %s, Exp: %d', Spf{1}.session,...
			  Spf{1}.grpname, Spf{1}.ExpNo);
	title(T,'color','r');
  end;
  
  if 0,
	% PLOT EPSP SUPERIMPOSED TO RANDOM AVERAGING
	mfigure([50 50 600 400]);
	W = floor(size(Spf{1}.epsp,1)/2);
	t = [-W:W]'*Spf{1}.dx*1000;
	L=min(size(t),size(Spf{1}.epsp,1));
	y = mean(Spf{1}.epsp,2);
	ry = squeeze(mean(Spf{1}.rndepsp,2));
	plot(t(1:L), y(1:L),'linewidth',2,'color','r');
	hold on;
	plot(t(1:L), ry(1:L));
	grid on;
  end;

  if 0,
	% PLOT ONE ORIGINAL WAVE FORM AND ITS RECONSTRUCTED FORM
	mfigure([100 100 600 400]);
	hd(1)=plot(t,Spf{1}.dat(:,10));
	hold on;
	hd(2)=plot(t,Spf{1}.reco(:,10),'r');
	grid on;
	legend(hd,'Original Mean SPForm','HighPass Filtered at 600Hz');
  end;

  if 0,
	mfigure([100 100 600 400]);
	m = mean(Spf{1}.amp,2);
	m = m/max(m);
	sigpsd(Mua);
	hold on;
	plot(Spf{1}.fr,m,'color','k','linewidth',2);
  end;
  
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Mua = mkspktrain(Spf)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t = Spf{1}.times;
pnts=round((t(end)+Spf{1}.SpikeWindow)/Spf{1}.dx);
Mua.session = Spf{1}.session;
Mua.grpname = Spf{1}.grpname;
Mua.ExpNo = Spf{1}.ExpNo;
Mua.dir = Spf{1}.dir;
Mua.dsp = Spf{1}.dsp;
Mua.dsp.func = 'dspsig';
Mua.dsp.args = {'color';'k';'linestyle';'-'};
Mua.stm = Spf{1}.stm;
Mua.dx = Spf{1}.dx;
Mua.dat = zeros(pnts+1,1);
Mua.chan = [1];
pt = round(t/Spf{1}.dx);
dur = round(Spf{1}.SpikeWindow/Spf{1}.dx);
for N=1:length(pt);
  Mua.dat(pt(N)+1:pt(N)+dur)=Mua.dat(pt(N)+1:pt(N)+dur) +...
	  detrend(Spf{1}.dat(:,N));
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Spf = spktrgavg(Spf,LfpFlt)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[b,a]=butter(3,[10 300]/((1/LfpFlt.dx)/2),'bandpass');
LfpFlt.dat = filtfilt(b,a,LfpFlt.dat);
WINDOW = 0.050;
for ObspNo=1:size(Spf,2)
  for ChanNo=1:size(Spf,1),
	t = round(Spf{ChanNo,ObspNo}.times/LfpFlt.dx);
	TEND = t(end);
	hdur = round((WINDOW/LfpFlt.dx)/2);
	S=1;
	for N=1:length(t);
	  if (t(N)+hdur) < size(LfpFlt.dat,1),
		Spf{ChanNo,ObspNo}.epsp(:,S) = LfpFlt.dat(t(N)-hdur:t(N)+ hdur,:);
		S=S+1;
	  end;
	end;
  end;
end;
rt = sort(round(rand(length(t),1) * TEND));
for N=1:length(rt);
  S=1;
  if (rt(N)-hdur)>0 & (rt(N)+hdur) < size(LfpFlt.dat,1),
	Spf{ChanNo,ObspNo}.rndepsp(:,N) = LfpFlt.dat(rt(N)-hdur:rt(N)+hdur,:);
	S=S+1;
  end;
  
end;  

Spf{ChanNo,ObspNo}.lfpdx = LfpFlt.dx;
Spf{ChanNo,ObspNo}.epsp = detrend(Spf{ChanNo,ObspNo}.epsp);
Spf{ChanNo,ObspNo}.rndepsp = detrend(Spf{ChanNo,ObspNo}.rndepsp);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Spf = getspkspc(Spf)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Sig = Spf;
for ObspNo=1:size(Spf,2)
  for ChanNo=1:size(Spf,1),
	Sig{ChanNo,ObspNo}.dat = detrend(Sig{ChanNo,ObspNo}.dat);
	[Spf{ChanNo,ObspNo}.amp,Spf{ChanNo,ObspNo}.fr]=DOfft(Sig{ChanNo,ObspNo});
  end;
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Spf = getspkpar(Sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Spf = Sig;
dx = Sig{1,1}.dx;
for ObspNo=1:size(Spf,2)
  for ChanNo=1:size(Spf,1),
	[peaks(1,:),ix(1,:)] = max(Sig{ChanNo,ObspNo}.dat);
	[peaks(2,:),ix(2,:)] = min(Sig{ChanNo,ObspNo}.dat);
	Spf{ChanNo,ObspNo}.SpkSize = abs(diff(peaks));
	m = mean(Spf{ChanNo,ObspNo}.SpkSize(:));
	Spf{ChanNo,ObspNo}.SpkSize = Spf{ChanNo,ObspNo}.SpkSize - m;
	Spf{ChanNo,ObspNo}.SpkSize = Spf{ChanNo,ObspNo}.SpkSize/m;
	Spf{ChanNo,ObspNo}.SpkDuration = abs(diff(ix))*dx*1000;
  end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Spf = getpca(Sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NPC=5;
Spf = Sig;
for ObspNo=1:size(Spf,2)
  for ChanNo=1:size(Spf,1),
	[PC, eVar, Proj, SigMean] = pca(Sig{ChanNo,ObspNo}.dat,NPC);
	for K=1:size(Sig{ChanNo,ObspNo}.dat,2),
	  Spf{ChanNo,ObspNo}.reco(:,K) = PC * Proj(K,:)' + SigMean;
	end;
  end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [fabs,fr] = DOfft(Sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data = Sig.dat;
srate = 1 / Sig.dx;
len = 4096;
fdat = fft(data,len,1);
LEN = size(fdat,1)/2;
fabs = abs(fdat(1:LEN,:)).^2;
lfr = (srate/2)*[0:LEN-1]/(LEN-1);
fr = lfr(:);

