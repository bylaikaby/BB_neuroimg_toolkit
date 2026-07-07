function dspclnspc(Spc,ChanNo,ARGS)
%DSPCLNSPC - shows the spectrograms of the Cln signal (e.g. ClnSpc)
%
% DSPCLNSPC (Spc, ExpNo) shows the spectrogram of the "ChanNo"
% recording channel of the Cln signal as surface plot in three
% dimensions. X is time, Y frequency, and Z power.
%
% DSPCLNSPC (Spc) shows the spectrogram of all channels averaged.
%
% DSPCLNSPC (...ARGS) shows the spectrogram with parameters
% defined by the user.
%
% Default Parameters:
% -----------------------------
% PLOT3D        = 0;            % 3D or Color-Coded-Only Surface
% COLBAR        = 1;            % Color bar requested
% WALLPLOTS     = 1;            % Plot on the wall the signal averages
% RANGELINES	= 1;            % Draw lines showing LFP/MUA Ranges
% RANGEVALS     = 1;            % Display the range values
% STIMULUS      = 1;            % Plot lines at Sig.stm{ObsNo}.stm...
% LFPRANGE      = [30 100];     % Range within which LFPs are averaged
% MUARANGE      = [500 2000];   % Range within which LFPs are averaged
% FRANGE        = [20 3000];    % Frequency range to plot
% TRANGE        = [];           % Time range to plot
% SDUNITS		= 1;            % if 0, then in dB units (log power)
% FEXTENTION	= 6000;         % push y axis back to see the time courses wall
% UNITLABEL     = 'SD Units';   % Z-units
%
% NKL, 20.02.01

PLOT3D  	= 0;            % 3D or Color-Coded-Only Surface
COLBAR  	= 1;            % Color bar requested
WALLPLOTS	= 1;            % Plot on the wall the signal averages
RANGELINES	= 1;            % Draw lines showing LFP/MUA Ranges
RANGEVALS	= 1;            % Display the range values
STIMULUS	= 0;            % Plot lines at Sig.stm{ObsNo}.stm...
LFPRANGE	= [30 100];     % Range within which LFPs are averaged
MUARANGE	= [500 2000];   % Range within which LFPs are averaged
FRANGE      = [20 3000];    % Frequency range to plot
TRANGE      = [];           % Time range to plot
SDUNITS		= 0;            % if 0, then in dB units (log power)
FEXTENTION	= 6000;         % push y axis back to see the time courses wall
UNITLABEL	= 'SD Units';   % Z-units

if nargin < 2,
  ChanNo = [];
end;

% The ClnSpc array it usually is a 3-D array of TimeXFreqXChanNo
% If however, multiple observation periods are collected, or the sigsort is used, it can be
% of 4 or even 5 dimensions. Four if each observation period has 1 trial-type, and 5 if each
% observation period has more than 1 repetitions of that trial-type.
% To ensure proper averaging we do the following:

if ~isempty(ChanNo),
  Spc.dat = Spc.dat(:,:,ChanNo,:,:,:);
end;

s = size(Spc.dat);
Spc.dat = reshape(Spc.dat,[s(1) s(2) prod(s(3:end))]);
Spc.dat = mean(Spc.dat,3);

if exist('ARGS'),
  pareval(ARGS);
end;


% IF NO 3D IS REQUESTED DETERMINE WHAT SHOULD BE PLOTTED...
if ~PLOT3D,
  WALLPLOTS = 0;            % There are no walls
  RANGEVALS = 0;            % No Range Values
  SDUNITS = 1;              % Plot power
  UNITLABEL	= 'Power (db)'; % Color-coded Units
end;

% CHECK LIMITS TO AVOID DISPLAY-PROBLEMS
if LFPRANGE(1) < FRANGE(1),
  LFPRANGE(1) = FRANGE(1);  % Otherwise it won't display the range-lines
end;

if MUARANGE(2) > FRANGE(2),
  FRANGE(2) = MUARANGE(2)   % Otherwise it won't display the range-lines
end;

% GET TIME AND FREQUENCY SERIES
t = [0:size(Spc.dat,1)-1]'*Spc.dx(1);
f = [0:size(Spc.dat,2)-1]'*Spc.dx(2);

if isempty(FRANGE)
  FRANGE = [f(1) f(end)];
end;

if isempty(TRANGE)
  TRANGE = [t(1) t(end)];
end;

FREQ_WIND = find(f>=FRANGE(1) & f<=FRANGE(2));
TIME_WIND = find(t>=TRANGE(1) & t<=TRANGE(2));

t = t(TIME_WIND);
f = f(FREQ_WIND);
lfppnts = find(f >= LFPRANGE(1) & f <= LFPRANGE(2));
muapnts = find(f >= MUARANGE(1) & f <= MUARANGE(2));

if SDUNITS,
  Spc = tosdu(Spc);                     % Convert to SD Units
else
  Spc.dat = 20 * log10(Spc.dat);          % Convert to dB Units
  Spc.dat = Spc.dat - min(Spc.dat(:));
end;

mspc = Spc.dat(TIME_WIND,FREQ_WIND);
Spc.dat = []; pack;
lfp = hnanmean(mspc(:,lfppnts),2);
mua = hnanmean(mspc(:,muapnts),2);

if PLOT3D,
  % THE FOLLOWING IS JUST TO GET OUR APPEARANCES RIGHT...
  m = median(mspc(find(mspc(:))));
  s = std(mspc(find(mspc(:))));
  cmax = m + 12 * s;               % The 8/2 Factors are purely empirical
  cmin = m - 4 * s;               % It seems to work for most plots!
  mspc(find(mspc>cmax))=cmax;
  mspc(find(mspc<cmin))=cmin;
else
  cmax = max(mspc(:)) * 0.95;
  cmin = min(mspc(:));
end;

% =================================================================
%					 P L O T T I N G . . . . .
% =================================================================
surf(t,f,mspc');
xlabel('Time in Seconds','FontSize',8);
ylabel('Frequency in Hz','FontSize',8);
zlabel(UNITLABEL,'FontSize',8);
if PLOT3D,
  view(45,70);        % view(35,60);
else
  view(0,90);
end;
shading interp;
hold on;

set(gca,'yscale','log');

if WALLPLOTS,                   % If wall-plots desired push one wall farer, so we
  set(gca,'Xlim',[0 t(end)]);   % can see the curves better...           
  set(gca,'Ylim',[f(1) FEXTENTION]);
else
  set(gca,'Xlim',[t(1) t(end)]);
  set(gca,'Ylim',[f(1) f(end)]);
end;

set(gca,'Clim',[cmin cmax],'Zlim',[cmin cmax]);
set(gca,'Xcolor','k','LineWidth',1);
set(gca,'Ycolor','k','LineWidth',1);
set(gca,'FontSize',7);
set(gca,'color',[1 .95 .85]);

L  = LFPRANGE(1);  R  = LFPRANGE(2);
ML = MUARANGE(1);  MR = MUARANGE(2);
xl = get(gca,'xlim');
yl = get(gca,'ylim');
zl = get(gca,'zlim');

if RANGELINES,
  %%% PLOT LFP/MUA RANGES: Lines parallel to X-axis
  line(xl,[ L  L],[zl(2) zl(2)],'color','k','LineWidth',2,'LineStyle','--');
  line(xl,[ R  R],[zl(2) zl(2)],'color','k','LineWidth',2,'LineStyle','--');
  line(xl,[ML ML],[zl(2) zl(2)],'Color','b','LineWidth',2,'LineStyle','--');
  line(xl,[MR MR],[zl(2) zl(2)],'Color','b','LineWidth',2,'LineStyle','--');

  %%% PLOT LFP/MUA RANGES: Lines on the Frequency-Wall
  line([xl(1) xl(1)],[L L],zl,'color','k','LineWidth',2,'LineStyle','--');
  line([xl(1) xl(1)],[R R],zl,'color','k','LineWidth',2,'LineStyle','--');
  line([xl(1) xl(1)],[ML ML],zl,'Color','b','LineWidth',2,'LineStyle','--');
  line([xl(1) xl(1)],[MR MR],zl,'Color','b','LineWidth',2,'LineStyle','--');
  
  % DO WHAT THE 'BOX' SHOULD BE DOING...
  line([xl(1) xl(1)],yl,[zl(2) zl(2)],'color','k','LineWidth',1);
  line(xl,[yl(2) yl(2)],[zl(2) zl(2)],'color','k','LineWidth',1);
  line([xl(2) xl(2)],[yl(2) yl(2)],zl,'color','k','LineWidth',1);
  line([xl(1) xl(1)],[f(end) f(end)],get(gca,'zlim'),'LineWidth',1,'Color','k');
  line([0 0],[yl(2) yl(2)],get(gca,'zlim'),'LineWidth',1,'Color','k');
end;

if WALLPLOTS,
  % DRAW AVERAGE LFP/MUA ON THE TIME WALL
  fr = ones(length(mua),1) .* yl(2);
  mx = max([max(lfp(:)) max(mua(:))]);
  plot3(t,fr,zl(2)*lfp/mx,'Color','k');
  fr = ones(length(mua),1) .* yl(2);
  plot3(t,fr,zl(2)*mua/mx,'Color','b');
end;

if RANGEVALS,
  % WRITE THE LIMIT VALUES
  xl1 = xl(1) * 1.2;  zl2 = zl(2) * 1.2;
  NumCol = [.2 .2 1]; NumSize = 8;
  text(xl1,L,zl2,sprintf('%d',L), 'HorizontalAlignment','left', ...
       'FontWeight','bold','FontSize',NumSize,'color',NumCol);
  text(xl1,R,zl2,sprintf('%d',R), 'HorizontalAlignment','left', ...
       'FontWeight','bold','FontSize',NumSize,'color',NumCol);
  text(xl1,ML,zl2,sprintf('%d',ML),'HorizontalAlignment','left', ...
       'FontWeight','bold','FontSize',NumSize,'color',NumCol);
  text(xl1,MR,zl2,sprintf('%d',MR),'HorizontalAlignment','left', ...
       'FontWeight','bold','FontSize',NumSize,'color',NumCol);
end;

if STIMULUS,
  if PLOT3D,
    % no HEMO_DELAY, HEMO_TAIL
    stm=expgetstm(Spc.session,Spc.ExpNo,'boxcar',0,0);
    stm.dat(find(stm.dat)) = zl(2)/2;
    if length(stm.dat) >= length(t),
      stm.dat = stm.dat(1:length(t));
    else
      t = t(1:length(stm.dat));
    end;
    fr = ones(length(mua),1) .* yl(1);
    plot3(t,fr,stm.dat,'LineWidth',4,'Color','r');
  else
    if isfield(Spc,'stm') & ~isempty(Spc.stm),
      stm = Spc.stm.time{1};
      for N=1:length(stm),
        line([stm(N) stm(N)],get(gca,'ylim'),[zl(2) zl(2)],...
             'color','b','linewidth',2,'linestyle','-');
        line([stm(N) stm(N)],get(gca,'ylim'),[zl(2) zl(2)],...
             'color','w','linewidth',2,'linestyle','--');
      end;
    end
  end;
end;

if COLBAR,
  hcb = colorbar;
  axes(hcb);
  set(gca,'FontSize',7);
  ylabel(UNITLABEL,'FontSize',8);
end;


