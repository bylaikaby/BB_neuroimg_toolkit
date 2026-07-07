function pranshow(SESSION,GrpName)
%PRANSHOW - display data for the anesthesia project
% pranshow(SESSION,GrpName) like all functions starting with PR_ is
% project specific. It displays the results of the anesthesia experiments.
% NKL, 13.12.01

if nargin < 2,
	error('usage: pranshow(SESSION,GrpName);');
end;

global DispPars DISPMODE PPTSTATE
DISPMODE = getdispmode;
if isempty(DISPMODE),
  DISPMODE=1;
end;

PPTSTATE = getpptstate;
if isempty(PPTSTATE),
  PPTSTATE = 0;
  setpptstate(PPTSTATE);
end;

if ~isfield(DispPars,'initialized'),
  initDispPars(DISPMODE,PPTSTATE);
end;

Ses = goto(SESSION);
load('pket.mat');
lfp = LfpM;
mua = Mua;

load(strcat(GrpName,'.mat'));

mfigure([100 100 1100 400]);
LfpM.dat = cat(3,lfp.dat,LfpM.dat);
Mua.dat = cat(3,mua.dat,Mua.dat);


keyboard
subplot(1,2,1);
DOPLOT(LfpM);
subplot(1,2,2);
DOPLOT(Mua);

keyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DOPLOT(Sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Sig.dat = squeeze(mean(Sig.dat,2));
Sig.dat = reshape(Sig.dat,[size(Sig.dat,1) round(size(Sig.dat,2)/10) 10]);
Sig.dat = squeeze(mean(Sig.dat,2));
t = [0:size(Sig.dat,1)-1] * Sig.dx; t = t(:);
s = [1:size(Sig.dat,2)]; s = s(:);

if 1,
  [x,y]=meshgrid(t,s);
  plot3(x,y,Sig.dat');
  set(gca,'xlim',[t(1) t(end)]);
  set(gca,'ylim',[s(1) s(end)]);
  set(gca,'zlim',[-1 4]);
  view(35,75)
  hold on
end;


if 0,
  [x,y]=meshgrid(t,s);
  z = x*0 + y*0;
  z = Sig.dat;
  obj = mesh(x,y,z',Sig.dat');
  set(gca,'xlim',[t(1) t(end)]);
  set(gca,'ylim',[s(1) s(end)]);
  set(gca,'zlim',[-1 4]);
  view(35,75)
  hold on
end;

return;
surf(t,s,Sig.dat');
set(gca,'Xlim',[t(1) t(end)]);
set(gca,'Ylim',[s(1) s(end)]);
set(gca,'Xcolor','k','LineWidth',1);
set(gca,'Ycolor','k','LineWidth',1);
xlabel('Time in sec','fontweight','bold','fontsize',8,'color','k');
ylabel('Scan Number','fontweight','bold','fontsize',8,'color','k');
shading interp;
view(0,90);


if 0,
if DispPars.pptstate,
  pptout(PPTTITLE,DispPars.pptout);
end;

end;
