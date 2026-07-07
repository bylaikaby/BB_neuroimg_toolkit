function dsproitsdep(roiTs,roiname,thr,Err)
%DSPROITSDEP - Display all time series roiTs based on roiTs{}.comidx
% DSPROITSDEP(Roi) is used to display the time series of the voxels
% within selected ROIs by means of the MROI program. roiTs must
% have .comidx field for .dat selection
%
% YM/AB/AG, 27.08.04

if nargin < 4,
  Err = 1;
end;
    


if nargin < 3,
  thr = 0.15;        % Default threshold for corr coeff.
  %fprintf('DSPROITSDEP: No r-threshold was defined; Using %0.2f\n',thr);
end;

if nargin < 2,
  roiname = 'ele';
end;

if nargin < 1,
  help dsproits;
  return;
end;
COL = 'krgbcmy';

INCR = 2;

if isstruct(roiTs),  

  roiTs = {roiTs};
end;


for N = 1:length(roiTs),
  comidx = roiTs{N}.comidx;

  roiTs{N}.dat = roiTs{N}.dat(:,find(comidx),:);
  roiTs{N}.coords = roiTs{N}.coords(find(comidx),:);
  roiTs{N}.r{1} = roiTs{N}.r{1}(find(comidx),:);
  % average data
  roiTs{N}.dat  = mean(roiTs{N}.dat,3);
  roiTs{N}.r{1} = mean(roiTs{N}.r{1},2);
end


mfigure([10 100 500 800]);
set(gcf,'color','k');
txt = sprintf('DSPROITS: Session: %s, ExpNo: %d\n', ...
              roiTs{1}.session, roiTs{1}.ExpNo(1));
suptitle(txt,'r',11);
subplot(2,1,1);
if isfield(roiTs{1},'r'),
  %matsmap(roiTs,thr);
  matsmap(roiTs,0);
end;
set(gca,'xcolor','w','ycolor','w');

subplot(2,1,2);
KK=1;
for N=1:length(roiTs)
  t = [0:size(roiTs{N}.dat,1)-1] * roiTs{N}.dx;

  % Here we call Sig = avgerr(Sig); which ...
  
  y = roiTs{N}.dat;
  if ~isempty(y),
    yerr = hnanstd(y,2)/sqrt(size(y,2));
    y = hnanmean(y,2);
    
    % 29.07.04 YM: supports Matlab 6 yet.
    if Err,
      %if str2num(version('-release')) >= 14,
      if datenum(version('-date')) >= datenum('August 02, 2005'),
        % for Matlab 7
        hd(KK) = errorbar(t(1:INCR:end),y(1:INCR:end),yerr(1:INCR:end));
        eb = findall(hd(KK));
        set(eb(1),'LineWidth',1,'Color',COL(mod(N,length(COL))+1));
        set(eb(2),'LineWidth',2,'Color',COL(mod(N,length(COL))+1));
      else
        % for Matlab 6.5.1
        tmphd = errorbar(t(1:INCR:end),y(1:INCR:end),yerr(1:INCR:end));
        set(tmphd(1),'LineWidth',1,'Color',COL(mod(N,length(COL))+1));
        set(tmphd(2),'LineWidth',2,'Color',COL(mod(N,length(COL))+1));
        hd(KK) = tmphd(1);
      end
    else
      plot(t(1:INCR:end),y(1:INCR:end));
    end;
    hold on;
    roinames{KK} = roiTs{N}.name;
    KK=KK+1;
  end;
  set(gca,'xlim',[t(1) t(end)]);
end;

drawstmlines(roiTs{1},'linewidth',2,'color','b','linestyle',':');
set(gca,'xcolor','w','ycolor','w','color',[.7 .7 .7]);
[h, h1] = legend(hd,roinames{:},2);
set(h,'FontWeight','normal','FontSize',8,'color',[.5 .5 .5]);
set(h,'xcolor','w','ycolor','w');
set(h1(1),'fontsize',8,'fontweight','bold','color','w');
xlabel('SD Units');
xlabel('Time in seconds');
grid on;
return;
