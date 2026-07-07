function [Spkt, Sdf] = siggetspk(SESSION,ExpNo,Sig,DoAverage)
%SIGGETSPK - Extract spikes from the raw signal (Cln)
%	[Spkt, Sdf] = SIGGETSPK(SESSION,ExpNo,Sig,[DoAverage])
%   - high-pass filters signals, detects zero-crossings and 
%   thresholds to extract spikes from a few neurons.
%   NKL, 10.11.02
%   YM,  01.03.04  do decimation in spksdf.m instead of here, to
%                  to avoid memory problem.
%   YM,  22.12.04  serious bug fix for Spkt.dat by hist(). 
%   YM,  17.01.05  avoid error for D98.at1/at2.
%   YM,  20.01.05  introduces minimal interval between spikes
%
%	See also SESSIGGETSPK SPKSDF

if ~exist('DoAverage','var'), DoAverage = 0;  end

TEST  = 0;
THRSD = 3.5;

HighPassCutoff = 500;

Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);
par = expgetpar(Ses,ExpNo);

CONV2SDU    = 1;
BINWIDTH    = par.stm.voldt;
SDFRATE     = Ses.anap.bands.samprate;
SDFKERNEL   = 0.025;

anap = getanap(SESSION);
if isfield(anap,'siggetspk'),
  if isfield(anap.siggetspk,'conv2sdu'),
    CONV2SDU = anap.siggetspk.conv2sdu;
  end;
  if isfield(anap.siggetspk,'binwidth'),
    BINWIDTH = anap.siggetspk.binwidth;
  end;
  if isfield(anap.siggetspk,'sdfkernel'),
    SDFKERNEL = anap.siggetspk.sdfkernel;
  end;
  if isfield(anap.siggetspk,'sdfrate'),
    SDFRATE = anap.siggetspk.sdfrate;
  end;
end;

NoChan = size(Sig.dat,2);
NoObsp = size(Sig.dat,3);
if ~isempty(Sig.dat),
  ObsLenPts = size(Sig.dat,1);
  NoChan = size(Sig.dat,2);
  NoObsp = size(Sig.dat,3);
else
  adxfile = catfilename(Ses,ExpNo,'adx');
  if isempty(dir(adxfile)),
	% get data from the original ADF/ADFW.
	% note that adx_XXXX can handle ADF/ADFW.
	adxfile = catfilename(Ses,ExpNo,'phys');
  end
  [NoChan,NoObsp,sampt,obslen]= adx_info(adxfile);
  % may cause problem if obslen changes between observations...
  ObsLenPts = obslen(1);
  % make sure to use correct value.
  Sig.dx = sampt/1000. * par.adf.tfactor;
  Sig.dxorg = sampt/1000.;
  fprintf('siggetspk: Sig.dat = %s\n',adxfile);
end
[b,a] = butter(4,HighPassCutoff/((1/Sig.dx)/2),'high');

if 0,		% OLD CODE
  for ObspNo=1:NoObsp,
	for ChanNo=1:NoChan,
	  Sig.dat(:,ChanNo,ObspNo) = filtfilt(b,a,Sig.dat(:,ChanNo,ObspNo));
	end;
  end;
  
  for ObspNo=1:NoObsp,
	for ChanNo=1:NoChan,
	  base = mean(Sig.dat(:,ChanNo,ObspNo));
	  sd   = std(Sig.dat(:,ChanNo,ObspNo));
	  thr  = base + THRSD * sd;
	  tmp = Sig.dat(:,ChanNo,ObspNo);		% high-pass filtered signal
	  tmp(tmp < thr) = 0;					% take pos threshold only
	  tmp = diff(tmp);					% differentiate
	  tmp = hzerox(tmp);					% find zero x-ings
	  Spk{ChanNo,ObspNo} = find(tmp);
	end;
  end;
end;

for ObspNo=NoObsp:-1:1,
  for ChanNo=NoChan:-1:1,
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


    % 20.01.05 YM: simple zero x-ing is not good enough, very sensitve to noises.
    % bad case resulting, ~20% of spikes with a interval less than 1ms
    %                     ~30% of spikes with a interval less than 2ms
if 0,
    % OLD CODE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	tmpwv = diff(tmpwv);			% differentiate
	tmpwv = hzerox(tmpwv);			% find zero x-ings
	Spk{ChanNo,ObspNo} = find(tmpwv);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    % NEW CODE, 20.01.05 method-1 %%%%%%%%%%%%%%%%%%%%%
    % detects the first rising edge, that crosses threshold
    %tmpwv(find(tmpwv ~= 0)) = 1;
	%Spk{ChanNo,ObspNo} = find(diff([0;tmpwv(:)]) > 0);
    
    % NEW CODE, 20.01.05 method-2 %%%%%%%%%%%%%%%%%%%%%
    % detects zero x-ing and remove too close spikes
    MIN_INTERVAL = round(0.001/Sig.dx);  % min interval of 1ms in points
	tmpwv = diff(tmpwv);			% differentiate
	tmpwv = hzerox(tmpwv);			% find zero x-ings
	%Spk{ChanNo,ObspNo} = find(tmpwv);
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
    %fprintf('%d --> %d\n',length(tmpspk),length(find(IDX)));
	Spk{ChanNo,ObspNo} = tmpspk(find(IDX));
end


  end;
end;
clear tmpwv tmp; tmp{1} = [];

Spkt.session			= Sig.session;
Spkt.grpname			= Sig.grpname;
Spkt.ExpNo              = ExpNo;

Spkt.dir.dname          = 'Spkt';
Spkt.dir.physfile		= Sig.dir.physfile;
Spkt.dir.evtfile		= Sig.dir.evtfile;
Spkt.dir.matfile		= Sig.dir.matfile;

Spkt.dsp.func			= 'dsppsth';
Spkt.dsp.args			= {'facecolor';'k';'edgecolor';'k'};
Spkt.dsp.label{1}		= sprintf('Time in sec');
Spkt.dsp.label{2}		= sprintf('Count');
Spkt.duration			= ObsLenPts;

Spkt.times              = Spk;
Spkt.dt                 = Sig.dx;

if isfield(Sig,'dxorg'),
  Spkt.dtorg = Sig.dxorg;
end
Spkt.chan				= Sig.chan;
if isfield(Sig,'sortedByStimulus'),
  Spkt.sortedByStimulus	= Sig.sortedByStimulus;
end;
if isfield(Sig,'err'),
  Spkt.err = Sig.err;
end;
if isfield(Sig,'cond'),
  Spkt.cond = Sig.cond;
end;


% 22.12.04 YM: simple use of hist with NBINS will not give correct histgram.
%              so, we have to set edges.
if ~isempty(par) & isfield(par,'adf') & ~isempty(par.adf),
  NBINS = round(par.adf.adflen(1)/(BINWIDTH));
  EDGES = [0:NBINS]/NBINS*par.adf.adflen(1)/Sig.dx;
else
  % 15.01.05 YM
  % for data that is not compatible to our data-acquisition, like D98.at1/at2
  NBINS = round(Spkt.duration*Spkt.dt/0.25);
  EDGES = [0:NBINS]/NBINS*Spkt.duration/Spkt.dt;
  Sig.dx = Spkt.dt;
end
  

for ObspNo=NoObsp:-1:1,
  for ChanNo=NoChan:-1:1,
    % 22.12.04 YM: simple use of hist with NBINS will not give correct histgram.
	%[n,x] = hist(Spkt.times{ChanNo,ObspNo},NBINS);
	n = histc(Spkt.times{ChanNo,ObspNo},EDGES);
	Spkt.dat(:,ChanNo,ObspNo) = n;
  end;
end;

%Spkt.dx			= (x(2)-x(1))*Sig.dx;
Spkt.dx			= (EDGES(2)-EDGES(1))*Sig.dx;
if isfield(Sig,'dxorg'),
  Spkt.dxorg = Spkt.dx / Sig.dx * Sig.dxorg;
end

if isfield(Sig,'grp'),
  Spkt.grp = Sig.grp;
end;

if isfield(Sig,'usr'),
  Spkt.usr = Sig.usr;
end;

if isfield(Sig,'evt'),
  Spkt.evt = Sig.evt;
end;

if isfield(Sig,'movie'),
  Spkt.movie = Sig.movie;
end;

clear Spk Sig tmp;

Sdf     = Spkt;
Sdf     = rmfield(Sdf,'times');
Sdf     = rmfield(Sdf,'dt');
Sdf.dat = spksdf(Spkt,SDFRATE,SDFKERNEL);
Sdf.dx  = 1/SDFRATE;

if isfield(Spkt,'dxorg'),
  Sdf.dxorg = Sdf.dx / Spkt.dx * Spkt.dxorg;
end

Sdf.dir.dname = 'Sdf';
Sdf.dsp.func = 'dspsig';
Sdf.dsp.args = {'color';[0 .7 0];'linestyle';'-';'linewidth';0.5};
Sdf.dsp.label{1} = 'Time in seconds';
Sdf.dsp.label{2} = 'Spike Density';

if isfield(par,'stm'),
  Sdf.stm = par.stm;
else
  Sdf.stm = {};
end
if isfield(par,'evt'),
  Sdf.evt = par.evt;
else
  Sdf.evt = {};
end
Sdf.grp = grp;

if CONV2SDU > 0,
  if CONV2SDU == 3,
    fprintf(' zerobase...');
    Sdf = xform(Sdf,'zerobase');
  elseif CONV2SDU == 2,
    fprintf(' detrend...');
    Sdf = xform(Sdf,'detrend');
  else
    fprintf(' conv2sdu...');
    Sdf = xform(Sdf,'tosdu');
  end;
end

% We don't really need this, because sigload takes care of the STM updates
% Sdf = rmfield(Sdf,{'stm','evt','grp'});

if DoAverage,
  fprintf('siggetspk[WARNING]: Averaging singal...\n');
  Spkt.dat = squeeze(hnanmean(Spkt.dat,3));
  Sdf.dat = squeeze(hnanmean(Sdf.dat,3));
end

if isfield(Spkt,'movie'),
  Sdf.movie = Spkt.movie;
end;
