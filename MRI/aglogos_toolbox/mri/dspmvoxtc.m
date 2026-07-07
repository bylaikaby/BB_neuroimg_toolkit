function varargout = dspmvoxtc(ROITS,varargin)
%DSPMVOXTC - displays a mean time course of ROITS structure by mvoxselect
%  DSPMVOXTC(ROITS,...) displays a mean time course of ROITS structure 
%  of that voxsels are  selected by mvoxselect based on the certain statistics/alpha.
%  HAXES = DSPMVOXTC(ROITS,...) does the same things, returing the axes handle.
%
%  Supported options are :
%    axes      : the axes handle to plot.
%    color     : color of the plot.
%    legend    : legend string
%    T0As0     : no delay of volume TR
%    StimAs0   : makes 0 as stimulus onset
%    StimColor : stimulus color
%    FontName  : font name for 'DefaultAxesFontName'
%
%  EXAMPLE :
%    >> sig = mvoxselect('e04ds1','visesmix','all','glm[2]',[],0.01);
%    >> dspmvoxtc(sig);
%  EXAMPLE 2:
%    >> sig1 = mvoxselect('e04ds1','visesmix','v1','glm[1]',[],0.01);
%    >> h = dspmvoxtc(sig1,'color','r');
%    >> sig2 = mvoxselect('e04ds1','visesmix','v2','glm[1]',[],0.01);
%    >> h = dspmvoxtc(sig2,'color','g','axes',h);
%  EXAMPLE 3:
%    >> dspmvoxtc({sig1 sig2},'color',{'r','g'},'legend',{'v1','v2'})
%
%  VERSION :
%    0.90 12.03.07 YM  pre-release
%    0.91 15.03.07 YM  supports 'hold on' capability, ROITS as a cell array.
%    0.92 26.08.09 YM  supports T0As0, StimAs0, StimColor, FontName.
%    0.93 08.12.11 YM  bug fix.
%    0.94 01.02.12 YM  ignore all(NaN) for nvox.
%    0.95 18.07.12 YM  supports .stat.fdq_q.
%
%  See also mvoxselect mvoxselectmask dspmvox dspmvoxmap anaload mview

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end


% CONTROL FLAGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H_AXES       = [];
COLOR        = [];
LEGTXT       = '';
T0_AS_ZERO   = 0;
STIM_AS_ZERO = 0;
STIM_COLOR   = [0.88 0.88 0.88];
DefaultAxesFontName = 'Comic Sans MS';

BSTRP = 100;    % bootstrapping variance

% parse inputs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for N=1:2:length(varargin),
  switch lower(varargin{N}),
   case {'axes'}
    H_AXES = varargin{N+1};
   case {'color'}
    COLOR = varargin{N+1};
   case {'legend'}
    LEGTXT = varargin{N+1};
   case {'bootstrap','bstrp'}
    BSTRP = varargin{N+1};
   case {'t0as0','t0aszero'}
    T0_AS_ZERO = varargin{N+1};
   case {'stimas0','stimaszero'}
    STIM_AS_ZERO = varargin{N+1};
   case {'stimcolor'}
    STIM_COLOR = varargin{N+1};
   case {'fontname','font','defaultaxesfontname'}
    DefaultAxesFontName = varargin{N+1};
  end
end


if iscell(ROITS) && length(ROITS) > 1,
  if isempty(COLOR),  COLOR = {'r','g','b','c','m','y','k'};  end
  for N = 1:length(ROITS),
    if iscell(COLOR),
      tmpcolor = COLOR{mod(N-1,length(COLOR))+1};
    elseif size(COLOR,1) > 1,
      tmpcolor = COLOR(mod(N-1,size(COLOR,1))+1,:);
    else
      tmpcolor = COLOR;
    end
    if iscell(LEGTXT),
      tmplegtxt = LEGTXT{N};
    else
      tmplegtxt = LEGTXT;
    end
    H_AXES = dspmvoxtc(ROITS{N},'axes',H_AXES,...
                       'color',tmpcolor,'legend',tmplegtxt,...
                       'T0As0',T0_AS_ZERO,'StimAs0',STIM_AS_ZERO,...
                       'StimColor',STIM_COLOR,'FontName',DefaultAxesFontName,...
                       'bootstrap',BSTRP);
  end
  if nargout,
    varargout{1} = H_AXES;
  end
  return
elseif iscell(ROITS),
  ROITS = ROITS{1};
end


if isempty(COLOR),  COLOR = 'b';  end


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(ROITS.session),
  Ses = goto(ROITS.session);
  grp = getgrp(Ses,ROITS.grpname);
  ANAP = getanap(Ses,grp);
else
  ANAP = [];
end

% PLOT TIME COURSE
if ischar(ROITS.session),
  tmptitle = sprintf('%s(%s) ROI:%s model:%s P<%g',Ses.name,grp.name,...
                     ROITS.name,ROITS.stat.model,ROITS.stat.alpha);
else
  tmptitle = sprintf('NSes=%d ROI:%s model:%s P<%g',length(ROITS.session),...
                     ROITS.name,ROITS.stat.model,ROITS.stat.alpha);
end
if isfield(ROITS.stat,'fdr_q') && any(ROITS.stat.fdr_q),
  tmptitle = sprintf('%s (P0=%g/FDRq=%g)',tmptitle,ROITS.stat.uncorrected_alpha,ROITS.stat.fdr_q);
end


if isempty(H_AXES) || ~ishandle(H_AXES),
  figure('Name',sprintf('%s: %s',mfilename,tmptitle));
  set(gcf,'DefaultAxesfontsize',	10);
  set(gcf,'DefaultAxesfontweight','bold');
  set(gcf,'DefaultAxesFontName', DefaultAxesFontName);
  % check the position of the figure, due to Matlab's bug,
  % sometimes the figure appears outside the monitor....
  pos = get(gcf,'pos');
  if abs(pos(1)) > 5000 || abs(pos(2)) > 5000,
    set(gcf,'pos',[100 100 pos(3) pos(4)]);
  end
  %axes('pos',[0.1300    0.100    0.7750    0.17]);
  H_AXES = axes();
else
  axes(H_AXES);
end

tctag = 'tcdat';
hTC = findobj(H_AXES,'tag',tctag);
if ~isempty(hTC),  hold on;  end

nvox = length(find(all(~isnan(ROITS.dat),1)));
%nvox = size(ROITS.dat,2);
if isempty(LEGTXT),
  tmptxt = sprintf('ROI:%s %s P<%g, N=%d',...
                   ROITS.name,ROITS.stat.model,ROITS.stat.alpha,nvox);
else
  tmptxt = LEGTXT;
end

if T0_AS_ZERO,
  tmpt = (0:size(ROITS.dat,1)-1)*ROITS.dx;
else
  tmpt = (1:size(ROITS.dat,1))*ROITS.dx;
end

STIM_TOFFS = 0;
if STIM_AS_ZERO && isfield(ROITS,'stm') && ~isempty(ROITS.stm),
  if isfield(ROITS.stm,'v') && isfield(ROITS.stm,'stmtypes'),
    for N = 1:length(ROITS.stm.v{1}),
      tmpv = ROITS.stm.v{1}(N);
      if ~any(strcmpi(ROITS.stm.stmtypes{tmpv+1},{'blank','none'})),
        STIM_TOFFS = ROITS.stm.time{1}(N);
        tmpt = tmpt - STIM_TOFFS;
        break;
      end
    end
  end
end


if size(ROITS.dat,2) > 1,
  if BSTRP,
    tmp = ROITS.dat;
    y = nanmean(tmp,2);
    Boot = bootstrp(BSTRP,@hnanmean,tmp'); 
    Cinter = prctile(Boot,[1,99]); % the 1 and 99% intervals
    hd = plot(tmpt, y,'linewidth',2,'color',COLOR,'tag','tcdat','UserData',tmptxt);
    hold on
    plot(tmpt,Cinter(1,:),'linestyle','-','color',COLOR,'linewidth',.5,'tag','cint');
    plot(tmpt,Cinter(2,:),'linestyle','-','color',COLOR,'linewidth',.5,'tag','cint');
    set(findobj(H_AXES,'tag','cint'),'handlevisibility','off');  % for legend()
  else
    tmpm = nanmean(ROITS.dat,2);
    tmps = nanstd(ROITS.dat,[],2) / sqrt(nvox);
    hd = errorbar(tmpt,tmpm,tmps,'color',COLOR,'tag','tcdat','UserData',tmptxt);
    eb = findall(hd);
    set(eb(1),'LineWidth',1.5);
    set(eb(2),'LineWidth',1.5);
  end;
else
  plot(tmpt,zeros(size(tmpt)),'color',COLOR,'tag','tcdat','UserData',tmptxt,'linewidth',1.5);
end
grid on;
xlabel('Time in sec');
set(gca,'xlim',[min(tmpt) max(tmpt)],'layer','top');

if isfield(ROITS,'xform') && isfield(ROITS.xform,'method'),
  switch lower(ROITS.xform(end).method),
   case {'tosdu', 'sdu'}
    tmpylabel = 'Amplitude in SDU';
   case {'percent'}
    tmpylabel = 'Amplitude in % changes';
   case {'frac'}
    tmpylabel = 'Amplitude in fraction';
   case {'zerobase'}
    tmpylabel = 'Amplitude (zero-base)';
  end
else
  tmpylabel = 'Arbitral Units';
end


if isempty(hTC),
  ylabel(tmpylabel);
  text(0.01,0.92,tmptxt,'units','normalized','FontSize',8,'tag','legend1');
  if size(ROITS.dat,2) > 1,
    if BSTRP,
      text(0.01,0.01,'mean+-cint','units','normalized','FontSize',8,'VerticalAlignment','bottom');
    else
      text(0.01,0.01,'mean+-sem','units','normalized','FontSize',8,'VerticalAlignment','bottom');
    end
  end
  subDrawStimIndicators(gca,ROITS,1,STIM_TOFFS,STIM_COLOR);
else
  ylabels = get(get(H_AXES,'ylabel'),'String');
  if ~any(strcmpi(ylabels,tmpylabel)),
    if ischar(ylabels),  ylabels{1} = ylabels;  end
    ylabels{end+1} = tmpylabel;
    ylabel(ylabels);
  end
  delete(findobj(H_AXES,'tag','legend1'));
  legtxt = {};
  for N = 1:length(hTC),
    legtxt{N} = get(hTC(N),'UserData');
  end
  legtxt{end+1} = tmptxt;
  legend(legtxt,'fontsize',10);
  subDrawStimIndicators(gca,ROITS,0,STIM_TOFFS,STIM_COLOR);
end


if nargout,
  varargout{1} = H_AXES;
end

return





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to draw stimulus indicators
function subDrawStimIndicators(haxs,Sig,NEWPLOT,STIM_TOFFS,STIM_COLOR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% draw stimulus indicators
ylm   = get(haxs,'ylim');  tmph = ylm(2)-ylm(1);
drawL = [];  drawR = [];
if isfield(Sig,'stm') && ~isempty(Sig.stm) && NEWPLOT,
  stimv = Sig.stm.v{1};
  stimt = Sig.stm.time{1};  stimt(end+1) = sum(Sig.stm.dt{1});
  stimt = stimt - STIM_TOFFS;
  stimdt = Sig.stm.dt{1};
  for N = 1:length(stimv),
    if any(strcmpi(Sig.stm.stmpars.StimTypes{stimv(N)+1},{'blank','none','nostim'})),
      continue;
    end
    if stimt(N) == stimt(N+1),
      tmpw = stimdt(N);
    else
      tmpw = stimt(N+1) - stimt(N);
    end
    if ~any(drawL == stimt(N)),
      line([stimt(N), stimt(N)],ylm,'color','k','tag','stim-line');
      drawL(end+1) = stimt(N);
    end
    if isempty(drawR) || ~any(drawR(:,1) == stimt(N) & drawR(:,2) == tmpw),
      rectangle('Position',[stimt(N) ylm(1) tmpw tmph],...
                'facecolor',STIM_COLOR,'linestyle','none',...
                'tag','stim-rect');
      drawR(end+1,1) = stimt(N);
      drawR(end  ,2) = tmpw;
    end
    if ~any(drawL == stimt(N)+tmpw),
      line([stimt(N),stimt(N)]+tmpw,ylm,'color','k','tag','stim-line');
      drawL(end+1) = stimt(N)+tmpw;
    end
  end
end

% adjust stimulus indicator size
set(allchild(haxs),'HandleVisibility','on');
ylm = get(haxs,'ylim');  tmph = ylm(2)-ylm(1);
h = findobj(haxs,'tag','stim-line');
set(h,'ydata',ylm);
h = findobj(haxs,'tag','stim-rect');
for N = 1:length(h),
  tmppos = get(h(N),'pos');
  tmppos(2) = ylm(1);  tmppos(4) = tmph;
  set(h(N),'pos',tmppos);
end

setfront(findobj(haxs,'tag','stim-line'));
setback(findobj(haxs,'tag','stim-rect'));
% set indicators' handles invisible to use legend() funciton.
set(findobj(haxs,'tag','stim-line'),'handlevisibility','off');
set(findobj(haxs,'tag','stim-rect'),'handlevisibility','off');
return;
