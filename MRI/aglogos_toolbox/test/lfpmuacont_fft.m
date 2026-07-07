function SIG = lfpmuacont_fft(Ses,ExpNo,Method)
%LFPMUACONT_FFT
%
%  VERSION :
%    0.90 08.05.05 YM  pre-release
%  See also SESLFPMUACONT

Ses = goto(Ses);
grp = getgrp(Ses,ExpNo);


DEMIX_DECORR = 0;



if ~exist('Method','var'),  Method = 'cor';  end


fprintf(' %s: loading Cln...',mfilename);
CLN = sigload(Ses,ExpNo,'Cln');
if isfield(grp,'findch') & ~isempty(grp.findch),
  fprintf(' removing bad chans (Nbad=%d)...',length(grp.findch));
  CLN.dat(:,grp.findch) = [];
  CLN.chan(grp.findch)  = [];
end
fprintf(' done.\n');


% reduce amount of computation
[IDXmovie IDXblank] = subGetMovieBlankIDX(CLN);
tmpmax = max([max(IDXmovie) max(IDXblank)]);
if tmpmax < size(CLN.dat,1) + round(10/CLN.dx),
  tmpmax = tmpmax + round(10/CLN.dx);
  CLN.dat = CLN.dat(1:tmpmax,:);
end
clear IDXmovie IDXblank tmpmax;


% make sure "Method" is valid
switch lower(Method),
 case {'corr'}
  Method = 'cor';
 case {'coherence'}
  Method = 'coh';
end




info.lcutoff    =  500;      % Before splitting the LFP region (to avoid singularities)
info.mcutoff    =  100;      % Before splitting the MUA region (to avoid singularities)
info.NewFs      = 1000;      % All signals will be resampled
%info.band{1}    = { [0 400],    'LFP',   'LFP' };
info.band{1}    = { [0 150],    'LFP',   'LFP' };
info.band{2}    = { [400 3000], 'MUA',   'MUA' };

% parameters for FIR filter %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
info.flttype    = 'cheby2';
info.lstop      = 1;
info.mstop      = 50;
info.hstop      = 50;
info.dB         = 60;
info.passripple = 0.1;

info.NewFsTr    = 40;       % 60dB decay width for above resampling
info.LowFs      = 110;      % downsample low freq bands for filter stability
info.LowFsTr    = 10;       % 60dB decay width for low freq downsample

tmpf = 0;  fbands = {};
while tmpf < 400,
  if tmpf < 40,
    if tmpf == 0,
      fbands{end+1} = [0.5  tmpf+2];	% avoid problem, gain up by 'low-pass' filter
    else
      fbands{end+1} = [tmpf tmpf+2];
    end
    tmpf = tmpf + 2;
  elseif tmpf < 100,
    fbands{end+1} = [tmpf tmpf+4];
    tmpf = tmpf + 4;
  else
    fbands{end+1} = [tmpf tmpf+10];
    tmpf = tmpf + 10;
  end
end
%info.fbands = fbands;


fprintf(' %s: MUA',mfilename);
fprintf(' HP[%dHz].',info.mcutoff);
mSig = DoFilter(CLN,  info.mcutoff, 'high');
fprintf(' BP[%d-%dHz].',info.band{2}{1}(1),info.band{2}{1}(2));
mSig = DoFilter(mSig, info.band{2}{1},   'bandpass');
fprintf(' ENV.');
mSig.dat = abs(mSig.dat);
fprintf(' DECIM[%.1fHz].',1/CLN.dx/3);
mSig = DoDecimate(mSig,1/CLN.dx/3);
fprintf(' LP[%dHz].',max(info.band{1}{1}));
mSig = DoFilter(mSig, info.band{1}{1},   'low');
fprintf(' DECIM[%.1fHz].',(1.0/mSig.dx) / round((1.0/mSig.dx)/info.NewFs));
mSig = DoDecimate(mSig, info.NewFs);
%fprintf(' tosdu.')
%mSig = xform(mSig,'tosdu');
fprintf(' done.\n');


% Reduce BandWidth Before Extracting LFPs
fprintf(' %s: LFP',mfilename);
fprintf(' LP[%dHz].',info.lcutoff);
lSig = DoFilter(CLN,info.lcutoff,'low');
fprintf(' DECIM[%.1fHz].',1/CLN.dx/3);
lSig = DoDecimate(lSig,1/CLN.dx/3);
fprintf(' LP[%dHz].',max(info.band{1}{1}));
lSig = DoFilter(lSig,info.band{1}{1},'low');
fprintf(' DECIM[%.1fHz].',(1.0/lSig.dx) / round((1.0/lSig.dx)/info.NewFs));
lSig = DoDecimate(lSig, info.NewFs);



% to remove effectively below 25Hz, 
% I should use 30Hz as cut-off frequency by cheby1() not butter().
[b,a] = cheby1(8,0.01,30/(1/lSig.dx/2),'high');
fprintf(' HP[%dHz].',30);
s = size(lSig.dat);
lSig.dat = reshape(lSig.dat,[s(1) prod(s(2:end))]);
lSig.dat = filtfilt(b,a,lSig.dat);
lSig.dat = reshape(lSig.dat,s);
%lSig = DoFilter(lSig,25,'high');



%fprintf(' tosdu.')
%lSig = xform(lSig,'tosdu');
fprintf(' done.\n');

clear CLN;  % no need of CLN

if lSig.dx ~= mSig.dx,
  fprintf(' ERROR %s: sampling rate differs between LFP/MUA.',mfilename);
  keyboard
end


SIG = rmfield(lSig,'dat');
%SIG.dir.dname = mfilename;
SIG.dir.dname = sprintf('lfpmua%s_fft',lower(Method));
SIG.info = info;
SIG.dat = cat(3, lSig.dat, mSig.dat);   clear mSig lSig;

[IDXmovie IDXblank] = subGetMovieBlankIDX(SIG);
Fs = 1.0/SIG.dx;

SIG.con.method   = Method;
SIG.con.idxblank = IDXblank;
SIG.con.idxmovie = IDXmovie;
SIG.con.f        = [];	% given later.

LFP = squeeze(SIG.dat(:,:,1));
MUA = squeeze(SIG.dat(:,:,2));


% PSEUDO-GROUNDING
%mlfp = mean(LFP,2);
%mmua = mean(MUA,2);
%for iCh = size(LFP,2):-1:1,
%  LFP(:,iCh) = LFP(:,iCh) - mlfp;
%  MUA(:,iCh) = MUA(:,iCh) - mmua;
%end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now compute "contrast" by raw signals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
F = 0;
LFPb = { LFP(IDXblank,:) };
LFPm = { LFP(IDXmovie,:) };
MUAb = { MUA(IDXblank,:) };
MUAm = { MUA(IDXmovie,:) };

SIG.conraw.method = Method;
SIG.conraw.idxblank = IDXblank;
SIG.conraw.idxmovie = IDXmovie;
SIG.conraw.f        = []; % given later

switch lower(Method),
 case {'cor'}
  DO_DETREND      = 0;
  DO_DEMIX_DECORR = 0;
  pfunc = @subGetCorrelation;
 case {'kc'}
  DO_DETREND      = 1;
  DO_DEMIX_DECORR = DEMIX_DECORR;
  fprintf(' %s: %s  detrend(%d)-normalize-demix(%d)...',...
          mfilename,Method,DO_DETREND,DO_DEMIX_DECORR);
  LFPm = subDetrendNormalizeDemix(LFPm,DO_DETREND,1,DO_DEMIX_DECORR);
  LFPb = subDetrendNormalizeDemix(LFPb,DO_DETREND,1,DO_DEMIX_DECORR);
  MUAm = subDetrendNormalizeDemix(MUAm,DO_DETREND,1,DO_DEMIX_DECORR);
  MUAb = subDetrendNormalizeDemix(MUAb,DO_DETREND,1,DO_DEMIX_DECORR);
  fprintf(' done.\n');
  pfunc = @subGetKernelCov;
 case {'mi'}
  DO_DETREND      = 1;
  DO_DEMIX_DECORR = DEMIX_DECORR;
  fprintf(' %s: %s detrend(%d)-normalize-demix(%d)...',...
          mfilename,Method,DO_DETREND,DO_DEMIX_DECORR);
  LFPm = subDetrendNormalizeDemix(LFPm,DO_DETREND,1,DO_DEMIX_DECORR);
  LFPb = subDetrendNormalizeDemix(LFPb,DO_DETREND,1,DO_DEMIX_DECORR);
  MUAm = subDetrendNormalizeDemix(MUAm,DO_DETREND,1,DO_DEMIX_DECORR);
  MUAb = subDetrendNormalizeDemix(MUAb,DO_DETREND,1,DO_DEMIX_DECORR);
  fprintf(' done.\n');
  pfunc = @subGetMutualInf;
 otherwise
  fprintf(' %s: error ''Method''=%s not supported yet.\n',mfilename,Method);
  SIG = {};
  return;
end
SIG.conraw.detrend = DO_DETREND;
SIG.conraw.demix   = DO_DEMIX_DECORR;
SIG.conraw.decorr  = DO_DEMIX_DECORR;


fprintf(' %s: %s MUA-LFP ',mfilename,Method);
fprintf(' movie...');
[CXYmovie,F] = pfunc(MUAm,LFPm,F,0,DO_DEMIX_DECORR);
fprintf(' blank...');
[CXYblank,F] = pfunc(MUAb,LFPb,F,0,DO_DEMIX_DECORR);
fprintf(' done.\n');
SIG.conraw.mualfp.blank = CXYblank;
SIG.conraw.mualfp.movie = CXYmovie;
SIG.conraw.f     = F;

fprintf(' %s: %s LFP-LFP ',mfilename,Method);
fprintf(' movie...');
[CXYmovie,F] = pfunc(LFPm,LFPm,F,1,DO_DEMIX_DECORR);
fprintf(' blank...');
[CXYblank,F] = pfunc(LFPb,LFPb,F,1,DO_DEMIX_DECORR);
fprintf(' done.\n');
SIG.conraw.lfplfp.blank = CXYblank;
SIG.conraw.lfplfp.movie = CXYmovie;
SIG.conraw.f     = F;

fprintf(' %s: %s MUA-MUA ',mfilename,Method);
fprintf(' movie...');
[CXYmovie,F] = pfunc(MUAm,MUAm,F,1,DO_DEMIX_DECORR);
fprintf(' blank...');
[CXYblank,F] = pfunc(MUAb,MUAb,F,1,DO_DEMIX_DECORR);
fprintf(' done.\n');
SIG.conraw.muamua.blank = CXYblank;
SIG.conraw.muamua.movie = CXYmovie;
SIG.conraw.f     = F;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute "contrast" for different frequency bands
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%fprintf(' %s: Filtering all bands (nf=%d)',mfilename,length(fbands));
fprintf(' %s: Filtering all bands by FFT ',mfilename);
fprintf(' movie...');
[LFPm MUAm F] = subFilterLFPMUA_FFT(LFP,MUA,IDXmovie,Fs);
fprintf(' blank...');
[LFPb MUAb F] = subFilterLFPMUA_FFT(LFP,MUA,IDXblank,Fs);
clear LFP MUA;
fprintf(' done.\n');


switch lower(Method),
 case {'cor'}
  DO_DETREND      = 0;
  DO_DEMIX_DECORR = 0;
  pfunc = @subGetCorrelation;
 case {'kc'}
  DO_DETREND      = 1;
  DO_DEMIX_DECORR = DEMIX_DECORR;
  fprintf(' %s: %s  detrend(%d)-normalize-demix(%d)...',...
          mfilename,Method,DO_DETREND,DO_DEMIX_DECORR);
  LFPm = subDetrendNormalizeDemix(LFPm,DO_DETREND,1,DO_DEMIX_DECORR);
  LFPb = subDetrendNormalizeDemix(LFPb,DO_DETREND,1,DO_DEMIX_DECORR);
  MUAm = subDetrendNormalizeDemix(MUAm,DO_DETREND,1,DO_DEMIX_DECORR);
  MUAb = subDetrendNormalizeDemix(MUAb,DO_DETREND,1,DO_DEMIX_DECORR);
  fprintf(' done.\n');
  pfunc = @subGetKernelCov;
 case {'mi'}
  DO_DETREND      = 1;
  DO_DEMIX_DECORR = DEMIX_DECORR;
  fprintf(' %s: %s detrend(%d)-normalize-demix(%d)...',...
          mfilename,Method,DO_DETREND,DO_DEMIX_DECORR);
  LFPm = subDetrendNormalizeDemix(LFPm,DO_DETREND,1,DO_DEMIX_DECORR);
  LFPb = subDetrendNormalizeDemix(LFPb,DO_DETREND,1,DO_DEMIX_DECORR);
  MUAm = subDetrendNormalizeDemix(MUAm,DO_DETREND,1,DO_DEMIX_DECORR);
  MUAb = subDetrendNormalizeDemix(MUAb,DO_DETREND,1,DO_DEMIX_DECORR);
  fprintf(' done.\n');
  pfunc = @subGetMutualInf;
 otherwise
  fprintf(' %s: error ''Method''=%s not supported yet.\n',mfilename,Method);
  SIG = {};
  return;
end

SIG.con.detrend = DO_DETREND;
SIG.con.demix   = DO_DEMIX_DECORR;
SIG.con.decorr  = DO_DEMIX_DECORR;

fprintf(' %s: %s MUA-LFP ',mfilename,Method);
fprintf(' movie...');
[CXYmovie,F] = pfunc(MUAm,LFPm,F,0,DO_DEMIX_DECORR);
fprintf(' blank...');
[CXYblank,F] = pfunc(MUAb,LFPb,F,0,DO_DEMIX_DECORR);
fprintf(' done.\n');
SIG.con.mualfp.blank = CXYblank;
SIG.con.mualfp.movie = CXYmovie;
SIG.con.f     = F;

fprintf(' %s: %s LFP-LFP ',mfilename,Method);
fprintf(' movie...');
[CXYmovie,F] = pfunc(LFPm,LFPm,F,1,DO_DEMIX_DECORR);
fprintf(' blank...');
[CXYblank,F] = pfunc(LFPb,LFPb,F,1,DO_DEMIX_DECORR);
fprintf(' done.\n');
SIG.con.lfplfp.blank = CXYblank;
SIG.con.lfplfp.movie = CXYmovie;
SIG.con.f     = F;

fprintf(' %s: %s MUA-MUA ',mfilename,Method);
fprintf(' movie...');
[CXYmovie,F] = pfunc(MUAm,MUAm,F,1,DO_DEMIX_DECORR);
fprintf(' blank...');
[CXYblank,F] = pfunc(MUAb,MUAb,F,1,DO_DEMIX_DECORR);
fprintf(' done.\n');
SIG.con.muamua.blank = CXYblank;
SIG.con.muamua.movie = CXYmovie;
SIG.con.f     = F;




return;





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sig = DoFilter(Sig,lim,mode,edgeFlt,info)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nyq = (1/Sig.dx)/2;
if nargin == 3,
  % USE NORMAL FILTER
  % called like DoFilter(Sig,lim,mode)
  if lim(1) == 0,
    [b,a] = butter(4,lim(2)/nyq,'low'); % for the Delta range!
    %[b,a] = cheby1(8,0.01,lim(2)/nyq,'low');
  else
    [b,a] = butter(4,lim/nyq,mode);
    %[b,a] = cheby1(8,0.01,lim/nyq,mode);
  end;
else
  % USE FIR FILTER
  % called like DoFilter(Sig,lim,mode,edgeFlt,info)
  [b,a] = subDesignFIRFilter(1/Sig.dx,lim,mode,edgeFlt,info);
end

%for SigNo=1:length(Sig),
  s = size(Sig.dat);
  Sig.dat = reshape(Sig.dat,[s(1) prod(s(2:end))]);
  Sig.dat = filtfilt(b,a,Sig.dat);
%   for N=1:size(Sig.dat,2),
%     Sig.dat(:,N) = filtfilt(b,a,Sig.dat(:,N));
%   end;
  Sig.dat = reshape(Sig.dat,s);
%end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = DoDecimate(Sig,NewFs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%nyq = (1/Sig.dx)/2;
FRAC = round(1/Sig.dx/NewFs);
s = size(Sig.dat);
oSig = rmfield(Sig,'dat');
oSig.dx = Sig.dx * FRAC;
Sig.dat = reshape(Sig.dat,[s(1) prod(s(2:end))]);
for N=size(Sig.dat,2):-1:1,
  oSig.dat(:,N) = decimate(Sig.dat(:,N),FRAC);
end;
s(1)=size(oSig.dat,1);
oSig.dat = reshape(oSig.dat,s);

clear Sig;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [b,a] = subDesignFIRFilter(Fs,lim,mode,edgeFlt,info)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  fsamp = 1/Sig.dx;
if lim(1) ==  0, % for the Delta range
  mode = 'low';
end
  
switch lower(mode),
 case {'lowpass','lp','low'}
  if lim(1) == 0,
    fcuts = [lim(2) (lim(2)+edgeFlt)];
  else
    fcuts = [lim(1) (lim(1)+edgeFlt)];
  end
  mags = [1 0];
  devs = [abs(1-10^(info.passripple/20)) 10^(-info.dB/20)];
  [n,Wn,beta,ftype] = kaiserord(fcuts,mags,devs,Fs);
  n = n + rem(n,2);
  b = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');
  a = 1;
 case {'highpass','hp','high'}
  fcuts = [lim(1)-edgeFlt lim(1)];
  mags = [0 1];
  devs = [10^(-info.dB/20) abs(1-10^(info.passripple/20))];
  [n,Wn,beta,ftype] = kaiserord(fcuts,mags,devs,Fs);
  n = n + rem(n,2);
  b = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');
  a = 1; 
 case {'bandpass','bp','band'}
  fcuts = [(lim(1)-edgeFlt) lim(1) lim(2) (lim(2)+edgeFlt)];
  mags = [0 1 0];
  devs = [10^(-info.dB/20)  abs(1-10^(info.passripple/20)) 10^(-info.dB/20)];
  [n,Wn,beta,ftype] = kaiserord(fcuts,mags,devs,Fs);
  n = n + rem(n,2);
  b = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');
  a = 1;
end

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [IDXmovie IDXblank] = subGetMovieBlankIDX(SIG)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

IDXmovie = getStimIndices(SIG,'movie');
IDXblank = getStimIndices(SIG,'blank');

if SIG.stm.dt{1}(1) < 30,
  len = round(SIG.stm.dt{1}(1)/SIG.dx);
  fprintf(' dur(30->%dsec)',SIG.stm.dt{1}(1));
else
  len = round(30/SIG.dx);	% 30 sec
end
IDXmovie = IDXmovie(1:len);
IDXblank = IDXblank(1:len);

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [oLFP,oMUA F] = subFilterLFPMUA_FFT(LFP,MUA,IDX,Fs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

LFP = LFP(IDX,:);
MUA = MUA(IDX,:);
oLFP = {};
oMUA = {};
F    = [];

% 0-10Hz,  0.5Hz resolution
TWIN_SEC = 2;
nfft       = 2^(nextpow2(TWIN_SEC*Fs)-1);
numoverlap = round(nfft*0.8);
fprintf(' [0-10: %d %.1fs].',nfft,nfft/Fs);
tmpB = [];  lfpB = [];
for iCh = size(LFP,2):-1:1,
  [tmpB,tmpF]   = specgram(LFP(:,iCh),nfft,Fs,[],numoverlap);
  lfpB(:,:,iCh) = abs(tmpB);  % (F,T)
end
tmpB = [];  muaB = [];
for iCh = size(MUA,2):-1:1,
  [tmpB,tmpF]   = specgram(MUA(:,iCh),nfft,Fs,[],numoverlap);
  muaB(:,:,iCh) = abs(tmpB);  % (F,T)
end
tmpsel = find(tmpF > 0.1 & tmpF <= 10);
for N = 1:length(tmpsel),
  iF = tmpsel(N);
  F(end+1) = tmpF(iF);
  oLFP{end+1} = squeeze(lfpB(iF,:,:));
  oMUA{end+1} = squeeze(muaB(iF,:,:));
end

% 10-100Hz, 1 Hz resolution
TWIN_SEC = 1;  
nfft       = 2^(nextpow2(TWIN_SEC*Fs)-1);
numoverlap = round(nfft*0.2);
fprintf(' [10-100: %d %.1fs].',nfft,nfft/Fs);
tmpB = [];  lfpB = [];
for iCh = size(LFP,2):-1:1,
  [tmpB,tmpF]   = specgram(LFP(:,iCh),nfft,Fs,[],numoverlap);
  lfpB(:,:,iCh) = abs(tmpB);  % (F,T)
end
tmpB = [];  muaB = [];
for iCh = size(MUA,2):-1:1,
  [tmpB,tmpF]   = specgram(MUA(:,iCh),nfft,Fs,[],numoverlap);
  muaB(:,:,iCh) = abs(tmpB);  % (F,T)
end
tmpsel = find(tmpF > 10 & tmpF <= 100);
for N = 1:length(tmpsel),
  iF = tmpsel(N);
  F(end+1) = tmpF(iF);
  oLFP{end+1} = squeeze(lfpB(iF,:,:));
  oMUA{end+1} = squeeze(muaB(iF,:,:));
end


% >100Hz, 5Hz resolution
TWIN_SEC   = 0.2;
nfft       = 2^(nextpow2(TWIN_SEC*Fs)-1);
numoverlap = round(nfft*0.2);
fprintf(' [100<: %d %.1fs].',nfft,nfft/Fs);
tmpB = [];  lfpB = [];
for iCh = size(LFP,2):-1:1,
  [tmpB,tmpF]   = specgram(LFP(:,iCh),nfft,Fs,[],numoverlap);
  lfpB(:,:,iCh) = abs(tmpB);  % (F,T)
end
tmpB = [];  muaB = [];
for iCh = size(MUA,2):-1:1,
  [tmpB,tmpF]   = specgram(MUA(:,iCh),nfft,Fs,[],numoverlap);
  muaB(:,:,iCh) = abs(tmpB);  % (F,T)
end
tmpsel = find(tmpF > 100 & tmpF < 400);
for N = 1:length(tmpsel),
  iF = tmpsel(N);
  F(end+1) = tmpF(iF);
  oLFP{end+1} = squeeze(lfpB(iF,:,:));
  oMUA{end+1} = squeeze(muaB(iF,:,:));
end

[F sidx] = sort(F);
oLFP = oLFP(sidx);
oMUA = oMUA(sidx);

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [oLFP,oMUA F] = subFilterLFPMUA_EXACT(LFP,MUA,IDX,Fs,Bands)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
margin_pts = round(2*Fs);	% 2sec margin

if min(IDX) <= margin_pts,
  SEL1 = [1:max(IDX)+margin_pts];
else
  SEL1 = [min(IDX)-margin_pts:max(IDX)+margin_pts];
end
IDX1  = [find(SEL1 == min(IDX)):find(SEL1 == max(IDX))];

% to avoid filtering error,
if min(IDX) <= margin_pts,
  % no margin at beginning,
  IDX1 = IDX1(round(1*Fs):end);
end

%
if IDX1(end) < size(LFP,1) - round(5*Fs),
  tmpsel = [1:IDX(end)+round(5*Fs)];
  LFP = LFP(tmpsel,:);
  MUA = MUA(tmpsel,:);
end


%decifac = [1 2 3 5 7 9 12 15 17];
decifac = [1 2 3 5 7 10 15];

for D = length(decifac):-1:1,
  iDeci = decifac(D);
  tmpLFP = [];  tmpMUA = [];
  if iDeci > 1,
    for N = size(LFP,2):-1:1,
      tmpLFP(:,N) = decimate(LFP(:,N),iDeci);
      tmpMUA(:,N) = decimate(MUA(:,N),iDeci);
    end
    tmpsel = [max([round(SEL1(1)/iDeci) 1]):min([round(SEL1(end)/iDeci) size(tmpLFP,1)])];
    tmpidx = [max([round(IDX1(1)/iDeci) 1]):min([round(IDX1(end)/iDeci) size(tmpLFP,1)])];
  else
    tmpLFP = LFP;
    tmpMUA = MUA;
    tmpsel = SEL1;
    tmpidx = IDX1;
  end
  DECI{D}.lfp = tmpLFP(tmpsel,:);
  DECI{D}.mua = tmpMUA(tmpsel,:);
  DECI{D}.idx = tmpidx;
  DECI_F(D)   = Fs / iDeci;
end

for iF = length(Bands):-1:1,
  F(iF) = mean(Bands{iF});

  % fc = 0.3*nyqf = 0.3*NewFs/2 = 0.3*Fs/iDeci/2
  [tmp, iDeci] = min(abs(Bands{iF}(2)./DECI_F*2 - 0.4));
  if iDeci < 1,  iDeci = 1;  end
  if iDeci > length(DECI), iDeci = length(DECI);  end


  
%  fprintf('\n %2d: [%3d %3d] Fs=%.1f, NewFs=%.1fHz, Deci=%d',...
%          iF,Bands{iF}(1),Bands{iF}(2),Fs,DECI_F(iDeci),round(Fs/DECI_F(iDeci)));
  
  tmpLFP = DECI{iDeci}.lfp;
  tmpMUA = DECI{iDeci}.mua;
  indx   = DECI{iDeci}.idx;
  nyqf   = (Fs/2)/iDeci;
  
  if Bands{iF}(2)-Bands{iF}(1) < 5,
    ORDER = 4;
  else
    ORDER = 8;
  end
  
  % band pass filter
  [b,a] = cheby1(ORDER,0.01,Bands{iF}/nyqf,'bandpass');
  %[b,a] = butter(ORDER,Bands{iF}/nyqf,'bandpass');

  if ~any(b) | ~any(a),
    fprintf(' [%3d %3d] Fs=%.1f, NewFs=%.1f-->%.1fHz, Deci=%d-->%d',...
            iF,Bands{iF}(1),Bands{iF}(2),Fs,DECI_F(iDeci),DECI_F(iDeci+1),...
            round(Fs/DECI_F(iDeci)),round(Fs/DECI_F(iDeci+1)));
    %keyboard
    iDeci = iDeci+1;
    tmpLFP = DECI{iDeci}.lfp;
    tmpMUA = DECI{iDeci}.mua;
    indx   = DECI{iDeci}.idx;
    nyqf   = (Fs/2)/iDeci;
    [b,a] = cheby1(ORDER,0.01,Bands{iF}/nyqf,'bandpass');
    %[b,a] = butter(ORDER,Bands{iF}/nyqf,'bandpass');
    if ~any(b) | ~any(a),
      keyboard
    end
  end

  tmpLFP = filtfilt(b,a,tmpLFP);
  tmpMUA = filtfilt(b,a,tmpMUA);
  
  if any(isnan(tmpLFP(:))) | any(isnan(tmpMUA(:))),
    keyboard
  end
  
  
  % rectification, if needed.
  [b,a] = cheby1(ORDER,0.01,max(Bands{iF})/nyqf,'low');
  %[b,a] = butter(ORDER,max(Bands{iF})/nyqf,'low');
  tmpLFP = abs(tmpLFP);
  tmpLFP = filtfilt(b,a,tmpLFP);

  if ~any(b) | ~any(a),
    keyboard
  end
  if any(isnan(tmpLFP(:))) | any(isnan(tmpMUA(:))),
    keyboard
  end

  
  oLFP{iF} = tmpLFP(indx,:);
  oMUA{iF} = tmpMUA(indx,:);
  
  
end


  
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [oLFP,oMUA F] = subFilterLFPMUA(LFP,MUA,IDX,Fs,Bands)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
margin_pts = round(2*Fs);	% 2sec margin

if min(IDX) <= margin_pts,
  tmpsel = [1:max(IDX)+margin_pts];
else
  tmpsel = [min(IDX)-margin_pts:max(IDX)+margin_pts];
end
LFP1 = LFP(tmpsel,:);
MUA1 = MUA(tmpsel,:);
IDX1  = [find(tmpsel == min(IDX)):find(tmpsel == max(IDX))];

% to avoid filtering error,
if min(IDX) <= margin_pts,
  % no margin at beginning,
  IDX1 = IDX1(round(1*Fs):end);
end

DEC_FAC = 2;
Fs2 = Fs / DEC_FAC;
for N=size(LFP,2):-1:1,
  LFP2(:,N) = decimate(LFP(:,N),DEC_FAC);
  MUA2(:,N) = decimate(MUA(:,N),DEC_FAC);
end
tmpsel2 = [max([round(tmpsel(1)/DEC_FAC) 1]):min([round(tmpsel(end)/DEC_FAC) size(LFP2,1)])];
LFP2 = LFP2(tmpsel2,:);
MUA2 = MUA2(tmpsel2,:);
IDX2 = [max([round(IDX1(1)/DEC_FAC) 1]):min([round(IDX1(end)/DEC_FAC) size(LFP2,1)])];

DEC_FAC = 5;
Fs3 = Fs / DEC_FAC;
for N=size(LFP,2):-1:1,
  LFP3(:,N) = decimate(LFP(:,N),DEC_FAC);
  MUA3(:,N) = decimate(MUA(:,N),DEC_FAC);
end
tmpsel3 = [max([round(tmpsel(1)/DEC_FAC) 1]):min([round(tmpsel(end)/DEC_FAC) size(LFP3,1)])];
LFP3 = LFP3(tmpsel3,:);
MUA3 = MUA3(tmpsel3,:);
IDX3 = [max([round(IDX1(1)/DEC_FAC) 1]):min([round(IDX1(end)/DEC_FAC) size(LFP3,1)])];

oLFP = cell(1,length(Bands));
oMUA = cell(1,length(Bands));

for iF = length(Bands):-1:1,
  F(iF) = mean(Bands{iF});
  if max(Bands{iF}) > 100,
    %keyboard
  end
  if max(Bands{iF}) < Fs3/2.2,
    % use decimated data
    nyqf = Fs3/2;
    tmpLFP = LFP3;
    tmpMUA = MUA3;
    indx = IDX3;
  elseif max(Bands{iF}) < Fs2/2.2,
    % use decimated data
    nyqf = Fs2/2;
    tmpLFP = LFP2;
    tmpMUA = MUA2;
    indx = IDX2;
  else
    %keyboard
    nyqf = Fs/2;
    tmpLFP = LFP1;
    tmpMUA = MUA1;
    indx = IDX1;
  end

%   if max(Bands{iF}) < Fs2/3,
%     % use decimated data
%     nyqf = Fs2/2;
%     tmpLFP = LFP2;
%     tmpMUA = MUA2;
%     indx = IDX2;
%   else
%     nyqf = Fs/2;
%     tmpLFP = LFP1;
%     tmpMUA = MUA1;
%     indx = IDX1;
%   end


  if Bands{iF}(2)-Bands{iF}(1) < 5,
    ORDER = 4;
  else
    ORDER = 8;
  end
  
  % band pass filter
  [b,a] = cheby1(ORDER,0.01,Bands{iF}/nyqf,'bandpass');
  tmpLFP = filtfilt(b,a,tmpLFP);
  tmpMUA = filtfilt(b,a,tmpMUA);
  
  if ~any(b) | ~any(a),
    keyboard
  end
  if any(isnan(tmpLFP(:))) | any(isnan(tmpMUA(:))),
    keyboard
  end
  
  
  % rectification, if needed.
  [b,a] = cheby1(ORDER,0.01,max(Bands{iF})/nyqf,'low');
  tmpLFP = abs(tmpLFP);
  tmpLFP = filtfilt(b,a,tmpLFP);

  if ~any(b) | ~any(a),
    keyboard
  end
  if any(isnan(tmpLFP(:))) | any(isnan(tmpMUA(:))),
    keyboard
  end

  
  oLFP{iF} = tmpLFP(indx,:);
  oMUA{iF} = tmpMUA(indx,:);

end

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DAT = subDetrendNormalizeDemix(DAT,DO_DETREND,DO_NORMALIZE,DO_DEMIX)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for iF = length(DAT):-1:1,
  % DETREND
  if DO_DETREND,
    for iCh = 1:size(DAT{iF},2),
      DAT{iF}(:,iCh) = detrend(DAT{iF}(:,iCh));
    end
  end

  % NORMALIZE
  if DO_NORMALIZE,
    mdat = mean(DAT{iF},1);
    sdat = std(DAT{iF},0,1);
    for iCh = 1:size(DAT{iF},2),
      DAT{iF}(:,iCh) = (DAT{iF}(:,iCh) - mdat(iCh)) ./ sdat(iCh);
    end
  end
  
  % DEMIX
  if DO_DEMIX,
    DAT{iF} = DAT{iF}(randperm(size(DAT{iF},1)),:);
  end
end


return;

  
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Cxy,F] = subGetCorrelation(X,Y,Bands,Dummy,Dumm2)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for iF = length(Bands):-1:1,
  tmpX = X{iF};
  tmpY = Y{iF};
  for iX = size(tmpX,2):-1:1,
    for iY = size(tmpY,2):-1:1,
      cxy = corr(tmpX(:,iX),tmpY(:,iY));
      Cxy(iF,iX,iY) = cxy;
    end
  end
end

if iscell(Bands),
  for iF = length(Bands):-1:1,
    F(iF) = mean(Bands{iF});
  end
else
  F = Bands;
end

  
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Cxy,F] = subGetKernelCov(X,Y,Bands,IsSameSig,DO_DECORR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for iF = length(Bands):-1:1,
  tmpX = X{iF};
  tmpY = Y{iF};
  for iX = size(tmpX,2):-1:1,
    % gram schmidt orthogonalization, 
    % process to subtract projectio of vector y on x from y.
    for iY = size(tmpY,2):-1:1,
      if IsSameSig & iX == iY,
        tmpy = tmpY(:,iY);
      else
        if DO_DECORR,
          tmpy = gsdecorr(tmpY(:,iY),tmpX(:,iX));
        else
          tmpy = tmpY(:,iY);
        end
      end
      cxy = contrast_pls2('kc',[tmpX(:,iX),tmpy(:)]);
      Cxy(iF,iX,iY) = cxy;
    end
  end
end

if iscell(Bands),
  for iF = length(Bands):-1:1,
    F(iF) = mean(Bands{iF});
  end
else
  F = Bands;
end

  
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Cxy,F] = subGetMutualInf(X,Y,Bands,IsSameSig,DO_DECORR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for iF = length(Bands):-1:1,
  tmpX = X{iF};
  tmpY = Y{iF};
  for iX = size(tmpX,2):-1:1,
    % gram schmidt orthogonalization, 
    % process to subtract projectio of vector y on x from y.
    for iY = size(tmpY,2):-1:1,
      if IsSameSig & iX == iY,
        tmpy = tmpY(:,iY);
      else
        if DO_DECORR,
          tmpy = gsdecorr(tmpY(:,iY),tmpX(:,iX));
        else
          tmpy = tmpY(:,iY);
        end
      end
      cxy = mi_new('mi',[tmpX(:,iX),tmpy(:)]);
      Cxy(iF,iX,iY) = cxy;
    end
  end
end

if iscell(Bands),
  for iF = length(Bands):-1:1,
    F(iF) = mean(Bands{iF});
  end
else
  F = Bands;
end

  
return;






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Cxy,F] = subGetCorrelationOLD(X,Y,IDX,Fs,Bands,RectifyX,RectifyY)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

margin_pts = round(2*Fs);	% 2sec margin

if min(IDX) <= margin_pts,
  tmpsel = [1:max(IDX)+margin_pts];
else
  tmpsel = [min(IDX)-margin_pts:max(IDX)+margin_pts];
end
X1 = X(tmpsel,:);
if isempty(Y),
  Y1 = [];
else
  Y1 = Y(tmpsel,:);
end
IDX1  = [find(tmpsel == min(IDX)):find(tmpsel == max(IDX))];

% to avoid filtering error,
if min(IDX) <= margin_pts,
  % no margin at beginning,
  IDX1 = IDX1(round(1*Fs):end);
end


DEC_FAC = 4;
Fs2 = Fs / DEC_FAC;
for N=size(X,2):-1:1,
  X2(:,N) = decimate(X(:,N),DEC_FAC);
  if ~isempty(Y),
    Y2(:,N) = decimate(Y(:,N),DEC_FAC);
  end
end
tmpsel2 = [max([round(tmpsel(1)/DEC_FAC) 1]):min([round(tmpsel(end)/DEC_FAC) size(X2,1)])];
X2 = X2(tmpsel2,:);
if isempty(Y),
  Y2 = [];
else
  Y2 = Y2(tmpsel2,:);
end
IDX2 = [max([round(IDX1(1)/DEC_FAC) 1]):min([round(IDX1(end)/DEC_FAC) size(X2,1)])];

DEC_FAC = 9;
Fs3 = Fs / DEC_FAC;
for N=size(X,2):-1:1,
  X3(:,N) = decimate(X(:,N),DEC_FAC);
  if ~isempty(Y),
    Y3(:,N) = decimate(Y(:,N),DEC_FAC);
  end
end
tmpsel3 = [max([round(tmpsel(1)/DEC_FAC) 1]):min([round(tmpsel(end)/DEC_FAC) size(X3,1)])];
X3 = X3(tmpsel3,:);
if isempty(Y),
  Y3 = [];
else
  Y3 = Y3(tmpsel3,:);
end
IDX3 = [max([round(IDX1(1)/DEC_FAC) 1]):min([round(IDX1(end)/DEC_FAC) size(X3,1)])];



Cxy = zeros(length(Bands),size(X,2),size(Y,2));

%for iF = length(Bands):-1:1,
for iF = 1:length(Bands),
  F(iF) = mean(Bands{iF});
  if max(Bands{iF}) < Fs3/2.5,
    % use decimated data
    nyqf = Fs3/2;
    tmpX = X3;
    tmpY = Y3;
    indx = IDX3;
  elseif max(Bands{iF}) < Fs2/2.5,
    % use decimated data
    nyqf = Fs2/2;
    tmpX = X2;
    tmpY = Y2;
    indx = IDX2;
  else
    nyqf = Fs/2;
    tmpX = X1;
    tmpY = Y1;
    indx = IDX1;
  end

%   if max(Bands{iF}) < Fs2/3,
%     % use decimated data
%     nyqf = Fs2/2;
%     tmpX = X2;
%     tmpY = Y2;
%     indx = IDX2;
%   else
%     nyqf = Fs/2;
%     tmpX = X1;
%     tmpY = Y1;
%     indx = IDX1;
%   end


  if Bands{iF}(2)-Bands{iF}(1) < 5,
    ORDER = 4;
  else
    ORDER = 8;
  end
  
  % band pass filter
  [b,a] = cheby1(ORDER,0.01,Bands{iF}/nyqf,'bandpass');
  tmpX = filtfilt(b,a,tmpX);
  if ~isempty(Y),
    tmpY = filtfilt(b,a,tmpY);
  end
  
  if ~any(b) | ~any(a),
    keyboard
  end
  
  if any(isnan(tmpX(:))) | any(isnan(tmpY(:))),
    keyboard
  end
  
  
  % rectification, if needed.
  if RectifyX,
    [b,a] = cheby1(ORDER,0.01,max(Bands{iF})/nyqf,'low');
    tmpX = abs(tmpX);
    tmpX = filtfilt(b,a,tmpX);
  end
  if RectifyY & ~isempty(Y),
    [b,a] = cheby1(ORDER,0.01,max(Bands{iF})/nyqf,'low');
    tmpY = abs(tmpY);
    tmpY = filtfilt(b,a,tmpY);
  end
  tmpX = tmpX(indx,:);
  if isempty(Y),
    tmpY = tmpX;
  else
    tmpY = tmpY(indx,:);
  end

  if ~any(b) | ~any(a),
    keyboard
  end
  if any(isnan(tmpX(:))) | any(isnan(tmpY(:))),
    keyboard
  end

  for iX = size(X,2):-1:1,
    for iY = size(Y,2):-1:1,
      cxy = corr(tmpX(:,iX),tmpY(:,iY));
      Cxy(iF,iX,iY) = cxy;
    end
  end
end

return;




