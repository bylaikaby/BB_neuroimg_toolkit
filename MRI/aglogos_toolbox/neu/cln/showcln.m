function showcln(SESSION,ExpNo,ChanNo)
%SHOWCLN - Cln Display (Time, spectra, amplitude-distribution & RMS)
% SHOWCLN (SESSION,ExpNo,ChanNo) is a small utility to display the original denoised
% neural signal. Four subplots are displayed, with the time
% course of the signal, its spectral power distribution, its
% amplitude distribution and its Root Mean Square function computed
% over Sig.stm.voldt windows. The fourth plot also displays whether
% the selected channels shows stimulus-relevant modulation.
%   
% SHOWCLN (SESSION, ExpNo) - Displays channel 1 of ExpNo
% SHOWCLN (SESSION, ExpNo, ChanNo) - Displays channel ChanNo of ExpNo
%   
% NKL 20.08.03

if nargin < 3,
  ChanNo=1;
end;

if nargin < 2,
  help showcln;
  return;
end;

global DispPars DISPMODE PPTSTATE
DISPMODE=0;				% DEFAULT SHOW AVERAGE OBSP/CHAN
initDispPars(DISPMODE,PPTSTATE);

if ~exist('ChanNo','var'),
  ChanNo = 1;
  fprintf('SHOWCLN: No channel was defined; using Chan: 1\n');
end;

SUBPLOTFLAG=0;
Ses = goto(SESSION);
Cln = sigload(Ses,ExpNo,'Cln');
Cln.dat = Cln.dat(:,ChanNo);
mfigure([50 120 900 600]);
subplot(2,2,1);
ARGS.SUBPLOTFLAG=0;
ARGS.PLOTTITLE=0;
ARGS.SKIP=3;
dspsig(Cln,ARGS);
title('Denoised & Decimated Signal');

subplot(2,2,2);
bCln = sigselepoch(Cln,'blank',0);
sCln = sigselepoch(Cln,'nonblank',0);
FFTARGS.COLOR='r';
FFTARGS.XSCALE='log';
FFTARGS.NORMALIZE=1;
msigfft(sCln,FFTARGS);
hold on;
FFTARGS.COLOR='b';
msigfft(bCln,FFTARGS);
title('Spectral Power for Baseline/Stimulus Conditions');

subplot(2,2,3);
hst=sighist(Cln);
dsphist(hst);

subplot(2,2,4);
ARGS.SUBPLOTFLAG=0;
ARGS.PLOTTITLE=0;
ARGS.PLOTSTMLINES=0;
ARGS.SKIP=1;
rmsCln = sigrms(Cln,'window');
hd = dspsig(rmsCln,ARGS);
grid on;
% COMPUTE T-TEST FOR RMS
H = sigttest(rmsCln);
title('RMS Values per TR-Epochs');
drawstmlines(rmsCln,'linewidth',2,'color','r','linestyle','--');

tit = sprintf('Session: %s, GrpName: %s, ExpNo: %d, ChanNo: %d\n',...
              Ses.name, Cln.grpname, ExpNo, ChanNo);
suptitle(tit,'r',9);

if H,
  set(gca,'color',[1 .8 .8]);
  mlegend(hd,'Modulating','linespec','color','k','fontweight','bold',...
          'fontsize',11,'textspec','color','g');
else
  set(gca,'color',[.4 .4 .4]);
  mlegend(hd,'Non-Modulating','linespec','color','k','fontweight','bold',...
          'fontsize',11,'textspec','color','r');
end;  




