
SESSION = 'j008v2';
GRPNAME = 'mdeftinj';


Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);


ROI = load(mroi_file(Ses,grp.grproi));
ROI = ROI.(grp.grproi);
ROI.roinames = union(ROI.roinames,Ses.roi.names);
ROI = mroiget(ROI,[],'brain');
ROI = mroicat(ROI);

% sort by slice
ROISLICE = zeros(1,length(ROI.roi));
for N = 1:length(ROI.roi),
  ROISLICE(N) = ROI.roi{N}.slice;
end
[ROISLICE, idx] = sort(ROISLICE);
ROI.roi = ROI.roi(idx);


% load anatomy to get dimension
anaImg = anaload(Ses,grp);
nX = size(anaImg.dat,1);  nY = size(anaImg.dat,2);  nS = size(anaImg.dat,3);
nT = length(grp.exps);

clear anaImg;

profz = zeros(length(grp.exps),nS);

REALIGNED = 1;
for iRoi = 1:length(ROI.roi),
  SLICE = ROI.roi{iRoi}.slice;
  tcImg = mn_tcslice_load(Ses,grp,SLICE,REALIGNED);
  tmpdat = double(reshape(tcImg.dat,[nX*nY nT]));
  tmpv   = mean(tmpdat,1);
  profz(:,SLICE) = tmpv(:);
end


NORMDAT = load('tcglobal.mat',grp.name);
NORMDAT = NORMDAT.(grp.name);

nprofz = profz;
for N = 1:size(profz,1),
  nprofz(N,:) = profz(N,:) / NORMDAT.dat(N);
end
