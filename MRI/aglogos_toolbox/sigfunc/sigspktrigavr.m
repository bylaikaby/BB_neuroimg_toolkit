function varargout = sigspktrigavr(Spkt,Sig,MAXLAGS_SEC,DO_PCA)
%SIGSPKTRIGAVR - Computes spike-triggered average of SIG.
%  SIGSPKTRIGAVR(SPKT,SIG)
%  SIGSPKTRIGAVR(SPKT,SIG,MAXLAGS_SEC) computes spike-triggered average of SIG.
%
%  SIGSPKTRIGAVR(SPKT,SIG,[],1)
%  SIGSPKTRIGAVR(SPKT,SIG,MAXLAGS_SEC,1) computes spike-triggered PCAs of SIG.
%
%  NOTE :
%   If 'Spkt' contains 'Spkt.times_shf' field, having shuffled spikes,
%   then SIGGETSPKTRIGAVR also operates for it.
%
%   The function requires  grp.confunc.eleconfig/eledist field in the description file.
%
%  VERSION :
%    0.90 21.12.04 YM  pre-release
%    0.91 24.12.04 YM  improved performance
%    0.92 30.12.04 YM  reorganized signal structure
%    0.93 04.01.05 YM  supports shuffled average
%    0.94 05.01.05 YM  supports 'Cln' signal and accepts 'MAXLAGS_SEC'.
%    0.95 07.01.05 YM  supports spectrum of spike-triggered average.
%    0.96 17.01.05 YM  use grp.confunc for D98at1/at2
%    0.97 18.01.05 YM  supports "Brstt" signal as "Spkt" input.
%    0.98 25.01.05 YM  bug fix for D98at1/D98at2
%    0.99 28.01.05 YM  adds .spkchan and .sigchan
%    1.00 07.02.05 YM  supports spike-triggered PCA.
%    1.01 06.01.06 YM  supports if no grp.confunc.eleconfig/eledist.
%
%  See also SESSPKTRIGAVR, DSPSPKTRIGAVR, GETELECOORDS, SPECGRAM

if nargin == 0,  help sigspktrigavr; return;  end

if nargin < 3, MAXLAGS_SEC = [];  end
if nargin < 4, DO_PCA = 0;        end


DEBUG = 0;
CLN_WINDOW = 0.05;

% just for debugging....
if DEBUG,
  Spkt.times = Spkt.times(1:3);
  Spkt.times_shf = Spkt.times_shf(1:3);
  Sig.dat = Sig.dat(:,1:3);
  Sig.chan = Sig.chan(1:3);

  % Algorithm check
  spkt = [200 250 400 570];
  sig = rand(1000,1);
  maxlags = 50;
  % method 1
  lags = -maxlags:maxlags;
  spksig = zeros(length(lags),1);
  for N = 1:length(spkt),
    spksig = spksig + sig(lags+spkt(N));
  end
  spksig = spksig/length(spkt);
  % method 2
  spkdat = zeros(size(sig));  spkdat(spkt) = 1;
  spksig2 = xcorr(sig,spkdat,maxlags);
  spksig2 = spksig2/length(spkt);
  figure;
  plot(spksig); hold on; plot(spksig2,'r')  
end  


% default lags as -8sec to +8 sec.
if isempty(MAXLAGS_SEC), MAXLAGS_SEC = 8;  end
MAXLAGS_PTS = round(MAXLAGS_SEC/Sig.dx);
LAGS = -MAXLAGS_PTS:MAXLAGS_PTS;  % time window in points

MIN_spkt = max(LAGS);
MAX_spkt = size(Sig.dat,1) - max(LAGS);

NSpkCh = length(Spkt.times);
NSigCh = size(Sig.dat,2);
NBands = size(Sig.dat,3);



[coords,eledist,elelist] = subGetCoords(Sig.session,Sig.ExpNo);

% check size of .chan and .dat/.times
if NSpkCh ~= length(Spkt.chan),
  error(' %s: size mismatch between Spkt.chan and Spkt.times',mfilename);
end
if NSigCh ~= length(Sig.chan),
  error(' %s: size mismatch between Sig.chan and Sig.dat',mfilename);
end
% check "coords" and "elelist" include all channels of .chan
for N = 1:length(Spkt.chan),
  if ~any(elelist == Spkt.chan(N)),
    error(' %s: Spkt.chan(%d)=%d is not in "coords" and "elelist".',...
          mfilename,N,Spkt.chan(N));
  end
end
for N = 1:length(Sig.chan),
  if ~any(elelist == Sig.chan(N)),
    error(' %s: Sig.chan(%d)=%d is not in "coords" and "elelist".',...
          mfilename,N,Sig.chan(N));
  end
end



fprintf(' %s: lags=%.1fs, nspk=%d, nchan=%d, %s:',...
        mfilename,MAXLAGS_SEC,NSpkCh,NSigCh,Sig.dir.dname);


DAT = zeros(length(LAGS),NBands,NSpkCh,NSigCh);
NSPK = zeros(1,NSpkCh);
DIST = zeros(NSpkCh,NSigCh);
if DO_PCA,
  NPcs = 10;
  PCS  = zeros(length(LAGS),NPcs,NBands,NSpkCh,NSigCh);
  EIG  = zeros(NPcs,NBands,NSpkCh,NSigCh);
end

%SPKDAT = zeros(size(Sig.dat,1),1);
%if 0,
for iSpk = NSpkCh:-1:1,
  fprintf('.');
  spkt = Spkt.times{iSpk}*Spkt.dt;  % converts to seconds, use Spkt.dt, never Spkt.dx.
  spkt = round(spkt/Sig.dx);		% spkt as in points of Sig.dx.
  spkt = spkt(find(spkt > MIN_spkt & spkt < MAX_spkt));
  if isempty(spkt),  continue;  end
  NSPK(iSpk) = length(spkt);
  %SPKDAT(:) = 0;  SPKDAT(spkt) = 1; 
  for iChan = NSigCh:-1:1,
    DIST(iSpk,iChan) = subGetEleDistance(coords,eledist,elelist,...
                                         Spkt.chan(iSpk),Sig.chan(iChan));
    if DO_PCA,
      tmpdat = subSpkTrigPca(spkt,squeeze(Sig.dat(:,iChan,:)),LAGS,NPcs);
      DAT(:,:,iSpk,iChan)   = tmpdat.reco;
      PCS(:,:,:,iSpk,iChan) = tmpdat.pcs;
      EIG(:,:,iSpk,iChan)   = tmpdat.evar;
      clear tmpdat;
    else
      % ---------------------------------------------------------------------
      % 19.10.2007 NKL SELLECT WAVEFORMS
      % THIS IS NEW CODE, TO SELECT SPIKES ACCORDING TO THEIR AMPLITUDE
      % WE USE THE GETSPKPKS AND ENTER RANGES OF AMPLITUDES TO BE SELECTED
      % SEE GETSPKPKS!
      % FOR THIS PROCEDURE WE DO NOT NEED CROSS-CHANNEL INTERACTIONS
      % ---------------------------------------------------------------------
      if(MAXLAGS_SEC <= CLN_WINDOW),
        if iSpk ~= iChan, continue; end;
        [DAT(:,:,iChan),wform{iChan}] = subSpkTrigAvr(spkt,squeeze(Sig.dat(:,iChan,:)),LAGS);
      else
        DAT(:,:,iSpk,iChan) = subSpkTrigAvr(spkt,squeeze(Sig.dat(:,iChan,:)),LAGS);
      end;
    
    end
    %DAT(:,:,iSpk,iChan) = subXcor(SPKDAT,squeeze(Sig.dat(:,iChan,:)),MAXLAGS_PTS);
  end
end
% reshape for Cln signal, NBands == 1
if NBands == 1,
  DAT = reshape(DAT,[length(LAGS),NSpkCh,NSigCh]);
  if DO_PCA,
    PCS  = reshape(PCS,[length(LAGS),NPcs,NSpkCh,NSigCh]);
    EIG  = reshape(EIG,[NPcs,NSpkCh,NSigCh]);
  end
end
%end
%keyboard

if ~isfield(Spkt,'spkwin_sec'),
  Spkt.spkwin_sec = Spkt.duration * Spkt.dt;		% use Spkt.dt, never Spkt.dx.
end


oSig = rmfield(Sig,{'dat','chan'});
oSig.dir.dname = sprintf('%s%s',Spkt.dir.dname,Sig.dir.dname);  % like SpktCln, Spktblp
if DO_PCA,
  oSig.dir.dname = spritnf('%sPca',oSig.dir.dname);	% like SpktClnPca, SpktblpPca
end
oSig.dsp.func = 'dspspktrigavr';
oSig.dsp.args = {};
oSig.dsp.label = {'Time in sec'; 'Amplitude'};
oSig.spkchan = Spkt.chan;
oSig.sigchan = Sig.chan;
oSig.dat = DAT;
if exist('wform','var'),
  oSig.wform = wform;
else
  oSig.wform = {};
end;
oSig.lags  = LAGS * Sig.dx;
oSig.nspk  = NSPK;
oSig.spkHz = NSPK/Spkt.spkwin_sec;
oSig.dist  = DIST;
if DO_PCA,
  oSig.pca.pcs = PCS;
  oSig.pca.evar = EIG;
end

% compute spectrogram too.
fprintf(' spc...');
% re-reshape for Cln signal, NBands == 1
if NBands == 1, DAT = reshape(DAT,[length(LAGS),1,NSpkCh,NSigCh]);  end
SPC = [];
% LF = 2.0/(length(LAGS)*Sig.dx)/(1.0/Sig.dx/2) = 4/length(LAGS)
NFFT = 2^nextpow2(length(LAGS)/4);
[b,a] = butter(4,[4/length(LAGS)*1.2, 0.4],'bandpass');  % 1.2 as a margin
for iSpk = NSpkCh:-1:1,
  for iChan = NSigCh:-1:1,
    DAT(:,:,iSpk,iChan) = filtfilt(b,a,DAT(:,:,iSpk,iChan));
    for iBand = NBands:-1:1,
      [tmpspc,f] = specgram(DAT(:,iBand,iSpk,iChan),NFFT,1/Sig.dx);
      SPC(:,iBand,iSpk,iChan) = mean(abs(tmpspc),2);
    end
  end
end
fsel = find(f > 0 & f < 100);
SPC = SPC(fsel,:,:,:);
f   = f(fsel);
% reshape for Cln signal, NBands == 1
if NBands == 1, SPC = reshape(SPC,[size(SPC,1),NSpkCh,NSigCh]);  end
oSig.spc = SPC;
oSig.f   = f;



% operate for shuffled spkes
if isfield(Spkt,'times_shf'),
  fprintf('  shuffled:');
  DAT = zeros(length(LAGS),NBands,NSpkCh,NSigCh);
  NSPK = zeros(1,NSpkCh);
  if DO_PCA,
    PCS  = zeros(length(LAGS),NPcs,NBands,NSpkCh,NSigCh);
    EIG  = zeros(NPcs,NBands,NSpkCh,NSigCh);
  end
  %SPKDAT = zeros(size(Sig.dat,1),1);
  for iSpk = NSpkCh:-1:1,
    fprintf('.');
    spkt = Spkt.times_shf{iSpk}*Spkt.dt;  % converts to seconds, use Spkt.dt, never Spkt.dx.
    spkt = round(spkt/Sig.dx);		% spkt as in points of Sig.dx.
    spkt = spkt(find(spkt > MIN_spkt & spkt < MAX_spkt));
    if isempty(spkt),  continue;  end
    NSPK(iSpk) = length(spkt);
    %SPKDAT(:) = 0;  SPKDAT(spkt) = 1;
    for iChan = NSigCh:-1:1,
      if DO_PCA,
        tmpdat = subSpkTrigPca(spkt,squeeze(Sig.dat(:,iChan,:)),LAGS,NPcs);
        DAT(:,:,iSpk,iChan)   = tmpdat.reco;
        PCS(:,:,:,iSpk,iChan) = tmpdat.pcs;
        EIG(:,:,iSpk,iChan)   = tmpdat.evar;
        clear tmpdat;
      else
      % ---------------------------------------------------------------------
      % 19.10.2007 NKL SELLECT WAVEFORMS
      % THIS IS NEW CODE, TO SELECT SPIKES ACCORDING TO THEIR AMPLITUDE
      % WE USE THE GETSPKPKS AND ENTER RANGES OF AMPLITUDES TO BE SELECTED
      % SEE GETSPKPKS!
      % FOR THIS PROCEDURE WE DO NOT NEED CROSS-CHANNEL INTERACTIONS
      % ---------------------------------------------------------------------
      if(MAXLAGS_SEC <= CLN_WINDOW),
        if iSpk ~= iChan, continue; end;
        [DAT(:,:,iChan),wform{iChan}] = subSpkTrigAvr(spkt,squeeze(Sig.dat(:,iChan,:)),LAGS);
      else
        DAT(:,:,iSpk,iChan) = subSpkTrigAvr(spkt,squeeze(Sig.dat(:,iChan,:)),LAGS);
      end;
      %DAT(:,:,iSpk,iChan) = subXcor(SPKDAT,squeeze(Sig.dat(:,iChan,:)),MAXLAGS_PTS);
      end
    end
  end;
  % reshape for Cln signal, Cln.dat = [t,chan]
  if NBands == 1,
    DAT = reshape(DAT,[length(LAGS),NSpkCh,NSigCh]);
    if DO_PCA,
      PCS  = reshape(PCS,[length(LAGS),NPcs,NSpkCh,NSigCh]);
      EIG  = reshape(EIG,[NPcs,NSpkCh,NSigCh]);
    end
  end
  oSig.shuffled.dat = DAT;
  oSig.shuffled.nspk = NSPK;
  oSig.shuffled.spkHz = NSPK/Spkt.spkwin_sec;
  if DO_PCA,
    oSig.shuffled.pca.pcs = PCS;
    oSig.shuffled.pca.evar = EIG;
  end
  
  
  % compute spectrogram too.
  fprintf(' spc...');
  % re-reshape for Cln signal, NBands == 1
  if NBands == 1, DAT = reshape(DAT,[length(LAGS),1,NSpkCh,NSigCh]);  end
  SPC = [];
  % LF = 2.0/(length(LAGS)*Sig.dx)/(1.0/Sig.dx/2) = 4/length(LAGS)
  NFFT = 2^nextpow2(length(LAGS)/4);
  [b,a] = butter(4,[4/length(LAGS)*1.2, 0.4],'bandpass');  % 1.2 as a margin
  for iSpk = NSpkCh:-1:1,
    for iChan = NSigCh:-1:1, 
      DAT(:,:,iSpk,iChan) = filtfilt(b,a,DAT(:,:,iSpk,iChan));
      for iBand = NBands:-1:1,
        [tmpspc,f] = specgram(DAT(:,iBand,iSpk,iChan),NFFT,1/Sig.dx);
        SPC(:,iBand,iSpk,iChan) = abs(tmpspc(:));
      end
    end
  end
  fsel = find(f > 0 & f < 100);
  SPC = SPC(fsel,:,:,:);
  f   = f(fsel);
  % reshape for Cln signal, NBands == 1
  if NBands == 1, SPC = reshape(SPC,[size(SPC,1),NSpkCh,NSigCh]);  end
  oSig.shuffled.spc = SPC;
  oSig.shuffled.f   = f;
end



% for "Brstt" signal
if isfield(Sig,'siggetburst'),
  oSig.siggetburst = Sig.siggetburst;
end


if nargout,
  varargout{1} = oSig;
end

fprintf(' done.\n');


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subfunction to get electrode coordinates
function [coords eledist elelist] = subGetCoords(Session,ExpNo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = getses(Session);
grp = getgrp(Ses,ExpNo);
coords = [];
if isfield(grp,'confunc'),
  eleconfig = grp.confunc.eleconfig;
  eledist   = grp.confunc.eledist;
elseif isfield(Ses.anap,'confunc'),
  eleconfig = Ses.anap.confunc.eleconfig;
  eledist   = Ses.anap.confunc.eledist;
else
  % arbitrary coords...
  fprintf('\nWARNING %s: no grp.confunc.eleconfig/eledist, asumming eledist=1mm.\n',mfilename);
  eleconfig = grp.hardch;
  eledist   = 1;
end
uele = sort(unique(eleconfig));

for N = length(uele):-1:1,
  [y, x] = find(eleconfig == uele(N));
  coords(N,:) = [x y 1];
  elelist(N) = uele(N);
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subfunction to get electrode distance
function Dist = subGetEleDistance(coords,eledist,elelist,xChan,yChan)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xChan = find(elelist == xChan);
yChan = find(elelist == yChan);
Dist = (coords(xChan,:) - coords(yChan,:)) * eledist;
Dist = sqrt(sum(Dist.*Dist));

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subfunction to get spike-triggered average of 'X'
function [Y,dat] = subSpkTrigAvr(SPKT,X,LAGS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Y = zeros(size(X,1),length(LAGS));
Y = zeros(length(LAGS),size(X,2));
for N = 1:length(SPKT),
  %Y = Y + X(:,LAGS+SPKT(N));
  Y = Y + X(LAGS+SPKT(N),:);

  if nargout > 1,
    if ~exist('dat','var'),
      dat = zeros(length(LAGS),length(SPKT));
    end;
    dat(:,N) = X(LAGS+SPKT(N));
  end;
end

Y = Y / length(SPKT);
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subfunction to get spike-triggered average of 'X'
function Y = subXcor(SPKDAT,X,MAXLAGS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% must be xcorr(X,SPKDAT), never xcorr(SPKDAT,X)
for iBand = size(X,2):-1:1,
  Y(:,iBand) = xcorr(X(:,iBand),SPKDAT,MAXLAGS);
end
%Y = xcorr(X,SPKDAT,MAXLAGS);
Y = Y / length(find(SPKDAT));
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subfunction to get spike-triggered average of 'X'
function RET = subSpkTrigPca(SPKT,X,LAGS,NPCS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% limit to 256 Mbytes
MEM_LIMIT = 512e+06;
if length(SPKT)*length(LAGS)*8 > MEM_LIMIT,
  nspikes = round(MEM_LIMIT/8/length(LAGS));
  selspks = randperm(length(SPKT));
  SPKT    = sort(SPKT(selspks(1:nspikes)));
end

% PCADAT as (T,Band,N)
PCADAT = zeros(length(LAGS),size(X,2),length(SPKT));
for N = 1:length(SPKT),
  PCADAT(:,:,N) = X(LAGS+SPKT(N),:);
end

% center the data
m = mean(PCADAT,3);
for N = size(PCADAT,3):-1:1,
  PCADAT(:,:,N) = PCADAT(:,:,N) - m;
end


% now (T,Band,N) --> (N,T,Band)
PCADAT = permute(PCADAT,[3 1 2]);
for iBand = size(PCADAT,3):-1:1,
  tmpdat = PCADAT(:,:,iBand);
  [u, ev, pc] = svds(mycov(tmpdat),NPCS);

keyboard

  ev = diag(ev);
  EVAR(:,iBand) = ev(:);
  PCS(:,:,iBand)  = pc;
  % project data to 'pc'
  tmpprj = tmpdat * pc;	% dim. as (N,NPC)
  PCAPRJ(:,:,iBand) = tmpprj;
  % reconstruct data with 'pc'
  PCAREC(:,:,iBand) = (pc * tmpprj')';	% dim. as (T,N)-->(N,T)
end


RET.reco = squeeze(mean(PCAREC,1));
RET.proj = squeeze(mean(PCAPRJ,1));
RET.evar = EVAR;
RET.pcs  = PCS;
RET.mvec = m;

return;
