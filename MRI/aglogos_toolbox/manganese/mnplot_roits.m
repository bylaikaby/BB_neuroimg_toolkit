function varargout = mnplot_roits(SESSION,GRPNAME,ROINAME,ALPHA,NORM,PROJOUT,USE_PCA)
%MNPLOT_ROITS - Plots time course of given ROI.
%  MNPLOT_ROITS(SESSION,GRPNAME,ROINAME,ALPHA,NORM,PROJOUT,[USE_PCA=0]) plots time course of 
%  ROINAME
%
%
%  VERSION :
%    0.90 16.06.05 YM   pre-release
%    0.91 06.02.12 YM   use mroi_file().
%
%  See also MN_ROITS_GET, MN_ROITS_CAT

if nargin < 3,  help mnplot_roits; return;  end

if nargin < 4,  ALPHA = 0.05;  end
if nargin < 5,  NORM = {}; end
if nargin < 6,
  %PROJOUT = {'muscle'};
  PROJOUT = {};
end
if nargin < 7,  USE_PCA = [];  end

if isempty(USE_PCA),  USE_PCA = 0;  end
if ischar(ROINAME),  ROINAME = { ROINAME };  end
if ischar(NORM) & ~isempty(NORM),  NORM = { NORM };  end


% CONTROL FLAGS, SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);


fprintf('%s %s: ALPHA=%.2f, USE_PCA=%d\n',...
        datestr(now,'HH:MM:SS'),mfilename,ALPHA,USE_PCA);
ROI = load(mroi_file(Ses,grp.grproi));
ROI = ROI.(grp.grproi);


% GET A TIME COURSE FOR NORMALIZATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(NORM) & ~isempty(NORM),  NORM = { NORM; };  end
if ~isempty(NORM),
  NORM = mn_roits_cat(mn_roits_get(ROI,grp,NORM,[],USE_PCA));
  if isempty(strfind(NORM.name,'regress')),
    NORM.dat = mean(NORM.dat,2);
  end
else
  NORM = {};
end



% GET TIME COURSES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(' loding roiTs...');
roiTs = {};
for N = 1:length(ROINAME),
  tmpts = mn_roits_cat(mn_roits_get(ROI,grp.name,ROINAME{N},[],USE_PCA));
  if ~isempty(tmpts),
    tmpts.dat = double(tmpts.dat);
    if ~isempty(NORM),
      tmpts = mnnormalize(tmpts,NORM);
      %for K = 1:size(tmpts.dat,2),
      %  tmpts.dat(:,K) = tmpts.dat(:,K) ./ NORM.dat;
      %end
    end
    roiTs{end+1} = tmpts;
  end
end
if ischar(PROJOUT) & ~isempty(PROJOUT),  PROJOUT = { PROJOUT; };  end
if ~isempty(PROJOUT),
  BASEDAT = zeros(size(roiTs{1}.dat,1),length(PROJOUT));
  for N = 1:length(PROJOUT),
    tmpts = mn_roits_cat(mn_roits_get(ROI,grp.name,PROJOUT{N},[],USE_PCA));
    tmpts.dat = double(tmpts.dat);
    if ~isempty(NORM),
      tmpts = mnnormalize(tmpts,NORM);
      %for K = 1:size(tmpts.dat,2),
      %  tmpts.dat(:,K) = tmpts.dat(:,K) ./ NORM.dat;
      %end
    end
    %idx = find(tmpts.coords(:,3) > 40);
    %tmpts.dat = tmpts.dat(:,idx);
    BASEDAT(:,N) = mean(tmpts.dat,2);
  end
else
  BASEDAT = [];
end


% PROJECT-OUT
if ~isempty(BASEDAT),
  fprintf(' proj-out(%s',PROJOUT{1});
  for N=2:length(PROJOUT), fprintf('-%s',PROJOUT{N});  end
  fprintf(')...');
  roiTs = mn_roits_projout(roiTs,BASEDAT);
end




% APPLY T-TEST %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ALPHA >= 1,
  for N = 1:length(roiTs),
    roiTs{N}.ttest.p = zeros(size(roiTs{N}.dat,2),1);
  end
else
  %if ~isfield(roiTs{1}.ttest) | isempty(roiTs{1}.ttest.p),
    fprintf(' t-test...');
    roiTs = mn_roits_ttest(roiTs);
  %end
end



fprintf(' plotting data...');
% PLOT DATA
hWin = subPlotTimeCourse(Ses,grp,roiTs,ALPHA,PROJOUT,NORM);
fprintf(' done.\n');

if nargout,
  varargout{1} = roiTs;
  if nargout > 1,
    varargout{2} = hWin;
  end
end


return;


% LOAD ANATOMY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(' loading anatomy...');
anaImg = anaload(Ses,grp);

keyboard
figfile = sprintf('%s_%s_%s_timecourse.fig',Ses.name,grp.name,mfilename);
saveas(hWin,figfile);

%for N = 1:length(roiTs),
%  hWin = subPlotImage(Ses,grp,roiTs,ALPHA,anaImg,PROJOUT);
%  figfile = sprintf('%s_%s_%s_%s.fig',Ses.name,grp.name,mfilename,roiTs{N}.name);
%  saveas(hWin,figfile);
%end


if nargout,
  varargout{1} = roiTs;
end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot time courses
function hWin = subPlotTimeCourse(Ses,grp,roiTs,ALPHA,PROJOUT,NORM)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tmptitle = sprintf('%s: %s %s ROI time course',mfilename,Ses.name,grp.name);
hWin = figure('Name',tmptitle);
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName',  'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');
set(gcf,'PaperOrientation',     'landscape');

%T = 1:size(roiTs{1}.dat,1);
T = mn_exptime(Ses.name,grp.name);

COL = colormap(jet(length(roiTs)));

IGNORE_TTEST = {'eye','ceye','ieye','sag-sinus','hor-sinus','muscle','chamber','pituitary'};


inftxt = sprintf('%s %s: mean+-sem, ALPHA=%g',Ses.name,grp.name,ALPHA);
if ~isempty(PROJOUT),
  inftxt = sprintf('%s, proj-out(%s',inftxt,PROJOUT{1});
  for N =2:length(PROJOUT),
    inftxt = sprintf('%s+%s',inftxt,PROJOUT{N});
  end
  inftxt = sprintf('%s)',inftxt);
end
if ~isempty(NORM),
  inftxt = sprintf('%s, norm(%s)',inftxt,NORM.name);
end


% process data
legtxt = {};
MDAT = zeros(length(T),length(roiTs));
SDAT = zeros(length(T),length(roiTs));
for N = 1:length(roiTs),
  if any(strcmpi(IGNORE_TTEST,roiTs{N}.name)),
    % eye should not be selected by T-test
    tmpdat = roiTs{N}.dat;
  else
    tmpdat = roiTs{N}.dat(:,find(roiTs{N}.ttest.p < ALPHA));
  end
  % remove points t(1) = 0;
  tmpdat = tmpdat(:,find(tmpdat(1,:) > 0));
  tmpdat = double(tmpdat);
  if ~isempty(tmpdat),
    MDAT(:,N) = mean(tmpdat,2);
    SDAT(:,N) = std(tmpdat,[],2) / sqrt(size(tmpdat,2));
  end
  legtxt{N} = sprintf('%s N=%d/%d',roiTs{N}.name,size(tmpdat,2),size(roiTs{N}.dat,2));
end


% plot data
subplot(1,2,1);
for N = 1:length(roiTs),
  m = MDAT(:,N);  s = SDAT(:,N);
  errorbar(T,m,s,'color',COL(N,:),'linewidth',2);  hold on; grid on;
  %plot(T,m,'color',COL(N,:),'linewidth',2);  hold on; grid on;
end
xlabel('Time in Hours');
if ~isempty(NORM),
  ylabel(sprintf('Voxel Value (%s=1)',NORM.name));
else
  ylabel('Voxel Value');
end
set(gca,'xlim',[0 max(T)]);
legend(legtxt);
text(0.02,0.07,inftxt,'units','normalized','fontname','Comic Sans MS');
title('Voxel Time Course')


% normalized plot
subplot(1,2,2);
subplot(1,1,1);
if 1,
  % NORMALZATION T0=0, MAX=1
  for N = 1:length(roiTs),
    m = MDAT(:,N);  s = SDAT(:,N);
    minv = m(1);
    maxv = max(m);
    if maxv - minv > 1.0e-15,
      m = (m - minv) / (maxv - minv);  s = s / (maxv - minv);
    else
      minv = min(m);
      if maxv ~= minv,
        m = (m - m(1)) / (maxv - minv);  s = s / (maxv - minv);
      else
        m = zeros(size(T));  s = zeros(size(T));
      end
    end
    errorbar(T,m,s,'color',COL(N,:),'linewidth',2);  hold on; grid on;
    %plot(T,m,'color',COL(N,:),'linewidth',2);  hold on; grid on;
  end
  ylabel('Normalized Voxel Value (T0=0,MAX=1)');
  set(gca,'ylim',[-0.2 1.2]);
else
  % NORMALIZATION T0=1
  for N = 1:length(roiTs),
    m = MDAT(:,N);  s = SDAT(:,N);
    m = m / m(1);  s = s/m(1);
    errorbar(T,m,s,'color',COL(N,:),'linewidth',2);  hold on; grid on;
    %plot(T,m,'color',COL(N,:),'linewidth',2);  hold on; grid on;
  end
  ylabel('Normalized Voxel Value (T0=1)');
  set(gca,'ylim',[0.8 2.4]);
end
xlabel('Time in Hours');
set(gca,'xlim',[0 max(T)]);
legend(legtxt);
text(0.02,0.07,inftxt,'units','normalized','fontname','Comic Sans MS');
title('Normalized Voxel Time Course')


return;





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot time courses
function hWin = subPlotTimeCourseOLD(Ses,grp,roiTs,ALPHA,PROJOUT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tmptitle = sprintf('%s: %s %s ROI time course',mfilename,Ses.name,grp.name);
hWin = figure('Name',tmptitle);
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName',  'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');

%T = 1:size(roiTs{1}.dat,1);
T = mn_exptime(Ses.name,grp.name);

COL = colormap(jet(length(roiTs)));

IGNORE_TTEST = {'eye','ceye','ieye','sag-sinus','hor-sinus','muscle','chamber','pituitary'};

legtxt = {};
% raw plot
subplot(3,1,1);
for N = 1:length(roiTs),
  if any(strcmpi(IGNORE_TTEST,roiTs{N}.name)),
    % eye should not be selected by T-test
    tmpdat = roiTs{N}.dat;
  else
    tmpdat = roiTs{N}.dat(:,find(roiTs{N}.ttest.p < ALPHA));
  end
  % remove points t(1) = 0;
  tmpdat = tmpdat(:,find(tmpdat(1,:) > 0));
  tmpdat = double(tmpdat);
  if ~isempty(tmpdat),
    m = mean(tmpdat,2);  s = std(tmpdat,[],2) / sqrt(size(tmpdat,2));
    errorbar(T,m,s,'color',COL(N,:),'linewidth',2);  hold on; grid on;
  else
    plot(T,zeros(size(T)),'color',COL(N,:),'linewidth',2);  hold on; grid on;
  end
  legtxt{N} = sprintf('%s N=%d/%d',roiTs{N}.name,size(tmpdat,2),size(roiTs{N}.dat,2));
end
xlabel('Time in Hours');
ylabel('Voxel Value');
set(gca,'xlim',[0 max(T)]);
legend(legtxt);
inftxt = sprintf('%s %s: mean+-sem, ALPHA=%g',Ses.name,grp.name,ALPHA);
if ~isempty(PROJOUT),
  inftxt = sprintf('%s, proj-out(%s',inftxt,PROJOUT{1});
  for N =2:length(PROJOUT),
    inftxt = sprintf('%s+%s',inftxt,PROJOUT{N});
  end
  inftxt = sprintf('%s)',inftxt);
end
text(0.02,0.07,inftxt,'units','normalized','fontname','Comic Sans MS');
title('Voxel Time Course');

% normalized plot
for iPlot = 2:3,
  subplot(3,1,iPlot);
  for N = 1:length(roiTs),
    if any(strcmpi(IGNORE_TTEST,roiTs{N}.name)),
      % eye should not be selected by T-test
      tmpdat = roiTs{N}.dat;
    else
      tmpdat = roiTs{N}.dat(:,find(roiTs{N}.ttest.p < ALPHA));
    end
    % remove points t(1) = 0;
    tmpdat = tmpdat(:,find(tmpdat(1,:) > 0));
    tmpdat = double(tmpdat);
    if ~isempty(tmpdat),
      for K = 1:size(tmpdat,2),
        tmpdat(:,K) = tmpdat(:,K) / tmpdat(1,K);
      end
      m = mean(tmpdat,2);  s = std(tmpdat,[],2) / sqrt(size(tmpdat,2));
      errorbar(T,m,s,'color',COL(N,:),'linewidth',2);  hold on; grid on;
    else
      plot(T,zeros(size(T)),'color',COL(N,:),'linewidth',2);  hold on; grid on;
    end
    legtxt{N} = sprintf('%s N=%d/%d',roiTs{N}.name,size(tmpdat,2),size(roiTs{N}.dat,2));
  end
  xlabel('Time in Hours');
  ylabel('Normalized Voxel Value (T0=1)');
  set(gca,'xlim',[0 max(T)]);
  legend(legtxt);
  text(0.02,0.07,inftxt,'units','normalized','fontname','Comic Sans MS');
  title('Normalized Voxel Time Course');
end

subplot(3,1,3);
set(gca,'ylim',[0.8 1.4]);


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot time courses
function hWin = subPlotImages(Ses,grp,roiTs, ALPHA,anaImg, PROJOUT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tmptitle = sprintf('%s: %s %s t-test map %s',mfilename,Ses.name,grp.name,roiTs.name);
hWin = figure('Name',tmptitle);
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName',  'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');


return;
