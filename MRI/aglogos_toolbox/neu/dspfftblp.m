function dspfftblp(fBlp)
%DSPFFTBLP - Show fourier spectrum of BLP signals
% dspfftblp(Blp) shows the output of sigfft(blp) call.
% NKL 09.01.06
  
if nargin < 1,
  help dspfftblp;
  return;
end;

if isstruct(fBlp),
  fr = [0:size(fBlp.dat,1)-1] * fBlp.dx;
  amp = squeeze(mean(fBlp.dat,2));  % Now is Fr X Band X (possible NoExp)
  amp = mean(amp,3);
else
  fr = [0:size(fBlp{1}.dat,1)-1] * fBlp.dx;
  for N=1:length(fBlp),
    amp = squeeze(mean(fBlp.dat,2));  % Now is Fr X Band X (possible NoExp)
    amp = mean(amp,3);
    if N==1,
      sumamp = zeros(size(amp));
    end;
    sumamp = sumamp + amp;
  end;
  amp = sumamp/N;
end;

YLIM = [fr(1) fr(end)];
[x,y] = meshgrid([1:size(amp,2)],fr);
mx = max(amp(:));
mn = min(amp(:));
plot3(x,y,amp);
view(-60,45);
set(gca,'ydir','reverse');
xlabel('Band-Number');
ylabel('Frequency in Hz');
zlabel('Spectral Power');
set(gca,'box','off');
set(gca,'xlim',[1 size(amp,2)]);
set(gca,'ylim',YLIM,'yscale','log');
set(gca,'zscale','log');
grid on;
title('Spectrum of Each BLP');
