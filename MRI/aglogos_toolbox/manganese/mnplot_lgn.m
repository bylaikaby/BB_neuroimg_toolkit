function varargout = mnplot_lgn(SESSION,GRPNAME,ALPHA,USE_PCA,PROJOUT)
%MNPLOT_LGN - Plots time course of pLGN and mLGN.
%  MNPLOT_LGN(SESSION,GRPNAME,ALPHA,[USE_PCA=0],PROJOUT) plots time course of
%  'mlgn' and 'plgn'.
%
%
%  VERSION :
%    0.90 15.06.05 YM   pre-release
%    0.91 06.02.12 YM   use mroi_file().
%
%  See also MN_ROITS_GET, MN_ROITS_CAT

if nargin < 2,  help mnplot_lgn; return;  end

if nargin < 3,  ALPHA = 0.05;  end
if nargin < 4,  USE_PCA = [];  end
if nargin < 5,
  PROJOUT = {'muscle'};
end

if isempty(USE_PCA),  USE_PCA = 0;  end


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);


fprintf('%s %s: ALPHA=%.2f, USE_PCA=%d\n',...
        datestr(now,'HH:MM:SS'),mfilename,ALPHA,USE_PCA);
ROI = load(mroi_file(Ses,grp.grproi));
ROI = ROI.(grp.grproi);

% GET TIME COURSES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(' loding roiTs...');
mlgn = mn_roits_cat(mn_roits_get(ROI,grp.name,'mlgn',[],USE_PCA));
plgn = mn_roits_cat(mn_roits_get(ROI,grp.name,'plgn',[],USE_PCA));
if ischar(PROJOUT) & ~isempty(PROJOUT),  PROJOUT = { PROJOUT; };  end
if ~isempty(PROJOUT),
  BASEDAT = zeros(size(plgn.dat,1),length(PROJOUT));
  for N = 1:length(PROJOUT),
    tmpts = mn_roits_cat(mn_roits_get(ROI,grp.name,PROJOUT{N},[],USE_PCA));
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
  mlgn = mn_roits_projout(mlgn,BASEDAT);
  plgn = mn_roits_projout(plgn,BASEDAT);
end


% APPLY T-TEST %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(' t-test...');
mlgn = mn_roits_ttest(mlgn);
plgn = mn_roits_ttest(plgn);


% LOAD ANATOMY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(' loading anatomy...');
anaImg = load(sprintf('%s.mat',grp.ana{1}),grp.ana{1});
anaImg = anaImg.(grp.ana{1}){grp.ana{2}};

fprintf(' plotting data...');
% PLOT DATA
keyboard
hWin = subPlotTimeCourse(Ses,grp,mlgn,plgn,ALPHA,PROJOUT);
figfile = sprintf('%s_%s_%s_timecourse.fig',Ses.name,grp.name,mfilename);
saveas(hWin,figfile);

hWin = subPlotImage(Ses,grp,mlgn,ALPHA,anaImg,PROJOUT);
figfile = sprintf('%s_%s_%s_mlgn.fig',Ses.name,grp.name,mfilename);
saveas(hWin,figfile);

hWin = subPlotImage(Ses,grp,plgn,ALPHA,anaImg,PROJOUT);
figfile = sprintf('%s_%s_%s_plgn.fig',Ses.name,grp.name,mfilename);
saveas(hWin,figfile);


if nargout,
  varargout{1} = mlgn;
  varargout{2} = plgn;
end


return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot time courses
function hWin = subPlotTimeCourse(Ses,grp,mlgn,plgn,ALPHA,PROJOUT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tmptitle = sprintf('%s: %s %s LGN time course',mfilename,Ses.name,grp.name);
hWin = figure('Name',tmptitle);
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName',  'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');

%T = 1:size(mlgn.dat,1);
T = mn_exptime(Ses.name,grp.name);

mlgn.dat = mlgn.dat(:,find(mlgn.ttest.p < ALPHA));
plgn.dat = plgn.dat(:,find(plgn.ttest.p < ALPHA));


% raw plot
subplot(2,1,1);
tmpdat = double(mlgn.dat);
if ~isempty(tmpdat),
  m = mean(tmpdat,2);  s = std(tmpdat,[],2) / sqrt(size(tmpdat,2));
  errorbar(T,m,s,'color','r','linewidth',2);  hold on; grid on;
else
  plot(T,zeros(size(T)),'color','r','linewidth',2);  hold on; grid on;
end
tmpdat = double(plgn.dat);
if ~isempty(tmpdat),
  m = mean(tmpdat,2);  s = std(tmpdat,[],2) / sqrt(size(tmpdat,2));
  errorbar(T,m,s,'color','g','linewidth',2);  hold on; grid on;
else
  plot(T,zeros(size(T)),'color','g','linewidth',2);  hold on; grid on;
end
xlabel('Time in Hours');
ylabel('Voxel Value');
set(gca,'xlim',[0 max(T)]);
legend(sprintf('mLGN N=%d',size(mlgn.dat,2)), sprintf('pLGN N=%d',size(plgn.dat,2)));
inftxt = sprintf('%s %s: mean+-sem, ALPHA=%.2f',Ses.name,grp.name,ALPHA);
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
subplot(2,1,2);
tmpdat = double(mlgn.dat);
if ~isempty(tmpdat),
  for N = 1:size(tmpdat,2),
    tmpdat(:,N) = tmpdat(:,N) / tmpdat(1,N);
  end
  m = mean(tmpdat,2);  s = std(tmpdat,[],2) / sqrt(size(tmpdat,2));
  errorbar(T,m,s,'color','r','linewidth',2);  hold on; grid on;
else
  plot(T,ones(size(T)),'color','r','linewidth',2);  hold on; grid on;
end
tmpdat = double(plgn.dat);
if ~isempty(tmpdat),
  for N = 1:size(tmpdat,2),
    tmpdat(:,N) = tmpdat(:,N) / tmpdat(1,N);
  end
  m = mean(tmpdat,2);  s = std(tmpdat,[],2) / sqrt(size(tmpdat,2));
  errorbar(T,m,s,'color','g','linewidth',2);  hold on; grid on;
else
  plot(T,ones(size(T)),'color','g','linewidth',2);  hold on; grid on;
end
xlabel('Time in Hours');
ylabel('Normalized Voxel Value (T0=1)');
set(gca,'xlim',[0 max(T)]);
legend(sprintf('mLGN N=%d',size(mlgn.dat,2)), sprintf('pLGN N=%d',size(plgn.dat,2)));
text(0.02,0.07,inftxt,'units','normalized','fontname','Comic Sans MS');
title('Normalized Voxel Time Course');


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot time courses
function hWin = subPlotImages(Ses,grp,lgn, ALPHA,anaImg, PROJOUT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tmptitle = sprintf('%s: %s %s t-test map %s',mfilename,Ses.name,grp.name,lgn.name);
hWin = figure('Name',tmptitle);
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName',  'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');


return;