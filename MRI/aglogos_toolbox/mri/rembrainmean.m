function roiTs = rembrainmean(roiTs, DEBUG)
%RPBRAINMEAN - Remove the average roiTs of all brain from individual time series
%
if nargin < 2,
  DEBUG = 0;
end;

if DEBUG,
  for N=1:length(roiTs),
    ts(:,N) = nanmean(roiTs{N}.dat,2);
  end;
  subplot(1,2,1);
  imagesc(ts');
  clear ts;
end;

dat = [];
for N=1:length(roiTs),
  dat = cat(2,dat, roiTs{N}.dat);
end;

SesName = roiTs{1}.session;
GrpName = roiTs{1}.grpname;
grp = getgrp(SesName, GrpName);
anap = getanap(SesName,GrpName);

M = anap.gettrial.IBRAINMEAN;
fprintf('Rem-Mean(%d).',M);

model =  expmkmodel(SesName, GrpName,'hipp');
mn = nanmean(model.dat,2);

[r, p] = corr(dat,mn);
idx = find(p>0.1 & abs(r)<0.1);
dat = dat(:,idx);

mdat = nanmean(dat,2);
sdat = nanstd(dat,[],2);

for R=1:length(roiTs)
  roiTs{R}.info.IBRAINMEAN = M;

  if M==1,
    roiTs{R}.dat = roiTs{R}.dat - repmat(mdat,[1 size(roiTs{R}.dat,2)]);
  elseif M==2,
    roiTs{R}.dat = roiTs{R}.dat - repmat(mdat,[1 size(roiTs{R}.dat,2)]);
    roiTs{R}.dat = roiTs{R}.dat ./ repmat(sdat,[1 size(roiTs{R}.dat,2)]);
  end;
end;

Xmethod = anap.gettrial.Xmethod;
if ~Xmethod | strcmp(Xmethod,'none') | isempty(Xmethod),
  fprintf('tosdu.');
  roiTs = xform(roiTs,'tosdu','prestim');
  for R=1:length(roiTs)
    roiTs{R}.info.Xmethod = 'tosdu';
  end;
end;

if DEBUG,
  for N=1:length(roiTs),
    ts(:,N) = nanmean(roiTs{N}.dat,2);
  end;
  subplot(1,2,2);
  imagesc(ts');
end;

return;
