function cannshowchan(SESSION,ExpNo,SIGNAMES)
%CANNSHOWCHAN - shows visual responses for each channel.
%  CANNSHOWCHAN(SESSION,EXPNO,SIGNAMES) shows visual responses for each channel.
%
%  VERSION :
%    0.90 16.08.05 YM  pre-release
%
%  See also CANNPOLAR

if nargin < 2,  help cannshowchan; return;  end

if nargin < 3,  SIGNAMES = '';  end


if isempty(SIGNAMES),  SIGNAMES = {'Mua','LfpL','LfpM','LfpH'};  end


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);


% LOAD DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
par  = expgetpar(Ses,ExpNo);
PRE_T  = 2.0;
POST_T = 7.5;



% PLOT DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
timestr = par.stm.date(5:end);
COL = 'rgbmrgbm';
figure('Name',sprintf('%s: %s ExpNo=%d %s',mfilename,Ses.name,ExpNo,timestr),...
       'NextPlot','add');
for N = 1:length(SIGNAMES),
  [hAX, tmp2] = subPlotData(Ses,ExpNo,SIGNAMES{N},PRE_T,POST_T,COL(N),N==1,length(SIGNAMES)>1);
  if ~isempty(tmp2),  hAX2 = tmp2;  end
end
% need to do this to see Mua...
if ~isempty(hAX2),
  for N = 1:length(hAX2),
    set(hAX2(N),'ActivePositionProperty','position','pos',get(hAX(N),'pos'));
    set(hAX(N),'ActivePositionProperty','position');
    axes(hAX2(N));
    set(gcf,'CurrentAxes',hAX(N));
  end
end
  


% put legend
pos = get(hAX(end),'position');
h = axes('position',[pos(1)+pos(3)+0.005 pos(2) 0.07 pos(4)]);
ystep = 1.0/(length(SIGNAMES)+1);
for N = 1:length(SIGNAMES),
  tmpy = 1 - ystep*N;
  tmprange = Ses.anap.bands.(SIGNAMES{N});
  if strcmpi(SIGNAMES{N},'Mua'),
    tmptxt = sprintf('%s [%d-%dk]',SIGNAMES{N},tmprange(1),tmprange(2)/1000);
  else
    tmptxt = sprintf('%s [%d-%d]',SIGNAMES{N},tmprange(1),tmprange(2));
  end
  line([0.02 0.4],[tmpy tmpy],'color',COL(N),'linewidth',2);
  text(0.42,tmpy,tmptxt,'fontsize',8);
end
set(gca,'xlim',[0 1],'ylim',[0 1],'box','on',...
        'xtick',[],'xticklabel',{},'ytick',[],'yticklabel',{});

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION TO PLOT DATA
function [hAX hAX2] = subPlotData(Ses,ExpNo,SIGNAME,PRE_T,POST_T,COLOR,IS_FIRST,IS_MULTISIG)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% CONTROL SETTINGS
MUA_SCALE = 4;
MAX_Y     = 4000;
  
% LOAD DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
spar = getsortpars(Ses,ExpNo);
Sig = sigload(Ses,ExpNo,SIGNAME);
STIM_DUR = Sig.stm.dt{1}(2);  % assumes blank-polar-blank
sSig = sigsort(Sig,spar.stim,PRE_T,POST_T);

hAX = [];  hAX2 = [];

mdata = squeeze(mean(sSig.dat,3));

% PLOT DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
timestr = Sig.stm.date(5:end);
T = [0:size(mdata,1)-1]*Sig.dx - PRE_T;
RECT_COL = [0.9 0.9 0.9];
for N = 1:size(mdata,2),
  hAX(N) = subplot(4,4,N);
  if IS_FIRST > 0,
    rectangle('position',[0 0 STIM_DUR 5000],'facecolor',RECT_COL,'edgecolor',RECT_COL);
  end
  hold on; grid on;
  if IS_MULTISIG & strcmpi(SIGNAME,'Mua'),
    hAX2(N)= axes('position',get(hAX(N),'position'));
    set(gca,'YAxisLocation','right','color','none', ...
            'XGrid','off','YGrid','off','Box','off',...
            'XTick',[],'XTickLabel',{});
    set(gca,'ylim',[0 MAX_Y/MUA_SCALE]);
    set(gca,'xlim',[min(T),max(T)]);
    if IS_FIRST > 0 && N == 1,
      ylabel('MUA ADC Units','fontsize',8);
    end
    set(gca,'HandleVisibility','off');  % do this, since next call of subplot() will delete...
    %set(gca,'ActivePositionProperty','position');
    if N == 1,  mdata = mdata * MUA_SCALE;  end
  end
  plot(T,mdata(:,N),'color',COLOR);
  axes(hAX(N));
  %set(gca,'ActivePositionProperty','position');
  set(gca,'xlim',[min(T),max(T)],'layer','top','box','on');
  set(gca,'ylim',[0 MAX_Y]);
  if IS_FIRST > 0,
    axes(hAX(N));
    text(0.98,0.98,sprintf('ch=%d',N),'units','normalized',...
         'horizontalalignment','right','verticalalignment','top');
    set(gca,'fontsize',8);
    if N == 1,
      title(sprintf('%s ExpNo=%d %s',Ses.name,ExpNo,timestr));
      if IS_MULTISIG,
        ylabel('LFP ADC Units');
      else
        ylabel('ADC Units');
      end
    end
    if N == size(mdata,2),
      xlabel('Time in seconds');
    end
  end
  
end

return;
