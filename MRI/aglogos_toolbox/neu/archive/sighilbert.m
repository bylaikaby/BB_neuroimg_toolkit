function Sig = sighilbert(Sig)
%SIGHILBERT - Compute Hilbert Transform of the Signal
% Sig = SIGHIBLERT(Sig) computes the Hilbert transform of the signal. The amplitude of the
% results provides the exact envelop of the signal.
%
% NKL, 25.07.04

if length(Sig) == 1,
  Sig = {Sig};
end;

for NoSig = 1:length(Sig),
  s = size(Sig{NoSig}.dat);
  Sig{NoSig}.dat = reshape(Sig{NoSig}.dat,[s(1) prod(s(2:end))]);
  Sig{NoSig}.dat = abs(hilbert(Sig{NoSig}.dat));
  Sig{NoSig}.dat = reshape(Sig{NoSig}.dat,s);
end;

if length(Sig) == 1,
  Sig = Sig{1};
end;


