function oSig = sigspc(iSig, WT, dT, NFFT, WinFct)
%SIGSPC - Make spectrogram from signal iSig
%	USE: oSig = SIGSPC(iSig, WT, dT, NFFT, WinFct)
%	AUTH: HM, 28.06.00, v1b.
%
%   B = SPECGRAM(A,NFFT,Fs,WINDOW,NOVERLAP) calculates the spectrogram for 
%   the signal in vector A.  SPECGRAM splits the signal into overlapping 
%   segments, windows each with the WINDOW vector and forms the columns of
%   B with their zero-padded, length NFFT discrete Fourier transforms.  Thus
%   each column of B contains an estimate of the short-term, time-localized
%   frequency content of the signal A.  Time increases linearly across the 
%   columns of B, from left to right.  Frequency increases linearly down 
%   the rows, starting at 0.  If A is a length NX complex signal, B is a 
%   complex matrix with NFFT rows and 
%        k = fix((NX-NOVERLAP)/(length(WINDOW)-NOVERLAP)) 
%   columns.  If A is real, B still has k columns but the higher frequency
%   components are truncated (because they are redundant); in that case,
%   SPECGRAM returns B with NFFT/2+1 rows for NFFT even and (NFFT+1)/2 rows 
%   for NFFT odd.  If you specify a scalar for WINDOW, SPECGRAM uses a 
%   Hanning window of that length.  WINDOW must have length smaller than
%   or equal to NFFT and greater than NOVERLAP.  NOVERLAP is the number of
%   samples the sections of A overlap.  Fs is the sampling frequency
%   which does not effect the spectrogram but is used for scaling plots.
%
%   [B,F,T] = SPECGRAM(A,NFFT,Fs,WINDOW,NOVERLAP) returns a column of 
%   frequencies F and one of times T at which the spectrogram is computed.
%   F has length equal to the number of rows of B, T has length k. If you 
%   leave Fs unspecified, SPECGRAM assumes a default of 2 Hz.
%
%	SESCLNSPC - calls this function as:
%	T = ep{ExpNo}.img.dx;
%	len = T / Cln.dx;
%	NFFT = getpow2(len,'ceiling');
%	ClnSpc = sigspc(Cln,   T,  T, NFFT, 'hanning');
%	oSig   = sigspc(iSig, WT, dT, NFFT,  WinFct)
% 
%	NKL, 13.10.02
%   YM,  11.10.05  use spectrogram instead of specgram in Matlab7.
%
%%% TODO: Smoothing kernel?

POWER = 1;
SDUNITS = 1;

if nargin < 1,
  help sigspc;
  return;
end;

if nargin < 2,
  WT = 1/4;
  dT = WT;
  NFFT = 2048;
  WinFct = 'hanning';
end;

% CHECK INPUT:
% FOR NEW SESSIONS USUALLY: dx: 1.4474e-004
% FOR NAT2001 dx: 1.3545e-004
Ts = iSig.dx(1);
NAT2001_CORRECTION = 0;
if NAT2001_CORRECTION,
  Ts = 1.4474e-004;
  %%%??Ts = 1.3545e-004;
end;

Fs = 1/Ts;

if ~exist('dT','var') || dT <= 0 ||  isempty(dT),
  dT = WT;
end;

N = round(WT/Ts);
WT = N*Ts;

dN = round(dT/Ts);
dT = dN*Ts;

% We don't need zero-padding if N is already greater than default (2048)
if ~exist('NFFT','var') || isempty(NFFT) || (NFFT < N),
  NFFT = 2^nextpow2(N);
end;

if ~exist('WinFct','var') || isempty(WinFct),
  WinFct = 'hanning';
end;

WINDOW = feval(WinFct,N);

if isfield(iSig,'usr') && isfield(iSig.usr,'overlap'),
  % E.G. NOVERLAP = 0.25, means 25% overlap between successive windows
  NOVERLAP = round(N*iSig.usr.overlap);
elseif WT == dT,
  NOVERLAP = 0;
else
  NOVERLAP = N - dN;
%  NOVERLAP = 0;       % why ignoring dT????
end;

if rem(NFFT,2),    % NFFT odd
  %select = [1:(NFFT+1)/2];
  F = ([1:(NFFT+1)/2] - 1)'*Fs/NFFT;
else
  %select = [1:NFFT/2+1];
  F = ([1:(NFFT+1)/2+1] - 1)'*Fs/NFFT;
end

fprintf(' sigspc V08.05.03 [NFFT:%d(%.2fs), WINDOW:%s/%d(%.2fs), NSHIFT:%d(%.2fs), dF:%6.3fHz]\n',...
        NFFT, NFFT*iSig.dx,...
        WinFct,N,N*iSig.dx,...
        length(WINDOW)-NOVERLAP, (length(WINDOW)-NOVERLAP)*iSig.dx,...
        mean(diff(F)));

NoChan = size(iSig.dat,2);
NoObsp = size(iSig.dat,3);

%%% WbarH = waitbar(0,'Calculating spectra...');
K = 1;
for ChanNo = NoChan:-1:1,
  for ObspNo = NoObsp:-1:1,
    % use "spectrogram" for Matlab7,  in near future, "specgram" will be obsolete.... 
    % [tmpSpc,F,T]=specgram(iSig.dat(:,ChanNo,ObspNo),NFFT,1/Ts,WINDOW,NOVERLAP);
    % 25.03.2011 - Changed to new version of SPECGRAM...
    
    % CESARE: he suggests that I put NFFT = length(WINDOW)
    % TRY THIS....
    NFFT = length(WINDOW);
    %%%%%%%%%%%%%%%%%%%%%%%%  ATTENTION!!!!!!!!!!!!!!!!1
    
    [tmpSpc,F,T, P] = spectrogram(iSig.dat(:,ChanNo,ObspNo),WINDOW,NOVERLAP,NFFT,1/Ts);
    % P IS THE POWEr (check and if everything backward compatible  skip the next lines....
    if POWER,
      tmpSpc = tmpSpc.*conj(tmpSpc);
    else
      tmpSpc = abs(tmpSpc);
    end;
    spcdat(:,:,ChanNo,ObspNo) = tmpSpc';	% make Sig= Sig(t,f)
    %%% waitbar(K/(NoObsp*NoChan)); - IT's causing trouble by "stealing" the window
    K = K+1;
  end;
end;
%%% close(WbarH);  drawnow;


oSig = iSig;		% copy all info.
oSig.dat = spcdat;

oSig.dx(1) = T(2)-T(1);
oSig.dx(2) = F(2)-F(1);
if isfield(iSig,'dxorg'),
  oSig.dxorg = oSig.dx;
  oSig.dxorg(1) = oSig.dxorg(1) / iSig.dx * iSig.dxorg;
  oSig.dxorg(2) = oSig.dxorg(2) / iSig.dxorg * iSig.dx;
end

oSig.dir.dname		= 'ClnSpc';
oSig.dsp.func		= 'dspclnspc';
oSig.dsp.args		= '1D';
oSig.dsp.label		= {};
oSig.dsp.label{1}	= sprintf('spectral power');
oSig.dsp.label{2}	= sprintf('time (dt= %g sec.)',oSig.dx(1));
oSig.dsp.label{3}	= sprintf('freq. (df= %gHz)',oSig.dx(2));



oSig.usr.(mfilename).nfft = NFFT;
oSig.usr.(mfilename).noverlap = NOVERLAP;
oSig.usr.(mfilename).winfunc = WinFct;
oSig.usr.(mfilename).window = length(WINDOW);


if ~nargout,
  showspc0(oSig);
end;

return;




