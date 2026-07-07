function [Spkt, Sdf] = siggetspk(Sig,varargin)
%SIGGETSPK - Extract spikes from the raw signal (Cln)
%	[Spkt, Sdf] = SIGGETSPK(Sig,...)
%   - high-pass filters signals, detects zero-crossings and 
%   thresholds to extract spikes from a few neurons.
%
%   Any parameters can be set as ANAP.siggetspk or GRP.xxx.anap.siggetspk
%   in the session file.
%   Supported parameters are
%     ANAP.siggetspk.highpassHz      = 500;       % Highpass filter (Hz)
%     ANAP.siggetspk.base_period     = 'blank';   % period to compute SD
%     ANAP.siggetspk.threshold       = 3.5;       % threshold for spike extraction in SDU
%     ANAP.siggetspk.min_interval_ms = 1.0;       % min. interval of spikes in ms
%     ANAP.siggetspk.binwidth        = (voldt)    % bin width in sec, usually imgtr of fMRI.
%     ANAP.siggetspk.conv2sdu        = 1;         % for SDF: 0|1
%     ANAP.siggetspk.sdfkernel       = 0.025;     % for SDF: SD of the smoothing kernel in sec.
%     ANAP.siggetspk.sdfrate         = 250;       % for SDF: sampling rate of "Sdf"
%
%
%  VERSION :
%    NKL, 10.11.02
%    YM,  01.03.04  do decimation in spksdf.m instead of here, to
%                   to avoid memory problem.
%    YM,  22.12.04  serious bug fix for Spkt.dat by hist(). 
%    YM,  17.01.05  avoid error for D98.at1/at2.
%    YM,  20.01.05  introduces minimal interval between spikes
%    YM,  11.12.09  supports anap.siggetspk.threshold/base_period.
%    YM,  13.02.13  supports "varargin", check amplitude.
%
%  See also SESGGETSPK GETSPK SPKSDF


TEST  = 0;
% THRSD = 3.5;
THRSD = 2.4;    % I changed this to capture smaller spikes and check their width... 18.10.2007

HighPassCutoff = 500;



Ses = goto(Sig.session);
grp = getgrp(Ses,Sig.ExpNo(1));
par = expgetpar(Ses,Sig.ExpNo(1));



CONV2SDU        = 1;
BINWIDTH        = par.stm.voldt;
SDFRATE         = Ses.anap.bands.samprate;
SDFKERNEL       = 0.025;
BASE_PERIOD     = 'blank';
MIN_INTERVAL_MS = 1.0;  % min. interval between spikes
DoAverage       = 0;

% update parameters by the session file -----------------------------------
anap = getanap(Ses,Sig.ExpNo(1));
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
  if isfield(anap.siggetspk,'threshold'),
    THRSD = anap.siggetspk.threshold;
  end
  if isfield(anap.siggetspk,'base_period')
    BASE_PERIOD = anap.siggetspk.base_period;
  end
  if isfield(anap.siggetspk,'highpassHz')
    HighPassCutoff = anap.siggetspk.highpassHz;
  end
  if isfield(anap.siggetspk,'min_interval_ms')
    MIN_INTERVAL_MS = anap.siggetspk.min_interval_ms;
  end
end;


% update parameters by input arguments
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'conv2sdu'}
    CONV2SDU = varargin{N+1};
   case {'binwidth'}
    BINWIDTH = varargin{N+1};
   case {'sdfkernel'}
    SDFKERNEL = varargin{N+1};
   case {'sdfrate'}
    SDFRATE = varargin{N+1};
   case {'threshold' 'thr'}
    THRSD = varargin{N+1};
   case {'base_period' 'base'}
    BASE_PERIOD = varargin{N+1};
   case {'highpasshz' 'highpass_hz' 'highpass'}
    HighPassCutoff = varargin{N+1};
   case {'min_interval_ms' 'min_interval'}
    MIN_INTERVAL_MS = varargin{N+1};
   case {'doaverage' 'average'}
    DoAverage = varargin{N+1};
  end
end


NoChan = size(Sig.dat,2);
NoObsp = size(Sig.dat,3);
if ~isempty(Sig.dat),
  ObsLenPts = size(Sig.dat,1);
  NoChan = size(Sig.dat,2);
  NoObsp = size(Sig.dat,3);
else
  % get data from the original ADF/ADFW.
  adffile = expfilename(Ses,ExpNo,'phys');
  [NoChan,NoObsp,sampt,obslen]= adf_info(adffile);
  % may cause problem if obslen changes between observations...
  ObsLenPts = obslen(1);
  % make sure to use correct value.
  Sig.dx = sampt/1000. * par.adf.tfactor;
  Sig.dxorg = sampt/1000.;
  fprintf('siggetspk: Sig.dat = %s\n',adxfile);
end
[b,a] = butter(4,HighPassCutoff/((1/Sig.dx)/2),'high');


% if 0,		% OLD CODE
%   for ObspNo=1:NoObsp,
% 	for ChanNo=1:NoChan,
% 	  Sig.dat(:,ChanNo,ObspNo) = filtfilt(b,a,Sig.dat(:,ChanNo,ObspNo));
% 	end;
%   end;
  
%   for ObspNo=1:NoObsp,
% 	for ChanNo=1:NoChan,
% 	  base = mean(Sig.dat(:,ChanNo,ObspNo));
% 	  sd   = std(Sig.dat(:,ChanNo,ObspNo));
% 	  thr  = base + THRSD * sd;
% 	  tmp = Sig.dat(:,ChanNo,ObspNo);		% high-pass filtered signal
% 	  tmp(tmp < thr) = 0;					% take pos threshold only
% 	  tmp = diff(tmp);					% differentiate
% 	  tmp = hzerox(tmp);					% find zero x-ings
% 	  Spk{ChanNo,ObspNo} = find(tmp);
% 	end;
%   end;
% end;


baseidx = [];
if any(BASE_PERIOD),
  try,
    baseidx = getStimIndices(Sig,BASE_PERIOD,0,0);
  catch,
    baseidx = [];
    BASE_PERIOD = '';
  end
end

fprintf('Spkt[thrsd=%g base=''%s'' NCh=%d bin=%gms minInterval=%gms]...',THRSD,BASE_PERIOD,NoChan,BINWIDTH*1000,MIN_INTERVAL_MS);

for ObspNo=NoObsp:-1:1,
  for ChanNo=NoChan:-1:1,
	if ~isempty(Sig.dat),
	  tmpwv = squeeze(Sig.dat(:,ChanNo,ObspNo));
	else
	  tmpwv = adx_read(adxfile,ObspNo-1,ChanNo-1);
	end
	tmpwv = filtfilt(b,a,tmpwv);		% high-pass filtered signal
    if ~isempty(baseidx),
      base = mean(tmpwv(baseidx));
      sd   = std(tmpwv(baseidx));
    else
      base = mean(tmpwv(:));
      sd   = std(tmpwv(:));
    end
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
    MIN_INTERVAL = round(MIN_INTERVAL_MS/1000.0/Sig.dx);  % min interval in points
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
    if isempty(tmpspk),
      fprintf(' [no spk ch=%d] ',ChanNo);
      Spk{ChanNo,ObspNo} = [];
    else
      Spk{ChanNo,ObspNo} = tmpspk(find(IDX));
    end
end


  end;
end;
clear tmpwv tmp; tmp{1} = [];

Spkt.session			= Sig.session;
Spkt.grpname			= Sig.grpname;
Spkt.ExpNo              = Sig.ExpNo;

Spkt.dir.dname          = 'Spkt';
if isfield(Sig.dir,'physfile'),
Spkt.dir.physfile		= Sig.dir.physfile;
Spkt.dir.evtfile		= Sig.dir.evtfile;
end
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

% % 22.12.04 YM: simple use of hist with NBINS will not give correct histgram.
% %              so, we have to set edges.
% if ~isempty(par) & isfield(par,'adf') & ~isempty(par.adf),
%   NBINS = round(par.adf.adflen(1)/(BINWIDTH));
%   EDGES = [0:NBINS]/NBINS*par.adf.adflen(1)/Sig.dx;
% else
%   %   % 15.01.05 YM
%   %   % for data that is not compatible to our data-acquisition, like D98.at1/at2
%   %   NBINS = round(Spkt.duration*Spkt.dt/0.25);
%   %   EDGES = [0:NBINS]/NBINS*Spkt.duration/Spkt.dt;
%   %   EDGES = [0:NBINS]/NBINS*Spkt.duration;
%   %   Sig.dx = Spkt.dt;
%   NBINS = round((Spkt.duration*Spkt.dt)/(BINWIDTH));
%   EDGES = ([0:NBINS]/NBINS)*Spkt.duration;
%   Sig.dx = BINWIDTH;;
% end

% this should work for all including catexps where adf screwed up...
EDGES = 0:BINWIDTH:(Spkt.duration*Spkt.dt + BINWIDTH/2);  % in sec
EDGES = EDGES/Spkt.dt;  % in points
NBINS = length(EDGES);

Spkt.dat = zeros(length(EDGES),ChanNo,ObspNo);
for ObspNo=NoObsp:-1:1,
  for ChanNo=NoChan:-1:1,
    % 22.12.04 YM: simple use of hist with NBINS will not give correct histgram.
	%[n,x] = hist(Spkt.times{ChanNo,ObspNo},NBINS);
    if isempty(Spkt.times{ChanNo,ObspNo}),  continue;  end
	n = histc(Spkt.times{ChanNo,ObspNo},EDGES);
	Spkt.dat(:,ChanNo,ObspNo) = n;
  end;
end;

%Spkt.dx			= (x(2)-x(1))*Sig.dx;
Spkt.dx			= (EDGES(2)-EDGES(1))*Spkt.dt;
if isfield(Sig,'dxorg'),
  Spkt.dxorg = Spkt.dx / Sig.dx * Sig.dxorg;
end

if isfield(Sig,'usr'),
  Spkt.usr = Sig.usr;
end;

if isfield(Sig,'evt'),
  Spkt.evt = Sig.evt;
end;

if isfield(Sig,'movie'),
  Spkt.movie = Sig.movie;
end;

Spkt.(mfilename).highpassHz      = HighPassCutoff;
Spkt.(mfilename).base_period     = BASE_PERIOD;
Spkt.(mfilename).threshold       = THRSD;
Spkt.(mfilename).min_interval_ms = BASE_PERIOD;
Spkt.(mfilename).binwidth        = BINWIDTH;
Spkt.(mfilename).average         = DoAverage;


clear Spk Sig tmp;


if DoAverage,
  fprintf('siggetspk[WARNING]: Averaging Spkt...\n');
  Spkt.dat = squeeze(nanmean(Spkt.dat,3));
end

if nargout == 1,  return;  end




fprintf(' Sdf[%gHz kernel=%g]...',SDFRATE,SDFKERNEL);

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

if isnumeric(CONV2SDU),
  tmpstr = 'none';
  if CONV2SDU == 1,
    tmpstr = 'tosdu';
  elseif CONV2SDU == 2,
    tmpstr = 'detrend';
  elseif CONV2SDU == 3,
    tmpstr = 'zerobase';
  end
  CONV2SDU = { tmpstr '' };
elseif ischar(CONV2SDU),
  CONV2SDU = { CONV2SDU '' };
end
if ~isempty(CONV2SDU),
  tmpmethod = CONV2SDU{1};
  tmpepoch  = '';
  if length(CONV2SDU) > 1,
    tmpepoch = CONV2SDU{2};
  end
  if ~isempty(tmpmethod) & ~any(strcmpi({'none','no'},tmpmethod)),
    fprintf(' xform(%s,%s)...',tmpmethod,tmpepoch);
    Sdf = xform(Sdf,tmpmethod,tmpepoch);
  end
end

Sdf.(mfilename).conv2sdu  = CONV2SDU;
Sdf.(mfilename).sdfkernel = SDFKERNEL;
Sdf.(mfilename).sdfrate   = SDFRATE;

% We don't really need this, because sigload takes care of the STM updates
% Sdf = rmfield(Sdf,{'stm','evt','grp'});

if DoAverage,
  fprintf('siggetspk[WARNING]: Averaging Sdf...\n');
  Sdf.dat  = squeeze(nanmean(Sdf.dat,3));
end

if isfield(Spkt,'movie'),
  Sdf.movie = Spkt.movie;
end;
