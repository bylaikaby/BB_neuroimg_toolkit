function showvital(SESSION,ExpNo)
%SHOWVITAL - Display the plethysmogram signal
% SHOWVITAL (SESSION) Display the plethysmogram signal in a single plot
% with no "figure" call.
% NKL 12.03.04

Ses = goto(SESSION);
if nargin == 2,
  Sig = matsigload('Vital.mat',sprintf('pleth%04d',ExpNo));
  dsppleth(Sig);
  return;
end;

EXPS = validexps(Ses);

[fftamp, fftfr] = matsigload('Vital.mat','fftamp','fftfr');
if isempty(fftamp),
  clear fftamp fftfr;
  K=1;
  for N=1:length(EXPS),
    Sig = matsigload('Vital.mat',sprintf('pleth%04d',EXPS(N)));
    if ~isempty(Sig),
      fprintf('%s, %s, %5d\n',Sig.session, Sig.grpname, Sig.ExpNo);
      [fftamp(:,K),fftfr] = sigfft(Sig);
      K=K+1;
    else
      fprintf('SHOWVITAL: ExpNo %d, does not have vitals\n',EXPS(N));
    end;
  end;
  save('Vital.mat','-append','fftamp','fftfr');
end;

FrLim = 3;  % Hz
expno = [1:size(fftamp,2)]';
h = mfigure([10 350 600 500]);
idx = find(fftfr<=FrLim);
fftfr = fftfr(idx);
fftamp = fftamp(idx,:);
[x,y] = meshgrid(expno,fftfr);
mx = max(fftamp(:));
mn = min(fftamp(:));
plot3(x,y,fftamp);
set(gca,'ydir','reverse');
xlabel('Number of Experiment');
ylabel('Frequency in Hz');
zlabel('Spectral Power');
set(gca,'box','off');
set(gca,'xlim',[1 size(fftamp,2)]);
set(gca,'ylim',[0 FrLim]);
set(gca,'zlim',[mn mx*0.75]);
grid on;
view(-50,70);
TIT = sprintf('showvital(%s)',Ses.name);
suptitle(TIT,'r');
saveas(h,'Vital3DPlot.fig');
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [fabs,fr] = sigfft(Sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MAXFREQ = 4;
data = detrend(Sig.dat);
srate = 1/Sig.dx;
len = size(data,1);
len = 65536/4;
fdat = fft(data,len,1);
LEN = size(fdat,1)/2;
fabs = abs(fdat(1:LEN,:));
lfr = (srate/2) * [0:LEN-1]/(LEN-1);
fr = lfr(:);
idx = find(fr<MAXFREQ);
fr = fr(idx);
fabs = fabs(idx);
return;




