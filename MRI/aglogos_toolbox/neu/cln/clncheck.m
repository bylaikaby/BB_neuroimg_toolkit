function clncheck(SESSION,ExpNo)
%CLNCHECK - Check the spectra of the Cln and the Gradient Channel
% CLNCHECK(SESSION,ExpNo) the function plots the power spectra of gradient channel (top
% panel) and the cleaned, Cln, signal (bottom panel) to check (visually) how good the
% denoising of the signal is.
%
% 18.07.2005 NKL
% 15.08.2005 YM   use spectrogram instead of sigfft.
%
% See also

if nargin < 2,
  help clncheck;
  return;
end;

Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);
if ~isrecording(grp),  return;  end

Cln = sigload(Ses,ExpNo,'Cln');


if isempty(Cln),
  fprintf('No Cln structure was found; did you run sesgetcln???\n');
  return;
end;

%Gra = rmfield(Cln,{'dat','gra'});
Gra = Cln;
Gra.dat = [];
Gra.gra = [];
if ~isfield(Cln,'gra'),
  [Gra.dat,Gra.dx] = grdread(Ses,ExpNo);
  Gra.dx = Gra.dx / 1000;
else
  Gra.dat = double(Cln.gra);
end

NFFT = 1024;
NOVERLAP = round(NFFT*0.2);

mfigure([10 50 800 600]);
set(gcf,'Name',sprintf('%s(%s,%d)',mfilename,Ses.name,ExpNo));
subplot(2,1,1);
if 0,
  % sigfft() does averaging across frequencies...
  sigfft(Gra);
else
  %[S,F,T] = spectrogram(Gra.dat,NFFT,NOVERLAP,NFFT,1.0/Gra.dx);
  %plot(F,mean(abs(S),2),'k');  hold on; grid on;
  [Pxx F] = pwelch(Gra.dat,NFFT,NOVERLAP,NFFT,1.0/Gra.dx);
  plot(F,Pxx,'color','k'); hold on; grid on;
  
  set(gca,'yscale','log');
end
xlabel('Frequency in Hz');
title(sprintf('%s ExpNo=%d(%s): Gradient Channel Power Spectrum',Ses.name,ExpNo,grp.name));
set(gca,'xlim',[0 3000]);
ylim=get(gca,'ylim');

subplot(2,1,2);
if 0,
  % sigfft() does averaging across frequencies...
  sigfft(Cln);
else
  legtxt = {};
  SIGCOLORS = 'rgbcmykrgbcmykr';
  for iCh = 1:size(Cln.dat,2),
    %[S,F,T] = spectrogram(Cln.dat(:,iCh),NFFT,NOVERLAP,NFFT,1.0/Cln.dx);
    %plot(F,mean(abs(S),2),'color',SIGCOLORS(iCh));  hold on;  grid on;
    [Pxx F] = pwelch(Cln.dat(:,iCh),NFFT,NOVERLAP,NFFT,1.0/Cln.dx);
    plot(F,Pxx,'color',SIGCOLORS(iCh));  hold on;  grid on;
    
    legtxt{iCh} = sprintf('ch%d',iCh);
  end
  if length(legtxt) > 1,  legend(legtxt);  end
  set(gca,'yscale','log');
end
title(sprintf('%s ExpNo=%d(%s): Cln Signal Power Spectrum',Ses.name,ExpNo,grp.name));
xlabel('Frequency in Hz');
set(gca,'xlim',[0 3000]);
set(gca,'ylim',ylim);