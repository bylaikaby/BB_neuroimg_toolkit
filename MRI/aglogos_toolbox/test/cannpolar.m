function cannpolar(SESSION,ExpNo)
%CANNPOLAR - plots Lfp/Mua time course for cannabinoid injection
%  CANNPOLAR(SESSION,EXPNO) plots Lfp/Mua time course for cannabinoid injection.
%
%  VERSION :
%    15.08.05 YM  pre-release
%
%  See also

if nargin < 2,  help cannpolar; return;  end



% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);



% LOAD DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sigload(Ses,ExpNo,'Mua','LfpL','LfpM','LfpH');


% SORT OUT DATA BY STMULUS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PRE_T  = 2.0;
POST_T = 7.5;
spar = getsortpars(Ses,ExpNo);
Mua  = sigsort(Mua,  spar.stim, PRE_T, POST_T);
LfpL = sigsort(LfpL, spar.stim, PRE_T, POST_T);
LfpM = sigsort(LfpM, spar.stim, PRE_T, POST_T);
LfpH = sigsort(LfpH, spar.stim, PRE_T, POST_T);

[Mua1, Mua2]   = subMeanStd(Mua, grp);
[LfpL1, LfpL2] = subMeanStd(LfpL,grp);
[LfpM1, LfpM2] = subMeanStd(LfpM,grp);
[LfpH1, LfpH2] = subMeanStd(LfpH,grp);


% PLOT DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure('Name',sprintf('%s ExpNo=%d',Ses.name,ExpNo));
T = [0:size(Mua2.dat,1)-1]*Mua2.dx - PRE_T;
RECT_COL = [0.9 0.9 0.9];
if ~isempty(findstr(grp.stminfo,'inj')),
  subplot(2,2,1);
  rectangle('position',[0 0 5 5000],'facecolor',RECT_COL,'edgecolor',RECT_COL);
  hold on;  grid on;
  plot(T,mean(Mua1.dat,2),  'r');
  plot(T,mean(LfpL1.dat,2), 'g');
  plot(T,mean(LfpM1.dat,2), 'b');
  plot(T,mean(LfpH1.dat,2), 'm');
  set(gca,'xlim',[min(T) max(T)],'ylim',[0 3500],'layer','top');
  legend('Mua','LfpL','LfpM','LfpH');
  title(sprintf('%s ExpNo=%d  PRE-INJECTION',Ses.name,ExpNo));
  xlabel('Time in seconds');   ylabel('ADC Units');
  text(0.01,0.05,sprintf('nchans=%d ntrials=%d',Mua1.nchans,Mua1.ntrials),...
       'units','normalized');
  box on;
end
subplot(2,2,2);
rectangle('position',[0 0 5 5000],'facecolor',RECT_COL,'edgecolor',RECT_COL);
hold on;  grid on;
plot(T,mean(Mua2.dat,2),  'r');
plot(T,mean(LfpL2.dat,2), 'g');
plot(T,mean(LfpM2.dat,2), 'b');
plot(T,mean(LfpH2.dat,2), 'm');
set(gca,'xlim',[min(T) max(T)],'ylim',[0 3500],'layer','top');
legend('Mua','LfpL','LfpM','LfpH');
title(sprintf('%s ExpNo=%d  POST-INJECTION',Ses.name,ExpNo));
xlabel('Time in seconds');   ylabel('ADC Units');
text(0.01,0.05,sprintf('nchans=%d ntrials=%d',Mua2.nchans,Mua2.ntrials),...
     'units','normalized');
box on;

subplot(2,2,3);
Sig = subMeanResponse(Mua,grp,'polar');
T = [0:size(Sig.dat,2)-1]*Sig.dx;
plot(T,mean(Sig.dat,1),  'r', 'marker','.','markersize',8);
hold on; grid on;
Sig = subMeanResponse(LfpL,grp,'polar');
plot(T,mean(Sig.dat,1),  'g', 'marker','.','markersize',8);
Sig = subMeanResponse(LfpM,grp,'polar');
plot(T,mean(Sig.dat,1),  'b', 'marker','.','markersize',8);
Sig = subMeanResponse(LfpH,grp,'polar');
plot(T,mean(Sig.dat,1),  'm', 'marker','.','markersize',8);
set(gca,'xlim',[min(T) max(T)],'ylim',[0 2500],'layer','top');
legend('Mua','LfpL','LfpM','LfpH');
title(sprintf('%s ExpNo=%d  VISUAL RESPONSES',Ses.name,ExpNo));
xlabel('Time in seconds');   ylabel('ADC Units');
text(0.01,0.05,sprintf('nchans=%d',Sig.nchans),...
     'units','normalized');
if ~isempty(findstr(grp.stminfo,'inj')),
  line([60 60],get(gca,'ylim'),'color','black');
  text(60,2000,'injection','horizontalalignment','right');
end

subplot(2,2,4);
Sig = subMeanResponse(Mua,grp,'blank');
T = [0:size(Sig.dat,2)-1]*Sig.dx;
plot(T,mean(Sig.dat,1),  'r', 'marker','.','markersize',8);
hold on; grid on;
Sig = subMeanResponse(LfpL,grp,'blank');
plot(T,mean(Sig.dat,1),  'g', 'marker','.','markersize',8);
Sig = subMeanResponse(LfpM,grp,'blank');
plot(T,mean(Sig.dat,1),  'b', 'marker','.','markersize',8);
Sig = subMeanResponse(LfpH,grp,'blank');
plot(T,mean(Sig.dat,1),  'm', 'marker','.','markersize',8);
set(gca,'xlim',[min(T) max(T)],'ylim',[0 2500],'layer','top');
legend('Mua','LfpL','LfpM','LfpH');
title(sprintf('%s ExpNo=%d  BASE LINE CHANGES',Ses.name,ExpNo));
xlabel('Time in seconds');   ylabel('ADC Units');
text(0.01,0.05,sprintf('nchans=%d',Sig.nchans),...
     'units','normalized');
if ~isempty(findstr(grp.stminfo,'inj')),
  line([60 60],get(gca,'ylim'),'color','black');
  text(60,2000,'injection','horizontalalignment','right');
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to compute mean and std of pre/post
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [SIG1, SIG2] = subMeanStd(Sig,grp)

if isfield(grp,'findch') & ~isempty(grp.findch),
  Chans = grp.findch;
else
  Chans = 1:size(Sig.dat,2);
end


SIG1 = rmfield(Sig,'dat');  SIG1.nchans = length(Chans);
SIG2 = rmfield(Sig,'dat');  SIG2.nchans = length(Chans);


if ~isempty(findstr(grp.stminfo,'inj')),
  SIG1.dat = squeeze(mean(Sig.dat(:,Chans,1:10),2));
  SIG1.std = squeeze(std(Sig.dat(:,Chans,1:10),[],2));
  SIG2.dat = squeeze(mean(Sig.dat(:,Chans,11:end),2));
  SIG2.std = squeeze(std(Sig.dat(:,Chans,11:end),[],2));
  SIG1.ntrials = 10;
  SIG2.ntrials = length(11:size(Sig.dat,3));
else
  SIG1.dat = [];
  SIG1.std = [];
  SIG2.dat = squeeze(mean(Sig.dat(:,Chans,1:end),2));
  SIG2.std = squeeze(std(Sig.dat(:,Chans,1:end),[],2));
  SIG1.ntrials = 0;
  SIG2.ntrials = length(11:size(Sig.dat,3));
end

  
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to compute mean and std of pre/post
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SIG = subMeanResponse(Sig,grp,epoch)

if isfield(grp,'findch') & ~isempty(grp.findch),
  Chans = grp.findch;
else
  Chans = 1:size(Sig.dat,2);
end


SIG = rmfield(Sig,'dat');  SIG.nchans = length(Chans);

T = [0:size(Sig.dat,1)-1]*Sig.dx - Sig.stm.time{1}(1);
if strcmpi(epoch,'blank'),
  sel = find(T < 0);
else
  sel = find(T > 0 & T < Sig.stm.dt{1}(1));
end

SIG.dat = squeeze(mean(Sig.dat(sel,Chans,:),1));
SIG.std = squeeze(std(Sig.dat(sel,Chans,:),[],1));

SIG.dx = 10;

return;

