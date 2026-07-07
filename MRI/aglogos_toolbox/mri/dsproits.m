function hd = dsproits(roiTs,varargin)
%DSPROITS - Display r-value selected time series in the structure roiTs
% DSPROITS(roiTs, varargin) is used to display the time series of the voxels
% within selected ROIs by means of the MROI program.
%
% VALIDARGS = {'RoiName';'rThr';'Mode';'Err';'FigFlag';'TrialNo'};
%
% Default arguments for function DSPROITS
% -----------------------------------------------------
% DEF.RoiName         = 'brain';                  % V1 is the default ROI to display
% DEF.rThr            = anap.rval;                % Corr coeff
% DEF.Mode            = 0;                        % Mode=0, mean; Mode=1, surface plot
% DEF.Err             = 0;                        % errorbar or plot
% DEF.FigFlag         = 0;                        % If set, make new figure
% DEF.TrialNo         = grp.refgrp.reftrial;      % If nonzero select trial
%
% See also MGETROITSINFO MROITSGET MROITSSEL MROITSMASK
%
% NKL, 11.04.04
% NKL, 29.12.05
% NKL, 13.06.07

if nargin < 1, help dsproits;  return; end;

CIVAL       = [0.01 0.99];
BSTRP       = 200;     % Itterations for Bootstraping
DRAW_ROI    = [];
COL_LINE    = 'k';
YLIM        = [];
LINEWIDTH   = 1;
LINESTYLE   = '-';
DRAWSTM     = 0;
STDERROR    = 1;


for N=1:2:length(varargin),
  switch lower(varargin{N}),
   case {'stderror'}
    STDERROR = varargin{N+1};
   case {'ylim'}
    YLIM = varargin{N+1};
   case {'drawstm', 'drawstmlines'}
    DRAWSTM = varargin{N+1};
   case {'linewidth'}
    LINEWIDTH = varargin{N+1};
   case {'linestyle'}
    LINESTYLE = varargin{N+1};
   case {'cival'}
    CIVAL = varargin{N+1};
   case {'bstrp'}
    BSTRP = varargin{N+1};
   case {'slice'}
    SELSLICE = varargin{N+1};
   case {'drawroi','drawrois','roinames','roidraw'}
    DRAW_ROI = varargin{N+1};
   case {'col','color'},
    COL_LINE = varargin{N+1};
   case {'gamma'}
    GAMMAV = varargin{N+1};
  end
end

if iscell(roiTs),
  for N=1:length(roiTs),
    hd(N) = subPlotTC(roiTs{N},CIVAL,BSTRP,COL_LINE,LINEWIDTH,LINESTYLE,YLIM,STDERROR);
  end;
  if DRAWSTM, subDrawStm(roiTs); end;
else
  hd = subPlotTC(roiTs,CIVAL,BSTRP,COL_LINE,LINEWIDTH,LINESTYLE,YLIM,STDERROR);
  if DRAWSTM, subDrawStm(roiTs); end;
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function hd = subPlotTC(roiTs,CIVAL,BSTRP,COL_LINE,LINEWIDTH,LINESTYLE,YLIM,STDERROR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for N=1:length(roiTs),
  t = [1:size(roiTs.dat,1)]*roiTs.dx;
  y = nanmean(roiTs.dat,2);

  if BSTRP,
    if ~isnan(y) & ~all(y==0),
      switch COL_LINE,
       case 'r',
        COL_FACE = [1 .7 .7];
       case 'b',
        COL_FACE = [.7 .7 1];
       case 'c',
        COL_FACE = [.7 .8 .8];
       case 'm',
        COL_FACE = [.9 .8 .9];
       case 'g',
        COL_FACE = [.7 1 .7];
       case 'y',
        COL_FACE = [.8 .8 .2];
       case 'x',
        COL_LINE = [.4 0 0];
        COL_FACE = [1 .6 .6];
       case 'k',
        COL_FACE = [.95 .85 .75];
       otherwise,
        COL_FACE = [.7 .7 .7];
      end;
      if ~STDERROR,
        Boot = bootstrp(BSTRP,@nanmean,roiTs.dat');
        Cinter = prctile(Boot,CIVAL); % the 1 and 99% intervals
      else
        m = nanmean(roiTs.dat,2);
        s = std(roiTs.dat,1,2)/sqrt(size(roiTs.dat,2));
        Cinter(1,:) = m-s;
        Cinter(2,:) = m+s;
      end;
      ciplot(Cinter(1,:),Cinter(2,:),t,COL_FACE);
    end;
  end;
  
  hold on
  hd = plot(t, y,'color',COL_LINE,'linewidth',LINEWIDTH,'linestyle',LINESTYLE);
  set(gca,'xlim',[t(1) t(end)]);
  if 0,
    YTICK = get(gca,'ytick');
    for N=1:length(YTICK),
      YTICKLABEL{N} = sprintf('%2.1f', YTICK(N));
    end;
    set(gca,'yticklabel',YTICKLABEL);
  end;
  hold off;
  set(gca,'layer','top');
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subDrawStm(sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
stm = sig.stm.time{1};
if isfield(sig.stm,'stmtypes'),
  stimuli = sig.stm.stmtypes(sig.stm.v{1}+1);
  if any(strcmpi(stimuli,'blank')),
    idxon = find(~strcmpi(stimuli,'blank'));
    idxoff = idxon + 1;
    stm(end+1) = max([stm(end) sum(sig.stm.dt{1})]);
    stm = unique(stm([idxon(:)' idxoff(:)']));
  else
    stm = zeros(1,2*length(sig.stm.time{1}));
    stm(1:2:end) = sig.stm.time{1};
    stm(2:2:end) = sig.stm.time{1} + sig.stm.dt{1};
  end
end
tmp = get(gca,'ylim'); tmpy = tmp(1);
tmph = tmp(2)-tmp(1);
hd = [];

for N=1:2:length(stm),
  tmpx = stm(N);
  tmpw = stm(N+1)-stm(N);
  hd(end+1) = rectangle('Position',[tmpx tmpy tmpw tmph],...
                        'facecolor',[.85 .85 .85],'linestyle',':','Tag','ScaleBar');
end
setback(hd);
set(gca,'layer','top');
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% OLD CODE - KEEP/MODIFY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NATURE_DEMO = 0;                % It was only used to re-plot with the correct format some
VALIDARGS = {'RoiName';'rThr';'Mode';'Err';'FigFlag';'TrialNo'};

[SesName, ExpNo] = mgetroitsinfo(roiTs);
Ses  = goto(SesName);
anap = getanap(Ses, ExpNo);
grp  = getgrp(Ses, ExpNo);

% Default arguments for function DSPROITS
%
if length(Ses.roi.names) == 1,
  DEF.RoiName       = Ses.roi.names{1};
else
  DEF.RoiName       = 'V1';                     % V1 is the default ROI to display
end
DEF.rThr            = anap.rval;                % Corr coeff
DEF.Mode            = 0;                        % Mode=0, mean; Mode=1, surface plot
DEF.Err             = 0;                        % errorbar or plot
DEF.FigFlag         = 0;                        % If set, make new figure
DEF.TrialNo         = grp.refgrp.reftrial;   % If nonzero select trial
out = parseinput(VALIDARGS,varargin);

if ~isempty(out),
    out = sctcat(out,DEF);
else
    out = DEF;
end;
pareval(out);

COL = 'rbymgck';
INCR = 1;
% Select TS from ROI with name "RoiName" and from all the slices
roiTs = mroitsget(roiTs,[],RoiName);            % Get desired ROI

if FigFlag,
    mfigure([100 400 800 700]);
end;
if length(roiTs{1}.ExpNo) > 1,
    txt = sprintf('DSPROITS: Session: %s, Group: %s\n',roiTs{1}.session, roiTs{1}.grpname);
else
    txt = sprintf('DSPROITS: Session: %s, ExpNo: %d\n',roiTs{1}.session, roiTs{1}.ExpNo(1));
end
figtitle(txt,'color','w');

set(gcf,'color','k');

if ~Mode,
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DISPLAY MAP AND AVERAGE TS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    subplot('position',[0.002 0.2 0.4 0.65]);
    if isfield(roiTs{1},'r'),
        matsmap(roiTs,rThr,'r',COL);
    else
    end;
    
    set(gca,'xcolor','w','ycolor','w');

%    subplot('position',[0.5 0.15 0.45 0.75]);

    KK=1;
    for N=1:length(roiTs)
        data = roiTs{N}.dat;
        name = roiTs{N}.name;
        if ~iscell(data),
            data = {data};
        end;
        t = [0:size(data{1},1)-1] * roiTs{N}.dx;
        t = t(:);
        if isempty(t),
            fprintf('DSPROITS: no data in roiTs\n');
            keyboard;
        end;

        for M=1:length(data),

            % Here we call Sig = avgerr(Sig); which ...
            y = data{M};
            if isempty(y), y = zeros(size(t,1),1); end;

            yerr = nanstd(y,1,2)/sqrt(size(y,2));
            y = nanmean(y,2);

            if Err,
                %if str2num(version('-release')) >= 14,
                if datenum(version('-date')) >= datenum('August 02, 2005'),
                    % for Matlab 7
                    hd(KK) = errorbar(t(1:INCR:end),y(1:INCR:end),yerr(1:INCR:end));
                    eb = findall(hd(KK));
                    set(eb(1),'LineWidth',1,'Color',COL(mod(M,length(COL))));
                    set(eb(2),'LineWidth',2,'Color',COL(mod(M,length(COL))));
                else
                    % for Matlab 6.5.1
                    tmphd = errorbar(t(1:INCR:end),y(1:INCR:end),yerr(1:INCR:end));
                    set(tmphd(1),'LineWidth',1,'Color',COL(mod(M,length(COL))));
                    set(tmphd(2),'LineWidth',2,'Color',COL(mod(M,length(COL))));
                    hd(KK) = tmphd(1);
                end
            else
                LW = 0.5; if M==1, LW=2; end;
                LS = ':'; if M==1, LS='-'; end;
                hd(M)=plot(t(1:INCR:end),y(1:INCR:end),'color',COL(mod(M,length(COL))),...
                    'linewidth',LW,'linestyle',LS,'marker','s','markerfacecolor','k');
            end;
            hold on;
            RoiNames{KK} = sprintf('%s: Mod=%d', name, M);
            KK=KK+1;
        end;
        set(gca,'xlim',[t(1) t(end)]);
    end;

    if isstim(SesName, grp.name),
        drawstmlines(roiTs{1},'linewidth',3,'color',[0 0.5 0],'linestyle',':');
    end;

    set(gca,'xcolor','w','ycolor','w','color',[.7 .7 .7]);
    if exist('hd','var') & ~isempty(hd),
        [h, h1] = legend(hd,RoiNames{:},'Location','northwest');
        set(h,'FontWeight','normal','FontSize',8,'color',[.5 .5 .5]);
        set(h,'xcolor','w','ycolor','w');
        % set(h1(1),'fontsize',8,'fontweight','bold','color','w');
    end
    ylabel('SD Units');
    xlabel('Time in seconds');

else
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DISPLAY MAP AND SURFACE PLOT WITH INDIVIDUAL TIME SERIES
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % XCOR MAP AND INFO
    subplot('position',[0.01 0.53 0.5 0.43]);
    if isfield(roiTs{1},'r'),
        matsmap(roiTs,rThr);
    end;
    subplot('position',[0.6 0.53 0.39 0.4]);
    set(gca,'color','k');
    set(gca,'xtick',[],'ytick',[]);

    if isfield(roiTs{1},'info'),
        ftext = fieldnames(roiTs{1}.info);
        R=100;
        for L=1:length(ftext),
            R = R - 5;
            val = getfield(roiTs{1}.info,ftext{L});
            if isnumeric(val),
                if int16(val)==val,
                    frm = '%+ 20s: %6d';
                else
                    frm = '%+ 20s: %6.2f';
                end;
            elseif iscell(val),
                frm = '%+ 20s: %6s';
                val = val{1};
            else
                frm = '%+ 20s: %6s';
            end;

            txt = sprintf(frm, lower(ftext{L}), val);
            text(10,R,txt,'color','y','fontname','Courier');
        end;
    else
        text(10,50,'No INFO structure in this roiTs','color','b','fontsize',11,'fontweight','bold');
    end;
    set(gca,'xlim',[0 100], 'ylim', [0 100]);
    title('[roiTs.info]: Data-Preprocessing Applied','color','y');

    % SURFACE PLOT WITH TIME COURSES
    subplot('position',[0.07 0.07 0.44 0.43]);
    vox = [1:size(roiTs{1}.dat,2)];
    time = [1:size(roiTs{1}.dat,1)]*roiTs{1}.dx;
    if 0,
        [x,y] = meshgrid(vox,time);
        plot3(x,y,roiTs{1}.dat);
    else
        surf(time,vox,roiTs{1}.dat');
        xlabel('Time in Seconds','FontSize',8);
        ylabel('Voxel Number','FontSize',8);
        view(0,90);
        shading interp;
        set(gca,'color','k','xcolor','w','ycolor','w');
        set(gca,'xlim',[time(1) time(end)],'ylim',[vox(1) vox(end)]);
        LIM=[-1 3];
        set(gca,'clim',LIM,'zlim',LIM);

        if NATURE_DEMO,
            set(gca,'xlim',[6.5 55]);
            set(gca,'xtick',[0:4:55]);
        end;

        savgca = gca;
        colorbar('North');

        ax = axes('position',get(savgca,'position'));
        axes(ax);
        set(ax,'color','none');
        hold on;
        plot(time,mean(roiTs{1}.dat,2),'color','k','linewidth',2);
        plot(time,mean(roiTs{1}.dat,2),'color','w','linewidth',2,'linestyle',':');
        set(gca,'xlim',[time(1) time(end)]);

        if NATURE_DEMO,
            set(gca,'xlim',[6.5 55]);
            set(gca,'xtick',[0:4:55]);
        end;
        drawstmlines(roiTs{1},'linewidth',2,'color','w');
        set(gca,'yticklabel',[]);
        set(gca,'xcolor','w','ycolor','w');
        grid on;
    end;

    % SPECTRUM
    subplot('position',[0.58 0.08 0.41 0.42]);
    mroitsfft(roiTs,RoiName,'color','y','linewidth',1.2);
    set(gca,'color','k','xcolor','w','ycolor','w');
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subPlotMap(anatomy, map, colmap, pos, MAPSCALE)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global slide sesname grpname
OFS = 0.005;            % Between slices
NS = size(anatomy,3);
X=size(anatomy,2);
Y=size(anatomy,1);
HS=0.5;
VS=0.75;
VOFS = (1 - VS)/2;

if NS<=6,
  Hor = 2; Ver=3;
elseif NS > 6 & NS<=9,
  Hor = 3; Ver = 3;
elseif NS > 9 & NS<=12,
  Hor=4; Ver=3;
else
  Hor=4; Ver=4;
end;
MAXW=HS-(Hor+1)*OFS;
MAXH=VS;

w = MAXW/Hor;
h = MAXH/Ver;

for S=1:NS,
  x = 0.02 + mod((S-1),Hor)*(w+OFS);
  y = (MAXH-VOFS) - ((floor((S-1)/Hor)) * (h+OFS));
  
  subplot('position',[x, y, w, h]);
  subPlotMapSlice(anatomy,map,S,colmap,MAPSCALE);
  text(x+5,y+10,sprintf('%d',S),'color','r','FontSize',12,...
       'FontWeight','bold','HorizontalAlignment','left');
  if S==1,
    txt = sprintf('showmap(%s,%s); -- Slide = %d', sesname,grpname,slide);
    if slide,  COL='y'; else COL = 'k'; end;
    title(txt,'color',COL,'FontWeight','normal','FontSize',10,'HorizontalAlignment','left');
  end;
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subPlotMapSlice(anatomy, map, slice,colmap, MAPSCALE)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global slide
ai = anatomy(:,:,slice);
ai = round(255 * ai/max(ai(:))) + 1;  % 1 to 256
fi = ai;

cmap = gray(256);
tmpc = repmat([0.5:0.5/255:1.0],[3 1])';  % 0.5-1.0/256 steps

% ADDS colors for common pixels
airgb = ind2rgb(ai',gray(256));
firgb = zeros(size(airgb));
%firgb = airgb;
mapped = zeros(size(airgb));
for N = 1:length(map),
  tmpmap = map{N}(:,:,slice)';
  tmpmap = (tmpmap - MAPSCALE{N}(1)) / (MAPSCALE{N}(2) - MAPSCALE{N}(1));  % 0 to 1
  tmpmap(find(tmpmap(:) > 1)) = 1;
  tmpmap(find(tmpmap(:) < 0)) = 0;
  tmpmap = round(tmpmap * 255) + 1;   % 1 to 256
  tmpidx = find(~isnan(repmat(tmpmap(:),[1 1 3])));  % for rgb
  tmpcmap = tmpc.*repmat(colmap(N,:),[256 1]);
  tmprgb = ind2rgb(tmpmap,tmpcmap);
  firgb(tmpidx) = firgb(tmpidx) + tmprgb(tmpidx);
  mapped(tmpidx) = 1;
end
tmpidx = find(mapped(:) == 0);
firgb(tmpidx) = airgb(tmpidx);
subimage(firgb);
axis fill;
axis tight;
axis off;
if slide,
  set(gca,'color','k');
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to scale anatomy image
function ANARGB = subScaleAnatomy(ANA,MINV,MAXV,GAMMA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global slide
if isstruct(ANA),
  tmpana = double(ANA.dat);
else
  tmpana = double(ANA);
end
clear ANA;
tmpana = (tmpana - MINV) / (MAXV - MINV);
tmpana = round(tmpana*255) + 1; % +1 for matlab indexing
tmpana(find(tmpana(:) <   0)) =   1;
tmpana(find(tmpana(:) > 256)) = 256;
anacmap = gray(256).^(1/GAMMA);
for N = size(tmpana,3):-1:1,
  ANARGB(:,:,:,N) = ind2rgb(tmpana(:,:,N),anacmap);
end
ANARGB = permute(ANARGB,[1 2 4 3]);  % [x,y,rgb,z] --> [x,y,z,rgb]
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to get scale values for maps
function MAPSCALE = subGetMapScale(MAPS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for N = 1:length(MAPS),
  minv = min(MAPS{N}(:));
  maxv = max(MAPS{N}(:));
  if minv == maxv,  minv = maxv*0.1;  end
  MAPSCALE{N} = [minv maxv];
end
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot color bars
function subPlotColorBar(colmap,MAPSCALE,stat)
global slide

w = 0.02;  h = 0.1;
tmpc = repmat([0.5:0.5/255:1.0],[3 1])';  % 0.5-1.0/256 steps
for N = 1:length(MAPSCALE),
  tmpx = 0.53 + 0.07*(N-1);
  tmpy = 0.85;
  axes('position',[tmpx tmpy w h]);
  tmpcmap = tmpc.*repmat(colmap(N,:),[256 1]);
  tmprgb = ind2rgb([1:256]',tmpcmap);
  tmpscale = [0:255]/255;  % 0 to 1
  tmpscale = tmpscale * (MAPSCALE{N}(2) - MAPSCALE{N}(1)) - MAPSCALE{N}(1);  % min to max
  image(1,tmpscale,tmprgb);
  if slide,
    set(gca,'FontWeight','normal','FontSize',8,'color',[.9 .9 .9]);
    set(gca,'xcolor',[.8 .8 .8],'ycolor',[.8 .8 .8]);
  else
    set(gca,'FontWeight','normal','FontSize',8,'color',[0 0 0]);
  end;
  
  set(gca,'ydir','normal');
  set(gca,'xtick',[],'xticklabel',[],'YAxisLocation','right');
  ylabel(upper(stat.model{N}));
  grid on;
end



