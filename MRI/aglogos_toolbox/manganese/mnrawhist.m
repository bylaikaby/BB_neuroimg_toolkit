function varargout = mnrawhist(SESSION,GRPNAME)
%MNRAWHIST - plots a histgram of voxel value distribution.
%  MNRAWHIST(SESSION,GRPNAME) plots a histgram of voxel value distribution.
%  This is useful to get threshold for binarization.
%  [THRESHOLD HIST EDGES] = MNRAWHIST(SESSION,GRPNAME) does the same things then
%  return results.
%
%  VERSION :
%    31.05.05 YM  pre-release
%
%  See also MNTCCENTROID

if nargin < 2,  help mnrawhist; return;  end

% CONTROL FLAGS/SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DO_NORMALIZE = 0;


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);

EXPS = grp.exps;

fprintf('%s %s: normalize(%d)',datestr(now,'HH:MM:SS'),mfilename,DO_NORMALIZE);


if DO_NORMALIZE > 0,
  NORM_TC = load('tcglobal.mat',grp.name);
  NORM_TC = NORM_TC.(grp.name);
end



% PLOT HISTGRAM OF VOXEL DISTRIBUTION TO GET THRESHOLD FOR BINARIZATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
HIST = [];
nsteps = 1024;
if DO_NORMALIZE,
  maxv = 10;
else
  maxv = double(intmax('int16'));
end
edges = 0:maxv/nsteps:maxv;
for iExp = length(EXPS):-1:1,
  if mod(iExp,5) == 0,  fprintf('.');  end
  ExpNo = EXPS(iExp);
  tmpimg = sigload(Ses,ExpNo,'tcImg');
  if DO_NORMALIZE > 0,
    if ExpNo > 10,
      %tmpimg.dat = double(tmpimg.dat)*1.6059;
      %tmpimg.dat = double(tmpimg.dat)*1.8479;
    end
    tmpimg.dat = double(tmpimg.dat) / NORM_TC.dat(iExp);
  end
  n = histc(double(tmpimg.dat(:)),edges);
  HIST(:,iExp) = n(:);
end
shist = std(HIST,[],2);
[minv mini] = min(shist(17:64));
mini + 17-1;
THRESHOLD = edges(mini+17-1);



tmptxt = sprintf('%s: Voxel Distribution %s(%s)',mfilename,Ses.name,grp.name);
figure;
set(gcf,'Name',tmptxt);
plot(edges,HIST);  grid on; hold on;
xlabel('Voxel Value');
ylabel('Number of Voxels');
title(sprintf('Voxel Distribution: %s(%s)',Ses.name,grp.name));
line([THRESHOLD THRESHOLD],get(gca,'ylim'),'color','r');
ylm = get(gca,'ylim');
text(THRESHOLD,ylm(2)*0.8,'Threshold for binarization','color','r');

fprintf(' done.\n');


if nargout,
  varargout{1} = THRESHOLD;
  if nargout > 2,
    varargout{2} = HIST;
  end
  if nargout > 3,
    varargout{3} = edges;
  end
end


return;



% PLOT CENTROIDS' TIME COURSE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CENT = [];  CENT2 = [];  THRESHOLD = 1568;
for iExp = length(EXPS):-1:1,
  if mod(iExp,5) == 0,  fprintf('.');  end
  ExpNo = EXPS(iExp);
  tmpimg = sigload('m02th1',ExpNo,'tcImg');
  % centroid without binarization
  tmpdat = tmpimg.dat;
  c = mcentroid(tmpdat);
  CENT(:,iExp) = c(:);
  % centroid with binarization
  tmpdat(:) = 0;
  tmpdat(find(tmpimg.dat(:) > THRESHOLD)) = 1;
  c = mcentroid(tmpdat);
  CENT2(:,iExp) = c(:);
end

figure;
set(gcf,'Name','m02th1: Centroid Time Course without binarization by threshold');
subplot(3,1,1); plot(CENT(1,:));  grid on; set(gca,'xlim',[0 104]); ylabel('Centroid X');
subplot(3,1,2); plot(CENT(2,:));  grid on; set(gca,'xlim',[0 104]); ylabel('Centroid Y');
subplot(3,1,3); plot(CENT(3,:));  grid on; set(gca,'xlim',[0 104]); ylabel('Centroid Z');


figure;
set(gcf,'Name','m02th1: Centroid Time Course WITH binarization by threshold');
subplot(3,1,1); plot(CENT2(1,:));  grid on; set(gca,'xlim',[0 104]); ylabel('Centroid X');
subplot(3,1,2); plot(CENT2(2,:));  grid on; set(gca,'xlim',[0 104]); ylabel('Centroid Y');
subplot(3,1,3); plot(CENT2(3,:));  grid on; set(gca,'xlim',[0 104]); ylabel('Centroid Z');

% get the most far pair
p = [];  K = 1;
for X=1:length(EXPS),
  for Y=X+1:length(EXPS),
    p(K,1) = EXPS(X);  p(K,2) = EXPS(Y);  K = K+1;
  end;
end;
D = pdist(CENT2');
[tmpv, tmpi] = max(D);
Exp1 = p(tmpi,1);  Exp2 = p(tmpi,2);

d = CENT2(:,p1) - CENT2(:,p2);
d = sqrt(sum(d.*d));
tcImg1 = sigload(SESSION,Exp1,'tcImg');
tcImg2 = sigload(SESSION,Exp2,'tcImg');

