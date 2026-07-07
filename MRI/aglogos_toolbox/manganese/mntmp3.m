
SESSION = 'd03se1';
GRPNAME = 'mdeftinj';
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);

EXPS = grp.exps;

for iExp = 1:length(EXPS),
  matfile = sprintf('SIGS/%s_%03d_TCIMG.mat',Ses.name,EXPS(iExp));
  load(matfile,'tcImg');
  if iExp==1, TCIMG = tcImg; end
  if iExp > 1,  TCIMG.dat = cat(4,TCIMG.dat,tcImg.dat); end
end

nX = size(TCIMG.dat,1);
nY = size(TCIMG.dat,2);
nS = size(TCIMG.dat,3);
nT = size(TCIMG.dat,4);

TCIMG.dat = reshape(TCIMG.dat,[nX*nY, nS, nT]);

load(mroi_file(Ses,grp.grproi));

roi = mroiget(RoiDef,[],'mlgn');

DAT = {};
for iRoi = 1:length(roi.roi),
  iSlice = roi.roi{iRoi}.slice;
  idx = find(roi.roi{iRoi}.mask(:) > 0);
  tmpdat = TCIMG.dat(idx,iSlice,:);
  sz = size(tmpdat);
  tmpdat = reshape(tmpdat,[prod(sz(1:end-1)), sz(end)]);
  DAT{iRoi} = tmpdat;
end

COL = 'rgbcmykrgbcmyk';

figure;
for N = 1:length(DAT),
  plot(mean(DAT{N},1),'color',COL(N)); hold on; grid on;
end

