function SigPsd = sigpsd(Sig,EPOCH)
%SIGPSD - Compute PSD of the signal
% SIGPSD(Sig) uses Matlab's psd function to computer power spectral
% density of the neural signals.
% NKL, 19.05.03

EPOCH=0;
if nargin < 2,
  EPOCH = 1;
end;

if EPOCH,
  Ses = Sig.session;
  ExpNo = Sig.ExpNo;
  bidx = getstimindices(Sig,'blank');
  sidx = getstimindices(Sig,'anystim');
  bSig = Sig;
  bSig.dat = Sig.dat(bidx(:),:);
  sSig = Sig;
  sSig.dat = Sig.dat(sidx(:),:);
  SigPsd{1} = dosigpsd(bSig);
  SigPsd{2} = dosigpsd(sSig);
  SigPsd{1}.dat = SigPsd{2}.dat./SigPsd{1}.dat;
  SigPsd = SigPsd{1};
else
  SigPsd = dosigpsd(Sig{N});
end;

if ~nargout,
  y = SigPsd.dat(:,1,1)/max(SigPsd.dat(:,1,1));
  plot([0:size(SigPsd.dat,1)-1]*SigPsd.dx(2),y);
%  set(gca,'xscale','log');
set(gca,'xlim',[0 10]);
  xlabel('Frequency in Hz');
  ylabel('Power');
  grid on;
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SigPsd = dosigpsd(Sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%
NPSD = 2^16;
Fs = 1/Sig.dx;
%NPSD = getpow2(size(Sig.dat,1),'floor');
LEN = NPSD/2+1;
NoChan = size(Sig.dat,2);
NoObsp = size(Sig.dat,3);
SigPsd = Sig;
SigPsd.dat = zeros(LEN,NoChan,NoObsp);
try,
for ObspNo = 1:NoObsp,
  for ChanNo = 1:NoChan,
	[SigPsd.dat(:,ChanNo,ObspNo),SigPsd.Fr]=PSD(Sig.dat(:,ChanNo,ObspNo),NPSD,Fs);
  end;
end;
catch,
  keyboard;
end;

SigPsd.dx = [];
SigPsd.dx(1) = Sig.dx;
SigPsd.dx(2) = mean(diff(SigPsd.Fr));

% DISPLAY
SigPsd.dsp.func	= 'dsppsd';
SigPsd.dsp.args	= {'color';'k';'linestyle';'-';'linewidth';0.5};
SigPsd.dsp.label	= {'Frequency in Hz'; 'Power'};

