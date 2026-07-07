function [Spkt, Sdf] = siggetspk(Sig,varargin)
%SIGGETSP - Extract spikes from the raw signal (Cln)
%	[Spkt, Sdf] = SIGGETSPK(Sig,...)
%   - high-pass filters signals, detects zero-crossings and 
%   thresholds to extract spikes from a few neurons.
%
%   Any parameters can be set as ANAP.siggetspk or GRP.xxx.anap.siggetspk
%   in the session file.
%   Supported parameters are
%     ANAP.siggetspk.highpassHz      = 800;       % Highpass filter (Hz)
%     ANAP.siggetspk.base_period     = 'blank';   % period to compute SD
%     ANAP.siggetspk.threshold       = 3.5;       % threshold for spike extraction in SDU
%     ANAP.siggetspk.spkselect       = 1          % runs spike selection.
%     ANAP.siggetspk.min_interval_ms = 1.0;       % min. interval of spikes in ms
%     ANAP.siggetspk.binwidth        = (voldt)    % bin width in sec, usually imgtr of fMRI.
%     ANAP.siggetspk.conv2sdu        = 1;         % for SDF: 0|1
%     ANAP.siggetspk.sdfkernel       = 0.025;     % for SDF: SD of the smoothing kernel in sec.
%     ANAP.siggetspk.sdfrate         = 250;       % for SDF: sampling rate of "Sdf"
%
%
%  VERSION :
%    NKL 10.11.02
%    YM  01.03.04  do decimation in spksdf.m instead of here, to
%                   to avoid memory problem.
%    YM  22.12.04  serious bug fix for Spkt.dat by hist(). 
%    YM  17.01.05  avoid error for D98.at1/at2.
%    YM  20.01.05  introduces minimal interval between spikes
%    YM  11.12.09  supports anap.siggetspk.threshold/base_period.
%    YM  12.02.13  supports "varargin".
%    YM  13.02.13  process through amplitude, cleanup.
%    YM  14.02.13  use rm_neighbors for faster processing.
%    YM  15.02.13  supports Michel's spike selecction.
%
%  See also SESGGETSPK GETSPK SPKSDF rm_neighbors spkselect clndespike

if nargin < 1,  eval(['help ' mfilename]); return;  end

if iscell(Sig),
  for N = 1:length(Sig),
    if nargout > 1
      [Spkt{N} Sdf{N}] = siggetspk(Sig{N},varargin{:});
    else
      Spkt{N} = siggetspk(Sig{N},varargin{:});
    end
  end
  return;
end



TEST  = 0;
THRSD = 3.5;
% THRSD = 2.4;    % I changed this to capture smaller spikes and check their width... 18.10.2007

HighPassCutoff = 800;

SPK_SELECT = 1;


Ses   = goto(Sig.session);
ExpNo = Sig.ExpNo(1);
grp   = getgrp(Ses,ExpNo);
par   = expgetpar(Ses,ExpNo);
anap  = getanap(Ses,ExpNo);

CONV2SDU        = 1;
BINWIDTH        = par.stm.voldt;
SDFRATE         = anap.bands.samprate;
SDFKERNEL       = 0.025;
BASE_PERIOD     = 'blank';
MIN_INTERVAL_MS = 1.0;  % min. interval between spikes
DoAverage       = 0;

% update parameters by the session file -----------------------------------
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
  if isfield(anap.siggetspk,'spkselect')
    SPK_SELECT = anap.siggetspk.spkselect;
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
   case {'spkselect'}
    SPK_SELECT = varargin{N+1};
   case {'doaverage' 'average'}
    DoAverage = varargin{N+1};
  end
end


if ~isempty(Sig.dat),
  ObsLenPts = size(Sig.dat,1);
  NoObsp    = size(Sig.dat,3);
  CHANS     = 1:size(Sig.dat,2);
else
  % get data from the original ADF/ADFW.
  adffile = expfilename(Ses,ExpNo,'phys');
  [tmpn,NoObsp,sampt,obslen]= adf_info(adffile);
  if isfield(grp,'hardch') && ~isempty(grp.hardch),
    CHANS = grp.hardch;
  else
    CHANS = 1:tmpn;
  end
  % may cause problem if obslen changes between observations...
  ObsLenPts = obslen(1);
  % make sure to use correct value.
  Sig.dx = sampt/1000. * par.adf.tfactor;
  Sig.dxorg = sampt/1000.;
  fprintf('siggetspk: Sig.dat = %s\n',adffile);
  clear tmpn sampt obslen;
end

[b,a] = butter(4,HighPassCutoff/((1/Sig.dx)/2),'high');


baseidx = [];
if any(BASE_PERIOD),
  try
    baseidx = getStimIndices(Sig,BASE_PERIOD,0,0);
  catch
    baseidx = [];
    BASE_PERIOD = '';
  end
end

fprintf('Spkt[hp=%gHz thrsd=%g base=''%s'' bin=%gms minInterval=%gms] NCh=%d',...
        HighPassCutoff,THRSD,BASE_PERIOD,BINWIDTH*1000,MIN_INTERVAL_MS,length(CHANS));

MIN_INTERVAL = round(MIN_INTERVAL_MS/1000.0/Sig.dx);  % min interval in points

Spk = cell(length(CHANS),NoObsp);
for iChan=1:length(CHANS),
  ChanNo = CHANS(iChan);
  if mod(iChan,10) == 0,
    fprintf('%d',iChan);
  else
    fprintf('.');
  end
  for iObsp=NoObsp:-1:1,
	if ~isempty(Sig.dat),
	  tmpwv = squeeze(Sig.dat(:,ChanNo,iObsp));
	else
      tmpwv = adfread(Ses,ExpNo,iObsp,ChanNo);
	  %tmpwv = adf_read(adxfile,iObsp-1,ChanNo-1);
	end
	tmpwv = filtfilt(b,a,tmpwv);		% high-pass filtered signal
    if ~isempty(baseidx),
      base = nanmean(tmpwv(baseidx));
      sd   = nanstd(tmpwv(baseidx));
    else
      base = nanmean(tmpwv(:));
      sd   = nanstd(tmpwv(:));
    end
    
    % 20.01.05 YM: simple zero x-ing is not good enough, very sensitve to noises.
    % bad case resulting, ~20% of spikes with a interval less than 1ms
    %                     ~30% of spikes with a interval less than 2ms
    % OLD CODE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% thr  = base + THRSD * sd;
	% tmpwv(tmpwv < thr) = 0;			% take pos threshold only
	% tmpwv = diff(tmpwv);			% differentiate
	% tmpwv = hzerox(tmpwv);			% find zero x-ings
	% Spk{iChan,iObsp} = find(tmpwv);
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
    % NEW CODE, 20.01.05 method-1 %%%%%%%%%%%%%%%%%%%%%
	% thr  = base + THRSD * sd;
	% tmpwv(tmpwv < thr) = 0;			% take pos threshold only
    % detects the first rising edge, that crosses threshold
    % tmpwv(find(tmpwv ~= 0)) = 1;
	% Spk{iChan,iObsp} = find(diff([0;tmpwv(:)]) > 0);

    
    % NEW CODE, 20.01.05 method-2 %%%%%%%%%%%%%%%%%%%%%
	% thr  = base + THRSD * sd;
	% tmpwv(tmpwv < thr) = 0;			% take pos threshold only
    % % detects zero x-ing and remove too close spikes
	% tmpwv = diff(tmpwv);			% differentiate
	% tmpwv = hzerox(tmpwv);			% find zero x-ings
	% %Spk{iChan,iObsp} = find(tmpwv);
    % tmpspk = find(tmpwv);
    % IDX = zeros(size(tmpspk));
    % IDX(1) = 1;
    % spkpre = 1;  spknow = 2;
    % while spknow <= length(tmpspk),
    %   if tmpspk(spknow) - tmpspk(spkpre) > MIN_INTERVAL,
    %     spkpre = spknow;
    %     IDX(spknow) = 1;
    %   end
    %   spknow = spknow + 1;
    % end
    % %fprintf('%d --> %d\n',length(tmpspk),length(find(IDX)));
    % if isempty(tmpspk),
    %   fprintf(' [no spk ch=%d] ',iChan);
    %   Spk{iChan,iObsp} = [];
    % else
    %   Spk{iChan,iObsp} = tmpspk(find(IDX));
    % end

    
    % NEW CODE, 13.02.13 method-3 %%%%%%%%%%%%%%%%%%%%%
    if sd < eps,
      tmpwv(:) = 0;
    else
      tmpwv = (tmpwv - base)/sd;
    end
    tmpwvA = abs(tmpwv);
    %tic
    [tmpval, tmpspk] = findpeaks(tmpwvA,'MINPEAKHEIGHT',THRSD);
	%tmpspk = hzerox(diff(tmpwvA));			% find zero x-ings
    %tmpspk(end+1:end+2) = 0;
    %tmpspk = circshift(tmpspk,2);
    %tmpspk = find(tmpspk > 0);
    %tmpval = tmpwvA(tmpspk);
    if MIN_INTERVAL > 0
      [tmpval ix] = sort(tmpval,'descend');
      tmpspk = tmpspk(ix);
      % nspk = length(tmpval);
      % for ispk = 1:nspk,
      %   if tmpspk(ispk) == 0,  continue;  end
      %   is = tmpspk(ispk) - MIN_INTERVAL;
      %   ie = tmpspk(ispk) + MIN_INTERVAL;
      %   for jspk = ispk+1:nspk,
      %     if tmpspk(jspk) >= is && tmpspk(jspk) <= ie
      %       tmpspk(jspk) = 0;
      %     end
      %   end
      % end
      % tmpidx = tmpspk > 0;
      % tmpspk = tmpspk(tmpidx);
      % tmpval = tmpval(tmpidx);
      
      [tmpspk tmpidx] = rm_neighbors(tmpspk,MIN_INTERVAL);

      tmpval = tmpval(tmpidx);
      [tmpspk ix] = sort(tmpspk,'ascend');
      tmpval = tmpval(ix);
    end
    %[tmpval, tmpspk] = findpeaks(tmpwvA,'MINPEAKHEIGHT',THRSD,'MINPEAKDISTANCE',MIN_INTERVAL);
    %toc
    if isempty(tmpspk),  fprintf(' [no spk ch=%d/obsp=%d] ',iChan,iObsp);  end
    Spk{iChan,iObsp} = tmpspk;
    
  end
end
clear tmpwv tmp;

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


if any(SPK_SELECT),
  ampPercentile = .05;
  powratio      = 3;
  fprintf('\n spkselect : [ampPercentile=%g%% powratio=%g].',ampPercentile*100,powratio);
  Spkt = spkselect(Spkt,'Cln',Sig,...
                   'ampPercentile',ampPercentile,'powratio',powratio);
  clear ampPercentile powratio;
  fprintf(' done.\n');
end


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

Spkt.dat = zeros(length(EDGES),length(CHANS),NoObsp);
for iChan = 1:length(CHANS),
  for iObsp = 1:NoObsp
    % 22.12.04 YM: simple use of hist with NBINS will not give correct histgram.
	%[n,x] = hist(Spkt.times{iChan,iObsp},NBINS);
    if isempty(Spkt.times{iChan,iObsp}),  continue;  end
	n = histc(Spkt.times{iChan,iObsp},EDGES);
	Spkt.dat(:,iChan,iObsp) = n;
  end
end


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
if isfield(Sdf,'times_spkcdt'),
  Sdf = rmfield(Sdf,'times_spkcdt');
end

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
