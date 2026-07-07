function varargout = mncheck_opn(SESSION,GRPNAME,NORM,PROJOUT)
%MNCHECK_OPN - Checks time course of optic nerve.
%  [ROITS,SIG] = MNCHECK_OPN(SESSION,GRPANME) checks time courses of optic nerve.
%
%  VERSION :
%    0.90 21.06.05 YM   pre-release
%
%  See also


if nargin < 2,  help mncheck_opn; return;  end


if nargin < 3,  NORM = 'global';  end
if nargin < 4,  PROJOUT = {'muscle'};     end


USE_PCA   = 1;



% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);
fprintf('%s %s : %s %s  USE_PCA=%d\n',datestr(now,'HH:MM:SS'),mfilename,...
        Ses.name,grp.name,USE_PCA);



% LOAD "opn" ROIs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(' loading ''opn''...');
roiTs = mn_roits_cat(mn_roits_get(Ses,grp,'opn',[], USE_PCA));
roiTs.dat = double(roiTs.dat);


% NORMALIZE ROITS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(NORM),
  fprintf(' normalizing(%s)...',NORM);
  roiNorm = mn_roits_cat(mn_roits_get(Ses,grp,NORM,[],USE_PCA));
  MDAT = mean(roiNorm.dat,2);
  for iT = 1:length(MDAT),
    roiTs.dat(iT,:) = roiTs.dat(iT,:) / MDAT(iT);
  end
end

% PROJECT OUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(PROJOUT),
  fprintf(' project-out...');
  if ischar(PROJOUT),  PROJOUT = { PROJOUT };  end
  PRJDAT = [];  K = 1;
  for N = 1:length(PROJOUT),
    tmpts = mn_roits_cat(mn_roits_get(Ses,grp,PROJOUT{N},[],USE_PCA));
    if ~isempty(tmpts),
      if ~isempty(NORM),
        for iT = 1:length(MDAT),
          tmpts.dat(iT,:) = tmpts.dat(iT,:) / MDAT(iT);
        end
      end
      PRJDAT(:,K) = mean(tmpts.dat,2);
      K = K + 1;
    end
  end
  roiTs = mn_roits_projout(roiTs,PRJDAT);
end


fprintf(' plotting...');
[hWin SIG] = subPlotData(Ses,grp,roiTs,NORM,PROJOUT);
figfile = sprintf('%s_%s_%s',Ses.name,grp.name,mfilename);
if ~isempty(NORM),
  figfile = sprintf('%s_norm-%s',figfile,NORM);
end
if ~isempty(PROJOUT),
  figfile = sprintf('%s_projout-%s',figfile,PROJOUT{1});
end
figfile = sprintf('%s.fig',figfile);
saveas(hWin,figfile);




fprintf(' done.\n');




if nargout,
  varargout{1} = roiTs;
  if nargout > 1,
    varargout{2} = SIG;
  end
end


return;






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot data
function [hWin SIG] = subPlotData(Ses,grp,roiTs,NORM,PROJOUT)

tmptitle = sprintf('%s: %s %s Horizontal Section',mfilename,Ses.name,grp.name);
hWin = figure('Name',tmptitle);
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName',  'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');
set(gcf,'PaperOrientation',     'landscape');


SLICES = sort(unique(roiTs.coords(:,3)));

T = mn_exptime(Ses,grp);

TC_PROFILE = zeros(length(T),length(SLICES),class(roiTs.dat));
for iSlice = 1:length(SLICES),
  selslice = SLICES(iSlice);
  tmpidx = find(roiTs.coords(:,3) == selslice);
  tmpdat = roiTs.dat(:,tmpidx);
  tmpdat = tmpdat(:,find(tmpdat(end,:) > 1));
  if ~isempty(tmpdat),
    TC_PROFILE(:,iSlice) = mean(tmpdat,2); 
  end
end

if length(T) > 10,
  tmpmax = max(find(T <= 65));
  %T_IDX = round(1:length(T)/10:length(T));
  T_IDX = round(1:tmpmax/10:tmpmax);
  T_IDX = sort(unique(T_IDX));
else
  T_IDX = 1:length(T);
end


subplot(2,1,1);
COL = jet(length(T_IDX));
legtxt = {};
for N = 1:length(T_IDX),
  Tidx = T_IDX(N);
  plot(SLICES,TC_PROFILE(Tidx,:),'color',COL(N,:));
  hold on; grid on;
  legtxt{N} = sprintf('%.1fhr',T(Tidx));
end
legend(legtxt);
xlabel('Coronal Slice Number');
ylabel('Mean Voxel Value');
title('OPN Profile');

subplot(2,1,2);
colormap(jet(256));
h = surf(T,SLICES,TC_PROFILE','linestyle','none');
colormap(jet(256));
%set(h,'linestyle','none');
xlabel('Time in Hours');
ylabel('Coronal Slice Number');
zlabel('Mean Voxel Value');
title('OPN Profile in 3D');
colorbar;
grid on;
%imagesc(T,SLICES,TC_PROFILE');
%set(gca,'ydir','normal');
%colorbar;
%grid on;
%xlabel('Time in Hours');
%ylabel('Coronal Slice Number');
%title('OPN Profile in 2D');


% REGRESSION
REG = {};
THR = [2.5 3.0 3.5];
fh = @(x,xdata)x(1)*xdata+x(2);
for iThr = 1:length(THR),
  T_THR = [];
  tmpthr = THR(iThr);
  for iSlice = 1:size(TC_PROFILE,2),
    idx = min(find(TC_PROFILE(:,N) >= tmpthr));
    if isempty(idx),
      T_THR(N) = 0;
    else
      T_THR(N) = T(idx);
    end;
  end
  idx = find(T_THR ~= 0);
  TOLFUN		= 1.0000e-006;
  options = optimset('TolFun',TOLFUN,'Display','off');
  [x,resnorm,residual] = lsqcurvefit(fh,[1 1],T_THR(idx),double(SLICES(idx)),[],[],options);
  REG{iThr}.xdata = T_THR(idx);
  REG{iThr}.ydata = SLICES(idx);
  REG{iThr}.x = x;
end



SIG.session  = Ses.name;
SIG.grpname  = grp.name;
SIG.ExpNo    = roiTs.ExpNo;
SIG.slice    = SLICES(:)';
SIG.time     = T;
SIG.dat      = TC_PROFILE;
SIG.info.normalization = NORM;
SIG.info.projectout    = PROJOUT;
SIG.reg      = REG;


return;
