function showrmsmri(SesName, ExpNo, RoiName, Thr)
%SHOWRMSMRI - Displays the RMS of the Neural Signal superimposed on the BOLD response.
% SHOWRMSMRI (SesName, ExpNo, RoiName, Thr) makes a figure with two subplots. The
% left shows the correlation map, and the right the time courses of the neural and MRI
% signals.
%
% USAGE:
%   SHOWRMSMRI (SesName, ExpNo, RoiName, Thr)
%       SesName     : Name of the session (e.g. k005x1)
%       ExpNo    : Experiment number of Group Name; if negative uses RAW data and applies
%                     user-defined preprocessing (definition in description file under the
%                     ANAP.mareats field.
%       RoiName     : ROI name (e.g. V1, V2,...)
%       Thr         : Threshold for r values
%  
%   SHOWRMSMRI ('k005x1', 'p2c100');
%   SHOWRMSMRI ('k005x1', -3) -- use tcImg of exp 3, preprocess, plot...
%  
%   The following function call shows good undershoot for brief pulses
%   SHOWBPULSE ('f01pr1','polarflash');
%
% NKL, 11.07.05


% ----------------------------------------------------------------------------
% SIGNAL SELECTION
% ----------------------------------------------------------------------------
NeuSigName = 'rmsCln';
MriSigName  = 'roiTs';

if nargin < 4,
  Thr = 0.15;
end;

if nargin < 3,
  RoiName = 'v1';
end;

if nargin < 2,
  help showrmsmri;
  return;
end;

Ses = goto(SesName);
grp = getgrp(Ses,ExpNo);

if isfield(grp,'anap') & isfield(grp.anap,'gettrial') & grp.anap.gettrial.status,
  NeuSigName = 'trmsCln';
  MriSigName  = 'troiTs';
end;

[NeuSig, MriSig] = sigload(Ses,ExpNo,NeuSigName,MriSigName);
if isfield(grp,'anap') & isfield(grp.anap,'gettrial') & grp.anap.gettrial.status,
  MriSig{1} = MriSig{1}{grp.refgrp.reftrial};
  NeuSig{1} = NeuSig{1}{grp.refgrp.reftrial};
end;

MriSig = mroitsget(MriSig,[],RoiName);
MriSig = mroitssel(MriSig,Thr);

if iscell(NeuSig),
  NeuSig = NeuSig{1};
end;

dspneumri(Ses, ExpNo, NeuSig, MriSig, Thr);
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dspneumri(Ses, ExpNo, NeuSig, MriSig, Thr)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
COL1        = [0 0 0];      % Neural signals and left y axis
COL2        = [0 0.3 0];    % Hemo signals and right y axis
AREACOL     = [.7 .5 .5];    % Area plot for BOLD signal

if iscell(MriSig{1}.dat),
  MriSig{1}.dat = MriSig{1}.dat{1};
end;

nt  = [0:size(NeuSig.dat,1)-1]  * NeuSig.dx;
mt  = [0:size(MriSig{1}.dat,1)-1] * MriSig{1}.dx;
neu  = mean(NeuSig.dat,3);
NeuMax = max(neu(:));
NeuMin = min(neu(:));
NoChan = size(NeuSig.dat,2);
pts = mean(MriSig{1}.dat,2);

mfigure([10 200 1100 750]);
set(gcf,'color',[.6 .65 .6]);
if isa(ExpNo,'char'),
  txt = sprintf('SHOWRMSMRI: Session: %s, Group: %s\n',Ses.name,ExpNo);
else
  txt = sprintf('SHOWRMSMRI: Session: %s, ExpNo: %d\n',Ses.name,ExpNo);
end;
figtitle(txt,'color','k','fontsize',14);

% XCOR MAP AND INFO
subplot(1,2,1);
set(gca,'color','k');
matsmap(MriSig,Thr);
title('R-Value Maps');

% TIME COURSES
subplot(2,2,2);
set(gca,'drawmode','fast');
area(mt,pts,'facecolor',[1 .8 .8],'edgecolor','r');
drawstmlines(MriSig{1},'color','k','linewidth',3,'linestyle',':');
grid on;
set(gca,'xlim',[mt(1) mt(end)]);
xlabel('Time in Seconds','FontWeight','bold','FontSize',9);
ylabel('BOLD Signal Change (SD Units)','FontWeight','bold','FontSize',9);
title('BOLD fMRI Response');

subplot(2,2,4);
COLS='rgbmkycrgbmkyc';
for N=1:NoChan,
  hd(N) = plot(nt,neu(:,N),'color',COLS(N),'linewidth',1.5);
  LAB{N} = sprintf('Chan: %d', N);
  hold on;
end;
set(gca,'xlim',[nt(1) nt(end)]);
grid on;
drawstmlines(NeuSig,'color','k','linewidth',3,'linestyle',':');

% BOLD RESPONSES
xlabel('Time in Seconds','FontWeight','bold','FontSize',9);
ylabel('NEURAL Signal Change (SD Units)','FontWeight','bold','FontSize',9);

h=legend(hd, LAB);
set(h,'Color',[.95 .95 1]);
title('RMS Neural Responses');
return;
