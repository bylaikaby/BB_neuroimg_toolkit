function dspmulreg(roiTs,thr)
%DSPMULREG - Demo file (to be deleted soon....)
% NKL 01.11.05

COL = 'rgbcmywk';
INCR = 2;
Err=1;
Mode=0;
thr = 0;

%%% FIX THIS!!!!!!!!!!!!!
Ses = goto(roiTs{1}.session);
grps = getgroups(Ses);
roinames = grps{1}.modelname;

mfigure([10 50 1500 1100]);
txt = sprintf('DSPROITS: Session: %s, Group: %s\n', roiTs{1}.session, roiTs{1}.grpname);
suptitle(txt,'r',11);
set(gcf,'color','k');

if Mode,
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % DISPLAY MAP AND SURFACE PLOT WITH INDIVIDUAL TIME SERIES
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % XCOR MAP AND INFO
  subplot('position',[0.01 0.53 05 0.43]);
  if isfield(roiTs{1},'r'),
    matsmap(roiTs,thr);
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
    set(ax,'color','none','box','on');
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
  mroitsfft(roiTs,roiname,'color','y','linewidth',1.2);
  set(gca,'color','k','xcolor','w','ycolor','w');
  
else
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % DISPLAY MAP AND AVERAGE TS
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  subplot('position',[0.002 0.2 0.52 0.65]);
  if isfield(roiTs{1},'r'),
    matsmap(roiTs,thr);
  end;
  set(gca,'xcolor','w','ycolor','w');
  
  subplot('position',[0.58 0.65 0.38 0.30]);
  dspmodel(roiTs);
  set(gca,'xcolor','w','ycolor','w','color',[.7 .7 .7]);

  %  subplot('position',[0.58 0.2 0.38 0.65]);
  subplot('position',[0.58 0.08 0.38 0.52]);
  for N=1:length(roiTs)
    data = roiTs{N}.dat;
    if ~iscell(data),
      data = {data};
    end;
    
    for NM=1:length(data),
      t = [0:size(data{NM},1)-1] * roiTs{N}.dx;
    
      % Here we call Sig = avgerr(Sig); which ...
      
      y = data{NM};
      if ~isempty(y),
        yerr = hnanstd(y,2)/sqrt(size(y,2));
        y = hnanmean(y,2);

        if Err,
          %if str2num(version('-release')) >= 14,
          if datenum(version('-date')) >= datenum('August 02, 2005'),
            % for Matlab 7
            hd(NM) = errorbar(t(1:INCR:end),y(1:INCR:end),yerr(1:INCR:end));
            eb = findall(hd(NM));
            set(eb(1),'LineWidth',1,'Color',COL(NM));
            set(eb(2),'LineWidth',2,'Color',COL(NM));
          else
            % for Matlab 6.5.1
            tmphd = errorbar(t(1:INCR:end),y(1:INCR:end),yerr(1:INCR:end));
            set(tmphd(1),'LineWidth',1,'Color',COL(NM));
            set(tmphd(2),'LineWidth',2,'Color',COL(NM));
            hd(NM) = tmphd(1);
          end
        else
          plot(t(1:INCR:end),y(1:INCR:end));
        end;
        hold on;
      end;
      set(gca,'xlim',[t(1) t(end)]);
    end;
  end;
  
  drawstmlines(roiTs{1},'linewidth',2,'color','b','linestyle',':');
  set(gca,'xcolor','w','ycolor','w','color',[.7 .7 .7]);
  nidx = find(hd);
  hd = hd(nidx);
  roinames = roinames(nidx);
  if exist('hd','var') & ~isempty(hd),
    [h, h1] = legend(hd,roinames{:},3);
    set(h,'FontWeight','normal','FontSize',8,'color',[.5 .5 .5]);
    set(h,'xcolor','w','ycolor','w');
    set(h1(1),'fontsize',8,'fontweight','bold','color','w');
  end
  ylabel('SD Units');
  xlabel('Time in seconds');
  grid on;
end;
return;
