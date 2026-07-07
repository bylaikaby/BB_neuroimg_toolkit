function cannashow(SESSION)
%CANNASHOW - plots time courses of baseline/response throughout injection.
%  CANNASHOW(SESSION) plots time courses of baseline/response throughout injection.
%
%
%  VERSION :
%    19.08.05 YM  pre-release
%
%  See also CANNASHOWCHAN

if nargin == 0,  help cannashow;  return;  end


% CONTROL FLAGS/SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SIG_NAMES  = {'Mua','LfpL','LfpM','LfpH'};
SIG_COLORS = 'rgbm';
PRE_T  = 2;
POST_T = 2;
MUA_SCALE = 10;


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);



grpnames = fieldnames(Ses.grp);
idx = find(strncmpi(grpnames,'canninj',7));
EXPS = [];
for N = 1:length(idx),
  grp = getgrp(Ses,grpnames{idx(N)});
  EXPS = [EXPS(:)' grp.exps(:)'];
end


par = expgetpar(Ses,min(EXPS));
t0 = datenum(par.evt.date(5:end),'mmm dd HH:MM:SS yyyy');

%EXPS = EXPS(1:3)

fprintf('%s %s: %s (nexps=%d)',datestr(now,'HH:MM:SS'),mfilename,Ses.name,length(EXPS));

figure('Name',sprintf('%s: %s',mfilename,Ses.name));
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName',  'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');
set(gcf,'PaperOrientation',     'landscape');
for iExp = 1:length(EXPS),
  fprintf('.');
  ExpNo = EXPS(iExp);
  par = expgetpar(Ses,ExpNo);
  tX = datenum(par.evt.date(5:end),'mmm dd HH:MM:SS yyyy');
  [Y, M, D, H, MI, S] = datevec(tX - t0);
  TS = D*24*60 + H*60 + MI + S/60;	% convert into minutes
  
  for iSig = 1:length(SIG_NAMES),
    SigName = SIG_NAMES{iSig};  SigColor = SIG_COLORS(iSig);
    subPlotData(Ses,ExpNo,TS,SigName,SigColor,PRE_T,POST_T,MUA_SCALE)
  end
end


legtxt = {};
for N = 1:length(SIG_NAMES),
  tmprange = Ses.anap.bands.(SIG_NAMES{N});
  if strcmpi(SIG_NAMES{N},'Mua'),
    tmptxt = sprintf('%s [%d-%dk]',SIG_NAMES{N},tmprange(1),tmprange(2)/1000);
  else
    tmptxt = sprintf('%s [%d-%d]',SIG_NAMES{N},tmprange(1),tmprange(2));
  end
  legtxt{N} = tmptxt;
end

subplot(2,1,1);
xlabel('Time in minutes');  ylabel(sprintf('ADC Units (LFP:x1 MUA:x%d)',MUA_SCALE));
set(gca,'ylim',[0 5000]);
title(sprintf('VISUAL RESPONSE: %s',Ses.name));
legend(legtxt,'location','EastOutside');
subplot(2,1,2);
xlabel('Time in minutes');  ylabel(sprintf('ADC Units (LFP:x1 MUA:x%d)',MUA_SCALE));
set(gca,'ylim',[0 5000]);
title(sprintf('BASE LINE: %s',Ses.name));
legend(legtxt,'location','EastOutside');
%subplot(3,1,3);
%xlabel('Time in minutes');  ylabel('Visual Responses (base=1)');
%set(gca,'ylim',[0 3]);
%title(sprintf('RATIO of RESP/BASE: %s',Ses.name));
%legend(legtxt,'location','EastOutside');



% draw injection lines
EXP_CANNINJ = [43 44 52 59];
EXP_ANTAINJ = [47 48 49];
for iExp = 1:length(EXP_CANNINJ),
  ExpNo = EXP_CANNINJ(iExp);
  par = expgetpar(Ses,ExpNo);
  tX = datenum(par.evt.date(5:end),'mmm dd HH:MM:SS yyyy');
  [Y, M, D, H, MI, S] = datevec(tX - t0);
  TS = D*24*60 + H*60 + MI + S/60;	% convert into minutes
  Ti = TS + 1;
  
  subplot(2,1,1);
  line([Ti Ti],get(gca,'ylim'),'color','k');
  subplot(2,1,2);
  line([Ti Ti],get(gca,'ylim'),'color','k');
  %subplot(3,3,3);
  %line([Ti Ti],get(gca,'ylim'),'color','k');
end
for iExp = 1:length(EXP_ANTAINJ),
  ExpNo = EXP_ANTAINJ(iExp);
  par = expgetpar(Ses,ExpNo);
  tX = datenum(par.evt.date(5:end),'mmm dd HH:MM:SS yyyy');
  [Y, M, D, H, MI, S] = datevec(tX - t0);
  TS = D*24*60 + H*60 + MI + S/60;	% convert into minutes
  Ti = TS + 1;
  subplot(2,1,1);
  line([Ti Ti],get(gca,'ylim'),'color','y');
  subplot(2,1,2);
  line([Ti Ti],get(gca,'ylim'),'color','y');
  %subplot(3,3,3);
  %line([Ti Ti],get(gca,'ylim'),'color','y');
end



fprintf(' done.\n');


return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot data
function subPlotData(Ses,ExpNo,TS,SigName,SigColor,PRE_T,POST_T,MUA_SCALE)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    % LOAD DATA
    Sig = sigload(Ses,ExpNo,SigName);
    spar = getsortpars(Ses,ExpNo);
    Sig = sigsort(Sig,spar.stim,PRE_T,POST_T);
    T = zeros(1,length(spar.stim.tonset{1}));
    for N = 1:length(T),
      T(N) = spar.stim.tonset{1}{N}(1)/60 + TS;
    end
    
    grp = getgrp(Ses,ExpNo);
    if isfield(grp,'findch') & isempty(grp.findch),
      Sig.dat = Sig.dat(:,grp.findch,:);
    end
    
    tmpt = [0:size(Sig.dat,1)-1]*Sig.dx - PRE_T;
    
    bsel = find(tmpt < 0);
    vsel = find(tmpt > 0 & tmpt < Sig.stm.dt{1}(1));

    if strcmpi(SigName,'Mua'),  Sig.dat = Sig.dat * MUA_SCALE;  end
    
    bdata = squeeze(mean(Sig.dat(bsel,:,:),2));
    vdata = squeeze(mean(Sig.dat(vsel,:,:),2));
    
    
    % plot visual responses
    subplot(2,1,1);
    plot(T,mean(vdata,1),'color',SigColor,'marker','.','markersize',8);
    %plot(T,vdata,'color',SigColor);
    hold on;  grid on;
    
    % plot base line
    subplot(2,1,2);
    plot(T,mean(bdata,1),'color',SigColor,'marker','.','markersize',8);
    %plot(T,bdata,'color',SigColor);
    hold on;  grid on;

    % plot ratio
    %subplot(3,1,3);
    %plot(T,mean(vdata,1)./mean(bdata,1),'color',SigColor,'marker','.','markersize',8);
    %plot(T,vdat./bdata,'color',SigColor);
    %hold on;  grid on;
    
return;

