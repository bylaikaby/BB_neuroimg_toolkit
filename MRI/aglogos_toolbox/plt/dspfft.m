function dspfft(Sig)
%DSPFFT - plot a neural raw signal
%	dspfft(Sig) - plot a neural raw signal
%	NKL, 13.12.01

if isstruct(Sig),
  fr = [0:size(Sig.dat,1)-1] * Sig.dx;
  amp = squeeze(mean(Sig.dat,2));  % Now is Fr X Band X (possible NoExp)
  amp = mean(amp,3);
else
  fr = [0:size(Sig{1}.dat,1)-1] * Sig.dx;
  for N=1:length(Sig),
    amp = squeeze(mean(Sig.dat,2));  % Now is Fr X Band X (possible NoExp)
    amp = mean(amp,3);
    if N==1,
      sumamp = zeros(size(amp));
    end;
    sumamp = sumamp + amp;
  end;
  amp = sumamp/N;
end;

plot(fr, amp, 'k');
xlabel('Frequency in Hz');
ylabel('Spectral Power');
set(gca,'box','off');
set(gca,'xlim',[fr(1) fr(end)]);
set(gca,'yscale','log');
grid on;
title(sprintf('Signal''s sampling rate was %6.2f', 1/Sig.sigdx));

