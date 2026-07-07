function showhist(SesName,ExpNo,SigName)
%SHOWHIST - Show the amplitude-distribution of a signal SigName
% SHOWHIST (SesName,ExpNo,SigName) shows the signal-amplitude
% distribution of the signal SigName of experiment ExpNo and
% session SesName.
%
% SHOWHIST (SesName) displays Cln for ExpNo = 1
% SHOWHIST (SesName, ExpNo) displays Cln for ExpNo
% SHOWHIST (SesName, ExpNo, SigName) displays SigName for ExpNo
%
% See also MYHIST HIST BAR SIGSTS
%
% NKL 30.05.04

if nargin < 3,
  SigName = 'Lfp';
end;

if nargin < 2,
  ExpNo = 1;
end;

Sig = sigload(SesName,ExpNo,SigName);
if isstruct(Sig) & strcmp(Sig.dir.dname,'Cln'),
  Sig = rms(Sig);
  Sig = tosdu(Sig);
end;

if iscell(Sig),
  tmp = Sig;
  clear Sig;
  Sig = tmp{1};
end;

mfigure([20 200 500 650]);
subplot(2,1,1);
dsphist(sighist(sigselepoch(Sig,'blank')));
grid on;
title(sprintf('Signal %s, Condition: "blank"',Sig.dir.dname));
subplot(2,1,2);
dsphist(sighist(sigselepoch(Sig,'nonblank')));
title(sprintf('Signal %s, Condition: "nonblank"',Sig.dir.dname),'color','r');
stit=sprintf('showhist: Session %s, ExpNo %d, Signal %s\n',...
             Sig.session, ExpNo, SigName);
suptitle(stit,'r',11);
grid on;

