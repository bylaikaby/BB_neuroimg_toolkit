function tstdeconv(SESSION,tstGrpName,hrfGrpName)
%TSTDECONV - Test deconvolution of the MRI signal
% TSTDECONV (SESSION, tstGrp, hrfGrp) uses the IR computed during
% spontaneous activity to deconvolve the MRI signal and prepare it
% for information-theoretical analysis.

if nargin & nargin < 3,
  fprintf('mtstdeconv: Syntax Parsing ERROR\n');
  help mtstdeconv;
  return;
end;

if ~nargin,
  SESSION = 'g02mn1';
  hrfGrpName = 'spont1';
  tstGrpName = 'movie1';
end;
  
Ses = goto(SESSION);
load(strcat(hrfGrpName,'.mat'),'hrf');
grp = getgrpbyname(Ses,tstGrpName);
filename = catfilename(Ses,grp.exps(1));
load(filename,'Pts','pLfpH');

sig1 = msigdeconv(Pts{1},hrf);      % optimal filtering

L=size(Pts{1}.dat,1);
t = [0:L-1]*Pts{1}.dx;
pLfpH.dat = pLfpH.dat(1:L,:);
sig1.dat = sig1.dat(1:L,:);
sig1 = tosdu(sig1);

% THE FOLLOWING IS REALLY SHIT. IT DOES NOT WORK AT ALL AND GENERATES A
% LOT OF PROBLEMS. I THEREFORE CALCULATED THE OPTIMAL FILTER MYSELF
% AND AM DOING THE POLY-DIVISION DIRECTLY... SOME MATLAB FUNCTIONS
% SEEM TO BE WRITTEN BY MONKEYS
if 0,       % DECONV()
  sig2 = msigdeconv(Pts{1},hrf,0);    % deconv
end;

mfigure([100 80 600 800]);
subplot(3,1,1);
dsphrf(hrf);
set(gca,'xlim',[0 100]);

subplot(3,1,2);
hd(1)=plot(t,mean(pLfpH.dat,2),'y','linewidth',2);
hold on;
hd(2)=plot(t,sig1.dat,'k');
legend(hd,'Neural','Deconvolved MRI');
title('Deconvolution following optimal Wiener filtering');
xlabel('Number of Images');
ylabel('Arbitrary Units');

subplot(3,1,3);
[ax,f1,f2]=plotyy(t,mean(pLfpH.dat,2),t,mean(Pts{1}.dat,2));
set(f1,'color','r');



