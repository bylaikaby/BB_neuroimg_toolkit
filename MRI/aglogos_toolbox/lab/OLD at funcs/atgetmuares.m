function [Spkt, atSdf] = atgetmuares(SESSION, ExpNo)
%ATGETMUARES - Get spike times from Andreas' setup
% ATGETMUARES is converting the data collected by Andreas in our
% standard format for further analysis. For the spikes resulting
% from clustering etc. we make atSdfs with sampling rate of
% 7KHz. This can be further reduced to the 250Hz that we use as
% input for the coherence or contrast function analysis.
% NKL 02.10.03

if ~nargin,
  SESSION = 'd98at1';
  ExpNo=1;
end;

% the length of res() is the number of channels
Ses = goto(SESSION);
neufilename = catfilename(Ses,ExpNo,'atphys');
clnfilename = catfilename(Ses,ExpNo,'cln');
load(neufilename,'muares');
info = muares(1).info;

for T=1:length(muares),
  ttid(T) = muares(T).ttid;
end;
ttid=ttid(:);
uttid = unique(ttid);
for N=1:length(uttid),
  tt = find(ttid==uttid(N));
  for K=1:length(tt),
    sua{N}{K} = muares(tt(K)).spikes;
  end;
end;

for T=1:length(muares),
  ttid(T) = muares(T).ttid;
end;
ttid=ttid(:);
uttid = unique(ttid);
for N=1:length(uttid),
  tt = find(ttid==uttid(N));
  for K=1:length(tt),
    sua{N}{K} = muares(tt(K)).spikes;
  end;
end;

for TetNo=1:length(uttid),
  [mSpkt{TetNo}, mSdf{TetNo}] = DoAtgetmuares(Ses,ExpNo,sua{TetNo},info);

  mSpkt{TetNo}.TetNo = uttid(TetNo);
  mSdf{TetNo}.TetNo = uttid(TetNo);
  fprintf('atgetmuares[%d]: processed Tetrode: %3.0f\n', ...
		  TetNo, mSdf{TetNo}.TetNo);
end;
clear muares;

for M=1:length(mSpkt),
  if M==1,
	muaSpkt = mSpkt{1};
	muaSdf = mSdf{1};
  else
	muaSpkt.times{M,1} = mSpkt{M}.times{1};
	muaSpkt.dat = cat(2,muaSpkt.dat,mSpkt{M}.dat);
	muaSdf.dat = cat(2,muaSdf.dat,mSdf{M}.dat);
  end;
  muaSpkt.chan(M) = mSpkt{M}.TetNo;
  muaSdf.chan(M) = mSdf{M}.TetNo;
end;
clear mSpkt mSdf;

filename = catfilename(Ses,ExpNo,'mat');
if exist(filename,'file'),
  save(filename,'-append','muaSpkt','muaSdf');
else
  save(filename,'muaSpkt','muaSdf');
end;
	
fprintf('atgetmuares: saved muaSpkt/muaSdf in %s\n',filename);
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [atSpkt,atSdf] = DoAtgetmuares(Ses,ExpNo,DATA,info)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
LEN_MINUTES = 5;
LEN_SECONDS = LEN_MINUTES * 60;

grp = getgrp(Ses,ExpNo);
atSpkt.session = Ses.name;
atSpkt.grpname = grp.name;
atSpkt.ExpNo = ExpNo;

% FILES
atSpkt.dir.dname	= 'muaSpkt';
atSpkt.dir.physfile= catfilename(Ses,ExpNo,'phys');
atSpkt.dir.evtfile	= catfilename(Ses,ExpNo,'evt');
atSpkt.dir.matfile	= catfilename(Ses,ExpNo,'mat');

% DISPLAY
atSpkt.dsp.func	= 'dsppsth';
atSpkt.dsp.args	= {'color';'k';'linestyle';'-';'linewidth';0.5};
atSpkt.dsp.label	= {'Time in sec'; 'ADC Units'};

% GROUP INFO
atSpkt.grp	= grp;

% EVENT INFO
% NOTE : ONLY A SINGLE ESS OBS-PERIOD IS ACCEPTABLE IN OUR ANALYSIS.
atSpkt.evt.NoObsp		= 1;			% Single obsps
atSpkt.evt.NoChan		= length(DATA); % 4 wires per tetrode
atSpkt.evt.nbins      = 100;
atSpkt.evt.start		= info.tstart;
atSpkt.evt.end			= info.tend;;
atSpkt.evt.obslen		= atSpkt.evt.end - atSpkt.evt.start;
atSpkt.evt.srate		= 7000;
atSpkt.evt.dx			= 0.500;
atSpkt.evt.mri		= [];

% STIMULUS INFO
atSpkt.stm.v			= {[0 1 0]};
atSpkt.stm.dt			= {[5 LEN_SECONDS-10 5]};
atSpkt.stm.t			= {[0 5 LEN_SECONDS]};
atSpkt.stm.stmpars	= {};
atSpkt.stm.pdmpars	= {};
atSpkt.stm.sortedByStimulus = 0;	    % Whether or not sorted by stimulus

% CHANNEL INFO
atSpkt.chan = [1:length(DATA)];

for N=1:length(DATA),
  atSpkt.times{N,1} = DATA{N}+1;
end;

clear s; pack;
atSpkt.dt  = 1/atSpkt.evt.srate;

tofs = round((info.tstart/1000)/atSpkt.dt);
atSpkt.duration=round(((info.tend-info.tstart)/1000)/atSpkt.dt);

for N=1:size(atSpkt.times,1),
  atSpkt.times{N,1} = round((atSpkt.times{N,1}/1000) / atSpkt.dt)-tofs;
  atSpkt.times{N,1} = atSpkt.times{N,1}(find(atSpkt.times{N,1}<atSpkt.duration));
end;

clear tmp tmp1 tmp2;

NoObsp	= atSpkt.evt.NoObsp;
NoChan	= atSpkt.evt.NoChan;
atSpkt.evt.NoChan	= size(atSpkt.times,1);
NoChan = atSpkt.evt.NoChan;

for ChanNo=1:NoChan,
  [n,x] = hist(atSpkt.times{ChanNo,1},atSpkt.evt.nbins);
  atSpkt.dat(:,ChanNo,NoObsp) = n;
end;
atSpkt.dx = mean(diff(x*atSpkt.dt));

atSdfSampRate = 250;          % We keep all at 250 Hz resample
clear Spk tmp;

atSdf = atSpkt;
atSdf = rmfield(atSdf,'times');
atSdf.dx = atSpkt.dt;

% GENERATE atSdf

atSdf.dat = DOspkatSdf(atSpkt);

f = round((1/atSdfSampRate)/atSdf.dx);
atSdf.dx = 1/f;
for ChanNo=NoChan:-1:1,
  tmp(:,ChanNo) = decimate(atSdf.dat(:,ChanNo),f);
end;
atSdf.dat	= tmp;
clear tmp; pack;

atSdf.dir.dname = 'atSdf';
atSdf.dsp.func = 'dspsig';
atSdf.dsp.args = {'color';[0 .7 0];'linestyle';'-';'linewidth';0.5};
atSdf.dsp.label{1} = 'Time in seconds';
atSdf.dsp.label{2} = 'Spike Density';

%  atSdf = tosdu(atSdf);
return;


function atSdf = DOspkatSdf(atSpkt)
%SPKatSdf - Make spike density functions
%	atSdf = spkatSdf(atSpkt)
%	Creates a spike density function (atSdf) for a given series
%	of spike events (spike times extracted by thresholding or
%	by cluster cutting).
%	IMPORTANT: atSdf are given in SD UNITS of PRESTIM !!!!!!!!!!!!!!!!!!!!!!
%	NKL, 14.10.00

sdSec = 0.005;		% SD = 5 ms
atSdf = MkatSdf(atSpkt,sdSec);
return;	

%%% Create atSdf
function atSdf = MkatSdf(Spk,sdSec)
try,
  sd = round(sdSec/Spk.dt);				% COMPUTE KERNEL
  meanx = sd * 3;
  ksize = 2 * meanx + 1;
  x = [1:ksize]';
  m = exp(-((x - meanx).*(x - meanx))/(2*sd*sd));
  m = m ./ sum(m);
  ofs = meanx;
  NoChan = size(Spk.times,1);
  
  atSdf = zeros(Spk.duration,NoChan);
  tsel = (1+ofs):(Spk.duration+ofs);
  for ChanNo = 1:NoChan,
	atSdf(Spk.times{ChanNo,1},ChanNo) = 1;
	tmp = conv(atSdf(:,ChanNo),m);
	atSdf(:,ChanNo) = tmp(tsel);
  end;
catch,
  disp(lasterr);
  keyboard;
end;

return;

