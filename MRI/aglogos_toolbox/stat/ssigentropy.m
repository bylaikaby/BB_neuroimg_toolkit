function eSig = ssigentropy( Sig, WinLen, Overlap)
%SSIGENTROPY - Computes the entropy of all channels of a signal Sig
%
% eSig=SSIGENTROPY(Sig) - Returns the entropy value of all channels
%       of the entire signal.
%
% eSig=SSIGENTROPY(Sig,WinLen) - Returns the entropy of N
%       non-overalapping windows. N = round(size(Sig.dat,1)/WinLen).
%       WinLen is in seconds; it is converted in points by using
%       the signal's sampling time Sig.dx.
%
% eSig=SSIGENTROPY(Sig,WinLen,Overlap) - Returns the entropy of N
%       overalapping windows. The number of windows N =
%       round(size(Sig.dat,1)/(WinLen-Overlap)). Overlap is defined by
%       the user as a fraction of the window length (WinLen*Overlap).
%
% eSig.dat is a #WINDOWS x #VOXELS (or Channels) matrix 
%
% Parameters: Overlap [0..0.99] Zero means no Overlap 0.99 almost full Overlap
%
% NK Logothetis & Andrei Belitski, 03.06.04

if ~nargin,
  help ssigentropy;
  return;
end;

if nargin < 3,
  Overlap = 0;
end;

if ~isstruct(Sig),
  fprintf('SIGSTS: Does not work with cell arrays\n');
  return;
end;

if Overlap > 1 | Overlap < 0,
  fprintf('SIGSTS: Overlap must be in the range [0 1]\n');
  return;
end;

if nargin < 2,
  eSig = DOentropyPerEpoch(Sig);
else
  eSig = DOentropy(Sig, WinLen, Overlap);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function eSig = DOentropyPerEpoch(Sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmp = sigselepoch(Sig,'blank');
eSig1 = DOentropy(tmp,-1);
tmp = sigselepoch(Sig,'nonblank');
eSig2 = DOentropy(tmp,-1);

eSig.dx      = Sig.dx;
eSig.dat     = cat(2,eSig1.dat,eSig2.dat);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function eSig = DOentropy(Sig, WinLen, Overlap)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if WinLen < 0,
  Overlap = 0;
  WinLen = size(Sig.dat,1);
else
  WinLen = round(WinLen/Sig.dx(1));
end;

OVLP = round(WinLen*Overlap);
SHIFT = WinLen - OVLP;
NW = floor(size(Sig.dat,1)/(WinLen-OVLP));

if strcmpi(Sig.dir.dname,'tcImg'),
  fprintf('SIGSTS: Signal tcImg can''t be processed, try roiTs\n');
  keyboard;
end;

if length(size(Sig.dat)) > 3,
  fprintf('SIGSTS: Matrix must have maximally 3 dimensions\n');
  keyboard;
end;

ibeg = 1;
for N=1:NW,
  iend = ibeg + WinLen;
  if iend > size(Sig.dat,1),
    iend = size(Sig.dat,1);
  end;
  eSig.dat(:,N) = sentropy(Sig.dat(ibeg:iend,:));
  ibeg = ibeg + SHIFT;
end;
eSig.dx = Sig.dx;
if WinLen > 0,
  eSig.dx = SHIFT*Sig.dx;
end;
return;

