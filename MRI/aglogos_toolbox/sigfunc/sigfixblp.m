function oSig = sigfixblp(Sig,USE_FIR,MIRROR_EDGES,Demo)
%SIGFIXBLP - Add/Modify a band in BLP
% OSIG = SIGFIXBLP (SIG) is here used to add the LFPN band for compatibility with the Nature
% 2001 work.
% NKL 14.01.06
  
if nargin < 1,  help sigfixblp; return;  end;

oSig = {};
if nargin < 2,  USE_FIR = [];  end
if nargin < 3,  MIRROR_EDGES = [];  end

if ~isstruct(Sig),
  fprintf('%s expects a structure (e.g. Cln) as input\n',mfilename);
  return;
end;

% DEFAULT VALUES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(USE_FIR),       USE_FIR = 1;       end
if isempty(MIRROR_EDGES),  MIRROR_EDGES = 1;  end
USE_ANDREI_FUNCS = 0;
DOPLOT           = 0;

info.band{ 1}       = {[  40   130] 'LFPN'    'LFP', 30};

info.lBands     = [1];    % Bands in the LFP range

info.lcutoff    = 500;      % Before splitting the LFP region (to avoid singularities)
info.mcutoff    = 100;      % Before splitting the MUA region (to avoid singularities)
info.NewFs      = 250;     % All signals will be resampled at 250Hz
info.NewFsTr    = info.NewFs*0.08;

% parameters for FIR filter %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
info.flttype    = 'cheby2';
info.lstop      = 1;
info.mstop      = 50;
info.hstop      = 50;
info.dB         = 60;
info.passripple = 0.1;

info.NewFsTr    = info.NewFs*0.08;       % 60dB decay width for above resampling
info.LowFs      = 110;      % downsample low freq bands for filter stability
info.LowFsTr    = 10;       % 60dB decay width for low freq downsample


% parameters to minimize unstable periods in both time edges %%%%%%%%%%%%%%%%
info.mirror     = MIRROR_EDGES;

% SDU conversion
info.conv2sdu   = 0;

% UPDATE "info" parameters by the session file. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(Sig.session);
grp = getgrp(Ses,Sig.ExpNo(1));

% DO NOT UPDATE ANYTHING -- FOR FIXING THE SIGNAL
% NKL 14.01.06
% first update by ANAP.sigfixblp
if isfield(Ses.anap,'sigfixblp') & ~isempty(Ses.anap.sigfixblp),
  fnames = fieldnames(Ses.anap.sigfixblp);
  for N = 1:length(fnames),
    info.(fnames{N}) = Ses.anap.sigfixblp.(fnames{N});
  end
  fprintf('\n%s:Updated params(n=%d) by ANAP.sigfixblp.',mfilename,length(fnames));
end

% finally ovewrite by GRP.xxx.sigfixblp
if isfield(grp,'anap') & isfield(grp.anap,'sigfixblp') & ~isempty(grp.anap.sigfixblp),
  fnames = fieldnames(grp.anap.sigfixblp);
  for N = 1:length(fnames),
    info.(fnames{N}) = grp.anap.sigfixblp.(fnames{N});
  end
  fprintf('\n%s:Updated params(n=%d) by GRP.%s.anap.sigfixblp.',mfilename,length(fnames),grp.name);
end

if exist('Demo','var'),
  info.envelop = 0;
  DOPLOT=1;
end;

% check very old data having multiple obsp.
OLD_DATA = 0;
if ndims(Sig.dat) == 3,
  % (t,chan,obsp) --> (t,chan*obsp)
  sz = size(Sig.dat);
  Sig.dat = reshape(Sig.dat,[sz(1) prod(sz(2:end))]);
  OLD_DATA = 1;
end

if USE_ANDREI_FUNCS > 0,
  % Use FIR fiter develped by Andrei/Arthur.
  [oSig FiltPrms] = subGetBlpAndrei(Sig,info);
else
  % normal signal processing, can be FIR or normal IIR
  [oSig FiltPrms] = subGetBlpNormal(Sig,info, USE_FIR);
end
oSig.filters = FiltPrms;

if isfield(oSig,'dxorg'),
  oSig.dxorg = oSig.dx * Sig.dxorg / Sig.dx;
end

if OLD_DATA > 0,
  sz(1) = size(oSig.dat,1);
  sz(end+1) = size(oSig.dat,3);
  % (t,chan*obsp,band) --> (t,chan,obsp,band)
  oSig.dat = reshape(oSig.dat,sz);
  % (t,chan,obsp,band) --> (t,chan,band) by average
  oSig.dat = mean(oSig.dat,3);
  sz = [sz(1) sz(2) sz(4)];
  oSig.dat = reshape(oSig.dat,sz);
end

if DOPLOT,
  dspblp(oSig);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to make "blp" with FIR filtering.
function [oSig FiltPrms] = subGetBlpAndrei(Cln,info)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
oSig = {};  FiltPrms = {};

USE_FIR = 1;

% EXTRACT LFP BANDS
if ~isempty(info.lBands),  fprintf('\n%s:LFP(FIR=%d) ',mfilename, USE_FIR);  end
info.envelop = info.lenvelop;
for B=info.lBands,
  [Lfp fprms] = subAndrei_fltlow(Cln,info,B);
  oSig = DoCat(oSig,Lfp);
  FiltPrms{B} = fprms;
  clear Lfp;
end

if 0,
  % NOW EXACTRACT MUA
  if ~isempty(info.mBands),  fprintf('\n%s:MUA(FIR=%d) ',mfilename,USE_FIR);  end
  info.envelop = info.menvelop;
  for B=info.mBands,
    band = info.band{B};
    [Mua,b,a] = subAndrei_filterSig(Cln,info.band{B}{1},info.lstop,info);
    Mua.dat = abs(Mua.dat);
    [Mua,b,a] = subAndrei_filterSig(Mua,info.NewFs,info.NewFsTr,info);
    oSig = DoCat(oSig,Mua);
    FiltPrms{B} = fprms;
    clear Mua;
  end
end;
  

oSig.dsp.func   = 'dspblp';
oSig.dir.dname  = 'blp';
oSig.info       = info;
oSig.info.date  = date;
oSig.info.time  = gettimestring;
%oSig.info.func  = dir(which(mfilename));
oSig.filters    = FiltPrms;


if info.conv2sdu > 0,
  oSig = xform(oSig,'tosdu');
end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to make "blp" with normal filtering.
function [oSig FiltPrms] = subGetBlpNormal(Sig,info, USE_FIR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
oSig = {};  FiltPrms = {};  fprms = [];

DECI = 8;

% Reduce BandWidth Before Extracting LFPs
fprintf('\n%s:LFP LP[%dHz].',mfilename,info.lcutoff);
lSig = DoFilter(Sig,info.lcutoff,'low',[],info,0);
% use decimation to avoid mismatch of time length to MUA
fprintf('DECIM[%.1fHz].',1/lSig.dx/DECI);
lSig = DoDecimate(lSig,1/lSig.dx/DECI);
%fprintf('RESAMP[%dHz].',info.lcutoff*2);
%lSig = DoResample(lSig,info.lcutoff*2);          % It filters, DECIMATES, etc.

if ~isempty(info.lBands),
  fprintf('\n%s:LFP(FIR=%d,MIRROR=%d) ',mfilename, USE_FIR, info.mirror);
end
SAME_SIG = [];
for B=info.lBands,
  band = info.band{B};
  % band pass filtering %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  fprintf('BP[%d-%d].',band{1}(1),band{1}(2));
  if isempty(SAME_SIG),
    [tmp fprms] = DoFilter(lSig,band{1},'bandpass',info.lstop,info,USE_FIR);
  else
    fprintf('=');
    tmp = SAME_SIG;
  end
  if B < length(info.band) & all(band{1} == info.band{B+1}{1}),
    SAME_SIG = tmp;
  else
    SAME_SIG = [];
  end
  
  % do rectification if needed. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if band{4} > 0,
    % Hilbert transform is not appropriate to get envelopes,
    % so do abs() and low-pass the signals.

    %fprintf('Hil.');
    %[tmp fprms] = DoFilterHilbert(lSig,band{1},'bandpass',info.NewFs,info.KEEP_PHASE,...
    %                              info.lstop,info,USE_FIR);

    fprintf('Abs.');
    tmp.dat = abs(tmp.dat);
    fw = ceil((band{1}(2) - band{1}(1))/2);  % half width
    if band{4} > fw,
      fprintf('%s WARNING:  rectHz(%.2f) is higher than band pass width(%.2f).!!! ',...
              mfilename,band{4},fw);
    else
      fw = band{4};
    end
    tmp = DoFilter(tmp,[0 fw],'bandpass',info.lstop,info,USE_FIR);
  end;
  
  % resample to designed Fs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  tmp = DoResample(tmp,info.NewFs,info.NewFsTr,info,0);
  oSig = DoCat(oSig,tmp);
  FiltPrms{B} = fprms;
  clear tmp;
end;
clear lSig SAME_SIG tmp;

if 0,
  % NOW EXACTRACT MUA
  if ~isempty(info.mBands),
    fprintf('\n%s:MUA(FIR=%d,MIRROR=%d) ',mfilename, USE_FIR, info.mirror);
  end
  %mSig = Sig;
  mSig = DoFilter(Sig,info.mcutoff,'high',[],info,0);
  SAME_SIG = [];
  for B=info.mBands,
    band = info.band{B};
    % band pass filtering %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf('BP[%d-%d].',band{1}(1),band{1}(2));
    if isempty(SAME_SIG),
      [tmp fprms] = DoFilter(mSig,band{1},'bandpass',info.mstop,info,USE_FIR);
    else
      fprintf('=');
      tmp = SAME_SIG;
    end
    if B < length(info.band) & all(band{1} == info.band{B+1}{1}),
      SAME_SIG = tmp;
    else
      SAME_SIG = [];
    end
    
    % rectification if needed %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if band{4} > 0,
      % MUA band [400 3000] is too broad to apply Hilbert ransform.
      % It would be appropriate to use the conventional method using abs().
      
      %fprintf('Hil.');
      %[tmp fprms] = DoFilterHilbert(mSig,band{1},'bandpass',info.NewFs,info.KEEP_PHASE,...
      %                              info.mstop,info,USE_FIR);
      
      fprintf('Abs.');
      tmp.dat = abs(tmp.dat);
      fw = ceil((band{1}(2) - band{1}(1))/2);  % half width
      if band{4} > fw,
        fprintf('%s WARNING:  RectHz(%.2f) is higher than band pass width(%.2f).!!! ',...
                mfilename,band{4},fw);
      else
        fw = band{4};
      end
      % to match the signal length use resample twice
      %tmp = DoDecimate(tmp,1/tmp.dx/DECI);
      tmp = DoResample(tmp,1/tmp.dx/DECI,info.NewFsTr,info,USE_FIR);
      tmp = DoFilter(tmp,[0 fw],'bandpass',info.lstop,info,USE_FIR);
      tmp = DoResample(tmp,info.NewFs,info.NewFsTr,info,0);  % USE_FIR=1 takes forever
                                                             %size(tmp.dat), size(oSig.dat)
    else
      % to match the signal length use resample twice
      tmp = DoResample(tmp,1/tmp.dx/DECI,info.NewFsTr,info,USE_FIR);
      tmp = DoResample(tmp,info.NewFs,info.NewFsTr,info,0);  % USE_FIR=1 takes forever
    end;
    oSig = DoCat(oSig,tmp);
    FiltPrms{B} = fprms;
    clear tmp;
  end;

  clear mSig Sig tmp SAME_SIG;
end;

oSig.dsp.func   = 'dspblp';
oSig.dir.dname  = 'blp';
oSig.info       = info;
oSig.info.date  = date;
oSig.info.time  = gettimestring;
%oSig.info.func  = dir(which(mfilename));
oSig.filters    = FiltPrms;


% gettting information for unstable periods caused by filtering.
f_orderSec = [];
for N = 1:length(oSig.filters),
  f_orderSec(N) = oSig.filters{N}.order/oSig.filters{N}.Fs;
end
f_orderSec = max(f_orderSec);
oSig.unstable_sec = f_orderSec;

if USE_FIR > 0,
  if info.mirror > 0,
    fprintf(' --WARNING: mirrored(%.3fsec)',f_orderSec);
  else
    fprintf(' --WARNING: UNSTABLE PERIODS(%.3fsec)',f_orderSec);
  end
else
end



if info.conv2sdu > 0,
  %oSig = tosdu(oSig);
  oSig = xform(oSig,'tosdu');
end



return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Sig fprms] = DoFilterHilbert(Sig,lim,mode,Fs,KEEP_PHASE,edgeFlt,info,USE_FIR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nyq = (1/Sig.dx)/2;
if USE_FIR == 0,
  fname  = 'butter';
  ftype  = mode;;
  forder = 4;
  % USE NORMAL FILTER
  % called like DoFilterHilbert(Sig,lim,mode,Fs,KEEP_PHASE)
  if lim(1) == 0,
    [b,a] = butter(4,lim(2)/nyq,'low'); % for the Delta range!
    %[b,a] = cheby1(8,0.01,lim(2)/nyq,'low');
    ftype  = 'low';
  else
    [b,a] = butter(4,lim/nyq,mode);
    %[b,a] = cheby1(8,0.01,lim/nyq,mode);
  end;
else
  % USE FIR FILTER
  % called like DoFilterHilbert(Sig,lim,mode,Fs,KEEP_PHASE,edgeFlt,info)
  [b,a,fname,ftype,forder] = subDesignFIRFilter(1/Sig.dx,lim,mode,edgeFlt,info);
end


s = size(Sig.dat);
Sig.dat = reshape(Sig.dat,[s(1) prod(s(2:end))]);
if info.mirror > 0,
  mirror = max([length(b),length(a)]);
  idxmir = [mirror+1:-1:2 1:size(Sig.dat,1) size(Sig.dat,1)-1:-1:size(Sig.dat,1)-mirror-1];
  idxsel = [1:size(Sig.dat,1)] + mirror;
  if KEEP_PHASE,
    for N=size(Sig.dat,2):-1:1,
      datmir = hilbert(filtfilt(b,a,Sig.dt(idxmir,N)));
      sigdat(:,N) = datmir(idxsel);
    end
    Sig.dat = sigdat;
    clear sigdat;
  else
    for N=size(Sig.dat,2):-1:1,
      datmir = abs(hilbert(filtfilt(b,a,Sig.dat(idxmir,N))));
      Sig.dat(:,N) = datmir(idxsel);
    end
  end
  clear datmir idxmir idxsel;
else
  if KEEP_PHASE,
    for N=size(Sig.dat,2):-1:1,
      sigdat(:,N) = hilbert(filtfilt(b,a,Sig.dat(:,N)));
    end
    Sig.dat = sigdat;
    clear sigdat;
  else
    for N=size(Sig.dat,2):-1:1,
      Sig.dat(:,N) = abs(hilbert(filtfilt(b,a,Sig.dat(:,N))));
    end
  end
end
Sig.dat = reshape(Sig.dat,s);


fprms.band  = lim;
fprms.Fs    = 1.0/Sig.dx;
fprms.fname = fname;
fprms.type  = ftype;
fprms.order = forder;
fprms.b     = b;
fprms.a     = a;


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Sig fprms] = DoFilter(Sig,lim,mode,edgeFlt,info,USE_FIR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nyq = (1/Sig.dx)/2;
if USE_FIR == 0,
  fname  = 'butter';
  ftype  = mode;;
  forder = 4;
  % USE NORMAL FILTER
  % called like DoFilter(Sig,lim,mode)
  if lim(1) == 0,
    [b,a] = butter(4,lim(2)/nyq,'low'); % for the Delta range!
    %[b,a] = cheby1(8,0.01,lim(2)/nyq,'low');
    ftype  = 'low';
  else
    [b,a] = butter(4,lim/nyq,mode);
    %[b,a] = cheby1(8,0.01,lim/nyq,mode);
  end;
else
  % USE FIR FILTER
  % called like DoFilter(Sig,lim,mode,edgeFlt,info)
  [b,a,fname,ftype,forder] = subDesignFIRFilter(1/Sig.dx,lim,mode,edgeFlt,info);
end


s = size(Sig.dat);
Sig.dat = reshape(Sig.dat,[s(1) prod(s(2:end))]);
if info.mirror > 0,
  mirror = max([length(b),length(a)]);
  idxmir = [mirror+1:-1:2 1:size(Sig.dat,1) size(Sig.dat,1)-1:-1:size(Sig.dat,1)-mirror-1];
  idxsel = [1:size(Sig.dat,1)] + mirror;
  datmir = filtfilt(b,a,Sig.dat(idxmir,:));
  Sig.dat = datmir(idxsel,:);
  clear datmir idxmir idxsel;
else
  Sig.dat = filtfilt(b,a,Sig.dat);
end;
Sig.dat = reshape(Sig.dat,s);


fprms.band  = lim;
fprms.Fs    = 1.0/Sig.dx;
fprms.fname = fname;
fprms.type  = ftype;
fprms.order = forder;
fprms.b     = b;
fprms.a     = a;

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
function oSig = DoResample(Sig,NewFs,NewFsTr,info,USE_FIR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%NOTE: using FIR may cause small rippling at both ends.
%
%We use our own filter here, rather than Matlab's filter for
%resample, as Matlab's filter has only 6dB attenuation at the new
%Nyquist frequency, which could cause a small amount of
%aliasing. Our method results in 60dB attenuation at the new
%Nyquist frequency. In addition our filter stipulates a flat (to
%within 0.1dB) response up to 125Hz, which is the highest freq band
%for which we use the signals with 310Hz resampling.

oSig = rmfield(Sig,'dat');
oSig.dx = 1/NewFs;
[p,q] = rat(Sig.dx/oSig.dx,0.0001);
  
%nyq = (1/Sig.dx)/2;
if USE_FIR > 0,
  % called like DoResample(Sig,NewFs,NewFsTr,info,1)
  transband = NewFsTr; %transition width from passband to stopband
  fsamp = p/Sig.dx;  %note: freq of UPSAMPLED signal!
  fcuts = [NewFs/2-transband NewFs/2]; %we want cutoff to start transband before nyquist
  mags = [1 0];
  devs = [abs(1-10^(info.passripple/20)) 10^(-info.dB/20)];
  [n,Wn,beta,ftype] = kaiserord(fcuts,mags,devs,fsamp);
  n = n + rem(n,2);
  b = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');
  %offset due to filtering in sec
  if isfield(oSig,'fltcutoff'),
    oSig.fltcutoff = oSig.fltcutoff+length(b)/fsamp; 
  else
    oSig.fltcutoff = length(b)/fsamp; 
  end;
end


s = size(Sig.dat);
Sig.dat = reshape(Sig.dat,[s(1) prod(s(2:end))]);
if USE_FIR > 0,
  if info.mirror > 0,
    pqmax = max(p,q);
    siglen = length(resample(Sig.dat(:,1),p,q,b));

    mirror = ceil(length(b)/pqmax)*pqmax;
    idxmir = [mirror+1:-1:2 1:size(Sig.dat,1) size(Sig.dat,1)-1:-1:size(Sig.dat,1)-mirror-1];
    idxsel = [1:siglen] + round(mirror*p/q);
    datmir = resample(Sig.dat(idxmir,:),p,q,b);
    oSig.dat = datmir(idxsel,:);
  else
    oSig.dat = resample(Sig.dat,p,q,b);
  end
else
  if info.mirror > 0,
    % NOTE :
    % resample() will use firls with a Kaise window as default.
    % followig code was taken from Matlab's resample() function.
    bta = 5;    N = 10;     pqmax = max(p,q);
    if( N>0 )
      fc = 1/2/pqmax;
      L = 2*N*pqmax + 1;
      h = p*firls( L-1, [0 2*fc 2*fc 1], [1 1 0 0]).*kaiser(L,bta)' ;
      % h = p*fir1( L-1, 2*fc, kaiser(L,bta)) ;
    else
      L = p;
      h = ones(1,p);
    end
    siglen = length(resample(Sig.dat(:,1),p,q));
    
    mirror = ceil(length(h)/pqmax)*pqmax;
    idxmir = [mirror+1:-1:2 1:size(Sig.dat,1) size(Sig.dat,1)-1:-1:size(Sig.dat,1)-mirror-1];
    idxsel = [1:siglen] + round(mirror*p/q);
    datmir = resample(Sig.dat(idxmir,:),p,q);
    oSig.dat = datmir(idxsel,:);
  else
    oSig.dat = resample(Sig.dat,p,q);
  end
end

s(1)=size(oSig.dat,1);
oSig.dat = reshape(oSig.dat,s);

clear Sig;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = DoUpsample(Sig,NewFs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = size(Sig.dat);
oSig = rmfield(Sig,'dat');
oSig.dx = 1/NewFs;
[p,q] = rat(Sig.dx/oSig.dx,0.0001);   %upsampled freq is p/Sig.dx
Sig.dat = reshape(Sig.dat,[s(1) prod(s(2:end))]);
oSig.dat = resample(Sig.dat,p,q);
s(1)=size(oSig.dat,1);
oSig.dat = reshape(oSig.dat,s);

s = size(Sig.hildat);
Sig.hildat = reshape(Sig.hildat,[s(1) prod(s(2:end))]);
oSig.hildat = resample(Sig.hildat,p,q);
s(1)=size(oSig.hildat,1);
oSig.hildat = reshape(oSig.hildat,s);

clear Sig;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sig = DoCat(Sig,NewSig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(Sig),
  Sig = NewSig;
  return;
end
  
s = size(Sig.dat);
if size(Sig.dat,1)>size(NewSig.dat,1),
  dlen = size(Sig.dat,1) - size(NewSig.dat,1);
  NewSig.dat = cat(1,NewSig.dat,NewSig.dat(1:dlen,:));
elseif size(Sig.dat,1)<size(NewSig.dat,1),
  NewSig.dat = NewSig.dat(1:size(Sig.dat,1),:);
end;
Sig.dat = cat(3,Sig.dat,NewSig.dat);
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [b,a,fname,ftype,forder] = subDesignFIRFilter(Fs,lim,mode,edgeFlt,info)
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

fname  = 'fir1-kaiser';
%ftype = ..., % given by above kaiserord().
forder = n;



return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNTION for subAndrei_fltlow, copied from fltlow.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Lfp fprms] = subAndrei_fltlow(tSig,info,B)
fprintf('BP[%d-%dHz].',info.band{B}{1}(1),info.band{B}{1}(2));
if info.band{B}{1}(2)< info.LowFs/2,
  Lfp = resampSig(tSig,info.LowFs,info.LowFsTr,info);
  [Lfp, frpms] = subAndrei_filterSig(Lfp,info.band{B}{1},info.lstop,info);
  if info.envelop
    Lfp.dat = abs(hilbert(Lfp.dat));
  end;
  Lfp = upsampSig(Lfp,info.NewFs);
else
  [Lfp,fprms] = subAndrei_filterSig(tSig,info.band{B}{1},info.lstop,info);
  if info.envelop
    Lfp.dat = abs(hilbert(Lfp.dat));
  end;
end;
%Lfp = windowSig(Lfp);
%tmp.dat = tmp.dat(getStimIndices(tmp,'stim',0,0),:);
%tmp.dat = sigprep(tmp.dat,'cr',order);

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNTION for subGetBlpAndrei, copied from filterSig.m
function [Sig,fprms] = subAndrei_filterSig(Sig,lim,fltedge,info)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% FILTERSIG - filter signal with new defined (10.02.05) FIR filters
nyq = (1/Sig.dx)/2;
if lim(1) == 0, % LOWPASS filtering
  fsamp = 1/Sig.dx;
  fcuts = [lim(2) (lim(2)+fltedge)];
  mags = [1 0];
  devs = [abs(1-10^(info.passripple/20)) 10^(-info.dB/20)];
  [n,Wn,beta,ftype] = kaiserord(fcuts,mags,devs,fsamp);
  n = n + rem(n,2);
  b = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');
  a = 1;

elseif  (lim(2)+0.5) > nyq, % HIGHPASS filtering
  fsamp = 1/Sig.dx;
  fcuts = [lim(1)-fltedge lim(1)];
  mags = [0 1];
  devs = [10^(-info.dB/20) abs(1-10^(info.passripple/20))];
  [n,Wn,beta,ftype] = kaiserord(fcuts,mags,devs,fsamp);
  n = n + rem(n,2);
  b = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');
  a = 1; 

else % BANDPASS filtering
  fsamp = 1/Sig.dx;
  fcuts = [(lim(1)-fltedge) lim(1) lim(2) (lim(2)+fltedge)];
  mags = [0 1 0];
  devs = [10^(-info.dB/20)  abs(1-10^(info.passripple/20)) 10^(-info.dB/20)];
  [n,Wn,beta,ftype] = kaiserord(fcuts,mags,devs,fsamp);
  n = n + rem(n,2);
  b = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');
  a = 1;
end;

% fltcutoff is the cut length of the signal due to filter artifacts
% at the beginning and end of filtered signal
if isfield(Sig,'fltcutoff'), 
  Sig.fltcutoff = Sig.fltcutoff+length(b)*Sig.dx;
else
  Sig.fltcutoff = length(b)*Sig.dx; 
end;

if info.mirror > 0,
  mirror = max([length(b),length(a)]);
  idxmir = [mirror+1:-1:2 1:size(Sig.dat,1) size(Sig.dat,1)-1:-1:size(Sig.dat,1)-mirror-1];
  idxsel = [1:size(Sig.dat,1)] + mirror;
  datmir = filtfilt(b,a,Sig.dat(idxmir,:));
  Sig.dat = datmir(idxsel,:);
  clear datmir idxmir idxsel;
else
  Sig.dat=filtfilt(b,a,Sig.dat);
end

% filter parameters
fprms.band  = lim;
fprms.Fs    = 1.0/Sig.dx;
fprms.fname = 'fir1-kaiser';
fprms.ftype = ftype;
fprms.order = n;
fprms.b     = b;
fprms.a     = a;

return;
