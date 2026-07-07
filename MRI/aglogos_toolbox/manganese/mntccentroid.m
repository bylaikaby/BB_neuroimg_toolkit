function varargout = mntccentroid(SESSION,GRPNAME,THRESHOLD)
%MNTCCENTROID - plots a time course of centroids.
%  MNTCCENTROID(SESSION,GRPNAME) plots a time course of centroids.
%
%  VERSION :
%    31.05.05 YM  pre-release
%
%  See also MCENTROID, MNRAWHIST

if nargin < 2,  help mntccentroid; return;  end

if nargin < 3,  THRESHOLD = [];  end


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);

EXPS = grp.exps;

fprintf('%s %s: ',datestr(now,'HH:MM:SS'),mfilename);


% PLOT CENTROIDS' TIME COURSE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CENT = [];  CENT2 = [];  THRESHOLD = 1568;
for iExp = length(EXPS):-1:1,
  if mod(iExp,5) == 0,  fprintf('.');  end
  ExpNo = EXPS(iExp);
  tmpimg = sigload(Ses,ExpNo,'tcImg');
  tmpdat = double(tmpimg.dat);
  if ~isempty(THRESHOLD),
    tmpdat(find(tmpimg.dat(:) > THRESHOLD)) = 1;
  end
  % centroid without binarization
  c = mcentroid(tmpdat);
  CENT(:,iExp) = c(:);
end


% PLOT RESULTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmptxt = sprintf('%s: %s(%s) Centroid Time Course', mfilename,Ses.name,grp.name);
if ~isempty(THRESHOLD),
  tmptxt = sprintf('%s THR=%.1f',tmptxt,THRESHOLD);
end

T = mn_exptime(Ses,grp);

figure('Name',tmptxt);
subplot(3,1,1);
plot(T,CENT(1,:),'marker','.','markersize',10);  grid on;
set(gca,'xlim',[0 max(T)]);
xlabel('Time in hours');  ylabel('Centroid X');
tmptxt = sprintf('%s(%s): Centroid Time Course',Ses.name,grp.name);
if isempty(THRESHOLD),
  tmptxt = sprintf('%s THR=%.1f',tmptxt,THRESHOLD);
end
title(tmptxt);
subplot(3,1,2);
plot(T,CENT(2,:),'marker','.','markersize',10);   grid on;
set(gca,'xlim',[0 max(T)]);
xlabel('Time in hours');  ylabel('Centroid Y');
subplot(3,1,3);
plot(T,CENT(3,:),'marker','.','markersize',10);  grid on;
set(gca,'xlim',[0 max(T)]);
xlabel('Time in hours');  ylabel('Centroid Z');



% get the most far pair
p = [];  K = 1;
for X=1:length(EXPS),
  for Y=X+1:length(EXPS),
    p(K,1) = X;  p(K,2) = Y;  K = K+1;
  end;
end;
D = pdist(CENT');
[tmpv, tmpi] = max(D);
iExp1 = p(tmpi,1);  iExp2 = p(tmpi,2);


d = CENT(:,iExp1) - CENT(:,iExp2);
d = sqrt(sum(d.*d));

fprintf(' Max-distance=%.2f(ExpNo%d-%d)',d,EXPS(iExp1),EXPS(iExp2));


fprintf(' done.\n');

return;

