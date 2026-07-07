function SIG = lfpmuacoh(Ses,ExpNo,TWIN_SEC)
%LFPMUACOH
%
%  VERSION :
%    0.90 xx.02.05 YM  pre-release
%
%  See also SESLFPMUACONT, LFPMUACONT_FFT

Ses = goto(Ses);
grp = getgrp(Ses,ExpNo);

if nargin < 3,  TWIN_SEC = [];  end


if isempty(TWIN_SEC) | TWIN_SEC <= 0,
  TWIN_SEC = 4;
end


fprintf(' %s: loading Cln...',mfilename);
CLN = sigload(Ses,ExpNo,'Cln');
if isfield(grp,'findch') & ~isempty(grp.findch),
  fprintf(' removing bad chans (Nbad=%d)...',length(grp.findch));
  CLN.dat(:,grp.findch) = [];
  CLN.chan(grp.findch)  = [];
end
fprintf(' done.\n');

[IDXmovie IDXblank] = subGetMovieBlankIDX(CLN);
% reduce amount of computation
[IDXmovie IDXblank] = subGetMovieBlankIDX(CLN);
tmpmax = max([max(IDXmovie) max(IDXblank)]);
if tmpmax < size(CLN.dat,1) + round(10/CLN.dx),
  tmpmax = tmpmax + round(10/CLN.dx);
  CLN.dat = CLN.dat(1:tmpmax,:);
end
clear IDXmovie IDXblank tmpmax;



info.lcutoff    =  500;      % Before splitting the LFP region (to avoid singularities)
info.mcutoff    =  100;      % Before splitting the MUA region (to avoid singularities)
info.NewFs      = 1000;      % All signals will be resampled
info.band{1}    = { [0 400],    'LFP',   'LFP' };
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
%fprintf(' tosdu.')
%lSig = xform(lSig,'tosdu');
fprintf(' done.\n');

clear CLN;  % no need of CLN

if lSig.dx ~= mSig.dx,
  fprintf(' ERROR %s: sampling rate differs between LFP/MUA.',mfilename);
  keyboard
end


SIG = rmfield(lSig,'dat');
SIG.dir.dname = mfilename;
SIG.info = info;
SIG.dat = cat(3, lSig.dat, mSig.dat);   clear mSig lSig;

[IDXmovie IDXblank] = subGetMovieBlankIDX(SIG);
Fs = 1.0/SIG.dx;
TWIN_PTS = 2^nextpow2(TWIN_SEC/SIG.dx);

SIG.con.method = 'coh';
SIG.con.window = TWIN_PTS;
SIG.con.window_sec = TWIN_PTS * SIG.dx;
SIG.con.idxblank = IDXblank;
SIG.con.idxmovie = IDXmovie;
SIG.con.f        = [];	% given later.

LFP = squeeze(SIG.dat(:,:,1));
MUA = squeeze(SIG.dat(:,:,2));


% PSEUDO GROUNDING
%mlfp = mean(LFP,2);
%mmua = mean(MUA,2);
%for iCh = size(LFP,2):-1:1,
%  LFP(:,iCh) = LFP(:,iCh) - mlfp;
%  MUA(:,iCh) = MUA(:,iCh) - mmua;
%end


fprintf(' %s: MUA-LFP Coh[TWIN=%d(%.1fs)]',mfilename,TWIN_PTS,TWIN_PTS*SIG.dx);
fprintf(' movie...');
[CXYmovie,F] = subGetCoherence(MUA(IDXmovie,:),LFP(IDXmovie,:),TWIN_PTS,Fs);
fprintf(' blank...');
[CXYblank,F] = subGetCoherence(MUA(IDXblank,:),LFP(IDXblank,:),TWIN_PTS,Fs);
fprintf(' done.\n');
SIG.con.mualfp.blank = CXYblank;
SIG.con.mualfp.movie = CXYmovie;
SIG.con.f     = F;

fprintf(' %s: LFP-LFP Coh[TWIN=%d(%.1fs)]...',mfilename,TWIN_PTS,TWIN_PTS*SIG.dx);
fprintf(' movie...');
[CXYmovie,F] = subGetCoherence(LFP(IDXmovie,:),LFP(IDXmovie,:),TWIN_PTS,Fs);
fprintf(' blank...');
[CXYblank,F] = subGetCoherence(LFP(IDXblank,:),LFP(IDXblank,:),TWIN_PTS,Fs);
fprintf(' done.\n');
SIG.con.lfplfp.blank = CXYblank;
SIG.con.lfplfp.movie = CXYmovie;
SIG.con.f     = F;

fprintf(' %s: MUA-MUA Coh[TWIN=%d(%.1fs)]...',mfilename,TWIN_PTS,TWIN_PTS*SIG.dx);
fprintf(' movie...');
[CXYmovie,F] = subGetCoherence(MUA(IDXmovie,:),MUA(IDXmovie,:),TWIN_PTS,Fs);
fprintf(' blank...');
[CXYblank,F] = subGetCoherence(MUA(IDXblank,:),MUA(IDXblank,:),TWIN_PTS,Fs);
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
function [Cxy,F] = subGetCoherence(X,Y,TWIN_PTS,Fs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

OVERLAP_PTS = round(TWIN_PTS*0.2);

for iX = size(X,2):-1:1,
  for iY = size(Y,2):-1:1,
    [cxy,F] = mscohere(X(:,iX),Y(:,iY),TWIN_PTS,OVERLAP_PTS,TWIN_PTS,Fs);
    Cxy(:,iX,iY) = cxy(:);
  end
end


return;
