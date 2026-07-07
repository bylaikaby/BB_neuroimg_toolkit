function oSig = sigconv(Sig,DX,KernelName,SECS,IRDX)
%SIGCONV - Convolve by using the HRF computed from experiments in monkeys
% oSig = SIGCONV(Sig,DX,KernelName,SECS,IRDX)
% 
% NKL 06.11.07

if nargin < 1,
  help sigconv;
  return;
end;

if nargin < 2,
  DX = Sig.dx(1);
end;

if nargin < 3,
  KernelName = 'hemo';
  KernelName = 'spmhrf';
end;

if nargin < 4,
  SECS = 25;            % 18 seconds gives the best results
end;

if nargin < 5,
  IRDX = 0.025;         % 25msec resampling, should be enough for BOLD
  IRDX = 0.050;         % 50msec resampling, should be enough for BOLD
end;

fprintf('sigconv [DX=%2.2f, Kernel=%s, KernelSize(sec)=%d, Resampling=%2.4f]\n',...
        DX, KernelName, SECS, IRDX);
if isstruct(Sig),
  oSig = subSigConv(Sig,DX,KernelName,SECS,IRDX);
%  oSig.dat = oSig.dat(1:size(Sig.dat,1),:,:,:,:);
else
  for N=1:length(Sig),
    if isstruct(Sig{N}),
      oSig{N} = subSigConv(Sig{N},DX,KernelName,SECS,IRDX);
      oSig{N}.dat = oSig{N}.dat(1:size(Sig{N}.dat,1),:,:,:,:);
    else
      for K=1:length(Sig{N}),
        oSig{N}{K} = subSigConv(Sig{N}{K},DX,KernelName,SECS,IRDX);
        oSig{N}{K}.dat = oSig{N}{K}.dat(1:size(Sig{N}{K}.dat,1),:,:,:,:);
      end;
    end;
  end;
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = subSigConv(Sig,DX,KernelName,SECS,IRDX)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmpIR = mhemokernel('hemo', IRDX, SECS);    % to compare...
if strcmp(KernelName,'spmhrf'),
    %	p(1) - delay of response (relative to onset)        6
    %	p(2) - delay of undershoot (relative to onset)      16
    %	p(3) - dispersion of response                       1
    %	p(4) - dispersion of undershoot                     1
    %	p(5) - ratio of response to undershoot              6
    %	p(6) - onset (seconds)                              0
    %	p(7) - length of kernel (seconds)                   32
    % IR.info     = [6 16 1 1 6 0 SECS];

    IR.name     = 'spmhrf';
    IR.dx       = tmpIR.dx;
    IR.info     = [5 12 1 1 6 0 SECS];
    IR.dat      = spm_hrf(IR.dx,IR.info);
    IR.hemoinfo = tmpIR.info;
    IR.hemodat  = tmpIR.dat;
else  
  IR = tmpIR;
end;

DO_DEBUG=0;
if DO_DEBUG,
  hold off; plot([0:size(IR.dat,1)-1]*IR.dx, IR.dat);
  hold on;  plot([0:size(IR.hemodat,1)-1]*IR.dx, IR.hemodat, 'r');
  keyboard;
end;

orgsize = size(Sig.dat);
LEN=orgsize(1);
if size(Sig.dat,2)>1,
  Sig.dat = reshape(Sig.dat,[LEN prod(orgsize(2:end))]);
end;
%tmpsig = Sig;
for N=1:size(Sig.dat,2),
  tmpdat = subResampleData(Sig.dat(:,N),Sig.dx(1),IRDX,0,1);
  tmpdat = subConvolveData(tmpdat,IR.dat(:),1);
  tmpdat = subResampleData(tmpdat,IRDX, DX, 0, 1);
  %AB 16.1.2008***********
  %Sig.dat(:,N) = tmpdat(1:LEN);
  alldat(:,N) = tmpdat;
  %***********************
end;
%AB 16.1.2008 *******
%Sig.dat = reshape(Sig.dat,orgsize);
orgsize(1)=size(alldat,1);
%********************
Sig.dat = reshape(alldat,orgsize);
Sig.dx(1) = DX;
oSig = Sig;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTOIN to resample data
function DAT = subResampleData(DAT,DX,NewDX,USE_FIR,DO_MIRROR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global SELECT_STIM
if iscell(DAT),
  for N = 1:length(DAT),
    DAT{N} = subResampleData(DAT{N},DX,NewDX,USE_FIR,DO_MIRROR);
  end
  return;
end

if DX == NewDX,  return;  end

[p,q] = rat(DX/NewDX,0.0001);

if NewDX > DX,
  % downsampling
  if USE_FIR > 0,
    NewFs = 1/NewDX;
    NewFsTr = NewFs * 0.08;
    info.dB         = 60;
    info.passripple = 0.1;

    transband = NewFsTr; %transition width from passband to stopband
    fsamp = p/DX;  %note: freq of UPSAMPLED signal!
    fcuts = [NewFs/2-transband NewFs/2]; %we want cutoff to start transband before nyquist
    mags = [1 0];
    devs = [abs(1-10^(info.passripple/20)) 10^(-info.dB/20)];
    [n,Wn,beta,ftype] = kaiserord(fcuts,mags,devs,fsamp);
    n = n + rem(n,2);
    b = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');
    if DO_MIRROR,
      pqmax = max(p,q);
      orglen = size(DAT,1);
      siglen = length(resample(DAT(:,1),p,q,b));
      mirror = ceil(length(b)/pqmax)*pqmax;
      idxmir = [mirror+1:-1:2 1:orglen orglen-1:-1:orglen-mirror-1];
      idxsel = [1:siglen] + round(mirror*p/q);
      datmir = resample(DAT(idxmir,:),p,q,b);
      DAT = datmir(idxsel,:);
    else
      DAT = resample(DAT,p,q,b);
    end
  else
    if DO_MIRROR,
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
      pqmax = max(p,q);
      orglen = size(DAT,1);
      siglen = length(resample(DAT(:,1),p,q));
      mirror = ceil(length(h)/pqmax)*pqmax;
      idxmir = [mirror+1:-1:2 1:orglen orglen-1:-1:orglen-mirror-1];
      if min(idxmir) > 0 & max(idxmir) <= orglen,
        idxsel = [1:siglen] + round(mirror*p/q);
        datmir = resample(DAT(idxmir,:),p,q);
        DAT = datmir(idxsel,:);
      else
        DAT = resample(DAT,p,q);
      end
    else
      DAT = resample(DAT,p,q);
    end
  end
elseif NewDX < DX,
  % upsampling
  DAT = resample(DAT,p,q);
end
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTOIN to make convolution
function DAT = subConvolveData(DAT,KDAT,DO_MIRROR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global SELECT_STIM
if iscell(DAT),
  for N = 1:length(DAT),
    DAT{N} = subConvolveData(DAT{N},KDAT,DO_MIRROR);
  end
  return;
end
KDAT = KDAT(:);
DAT(find(isnan(DAT))) = 0;

klen = length(KDAT);
if klen >= size(DAT,1),
  DO_MIRROR = 0;
end

if DO_MIRROR,
  idxmir = [klen+1:-1:2 1:size(DAT,1) size(DAT,1)-1:-1:size(DAT,1)-klen-1];
  idxsel = [1:size(DAT,1)] + klen;
  for N = 1:size(DAT,2),
    tmp = fconv(DAT(idxmir,N),KDAT);
    DAT(:,N) = tmp(idxsel);
  end
else
  sel = 1:size(DAT,1);
  for N = 1:size(DAT,2),
    tmp = fconv(DAT(:,N),KDAT);
    DAT(:,N) = tmp(sel);
  end
end
return;



