function blpSpc = expgetblpspc(SesName, ExpNo)
%EXPGETBLPSPC : Computes the spectrogram of each BLP.
%  EXPGETBLPSPC(SESSION,EXPNO) computes the spectrogram of each BLP.
%  The BLP bands are defined in the structure ANAP.blpSpc.  If a band is not found in the
%  existing 'blp' signal, then it is extracted di nuovo, and the spectrogram of the newley
%  extracted blp is computed.
%
%  The aim of the blp-spectrogram is to test the hypothesis that slow fMRI oscillations are
%  mediated by very slow synchronous nervous activity, i.e. in the range of 0.1 Hz. Usually
%  the raw signal is split in bands either by band separation or by applying time-dependent
%  frequency analysis, e.g. spectrogram. The envelope (amplitude) of every frequency band or
%  the power (or the square root of power) of the spectrogram all capture low frequencies
%  (e.g. the BLP can vary with 0.1 or 0.01 Hz over time, provided there is enough
%  data). However, the BLP itself has various components that might be differentially
%  contributing into the fMRI signal. Using the entire BLP, i.e. averaring all frequency
%  components of a BLP may hide interesting correlations between a frequency range and the
%  BOLD signal.
%
%  The specific aim is thus:
%   1. Compute the spectrogram of each BLP (e.g. nm1, nm2, gamma, hgamma, mua)
%   2. 
%  
%
%  NOTE :
%    blpSpc = 
%          session: 'j00fo1'
%          grpname: 'rnd01'
%            ExpNo: 16
%              dir: [1x1 struct]
%              dsp: [1x1 struct]
%              usr: [1x1 struct]
%             chan: 1
%               dx: [10.0000 0.1000]  <--- dt,df
%            dxorg: [10.0000 0.1000]
%              err: [1x1 struct]
%              grp: [1x1 struct]
%              evt: [1x1 struct]
%              stm: [1x1 struct]
%              dat: [44x200x1x7 double] <--- as (t,freq,chan,band,...)
%             info: [1x1 struct]
%          filters: {1x7 cell}
%     unstable_sec: 3.6263
%             freq: [200x1 double]    <--- frequencies
%          spcinfo: [1x1 struct]
%
%   blpSpc.info =
%            band: {1x7 cell}         <--- extracted blp bands
%          lBands: [1 2 3 4 5 6]
%          mBands: 7
%          ....
%
%
%  NOTE};
%    Analysis parameters can be given by ANAP.blpSpc in the session file.
%    % for blp extraction
%    ANAP.blpSpc.band{ 1}  = {[   1     8] 'dethe'  'LFP',  8};
%    ANAP.blpSpc.band{ 2}  = {[   8    12] 'alpha'  'LFP', 12};
%    ANAP.blpSpc.band{ 3}  = {[  12    24] 'nm1'    'LFP', 24};
%    ANAP.blpSpc.band{ 4}  = {[  24    40] 'nm2'    'LFP', 40};
%    ANAP.blpSpc.band{ 5}  = {[  60   100] 'gamma'  'LFP', 60};
%    ANAP.blpSpc.band{ 6}  = {[ 120   250] 'hgamma' 'LFP', 60};
%    ANAP.blpSpc.band{ 7}  = {[1000  3000] 'mua'    'MUA', 60};
%    ANAP.blpSpc.lBands    = [1:6];
%    ANAP.blpSpc.mBands    = [7];
%    % for spectrogram
%    ANAP.blpSpc.twin      = 10;  % time window in seconds
%    ANAP.blpSpc.dt        = 'imgtr';  % dx for spectrogram
%    ANAP.blpSpc.nfft_sec  = 10;  % num. of FFT in seconds
%    ANAP.blpSpc.window    = 'hamming';
%    ANAP.blpSpc.freq      = [0 20];  % frequency range to keep
%    ANAP.blpSpc.power     = 1;
%    ANAP.blpSpc.xform     = {'none','prestim'};
%    ANAP.blpSpc.plot      = 0;
%
%  VERSION :
%    0.90 11.06.08 YM  pre-release
%
%  See also sesgetblpspc siggetblp spectrogram

if nargin < 1,  eval(sprintf('help %s',mfilename)); return;  end

% for BLP extraction
ANAP.band{ 1}  = {[   1     8] 'dethe'  'LFP', 8};
ANAP.band{ 2}  = {[   8    12] 'alpha'  'LFP', 8};
ANAP.band{ 3}  = {[  12    24] 'nm1'    'LFP', 8};
ANAP.band{ 4}  = {[  24    40] 'nm2'    'LFP', 8};
ANAP.band{ 5}  = {[  60   100] 'gamma'  'LFP', 8};
ANAP.band{ 6}  = {[ 120   250] 'hgamma' 'LFP', 8};
ANAP.band{ 7}  = {[1000  3000] 'mua'    'MUA', 8};
ANAP.lBands    = [1:6];
ANAP.mBands    = [7];

% for spectrogram
ANAP.twin      = 20;                    % time window in seconds (defined by the lowest
                                        % frequency change we want to see, e.g. for 0.1 Hz,
                                        % which is the alleged "oscillation" in fMRI, we
                                        % need a 10 seconds window.
ANAP.dt        = 'imgtr';               % dx for spectrogram (defined by the window shift)
ANAP.nfft_sec  = 20;                    % num. of FFT in seconds (used by pwelch); if largen
                                        % than twind then is zero-padded
ANAP.window    = 'hamming';             % window-type
ANAP.freq      = [0 1];                 % frequency range to keep
ANAP.power     = 1;                     % power/amplitude(square-root)
ANAP.xform     = {'none','prestim'};
ANAP.plot      = 0;


Ses = goto(SesName);
grp  = getgrp(Ses,ExpNo);
anap = getanap(Ses,ExpNo);
% override settings by the session file
if isfield(anap,'blpSpc') & ~isempty(anap.blpSpc),
  ANAP = sctmerge(ANAP,anap.blpSpc);
end
if ischar(ANAP.dt) & any(strcmpi(ANAP.dt,{'imgtr','voltr'})),
  if isimaging(Ses,ExpNo),
    tmppar = expgetpar(Ses,ExpNo);
    ANAP.dt = tmppar.pvpar.imgtr;
  else
    ANAP.dt = 0.25;
  end
end


fprintf('%s %s %s/%d: \n', gettimestring,mfilename,Ses.name,ExpNo);

fprintf(' loading blp.');
blp = sigload(Ses,ExpNo,'blp');
if ~isempty(blp),
  blpband = blp.info.band;
else
  blpband = {};
end
BAND_FOUND = zeros(1,length(ANAP.band));
for N = 1:length(ANAP.band),
  spcband = ANAP.band{N};
  for K = 1:length(blpband),
    if isequal(spcband{1},blpband{K}{1}),
      if strcmpi(spcband{2},blpband{K}{2}) & strcmpi(spcband{3},blpband{K}{3}),
        if blpband{K}{4} >= spcband{4},
          BAND_FOUND(N) = K;
          break;
        end
      end
    end
  end
end
fprintf(' band-found=%d/%d,  new bands=%d\n',...
        length(find(BAND_FOUND>0)),length(BAND_FOUND),...
        length(BAND_FOUND)-length(find(BAND_FOUND > 0)));

% update blp
if ~isempty(blp),
  idx = find(BAND_FOUND > 0);
  % blp.dat as (t,chan,band,...)
  blp.dat = blp.dat(:,:,idx,:);
  blp.info.band = blp.info.band(idx);
  [c,ia,ib] = intersect(idx,blp.info.lBands);
  blp.info.lBands = ia;
  [c,ia,ib] = intersect(idx,blp.info.mBands);
  blp.info.mBands = ia;
  if isfield(blp,'filters'),
    blp.filters = blp.filters(idx);
  end
  if isfield(blp,'xform'),
    blp.xform.mean = blp.xform.mean(:,:,idx,:);
    blp.xform.std  = blp.xform.std(:,:,idx,:);
  end
  % resample to 100Hz
  %blp = sigresample(blp,0.01,'rat_tol',0.001);
end

idx = find(BAND_FOUND == 0);
if ~isempty(idx),
  if ~isempty(blp),
    % use the same parameter as blp
    iINFO = blp.info;
  end
  iINFO.band = ANAP.band(idx);
  [c,ia,ib] = intersect(idx,ANAP.lBands);
  iINFO.lBands = ia;
  [c,ia,ib] = intersect(idx,ANAP.mBands);
  iINFO.mBands = ia;
  newblp = expgetblp(Ses,ExpNo,iINFO);
  % resample to 100Hz
  %newblp = sigresample(newblp,0.01,'rat_tol',0.001);
end


if isempty(blp),
  blp = newblp;
  clear newblp;
else
  % now merge old blp and new blp
  oldblp = blp;
  blp = newblp;
  blp.dat = [];
  blp.info.band = {};
  blp.info.lBands = ANAP.lBands;
  blp.info.mBands = ANAP.mBands;
  blp.filters = {};
  if isfield(blp,'xform'),
    blp.xform.mean = [];
    blp.xform.std  = [];
  end
  % why this happens....
  if size(oldblp.dat,1) > size(newblp.dat,1),
    N = size(newblp.dat,1);
    fprintf(' old[%d->%d]...',size(oldblp.dat,1),N);
    oldblp.dat = oldblp.dat(1:N,:,:,:,:);
  elseif size(oldblp.dat,1) < size(newblp.dat,1),
    N = size(oldblp.dat,1);
    fprintf(' new[%d->%d]...',size(newblp.dat,1),N);
    newblp.dat = newblp.dat(1:N,:,:,:,:);
  end
  
  newidx = 1;
  oldidx = 1;
  % blp.dat as (t,chan,band,...)
  for N = 1:length(BAND_FOUND),
    if BAND_FOUND(N) > 0,
      blp.dat = cat(3,blp.dat,oldblp.dat(:,:,oldidx,:,:));
      %size(blp.dat)
      blp.info.band{end+1} = oldblp.info.band{oldidx};
      blp.filters{end+1}   = oldblp.filters{oldidx};
      if isfield(blp,'xform'),
        blp.xform.mean = cat(3,blp.xform.mean,oldblp.xform.mean(:,:,oldidx,:));
        blp.xform.std  = cat(3,blp.xform.std, oldblp.xform.std(:,:,oldidx,:));
      end
      oldidx = oldidx + 1;
    else
      blp.dat = cat(3,blp.dat,newblp.dat(:,:,newidx,:,:));
      %size(blp.dat)
      blp.info.band{end+1} = newblp.info.band{newidx};
      blp.filters{end+1}   = newblp.filters{newidx};
      if isfield(blp,'xform'),
        blp.xform.mean = cat(3,blp.xform.mean,newblp.xform.mean(:,:,newidx,:));
        blp.xform.std  = cat(3,blp.xform.std, newblp.xform.std(:,:,newidx,:));
      end
      newidx = newidx + 1;
    end
  end
  clear oldblp newblp;
end


% compute spectrogram
blpSpc = subSigSpectrogram(blp,ANAP);


if ~nargout,
  sigsave(Ses,ExpNo,'blpSpc',blpSpc);
  clear blpSpc;
end

if ANAP.plot > 0,
  t = [0:size(blpSpc.dat,1)-1]*blpSpc.dx(1);
  f = blpSpc.freq;
  for iCh = 1:size(blpSpc.dat,3),
    tmptitle = sprintf('%s ExpNo=%d Ch=%d',Ses.name,ExpNo,iCh);
    figure('Name',tmptitle);
    for iB = 1:size(blpSpc.dat,4),
      subplot(size(blpSpc.dat,4),1,iB);
      tmpimg = squeeze(blpSpc.dat(:,:,iCh,iB));
      imagesc(t,f,tmpimg');
      set(gca,'ydir','normal');
      xlabel('Time(sec)');
      ylabel('Frequency(Hz)');
      binfo = blpSpc.info.band{iB};
      tmptxt = sprintf('%s(ExpNo=%d) Ch=%d Band=[%g %g]/%gHz',...
                       Ses.name,ExpNo,iCh,binfo{1}(1),binfo{1}(2),binfo{4});
    end
  end
end


return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SigSpc = subSigSpectrogram(Sig,iANAP)

ANAP.twin     = 10;
ANAP.dt       = 10;
ANAP.nfft_sec = 10;
ANAP.window   = 'hamming';
ANAP.freq     = [0 20];  % frequencies to keep
ANAP.power    = 1;
ANAP.xform    = {'none','prestim'};

if nargin > 1,
  ANAP = sctmerge(ANAP,iANAP);
end
  
NTWIN = round(ANAP.twin/Sig.dx(1));
WINDOW = feval(ANAP.window,NTWIN);
NFFT = round(ANAP.nfft_sec/Sig.dx(1));
if NFFT < NTWIN,  NFFT = nextpow2(NTWIN);  end
NOVERLAP = round((ANAP.twin-ANAP.dt)/Sig.dx(1));
Fs   = 1.0/Sig.dx(1);

fprintf(' spc(dt=%.3fsec,twin=%.3fsec,win=%s,nfft=%d)...',...
        (NTWIN-NOVERLAP)*Sig.dx(1),NTWIN*Sig.dx(1),...
        ANAP.window,NFFT);


szdat = size(Sig.dat);
Sig.dat = reshape(Sig.dat,[szdat(1) prod(szdat(2:end))]);

spcdat = [];
for N = size(Sig.dat,2):-1:1,
  [tmpspc,F,T] = spectrogram(Sig.dat(:,N),WINDOW,NOVERLAP,NFFT,Fs);
  if ANAP.power > 0,
    tmpspc = tmpspc .* conj(tmpspc);
  else
    tmpspc = abs(tmpspc);
  end
  spcdat(:,:,N) = tmpspc';  % (f,t) --> (t,f)
end

if length(ANAP.freq) == 1,
  idx = find(F <= ANAP.freq);
  F = F(idx);
  spcdat = spcdat(:,idx,:);
elseif length(ANAP.freq) == 2,
  idx = find(F >= ANAP.freq(1) & F <= ANAP.freq(2));
  F = F(idx);
  spcdat = spcdat(:,idx,:);
end


% recover the original dimension
szspc = size(spcdat);
spcdat = reshape(spcdat,[szspc(1) szspc(2), szdat(2:end)]);


SigSpc = Sig;
if isfield(SigSpc,'dir'),
  SigSpc.dir.dname = sprintf('%sSpc',Sig.dir.dname);
end
SigSpc.dat = [];
SigSpc.dx  = [];
SigSpc.dx(1) = T(2)-T(1);
SigSpc.dx(2) = F(end)-F(end-1);
if isfield(Sig,'dxorg'),
  SigSpc.dxorg = SigSpc.dx;
  Sig.dxorg(1) = SigSpc.dxorg(1) / Sig.dx(1) * Sig.dxorg(1);
  Sig.dxorg(2) = SigSpc.dxorg(2) / Sig.dxorg(1) * Sig.dx(1);
end
if isfield(SigSpc,'xform'),
  SigSpc = rmfield(SigSpc,'xform');
end
SigSpc.dat = spcdat;
SigSpc.freq = F;
SigSpc.spcinfo.twin_pts = NTWIN;
SigSpc.spcinfo.window   = ANAP.window;
SigSpc.spcinfo.noverlap = NOVERLAP;
SigSpc.spcinfo.nfft     = NFFT;
SigSpc.spcinfo.Fs       = Fs;
SigSpc.spcinfo.power    = ANAP.power;
SigSpc.spcinfo.xform    = ANAP.xform;

method = 'none';  epoch = 'prestim';
if ~isempty(ANAP.xform),
  if ischar(ANAP.xform),
    method = ANAP.xform;
  else
    method = ANAP.xform{1};
    epoch  = ANAP.xform{2};
  end
end
fprintf(' xform(%s,%s)...',method,epoch);
if ~isempty(method) & ~strcmpi(method,'none'),
  SigSpc = xform(SigSpc,method,epoch,0,0);
end


fprintf(' done.\n');

return
